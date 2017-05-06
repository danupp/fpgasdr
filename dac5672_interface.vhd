library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.ALL;

entity dac5672_interface is
	port (DA : out std_logic_vector(13 downto 0);
			SELECTIQ : out std_logic;
			RESETIQ : out std_logic := '1';
			Mod_Data : in std_logic_vector(13 downto 0);
			A_Data_nomod : in std_logic_vector(13 downto 0);
			B_Data_nomod : in std_logic_vector(13 downto 0);
			clk240 : in std_logic;
			B_clk : buffer std_logic;
			A_clk : buffer std_logic;
			POR : in std_logic_vector(1 downto 0);
			tx : in std_logic;
			modsel_A_B : in std_logic;
			cw_tx_nomod : std_logic;
			key : in std_logic;
			fm : in std_logic;
			DAC_clk : out std_logic
			);
end dac5672_interface;

architecture dac5672_interface_arch of dac5672_interface is

signal B_data_r, B_data_rr, A_data_r, A_data_rr : std_logic_vector(13 downto 0);
signal DAC_clk_signal_1, DAC_clk_signal_2, DAC_clk_signal_3 : std_logic;

attribute keep: boolean;
attribute keep of DAC_clk_signal_1: signal is true;
attribute keep of DAC_clk_signal_2: signal is true;
attribute keep of DAC_clk_signal_3: signal is true;

begin
DAC_clk_signal_1 <= clk240; -- For delay
DAC_clk_signal_2 <= DAC_clk_signal_1;
DAC_clk_signal_3 <= DAC_clk_signal_2;
DAC_clk <= DAC_clk_signal_1;
	
SELECTIQ <= A_clk;

	p0 : process(clk240)
	variable sel : std_logic := '0';
	begin
		if clk240'event and clk240 = '1' then
		--if DAC_clk_signal_1'event and DAC_clk_signal_1 = '1' then
			if sel = '0' then
				A_clk <= '1';
				B_clk <= '0';
			else
				A_clk <= '0';
				B_clk <= '1';
			end if;
			sel := not sel;
		end if;
	end process;
	
	reg_B_data : process (B_clk)
	begin 
		if B_clk'event and B_clk = '1' then
			if tx = '0' then 
				B_data_r <= not B_Data_nomod(13) & B_Data_nomod(12 downto 0);
			elsif modsel_A_B = '1' then
				B_data_r <= "00000000000000";
			else
				if fm = '1' or (key = '1' and cw_tx_nomod = '1') then
					B_data_r <= not B_Data_nomod(13) & B_Data_nomod(13) & B_Data_nomod(13) & B_Data_nomod(12 downto 2);
				else
					B_data_r <= not Mod_Data(13) & Mod_Data(12 downto 0);
				end if;
			end if;
			B_data_rr <= B_data_r;
		end if;
	end process;

	reg_A_data : process (A_clk)
	begin 
		if A_clk'event and A_clk = '1' then
			if modsel_A_B = '1' and tx = '1' then
				if fm = '1' or (key = '1' and cw_tx_nomod = '1') then
					A_data_r <= not A_data_nomod(13) & A_data_nomod(12 downto 0);
				else
					A_data_r <= not Mod_Data(13) & Mod_Data(12 downto 0);
				end if;
			else
				A_data_r <= not A_data_nomod(13) & A_data_nomod(12 downto 0);
			end if;
			A_data_rr <= A_data_r;
		end if;
	end process;
	
	DAbus : process (DAC_clk_signal_2) --clk240)
	variable sel : std_logic := '0';
	begin
		--if clk240'event and clk240 = '1' then
		if DAC_clk_signal_2'event and DAC_clk_signal_2 = '1' then
			if sel = '1' then
				DA <= B_data_rr;
			else 
				DA <= A_data_rr;
			end if;
			sel := not sel;
		end if;
	end process;
	
	resetiq_ctrl : process (A_clk)
	begin
		if A_clk'event and A_clk = '0' and POR = "11" then
			RESETIQ <= '0';
		end if;
	end process;
	
end dac5672_interface_arch;
	