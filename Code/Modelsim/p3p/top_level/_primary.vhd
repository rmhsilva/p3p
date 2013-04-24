library verilog;
use verilog.vl_types.all;
entity top_level is
    generic(
        n_components    : integer := 6;
        n_senones       : integer := 5;
        n_tx_nums       : integer := 1
    );
    port(
        clk             : in     vl_logic;
        reset           : in     vl_logic;
        status_led      : out    vl_logic;
        LRADC0_fix      : out    vl_logic;
        uart_tx         : out    vl_logic;
        uart_rx         : in     vl_logic;
        new_vector_incoming: in     vl_logic;
        duart_rx_in     : in     vl_logic;
        duart_tx_in     : in     vl_logic;
        duart_rx_out    : out    vl_logic;
        duart_tx_out    : out    vl_logic;
        sram_data       : inout  vl_logic_vector(7 downto 0);
        sram_addr       : out    vl_logic_vector(20 downto 0);
        sram_ce         : out    vl_logic;
        sram_we         : out    vl_logic;
        sram_oe         : out    vl_logic
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of n_components : constant is 1;
    attribute mti_svvh_generic_type of n_senones : constant is 1;
    attribute mti_svvh_generic_type of n_tx_nums : constant is 1;
end top_level;
