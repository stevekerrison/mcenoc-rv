// Copyright 1986-2016 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2016.1 (lin64) Build 1538259 Fri Apr  8 15:45:23 MDT 2016
// Date        : Wed Feb 22 09:22:34 2017
// Host        : ulysses running 64-bit Ubuntu 16.04.2 LTS
// Command     : write_verilog -force -mode synth_stub
//               /home/steve/research/emc2/mcenoc-rv/mcenoc-rv-xilinx/mcenoc-rv-xilinx.srcs/sources_1/ip/picorv32_bram/picorv32_bram_stub.v
// Design      : picorv32_bram
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7k160tfbg676-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "blk_mem_gen_v8_3_2,Vivado 2016.1" *)
module picorv32_bram(clka, wea, addra, dina, douta)
/* synthesis syn_black_box black_box_pad_pin="clka,wea[3:0],addra[12:0],dina[31:0],douta[31:0]" */;
  input clka;
  input [3:0]wea;
  input [12:0]addra;
  input [31:0]dina;
  output [31:0]douta;
endmodule
