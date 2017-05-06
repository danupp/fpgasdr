//lpm_mult CBX_SINGLE_OUTPUT_FILE="ON" LPM_HINT="DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=5" LPM_PIPELINE=0 LPM_REPRESENTATION="SIGNED" LPM_TYPE="LPM_MULT" LPM_WIDTHA=14 LPM_WIDTHB=14 LPM_WIDTHP=28 LPM_WIDTHS=1 clock dataa datab result
//VERSION_BEGIN 15.1 cbx_mgl 2015:10:21:19:02:34:SJ cbx_stratixii 2015:10:14:18:59:15:SJ cbx_util_mgl 2015:10:14:18:59:15:SJ  VERSION_END
// synthesis VERILOG_INPUT_VERSION VERILOG_2001
// altera message_off 10463



// Copyright (C) 1991-2015 Altera Corporation. All rights reserved.
//  Your use of Altera Corporation's design tools, logic functions 
//  and other software and tools, and its AMPP partner logic 
//  functions, and any output files from any of the foregoing 
//  (including device programming or simulation files), and any 
//  associated documentation or information are expressly subject 
//  to the terms and conditions of the Altera Program License 
//  Subscription Agreement, the Altera Quartus Prime License Agreement,
//  the Altera MegaCore Function License Agreement, or other 
//  applicable license agreement, including, without limitation, 
//  that your use is for the sole purpose of programming logic 
//  devices manufactured by Altera and sold by Altera or its 
//  authorized distributors.  Please refer to the applicable 
//  agreement for further details.



//synthesis_resources = lpm_mult 1 
//synopsys translate_off
`timescale 1 ps / 1 ps
//synopsys translate_on
module  mg2om
	( 
	clock,
	dataa,
	datab,
	result) /* synthesis synthesis_clearbox=1 */;
	input   clock;
	input   [13:0]  dataa;
	input   [13:0]  datab;
	output   [27:0]  result;

	wire  [27:0]   wire_mgl_prim1_result;

	lpm_mult   mgl_prim1
	( 
	.clock(clock),
	.dataa(dataa),
	.datab(datab),
	.result(wire_mgl_prim1_result));
	defparam
		mgl_prim1.lpm_pipeline = 0,
		mgl_prim1.lpm_representation = "SIGNED",
		mgl_prim1.lpm_type = "LPM_MULT",
		mgl_prim1.lpm_widtha = 14,
		mgl_prim1.lpm_widthb = 14,
		mgl_prim1.lpm_widthp = 28,
		mgl_prim1.lpm_widths = 1,
		mgl_prim1.lpm_hint = "DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=5";
	assign
		result = wire_mgl_prim1_result;
endmodule //mg2om
//VALID FILE
