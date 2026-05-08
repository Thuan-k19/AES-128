module SubBytes (
    input  wire [127:0] state_in,
    output wire [127:0] state_out
);
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : Sbox
            Sbox sbox_inst (
                .a(state_in[i*8 +: 8]),
                .c(state_out[i*8 +: 8])
            );
        end
    endgenerate

endmodule