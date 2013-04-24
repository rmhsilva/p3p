library verilog;
use verilog.vl_types.all;
entity normaliser is
    generic(
        n_senones       : integer := 10
    );
    port(
        clk             : in     vl_logic;
        reset           : in     vl_logic;
        start_norm      : in     vl_logic;
        do_norm         : in     vl_logic;
        best_score      : in     vl_logic_vector(15 downto 0);
        sram_ready      : in     vl_logic;
        sram_idle       : in     vl_logic;
        data_addr       : out    vl_logic_vector(20 downto 0);
        write_data      : out    vl_logic;
        data_out        : out    vl_logic_vector(15 downto 0);
        read_data       : out    vl_logic;
        data_in         : in     vl_logic_vector(15 downto 0);
        norm_done       : out    vl_logic
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of n_senones : constant is 1;
end normaliser;
