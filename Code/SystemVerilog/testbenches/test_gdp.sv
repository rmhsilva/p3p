`timescale 1ns / 1ps
// Testbench for GDP

module test_gdp();
  
logic        reset, clk, first_calc, last_calc;
logic [15:0] x;
logic [15:0] k;
logic [15:0] omega;
logic [15:0] mean;
logic [15:0] ln_p;
logic        data_ready;

// Clock function
initial begin
  clk = 0;
  forever #5ns clk = ~clk;
end

// Properties to be fullfilled
assert property (@(posedge clk) last_calc |-> ##4 data_ready);


// Set signals
initial begin
  reset = 1;
  first_calc = 0;
  last_calc  = 0;
  x = 0;
  k = 0;
  omega = 0;
  mean = 0;
  
  #20ns;
  reset = 0;
  first_calc = 1;
  x = 16'hDABE;
  omega = 16'h002B;
  mean = 16'h17A3;
  
//  #10ns;
//  first_calc = 0;
//  x = ;
//  omega = ;
//  mean = ;
//
//  #5ns;
//  x = ;
//  omega = ;
//  mean = ;
//  
//  #5ns;
//  x = ;
//  omega = ;
//  mean = ;
  
  #10ns;
  first_calc = 0;
  last_calc = 1;
  x = 16'h00C1;
  k = 16'h17C5;
  omega = 16'h0014;
  mean = 16'h0EF5;
  
  #10ns last_calc = 0;
  
  #15ns;
  assert(data_ready == 1'b1);
  assert(ln_p == 16'h0000) $display("Finished, correct result");
  
end

// connect modules
gdp pipe(.*);

//module gdp(
//	 input clk, reset,
//	 input first_calc, last_calc,
//    input [0:15] x,		// Observation vector component
//    input [0:15] k,		// K value for this state
//    input [0:15] omega,	// Corresponding omega component...
//    input [0:15] mean,	// ... and mean component
//	 
//    output reg [0:15] ln_p,	// ln(P(X)) = ln[ probability of X for this state ]
//    output data_ready
//    );

endmodule
