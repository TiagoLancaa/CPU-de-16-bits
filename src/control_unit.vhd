library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity control_unit is     --entidade da unidade de controle
    port (
        clk           : in  std_logic;      -- entrade de clock (sincronizada com botão de debounce ou gerador de clock) 
        reset         : in  std_logic;      -- entrada de reset assíncrono (reiniciar a CPU)
        opcode        : in  std_logic_vector(3 downto 0);   -- 4 bits mais significativos da instrução (operação a ser realizada)
        pc_write      : out std_logic;      -- habilita a escrita incondicional no PC (Fetch e Jump)
        pc_write_cond : out std_logic;      -- habilita a escrita consicional no PC (Branch)
        i_or_d        : out std_logic;      -- seleciona entre o endereço do PC (0) ou endereço da ULA (1) para acessar a memória
        mem_read      : out std_logic;      -- habilita a leitura da memória    
        mem_write     : out std_logic;      -- habilita a escrita na memória
        ir_write      : out std_logic;      -- habilita a escrita no registrador de instrução (IR)
        reg_write     : out std_logic;      -- habilita a escrita no banco de registradores
        mem_to_reg    : out std_logic;      -- seleciona entre o dado da memória (1) ou o resultado da ULA (0) para escrever no banco de registradores
        alu_src_a     : out std_logic;      -- seleciona entre o registrador A (0) ou o PC (1) como entrada A da ULA
        alu_src_b     : out std_logic_vector(1 downto 0);       -- seleciona entre o registrador B (00), constante 4 (01), imediato (10) ou deslocamento (11) como entrada B da ULA
        alu_op        : out std_logic_vector(2 downto 0);       -- seleciona a operação da ULA: 000=AND, 001=OR, 010=ADD, 110=SUB, 111=SLT, 100=BEQ/BNE
        pc_src        : out std_logic_vector(1 downto 0);       -- seletor da fonte que atualiza o PC: 00=ULA, 01=ULA (Branch), 10=Jump
        state_leds    : out std_logic_vector(7 downto 0)        -- LEDs que indicam o estado atual da máquina de estados
    );
end entity control_unit;

architecture behavioral of control_unit is

    type state_type is (    -- enum de estados da máquina multiciclo
        FETCH,              -- busca da instrução na memória e incremento do PC
        DECODE,             -- decodificação do opcode e leitura dos registradores
        EXEC_R,             -- execução da operação aritmética ou lógica (R-type)
        WB_R,               -- gravação do resultado da operação R-type no registrador Ri
        EXEC_ADDI,          -- execução da operação aritmética ADDI (Rj + imediato)
        WB_I,               -- gravação do resultado de ADDI no registrador Ri
        MEM_ADDR,           -- cálculo do endereço efetivo de memória (Rj + imediato) para LS e ST
        MEM_READ,           -- leitura da memória (ciclo de acesso para LD)
        MEM_WB,             -- gravação do dado lido da memória no registrador Ri
        MEM_WRITE,          -- escrita do dado de Ri na memória (ciclo de acesso para ST)
        BRANCH_BEQ,         -- verificação de igualdade dos operandos e atualização condicional do PC (BEQ)
        BRANCH_BNE,         -- verificação de desigualdade dos operandos e atualização condicional do PC (BNE)
        JUMP                -- atualização incondicional do PC (JUMP)
    );

    signal current_state, next_state : state_type; --sinais internos para armazenar o estado atual e o próximo estado da FSM

begin
    --Lógica combinacional de Transição de estados
    process(clk, reset)
    begin
        if reset = '1' then
            current_state <= FETCH;
        elsif rising_edge(clk) then
            current_state <= next_state;
        end if;
    end process;

    process(current_state, opcode)
    begin
        next_state <= FETCH;

        case current_state is
            when FETCH =>
                next_state <= DECODE;

            when DECODE =>
                case opcode is
                    when "0000" | "0001" | "0010" | "0011" | "0100" =>
                        next_state <= EXEC_R;
                    when "0101" =>
                        next_state <= EXEC_ADDI;
                    when "0110" | "0111" =>
                        next_state <= MEM_ADDR;
                    when "1000" =>
                        next_state <= BRANCH_BEQ;
                    when "1001" =>
                        next_state <= BRANCH_BNE;
                    when "1010" =>
                        next_state <= JUMP;
                    when others =>
                        next_state <= FETCH;
                end case;

            when EXEC_R =>
                next_state <= WB_R;

            when WB_R =>
                next_state <= FETCH;

            when EXEC_ADDI =>
                next_state <= WB_I;

            when WB_I =>
                next_state <= FETCH;

            when MEM_ADDR =>
                if opcode = "0110" then
                    next_state <= MEM_READ;
                else
                    next_state <= MEM_WRITE;
                end if;

            when MEM_READ =>
                next_state <= MEM_WB;

            when MEM_WB =>
                next_state <= FETCH;

            when MEM_WRITE =>
                next_state <= FETCH;

            when BRANCH_BEQ =>
                next_state <= FETCH;

            when BRANCH_BNE =>
                next_state <= FETCH;

            when JUMP =>
                next_state <= FETCH;

            when others =>
                next_state <= FETCH;
        end case;
    end process;

    -- Lógica combinacional de saídas de controle
    process(current_state, opcode)
    begin
        pc_write      <= '0';
        pc_write_cond <= '0';
        i_or_d        <= '0';
        mem_read      <= '0';
        mem_write     <= '0';
        ir_write      <= '0';
        reg_write     <= '0';
        mem_to_reg    <= '0';
        alu_src_a     <= '0';
        alu_src_b     <= "00";
        alu_op        <= "010";
        pc_src        <= "00";
        state_leds    <= "00000000";

        case current_state is
            when FETCH =>
                mem_read   <= '1';
                ir_write   <= '1';
                alu_src_a  <= '0';
                alu_src_b  <= "01";
                alu_op     <= "010";
                pc_write   <= '1';
                pc_src     <= "00";
                state_leds <= "00000001";

            when DECODE =>
                alu_src_a  <= '0';
                alu_src_b  <= "11";
                alu_op     <= "010";
                state_leds <= "00000010";

            when EXEC_R =>
                alu_src_a <= '1';
                alu_src_b <= "00";
                case opcode is
                    when "0000" =>
                        alu_op <= "010";
                    when "0001" =>
                        alu_op <= "100";
                    when "0010" =>
                        alu_op <= "000";
                    when "0011" =>
                        alu_op <= "001";
                    when "0100" =>
                        alu_op <= "110";
                    when others =>
                        alu_op <= "010";
                end case;
                state_leds <= "00000100";

            when WB_R =>
                reg_write  <= '1';
                mem_to_reg <= '0';
                state_leds <= "00001000";

            when EXEC_ADDI =>
                alu_src_a  <= '1';
                alu_src_b  <= "10";
                alu_op     <= "010";
                state_leds <= "00010000";

            when WB_I =>
                reg_write  <= '1';
                mem_to_reg <= '0';
                state_leds <= "00010001";

            when MEM_ADDR =>
                alu_src_a  <= '1';
                alu_src_b  <= "10";
                alu_op     <= "010";
                state_leds <= "00100000";

            when MEM_READ =>
                mem_read   <= '1';
                i_or_d     <= '1';
                state_leds <= "00100001";

            when MEM_WB =>
                reg_write  <= '1';
                mem_to_reg <= '1';
                state_leds <= "00100010";

            when MEM_WRITE =>
                mem_write  <= '1';
                i_or_d     <= '1';
                state_leds <= "00100100";

            when BRANCH_BEQ =>
                alu_src_a     <= '1';
                alu_src_b     <= "00";
                alu_op        <= "100";
                pc_write_cond <= '1';
                pc_src        <= "01";
                state_leds    <= "01000000";

            when BRANCH_BNE =>
                alu_src_a     <= '1';
                alu_src_b     <= "00";
                alu_op        <= "100";
                pc_write_cond <= '1';
                pc_src        <= "01";
                state_leds    <= "01000001";

            when JUMP =>
                pc_write   <= '1';
                pc_src     <= "10";
                state_leds <= "10000000";

            when others =>
                state_leds <= "00000000";
        end case;
    end process;

end architecture behavioral;
