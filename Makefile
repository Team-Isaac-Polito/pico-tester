# =========================
# Raspberry Pi Pico (RP2040) — Arduino-CLI Makefile
# Multi-sketch support: tester/ and tested/
#
# Usage examples:
#   make SKETCH=tester compile
#   make SKETCH=tester upload PORT=COM7
#   make SKETCH=tested upload PORT=COM8
#   make SKETCH=tester upload_bootsel DESTINATION=E:\
# =========================

# ------------- Selectable Sketch (default: tester)
SKETCH        ?= tester                    # or: tested
SKETCH_PATH    = $(CURDIR)/$(SKETCH)
SKETCH_NAME    = $(notdir $(SKETCH_PATH))

# ------------- Board Configuration
BOARD_FQBN    ?= rp2040:rp2040:rpipico

# ------------- Build Output Folders
BUILD_DIR      = $(CURDIR)/build/$(SKETCH)
OUTPUT_DIR     = $(BUILD_DIR)/output

# ------------- Optional
LIBS_DIR       = $(CURDIR)/lib
INCLUDE_DIR    = $(CURDIR)/include
LIBRARY_PATHS  = $(wildcard $(LIBS_DIR)/*/src)
LIBRARY_FLAGS  = $(addprefix --library ,$(LIBRARY_PATHS))
INCLUDE_PATHS  = $(INCLUDE_DIR) $(LIBRARY_PATHS)
CFLAGS        += $(foreach dir,$(INCLUDE_PATHS),-I$(dir))
CXXFLAGS      += $(foreach dir,$(INCLUDE_PATHS),-I$(dir))

define print_green
	@pwsh -NoProfile -Command "Write-Host '$1' -ForegroundColor Green"
endef
define print_red
	@pwsh -NoProfile -Command "Write-Host '$1' -ForegroundColor Red"
endef

SUCCESS_SYMBOL     = " Compilation completed successfully! "
ERROR_SYMBOL       = " Compilation error! "
COMPILATION_SYMBOL = " Compilation in progress... "

DESTINATION ?= E:\
PORT ?= $(shell arduino-cli board list | findstr "Raspberry Pi Pico" | for /f "tokens=1" %%a in ('more') do @echo %%a)

# -------- Build outputs (printed after compilation)
BUILD_OUTPUT_UF2 := $(OUTPUT_DIR)\$(SKETCH_NAME).ino.uf2
BUILD_OUTPUT_BIN := $(OUTPUT_DIR)\$(SKETCH_NAME).ino.bin

.PHONY: all compile compile_fast upload upload_bootsel clean clean_output clean_all monitor help auto_com_port port

.DEFAULT:
	@echo "Invalid command: '$@'"; \
	echo "Use 'make help' to see the list of available commands."; \
	$(MAKE) help

all: compile upload

# ------------- Compilation
compile: clean_output
	$(call print_green,$(COMPILATION_SYMBOL))
	@arduino-cli compile \
		--fqbn $(BOARD_FQBN) \
		--build-path "$(BUILD_DIR)" \
		--output-dir "$(OUTPUT_DIR)" \
		$(LIBRARY_FLAGS) \
		--build-property compiler.cpp.extra_flags="$(foreach dir,$(INCLUDE_PATHS),-I$(dir))" \
		--build-property compiler.c.extra_flags="$(foreach dir,$(INCLUDE_PATHS),-I$(dir))" \
		"$(SKETCH_PATH)"
	@if exist "$(BUILD_OUTPUT_UF2)" echo UF2: "$(BUILD_OUTPUT_UF2)"
	@if exist "$(BUILD_OUTPUT_BIN)" echo BIN: "$(BUILD_OUTPUT_BIN)"
	$(call print_green,$(SUCCESS_SYMBOL))

compile_fast:
	@arduino-cli compile --fqbn $(BOARD_FQBN) --build-path "$(BUILD_DIR)" --output-dir "$(OUTPUT_DIR)" "$(SKETCH_PATH)"
	@if exist "$(BUILD_OUTPUT_UF2)" echo UF2: "$(BUILD_OUTPUT_UF2)"
	@if exist "$(BUILD_OUTPUT_BIN)" echo BIN: "$(BUILD_OUTPUT_BIN)"
	$(call print_green,$(SUCCESS_SYMBOL))

# ------------- Upload (serial)
upload:
	@echo "Current COM port: $(PORT)"
	@if exist "$(OUTPUT_DIR)" ( \
		echo Uploading from "$(OUTPUT_DIR)"... & \
		arduino-cli upload -p $(PORT) --fqbn $(BOARD_FQBN) --input-dir "$(OUTPUT_DIR)" \
	) else ( \
		echo "Output folder not found. Run 'make compile' first." \
	)

# ------------- Upload .uf2 file in BOOTSEL mode
upload_bootsel:
	@if exist "$(BUILD_OUTPUT_UF2)" ( \
		echo "Copying UF2 to $(DESTINATION) ..." & \
		powershell -NoProfile -Command "Copy-Item '$(BUILD_OUTPUT_UF2)' -Destination '$(DESTINATION)' -Force" \
	) else ( \
		echo ".uf2 file not found. Run 'make compile' first." \
	)

# ------------- Cleaning
clean:
	@echo BUILD_DIR is: "$(BUILD_DIR)"
	@if exist "$(BUILD_DIR)" ( \
		echo Removing build folder... & rd /s /q "$(BUILD_DIR)" & echo Build folder removed. \
	) else ( \
		echo Build folder does not exist. \
	)

clean_output:
	@if exist "$(OUTPUT_DIR)" ( \
		echo Cleaning output folder... & rd /s /q "$(OUTPUT_DIR)" & echo Output folder cleaned. \
	) else ( \
		rem no output to clean \
	)

clean_all:
	@if exist "$(CURDIR)\build" ( \
		echo Removing ALL build artifacts... & rd /s /q "$(CURDIR)\build" & echo All build artifacts removed. \
	) else ( \
		echo No build folder to remove. \
	)

# ------------- Serial monitor
monitor:
	@arduino-cli monitor -p $(PORT) -c baudrate=115200

# ------------- Command guide
help:
	@echo "Available commands:"
	@echo "  make compile          - Compile current sketch (SKETCH=tester|tested)"
	@echo "  make compile_fast     - Quick compile (no extra include flags)"
	@echo "  make upload           - Upload over serial (set PORT=COMx)"
	@echo "  make upload_bootsel   - Copy .uf2 to BOOTSEL drive (DESTINATION=E:\\)"
	@echo "  make monitor          - Open serial monitor (115200)"
	@echo "  make all              - Compile + upload"
	@echo "  make clean            - Remove build folder of current sketch"
	@echo "  make clean_all        - Remove all build artifacts"
	@echo "  make help             - Show this guide"
	@echo "  make auto_com_port    - Try to auto-detect Pico COM port"
	@echo "  make port             - List all boards/ports"

# ------------- Print detected COM port
auto_com_port:
	@echo "Auto-detected COM port: $(PORT)"

# ------------- List all available COM ports
port:
	@echo "Boards/ports:"
	@arduino-cli board list
