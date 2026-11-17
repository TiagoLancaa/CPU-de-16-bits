library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cpu is
    generic (
        -- 500.000 ciclos = ~10 ms em 50 MHz (placa). No testbench, pode ser alterado para 2.
        DEBOUNCE_CYCLES : positive := 500_000
    );
    port (
        CLOCK_50 : in  std_logic;                     -- Clock principal da placa DE2-115 (50 MHz)
        KEY      : in  std_logic_vector(3 downto 0);  -- KEY(0): Passo de clock / KEY(1): Reset
        SW       : in  std_logic_vector(17 downto 0); -- SW(17): Seleciona RDM ('1') vs ULA ('0') nos HEX4-7
        LEDG     : out std_logic_vector(7 downto 0);  -- Estado atual da Unidade de Controle nos LEDs Verdes
        HEX0     : out std_logic_vector(6 downto 0);  -- PC (bits 3 downto 0)
        HEX1     : out std_logic_vector(6 downto 0);  -- PC (bits 7 downto 4)
        HEX2     : out std_logic_vector(6 downto 0);  -- PC (bits 11 downto 8)
        HEX3     : out std_logic_vector(6 downto 0);  -- PC (bits 15 downto 12)
        HEX4     : out std_logic_vector(6 downto 0);  -- Saída multiplexada (bits 3 downto 0)
        HEX5     : out std_logic_vector(6 downto 0);  -- Saída multiplexada (bits 7 downto 4)
        HEX6     : out std_logic_vector(6 downto 0);  -- Saída multiplexada (bits 11 downto 8)
        HEX7     : out std_logic_vector(6 downto 0)   -- Saída multiplexada (bits 15 downto 12)
    );
end entity cpu;

architecture estrutural of cpu is

    -- Sinais de sincronização e debouncer para a chave KEY(0)
    signal key_meta, key_sync : std_logic_vector(1 downto 0) := "11";
    signal reset        : std_logic;
    signal step_level   : std_logic := '1';
    signal step_pulse   : std_logic := '0';
    signal stable_count : natural range 0 to DEBOUNCE_CYCLES - 1 := 0;

    -- Sinais de interconexão entre FSM (Unidade de Controle) e Datapath
    signal opcode       : std_logic_vector(3 downto 0);
    signal zero_flag    : std_logic;
    signal reg_write    : std_logic;
    signal mem_read     : std_logic;
    signal mem_write    : std_logic;
    signal branch       : std_logic;
    signal bne          : std_logic;
    signal jump         : std_logic;
    signal alu_src      : std_logic;
    signal mem_to_reg   : std_logic;
    signal alu_op       : std_logic_vector(2 downto 0);
    signal estado_ctrl  : std_logic_vector(7 downto 0);

    -- Barramentos conectados ao Datapath expandido
    signal pc_sig       : std_logic_vector(15 downto 0);
    signal alu_sig      : std_logic_vector(15 downto 0);
    signal rdm_sig      : std_logic_vector(15 downto 0);
    signal hex4_7_val   : std_logic_vector(15 downto 0);

    -- Conversão binário para display de 7 segmentos (ânodo comum: ativo em '0')
    function to_7seg(valor : std_logic_vector(3 downto 0)) return std_logic_vector is
    begin
        case valor is
            when "0000" => return "1000000"; -- 0
            when "0001" => return "1111001"; -- 1
            when "0010" => return "0100100"; -- 2
            when "0011" => return "0110000"; -- 3
            when "0100" => return "0011001"; -- 4
            when "0101" => return "0010010"; -- 5
            when "0110" => return "0000010"; -- 6
            when "0111" => return "1111000"; -- 7
            when "1000" => return "0000000"; -- 8
            when "1001" => return "0010000"; -- 9
            when "1010" => return "0001000"; -- A
            when "1011" => return "0000011"; -- b
            when "1100" => return "1000110"; -- C
            when "1101" => return "0100001"; -- d
            when "1110" => return "0000110"; -- E
            when "1111" => return "0001110"; -- F
            when others => return "1111111";
        end case;
    end function;

begin

    -- Circuito Debouncer do botão KEY(0) e sinal de Reset ativo em '1' via KEY(1)
    process (CLOCK_50)
    begin
        if rising_edge(CLOCK_50) then
            key_meta   <= KEY(1 downto 0);
            key_sync   <= key_meta;
            step_pulse <= '0';

            if key_sync(0) = step_level then
                stable_count <= 0;
            elsif stable_count = DEBOUNCE_CYCLES - 1 then
                step_level   <= key_sync(0);
                step_pulse   <= not key_sync(0);
                stable_count <= 0;
            else
                stable_count <= stable_count + 1;
            end if;
        end if;
    end process;

    reset <= not key_sync(1);

    -- Instanciação da Unidade de Controle (Pedro)
    uc : entity work.unidade_controle
        port map (
            clk       => CLOCK_50,
            reset     => reset,
            step      => step_pulse,
            Opcode    => opcode,
            Zero      => zero_flag,
            RegWrite  => reg_write,
            MemRead   => mem_read,
            MemWrite  => mem_write,
            Branch    => branch,
            BNE       => bne,
            Jump      => jump,
            ALUSrc    => alu_src,
            MemToReg  => mem_to_reg,
            ALUOp     => alu_op,
            EstadoLED => estado_ctrl
        );

    -- Instanciação do Datapath expandido (Eloise / Tiago)
    core : entity work.datapath
        port map (
            clk      => CLOCK_50,
            reset    => reset,
            step     => step_pulse,
            RegWrite => reg_write,
            MemRead  => mem_read,
            MemWrite => mem_write,
            Branch   => branch,
            BNE      => bne,
            Jump     => jump,
            ALUSrc   => alu_src,
            MemToReg => mem_to_reg,
            ALUOp    => alu_op,
            Opcode   => opcode,
            Zero     => zero_flag,
            PCOut    => pc_sig,
            ALUOut   => alu_sig,
            RDMOut   => rdm_sig
        );

    -- LEDs Verdes exibem o estado atual da Unidade de Controle
    LEDG <= estado_ctrl;

    -- Multiplexação da chave SW(17): '1' exibe RDM (Memória), '0' exibe ULA
    hex4_7_val <= rdm_sig when SW(17) = '1' else alu_sig;

    -- Mapeamento do Program Counter (PC) nos displays HEX0 a HEX3
    HEX0 <= to_7seg(pc_sig(3 downto 0));
    HEX1 <= to_7seg(pc_sig(7 downto 4));
    HEX2 <= to_7seg(pc_sig(11 downto 8));
    HEX3 <= to_7seg(pc_sig(15 downto 12));

    -- Mapeamento da saída multiplexada (RDM vs ULA) nos displays HEX4 a HEX7
    HEX4 <= to_7seg(hex4_7_val(3 downto 0));
    HEX5 <= to_7seg(hex4_7_val(7 downto 4));
    HEX6 <= to_7seg(hex4_7_val(11 downto 8));
    HEX7 <= to_7seg(hex4_7_val(15 downto 12));

end architecture estrutural;
