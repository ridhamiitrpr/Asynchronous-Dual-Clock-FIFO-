# Asynchronous FIFO — Verilog RTL

A **dual-clock asynchronous FIFO** implemented in Verilog for reliable data transfer between independent clock domains.

The design uses **Gray-coded read/write pointers**, **two-stage clock-domain synchronizers**, and dedicated **full/empty detection logic**. The RTL is verified using a self-checking testbench containing directed tests, stress tests, randomized asynchronous traffic, and reset-during-active-traffic testing.

---

## Overview

A FIFO (First-In-First-Out) stores data in the order it is written and returns it in the same order.

Unlike a synchronous FIFO, an asynchronous FIFO operates with **independent write and read clocks**. This makes it useful when data must cross between logic blocks operating at different clock frequencies.

## Key Design Features

- Parameterizable data width and FIFO depth
- Independent read and write clock domains
- Gray-code read/write pointers
- Two-stage synchronizers for CDC
- Full flag generation
- Empty flag generation
- Self-checking testbench
- GTKWave-based waveform verification

### Configuration

| Parameter          |      Value |
| ------------------ | ---------: |
| Data width         |     8 bits |
| Address width      |     4 bits |
| FIFO depth         | 16 entries |
| Pointer width      |     5 bits |
| Write clock period |      20 ns |
| Read clock period  |      34 ns |

The write interface is **synchronous to `wclk`**, while the read side uses **asynchronous read behavior**.

---

## Design Architecture

The FIFO is divided into independent write and read domains.

![Architecture](<Architecture.gif>)



### Clock-Domain Crossing

The read pointer is converted to Gray code and synchronized into the write clock domain.

Similarly, the write pointer is converted to Gray code and synchronized into the read clock domain.

```text
Write Domain                         Read Domain

   wptr ── Gray ──► 2-FF Sync ──►   Empty Detection
                                     
   Full Detection ◄── Gray ◄── 2-FF Sync ◄──   rptr
                  

```

Gray coding is used because only one bit changes between consecutive pointer values, making the pointer suitable for clock-domain crossing through synchronizer stages.

---

## Full and Empty Detection

The FIFO uses an additional pointer bit beyond the memory address bits.

For:

```text
ADDRSIZE = 4
```

the FIFO contains:

```text
2^4 = 16 entries
```

and the pointers are 5 bits wide.

The additional bit allows the design to distinguish between:

* A pointer reaching the same location after a complete wraparound
* A genuinely empty FIFO
* A genuinely full FIFO

### Empty

The FIFO is empty when the current read pointer reaches the synchronized write pointer.

```text
rempty = 1
```

Further reads are rejected while the FIFO remains empty.

### Full

The FIFO is full when the write pointer reaches the appropriate wrapped position relative to the synchronized read pointer.

```text
wfull = 1
```

Further writes are rejected while the FIFO remains full.

---

## RTL Modules

The `rtl/` directory contains the complete FIFO implementation.

| File            | Function                                    |
| --------------- | ------------------------------------------- |
| `top.v`         | Top-level FIFO integration                  |
| `fifo_memory.v` | FIFO storage memory                         |
| `wptr_full.v`   | Write pointer and full detection            |
| `rptr_empty.v`  | Read pointer and empty detection            |
| `sync_r2w.v`    | Synchronizes read pointer into write domain |
| `sync_w2r.v`    | Synchronizes write pointer into read domain |

The modular structure separates **memory, pointer generation, flag generation, and CDC synchronization**, making the design easier to understand and debug.

---

## Verification

The FIFO is verified using a **self-checking Verilog testbench**.

A reference FIFO model is maintained inside the testbench. Whenever a read is accepted, the expected value from the reference model is compared against the actual FIFO output.

The testbench also tracks:

* Accepted writes
* Accepted reads
* Rejected writes due to `wfull`
* Rejected reads due to `rempty`
* FIFO model occupancy
* Data mismatches

An error is reported whenever the DUT output differs from the reference model.

### Test Cases

| Test                                   | Verification Objective                                       |
| -------------------------------------- | ------------------------------------------------------------ |
| **1. Reset**                           | Verify initial FIFO state and reset behavior                 |
| **2. Basic Operation**                 | Verify normal FIFO ordering and data integrity               |
| **3. Full + Overflow**                 | Fill the FIFO and verify that additional writes are rejected |
| **4. Empty + Underflow**               | Empty the FIFO and verify that additional reads are rejected |
| **5. Write Faster than Read**          | Stress the FIFO when writes occur faster than reads          |
| **6. Read Faster than Write**          | Stress the FIFO when reads occur faster than writes          |
| **7. Simultaneous Read/Write**         | Exercise both clock domains concurrently                     |
| **8. Randomized Asynchronous Traffic** | Verify behavior under pseudo-random read/write activity      |
| **9. Reset During Active Traffic**     | Verify that reset correctly flushes active FIFO contents     |

The randomized test uses fixed seeds, making the simulation **reproducible**.

---

## Waveform Verification

Waveforms were inspected using **GTKWave** to verify the interaction between the two clock domains.

The waveform captures focus on signals such as:

* `wclk`, `rclk`
* `winc`, `rinc`
* `wdata`, `rdata`
* `wfull`, `rempty`
* Gray-coded write/read pointers
* Synchronized Gray-coded pointers
* Reset behavior

The complete waveform set is organized by test case in the [`Waveforms/`](Waveforms/) directory.

### Example: FIFO Basic Operation

![Test 2 Waveform](<Waveforms/Test 2(Basic Operation)/Image 02.png>)



### Example: Full and Overflow Protection

![Test 3 Waveform(1)](<Waveforms/Test 3( Full + Overflow)/Image 03.png>)

![Test 3 Waveform(2)](<Waveforms/Test 3( Full + Overflow)/Image 04.png>)


The waveform captures are intended to complement the self-checking console output: the console verifies the transactions automatically, while the waveforms provide visual evidence of the underlying RTL behavior.

---

## Reset and Design Assumptions

The following assumptions apply to this implementation:

* The write and read clocks are independent clock domains.
* The FIFO depth is assumed to be a **power of two**, as required by the Gray-code pointer architecture.
* Reset is **synchronous** to the respective clocked logic.
* The required reset timing conditions are assumed to be satisfied externally.
* Reset during active traffic is functionally verified in simulation.
* This project demonstrates **functional RTL verification**; synthesis, physical implementation, and timing closure are outside the scope of the project.

---

## Simulation

The project was simulated using:

* **Icarus Verilog** — RTL compilation and simulation
* **GTKWave** — waveform analysis

### Compile

From the repository root:

```bash
iverilog -I rtl -o sim tb/tb.v rtl/*.v
```


### Run

```bash
vvp sim
```

The complete console output from the verification run is available in:

```text
Simulation/Console_Output.txt
```

### View Waveforms

```bash
gtkwave async_fifo1_tb.vcd
```

---

## Repository Structure

```text
Asynchronous-FIFO-Verilog/
│
├── rtl/
│   ├── top.v
│   ├── fifo_memory.v
│   ├── wptr_full.v
│   ├── rptr_empty.v
│   ├── sync_r2w.v
│   └── sync_w2r.v
│
├── tb/
│   └── tb.v
│
├── Waveforms/
│   ├── Test 1 - Reset/
│   ├── Test 2 - Basic Operation/
│   ├── Test 3 - Full + Overflow/
│   ├── Test 4 - Empty + Underflow/
│   ├── Test 5 - Write Faster than Read/
│   ├── Test 6 - Read Faster than Write/
│   ├── Test 7 - Simultaneous Read and Write/
│   ├── Test 8 - Randomized Traffic/
│   └── Test 9 - Reset During Active Traffic/
│
├── Simulation/
│   └── Console_Output.txt
│   └── Console_Output_Summary.png
│
└── README.md
└── Architecture.gif
```

---

## Verification Result

All nine verification scenarios are designed to complete without data mismatches or FIFO-model inconsistencies.

![Verification Summary](<Simulation/Console_Output_Summary.png>)



The repository contains both the **RTL implementation** and the **verification evidence** needed to inspect how the FIFO behaves under normal, boundary, asynchronous, randomized, and reset conditions.

---

## Author

**Ridham Garg**
2024epb1276@iitrpr.ac.in
Indian Institute of Technology Ropar
