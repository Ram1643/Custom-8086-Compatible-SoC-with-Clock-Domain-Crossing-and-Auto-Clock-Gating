# ============================================================================
# Makefile for 8086-like SoC Compilation, Simulation, and Verdi Debugging
# ============================================================================

# --- Tool Definitions ---
ASM=perl
COMPILER = vcs
SIMULATOR = ./simv -cm line+cond+branch+tgl -assert success
VIEWER = verdi

# --- Project Variables ---
# Change RTL_SRC if your code is split across multiple files 
# (e.g., RTL_SRC = src/*.v tb/*.v)
RTL_SRC = -f ../../rtl/rtl.flist ../tb/tb.sv 
ORIG_MODULE = ../sw/hex.pl
SOURCE_MODULE=../sw/test1.asm

FSDB_FILE = soc_int.fsdb

# --- Compilation Options ---
# -full64: Compile for 64-bit architecture
# -sverilog: Enable SystemVerilog support
# -kdb: Generate Knowledge Database (Required for Verdi)
# -debug_access+all: Enable full debug access for FSDB dumping
# -timescale: Set default timescale
VCS_FLAGS = -full64 -sverilog -timescale=1ns/1ps -kdb -lca -debug_access+all -timescale=1ns/1ps -l compile.log -cm line+cond+branch+tgl

# --- Simulation Options ---
SIM_FLAGS = -l sim.log

# ============================================================================
# Targets
# ============================================================================

.PHONY: all compile sim verdi clean

# Default target: Compiles and runs the simulation
all:asm compile sim 
asm:
	@echo "========================================================"
	@echo "==> asm compilation..."
	@echo "========================================================"
	$(ASM) $(ORIG_MODULE) $(SOURCE_MODULE) 

# 1. Compile the RTL and Testbench
compile:
	@echo "========================================================"
	@echo "==> Compiling Design..."
	@echo "========================================================"
	$(COMPILER) $(VCS_FLAGS) $(RTL_SRC) 

# 2. Run the Simulation
sim: compile
	@echo "========================================================"
	@echo "==> Running Simulation..."
	@echo "========================================================"
	$(SIMULATOR) $(SIM_FLAGS)

# 3. Open Verdi for Waveform Debugging
verdi:
	@echo "========================================================"
	@echo "==> Launching Verdi..."
	@echo "========================================================"
	$(VIEWER) -ssf $(FSDB_FILE) -nologo &

# 4. Clean up generated artifacts
clean:
	@echo "========================================================"
	@echo "==> Cleaning up workspace..."
	@echo "========================================================"
	rm -rf csrc simv simv.daidir *.log *.fsdb *.key novas.* verdiLog *.conf
