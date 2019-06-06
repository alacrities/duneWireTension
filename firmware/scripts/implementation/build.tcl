# filename: build.tcl
#proc setup { } {
#######################################################################################
# User Settings 
#######################################################################################

# to generate bitfile from scripts directory in: vivado -mode tcl
# source implementation/build.tcl
# makeBit 
puts "use commands: setup, readSource, synth, opt, place, postPlacePhysOpt route, bitgen, makeBit, explorePlaceDirectives exploreFullDirectives"

proc makeBit {} {

    puts "\n##################################################################"
    puts "#                    Run Selected Implementation Processes       #"
    puts "##################################################################\n"

    setup
    readSource
    synth
    opt
    place
    postPlacePhysOpt
    route
    bitgen
}

proc rePlace {} {
    global proj_dir
    global proj_name

    puts "\n##################################################################"
    puts "#                    Run Selected Implementation Processes       #"
    puts "##################################################################\n"

  #  setup
  #  read_checkpoint  $proj_dir/${proj_name}_post_opt.dcp
  #  delete_pblock [get_pblocks pB_*]

    opt
    place
    postPlacePhysOpt
    route
   # bitgen
}

proc setup {} {

    puts "\n##################################################################"
    puts "#                    Setup                                         #"
    puts "##################################################################\n"

    #Script Configuration
    set synth 0

    global top_module
    global proj_name
    global proj_dir
    global scriptdir
    global firmware_dir
    global proj_sources_dir
    global board_part
    global part
    global post_route_wns
    global target
    global ip_dir

 ##select configuration   
    set target "dune"

    set scriptdir [pwd]
    set firmware_dir $scriptdir/../
    set proj_sources_dir $firmware_dir/source/

        set top_module "top_tension_analyzer"
        set proj_name "tension_analyzer"
        set part "xc7z020clg400-2"

#        set top_module "top_tension_analyzer_vc707"
#        set proj_name "tension_analyzer_vc707"
#        set board_part "xilinx.com:vc707:part0:1.1"
#        set part "xc7vx485tffg1761-2"

    set_param general.maxThreads 8
    set post_route_wns xxx
    set proj_dir $firmware_dir/../vivadoProjects/$proj_name
   
    puts "Target: $target"
    puts "FPGA Part: $part"
    puts "Scripts Directory:  $scriptdir"
    puts "Project Directory: $proj_dir"
}

proc readSource {} {
    global scriptdir
    global proj_sources_dir
    global proj_name    
    global proj_dir    
    global board_part
    global part
    global target
    
    puts "\n##################################################################"
    puts "#                    Read Source                                 #"
    puts "##################################################################\n"

        # board part and in memory project mey be needed with BSP 
        # create_project -in_memory -part $part
        # set_property board_part $board_part [current_project]
        # source $scriptdir/implementation/readVc707DwaSource.tcl
        source $scriptdir/implementation/readMicrozedWtaSource.tcl
}

proc synth {} {
    global top_module
    global scriptdir
    global proj_sources_dir
    global proj_dir
    global proj_name
    global part
    global target


    puts "\n##################################################################"
    puts "#                    Synth Design                                #"
    puts "##################################################################\n"

    set defines ""
    append defines -verilog_define " " USE_DEBUG " "

    # synthesis related settings
    # vivado 2017 Flow_PerfOptomized_high
    #setup
    set synth_args ""
    append SYNTH_ARGS " " -flatten_hierarchy " " rebuilt " "
    append SYNTH_ARGS " " -gated_clock_conversion " " off " "
    append SYNTH_ARGS " " -bufg " {" 12 "} "
    append SYNTH_ARGS " " -fanout_limit " {" 400 "} "
    append SYNTH_ARGS " " -directive " " Default " "
    append SYNTH_ARGS " " -fsm_extraction " " one_hot " "
    append SYNTH_ARGS " " -keep_equivalent_registers " "
    append SYNTH_ARGS " " -resource_sharing " " off " "
    append SYNTH_ARGS " " -control_set_opt_threshold " " auto " "
    append SYNTH_ARGS " " -no_lc " "
    append SYNTH_ARGS " " -shreg_min_size " {" 5 "} "
    append SYNTH_ARGS " " -max_bram " {" -1 "} "
    append SYNTH_ARGS " " -max_uram " {" -1 "} "
    append SYNTH_ARGS " " -max_dsp " {" -1 "} "
    append SYNTH_ARGS " " -max_bram_cascade_height " {" -1 "} "
    append SYNTH_ARGS " " -max_uram_cascade_height " {" -1 "} "
    append SYNTH_ARGS " " -cascade_dsp " " auto " "
    append SYNTH_ARGS " " -verbose

    eval "synth_design $defines $synth_args -top $top_module -part $part"

    report_timing_summary -file $proj_dir/${proj_name}_post_synth_tim.rpt
    report_utilization -file $proj_dir/${proj_name}_post_synth_util.rpt
    write_checkpoint -force $proj_dir/${proj_name}_post_synth.dcp
}

proc opt {} {
    global proj_dir
    global proj_name
puts $proj_name
    #################################
    #check for incremental compile
    #################################
    # currently f's the placer
    #read_checkpoint -incremental $incrReuseDcp
    #report_incremental_reuse

    puts "\n##################################################################"
    puts "#                    Opt Design          ExploreWithRemap                        #"
    puts "##################################################################\n"

    opt_design -directive ExploreWithRemap
    report_timing_summary -file $proj_dir/${proj_name}_post_opt_tim.rpt
    report_utilization -file $proj_dir/${proj_name}_post_opt_util.rpt
    write_checkpoint -force $proj_dir/${proj_name}_post_opt.dcp
    # Upgrade DSP connection warnings (like "Invalid PCIN Connection for OPMODE value") to
    # an error because this is an error post route
    set_property SEVERITY {ERROR} [get_drc_checks DSPS-*]
    # Run DRC on opt design to catch early issues like comb loops
    report_drc -file $proj_dir/${proj_name}_post_opt_drc.rpt
}


# Place Design
# explore placment directives then quit 
#source $scriptdir/implementation/explorePlaceDirectives.tcl
proc place {} {
    global proj_dir
    global proj_name


    puts "\n##################################################################"
    puts "#                    Place                   ExtraTimingOpt                    #"
    puts "##################################################################\n"

    # scan of directives using ExtraNetDelay wns  +0.118
    # scan of directives using AltSpreadLogicy wns  +0.110
    #place_design -directive  AltSpreadLogic_medium
    #place_design -directive  ExtraNetDelay_low
    place_design -directive  ExtraTimingOpt -timing_summary 
    report_timing_summary -file $proj_dir/${proj_name}_post_place_tim.rpt
    report_utilization -file $proj_dir/${proj_name}_post_place_util.rpt
    write_checkpoint -force $proj_dir/${proj_name}_post_place.dcp

    set WNS [get_property SLACK [get_timing_paths -max_paths 1 -nworst 1 -setup]]
    puts "\n Post Place  WNS = $WNS \n"
}

proc postPlacePhysOpt {} {
    global proj_dir
    global proj_name

    puts "\n##################################################################"
    puts "#                    Post Place Phys Opt   AlternateReplication   #"
    puts "##################################################################\n"
    phys_opt_design -directive AlternateReplication
    report_timing_summary -file $proj_dir/${proj_name}_post_place_physopt_tim2.rpt
 
    set WNS [get_property SLACK [get_timing_paths -max_paths 1 -nworst 1 -setup]]
    puts "\n Post Phys Opt WNS = $WNS \n"
}
proc route {} {
    global proj_dir
    global proj_name
    global post_route_wns
    puts "\n##################################################################"
    puts "#                    Route                                       #"
    puts "##################################################################"
    puts ""
    # Route Design
    route_design -directive Explore
    report_timing_summary -file $proj_dir/${proj_name}_post_route_tim.rpt
    report_utilization -hierarchical -file $proj_dir/${proj_name}_post_route_util.rpt
    report_route_status -file $proj_dir/${proj_name}_post_route_status.rpt
    report_io -file $proj_dir/${proj_name}_post_route_io.rpt
    report_power -file $proj_dir/${proj_name}_post_route_power.rpt
    report_design_analysis -logic_level_distribution \
	-of_timing_paths [get_timing_paths -max_paths 10000 \
			      -slack_lesser_than 0] \
	-file $proj_dir/${proj_name}_post_route_vios.rpt
    write_checkpoint -force $proj_dir/${proj_name}_post_route.dcp

    set WNS [get_property SLACK [get_timing_paths -max_paths 1 -nworst 1 -setup]]
    puts "\n Post Route WNS = $WNS \n"
    set post_route_wns $WNS
}
proc postRoutePhysOpt {} {
    global proj_dir
    global proj_name


    puts "\n##################################################################"
    puts "#                    Post Route Phys Opt    AggressiveExplore                #"
    puts "##################################################################\n"
    phys_opt_design -directive AggressiveExplore
    report_timing_summary -file $proj_dir/${proj_name}_post_place_physopt_tim1.rpt

 
    #phys_opt_design -directive AddRetime
    #report_timing_summary -file $proj_dir/${proj_name}_post_place_physopt_tim3.rpt
    report_utilization -file $proj_dir/${proj_name}_post_place_physopt_util.rpt
    write_checkpoint -force $proj_dir/${proj_name}_post_route_physopt.dcp

    set WNS [get_property SLACK [get_timing_paths -max_paths 1 -nworst 1 -setup]]
    puts "\n Post Phys Opt WNS = $WNS \n"
}

proc bitgen {} {
    global proj_dir
    global proj_name
    global post_route_wns
    global target
    
    puts "\n##################################################################"
    puts "#                   Generate  Bitfile                            #"
    puts "##################################################################\n"

    set build_date [ clock format [ clock seconds ] -format %Y%m%d ]
    set build_time [ clock format [ clock seconds ] -format %H%M%S ]

    write_debug_probes -force $proj_dir/${proj_name}_${build_date}_${build_time}_${post_route_wns}ns.ltx
    write_bitstream -force $proj_dir/${proj_name}_${build_date}_${build_time}_${post_route_wns}ns.bit \
	-bin_file

    if {$target == "vc707"} {

        write_mem_info -force $proj_dir/${proj_name}_${build_date}_${build_time}_${post_route_wns}ns.mmi
        get_property SLACK [get_timing_paths -max_paths 20 -nworst 7 -setup]
    }
}

proc writeGdrive {} {
    exec  rclone copy $proj_dir/${proj_name}_${build_date}_${build_time}_${post_route_wns}ns.ltx gharvard:/projects/atlas/mmtp/mcsFiles
    exec  rclone copy $proj_dir/${proj_name}_${build_date}_${build_time}_${post_route_wns}ns.bit gharvard:/projects/atlas/mmtp/mcsFiles
}

