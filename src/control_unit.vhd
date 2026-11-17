library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity control_unit is
    port (
        clk            : in  std_logic;
        reset          : in  std_logic;
        step           : in  std_logic;
        opcode         : in  std_logic_vector(3 downto 0);
        pc_write       : out std_logic;
        pc_write_cond  : out std_logic;
        branch_ne      : out std_logic;
        mem_read       : out std_logic;
        mem_write      : out std_logic;
        ir_write       : out std_logic;
        reg_write      : out std_logic;
        mem_to_reg     : out std_logic;
        reg_read_b_sel : out std_logic;
        alu_src_a      : out std_logic;
        alu_src_b      : out std_logic_vector(1 downto 0);
        alu_op         : out std_logic_vector(2 downto 0);
        pc_src         : out std_logic_vector(1 downto 0);
        state_leds     : out std_logic_vector(7 downto 0)
    );
end entity control_unit;

architecture behavioral of control_unit is

    type state_type is (
        FETCH,
        DECODE,
        EXEC_R,
        WB_R,
        EXEC_ADDI,
        WB_I,
        MEM_ADDR,
        MEM_READ,
        MEM_WB,
        MEM_WRITE,
        BRANCH_BEQ,
        BRANCH_BNE,
        JUMP
    );

    signal current_state, next_state : state_type;

begin

    process(clk, reset)
    begin
        if reset = '1' then
            current_state <= FETCH;
        elsif rising_edge(clk) then
            if step = '1' then
                current_state <= next_state;
            end if;
        end if;
    end process;

    process(current_state, opcode)
    begin
        next_state <= FETCH;

        case current_state is
            when FETCH =>
                next_state <= DECODE;

            when DECODE =>
                case opcode is
                    when "0000" | "0001" | "0010" | "0011" | "0100" =>
                        next_state <= EXEC_R;
                    when "0101" =>
                        next_state <= EXEC_ADDI;
                    when "0110" | "0111" =>
                        next_state <= MEM_ADDR;
                    when "1000" =>
                        next_state <= BRANCH_BEQ;
                    when "1001" =>
                        next_state <= BRANCH_BNE;
                    when "1010" =>
                        next_state <= JUMP;
                    when others =>
                        next_state <= FETCH;
                end case;

            when EXEC_R =>
                next_state <= WB_R;

            when WB_R =>
                next_state <= FETCH;

            when EXEC_ADDI =>
                next_state <= WB_I;

            when WB_I =>
                next_state <= FETCH;

            when MEM_ADDR =>
                if opcode = "0110" then
                    next_state <= MEM_READ;
                else
                    next_state <= MEM_WRITE;
                end if;

            when MEM_READ =>
                next_state <= MEM_WB;

            when MEM_WB =>
                next_state <= FETCH;

            when MEM_WRITE =>
                next_state <= FETCH;

            when BRANCH_BEQ =>
                next_state <= FETCH;

            when BRANCH_BNE =>
                next_state <= FETCH;

            when JUMP =>
                next_state <= FETCH;

            when others =>
                next_state <= FETCH;
        end case;
    end process;

    process(current_state, opcode)
    begin
        pc_write       <= '0';
        pc_write_cond  <= '0';
        branch_ne      <= '0';
        mem_read       <= '0';
        mem_write      <= '0';
        ir_write       <= '0';
        reg_write      <= '0';
        mem_to_reg     <= '0';
        reg_read_b_sel <= '0';
        alu_src_a      <= '0';
        alu_src_b      <= "00";
        alu_op         <= "010";
        pc_src         <= "00";
        state_leds     <= "00000000";

        if opcode = "0111" or opcode = "1000" or opcode = "1001" then
            reg_read_b_sel <= '1';
        end if;

        case current_state is
            when FETCH =>
                ir_write   <= '1';
                alu_src_a  <= '0';
                alu_src_b  <= "01";
                alu_op     <= "010";
                pc_write   <= '1';
                pc_src     <= "00";
                state_leds <= "00000001";

            when DECODE =>
                alu_src_a  <= '0';
                alu_src_b  <= "11";
                alu_op     <= "010";
                state_leds <= "00000010";

            when EXEC_R =>
                alu_src_a <= '1';
                alu_src_b <= "00";
                case opcode is
                    when "0000" =>
                        alu_op <= "010";
                    when "0001" =>
                        alu_op <= "100";
                    when "0010" =>
                        alu_op <= "000";
                    when "0011" =>
                        alu_op <= "001";
                    when "0100" =>
                        alu_op <= "110";
                    when others =>
                        alu_op <= "010";
                end case;
                state_leds <= "00000100";

            when WB_R =>
                reg_write  <= '1';
                mem_to_reg <= '0';
                state_leds <= "00001000";

            when EXEC_ADDI =>
                alu_src_a  <= '1';
                alu_src_b  <= "10";
                alu_op     <= "010";
                state_leds <= "00010000";

            when WB_I =>
                reg_write  <= '1';
                mem_to_reg <= '0';
                state_leds <= "00010001";

            when MEM_ADDR =>
                alu_src_a  <= '1';
                alu_src_b  <= "10";
                alu_op     <= "010";
                state_leds <= "00100000";

            when MEM_READ =>
                mem_read   <= '1';
                state_leds <= "00100001";

            when MEM_WB =>
                reg_write  <= '1';
                mem_to_reg <= '1';
                state_leds <= "00100010";

            when MEM_WRITE =>
                mem_write  <= '1';
                state_leds <= "00100100";

            when BRANCH_BEQ =>
                alu_src_a     <= '1';
                alu_src_b     <= "00";
                alu_op        <= "100";
                pc_write_cond <= '1';
                branch_ne     <= '0';
                pc_src        <= "01";
                state_leds    <= "01000000";

            when BRANCH_BNE =>
                alu_src_a     <= '1';
                alu_src_b     <= "00";
                alu_op        <= "100";
                pc_write_cond <= '1';
                branch_ne     <= '1';
                pc_src        <= "01";
                state_leds    <= "01000001";

            when JUMP =>
                pc_write   <= '1';
                pc_src     <= "10";
                state_leds <= "10000000";

            when others =>
                state_leds <= "00000000";
        end case;
    end process;

end architecture behavioral;
