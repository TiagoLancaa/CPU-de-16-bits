library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

  entity ula_tb is
 
 end entity;
 
 architecture logica of ula_tb is
	signal ula_op: std_logic_vector(2 downto 0);
	signal A: std_logic_vector(15 downto 0);
	signal B: std_logic_vector(15 downto 0);
   signal R: std_logic_vector(15 downto 0);
   signal Zero: std_logic;
   signal Overflow: std_logic;
   signal Cout: std_logic;
	
	begin
		ula_test: entity work.ULA PORT MAP(A, B, ula_op, R, Zero, OverFlow, Cout);
		
		process
			variable x,y: integer := 0;
			begin
				for op in 0 to 7 loop
					if not ((op = 3) or (op = 5)) then
						-- gera controle ula
						ula_op <= std_logic_vector(to_unsigned(op,3));
						wait for 10 ps;
						
						for i in 0 to 17 loop
							-- gera A e B
							x := i*3855;
							y := (i*975) mod 65635;
							A <= std_logic_vector(to_unsigned(x,16));
							B <= std_logic_vector(to_unsigned(y,16));
							wait for 100 ps;
						end loop;
					end if;
				end loop;
		end process;
end logica;