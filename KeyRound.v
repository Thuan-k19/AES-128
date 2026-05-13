// One AES-128 key-schedule step: {w0..w3} -> {w4..w7}
// Uses shared Sbox module (same table as SubBytes) to avoid duplicating the
// large 256-entry case logic that lived in a separate function.
module KeyRound (
    input  wire [127:0] key,
    input  wire [3:0]   round_index,
    output wire [127:0] key_out
);
    wire [31:0] w0 = key[127:96];
    wire [31:0] w1 = key[95:64];
    wire [31:0] w2 = key[63:32];
    wire [31:0] w3 = key[31:0];

    // RotWord on w3
    wire [31:0] temp_rot = {w3[23:0], w3[31:24]};

    wire [7:0] sb0, sb1, sb2, sb3;
    Sbox u_sb0 (.a(temp_rot[31:24]), .c(sb0));
    Sbox u_sb1 (.a(temp_rot[23:16]), .c(sb1));
    Sbox u_sb2 (.a(temp_rot[15:8]),  .c(sb2));
    Sbox u_sb3 (.a(temp_rot[7:0]),   .c(sb3));

    wire [31:0] subword = {sb0, sb1, sb2, sb3};

    function [31:0] rconx;
        input [3:0] r;
        begin
            case (r)
                4'h1: rconx = 32'h01000000;
                4'h2: rconx = 32'h02000000;
                4'h3: rconx = 32'h04000000;
                4'h4: rconx = 32'h08000000;
                4'h5: rconx = 32'h10000000;
                4'h6: rconx = 32'h20000000;
                4'h7: rconx = 32'h40000000;
                4'h8: rconx = 32'h80000000;
                4'h9: rconx = 32'h1b000000;
                4'ha: rconx = 32'h36000000;
                default: rconx = 32'h00000000;
            endcase
        end
    endfunction

    wire [31:0] w4 = w0 ^ subword ^ rconx(round_index);
    wire [31:0] w5 = w1 ^ w4;
    wire [31:0] w6 = w2 ^ w5;
    wire [31:0] w7 = w3 ^ w6;

    assign key_out = {w4, w5, w6, w7};

endmodule
