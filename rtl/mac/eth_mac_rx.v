/*
 * Ethernet MAC Receive Module
 *
 * This module implements the Ethernet MAC receive path
 * Features:
 *   - GMII input interface
 *   - AXI-Stream output interface
 *   - Preamble and SFD detection
 *   - CRC32 (FCS) checking
 *   - Frame error detection
 *   - Frame length checking
 *
 * Author: Claude
 * Date: 2025-10-21
 */

module eth_mac_rx (
    // Clock and Reset
    input  wire         clk,
    input  wire         rst_n,

    // GMII Interface
    input  wire [7:0]   gmii_rxd,
    input  wire         gmii_rx_dv,
    input  wire         gmii_rx_er,

    // AXI-Stream Output Interface
    output reg  [7:0]   m_axis_tdata,
    output reg          m_axis_tvalid,
    output reg          m_axis_tlast,
    input  wire         m_axis_tready,

    // Status
    output reg          rx_busy,
    output reg  [15:0]  rx_frame_count,
    output reg  [15:0]  rx_error_count,
    output reg          rx_crc_error
);

    // State machine definitions
    localparam [2:0] ST_IDLE       = 3'd0;
    localparam [2:0] ST_PREAMBLE   = 3'd1;
    localparam [2:0] ST_SFD        = 3'd2;
    localparam [2:0] ST_DATA       = 3'd3;
    localparam [2:0] ST_FCS        = 3'd4;
    localparam [2:0] ST_GOOD       = 3'd5;
    localparam [2:0] ST_ERROR      = 3'd6;

    // Parameters
    localparam MIN_FRAME_SIZE = 64;    // Minimum frame size (including FCS)
    localparam MAX_FRAME_SIZE = 1518;  // Maximum frame size (including FCS)

    // State machine
    reg [2:0]  state;
    reg [2:0]  next_state;

    // Counters
    reg [15:0] byte_count;
    reg [1:0]  fcs_count;

    // Data buffering - FIFO for frame data
    reg [7:0]  data_fifo [0:1535];  // Buffer for max frame size
    reg [10:0] fifo_wr_ptr;
    reg [10:0] fifo_rd_ptr;
    reg [10:0] frame_length;
    reg        frame_valid;

    // CRC signals
    reg        crc_en;
    reg        crc_clear;
    wire [31:0] crc_out;
    reg [31:0]  received_fcs;

    // GMII input registers
    reg [7:0]  gmii_rxd_r;
    reg        gmii_rx_dv_r;
    reg        gmii_rx_er_r;

    // Instantiate CRC32 module
    eth_mac_crc32 crc32_inst (
        .clk       (clk),
        .rst_n     (rst_n),
        .crc_en    (crc_en),
        .crc_clear (crc_clear),
        .data_in   (gmii_rxd_r),
        .crc_out   (crc_out)
    );

    // Register GMII inputs for timing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gmii_rxd_r <= 8'd0;
            gmii_rx_dv_r <= 1'b0;
            gmii_rx_er_r <= 1'b0;
        end else begin
            gmii_rxd_r <= gmii_rxd;
            gmii_rx_dv_r <= gmii_rx_dv;
            gmii_rx_er_r <= gmii_rx_er;
        end
    end

    // State machine - next state logic
    always @(*) begin
        next_state = state;

        case (state)
            ST_IDLE: begin
                if (gmii_rx_dv_r && gmii_rxd_r == 8'h55) begin
                    next_state = ST_PREAMBLE;
                end
            end

            ST_PREAMBLE: begin
                if (!gmii_rx_dv_r || gmii_rx_er_r) begin
                    next_state = ST_IDLE;
                end else if (gmii_rxd_r == 8'hD5) begin
                    next_state = ST_SFD;
                end else if (gmii_rxd_r != 8'h55) begin
                    next_state = ST_IDLE;
                end
            end

            ST_SFD: begin
                if (!gmii_rx_dv_r || gmii_rx_er_r) begin
                    next_state = ST_ERROR;
                end else begin
                    next_state = ST_DATA;
                end
            end

            ST_DATA: begin
                if (gmii_rx_er_r) begin
                    next_state = ST_ERROR;
                end else if (!gmii_rx_dv_r) begin
                    if (byte_count >= MIN_FRAME_SIZE && byte_count <= MAX_FRAME_SIZE) begin
                        next_state = ST_GOOD;
                    end else begin
                        next_state = ST_ERROR;
                    end
                end else if (byte_count >= MAX_FRAME_SIZE) begin
                    next_state = ST_ERROR;
                end
            end

            ST_GOOD: begin
                next_state = ST_IDLE;
            end

            ST_ERROR: begin
                next_state = ST_IDLE;
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

    // Byte counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            byte_count <= 16'd0;
        end else begin
            if (state == ST_IDLE || state == ST_PREAMBLE || state == ST_SFD) begin
                byte_count <= 16'd0;
            end else if (state == ST_DATA && gmii_rx_dv_r) begin
                byte_count <= byte_count + 1'b1;
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
            end else if (state == ST_DATA && gmii_rx_dv_r) begin
                crc_clear <= 1'b0;
                crc_en <= 1'b1;
            end else begin
                crc_clear <= 1'b0;
                crc_en <= 1'b0;
            end
        end
    end

    // Write data to FIFO
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fifo_wr_ptr <= 11'd0;
            frame_length <= 11'd0;
        end else begin
            if (state == ST_IDLE || state == ST_PREAMBLE || state == ST_SFD) begin
                fifo_wr_ptr <= 11'd0;
            end else if (state == ST_DATA && gmii_rx_dv_r) begin
                data_fifo[fifo_wr_ptr] <= gmii_rxd_r;
                fifo_wr_ptr <= fifo_wr_ptr + 1'b1;
            end else if (state == ST_GOOD) begin
                // Store frame length (excluding 4-byte FCS)
                frame_length <= fifo_wr_ptr - 11'd4;
            end
        end
    end

    // Frame valid flag and CRC checking
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            frame_valid <= 1'b0;
            rx_crc_error <= 1'b0;
        end else begin
            if (state == ST_GOOD) begin
                // Check if CRC is correct
                // For correct frames, CRC should be 0xC704DD7B (magic number)
                if (crc_out == 32'hC704DD7B) begin
                    frame_valid <= 1'b1;
                    rx_crc_error <= 1'b0;
                end else begin
                    frame_valid <= 1'b0;
                    rx_crc_error <= 1'b1;
                end
            end else begin
                frame_valid <= 1'b0;
                if (state == ST_IDLE) begin
                    rx_crc_error <= 1'b0;
                end
            end
        end
    end

    // Read from FIFO and output via AXI-Stream
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fifo_rd_ptr <= 11'd0;
            m_axis_tdata <= 8'd0;
            m_axis_tvalid <= 1'b0;
            m_axis_tlast <= 1'b0;
        end else begin
            if (state == ST_IDLE) begin
                fifo_rd_ptr <= 11'd0;
                m_axis_tvalid <= 1'b0;
                m_axis_tlast <= 1'b0;
            end else if (frame_valid && fifo_rd_ptr < frame_length) begin
                if (!m_axis_tvalid || m_axis_tready) begin
                    m_axis_tdata <= data_fifo[fifo_rd_ptr];
                    m_axis_tvalid <= 1'b1;

                    if (fifo_rd_ptr == frame_length - 1) begin
                        m_axis_tlast <= 1'b1;
                    end else begin
                        m_axis_tlast <= 1'b0;
                    end

                    fifo_rd_ptr <= fifo_rd_ptr + 1'b1;
                end
            end else if (m_axis_tvalid && m_axis_tready && m_axis_tlast) begin
                m_axis_tvalid <= 1'b0;
                m_axis_tlast <= 1'b0;
            end
        end
    end

    // RX busy signal
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_busy <= 1'b0;
        end else begin
            rx_busy <= (state != ST_IDLE);
        end
    end

    // Frame counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_frame_count <= 16'd0;
        end else begin
            if (state == ST_GOOD && frame_valid) begin
                rx_frame_count <= rx_frame_count + 1'b1;
            end
        end
    end

    // Error counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_error_count <= 16'd0;
        end else begin
            if (state == ST_ERROR || (state == ST_GOOD && !frame_valid)) begin
                rx_error_count <= rx_error_count + 1'b1;
            end
        end
    end

endmodule
