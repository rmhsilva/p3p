library verilog;
use verilog.vl_types.all;
entity uart_rx is
    port(
        clk             : in     vl_logic;
        reset           : in     vl_logic;
        baudtick8       : in     vl_logic;
        rx              : in     vl_logic;
        rx_data         : out    vl_logic_vector(7 downto 0);
        rx_available    : out    vl_logic;
        rx_idle         : out    vl_logic
    );
end uart_rx;
