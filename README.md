# Thiết kế Bộ Mã Hóa AES-128 Pipeline Hiệu Năng Cao Trên FPGA (NIST FIPS-197)

[![Verilog HDL](https://img.shields.io/badge/Language-Verilog%20HDL-blue.svg)](https://en.wikipedia.org/wiki/Verilog)
[![FPGA Target](https://img.shields.io/badge/Target-Xilinx%20Kintex--7-red.svg)](https://www.xilinx.com/products/silicon-devices/fpga/kintex-7.html)
[![Throughput](https://img.shields.io/badge/Throughput-26.7%20Gbps-brightgreen.svg)]()
[![Standard](https://img.shields.io/badge/Standard-NIST%20FIPS--197-orange.svg)](https://csrc.nist.gov/publications/detail/fips/197/final)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Đồ án thiết kế phần cứng vi mạch cho bộ mã hóa **AES-128 (Advanced Encryption Standard)** sử dụng kiến trúc **10-stage Pipeline** kết hợp cơ chế sinh khóa trực tiếp (**On-the-fly Key Expansion**), tối ưu hóa thông lượng và diện tích phần cứng trên FPGA.

* **Sinh viên thực hiện:** Cao Minh Thuận (MSSV: 24521734)
* **Lớp:** CE213.Q21.VMTN
* **Giảng viên hướng dẫn:** TS. Trần Thị Điểm
* **Đơn vị:** Khoa Kỹ thuật Máy tính – Trường Đại học Công nghệ Thông tin, ĐHQG-HCM (UIT)

---

## 📑 Mục lục
1. [Giới thiệu tổng quan](#-giới-thiệu-tổng-quan)
2. [Điểm nổi bật của thiết kế](#-điểm-nổi-bật-của-thiết-kế)
3. [Kiến trúc phần cứng](#-kiến-trúc-phần-cứng)
   * [Sơ đồ khối 10-Stage Pipeline](#1-sơ-đồ-khối-10-stage-pipeline)
   * [Các khối chức năng trong từng Round](#2-các-khối-chức-năng-trong-từng-round)
   * [Cơ chế On-the-fly Key Expansion](#3-cơ-chế-on-the-fly-key-expansion)
4. [Cấu trúc mã nguồn](#-cấu-trúc-mã-nguồn)
5. [Hướng dẫn mô phỏng & kiểm chứng](#-hướng-dẫn-mô-phỏng--kiểm-chứng)
   * [Mô phỏng với Icarus Verilog (CLI)](#1-mô-phỏng-nhanh-bằng-icarus-verilog-khuyên-dùng)
   * [Mô phỏng với ModelSim](#2-mô-phỏng-với-modelsim)
   * [Mô phỏng với Vivado](#3-mô-phỏng-với-xilinx-vivado)
6. [Kết quả tổng hợp và thực thi FPGA (Implementation)](#-kết-quả-tổng-hợp-và-thực-thi-fpga-implementation)
   * [Tài nguyên phần cứng (Resource Utilization)](#1-tiêu-thụ-tài-nguyên-resource-utilization)
   * [Định thời và thông lượng (Timing & Throughput)](#2-định-thời-và-thông-lượng-timing--throughput)
   * [Công suất tiêu thụ (Power Analysis)](#3-công-suất-tiêu-thụ-power-analysis)
   * [So sánh với các công trình nghiên cứu khác](#4-bảng-so-sánh-với-các-công-trình-nghiên-cứu)
7. [Tài liệu tham khảo](#-tài-liệu-tham-khảo)

---

## 🔍 Giới thiệu tổng quan

**AES-128** là thuật toán mã hóa khối đối xứng được Viện Tiêu chuẩn và Công nghệ Quốc gia Hoa Kỳ (NIST) chuẩn hóa trong tài liệu **FIPS-197**. Thuật toán xử lý khối dữ liệu đầu vào `Plaintext` kích thước **128 bit** cùng với khóa `Key` kích thước **128 bit** trải qua **10 vòng biến đổi (Rounds)** liên tiếp để tạo ra bản mã `Ciphertext` 128 bit.

Dự án này tập trung vào thiết kế phần cứng vi mạch (RTL Verilog) hiệu năng cao, tối ưu cho việc xử lý luồng dữ liệu liên tục với tốc độ Gigabits trên nền tảng FPGA.

---

## ⚡ Điểm nổi bật của thiết kế

* **Kiến trúc Fully-Pipelined 10 tầng:** Cho phép đưa dữ liệu mới vào ở **mỗi chu kỳ xung nhịp**. Sau độ trễ ban đầu (11 chu kỳ để lấp đầy pipeline), mạch xuất ra **1 block Ciphertext (128 bit) / 1 chu kỳ clock**, đạt thông lượng cực đại.
* **Sinh khóa On-the-fly (`KeyRound`):** Khóa của vòng $i$ được tính toán song song trực tiếp từ khóa của vòng $i-1$ ngay trong tầng pipeline tương ứng. Thiết kế này:
  * Loại bỏ hoàn toàn khối `KeyExpansion` cồng kềnh trước đó (vốn phải tính trước và lưu toàn bộ 11 khóa vào hàng loạt thanh ghi tĩnh).
  * Tiết kiệm đáng kể tài nguyên Flip-Flops/Registers trên FPGA.
* **Tối ưu dùng chung S-box:** Khối tính khóa `KeyRound` dùng chung bảng tra phi tuyến với khối `SubBytes` (`Sbox.v`), tránh trùng lặp phần cứng bảng tra S-box (256 trường hợp).
* **Kiểm định chặt chẽ:** Đạt 100% chuẩn xác với các test vector chuẩn trong tài liệu NIST FIPS-197.

---

## 🏛 Kiến trúc phần cứng

### 1. Sơ đồ khối 10-Stage Pipeline

```
Plaintext [127:0] ──┐
                    ├──(+)──>[Stage 0 Reg]──>[ Round 1 ]──>[Stage 1 Reg]──> ... ──>[ Round 9 ]──>[Stage 9 Reg]──>[ Round 10 ]──>[Ciphertext Reg]
      Key [127:0] ──┘                                                                                                                │
                                                                                                                               [127:0] Ciphertext
```

* **Round 0 (Initial AddRoundKey):** Thực hiện phép $\text{Plaintext} \oplus \text{Key}$, ghi vào thanh ghi `stage_data[0]`.
* **Round 1 đến Round 9 (`AESround`):** Mỗi tầng gồm 4 bước biến đổi chuẩn kết hợp sinh khóa:
  $$\text{State}_{in} \xrightarrow{\text{SubBytes}} \xrightarrow{\text{ShiftRows}} \xrightarrow{\text{MixColumns}} \oplus \text{Key}_{out} \longrightarrow \text{State}_{out}$$
  $$\text{Key}_{in} \xrightarrow{\text{KeyRound}} \text{Key}_{out}$$
* **Round 10 (`AESfinal`):** Bỏ qua bước `MixColumns` theo chuẩn FIPS-197:
  $$\text{State}_{in} \xrightarrow{\text{SubBytes}} \xrightarrow{\text{ShiftRows}} \oplus \text{Key}_{out} \longrightarrow \text{Ciphertext}$$

---

### 2. Các khối chức năng trong từng Round

| Module | Chức năng | Cơ chế hoạt động |
| :--- | :--- | :--- |
| **`SubBytes`** | Thay thế byte phi tuyến | Ghép 16 khối `Sbox` 8-bit song song, tra bảng giá trị trong trường hữu hạn $GF(2^8)$. |
| **`ShiftRows`** | Dịch vòng các hàng | Hoán vị cố định các byte: Hàng 0 giữ nguyên, hàng 1 dịch trái 1 byte, hàng 2 dịch trái 2 byte, hàng 3 dịch trái 3 byte. |
| **`MixColumns`** | Trộn dữ liệu tuyến tính | Nhân ma trận trạng thái với ma trận đa thức cố định trong trường $GF(2^8)$ qua các hàm nhân $x \cdot \{02\}$ (`mb2`) và $x \cdot \{03\}$ (`mb3`). |
| **`KeyRound`** | Mở rộng khóa trực tiếp | Thực hiện `RotWord`, `SubWord` (qua 4 khối S-box), XOR với hằng số vòng `rconx` và chuỗi từ khóa trước đó. |

---

### 3. Cơ chế On-the-fly Key Expansion

Mỗi vòng $r$ nhận `key` 128 bit từ vòng trước $\{w_0, w_1, w_2, w_3\}$ và sinh ra 4 từ mới $\{w_4, w_5, w_6, w_7\}$:

$$\begin{aligned}
w_4 &= w_0 \oplus \text{SubWord}(\text{RotWord}(w_3)) \oplus \text{Rcon}[r] \\
w_5 &= w_1 \oplus w_4 \\
w_6 &= w_2 \oplus w_5 \\
w_7 &= w_3 \oplus w_6
\end{aligned}$$

---

## 📁 Cấu trúc mã nguồn

```text
├── AES_pipeline.v          # [TOP-LEVEL] Module bộ mã hóa AES-128 10 tầng pipeline
├── AESround.v              # Module vòng lặp chuẩn (Round 1 -> 9)
├── AESfinal.v              # Module vòng lặp cuối (Round 10 - không có MixColumns)
├── KeyRound.v              # Module sinh khóa on-the-fly cho từng vòng
├── MixColumns.v            # Khối biến đổi trộn cột trong trường Galois GF(2^8)
├── ShiftRows.v             # Khối biến đổi dịch hàng dữ liệu 128-bit
├── SubBytes.v              # Tầng thay thế byte (16 khối Sbox song song)
├── Sbox.v                  # Bảng tra cứu S-box phi tuyến chuẩn 8-bit
├── tb_AESpipeline.v        # Testbench kiểm tra đầy đủ pipeline với NIST FIPS-197
├── aes.xdc                 # File ràng buộc chân & định thời (Constraint clock 10ns)
├── AES_finish/             # Dự án Xilinx Vivado hoàn thiện (.xpr)
├── 24521734_AES-128.pdf    # Báo cáo đồ án chi tiết (Slide Report)
├── LICENSE                 # Giấy phép mã nguồn mở MIT
└── README.md               # Tài liệu hướng dẫn đồ án
```

---

## 🚀 Hướng dẫn mô phỏng & kiểm chứng

### 1. Mô phỏng nhanh bằng Icarus Verilog (Khuyên dùng)

Yêu cầu cài đặt `iverilog` và `vvp`. Chạy các lệnh sau trong terminal:

```bash
# Biên dịch toàn bộ thiết kế và testbench
iverilog -o sim_aes tb_AESpipeline.v AES_pipeline.v AESround.v AESfinal.v KeyRound.v SubBytes.v Sbox.v ShiftRows.v MixColumns.v

# Chạy mô phỏng
vvp sim_aes
```

**Kết quả kỳ vọng:**
```text
Test Case 1: PASSED
Test Case 2: PASSED
tb_AESpipeline.v:68: $finish called at 186000 (1ps)
```

---

### 2. Mô phỏng với ModelSim

1. Khởi động ModelSim, mở file project `AES_finish.mpf` (hoặc tạo project mới và thêm tất cả các file `.v`).
2. Nhấn **Compile All**.
3. Vào tab **Library** -> mở thư viện `work` -> chọn `tb_AES_pipeline` -> **Simulate**.
4. Chạy lệnh: `run -all`.

---

### 3. Mô phỏng với Xilinx Vivado

1. Mở Vivado và mở project `AES_finish/AES_finish.xpr`.
2. Trong cửa sổ **Flow Navigator**, chọn **Run Simulation** -> **Run Behavioral Simulation**.
3. Quan sát dạng sóng (Waveform) tại chu kỳ xung nhịp thứ 11 và 12 để đối chiếu Ciphertext.

---

## 📊 Kết quả tổng hợp và thực thi FPGA (Implementation)

Thiết kế đã được tổng hợp (Synthesis) và thực thi (Implementation) thành công trên kit **Xilinx Kintex-7** (Part: `xc7k160tiffv676-2L`) với công cụ Vivado.

### 1. Tiêu thụ tài nguyên (Resource Utilization)

| Loại tài nguyên | Sử dụng | Khả dụng | Tỷ lệ (%) |
| :--- | :---: | :---: | :---: |
| **Slice LUTs** | **9,626** | 101,400 | **9.49%** |
| **Slice Registers (FF)** | **2,688** | 202,800 | **1.33%** |
| **Slices** | **2,653** | 25,350 | **10.47%** |
| **F7 Muxes** | 3,200 | 50,700 | 6.31% |
| **F8 Muxes** | 1,591 | 25,350 | 6.28% |
| **Bonded IOB** | 386 | 400 | 96.50% |

---

### 2. Định thời và thông lượng (Timing & Throughput)

* **Ràng buộc Clock Target:** $T_{clk} = 10.0\text{ ns}$ ($F = 100\text{ MHz}$)
* **Worst Negative Slack (WNS):** $+5.218\text{ ns}$ (Thỏa mãn tuyệt đối, không vi phạm timing)
* **Chu kỳ tối thiểu:**
  $$T_{min} = T_{clk} - \text{WNS} = 10.0\text{ ns} - 5.218\text{ ns} = 4.782\text{ ns}$$
* **Tần số hoạt động tối đa ($F_{max}$):**
  $$F_{max} = \frac{1}{T_{min}} = \frac{1}{4.782\text{ ns}} \approx \mathbf{209.1\text{ MHz}}$$
* **Thông lượng tối đa (Max Throughput):**
  Do kiến trúc Pipeline 10 tầng xử lý liên tục 128 bit dữ liệu ở mỗi chu kỳ xung nhịp:
  $$\text{Throughput} = \text{Data Width} \times F_{max} = 128\text{ bit} \times 209.1\text{ MHz} \approx \mathbf{26.7\text{ Gbps}}$$

---

### 3. Công suất tiêu thụ (Power Analysis)

* **Tổng công suất tiêu thụ (Total On-Chip Power):** **0.67 W**
  * Dynamic Power: **0.583 W (87%)**
    * Clocks: 0.023 W (4%)
    * Signals: 0.224 W (38%)
    * Logic: 0.213 W (37%)
    * I/O: 0.123 W (21%)
  * Device Static Power: **0.087 W (13%)**
* **Nhiệt độ mối nối (Junction Temperature):** $26.3^\circ\text{C}$ (Thermal Margin: $73.7^\circ\text{C}$)

---

### 4. Bảng so sánh với các công trình nghiên cứu

| Tiêu chí | **Thiết kế đồ án**<br>*(AES-128 Pipeline)* | **Bài báo [2]**<br>*(Borkar et al., 2011)* | **Bài báo [1]**<br>*(Kumar et al., 2021)* |
| :--- | :---: | :---: | :---: |
| **FPGA Target** | **Kintex-7** (`xc7k160t`) | Virtex (`XCV600 BG560-6`) | **Kintex-7** |
| **Tần số $F_{max}$** | **209.1 MHz** | 140.39 MHz | 81.33 MHz |
| **Slice LUTs** | 9,626 | 3,645 | 8,129 |
| **Flip Flops (FF)** | **2,688** | 512 | 7,120 |
| **Slices** | 2,653 | 1,853 | 467 |
| **Bonded IOB** | 386 | 391 | 211 |

> **Nhận xét:** Thiết kế đạt tần số hoạt động **$F_{max} = 209.1\text{ MHz}$**, cao gấp **2.56 lần** so với công trình của Kumar et al. trên cùng dòng chip Kintex-7, đồng thời giảm được hơn **62% số lượng Flip Flops** nhờ cơ chế sinh khóa On-the-fly hiệu quả.

---

## 📚 Tài liệu tham khảo

1. T. M. Kumar, K. S. Reddy, S. Rinaldi, B. D. Parameshachari and K. Arunachalam, *"A Low Area High Speed FPGA Implementation of AES Architecture for Cryptography Application"*, Electronics, Vol. 10, No. 16, 2021.
2. A. M. Borkar, R. V. Kshirsagar and M. V. Vyawahare, *"FPGA Implementation of AES Algorithm"*, Proc. 3rd Int. Conf. on Electronics Computer Technology (ICECT), 2011, pp. 401-405.
3. H. S. Deshpande, K. J. Karande and A. O. Mulani, *"Efficient Implementation of AES Algorithm on FPGA"*, Proc. Int. Conf. on Communication and Signal Processing (ICCSP), 2014, pp. 1895-1899.
4. National Institute of Standards and Technology (NIST), *"Advanced Encryption Standard (AES)"*, Federal Information Processing Standards Publication (FIPS) 197, Nov 2001.

---

## 📄 Bản quyền & Tác giả

Dự án được phát hành theo giấy phép [MIT License](LICENSE). Mọi đóng góp, tái sử dụng trong học tập và nghiên cứu xin vui lòng ghi rõ nguồn tác giả.
