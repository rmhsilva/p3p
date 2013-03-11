typedef logic signed [15:0] num; // My number format

module send #(parameter n_senones=10)
    (
	input logic clk, reset, start_send,

    // Uart connection
    input logic uart_ready,
    output num tx_value,
    output logic start_tx,

    // SRAM connection
    input num data_in,
    input logic sram_ready,
    output logic [20:0] sram_addr,
    output logic read_data,

    output logic send_done
	);

// Module to send all the senone scores from memory to L'Imperatrice (via UART)

logic sending;
logic [7:0] senone_index;

always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
        senone_index <= 0;
        send_done <= 0;
        sending <= 0;
    end
    else if (~sending && start_send) begin
        sending <= 1'b1;
        senone_index <= 0;
        send_done <= 1'b0;
    end
    else if (sending) begin
        if (senone_index == n_senones-1) begin
            senone_index <= 0;
            sending <= 0;
            send_done <= 1'b1;
            start_tx <= 0;
        end
        else if (uart_ready && sram_ready) begin
            senone_index <= senone_index + 1;
            tx_value <= data_in;
            start_tx <= 1;
        end
        else begin
            start_tx <= 0;
        end
    end
    else send_done <= 0;
end

// Assign sram signals conditionally, to avoid bus contention
assign read_data = (sending)? 1'b1 : 1'bZ;
assign sram_addr = (sending)? senone_index<<1 : 21'bZ;

endmodule