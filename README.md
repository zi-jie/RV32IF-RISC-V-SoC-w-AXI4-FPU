# RV32IF RISC-V SoC w/ AXI4, FPU
Course Project: Advanced VLSI System Design (AVSD) 

Keywords: RTL / SystemVerilog / RISC-V / SoC / CDC / AXI4 / Assembly

Project Description

- Architected a 5-stage RV32IF pipelined CPU supporting 66 instructions, including Integer and Floating-Point Unit (FPU) operations.

- Designed and integrated a Multi-Master/Slave AXI4 interconnect connecting DMA, DRAM controller, and Watchdog Timer, with Asynchronous FIFOs to resolve clock domain crossing (CDC) issues across CPU, AXI, and DRAM clock domains.

- Executed the complete RTL-to-GDSII physical design flow using Cadence Innovus, validating design correctness and robustness through JasperGold AXI4 protocol checks, Spyglass CDC analysis, and achieving DRC/LVS-clean sign-off.
