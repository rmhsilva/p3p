//typedef logic signed [15:0] num; // My number format

module normaliser #(parameter n_senones=10)
    (
    input logic clk, reset, start_norm,
    input num best_score,

    // SRAM connections
    input logic sram_ready,
    output logic [20:0] data_addr,
    output logic write_data,
    output num data_out,
    output logic read_data,
    input num data_in,

    output logic norm_done
	);

// This module takes in a best score, and normalises scores to it
// score_norm = best_score - score_norm

logic [7:0] senone_index;
num current_score;
num best_score_reg;

typedef enum {IDLE, READING, WRITING} state_t;
state_t state;

always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
        senone_index <= 0;
        norm_done <= 0;
    end
    else begin
        case (state)
            IDLE: begin
                norm_done <= 0;
                if (start_norm) begin
                    state <= READING;
                    best_score_reg <= best_score;
                    senone_index <= 0;
                end
            end

            READING:
                if (sram_ready) begin
                    current_score <= data_in;
                    state <= WRITING;
                end

            WRITING:
                if (sram_ready) begin
                    if (senone_index == n_senones-1) begin
                        state <= IDLE;
                        norm_done <= 1;
                    end
                    else begin
                        state <= READING;
                        senone_index <= senone_index + 1;
                    end
                end
        endcase
    end
end

// Assign sram signals conditionally, to avoid bus contention
always_comb begin
    data_addr  = (state!=IDLE)? senone_index<<1 : 21'bZ;
    data_out   = (state==WRITING)? (best_score_reg - current_score) : 8'bZ;
    write_data = (state==WRITING)? 1'b1 : 1'bZ;
    read_data  = (state==READING)? 1'b1 : 1'bZ;
end


endmodule