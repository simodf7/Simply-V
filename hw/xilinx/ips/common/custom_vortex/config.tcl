# Author: sim.difraia@studenti.unina.it 
# Description: 
# This script does obtains Vortex Wrapper IP 
 
#########################
# Directories and files #
#########################

set top_module custom_top_wrapper
set vortex_module vortex_subsystem

set dir_name $::env(HW_UNITS_ROOT)/$::env(IP_NAME)
set rtl_dir_name ${dir_name}/rtl
set unina_soc_dir $::env(XILINX_ROOT)/rtl

set mem_macro_path ${unina_soc_dir}/headers/simplyv_mem.svh
set axi_macro_path ${unina_soc_dir}/headers/simplyv_axi.svh
set pkg_path ${unina_soc_dir}/simplyv_pkg.sv
set top_module_path ${dir_name}/${top_module}.sv


#######################
# Vortex subsystem IP #
#######################

# Note: Vortex subsystem IP repo path + (DCR + VX console) IPs repo path 
set ip_repos_list {}
lappend ip_repos_list ${rtl_dir_name}/ip_repo
lappend ip_repos_list ${rtl_dir_name}/vxsys_repo 

set_property ip_repo_paths $ip_repos_list [current_project]
update_ip_catalog 

create_ip -vlnv user.org:user:$vortex_module:1.0
generate_target instantiation_template [get_files $vortex_module.xci] 


###################
# Wrapper Sources #
###################

# Append svh files and top module
set src_file_list {}
lappend src_file_list ${mem_macro_path}
lappend src_file_list ${axi_macro_path}
lappend src_file_list ${pkg_path}
lappend src_file_list ${top_module_path}

# Add files to project
import_files -norecurse -fileset [current_fileset] $src_file_list
set_property top ${top_module} [current_fileset]
update_compile_order -fileset sources_1


###########
# Package #
###########

# Suppress: WARNING: [IP_Flow 19-3833] Unreferenced file from the top module is not packaged: <...>.
set_msg_config -id {[IP_Flow 19-3833]} -suppress

# Package the IP and update the catalog
set top_repo $::env(IP_DIR)/build/ip_repo_top 

ipx::package_project -root_dir ${top_repo} -vendor user.org -library user -taxonomy /UserIP
set_property name $::env(IP_PRJ_NAME) [ipx::current_core]
set_property core_revision 2 [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::check_integrity [ipx::current_core]
ipx::save_core [ipx::current_core]

lappend ip_repos_list $top_repo
set_property ip_repo_paths $ip_repos_list [current_project]
update_ip_catalog

# Import IP into the project
create_ip -vlnv user.org:user:$::env(IP_PRJ_NAME):1.0 -module_name $::env(IP_NAME)
