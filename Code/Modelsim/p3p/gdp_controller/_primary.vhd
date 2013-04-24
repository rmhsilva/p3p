library verilog;
use verilog.vl_types.all;
entity gdp_controller is
    generic(
        n_components    : integer := 5;
        n_senones       : integer := 10
    );
    port(
        clk             : in     vl_logic;
        reset           : in     vl_logic;
        x               : in     vl_logic;
        new_vector_available: in     vl_logic;
        senone_idx      : out    vl_logic_vector(7 downto 0);
        senone_score    : out    vl_logic_vector(15 downto 0);
        score_ready     : out    vl_logic;
        last_senone     : out    vl_logic;
        gdp_idle        : out    vl_logic
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of n_components : constant is 1;
    attribute mti_svvh_generic_type of n_senones : constant is 1;
end gdp_controller;
