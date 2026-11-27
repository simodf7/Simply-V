# Author: sim.difraia@studenti.unina.it 
# Description: 
# This script does obtains Vortex Wrapper IP 
 
#########################
# Directories and files #
#########################

set top_module custom_top_wrapper
set vortex_module vortex_subsystem
set vortex_module_name vortex_sys

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

create_ip -vlnv user.org:user:$vortex_module:1.0 -module_name $vortex_module_name
generate_target instantiation_template [get_files $vortex_module.xci] 


####################
# Other IPs Needed #
####################



# AXI DWIDTH CONVERTER 64 to 32 


if { $::env(MBUS_DATA_WIDTH) == 64 } {
  create_ip -name axi_dwidth_converter -vendor xilinx.com -library ip -version 2.1 -module_name vx_dwidth_64_to_32

  set_property -dict [list \
    CONFIG.MI_DATA_WIDTH {32} \
    CONFIG.SI_DATA_WIDTH {64} \
    CONFIG.SI_ID_WIDTH $::env(MBUS_ID_WIDTH) \
    CONFIG.ADDR_WIDTH $::env(MBUS_ADDR_WIDTH) \
  ] [get_ips vx_dwidth_64_to_32]

} 


# AXI PROTOCOL CONVERTER AXI4 to AXILITE

create_ip -name axi_protocol_converter -vendor xilinx.com -library ip -version 2.1 -module_name vx_axi4_to_axilite

set_property -dict [list \
    CONFIG.MI_PROTOCOL      {AXI4LITE} \
    CONFIG.READ_WRITE_MODE  {READ_WRITE} \
    CONFIG.SI_PROTOCOL      {AXI4} \
    CONFIG.TRANSLATION_MODE {2} \
] [get_ips vx_axi4_to_axilite]

set_property CONFIG.DATA_WIDTH  32                      [get_ips vx_axi4_to_axilite]
set_property CONFIG.ADDR_WIDTH  13                      [get_ips vx_axi4_to_axilite]
set_property CONFIG.ID_WIDTH    $::env(MBUS_ID_WIDTH)   [get_ips vx_axi4_to_axilite]


# AXI DATA WIDTH CONVERTER 512 to MBUS_DATA_WIDTH 

create_ip -name axi_dwidth_converter -vendor xilinx.com -library ip -version 2.1 -module_name vx_dwidth_from512

set_property -dict [list \
  CONFIG.SI_DATA_WIDTH {512} \
] [get_ips vx_dwidth_from512]

# MBUS ID WIDTH is the same of VORTEX ID 

set_property CONFIG.ADDR_WIDTH     $::env(MBUS_ADDR_WIDTH)  [get_ips vx_dwidth_from512]
set_property CONFIG.SI_ID_WIDTH    $::env(MBUS_ID_WIDTH)    [get_ips vx_dwidth_from512]
set_property CONFIG.MI_DATA_WIDTH  $::env(MBUS_DATA_WIDTH)  [get_ips vx_dwidth_from512]


generate_target instantiation_template [get_ips vx_*]


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
# Package from sources_1: it contains both imports/ (wrapper, headers) and ip/ (vortex_sys),
# so the packaged IP is self-contained (no external files)
set top_repo $::env(IP_DIR)/build/$::env(IP_PRJ_NAME).srcs/sources_1 

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
set_property -dict [list \
  CONFIG.LOCAL_AXI_DATA_WIDTH $::env(MBUS_DATA_WIDTH) \
  CONFIG.LOCAL_AXI_ADDR_WIDTH $::env(MBUS_ADDR_WIDTH) \
  CONFIG.LOCAL_AXI_ID_WIDTH   $::env(MBUS_ID_WIDTH)   \
] [get_ips $::env(IP_NAME)]



################################
# Vortex async BRAM patch hook #
################################
# Vortex maps its asynchronous-read RAMs to BRAM with a netlist patch:
# with ASYNC_BRAM_PATCH (set by VX_platform.vh for Vivado synthesis),
# VX_dp_ram/VX_sp_ram instantiate VX_async_ram_patch, whose VX_placeholder
# cells are left as black boxes by synth_design. The Vortex script
# xilinx_async_bram_patch.tcl rewires the read address to its next-cycle
# value and removes the placeholders.
#
# The Vortex flow runs the script before opt_design (pre_opt_hook.tcl).
# Here the subsystem is synthesized out-of-context as a Simply-V IP, so the
# script runs as a post-synthesis hook of this IP's synthesis run: the
# netlist is the same (synthesized, not yet optimized), and the IP
# checkpoint is already complete when linked into the Simply-V design.
#
# Workaround: the synthesis run is created by the common post_config.tcl,
# after this script, and creating it here moves the .xci out of sources_1,
# where post_config.tcl looks for it. Instead, create_ip_run is wrapped
# once: the wrapper calls the original command, attaches the hook to the
# new run and restores the original command.

set ::vx_post_synth ${rtl_dir_name}/vortex_post_synth.tcl 
add_files -fileset utils_1 -norecurse ${::vx_post_synth}

rename create_ip_run vx_orig_create_ip_run
proc create_ip_run {args} {
    set run [vx_orig_create_ip_run {*}$args]
    set_property STEPS.SYNTH_DESIGN.TCL.POST ${::vx_post_synth} [get_runs $::env(IP_NAME)_synth_1]
    # One-shot wrapper: restore the original command
    rename create_ip_run ""
    rename vx_orig_create_ip_run create_ip_run
    return $run
}

