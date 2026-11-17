
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity instruction_memory is
    port (
        address  : in  std_logic_vector(15 downto 0);
        data_out : out std_logic_vector(15 downto 0)
    );
end entity;

architecture rtl of instruction_memory is

    type rom_type is array (0 to 255)
        of std_logic_vector(15 downto 0);

    -- Espelha o programa do ini_mem.mif do Ayrton.
    -- O arquivo .mif original permanece inalterado.
    signal rom : rom_type := (
        0  => x"520A",
        1  => x"5405",
        2  => x"0650",
        3  => x"1850",
        4  => x"2A50",
        5  => x"3C50",
        6  => x"4E80",
        7  => x"7204",
        8  => x"6004",
        9  => x"8282",
        10 => x"9281",
        11 => x"A00E",
        12 => x"A00C",
        others => x"0000"
    );

    attribute ram_init_file : string;
    attribute ram_init_file of rom : signal is "src/ini_mem.mif";

begin

    process(all)
    begin
        data_out <= (others => '0');

        if unsigned(address) < 256 then
            data_out <= rom(to_integer(unsigned(address)));
        end if;
    end process;

end architecture;
