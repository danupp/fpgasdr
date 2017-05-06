library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.ALL;

entity down_dec is
	port (Data_in : in std_logic_vector(23 downto 0);
			Data_out_I : out std_logic_vector(23 downto 0);
			Data_out_Q : out std_logic_vector(23 downto 0);
			clk_in : in std_logic; -- 40 MHz
			clk_sample : in std_logic; -- 40 / 32 MHz
			rx_att : in std_logic_vector(1 downto 0);
			clk_out : out std_logic
			);
end down_dec;

architecture down_dec_arch of down_dec is

--signal Data_in_trunk : signed (17 downto 0);
-- signal Ia : signed (8 downto 0);
-- signal Qa : signed (8 downto 0);
--signal mac_I_sig : signed (23 downto 0);
--signal mac_Q_sig : signed (23 downto 0);
	
type longbuffer is array (200 downto 0) of signed (23 downto 0);
type filt_type is array (159 downto 0) of signed (23 downto 0);

signal Ia : longbuffer;
signal Qa : longbuffer;

constant filtkoeff : filt_type :=

-- Scilab:
-->[v,a,f] = wfir ('lp', 160, [1/120 0], 'hn', 0);
-->round(v*2^28)

	("000000000000000000000000",
    "111111111111111010100010",
    "111111111111101010101011",
    "111111111111010001011011",
    "111111111110110000000011",
    "111111111110001000000000",
    "111111111101011010111111",
    "111111111100101010111011",
    "111111111011111001111100",
    "111111111011001010011001",
    "111111111010011110110010",
    "111111111001111001110110",
    "111111111001011110011010",
    "111111111001001111011111",
    "111111111001010000001110",
    "111111111001100011110101",
    "111111111010001101101010",
    "111111111011010001000101",
    "111111111100110001011111",
    "111111111110110010010110",
    "000000000001010111000011",
    "000000000100100010111111",
    "000000001000011001011111",
    "000000001100111101110000",
    "000000010010010010111011",
    "000000011000011011111110",
    "000000011111011011101011",
    "000000100111010100101011",
    "000000110000001001010110",
    "000000111001111011110110",
    "000001000100101110000110",
    "000001010000100001101100",
    "000001011101010111111100",
    "000001101011010001110101",
    "000001111010010000000010",
    "000010001010010010110101",
    "000010011011011010001011",
    "000010101101100101101001",
    "000011000000110100011001",
    "000011010101000101010000",
    "000011101010010110100111",
    "000100000000100110011111",
    "000100010111110010100000",
    "000100101111110111111001",
    "000101001000110011100001",
    "000101100010100001111000",
    "000101111100111111000100",
    "000110011000000110111000",
    "000110110011110100110000",
    "000111010000000011110100",
    "000111101100101110111010",
    "001000001001110000100110",
    "001000100111000011001100",
    "001001000100100000110011",
    "001001100010000011010100",
    "001001111111100100011111",
    "001010011100111101111011",
    "001010111010001001000111",
    "001011010110111111011111",
    "001011110011011010011101",
    "001100001111010011011001",
    "001100101010100011110000",
    "001101000101000101000000",
    "001101011110110000110000",
    "001101110111100000101101",
    "001110001111001110110010",
    "001110100101110101000011",
    "001110111011001101110110",
    "001111001111010011110000",
    "001111100010000001101010",
    "001111110011010010110001",
    "010000000011000010100111",
    "010000010001001101001001",
    "010000011101101110101001",
    "010000101000100011110111",
    "010000110001101001111101",
    "010000111000111110100010",
    "010000111110011111101010",
    "010001000010001011111001",
    "010001000100000010010001",
    "010001000100000010010001",
    "010001000010001011111001",
    "010000111110011111101010",
    "010000111000111110100010",
    "010000110001101001111101",
    "010000101000100011110111",
    "010000011101101110101001",
    "010000010001001101001001",
    "010000000011000010100111",
    "001111110011010010110001",
    "001111100010000001101010",
    "001111001111010011110000",
    "001110111011001101110110",
    "001110100101110101000011",
    "001110001111001110110010",
    "001101110111100000101101",
    "001101011110110000110000",
    "001101000101000101000000",
    "001100101010100011110000",
    "001100001111010011011001",
    "001011110011011010011101",
    "001011010110111111011111",
    "001010111010001001000111",
    "001010011100111101111011",
    "001001111111100100011111",
    "001001100010000011010100",
    "001001000100100000110011",
    "001000100111000011001100",
    "001000001001110000100110",
    "000111101100101110111010",
    "000111010000000011110100",
    "000110110011110100110000",
    "000110011000000110111000",
    "000101111100111111000100",
    "000101100010100001111000",
    "000101001000110011100001",
    "000100101111110111111001",
    "000100010111110010100000",
    "000100000000100110011111",
    "000011101010010110100111",
    "000011010101000101010000",
    "000011000000110100011001",
    "000010101101100101101001",
    "000010011011011010001011",
    "000010001010010010110101",
    "000001111010010000000010",
    "000001101011010001110101",
    "000001011101010111111100",
    "000001010000100001101100",
    "000001000100101110000110",
    "000000111001111011110110",
    "000000110000001001010110",
    "000000100111010100101011",
    "000000011111011011101011",
    "000000011000011011111110",
    "000000010010010010111011",
    "000000001100111101110000",
    "000000001000011001011111",
    "000000000100100010111111",
    "000000000001010111000011",
    "111111111110110010010110",
    "111111111100110001011111",
    "111111111011010001000101",
    "111111111010001101101010",
    "111111111001100011110101",
    "111111111001010000001110",
    "111111111001001111011111",
    "111111111001011110011010",
    "111111111001111001110110",
    "111111111010011110110010",
    "111111111011001010011001",
    "111111111011111001111100",
    "111111111100101010111011",
    "111111111101011010111111",
    "111111111110001000000000",
    "111111111110110000000011",
    "111111111111010001011011",
    "111111111111101010101011",
    "111111111111111010100010",
    "000000000000000000000000");

--attribute ramstyle : string;
--attribute ramstyle of filtkoeff : constant is "M4K";

signal sample : boolean := false;
signal ack : boolean := false;

signal I_asynch,Q_asynch, I_synch, Q_synch : signed (23 downto 0);

signal mac_I : signed (60 downto 0);
signal mac_Q : signed (60 downto 0);

signal write_pointer, write_pointer_last : integer range 0 to 255 := 200;
signal read_pointer : integer range 0 to 255;
signal clk_out_next : boolean := false;
	
begin

downconversion : process (clk_in)
	variable ns : integer range 0 to 3 := 0;	
	begin	
		if clk_in'event and clk_in = '1' then		
			if clk_out_next = true then
				clk_out <= '1';
			else
				clk_out <= '0';
			end if;

			if sample = true then
				ack <= true;
				if ns = 0 then
					Ia(write_pointer) <= signed(Data_in);  				-- 1
					Qa(write_pointer) <= to_signed(0,24); 		-- 0
					ns := 1;
				elsif ns = 1 then
					Ia(write_pointer) <= to_signed(0,24);		-- 0
					Qa(write_pointer) <= signed(Data_in);			-- 1
					ns := 2;
				elsif ns = 2 then
					Ia(write_pointer) <= (not signed(Data_in)) + 1; -- -1
					Qa(write_pointer) <= to_signed(0,24); 	 -- 0
					ns := 3;
				elsif ns = 3 then
					Ia(write_pointer) <= to_signed(0,24);		-- 0
					Qa(write_pointer) <= (not signed(Data_in)) + 1; -- -1
					ns := 0;
				end if;		
				write_pointer_last <= write_pointer;
			else
				ack <= false;
			end if;
			I_asynch <= Ia(read_pointer);
			Q_asynch <= Qa(read_pointer);
			I_synch <= I_asynch;
			Q_synch <= Q_asynch;
		end if;
	end process;
	
filter : process (clk_in)
	variable prod_I : signed (47 downto 0);
	variable prod_Q : signed (47 downto 0);
	variable n, nn : integer range 0 to 160 := 0;
	variable m : integer range 0 to 31 := 0;
	variable filter_start_pointer : integer range 0 to 200 := 100;
	variable p : integer range 0 to 511;

	begin	
		if clk_in'event and clk_in = '0' then
			if ack = true then	
				if write_pointer = 0 or write_pointer > 200 then
					write_pointer <= 200;
				else
					write_pointer <= write_pointer - 1;
				end if;		
				if m = 31 then
					filter_start_pointer := write_pointer_last;
					m := 0;
					n := 0;			
				else
					m := m + 1;
				end if;
			end if;

			p := filter_start_pointer + n;
			if p > 200 then
				read_pointer <= p - 201;
			else
				read_pointer <= p;
			end if;
			
			if n < 160 then
				if n = 1 then
					nn := 159;
				elsif n = 0 then
					nn := 158;
				else
					nn := n - 2;
				end if;
				
            prod_I := I_synch*filtkoeff(nn);  -- Ia(32*m)
				prod_Q := Q_synch*filtkoeff(nn);
				
				if nn = 0 then
					if rx_att = "11" then
						Data_out_I <= std_logic_vector(mac_I + to_signed(268435456,60))(52 downto 29);  
						Data_out_Q <= std_logic_vector(mac_Q + to_signed(268435456,60))(52 downto 29);
					elsif rx_att = "10" then
						Data_out_I <= std_logic_vector(mac_I + to_signed(134217728,60))(51 downto 28); 
						Data_out_Q <= std_logic_vector(mac_Q + to_signed(134217728,60))(51 downto 28);
					elsif rx_att = "01" then
						Data_out_I <= std_logic_vector(mac_I + to_signed(67108864,60))(50 downto 27);  
						Data_out_Q <= std_logic_vector(mac_Q + to_signed(67108864,60))(50 downto 27);
					else
						Data_out_I <= std_logic_vector(mac_I + to_signed(33554432,60))(49 downto 26);  
						Data_out_Q <= std_logic_vector(mac_Q + to_signed(33554432,60))(49 downto 26);
					end if;
					mac_I <= to_signed(0,61) + prod_I;
					mac_Q <= to_signed(0,61) + prod_Q;
				else
					mac_I <= mac_I + prod_I;
					mac_Q <= mac_Q + prod_Q;
				end if;
				
				if nn = 2 then
					clk_out_next <= true;
				else
					clk_out_next <= false;
				end if;

            n := n + 1;
         end if;
			
		end if;
	end process;
	
	sample_ff : process(clk_sample,ack)
	begin
		if ack = true then
			sample <= false;
		elsif clk_sample'event and clk_sample = '1' then
			sample <= true;
		end if;
	end process;
	
end down_dec_arch;