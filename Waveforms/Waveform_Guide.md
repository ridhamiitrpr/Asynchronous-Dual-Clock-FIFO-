# Waveform Simulation Guide

This directory contains the **GTKWave waveform captures** used to verify the Asynchronous FIFO RTL. The screenshots are organized according to the verification tests performed by the self-checking testbench.

---

## 📋 Signal Glossary

| Signal Group       | Variable                  | Purpose                                             |
| ------------------ | ------------------------- | --------------------------------------------------- |
| **Global Control** | `rst`                     | Synchronous reset for the FIFO                      |
| **Write Domain**   | `wclk`                    | Write-side clock (20 ns period)                     |
|                    | `winc`                    | Write request                                       |
|                    | `wdata[7:0]`              | Data presented to the FIFO                          |
|                    | `wfull`                   | Indicates that the FIFO cannot accept another write |
| **Read Domain**    | `rclk`                    | Read-side clock (34 ns period)                      |
|                    | `rinc`                    | Read request                                        |
|                    | `rdata[7:0]`              | Data read from the FIFO                             |
|                    | `rempty`                  | Indicates that the FIFO has no data available       |
| **Clock Crossing** | `wptr[4:0]` / `rptr[4:0]` | Gray-coded write/read pointers                      |
|                    | `wq2_rptr[4:0]`           | Read pointer synchronized into the write domain     |
|                    | `rq2_wptr[4:0]`           | Write pointer synchronized into the read domain     |

---

## 🧪 Verification Tests

The waveforms cover the following progression:

| Test                                   | Verification Objective                                            |
| -------------------------------------- | ----------------------------------------------------------------- |
| **1. Reset**                           | Verify the initial FIFO state and reset behavior                  |
| **2. Basic Operation**                 | Verify normal write, read, and FIFO ordering                      |
| **3. Full + Overflow**                 | Fill the FIFO and verify that additional writes are blocked       |
| **4. Empty + Underflow**               | Empty the FIFO and verify that additional reads are blocked       |
| **5. Write Faster Than Read**          | Verify correct operation when the write side produces data faster |
| **6. Read Faster Than Write**          | Verify correct operation when the read side consumes data faster  |
| **7. Simultaneous Read/Write**         | Exercise both clock domains concurrently                          |
| **8. Randomized Asynchronous Traffic** | Stress the FIFO using pseudo-random read/write activity           |
| **9. Reset During Active Traffic**     | Verify reset behavior while FIFO traffic is in progress           |

---

## 🔍 What to Look for in the Waveforms

The screenshots are intended to make the following relationships visible.

### Write Operation

`winc` → `wfull` check → `wdata` accepted → write pointer advances

### Read Operation

`rinc` → `rempty` check → `rdata` produced → read pointer advances

### FIFO Boundaries

* When the FIFO becomes **full**, `wfull` asserts and further writes are rejected.
* When the FIFO becomes **empty**, `rempty` asserts and further reads are rejected.
* Data read from the FIFO must remain in the same order in which it was successfully written.

### Clock-Domain Crossing

The Gray-coded pointers are transferred between the two clock domains through the synchronizer stages:

```text
Write Pointer → Synchronizer → Read Domain
Read Pointer  → Synchronizer → Write Domain
```

The synchronized pointer signals in the waveforms provide visibility into this process.

---

## 📸 Waveform Organization

Since some tests run for considerably longer than others, a single screenshot is not always sufficient. The 20 captures are therefore divided across the tests, with multiple screenshots used where necessary to keep the important transitions readable.
