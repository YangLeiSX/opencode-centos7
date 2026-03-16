#!/bin/bash
# 05-install-opencode.sh - 安装并 patch opencode
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

INSTALL_DIR="${OPENCODE_INSTALL_DIR:-$HOME/.opencode}"
DEPS_DIR="$SCRIPT_DIR/../deps"

GNU_DIR="$INSTALL_DIR/gnu"
BIN_DIR="$INSTALL_DIR/bin"

log_step "步骤 5: 安装并 patch opencode"

# 检查 glibc 是否完成
if [ ! -f "$DEPS_DIR/.glibc.completed" ]; then
    log_error "glibc 未编译完成，请先运行：bash scripts/03-build-glibc.sh"
    exit 1
fi

# 检查 patchelf 是否完成
if [ ! -f "$DEPS_DIR/.patchelf.completed" ]; then
    log_error "patchelf 未编译完成，请先运行：bash scripts/04-build-patchelf.sh"
    exit 1
fi

# 安装 opencode
RAW_OPENCODE_BIN="$HOME/.opencode/bin/opencode"

if [ -f "$RAW_OPENCODE_BIN" ]; then
    log_info "opencode 已安装，跳过下载"
else
    log_info "执行官方安装脚本..."
    curl -fsSL https://opencode.ai/install | bash
fi

# 准备目标二进制
mkdir -p "$BIN_DIR"
OPENCODE_BIN="$BIN_DIR/opencode"

if [ "$RAW_OPENCODE_BIN" != "$OPENCODE_BIN" ]; then
    cp "$RAW_OPENCODE_BIN" "$OPENCODE_BIN"
fi

log_info "备份原文件..."
cp "$OPENCODE_BIN" "$OPENCODE_BIN.bak"

log_success "opencode 备份完成！"
