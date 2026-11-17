
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity datapath is
    port (
        clk        : in  std_logic;
        reset      : in  std_logic;
        step       : in  std_logic;

        -- Controles dos MUXes e da memoria
        alu_src_b  : in  std_logic_vector(1 downto 0);
        mem_read   : in  std_logic;
        mem_write  : in  std_logic;
        mem_to_reg : in  std_logic;

        -- Saidas
        pc_out     : out std_logic_vector(15 downto 0);
        instr_out  : out std_logic_vector(15 downto 0);
        result_out : out std_logic_vector(15 downto 0)
    );
end entity;

architecture rtl of datapath is

    subtype word is std_logic_vector(15 downto 0);

    -- PC
    signal pc : natural range 0 to 255 := 0;
    signal pc_address : word;

    -- Instrucao e registradores
    signal instr  : word;
    signal a      : word;
    signal b      : word;
    signal result : word;

    -- Controle original da ULA
    signal ula_ctl      : std_logic_vector(2 downto 0);
    signal write_enable : std_logic;

    -- MUXes
    signal alu_operand_b       : word;
    signal register_write_data : word;

    -- Memoria de Dados
    signal memory_read_data : word;

    -- Imediatos
    signal immediate_extended : word;
    signal immediate_shifted  : word;

begin

    --------------------------------------------------
    -- MEMORIA DE INSTRUCOES
    -- CONEXAO DA PARTE ELOISE
    --------------------------------------------------

    pc_address <= std_logic_vector(to_unsigned(pc, 16));

    memory_instruction : entity work.instruction_memory
        port map (
            address  => pc_address,
            data_out => instr
        );

    --------------------------------------------------
    -- EXTENSAO DO IMEDIATO
    --------------------------------------------------

    immediate_extended <=
        std_logic_vector(
            resize(signed(instr(5 downto 0)), 16)
        );

    immediate_shifted <=
        std_logic_vector(
            shift_left(unsigned(immediate_extended), 1)
        );

    --------------------------------------------------
    -- BANCO DE REGISTRADORES
    --------------------------------------------------

    registers : entity work.regfile
        generic map (
            reset_r1 => x"0007",
            reset_r2 => x"FFFD",
            reset_r3 => x"0009"
        )
        port map (
            clk          => clk,
            reset        => reset,
            write_enable => write_enable,
            write_addr   => instr(11 downto 9),
            write_data   => register_write_data,
            read_addr_a  => instr(8 downto 6),
            read_addr_b  => instr(5 downto 3),
            read_data_a  => a,
            read_data_b  => b
        );

    --------------------------------------------------
    -- CONTROLE ORIGINAL DA ULA
    --------------------------------------------------

    with instr(15 downto 12) select
        ula_ctl <=
            "010" when "0000", -- ADD
            "100" when "0001", -- SUB
            "000" when "0010", -- AND
            "001" when "0011", -- OR
            "110" when "0100", -- SLT
            "011" when others;

    write_enable <= '1'
        when step = '1'
        and ula_ctl /= "011"
        else '0';

    --------------------------------------------------
    -- MUX 4:1 DA ENTRADA B DA ULA
    -- PARTE ELOISE
    --------------------------------------------------

    mux_alu : entity work.mux4_16
        port map (
            entrada_0 => b,
            entrada_1 => x"0004",
            entrada_2 => immediate_extended,
            entrada_3 => immediate_shifted,
            seletor   => alu_src_b,
            saida     => alu_operand_b
        );

    --------------------------------------------------
    -- ULA
    --------------------------------------------------

    alu : entity work.ULA
        port map (
            A        => a,
            B        => alu_operand_b,
            ULACtl   => ula_ctl,
            R        => result,
            Zero     => open,
            Overflow => open,
            Cout     => open
        );

    --------------------------------------------------
    -- MEMORIA DE DADOS - RDM
    -- PARTE ELOISE
    --------------------------------------------------

    memory_data : entity work.data_memory
        port map (
            clk        => clk,
            mem_read   => mem_read,
            mem_write  => mem_write,
            address    => result,
            write_data => b,
            read_data  => memory_read_data
        );

    --------------------------------------------------
    -- MUX DE RETORNO AO BANCO DE REGISTRADORES
    -- PARTE ELOISE
    --------------------------------------------------

    mux_writeback : entity work.mux2_16
        port map (
            entrada_a => result,
            entrada_b => memory_read_data,
            seletor   => mem_to_reg,
            saida     => register_write_data
        );

    --------------------------------------------------
    -- PC ORIGINAL - PROVISORIO
    --------------------------------------------------

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                pc <= 0;
            elsif step = '1' then
                if pc < 255 then
                    pc <= pc + 1;
                end if;
            end if;
        end if;
    end process;

    --------------------------------------------------
    -- SAIDAS
    --------------------------------------------------

    pc_out     <= pc_address;
    instr_out  <= instr;
    result_out <= result;

end architecture;
