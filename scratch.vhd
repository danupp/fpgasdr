
library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

entity audio_filt is
	port (RX_audio_in : in std_logic_vector(9 downto 0);
			TX_audio_in : in std_logic_vector(9 downto 0);
			audio_out : out std_logic_vector(9 downto 0);
			clk_in : in std_logic; -- 20 MHz
			clk_sample : in std_logic;
			ssb_am : in std_logic;
			wide_narrow : in std_logic;
			tx : in std_logic;
			filt_bypass : in std_logic
			);
end audio_filt;

architecture filter_arch of audio_filt is
	
type longbuffer is array (0 to 260) of signed (9 downto 0);
type filt_type is array (0 to 126) of signed (9 downto 0);

signal data_in_buffer : longbuffer;

constant weaver_wide_rx : filt_type :=
--Scilab:
--> [v,a,f] = wfir ('lp', 256, [1.55/39 0], 'hn', [0 0]);
--> round(v*2^26)

   ("000000000000000000000100",
    "111111111111111111111000",
    "111111111111111110110101",


constant weaver_wide_tx : filt_type :=
--Scilab:
--> [v,a,f] = wfir ('lp', 256, [1.55/25 0], 'hn', [0 0]);
--> round(v*2^26)

   ("111111111111111111101011",
    "111111111111111110011011",
    "111111111111111100011010",



constant weaver_narrow : filt_type :=
--Scilab:
--> [v,a,f] = wfir ('lp', 256, [0.4/39 0], 'hn', 0);
--> round(v*2^28)

	("000000000000000001100010",
    "000000000000000110010010",


constant am_filter : filt_type :=

-->[v,a,f] = wfir ('lp', 256, [7.5/39 0], 'hn', [0 0]);
-->round(v*2^24)

   ("000000000000000000000110",
    "000000000000000000010011",

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
					indata := signed(RX_audio_in);
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
				deb <= '1';
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
				mac <= to_signed(0,25);
				prod <= to_signed(0,19);
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
				
				if filt_bypass = '1' then
					if n = 10 then
						filtkoeff := "0111111111";
					else
						filtkoeff := "0000000000";
					end if;
				elsif ssb_am = '0' then
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
					audio_out <= std_logic_vector(mac + to_signed(8388608,63))(47 downto 24); TBD
				else
					if wide_narrow = '1' then
						audio_out <= std_logic_vector(mac + to_signed(33554432,63))(47 downto 24);  
					else
						audio_out <= std_logic_vector(mac + to_signed(134217728,63))(50 downto 27); 
					end if;
				end if;
				state <= 6;
			end if;
		end if;
	end process;
	
end filter_arch;


library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.ALL;

entity tx_upsample is
	port (Data_in_I : in std_logic_vector(23 downto 0);
			Data_in_Q : in std_logic_vector(23 downto 0);
			Data_out_I : out std_logic_vector(13 downto 0);
			Data_out_Q : out std_logic_vector(13 downto 0);
			clk20 : in std_logic; -- 20 MHz
			clk_sample : in std_logic;
			att : in std_logic;
			clk_out : buffer std_logic
			);
end tx_upsample;

architecture filter_arch of tx_upsample is

type longbuffer is array (0 to 2) of signed (13 downto 0);
signal buffer_I, buffer_Q : longbuffer;
signal mac_I, mac_Q : signed (15 downto 0);
signal Data_in_I_buff, Data_in_Q_buff : signed (13 downto 0);
signal req, req0, req1, req2, req3 : std_logic := '0';
signal ack : std_logic := '0';

begin
			
	sample : process(ack, clk_sample)
	begin
		if ack = '1' then
			req <= '0';
		elsif clk_sample'event and clk_sample='0' then
			req <= '1';
		end if;
	end process;
		
	p0 : process (clk20)
	variable count_div : integer range 0 to 799 := 0;
	begin
		if clk20'event and clk20 = '1' then 

					  
			req0 <= req;
			req1 <= req0;
			req2 <= req1;
			req3 <= req2;
			
			if req3 = '1' then
				ack <= '1';
			elsif req2 = '1' then
				if att = '0' then
					Data_in_I_buff <= signed(Data_in_I(15 downto 2));
					Data_in_Q_buff <= signed(Data_in_Q(15 downto 2));
				else
					Data_in_I_buff <= signed(Data_in_I(14 downto 1));
					Data_in_Q_buff <= signed(Data_in_Q(14 downto 1));
				end if;	
				--count_div := 50;
			else
				ack <= '0';
			end if;
				
			if count_div = 191 then -- compute
				mac_I <=       (buffer_I(0)(13) & buffer_I(0)(13) & buffer_I(0)(13 downto 0)) +
						      	(buffer_I(1)(13) & buffer_I(1)(13) & buffer_I(1)(13 downto 0)) +
									(buffer_I(2)(13) & buffer_I(2)(13 downto 0) & buffer_I(2)(0)); -- 1,1,2
				mac_Q <=       (buffer_Q(0)(13) & buffer_Q(0)(13) & buffer_Q(0)(13 downto 0)) +
									(buffer_Q(1)(13) & buffer_Q(1)(13) & buffer_Q(1)(13 downto 0)) +
									(buffer_Q(2)(13) & buffer_Q(2)(13 downto 0) & buffer_Q(2)(0)); -- 1,1,2
				clk_out <= '0';
			elsif (count_div = 287) or (count_div = 671) then
				Data_out_I <= std_logic_vector(mac_I(15 downto 2));
				Data_out_Q <= std_logic_vector(mac_Q(15 downto 2));  -- div by 4 =(1+2+1+1+2+1)/2
			elsif count_div = 383 then
				clk_out <= '1';
			elsif count_div = 575 then  -- compute
				mac_I <=       (buffer_I(0)(13) & buffer_I(0)(13 downto 0) & buffer_I(0)(0)) +
									(buffer_I(1)(13) & buffer_I(1)(13) & buffer_I(1)(13 downto 0)) +
									(buffer_I(2)(13) & buffer_I(2)(13) & buffer_I(2)(13 downto 0)); -- 2,1,1
				mac_Q <=       (buffer_Q(0)(13) & buffer_Q(0)(13 downto 0) & buffer_Q(0)(0)) +
									(buffer_Q(1)(13) & buffer_Q(1)(13) & buffer_Q(1)(13 downto 0)) +
									(buffer_Q(2)(13) & buffer_Q(2)(13) & buffer_Q(2)(13 downto 0)); -- 2,1,1				
				clk_out <= '0';
			elsif count_div = 767 and req2 = '0' then -- sample
				buffer_I(0) <= Data_in_I_buff;
				buffer_Q(0) <= Data_in_Q_buff;
				buffer_I(1) <= buffer_I(0);
				buffer_Q(1) <= buffer_Q(0);
				buffer_I(2) <= buffer_I(1);
				buffer_Q(2) <= buffer_Q(1);
				clk_out <= '1'; -- div by 768, for 52.0833 ksps
			end if;
			
			if count_div = 767 then
				count_div := 0;
			else
				count_div := count_div + 1;
			end if;
		end if;
	end process;
	
end filter_arch;




library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.ALL;

entity tx_upsample is
	port (Data_in_I : in std_logic_vector(23 downto 0);
			Data_in_Q : in std_logic_vector(23 downto 0);
			Data_out_I : out std_logic_vector(13 downto 0);
			Data_out_Q : out std_logic_vector(13 downto 0);
			clk20 : in std_logic; -- 20 MHz
			clk_sample : in std_logic;
			tx_att : in std_logic_vector(1 downto 0);
			clk_out : buffer std_logic
			);
end tx_upsample;

architecture filter_arch of tx_upsample is

type longbuffer is array (0 to 4) of signed (13 downto 0);
signal buffer_I, buffer_Q : longbuffer;
signal Data_in_I_buff, Data_in_Q_buff : signed (13 downto 0);
signal req, req0, req1, req2, req3 : std_logic := '0';
signal ack : std_logic := '0';

begin


	sample : process(ack, clk_sample)		
	begin
		if ack = '1' then
			req <= '0';
		elsif clk_sample'event and clk_sample='0' then
			req <= '1';
		end if;
	end process;
		
	p0 : process (clk20)
	variable mac_I, mac_Q : signed (15 downto 0);	
	variable count_div : integer range 0 to 799 := 0;
	begin
		if clk20'event and clk20 = '1' then 

					  
			req0 <= req;
			req1 <= req0;
			req2 <= req1;
			req3 <= req2;
			
			if req3 = '1' then
				ack <= '1';
			elsif req2 = '1' then
				if tx_att = "00" then
					Data_in_I_buff <= signed(Data_in_I(13 downto 0));
					Data_in_Q_buff <= signed(Data_in_Q(13 downto 0));
				elsif tx_att = "01" then
					Data_in_I_buff <= signed(Data_in_I(14 downto 1));
					Data_in_Q_buff <= signed(Data_in_Q(14 downto 1));
				elsif tx_att = "10" then
					Data_in_I_buff <= signed(Data_in_I(15 downto 2));
					Data_in_Q_buff <= signed(Data_in_Q(15 downto 2));
				else
					Data_in_I_buff <= signed(Data_in_I(16 downto 3));
					Data_in_Q_buff <= signed(Data_in_Q(16 downto 3));
				end if;
			else
				ack <= '0';
			end if;
			
			if count_div = 191 then
				mac_I :=       (buffer_I(0)(13) & buffer_I(0)(13) & buffer_I(0)(13 downto 0)) +
						      	(buffer_I(1)(13) & buffer_I(1)(13) & buffer_I(1)(13 downto 0));
																														-- 1,1
				mac_Q :=       (buffer_Q(0)(13) & buffer_Q(0)(13) & buffer_Q(0)(13 downto 0)) +
									(buffer_Q(1)(13) & buffer_Q(1)(13) & buffer_Q(1)(13 downto 0)); -- 1,1
				clk_out <= '0';
			elsif count_div = 287 then				
				Data_out_I <= std_logic_vector(mac_I(14 downto 1));   -- 0.5
				Data_out_Q <= std_logic_vector(mac_Q(14 downto 1));   -- 0.5
			elsif count_div = 383 then
				clk_out <= '1'; -- div by 384, for 52.0833 ksps
			elsif count_div = 575 then
				mac_I :=       buffer_I(0)(13) & buffer_I(0)(13) & buffer_I(0)(13 downto 0); -- 1
				mac_Q :=       buffer_Q(0)(13) & buffer_Q(0)(13) & buffer_Q(0)(13 downto 0); -- 1			
				clk_out <= '0';
			elsif count_div = 671 then
				Data_out_I <= std_logic_vector(mac_I(13 downto 0));  -- 1
				Data_out_Q <= std_logic_vector(mac_Q(13 downto 0));  -- 1
			elsif count_div = 767 and req2 = '0' then -- sample
				buffer_I(0) <= Data_in_I_buff;
				buffer_Q(0) <= Data_in_Q_buff;
				buffer_I(1) <= buffer_I(0);
				buffer_Q(1) <= buffer_Q(0);
				buffer_I(2) <= buffer_I(1);
				buffer_Q(2) <= buffer_Q(1);
				buffer_I(3) <= buffer_I(2);
				buffer_Q(3) <= buffer_Q(2);
				buffer_I(4) <= buffer_I(3);
				buffer_Q(4) <= buffer_Q(3);
				clk_out <= '1'; -- div by 384, for 52.0833 ksps
			end if;
			
			if count_div = 767 then
				count_div := 0;
			else
				count_div := count_div + 1;
			end if;
		end if;
	end process;
	
end filter_arch;


library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.ALL;

entity tx_upsample is
	port (Data_in_I : in std_logic_vector(23 downto 0);
			Data_in_Q : in std_logic_vector(23 downto 0);
			Data_out_I : out std_logic_vector(13 downto 0);
			Data_out_Q : out std_logic_vector(13 downto 0);
			clk20 : in std_logic; -- 20 MHz
			clk_sample : in std_logic;
			tx_att : in std_logic_vector(1 downto 0);
			clk_out : buffer std_logic;
			deb : out std_logic
			);
end tx_upsample;

architecture filter_arch of tx_upsample is

type longbuffer is array (0 to 200) of signed (13 downto 0);
type filt_type is array (0 to 254) of signed (13 downto 0);

signal buffer_I, buffer_Q : longbuffer;

constant interpolation_filter : filt_type :=

-- [v,a,f] = wfir ('lp', 512, [10/104 0], 'hn', [0 0]);
-- round(v*2^15)


   ("00000000000000",
    "00000000000000",
    "00000000000000",
    "00000000000000",
    "00000000000000",
    "00000000000000",
    "00000000000000",
    "00000000000000",
    "00000000000000",
    "00000000000000",
    "00000000000000",
    "00000000000000",
    "00000000000000",
    "00000000000000",
    "00000000000000",
    "00000000000000",
    "00000000000000",
    "00000000000000",
    "11111111111111",
    "11111111111111",
    "00000000000000",
    "00000000000000",
    "00000000000001",
    "00000000000001",
    "00000000000001",
    "00000000000000",
    "00000000000000",
    "11111111111111",
    "11111111111111",
    "11111111111111",
    "11111111111111",
    "00000000000000",
    "00000000000001",
    "00000000000010",
    "00000000000010",
    "00000000000001",
    "00000000000000",
    "11111111111111",
    "11111111111110",
    "11111111111101",
    "11111111111110",
    "11111111111111",
    "00000000000001",
    "00000000000011",
    "00000000000100",
    "00000000000011",
    "00000000000001",
    "11111111111111",
    "11111111111100",
    "11111111111011",
    "11111111111100",
    "11111111111110",
    "00000000000001",
    "00000000000100",
    "00000000000110",
    "00000000000101",
    "00000000000011",
    "00000000000000",
    "11111111111100",
    "11111111111001",
    "11111111111001",
    "11111111111011",
    "00000000000000",
    "00000000000100",
    "00000000001000",
    "00000000001000",
    "00000000000110",
    "00000000000010",
    "11111111111100",
    "11111111111000",
    "11111111110110",
    "11111111111000",
    "11111111111101",
    "00000000000011",
    "00000000001001",
    "00000000001100",
    "00000000001010",
    "00000000000101",
    "11111111111110",
    "11111111110111",
    "11111111110011",
    "11111111110011",
    "11111111111001",
    "00000000000001",
    "00000000001001",
    "00000000001111",
    "00000000001111",
    "00000000001010",
    "00000000000001",
    "11111111110111",
    "11111111110000",
    "11111111101110",
    "11111111110011",
    "11111111111101",
    "00000000001000",
    "00000000010001",
    "00000000010101",
    "00000000010001",
    "00000000000110",
    "11111111111001",
    "11111111101110",
    "11111111101001",
    "11111111101100",
    "11111111110110",
    "00000000000101",
    "00000000010010",
    "00000000011010",
    "00000000011000",
    "00000000001110",
    "11111111111110",
    "11111111101110",
    "11111111100100",
    "11111111100011",
    "11111111101101",
    "11111111111110",
    "00000000010001",
    "00000000011110",
    "00000000100001",
    "00000000011000",
    "00000000000110",
    "11111111110001",
    "11111111100001",
    "11111111011011",
    "11111111100010",
    "11111111110101",
    "00000000001100",
    "00000000100000",
    "00000000101001",
    "00000000100100",
    "00000000010010",
    "11111111111000",
    "11111111100001",
    "11111111010011",
    "11111111010110",
    "11111111101000",
    "00000000000011",
    "00000000011110",
    "00000000110000",
    "00000000110001",
    "00000000100000",
    "00000000000011",
    "11111111100100",
    "11111111001110",
    "11111111001001",
    "11111111011000",
    "11111111110110",
    "00000000011000",
    "00000000110100",
    "00000000111110",
    "00000000110001",
    "00000000010011",
    "11111111101101",
    "11111111001100",
    "11111110111100",
    "11111111000101",
    "11111111100011",
    "00000000001101",
    "00000000110100",
    "00000001001001",
    "00000001000101",
    "00000000101000",
    "11111111111011",
    "11111111001111",
    "11111110110010",
    "11111110110001",
    "11111111001100",
    "11111111111011",
    "00000000101101",
    "00000001010010",
    "00000001011010",
    "00000001000010",
    "00000000010001",
    "11111111011000",
    "11111110101100",
    "11111110011100",
    "11111110101111",
    "11111111100001",
    "00000000100000",
    "00000001010101",
    "00000001101110",
    "00000001100000",
    "00000000101111",
    "11111111101011",
    "11111110101100",
    "11111110001000",
    "11111110001111",
    "11111110111110",
    "00000000001000",
    "00000001010001",
    "00000010000001",
    "00000010000011",
    "00000001010111",
    "00000000001001",
    "11111110110100",
    "11111101111000",
    "11111101101010",
    "11111110010010",
    "11111111100011",
    "00000001000011",
    "00000010001111",
    "00000010101010",
    "00000010001001",
    "00000000110101",
    "11111111001010",
    "11111101101101",
    "11111101000001",
    "11111101011000",
    "11111110101101",
    "00000000100101",
    "00000010010110",
    "00000011010110",
    "00000011001011",
    "00000001110110",
    "11111111110010",
    "11111101101011",
    "11111100010010",
    "11111100001100",
    "11111101011101",
    "11111111110000",
    "00000010010001",
    "00000100000111",
    "00000100100101",
    "00000011011010",
    "00000000111001",
    "11111101111001",
    "11111011011011",
    "11111010011110",
    "11111011011110",
    "11111110001110",
    "00000001110111",
    "00000101001000",
    "00000110110010",
    "00000110000101",
    "00000011000100",
    "11111110100110",
    "11111010001011",
    "11110111011101",
    "11110111100111",
    "11111010111100",
    "00000000101000",
    "00000110111000",
    "00001011011101",
    "00001100011000",
    "00001000101101",
    "00000000111100",
    "11110111001010",
    "11101110100100",
    "11101010101011",
    "11101110010011",
    "11111010101011",
    "00001110110111",
    "00100111110101",
    "01000001000100",
    "01010101100001",
    "01100000111110");

signal Data_in_I_buff, Data_in_Q_buff : signed (13 downto 0);
signal req, req0, req1, req2, req3 : std_logic := '0';
signal ack : std_logic := '0';
signal state : integer range 0 to 6 := 0;
signal write_pointer : integer range 0 to 200 := 192;
signal read_pointer : integer range 0 to 200 := 192;
signal asynch_data_read_I, asynch_data_read_Q, synch_data_read_I, synch_data_read_Q : signed (13 downto 0);
signal mac_I, mac_Q : signed (34 downto 0);
signal prod_I, prod_Q : signed (27 downto 0);
signal count_div : integer range 0 to 799 := 0;

begin

	sample : process(ack, clk_sample)		
	begin
		if ack = '1' then
			req <= '0';
		elsif clk_sample'event and clk_sample='0' then
			req <= '1';
		end if;
	end process;
	
p0 : process (clk20)
	variable in_I, in_Q : signed (13 downto 0);	
	begin
		if clk20'event and clk20 = '1' then 
					  
			req0 <= req;
			req1 <= req0;
			req2 <= req1;
			req3 <= req2;
			
			if req3 = '1' then
				ack <= '1';
			elsif req2 = '1' then
				if tx_att = "00" then
					in_I := signed(Data_in_I(13 downto 0));
					in_Q := signed(Data_in_Q(13 downto 0));
				elsif tx_att = "01" then
					in_I := signed(Data_in_I(14 downto 1));
					in_Q := signed(Data_in_Q(14 downto 1));
				elsif tx_att = "10" then
					in_I := signed(Data_in_I(15 downto 2));
					in_Q := signed(Data_in_Q(15 downto 2));
				else
					in_I := signed(Data_in_I(16 downto 3));
					in_Q := signed(Data_in_Q(16 downto 3));
				end if;
				buffer_I(write_pointer) <= in_I;
				buffer_Q(write_pointer) <= in_Q;
				count_div <= 0;
			else
				ack <= '0';
				if count_div < 768 then
					count_div <= count_div + 1;
				end if;
			end if;
			asynch_data_read_I <= buffer_I(read_pointer);
			asynch_data_read_Q <= buffer_Q(read_pointer);
			synch_data_read_I <= asynch_data_read_I;
			synch_data_read_Q <= asynch_data_read_Q;

			if count_div < 96 then
				clk_out <= '1';
			elsif count_div = 96 then
				clk_out <= '0';
			elsif count_div = 192  then
				clk_out <= '1';
			elsif count_div = 288  then
				clk_out <= '0';
			elsif count_div = 384 then
				clk_out <= '1';
			elsif count_div = 480  then
				clk_out <= '0';
			elsif count_div = 576 then	
				clk_out <= '1';
			elsif count_div = 672 then -- and req2 = '0' then -- sample
				clk_out <= '0'; -- div by 192, for 104.xx ksps
			end if;
			
		end if;
	end process;

	p1 : process (clk20)
	variable filtkoeff : signed(13 downto 0);
	variable n : integer range 0 to 270 := 0;
	variable m : integer range 0 to 3;
	variable p : integer range 0 to 540;
	variable k : integer range 0 to 126;
	
	begin
		if clk20'event and clk20 = '0' then 
				
			if count_div = 0 or count_div = 191 or count_div = 383 or count_div = 575 then
				state <= 0;
				deb <= '0';
			elsif state = 0 then
				n := 0;
				
				if count_div < 191 then
					m := 0;
				elsif count_div < 383 then
					m := 1;
				elsif count_div < 575 then
					m := 2;
				else
					m := 3;
				end if;
				
				if write_pointer = 0 then
					if m = 3 then
						write_pointer <= 200;
					end if;
					read_pointer <= 2;
				elsif write_pointer = 200 then
					if m = 3 then
						write_pointer <= write_pointer - 1;
					end if;
					read_pointer <= 1;
				elsif write_pointer = 199 then
					if m = 3 then
						write_pointer <= write_pointer - 1;
					end if;
					read_pointer <= 0;
				else
					if m = 3 then
						write_pointer <= write_pointer - 1;
					end if;
					read_pointer <= write_pointer + 2;
				end if;		
				mac_I <= to_signed(0,35);
				mac_Q <= to_signed(0,35);
				prod_I <= to_signed(0,28);
				prod_Q <= to_signed(0,28);
				state <= 1;
			elsif state = 1 then 
				p := read_pointer + 1;
				if p > 200 then
					read_pointer <= p - 201;
				else
					read_pointer <= p;
				end if;
				state <= 3;
			elsif state = 3 then
				
				if n > 64 then
					k := 4*(128 - n)-m;
				else
					k := 4*n+m;
				end if;			

				filtkoeff := interpolation_filter(k);
				
				prod_I <= synch_data_read_I * filtkoeff;
				prod_Q <= synch_data_read_Q * filtkoeff;
				mac_I <= mac_I + prod_I;
				mac_Q <= mac_Q + prod_Q;
		
				n := n + 1;
				
				if n > 126 then
					state <= 4;
				else				
					p := read_pointer + 1;
					if p > 200 then
						read_pointer <= p - 201;
					else
						read_pointer <= p;
					end if;
				end if;
				
			elsif state = 4 then
				mac_I <= mac_I + prod_I;
				mac_Q <= mac_Q + prod_Q;
				state <= 5;
			elsif state = 5 then
				Data_out_I <= std_logic_vector(mac_I + to_signed(0,35))(27 downto 14);  
				Data_out_Q <= std_logic_vector(mac_Q + to_signed(0,35))(27 downto 14);
				state <= 6;
				deb <= '1';
			end if;
		end if;
	end process;
		
	
	
end filter_arch;








library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.ALL;

entity tx_upsample is
	port (Data_in_I : in std_logic_vector(23 downto 0);
			Data_in_Q : in std_logic_vector(23 downto 0);
			Data_out_I : out std_logic_vector(13 downto 0);
			Data_out_Q : out std_logic_vector(13 downto 0);
			clk20 : in std_logic; -- 20 MHz
			clk_sample : in std_logic;
			tx_att : in std_logic_vector(1 downto 0);
			clk_out : buffer std_logic
			);
end tx_upsample;

architecture filter_arch of tx_upsample is

type longbuffer is array (0 to 4) of signed (13 downto 0);
signal buffer_I, buffer_Q : longbuffer;
signal Data_in_I_buff, Data_in_Q_buff : signed (13 downto 0);
signal req, req0, req1, req2, req3 : std_logic := '0';
signal ack : std_logic := '0';

begin


	sample : process(ack, clk_sample)		
	begin
		if ack = '1' then
			req <= '0';
		elsif clk_sample'event and clk_sample='0' then
			req <= '1';
		end if;
	end process;
		
	p0 : process (clk20)
	variable mac_I, mac_Q : signed (15 downto 0);	
	variable count_div : integer range 0 to 799 := 0;
	begin
		if clk20'event and clk20 = '1' then 

					  
			req0 <= req;
			req1 <= req0;
			req2 <= req1;
			req3 <= req2;
			
			if req3 = '1' then
				ack <= '1';
			elsif req2 = '1' then
				if tx_att = "00" then
					Data_in_I_buff <= signed(Data_in_I(13 downto 0));
					Data_in_Q_buff <= signed(Data_in_Q(13 downto 0));
				elsif tx_att = "01" then
					Data_in_I_buff <= signed(Data_in_I(14 downto 1));
					Data_in_Q_buff <= signed(Data_in_Q(14 downto 1));
				elsif tx_att = "10" then
					Data_in_I_buff <= signed(Data_in_I(15 downto 2));
					Data_in_Q_buff <= signed(Data_in_Q(15 downto 2));
				else
					Data_in_I_buff <= signed(Data_in_I(16 downto 3));
					Data_in_Q_buff <= signed(Data_in_Q(16 downto 3));
				end if;
			else
				ack <= '0';
			end if;
			
			if count_div = 191 then
				mac_I :=       (buffer_I(0)(13) & buffer_I(0)(13) & buffer_I(0)(13 downto 0)) +
						      	(buffer_I(1)(13) & buffer_I(1)(13) & buffer_I(1)(13 downto 0));
																														-- 1,1
				mac_Q :=       (buffer_Q(0)(13) & buffer_Q(0)(13) & buffer_Q(0)(13 downto 0)) +
									(buffer_Q(1)(13) & buffer_Q(1)(13) & buffer_Q(1)(13 downto 0)); -- 1,1
				clk_out <= '0';
			elsif count_div = 287 then				
				Data_out_I <= std_logic_vector(mac_I(14 downto 1));   -- 0.5
				Data_out_Q <= std_logic_vector(mac_Q(14 downto 1));   -- 0.5
			elsif count_div = 383 then
				clk_out <= '1'; -- div by 384, for 52.0833 ksps
			elsif count_div = 575 then
				mac_I :=       buffer_I(0)(13) & buffer_I(0)(13) & buffer_I(0)(13 downto 0); -- 1
				mac_Q :=       buffer_Q(0)(13) & buffer_Q(0)(13) & buffer_Q(0)(13 downto 0); -- 1			
				clk_out <= '0';
			elsif count_div = 671 then
				Data_out_I <= std_logic_vector(mac_I(13 downto 0));  -- 1
				Data_out_Q <= std_logic_vector(mac_Q(13 downto 0));  -- 1
			elsif count_div = 767 and req2 = '0' then -- sample
				buffer_I(0) <= Data_in_I_buff;
				buffer_Q(0) <= Data_in_Q_buff;
				buffer_I(1) <= buffer_I(0);
				buffer_Q(1) <= buffer_Q(0);
				buffer_I(2) <= buffer_I(1);
				buffer_Q(2) <= buffer_Q(1);
				buffer_I(3) <= buffer_I(2);
				buffer_Q(3) <= buffer_Q(2);
				buffer_I(4) <= buffer_I(3);
				buffer_Q(4) <= buffer_Q(3);
				clk_out <= '1'; -- div by 384, for 52.0833 ksps
			end if;
			
			if count_div = 767 then
				count_div := 0;
			else
				count_div := count_div + 1;
			end if;
		end if;
	end process;
	
end filter_arch;