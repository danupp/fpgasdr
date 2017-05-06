library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_unsigned.ALL;

entity tx_synchbuff is
	port (data_in : in std_logic_vector(13 downto 0);
			clk120 : in std_logic;
			clk_data : in std_logic;
			tx : in std_logic;
			data_out : out std_logic_vector(13 downto 0)
			);
end tx_synchbuff;

architecture synchbuff_arch of tx_synchbuff is

signal req, req_1, req_2, req_3, ack : std_logic;

begin

p0 : process (clk120)
 begin
   if clk120'event and clk120 = '1' and tx = '1' then
     req_1 <= req;
     req_2 <= req_1;
     req_3 <= req_2;
     if req_2 = '0' then
       ack <= '0';
     elsif req_3 = '1' then
       ack <= '1';
     elsif req_2 = '1' then
       data_out <= data_in;
     end if;
   end if;
 end process;
	
req_ff : process(clk_data,ack)
	begin
		if ack = '1' then
			req <= '0';
		elsif clk_data'event and clk_data = '1' and (req = '0' and req_1 = '0' and req_2 = '0' and req_3 = '0') then
			req <= '1';
		end if;
	end process;
	
end synchbuff_arch;


library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.ALL;

entity weaver_tx_mixsum is
	port (I_prod_in : in std_logic_vector(27 downto 0);
			Q_prod_in : in std_logic_vector(27 downto 0);
			clk_in : in std_logic;
			usb_lsb : in std_logic;
			tx : in std_logic;
			Mod_data_out : out std_logic_vector(13 downto 0)
			);
end weaver_tx_mixsum;

architecture mixsum_arch of weaver_tx_mixsum is

signal I_prod, Q_prod, mixsum_sig : signed (27 downto 0);
signal ms_temp, ls_temp : signed (14 downto 0);
signal ms0_sum, ls0_sum, ls0_temp : signed (14 downto 0);
signal ms0a, ms0b : signed(13 downto 0);

begin					
		
	Mod_data_out <= std_logic_vector(mixsum_sig)(25 downto 12);  -- 14 bits of 28, shifted 1 bit for mult by LO and 1 bit for conv loss compensation	
	
	p0 : process (clk_in)
		
	begin	
		if clk_in'event and clk_in = '1' then --and tx = '1'
			I_prod <= signed(I_prod_in); -- register
			Q_prod <= signed(Q_prod_in);
			
			if usb_lsb = '1' then
						-- cycle 1:
					ms0a <= I_prod(27 downto 14);
					ms0b <= Q_prod(27 downto 14);
					ls0_temp <= ('0' & I_prod(13 downto 0)) + ('0' & Q_prod(13 downto 0));
			
					-- cycle 2:
					ms0_sum <= signed(ms0a & ls0_temp(14)) + signed(ms0b & ls0_temp(14));
					ls0_sum <= ls0_temp;
			
					-- cycle 3:
					--mixsum_sig <= ms0_sum(14 downto 1) & ls0_sum(13 downto 0); 
					
				--mixsum_sig <= ms_temp(14 downto 1) & ls_temp(13 downto 0);  
				mixsum_sig <= I_prod + Q_prod;
			else
									-- cycle 1:
					ms0a <= I_prod(27 downto 14);
					ms0b <= Q_prod(27 downto 14);
					ls0_temp <= ('0' & I_prod(13 downto 0)) - ('0' & Q_prod(13 downto 0));
			
					-- cycle 2:
					ms0_sum <= signed(ms0a & ls0_temp(14)) - signed(ms0b & ls0_temp(14));
					ls0_sum <= ls0_temp;
			
					-- cycle 3:
					--mixsum_sig <= ms0_sum(14 downto 1) & ls0_sum(13 downto 0); 

				mixsum_sig <= I_prod - Q_prod;
			end if;
			
		end if;
	end process;
		
end mixsum_arch;

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_unsigned.ALL;

entity LO_select is
	port (LO_in_A : in std_logic_vector(13 downto 0);
			LO_in_B : in std_logic_vector(13 downto 0);
			LO_out : out std_logic_vector(13 downto 0);
			sel_A_B : in std_logic
			);
end LO_select;

architecture select_arch of LO_select is

begin

	LO_out <= LO_in_A when sel_A_B = '1' else
					LO_in_B;
	
end select_arch;

library ieee;
use ieee.std_logic_1164.ALL;

entity mod_clock_mux is
	port (clk_A : in std_logic;
			clk_B : in std_logic;
			sel_A_B : in std_logic;
			clk_out : out std_logic
			);
end mod_clock_mux;

architecture clock_mux_arch of mod_clock_mux is

begin
	
	clk_out <= clk_A when sel_A_B='1' else
					clk_B;
	
end clock_mux_arch;