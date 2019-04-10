vlib questa_lib/work
vlib questa_lib/msim

vlib questa_lib/msim/xil_defaultlib
vlib questa_lib/msim/xpm

vmap xil_defaultlib questa_lib/msim/xil_defaultlib
vmap xpm questa_lib/msim/xpm

vlog -work xil_defaultlib -64 -sv \
"/home/nate/opt/Xilinx/Vivado/2018.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \

vcom -work xpm -64 -93 \
"/home/nate/opt/Xilinx/Vivado/2018.2/data/ip/xpm/xpm_VCOMP.vhd" \

vcom -work xil_defaultlib -64 -93 \
"../../../../cores.srcs/sources_1/ip/xadc_senseWire/xadc_senseWire_drp_to_axi_stream.vhd" \
"../../../../cores.srcs/sources_1/ip/xadc_senseWire/xadc_senseWire_xadc_core_drp.vhd" \
"../../../../cores.srcs/sources_1/ip/xadc_senseWire/xadc_senseWire_axi_xadc.vhd" \
"../../../../cores.srcs/sources_1/ip/xadc_senseWire/xadc_senseWire.vhd" \

vlog -work xil_defaultlib \
"glbl.v"

