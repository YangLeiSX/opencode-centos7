#!/bin/bash
# 03-build-glibc.sh - 编译 glibc 2.31
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

INSTALL_DIR="${OPENCODE_INSTALL_DIR:-$HOME/.opencode}"
DEPS_DIR="$SCRIPT_DIR/../deps"
GNU_DIR="$INSTALL_DIR/gnu"
MARKER="$DEPS_DIR/.glibc.completed"

log_step "步骤 3: 编译 glibc"

# 检查是否已编译
if [ -f "$MARKER" ] && [ "${REBUILD:-0}" != "1" ]; then
    log_info "glibc 已编译完成（跳过）"
    exit 0
fi

# 检查 GCC 是否完成
if [ ! -f "$DEPS_DIR/.gcc.completed" ]; then
    log_error "GCC 未编译完成，请先运行：bash scripts/02-build-gcc.sh"
    exit 1
fi

cd "$DEPS_DIR"

# 下载源码
if [ ! -f "glibc-2.31.tar.gz" ]; then
    log_info "下载 glibc 2.31..."
    wget --progress=bar:force:noscroll -c https://ftp.gnu.org/gnu/glibc/glibc-2.31.tar.gz
fi

if [ ! -d "glibc-2.31" ]; then
    tar -xzf glibc-2.31.tar.gz
fi

# 编译
BUILD_DIR="$DEPS_DIR/glibc-build"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

log_info "配置 glibc..."

CC="$GNU_DIR/bin/gcc" \
CXX="$GNU_DIR/bin/g++" \
../glibc-2.31/configure \
    --prefix="$GNU_DIR" \
    --disable-multilib \
    --enable-static-nss \
    --without-selinux \
    --without-cvs \
    --disable-werror \
    2>&1 | tee configure.log

log_info "编译 glibc（约 30-60 分钟）..."
make -j$(nproc) 2>&1 | tee make.log
make install 2>&1 | tee install.log

# 验证
if [ -f "$GNU_DIR/lib/ld-linux-x86-64.so.2" ]; then
    touch "$MARKER"
    log_success "glibc 编译成功！"
else
    log_error "glibc 编译失败：找不到 $GNU_DIR/lib/ld-linux-x86-64.so.2"
    exit 1
fi
