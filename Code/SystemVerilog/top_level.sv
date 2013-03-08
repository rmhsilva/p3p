typedef logic signed [15:0] num; // My number format

module main (
	input logic clk50M,	reset,	// clk50M: (P60) 50MHz onboard clock
	output logic status_led,	// (P31) onboard status LED
	// Data uart:
	output logic uart_tx,		//  -> pin 2, bank 2 of L'Imperatrice
	input logic uart_rx,		//  -> pin 3, bank 2 of L'Imperatrice
	// L'Imperatrice Debug uart re-route:
	input logic duart_rx_in,	//  -> FTDI TX pin
	input logic duart_tx_in,	//  -> pin 1, bank 2 of L'Imperatrice
	output logic duart_rx_out,	//  -> pin 0, bank 2 of L'Imperatrice
	output logic duart_tx_out,	//  -> FTDI RX pin
	// Onboard SRAM signals:
	inout logic [7:0] sram_data,
	output logic [20:0] sram_addr,
	output logic sram_ce, sram_we, sram_oe
	);

parameter n_components = 5;
parameter n_senones = 10;
parameter n_tx_bytes = 2;
parameter n_rx_bytes = 2*n_components;



/*****[ Internal signals and wires ]****************/

// Counter for flashing LED thing
logic [25:0] status_cnt = 0;


// GDP controller Signals
logic new_vector_available;
num x [n_components-1:0];
logic [7:0] senone_idx;
num senone_score;
logic score_ready;
logic gdp_idle;


// UART signals
logic rx_available;
logic start_tx;
num tx_buffer [n_tx_bytes:0];
num rx_buffer [n_rx_bytes:0];


// State machine setup
typedef enum {IDLE, PROC, NORM, SEND} state_t;
state_t state, next;


/***************************************************/
/*****[ Main Operations ]***************************/



// Simple flashing LED to indicate operation.
always @(posedge clk50M) begin
    status_cnt <= status_cnt + 1;
end
// Assign the status LED to different values depending on operation
always_comb begin : proc_statusLED
    unique case (state)
        IDLE: status_led = 1'b1;
        PROC: status_led = status_cnt[25];
        NORM: status_led = status_cnt[24];
        SEND: status_led = status_cnt[23];
        default: status_led = 1'b0;
    endcase
end : proc_statusLED

// Reroute the ARM chip Debug UART serial port
assign {duart_rx_out,duart_tx_out} = {duart_rx_in,duart_tx_in};



/*****[ Connect Modules up ]************************/

// Serial connection to L'Imperatrice
uart #(.n_tx_bytes(n_tx_bytes), .n_rx_bytes(n_rx_bytes)) data_uart
        (.clk(clk50M), .rx(uart_rx), .tx(uart_tx), .send_data(start_tx), .rx_available, .tx_bytes(tx_buffer), .rx_bytes(rx_buffer));

// GDP controller
gdp_controller #(.n_components(n_components), .n_senones(n_senones)) gdp_c
                 (.clk(clk50M), .*);


endmodule
