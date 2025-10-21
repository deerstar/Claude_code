/*
 * Ethernet MAC Top Module
 *
 * This is the top-level module for the Ethernet MAC
 * Features:
 *   - Full-duplex operation
 *   - AXI-Stream interfaces for TX and RX
 *   - GMII interface to PHY
 *   - CRC generation and checking
 *   - Frame length validation
 *   - Status and statistics
 *
 * Author: Claude
 * Date: 2025-10-21
 */

module eth_mac (
    // Clock and Reset
    input  wire         clk,           // 125MHz for Gigabit, 25MHz for 100Mbps, 2.5MHz for 10Mbps
    input  wire         rst_n,

    // TX AXI-Stream Interface
    input  wire [7:0]   s_axis_tx_tdata,
    input  wire         s_axis_tx_tvalid,
    input  wire         s_axis_tx_tlast,
    output wire         s_axis_tx_tready,

    // RX AXI-Stream Interface
    output wire [7:0]   m_axis_rx_tdata,
    output wire         m_axis_rx_tvalid,
    output wire         m_axis_rx_tlast,
    input  wire         m_axis_rx_tready,

    // GMII Interface
    output wire [7:0]   gmii_txd,
    output wire         gmii_tx_en,
    output wire         gmii_tx_er,
    input  wire [7:0]   gmii_rxd,
    input  wire         gmii_rx_dv,
    input  wire         gmii_rx_er,

    // Status and Statistics
    output wire         tx_busy,
    output wire         rx_busy,
    output wire [15:0]  tx_frame_count,
    output wire [15:0]  rx_frame_count,
    output wire [15:0]  rx_error_count,
    output wire         rx_crc_error
);

    // Instantiate TX module
    eth_mac_tx tx_inst (
        .clk              (clk),
        .rst_n            (rst_n),
        .s_axis_tdata     (s_axis_tx_tdata),
        .s_axis_tvalid    (s_axis_tx_tvalid),
        .s_axis_tlast     (s_axis_tx_tlast),
        .s_axis_tready    (s_axis_tx_tready),
        .gmii_txd         (gmii_txd),
        .gmii_tx_en       (gmii_tx_en),
        .gmii_tx_er       (gmii_tx_er),
        .tx_busy          (tx_busy),
        .tx_frame_count   (tx_frame_count)
    );

    // Instantiate RX module
    eth_mac_rx rx_inst (
        .clk              (clk),
        .rst_n            (rst_n),
        .gmii_rxd         (gmii_rxd),
        .gmii_rx_dv       (gmii_rx_dv),
        .gmii_rx_er       (gmii_rx_er),
        .m_axis_tdata     (m_axis_rx_tdata),
        .m_axis_tvalid    (m_axis_rx_tvalid),
        .m_axis_tlast     (m_axis_rx_tlast),
        .m_axis_tready    (m_axis_rx_tready),
        .rx_busy          (rx_busy),
        .rx_frame_count   (rx_frame_count),
        .rx_error_count   (rx_error_count),
        .rx_crc_error     (rx_crc_error)
    );

endmodule
