library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity instruction_memory is
    port (
        address  : in  std_logic_vector(15 downto 0);
        data_out : out std_logic_vector(15 downto 0)
    );
end entity;

architecture rtl of instruction_memory is

    type rom_type is array (0 to 255) of std_logic_vector(15 downto 0);

    -- Le o arquivo .mif diretamente para inicializacao (funciona no ModelSim e Quartus)
    impure function init_rom_from_mif(mif_file_name : in string) return rom_type is
        file mif_file       : text open read_mode is mif_file_name;
        variable mif_line   : line;
        variable temp_rom   : rom_type := (others => (others => '0'));
        variable addr_int   : integer;
        variable data_word  : std_logic_vector(15 downto 0);
        variable char_buf   : character;
        variable hex_val    : integer;
        variable read_ok    : boolean;
        variable in_content : boolean := false;

        function hex_char_to_int(c : character) return integer is
        begin
            case c is
                when '0' to '9' => return character'pos(c) - character'pos('0');
                when 'A' to 'F' => return character'pos(c) - character'pos('A') + 10;
                when 'a' to 'f' => return character'pos(c) - character'pos('a') + 10;
                when others     => return -1;
            end case;
        end function;

    begin
        while not endfile(mif_file) loop
            readline(mif_file, mif_line);
            if mif_line'length >= 5 then
                if mif_line.all(1 to 5) = "BEGIN" then
                    in_content := true;
                    next;
                end if;
            end if;

            if in_content then
                addr_int := 0;
                read_ok  := false;
                while mif_line'length > 0 loop
                    read(mif_line, char_buf);
                    if char_buf = '[' or char_buf = 'E' or char_buf = '-' then
                        read_ok := false;
                        exit;
                    elsif char_buf = ':' then
                        read_ok := true;
                        exit;
                    else
                        hex_val := hex_char_to_int(char_buf);
                        if hex_val >= 0 then
                            addr_int := addr_int * 16 + hex_val;
                        end if;
                    end if;
                end loop;

                if read_ok and addr_int >= 0 and addr_int < 256 then
                    data_word := (others => '0');
                    while mif_line'length > 0 loop
                        read(mif_line, char_buf);
                        exit when char_buf = ';';
                        hex_val := hex_char_to_int(char_buf);
                        if hex_val >= 0 then
                            data_word := data_word(11 downto 0) & std_logic_vector(to_unsigned(hex_val, 4));
                        end if;
                    end loop;
                    temp_rom(addr_int) := data_word;
                end if;
            end if;
        end loop;
        return temp_rom;
    end function;

    -- IMPORTANTE: Ajuste o caminho abaixo conforme o local do seu arquivo .qpf:
    -- Se o .qpf esta na raiz do projeto: "src/ini_mem.mif"
    -- Se o .qpf esta dentro de quartus/: "../src/ini_mem.mif" (ou copie ini_mem.mif para quartus/ e use "ini_mem.mif")
    signal rom : rom_type := init_rom_from_mif("src/ini_mem.mif");

    attribute ram_init_file : string;
    attribute ram_init_file of rom : signal is "src/ini_mem.mif";

begin

    data_out <= rom(to_integer(unsigned(address)))
                when unsigned(address) < 256
                else (others => '0');

end architecture;