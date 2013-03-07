// Senone struct
typedef struct {
  num k;
  num omegas [n_components-1:0];
  num means  [n_components-1:0];
} senone_data;

// All the senone data!
senone_data all_s_data [n_senones-1:0] = {
  // Senone 9 (ST_ae_4_17)
  { k:      16'h15EA,
    omegas: { 16'h0015, 16'h0011, 16'h001E, 16'h001C, 16'h0022 },
    means:  { 16'hFE98, 16'hF0B4, 16'h0110, 16'hE925, 16'hF0D9 }
  },
  // Senone 8 (ST_r_4_107)
  { k:      16'h19AD,
    omegas: { 16'h000A, 16'h000A, 16'h0013, 16'h000F, 16'h0027 },
    means:  { 16'hE8AA, 16'hFB7C, 16'h0865, 16'h085F, 16'h190A }
  },
  // Senone 7 (ST_ah_3_68)
  { k:      16'h192B,
    omegas: { 16'h000C, 16'h0011, 16'h0015, 16'h001B, 16'h002A },
    means:  { 16'hF05F, 16'h14E3, 16'hEED8, 16'hEBD7, 16'h07BF }
  },
  // Senone 6 (ST_ey_4_46)
  { k:      16'h17E8,
    omegas: { 16'h0010, 16'h000A, 16'h0012, 16'h0014, 16'h0021 },
    means:  { 16'h01E8, 16'hFF5B, 16'hFA39, 16'h206F, 16'h2E0E }
  },
  // Senone 5 (ST_l_3_110)
  { k:      16'h1848,
    omegas: { 16'h000A, 16'h000F, 16'h0009, 16'h0019, 16'h0027 },
    means:  { 16'h1364, 16'h02F3, 16'hDE9B, 16'h0D2D, 16'h3E15 }
  },
  // Senone 4 (ST_ax_3_22)
  { k:      16'h1A5A,
    omegas: { 16'h000B, 16'h0008, 16'h0011, 16'h000E, 16'h001C },
    means:  { 16'hE422, 16'hEED2, 16'hFCD3, 16'h0671, 16'h0E8E }
  },
  // Senone 3 (ST_v_2_28)
  { k:      16'h1844,
    omegas: { 16'h0012, 16'h000D, 16'h001A, 16'h0016, 16'h002A },
    means:  { 16'hF111, 16'hF971, 16'h0956, 16'h0AE2, 16'h1E8A }
  },
  // Senone 2 (ST_ae_4_18)
  { k:      16'h1515,
    omegas: { 16'h000D, 16'h000B, 16'h0011, 16'h0011, 16'h001E },
    means:  { 16'h013B, 16'hFAC1, 16'h051F, 16'hF006, 16'hFFE9 }
  },
  // Senone 1 (ST_r_4_108)
  { k:      16'h1838,
    omegas: { 16'h0009, 16'h000E, 16'h001B, 16'h000F, 16'h0025 },
    means:  { 16'hF655, 16'hF859, 16'h0766, 16'hFC93, 16'h10FC }
  },
  // Senone 0 (ST_ey_4_47)
  { k:      16'h17C5,
    omegas: { 16'h000F, 16'h0011, 16'h0010, 16'h0014, 16'h002B },
    means:  { 16'hFA2D, 16'hFADD, 16'hF9E4, 16'h0EF7, 16'h17A3 }
  }
};