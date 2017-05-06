library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.ALL;

entity clk_select is
	port (tcxo_clk_in : in std_logic;
			ext_clk_in : in std_logic;
			TCXO_nEN : buffer std_logic := '0'
			);
end clk_select;

architecture select_arch of clk_select is

signal counter_a, counter_b : integer range 0 to 100000 := 0;
signal defined : std_logic := '0';
begin
				
	count_a : process (tcxo_clk_in) 
	begin
		if tcxo_clk_in'event and tcxo_clk_in='1' and defined = '0' then
			counter_a <= counter_a + 1;
			if counter_a > 90900 then
				defined <= '1';
				if counter_b > 20000 then
					TCXO_nEN <= '1'; -- turn off TCXO, select ext ref
				end if;
			end if;
		end if;
	end process;

	count_b : process (ext_clk_in) 
	begin
		if ext_clk_in'event and ext_clk_in='1' and defined = '0' then
			counter_b <= counter_b + 1;
		end if;
	end process;

end select_arch;