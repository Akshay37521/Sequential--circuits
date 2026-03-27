# SISO Shift Register Verification (SystemVerilog)

## Overview
Verification of a 4-bit Serial-In Serial-Out (SISO) shift register using SystemVerilog with focus on timing correctness, synchronization, and assertion-based validation.

---

## DUT Description
- 4-bit shift register  
- Serial input and serial output  
- Data shifts on each positive clock edge  
- Synchronous reset  

---

## Verification Architecture
The testbench is built using modular components:

- **Generator** → constrained random stimulus  
- **Driver** → drives signals using clocking block  
- **Monitor** → samples DUT signals using separate clocking block  
- **Scoreboard** → checks expected vs actual output  

---

## Key Techniques
- Clocking blocks for proper timing separation (driver vs monitor)  
- Constrained random verification  
- Scoreboard-based checking with reset handling  
- SystemVerilog Assertions (SVA):
  - Reset behavior
  - Shift correctness (4-cycle delay)
  - Stability checks  

---

## Timing Fix
Initial implementation had race conditions due to improper sampling.

**Fix:**
- Separate clocking blocks for driver and monitor  
- Proper alignment of sampling and DUT update  

---

## Simulation Setup
- Platform: EDA Playground / Local Simulation  
- Simulator: Siemens QuestaSim  
- Language: SystemVerilog  

---

## Results
- Total Test Cases: 200  
- Passed: 200  
- Failed: 0  
- All assertions passed  

---

## Project Structure
