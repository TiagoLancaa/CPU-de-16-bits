library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ULA is
    port (
        A        : in  std_logic_vector(15 downto 0);
        B        : in  std_logic_vector(15 downto 0);
        ULACtl   : in  std_logic_vector(2 downto 0);
        R        : out std_logic_vector(15 downto 0);
        Zero     : out std_logic;
        Overflow : out std_logic;
        Cout     : out std_logic
    );
end entity ULA;

architecture comportamental of ULA is
    -- Variáveis com 17 bits para preservar o Carry-Out (bit 16) durante as contas
    signal soma, sub      : unsigned(16 downto 0);
    signal resultado      : std_logic_vector(15 downto 0);
    signal resultado_slt  : std_logic_vector(15 downto 0);
begin

    -- Operações aritméticas base (calculadas continuamente)
    soma <= unsigned('0' & A) + unsigned('0' & B);
    sub  <= unsigned('0' & A) + unsigned('0' & (not B)) + 1;

    -- SLT (Set on Less Than): 1 se A < B (considerando sinal), caso contrário 0
    resultado_slt <= x"0001" when signed(A) < signed(B) else x"0000";

    -- Multiplexador principal da ULA
    with ULACtl select 
        resultado <=
            A and B                             when "000", -- Instrução: AND
            A or B                              when "001", -- Instrução: OR
            std_logic_vector(soma(15 downto 0)) when "010", -- Instruções: ADD, ADDI, LD, ST
            std_logic_vector(sub(15 downto 0))  when "100", -- Instruções: SUB, BEQ, BNE
            resultado_slt                       when "110", -- Instrução: SLT
            A nor B                             when "111", -- (Operação complementar)
            (others => '0')                     when others;

    R <= resultado;

    Zero <= '1' when resultado = x"0000" else '0';

    -- Multiplexação do Carry-Out
    with ULACtl select
        Cout <= soma(16) when "010",
                sub(16)  when "100",
                '0'      when others;

    -- Lógica de detecção de Overflow (valida apenas para soma e subtração)
    Overflow <=
        ((not (A(15) xor B(15))) and (A(15) xor resultado(15))) when ULACtl = "010" else
        ((A(15) xor B(15)) and (A(15) xor resultado(15)))       when ULACtl = "100" else
        '0';

end architecture comportamental;
