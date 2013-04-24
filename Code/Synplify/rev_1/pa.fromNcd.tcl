
# PlanAhead Launch Script for Post PAR Floorplanning, created by Project Navigator

create_project -name Main -dir "H:/work/Part3/P3-Project/Code/Synplify/rev_1/planAhead_run_1" -part xc3s50antqg144-4
set srcset [get_property srcset [current_run -impl]]
set_property design_mode GateLvl $srcset
set_property edif_top_file "Main.edf" [ get_property srcset [ current_run ] ]
add_files -norecurse { {H:/work/Part3/P3-Project/Code/Synplify/rev_1} }
set_property target_constrs_file "synplicity.ucf" [current_fileset -constrset]
add_files [list {synplicity.ucf}] -fileset [get_property constrset [current_run]]
link_design
read_xdl -file "H:/work/Part3/P3-Project/Code/Synplify/rev_1/top_level.ncd"
if {[catch {read_twx -name results_1 -file "H:/work/Part3/P3-Project/Code/Synplify/rev_1/top_level.twx"} eInfo]} {
   puts "WARNING: there was a problem importing \"H:/work/Part3/P3-Project/Code/Synplify/rev_1/top_level.twx\": $eInfo"
}
