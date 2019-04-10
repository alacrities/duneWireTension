// Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2018.2 (lin64) Build 2258646 Thu Jun 14 20:02:38 MDT 2018
// Date        : Wed Apr 10 13:18:52 2019
// Host        : localhost.localdomain running 64-bit Fedora release 29 (Twenty Nine)
// Command     : write_verilog -force -mode synth_stub
//               /home/nate/projects/duneWireTension/vivadoProjects/cores/cores.srcs/sources_1/ip/vio_ctrl/vio_ctrl_stub.v
// Design      : vio_ctrl
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7vx485tffg1761-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* X_CORE_INFO = "vio,Vivado 2018.2" *)
module vio_ctrl(clk, probe_in0, probe_in1, probe_out0, 
  probe_out1, probe_out2, probe_out3)
/* synthesis syn_black_box black_box_pad_pin="clk,probe_in0[31:0],probe_in1[31:0],probe_out0[31:0],probe_out1[0:0],probe_out2[0:0],probe_out3[0:0]" */;
  input clk;
  input [31:0]probe_in0;
  input [31:0]probe_in1;
  output [31:0]probe_out0;
  output [0:0]probe_out1;
  output [0:0]probe_out2;
  output [0:0]probe_out3;
endmodule
