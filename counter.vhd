library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.ALL;

entity clkdiv is
	port (clk_in : in std_logic;
			clk_slow : out std_logic;
			POR : buffer std_logic_vector(1 downto 0) := "00"
			);
end clkdiv;

architecture counter_arch of clkdiv is

signal counter : std_logic_vector (22 downto 0);

begin
	clk_slow <= counter(22);
	
	count : process (clk_in) 
		begin
		if clk_in'event and clk_in='1' then
			counter <= counter + 1;
		end if;
		end process;
		
	reset : process (counter(11))
	variable rescount : integer range 0 to 2000 := 0;
		begin
			if counter(9)'event and counter(9) = '1' then
				if POR /= "11" then
					rescount := rescount + 1;
					if rescount < 500 then
						POR <= "00";
					elsif rescount < 1000 then
						POR <= "01";
					elsif rescount < 1500 then
						POR <= "10";
					elsif rescount = 2000 then
						POR <= "11";
					end if;
				end if;
			end if;
		end process reset;
	
end counter_arch;