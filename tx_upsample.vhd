
library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.ALL;

entity tx_upsample_bypass is
	port (Data_in_I : in std_logic_vector(23 downto 0);
			Data_in_Q : in std_logic_vector(23 downto 0);
			Data_out_I : out std_logic_vector(13 downto 0);
			Data_out_Q : out std_logic_vector(13 downto 0);
			clk20 : in std_logic; -- 20 MHz
			clk_sample : in std_logic; 
			tx_att : in std_logic_vector(1 downto 0);
			clk_out : buffer std_logic
			);
end tx_upsample_bypass;

architecture bypass_arch of tx_upsample_bypass is

begin
	Data_out_I <= Data_in_I(13 downto 0) when tx_att="00" else
					  Data_in_I(14 downto 1) when tx_att="01" else
					  Data_in_I(15 downto 2) when tx_att="10" else
					  Data_in_I(16 downto 3);
	Data_out_Q <= Data_in_Q(13 downto 0) when tx_att="00" else
					  Data_in_Q(14 downto 1) when tx_att="01" else
					  Data_in_Q(15 downto 2) when tx_att="10" else
					  Data_in_Q(16 downto 3);
	clk_out <= clk_sample;
end bypass_arch;




library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.ALL;

entity tx_upsample1 is
	port (Data_in_I : in std_logic_vector(23 downto 0);
			Data_in_Q : in std_logic_vector(23 downto 0);
			Data_out_I : out std_logic_vector(13 downto 0);
			Data_out_Q : out std_logic_vector(13 downto 0);
			clk20 : in std_logic; -- 20 MHz
			clk_sample : in std_logic;
			att : in std_logic;
			clk_out : buffer std_logic
			);
end tx_upsample1;

architecture filter_arch of tx_upsample1 is

type longbuffer is array (0 to 2) of signed (13 downto 0);
signal buffer_I, buffer_Q : longbuffer;
signal mac_I, mac_Q : signed (15 downto 0);
signal Data_in_I_buff, Data_in_Q_buff : signed (13 downto 0);
signal req, req0, req1, req2, req3 : std_logic := '0';
signal ack : std_logic := '0';

begin
			
	sample : process(ack, clk_sample)
	begin
		if ack = '1' then
			req <= '0';
		elsif clk_sample'event and clk_sample='0' then
			req <= '1';
		end if;
	end process;
		
	p0 : process (clk20)
	variable count_div : integer range 0 to 799 := 0;
	begin
		if clk20'event and clk20 = '1' then 

					  
			req0 <= req;
			req1 <= req0;
			req2 <= req1;
			req3 <= req2;
			
			if req3 = '1' then
				ack <= '1';
			elsif req2 = '1' then
				if att = '0' then
					Data_in_I_buff <= signed(Data_in_I(15 downto 2));
					Data_in_Q_buff <= signed(Data_in_Q(15 downto 2));
				else
					Data_in_I_buff <= signed(Data_in_I(14 downto 1));
					Data_in_Q_buff <= signed(Data_in_Q(14 downto 1));
				end if;	
				--count_div := 50;
			else
				ack <= '0';
			end if;
				
			if count_div = 191 then -- compute
				mac_I <=       (buffer_I(0)(13) & buffer_I(0)(13) & buffer_I(0)(13 downto 0)) +
						      	(buffer_I(1)(13) & buffer_I(1)(13) & buffer_I(1)(13 downto 0)) +
									(buffer_I(2)(13) & buffer_I(2)(13 downto 0) & buffer_I(2)(0)); -- 1,1,2
				mac_Q <=       (buffer_Q(0)(13) & buffer_Q(0)(13) & buffer_Q(0)(13 downto 0)) +
									(buffer_Q(1)(13) & buffer_Q(1)(13) & buffer_Q(1)(13 downto 0)) +
									(buffer_Q(2)(13) & buffer_Q(2)(13 downto 0) & buffer_Q(2)(0)); -- 1,1,2
				clk_out <= '0';
			elsif (count_div = 287) or (count_div = 671) then
				Data_out_I <= std_logic_vector(mac_I(15 downto 2));
				Data_out_Q <= std_logic_vector(mac_Q(15 downto 2));  -- div by 4 =(1+2+1+1+2+1)/2
			elsif count_div = 383 then
				clk_out <= '1';
			elsif count_div = 575 then  -- compute
				mac_I <=       (buffer_I(0)(13) & buffer_I(0)(13 downto 0) & buffer_I(0)(0)) +
									(buffer_I(1)(13) & buffer_I(1)(13) & buffer_I(1)(13 downto 0)) +
									(buffer_I(2)(13) & buffer_I(2)(13) & buffer_I(2)(13 downto 0)); -- 2,1,1
				mac_Q <=       (buffer_Q(0)(13) & buffer_Q(0)(13 downto 0) & buffer_Q(0)(0)) +
									(buffer_Q(1)(13) & buffer_Q(1)(13) & buffer_Q(1)(13 downto 0)) +
									(buffer_Q(2)(13) & buffer_Q(2)(13) & buffer_Q(2)(13 downto 0)); -- 2,1,1				
				clk_out <= '0';
			elsif count_div = 767 and req2 = '0' then -- sample
				buffer_I(0) <= Data_in_I_buff;
				buffer_Q(0) <= Data_in_Q_buff;
				buffer_I(1) <= buffer_I(0);
				buffer_Q(1) <= buffer_Q(0);
				buffer_I(2) <= buffer_I(1);
				buffer_Q(2) <= buffer_Q(1);
				clk_out <= '1'; -- div by 768, for 52.0833 ksps
			end if;
			
			if count_div = 767 then
				count_div := 0;
			else
				count_div := count_div + 1;
			end if;
		end if;
	end process;
	
end filter_arch;




library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.ALL;

entity tx_upsample2 is
	port (Data_in_I : in std_logic_vector(23 downto 0);
			Data_in_Q : in std_logic_vector(23 downto 0);
			Data_out_I : out std_logic_vector(13 downto 0);
			Data_out_Q : out std_logic_vector(13 downto 0);
			clk20 : in std_logic; -- 20 MHz
			clk_sample : in std_logic;
			tx_att : in std_logic_vector(1 downto 0);
			clk_out : buffer std_logic
			);
end tx_upsample2;

architecture filter_arch of tx_upsample2 is

type longbuffer is array (0 to 4) of signed (13 downto 0);
signal buffer_I, buffer_Q : longbuffer;
signal Data_in_I_buff, Data_in_Q_buff : signed (13 downto 0);
signal req, req0, req1, req2, req3 : std_logic := '0';
signal ack : std_logic := '0';

begin


	sample : process(ack, clk_sample)		
	begin
		if ack = '1' then
			req <= '0';
		elsif clk_sample'event and clk_sample='0' then
			req <= '1';
		end if;
	end process;
		
	p0 : process (clk20)
	variable mac_I, mac_Q : signed (15 downto 0);	
	variable count_div : integer range 0 to 799 := 0;
	begin
		if clk20'event and clk20 = '1' then 

					  
			req0 <= req;
			req1 <= req0;
			req2 <= req1;
			req3 <= req2;
			
			if req3 = '1' then
				ack <= '1';
			elsif req2 = '1' then
				if tx_att = "00" then
					Data_in_I_buff <= signed(Data_in_I(13 downto 0));
					Data_in_Q_buff <= signed(Data_in_Q(13 downto 0));
				elsif tx_att = "01" then
					Data_in_I_buff <= signed(Data_in_I(14 downto 1));
					Data_in_Q_buff <= signed(Data_in_Q(14 downto 1));
				elsif tx_att = "10" then
					Data_in_I_buff <= signed(Data_in_I(15 downto 2));
					Data_in_Q_buff <= signed(Data_in_Q(15 downto 2));
				else
					Data_in_I_buff <= signed(Data_in_I(16 downto 3));
					Data_in_Q_buff <= signed(Data_in_Q(16 downto 3));
				end if;
			else
				ack <= '0';
			end if;
			
			if count_div < 95 then
				clk_out <= '1';
			elsif count_div = 95 then
				clk_out <= '0';
			elsif count_div = 191 then
				mac_I :=       (buffer_I(0)(13) & buffer_I(0)(13) & buffer_I(0)(13 downto 0)) +
						      	(buffer_I(1)(13) & buffer_I(1)(13) & buffer_I(1)(13 downto 0));
																														-- 1,1
				mac_Q :=       (buffer_Q(0)(13) & buffer_Q(0)(13) & buffer_Q(0)(13 downto 0)) +
									(buffer_Q(1)(13) & buffer_Q(1)(13) & buffer_Q(1)(13 downto 0)); -- 1,1
				clk_out <= '1';
			elsif count_div = 287 then				
				Data_out_I <= std_logic_vector(mac_I(14 downto 1));   -- 0.5
				Data_out_Q <= std_logic_vector(mac_Q(14 downto 1));   -- 0.5
				clk_out <= '0';
			elsif count_div = 383 then
				clk_out <= '1'; 	
			elsif count_div = 479  then
				clk_out <= '0';
			elsif count_div = 575 then
				mac_I :=       buffer_I(0)(13) & buffer_I(0)(13) & buffer_I(0)(13 downto 0); -- 1
				mac_Q :=       buffer_Q(0)(13) & buffer_Q(0)(13) & buffer_Q(0)(13 downto 0); -- 1			
				clk_out <= '1';
			elsif count_div = 671 then
				Data_out_I <= std_logic_vector(mac_I(13 downto 0));  -- 1
				Data_out_Q <= std_logic_vector(mac_Q(13 downto 0));  -- 1
				clk_out <= '0';
			elsif count_div = 767 then
				clk_out <= '1'; -- div by 192, for 104.xx ksps
				if req2 = '0' then -- sample
					buffer_I(0) <= Data_in_I_buff;
					buffer_Q(0) <= Data_in_Q_buff;
					buffer_I(1) <= buffer_I(0);
					buffer_Q(1) <= buffer_Q(0);
					buffer_I(2) <= buffer_I(1);
					buffer_Q(2) <= buffer_Q(1);
					buffer_I(3) <= buffer_I(2);
					buffer_Q(3) <= buffer_Q(2);
					buffer_I(4) <= buffer_I(3);
					buffer_Q(4) <= buffer_Q(3);
				end if;
			end if;
			
			if count_div = 767 then
				count_div := 0;
			else
				count_div := count_div + 1;
			end if;
		end if;
	end process;
	
end filter_arch;

