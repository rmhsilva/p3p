//typedef logic signed [15:0] num; // My number format

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
    output logic [20:0] data_addr,
    output logic read_data,

    output logic send_done
	);

// Module to send all the senone scores from memory to L'Imperatrice (via UART)

logic [7:0] senone_index;

typedef enum {IDLE, READING, SENDING} state_t;
state_t state;


always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
        senone_index <= 0;
        send_done <= 0;
        state <= IDLE;
    end
    else
        case (state)
            IDLE: begin
                send_done <= 0;
                if (start_send) begin
                    state <= READING;
                    senone_index <= 0;
                end
            end

            READING:
                if (sram_ready) begin
                    state <= SENDING;
                    tx_value <= data_in;
                    start_tx <= 1;
                end

            SENDING: begin
                start_tx <= 0;
                if (uart_ready) begin
                    if (senone_index == n_senones-1) begin
                        state <= IDLE;
                        send_done <= 1'b1;
                    end else begin
                        state <= READING;
                        senone_index <= senone_index + 1;
                    end
                end
              end
        endcase
end

// Assign sram and uart signals conditionally, to avoid bus contention
assign read_data = (state==READING)? 1'b1 : 1'bZ;
assign data_addr = (state==READING)? senone_index<<1 : 21'bZ;


endmodule