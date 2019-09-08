library ieee;
use ieee.std_logic_1164.ALL;
--use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.ALL;

entity noise_blanker is
	port (rx_data_in_I : in std_logic_vector(23 downto 0);
			rx_data_in_Q : in std_logic_vector(23 downto 0);
			clk_in : in std_logic;
			rx_data_out_I : out std_logic_vector(23 downto 0);
			rx_data_out_Q : out std_logic_vector(23 downto 0)
			);
end noise_blanker;

architecture nb_arch of noise_blanker is

type peakbuffer is array (0 to 512) of integer range 0 to 22;
--type peakbuffer is array (0 to 512) of unsigned(4 downto 0);

signal Data_in_I_reg, Data_in_Q_reg : std_logic_vector(23 downto 0);
signal Data_out_I_reg, Data_out_Q_reg : std_logic_vector(23 downto 0);

signal peakvals : peakbuffer;

signal peakval : integer range 0 to 22;
signal avgpeak : unsigned (13 downto 0);
signal write_pointer, read_pointer : integer range 0 to 745;

begin


	sample : process (clk_in)
	begin
		if clk_in'event and clk_in = '1' then
			Data_in_I_reg <= rx_data_in_I;
			Data_in_Q_reg <= rx_data_in_Q;
			rx_data_out_I <= Data_out_I_reg;
			rx_data_out_Q <= Data_out_Q_reg;
		end if;
	end process;
			
	peaksample: process (clk_in)
	variable peakval_v : integer range 0 to 22;
	variable i : integer range 0 to 99;
	variable j, k : integer range 0 to 745;
	begin
		if clk_in'event and clk_in = '1' then
		
			for n in 22 downto 0 loop
            if (Data_in_I_reg(23) = '0' and Data_in_I_reg(n) = '1') or
					(Data_in_I_reg(23) = '1' and Data_in_I_reg(n) = '0') or
               (Data_in_Q_reg(23) = '0' and Data_in_Q_reg(n) = '1') or
					(Data_in_Q_reg(23) = '1' and Data_in_Q_reg(n) = '0') then
					if n > peakval then
						peakval_v := n;
					end if;
            end if;
         end loop;
			peakval <= peakval_v;
			if i < 9 then
				i := i + 1;
			else					-- Every 10 samples store peak of the samples to buffer
				i := 0;
				if j < 744 then
					j := j + 1;
					k := j + 1;
				elsif i = 744 then
					j := 745;
					k := 0;
				else
					j := 0;
					k := 1;
				end if;
				write_pointer <= j;
				read_pointer <= k;
				peakvals(write_pointer) <= peakval;
				avgpeak <= avgpeak + to_unsigned(peakval,14) - to_unsigned(peakvals(read_pointer),14);
				peakval_v := 0;
			end if;

		end if;
	end process;
	
	limiter : process (clk_in)
	variable peakval : integer range 0 to 22;
	begin
		if clk_in'event and clk_in = '1' then
			for n in 22 downto 0 loop
            if (Data_in_I_reg(23) = '0' and Data_in_I_reg(n) = '1') or
					(Data_in_I_reg(23) = '1' and Data_in_I_reg(n) = '0') or
               (Data_in_Q_reg(23) = '0' and Data_in_Q_reg(n) = '1') or
					(Data_in_Q_reg(23) = '1' and Data_in_Q_reg(n) = '0') then
					if n > peakval then
						peakval := n;
					end if;
            end if;
         end loop;
			if (peakval > 1) and (peakval > to_integer(avgpeak(13 downto 9))) then
				Data_out_I_reg <= "000000000000000000000000";
				Data_out_Q_reg <= "000000000000000000000000";
			else
				Data_out_I_reg <= Data_in_I_reg;
				Data_out_Q_reg <= Data_out_Q_reg;
			end if;
		end if;
	end process;
	
	
end nb_arch;
