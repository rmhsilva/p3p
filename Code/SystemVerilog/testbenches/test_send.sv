`timescale 1ns / 1ps
// Testbench for uart. Run for ~140us

typedef logic signed [15:0] num; // My number format

module test_send();

// General signals
logic reset, clk;

// uart things
logic tx, rx, rx_available;
num rx_nums [9:0];

// Connections between send and uart
logic start_send, send_done;  // to the send module
logic uart_ready, start_tx;   // between send and uart
num tx_value;

// SRAM connection
num data_in;
logic sram_ready, read_data;
logic [20:0] sram_addr;

// Module inst.
send #(.n_senones(5)) sender (.*);
uart #(.n_tx_nums(1), .n_rx_nums(10)) serial
  (.tx_nums(tx_value), .tx_ready(uart_ready) .send_data(start_tx) .*);

// TODO: test this with the sram module included.

// Clock function
initial begin
  clk = 0;
  forever #5ns clk = ~clk;
end

// Set signals
initial begin
  reset = 1;
  start_send = 0;
  data_in = 16'h55aa;
  sram_ready = 1;

  #20ns;
  reset = 0;
  start_send = 1;


  #20ns start_send = 0;

end


endmodule
