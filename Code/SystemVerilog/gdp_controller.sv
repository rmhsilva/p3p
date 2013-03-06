typedef logic signed [15:0] num; // My number format

module gdp_controller #(parameter n_components = 25)
    (
    input logic clk, reset,

    input num x [n_components:0],
    input logic new_vector_available, // flag. data on x is new and valid

    input num mean, omega, k, // stats
    input logic new_stats_available, // flag. above data is new and valid
    output logic get_new_stats,

    output logic [7:0] senone_index, // index of senone currently scoring
    output num senone_score,
    output logic score_ready, // flag. data on senone_score is valid

    output logic gdp_idle // High when done processing
    );


// Basic purpose of this module: update the probabilities of ALL senones, given a new observation vector


// loop from start of senone data to end, feeding it into the pipeline.
// possible future extension - split this into two or more modules, ie have more than 1 GDP active.


// GDP connections
logic gdp_clk; // Need a special clock signal, as it must be slower :(
logic first_calc, last_calc;
num x_component;

// Other internals
logic [4:0] comp_index;

// State machine setup
typedef enum {IDLE, WAITNEW, WAIT2, LOADGDP} state_t;
state_t state, next;


always_ff@(posedge clk or posedge reset) begin : proc_main
    if(reset) begin
        state <= IDLE;
        comp_index <= 0;
        senone_index <= 0;
    end
    else begin
        state <= next;

        if (comp_index == 24) begin
            senone_index <= senone_index + 1;
            comp_index <= 0;
        end
        else if (state == LOADGDP) comp_index <= comp_index + 1;
        else if (state == IDLE) comp_index <= 0;
    end
end

always_comb begin : proc_maincomb
    case (state)
        IDLE: if (new_vector_available) begin
            next = WAITNEW;
            get_new_stats = 0;
        end
        WAITNEW: if (new_stats_available) begin
            next = LOADGDP;
            get_new_stats = 1;
        end

        LOADGDP: begin
            next = new_stats_available? LOADGDP : WAITNEW;
            
            get_new_stats = 1;
        end

        default: next = state;
    endcase
end : proc_maincomb

// GDP_clk must change with the actual clock
assign gdp_clk = clk & (state==LOADGDP);


// Instantiate modules
gdp gdpipe(.clk(gdp_clk), .reset(reset), .first_calc(first_calc), .last_calc(last_calc),
                .x(x_component), .k(k), .omega(omega), .mean(mean), .ln_p(senone_score), .data_ready(score_ready));

endmodule
