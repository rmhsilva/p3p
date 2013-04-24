typedef logic signed [15:0] num; // My number format

module test_top_level();

// Module signals:
logic clk,	reset;	 // clk50M: (P60) 50MHz onboard clock
logic status_led;	    // (P31) onboard status LED

// Data uart:
logic uart_tx;		//  -> pin 2, bank 2 of L'Imperatrice
logic uart_rx;		//  -> pin 3, bank 2 of L'Imperatrice
logic new_vector_incoming;

// L'Imperatrice Debug uart re-route:
logic duart_rx_in;	 //  -> FTDI TX pin
logic duart_tx_in;	 //  -> pin 1, bank 2 of L'Imperatrice
logic duart_rx_out;	//  -> pin 0, bank 2 of L'Imperatrice
logic duart_tx_out;	//  -> FTDI RX pin

// Onboard SRAM signals:
wire [7:0] sram_data;
logic [20:0] sram_addr;
logic sram_ce, sram_we, sram_oe;

logic clk_out;
logic [2:0] state_output;
logic start_norm, start_send, norm_done, send_done, LRADC0_fix;
logic [7:0] sram_data_debug;
logic [3:0] sram_addr_debug;
logic ce_db, we_db, oe_db;
logic [2:0] sender_state;


top_level top(.*);

// Virtual SRAM chip for testing purposes:
sram_model mem(.cs(sram_ce), .we(sram_we), .oe(sram_oe), .addr(sram_addr), .data(sram_data));

// Use a virtual UART to simulate receiving data
logic virtual_send, virtual_ready;
num virtual_data [5:0];
uart #(.n_tx_nums(6), .n_rx_nums(5)) virtual_serial
  ( .rx(), .tx(uart_rx), .send_data(virtual_send), .tx_nums(virtual_data),
    .tx_ready(virtual_ready), .rx_available(), .rx_nums(), .*);


// Clock function
initial begin
  clk = 0;
  forever #10ns clk = ~clk;
end


// Set signals
initial begin
  reset = 1;
  virtual_send = 0;
  virtual_data = {16'h175B, 16'hF6A5, 16'hFEDA, 16'hFD3C, 16'h00C1, 16'hDABE};
  
  #20ns;
  reset = 0;
  new_vector_incoming = 1;
  virtual_send = 1;
  
  #20ns;
  new_vector_incoming = 0;
  virtual_send = 0;
  
  #1100us;
  //new_vector_incoming = 1;
  
  #20ns;
  //new_vector_incoming = 0;
  
end

endmodule

