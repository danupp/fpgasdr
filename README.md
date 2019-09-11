# DSP/SDR with FPGA

This repository contains FPGA firmware for the FPGA SDR/DSP radio board.
Development started in 2013 on a Cyclone II board prototype but the current platforms target a Cyclone IV on a board developed together with Elektor Labs.

This repository was created 2017-05-06 in order to separate the FPGA firmware from control software in the legacy repository.

For an overall project description, please visit: https://sm6vfz.wordpress.com/dspsdr-with-fpga/

## Firmware source and binary

This repository contains vhdl and other source files for the FPGA itself. Under output_files the compiled binaries can be found. For programming the latest built firmware into the non-volatile flash memory, use the JTAG Indirect Configuration file, [trx.jic](fpga/output_files/trx.jic), with an USB Blaster or similar programmer and the Quartus Prime software. (When running the latter in Linux, it is sometimes necessary to run the jtag daemon, jtagd, as root user.) 

## Communication protocol

Communication with the FPGA is over I2C or UART.
Please refer to the [register map](/docs/register-map.org) for more information about how the FPGA is controlled.

## Changelog

2016-11-12: (built jic binary)  
* TX works also in direct mode, i.e. modulation directly on the channel frequency, from DAC A. (In indirect mode, the modulated carrier is generated at the IF frequency by DAC B, to pass through a crystal filter.)  
(Heavy alias products from upsampling still present.)  
* Channel/dial frequency should now not be set adjusted by IF freq. This will be done internally in FPGA. (JIC-file not build.)
* Created the Changelog.  
* Updated the register-map description.  
	
2016-11-26:  
* Added slightly better upsampling in TX for better spectrum.  
* Remove old text in register-map.  

2016-12-17: (built jic binary)  
* Faster I2C communication with audio codec for swift volume control.
* Weaver modulator bypass in CW implemented fully, for decent TX spectrum in direct mode with TX signal from DAC A. This is enabled by the cw_tx_nomod configuration bit.

2016-12-XX:  
* Added experimental FM modulation in TX, indirect mode
* Added bit in register map for FM mode.

2017-04-17: (built jic binary)  
* Squelch implemented.

2017-05-15: (built jic binary)  
* Added post agc audio filter in TX
* Increased mic gain in codec
* Slower agc/compressor release in TX
* Larger compressor dynamic

2017-05-30: (built jic binary)  
* Fixed small bug in AGC
* Bypassed audio filter after demodulator. It is probably not necessary.

2017-06-08: (built jic binary)  
* Another small fix in AGC
* Implemented two-tone generation for TX IM measurement. Updated register map.

2017-06-23: (built jic binary)  
* Faster AGC/compressor release when going into TX, makes it faster to get full power level.

2017-10-09:  
* Experimental audio output in I2S at 39ksps.

2017-10-22:  
* Raw IQ available as I2S.
* Modified .gitignore not to remove trx.sof and trx.jic in output_files

2017-10-25:  
* I2S output now controllable from register. See register map for details.
	
2017-11-19:  
* With I2S enabled, stream to codec now connected to I2S input.
	
2018-01-08:  
* Audio not fed into FPGA in I2S-mode anymore.
  
2018-01-12:  
* Implemented more efficient decimator.  
  
2019-07-31:  (built jic binary)
* Small improvement in AGC.  
* Line out now enabled together with speaker audio channel.  
  
2019-09-08:  (built jic binary)  
* All codec setup now removed from FPGA and put onto the host mcu to do. I2C bridge added for this purpose. UART mode removed.  
* Codew written for noise blanker after decimation filter, not implemented.  
  
2019-09-11: (built jic)
* Fixed bug with missing mic audio.  
  


