library verilog;
use verilog.vl_types.all;
entity max is
    port(
        clk             : in     vl_logic;
        reset           : in     vl_logic;
        new_vector_available: in     vl_logic;
        new_senone      : in     vl_logic;
        last_senone     : in     vl_logic;
        current_score   : in     vl_logic_vector(15 downto 0);
        best_score      : out    vl_logic_vector(15 downto 0);
        max_done        : out    vl_logic
    );
end max;
