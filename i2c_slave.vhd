library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_unsigned.ALL; -- behövs för +

entity i2c_bridge is
	port (clk : in std_logic;  -- 20 MHz etc
			SDA_mcu : inout std_logic := 'Z';  -- with weak pull-up
			SCL_mcu : in std_logic;
			SDA_int_in : in std_logic;
			SDA_int_out : out std_logic := '1';
			SCL_int : out std_logic;
			SDA_codec : inout std_logic := 'Z';
			SCL_codec : out std_logic
			);
end i2c_bridge;

architecture arch of i2c_bridge is

	signal SCL_mcu_reg : std_logic_vector(15 downto 0);
	signal SDA_mcu_reg : std_logic_vector(23 downto 0);
	signal SDA_int_reg : std_logic_vector(15 downto 0);
	signal SDA_codec_reg : std_logic_vector(15 downto 0);
	
	begin

	sample : process(clk)
	variable SINK : std_logic := '0';
	begin
		if clk'event and clk = '1' then
			SCL_mcu_reg <= SCL_mcu_reg(14 downto 0) & SCL_mcu;
			SDA_mcu_reg <= SDA_mcu_reg(22 downto 0) & SDA_mcu;
			SDA_int_reg <= SDA_int_reg(14 downto 0) & SDA_int_in;
			SDA_codec_reg <= SDA_codec_reg(14 downto 0) & SDA_codec;
		elsif clk'event and clk = '0' then
			if SCL_mcu_reg(7 downto 0) = "00000000" then
				SCL_int <= '0';
				SCL_codec <= '0';
			elsif SCL_mcu_reg(7 downto 0) = "11111111" then
				SCL_int <= '1';
				SCL_codec <= '1';
			end if;
			if SINK = '0' and SDA_mcu_reg = "111111111111111111111111" and (SDA_int_reg(7 downto 0) = "00000000" or SDA_codec_reg(7 downto 0) = "00000000") then
				SDA_mcu <= '0';
				SINK := '1';
			elsif SINK = '1' and SDA_int_reg(7 downto 0) = "11111111" and SDA_codec_reg(7 downto 0) = "11111111" then
				SDA_mcu <= 'Z';
				SINK := '0';
			elsif SINK = '0' and SDA_mcu_reg(7 downto 0) = "00000000" then
				SDA_int_out <= '0';
				SDA_codec <= '0';
			elsif SINK = '0' and SDA_mcu_reg(7 downto 0) = "11111111" then
				SDA_int_out <= '1';
				SDA_codec <= 'Z';
			end if;
		end if;
	end process;
end arch;



library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.ALL;

entity i2c_slave is
	port (SDA_in : in std_logic;
			SDA_out : out std_logic := '1';
			SCL : in std_logic;
			Data_addr : out std_logic_vector(7 downto 0);
			Data_word : out std_logic_vector(31 downto 0);
			Strobe : out std_logic;
			Status_data : in  std_logic_vector(7 downto 0);
			enable : in std_logic
			);
end i2c_slave;

architecture i2c_slave_arch of i2c_slave is
signal bitcount : integer range 0 to 54 := 54;
signal indata : std_logic_vector(54 downto 0);
signal addressed : std_logic := '0';
signal read_write : std_logic;
signal start, stop : std_logic := '0';
signal status_data_buffer : std_logic_vector(7 downto 0);

begin

Data_addr <= indata(44 downto 37);
Data_word <= indata(35 downto 28) & indata(26 downto 19) & indata(17 downto 10) & indata(8 downto 1);
			
start_detect : process(SDA_in,SCL,enable)
begin
	if SCL = '0' then
		start <= '0';
	elsif SDA_in'event and SDA_in='0' and SCL='1' and enable = '1' then
		start <= '1';
	end if;
end process;

stop_detect : process(SDA_in,SCL)
begin
	if SCL = '0' then
		stop <= '0';
	elsif SDA_in'event and SDA_in='1' and SCL='1' then
		stop <= '1';
	end if;
end process;

sample : process(SCL,start,stop)
begin
	if start = '1' then  -- asynch reset
		bitcount <= 0;
--	elsif stop = '1' then
--		bitcount <= 36;
	elsif SCL'event and SCL = '1' then
		if bitcount < 54 then
			indata(54 downto 0) <= indata(53 downto 0) & SDA_in;
			bitcount <= bitcount + 1;
		end if;
	end if;
end process;

Datatransfer : process(SCL)
begin
	if SCL'event and SCL = '0' then
		if bitcount < 8 then
			addressed <= '0';
			Strobe <= '0';
		elsif bitcount = 8 then
			if indata(7 downto 0) = "01000110" then -- addr 0x23 write
				addressed <= '1';
				read_write <= '0';
				SDA_out <= '0';
			elsif indata(7 downto 0) = "01000111" then -- addr 0x23 read
				addressed <= '1';
				read_write <= '1';
				SDA_out <= '0';		
				status_data_buffer <= status_data;
			end if;
		elsif addressed = '1' and read_write = '1' and bitcount < 17 then
			if status_data_buffer(16 - bitcount) = '1' then
				SDA_out <= '1';
			else
				SDA_out <= '0';
			end if;
		elsif (bitcount = 17 or bitcount = 26 or bitcount = 35 or bitcount = 44 or bitcount = 53) and addressed = '1' and read_write = '0' then
			SDA_out <= '0';
		elsif bitcount = 54 and addressed = '1' and read_write = '0' then
			SDA_out <= '1';
			addressed <= '0';
			Strobe <= '1';
		else
			SDA_out <= '1';
		end if;
	end if;
end process;


end i2c_slave_arch;
