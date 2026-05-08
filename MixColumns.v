module MixColumns (
    input  wire [127:0] state_in,
    output wire [127:0] state_out
);
    
    // 1. Hàm nhân với 0x02
    function [7:0] mb2;
        input [7:0] x;
        begin
            // Dịch trái 1 bit. Nếu bit thứ 7 (MSB) là 1, XOR với 0x1b
            mb2 = {x[6:0], 1'b0} ^ (x[7] ? 8'h1b : 8'h00);
        end
    endfunction

    // 2. Hàm nhân với 0x03
    // (x * 0x03) = (x * 0x02) XOR (x * 0x01)
    function [7:0] mb3;
        input [7:0] x;
        begin
            mb3 = mb2(x) ^ x;
        end
    endfunction

    // =========================================================================
    // TÁCH MA TRẬN STATE THÀNH 4 CỘT (Mỗi cột 32-bit, gồm 4 byte)
    // =========================================================================
    
    // Cột 0
    wire [7:0] c0_0 = state_in[127:120];
    wire [7:0] c0_1 = state_in[119:112];
    wire [7:0] c0_2 = state_in[111:104];
    wire [7:0] c0_3 = state_in[103:96];

    // Cột 1
    wire [7:0] c1_0 = state_in[95:88];
    wire [7:0] c1_1 = state_in[87:80];
    wire [7:0] c1_2 = state_in[79:72];
    wire [7:0] c1_3 = state_in[71:64];

    // Cột 2
    wire [7:0] c2_0 = state_in[63:56];
    wire [7:0] c2_1 = state_in[55:48];
    wire [7:0] c2_2 = state_in[47:40];
    wire [7:0] c2_3 = state_in[39:32];

    // Cột 3
    wire [7:0] c3_0 = state_in[31:24];
    wire [7:0] c3_1 = state_in[23:16];
    wire [7:0] c3_2 = state_in[15:8];
    wire [7:0] c3_3 = state_in[7:0];

    // =========================================================================
    // THỰC HIỆN PHÉP NHÂN MA TRẬN CHO TỪNG CỘT
    // Công thức ma trận:
    // [d0] = [02 03 01 01] * [b0]
    // [d1] = [01 02 03 01] * [b1]
    // [d2] = [01 01 02 03] * [b2]
    // [d3] = [03 01 01 02] * [b3]
    // =========================================================================

    // Cột 0 Mới
    wire [7:0] d0_0 = mb2(c0_0) ^ mb3(c0_1) ^     c0_2  ^     c0_3;
    wire [7:0] d0_1 =     c0_0  ^ mb2(c0_1) ^ mb3(c0_2) ^     c0_3;
    wire [7:0] d0_2 =     c0_0  ^     c0_1  ^ mb2(c0_2) ^ mb3(c0_3);
    wire [7:0] d0_3 = mb3(c0_0) ^     c0_1  ^     c0_2  ^ mb2(c0_3);

    // Cột 1 Mới
    wire [7:0] d1_0 = mb2(c1_0) ^ mb3(c1_1) ^     c1_2  ^     c1_3;
    wire [7:0] d1_1 =     c1_0  ^ mb2(c1_1) ^ mb3(c1_2) ^     c1_3;
    wire [7:0] d1_2 =     c1_0  ^     c1_1  ^ mb2(c1_2) ^ mb3(c1_3);
    wire [7:0] d1_3 = mb3(c1_0) ^     c1_1  ^     c1_2  ^ mb2(c1_3);

    // Cột 2 Mới
    wire [7:0] d2_0 = mb2(c2_0) ^ mb3(c2_1) ^     c2_2  ^     c2_3;
    wire [7:0] d2_1 =     c2_0  ^ mb2(c2_1) ^ mb3(c2_2) ^     c2_3;
    wire [7:0] d2_2 =     c2_0  ^     c2_1  ^ mb2(c2_2) ^ mb3(c2_3);
    wire [7:0] d2_3 = mb3(c2_0) ^     c2_1  ^     c2_2  ^ mb2(c2_3);

    // Cột 3 Mới
    wire [7:0] d3_0 = mb2(c3_0) ^ mb3(c3_1) ^     c3_2  ^     c3_3;
    wire [7:0] d3_1 =     c3_0  ^ mb2(c3_1) ^ mb3(c3_2) ^     c3_3;
    wire [7:0] d3_2 =     c3_0  ^     c3_1  ^ mb2(c3_2) ^ mb3(c3_3);
    wire [7:0] d3_3 = mb3(c3_0) ^     c3_1  ^     c3_2  ^ mb2(c3_3);

    // =========================================================================
    // GHÉP LẠI THÀNH DỮ LIỆU ĐẦU RA (128-bit)
    // =========================================================================
    assign state_out = {
        d0_0, d0_1, d0_2, d0_3,  // Cột 0
        d1_0, d1_1, d1_2, d1_3,  // Cột 1
        d2_0, d2_1, d2_2, d2_3,  // Cột 2
        d3_0, d3_1, d3_2, d3_3   // Cột 3
    };

endmodule