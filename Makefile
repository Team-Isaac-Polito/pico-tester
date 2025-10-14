# Use Windows CMD for recipes
SHELL := cmd
.SHELLFLAGS := /C

# =========================
# Raspberry Pi Pico (RP2040) — Arduino-CLI Makefile
# Multi-sketch support: tester/ and tested/
#
# Examples:
#   make SKETCH=tester compile
#   make SKETCH=tester upload PORT=COM7
#   make SKETCH=tested  upload PORT=COM8
#   make SKETCH=tester upload_bootsel DESTINATION=E:\
# =========================

# -------- Sketch selection (default: tester)
SKETCH       ?= tester                 # or: tested
SKETCH_PATH   = $(CURDIR)/$(SKETCH)
SKETCH_NAME   = $(notdir $(SKETCH_PATH))

# -------- Board configuration
BOARD_FQBN   ?= rp2040:rp2040:rpipico

# -------- Build output folders (per sketch)
BUILD_DIR     = $(CURDIR)/build/$(SKETCH)
OUTPUT_DIR    = $(BUILD_DIR)/output

# -------- Optional local libs/includes
LIBS_DIR      = $(CURDIR)/lib
INCLUDE_DIR   = $(CURDIR)/include
LIBRARY_PATHS = $(wildcard $(LIBS_DIR)/*/src)
LIBRARY_FLAGS = $(addprefix --library ,$(LIBRARY_PATHS))
INCLUDE_PATHS = $(INCLUDE_DIR) $(LIBRARY_PATHS)
CFLAGS   += $(foreach dir, $(INCLUDE_PATHS), -I$(dir))
CXXFLAGS += $(foreach dir, $(INCLUDE_PATHS), -I$(dir))

SUCCESS_SYMBOL     = "======================================== Compilation completed successfully ========================================="
ERROR_SYMBOL       = "======================================== Compilation error! ========================================"
COMPILATION_SYMBOL = "======================================== Compilation in progress ========================================"

# Optional define (remove if unused)
MODULE_DEFINE ?= MK2_MOD1

# BOOTSEL drive and port autodetect (you said this works for you)
DESTINATION ?= D:\
PORT ?= $(shell arduino-cli board list | findstr "Raspberry Pi Pico" | for /f "tokens=1" %%a in ('more') do @echo %%a)

# Pretty messages (PowerShell just for color echo, called from CMD)
define print_green
	@powershell -NoProfile -Command "Write-Host '$(1)' -ForegroundColor Green"
endef
define print_red
	@powershell -NoProfile -Command "Write-Host '$(1)' -ForegroundColor Red"
endef

# -------- Build outputs (printed after compilation)
BUILD_OUTPUT_UF2 := $(OUTPUT_DIR)\$(SKETCH_NAME).ino.uf2
BUILD_OUTPUT_BIN := $(OUTPUT_DIR)\$(SKETCH_NAME).ino.bin

.PHONY: all compile compile_fast compile_all upload upload_bootsel clean clean_output clean_all monitor help auto_com_port port

.DEFAULT:
	@echo "Invalid command: '$@'"
	@echo "Use 'make help' to see the list of available commands."
	@$(MAKE) help

all: compile upload

# -----------------------
# Compilation (per sketch)
# -----------------------
compile: clean_output
	$(call print_green, $(COMPILATION_SYMBOL))
	@arduino-cli compile --fqbn $(BOARD_FQBN) --build-path "$(BUILD_DIR)" "$(SKETCH_PATH)" --output-dir "$(OUTPUT_DIR)" $(LIBRARY_FLAGS) \
		--build-property "compiler.cpp.extra_flags=$(foreach dir,$(INCLUDE_PATHS),-I$(dir)) -D$(MODULE_DEFINE)" \
		--build-property "compiler.c.extra_flags=$(foreach dir,$(INCLUDE_PATHS),-I$(dir)) -D$(MODULE_DEFINE)" && \
	@if exist "$(BUILD_OUTPUT_UF2)" echo UF2: "$(BUILD_OUTPUT_UF2)"
	@if exist "$(BUILD_OUTPUT_BIN)" echo BIN: "$(BUILD_OUTPUT_BIN)"
	$(call print_green, $(SUCCESS_SYMBOL))

# Fast compile (no include/defines aggregation)
compile_fast:
	@arduino-cli compile --fqbn $(BOARD_FQBN) --build-path "$(BUILD_DIR)" --output-dir "$(OUTPUT_DIR)" "$(SKETCH_PATH)"

# Build same sketch twice with different outputs/defines (optional)
compile_all:
	$(MAKE) compile BUILD_DIR=$(CURDIR)/build1 OUTPUT_DIR=$(CURDIR)/out_MK2_MOD1 MODULE_DEFINE=MK2_MOD1
	$(MAKE) compile BUILD_DIR=$(CURDIR)/build2 OUTPUT_DIR=$(CURDIR)/out_MK2_MOD2 MODULE_DEFINE=MK2_MOD2

# -----------------------
# Upload over serial
# -----------------------
upload:
	@echo "Check that you have entered the correct COM port. The current COM port is: $(PORT)"
	@if exist "$(OUTPUT_DIR)" ( \
		echo "Uploading build from: $(OUTPUT_DIR)" & \
		arduino-cli upload -p $(PORT) --fqbn $(BOARD_FQBN) --input-dir "$(OUTPUT_DIR)" \
	) else ( \
		echo "Output folder not found. Run 'make compile' before uploading the code." \
	)

# -----------------------
# Upload .uf2 via BOOTSEL
# -----------------------
upload_bootsel:
	@if exist "$(BUILD_OUTPUT_UF2)" ( \
		echo "Uploading .uf2 file to Raspberry Pi Pico (BOOTSEL)..." && \
		powershell -NoProfile -Command "Copy-Item '$(BUILD_OUTPUT_UF2)' -Destination '$(DESTINATION)' -Force" \
	) else ( \
		echo ".uf2 file not found. Run 'make compile' before uploading the code." \
	)

# -----------------------
# Cleaning
# -----------------------
clean:
	@echo BUILD_DIR is: "$(BUILD_DIR)"
	@if exist "$(BUILD_DIR)" ( \
		echo "Removing build folder..." & rd /s /q "$(BUILD_DIR)" & echo "Build folder removed." \
	) else ( \
		echo "Build folder does not exist." \
	)

clean_output:
	@echo "Cleaning output..."
	@if exist "$(OUTPUT_DIR)" ( \
		rd /s /q "$(OUTPUT_DIR)" & echo "Output folder cleaned." \
	) else ( \
		echo "No output to clean." \
	)

# -----------------------
# Serial monitor
# -----------------------
monitor:
	arduino-cli monitor -p $(PORT) -c baudrate=115200

# -----------------------
# Help / utilities
# -----------------------
help:
	@echo "Available commands:"
	@echo "  make compile          - Compile current sketch (SKETCH=tester|tested)"
	@echo "  make compile_fast     - Quick compile"
	@echo "  make compile_all      - Example: two outputs with different defines"
	@echo "  make upload           - Upload over serial (set PORT=COMx)"
	@echo "  make upload_bootsel   - Copy .uf2 to BOOTSEL drive (DESTINATION=E:\\)"
	@echo "  make monitor          - Open serial monitor (115200)"
	@echo "  make all              - Compile + upload"
	@echo "  make clean            - Remove build folder of current sketch"
	@echo "  make clean_output     - Remove only output folder of current sketch"
	@echo "  make help             - Show this guide"
	@echo "  make auto_com_port    - Print detected Pico COM port"
	@echo "  make port             - List all boards/ports"

auto_com_port:
	@echo "The automatically detected COM port is: $(PORT)"

port:
	@echo "Boards/ports:"
	@arduino-cli board list
