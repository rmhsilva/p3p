library verilog;
use verilog.vl_types.all;
entity test_gdp_controller is
    generic(
        n_components    : integer := 5;
        n_senones       : integer := 10
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of n_components : constant is 1;
    attribute mti_svvh_generic_type of n_senones : constant is 1;
end test_gdp_controller;
