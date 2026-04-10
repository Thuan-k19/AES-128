module ShiftRows (
    input  wire [127:0] plaintext,
    output wire [127:0] ciphertext
);

    assign ciphertext[127:96] = {plaintext[127:120], plaintext[87:80], plaintext[47:40], plaintext[7:0]};
    assign ciphertext[95:64] = {plaintext[95:88], plaintext[55:48], plaintext[15:8], plaintext[103:96]};
    assign ciphertext[63:32] = {plaintext[63:56], plaintext[23:16], plaintext[111:104], plaintext[71:64]};
    assign ciphertext[31:0] = {plaintext[31:24], plaintext[119:112], plaintext[79:72], plaintext[39:32]};

endmodule