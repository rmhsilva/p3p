typedef logic signed [15:0] num; // My number format

module gdp_controller #(parameter n_components=5, n_senones=10)
    (
    input logic clk, reset,

    input num x [n_components-1:0],
    input logic new_vector_available, // flag. data on x is new and valid

    output logic [7:0] senone_idx, // index of senone currently scoring
    output num senone_score,
    output logic score_ready, // flag. data on senone_score is valid
    output logic last_senone, // flag. this is the final senone

    output logic gdp_idle // High when done processing
    );


// Basic purpose of this module: update the probabilities of ALL senones, given a new observation vector
// possible future extension - split this into two or more modules, ie have more than 1 GDP active.

// Include the senone data file (contains senone_data struct too)
`include "all_s_data.sv";

// GDP connections
logic first_calc, last_calc;
num x_component, mean, omega, k;

// Other internals
num x_buf [n_components-1:0];
int comp_index;
int senone_index;             // Index of currently processed senone and component
int senone_idx_buffer [4:0];  // The score arrives after the index has changed. Use shift

// State machine setup
typedef enum {IDLE, WAITNEW, LOADGDP} state_t;
state_t state, next;


always_ff@(posedge clk or posedge reset) begin : proc_main
    if(reset) begin
        state <= IDLE;
        comp_index <= 0;
        senone_index <= 0;
    end
    else begin
        state <= next;
        senone_idx_buffer <= {senone_index, senone_idx_buffer[4:1]};

        // Do the counter logic
        if (state == IDLE) begin
          comp_index <= 0;
          senone_index <= 0;
        end
        else if (state == LOADGDP) begin
          if (comp_index == n_components-1) begin
            comp_index <= 0;
            if (senone_index == n_senones-1) begin
              senone_index <= 0;
              state <= IDLE;
            end
            else senone_index <= senone_index + 1;
          end
          else comp_index <= comp_index + 1;
        end

        //if (state == LOADGDP) $display(all_s_data[senone_index].omegas[comp_index]);
    end
end

always_comb begin : proc_maincomb
    case (state)
        IDLE: begin
            last_calc = 0;
            first_calc = 0;
            k = 0;
            omega = 0;
            mean = 0;
            x_component = 0;

            if (new_vector_available) begin
              next = LOADGDP;
              x_buf = x;  // Latch the x input data here
            end
            else next = IDLE;
          end

        LOADGDP: begin
            // Various signals
            if (comp_index==0) first_calc = 1'b1;
            else first_calc = 0;

            if (comp_index==n_components-1) last_calc = 1'b1;
            else last_calc = 0;

            // Assign data
            k             = all_s_data[senone_index].k;
            omega         = all_s_data[senone_index].omegas[comp_index];
            mean          = all_s_data[senone_index].means[comp_index];
            x_component   = x_buf[comp_index];
        end

        default: next = state;
    endcase
end : proc_maincomb

// GDP_clk must change with the actual clock, but only when we're loading the GDP
//assign gdp_clk = clk & (state==LOADGDP);

assign gdp_idle = (state==IDLE);
assign senone_idx = senone_idx_buffer[0];
assign last_senone = score_ready & (senone_idx == n_senones-1);


// Instantiate modules
gdp gdpipe(.clk, .reset, .first_calc, .last_calc,
          .x(x_component), .k, .omega, .mean, .ln_p(senone_score), .data_ready(score_ready));


endmodule
