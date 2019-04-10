vlib work
vlib riviera

vlib riviera/xil_defaultlib
vlib riviera/xpm

vmap xil_defaultlib riviera/xil_defaultlib
vmap xpm riviera/xpm

vlog -work xil_defaultlib  -sv2k12 "+incdir+../../../../cores.srcs/sources_1/ip/vio_ctrl/hdl/verilog" "+incdir+../../../../cores.srcs/sources_1/ip/vio_ctrl/hdl" "+incdir+../../../../cores.srcs/sources_1/ip/vio_ctrl/hdl/verilog" "+incdir+../../../../cores.srcs/sources_1/ip/vio_ctrl/hdl" \
"/home/nate/opt/Xilinx/Vivado/2018.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"/home/nate/opt/Xilinx/Vivado/2018.2/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm -93 \
"/home/nate/opt/Xilinx/Vivado/2018.2/data/ip/xpm/xpm_VCOMP.vhd" \

vcom -work xil_defaultlib -93 \
"../../../../cores.srcs/sources_1/ip/vio_ctrl/sim/vio_ctrl.vhd" \

vlog -work xil_defaultlib \
"glbl.v"

