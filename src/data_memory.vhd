
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity data_memory is
    port (
        clk        : in  std_logic;
        mem_read   : in  std_logic;
        mem_write  : in  std_logic;
        address    : in  std_logic_vector(15 downto 0);
        write_data : in  std_logic_vector(15 downto 0);
        read_data  : out std_logic_vector(15 downto 0)
    );
end entity;

architecture rtl of data_memory is

    type memory_type is array (0 to 255)
        of std_logic_vector(15 downto 0);

    signal ram : memory_type := (others => (others => '0'));

begin

    -- Escrita sincrona
    process(clk)
    begin
        if rising_edge(clk) then
            if mem_write = '1' then
                if unsigned(address) < 256 then
                    ram(to_integer(unsigned(address))) <= write_data;
                end if;
            end if;
        end if;
    end process;

    -- Leitura combinacional (VHDL-93 compativel)
    read_data <= ram(to_integer(unsigned(address)))
                 when (mem_read = '1' and unsigned(address) < 256)
                 else (others => '0');

end architecture;
