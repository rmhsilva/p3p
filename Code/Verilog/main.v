`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:33:32 02/17/2013 
// Design Name: 
// Module Name:    main 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module main(
    input clk50M,	reset,		// clk50M: (P60) 50MHz onboard clock
    output status_led,			// (P31) onboard status LED
	 
    output uart_tx,				//  -> pin 2, bank 2 of L'Imperatrice
    input uart_rx,				//  -> pin 3, bank 2 of L'Imperatrice
	 
	 input duart_rx_in,			// The Debug Uart signals from L'Imperatrice
	 input duart_tx_in,			//  -> pin 1, bank 2 of L'Imperatrice
	 output duart_rx_out,		//  -> pin 0, bank 2 of L'Imperatrice
	 output duart_tx_out,		//  -> FTDI RX pin
	 
    inout [7:0] sram_data,
	 output [20:0] sram_addr,
    output sram_ce,
    output sram_we,
	 output sram_oe
    );

parameter n_tx_bytes = 2;
parameter n_rx_bytes = 2*25;


/*****[ Internal signals and wires ]****************/

// Counter for flashing LED thing
reg [25:0] status_cnt = 0;

// Serial connection stuff
reg start_tx = 0;
wire rx_available;
reg [7:0] tx_buffer [0:n_tx_bytes-1];
wire [7:0] rx_buffer [0:n_rx_bytes-1]; 
wire [(n_rx_bytes*8)-1:0] rx_buffer_flat;		// Flattened versions of the above
wire [(n_tx_bytes*8)-1:0] tx_buffer_flat;		// .

// GDP signals
wire [15:0] gdp_result;

// Various signals
wire gdp_done, norm_done, send_done;

// State machine things
parameter [2:0]
	IDLE = 3'd0 ,
	PROC = 3'd1 ,
	NORM = 3'd2 ,
	SEND = 3'd3 ;

reg [2:0] state, next_state;


integer i;



/***************************************************/
/*****[ Main Operations ]***************************/

// State logic. Yes this state machine does nothing. Yet.
always @(posedge clk50M, posedge reset) begin
	if (reset) state <= IDLE;
	else
		case (state)
			IDLE: state <= (rx_available)? PROC : IDLE;
			PROC: state <= (gdp_done)? NORM : PROC;
			NORM: state <= SEND; //(norm_done)? SEND : NORM;
			SEND: state <= IDLE; //(send_done)? IDLE : NORM;
			default: state <= IDLE;
		endcase
end

// Signal logic
always @(state) begin
	case (state)
		PROC: {tx_buffer[0],tx_buffer[1]} = (gdp_done)? gdp_result : 16'd0;
		SEND: begin
			start_tx = 1'b1;
		end
		default: begin
			start_tx = 0;
		end
	endcase
end



/*****[ Misc top-level operations ]******************/

// Unflatten received data
//always @(posedge clk50M) begin
//	if (rx_available) begin
//		for (i=0; i<n_rx_bytes; i=i+1) rx_buffer[i] = rx_buffer_flat[i*8 +: 8];
//	end
//end

// Flatten data to tx
//genvar i;
//generate
//for (i=0; i<n_tx_bytes; i=i+1) begin : blocki
//	assign tx_buffer_flat[i*8 +: 8] = tx_buffer[i];
//end
//endgenerate

// Simple flashing LED to indicate operation.
always @(posedge clk50M) begin
	status_cnt <= status_cnt + 1;
end
assign status_led = status_cnt[25];

// Reroute the ARM chip Debug UART serial port
assign {duart_rx_out,duart_tx_out} = {duart_rx_in,duart_tx_in};



/*****[ Instantiate modules ]***********************/
uart #(.n_tx_bytes(n_tx_bytes), .n_rx_bytes(n_rx_bytes)) data_uart  // The serial connection to PC
		(.clk(clk50M), .rx(uart_rx), .tx(uart_tx), .send_data(start_tx), .rx_available(rx_available), .tx_bits(tx_buffer_flat), .rx_bits(rx_buffer_flat));


// Gaussian Distance Pipe Controller
gdp_controller gdp_ctrl (
    .clk(clk), .reset(reset), 
    .x(rx_buffer_flat), 
    .new_vector(rx_available), 
    .data_in(data_in), 
    .get_data(get_data), 
    .write_data(write_data), 
    .data_addr(data_addr), 
    .data_out(gdp_result), 
    .gdp_done(gdp_done)
    );

// Storage interface (SRAM etc)


endmodule
