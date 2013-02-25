`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:38:36 02/17/2013 
// Design Name: 
// Module Name:    uart 
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

// TODO: refactor code, using diff variable names (no RxD etc..)
module uart
	#( parameter n_tx_bytes = 2,		// Number of bytes that can be queued for tx
		parameter n_rx_bytes = 2*25)	// Number of bytes that should be received in a packet
	(
	 input clk,
    input rx,
    output tx,
	 
	 input send_data,  						// Send data in tx_bytes (flag)
	 input [(n_tx_bytes*8)-1:0] tx_bits,
	 output tx_ready,							// Ready for new tx (flag)
	 
	 output rx_available,					// New data received (flag)
	 output [(n_rx_bytes*8)-1:0] rx_bits
   );

integer i;	// loop var

// Original test:
//wire RxD_data_ready;
//wire RxD_endofpacket;
//wire [7:0] RxD_data;
//
//reg [7:0] Buf;
//reg tx_ready = 1'b0;
//always @(posedge clk)
//	if(RxD_data_ready) begin
//		Buf <= RxD_data;
//		tx_ready <= 1'b1;
//	end
//	else
//		tx_ready <= 1'b0;
//		
//assign led = Buf[0];

// TX process
reg [7:0] tx_buffer [0:n_tx_bytes];
reg [7:0] tx_byte;
reg start_tx = 0;
integer tx_index = n_tx_bytes;		// Used to index tx_buffer

always @(posedge clk) begin
	if (tx_index < n_tx_bytes) begin		// go from index 1 -> n_tx_bytes
		start_tx <= 1'b1;
		tx_byte	<= tx_buffer[tx_index];
		tx_index <= tx_index + 1;
	end
	else if (send_data) begin
		for (i=0; i<n_tx_bytes; i=i+1) tx_buffer[i] = tx_bits[i*8 +: 8];
		tx_index 	<= 1;
		start_tx 	<= 1'b1;
		tx_byte		<= tx_bits[7:0];	// tx lowest byte first.
	end
	else start_tx <= 1'b0;
end

assign tx_ready = ~start_tx;	// tx_ready: high when not tx'ing anymore


// RX process
reg [7:0] rx_buffer [0:n_rx_bytes];
wire RxD_data_ready;
wire RxD_endofpacket;
wire [7:0] RxD_data;
integer rx_index = 0;

always @(posedge clk) begin
	if (RxD_data_ready) begin
		rx_buffer[rx_index] <= RxD_data;
		rx_index <= rx_index + 1;
	end
	else if (RxD_endofpacket) rx_index <= 0;
end

// rx_available high for 1 clock cycle when no more data rec'd
assign rx_available = RxD_endofpacket;

// Flatten the RX bits... 
genvar j;
generate
for(j=0; j<n_rx_bytes; j=j+1) begin : assign_rx
	assign rx_bits[j*8 +: 8] = rx_buffer[j];
end
endgenerate


// Module instantiations
async_transmitter serializer(.clk(clk), .TxD(tx), .TxD_start(start_tx), .TxD_data(tx_byte));
async_receiver deserializer(.clk(clk), .RxD(rx), .RxD_data_ready(RxD_data_ready), .RxD_data(RxD_data), .RxD_endofpacket(RxD_endofpacket));

endmodule
