library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cpu_tb is
end entity cpu_tb;

architecture logica of cpu_tb is

    signal clk  : std_logic := '0';
    signal key  : std_logic_vector(3 downto 0) := "1111";
    signal sw   : std_logic_vector(17 downto 0) := (others => '0');
    signal ledg : std_logic_vector(7 downto 0);
    signal hex0, hex1, hex2, hex3 : std_logic_vector(6 downto 0);
    signal hex4, hex5, hex6, hex7 : std_logic_vector(6 downto 0);

    signal sim_done : boolean := false;

begin

    uut : entity work.cpu
        generic map (
            DEBOUNCE_CYCLES => 2
        )
        port map (
            CLOCK_50 => clk,
            KEY      => key,
            SW       => sw,
            LEDG     => ledg,
            HEX0     => hex0,
            HEX1     => hex1,
            HEX2     => hex2,
            HEX3     => hex3,
            HEX4     => hex4,
            HEX5     => hex5,
            HEX6     => hex6,
            HEX7     => hex7
        );

    -- Clock de 50 MHz (periodo de 20 ns)
    clk_process : process
    begin
        while not sim_done loop
            clk <= '0';
            wait for 10 ns;
            clk <= '1';
            wait for 10 ns;
        end loop;
        wait;
    end process;

    -- Estimulos simulando cliques no botao KEY(0) e chave SW(17)
    stimulus_process : process
        procedure press_step is
        begin
            key(0) <= '0';
            wait for 120 ns;
            key(0) <= '1';
            wait for 120 ns;
        end procedure;
    begin
        -- Reset inicial via KEY(1) ativo em '0'
        key(1) <= '0';
        wait for 100 ns;
        key(1) <= '1';
        wait for 60 ns;

        -- Verifica estado inicial FETCH (LEDG = 0x01) e PC = 0000
        assert ledg = "00000001"
            report "Erro: estado inicial apos reset deveria ser FETCH (0x01)" severity error;
        assert hex0 = "1000000" and hex1 = "1000000" and hex2 = "1000000" and hex3 = "1000000"
            report "Erro: PC inicial apos reset deveria ser 0000" severity error;

        -- Executa 11 passos (ADDI R1=10, ADDI R2=5, inicio ADD) -> no passo 11 ALUOut = 0x000F
        for s in 1 to 11 loop
            press_step;
        end loop;

        -- Em WB_R de ADD R3, R1, R2 (SW17 = '0' mostra ALUOut = 000F)
        assert hex4 = "0001110" and hex5 = "1000000" and hex6 = "1000000" and hex7 = "1000000"
            report "Erro: ALUOut esperado 000F apos ADD R3, R1, R2" severity error;

        -- Avanca ate concluir LD (passo 36 conclui MEM_READ: RDM = 000A)
        for s in 12 to 36 loop
            press_step;
        end loop;

        -- Seleciona RDM nos displays HEX4-HEX7 via SW(17) = '1'
        sw(17) <= '1';
        wait for 20 ns;
        assert hex4 = "0001000" and hex5 = "1000000" and hex6 = "1000000" and hex7 = "1000000"
            report "Erro: RDM esperado 000A apos LD R0, R0, 4" severity error;

        -- Volta SW(17) para '0' e avanca ate passar BEQ, BNE e entrar no loop JMP 12 (0x000C)
        sw(17) <= '0';
        for s in 37 to 46 loop
            press_step;
        end loop;

        assert hex0 = "1000110" and hex1 = "1000000" and hex2 = "1000000" and hex3 = "1000000"
            report "Erro: PC esperado 000C apos BNE e JMP 12" severity error;

        -- Executa mais um ciclo do JMP 12 para confirmar loop estavel em 0x000C
        for s in 47 to 49 loop
            press_step;
        end loop;

        assert hex0 = "1000110" and hex1 = "1000000" and hex2 = "1000000" and hex3 = "1000000"
            report "Erro: PC deveria permanecer em 000C no loop do JMP 12" severity error;

        report "Simulacao global cpu_tb concluida com sucesso!" severity note;
        sim_done <= true;
        wait;
    end process;

end architecture logica;