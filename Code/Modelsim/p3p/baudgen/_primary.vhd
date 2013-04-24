library verilog;
use verilog.vl_types.all;
entity baudgen is
    generic(
        add             : integer := 151
    );
    port(
        clk             : in     vl_logic;
        enable          : in     vl_logic;
        baud_normal     : out    vl_logic;
        baud_fast       : out    vl_logic
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of add : constant is 1;
end baudgen;
