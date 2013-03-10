`timescale 1ns / 1ps
// Testbench for GDP

typedef logic signed [15:0] num; // My number format

module test_gdp_controller();
  
parameter n_components=5, n_senones=10;

// Signals
logic reset, clk;
logic new_vector_available;
num x [n_components-1:0];
logic [7:0] senone_idx;
num senone_score;
logic score_ready;
logic gdp_idle;

// connect module
gdp_controller #(.n_components(n_components), .n_senones(n_senones)) gdp_c (.*);


// Clock function
initial begin
  clk = 0;
  forever #5ns clk = ~clk;
end

// Properties to be fullfilled


// Set signals
initial begin
  reset = 1;
  new_vector_available = 0;

  #20ns;
  reset = 0;
  new_vector_available = 1'b1;
  x = { 16'hF6A5, 16'hFEDA, 16'hFD3C, 16'h00C1, 16'hDABE };

  #10ns new_vector_available = 0;
  #90ns; // Wait for output


  assert (score_ready == 1'b1);
  assert (senone_score[15:6] == 10'b0001001011)
    else $display("Error in score for ST_ey_4_47!");

  #25ns assert (score_ready == 1'b0) else $display("score_ready not low!");
  #25ns;
  assert (score_ready == 1'b1) else $display("score_ready not high!");
  assert (senone_score[15:6] == 10'b0001010010)
    else $display("Error in score for ST_r_4_108!");

  #25ns assert (score_ready == 1'b0) else $display("score_ready not low!");
  #25ns;
  assert (score_ready == 1'b1) else $display("score_ready not high!");
  assert (senone_score[15:6] == 10'b0001001110)
    else $display("Error in score for ST_ae_4_18!");

  #25ns assert (score_ready == 1'b0) else $display("score_ready not low!");
  #25ns;
  assert (score_ready == 1'b1) else $display("score_ready not high!");
  assert (senone_score[15:6] == 10'b0001001000)
    else $display("Error in score for ST_v_2_28!");

  #25ns assert (score_ready == 1'b0) else $display("score_ready not low!");
  #25ns;
  assert (score_ready == 1'b1) else $display("score_ready not high!");
  assert (senone_score[15:6] == 10'b0001011111)
    else $display("Error in score for ST_ax_3_22!");

  #25ns assert (score_ready == 1'b0) else $display("score_ready not low!");
  #25ns;
  assert (score_ready == 1'b1) else $display("score_ready not high!");
  assert (senone_score[15:6] == 10'b0000101111)
    else $display("Error in score for ST_l_3_110!");

  #25ns assert (score_ready == 1'b0) else $display("score_ready not low!");
  #25ns;
  assert (score_ready == 1'b1) else $display("score_ready not high!");
  assert (senone_score[15:6] == 10'b0001000000)
    else $display("Error in score for ST_ey_4_46!");

  #25ns assert (score_ready == 1'b0) else $display("score_ready not low!");
  #25ns;
  assert (score_ready == 1'b1) else $display("score_ready not high!");
  assert (senone_score[15:6] == 10'b0001010111)
    else $display("Error in score for ST_ah_3_68!");

  #25ns assert (score_ready == 1'b0) else $display("score_ready not low!");
  #25ns;
  assert (score_ready == 1'b1) else $display("score_ready not high!");
  assert (senone_score[15:6] == 10'b0001010011)
    else $display("Error in score for ST_r_4_107!");

  #25ns assert (score_ready == 1'b0) else $display("score_ready not low!");
  #25ns;
  assert (score_ready == 1'b1) else $display("score_ready not high!");
  assert (senone_score[15:6] == 10'b0001010011)
    else $display("Error in score for ST_ae_4_17!");

  #25ns assert (score_ready == 1'b0) else $display("score_ready not low!");
  #25ns;

end

endmodule

