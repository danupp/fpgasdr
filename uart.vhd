library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.ALL;

entity uart is
	port (RXD : in std_logic;
			TXD : inout std_logic;
			enable : in std_logic;
			clk20 : in std_logic;
			Data_addr : out std_logic_vector(7 downto 0);
			Data_word : out std_logic_vector(31 downto 0);
			Strobe : out std_logic;
			Status_data : in  std_logic_vector(7 downto 0)
			);
end uart;

architecture uart_arch of uart is


begin

P0 : process(enable,clk20)
variable counter : integer range 0 to 260;
variable tx_counter : integer range 0 to 81;
variable sample_buffer : std_logic_vector(7 downto 0) := "11111111";
variable bit_buffer : std_logic_vector(7 downto 0);
variable samples : integer range 0 to 8;
variable bits : integer range 0 to 8 := 0;
variable bytes : integer range 0 to 4 := 0;
variable started_rx : boolean := false;
variable started_tx : boolean := false;
variable IssueStrobe : boolean := false;
variable Status_data_var : std_logic_vector(7 downto 0);

begin
	if enable = '0' then
		TXD <= 'Z';
	elsif clk20'event and clk20='1' then
		counter := counter + 1;
		if counter = 260 then -- 20e6/260 = 9600*8
			counter := 0;
			
			if started_tx = true then
				if tx_counter = 0 then
					TXD <= '0'; -- start bit
					Status_data_var := Status_data; 
				elsif tx_counter = 8 then
					TXD <= Status_data_var(0);
				elsif tx_counter = 16 then
					TXD <= Status_data_var(1);
				elsif tx_counter = 24 then
					TXD <= Status_data_var(2);
				elsif tx_counter = 32 then
					TXD <= Status_data_var(3);
				elsif tx_counter = 40 then
					TXD <= Status_data_var(4);
				elsif tx_counter = 48 then
					TXD <= Status_data_var(5);
				elsif tx_counter = 56 then
					TXD <= Status_data_var(6);
				elsif tx_counter = 64 then
					TXD <= Status_data_var(7);
				elsif tx_counter = 72 then
					TXD <= '1'; -- stop bit
				elsif tx_counter = 80 then
					started_tx := false;
				end if;
				tx_counter := tx_counter + 1;
			else
				TXD <= '1';
			end if;
			
			if IssueStrobe = true then
				IssueStrobe := false;
				Strobe <= '1';
				started_tx := true;
			else
				Strobe <= '0';
			end if;
			
			sample_buffer := sample_buffer(6 downto 0) & RXD;
			samples := samples + 1;
			
			if started_rx = false and sample_buffer(6 downto 1) = "000000" then -- start bit
				started_rx := true;
				samples := 0;
				bits := 0;
			elsif started_rx = true and samples = 8 and sample_buffer(5 downto 2) = "0000" then  
				bit_buffer := '0' & bit_buffer(7 downto 1);  -- LSB first
				bits := bits + 1;
				samples := 0;
			elsif started_rx = true and samples = 8 and sample_buffer(5 downto 2) = "1111" then
				if bits = 8 then -- this is then a stop bit
					started_rx := false;
					if bytes = 0 then
						Data_addr <= bit_buffer(7 downto 0);
						bytes := 1;
					elsif bytes = 1 then
						Data_word(31 downto 24) <= bit_buffer(7 downto 0);
						bytes := 2;
					elsif bytes = 2 then
						Data_word(23 downto 16) <= bit_buffer(7 downto 0);
						bytes := 3;
					elsif bytes = 3 then
						Data_word(15 downto 8) <= bit_buffer(7 downto 0);
						bytes := 4;
					elsif bytes = 4 then
						Data_word(7 downto 0) <= bit_buffer(7 downto 0);
						bytes := 0;
						IssueStrobe := true;
					end if;	
				else
					bit_buffer := '1' & bit_buffer(7 downto 1); -- LSB first
					bits := bits + 1;
					samples := 0;
				end if;
			end if;
		end if;
	end if;
end process;
end uart_arch;

