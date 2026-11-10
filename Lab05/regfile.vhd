library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity regfile is
    generic (
        reset_r1 : std_logic_vector(15 downto 0) := x"0000";
        reset_r2 : std_logic_vector(15 downto 0) := x"0000";
        reset_r3 : std_logic_vector(15 downto 0) := x"0000"
    );
    port (
        clk          : in  std_logic;
        reset        : in  std_logic;
        write_enable : in  std_logic;
        write_addr   : in  std_logic_vector(2 downto 0);
        write_data   : in  std_logic_vector(15 downto 0);
        read_addr_a  : in  std_logic_vector(2 downto 0);
        read_addr_b  : in  std_logic_vector(2 downto 0);
        read_data_a  : out std_logic_vector(15 downto 0);
        read_data_b  : out std_logic_vector(15 downto 0)
    );
end entity;

architecture rtl of regfile is
    type register_bank is array (0 to 7) of std_logic_vector(15 downto 0);
    signal regs : register_bank;
begin
    read_data_a <= regs(to_integer(unsigned(read_addr_a)));
    read_data_b <= regs(to_integer(unsigned(read_addr_b)));

    process (clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                regs <= (1 => reset_r1, 2 => reset_r2, 3 => reset_r3,
                         others => x"0000");
            elsif write_enable = '1' then
                regs(to_integer(unsigned(write_addr))) <= write_data;
            end if;
        end if;
    end process;
end architecture;
