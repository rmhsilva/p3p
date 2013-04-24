// Uncomment the typedef for Modelsim compilation
//typedef logic signed [15:0] num;

module uart #(parameter n_tx_nums=1, n_rx_nums=25)
    (
    input logic clk, reset, rx, 
    output logic tx,
    input logic new_vector_incoming,  // Indicates L'Imperatrice is tx'ing a new vector

    input logic send_data,
    input num tx_nums [n_tx_nums-1:0],
    output logic tx_ready,

    output rx_available,
    output num rx_nums [n_rx_nums-1:0]
    );

// Internals
logic sending;
logic baud_normal, baud_fast;
logic rx_idle, uart_available, start_tx, uart_tx_ready;
shortint tx_index, rx_index;
logic [7:0] tx_byte, rx_byte;
logic [7:0] tx_buffer [(n_tx_nums*2)-1:0];
logic [7:0] rx_buffer [(n_rx_nums*2)-1:0];


// Tx process (LSB first)
always_ff @(posedge clk or posedge reset) begin : proc_tx
    if (reset) begin
      sending <= 0;
      tx_index <= 0;
      tx_byte <= 0;
    end
    else if (sending) begin
      tx_byte <= tx_buffer[tx_index];
      
      if (tx_index == n_tx_nums*2) sending <= 0;
      else
      if (uart_tx_ready) begin  // only move to next byte when uart tx is ready
        tx_index <= tx_index + 1;
      end
    end
    else if (send_data) begin
        for (int i=0; i<n_tx_nums; i=i+1)
            {tx_buffer[(i*2)+1], tx_buffer[i*2]} <= tx_nums[i];

        sending <= 1;
        tx_index <= 0;
        tx_byte <= tx_nums[0][7:0];
    end
end

assign start_tx = sending;
assign tx_ready = (~send_data & uart_tx_ready & ~start_tx); // tx_ready: high when not tx'ing anymore


// Rx process
always_ff @(posedge clk or posedge reset) begin : proc_rx
    if (reset)
      rx_index <= 0;
    else
    if (uart_available && (rx_index < n_rx_nums*2)) begin
        rx_buffer[rx_index] <= rx_byte;
        rx_index <= rx_index + 1;
    end
    else if (new_vector_incoming | rx_index == n_rx_nums*2) rx_index <= 0;  // Reset the count
end

// Assign outputs correctly
always_comb
    for (int i=0; i<n_rx_nums; i=i+1)
        rx_nums[i] = {rx_buffer[(i*2)+1], rx_buffer[i*2]};

// rx_available high when enough numbers have been received.
assign rx_available = (rx_index==n_rx_nums*2);


// Module instantiations
baudgen ticker (.clk, .enable(1'b1), .baud_normal, .baud_fast);
uart_tx serialiser (.tx_data(tx_byte), .tx_ready(uart_tx_ready), .baudtick(baud_normal), .*);
uart_rx deserialiser (.rx_data(rx_byte), .rx_available(uart_available), .baudtick8(baud_fast), .*);

endmodule