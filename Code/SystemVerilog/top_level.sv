typedef logic signed [15:0] num; // My number format

module top_level (
	input logic clk50M,	reset,	// clk50M: (P60) 50MHz onboard clock
	output logic status_led,	// (P31) onboard status LED

	// Data uart:
	output logic uart_tx,		//  -> pin 2, bank 2 of L'Imperatrice
	input logic uart_rx,		//  -> pin 3, bank 2 of L'Imperatrice

	// L'Imperatrice Debug uart re-route:
	input logic duart_rx_in,	//  -> FTDI TX pin
	input logic duart_tx_in,	//  -> pin 1, bank 2 of L'Imperatrice
	output logic duart_rx_out,	//  -> pin 0, bank 2 of L'Imperatrice
	output logic duart_tx_out,	//  -> FTDI RX pin

	// Onboard SRAM signals:
	inout [7:0] sram_data,
	output logic [20:0] sram_addr,
	output logic sram_ce, sram_we, sram_oe
	);

parameter n_components = 5;
parameter n_senones = 10;
parameter n_tx_nums = 1;



/*****[ Internal signals and wires ]***************************************/

// Counter for flashing LED thing
logic [25:0] status_cnt = 0;


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

// Other signals
logic norm_done, send_done;


// UART signals
logic rx_available, tx_ready, start_tx;
num tx_buffer [n_tx_nums-1:0];
num rx_buffer [n_components-1:0];


// State machine setup
typedef enum {IDLE, PROC, NORM, SEND} state_t;
state_t state, next;


/***************************************************************************/
/*****[ Main Operations ]***************************************************/

// Main state machine
always_ff@(posedge clk50M or posedge reset) begin : proc_mainFF
    if (reset) begin
      state <= IDLE;
    end begin
      state <= next;
    end
end

always_comb begin : proc_maincomb
  if (reset) begin
    next = IDLE;
  end
  else begin
    unique case (state)
        IDLE: begin
          //IDLE: if (rx_available) next = PROC;
          if (duart_rx_in) next = PROC;   // TESTING. replace with above
          //new_vector_available = 
        end
        PROC: begin
          if (last_senone) next = NORM;
            
          if (score_ready) begin
            // write to SRAM
            write_data <= 1;
            data_addr <= senone_idx<<1;
            data_in <= senone_score;
          end
        end
        NORM: if (norm_done) next = SEND;
        SEND: if (send_done) next = IDLE;
        default: next = IDLE;
    endcase
  end
end : proc_maincomb


// TESTING:
assign new_vector_available = duart_rx_in;
assign x = { 16'hF6A5, 16'hFEDA, 16'hFD3C, 16'h00C1, 16'hDABE }; // normally = rx_buffer


// Simple flashing LED to indicate operation.
always @(posedge clk50M) begin
    status_cnt <= status_cnt + 1;
end
// Assign the status LED to different values depending on operation
always_comb begin : proc_statusLED
    unique case (state)
        IDLE: status_led = 1'b1;
        PROC: status_led = status_cnt[25];
        NORM: status_led = status_cnt[24];
        SEND: status_led = status_cnt[23];
        default: status_led = 1'b0;
    endcase
end : proc_statusLED

// Reroute the ARM chip Debug UART serial port
assign {duart_rx_out,duart_tx_out} = {duart_rx_in,duart_tx_in};



/*****[ Connect Modules up ]*************************************************/

// Serial connection to L'Imperatrice
uart #(.n_tx_nums(n_tx_nums), .n_rx_nums(n_components)) data_uart
        (.clk(clk50M), .reset, .rx(uart_rx), .tx(uart_tx), .send_data(start_tx), .rx_available, 
        .tx_ready, .tx_nums(tx_buffer), .rx_nums(rx_buffer));

// GDP controller
gdp_controller #(.n_components(n_components), .n_senones(n_senones)) gdp_c
                 (.clk(clk50M), .*);

// Maximiser unit
max maximiser(.clk(clk50M), .new_senone(score_ready), .current_score(senone_score), .*);

// Normaliser unit


endmodule