`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    20:27:27 02/20/2013 
// Design Name: 
// Module Name:    gdp 
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
module gdp(
	 input clk, reset,
	 input first_calc, last_calc,
    input [0:15] x,		// Observation vector component
    input [0:15] k,		// K value for this state
    input [0:15] omega,	// Corresponding omega component...
    input [0:15] mean,	// ... and mean component
	 
    output reg [0:15] ln_p,	// ln(P(X)) = ln[ probability of X for this state ]
    output data_ready
    );

parameter pipeline_length = 3;

// Simple 0:15 mux. Because writing 'mux' is clearer.
function [0:15] mux;
input [0:15] a, b;		// a chosen if sel == 0
input sel;
begin
	mux = (sel)? b : a;
end
endfunction

integer i;


/*****[ Pipeline containers ]*************************/
// TODO: Check the size of these....! ie need 32 bits after square? etc
// upper bits after squaring / multiplying / adding -> use to check for overflow?
reg [pipeline_length-1:0] first_calc_r = 0;
reg [pipeline_length-1:0] last_calc_r = 0;
reg [15:0] presub_r [1:0];
reg [15:0] presquare_r = 0;
reg [31:0] prescale_r = 0;
reg [15:0] omega_r [pipeline_length-1:0];

wire [33:0] scaled_result;
wire [15:0] acc_result;


/*****[ Shift things along (l->r) ]********************/
always @(posedge clk) begin
	first_calc_r 	<= {first_calc, first_calc_r[pipeline_length-1:1]};
	last_calc_r		<= {last_calc, last_calc_r[pipeline_length-1:1]};
	
	omega_r[pipeline_length - 1] <= omega;
	for(i=pipeline_length-1; i>0; i=i-1)
		omega_r[i-1] <= omega[i];
	
	presub_r[0] <= mux(x,k, last_calc);
	presub_r[1] <= mux(mean,acc_result, last_calc);
	
	presquare_r <= presub_r[0] - presub_r[1];		// Subtraction
	prescale_r  <= presquare_r * presquare_r;		// Squaring
end

// output of subtractor, into output!
always @(posedge clk or posedge reset) begin
	if (reset)
		ln_p <= 0;
	else
		ln_p <= presquare_r;
end


/*****[ Connect things ]*****************************/
assign scaled_result = prescale_r * omega_r[0];	// Multiplication
assign acc_result = scaled_result + mux(acc_result,0, first_calc_r[0]);	// Add
assign data_ready = last_calc_r[0];

endmodule
