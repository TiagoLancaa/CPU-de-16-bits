library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity datapath is
    port (
        clk            : in  std_logic;
        reset          : in  std_logic;
        step           : in  std_logic;

        -- Sinais vindos da Unidade de Controle (FSM Multiciclo)
        pc_write       : in  std_logic;
        pc_write_cond  : in  std_logic;
        branch_ne      : in  std_logic;
        pc_src         : in  std_logic_vector(1 downto 0);
        ir_write       : in  std_logic;
        mem_read       : in  std_logic;
        mem_write      : in  std_logic;
        reg_write      : in  std_logic;
        mem_to_reg     : in  std_logic;
        reg_read_b_sel : in  std_logic;
        alu_src_a      : in  std_logic;
        alu_src_b      : in  std_logic_vector(1 downto 0);
        alu_op         : in  std_logic_vector(2 downto 0);

        -- Sinais de feedback para a UC e saidas para a placa DE2-115
        opcode         : out std_logic_vector(3 downto 0);
        zero_flag      : out std_logic;
        pc_out         : out std_logic_vector(15 downto 0);
        instr_out      : out std_logic_vector(15 downto 0);
        alu_out        : out std_logic_vector(15 downto 0);
        rdm_out        : out std_logic_vector(15 downto 0)
    );
end entity datapath;

architecture rtl of datapath is

    subtype word is std_logic_vector(15 downto 0);

    -- Registradores arquiteturais e de ciclo (Multiciclo)
    signal pc_reg      : word := x"0000";
    signal ir_reg      : word := x"0000";
    signal reg_a       : word := x"0000";
    signal reg_b       : word := x"0000";
    signal alu_out_reg : word := x"0000";
    signal mdr_reg     : word := x"0000";

    -- Sinais das memorias
    signal mem_instr_data : word;
    signal mem_data_read  : word;

    -- Extensores de operando (Tipo I e Tipo J)
    signal extended_i : word;
    signal extended_j : word;

    -- Banco de registradores e MUXes
    signal read_addr_b_mux : std_logic_vector(2 downto 0);
    signal rf_read_a       : word;
    signal rf_read_b       : word;
    signal rf_write_data   : word;
    signal rf_write_en     : std_logic;
    signal dm_write_en     : std_logic;

    -- ULA e desvios
    signal alu_in_a     : word;
    signal alu_in_b     : word;
    signal alu_result   : word;
    signal alu_zero     : std_logic;
    signal next_pc      : word;
    signal branch_taken : std_logic;
    signal pc_enable    : std_logic;

begin

    --------------------------------------------------
    -- MEMORIA DE INSTRUCOES (Enderecamento por palavra)
    --------------------------------------------------
    memory_instruction : entity work.instruction_memory
        port map (
            address  => pc_reg,
            data_out => mem_instr_data
        );

    --------------------------------------------------
    -- EXTENSOR DE OPERANDOS (Tipo I com sinal, Tipo J zero-ext)
    --------------------------------------------------
    extender : entity work.operand_extender
        port map (
            immediate_i => ir_reg(5 downto 0),
            address_j   => ir_reg(11 downto 0),
            extended_i  => extended_i,
            extended_j  => extended_j
        );

    --------------------------------------------------
    -- MUX DE LEITURA B DO BANCO DE REGISTRADORES
    -- '0': Rk IR(5..3) para Tipo R | '1': Ri IR(11..9) para ST, BEQ, BNE
    --------------------------------------------------
    read_addr_b_mux <= ir_reg(11 downto 9) when reg_read_b_sel = '1'
                       else ir_reg(5 downto 3);

    rf_write_en <= reg_write and step;
    dm_write_en <= mem_write and step;

    registers : entity work.regfile
        generic map (
            reset_r1 => x"0000",
            reset_r2 => x"0000",
            reset_r3 => x"0000"
        )
        port map (
            clk          => clk,
            reset        => reset,
            write_enable => rf_write_en,
            write_addr   => ir_reg(11 downto 9),
            write_data   => rf_write_data,
            read_addr_a  => ir_reg(8 downto 6),
            read_addr_b  => read_addr_b_mux,
            read_data_a  => rf_read_a,
            read_data_b  => rf_read_b
        );

    --------------------------------------------------
    -- MUXES DA ULA (Entrada A e Entrada B)
    --------------------------------------------------
    mux_alu_a : entity work.mux2_16
        port map (
            entrada_a => pc_reg,
            entrada_b => reg_a,
            seletor   => alu_src_a,
            saida     => alu_in_a
        );

    mux_alu_b : entity work.mux4_16
        port map (
            entrada_0 => reg_b,
            entrada_1 => x"0001",
            entrada_2 => extended_i,
            entrada_3 => extended_i,
            seletor   => alu_src_b,
            saida     => alu_in_b
        );

    --------------------------------------------------
    -- ULA DE 16 BITS
    --------------------------------------------------
    alu : entity work.ULA
        port map (
            A        => alu_in_a,
            B        => alu_in_b,
            ULACtl   => alu_op,
            R        => alu_result,
            Zero     => alu_zero,
            Overflow => open,
            Cout     => open
        );

    --------------------------------------------------
    -- MEMORIA DE DADOS (RDM)
    --------------------------------------------------
    memory_data : entity work.data_memory
        port map (
            clk        => clk,
            mem_read   => mem_read,
            mem_write  => dm_write_en,
            address    => alu_out_reg,
            write_data => reg_b,
            read_data  => mem_data_read
        );

    --------------------------------------------------
    -- MUX DE WRITE-BACK (ALUOut vs RDM)
    --------------------------------------------------
    mux_writeback : entity work.mux2_16
        port map (
            entrada_a => alu_out_reg,
            entrada_b => mdr_reg,
            seletor   => mem_to_reg,
            saida     => rf_write_data
        );

    --------------------------------------------------
    -- MUX DE PROXIMO PC E LOGICA DE DESVIO (BEQ / BNE / JMP)
    --------------------------------------------------
    mux_pc : entity work.mux4_16
        port map (
            entrada_0 => alu_result,
            entrada_1 => alu_out_reg,
            entrada_2 => extended_j,
            entrada_3 => alu_result,
            seletor   => pc_src,
            saida     => next_pc
        );

    branch_taken <= pc_write_cond and (alu_zero xor branch_ne);
    pc_enable    <= pc_write or branch_taken;

    --------------------------------------------------
    -- REGISTRADORES SINCRONOS MULTICICLO (avancam com step = '1')
    --------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                pc_reg      <= x"0000";
                ir_reg      <= x"0000";
                reg_a       <= x"0000";
                reg_b       <= x"0000";
                alu_out_reg <= x"0000";
                mdr_reg     <= x"0000";
            elsif step = '1' then
                if pc_enable = '1' then
                    pc_reg <= next_pc;
                end if;

                if ir_write = '1' then
                    ir_reg <= mem_instr_data;
                end if;

                reg_a       <= rf_read_a;
                reg_b       <= rf_read_b;
                alu_out_reg <= alu_result;

                if mem_read = '1' then
                    mdr_reg <= mem_data_read;
                end if;
            end if;
        end if;
    end process;

    --------------------------------------------------
    -- SAIDAS PARA UNIDADE DE CONTROLE E DISPLAYS
    --------------------------------------------------
    opcode    <= ir_reg(15 downto 12);
    zero_flag <= alu_zero;
    pc_out    <= pc_reg;
    instr_out <= ir_reg;
    alu_out   <= alu_out_reg;
    rdm_out   <= mdr_reg;

end architecture rtl;
