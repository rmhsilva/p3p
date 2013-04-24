library verilog;
use verilog.vl_types.all;
entity sram_model is
    port(
        cs              : in     vl_logic;
        we              : in     vl_logic;
        oe              : in     vl_logic;
        addr            : in     vl_logic_vector(20 downto 0);
        data            : inout  vl_logic_vector(7 downto 0)
    );
end sram_model;
