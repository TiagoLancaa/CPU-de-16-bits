library ieee;
use ieee.std_logic_1164.all;

entity datapath_board is
    port (
        CLOCK_50 : in std_logic;
        KEY      : in std_logic_vector(3 downto 0);
        HEX0, HEX1, HEX2, HEX3 : out std_logic_vector(6 downto 0);
        HEX4, HEX5, HEX6, HEX7 : out std_logic_vector(6 downto 0)
    );
end entity;

architecture rtl of datapath_board is
    -- Dez milissegundos de estabilidade com clock de 50 MHz.
    constant debounce_cycles : positive := 500_000;
    signal key_meta, key_sync : std_logic_vector(1 downto 0) := "11";
    signal reset : std_logic;
    signal step_level : std_logic := '1';
    signal step_pulse : std_logic := '0';
    signal stable_count : natural range 0 to debounce_cycles - 1 := 0;
    signal pc, result : std_logic_vector(15 downto 0);

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
    process (CLOCK_50)
    begin
        if rising_edge(CLOCK_50) then
            key_meta <= KEY(1 downto 0);
            key_sync <= key_meta;
            step_pulse <= '0';

            if key_sync(0) = step_level then
                stable_count <= 0;
            elsif stable_count = debounce_cycles - 1 then
                step_level <= key_sync(0);
                step_pulse <= not key_sync(0);
                stable_count <= 0;
            else
                stable_count <= stable_count + 1;
            end if;
        end if;
    end process;

    reset <= not key_sync(1);

    core : entity work.datapath
        port map (
            clk => CLOCK_50,
            reset => reset,
            step => step_pulse,
            pc_out => pc,
            instr_out => open,
            result_out => result
        );

    HEX0 <= to_7seg(pc(3 downto 0));
    HEX1 <= to_7seg(pc(7 downto 4));
    HEX2 <= to_7seg(pc(11 downto 8));
    HEX3 <= to_7seg(pc(15 downto 12));
    HEX4 <= to_7seg(result(3 downto 0));
    HEX5 <= to_7seg(result(7 downto 4));
    HEX6 <= to_7seg(result(11 downto 8));
    HEX7 <= to_7seg(result(15 downto 12));
end architecture;
