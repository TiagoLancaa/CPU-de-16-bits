library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cpu is
    generic (
        -- 500.000 ciclos = ~10 ms em 50 MHz (placa). No testbench, usar valor menor (ex: 2).
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

    -- Sincronizacao de reset (KEY(1) ativo em nivel baixo na placa)
    signal key1_meta  : std_logic := '1';
    signal key1_sync  : std_logic := '1';
    signal reset      : std_logic;
    signal step_pulse : std_logic;

    -- Sinais de interconexao entre FSM (Unidade de Controle) e Datapath
    signal opcode         : std_logic_vector(3 downto 0);
    signal pc_write       : std_logic;
    signal pc_write_cond  : std_logic;
    signal branch_ne      : std_logic;
    signal pc_src         : std_logic_vector(1 downto 0);
    signal ir_write       : std_logic;
    signal mem_read       : std_logic;
    signal mem_write      : std_logic;
    signal reg_write      : std_logic;
    signal mem_to_reg     : std_logic;
    signal reg_read_b_sel : std_logic;
    signal alu_src_a      : std_logic;
    signal alu_src_b      : std_logic_vector(1 downto 0);
    signal alu_op         : std_logic_vector(2 downto 0);
    signal estado_ctrl    : std_logic_vector(7 downto 0);

    -- Barramentos conectados ao Datapath
    signal pc_sig     : std_logic_vector(15 downto 0);
    signal alu_sig    : std_logic_vector(15 downto 0);
    signal rdm_sig    : std_logic_vector(15 downto 0);
    signal hex4_7_val : std_logic_vector(15 downto 0);

begin

    -- Sincronizacao de dois estagios para o botao de reset KEY(1)
    process (CLOCK_50)
    begin
        if rising_edge(CLOCK_50) then
            key1_meta <= KEY(1);
            key1_sync <= key1_meta;
        end if;
    end process;

    reset <= not key1_sync;

    -- Instanciacao do Debouncer para o botao de clock KEY(0)
    db_step : entity work.debouncer
        generic map (
            DEBOUNCE_CYCLES => DEBOUNCE_CYCLES
        )
        port map (
            clk       => CLOCK_50,
            reset     => reset,
            button_in => KEY(0),
            pulse_out => step_pulse
        );

    -- Instanciacao da Unidade de Controle (FSM Multiciclo)
    uc : entity work.control_unit
        port map (
            clk            => CLOCK_50,
            reset          => reset,
            step           => step_pulse,
            opcode         => opcode,
            pc_write       => pc_write,
            pc_write_cond  => pc_write_cond,
            branch_ne      => branch_ne,
            mem_read       => mem_read,
            mem_write      => mem_write,
            ir_write       => ir_write,
            reg_write      => reg_write,
            mem_to_reg     => mem_to_reg,
            reg_read_b_sel => reg_read_b_sel,
            alu_src_a      => alu_src_a,
            alu_src_b      => alu_src_b,
            alu_op         => alu_op,
            pc_src         => pc_src,
            state_leds     => estado_ctrl
        );

    -- Instanciacao do Datapath Multiciclo
    core : entity work.datapath
        port map (
            clk            => CLOCK_50,
            reset          => reset,
            step           => step_pulse,
            pc_write       => pc_write,
            pc_write_cond  => pc_write_cond,
            branch_ne      => branch_ne,
            pc_src         => pc_src,
            ir_write       => ir_write,
            mem_read       => mem_read,
            mem_write      => mem_write,
            reg_write      => reg_write,
            mem_to_reg     => mem_to_reg,
            reg_read_b_sel => reg_read_b_sel,
            alu_src_a      => alu_src_a,
            alu_src_b      => alu_src_b,
            alu_op         => alu_op,
            opcode         => opcode,
            zero_flag      => open,
            pc_out         => pc_sig,
            instr_out      => open,
            alu_out        => alu_sig,
            rdm_out        => rdm_sig
        );

    -- LEDs Verdes exibem o estado atual da Unidade de Controle
    LEDG <= estado_ctrl;

    -- Multiplexacao da chave SW(17): '1' exibe RDM (Memoria), '0' exibe ULA
    hex4_7_val <= rdm_sig when SW(17) = '1' else alu_sig;

    -- Mapeamento do Program Counter (PC) nos displays HEX0 a HEX3
    disp_hex0 : entity work.hex_to_7seg port map (hex_in => pc_sig(3 downto 0),   seg_out => HEX0);
    disp_hex1 : entity work.hex_to_7seg port map (hex_in => pc_sig(7 downto 4),   seg_out => HEX1);
    disp_hex2 : entity work.hex_to_7seg port map (hex_in => pc_sig(11 downto 8),  seg_out => HEX2);
    disp_hex3 : entity work.hex_to_7seg port map (hex_in => pc_sig(15 downto 12), seg_out => HEX3);

    -- Mapeamento da saida multiplexada (RDM vs ULA) nos displays HEX4 a HEX7
    disp_hex4 : entity work.hex_to_7seg port map (hex_in => hex4_7_val(3 downto 0),   seg_out => HEX4);
    disp_hex5 : entity work.hex_to_7seg port map (hex_in => hex4_7_val(7 downto 4),   seg_out => HEX5);
    disp_hex6 : entity work.hex_to_7seg port map (hex_in => hex4_7_val(11 downto 8),  seg_out => HEX6);
    disp_hex7 : entity work.hex_to_7seg port map (hex_in => hex4_7_val(15 downto 12), seg_out => HEX7);

end architecture estrutural;
