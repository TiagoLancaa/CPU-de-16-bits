library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;   

entity debouncer is
    port (
        clk     : in  std_logic;
        reset   : in  std_logic;
        button_in   : in  std_logic;
        pulse_out   : out std_logic
    );
end entity debouncer;

architecture behavior of debouncer is
    -- Constante de tempo: 50 MHz tem período de 20 ns (50.000.000 ciclos por segundo)
    -- Para esperar 10 milissegundos de estabilidade mecânica: 50.000.000 * 0,010 = 500.000 ciclos
    constant DEBOUNCE_TIME : integer := 500000; -- 

    signal counter : integer range 0 to DEBOUNCE_TIME := 0;     -- Contador de ciclos: varia de 0 até 499.999 (tempo necessário para confirmar a estabilidade)

    signal sync_0 : std_logic := '1'; -- Primeiro estágio de sincronização (evita metaestabilidade de sinal assíncrono)
    signal sync_1 : std_logic := '1'; -- Segundo estágio de sincronização (completa com o domínio de clock de 50 MHz)
    signal state : std_logic := '1'; -- Estado atual do botão (1 = não pressionado, 0 = pressionado)


    begin
        process(clk)
        begin
        if rising_edge(clk) then
        if reset = '1' then --Reinicializa os sinais de sincronização, estado e contador
            sync_0 <= '1';
            sync_1 <= '1';
            state <= '1';
            counter <= 0;
            pulse_out <= '0';
        else
            --Comportamento normal do debouncer (quando não há reset)
            pulse_out <= '0'; -- Inicializa a saída de pulso como 0
            sync_0 <= button_in; -- Primeiro estágio de sincronização: captura o sinal do botão
            sync_1 <= sync_0; -- Segundo estágio de sincronização: captura o sinal

            if sync_1 = state then --Se não houver click no botão
                counter <= 0; --reseta o contador
            else --Se houver click no botão
                if counter = DEBOUNCE_TIME - 1 then --Se o contador ainda atingiu o valor máximo
                    state <= sync_1; --atualiza o estado do botão para o novo valor
                    counter <= 0; --reseta o contador
                    -- Se o novo estado estável for '0', significa que o botão acabou de ser PRESSIONADO
                    if sync_1 = '0' then
                        pulse_out <= '1'; -- Gera um pulso de saída de 1 ciclo de clock
                    end if;
                -- Caso ainda não tenha completado os 10 ms de estabilidade, continua contando
                else
                    counter <= counter + 1;
                end if;
            end if; -- Fim da verificação de igualdade de estado
        end if; -- Fim da condição de reset
    end if; -- Fim da verificação da borda de subida do clock
        
end process; -- Fim do processo síncrono
end architecture behavior; -- Fim da arquitetura do debouncer