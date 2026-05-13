// AES-128 encrypt, 10 pipeline stages (1 block / cycle when full).
// stage_data[i] / stage_key[i] hold the state and key material for round i.
module AES_pipeline (
    input  wire        clk,
    input  wire        reset,
    input  wire [127:0] plaintext,
    input  wire [127:0] key,
    output reg  [127:0] ciphertext
);

    reg [127:0] stage_data [0:9];
    reg [127:0] stage_key  [0:9];

    wire [127:0] round_data_out [1:9];
    wire [127:0] round_key_out  [1:9];
    wire [127:0] final_data_out;

    genvar i;
    generate
        for (i = 1; i <= 9; i = i + 1) begin : round_gen
            AESround round_inst (
                .plaintext   (stage_data[i-1]),
                .key         (stage_key [i-1]),
                .round_index (i[3:0]),
                .ciphertext  (round_data_out[i]),
                .key_out     (round_key_out [i])
            );
        end
    endgenerate

    AESfinal round10 (
        .plaintext   (stage_data[9]),
        .key         (stage_key [9]),
        .round_index (4'd10),
        .ciphertext  (final_data_out)
    );

    integer j;
    always @(posedge clk) begin
        if (reset) begin
            for (j = 0; j <= 9; j = j + 1) begin
                stage_data[j] <= 128'b0;
                stage_key[j]  <= 128'b0;
            end
            ciphertext <= 128'b0;
        end
        else begin
            stage_data[0] <= plaintext ^ key;
            stage_key[0]  <= key;
            for (j = 1; j <= 9; j = j + 1) begin
                stage_data[j] <= round_data_out[j];
                stage_key[j]  <= round_key_out[j];
            end
            ciphertext <= final_data_out;
        end
    end
endmodule
