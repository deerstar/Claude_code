/*
 * Ethernet MAC CRC32 Module
 *
 * This module implements CRC32 generation and checking for Ethernet frames
 * Polynomial: 0x04C11DB7 (Ethernet standard)
 *
 * Author: Claude
 * Date: 2025-10-21
 */

module eth_mac_crc32 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        crc_en,      // Enable CRC calculation
    input  wire        crc_clear,   // Clear CRC accumulator
    input  wire [7:0]  data_in,     // Input data byte
    output reg  [31:0] crc_out      // CRC output
);

    // CRC32 polynomial for Ethernet: 0x04C11DB7
    // Standard Ethernet CRC32

    wire [31:0] crc_next;
    reg  [31:0] crc_reg;

    // CRC32 calculation logic
    // Using parallel CRC calculation for 8-bit data
    function [31:0] nextCRC32_D8;
        input [7:0]  data;
        input [31:0] crc;
        reg   [7:0]  d;
        reg   [31:0] c;
        reg   [31:0] newcrc;
    begin
        d = data;
        c = crc;

        newcrc[0] = d[6] ^ d[0] ^ c[24] ^ c[30];
        newcrc[1] = d[7] ^ d[6] ^ d[1] ^ d[0] ^ c[24] ^ c[25] ^ c[30] ^ c[31];
        newcrc[2] = d[7] ^ d[6] ^ d[2] ^ d[1] ^ d[0] ^ c[24] ^ c[25] ^ c[26] ^ c[30] ^ c[31];
        newcrc[3] = d[7] ^ d[3] ^ d[2] ^ d[1] ^ c[25] ^ c[26] ^ c[27] ^ c[31];
        newcrc[4] = d[6] ^ d[4] ^ d[3] ^ d[2] ^ d[0] ^ c[24] ^ c[26] ^ c[27] ^ c[28] ^ c[30];
        newcrc[5] = d[7] ^ d[6] ^ d[5] ^ d[4] ^ d[3] ^ d[1] ^ d[0] ^ c[24] ^ c[25] ^ c[27] ^ c[28] ^ c[29] ^ c[30] ^ c[31];
        newcrc[6] = d[7] ^ d[6] ^ d[5] ^ d[4] ^ d[2] ^ d[1] ^ c[25] ^ c[26] ^ c[28] ^ c[29] ^ c[30] ^ c[31];
        newcrc[7] = d[7] ^ d[5] ^ d[3] ^ d[2] ^ d[0] ^ c[24] ^ c[26] ^ c[27] ^ c[29] ^ c[31] ^ c[30];
        newcrc[8] = d[4] ^ d[3] ^ d[1] ^ d[0] ^ c[0] ^ c[24] ^ c[25] ^ c[27] ^ c[28] ^ c[30];
        newcrc[9] = d[5] ^ d[4] ^ d[2] ^ d[1] ^ c[1] ^ c[25] ^ c[26] ^ c[28] ^ c[29] ^ c[31];
        newcrc[10] = d[5] ^ d[3] ^ d[2] ^ d[0] ^ c[2] ^ c[24] ^ c[26] ^ c[27] ^ c[29] ^ c[30];
        newcrc[11] = d[4] ^ d[3] ^ d[1] ^ d[0] ^ c[3] ^ c[24] ^ c[25] ^ c[27] ^ c[28] ^ c[30] ^ c[31];
        newcrc[12] = d[6] ^ d[5] ^ d[4] ^ d[2] ^ d[1] ^ d[0] ^ c[4] ^ c[24] ^ c[25] ^ c[26] ^ c[28] ^ c[29] ^ c[30] ^ c[31];
        newcrc[13] = d[7] ^ d[6] ^ d[5] ^ d[3] ^ d[2] ^ d[1] ^ c[5] ^ c[25] ^ c[26] ^ c[27] ^ c[29] ^ c[30] ^ c[31];
        newcrc[14] = d[7] ^ d[6] ^ d[4] ^ d[3] ^ d[2] ^ c[6] ^ c[26] ^ c[27] ^ c[28] ^ c[30] ^ c[31];
        newcrc[15] = d[7] ^ d[5] ^ d[4] ^ d[3] ^ c[7] ^ c[27] ^ c[28] ^ c[29] ^ c[31];
        newcrc[16] = d[5] ^ d[4] ^ d[0] ^ c[8] ^ c[24] ^ c[28] ^ c[29] ^ c[30];
        newcrc[17] = d[6] ^ d[5] ^ d[1] ^ c[9] ^ c[25] ^ c[29] ^ c[30] ^ c[31];
        newcrc[18] = d[7] ^ d[6] ^ d[2] ^ c[10] ^ c[26] ^ c[30] ^ c[31];
        newcrc[19] = d[7] ^ d[3] ^ c[11] ^ c[27] ^ c[31];
        newcrc[20] = d[4] ^ c[12] ^ c[28];
        newcrc[21] = d[5] ^ c[13] ^ c[29];
        newcrc[22] = d[0] ^ c[14] ^ c[24] ^ c[30];
        newcrc[23] = d[6] ^ d[1] ^ d[0] ^ c[15] ^ c[24] ^ c[25] ^ c[30] ^ c[31];
        newcrc[24] = d[7] ^ d[2] ^ d[1] ^ c[16] ^ c[25] ^ c[26] ^ c[31];
        newcrc[25] = d[3] ^ d[2] ^ c[17] ^ c[26] ^ c[27];
        newcrc[26] = d[6] ^ d[4] ^ d[3] ^ d[0] ^ c[18] ^ c[24] ^ c[27] ^ c[28] ^ c[30];
        newcrc[27] = d[7] ^ d[5] ^ d[4] ^ d[1] ^ c[19] ^ c[25] ^ c[28] ^ c[29] ^ c[31];
        newcrc[28] = d[6] ^ d[5] ^ d[2] ^ c[20] ^ c[26] ^ c[29] ^ c[30];
        newcrc[29] = d[7] ^ d[6] ^ d[3] ^ c[21] ^ c[27] ^ c[30] ^ c[31];
        newcrc[30] = d[7] ^ d[4] ^ c[22] ^ c[28] ^ c[31];
        newcrc[31] = d[5] ^ c[23] ^ c[29];

        nextCRC32_D8 = newcrc;
    end
    endfunction

    // Calculate next CRC value
    assign crc_next = nextCRC32_D8(data_in, crc_reg);

    // CRC register update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_reg <= 32'hFFFFFFFF;
        end else begin
            if (crc_clear) begin
                crc_reg <= 32'hFFFFFFFF;
            end else if (crc_en) begin
                crc_reg <= crc_next;
            end
        end
    end

    // Output inverted CRC (Ethernet standard)
    always @(*) begin
        crc_out = ~crc_reg;
    end

endmodule
