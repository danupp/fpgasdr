library ieee;
use ieee.std_logic_1164.ALL;
--use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.ALL;

entity tx_rx_agc is
	port (rx_data_in_I : in std_logic_vector(23 downto 0);
			rx_data_in_Q : in std_logic_vector(23 downto 0);
			clk_in : in std_logic;  -- 1.25 MHz
			tx_audio_in : in std_logic_vector(15 downto 0);
			tx : in std_logic;
			rx_data_out_I : out std_logic_vector(9 downto 0);
			rx_data_out_Q : out std_logic_vector(9 downto 0);
			tx_audio_out : out std_logic_vector(9 downto 0);
			rssi : out std_logic_vector(5 downto 0)
			);
end tx_rx_agc;

architecture tx_rx_agc_arch of tx_rx_agc is

signal Data_in_I_reg, Data_in_Q_reg : signed(23 downto 0);
signal Data_out_I_reg, Data_out_Q_reg : std_logic_vector(9 downto 0);

begin
	
	reg : process (clk_in)
	begin
		if clk_in'event and clk_in = '1' then
			if tx = '0' then 
				Data_in_I_reg <= signed(rx_data_in_I);
				Data_in_Q_reg <= signed(rx_data_in_Q);
				rx_data_out_I <= Data_out_I_reg;
				rx_data_out_Q <= Data_out_Q_reg;
			else
				Data_in_I_reg <= signed(tx_audio_in(15) & tx_audio_in(15) & tx_audio_in(15) & tx_audio_in(15) & tx_audio_in(15) & tx_audio_in(15) & tx_audio_in(15) & tx_audio_in(15) & tx_audio_in );
				Data_in_Q_reg <= to_signed(0,24);
				tx_audio_out <= Data_out_I_reg;
			end if;
		end if;
	end process;
	
	
	p0: process (clk_in)
	variable peak_a : integer range 0 to 22;
	variable agc_a, agc_a_I, agc_a_Q : integer range 8 to 22 := 16;
	variable peak_b, peak_b_old : integer range 0 to 2047 := 0;
	variable agc_b, agc_b_I, agc_b_Q : integer range 16 to 31 := 16;
	variable ticks, timelim : integer range 0 to 99999 := 0;
	constant timelim_rx : integer := 4000;
	constant timelim_tx : integer := 12000;
	variable Data_out_I_t, Data_out_Q_t : signed(9 downto 0);

	begin
		if clk_in'event and clk_in = '1' then
			for n in 22 downto 0 loop
            if (Data_in_I_reg(23) = '0' and Data_in_I_reg(n) = '1') or
					(Data_in_I_reg(23) = '1' and Data_in_I_reg(n) = '0') or
               (Data_in_Q_reg(23) = '0' and Data_in_Q_reg(n) = '1') or
					(Data_in_Q_reg(23) = '1' and Data_in_Q_reg(n) = '0') then
					if n > peak_a then
						peak_a := n;
					end if;
               exit;
            end if;
         end loop;

			if agc_a < 21 and 
			( peak_b < to_integer(abs(Data_in_I_reg(agc_a + 3 downto agc_a - 8))) or peak_b < to_integer(abs(Data_in_Q_reg(agc_a + 3 downto agc_a - 8))) ) then
				peak_b := to_integer(abs(Data_in_I_reg(agc_a + 3 downto agc_a - 8)));
				if peak_b < to_integer(abs(Data_in_Q_reg(agc_a + 3 downto agc_a - 8))) then
					peak_b := to_integer(abs(Data_in_Q_reg(agc_a + 3 downto agc_a - 8)));
				end if;
			elsif	peak_b < to_integer(abs(Data_in_I_reg(23 downto 13))) or peak_b < to_integer(abs(Data_in_Q_reg(23 downto 13)))then
				peak_b := to_integer(abs(Data_in_I_reg(23 downto 13)));
				if peak_b < to_integer(abs(Data_in_Q_reg(23 downto 13))) then
					peak_b := to_integer(abs(Data_in_Q_reg(23 downto 13)));
				end if;
			end if;				
				
			ticks := ticks + 1;
			
			if tx = '1' then
				timelim := timelim_tx;
			else
				timelim := timelim_rx;
			end if;
				
	      if peak_b - 20 > peak_b_old or 
				--peak_b > 500 or
				peak_a > agc_a + 1 or 
				ticks > timelim then
				
				if peak_a > agc_a + 1 then
					agc_a := peak_a;
					agc_b := 16;
					
				elsif (peak_b > 761 and agc_a < 21) or peak_a = agc_a + 1 then
					agc_a := agc_a + 2;		-- -4
					agc_b := 31;				-- 1 + 15/16
			
				elsif peak_b > 721 and agc_a < 22 then
					agc_a := agc_a + 1; 		-- -2
					agc_b := 16;		  		-- 1 			
				elsif peak_b > 681 and agc_a < 22 then
					agc_a := agc_a + 1; 		-- -2
					agc_b := 17;		  		-- 1 + 1/16 			
				elsif peak_b > 645 and agc_a < 22 then
					agc_a := agc_a + 1; 		-- -2
					agc_b := 18;		  		-- 1 + 2/16 			
				elsif peak_b > 613 and agc_a < 22 then
					agc_a := agc_a + 1; 		-- -2
					agc_b := 19;		  		-- 1 + 3/16 			
				elsif peak_b > 584 and agc_a < 22 then
					agc_a := agc_a + 1; 		-- -2
					agc_b := 20;		  		-- 1 + 4/16 			
				elsif peak_b > 557 and agc_a < 22 then
					agc_a := agc_a + 1; 		-- -2
					agc_b := 21;		  		-- 1 + 5/16 			
				elsif peak_b > 533 and agc_a < 22 then
					agc_a := agc_a + 1; 		-- -2
					agc_b := 22;		  		-- 1 + 6/16 			
				elsif peak_b > 511 and agc_a < 22 then
					agc_a := agc_a + 1; 		-- -2
					agc_b := 23;		  		-- 1 + 7/16 			
				elsif peak_b > 490 and agc_a < 22 then
					agc_a := agc_a + 1; 		-- -2
					agc_b := 24;		  		-- 1 + 8/16 			
				elsif peak_b > 471 and agc_a < 22 then
					agc_a := agc_a + 1; 		-- -2
					agc_b := 25;		  		-- 1 + 9/16 			
				elsif peak_b > 454 and agc_a < 22 then
					agc_a := agc_a + 1; 		-- -2
					agc_b := 26;		  		-- 1 + 10/16 			
				elsif peak_b > 438 and agc_a < 22 then
					agc_a := agc_a + 1; 		-- -2
					agc_b := 27;		  		-- 1 + 11/16 			
				elsif peak_b > 423 and agc_a < 22 then
					agc_a := agc_a + 1; 		-- -2
					agc_b := 28;		  		-- 1 + 12/16 			
				elsif peak_b > 409 and agc_a < 22 then
					agc_a := agc_a + 1; 		-- -2
					agc_b := 29;		  		-- 1 + 13/16 			
				elsif peak_b > 395 and agc_a < 22 then
					agc_a := agc_a + 1; 		-- -2
					agc_b := 30;		  		-- 1 + 14/16
				elsif peak_b > 383 and agc_a < 22 then
					agc_a := agc_a + 1; 		-- -2
					agc_b := 31;		  		-- 1 + 15/16 			
					
				elsif peak_b > 360 and agc_a > 7 then
					agc_b := 16;		  		-- 1 
				elsif peak_b > 340 and agc_a > 7 then
					agc_b := 17;				-- 1 + 1/16 => max 383
				elsif peak_b > 323 and agc_a > 7 then
					agc_b := 18;				-- 1 + 2/16
				elsif peak_b > 306 and agc_a > 7 then
					agc_b := 19;
				elsif peak_b > 292 and agc_a > 7 then
					agc_b := 20;
				elsif peak_b > 279 and agc_a > 7 then
					agc_b := 21;
				elsif peak_b > 266 and agc_a > 7 then
					agc_b := 22;
				elsif peak_b > 255 and agc_a > 7 then
					agc_b := 23;
				elsif peak_b > 245 and agc_a > 7 then
					agc_b := 24;
				elsif peak_b > 237 and agc_a > 7 then
					agc_b := 25;
				elsif peak_b > 227 and agc_a > 7 then
					agc_b := 26;
				elsif peak_b > 219 and agc_a > 7 then
					agc_b := 27;
				elsif peak_b > 211 and agc_a > 7 then
					agc_b := 28;
				elsif peak_b > 204 and agc_a > 7 then
					agc_b := 29;
				elsif peak_b > 198 and agc_a > 7 then
					agc_b := 30;
				elsif peak_b > 191 and agc_a > 7 then
					agc_b := 31;				-- 1 + 15/16
					
				elsif peak_b > 180 and agc_a > 8 then
					agc_a := agc_a - 1; 		-- +2
					agc_b := 16;		  		-- 1 			
				elsif peak_b > 170 and agc_a > 8 then
					agc_a := agc_a - 1; 		-- +2
					agc_b := 17;		  		-- 1 + 1/16 			
				elsif peak_b > 161 and agc_a > 8 then
					agc_a := agc_a - 1; 		-- +2
					agc_b := 18;		  		-- 1 + 2/16 			
				elsif peak_b > 153 and agc_a > 8 then
					agc_a := agc_a - 1; 		-- +2
					agc_b := 19;		  		-- 1 + 3/16 			
				elsif peak_b > 146 and agc_a > 8 then
					agc_a := agc_a - 1; 		-- +2
					agc_b := 20;		  		-- 1 + 4/16 			
				elsif peak_b > 139 and agc_a > 8 then
					agc_a := agc_a - 1; 		-- +2
					agc_b := 21;		  		-- 1 + 5/16 			
				elsif peak_b > 133 and agc_a > 8 then
					agc_a := agc_a - 1; 		-- +2
					agc_b := 22;		  		-- 1 + 6/16 			
				elsif peak_b > 129 and agc_a > 8 then
					agc_a := agc_a - 1; 		-- +2
					agc_b := 23;		  		-- 1 + 7/16 			
				elsif peak_b > 122 and agc_a > 8 then
					agc_a := agc_a - 1; 		-- +2
					agc_b := 24;		  		-- 1 + 8/16 			
				elsif peak_b > 118 and agc_a > 8 then
					agc_a := agc_a - 1; 		-- +2
					agc_b := 25;		  		-- 1 + 9/16 			
				elsif peak_b > 113 and agc_a > 8 then
					agc_a := agc_a - 1; 		-- +2
					agc_b := 26;		  		-- 1 + 10/16 			
				elsif peak_b > 109 and agc_a > 8 then
					agc_a := agc_a - 1; 		-- +2
					agc_b := 27;		  		-- 1 + 11/16 	
				elsif peak_b > 105 and agc_a > 8 then
					agc_a := agc_a - 1; 		-- +2
					agc_b := 28;		  		-- 1 + 12/16 			
				elsif peak_b > 102 and agc_a > 8 then
					agc_a := agc_a - 1; 		-- +2
					agc_b := 29;		  		-- 1 + 13/16 			
				elsif peak_b > 99 and agc_a > 8 then
					agc_a := agc_a - 1; 		-- +2
					agc_b := 30;		  		-- 1 + 14/16 			
				elsif peak_b > 95 and agc_a > 8 then
					agc_a := agc_a - 1; 		-- +2
					agc_b := 31;		  		-- 1 + 15/16 	
					
				elsif peak_b < 96 and agc_a > 9 then 
					agc_a := agc_a - 2;		-- +4
					agc_b := 16;				-- 1
					
				elsif agc_a = 8 then 
					agc_b := 31;				
				end if;
				
				if peak_b > 766 then
					peak_b_old := to_integer(to_unsigned(peak_b, 12) srl 2 );  -- div by 4
				elsif peak_b > 383 then
					peak_b_old := to_integer(to_unsigned(peak_b, 9) srl 1 );  -- div by 2
				elsif peak_b > 191 then
					peak_b_old := peak_b;
				elsif peak_b > 95 then
					peak_b_old := to_integer(to_unsigned(peak_b, 9) sll 1 );  -- mult by 2
				else
					peak_b_old := to_integer(to_unsigned(peak_b, 9) sll 2 );  -- mult by 4
				end if;	
				
				rssi <= std_logic_vector(to_unsigned(peak_a,6));
				
				peak_a := 0;
				peak_b := 0;
				ticks := 0;
				
         end if;

			--if Data_out_I_reg(9 downto 5) = "00000" or Data_out_I_reg(9 downto 5) = "11111" then
				agc_a_I := agc_a;
				agc_b_I := agc_b;
			--end if;
			
			--if Data_out_Q_reg(9 downto 5) = "00000" or Data_out_Q_reg(9 downto 5) = "11111" then
				agc_a_Q := agc_a;
				agc_b_Q := agc_b;
			--end if;
			
			if agc_a_I < 9 then
				Data_out_I_t := Data_in_I_reg(9 downto 0);
			elsif (agc_a_I < 22) and (agc_a_I > 8) then
            Data_out_I_t := signed(Data_in_I_reg + signed(signed'("000000000000000000000001") sll (agc_a_I - 9)))(agc_a_I + 1 downto agc_a_I - 8);
			else
            Data_out_I_t := signed(Data_in_I_reg + to_signed(8192,24))(23 downto 14);
			end if;

			if agc_a_Q < 9 then
				Data_out_Q_t := Data_in_Q_reg(9 downto 0);
			elsif (agc_a_Q < 22) and (agc_a_Q > 8) then
				Data_out_Q_t := signed(Data_in_Q_reg + signed(signed'("000000000000000000000001") sll (agc_a_Q - 9)))(agc_a_Q + 1 downto agc_a_Q - 8);
			else
				Data_out_Q_t := signed(Data_in_Q_reg + to_signed(8192,24))(23 downto 14);
			end if;
			
			Data_out_I_reg <= std_logic_vector(Data_out_I_t * to_signed(agc_b_I,6))(13 downto 4);
			Data_out_Q_reg <= std_logic_vector(Data_out_Q_t * to_signed(agc_b_Q,6))(13 downto 4);
			
		end if;
	end process;    


end tx_rx_agc_arch;


library ieee;
use ieee.std_logic_1164.ALL;
--use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.ALL;

entity tx_rx_agc_bypass is
	port (rx_data_in_I : in std_logic_vector(23 downto 0);
			rx_data_in_Q : in std_logic_vector(23 downto 0);
			clk_in : in std_logic;  -- 1.25 MHz
			tx_audio_in : in std_logic_vector(15 downto 0);
			tx : in std_logic;
			rx_data_out_I : out std_logic_vector(9 downto 0);
			rx_data_out_Q : out std_logic_vector(9 downto 0);
			tx_audio_out : out std_logic_vector(9 downto 0);
			rssi : out std_logic_vector(4 downto 0)
			);
end tx_rx_agc_bypass;

architecture agcb_arch of tx_rx_agc_bypass is

begin

rx_data_out_I <= rx_data_in_I(12 downto 3);
rx_data_out_Q <= rx_data_in_Q(12 downto 3);
tx_audio_out <= tx_audio_in(9 downto 0);
rssi <= "00100";

end agcb_arch;



	
library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

entity post_agc_rx_filt is
	port (data_in_I : in std_logic_vector(9 downto 0);
			data_in_Q : in std_logic_vector(9 downto 0);
			data_out_I : out std_logic_vector(9 downto 0);
			data_out_Q : out std_logic_vector(9 downto 0);
			clk20 : in std_logic; -- 20 MHz
			clk_sample : in std_logic; -- 39 kHz
			ssb_am : in std_logic;
			wide_narrow : in std_logic;
			tx : in std_logic;
			bypass : in std_logic
			);
end post_agc_rx_filt;

architecture filter_arch of post_agc_rx_filt is
	
type longbuffer is array (0 to 260) of signed (9 downto 0);
type filt_type is array (0 to 126) of signed (9 downto 0);

signal data_in_buffer_I, data_in_buffer_Q : longbuffer;

constant ssb_wide : filt_type :=
--Scilab:
--> [v,a,f] = wfir ('lp', 256, [1.6/39 0], 'hn', [0 0]);
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
    "0000000001",
    "0000000001",
    "0000000001",
    "0000000001",
    "0000000001",
    "0000000001",
    "0000000001",
    "0000000001",
    "0000000000",
    "0000000000",
    "0000000000",
    "1111111111",
    "1111111110",
    "1111111110",
    "1111111110",
    "1111111101",
    "1111111101",
    "1111111101",
    "1111111110",
    "1111111110",
    "1111111111",
    "0000000000",
    "0000000001",
    "0000000010",
    "0000000011",
    "0000000100",
    "0000000101",
    "0000000101",
    "0000000101",
    "0000000101",
    "0000000101",
    "0000000100",
    "0000000010",
    "0000000001",
    "1111111111",
    "1111111101",
    "1111111011",
    "1111111010",
    "1111111000",
    "1111110111",
    "1111110111",
    "1111110111",
    "1111111000",
    "1111111010",
    "1111111100",
    "1111111110",
    "0000000001",
    "0000000100",
    "0000000111",
    "0000001010",
    "0000001100",
    "0000001110",
    "0000001111",
    "0000001110",
    "0000001101",
    "0000001011",
    "0000000111",
    "0000000011",
    "1111111111",
    "1111111010",
    "1111110101",
    "1111110001",
    "1111101101",
    "1111101010",
    "1111101001",
    "1111101001",
    "1111101011",
    "1111101110",
    "1111110011",
    "1111111001",
    "0000000000",
    "0000001000",
    "0000010000",
    "0000010111",
    "0000011101",
    "0000100010",
    "0000100101",
    "0000100101",
    "0000100011",
    "0000011110",
    "0000010111",
    "0000001101",
    "0000000010",
    "1111110101",
    "1111100111",
    "1111011010",
    "1111001110",
    "1111000100",
    "1110111101",
    "1110111010",
    "1110111100",
    "1111000011",
    "1111001111",
    "1111100001",
    "1111111000",
    "0000010100",
    "0000110011",
    "0001010110",
    "0001111011",
    "0010100001",
    "0011000110",
    "0011101001",
    "0100001001",
    "0100100100",
    "0100111001",
    "0101001000",
    "0101001111");

constant cw_narrow : filt_type :=
--Scilab:
--> [v,a,f] = wfir ('lp', 256, [0.45/39 0], 'hn', [0 0]);
--> round(v*2^14)
   ("0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000001",
    "0000000001",
    "0000000001",
    "0000000001",
    "0000000001",
    "0000000001",
    "0000000010",
    "0000000010",
    "0000000010",
    "0000000011",
    "0000000011",
    "0000000011",
    "0000000011",
    "0000000100",
    "0000000100",
    "0000000100",
    "0000000100",
    "0000000101",
    "0000000101",
    "0000000101",
    "0000000101",
    "0000000101",
    "0000000101",
    "0000000101",
    "0000000100",
    "0000000100",
    "0000000100",
    "0000000011",
    "0000000010",
    "0000000010",
    "0000000001",
    "0000000000",
    "1111111111",
    "1111111110",
    "1111111100",
    "1111111011",
    "1111111001",
    "1111111000",
    "1111110110",
    "1111110100",
    "1111110010",
    "1111110000",
    "1111101110",
    "1111101100",
    "1111101010",
    "1111101000",
    "1111100110",
    "1111100100",
    "1111100001",
    "1111011111",
    "1111011110",
    "1111011100",
    "1111011010",
    "1111011000",
    "1111010111",
    "1111010110",
    "1111010101",
    "1111010100",
    "1111010011",
    "1111010011",
    "1111010011",
    "1111010100",
    "1111010100",
    "1111010110",
    "1111010111",
    "1111011001",
    "1111011011",
    "1111011110",
    "1111100001",
    "1111100101",
    "1111101001",
    "1111101110",
    "1111110011",
    "1111111001",
    "1111111111",
    "0000000110",
    "0000001101",
    "0000010100",
    "0000011100",
    "0000100101",
    "0000101110",
    "0000110111",
    "0001000001",
    "0001001011",
    "0001010101",
    "0001100000",
    "0001101011",
    "0001110111",
    "0010000010",
    "0010001110",
    "0010011010",
    "0010100110",
    "0010110010",
    "0010111110",
    "0011001010",
    "0011010110",
    "0011100010",
    "0011101110",
    "0011111001",
    "0100000100",
    "0100001111",
    "0100011010",
    "0100100100",
    "0100101110",
    "0100111000",
    "0101000001",
    "0101001001",
    "0101010001",
    "0101011000",
    "0101011111",
    "0101100101",
    "0101101010",
    "0101101110",
    "0101110010",
    "0101110101",
    "0101111000",
    "0101111001",
    "0101111010");

constant am_filter : filt_type :=

-->[v,a,f] = wfir ('lp', 256, [7.5/39 0], 'hn', [0 0]);
-->round(v*2^10)

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
    "1111111111",
    "0000000000",
    "0000000000",
    "0000000001",
    "0000000000",
    "1111111111",
    "1111111111",
    "0000000000",
    "0000000001",
    "0000000000",
    "1111111111",
    "1111111111",
    "0000000000",
    "0000000001",
    "0000000001",
    "1111111111",
    "1111111111",
    "0000000000",
    "0000000001",
    "0000000001",
    "1111111111",
    "1111111110",
    "1111111111",
    "0000000010",
    "0000000010",
    "0000000000",
    "1111111110",
    "1111111111",
    "0000000001",
    "0000000011",
    "0000000000",
    "1111111110",
    "1111111110",
    "0000000001",
    "0000000011",
    "0000000001",
    "1111111101",
    "1111111101",
    "0000000000",
    "0000000100",
    "0000000010",
    "1111111110",
    "1111111100",
    "1111111111",
    "0000000100",
    "0000000100",
    "1111111110",
    "1111111011",
    "1111111110",
    "0000000100",
    "0000000101",
    "1111111111",
    "1111111010",
    "1111111100",
    "0000000100",
    "0000000111",
    "0000000001",
    "1111111001",
    "1111111010",
    "0000000011",
    "0000001001",
    "0000000011",
    "1111111001",
    "1111110111",
    "0000000001",
    "0000001010",
    "0000000110",
    "1111111001",
    "1111110100",
    "1111111110",
    "0000001100",
    "0000001011",
    "1111111011",
    "1111110000",
    "1111111010",
    "0000001101",
    "0000010001",
    "1111111110",
    "1111101011",
    "1111110011",
    "0000001110",
    "0000011011",
    "0000000100",
    "1111100010",
    "1111100100",
    "0000001111",
    "0000110010",
    "0000010101",
    "1111001010",
    "1110101110",
    "0000010000",
    "0011010011",
    "0101110010");

	
signal sample : boolean := false;
signal to_sample : boolean := false;
signal sampled : boolean := false;
signal state : integer range 0 to 6 := 0;
signal write_pointer : integer range 0 to 260 := 255;
signal read_pointer : integer range 0 to 260 := 255;
signal asynch_data_read_I, asynch_data_read_Q, synch_data_read_I, synch_data_read_Q : signed (9 downto 0);
signal mac_I, mac_Q : signed (25 downto 0);
signal prod_I, prod_Q : signed (19 downto 0);
	

begin
	
	p0 : process (clk20)
	variable indata_I, indata_Q : signed (9 downto 0);
	begin	
		if clk20'event and clk20 = '1' then
			if sample = true then
				to_sample <= true; -- sample at next clock cycle
			elsif to_sample = true then -- sample and write to RAM
				indata_I := signed(data_in_I);
				indata_Q := signed(data_in_Q);
				data_in_buffer_I(write_pointer) <= indata_I;
				data_in_buffer_Q(write_pointer) <= indata_Q;
				to_sample <= false;
				sampled <= true;
			else
				sampled <= false;

			end if;
			asynch_data_read_I <= data_in_buffer_I(read_pointer);
			asynch_data_read_Q <= data_in_buffer_Q(read_pointer);
			synch_data_read_I <= asynch_data_read_I;
			synch_data_read_Q <= asynch_data_read_Q;
				
		end if;
	end process;
	
	sample_ff : process(clk_sample,sampled)
	begin
		if to_sample = true or tx='1' then
			sample <= false;
		elsif clk_sample'event and clk_sample = '1' then
			sample <= true;
		end if;
	end process;
			
	p1 : process (clk20)
	variable filtkoeff : signed(9 downto 0);
	variable n : integer range 0 to 270 := 0;
	variable p : integer range 0 to 540;
	variable k : integer range 0 to 126;
	
	begin
		if clk20'event and clk20 = '0' then 
				
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
				mac_I <= to_signed(0,26);
				mac_Q <= to_signed(0,26);
				prod_I <= to_signed(0,20);
				prod_Q <= to_signed(0,20);
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
				
				prod_I <= synch_data_read_I * filtkoeff;
				prod_Q <= synch_data_read_Q * filtkoeff;
				mac_I <= mac_I + prod_I;
				mac_Q <= mac_Q + prod_Q;
				
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
				mac_I <= mac_I + prod_I;
				mac_Q <= mac_Q + prod_Q;
				state <= 5;
			elsif state = 5 then
				if bypass = '1' then
					data_out_I <= data_in_I;
					data_out_Q <= data_in_Q;
				elsif ssb_am = '0' then
					data_out_I <= std_logic_vector(mac_I)(19 downto 10);
					data_out_Q <= std_logic_vector(mac_Q)(19 downto 10);
				else
					if wide_narrow = '1' then
						data_out_I <= std_logic_vector(mac_I)(21 downto 12);
						data_out_Q <= std_logic_vector(mac_Q)(21 downto 12);
					else
						data_out_I <= std_logic_vector(mac_I)(23 downto 14);
						data_out_Q <= std_logic_vector(mac_Q)(23 downto 14);
					end if;
				end if;
				state <= 6;
			end if;
		end if;
	end process;
	
end filter_arch;

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

entity post_agc_filt is
	port (data_in_I : in std_logic_vector(9 downto 0);
			data_in_Q : in std_logic_vector(9 downto 0);
			data_in_TX : in std_logic_vector(9 downto 0);
			data_out_I : out std_logic_vector(9 downto 0);
			data_out_Q : out std_logic_vector(9 downto 0);
			data_out_TX : out std_logic_vector(9 downto 0);
			clk20 : in std_logic; -- 20 MHz
			clk_sample : in std_logic; -- 26 / 39 kHz
			ssb_am : in std_logic;
			wide_narrow : in std_logic;
			tx : in std_logic;
			bypass : in std_logic
			);
end post_agc_filt;

architecture filter_arch of post_agc_filt is
	
type longbuffer is array (0 to 260) of signed (9 downto 0);
type filt_type is array (0 to 126) of signed (9 downto 0);

signal data_in_buffer_I, data_in_buffer_Q : longbuffer;

constant tx_filter : filt_type :=
--Scilab:
--> [v,a,f] = wfir ('lp', 256, [3.2/26 0], 'hn', [0 0]);
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
    "1111111111",
    "0000000000",
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
    "0000000001",
    "0000000001",
    "0000000000",
    "1111111111",
    "1111111110",
    "1111111111",
    "0000000000",
    "0000000001",
    "0000000010",
    "0000000010",
    "0000000000",
    "1111111111",
    "1111111110",
    "1111111110",
    "1111111111",
    "0000000001",
    "0000000011",
    "0000000011",
    "0000000001",
    "1111111110",
    "1111111100",
    "1111111101",
    "1111111111",
    "0000000010",
    "0000000100",
    "0000000100",
    "0000000010",
    "1111111110",
    "1111111011",
    "1111111011",
    "1111111110",
    "0000000010",
    "0000000101",
    "0000000110",
    "0000000011",
    "1111111110",
    "1111111010",
    "1111111001",
    "1111111100",
    "0000000010",
    "0000000111",
    "0000001000",
    "0000000101",
    "1111111110",
    "1111111000",
    "1111110110",
    "1111111010",
    "0000000010",
    "0000001001",
    "0000001011",
    "0000000111",
    "1111111111",
    "1111110110",
    "1111110011",
    "1111110111",
    "0000000001",
    "0000001011",
    "0000010000",
    "0000001011",
    "0000000000",
    "1111110100",
    "1111101110",
    "1111110010",
    "1111111111",
    "0000001110",
    "0000010110",
    "0000010010",
    "0000000010",
    "1111110000",
    "1111100101",
    "1111101010",
    "1111111100",
    "0000010011",
    "0000100001",
    "0000011101",
    "0000000111",
    "1111101010",
    "1111010101",
    "1111011000",
    "1111110100",
    "0000011100",
    "0000111011",
    "0000111011",
    "0000010110",
    "1111011000",
    "1110100001",
    "1110010110",
    "1111010000",
    "0001001110",
    "0011110100",
    "0110001110",
    "0111101100");
	 
constant ssb_wide : filt_type :=
--Scilab:
--> [v,a,f] = wfir ('lp', 256, [1.6/39 0], 'hn', [0 0]);
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
    "0000000001",
    "0000000001",
    "0000000001",
    "0000000001",
    "0000000001",
    "0000000001",
    "0000000001",
    "0000000001",
    "0000000000",
    "0000000000",
    "0000000000",
    "1111111111",
    "1111111110",
    "1111111110",
    "1111111110",
    "1111111101",
    "1111111101",
    "1111111101",
    "1111111110",
    "1111111110",
    "1111111111",
    "0000000000",
    "0000000001",
    "0000000010",
    "0000000011",
    "0000000100",
    "0000000101",
    "0000000101",
    "0000000101",
    "0000000101",
    "0000000101",
    "0000000100",
    "0000000010",
    "0000000001",
    "1111111111",
    "1111111101",
    "1111111011",
    "1111111010",
    "1111111000",
    "1111110111",
    "1111110111",
    "1111110111",
    "1111111000",
    "1111111010",
    "1111111100",
    "1111111110",
    "0000000001",
    "0000000100",
    "0000000111",
    "0000001010",
    "0000001100",
    "0000001110",
    "0000001111",
    "0000001110",
    "0000001101",
    "0000001011",
    "0000000111",
    "0000000011",
    "1111111111",
    "1111111010",
    "1111110101",
    "1111110001",
    "1111101101",
    "1111101010",
    "1111101001",
    "1111101001",
    "1111101011",
    "1111101110",
    "1111110011",
    "1111111001",
    "0000000000",
    "0000001000",
    "0000010000",
    "0000010111",
    "0000011101",
    "0000100010",
    "0000100101",
    "0000100101",
    "0000100011",
    "0000011110",
    "0000010111",
    "0000001101",
    "0000000010",
    "1111110101",
    "1111100111",
    "1111011010",
    "1111001110",
    "1111000100",
    "1110111101",
    "1110111010",
    "1110111100",
    "1111000011",
    "1111001111",
    "1111100001",
    "1111111000",
    "0000010100",
    "0000110011",
    "0001010110",
    "0001111011",
    "0010100001",
    "0011000110",
    "0011101001",
    "0100001001",
    "0100100100",
    "0100111001",
    "0101001000",
    "0101001111");

constant cw_narrow : filt_type :=
--Scilab:
--> [v,a,f] = wfir ('lp', 256, [0.45/39 0], 'hn', [0 0]);
--> round(v*2^14)
   ("0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000000",
    "0000000001",
    "0000000001",
    "0000000001",
    "0000000001",
    "0000000001",
    "0000000001",
    "0000000010",
    "0000000010",
    "0000000010",
    "0000000011",
    "0000000011",
    "0000000011",
    "0000000011",
    "0000000100",
    "0000000100",
    "0000000100",
    "0000000100",
    "0000000101",
    "0000000101",
    "0000000101",
    "0000000101",
    "0000000101",
    "0000000101",
    "0000000101",
    "0000000100",
    "0000000100",
    "0000000100",
    "0000000011",
    "0000000010",
    "0000000010",
    "0000000001",
    "0000000000",
    "1111111111",
    "1111111110",
    "1111111100",
    "1111111011",
    "1111111001",
    "1111111000",
    "1111110110",
    "1111110100",
    "1111110010",
    "1111110000",
    "1111101110",
    "1111101100",
    "1111101010",
    "1111101000",
    "1111100110",
    "1111100100",
    "1111100001",
    "1111011111",
    "1111011110",
    "1111011100",
    "1111011010",
    "1111011000",
    "1111010111",
    "1111010110",
    "1111010101",
    "1111010100",
    "1111010011",
    "1111010011",
    "1111010011",
    "1111010100",
    "1111010100",
    "1111010110",
    "1111010111",
    "1111011001",
    "1111011011",
    "1111011110",
    "1111100001",
    "1111100101",
    "1111101001",
    "1111101110",
    "1111110011",
    "1111111001",
    "1111111111",
    "0000000110",
    "0000001101",
    "0000010100",
    "0000011100",
    "0000100101",
    "0000101110",
    "0000110111",
    "0001000001",
    "0001001011",
    "0001010101",
    "0001100000",
    "0001101011",
    "0001110111",
    "0010000010",
    "0010001110",
    "0010011010",
    "0010100110",
    "0010110010",
    "0010111110",
    "0011001010",
    "0011010110",
    "0011100010",
    "0011101110",
    "0011111001",
    "0100000100",
    "0100001111",
    "0100011010",
    "0100100100",
    "0100101110",
    "0100111000",
    "0101000001",
    "0101001001",
    "0101010001",
    "0101011000",
    "0101011111",
    "0101100101",
    "0101101010",
    "0101101110",
    "0101110010",
    "0101110101",
    "0101111000",
    "0101111001",
    "0101111010");

constant am_filter : filt_type :=

-->[v,a,f] = wfir ('lp', 256, [7.5/39 0], 'hn', [0 0]);
-->round(v*2^10)

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
    "1111111111",
    "0000000000",
    "0000000000",
    "0000000001",
    "0000000000",
    "1111111111",
    "1111111111",
    "0000000000",
    "0000000001",
    "0000000000",
    "1111111111",
    "1111111111",
    "0000000000",
    "0000000001",
    "0000000001",
    "1111111111",
    "1111111111",
    "0000000000",
    "0000000001",
    "0000000001",
    "1111111111",
    "1111111110",
    "1111111111",
    "0000000010",
    "0000000010",
    "0000000000",
    "1111111110",
    "1111111111",
    "0000000001",
    "0000000011",
    "0000000000",
    "1111111110",
    "1111111110",
    "0000000001",
    "0000000011",
    "0000000001",
    "1111111101",
    "1111111101",
    "0000000000",
    "0000000100",
    "0000000010",
    "1111111110",
    "1111111100",
    "1111111111",
    "0000000100",
    "0000000100",
    "1111111110",
    "1111111011",
    "1111111110",
    "0000000100",
    "0000000101",
    "1111111111",
    "1111111010",
    "1111111100",
    "0000000100",
    "0000000111",
    "0000000001",
    "1111111001",
    "1111111010",
    "0000000011",
    "0000001001",
    "0000000011",
    "1111111001",
    "1111110111",
    "0000000001",
    "0000001010",
    "0000000110",
    "1111111001",
    "1111110100",
    "1111111110",
    "0000001100",
    "0000001011",
    "1111111011",
    "1111110000",
    "1111111010",
    "0000001101",
    "0000010001",
    "1111111110",
    "1111101011",
    "1111110011",
    "0000001110",
    "0000011011",
    "0000000100",
    "1111100010",
    "1111100100",
    "0000001111",
    "0000110010",
    "0000010101",
    "1111001010",
    "1110101110",
    "0000010000",
    "0011010011",
    "0101110010");

	
signal sample : boolean := false;
signal to_sample : boolean := false;
signal sampled : boolean := false;
signal state : integer range 0 to 6 := 0;
signal write_pointer : integer range 0 to 260 := 255;
signal read_pointer : integer range 0 to 260 := 255;
signal asynch_data_read_I, asynch_data_read_Q, synch_data_read_I, synch_data_read_Q : signed (9 downto 0);
signal mac_I, mac_Q : signed (25 downto 0);
signal prod_I, prod_Q : signed (19 downto 0);
	

begin
	
	p0 : process (clk20)
	variable indata_I, indata_Q : signed (9 downto 0);
	begin	
		if clk20'event and clk20 = '1' then
			if sample = true then
				to_sample <= true; -- sample at next clock cycle
			elsif to_sample = true then -- sample and write to RAM
				if tx = '0' then 
					indata_I := signed(data_in_I);
					indata_Q := signed(data_in_Q);
					data_in_buffer_I(write_pointer) <= indata_I;
					data_in_buffer_Q(write_pointer) <= indata_Q;
				else
					indata_I := signed(data_in_TX);
					data_in_buffer_I(write_pointer) <= indata_I;
				end if;
				to_sample <= false;
				sampled <= true;
			else
				sampled <= false;

			end if;
			asynch_data_read_I <= data_in_buffer_I(read_pointer);
			asynch_data_read_Q <= data_in_buffer_Q(read_pointer);
			synch_data_read_I <= asynch_data_read_I;
			synch_data_read_Q <= asynch_data_read_Q;
				
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
			
	p1 : process (clk20)
	variable filtkoeff : signed(9 downto 0);
	variable n : integer range 0 to 270 := 0;
	variable p : integer range 0 to 540;
	variable k : integer range 0 to 126;
	
	begin
		if clk20'event and clk20 = '0' then 
				
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
				mac_I <= to_signed(0,26);
				mac_Q <= to_signed(0,26);
				prod_I <= to_signed(0,20);
				prod_Q <= to_signed(0,20);
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
				
				if tx = '1' then
					filtkoeff := tx_filter(k);
				elsif ssb_am = '0' then
					filtkoeff := am_filter(k);
				else
					if wide_narrow = '1' then
						filtkoeff := ssb_wide(k);
					else
						filtkoeff := cw_narrow(k);
					end if;
				end if;
				
				prod_I <= synch_data_read_I * filtkoeff;
				prod_Q <= synch_data_read_Q * filtkoeff;
				mac_I <= mac_I + prod_I;
				mac_Q <= mac_Q + prod_Q;
				
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
				mac_I <= mac_I + prod_I;
				mac_Q <= mac_Q + prod_Q;
				state <= 5;
			elsif state = 5 then
				if bypass = '1' then
					data_out_I <= data_in_I;
					data_out_Q <= data_in_Q;
				elsif tx = '1' then
					data_out_TX <= std_logic_vector(mac_I)(20 downto 11);
				elsif ssb_am = '0' then
					data_out_I <= std_logic_vector(mac_I)(19 downto 10);
					data_out_Q <= std_logic_vector(mac_Q)(19 downto 10);
				else
					if wide_narrow = '1' then
						data_out_I <= std_logic_vector(mac_I)(21 downto 12);
						data_out_Q <= std_logic_vector(mac_Q)(21 downto 12);
					else
						data_out_I <= std_logic_vector(mac_I)(23 downto 14);
						data_out_Q <= std_logic_vector(mac_Q)(23 downto 14);
					end if;
				end if;
				state <= 6;
			end if;
		end if;
	end process;
	
end filter_arch;