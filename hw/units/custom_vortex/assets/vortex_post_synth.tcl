# Author: Simone Di Fraia <sim.difraia@studenti.unina.it>
# Description:
#   Post-synthesis hook of the custom_vortex IP synthesis run (registered by
#   config.tcl as STEPS.SYNTH_DESIGN.TCL.POST).
#   1. Applies the Vortex async BRAM patch (xilinx_async_bram_patch.tcl,
#      fetched in rtl/ by fetch_sources.sh), which the Vortex flow runs
#      before opt_design.
#   2. Writes the IP checkpoint again: in IP runs TCL.POST executes after
#      the checkpoint has already been written, so without this step the
#      patched netlist would be lost.
#   3. Regenerates the utilization report on the patched netlist.


# 1. Vortex async BRAM patch
source $::env(HW_UNITS_ROOT)/$::env(IP_NAME)/rtl/xilinx_async_bram_patch.tcl

# 2. Overwrite the checkpoint written by the run
write_checkpoint -force -noxdef $::env(IP_NAME).dcp

# 3. Utilization report of the patched netlist
report_utilization -file $::env(IP_NAME)_utilization_synth.rpt
