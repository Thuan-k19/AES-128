`timescale 1ns / 1ps

module tb_AES_pipeline;

    // Khai báo các tín hiệu tương ứng với module của bạn
    reg clk;
    reg reset;
    reg [127:0] plaintext;
    reg [127:0] key;
    wire [127:0] ciphertext;

    // Khởi tạo module AES_pipeline
    AES_pipeline uut (
        .clk(clk), 
        .reset(reset), 
        .plaintext(plaintext), 
        .key(key), 
        .ciphertext(ciphertext)
    );

    // Tạo xung nhịp (Clock generation) - Chu kỳ 10ns
    always #5 clk = ~clk;

    initial begin
        // Khởi tạo các tín hiệu đầu vào
        clk = 0;
        reset = 1;
        plaintext = 128'h0;
        key = 128'h0;

        // Đợi 100ns để hoàn tất reset
        #10;
        reset = 0;
        
        // -----------------------------------------------------
        // TEST CASE 1: Theo tài liệu Implementation AES
        // -----------------------------------------------------
        @(posedge clk);
        plaintext = 128'h00112233445566778899aabbccddeeff;
        key       = 128'h000102030405060708090a0b0c0d0e0f;
        
        // -----------------------------------------------------
        // TEST CASE 2: Theo chuẩn NIST FIPS-197
        // (Đưa thẳng vào ở xung nhịp tiếp theo để test Pipeline)
        // -----------------------------------------------------
        @(posedge clk);
        plaintext = 128'h3243f6a8885a308d313198a2e0370734;
        key       = 128'h2b7e151628aed2a6abf7158809cf4f3c;
        
        // Đợi 11 chu kỳ xung nhịp cho Test Case 1 chạy ra khỏi Pipeline
        repeat(10) @(posedge clk);
        
        if (ciphertext === 128'h69c4e0d86a7b0430d8cdb78070b4c55a)
            $display("Test Case 1: PASSED");
        else
            $display("Test Case 1: FAILED. Output = %h", ciphertext);

        // Đợi thêm 1 chu kỳ xung nhịp nữa cho Test Case 2 ra khỏi Pipeline
        @(posedge clk);
        
        if (ciphertext === 128'h3925841d02dc09fbdc118597196a0b32)
            $display("Test Case 2: PASSED");
        else
            $display("Test Case 2: FAILED. Output = %h", ciphertext);

        // Kết thúc mô phỏng
        #50;
        $finish;
    end
      
endmodule