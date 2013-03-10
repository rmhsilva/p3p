`timescale 1ns / 1ps
// Testbench for uart. Run for ~140us

typedef logic signed [15:0] num; // My number format

module test_uart();
  
logic reset, clk, tx, rx;
logic send_data, tx_ready, rx_available;
num tx_nums [0:0];
num rx_nums [9:0];

uart #(.n_tx_nums(1), .n_rx_nums(10)) serial (.*);

// Clock function
initial begin
  clk = 0;
  forever #5ns clk = ~clk;
end

// Set signals
initial begin
  reset = 1;
  send_data = 0;
  
  #100ns reset = 0;
  tx_nums[0] = 16'h55AA;
  send_data = 1;
  
  #10ns send_data = 0;
  
  #120us reset = 0;
  tx_nums[0] = 16'h55AA;
  send_data = 1;
  
  #10ns send_data = 0;
end


endmodule
