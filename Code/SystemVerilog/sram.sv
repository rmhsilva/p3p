typedef logic signed [15:0] num; // My number format

module sram (
  input logic clk, reset,
  input logic [20:0] data_addr,
  output logic sram_ready,      // indicates finished reading or writing
  output logic sram_idle,       // indicates no operation currently in process

  input logic write_data,
  input num data_in,

  input logic read_data,
  output num data_out,

  // Actual RAM connections
  inout [7:0] sram_data,
	output logic [20:0] sram_addr,
	output logic sram_ce, sram_we, sram_oe
  );

// State machine things
typedef enum {IDLE, WRITE1, WRITE2, READ1, READ2} state_t;
state_t state;

// Buffers to store data as it's being processed
num buffer;
logic [20:0] address;
reg [7:0] sram_data_reg;

always_ff @(posedge clk or posedge reset) begin
  if(reset) begin
    state <= IDLE;
	end
	else begin
	  unique case (state)
	    IDLE: if (write_data | read_data) begin
	            address <= data_addr;

	            if (write_data) begin
	              state <= WRITE1;
	              //buffer <= data_in;
	            end
	            else if (read_data) state <= READ1;
      	     end

	    WRITE1: state <= WRITE2;
	    WRITE2: state <= IDLE;

	    READ1: begin
	      state <= READ2;
	      //buffer[7:0] <= sram_data;
	    end
	    READ2: begin
	      state <= IDLE;
	      //buffer[15:8] <= sram_data;
	    end
	  endcase
	end
end

always_comb begin
  unique case (state)
    IDLE: begin
		  sram_we = 1;
		  sram_oe = 1;
      if (write_data) buffer = data_in;
		end
    WRITE1, WRITE2: begin
		  sram_we = 0;
		  sram_oe = 1;
		  sram_data_reg = (state==WRITE1)? buffer[7:0] : buffer[15:8];
		  sram_addr = (state==WRITE1)? address : address+1;
    end
    READ1, READ2: begin
		  sram_we = 1;
		  sram_oe = 0;
      buffer[7:0] = (state==READ1)? sram_data : buffer[7:0];
      buffer[15:8]= (state==READ2)? sram_data : buffer[15:8];
		  sram_addr = (state==READ1)? address : address+1;
    end
  endcase
end

// Assign outputs!
assign sram_ce = (state==IDLE)? 1'b1 : 1'b0;
assign sram_data = (state==WRITE1 || state==WRITE2)? sram_data_reg : 'bZ;
assign data_out = buffer;
assign sram_ready = (state==READ2) || (state==WRITE2);
assign sram_idle = (state==IDLE);

endmodule
