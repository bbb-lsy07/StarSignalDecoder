#!/bin/bash

# 星际迷航：信号解码 - 简化版一键安装脚本 (Linux/macOS) v1.0.0
# 作者：bbb-lsy07
# 邮箱：lisongyue0125@163.com
# 专注于 Linux/macOS 自动化安装，Windows 用户请参考手动说明。

# --- 定义颜色 ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# --- 全局变量 ---
REPO_URL="https://github.com/bbb-lsy07/StarSignalDecoder.git"
GAME_NAME="starsignal"

# --- 辅助函数 ---

print_status() {
    echo -e "${GREEN}==> $1 ${NC}"
}

print_warning() {
    echo -e "${YELLOW}警告：$1 ${NC}"
}

print_error() {
    echo -e "${RED}错误：$1 ${NC}"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "Linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macOS"
    elif [[ "$OSTYPE" == "cygwin" || "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
        echo "Windows"
    else
        echo "Unknown"
    fi
}

# --- 主要安装逻辑 ---

install_dependencies_linux_macos() {
    local OS=$(detect_os)
    local PYTHON_CMD=""
    local PIP_CMD=""

    echo ""
    print_status "星际迷航：信号解码 - 简化版安装脚本开始运行！"
    print_status "当前操作系统: ${OS}"
    echo ""

    if [ "$OS" == "Windows" ]; then
        print_error "此脚本主要用于 Linux/macOS。"
        print_warning "对于 Windows，请参考以下手动安装指南："
        echo ""
        echo "=================================================================="
        echo "【Windows 手动安装指南】"
        echo "1. 安装 Python 3.6+ 和 pip："
        echo "   推荐使用 winget: winget install --id Python.Python.3 --source winget"
        echo "   或从 Python 官网 (https://www.python.org/downloads/) 下载安装，"
        echo "   务必在安装时勾选 'Add Python to PATH'。"
        echo "2. 安装 Git for Windows："
        echo "   推荐使用 winget: winget install --id Git.Git"
        echo "   或从 Git 官网 (https://git-scm.com/download/win) 下载安装，"
        echo "   勾选 'Use Git from the Windows Command Prompt' 或 'Git from the command line and also from 3rd-party software'。"
        echo "3. 手动添加 PATH (如果 starsignal 命令无法找到)："
        echo "   找到类似 'C:\\Users\\你的用户名\\AppData\\Roaming\\Python\\Python39\\Scripts' 的路径，"
        echo "   并将其添加到用户环境变量的 'Path' 中。然后重启 PowerShell 或 Git Bash。"
        echo "4. 安装游戏核心："
        echo "   pip install --user git+${REPO_URL}@main"
        echo "   pip install --user colorama"
        echo "5. 运行游戏: starsignal"
        echo "=================================================================="
        exit 1
    fi

    # 1. 检查并安装 Python 3
    print_status "1. 检查并安装 Python 3.6+ 和 pip..."
    if command_exists python3; then
        PYTHON_CMD="python3"
        print_status "Python 3 已检测到。"
    elif command_exists python; then
        PYTHON_VERSION=$(python -c 'import sys; print(sys.version_info.major)')
        if [ "$PYTHON_VERSION" -ge 3 ]; then
            PYTHON_CMD="python"
            print_status "Python 3 已检测到 (通过 'python' 命令)。"
        fi
    fi

    if [ -z "$PYTHON_CMD" ]; then
        print_warning "Python 3 未检测到。尝试安装..."
        if [ "$OS" == "Linux" ]; then
            if command_exists apt-get; then
                sudo apt-get update && sudo apt-get install -y python3 python3-dev python3-pip
            elif command_exists yum; then
                sudo yum install -y python3 python3-devel python3-pip
            else
                print_error "不支持的 Linux 包管理器。请手动安装 Python 3。"
                exit 1
            fi
        elif [ "$OS" == "macOS" ]; then
            if command_exists brew; then
                brew install python3
            else
                print_error "Homebrew 未安装。请手动安装 Homebrew (https://brew.sh/) 或 Python 3。"
                exit 1
            fi
        fi
        # 再次检查 Python 命令
        if command_exists python3; then PYTHON_CMD="python3"; fi
        if [ -z "$PYTHON_CMD" ] && command_exists python; then PYTHON_CMD="python"; fi
        if [ -z "$PYTHON_CMD" ]; then
            print_error "Python 3 安装失败或未在 PATH 中找到。请手动检查并安装。"
            exit 1
        fi
    fi

    # 确保 pip 可用
    if command_exists pip3; then
        PIP_CMD="pip3"
    elif command_exists pip; then
        PIP_CMD="pip"
    fi
    if [ -z "$PIP_CMD" ]; then
        print_warning "pip 未检测到。尝试安装/升级 pip..."
        "$PYTHON_CMD" -m ensurepip --upgrade || { print_error "pip 安装失败。"; exit 1; }
        "$PYTHON_CMD" -m pip install --upgrade pip || { print_error "pip 升级失败。"; exit 1; }
        if command_exists pip3; then PIP_CMD="pip3"; else PIP_CMD="pip"; fi
        if [ -z "$PIP_CMD" ]; then
            print_error "pip 安装/升级后仍不可用。请手动检查并修复。"
            exit 1
        fi
    fi
    print_status "Python 和 pip 环境准备就绪。"

    # 2. 检查并安装 Git
    print_status "2. 检查并安装 Git..."
    if ! command_exists git; then
        print_warning "Git 未检测到。尝试安装 Git..."
        if [ "$OS" == "Linux" ]; then
            if command_exists apt-get; then
                sudo apt-get install -y git
            elif command_exists yum; then
                sudo yum install -y git
            else
                print_error "不支持的 Linux 包管理器。请手动安装 Git。"
                exit 1
            fi
        elif [ "$OS" == "macOS" ]; then
            if command_exists brew; then
                brew install git
            else
                print_error "Homebrew 未安装。请手动安装 Homebrew 或 Git。"
                exit 1
            fi
        fi
        if ! command_exists git; then
            print_error "Git 安装失败或未在 PATH 中找到。请手动检查并安装。"
            exit 1
        fi
    fi
    print_status "Git 环境准备就绪。"

    # 3. 确保 pip Scripts 目录在 PATH 中 (仅针对 Linux/macOS .local/bin)
    print_status "3. 确保 starsignal 命令在 PATH 中..."
    LOCAL_BIN="$HOME/.local/bin"
    if [[ "$($PIP_CMD --version 2>/dev/null)" == *"pip"* ]]; then # 确保pip本身可用
        # 获取pip的user_base路径
        PIP_USER_BASE=$("$PYTHON_CMD" -c "import site; print(site.USER_BASE)" 2>/dev/null)
        if [ -n "$PIP_USER_BASE" ]; then
            LOCAL_BIN="$PIP_USER_BASE/bin" # 对于Linux/macOS，pip --user 安装的可执行文件通常在 <user_base>/bin
        fi
    fi

    if ! command_exists "$GAME_NAME"; then
        if [[ ":$PATH:" != *":$LOCAL_BIN:"* ]]; then
            print_warning "Python 用户脚本目录 (${LOCAL_BIN}) 不在您的 PATH 环境变量中。"
            echo "尝试将其添加到您的 PATH。您可能需要重新加载您的 shell 配置（例如 'source ~/.bashrc'）或重启终端以使更改生效。"
            echo "export PATH=\$PATH:$LOCAL_BIN" >> "$HOME/.bashrc"
            echo "export PATH=\$PATH:$LOCAL_BIN" >> "$HOME/.zshrc"
            # 尝试立即生效，但通常需要重启终端
            source "$HOME/.bashrc" >/dev/null 2>&1 || true
            source "$HOME/.zshrc" >/dev/null 2>&1 || true
        else
            print_status "starsignal 命令应在 PATH 中。"
        fi
    else
        print_status "starsignal 命令已在 PATH 中。"
    fi
    echo ""

    # 4. 安装游戏核心
    print_status "4. 安装 星际迷航：信号解码 游戏核心..."
    print_status "安装稳定版 (main 分支)..."
    "$PIP_CMD" install --user "git+${REPO_URL}@main" || { print_error "游戏安装失败。"; exit 1; }
    print_status "安装 colorama (用于彩色输出)..."
    "$PIP_CMD" install --user colorama || { print_warning "colorama 安装失败。游戏可能无法显示彩色输出。"; }

    print_status "游戏安装完成！"
    echo ""
    print_status "【如何启动游戏】"
    echo "请重启您的终端（或运行 'source ~/.bashrc' / 'source ~/.zshrc'），然后运行："
    echo -e "${CYAN}starsignal${NC}"
    echo ""
    print_status "感谢您的体验！"
    echo ""
}

# --- 脚本入口点 ---
main() {
    install_dependencies_linux_macos
}

main "$@"
