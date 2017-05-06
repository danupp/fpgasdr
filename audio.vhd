library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.ALL;

entity audiomux_sp is
	port (RX_Audio : in std_logic_vector(9 downto 0);
			TX_Audio : in std_logic_vector(9 downto 0);
			CW_Audio : in std_logic_vector(9 downto 0);
			clk_in : in std_logic;
			Audio_out : out std_logic_vector(9 downto 0);
			clk_codec : in std_logic;
			tx : in std_logic;
			key : in std_logic;
			mute : in std_logic
			);
end audiomux_sp;

architecture mux_arch of audiomux_sp is
signal databuff1, databuff2, databuff3 : std_logic_vector(9 downto 0);
begin

	p1 : process (clk_in)
	variable data_temp : std_logic_vector(10 downto 0);
	begin
		if clk_in'event and clk_in = '1' then
			if tx = '0' then
				data_temp := RX_Audio(9) & RX_Audio;
			else
				data_temp := "00000000000"; -- TX_Audio(9) & TX_Audio;
			end if;
			if key = '1' then
				data_temp := data_temp + (CW_audio(9) & CW_audio(9 downto 0));
				databuff1 <= data_temp(10 downto 1);
			else
				databuff1 <= data_temp(9 downto 0);
			end if;
			databuff2 <= databuff1;
		end if;
	end process;
	
	p2 : process (clk_codec, clk_in)
	begin
		if clk_codec'event and clk_codec = '1' then
			databuff3 <= databuff2;
			if mute = '0' then
				Audio_out <= databuff3;
			else
				Audio_out <= "0000000000";
			end if;
		end if;
	end process;
	
end mux_arch;

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.ALL;

entity squelch is
	port (squelch_level : in std_logic_vector(5 downto 0);
			rssi : in std_logic_vector(5 downto 0);
			mute : out std_logic
			);
end squelch;

architecture sq_arch of squelch is
begin
	
mute <= '0' when squelch_level <= rssi else '1';
	
end sq_arch;


library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_unsigned.ALL;

entity audiomux_tx is
	port (key : in std_logic;
			audio_data_in : in std_logic_vector(15 downto 0);
			CW_audio_data_in : in std_logic_vector(9 downto 0);
			mod_data_out : out std_logic_vector(15 downto 0)
			);
end audiomux_tx;

architecture mux_arch of audiomux_tx is
begin
mod_data_out <= audio_data_in when key = '0' else
						CW_audio_data_in(9) & CW_audio_data_in & "00000";
end mux_arch;


library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.ALL;

entity rx_audio_antialias_lpf is
	port (Audio_in : in std_logic_vector(15 downto 0);
			Audio_out : out std_logic_vector(15 downto 0);
			clk_in : in std_logic
			);
end rx_audio_antialias_lpf;

architecture antialias_arch of rx_audio_antialias_lpf is

type databuffer is array (0 to 5) of signed (15 downto 0);

signal audiobuff : databuffer;
signal ka, kb, kc, kd : integer range 0 to 4;

begin

	p0 : process (clk_in)

	variable n : integer range 0 to 4;
	
	begin
	if clk_in'event and clk_in = '1' then
		if n = 0 then 
			n := 1;
			ka <= 0;
			kb <= 4;
			kc <= 3;
			kd <= 2;
		elsif n = 1 then
			n := 2;
			ka <= 1;
			kb <= 0;
			kc <= 4;
			kd <= 3;
		elsif n = 2 then
			n := 3;
			ka <= 2;
			kb <= 1;
			kc <= 0;
			kd <= 4;
		elsif n = 3 then
			n := 4;
			ka <= 3;
			kb <= 2;
			kc <= 1;
			kd <= 0;
		elsif n = 4 then
			n := 0;
			ka <= 4;
			kb <= 3;
			kc <= 2;
			kd <= 1;
		end if;
		
		audiobuff(n) <= signed(audio_in);
	end if;
	end process;
	
	p1 : process (clk_in)
	begin
	if clk_in'event and clk_in = '0' then
		audio_out <= std_logic_vector((audiobuff(ka)(15) & audiobuff(ka)(15) & audiobuff(ka)(15) & audiobuff(ka))
											+ (audiobuff(kb)(15) & audiobuff(kb)(15) & audiobuff(kb) & '0') 
											+ (audiobuff(kc)(15) & audiobuff(kc)(15) & audiobuff(kc) & '0')
											+ (audiobuff(kd)(15) & audiobuff(kd)(15) & audiobuff(kd)(15) & audiobuff(kd)))(18 downto 3);
	end if;
	end process;
	
end antialias_arch;
	
library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

entity audio_filt is
	port (RX_audio_in : in std_logic_vector(9 downto 0);
			TX_audio_in : in std_logic_vector(9 downto 0);
			audio_out : out std_logic_vector(15 downto 0);
			clk_in : in std_logic; -- 20 MHz
			clk_sample : in std_logic;
			ssb_am : in std_logic;
			wide_narrow : in std_logic;
			tx : in std_logic
			);
end audio_filt;

architecture filter_arch of audio_filt is
	
type longbuffer is array (0 to 260) of signed (9 downto 0);
type filt_type is array (0 to 126) of signed (9 downto 0);

signal data_in_buffer : longbuffer;

constant ssb_wide : filt_type :=
--Scilab:
--> [v,a,f] = wfir ('lp', 256, [3.2/25 0], 'hn', [0 0]);
--> round(v*2^11)
   ("0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000001",
    "0000000000",
    "0000000000",
    "1111111111",
    "1111111111",
    "1111111111",
    "0000000000",
    "0000000001",
    "0000000001",
    "0000000001",
    "0000000000",
    "1111111111",
    "1111111111",
    "1111111111",
    "0000000000",
    "0000000001",
    "0000000010",
    "0000000001",
    "1111111111",
    "1111111110",
    "1111111110",
    "1111111111",
    "0000000001",
    "0000000010",
    "0000000010",
    "0000000001",
    "1111111111",
    "1111111101",
    "1111111101",
    "1111111111",
    "0000000010",
    "0000000011",
    "0000000011",
    "0000000001",
    "1111111110",
    "1111111100",
    "1111111101",
    "0000000000",
    "0000000011",
    "0000000101",
    "0000000100",
    "0000000000",
    "1111111100",
    "1111111010",
    "1111111100",
    "0000000000",
    "0000000101",
    "0000000111",
    "0000000100",
    "1111111111",
    "1111111010",
    "1111111000",
    "1111111100",
    "0000000010",
    "0000001000",
    "0000001001",
    "0000000101",
    "1111111101",
    "1111110111",
    "1111110110",
    "1111111011",
    "0000000100",
    "0000001011",
    "0000001011",
    "0000000100",
    "1111111010",
    "1111110011",
    "1111110011",
    "1111111100",
    "0000001000",
    "0000010000",
    "0000001110",
    "0000000100",
    "1111110110",
    "1111101101",
    "1111110000",
    "1111111101",
    "0000001110",
    "0000010111",
    "0000010010",
    "0000000001",
    "1111101110",
    "1111100100",
    "1111101011",
    "0000000001",
    "0000011001",
    "0000100011",
    "0000011001",
    "1111111100",
    "1111011110",
    "1111010001",
    "1111100010",
    "0000001010",
    "0000110011",
    "0001000010",
    "0000101000",
    "1111101011",
    "1110101001",
    "1110001111",
    "1110111110",
    "0000111100",
    "0011101100",
    "0110010110",
    "0111111110");

constant cw_narrow : filt_type :=
--Scilab:
--> [v,a,f] = wfir ('lp', 256, [1.2/26 0], 'hn', [0 0]);
--> round(v*2^12)
   ("0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "1111111111",
    "1111111111",
    "1111111111",
    "1111111111",
    "1111111111",
    "1111111111",
    "1111111111",
    "0000000000",
    "0000000000",
    "0000000001",
    "0000000001",
    "0000000010",
    "0000000010",
    "0000000010",
    "0000000011",
    "0000000011",
    "0000000010",
    "0000000010",
    "0000000001",
    "0000000000",
    "1111111111",
    "1111111110",
    "1111111101",
    "1111111100",
    "1111111011",
    "1111111011",
    "1111111100",
    "1111111100",
    "1111111101",
    "1111111111",
    "0000000001",
    "0000000010",
    "0000000100",
    "0000000110",
    "0000000111",
    "0000001000",
    "0000001000",
    "0000000111",
    "0000000110",
    "0000000100",
    "0000000001",
    "1111111111",
    "1111111100",
    "1111111001",
    "1111110110",
    "1111110101",
    "1111110100",
    "1111110100",
    "1111110101",
    "1111110111",
    "1111111011",
    "1111111111",
    "0000000011",
    "0000000111",
    "0000001011",
    "0000001111",
    "0000010001",
    "0000010010",
    "0000010010",
    "0000010000",
    "0000001100",
    "0000000111",
    "0000000001",
    "1111111010",
    "1111110100",
    "1111101110",
    "1111101001",
    "1111100110",
    "1111100100",
    "1111100101",
    "1111101001",
    "1111101111",
    "1111110111",
    "0000000000",
    "0000001010",
    "0000010100",
    "0000011110",
    "0000100101",
    "0000101010",
    "0000101100",
    "0000101001",
    "0000100100",
    "0000011010",
    "0000001101",
    "1111111101",
    "1111101100",
    "1111011011",
    "1111001011",
    "1110111110",
    "1110110100",
    "1110110001",
    "1110110100",
    "1110111110",
    "1111010001",
    "1111101011",
    "0000001100",
    "0000110011",
    "0001011111",
    "0010001110",
    "0010111110",
    "0011101100",
    "0100010111",
    "0100111100",
    "0101011010",
    "0101101110",
    "0101111001");

constant am_filter : filt_type :=

-->[v,a,f] = wfir ('lp', 256, [8/25 0], 'hn', [0 0]);
-->round(v*2^9)

   ("0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "1111111111",
    "0000000000",
    "0000000000",
    "1111111111",
    "0000000000",
    "0000000000",
    "1111111111",
    "0000000000",
    "0000000001",
    "1111111111",
    "0000000000",
    "0000000001",
    "1111111111",
    "0000000000",
    "0000000001",
    "1111111111",
    "1111111111",
    "0000000001",
    "0000000000",
    "1111111111",
    "0000000001",
    "0000000000",
    "1111111111",
    "0000000001",
    "0000000000",
    "1111111110",
    "0000000001",
    "0000000001",
    "1111111110",
    "0000000001",
    "0000000001",
    "1111111110",
    "0000000000",
    "0000000010",
    "1111111110",
    "0000000000",
    "0000000010",
    "1111111110",
    "1111111111",
    "0000000011",
    "1111111111",
    "1111111110",
    "0000000011",
    "1111111111",
    "1111111110",
    "0000000011",
    "0000000000",
    "1111111101",
    "0000000011",
    "0000000001",
    "1111111100",
    "0000000010",
    "0000000010",
    "1111111011",
    "0000000010",
    "0000000011",
    "1111111011",
    "0000000001",
    "0000000101",
    "1111111011",
    "1111111111",
    "0000000110",
    "1111111011",
    "1111111101",
    "0000001000",
    "1111111100",
    "1111111011",
    "0000001001",
    "1111111101",
    "1111111000",
    "0000001011",
    "0000000000",
    "1111110011",
    "0000001100",
    "0000000100",
    "1111101101",
    "0000001101",
    "0000001100",
    "1111100011",
    "0000001101",
    "0000100000",
    "1111000010",
    "0000001110",
    "0100010011");

	
signal sample : boolean := false;
signal to_sample : boolean := false;
signal sampled : boolean := false;
signal state : integer range 0 to 6 := 0;
signal write_pointer : integer range 0 to 260 := 255;
signal read_pointer : integer range 0 to 260 := 255;
signal asynch_data_read, synch_data_read : signed (9 downto 0);
signal mac : signed (25 downto 0);
signal prod : signed (19 downto 0);
	

begin
	
	p0 : process (clk_in)
	variable indata : signed (9 downto 0);
	begin	
		if clk_in'event and clk_in = '1' then
			if sample = true then
				to_sample <= true; -- sample at next clock cycle
			elsif to_sample = true then -- sample and write to RAM
				if tx = '0' then
					indata := signed(RX_audio_in);
				else
					indata := signed(TX_audio_in);
				end if;
				data_in_buffer(write_pointer) <= indata;
				to_sample <= false;
				sampled <= true;
			else
				sampled <= false;

			end if;
			asynch_data_read <= data_in_buffer(read_pointer);
			synch_data_read <= asynch_data_read;
				
		end if;
	end process;
	
	sample_ff : process(clk_sample,sampled)
	begin
		if to_sample = true then
			sample <= false;
		elsif clk_sample'event and clk_sample = '1' then
			sample <= true;
		end if;
	end process;
			
	p1 : process (clk_in)
	variable filtkoeff : signed(9 downto 0);
	variable n : integer range 0 to 270 := 0;
	variable p : integer range 0 to 540;
	variable k : integer range 0 to 126;
	
	begin
		if clk_in'event and clk_in = '0' then 
				
			if sampled = true then
				state <= 0;
			elsif state = 0 then
				n := 0;
				if write_pointer = 0 then
					write_pointer <= 260;
					read_pointer <= 2;
				elsif write_pointer = 260 then
					write_pointer <= write_pointer - 1;
					read_pointer <= 1;
				elsif write_pointer = 259 then
					write_pointer <= write_pointer - 1;
					read_pointer <= 0;
				else
					write_pointer <= write_pointer - 1;
					read_pointer <= write_pointer + 2;
				end if;		
				mac <= to_signed(0,26);
				prod <= to_signed(0,20);
				state <= 1;
			elsif state = 1 then 
				p := read_pointer + 1;
				if p > 260 then
					read_pointer <= p - 261;
				else
					read_pointer <= p;
				end if;
				state <= 3;
			elsif state = 3 then

				if n > 126 then
					k := 253 - n;
				else
					k := n;
				end if;
				
				if ssb_am = '0' then
					filtkoeff := am_filter(k);
				else
					if wide_narrow = '1' then
						filtkoeff := ssb_wide(k);
					else
						filtkoeff := cw_narrow(k);
					end if;
				end if;
				prod <= synch_data_read * filtkoeff;
				mac <= mac + prod;
				
				n := n + 1;
				
				if n > 253 then
					state <= 4;
				else				
					p := read_pointer + 1;
					if p > 260 then
						read_pointer <= p - 261;
					else
						read_pointer <= p;
					end if;
				end if;
				
			elsif state = 4 then
				mac <= mac + prod;
				state <= 5;
			elsif state = 5 then
				if ssb_am = '0' then
					audio_out <= std_logic_vector(mac)(19 downto 4);
				else
					if wide_narrow = '1' then
						audio_out <= std_logic_vector(mac)(20 downto 5);
					else
						audio_out <= std_logic_vector(mac)(21 downto 6);
					end if;
				end if;
				state <= 6;
			end if;
		end if;
	end process;
	
end filter_arch;