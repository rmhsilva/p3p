// SRAM Model

module sram_model (
  input logic cs, we, oe,   // Signals
  input logic [21:0] addr,  // Address bus
  inout [7:0] data          // Data bus (bi-dir)
  );

// Memory instantiation
logic [7:0] memory [0:1<<21] = {
  {((1<<21)-4){8'b0}},
  8'hABCD, 8'h1234,
  8'h55AA, 8'hAAFF
};

// Read process
assign data = (~cs & ~oe)? memory[addr] : {8{1'bz}};

// Write process
always_latch
  if (~cs & ~we)
    memory[addr] = data;

// Make sure write and read not both requested...
assert property (~we & ~oe) $display ("BAD: WE and OE both active in SRAM!");

endmodule