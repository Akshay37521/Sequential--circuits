# SISO Shift Register Verification (SystemVerilog)

## Objective
To verify the functionality of a Serial-In Serial-Out (SISO) shift register using a structured SystemVerilog testbench.

---

## DUT Description
- 1-bit serial input  
- 1-bit serial output  
- Data shifts on each clock cycle  
- Synchronous reset  

---

## Verification Approach
The verification environment includes:

- Generator → constrained random stimulus  
- Driver → clocking block-based signal driving  
- Monitor → captures DUT activity  
- Scoreboard → validates delayed output behavior  

---

## Key Concepts Used
- Program block (avoids race conditions)  
- Clocking block (ensures proper timing)  
- Constrained random verification  
- Queue-based checking mechanism  

---

## Simulation Setup
- Platform: EDA Playground  
- Simulator: Siemens QuestaSim 2020.1  
- Language: SystemVerilog  

---

## Results
- Total Test Cases: 200  
- Passed: 200  
- Failed: 0  

---

## Detailed Report
For complete details including waveform analysis and screenshots, refer to:

👉 `report.pdf`

---

## Folder Structure
