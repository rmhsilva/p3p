
#Begin clock constraint
define_clock -name {top_level|clk} {p:top_level|clk} -period 8.826 -clockgroup Autoconstr_clkgroup_0 -rise 0.000 -fall 4.413 -route 0.000 
#End clock constraint

#Begin clock constraint
define_clock -name {sram|sram_ce_inferred_clock} {n:sram|sram_ce_inferred_clock} -period 10000000.000 -clockgroup Autoconstr_clkgroup_1 -rise 0.000 -fall 5000000.000 -route 0.000 
#End clock constraint
