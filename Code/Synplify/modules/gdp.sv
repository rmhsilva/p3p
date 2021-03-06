typedef logic signed [15:0] num; // My number format

module gdp(
  input logic clk, reset, first_calc, last_calc,
  output logic data_ready,

  input num x, k, omega, mean,
  output num ln_p
  );

parameter length = 4;             // length of the pipeline
parameter decimal_position = 11;  // Position of D.P. in my number sys
parameter k_shift = 2;            // amount K is shifted by
parameter res_shift = 3;          // amount result is shifted

// Internal signals
logic [2:0] first_calc_r; // shift registers for first/last calc indicators
logic [3:0] last_calc_r;

logic signed [16:0] sub_out;
logic signed [31:0] square_out, scale_out, acc_sum, result;
num omega_r [1:0];
num k_r [3:0];


// Main process to shift things along
always_ff@(posedge clk or posedge reset) begin : proc_main
  if(reset) begin
    sub_out <= 0;
    square_out <= 0;
    scale_out <= 0;
    acc_sum <= 0;
    result <= 0;
    data_ready <= 0;
    last_calc_r <=  {1'b0, 1'b0, 1'b0, 1'b0};
    first_calc_r <= {1'b0, 1'b0, 1'b0};
    omega_r <= {16'h0000, 16'h0000};
    k_r <= {16'h0000,16'h0000,16'h0000,16'h0000};
  end
  else begin
    first_calc_r <= {first_calc_r[1:0], first_calc};
    last_calc_r <= {last_calc_r[2:0], last_calc};
    k_r[0] <= k;
    k_r[1] <= k_r[0];
    k_r[2] <= k_r[1];
    k_r[3] <= k_r[2];
    omega_r[0] <= omega;
    omega_r[1] <= omega_r[0];

    // Pipeline calculations
    sub_out <= x - mean;
    square_out <= (sub_out * sub_out)>>>decimal_position-1;
    scale_out <= (square_out * omega_r[1])>>>decimal_position-1;
    acc_sum <= (first_calc_r[2])? (0+scale_out) : (acc_sum+scale_out);

    // Calc result and set output!
    result <= ((k_r[3]<<<k_shift) - acc_sum)>>>res_shift;
    data_ready <= last_calc_r[3];
  end
end

// Output 16 bit slice of result!
assign ln_p = {result[31], result[14:0]};


endmodule