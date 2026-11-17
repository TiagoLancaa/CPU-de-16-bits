library ieee;
use ieee.std_logic_1164.all;

entity mux4_16 is
    port (
        entrada_0 : in  std_logic_vector(15 downto 0);
        entrada_1 : in  std_logic_vector(15 downto 0);
        entrada_2 : in  std_logic_vector(15 downto 0);
        entrada_3 : in  std_logic_vector(15 downto 0);
        seletor   : in  std_logic_vector(1 downto 0);
        saida     : out std_logic_vector(15 downto 0)
    );
end entity;

architecture rtl of mux4_16 is
begin
    with seletor select
        saida <= entrada_0 when "00",
                 entrada_1 when "01",
                 entrada_2 when "10",
                 entrada_3 when "11",
                 entrada_0 when others;
end architecture;