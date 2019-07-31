library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_unsigned.ALL; -- behövs för +
-- use ieee.numeric_bit.ALL;

entity TLV320AIC20K_interface is
	port (SDA : inout std_logic := 'Z';
			SCL : out std_logic;
			RESET_N : out std_logic;
			PWRDWN_N : out std_logic;
			MCLK : out std_logic;
			SCLK : in std_logic;
			FS : in std_logic;
			DIN : out std_logic;
			DOUT : in std_logic;
			clk0 : in std_logic;
			ch1_in : in std_logic_vector(15 downto 0);
			ch2_in : in std_logic_vector(15 downto 0);
			ch1_out : out std_logic_vector(15 downto 0);
			ch2_out : out std_logic_vector(15 downto 0);
			err_out : out std_logic := '0';
			POR : in std_logic_vector (1 downto 0);
			audio_conf : in std_logic_vector(15 downto 0);
			conf_strobe : std_logic
			);
end TLV320AIC20K_interface;

architecture Codec_ctrl of TLV320AIC20K_interface is

type regdata is array (0 to 11) of std_logic_vector (11 downto 0);

constant init_regdata : regdata :=  -- index (3bits) 0 data (8bits)
			("001001101001",
			"010000100000",
			"011000000001",
			"011001001100",
			"110010001100", -- spk+line to dac, reg 6b måste komma före reg 4
			"101000010110", -- +33dB på ADC
			"101001010100", -- -30 dB på DAC
			"101010111111", -- mute sidetones
			"101011000000",  -- 0dB spk gain
			"110000000100", -- mic till adc
			"100010001100", -- M = 12
		   "100000100001");  -- P = 1, N = 4   -> 26.041 ksps at 20 MHz
			

signal new_regdata : regdata;
signal I2C_data : std_logic_vector (26 downto 0);
signal I2C_state : integer range 0 to 5 := 5;
signal clk_I2C : std_logic_vector(1 downto 0) := "00";
signal I2C_start_transfer : boolean := false;
signal init_done : boolean := false;
signal update_reg : boolean := false;

signal data_from_codec : std_logic_vector (30 downto 0); -- plus LSB in DOUT
signal data_to_codec : std_logic_vector (30 downto 0); -- plus MSB in DIN

signal clk_counter : std_logic_vector(10 downto 0);
signal clk_slow : std_logic;

signal conf_strobe_ff_q : std_logic := '0';
signal conf_strobe_ff_reset : std_logic := '0';

begin

MCLK <= clk0;
PWRDWN_N <= '1';
RESET_N <= POR(1);
clk_slow <= clk_counter(7);

clk_div : process (clk0)
begin
	if clk0'event and clk0 = '1' then
		clk_counter <= clk_counter + 1;
	end if;
end process;

regload : process (clk_slow)
variable n : integer range 0 to 12 := 0;
variable m : integer range 0 to 2;
variable DAC_gain_regval : std_logic_vector(11 downto 0);
begin
	if clk_slow'event and clk_slow = '1' then
		if init_done = false and POR = "11" then
			if I2C_start_transfer = false then
				if I2C_state = 5 then -- transfer complete or not started
					if n = 12 then -- transfer complete
						init_done <= true;
						n := 0;
						--audio_conf_last <= audio_conf;
					--err_out <= '1';
					else
						I2C_data <= "10000000000000" & init_regdata(n) & '0';
						I2C_start_transfer <= true;
						n := n + 1;
						m := 0;
					end if;
				end if;
			else
				if m < 2 then
					m := m + 1;
				else
					I2C_start_transfer <= false;		
				end if;
			end if;
		elsif update_reg = true then
			if I2C_start_transfer = false then
				if I2C_state = 5 then -- transfer complete or not started
					if n = 12 then -- transfer complete
						update_reg <= false;
						conf_strobe_ff_reset <= '0';
						n := 0;		
					else
						I2C_data <= "10000000000000" & new_regdata(n) & '0';
						I2C_start_transfer <= true;
						n := n + 1;
						m := 0;
					end if;
				end if;
			else
				if m < 2 then
					m := m + 1;
				else
					I2C_start_transfer <= false;		
				end if;
			end if;
		elsif conf_strobe_ff_q = '1' then
			conf_strobe_ff_reset <= '1';
			update_reg <= true;
			DAC_gain_regval := "101001" & audio_conf(5 downto 0);
			new_regdata <= init_regdata(0 to 5) & DAC_gain_regval & init_regdata(7 to 11);
		end if;
	end if;
end process;

conf_strobe_ff : process(conf_strobe,conf_strobe_ff_reset,init_done)
begin
	if conf_strobe_ff_reset = '1' then  -- asynch reset
		conf_strobe_ff_q <= '0';
	elsif conf_strobe'event and conf_strobe = '1' and init_done = true then
		conf_strobe_ff_q <= '1';
	end if;
end process;

I2C_transmit : process(clk_slow)

variable n : integer range 0 to 26;
variable SDA_in : std_logic;

begin
	if clk_slow'event and clk_slow = '1' then

		if I2C_start_transfer = true then
			I2C_state <= 0;
			CLK_I2C <= "00";
			n := 26;
		else 
			clk_I2C <= clk_I2C + 1;
		end if;
		
		if I2C_state = 0 then -- initiated
			SCL <= '1';
			SDA <= '1';
			if clk_I2C = "11" then
				I2C_state <= 1;
			end if;
		elsif I2C_state = 1 then -- start
			if clk_I2C = "10" then  
				SDA <= '0'; -- start bit
			elsif clk_I2C = "11" then
				I2C_state <= 2;
			end if;
		elsif I2C_state = 2 then -- transfer
			if clk_I2C = "00" then  -- SCL går låg
				SCL <= '0';
			elsif clk_I2C = "01" then -- SCL är låg
				if n = 18 or n = 9 or n = 0 then
					SDA <= 'Z'; -- ack?
				else
					SDA <= I2C_data(n);
				end if;
			elsif clk_I2C = "10" then -- SCL går hög
				SCL <= '1';
				if n = 18 or n = 9 or n = 0 then
					SDA_in := SDA;
					if SDA_in /= '0' then -- NACK
						if n = 18 then
							err_out <= '1';
						end if;
					end if;
				end if;
			elsif clk_I2C = "11" then -- SCL är hög
				if n = 0 then
					I2C_state <= 3;
				else
					n := n - 1;
				end if;
			end if;
		elsif I2C_state = 3 then -- issue stop bit
			if clk_I2C = "00" then  -- SCL går låg
				SCL <= '0';
			elsif clk_I2C = "01" then -- SCL är låg
				SDA <= '0';
			elsif clk_I2C = "10" then -- SCL går hög
				SCL <= '1';
			elsif clk_I2C = "11" then -- SCL är hög
				SDA <= '1';
				I2C_state <= 4;
			end if;
		elsif I2C_state = 4 then -- issue one clock cycle
			if clk_I2C = "00" then  -- SCL går låg
				SCL <= '0';
			elsif clk_I2C = "10" then -- SCL går hög
				SCL <= '1';
			elsif clk_I2C = "11" then -- SCL är hög
				I2C_state <= 5; -- terminate
			end if;
		end if;
	end if;
end process;

data_transfer : process (SCLK)
variable FS_delay : std_logic;
begin
	if init_done = true then
		if SCLK'event and SCLK = '0' and FS = '0' then
			data_from_codec <= data_from_codec(29 downto 0) & DOUT;
			FS_delay := '0';
		elsif SCLK'event and SCLK = '0' and FS = '1' then
			ch1_out <= data_from_codec(30 downto 15);
			ch2_out <= data_from_codec(14 downto 0) & DOUT;
			FS_delay := '1';
		elsif SCLK'event and SCLK = '1' and FS_delay = '0' then
			DIN <= data_to_codec(30);
			data_to_codec(30 downto 0) <= data_to_codec(29 downto 0) & '0';
		elsif SCLK'event and SCLK = '1' and FS_delay = '1' then
			DIN <= ch1_in(15);
			data_to_codec <= ch1_in (14 downto 0) & ch2_in;
		end if;
	end if;
end process data_transfer;

end Codec_ctrl;
