#!/bin/bash
# 04-build-patchelf.sh - 编译 patchelf
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

INSTALL_DIR="${OPENCODE_INSTALL_DIR:-$HOME/.opencode}"
DEPS_DIR="$SCRIPT_DIR/../deps"
GNU_DIR="$INSTALL_DIR/gnu"
MARKER="$DEPS_DIR/.patchelf.completed"

log_step "步骤 4: 编译 patchelf"

# 检查是否已编译
if [ -f "$MARKER" ] && [ "${REBUILD:-0}" != "1" ]; then
    log_info "patchelf 已编译完成（跳过）"
    exit 0
fi

mkdir -p "$DEPS_DIR"
cd "$DEPS_DIR"

# 克隆源码
PATCHELF_DIR="$DEPS_DIR/patchelf"
if [ ! -d "$PATCHELF_DIR" ]; then
    log_info "克隆 patchelf..."
    git clone --depth 1 https://github.com/NixOS/patchelf "$PATCHELF_DIR"
fi

# 编译
cd "$PATCHELF_DIR"
log_info "编译 patchelf..."
./bootstrap.sh
./configure --prefix="$GNU_DIR"
make
make install

# 验证
if [ -f "$GNU_DIR/bin/patchelf" ]; then
    touch "$MARKER"
    log_success "patchelf 编译成功！"
else
    log_error "patchelf 编译失败"
    exit 1
fi
