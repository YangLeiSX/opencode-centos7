#!/bin/bash
# 02-build-gcc.sh - 编译 GCC 9.5.0
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

INSTALL_DIR="${OPENCODE_INSTALL_DIR:-$HOME/.opencode}"
DEPS_DIR="$SCRIPT_DIR/../deps"
GNU_DIR="$INSTALL_DIR/gnu"
MARKER="$DEPS_DIR/.gcc.completed"

log_step "步骤 2: 编译 GCC"

# 检查是否已编译
if [ -f "$MARKER" ] && [ "${REBUILD:-0}" != "1" ]; then
    log_info "GCC 已编译完成（跳过）"
    exit 0
fi

mkdir -p "$DEPS_DIR"
cd "$DEPS_DIR"

# 下载源码
if [ ! -f "gcc-9.5.0.tar.gz" ]; then
    log_info "下载 GCC 9.5.0..."
    wget --progress=bar:force:noscroll -c https://ftp.gnu.org/gnu/gcc/gcc-9.5.0/gcc-9.5.0.tar.gz
fi

if [ ! -d "gcc-9.5.0" ]; then
    tar -xzf gcc-9.5.0.tar.gz
fi

# 编译
BUILD_DIR="$DEPS_DIR/gcc-build"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

log_info "配置 GCC..."
../gcc-9.5.0/configure \
    --prefix="$GNU_DIR" \
    --disable-multilib \
    --enable-languages=c,c++ \
    --disable-libquadmath \
    --disable-libquadmath-support \
    --disable-libsanitizer \
    --disable-libvtv \
    --disable-libcilkrts \
    --disable-libgomp \
    --disable-libssp \
    --disable-lto \
    --disable-libada \
    2>&1 | tee configure.log

log_info "编译 GCC（约 30-60 分钟）..."
make -j$(nproc) 2>&1 | tee make.log
make install 2>&1 | tee install.log

# 验证
if [ -f "$GNU_DIR/bin/gcc" ]; then
    touch "$MARKER"
    log_success "GCC 编译成功！"
else
    log_error "GCC 编译失败：找不到 $GNU_DIR/bin/gcc"
    exit 1
fi
