# High-Throughput AES-128 Pipelined Hardware Accelerator on FPGA (NIST FIPS-197)

[![Verilog HDL](https://img.shields.io/badge/Language-Verilog%20HDL-blue.svg)](https://en.wikipedia.org/wiki/Verilog)
[![FPGA Target](https://img.shields.io/badge/Target-Xilinx%20Kintex--7-red.svg)](https://www.xilinx.com/products/silicon-devices/fpga/kintex-7.html)
[![Throughput](https://img.shields.io/badge/Throughput-26.7%20Gbps-brightgreen.svg)]()
[![Standard](https://img.shields.io/badge/Standard-NIST%20FIPS--197-orange.svg)](https://csrc.nist.gov/publications/detail/fips/197/final)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A high-performance, fully-pipelined hardware implementation of the **AES-128 (Advanced Encryption Standard)** encryption algorithm written in Verilog HDL. The design incorporates a **10-stage pipeline** architecture combined with **on-the-fly key expansion**, achieving ultra-high throughput and optimal hardware resource utilization on Xilinx Kintex-7 FPGAs.

* **Author:** Cao Minh Thuan (Student ID: `24521734`)
* **Class:** CE213.Q21.VMTN
* **Advisor:** Dr. Tran Thi Diem
* **Institution:** Faculty of Computer Engineering, University of Information Technology, VNU-HCM (UIT)

---

## 📑 Table of Contents
1. [Overview](#-overview)
2. [Key Architectural Highlights](#-key-architectural-highlights)
3. [Hardware Architecture](#-hardware-architecture)
   * [10-Stage Fully-Pipelined Datapath](#1-10-stage-fully-pipelined-datapath)
   * [Round Transformation Modules](#2-round-transformation-modules)
   * [On-the-Fly Key Schedule Engine](#3-on-the-fly-key-schedule-engine)
4. [Repository Structure](#-repository-structure)
5. [Simulation & Verification](#-simulation--verification)
   * [Quick CLI Simulation with Icarus Verilog](#1-quick-cli-simulation-with-icarus-verilog-recommended)
   * [Simulation with Mentor Graphics ModelSim](#2-simulation-with-mentor-graphics-modelsim)
   * [Simulation with Xilinx Vivado](#3-simulation-with-xilinx-vivado)
6. [Synthesis & FPGA Implementation Results](#-synthesis--fpga-implementation-results)
   * [Resource Utilization](#1-hardware-resource-utilization)
   * [Timing & Throughput Analysis](#2-timing--throughput-analysis)
   * [Power Consumption](#3-power-consumption-analysis)
   * [Comparison with State-of-the-Art Works](#4-comparison-with-state-of-the-art-works)
7. [References](#-references)
8. [License & Citation](#-license--citation)

---

## 🔍 Overview

The **Advanced Encryption Standard (AES)** is a widely adopted symmetric-key block cipher standardized by the National Institute of Standards and Technology (NIST) in **FIPS-197**. AES-128 encrypts a **128-bit Plaintext** block using a **128-bit Cipher Key** through **10 consecutive transformation rounds** to produce a **128-bit Ciphertext** block.

This project delivers an RTL-level hardware implementation optimized for wire-speed network encryption, data storage systems, and real-time cryptography where throughput and latency consistency are paramount.

---

## ⚡ Key Architectural Highlights

* **10-Stage Fully Pipelined Pipeline:** 
  * Accepts a new 128-bit plaintext block and 128-bit key at **every single clock cycle**.
  * After an initial 11-cycle latency (to fill the pipeline registers), the core outputs **one 128-bit ciphertext block per clock cycle**, delivering maximum possible throughput.
* **On-the-Fly Key Expansion (`KeyRound`):**
  * Round keys are dynamically derived in parallel with each data stage from the key of the previous round ($K_i$ from $K_{i-1}$).
  * Completely eliminates the overhead of precomputing and buffering all 11 round keys simultaneously in large register files.
  * Significantly reduces Flip-Flop count and balances propagation delays across stages.
* **Shared S-Box Architecture:**
  * The `KeyRound` module shares the non-linear Substitution Box LUT (`Sbox.v`) with the datapath `SubBytes` layer, avoiding any redundant hardware lookup tables.
* **NIST FIPS-197 Verified:**
  * 100% compliant with standard test vectors from NIST FIPS-197 documentation.

---

## 🏛 Hardware Architecture

### 1. 10-Stage Fully-Pipelined Datapath

```text
                  ┌────────────────────────────────────────────────────────┐
Plaintext [127:0] ┤ (XOR) ──>[Stage 0]──>[Round 1]──>[Stage 1]──> ... ──> ├─┐
      Key [127:0] ┤                                                        │ │
                  └────────────────────────────────────────────────────────┘ │
┌────────────────────────────────────────────────────────────────────────────┘
│
└──> ... ──>[Round 9]──>[Stage 9]──>[Round 10]──>[Ciphertext Reg] ──> Ciphertext [127:0]
```

* **Round 0 (Initial AddRoundKey):**  
  The input `Plaintext` is bitwise XORed directly with the initial `Key` and registered into `stage_data[0]`.

* **Rounds 1 through 9 (`AESround`):**  
  Each intermediate stage executes the four standard AES transformations in sequence, combined with on-the-fly round key generation:
  * **Datapath flow:** `State_in` $\rightarrow$ `SubBytes` $\rightarrow$ `ShiftRows` $\rightarrow$ `MixColumns` $\rightarrow$ `(+) Key_out` $\rightarrow$ `State_out`
  * **Key schedule flow:** `Key_in` $\rightarrow$ `KeyRound` $\rightarrow$ `Key_out`

* **Round 10 (`AESfinal`):**  
  In accordance with FIPS-197, `MixColumns` is bypassed in the final round:
  * **Final round flow:** `State_in` $\rightarrow$ `SubBytes` $\rightarrow$ `ShiftRows` $\rightarrow$ `(+) Key_out` $\rightarrow$ `Ciphertext`

---

### 2. Round Transformation Modules

| Module | Function | Operation Description |
| :--- | :--- | :--- |
| **`SubBytes`** | Non-linear Byte Substitution | Instantiates 16 parallel 8-bit `Sbox` instances, mapping each state byte through multiplicative inversion in $GF(2^8)$ followed by an affine transformation. |
| **`ShiftRows`** | Cyclical Row Permutation | Fixed byte-level wire permutation: Row 0 is unshifted; Row 1 is cyclically rotated left by 1 byte; Row 2 by 2 bytes; Row 3 by 3 bytes. |
| **`MixColumns`** | Linear Column Diffusion | Multiplies each 4-byte column by a fixed MDS polynomial matrix over $GF(2^8)$ utilizing efficient Galois multiplier functions ($x \cdot \{02\}$ as `mb2` and $x \cdot \{03\}$ as `mb3`). |
| **`KeyRound`** | Real-Time Key Schedule | Applies `RotWord`, `SubWord` (via 4 shared S-boxes), and XOR with the round constant `rconx` to generate words $w_4$ through $w_7$ on the fly. |

---

### 3. On-the-Fly Key Schedule Engine

At round $r$, given the current 128-bit key words $\{w_0, w_1, w_2, w_3\}$, the next round key words $\{w_4, w_5, w_6, w_7\}$ are computed synchronously as follows:

```text
w[4] = w[0] ^ SubWord(RotWord(w[3])) ^ Rcon[r]
w[5] = w[1] ^ w[4]
w[6] = w[2] ^ w[5]
w[7] = w[3] ^ w[6]
```

---

## 📁 Repository Structure

```text
├── AES_pipeline.v          # [TOP-LEVEL] 10-stage pipelined AES-128 encryption core
├── AESround.v              # Standard round module (Rounds 1 to 9)
├── AESfinal.v              # Final round module (Round 10, omitting MixColumns)
├── KeyRound.v              # On-the-fly round key generator
├── MixColumns.v            # Column diffusion over Galois Field GF(2^8)
├── ShiftRows.v             # Byte-level cyclical row transposition
├── SubBytes.v              # Byte substitution layer (16 parallel S-boxes)
├── Sbox.v                  # 8-bit non-linear AES Substitution Box (LUT)
├── tb_AESpipeline.v        # Testbench verifying pipeline throughput and FIPS-197 vectors
├── aes.xdc                 # Xilinx Design Constraints (100 MHz / 10 ns clock specification)
├── AES_finish/             # Complete Vivado project (.xpr) and run configurations
├── 24521734_AES-128.pdf    # Comprehensive graduation/course project report (Slides)
├── LICENSE                 # MIT Open Source License
└── README.md               # Technical project documentation
```

---

## 🚀 Simulation & Verification

The testbench [`tb_AESpipeline.v`](tb_AESpipeline.v) validates consecutive multi-block pipelining using standard NIST vectors:
* **Test Case 1 (Implementation Reference):**
  * Plaintext: `00112233445566778899aabbccddeeff`
  * Key: `000102030405060708090a0b0c0d0e0f`
  * Expected Ciphertext: `69c4e0d86a7b0430d8cdb78070b4c55a`
* **Test Case 2 (NIST FIPS-197 Official):**
  * Plaintext: `3243f6a8885a308d313198a2e0370734`
  * Key: `2b7e151628aed2a6abf7158809cf4f3c`
  * Expected Ciphertext: `3925841d02dc09fbdc118597196a0b32`

---

### 1. Quick CLI Simulation with Icarus Verilog (Recommended)

Requires `iverilog` and `vvp`. Run the following commands:

```bash
# Compile testbench and all RTL modules
iverilog -o sim_aes tb_AESpipeline.v AES_pipeline.v AESround.v AESfinal.v KeyRound.v SubBytes.v Sbox.v ShiftRows.v MixColumns.v

# Execute simulation runtime
vvp sim_aes
```

**Expected Console Output:**
```text
Test Case 1: PASSED
Test Case 2: PASSED
tb_AESpipeline.v:68: $finish called at 186000 (1ps)
```

---

### 2. Simulation with Mentor Graphics ModelSim

1. Launch ModelSim and open the workspace project `AES_finish.mpf` (or create a new library and load all `.v` files).
2. Click **Compile All**.
3. Open the **Library** tab -> expand `work` -> right-click `tb_AES_pipeline` -> select **Simulate**.
4. In the transcript terminal, type: `run -all`.

---

### 3. Simulation with Xilinx Vivado

1. Open Vivado and load `AES_finish/AES_finish.xpr`.
2. Under **Flow Navigator**, click **Run Simulation** -> **Run Behavioral Simulation**.
3. Inspect waveforms at cycles 11 and 12 to observe the streaming pipeline outputs.

---

## 📊 Synthesis & FPGA Implementation Results

The design was fully synthesized and implemented on the **Xilinx Kintex-7** FPGA family (`xc7k160tiffv676-2L`) using Vivado.

### 1. Hardware Resource Utilization

| Resource Type | Used | Available | Utilization (%) |
| :--- | :---: | :---: | :---: |
| **Slice LUTs** | **9,626** | 101,400 | **9.49%** |
| **Slice Registers (FF)** | **2,688** | 202,800 | **1.33%** |
| **Slices** | **2,653** | 25,350 | **10.47%** |
| **F7 Muxes** | 3,200 | 50,700 | 6.31% |
| **F8 Muxes** | 1,591 | 25,350 | 6.28% |
| **Bonded IOB** | 386 | 400 | 96.50% |

---

### 2. Timing & Throughput Analysis

* **Target Clock Constraint:** $T_{clk} = 10.000\text{ ns}$ ($F = 100\text{ MHz}$)
* **Worst Negative Slack (WNS):** $+5.218\text{ ns}$ (Clean timing closure, zero negative slack)
* **Minimum Achievable Clock Period ($T_{min}$):**  
  $$T_{min} = T_{clk} - \text{WNS} = 10.000\text{ ns} - 5.218\text{ ns} = \mathbf{4.782\text{ ns}}$$
* **Maximum Clock Frequency ($F_{max}$):**  
  $$F_{max} = \frac{1}{T_{min}} = \frac{1}{4.782\text{ ns}} \approx \mathbf{209.1\text{ MHz}}$$
* **Maximum Throughput:**  
  $$\text{Throughput} = \text{Block Size (bits)} \times F_{max} = 128\text{ bits} \times 209.1\text{ MHz} \approx \mathbf{26.7\text{ Gbps}}$$

---

### 3. Power Consumption Analysis

* **Total On-Chip Power:** **0.67 W**
  * **Dynamic Power:** **0.583 W (87%)**
    * Clocks: 0.023 W (4%)
    * Signals: 0.224 W (38%)
    * Logic: 0.213 W (37%)
    * I/O: 0.123 W (21%)
  * **Device Static Power:** **0.087 W (13%)**
* **Junction Temperature:** $26.3^\circ\text{C}$ (Thermal Margin: $73.7^\circ\text{C}$)

---

### 4. Comparison with State-of-the-Art Works

| Metric | **This Work**<br>*(AES-128 Pipeline)* | **Borkar et al. [2]**<br>*(AES-128)* | **Kumar et al. [1]**<br>*(AES-128-MPPRM)* |
| :--- | :---: | :---: | :---: |
| **FPGA Target** | **Kintex-7** (`xc7k160t`) | Virtex (`XCV600 BG560-6`) | **Kintex-7** |
| **$F_{max}$** | **209.1 MHz** | 140.39 MHz | 81.33 MHz |
| **Slice LUTs** | 9,626 | 3,645 | 8,129 |
| **Flip-Flops (FF)** | **2,688** | 512 | 7,120 |
| **Slices** | 2,653 | 1,853 | 467 |
| **Bonded IOB** | 386 | 391 | 211 |

> **Key Takeaway:** Compared to the recent work by Kumar et al. on the identical Kintex-7 FPGA architecture, our proposed pipelined design achieves **$2.56\times$ higher operating frequency** ($209.1\text{ MHz}$ vs $81.33\text{ MHz}$) while consuming **$62.2\%$ fewer Flip-Flops** ($2,688$ vs $7,120$), demonstrating the efficiency of our on-the-fly key generation strategy.

---

## 📚 References

1. T. M. Kumar, K. S. Reddy, S. Rinaldi, B. D. Parameshachari and K. Arunachalam, *"A Low Area High Speed FPGA Implementation of AES Architecture for Cryptography Application"*, Electronics, Vol. 10, No. 16, 2021.
2. A. M. Borkar, R. V. Kshirsagar and M. V. Vyawahare, *"FPGA Implementation of AES Algorithm"*, Proc. 3rd Int. Conf. on Electronics Computer Technology (ICECT), 2011, pp. 401-405.
3. H. S. Deshpande, K. J. Karande and A. O. Mulani, *"Efficient Implementation of AES Algorithm on FPGA"*, Proc. Int. Conf. on Communication and Signal Processing (ICCSP), 2014, pp. 1895-1899.
4. National Institute of Standards and Technology (NIST), *"Advanced Encryption Standard (AES)"*, Federal Information Processing Standards Publication (FIPS) 197, Nov 2001.

---

## 📄 License & Citation

This project is licensed under the [MIT License](LICENSE) - see the LICENSE file for details. If you use or reference this work in your academic studies or research, please cite:

```bibtex
@misc{thuan2026aes128,
  author = {Cao Minh Thuan},
  title = {High-Throughput AES-128 Pipelined Hardware Accelerator on FPGA},
  year = {2026},
  publisher = {GitHub},
  howpublished = {\url{https://github.com/Thuan-k19/AES-128}}
}
```
