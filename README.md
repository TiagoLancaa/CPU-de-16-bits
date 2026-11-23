# CPU de 16 bits - Arquitetura RISC (Projeto Final)

Repositório oficial do Projeto Final da disciplina de **Arquitetura de Sistemas Computacionais** (Engenharia de Computação — PUC-Campinas, 2026). O projeto consiste na especificação, descrição em hardware (VHDL), simulação e síntese física de uma CPU multiciclo completa de 16 bits embarcada na placa FPGA **Altera/Intel DE2-115**.

## Equipe
* **Ayrton Senna Barros Carvalho** - 13271242
* **Eloise dos Santos Ruiz** — RA: 24002341
* **Pedro Henrique Coan Zin** — RA: 24026585
* **Tiago Aureliano Lança Rodriguez** — RA: 25004196

---

## Descrição Geral do Projeto
A arquitetura implementada processa palavras de **16 bits** e opera sob uma máquina de estados finitos (FSM) multiciclo capaz de buscar, decodificar e executar um conjunto de **11 instruções RISC**. O sistema integra:
* **Unidade Lógica e Aritmética (ULA):** Operações lógicas, aritméticas e geração das flags `Zero`, `Overflow` e `Cout`.
* **Caminho de Dados (*Datapath*):** Banco de 8 registradores de 16 bits, Program Counter (PC), Extensores de Sinal (6 e 12 bits), Multiplexadores, Memória de Instruções (ROM inicializada via `.mif`) e Memória de Dados (RAM/RDM).
* **Unidade de Controle:** FSM responsável por decodificar o *Opcode* de 4 bits e coordenar todos os sinais de controle do *Datapath* a cada ciclo.
* **Interface FPGA (DE2-115):** Módulo *Top-Level* (`cpu.vhd`) com circuito *debouncer* síncrono para passo manual de *clock* e mapeamento completo nos periféricos da placa.

---

## Especificações da Arquitetura

### Banco de Registradores
* **Quantidade:** 8 registradores de propósito geral (`R0` a `R7`).
* **Largura de Endereçamento:** 3 bits (`Ri`, `Rj`, `Rk`).
* **Tamanho da Palavra:** 16 bits.

### Formatos das Instruções (16 bits)
| Formato | Bits `[15..12]` | Bits `[11..9]` | Bits `[8..6]` | Bits `[5..3]` | Bits `[2..0]` |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Tipo R** | `Opcode` (4b) | `Ri` (3b) | `Rj` (3b) | `Rk` (3b) | Não usado (3b) |
| **Tipo I** | `Opcode` (4b) | `Ri` (3b) | `Rj` (3b) | `Imediato` (6b) — bits `[5..0]` | ← |
| **Tipo J** | `Opcode` (4b) | `Endereço` (12b) — bits `[11..0]` | ← | ← | ← |

### Conjunto de Instruções Suportadas (ISA)
| Instrução | Formato | Operação | Descrição |
| :--- | :---: | :--- | :--- |
| `ADD Ri, Rj, Rk` | Tipo R | `Ri <- Rj + Rk` | Soma entre dois registradores |
| `SUB Ri, Rj, Rk` | Tipo R | `Ri <- Rj - Rk` | Subtração entre dois registradores |
| `AND Ri, Rj, Rk` | Tipo R | `Ri <- Rj && Rk` | Operação lógica AND bit a bit |
| `OR Ri, Rj, Rk` | Tipo R | `Ri <- Rj \|\| Rk` | Operação lógica OR bit a bit |
| `SLT Ri, Rj, Rk` | Tipo R | `Ri <- 1 se Rj < Rk; senão 0` | *Set on Less Than* (com sinal) |
| `ADDI Ri, Rj, imm` | Tipo I | `Ri <- Rj + imediato` | Soma com constante imediata estendida |
| `LD Ri, Rj, imm` | Tipo I | `Ri <- Memoria[Rj + imediato]` | Leitura da memória de dados (*Load*) |
| `ST Ri, Rj, imm` | Tipo I | `Memoria[Rj + imediato] <- Ri` | Escrita na memória de dados (*Store*) |
| `BEQ Ri, Rj, imm` | Tipo I | `Se Ri == Rj: PC <- (PC + 1) + imm` | Desvio condicional se igual |
| `BNE Ri, Rj, imm` | Tipo I | `Se Ri != Rj: PC <- (PC + 1) + imm` | Desvio condicional se diferente |
| `JMP end` | Tipo J | `PC <- end` | Salto incondicional |

---

## Estrutura do Repositório

```text
├── README.md                       # Documentação geral do projeto
├── .gitignore                      # Arquivos temporários do Quartus Prime ignorados
├── docs/
│   └── especificacao_projeto.pdf   # Relatório técnico completo com diagramas e tabelas
├── src/
│   ├── cpu.vhd                     # Entidade Top-Level (interface com a placa DE2-115)
│   ├── control_unit.vhd            # Unidade de Controle (Máquina de Estados Finitos)
│   ├── datapath.vhd                # Caminho de Dados completo de 16 bits
│   ├── ula.vhd                     # Unidade Lógica e Aritmética de 16 bits
│   ├── regfile.vhd                 # Banco de Registradores (8x16 bits)
│   ├── instruction_memory.vhd      # Memória de Instruções (ROM inicializada via .mif)
│   ├── data_memory.vhd             # Memória de Dados (RAM para LD/ST)
│   ├── operand_extender.vhd        # Extensores de sinal (6->16 bits e 12->16 bits)
│   ├── mux2_16.vhd                 # Multiplexador 2:1 de 16 bits
│   ├── mux4_16.vhd                 # Multiplexador 4:1 de 16 bits
│   ├── debouncer.vhd               # Filtro digital para o botão de clock manual
│   ├── hex_to_7seg.vhd             # Decodificador hexadecimal para displays de 7 segmentos
│   └── ini_mem.mif                 # Programa em código de máquina para inicialização da ROM
├── sim/
│   ├── ula_tb.vhd                  # Testbench unitário da ULA
│   ├── regfile_tb.vhd              # Testbench unitário do Banco de Registradores
│   └── cpu_tb.vhd                  # Testbench global da CPU completa
└── quartus/
    ├── cpu.qpf                     # Arquivo de projeto do Intel Quartus Prime
    └── cpu.qsf                     # Mapeamento de pinos da FPGA DE2-115