vlib work
vlib activehdl

vlib activehdl/xil_defaultlib
vlib activehdl/xpm

vmap xil_defaultlib activehdl/xil_defaultlib
vmap xpm activehdl/xpm

vlog -work xil_defaultlib  -sv2k12 \
"/home/nate/opt/Xilinx/Vivado/2018.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \

vcom -work xpm -93 \
"/home/nate/opt/Xilinx/Vivado/2018.2/data/ip/xpm/xpm_VCOMP.vhd" \

vcom -work xil_defaultlib -93 \
"../../../../cores.srcs/sources_1/ip/xadc_senseWire/xadc_senseWire_drp_to_axi_stream.vhd" \
"../../../../cores.srcs/sources_1/ip/xadc_senseWire/xadc_senseWire_xadc_core_drp.vhd" \
"../../../../cores.srcs/sources_1/ip/xadc_senseWire/xadc_senseWire_axi_xadc.vhd" \
"../../../../cores.srcs/sources_1/ip/xadc_senseWire/xadc_senseWire.vhd" \

vlog -work xil_defaultlib \
"glbl.v"

