#################################################
###  SET DESIGN VARIABLES                     ###
#################################################
set DesignName  	"Main"
set FamilyName  	"SPARTAN3A"
set DeviceName  	"XC3S50AN"
set PackageName 	"TQG144"
set SpeedGrade  	"-4"
set TopModule   	"top_level"
set EdifFile    	"H:/work/Part3/P3-Project/Code/Synplify/rev_1/Main.edf"

#################################################
###  SET FLOW                                 ###
#################################################
set Flow 	"Standard"

#################################################
###  SET POWER OPTION                         ###
#################################################
set Power 	"0"

#################################################
###  PROJECT SETUP                            ###
#################################################
if {![file exists $DesignName.xise]} { 

	project new 			$DesignName.xise
	project set family 		$FamilyName
	project set device 		$DeviceName
	project set package 		$PackageName
	project set speed 		$SpeedGrade
	xfile 	add 			$EdifFile

	if {[file exists synplicity.ucf]} { xfile add synplicity.ucf }

} else {

	project open $DesignName.xise

}

#################################################
###  STANDARD                                 ###
#################################################
if { $Flow == "Standard" } {

	project set 	"Netlist Translation Type" 		"Timestamp"
	project set 	"Other NGDBuild Command Line Options" 	"-verbose"
	project set 	"Generate Detailed MAP Report" 		TRUE
	project set 	{Place & Route Effort Level (Overall)} 	"High"
}

#################################################
###  FAST                                     ###
#################################################
if { $Flow == "Fast" } {

	project set 	"Netlist Translation Type" 		"Timestamp"
	project set 	"Other NGDBuild Command Line Options" 	"-verbose"
	project set 	"Generate Detailed MAP Report" 		TRUE
	project set 	{Place & Route Effort Level (Overall)} 	"Standard"
}

#################################################
###  SMARTGUIDE                               ###
#################################################
if { $Flow == "SmartGuide" } {

	project set 	"Use Smartguide" 			TRUE  
	project set 	"SmartGuide Filename" 			$DesignName\_guide.ncd  
	project set 	"Netlist Translation Type" 		"Timestamp"
	project set 	"Other NGDBuild Command Line Options" 	"-verbose"
	project set 	"Generate Detailed MAP Report" 		TRUE
	project set 	{Place & Route Effort Level (Overall)} 	"High"
}

#################################################
###  SMARTGUIDE FAST                          ###
#################################################
if { $Flow == "SmartGuideFast" } {

	project set 	"Use Smartguide" 			TRUE  
	project set 	"SmartGuide Filename" 			$DesignName\_guide.ncd  
	project set 	"Netlist Translation Type" 		"Timestamp"
	project set 	"Other NGDBuild Command Line Options" 	"-verbose"
	project set 	"Generate Detailed MAP Report" 		TRUE
	project set 	{Place & Route Effort Level (Overall)} 	"Standard"
}


#################################################
###  EXECUTE ISE PLACE & ROUTE                ###
#################################################
file 	delete -force 	$DesignName\_xdb
project open 		$DesignName.xise
process run 		"Implement Design" -force rerun_all
## process run      "Generate Programming File"

#################################################
###  EXECUTE POWER OPTION                     ###
#################################################
if { $Power == "1" } {

        exec xpwr -v $DesignName.ncd $DesignName.pcf
}

project close
