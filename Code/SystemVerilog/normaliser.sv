typedef logic signed [15:0] num; // My number format

module normaliser (
	input logic clk, reset, new_senone, last_senone,
	input num best_score,
	input num score,
	output num score_norm,
    output logic norm_done
	);

// This module takes in a best score, and normalises scores to it
// score_norm = best_score - score_norm


endmodule