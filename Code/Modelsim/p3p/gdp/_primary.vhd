library verilog;
use verilog.vl_types.all;
entity gdp is
    generic(
        length          : integer := 4;
        decimal_position: integer := 11;
        k_shift         : integer := 2;
        res_shift       : integer := 3
    );
    port(
        clk             : in     vl_logic;
        reset           : in     vl_logic;
        first_calc      : in     vl_logic;
        last_calc       : in     vl_logic;
        data_ready      : out    vl_logic;
        x               : in     vl_logic_vector(15 downto 0);
        k               : in     vl_logic_vector(15 downto 0);
        omega           : in     vl_logic_vector(15 downto 0);
        mean            : in     vl_logic_vector(15 downto 0);
        ln_p            : out    vl_logic_vector(15 downto 0)
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of length : constant is 1;
    attribute mti_svvh_generic_type of decimal_position : constant is 1;
    attribute mti_svvh_generic_type of k_shift : constant is 1;
    attribute mti_svvh_generic_type of res_shift : constant is 1;
end gdp;
