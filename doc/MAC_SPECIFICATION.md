# Ethernet MAC 模块规格说明

## 概述

这是一个用Verilog实现的以太网MAC（Media Access Control）控制器，支持全双工操作。该实现符合IEEE 802.3以太网标准。

## 特性

### 核心功能
- **全双工操作**: 支持同时发送和接收
- **GMII接口**: 与PHY芯片通信（支持1000Mbps，也可通过时钟调整支持100/10Mbps）
- **AXI-Stream接口**: 标准的数据流接口
- **CRC32**: 自动生成和校验帧校验序列（FCS）
- **帧处理**:
  - 自动添加前导码和帧起始定界符
  - 最小帧长度填充（64字节）
  - 帧间隙（IFG）处理
  - 帧长度验证

### 发送路径（TX）
- 自动插入7字节前导码（0x55）和1字节SFD（0xD5）
- 自动计算并添加4字节CRC32校验
- 支持最小帧长度填充（60字节数据 + 4字节FCS = 64字节）
- 12字节帧间隙处理
- 发送统计计数

### 接收路径（RX）
- 前导码和SFD检测
- CRC32校验
- 错误帧过滤
- 帧长度检查（64-1518字节）
- 接收统计和错误计数

## 模块层次结构

```
eth_mac (顶层)
├── eth_mac_tx (发送模块)
│   └── eth_mac_crc32 (CRC生成)
└── eth_mac_rx (接收模块)
    └── eth_mac_crc32 (CRC校验)
```

## 接口定义

### 时钟和复位
```verilog
input  wire  clk      // 125MHz (1000Mbps), 25MHz (100Mbps), 2.5MHz (10Mbps)
input  wire  rst_n    // 异步复位，低电平有效
```

### TX AXI-Stream接口
```verilog
input  wire [7:0]  s_axis_tx_tdata    // 发送数据
input  wire        s_axis_tx_tvalid   // 数据有效
input  wire        s_axis_tx_tlast    // 帧结束标志
output wire        s_axis_tx_tready   // 准备接收数据
```

### RX AXI-Stream接口
```verilog
output wire [7:0]  m_axis_rx_tdata    // 接收数据
output wire        m_axis_rx_tvalid   // 数据有效
output wire        m_axis_rx_tlast    // 帧结束标志
input  wire        m_axis_rx_tready   // 准备接收数据
```

### GMII接口（到PHY）
```verilog
// TX方向
output wire [7:0]  gmii_txd      // 发送数据
output wire        gmii_tx_en    // 发送使能
output wire        gmii_tx_er    // 发送错误（未使用）

// RX方向
input  wire [7:0]  gmii_rxd      // 接收数据
input  wire        gmii_rx_dv    // 接收数据有效
input  wire        gmii_rx_er    // 接收错误
```

### 状态和统计
```verilog
output wire        tx_busy           // 发送忙
output wire        rx_busy           // 接收忙
output wire [15:0] tx_frame_count    // 发送帧计数
output wire [15:0] rx_frame_count    // 接收帧计数（仅有效帧）
output wire [15:0] rx_error_count    // 接收错误帧计数
output wire        rx_crc_error      // CRC错误标志
```

## 使用示例

### 发送一帧数据

```verilog
// 1. 等待MAC空闲
while (tx_busy) @(posedge clk);

// 2. 发送数据字节
for (i = 0; i < frame_length; i = i + 1) begin
    @(posedge clk);
    s_axis_tx_tdata = data[i];
    s_axis_tx_tvalid = 1;
    s_axis_tx_tlast = (i == frame_length - 1);

    // 等待ready信号
    while (!s_axis_tx_tready) @(posedge clk);
end

// 3. 结束传输
@(posedge clk);
s_axis_tx_tvalid = 0;
s_axis_tx_tlast = 0;
```

### 接收一帧数据

```verilog
// 设置ready信号
m_axis_rx_tready = 1;

// 监听接收数据
always @(posedge clk) begin
    if (m_axis_rx_tvalid && m_axis_rx_tready) begin
        rx_buffer[rx_index] = m_axis_rx_tdata;
        rx_index = rx_index + 1;

        if (m_axis_rx_tlast) begin
            // 帧接收完成
            process_frame(rx_buffer, rx_index);
            rx_index = 0;
        end
    end
end
```

## 以太网帧格式

MAC处理的完整帧格式：

```
+----------+-----+----------------+------+-----+
| Preamble | SFD |  MAC Frame     | FCS  | IFG |
|  (7B)    | (1B)| (46-1500 Bytes)| (4B) |(12B)|
+----------+-----+----------------+------+-----+
   0x55×7   0xD5   用户数据         CRC32  空闲

MAC Frame包括：
- 目标MAC地址 (6B)
- 源MAC地址 (6B)
- 类型/长度 (2B)
- 数据 (46-1500B)
```

注意：
- 前导码、SFD、FCS和IFG由MAC自动处理
- 用户只需提供MAC帧数据（包含地址和数据）
- 如果数据少于46字节，MAC会自动填充到最小帧长度

## 时序要求

### TX时序
- 数据建立时间：在时钟上升沿前
- 帧间最小间隔：12字节时间
- 最大帧长度：1518字节（不含前导码和SFD）

### RX时序
- 数据捕获：时钟上升沿
- CRC校验延迟：1个时钟周期
- FIFO深度：1536字节（支持最大帧）

## 参数配置

模块中的关键参数：

```verilog
// eth_mac_tx.v
localparam PREAMBLE_LEN = 7;       // 前导码长度
localparam MIN_FRAME_SIZE = 60;    // 最小帧大小（不含FCS）
localparam IFG_BYTES = 12;         // 帧间隙

// eth_mac_rx.v
localparam MIN_FRAME_SIZE = 64;    // 最小帧大小（含FCS）
localparam MAX_FRAME_SIZE = 1518;  // 最大帧大小（含FCS）
```

## 资源使用（预估）

对于Xilinx 7系列FPGA：
- LUTs: ~2000
- FFs: ~1500
- BRAM: 1个 (用于RX FIFO)

实际资源使用取决于综合工具和优化选项。

## 已知限制

1. 不支持半双工和冲突检测
2. 不支持流量控制（PAUSE帧）
3. 不支持VLAN标签处理
4. 不支持巨型帧（>1518字节）
5. RX FIFO固定大小，不支持背压

## 测试

测试文件位于 `tb/tb_eth_mac.v`

运行仿真：
```bash
# 使用Icarus Verilog
iverilog -o sim tb/tb_eth_mac.v rtl/mac/*.v
vvp sim

# 使用ModelSim
vlog rtl/mac/*.v tb/tb_eth_mac.v
vsim -c tb_eth_mac -do "run -all"
```

## 版本历史

- v1.0 (2025-10-21): 初始版本
  - 基本TX/RX功能
  - CRC32生成和校验
  - AXI-Stream和GMII接口

## 作者

Claude - 2025

## 许可证

开源使用，遵循MIT许可证。
