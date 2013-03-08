typedef logic signed [15:0] num; // My number format

module uart #(parameter n_tx_nums=1, n_rx_nums=25)
    (
    input logic clk, reset, rx, tx,

    input logic send_data,
    input num tx_nums [n_tx_nums-1:0],
    output logic tx_ready,

    output rx_available,
    output num rx_nums [n_rx_nums-1:0]
    );

// Internals
logic start_tx, rx_ready, rx_packet_end;
shortint tx_index, rx_index;
logic [7:0] tx_byte, rx_byte;
logic [7:0] tx_buffer [(n_tx_nums*2)-1:0];
logic [7:0] rx_buffer [(n_rx_nums*2)-1:0];


// Tx process (LSB first)
always_ff @(posedge clk) begin : proc_tx
    if (tx_index < n_tx_nums*2) begin
        start_tx <= 1'b1;
        tx_byte <= tx_buffer[tx_index];
        tx_index <= tx_index + 1;
    end
    else if (send_data) begin
        for (int i=0; i<n_tx_nums; i=i+1)
            {tx_buffer[i+1], tx_buffer[i])} <= tx_nums[i];

        tx_index <= 1;
        start_tx <= 1'b1;
        tx_byte <= {tx_nums[0]}[7:0];
    end
    else start_tx <= 0;
end

assign tx_ready = ~start_tx; // tx_ready: high when not tx'ing anymore


// Rx process
always_ff @(posedge clk) begin : proc_rx
    if (rx_ready && (rx_index < n_rx_nums*2)) begin
        rx_buffer[rx_index] <= rx_byte;
        rx_index <= rx_index + 1;
    end
    else rx_index <= 0;
end

always_comb
    for (int i=0; i<n_rx_nums; i=i+1)
        rx_nums[i] = {rx_buffer[i+1], rx_buffer[i]};
end

// rx_available high for 1 clock cycle when no more data rec'd
assign rx_available = rx_packet_end;


// Module instantiations
async_transmitter serializer(.clk(clk), .TxD(tx), .TxD_start(start_tx), .TxD_data(tx_byte));
async_receiver deserializer(.clk(clk), .RxD(rx), .RxD_data_ready(rx_ready), .RxD_data(rx_byte), .RxD_endofpacket(rx_packet_end));

endmodule
