/*
 * Ethernet MAC Transmit Module
 *
 * This module implements the Ethernet MAC transmit path
 * Features:
 *   - AXI-Stream input interface
 *   - GMII output interface
 *   - Automatic preamble and SFD insertion
 *   - CRC32 (FCS) generation and insertion
 *   - Minimum frame size padding (64 bytes)
 *   - Inter-frame gap (IFG) handling
 *
 * Author: Claude
 * Date: 2025-10-21
 */

module eth_mac_tx (
    // Clock and Reset
    input  wire         clk,
    input  wire         rst_n,

    // AXI-Stream Input Interface
    input  wire [7:0]   s_axis_tdata,
    input  wire         s_axis_tvalid,
    input  wire         s_axis_tlast,
    output reg          s_axis_tready,

    // GMII Interface
    output reg  [7:0]   gmii_txd,
    output reg          gmii_tx_en,
    output reg          gmii_tx_er,

    // Status
    output reg          tx_busy,
    output reg  [15:0]  tx_frame_count
);

    // State machine definitions
    localparam [3:0] ST_IDLE       = 4'd0;
    localparam [3:0] ST_PREAMBLE   = 4'd1;
    localparam [3:0] ST_SFD        = 4'd2;
    localparam [3:0] ST_DATA       = 4'd3;
    localparam [3:0] ST_PAD        = 4'd4;
    localparam [3:0] ST_FCS        = 4'd5;
    localparam [3:0] ST_IFG        = 4'd6;

    // Parameters
    localparam PREAMBLE_LEN = 7;       // 7 bytes of 0x55
    localparam MIN_FRAME_SIZE = 60;    // Minimum frame size (excluding FCS)
    localparam IFG_BYTES = 12;         // Inter-frame gap

    // State machine
    reg [3:0]  state;
    reg [3:0]  next_state;

    // Counters
    reg [3:0]  preamble_count;
    reg [15:0] byte_count;
    reg [3:0]  ifg_count;
    reg [1:0]  fcs_count;

    // Data buffering
    reg [7:0]  data_buf;
    reg        data_valid;

    // CRC signals
    reg        crc_en;
    reg        crc_clear;
    wire [31:0] crc_out;
    reg [31:0]  crc_latched;

    // Instantiate CRC32 module
    eth_mac_crc32 crc32_inst (
        .clk       (clk),
        .rst_n     (rst_n),
        .crc_en    (crc_en),
        .crc_clear (crc_clear),
        .data_in   (data_buf),
        .crc_out   (crc_out)
    );

    // State machine - next state logic
    always @(*) begin
        next_state = state;

        case (state)
            ST_IDLE: begin
                if (s_axis_tvalid) begin
                    next_state = ST_PREAMBLE;
                end
            end

            ST_PREAMBLE: begin
                if (preamble_count == PREAMBLE_LEN - 1) begin
                    next_state = ST_SFD;
                end
            end

            ST_SFD: begin
                next_state = ST_DATA;
            end

            ST_DATA: begin
                if (data_valid && s_axis_tlast) begin
                    if (byte_count < MIN_FRAME_SIZE) begin
                        next_state = ST_PAD;
                    end else begin
                        next_state = ST_FCS;
                    end
                end
            end

            ST_PAD: begin
                if (byte_count >= MIN_FRAME_SIZE) begin
                    next_state = ST_FCS;
                end
            end

            ST_FCS: begin
                if (fcs_count == 3) begin
                    next_state = ST_IFG;
                end
            end

            ST_IFG: begin
                if (ifg_count == IFG_BYTES - 1) begin
                    next_state = ST_IDLE;
                end
            end

            default: next_state = ST_IDLE;
        endcase
    end

    // State machine - state register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= ST_IDLE;
        end else begin
            state <= next_state;
        end
    end

    // Preamble counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            preamble_count <= 4'd0;
        end else begin
            if (state == ST_PREAMBLE) begin
                preamble_count <= preamble_count + 1'b1;
            end else begin
                preamble_count <= 4'd0;
            end
        end
    end

    // Byte counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            byte_count <= 16'd0;
        end else begin
            if (state == ST_IDLE) begin
                byte_count <= 16'd0;
            end else if (state == ST_DATA && data_valid) begin
                byte_count <= byte_count + 1'b1;
            end else if (state == ST_PAD) begin
                byte_count <= byte_count + 1'b1;
            end
        end
    end

    // IFG counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ifg_count <= 4'd0;
        end else begin
            if (state == ST_IFG) begin
                ifg_count <= ifg_count + 1'b1;
            end else begin
                ifg_count <= 4'd0;
            end
        end
    end

    // FCS counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fcs_count <= 2'd0;
        end else begin
            if (state == ST_FCS) begin
                fcs_count <= fcs_count + 1'b1;
            end else begin
                fcs_count <= 2'd0;
            end
        end
    end

    // Data buffering and ready signal
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_buf <= 8'd0;
            data_valid <= 1'b0;
            s_axis_tready <= 1'b0;
        end else begin
            if (state == ST_DATA && s_axis_tvalid) begin
                data_buf <= s_axis_tdata;
                data_valid <= 1'b1;
                s_axis_tready <= 1'b1;
            end else begin
                data_valid <= 1'b0;
                s_axis_tready <= 1'b0;
            end
        end
    end

    // CRC control
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_en <= 1'b0;
            crc_clear <= 1'b1;
        end else begin
            if (state == ST_IDLE || state == ST_PREAMBLE) begin
                crc_clear <= 1'b1;
                crc_en <= 1'b0;
            end else if (state == ST_DATA && data_valid) begin
                crc_clear <= 1'b0;
                crc_en <= 1'b1;
            end else if (state == ST_PAD) begin
                crc_clear <= 1'b0;
                crc_en <= 1'b1;
            end else begin
                crc_clear <= 1'b0;
                crc_en <= 1'b0;
            end
        end
    end

    // Latch CRC at end of data/pad
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_latched <= 32'd0;
        end else begin
            if ((state == ST_DATA && s_axis_tlast && byte_count >= MIN_FRAME_SIZE) ||
                (state == ST_PAD && byte_count >= MIN_FRAME_SIZE)) begin
                crc_latched <= crc_out;
            end
        end
    end

    // GMII output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gmii_txd <= 8'd0;
            gmii_tx_en <= 1'b0;
            gmii_tx_er <= 1'b0;
        end else begin
            gmii_tx_er <= 1'b0;  // Error signal not used

            case (state)
                ST_IDLE: begin
                    gmii_txd <= 8'd0;
                    gmii_tx_en <= 1'b0;
                end

                ST_PREAMBLE: begin
                    gmii_txd <= 8'h55;
                    gmii_tx_en <= 1'b1;
                end

                ST_SFD: begin
                    gmii_txd <= 8'hD5;
                    gmii_tx_en <= 1'b1;
                end

                ST_DATA: begin
                    if (data_valid) begin
                        gmii_txd <= data_buf;
                        gmii_tx_en <= 1'b1;
                    end else begin
                        gmii_txd <= 8'd0;
                        gmii_tx_en <= 1'b0;
                    end
                end

                ST_PAD: begin
                    gmii_txd <= 8'h00;
                    gmii_tx_en <= 1'b1;
                end

                ST_FCS: begin
                    // Send CRC bytes in LSB first order
                    case (fcs_count)
                        2'd0: gmii_txd <= crc_latched[7:0];
                        2'd1: gmii_txd <= crc_latched[15:8];
                        2'd2: gmii_txd <= crc_latched[23:16];
                        2'd3: gmii_txd <= crc_latched[31:24];
                    endcase
                    gmii_tx_en <= 1'b1;
                end

                ST_IFG: begin
                    gmii_txd <= 8'd0;
                    gmii_tx_en <= 1'b0;
                end

                default: begin
                    gmii_txd <= 8'd0;
                    gmii_tx_en <= 1'b0;
                end
            endcase
        end
    end

    // TX busy signal
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_busy <= 1'b0;
        end else begin
            tx_busy <= (state != ST_IDLE);
        end
    end

    // Frame counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_frame_count <= 16'd0;
        end else begin
            if (state == ST_FCS && fcs_count == 3) begin
                tx_frame_count <= tx_frame_count + 1'b1;
            end
        end
    end

endmodule
