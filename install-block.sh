#!/bin/bash
# install.sh - opencode-centos7 主安装脚本
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export OPENCODE_INSTALL_DIR="${OPENCODE_INSTALL_DIR:-$HOME/.opencode}"
export REBUILD=0

# 激活 devtoolset（供所有子脚本继承）
for version in 9 8 7; do
    if [ -f "/opt/rh/devtoolset-$version/enable" ]; then
        source "/opt/rh/devtoolset-$version/enable"
        echo "[INFO] 已激活 devtoolset-$version (GCC $(gcc --version | head -1))"
        break
    fi
done

# 解析参数
for arg in "$@"; do
    case $arg in
        --rebuild) REBUILD=1 ;;
    esac
done

echo "=========================================="
echo "opencode-centos7 安装程序"
echo "=========================================="
echo ""

# 依次执行各模块
bash "$SCRIPT_DIR/scripts/01-check-deps.sh"
bash "$SCRIPT_DIR/scripts/02-build-gcc.sh"
bash "$SCRIPT_DIR/scripts/03-build-glibc.sh"
bash "$SCRIPT_DIR/scripts/04-build-patchelf.sh"
bash "$SCRIPT_DIR/scripts/05-install-opencode.sh"
bash "$SCRIPT_DIR/scripts/06-create-launcher.sh"

echo ""
echo "=========================================="
echo "✅ 全部完成！"
echo "=========================================="
