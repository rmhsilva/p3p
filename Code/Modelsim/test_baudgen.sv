// Testbench for Baud generator. Run for at least 20us

module test_baudgen();
  
logic enable, baud_normal, baud_fast, clk;

baudgen ticker (.*);
  
// Clock function
initial begin
  clk = 0;
  forever #10ns clk = ~clk;
end

// Set signals
initial begin
  enable = 0;
  
  #40ns enable = 1;
end


endmodule
