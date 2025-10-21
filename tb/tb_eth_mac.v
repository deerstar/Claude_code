/*
 * Testbench for Ethernet MAC
 *
 * This testbench verifies the basic functionality of the Ethernet MAC
 * including TX and RX paths, CRC generation/checking, and loopback mode
 *
 * Author: Claude
 * Date: 2025-10-21
 */

`timescale 1ns / 1ps

module tb_eth_mac;

    // Parameters
    parameter CLK_PERIOD = 8;  // 125MHz for Gigabit Ethernet

    // Signals
    reg         clk;
    reg         rst_n;

    // TX AXI-Stream Interface
    reg  [7:0]  s_axis_tx_tdata;
    reg         s_axis_tx_tvalid;
    reg         s_axis_tx_tlast;
    wire        s_axis_tx_tready;

    // RX AXI-Stream Interface
    wire [7:0]  m_axis_rx_tdata;
    wire        m_axis_rx_tvalid;
    wire        m_axis_rx_tlast;
    reg         m_axis_rx_tready;

    // GMII Interface
    wire [7:0]  gmii_txd;
    wire        gmii_tx_en;
    wire        gmii_tx_er;
    reg  [7:0]  gmii_rxd;
    reg         gmii_rx_dv;
    reg         gmii_rx_er;

    // Status
    wire        tx_busy;
    wire        rx_busy;
    wire [15:0] tx_frame_count;
    wire [15:0] rx_frame_count;
    wire [15:0] rx_error_count;
    wire        rx_crc_error;

    // Test variables
    reg [7:0]   tx_test_data [0:99];
    reg [7:0]   rx_test_data [0:99];
    integer     tx_data_idx;
    integer     rx_data_idx;
    integer     i;

    // Instantiate DUT
    eth_mac dut (
        .clk                (clk),
        .rst_n              (rst_n),
        .s_axis_tx_tdata    (s_axis_tx_tdata),
        .s_axis_tx_tvalid   (s_axis_tx_tvalid),
        .s_axis_tx_tlast    (s_axis_tx_tlast),
        .s_axis_tx_tready   (s_axis_tx_tready),
        .m_axis_rx_tdata    (m_axis_rx_tdata),
        .m_axis_rx_tvalid   (m_axis_rx_tvalid),
        .m_axis_rx_tlast    (m_axis_rx_tlast),
        .m_axis_rx_tready   (m_axis_rx_tready),
        .gmii_txd           (gmii_txd),
        .gmii_tx_en         (gmii_tx_en),
        .gmii_tx_er         (gmii_tx_er),
        .gmii_rxd           (gmii_rxd),
        .gmii_rx_dv         (gmii_rx_dv),
        .gmii_rx_er         (gmii_rx_er),
        .tx_busy            (tx_busy),
        .rx_busy            (rx_busy),
        .tx_frame_count     (tx_frame_count),
        .rx_frame_count     (rx_frame_count),
        .rx_error_count     (rx_error_count),
        .rx_crc_error       (rx_crc_error)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Loopback connection (TX to RX)
    always @(posedge clk) begin
        gmii_rxd <= gmii_txd;
        gmii_rx_dv <= gmii_tx_en;
        gmii_rx_er <= gmii_tx_er;
    end

    // Initialize test data
    initial begin
        for (i = 0; i < 100; i = i + 1) begin
            tx_test_data[i] = i[7:0];
        end
    end

    // Main test sequence
    initial begin
        // Initialize signals
        rst_n = 0;
        s_axis_tx_tdata = 8'h00;
        s_axis_tx_tvalid = 0;
        s_axis_tx_tlast = 0;
        m_axis_rx_tready = 1;
        tx_data_idx = 0;
        rx_data_idx = 0;

        // Reset
        #(CLK_PERIOD * 10);
        rst_n = 1;
        #(CLK_PERIOD * 10);

        $display("========================================");
        $display("Ethernet MAC Testbench Starting");
        $display("========================================");

        // Test 1: Send a 64-byte frame
        $display("\nTest 1: Sending 64-byte frame...");
        send_frame(64);
        wait_tx_complete();
        #(CLK_PERIOD * 200);

        // Test 2: Send a 100-byte frame
        $display("\nTest 2: Sending 100-byte frame...");
        send_frame(100);
        wait_tx_complete();
        #(CLK_PERIOD * 200);

        // Test 3: Send minimum frame (46 bytes data + 14 bytes header + 4 bytes FCS = 64 bytes)
        $display("\nTest 3: Sending minimum frame (46 bytes)...");
        send_frame(46);
        wait_tx_complete();
        #(CLK_PERIOD * 200);

        // Display statistics
        #(CLK_PERIOD * 100);
        $display("\n========================================");
        $display("Test Results:");
        $display("========================================");
        $display("TX Frame Count: %d", tx_frame_count);
        $display("RX Frame Count: %d", rx_frame_count);
        $display("RX Error Count: %d", rx_error_count);
        $display("========================================");

        if (tx_frame_count == rx_frame_count && rx_error_count == 0) begin
            $display("TEST PASSED!");
        end else begin
            $display("TEST FAILED!");
        end

        #(CLK_PERIOD * 100);
        $finish;
    end

    // Task to send a frame
    task send_frame;
        input integer frame_size;
        integer j;
    begin
        $display("Sending frame of size %d bytes...", frame_size);

        for (j = 0; j < frame_size; j = j + 1) begin
            @(posedge clk);
            s_axis_tx_tdata = tx_test_data[j % 100];
            s_axis_tx_tvalid = 1;

            if (j == frame_size - 1) begin
                s_axis_tx_tlast = 1;
            end else begin
                s_axis_tx_tlast = 0;
            end

            // Wait for ready
            while (!s_axis_tx_tready) begin
                @(posedge clk);
            end
        end

        @(posedge clk);
        s_axis_tx_tvalid = 0;
        s_axis_tx_tlast = 0;
    end
    endtask

    // Task to wait for TX completion
    task wait_tx_complete;
    begin
        while (tx_busy) begin
            @(posedge clk);
        end
        $display("Frame transmission complete");
    end
    endtask

    // Monitor RX data
    always @(posedge clk) begin
        if (m_axis_rx_tvalid && m_axis_rx_tready) begin
            rx_test_data[rx_data_idx] = m_axis_rx_tdata;
            $display("RX[%d]: 0x%02X", rx_data_idx, m_axis_rx_tdata);
            rx_data_idx = rx_data_idx + 1;

            if (m_axis_rx_tlast) begin
                $display("Frame received (%d bytes)", rx_data_idx);
                rx_data_idx = 0;
            end
        end
    end

    // Timeout watchdog
    initial begin
        #(CLK_PERIOD * 100000);
        $display("ERROR: Simulation timeout!");
        $finish;
    end

    // Waveform dump
    initial begin
        $dumpfile("tb_eth_mac.vcd");
        $dumpvars(0, tb_eth_mac);
    end

endmodule
