#!/bin/bash
# 01-check-deps.sh - 检查系统依赖
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"  # 公共函数（颜色输出等）

log_step "步骤 1: 检查系统依赖"

# 检查基本工具
REQUIRED_TOOLS="wget tar gzip make"
for tool in $REQUIRED_TOOLS; do
    if ! command -v "$tool" &> /dev/null; then
        log_error "缺少必要工具：$tool"
        log_error "请安装：sudo yum install -y $tool"
        exit 1
    fi
done

# 检查 gcc/g++
if ! command -v "gcc" &> /dev/null || ! command -v "g++" &> /dev/null; then
    log_error "缺少 GCC/G++ 编译器"
    log_error "请安装：sudo yum install -y gcc gcc-c++"
    log_error "或使用 devtoolset：sudo yum install -y devtoolset-9"
    exit 1
fi

log_success "系统依赖检查通过"