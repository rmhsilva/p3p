
# PlanAhead Launch Script for Post-Synthesis floorplanning, created by Project Navigator

create_project -name Main -dir "H:/work/Part3/P3-Project/Code/Synplify/rev_1/planAhead_run_1" -part xc3s50antqg144-4
set_property design_mode GateLvl [get_property srcset [current_run -impl]]
set_property edif_top_file "H:/work/Part3/P3-Project/Code/Synplify/rev_1/Main.edf" [ get_property srcset [ current_run ] ]
add_files -norecurse { {H:/work/Part3/P3-Project/Code/Synplify/rev_1} }
set_property target_constrs_file "synplicity.ucf" [current_fileset -constrset]
add_files [list {synplicity.ucf}] -fileset [get_property constrset [current_run]]
link_design
