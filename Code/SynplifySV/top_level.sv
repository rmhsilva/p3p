//typedef logic signed [15:0] num; // My number format

module top_level (
	input logic clk,	reset,	 // clk: (P60) 50MHz onboard clock
	output logic status_led,	// (P31) onboard status LED

	// Data uart:
	output logic uart_tx,		          //-> pin 2, bank 2 of L'Imperatrice
	input logic uart_rx,		           //-> pin 3, bank 2 of L'Imperatrice
	input logic new_vector_incoming, //-> pin 5, bank 2 of L'Imperatrice

	// L'Imperatrice Debug uart re-route:
	input logic duart_rx_in,	  //-> FTDI TX pin
	input logic duart_tx_in,	  //-> pin 1, bank 2 of L'Imperatrice
	output logic duart_rx_out,	//-> pin 0, bank 2 of L'Imperatrice
	output logic duart_tx_out,	//-> FTDI RX pin

	// Onboard SRAM signals:
	inout [7:0] sram_data,
	output logic [20:0] sram_addr,
	output logic sram_ce, sram_we, sram_oe,
	
	// Debug outputs
	output logic [2:0] state_output,
	output logic start_norm, start_send, norm_done, send_done,
	output logic [7:0] sram_data_debug,
	output logic [3:0] sram_addr_debug,
	output logic ce_db, we_db, oe_db
	);

parameter n_components = 3;
parameter n_senones = 2;
parameter n_tx_nums = 1;



/*****[ Internal signals and wires ]***************************************/

// Counter for flashing LED thing
logic [25:0] status_cnt;


// GDP controller Signals
logic new_vector_available;
num x [n_components-1:0];
logic [7:0] senone_idx;
num senone_score;
logic score_ready;
logic gdp_idle;
logic last_senone;

// Max unit signals
num best_score;
logic max_done;

// SRAM signals, and connections to normaliser and sender
logic sram_ready, sram_idle;
num sram_data_out;
logic read_sram,             norm_read_sram,  send_read_sram;
logic write_sram,            norm_write_sram, send_write_sram;
logic [20:0] sram_data_addr, norm_sram_addr,  send_sram_addr;
num sram_data_in,            norm_sram_data,  send_sram_data;

// Other control signals
//logic start_norm, start_send;
//logic norm_done, send_done;


// UART signals
logic rx_available, tx_ready, start_tx;
num tx_buffer [n_tx_nums-1:0];
num rx_buffer [n_components-1:0];


// State machine setup
typedef enum {IDLE, PROC, NORM, SEND} state_t;
state_t state;


/***************************************************************************/
/*****[ Main Operations ]***************************************************/


assign x = rx_buffer;
assign new_vector_available = rx_available;
// TESTING:
//assign new_vector_available = new_vector_incoming;
//assign x = { 16'hF6A5, 16'hFEDA, 16'hFD3C, 16'h00C1, 16'hDABE }; // normally = rx_buffer

// State machine
always_ff@(posedge clk or posedge reset) begin : proc_mainFF
    if (reset)
      state <= IDLE;
    else
      case (state)
        IDLE: begin
          if (rx_available) state <= PROC;
          //if (new_vector_incoming) state <= PROC;   // TESTING. replace with above
        end
        PROC: if (last_senone) state <= NORM;
        NORM: if (norm_done) state <= SEND;
        SEND: if (send_done) state <= IDLE;
        default: state <= IDLE;
      endcase
end

// Signal logic
always_comb begin : proc_outputlogic
  start_norm = ((state==NORM && ~norm_done) && (sram_idle | start_norm))? 1'b1 : 1'b0;
  start_send = ((state==SEND && ~send_done) && (sram_idle | start_send))? 1'b1 : 1'b0;
end : proc_outputlogic


// Assign SRAM signals only when required, to avoid contention
always_comb begin : proc_sram_signals
    unique
    if (state==PROC && score_ready) begin
      read_sram = 1'b0;
      write_sram = 1'b1;
      sram_data_addr = senone_idx<<1;
      sram_data_in   = senone_score;
    end
    else if (state==NORM) begin
      // Assign sram signals to normaliser outputs
      read_sram  = norm_read_sram;
      write_sram = norm_write_sram;
      sram_data_addr = norm_sram_addr;
      sram_data_in   = norm_sram_data;
    end
    else if (state==SEND) begin
      // And to send outputs
      read_sram  = send_read_sram;
      write_sram = send_write_sram;
      sram_data_addr = send_sram_addr;
      sram_data_in   = send_sram_data;
    end
    else begin
      read_sram  = 1'bz;
      write_sram = 1'bZ;
      sram_data_addr = 20'bZ;
      sram_data_in   = 16'bZ;
    end
end : proc_sram_signals


// Simple flashing LED to indicate operation.
always @(posedge clk or posedge reset) begin
  if (reset) status_cnt <= 0;
  else status_cnt <= 1 + status_cnt;
end
// Assign the status LED to different values depending on operation
always_comb begin : proc_statusLED
    case (state)
        IDLE: status_led = 1'b1;
        PROC: status_led = status_cnt[25];
        NORM: status_led = status_cnt[24];
        SEND: status_led = status_cnt[23];
        default: status_led = 1'b0;
    endcase
end : proc_statusLED

// Reroute the ARM chip Debug UART serial port
assign {duart_rx_out,duart_tx_out} = {duart_rx_in,duart_tx_in};

// Debug info on pins!
assign state_output = state;
always_comb begin
	sram_data_debug = sram_data;
	sram_addr_debug = sram_addr[3:0];
	ce_db = sram_ce;
	we_db = sram_we;
	oe_db = sram_oe;
	
	case (state)
		IDLE: state_output[1:0] = 2'b00;
		PROC: state_output[1:0] = 2'b01;
		NORM: state_output[1:0] = 2'b10;
		SEND: state_output[1:0] = 2'b11;
	endcase
end


/*****[ Connect Modules up ]*************************************************/

// Serial connection to L'Imperatrice
uart #(.n_tx_nums(n_tx_nums), .n_rx_nums(n_components)) data_uart
        ( .clk, .reset, .rx_available, .tx_ready, .new_vector_incoming,
          .rx(uart_rx),        .tx(uart_tx), .send_data(start_tx),
          .tx_nums(tx_buffer), .rx_nums(rx_buffer));

// GDP controller
gdp_controller #(.n_components(n_components), .n_senones(n_senones)) gdp_c
                  ( .clk, .reset, .x, .new_vector_available, .senone_idx,
                    .senone_score, .gdp_idle, .score_ready, .last_senone);

// Maximiser unit
max maximiser(.clk, .reset, .last_senone, .max_done, .best_score,
              .new_senone(score_ready), .current_score(senone_score) );

// Normaliser unit
normaliser #(.n_senones(n_senones)) norm
              ( .clk, .reset, .start_norm, .best_score, .sram_ready, .norm_done,
                .data_addr(norm_sram_addr), .write_data(norm_write_sram),
                .data_out(norm_sram_data),  .read_data(norm_read_sram),
                .data_in(sram_data_out) );

// Sender unit
send #(.n_senones(n_senones)) sender
        ( .clk, .reset, .start_send, .send_done, .sram_ready,
          .uart_ready(tx_ready),   .tx_value(tx_buffer[0]), .start_tx,
          .data_in(sram_data_out), .data_addr(send_sram_addr),
          .read_data(send_read_sram) );

// SRAM
sram ram_access(.sram_data, .sram_addr, .sram_ce, .sram_we, .sram_oe, .sram_idle,
                .clk, .reset, .sram_ready, .data_addr(sram_data_addr),
                .data_out(sram_data_out),  .write_data(write_sram),
                .data_in(sram_data_in),    .read_data(read_sram) );


endmodule