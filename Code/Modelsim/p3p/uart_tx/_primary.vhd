library verilog;
use verilog.vl_types.all;
entity uart_tx is
    port(
        clk             : in     vl_logic;
        reset           : in     vl_logic;
        start_tx        : in     vl_logic;
        baudtick        : in     vl_logic;
        tx_data         : in     vl_logic_vector(7 downto 0);
        tx              : out    vl_logic;
        tx_ready        : out    vl_logic
    );
end uart_tx;
