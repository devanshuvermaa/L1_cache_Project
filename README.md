# L1 Write-Back Cache Controller (SystemVerilog)

A cycle-accurate RTL implementation of an L1 Cache Controller designed to bridge the speed gap between a high-frequency CPU and high-latency Main Memory. 

**Status:** `Phase 2: RTL Implementation Complete` | `Phase 3: Verification In Progress`

---

## 🏗️ Phase 1: Architecture & Interface Design
Before writing logic, the boundaries of the Cache Controller were defined to handle two drastically different interfaces:
* **CPU Interface:** Fast, 32-bit word requests. Strict requirement to stall the CPU (`cpu_stall`) during cache misses.
* **Memory Interface:** Slow, 128-bit (16-byte) burst transfers to maximize bus efficiency.

## 🛠️ Phase 2: RTL Implementation
The cache is divided into three parallel hardware units:

1. **Data Array (`src/data_array.sv`)**
   * 64-depth SRAM storing 128-bit blocks.
   * Synchronous writes, asynchronous reads for speculative execution.
2. **Tag Array (`src/tag_array.sv`)**
   * Stores 22-bit address fingerprints.
   * Implements a **Dirty Bit** policy to defer memory writes until eviction, preventing memory bus bottlenecking.
3. **Finite State Machine (`src/cache_top.sv`)**
   * A 4-state controller (`IDLE`, `COMPARE`, `WRITE_BACK`, `ALLOCATE`).
   * Evaluates hit/miss asynchronously and orchestrates the CPU stall and Main Memory fetch cycles.

## 🧪 Phase 3: Verification & Waveforms (In Progress)
*(To be completed: I will simulate the FSM using Icarus Verilog and analyze the electrical waveforms in GTKWave. Screenshots of the cycle-accurate hit/miss logic will be documented here.)*

---

## 💻 How to Run the Simulation Locally
*(Instructions for compiling the testbench with Icarus Verilog will go here once Phase 3 is complete)*