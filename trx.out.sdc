## Generated SDC file "trx.out.sdc"

## Copyright (C) 1991-2016 Altera Corporation. All rights reserved.
## Your use of Altera Corporation's design tools, logic functions 
## and other software and tools, and its AMPP partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Altera Program License 
## Subscription Agreement, the Altera Quartus Prime License Agreement,
## the Altera MegaCore Function License Agreement, or other 
## applicable license agreement, including, without limitation, 
## that your use is for the sole purpose of programming logic 
## devices manufactured by Altera and sold by Altera or its 
## authorized distributors.  Please refer to the applicable 
## agreement for further details.


## VENDOR  "Altera"
## PROGRAM "Quartus Prime"
## VERSION "Version 15.1.2 Build 193 02/01/2016 SJ Lite Edition"

## DATE    "Sat Nov 12 00:35:57 2016"

##
## DEVICE  "EP4CE10E22C8"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {clk20} -period 50.000 -waveform { 0.000 25.000 } [get_ports {clk_tcxo}]
create_clock -name {ADC_clk} -period 800.000 -waveform { 0.000 25.000 } [get_nets {inst0|ADC_Clk}]
create_clock -name {rx_sample_clk} -period 25000.000 -waveform { 0.000 800.000 } [get_nets {inst6|clk_out}]
create_clock -name {FS_clk} -period 40000.000 -waveform { 0.000 800.000 } [get_ports {CODEC_FS}]
create_clock -name {CODEC_Serial_clk} -period 1000.000 -waveform { 0.000 500.000 } [get_ports {CODEC_SCLK}]
create_clock -name {tx_rx_sample_clk} -period 25000.000 -waveform { 0.000 800.000 } [get_nets {inst8|clk_out}]
create_clock -name {Slow_clk} -period 100000.000 -waveform { 0.000 50000.000 } [get_nets {inst1|Counter[9]}]
create_clock -name {POR_clk} -period 100000.000 -waveform { 0.000 50000.000 } [get_nets {inst1|POR[0]}]


#**************************************************************
# Create Generated Clock
#**************************************************************

create_generated_clock -name {clk240} -source [get_ports {clk_tcxo}] -multiply_by 12 -master_clock {clk20} 
create_generated_clock -name {A_clk_DAC} -source [get_ports {clk_tcxo}] -multiply_by 6 -master_clock {clk20} 
create_generated_clock -name {B_clk_DAC} -source [get_ports {clk_tcxo}] -multiply_by 12 -master_clock {clk20} 


#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************

set_clock_uncertainty -rise_from [get_clocks {clk20}] -rise_to [get_clocks {clk20}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {clk20}] -fall_to [get_clocks {clk20}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {clk20}] -rise_to [get_clocks {ADC_clk}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {clk20}] -fall_to [get_clocks {ADC_clk}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {clk20}] -rise_to [get_clocks {tx_rx_sample_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {clk20}] -fall_to [get_clocks {tx_rx_sample_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {clk20}] -rise_to [get_clocks {clk20}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {clk20}] -fall_to [get_clocks {clk20}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {clk20}] -rise_to [get_clocks {ADC_clk}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {clk20}] -fall_to [get_clocks {ADC_clk}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {clk20}] -rise_to [get_clocks {tx_rx_sample_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {clk20}] -fall_to [get_clocks {tx_rx_sample_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {ADC_clk}] -rise_to [get_clocks {clk20}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {ADC_clk}] -fall_to [get_clocks {clk20}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {ADC_clk}] -rise_to [get_clocks {clk20}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {ADC_clk}] -fall_to [get_clocks {clk20}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {FS_clk}] -rise_to [get_clocks {CODEC_Serial_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {FS_clk}] -fall_to [get_clocks {CODEC_Serial_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {FS_clk}] -rise_to [get_clocks {CODEC_Serial_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {FS_clk}] -fall_to [get_clocks {CODEC_Serial_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {tx_rx_sample_clk}] -rise_to [get_clocks {clk20}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {tx_rx_sample_clk}] -fall_to [get_clocks {clk20}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {tx_rx_sample_clk}] -rise_to [get_clocks {FS_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {tx_rx_sample_clk}] -fall_to [get_clocks {FS_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {tx_rx_sample_clk}] -rise_to [get_clocks {tx_rx_sample_clk}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {tx_rx_sample_clk}] -fall_to [get_clocks {tx_rx_sample_clk}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {tx_rx_sample_clk}] -rise_to [get_clocks {clk20}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {tx_rx_sample_clk}] -fall_to [get_clocks {clk20}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {tx_rx_sample_clk}] -rise_to [get_clocks {FS_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {tx_rx_sample_clk}] -fall_to [get_clocks {FS_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {tx_rx_sample_clk}] -rise_to [get_clocks {tx_rx_sample_clk}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {tx_rx_sample_clk}] -fall_to [get_clocks {tx_rx_sample_clk}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {CODEC_Serial_clk}] -rise_to [get_clocks {CODEC_Serial_clk}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {CODEC_Serial_clk}] -fall_to [get_clocks {CODEC_Serial_clk}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {CODEC_Serial_clk}] -rise_to [get_clocks {CODEC_Serial_clk}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {CODEC_Serial_clk}] -fall_to [get_clocks {CODEC_Serial_clk}]  0.020  


#**************************************************************
# Set Input Delay
#**************************************************************



#**************************************************************
# Set Output Delay
#**************************************************************



#**************************************************************
# Set Clock Groups
#**************************************************************



#**************************************************************
# Set False Path
#**************************************************************



#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************

