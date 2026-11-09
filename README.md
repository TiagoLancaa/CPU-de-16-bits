# CPU de 16 bits - Arquitetura RISC (Projeto Final)

Repositório destinado ao desenvolvimento do Projeto Final da disciplina de Arquitetura de Sistemas Computacionais. O projeto consiste no desenvolvimento e simulação de uma CPU completa, implementada em VHDL, capaz de executar um conjunto específico de instruções RISC. O hardware foi projetado e testado para ser embarcado em uma placa FPGA (Família Altera/Intel DE2-115).

## Equipe
* Ayrton Senna Barros Carvalho - 13271242
* Eloise dos Santos Ruiz - 24002341
* Pedro Henrique Coan Zin - 24026585
* Tiago Aureliano Lança Rodriguez - 25004196

---

## Progresso Atual (Parte 1)

O projeto está em sua fase inicial de planejamento e integração dos componentes básicos construídos durante as aulas práticas.

O foco da parte 1 é **adaptar os laboratórios 04 e 05** para atuarem como os alicerces da CPU de 16 bits:
* **ULA Refatorada:** O código VHDL da Unidade Lógica e Aritmética (Laboratório 04) vai ser limpo e revisado para garantir a funcionalidade em palavras de 16 bits e a geração correta das saídas (incluindo flags como *Zero* e *Overflow*).
* **Datapath (Início):** O esqueleto inicial do Caminho de Dados (Laboratório 05) está sendo modificado. O Banco de Registradores, o PC (Program Counter) e as instâncias das memórias estão sendo ajustados para larguras de 16 bits e endereçamentos de 3 bits, conforme exigido pela especificação das instruções RISC do projeto final.

---

## To-Do List (Próximas Tarefas)

A equipe possui um cronograma de desenvolvimento focado em finalizar a integração até o dia 23 de novembro.

### Parte 2: Expansão do Caminho de Dados
* [ ] Ajustar o Banco de Registradores (endereços de 3 bits, dados de 16 bits).
* [ ] Implementar e conectar a **Memória de Dados** (`LD` e `ST`).
* [ ] Adicionar o **Extensor de Sinal** para os operandos imediatos (de 6 para 16 bits).
* [ ] Inserir os multiplexadores e o somador para o cálculo de desvio (`BEQ` e `BNE`).

### Parte 3: Unidade de Controle
* [ ] Projetar o Diagrama de Estados e a Tabela de Transições.
* [ ] Desenvolver a **Unidade de Controle** em VHDL (decodificando os Opcodes de 4 bits).
* [ ] Conectar os sinais de controle gerados ao Datapath.

### Parte 4 (Final): Testes e FPGA
* [ ] Criar o arquivo `.mif` com os programas de teste.
* [ ] Implementar o circuito *debouncer* para o botão de *clock*.
* [ ] Integrar a CPU no módulo Top-Level para a placa DE2-115 (mapeando a multiplexação SW17, visores HEX e LEDs).
* [ ] Redigir a Especificação da Arquitetura (PDF Final).

---

## Uso de Inteligência Artificial
Durante a elaboração deste projeto, ferramentas de IA foram utilizadas para:
* **Planejamento de Cronograma:** Estruturação das metas semanais para a divisão do trabalho entre os quatro membros.
* **Documentação:** Geração do esqueleto inicial deste README.
