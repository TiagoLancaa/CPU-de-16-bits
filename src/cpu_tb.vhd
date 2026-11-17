library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cpu_tb is

end entity cpu_tb;

architecture logica of cpu_tb is

    -- Sinais de teste
    signal clk        : std_logic := '0';
    signal key        : std_logic_vector(3 downto 0) := "1111";
    signal sw         : std_logic_vector(17 downto 0) := (others => '0');
    signal ledg       : std_logic_vector(7 downto 0);
    signal hex0, hex1, hex2, hex3 : std_logic_vector(6 downto 0);
    signal hex4, hex5, hex6, hex7 : std_logic_vector(6 downto 0);

    

begin

    
    uut : entity work.cpu
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

    -- Processo gerador de Clock direto
    clk_process : process
    begin
        clk <= '0';
        wait for 20 ns;
        clk <= '1';
        wait for 20 ns;
    end process;

    -- Processo de Estímulos (Reseta no início e deixa rodando direto)
    stimulus_process : process
    begin
        -- Aciona o Reset (KEY(1) em '0') por 50 ns
        key(1) <= '0';
        wait for 50 ns;
        
        -- Libera o Reset (KEY(1) em '1')
        key(1) <= '1';
        
        -- Deixa rodando livremente por tempo suficiente para executar o programa do .mif
        wait for 2000 ns;
        
        -- Fim da simulação
        wait;
    end process;

end architecture logica;