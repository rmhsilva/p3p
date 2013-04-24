library verilog;
use verilog.vl_types.all;
entity s_data_rom is
    generic(
        n_components    : integer := 25
    );
    port(
        senone          : out    work.s_data_rom.senone_data;
        senone_index    : in     vl_logic_vector(4 downto 0)
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of n_components : constant is 1;
end s_data_rom;
