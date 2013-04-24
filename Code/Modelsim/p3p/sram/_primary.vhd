library verilog;
use verilog.vl_types.all;
entity sram is
    port(
        clk             : in     vl_logic;
        reset           : in     vl_logic;
        data_addr       : in     vl_logic_vector(20 downto 0);
        sram_ready      : out    vl_logic;
        sram_idle       : out    vl_logic;
        write_data      : in     vl_logic;
        data_in         : in     vl_logic_vector(15 downto 0);
        read_data       : in     vl_logic;
        data_out        : out    vl_logic_vector(15 downto 0);
        sram_data       : inout  vl_logic_vector(7 downto 0);
        sram_addr       : out    vl_logic_vector(20 downto 0);
        sram_ce         : out    vl_logic;
        sram_we         : out    vl_logic;
        sram_oe         : out    vl_logic
    );
end sram;
