library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_unsigned.ALL;

entity ad7760_interface is
	port (DBus : inout std_logic_vector(15 downto 0) := "ZZZZZZZZZZZZZZZZ";
			nDRDY : in std_logic;
			nCS : out std_logic := '1';
			nRDWR : out std_logic;
			nRESET : out std_logic;
			nSYNC : out std_logic;
			ADC_Data : out std_logic_vector(23 downto 0);
			ADC_Clk : out std_logic;
			POR : in std_logic_vector(1 downto 0);
			clk0 : in std_logic;
			tx : in std_logic;
			MCLK: out std_logic;
			err_out : out std_logic := '0'
			);
end ad7760_interface;

architecture ad7760_interface_arch of ad7760_interface is

signal ADC_Status_read : std_logic_vector(7 downto 0);
signal ADC_Register_address : std_logic_vector(15 downto 0);
signal ADC_Register_data : std_logic_vector(15 downto 0);
signal start_write : boolean := false;
signal init_done : boolean := false;
--signal ICLK : std_logic;
signal write_state : integer range 0 to 26 := 26;
signal read_state : integer range 0 to 15 := 15;

signal ADC_Clk_en : boolean := false;

signal clk_counter : std_logic_vector(10 downto 0);
signal clk_slow : std_logic;

signal sample : std_logic := '0';
signal sample_ack : std_logic := '0';
 
type regdata is array (0 to 1) of std_logic_vector (15 downto 0);

constant init_regdata : regdata := 
			("0000000000100010", -- reg 2
			 "0000000000011001"); -- reg 1  1.25MSPS
constant reg_addr : regdata := 
			(x"0002", -- reg 2
			 x"0001"); -- reg 1
			
begin
	MCLK <= clk0;
	nRESET <= POR(1);
	nSYNC <= '1';
	clk_slow <= clk_counter(10);
	
	clkdiv : process (clk0)
	begin
		if clk0'event and clk0 = '1' then
--			ICLK <= not ICLK;
			clk_counter <= clk_counter + 1;
		end if;
	end process;
	
	init : process (clk_slow)
	variable n : integer range 0 to 2 := 0;
	begin
		if clk_slow'event and clk_slow = '1' then
			if POR = "11" then
				if init_done = false then
					if n < 2 then
						if start_write = false then
							if write_state = 26 then
								ADC_Register_address <= reg_addr(n);
								ADC_Register_data <= init_regdata(n);
								start_write <= true;
							end if;
						else
							start_write <= false; -- clk_slow slower than ICLK!
							n := n + 1;
						end if;
					elsif write_state = 26 then -- such that no operation is ongoing
						init_done <= true;
					end if;
				end if;
			end if;
		end if;		
	end process;
	
	regWrite : process (clk0)
	begin
		if clk0'event and clk0 = '1' then
			if start_write = true then
				write_state <= 0;
				nRDWR <= '1';
			elsif write_state = 0 then
				write_state <= 1;
				DBus <= ADC_Register_address;
			elsif write_state = 1 then
				nCS <= '0';
				write_state <= 2;
			elsif write_state > 1 and write_state < 9 then
				write_state <= write_state + 1;
			elsif write_state = 9 then
				nCS <= '1';
				write_state <= 10;
			elsif write_state > 9 and write_state < 16 then
				write_state <= write_state + 1;
			elsif write_state = 16 then
				DBus <= ADC_Register_data;
				write_state <= 17;
			elsif write_state = 17 then
				nCS <= '0';
				write_state <= 18;
			elsif write_state > 17 and write_state < 25 then
				write_state <= write_state + 1;
			elsif write_state = 25 then
				nCS <= '1';
				write_state <= 26;
			elsif init_done = true then
				--err_out <= '1';
				DBus <= "ZZZZZZZZZZZZZZZZ";
				if sample = '1' then --nDRDY = '0' and read_state = 15 then
					--ADC_Clk_en <= false;
					read_state <= 2;
					sample_ack <= '1';
				else
					if read_state = 0 then
						ADC_Clk_en <= false; -- to sync with master clock
						read_state <= 1;
					elsif read_state = 1 then
						read_state <= 2; -- to ensure some delay
					elsif read_state = 2 then
						if tx = '0' then
							ADC_Clk_en <= false;
							nRDWR <= '0';
							read_state <= 3;
						end if;
					elsif read_state = 3 then
						nCS <= '0';
						read_state <= 5;
					elsif read_state = 4 then
						read_state <= 5;
					elsif read_state = 5 then
						read_state <= 6;
					elsif read_state = 6 then
						ADC_Data(23 downto 8) <= DBus(15 downto 0);
						read_state <= 7;
					elsif read_state = 7 then
						nCS <= '1';
						nRDWR <= '1';
						read_state <= 8;
					elsif read_state = 8 then
						read_state <= 9;
					elsif read_state = 9 then
						read_state <= 10;
					elsif read_state = 10 then
						nRDWR <= '0';
						read_state <= 11;
					elsif read_state = 11 then
						nCS <= '0';
						read_state <= 13;
					elsif read_state = 12 then
						read_state <= 13;
					elsif read_state = 13 then
						read_state <= 14;
					elsif read_state = 14 then
						ADC_Data(7 downto 0) <= DBus(15 downto 8);
						ADC_Status_read <= DBus(7 downto 0);
						read_state <= 15;
						--ADC_Clk <= '1';
					elsif read_state = 15 then
						nCS <= '1';
						nRDWR <= '1';
						--ADC_Clk <= '0';
						ADC_Clk_en <= true;
						--read_state <= 0;
						sample_ack <= '0';
						err_out <= '1';
					end if;
				end if;
			end if;
		end if;
	end process;
	
sample_clk_gen : process (clk0)
begin
	if clk0'event and clk0 = '0' then
		if ADC_Clk_en = true then
			ADC_Clk <= '1';
		else
			ADC_Clk <= '0';	
		end if;
	end if;
end process;


sample_trig : process(nDRDY,sample_ack)
begin
	if sample_ack = '1' then
		sample <= '0';
	elsif nDRDY'event and nDRDY='1' and sample_ack='0' then
		sample <= '1';
	end if;
end process;

end ad7760_interface_arch;
	