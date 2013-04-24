// Uncomment the typedef for Modelsim compilation
//typedef logic signed [15:0] num;

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
    /* Senone 11 (ST_ow_3_83): */
    11: senone = '{ 16'hD5F7, // K
        {16'h0013, 16'h000A, 16'h000E, 16'h000F, 16'h0020, 16'h002E},  // omegas
        {16'hE0F4, 16'h0488, 16'h1182, 16'hF02F, 16'hF331, 16'h2640}}; // means
    /* Senone 10 (ST_v_2_27): */
    10: senone = '{ 16'hCF4E, // K
        {16'h000E, 16'h0013, 16'h000D, 16'h001C, 16'h0017, 16'h0030},  // omegas
        {16'hF6F2, 16'hE558, 16'hEC8A, 16'hF95C, 16'h052E, 16'h1D0B}}; // means
    /* Senone 9 (ST_ae_4_17): */
    9: senone = '{ 16'hD42B, // K
        {16'h000E, 16'h0015, 16'h0011, 16'h001E, 16'h001C, 16'h0022},  // omegas
        {16'h0710, 16'hFE98, 16'hF0B4, 16'h0110, 16'hE925, 16'hF0D9}}; // means
    /* Senone 8 (ST_r_4_107): */
    8: senone = '{ 16'hCCA6, // K
        {16'h000B, 16'h000A, 16'h000A, 16'h0013, 16'h000F, 16'h0027},  // omegas
        {16'h057D, 16'hE8AA, 16'hFB7C, 16'h0865, 16'h085F, 16'h190A}}; // means
    /* Senone 7 (ST_ah_3_68): */
    7: senone = '{ 16'hCDA9, // K
        {16'h000B, 16'h000C, 16'h0011, 16'h0015, 16'h001B, 16'h002A},  // omegas
        {16'hE340, 16'hF05F, 16'h14E3, 16'hEED8, 16'hEBD7, 16'h07BF}}; // means
    /* Senone 6 (ST_ey_4_46): */
    6: senone = '{ 16'hD02F, // K
        {16'h000C, 16'h0010, 16'h000A, 16'h0012, 16'h0014, 16'h0021},  // omegas
        {16'hDC01, 16'h01E8, 16'hFF5B, 16'hFA39, 16'h206F, 16'h2E0E}}; // means
    /* Senone 5 (ST_l_3_110): */
    5: senone = '{ 16'hCF70, // K
        {16'h0009, 16'h000A, 16'h000F, 16'h0009, 16'h0019, 16'h0027},  // omegas
        {16'hFC4C, 16'h1364, 16'h02F3, 16'hDE9B, 16'h0D2D, 16'h3E15}}; // means
    /* Senone 4 (ST_ax_3_22): */
    4: senone = '{ 16'hCB4C, // K
        {16'h000B, 16'h000B, 16'h0008, 16'h0011, 16'h000E, 16'h001C},  // omegas
        {16'hFDB4, 16'hE422, 16'hEED2, 16'hFCD3, 16'h0671, 16'h0E8E}}; // means
    /* Senone 3 (ST_v_2_28): */
    3: senone = '{ 16'hCF78, // K
        {16'h0011, 16'h0012, 16'h000D, 16'h001A, 16'h0016, 16'h002A},  // omegas
        {16'hE574, 16'hF111, 16'hF971, 16'h0956, 16'h0AE2, 16'h1E8A}}; // means
    /* Senone 2 (ST_ae_4_18): */
    2: senone = '{ 16'hD5D5, // K
        {16'h000A, 16'h000D, 16'h000B, 16'h0011, 16'h0011, 16'h001E},  // omegas
        {16'hF9CB, 16'h013B, 16'hFAC1, 16'h051F, 16'hF006, 16'hFFE9}}; // means
    /* Senone 1 (ST_r_4_108): */
    1: senone = '{ 16'hCF90, // K
        {16'h0008, 16'h0009, 16'h000E, 16'h001B, 16'h000F, 16'h0025},  // omegas
        {16'h0F35, 16'hF655, 16'hF859, 16'h0766, 16'hFC93, 16'h10FC}}; // means
    /* Senone 0 (ST_ey_4_47): */
    0: senone = '{ 16'hD075, // K
        {16'h000C, 16'h000F, 16'h0011, 16'h0010, 16'h0014, 16'h002B},  // omegas
        {16'hEBCB, 16'hFA2D, 16'hFADD, 16'hF9E4, 16'h0EF7, 16'h17A3}}; // means

    default: senone = 'b0;
  endcase
end

endmodule