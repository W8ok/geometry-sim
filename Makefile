# Sources
SRCS = src/main.c

# Assets
ASSETS = assets/

# Output directories
PROJECT_NAME = get_in_the_hole
OUT_DIR = executables
LINUX_DIR = $(OUT_DIR)/$(PROJECT_NAME)-linux
LINUX_ZIP = $(OUT_DIR)/$(PROJECT_NAME)-linux.tar.gz
WINDOWS_DIR = $(OUT_DIR)/$(PROJECT_NAME)-windows
WINDOWS_ZIP = $(OUT_DIR)/$(PROJECT_NAME)-windows.zip

# Binary names inside folders
LINUX_BIN = $(LINUX_DIR)/$(PROJECT_NAME).x86_64
WINDOWS_BIN = $(WINDOWS_DIR)/$(PROJECT_NAME).exe

# Rust Config
RUST_DIR = src/rustcore
RUST_TARGET_LINUX = $(RUST_DIR)/target/release
RUST_TARGET_WIN = $(RUST_DIR)/target/x86_64-pc-windows-gnu/release
RUST_LIB_LINUX = $(RUST_TARGET_LINUX)/librustcore.so
RUST_LIB_WIN = $(RUST_TARGET_WIN)/rustcore.dll

# Linux Config
CC_LINUX = gcc
CFLAGS_LINUX = -std=c23 -Wall -Wextra -Isrc -O2
LDFLAGS_LINUX = -Wl,-rpath,'$$ORIGIN' -L$(RUST_TARGET_LINUX) -lrustcore -lSDL3 -lGL -lm -lpthread -ldl -s
OBJS_LINUX = $(SRCS:src/%.c=obj/linux/%.o)

# Windows Config
CC_WIN = x86_64-w64-mingw32-gcc
CFLAGS_WIN = -std=c11 -Wall -Wextra -Isrc -Iwinlibs/include
LDFLAGS_WIN = -Lwinlibs/lib -L$(RUST_TARGET_WIN) -lrustcore -lSDL3 -lopengl32 -lm -lpthread -lwinmm -lgdi32
OBJS_WIN = $(SRCS:src/%.c=obj/win/%.o)

# Simple Development Build
DEV_BIN = $(PROJECT_NAME)
DEV_OBJS = $(SRCS:src/%.c=obj/dev/%.o)

.DEFAULT_GOAL := clean-make

linux: $(LINUX_ZIP)
windows: $(WINDOWS_ZIP)
all: linux windows

# Rust Build Chain
rust-linux:
	@echo "Building Rust (Linux)..."
	cd $(RUST_DIR) && cargo build --release

rust-windows:
	@echo "Building Rust (Windows)..."
	cd $(RUST_DIR) && cargo build --release --target x86_64-pc-windows-gnu

# Development Build
$(DEV_BIN): rust-linux $(DEV_OBJS)
	$(CC_LINUX) $(CFLAGS_LINUX) -o $@ $(DEV_OBJS) -L$(RUST_TARGET_LINUX) -lrustcore $(LDFLAGS_LINUX)
	cp $(RUST_LIB_LINUX) ./

obj/dev/%.o: src/%.c
	mkdir -p $(@D)
	$(CC_LINUX) $(CFLAGS_LINUX) -c $< -o $@

# Linux Build Chain
$(LINUX_BIN): rust-linux $(OBJS_LINUX)
	@echo "Building Linux binary..."
	mkdir -p $(LINUX_DIR)
	$(CC_LINUX) $(CFLAGS_LINUX) -o $@ $(OBJS_LINUX) $(LDFLAGS_LINUX)

obj/linux/%.o: src/%.c
	mkdir -p $(@D)
	$(CC_LINUX) $(CFLAGS_LINUX) -c $< -o $@

$(LINUX_DIR): $(LINUX_BIN)
	@echo "Copying Linux libraries..."
	cp /usr/lib/libSDL3.so $(LINUX_DIR)/ 2>/dev/null || echo "SDL3 not found in /usr/lib/"
	cp $(RUST_LIB_LINUX) $(LINUX_DIR)/ 2>/dev/null || echo "Rust .so not found"
	cp /usr/lib/libgcc_s.so.1 $(LINUX_DIR)/ 2>/dev/null || true
	@echo "Copying Linux assets..."
	cp -r $(ASSETS) $(LINUX_DIR) 2>/dev/null || true

$(LINUX_ZIP): $(LINUX_DIR)
	cd $(OUT_DIR) && tar -czf $(PROJECT_NAME)-linux.tar.gz $(PROJECT_NAME)-linux/
	@echo "Linux archive: $(LINUX_ZIP)"

# Windows Build Chain
$(WINDOWS_BIN): rust-windows $(OBJS_WIN)
	@echo "Building Windows binary..."
	mkdir -p $(WINDOWS_DIR)
	$(CC_WIN) $(CFLAGS_WIN) -o $@ $(OBJS_WIN) $(LDFLAGS_WIN)

obj/win/%.o: src/%.c
	mkdir -p $(@D)
	$(CC_WIN) $(CFLAGS_WIN) -c $< -o $@

$(WINDOWS_DIR): $(WINDOWS_BIN)
	@echo "Copying Windows libraries..."
	cp winlibs/lib/SDL3.dll $(WINDOWS_DIR)/ 2>/dev/null || echo "Note: Add SDL3.dll to winlibs/lib/"
	cp $(RUST_LIB_WIN) $(WINDOWS_DIR)/ 2>/dev/null || echo "Rust DLL missing"
	find /usr -name "libgcc_s_seh-1.dll" 2>/dev/null | head -1 | xargs -I {} cp {} $(WINDOWS_DIR)/ 2>/dev/null || true
	find /usr -name "libwinpthread-1.dll" 2>/dev/null | head -1 | xargs -I {} cp {} $(WINDOWS_DIR)/ 2>/dev/null || true
	@echo "Copying Windows assets..."
	cp -r $(ASSETS) $(WINDOWS_DIR) 2>/dev/null || true

$(WINDOWS_ZIP): $(WINDOWS_DIR)
	cd $(OUT_DIR) && zip -rq $(PROJECT_NAME)-windows.zip $(PROJECT_NAME)-windows/
	@echo "Windows archive: $(WINDOWS_ZIP)"

# Utilities
run: clean-make
	./$(DEV_BIN)

clean:
	rm -rf $(OUT_DIR) obj/ $(DEV_BIN)

# Clean and clear before building
clean-make:
	@make clean-dev > /dev/null 2>&1 || true
	@clear
	@make $(DEV_BIN)

clean-linux:
	rm -rf $(LINUX_DIR) $(LINUX_ZIP) obj/linux/

clean-windows:
	rm -rf $(WINDOWS_DIR) $(WINDOWS_ZIP) obj/win/

clean-dev:
	rm -rf obj/dev/ $(DEV_BIN)

help:
	@echo "Available targets:"
	@echo "	make or make run	- Build/run development binary in root (.o in obj/dev/)"
	@echo "	make linux		- Build Linux folder + zip"
	@echo "	make windows		- Build Windows folder + zip"
	@echo "	make all		- Build both"
	@echo "	make clean		- Clean everything"
	@echo "	make clean-dev		- Clean only development build"
	@echo "	make clean-linux	- Clean Linux builds"
	@echo "	make clean-windows	- Clean Windows builds"

.PHONY: linux windows all run clean clean-dev clean-linux clean-windows rust-linux rust-windows

