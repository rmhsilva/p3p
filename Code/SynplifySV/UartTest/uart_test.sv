module uart_test(
	input logic clk, reset, rx, new_vector_incoming, 
	output logic tx, tx_ready, rx_available, status_led
	);

// This should be the full uart system

logic send_data;
num tx_nums [0:0];
num rx_nums [3:0];
logic [2:0] index;

always_ff @(posedge clk or posedge reset) begin
	if (reset) begin
		status_led <= 0;
		index <= 0;
		send_data <= 1;
		tx_nums <= 'h1234;
	end
	else if (rx_available) begin
		tx_nums <= rx_nums[index];
		index <= index + 1;
		send_data <= 1;
		status_led <= 1;
	end
	else send_data <= 0;
end


uart #(.n_tx_nums(1), .n_rx_nums(4)) serial (.*);


// This test just echo's back what you give it
//
//logic baudtick, baudtick8, start_tx;
//logic [7:0] tx_data;
//logic [7:0] rx_data;
//
//baudgen ticker (.enable(1'b1), .baud_normal(baudtick), .baud_fast(baudtick8), .clk);
//uart_tx sender (.*);
//uart_rx rec (.rx_idle(), .*);
//
//always_ff @(posedge clk or posedge reset) begin
//	if (reset) begin
//		status_led <= 0;
//		start_tx <= 1;
//		tx_data <= 8'hAB;
//	end
//	else if (rx_available) begin
//		start_tx <= 1;
//		tx_data <= rx_data + 1;
//	end
//	else start_tx <= 0;
//end


endmodule