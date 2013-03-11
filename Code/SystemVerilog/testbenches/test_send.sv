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

// sender SRAM connection
num data_in;
logic sram_ready, read_data;
logic [20:0] data_addr;

// Actual SRAM connections
wire [7:0] sram_data;
logic [20:0] sram_addr;
logic sram_ce, sram_we, sram_oe;

// Module inst.
send #(.n_senones(5)) sender (.*);
uart #(.n_tx_nums(1), .n_rx_nums(10)) serial
  (.tx_nums(tx_value), .tx_ready(uart_ready), .send_data(start_tx), .*);

// SRAM access module
sram ram(.clk, .reset, .data_addr, .sram_ready, .data_out(data_in),
  .write_data(), .data_in(), .read_data, .sram_addr, .sram_data, .*);

// SRAM model
sram_model mem(.cs(sram_ce), .we(sram_we), .oe(sram_oe), .addr(sram_addr), .data(sram_data));

// Clock function
initial begin
  clk = 0;
  forever #5ns clk = ~clk;
end

//assign data_in = 16'h8008 + sram_addr<<1;

// Set signals
initial begin
  reset = 1;
  start_send = 0;

  #20ns;
  reset = 0;
  start_send = 1;


  #20ns start_send = 0;

end


endmodule
