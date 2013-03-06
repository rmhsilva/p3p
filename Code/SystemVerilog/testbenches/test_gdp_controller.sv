`timescale 1ns / 1ps
// Testbench for GDP

typedef logic signed [15:0] num; // My number format

module test_gdp_controller();
  
// Signals
logic reset, clk;
logic new_vector_available;
num x [25:0];
num mean, omega, k;
logic new_stats_available, get_new_stats;
logic [7:0] senone_index;
num senone_score;
logic score_ready;
logic gdp_idle;

// connect module
gdp_controller gdp_c (.*);


// Clock function
initial begin
  clk = 0;
  forever #5ns clk = ~clk;
end

// Properties to be fullfilled


// Set signals
initial begin
  reset = 1;
  
  #20ns;
  reset = 0;
  new_vector_available = 1;
  new_stats_available = 1;
  
end


endmodule

