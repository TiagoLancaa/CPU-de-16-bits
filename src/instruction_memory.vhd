
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity instruction_memory is
    port (
        address  : in std_logic_vector(15 downto 0);
        data_out : out std_logic_vector(15 downto 0)
    );
end entity;

architecture rtl of instruction_memory is

    type rom_type is array (0 to 255)
        of std_logic_vector(15 downto 0);

    signal rom : rom_type;

    attribute ram_init_file : string;
	 attribute ram_init_file of rom : signal
		is "C:/Users/25004196/Downloads/CPU-de-16-bits/src/ini_mem.mif";

begin

    data_out <= rom(to_integer(unsigned(address)))
                when unsigned(address) < 256
                else (others => '0');

end architecture;
