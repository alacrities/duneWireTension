-makelib ies_lib/xil_defaultlib -sv \
  "/home/nate/opt/Xilinx/Vivado/2018.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
  "/home/nate/opt/Xilinx/Vivado/2018.2/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \
-endlib
-makelib ies_lib/xpm \
  "/home/nate/opt/Xilinx/Vivado/2018.2/data/ip/xpm/xpm_VCOMP.vhd" \
-endlib
-makelib ies_lib/xil_defaultlib \
  "../../../../../../firmware/source/cores/ip/clk_sysclk_mmcm/clk_sysclk_mmcm_clk_wiz.v" \
  "../../../../../../firmware/source/cores/ip/clk_sysclk_mmcm/clk_sysclk_mmcm.v" \
-endlib
-makelib ies_lib/xil_defaultlib \
  glbl.v
-endlib

