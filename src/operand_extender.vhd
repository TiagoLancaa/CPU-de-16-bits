library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity operand_extender is
    port (
        immediate_i : in  std_logic_vector(5 downto 0);
        address_j   : in  std_logic_vector(11 downto 0);
        extended_i  : out std_logic_vector(15 downto 0);
        extended_j  : out std_logic_vector(15 downto 0)
    );
end entity;

architecture rtl of operand_extender is
begin
    -- Tipo I: estende o imediato de 6 para 16 bits preservando o sinal.
    extended_i <= std_logic_vector(resize(signed(immediate_i), 16));

    -- Tipo J: completa o endereço absoluto do JMP com zeros à esquerda.
    extended_j <= std_logic_vector(resize(unsigned(address_j), 16));
end architecture;
