# Makefile for Ethernet MAC Simulation
#
# Supports multiple simulators:
#   - Icarus Verilog (iverilog)
#   - ModelSim/QuestaSim
#   - Vivado Simulator (xsim)

# Project settings
PROJECT = eth_mac
RTL_DIR = rtl/mac
TB_DIR = tb
SIM_DIR = sim

# Source files
RTL_SRCS = $(RTL_DIR)/eth_mac_crc32.v \
           $(RTL_DIR)/eth_mac_tx.v \
           $(RTL_DIR)/eth_mac_rx.v \
           $(RTL_DIR)/eth_mac.v

TB_SRCS = $(TB_DIR)/tb_eth_mac.v

ALL_SRCS = $(RTL_SRCS) $(TB_SRCS)

# Default target
.PHONY: all
all: iverilog

# Icarus Verilog simulation
.PHONY: iverilog
iverilog: $(ALL_SRCS)
	@echo "========================================="
	@echo "Running Icarus Verilog simulation..."
	@echo "========================================="
	@mkdir -p $(SIM_DIR)
	iverilog -o $(SIM_DIR)/$(PROJECT).vvp $(ALL_SRCS)
	cd $(SIM_DIR) && vvp $(PROJECT).vvp
	@echo "Simulation complete. Waveform: $(SIM_DIR)/tb_eth_mac.vcd"

# View waveform with GTKWave
.PHONY: wave
wave:
	@if [ -f $(SIM_DIR)/tb_eth_mac.vcd ]; then \
		gtkwave $(SIM_DIR)/tb_eth_mac.vcd & \
	else \
		echo "No waveform file found. Run 'make iverilog' first."; \
	fi

# ModelSim/QuestaSim simulation
.PHONY: modelsim
modelsim: $(ALL_SRCS)
	@echo "========================================="
	@echo "Running ModelSim simulation..."
	@echo "========================================="
	@mkdir -p $(SIM_DIR)
	cd $(SIM_DIR) && vlib work
	cd $(SIM_DIR) && vlog -work work $(addprefix ../,$(ALL_SRCS))
	cd $(SIM_DIR) && vsim -c -do "run -all; quit" tb_eth_mac

# Vivado Simulator
.PHONY: xsim
xsim: $(ALL_SRCS)
	@echo "========================================="
	@echo "Running Vivado Simulator..."
	@echo "========================================="
	@mkdir -p $(SIM_DIR)
	cd $(SIM_DIR) && xvlog $(addprefix ../,$(ALL_SRCS))
	cd $(SIM_DIR) && xelab tb_eth_mac -debug typical
	cd $(SIM_DIR) && xsim tb_eth_mac -runall

# Verilator lint check
.PHONY: lint
lint: $(RTL_SRCS)
	@echo "========================================="
	@echo "Running Verilator lint check..."
	@echo "========================================="
	verilator --lint-only -Wall $(RTL_SRCS)

# Clean generated files
.PHONY: clean
clean:
	@echo "Cleaning generated files..."
	rm -rf $(SIM_DIR)
	rm -f *.vcd *.vvp *.log
	@echo "Clean complete."

# Help
.PHONY: help
help:
	@echo "Ethernet MAC Makefile"
	@echo "====================="
	@echo ""
	@echo "Available targets:"
	@echo "  all        - Run default simulation (Icarus Verilog)"
	@echo "  iverilog   - Run Icarus Verilog simulation"
	@echo "  wave       - Open waveform viewer (GTKWave)"
	@echo "  modelsim   - Run ModelSim simulation"
	@echo "  xsim       - Run Vivado Simulator"
	@echo "  lint       - Run Verilator lint check"
	@echo "  clean      - Remove generated files"
	@echo "  help       - Show this help message"
	@echo ""
	@echo "Examples:"
	@echo "  make iverilog    # Run simulation"
	@echo "  make wave        # View waveforms"
	@echo "  make clean       # Clean up"
