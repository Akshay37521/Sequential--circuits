# D Flip-Flop Verification (SystemVerilog)

## Overview
This project verifies a synchronous D Flip-Flop using a SystemVerilog-based testbench.

## Verification Architecture
- Generator → Creates stimulus
- Driver → Drives DUT inputs
- Monitor → Samples DUT behavior
- Scoreboard → Compares expected vs actual output

## Key Issue Encountered
Initial implementation resulted in **52 failing test cases**.

### Root Cause
The scoreboard compared output with the **current input D**, while a D Flip-Flop is a **sequential circuit** where output depends on the **previous cycle input**.

### Fix
- Implemented expected value tracking using previous cycle input
- Corrected timing alignment using clocking block
- Ensured proper sampling in monitor

## Result
- Before Fix: 52 failures
- After Fix: 200 / 200 test cases passed

## Tools Used
- Platform: EDA Playground
- Simulator: Siemens QuestaSim 2020.1
- Language: SystemVerilog

## Detailed Report
See full documentation here: [report.pdf](./report.pdf)
