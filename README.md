**Custom 8086-Compatible SoC with Clock Domain Crossing and Auto-Clock Gating**
Overview
This repository contains the complete RTL implementation of a custom 16-bit CPU integrated into a multi-frequency System-on-Chip (SoC). The full design is available in the cpu_with_clkgating.txt file. The architecture focuses on high-performance data routing, dynamic power management, and robust metastability prevention across varying clock domains.   


Key Features & Architecture
CPU Core & Memory Management
Custom 8086 Core: The CPU is partitioned into a dedicated Execution Unit (EU) with 4-phase handshake latches and a Bus Interface Unit (BIU) acting as a unified fetch manager.   


16-bit ALU: Supports core arithmetic and logic operations including ADD, SUB, AND, OR, and PASS.   

L1 Caches & TLB: Features separate instruction and data Translation Lookaside Buffers (TLBs) with 8 entries each, backed by direct-mapped L1 caches utilizing 128-bit burst fills.   


Instruction Fetching: Incorporates a 6-depth prefetch queue and an Internal Instruction Memory (ITCM) for deterministic execution.   


Advanced Bus Interconnect
4x6 Wishbone Matrix: A high-speed Wishbone interconnect matrix handles parallel traffic between 4 master devices and 6 slave endpoints.   


Hardware Address Decoding: Routes traffic based on top-nibble address decoding.   


Security Trapping: Hardwired to flag errors and trap illegal access attempts to restricted memory ranges (0x400-0x67F).   


Dual-Clock Main Memory: Integrates an asynchronous dual-port main memory designed to handle 150 MHz writes and 100 MHz reads safely.   


Clock Domain Crossing (CDC)
Multi-Frequency SoC: Safely bridges a 200 MHz CPU domain, 150 MHz DMA/IP domains, and a 100 MHz memory domain.   


Wishbone CDC Bridges: Wraps cross-domain communication in dedicated command and response mailboxes to prevent bus lockups.   


Asynchronous FIFOs: Utilizes custom Async FIFOs equipped with Gray-code pointers and 2-stage flip-flop synchronizers to eliminate metastability during fast-to-slow domain handoffs.   


Low-Power Design & Control IPs
Auto-Clock Gating: Utilizes an Integrated Clock Gating (ICG) cell with a negative-level sensitive latch to ensure glitch-free clock gating.   

Smart IP Controllers: Dual-port IP controllers dynamically gate their own 150 MHz clocks, waking up only upon CPU triggers, active slave access, or when completing an active state.   


System Controller (SYSCON): A centralized PMU/SYSCON allows software to trigger macro-level clock enables and isolated soft resets for individual IP blocks.   


Programmable Interrupt Controller (PIC): Captures multi-source IP triggers and routes synchronized edge-triggered interrupts to the CPU.   
