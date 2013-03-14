// baudgen.sv - Module to generate a 115200 baud tick for UART

module baudgen(
  input logic clk, enable,
  output logic baud_normal, baud_fast
  );

// 50MHz / 115.2kHz = 434.027
// With a 16 bit number, max value = 65536
// 65536 / 151 = 434.013 which is VERY close to 434.027
// Thus use this as the baud tick generator!

// Use 151 * 4 if using slowed clock 
parameter add = 'd151;
//parameter add = 'd151*8;

// Accumulator
reg [16:0] baud_acc = 0;
reg [13:0] baud_acc_fast = 0;

// Add every tick
always_ff @(posedge clk) begin
  baud_acc <= add + baud_acc[15:0];
  baud_acc_fast <= add + baud_acc_fast[12:0];
end

assign baud_normal = enable? baud_acc[16] : 'bZ;
assign baud_fast = enable? baud_acc_fast[13] : 'bZ;

endmodule