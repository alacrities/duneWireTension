#
#Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
#
set_param synth.incrementalSynthesisCache ./.Xil/Vivado-18052-localhost.localdomain/incrSyn
set_param logicopt.enableRemapLopt 1
set_param logicopt.enablePowerLopt8Series 0
set_param synth.enableIncremental 0
set_param logicopt.enableHighEffortDirective 1
set_param logicopt.enablePowerLopt9Series 0
set_param chipscope.flow 0
set_param synth.rodin.xdcFlow false
set script_paths /home/nate/projects/duneWireTension/firmware/scripts/.Xil/Vivado-18052-localhost.localdomain/dbg_hub_CV.0/out/get_cs_ip.tcl
foreach script_path $script_paths { 
    source $script_path
    lappend debug_ip_vlnv $ip_vlnv 
    lappend debug_ip_module_name $ip_module_name
    lappend debug_params $params
    lappend debug_output_xci $output_xci
    lappend debug_output_dcp $output_dcp
    lappend debug_output_dir $output_dir
    lappend debug_synth_opts $synth_opts
    lappend debug_xdc_files $xdc_files
}
set debug_ip_repo_paths $ip_repo_paths
set debug_ip_output_repo $ip_output_repo
set debug_ip_cache_permissions $ip_cache_permissions

set debug_oopbus_ip_repo_paths [get_param chipscope.oopbus_ip_repo_paths]
set jobs 3

source {/home/nate/opt/Xilinx/Vivado/2018.2/scripts/ip/ipxchipscope.tcl}

set failed [catch {ipx::chipscope::run_multi_gen_and_synth_ip_core $part $board_part $board_connections $board_part_repo_paths $tool_flow $debug_ip_vlnv $debug_ip_module_name $debug_params $debug_output_xci $debug_output_dcp $debug_output_dir $debug_ip_repo_paths $debug_ip_output_repo $debug_ip_cache_permissions $debug_oopbus_ip_repo_paths $debug_synth_opts $debug_xdc_files $jobs} errMessage]

if { $failed } {
send_msg_id {IP_Flow 19-3805} ERROR "Failed to generate and synthesize debug IPs. \n $errMessage"
  exit 1
}
