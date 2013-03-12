module top (
	input logic clk50M,			// clk50M: (P60) 50MHz onboard clock
	output logic status_led,	// (P31) onboard status LED
	input logic switch3, switch4, button,

	// Onboard SRAM signals:
	inout [7:0] sram_data,
	output logic [20:0] sram_addr,
	output logic sram_ce, sram_we, sram_oe
	);
	
// Internal signals
num data_in, data_out;
logic [20:0] data_addr;
logic write_data, read_data, sram_ready, reset;

logic set_mem;
logic cleared_in;

// Simple flashing LED to indicate operation.
logic [25:0] status_cnt;
always_ff @(posedge clk50M) begin
    status_cnt <= status_cnt + 1;
end

always_ff @(posedge clk50M or posedge button) begin
	if (button) begin
		set_mem <= 0;
	end
	else if (~set_mem) begin
		write_data <= 1;
		read_data <= 0;
		data_in <= 16'b1000101011110101;
		set_mem <= 1;
		cleared_in <= 0;
	end
	else if (~cleared_in) begin
		write_data <= 0;
		cleared_in <= 1;
		data_in <= 16'b0;
	end
	else begin
		read_data <= 1;
	end
end

assign data_addr = 21'b0;

assign status_led = data_out[{switch3, switch4}];

sram mem (.clk(clk50M), .*);

endmodule