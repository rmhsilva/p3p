`timescale 1ns / 1ps
// Testbench for GDP

typedef logic signed [15:0] num; // My number format

module test_top_level();

// Module signals:
logic clk,	reset;	 // clk50M: (P60) 50MHz onboard clock
logic status_led;	    // (P31) onboard status LED

// Data uart:
logic uart_tx;		//  -> pin 2, bank 2 of L'Imperatrice
logic uart_rx;		//  -> pin 3, bank 2 of L'Imperatrice

// L'Imperatrice Debug uart re-route:
logic duart_rx_in;	 //  -> FTDI TX pin
logic duart_tx_in;	 //  -> pin 1, bank 2 of L'Imperatrice
logic duart_rx_out;	//  -> pin 0, bank 2 of L'Imperatrice
logic duart_tx_out;	//  -> FTDI RX pin

// Onboard SRAM signals:
wire [7:0] sram_data;
logic [20:0] sram_addr;
logic sram_ce, sram_we, sram_oe;


top_level top (.clk50M(clk), .sram_data(sram_data), .*);
  

// Clock function
initial begin
  clk = 0;
  forever #5ns clk = ~clk;
end


// Set signals
initial begin
  reset = 1;
  duart_rx_in = 0;
  
  #20ns;
  reset = 0;
  duart_rx_in = 1;
  
end

endmodule

