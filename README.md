# Ethernet MAC Controller (Verilog Implementation)

这是一个用Verilog实现的完整以太网MAC（Media Access Control）控制器，符合IEEE 802.3标准。

## 项目简介

本项目提供了一个功能完整、易于集成的以太网MAC IP核，适用于FPGA设计。支持千兆/百兆/十兆以太网，采用标准的GMII接口连接PHY芯片，以及AXI-Stream接口连接上层协议栈。

## 主要特性

- ✅ **全双工操作** - 支持同时发送和接收
- ✅ **多速率支持** - 1000/100/10 Mbps（通过时钟频率选择）
- ✅ **标准接口** - GMII接口（连接PHY）+ AXI-Stream接口（连接上层）
- ✅ **自动CRC处理** - CRC32生成和校验
- ✅ **完整帧处理** - 前导码、SFD、最小帧填充、帧间隙
- ✅ **错误检测** - CRC校验、帧长度检查
- ✅ **统计功能** - 发送/接收帧计数、错误计数

## 目录结构

```
.
├── rtl/                    # RTL源代码
│   └── mac/                # MAC模块
│       ├── eth_mac.v       # 顶层MAC模块
│       ├── eth_mac_tx.v    # 发送模块
│       ├── eth_mac_rx.v    # 接收模块
│       └── eth_mac_crc32.v # CRC32计算模块
├── tb/                     # 测试文件
│   └── tb_eth_mac.v        # MAC模块测试bench
├── doc/                    # 文档
│   └── MAC_SPECIFICATION.md # 详细规格说明
├── Makefile                # 仿真Makefile
└── README.md               # 本文件
```

## 快速开始

### 1. 克隆仓库

```bash
git clone <repository-url>
cd Claude_code
```

### 2. 运行仿真

使用Icarus Verilog（推荐用于快速验证）：

```bash
make iverilog
```

查看波形：

```bash
make wave
```

使用其他仿真器：

```bash
make modelsim   # ModelSim/QuestaSim
make xsim       # Vivado Simulator
```

### 3. 代码检查

```bash
make lint       # 使用Verilator进行代码检查
```

### 4. 清理

```bash
make clean
```

## 模块接口

### 顶层模块：eth_mac

```verilog
module eth_mac (
    // 时钟和复位
    input  wire         clk,           // 125MHz (1G), 25MHz (100M), 2.5MHz (10M)
    input  wire         rst_n,         // 异步复位，低电平有效

    // TX AXI-Stream接口
    input  wire [7:0]   s_axis_tx_tdata,
    input  wire         s_axis_tx_tvalid,
    input  wire         s_axis_tx_tlast,
    output wire         s_axis_tx_tready,

    // RX AXI-Stream接口
    output wire [7:0]   m_axis_rx_tdata,
    output wire         m_axis_rx_tvalid,
    output wire         m_axis_rx_tlast,
    input  wire         m_axis_rx_tready,

    // GMII接口
    output wire [7:0]   gmii_txd,
    output wire         gmii_tx_en,
    output wire         gmii_tx_er,
    input  wire [7:0]   gmii_rxd,
    input  wire         gmii_rx_dv,
    input  wire         gmii_rx_er,

    // 状态和统计
    output wire         tx_busy,
    output wire         rx_busy,
    output wire [15:0]  tx_frame_count,
    output wire [15:0]  rx_frame_count,
    output wire [15:0]  rx_error_count,
    output wire         rx_crc_error
);
```

## 使用示例

### 发送以太网帧

```verilog
// 准备发送64字节的数据
reg [7:0] tx_data [0:63];
integer i;

initial begin
    // 初始化数据
    for (i = 0; i < 64; i = i + 1) begin
        tx_data[i] = i;
    end

    // 等待复位
    wait(rst_n);
    @(posedge clk);

    // 发送帧
    for (i = 0; i < 64; i = i + 1) begin
        @(posedge clk);
        s_axis_tx_tdata = tx_data[i];
        s_axis_tx_tvalid = 1;
        s_axis_tx_tlast = (i == 63);

        // 等待ready
        while (!s_axis_tx_tready) @(posedge clk);
    end

    @(posedge clk);
    s_axis_tx_tvalid = 0;
    s_axis_tx_tlast = 0;
end
```

### 接收以太网帧

```verilog
// 接收数据
reg [7:0] rx_buffer [0:1517];
integer rx_idx;

initial begin
    m_axis_rx_tready = 1;
    rx_idx = 0;
end

always @(posedge clk) begin
    if (m_axis_rx_tvalid && m_axis_rx_tready) begin
        rx_buffer[rx_idx] = m_axis_rx_tdata;
        rx_idx = rx_idx + 1;

        if (m_axis_rx_tlast) begin
            $display("Received frame with %d bytes", rx_idx);
            rx_idx = 0;
        end
    end
end
```

## 性能指标

| 参数 | 值 |
|------|-----|
| 最大吞吐量 | 1000 Mbps (全双工) |
| 最小帧间隙 | 96 ns @ 1Gbps (12字节) |
| 最小帧长度 | 64 字节（含FCS） |
| 最大帧长度 | 1518 字节（含FCS） |
| CRC多项式 | 0x04C11DB7 (IEEE 802.3) |
| 延迟 | < 20 时钟周期 |

## FPGA资源使用

基于Xilinx 7系列FPGA的综合结果（预估）：

- **查找表(LUTs)**: ~2000
- **触发器(FFs)**: ~1500
- **Block RAM**: 1个（用于RX FIFO）
- **最大频率**: >200 MHz

## 集成到FPGA设计

1. 将 `rtl/mac/` 目录下的所有文件添加到项目
2. 实例化顶层模块 `eth_mac`
3. 连接125MHz时钟（千兆）或25MHz时钟（百兆）
4. 连接GMII接口到PHY芯片
5. 连接AXI-Stream接口到你的协议栈

示例约束（Xilinx）：

```tcl
# GMII时钟
create_clock -period 8.000 [get_ports gmii_rx_clk]
create_clock -period 8.000 [get_ports gmii_tx_clk]

# GMII接口
set_property IOSTANDARD LVCMOS33 [get_ports gmii_*]
```

## 文档

详细的技术文档请参阅：

- [MAC模块规格说明](doc/MAC_SPECIFICATION.md) - 完整的技术规格和使用指南

## 测试

项目包含完整的testbench：

- `tb/tb_eth_mac.v` - 基本功能测试，包括回环测试

测试覆盖：
- ✅ TX路径：前导码、数据、FCS、IFG
- ✅ RX路径：帧接收、CRC校验
- ✅ 最小帧长度填充
- ✅ 回环测试
- ✅ 统计计数器

## 已知限制

当前版本不支持以下功能（可在未来版本中添加）：

- 半双工模式和CSMA/CD
- 流量控制（PAUSE帧）
- VLAN标签处理
- 巨型帧（>1518字节）
- 自动协商

## 版本历史

### v1.0 (2025-10-21)
- 初始发布
- 支持全双工TX/RX
- CRC32生成和校验
- GMII和AXI-Stream接口
- 基本统计功能

## 贡献

欢迎提交Issue和Pull Request！

## 许可证

MIT License - 详见LICENSE文件

## 作者

Claude - 2025

---

**注意**: 本项目仅用于教育和研究目的。在生产环境中使用前请进行充分的测试和验证。
