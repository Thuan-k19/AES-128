module AddRoundKey (
    input  wire [127:0] plaintext,
    input  wire [127:0] key,
    output wire [127:0] ciphertext
);
    assign ciphertext = plaintext ^ key;

endmodule