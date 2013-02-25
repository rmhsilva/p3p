`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:28:38 02/23/2013 
// Design Name: 
// Module Name:    gdp_controller 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module gdp_controller
	#(parameter n_components = 25)
	(
    input clk, reset,
	 input [(n_components*16)-1:0] x,	// the observation vector
	 input new_vector,						// indicates new vector available
	 
	 input [(3*16)-1:0] data_in, 	// statistical (mean,omega,K) values from storage
	 output get_data,					// Get next stat values (eg from SRAM) flag
	 
	 output reg write_data,			// Write data (eg into SRAM) flag
	 output reg [7:0] data_addr,	// Address of data in storage (to store or read)
	 output reg [15:0] data_out,	// Data lines (for read or write)
	 
	 output reg gdp_done			// Finished processing senones flag
    );

// Basic purpose of this module: update the probabilities of ALL senones, given a new observation vector


// loop from start of senone data to end, feeding it into the pipeline.
// possible future extension - split this into two or more modules, ie have more than 1 GDP active.

reg [4:0] component_index = 0;
reg [8:0] senone_index = 0;

wire last_calc, first_calc;
wire data_ready;
reg [15:0] x_component;
reg [15:0] k;
reg [15:0] omega;
reg [15:0] mean;
wire [15:0] ln_p;

// Temporary, testing TODO remove
always @(posedge clk) begin
	if (new_vector) begin
		data_out <= x[15:0] + x[31:16];
		write_data <= 1;
		gdp_done <= 1;
	end
	else gdp_done <= 0;
end

// Always loop controlling the indexes and signals
always @(posedge clk) begin
	if (new_vector) begin
		component_index <= 0;
		senone_index <= 0;
	end
	else begin // loop over all components
		if (component_index < n_components-1) begin
			component_index <= component_index + 1;
			
			x_component <= x[component_index*16 +: 16];
			
			// Get stat values
			
		end
		
		else begin
			component_index <= 0;
			senone_index <= senone_index + 1;
			
			// Write score to ROM
		end
	end
end

// Assignments of signals
assign first_calc = (component_index==0)? 1 : 0;
assign last_calc = (component_index==n_components-2)? 1 : 0;


// Instantiate modules
gdp gdpipe(.clk(clk), .reset(reset), .first_calc(first_calc), .last_calc(last_calc),
				.x(x_component), .k(k), .omega(omega), .mean(mean), .ln_p(ln_p), .data_ready(data_ready));
				

endmodule
