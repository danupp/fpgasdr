library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.ALL;

entity cw_nco is
	port (ADDR : out std_logic_vector(7 downto 0);
			clk_in : in std_logic;  -- 39.0625 / 15 kHz
			key : in std_logic;
			tx : in std_logic;
			cos_raw : in std_logic_vector(8 downto 0);
			cos_out : out std_logic_vector(9 downto 0)
			);
end cw_nco;

architecture nco_arch of cw_nco is

signal reg1 : std_logic_vector(10 downto 0) := "00000000000";
signal sign_cos, sign_cos_reg : std_logic;

begin
	p0 : process(clk_in)
	begin
		if clk_in'event and clk_in = '1' and key = '1' then
			if tx = '1' then
				reg1 <= reg1 + 66;  -- 806 Hz, 25kHz fs	
			else
				reg1 <= reg1 + 42;  -- 801 Hz, 39.0625kHz fs	
			end if;
		end if;
	end process;

	p1 : process(clk_in)
	begin
		if clk_in'event and clk_in = '1' then
			if reg1(10 downto 9) = "00" then
				ADDR <= reg1(8 downto 1);
				sign_cos <= '0';
			elsif reg1(10 downto 9) = "01" then
				ADDR <= std_logic_vector(255 - reg1(8 downto 1));
				sign_cos <= '1';
			elsif reg1(10 downto 9) = "10" then
				ADDR <= reg1(8 downto 1);
				sign_cos <= '1';
			elsif reg1(10 downto 9) = "11" then
				ADDR <= std_logic_vector(255 - reg1(8 downto 1));
				sign_cos <= '0';
			end if;
		end if;
	end process;
	
	p2 : process(clk_in)
	begin
		if clk_in'event and clk_in = '1' then
			sign_cos_reg <= sign_cos;
			if sign_cos_reg = '0' then
				cos_out <= '0' & cos_raw;
			else
				cos_out <= std_logic_vector(- signed('0' & cos_raw));
			end if;
		end if;
	end process;
	
end nco_arch;