
library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.ALL;

entity rx_audio_mix is
	port (ssb_audio_data_in : in std_logic_vector(9 downto 0);
			am_audio_data_in : in std_logic_vector(9 downto 0);
			fm_audio_data_in : in std_logic_vector(9 downto 0);
			ssb_am : in std_logic;
			fm : in std_logic;
			audio_data_out : out std_logic_vector(9 downto 0)
			);
end rx_audio_mix;

architecture audio_arch of rx_audio_mix is
begin
audio_data_out <= fm_audio_data_in when fm='1' else
						ssb_audio_data_in(9 downto 0) when ssb_am = '1' else
						am_audio_data_in(9 downto 0);
end audio_arch;

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.ALL;

entity weaver_mixsum is
	port (I_data_RX_in : in std_logic_vector(9 downto 0);
			Q_data_RX_in : in std_logic_vector(9 downto 0);
			I_LO_in : in std_logic_vector(9 downto 0);
			Q_LO_in : in std_logic_vector(9 downto 0);
			clk_in : in std_logic;
			usb_lsb : in std_logic;
			tx : in std_logic;
			mod_data_in : in std_logic_vector(9 downto 0);
			ssb_am : in std_logic;
			ssb_demod_data_out : out std_logic_vector(9 downto 0);
			am_squared_data_out : out std_logic_vector(19 downto 0);
			I_data_TX_out : out std_logic_vector(13 downto 0);
			Q_data_TX_out : out std_logic_vector(13 downto 0)
			);
end weaver_mixsum;

architecture mixsum_arch of weaver_mixsum is

signal mixsum_sig : signed (20 downto 0);
signal I_data : signed (9 downto 0);
signal Q_data : signed (9 downto 0);
signal I_prod : signed (19 downto 0);
signal Q_prod : signed (19 downto 0);
	
begin
					
	p0 : process (clk_in)
	
	begin	
		if clk_in'event and clk_in = '1' then
		
			if tx = '0' then
				I_data <= signed(I_data_RX_in);
				Q_data <= signed(Q_data_RX_in);
			else
				I_data <= signed (mod_data_in);
				Q_data <= signed (mod_data_in);
			end if;
			
			if ssb_am = '1' then
				I_prod <= I_data*signed(I_LO_in);
				Q_prod <= Q_data*signed(Q_LO_in);
			else
				I_prod <= I_data*I_data;
				Q_prod <= Q_data*Q_data;
			end if;
			
			if tx = '0' then
				if (ssb_am = '0') or (ssb_am = '1' and usb_lsb = '1') then
					mixsum_sig <= (I_prod(19) & I_prod) + (Q_prod(19) & Q_prod);
				elsif ssb_am = '1' and usb_lsb = '0' then
					mixsum_sig <= (I_prod(19) & I_prod)	- (Q_prod(19) & Q_prod);
				end if;
				
				--ssb_demod_data_out <= std_logic_vector(I_LO_in(9) & I_LO_in(9 downto 1));
				--ssb_demod_data_out <= std_logic_vector(I_data)(9 downto 0); --feed through for frequency response measurement
				ssb_demod_data_out <= std_logic_vector(mixsum_sig + to_signed(128,20))(18 downto 9); -- One shift for mult by LO, no shift for demod loss
				am_squared_data_out <= std_logic_vector(mixsum_sig)(19 downto 0);
			else 
				I_data_TX_out <= std_logic_vector(I_prod + to_signed(32,20))(19 downto 6);  -- No shift
				Q_data_TX_out <= std_logic_vector(Q_prod + to_signed(32,20))(19 downto 6); 
			end if;
		end if;
	end process;
		
end mixsum_arch;


library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.ALL;

entity weaver_nco is
	port (ADDR : out std_logic_vector(7 downto 0);
			cos_raw : in std_logic_vector(8 downto 0);
			sin_raw : in std_logic_vector(8 downto 0);
			clk_in : in std_logic; 
			wide_narrow : in std_logic;
			tx : in std_logic;
			cos_out : out std_logic_vector(9 downto 0);
			sin_out : out std_logic_vector(9 downto 0)
			);
end weaver_nco;

architecture nco_arch of weaver_nco is

signal reg1 : std_logic_vector(10 downto 0) := "00000000000";
signal sign_cos, sign_sin, sign_cos_reg, sign_sin_reg : std_logic;

begin
	p0 : process(clk_in)
	begin
		if clk_in'event and clk_in = '1' then
			if wide_narrow = '1' and tx = '0' then
				reg1 <= reg1 + 92;  -- 1.7969 kHz, 40 kHz fs
			elsif wide_narrow = '0' and tx = '0' then
				reg1 <= reg1 + 46;  -- 0.8984 kHz, 40 kHz fs
			elsif wide_narrow = '1' and tx = '1' then
				reg1 <= reg1 + 142;  -- 1806 Hz, 26 kHz fs		
			elsif wide_narrow = '0' and tx = '1' then
				reg1 <= reg1 + 71;  -- 903 Hz, 26 kHz fs		
			end if;
		end if;
	end process;
	
	p1 : process(clk_in)
	begin
		if clk_in'event and clk_in = '0' then
			if reg1(10 downto 9) = "00" then
				ADDR <= reg1(8 downto 1);
				sign_cos <= '0';
				sign_sin <= '0';
			elsif reg1(10 downto 9) = "01" then
				ADDR <= std_logic_vector(255 - reg1(8 downto 1));
				sign_cos <= '1';
				sign_sin <= '0';
			elsif reg1(10 downto 9) = "10" then
				ADDR <= reg1(8 downto 1);
				sign_cos <= '1';
				sign_sin <= '1';
			elsif reg1(10 downto 9) = "11" then
				ADDR <= std_logic_vector(255 - reg1(8 downto 1));
				sign_cos <= '0';
				sign_sin <= '1';
			end if;
		end if;
	end process;
	
	
	p2 : process(clk_in)
	begin
		if clk_in'event and clk_in = '1' then
			sign_cos_reg <= sign_cos;
			sign_sin_reg <= sign_sin;
			
			if sign_cos_reg = '0' then
				cos_out <= '0' & cos_raw;
			else
				cos_out <= std_logic_vector(not signed('0' & cos_raw) + 1);
			end if;
			
			if sign_sin_reg = '0' then
				sin_out <= '0' & sin_raw;
			else
				sin_out <= std_logic_vector(not signed('0' & sin_raw) + 1);
			end if;
		end if;
	end process;
	
	--ADDR <= reg1(10 downto 1);

end nco_arch;

