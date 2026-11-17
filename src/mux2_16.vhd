library ieee;
use ieee.std_logic_1164.all;

entity mux2_16 is
    port (
        entrada_a : in  std_logic_vector(15 downto 0);
        entrada_b : in  std_logic_vector(15 downto 0);
        seletor   : in  std_logic;
        saida     : out std_logic_vector(15 downto 0)
    );
end entity;

architecture rtl of mux2_16 is
begin
    saida <= entrada_a when seletor = '0'
             else entrada_b;
end architecture;