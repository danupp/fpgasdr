#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name clk20 -period 50.000 -waveform { 0.000 25.000 } [get_ports {clk_tcxo}]
create_clock -name ADC_clk -period 800.000 -waveform { 0.000 25.000 } [get_nets {inst0|ADC_Clk}]
create_clock -name rx_sample_clk -period 25000.000 -waveform { 0.000 800.000 } [get_nets {inst6|clk_out}]
create_clock -name FS_clk -period 40000.000 -waveform { 0.000 800 } [get_ports {CODEC_FS}]
create_clock -name CODEC_Serial_clk -period 1000.000 -waveform { 0.000 500 } [get_ports {CODEC_SCLK}]
create_clock -name tx_rx_sample_clk -period 25000.000 -waveform { 0.000 800.000 } [get_nets {inst8|clk_out}]
create_clock -name tx_upsample_clk -period 10000.000 -waveform { 0.000 800.000 } [get_nets {inst19|clk_out}]

create_clock -name SDA_clk -period 1000.000 -waveform { 0.000 100.000 } [get_ports {SDA}]
create_clock -name SCL_clk -period 1000.000 -waveform { 0.000 100.000 } [get_ports {SCL}]
create_clock -name I2C_Strobe_clk -period 100000.000 -waveform { 0.000 800.000 } [get_nets {inst11|Strobe}]
create_clock -name ADC_slow_clk -period 100000.000 -waveform { 0.000 50000.000 } [get_nets {inst4|ClkCounter[10]}]
create_clock -name Slow_clk -period 100000.000 -waveform { 0.000 50000.000 } [get_nets {inst1|Counter[9]}]
create_clock -name POR_clk -period 100000.000 -waveform { 0.000 50000.000 } [get_nets {inst1|POR[0]}]

#**************************************************************
# Create Generated Clock
#**************************************************************

create_generated_clock -name clk240 -source [get_ports {clk_tcxo}] -multiply_by 12 [get_pins {inst2|altpll_component|auto_generated|pll1|clk[0]}]
create_generated_clock -name A_clk_DAC -source [get_ports {clk_tcxo}] -multiply_by 6 [get_nets {inst3|A_clk}]
create_generated_clock -name B_clk_DAC -source [get_ports {clk_tcxo}] -multiply_by 6 [get_nets {inst3|B_clk}]

#-source [get_pins -compatibility_mode *pll1\|clk*] \
#**************************************************************
# Set Clock Uncertainty
#**************************************************************

set_clock_uncertainty -rise_from [get_clocks {B_clk_DAC}] -rise_to [get_clocks {PLL_C0}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {B_clk_DAC}] -fall_to [get_clocks {PLL_C0}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {B_clk_DAC}] -rise_to [get_clocks {B_clk_DAC}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {B_clk_DAC}] -fall_to [get_clocks {B_clk_DAC}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {B_clk_DAC}] -rise_to [get_clocks {PLL_C0}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {B_clk_DAC}] -fall_to [get_clocks {PLL_C0}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {B_clk_DAC}] -rise_to [get_clocks {B_clk_DAC}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {B_clk_DAC}] -fall_to [get_clocks {B_clk_DAC}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {ADC_clk}] -rise_to [get_clocks {clk20}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {ADC_clk}] -fall_to [get_clocks {clk20}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {ADC_clk}] -rise_to [get_clocks {clk20}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {ADC_clk}] -fall_to [get_clocks {clk20}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {CODEC_Serial_clk}] -rise_to [get_clocks {CODEC_Serial_clk}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {CODEC_Serial_clk}] -fall_to [get_clocks {CODEC_Serial_clk}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {CODEC_Serial_clk}] -rise_to [get_clocks {CODEC_Serial_clk}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {CODEC_Serial_clk}] -fall_to [get_clocks {CODEC_Serial_clk}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {FS_clk}] -rise_to [get_clocks {CODEC_Serial_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {FS_clk}] -fall_to [get_clocks {CODEC_Serial_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {FS_clk}] -rise_to [get_clocks {CODEC_Serial_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {FS_clk}] -fall_to [get_clocks {CODEC_Serial_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {A_clk_DAC}] -rise_to [get_clocks {PLL_C0}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {A_clk_DAC}] -fall_to [get_clocks {PLL_C0}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {A_clk_DAC}] -rise_to [get_clocks {A_clk_DAC}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {A_clk_DAC}] -fall_to [get_clocks {A_clk_DAC}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {A_clk_DAC}] -rise_to [get_clocks {PLL_C0}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {A_clk_DAC}] -fall_to [get_clocks {PLL_C0}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {A_clk_DAC}] -rise_to [get_clocks {A_clk_DAC}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {A_clk_DAC}] -fall_to [get_clocks {A_clk_DAC}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {tx_rx_sample_clk}] -rise_to [get_clocks {FS_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {tx_rx_sample_clk}] -fall_to [get_clocks {FS_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {tx_rx_sample_clk}] -rise_to [get_clocks {tx_rx_sample_clk}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {tx_rx_sample_clk}] -fall_to [get_clocks {tx_rx_sample_clk}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {tx_rx_sample_clk}] -rise_to [get_clocks {clk20}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {tx_rx_sample_clk}] -fall_to [get_clocks {clk20}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {tx_rx_sample_clk}] -rise_to [get_clocks {FS_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {tx_rx_sample_clk}] -fall_to [get_clocks {FS_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {tx_rx_sample_clk}] -rise_to [get_clocks {tx_rx_sample_clk}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {tx_rx_sample_clk}] -fall_to [get_clocks {tx_rx_sample_clk}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {tx_rx_sample_clk}] -rise_to [get_clocks {clk20}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {tx_rx_sample_clk}] -fall_to [get_clocks {clk20}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {clk20}] -rise_to [get_clocks {ADC_clk}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {clk20}] -fall_to [get_clocks {ADC_clk}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {clk20}] -rise_to [get_clocks {tx_rx_sample_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {clk20}] -fall_to [get_clocks {tx_rx_sample_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {clk20}] -rise_to [get_clocks {clk20}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {clk20}] -fall_to [get_clocks {clk20}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {clk20}] -rise_to [get_clocks {ADC_clk}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {clk20}] -fall_to [get_clocks {ADC_clk}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {clk20}] -rise_to [get_clocks {tx_rx_sample_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {clk20}] -fall_to [get_clocks {tx_rx_sample_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {clk20}] -rise_to [get_clocks {clk20}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {clk20}] -fall_to [get_clocks {clk20}]  0.020  
