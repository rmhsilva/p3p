`timescale 1ns / 1ps
// Testbench for uart. Run for ~140us

typedef logic signed [15:0] num; // My number format

module test_uart();
  
logic reset, clk, tx, rx, new_vector_incoming;
logic send_data, tx_ready, rx_available;
num tx_nums [4:0];
num rx_nums [4:0];

uart #(.n_tx_nums(5), .n_rx_nums(5)) serial (.*);


// Clock function
initial begin
  clk = 0;
  forever #5ns clk = ~clk;
end

assign rx = tx;

// Set signals
initial begin
  reset = 1;
  send_data = 0;
  
  #100ns reset = 0;
  send_data = 1;
  tx_nums = { 16'hF6A5, 16'hFEDA, 16'hFD3C, 16'h00C1, 16'hDABE };
  
  #10ns send_data = 0;
  
 // // Test sending 2 different 16 bit vals
//  #100ns reset = 0;
//  tx_nums[0] = 16'h5501;
//  send_data = 1;
//  
//  #10ns send_data = 0;
//  
//  #120us;
//  tx_nums[0] = 16'h01FF;
//  send_data = 1;
//  
//  #10ns send_data = 0;
//  
//  // Test receiving data
//  #150us;
//  new_vector_incoming = 1;
//  tx_nums[0] = 16'h1234;
//  send_data = 1;
//  
//  #10ns;
//  send_data = 0;
//  new_vector_incoming = 0;
//  
//  #120us;
//  tx_nums[0] = 16'h5678;
//  send_data = 1;
//  
//  #10ns send_data = 0;
end


endmodule
