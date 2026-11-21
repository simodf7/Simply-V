# Author: sim.difraia@studenti.unina.it 
# Description: 
# This script does obtains Vortex_subsystem IP 

###########
# Project #
###########
set project_name "vx_subsys_prj"
create_project $project_name ./$project_name -force -part  $::env(XILINX_PART_NUMBER)
set_property board_part $::env(XILINX_BOARD_PART) [current_project]

#########################
# Directories and files #
#########################

set rtl_dir [file normalize ./rtl] 
set tcl_dir [file normalize ./tcl] 
set user_ip_dir ${rtl_dir}/ip_repo
set vcs_file ${rtl_dir}/sources.txt 


source "${tcl_dir}/parse_vcs_list.tcl"
set vlist [parse_vcs_list "${vcs_file}"]

set vsources_list  [lindex $vlist 0]
set vincludes_list [lindex $vlist 1]
set vdefines_list  [lindex $vlist 2]


###########
# Sources #
###########
add_files -norecurse -verbose -fileset sources_1 ${vsources_list}

###########
# Defines #
###########
set_property verilog_define ${vdefines_list} [get_filesets sources_1]


##############
# Import IPS #
##############

set_property ip_repo_paths ${user_ip_dir} [current_project]
update_ip_catalog


set ::env(FPU_IP) [file normalize ./$project_name/ip]
set tool_dir ${tcl_dir}
set device_part $::env(XILINX_PART_NUMBER)
source ${tcl_dir}/import_ip.tcl

##############################
# Create Vortex Subsystem IP #
##############################

set clk_freq_hz [expr {$::env(MAIN_CLOCK_FREQ_MHZ) * 1000000} ]
set ip_repo_out ${rtl_dir}/vxsys_repo 
source ${tcl_dir}/vortex_subsystem_bd.tcl



