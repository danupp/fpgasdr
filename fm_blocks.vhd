library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.ALL;

entity atan_addr_trunk is
	port (I_in : in std_logic_vector(9 downto 0);
			Q_in : in std_logic_vector(9 downto 0);
			ADDR : out std_logic_vector(13 downto 0)
			);
end atan_addr_trunk;

architecture trunk_arch of atan_addr_trunk is

begin

ADDR <= Q_in(9 downto 3) & I_in(9 downto 3);

end trunk_arch;




library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.ALL;

entity differentiator is
	port (data_in : in std_logic_vector(7 downto 0);
			data_out : out std_logic_vector(9 downto 0);
			clk_sample : in std_logic;
			enable : in std_logic
			);
end differentiator;

architecture diff_arch1 of differentiator is

signal reg0, reg1, reg2 : signed(7 downto 0);
signal diff_sig : signed(8 downto 0);

begin

	p1 : process(clk_sample)
	begin
		if clk_sample'event and clk_sample = '1' and enable = '1' then
			reg0 <= signed(data_in); 
			reg1 <= reg0;
			reg2 <= reg1;
		end if;	
	end process;

	p2 : process(clk_sample)
	begin
		if clk_sample'event and clk_sample = '0' and enable = '1' then
			if reg0(7) = reg1(7) then  -- ignore discontinuities 
				diff_sig <= (reg0(7) & reg0) - (reg2(7) & reg2); 
			end if;
		end if;	
	end process;
	
	data_out <= std_logic_vector(diff_sig & '0');
	
end diff_arch1;