library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity datapath_tb is
end entity;

architecture test of datapath_tb is
    signal clk : std_logic := '0';
    signal reset, step : std_logic := '0';
    signal pc, instr, result : std_logic_vector(15 downto 0);

    type words is array (natural range <>) of std_logic_vector(15 downto 0);
    constant expected_instr : words :=
        (x"0850", x"1B18", x"2D58", x"3FA0",
         x"40B8", x"43D0", x"0608", x"F000");
    constant expected_result : words :=
        (x"0004", x"FFFB", x"0009", x"000D",
         x"0001", x"0000", x"0001", x"0000");
begin
    dut : entity work.datapath
        port map (clk => clk, reset => reset, step => step,
                  pc_out => pc, instr_out => instr, result_out => result);

    process
        procedure tick is
        begin
            clk <= '0';
            wait for 5 ns;
            clk <= '1';
            wait for 5 ns;
        end procedure;
    begin
        reset <= '1';
        tick;
        reset <= '0';
        tick;
        assert pc = x"0000" and result = x"0004"
            report "PC ou resultado mudou sem passo" severity failure;

        for i in expected_instr'range loop
            assert pc = std_logic_vector(to_unsigned(i, 16))
                report "PC incorreto no passo " & integer'image(i) severity failure;
            assert instr = expected_instr(i)
                report "Instrucao incorreta no PC " & integer'image(i) severity failure;
            assert result = expected_result(i)
                report "Resultado incorreto no PC " & integer'image(i) severity failure;
            step <= '1';
            tick;
        end loop;

        assert pc = x"0007" report "PC avancou apos o fim" severity failure;
        reset <= '1';
        tick;
        assert pc = x"0000" and result = x"0004"
            report "Reset nao restaurou PC e operandos iniciais" severity failure;

        report "Testes do datapath concluidos" severity note;
        wait;
    end process;
end architecture;
