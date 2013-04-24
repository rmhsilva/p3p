library verilog;
use verilog.vl_types.all;
entity uart is
    generic(
        n_tx_nums       : integer := 1;
        n_rx_nums       : integer := 25
    );
    port(
        clk             : in     vl_logic;
        reset           : in     vl_logic;
        rx              : in     vl_logic;
        tx              : out    vl_logic;
        new_vector_incoming: in     vl_logic;
        send_data       : in     vl_logic;
        tx_nums         : in     vl_logic;
        tx_ready        : out    vl_logic;
        rx_available    : out    vl_logic;
        rx_nums         : out    vl_logic
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of n_tx_nums : constant is 1;
    attribute mti_svvh_generic_type of n_rx_nums : constant is 1;
end uart;
