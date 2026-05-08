module AESfinal (
    input  wire [127:0] plaintext,
    input  wire [127:0] key,
    input  wire [3:0] round_index,
    output wire [127:0] ciphertext,
    output wire [127:0] key_out
);

    wire [127:0] output_sub, output_shift;
    
    KeyRound keyround(
        .key(key),
        .round_index(round_index),
        .key_out (key_out)
    );

    SubBytes Sub(
        .state_in(plaintext),
        .state_out(output_sub)
    );

    ShiftRows Shift (
        .state_in (output_sub),
        .state_out(output_shift)
    );

    assign ciphertext = output_shift ^ key_out;

endmodule
