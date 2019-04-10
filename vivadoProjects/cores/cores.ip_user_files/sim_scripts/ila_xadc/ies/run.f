-makelib ies_lib/xil_defaultlib -sv \
  "/home/nate/opt/Xilinx/Vivado/2018.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
  "/home/nate/opt/Xilinx/Vivado/2018.2/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \
-endlib
-makelib ies_lib/xpm \
  "/home/nate/opt/Xilinx/Vivado/2018.2/data/ip/xpm/xpm_VCOMP.vhd" \
-endlib
-makelib ies_lib/xil_defaultlib \
  "../../../../cores.srcs/sources_1/ip/ila_xadc/sim/ila_xadc.vhd" \
-endlib
-makelib ies_lib/xil_defaultlib \
  glbl.v
-endlib

