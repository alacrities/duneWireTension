-makelib xcelium_lib/xil_defaultlib -sv \
  "/home/nate/opt/Xilinx/Vivado/2018.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
-endlib
-makelib xcelium_lib/xpm \
  "/home/nate/opt/Xilinx/Vivado/2018.2/data/ip/xpm/xpm_VCOMP.vhd" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  "../../../../cores.srcs/sources_1/ip/xadc_senseWire/xadc_senseWire_drp_to_axi_stream.vhd" \
  "../../../../cores.srcs/sources_1/ip/xadc_senseWire/xadc_senseWire_xadc_core_drp.vhd" \
  "../../../../cores.srcs/sources_1/ip/xadc_senseWire/xadc_senseWire_axi_xadc.vhd" \
  "../../../../cores.srcs/sources_1/ip/xadc_senseWire/xadc_senseWire.vhd" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  glbl.v
-endlib

