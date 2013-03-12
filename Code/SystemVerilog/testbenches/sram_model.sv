// SRAM Model. Note: only the first 8 bytes are available right now...

module sram_model (
  input logic cs, we, oe,   // Signals
  input logic [20:0] addr,  // Address bus
  inout [7:0] data          // Data bus (bi-dir)
  );

// Memory instantiation
//logic [7:0] memory [0:19] = {
//  8'h12, 8'h34,
//  8'h56, 8'h78,
//  8'h9A, 8'hA1,
//  8'hAB, 8'h12,
//  8'h55, 8'hAA,
//  8'h12, 8'h34,
//  8'h56, 8'h78,
//  8'h9A, 8'hA1,
//  8'hAB, 8'h12,
//  8'h55, 8'hAA
//};
logic [7:0] memory [0:31] = '{32{8'h55}};

// Read process
assign data = (~cs & ~oe)? memory[addr[4:0]] : {8{1'bz}};

// Write process
always_latch
  if (~cs & ~we)
    memory[addr[4:0]] = data;

// Make sure write and read not both requested...
always_comb
  assert(!(~we && ~oe));

endmodule