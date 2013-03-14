// Senone struct

module s_data_rom #(parameter n_components = 25)
	(senone, senone_index);

typedef struct packed {
  num k;
  num [n_components-1:0] omegas;
  num [n_components-1:0] means;
} senone_data;

output senone_data senone;
input logic [4:0] senone_index;

always @(senone_index) begin
	case (senone_index)
  		0: senone = '{16'h17C5, {16'h0011, 16'h0010, 16'h0014, 16'h002B}, {16'hFADD, 16'hF9E4, 16'h0EF7, 16'h17A3}};
		1: senone = '{16'h1838, {16'h000E, 16'h001B, 16'h000F, 16'h0025}, {16'hF859, 16'h0766, 16'hFC93, 16'h10FC}};
  		2: senone = '{16'h1515, {16'h000B, 16'h0011, 16'h0011, 16'h001E}, {16'hFAC1, 16'h051F, 16'hF006, 16'hFFE9}};
  		
     	default: senone = 'b0;
     endcase
end

endmodule