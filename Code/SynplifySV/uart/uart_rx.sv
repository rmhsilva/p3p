// UART receive module - receives bytes down the wire.

module uart_rx
  (
  input logic clk, reset, baudtick8, rx,
  output logic [7:0] rx_data,
  output logic rx_available, rx_idle
  );

//logic baudtick8;  // Use a clock at 8 times the real baud

// Baud generator
//baudgen ticker (.clk, .enable(1'b1), .baud_normal(), .baud_fast(baudtick8));


// Shift register to sync RX to our clock
// Use inverted rx to avoid detecting chars at startup
logic [1:0] rx_sync_inv;
always_ff @(posedge clk)
  if (baudtick8) rx_sync_inv <= {rx_sync_inv[0], ~rx};
    

// Filter RX to avoid detecting short start bits
logic [1:0] rx_count;
logic rx_bit_inv;

always_ff @(posedge clk or posedge reset)
  if (reset)
    rx_count <= 0;
  else
  if (baudtick8) begin
    if (rx_sync_inv[1] && rx_count!=2'b11) rx_count <= 1 + rx_count;
    else // Decrement count when rx is low
    if (~rx_sync_inv[1] && rx_count!=2'b00) rx_count <= -1 + rx_count;
  
    // rx must be low 3 clocks in sequence for a valid start bit
    if (rx_count==2'b00) rx_bit_inv <= 0;
    else
    if (rx_count==2'b11) rx_bit_inv <= 1;
  end

// Receiver state machine
logic [3:0] state;
logic next_bit;

always_ff @(posedge clk or posedge reset)
  if (reset)
    state <= 4'b0;
  else
  if (baudtick8)
  case(state)
    4'b0000: if(rx_bit_inv) state <= 4'b1000; // wait for start bit
    4'b1000: if(next_bit) state <= 4'b1001; // bit 0
    4'b1001: if(next_bit) state <= 4'b1010; // bit 1
    4'b1010: if(next_bit) state <= 4'b1011; // bit 2
    4'b1011: if(next_bit) state <= 4'b1100; // bit 3
    4'b1100: if(next_bit) state <= 4'b1101; // bit 4
    4'b1101: if(next_bit) state <= 4'b1110; // bit 5
    4'b1110: if(next_bit) state <= 4'b1111; // bit 6
    4'b1111: if(next_bit) state <= 4'b0001; // bit 7
    4'b0001: if(next_bit) state <= 4'b0000; // stop bit
    default: state <= 4'b0000;
  endcase
  
// Using a next_bit to advance a bit once every 8 baud ticks
logic [3:0] os_count;  // (oversample counter)
assign next_bit = (os_count==4'd10);

always_ff @(posedge clk)
  if (state==0)
    os_count <= 'b0;
  else
  if (baudtick8)
    os_count <= {os_count[2:0] + 4'b0001} | {os_count[3], 3'b000};


// Finally, buffer rx
always_ff @(posedge clk)
  if (baudtick8 && next_bit && state[3]) rx_data <= {~rx_bit_inv, rx_data[7:1]};
    
    
// Extra: flag when at end of byte and going idle
always_ff @(posedge clk) begin
	rx_available <= (baudtick8 && next_bit && state==4'b0001 && ~rx_bit_inv);  // Require valid stop bit
end

logic [4:0] gap_cnt;
assign rx_idle = gap_cnt[4];

always_ff @(posedge clk)
  if (state!=0) gap_cnt <= 5'h00;
  else if(baudtick8 & ~gap_cnt[4]) gap_cnt <= gap_cnt + 5'h01;

endmodule