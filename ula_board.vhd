library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ula_board is
    port (
        SW   : in  std_logic_vector(17 downto 0);
        LEDR : out std_logic_vector(17 downto 0);
        LEDG : out std_logic_vector(2 downto 0);

        HEX0 : out std_logic_vector(6 downto 0);
        HEX1 : out std_logic_vector(6 downto 0);
        HEX2 : out std_logic_vector(6 downto 0);
        HEX3 : out std_logic_vector(6 downto 0)
    );
end entity ula_board;

architecture funcionamento of ula_board is

    signal A_ext  : std_logic_vector(15 downto 0);
    signal B_ext  : std_logic_vector(15 downto 0);
    signal op_ctl : std_logic_vector(2 downto 0);
    signal R_sig  : std_logic_vector(15 downto 0);

    -- Função pura para decodificar binário para 7 segmentos (catodo comum / anodo comum adaptado)
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

    -- Mapeamento das chaves de acordo com o padrão do Lab 04
    op_ctl <= SW(17 downto 15);
    
    -- Extensão de sinal para transformar 7 bits em 16 bits para A e B
    A_ext(6 downto 0)  <= SW(13 downto 7);
    A_ext(15 downto 7) <= (others => SW(13));

    B_ext(6 downto 0)  <= SW(6 downto 0);
    B_ext(15 downto 7) <= (others => SW(6));

    -- Instância do componente ULA refatorado
    UUT: entity work.ULA
    port map (
        A        => A_ext,
        B        => B_ext,
        ULACtl   => op_ctl,
        R        => R_sig,
        Zero     => LEDG(0),
        Overflow => LEDG(1),
        Cout     => LEDG(2)
    );

    LEDR <= SW;

    -- Mapeamento da saída R_sig (16 bits) para os 4 displays HEX
    HEX0 <= to_7seg(R_sig(3 downto 0));
    HEX1 <= to_7seg(R_sig(7 downto 4));
    HEX2 <= to_7seg(R_sig(11 downto 8));
    HEX3 <= to_7seg(R_sig(15 downto 12));

end architecture funcionamento;