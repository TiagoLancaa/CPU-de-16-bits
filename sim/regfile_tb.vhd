library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity regfile_tb is

end entity;

architecture logica of regfile_tb is
	signal clk            : std_logic;
   signal reset          : std_logic;
   signal write_enable   : std_logic;
   signal write_addr     : std_logic_vector(2 downto 0);
   signal write_data     : std_logic_vector(15 downto 0);
   signal read_addr_a    : std_logic_vector(2 downto 0);
   signal read_addr_b    : std_logic_vector(2 downto 0);
   signal read_data_a    : std_logic_vector(15 downto 0);
   signal read_data_b    : std_logic_vector(15 downto 0);
	
	begin
		tes_reg: entity work.regfile PORT MAP(
			clk, reset, write_enable, write_addr, write_data, 
			read_addr_a, read_addr_b, read_data_a, read_data_b
		);
		--gera clock
		clock: process
		begin
			clk <= '0';
			wait for 100 ps;
			clk <= '1'; 
			wait for 100 ps;
		end process;
		
		--gera write enable
		enable: process
		begin
			write_enable <= '1';
			wait for 500 ps;
			write_enable <= '0';
			wait for 200 ps;
		end process;
		
		--gera reset
		res: process
		begin
			reset <= '0';
			wait for 1000 ps;
			reset <= '1';
			wait for 200 ps;
		end process;
		
		--gera write_addr
		waddr: process
		begin
			for i in 0 to 2 loop
				write_addr <= std_logic_vector(to_unsigned(i,3));
				wait for 100 ps;
			end loop;
		end process;
		
		--gera write_data
		wdata: process
			variable x: integer := 0;
		
		begin
			for i in 0 to 17 loop
				x := i*3855;
				write_data <= std_logic_vector(to_unsigned(x,16));
				wait for 100 ps;
			end loop;
		end process;
		
		--gera read_addr_a
		addr_a: process
		begin
			for i in 0 to 2 loop
				read_addr_a <= std_logic_vector(to_unsigned(i,3));
				wait for 100 ps;
			end loop;
		end process;
		
		--gera read_addr_b
		addr_b: process
		begin
			for i in 2 downto 0 loop
				read_addr_b <= std_logic_vector(to_unsigned(i,3));
				wait for 100 ps;
			end loop;
		end process;
		
end logica;

		  
	