#!/bin/bash
# 06-create-launcher.sh - 创建启动脚本
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

INSTALL_DIR="${OPENCODE_INSTALL_DIR:-$HOME/.opencode}"
BIN_DIR="$INSTALL_DIR/bin"

log_step "步骤 6: 创建启动脚本"

if [ ! -f "$BIN_DIR/opencode.bak" ]; then
    log_error "未找到 opencode.bak，请先运行：bash scripts/05-install-opencode.sh"
    exit 1
fi

log_info "创建启动脚本..."
cat > "$INSTALL_DIR/opencode" << 'LAUNCHER_EOF'
#!/bin/bash
# OpenCode Launcher - 基于 opencode-on-centos7 方案修复版
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENCODE_DIR="${HOME}/.opencode"

# 检查安装目录
if [[ ! -d "$OPENCODE_DIR" ]]; then
    echo "错误：未找到 OpenCode 安装目录 $OPENCODE_DIR"
    exit 1
fi

# 定义清理函数
cleanup_terminal() {
    # 重置终端鼠标事件跟踪
    echo -e '\033[?1000h\033[?1002h\033[?1003h' 2>/dev/null || true
}

# 设置 trap 确保退出时清理
trap cleanup_terminal EXIT INT TERM

# 禁用鼠标事件跟踪（防止终端异常）
echo -e '\033[?1000l\033[?1002l\033[?1003l\033[?1005l\033[?1006l' 2>/dev/null || true

# 关键路径
GLIBC_LOADER="$OPENCODE_DIR/gnu/lib/ld-linux-x86-64.so.2"
OPENCODE_BAK="$OPENCODE_DIR/bin/opencode.bak"
PATCHELF="$OPENCODE_DIR/gnu/bin/patchelf"

# 检查必要文件
if [[ ! -f "$GLIBC_LOADER" ]]; then
    echo "错误：未找到 glibc loader: $GLIBC_LOADER"
    exit 1
fi

if [[ ! -f "$OPENCODE_BAK" ]]; then
    echo "错误：未找到 OpenCode 备份文件：$OPENCODE_BAK"
    exit 1
fi

# 创建临时目录
TEMP_DIR=$(mktemp -d)
TEMP_OPENCODE="$TEMP_DIR/opencode"

# 复制备份到临时目录
cp "$OPENCODE_BAK" "$TEMP_OPENCODE"

# 使用 patchelf 修改 interpreter
if [[ -f "$PATCHELF" ]]; then
    "$PATCHELF" --set-interpreter "$GLIBC_LOADER" "$TEMP_OPENCODE" 2>/dev/null || {
        echo "警告：patchelf 修改失败，尝试直接运行..."
    }
fi

# 保存原始环境变量
ORIGINAL_LD_LIBRARY_PATH="$LD_LIBRARY_PATH"
ORIGINAL_LANG="$LANG"
ORIGINAL_TERM="$TERM"
ORIGINAL_LOCPATH="$LOCPATH"

# 设置安全的环境变量
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export TERM=xterm-256color

# 关键：不设置 glibc 的 LD_LIBRARY_PATH
# OpenCode 通过 patchelf 修改的 interpreter 自动找到自定义 glibc
# 只设置 gnu/lib64 用于 libgcc_s.so.1（pthread_cancel 需要）
export LD_LIBRARY_PATH="$OPENCODE_DIR/gnu/lib64"

# 设置 locale 路径（如果存在）
if [[ -d "$OPENCODE_DIR/gnu/lib/locale" ]]; then
    export LOCPATH="$OPENCODE_DIR/gnu/lib/locale"
fi

# 运行 OpenCode
"$TEMP_OPENCODE" "$@"
RETURN_CODE=$?

# 恢复原始环境变量
export LD_LIBRARY_PATH="$ORIGINAL_LD_LIBRARY_PATH"
export LANG="$ORIGINAL_LANG"
export TERM="$ORIGINAL_TERM"
if [[ -n "$ORIGINAL_LOCPATH" ]]; then
    export LOCPATH="$ORIGINAL_LOCPATH"
else
    unset LOCPATH
fi

# 后台清理临时文件
( sleep 0.2; rm -rf "$TEMP_DIR" ) 2>/dev/null &

exit $RETURN_CODE
LAUNCHER_EOF

chmod +x "$INSTALL_DIR/opencode"

log_info "测试运行..."
if "$INSTALL_DIR/opencode" --version &> /dev/null; then
    log_success "安装完成！"
    echo ""
    echo "使用方法：$INSTALL_DIR/opencode"
else
    log_error "测试失败，请检查日志"
    exit 1
fi
