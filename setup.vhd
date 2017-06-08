library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.ALL;

entity setup_interface is 
	port (addr : in std_logic_vector(7 downto 0);
			data : in std_logic_vector(31 downto 0); 
			strobe : in std_logic;
			POR : in std_logic_vector(1 downto 0);
			rssi_in : in std_logic_vector(5 downto 0);
			tx_in : in std_logic;
			mute_in : in std_logic;
			freq : out std_logic_vector(24 downto 0) := std_logic_vector(to_unsigned(622592,25));
			clar : out std_logic_vector(6 downto 0) := "0000000";
			ssb_am : out std_logic := '1';
			wide_narrow : out std_logic := '1';
			tx : out std_logic := '0';
			key : out std_logic := '0';
			usb_lsb : out std_logic := '0';
			audio_conf_strobe : out std_logic;
			status_out : out std_logic_vector(7 downto 0);
			cw_tx_nomod : out std_logic := '1';
			fconf : out std_logic := '0';
			if_freq : out std_logic_vector(2 downto 0);
			rx_att : out std_logic_vector(1 downto 0);
			tx_att : out std_logic_vector(1 downto 0);
			fm : out std_logic;
			squelch : out std_logic_vector(5 downto 0);
			twotone : out std_logic
			);
end setup_interface;

architecture setup_arch of setup_interface is

	
begin
	status_out <= tx_in & (not mute_in) & rssi_in;
	
	audio_conf_strobe <= '1' when (POR = "11" and addr(7 downto 6) = "10" and strobe = '1') else '0';
		
	p0 : process (strobe)
	begin
		if POR = "11" then
			if strobe'event and strobe = '1' then
				if addr(7 downto 6) = "01" then
					ssb_am <= addr(5);
					wide_narrow <= addr(4);
					usb_lsb <= addr(3);
					fm <= addr(0);
					tx <= addr(2);
					key <= addr(1);
					cw_tx_nomod <= data(21);
					fconf <= data(19);
					twotone <= data(17);
					tx_att <= data(31 downto 30);
					rx_att <= data(28 downto 27);
					if_freq <= data(25 downto 23);
				elsif addr(7 downto 6) = "11" then
					freq <= data(24 downto 0); --freq <= addr(5 downto 0) & data; 
					clar <= data(31 downto 25);
				elsif addr(7 downto 6) = "10" then
					squelch <= data(13 downto 8);
				end if;
			end if;
		end if;
	end process;

end setup_arch;


library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.ALL;

entity io_select is
	port (addr_I2C : in std_logic_vector(7 downto 0);
			data_I2C : in std_logic_vector(31 downto 0); 
			strobe_I2C : in std_logic;
			addr_UART : in std_logic_vector(7 downto 0);
			data_UART : in std_logic_vector(31 downto 0); 
			strobe_UART : in std_logic;
			I2C_UART_select : in std_logic; 
			addr : out std_logic_vector(7 downto 0);
			data : out std_logic_vector(31 downto 0); 
			strobe : out std_logic
			);
end io_select;

architecture select_arch of io_select is
begin

	addr <= addr_I2C when I2C_UART_select = '1' else
					addr_UART;
	data <= data_I2C when I2C_UART_select = '1' else
					data_UART;
	strobe <= strobe_I2C when I2C_UART_select = '1' else
					strobe_UART;
					
end select_arch;