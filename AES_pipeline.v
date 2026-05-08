module AES_pipeline (
    input  wire clk, reset,
    input  wire [127:0] plaintext,
    input  wire [127:0] key,
    output reg  [127:0] ciphertext
);

    //mỗi stage có 1 data register và 1 key register
    reg  [127:0] stage_data [0:9];
    reg  [127:0] stage_key  [0:9];

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
            for (j = 0; j <= 10; j = j + 1) begin
                stage_data[j] <= 128'b0;
                stage_key [j] <= 128'b0;
            end
            ciphertext <= 128'b0;
        end
        else begin
            stage_data[0] <= plaintext ^ key;
            stage_key [0] <= key;
            stage_data[1] <= round_data_out[1]
            stage_key[1] <= round_key_out[1]
            stage_data[2] <= round_data_out[2]
            stage_key[2] <= round_key_out[2]
            stage_data[3] <= round_data_out[3]
            stage_key[3] <= round_key_out[3]
            stage_data[4] <= round_data_out[4]
            stage_key[4] <= round_key_out[4]
            stage_data[5] <= round_data_out[5]
            stage_key[5] <= round_key_out[5]
            stage_data[6] <= round_data_out[6]
            stage_key[6] <= round_key_out[6]
            stage_data[7] <= round_data_out[7]
            stage_key[7] <= round_key_out[7]
            stage_data[8] <= round_data_out[8]
            stage_key[8] <= round_key_out[8]
            stage_data[9] <= round_data_out[9]
            stage_key[9] <= round_key_out[9]
            ciphertext <= final_data_out;
        end
    end
endmodule
