module uart_tx
  (
  input logic clk, reset, start_tx, baudtick,
  input logic [7:0] tx_data,
  output logic tx, tx_ready
  );

// UART transmit module - sends a single byte down the wire.

// Register the incoming data
logic [7:0] tx_data_reg;
always_ff @(posedge clk)
  if (tx_ready & start_tx) tx_data_reg <= tx_data;

// Transmitter state
logic [3:0] state;
assign tx_ready = (state==0);

// Logic - only change state on the baud tick event
always_ff @(posedge clk)
  if (reset)
    state <= 4'b0;
  else
  	case(state)
  		4'b0000: if(start_tx) state <= 4'b0001;
  		4'b0001: if(baudtick) state <= 4'b0100;
  		4'b0100: if(baudtick) state <= 4'b1000;  // start
  		4'b1000: if(baudtick) state <= 4'b1001;  // bit 0
  		4'b1001: if(baudtick) state <= 4'b1010;  // bit 1
  		4'b1010: if(baudtick) state <= 4'b1011;  // bit 2
  		4'b1011: if(baudtick) state <= 4'b1100;  // bit 3
  		4'b1100: if(baudtick) state <= 4'b1101;  // bit 4
  		4'b1101: if(baudtick) state <= 4'b1110;  // bit 5
  		4'b1110: if(baudtick) state <= 4'b1111;  // bit 6
  		4'b1111: if(baudtick) state <= 4'b0010;  // bit 7
  		4'b0010: if(baudtick) state <= 4'b0000;  // A single stop bit
  		default: if(baudtick) state <= 4'b0000;
  	endcase

// Output bit - takes data depending on state
logic output_bit;
assign output_bit = tx_data_reg[state[2:0]];

// Determine tx value
always_ff @(posedge clk)
  tx <= (state<4) | (state[3] & output_bit);

endmodule