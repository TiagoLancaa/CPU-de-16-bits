library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity datapath is
    port (
        clk         : in  std_logic;
        reset       : in  std_logic;
        step        : in  std_logic;
        pc_out      : out std_logic_vector(15 downto 0);
        instr_out   : out std_logic_vector(15 downto 0);
        result_out  : out std_logic_vector(15 downto 0)
    );
end entity;

architecture rtl of datapath is
    subtype word is std_logic_vector(15 downto 0);
    type register_bank is array (0 to 7) of word;
    constant initial_regs : register_bank :=
        (x"0000", x"0007", x"FFFD", x"0009", others => x"0000");

    function encode_r(opcode, ri, rj, rk : natural) return word is
    begin
        return std_logic_vector(to_unsigned(opcode, 4) & to_unsigned(ri, 3) &
                                to_unsigned(rj, 3) & to_unsigned(rk, 3) & "000");
    end function;

    type instruction_memory is array (natural range <>) of word;
    constant rom : instruction_memory := (
        encode_r(0, 4, 1, 2), -- ADD R4, R1, R2: 7 + (-3) = 4
        encode_r(1, 5, 4, 3), -- SUB R5, R4, R3: 4 - 9 = -5
        encode_r(2, 6, 5, 3), -- AND R6, R5, R3: FFFB and 0009 = 0009
        encode_r(3, 7, 6, 4), -- OR  R7, R6, R4: 0009 or 0004 = 000D
        encode_r(4, 0, 2, 7), -- SLT R0, R2, R7: -3 < 13 = 1
        encode_r(4, 1, 7, 2), -- SLT R1, R7, R2: 13 < -3 = 0
        encode_r(0, 3, 0, 1), -- ADD R3, R0, R1: 1 + 0 = 1
        x"F000"               -- Fim da demonstração
    );

    signal regs : register_bank;
    signal pc : natural range rom'low to rom'high;
    signal instr, a, b, result : word;
    signal ula_ctl : std_logic_vector(2 downto 0);
    signal write_enable : std_logic;
begin
    instr <= rom(pc);
    a <= regs(to_integer(unsigned(instr(8 downto 6))));
    b <= regs(to_integer(unsigned(instr(5 downto 3))));

    with instr(15 downto 12) select
        ula_ctl <= "010" when "0000", -- ADD
                   "100" when "0001", -- SUB
                   "000" when "0010", -- AND
                   "001" when "0011", -- OR
                   "110" when "0100", -- SLT
                   "011" when others;

    write_enable <= '0' when ula_ctl = "011" else '1';

    alu : entity work.ULA
        port map (A => a, B => b, ULACtl => ula_ctl, R => result,
                  Zero => open, Overflow => open, Cout => open);

    process (clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                pc <= 0;
                regs <= initial_regs;
            elsif step = '1' and pc < rom'high then
                if write_enable = '1' then
                    regs(to_integer(unsigned(instr(11 downto 9)))) <= result;
                end if;
                pc <= pc + 1;
            end if;
        end if;
    end process;

    pc_out <= std_logic_vector(to_unsigned(pc, pc_out'length));
    instr_out <= instr;
    result_out <= result;
end architecture;
