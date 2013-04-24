// Uncomment the typedef for Modelsim compilation
//typedef logic signed [15:0] num;

module max (
	input logic clk, reset, 
	input logic new_vector_available, new_senone, last_senone,
	input num current_score,
	output num best_score,
	output logic max_done
	);

// This module takes in scores, and finds the maximum. Simple!

always_ff@(posedge clk or posedge reset) begin : proc_main
	if(reset | new_vector_available) begin
		best_score <= 16'h8000;	// Max <= -1 * 0xEFFF;
	end 
	else if (new_senone) begin
		if (current_score > best_score)
			best_score <= current_score;

    max_done <= last_senone;
	end
end

endmodule