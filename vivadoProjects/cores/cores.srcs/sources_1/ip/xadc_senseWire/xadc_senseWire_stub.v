// Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2018.2 (lin64) Build 2258646 Thu Jun 14 20:02:38 MDT 2018
// Date        : Wed Apr 10 12:41:42 2019
// Host        : localhost.localdomain running 64-bit Fedora release 29 (Twenty Nine)
// Command     : write_verilog -force -mode synth_stub
//               /home/nate/projects/duneWireTension/vivadoProjects/cores/cores.srcs/sources_1/ip/xadc_senseWire/xadc_senseWire_stub.v
// Design      : xadc_senseWire
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7vx485tffg1761-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module xadc_senseWire(s_axis_aclk, m_axis_aclk, m_axis_resetn, 
  m_axis_tdata, m_axis_tvalid, m_axis_tid, m_axis_tready, vauxp0, vauxn0, vauxp8, vauxn8, busy_out, 
  channel_out, eoc_out, eos_out, alarm_out, vp_in, vn_in)
/* synthesis syn_black_box black_box_pad_pin="s_axis_aclk,m_axis_aclk,m_axis_resetn,m_axis_tdata[15:0],m_axis_tvalid,m_axis_tid[4:0],m_axis_tready,vauxp0,vauxn0,vauxp8,vauxn8,busy_out,channel_out[4:0],eoc_out,eos_out,alarm_out,vp_in,vn_in" */;
  input s_axis_aclk;
  input m_axis_aclk;
  input m_axis_resetn;
  output [15:0]m_axis_tdata;
  output m_axis_tvalid;
  output [4:0]m_axis_tid;
  input m_axis_tready;
  input vauxp0;
  input vauxn0;
  input vauxp8;
  input vauxn8;
  output busy_out;
  output [4:0]channel_out;
  output eoc_out;
  output eos_out;
  output alarm_out;
  input vp_in;
  input vn_in;
endmodule
