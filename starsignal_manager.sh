#!/bin/bash

# ==============================================================================
# 星际迷航：信号解码 - 全功能管理脚本 v3.0.0
# 作者：bbb-lsy07
# 邮箱：lisongyue0125@163.com
#
# 功能：
#   - 跨平台支持 (Linux/macOS 自动化，Windows 提供详细手动指南)
#   - 智能环境检测与自动安装 (Python3, pip, Git, Homebrew, winget)
#   - 一键安装稳定版 (main) 或开发版 (dev) 游戏
#   - 游戏更新、修复、清理存档、卸载功能
#   - 游戏启动与命令行选项支持 (难度、教程、练习、加载存档)
#   - 自动修复 PATH 环境变量和存档文件权限
#   - 诊断终端编码问题
#   - 游戏内交互问题诊断与建议
#   - 实时输出进度，同时记录核心操作到日志文件
# ==============================================================================

# --- 定义颜色 ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# --- 全局变量和配置 ---
REPO_URL="https://github.com/bbb-lsy07/StarSignalDecoder.git"
GAME_NAME="starsignal"
DATA_FILE="$HOME/.starsignal_data.json"
LOG_FILE="$HOME/.starsignal_manager.log" # 仅记录脚本自身核心运行信息
SAVE_FILE_PREFIX="$HOME/.starsignal_save_"
SCRIPT_VERSION="3.0.0" # 脚本自身版本

# 如果以 root 运行，尝试使用 SUDO_USER 的家目录
if [ "$(id -u)" -eq 0 ] && [ -n "$SUDO_USER" ]; then
    DATA_FILE="/home/$SUDO_USER/.starsignal_data.json"
    LOG_FILE="/home/$SUDO_USER/.starsignal_manager.log"
    SAVE_FILE_PREFIX="/home/$SUDO_USER/.starsignal_save_"
fi

# 检查当前是否在终端运行 (仅用于警告，不强制)
IS_TERMINAL=true
if ! [ -t 0 ]; then
    IS_TERMINAL=false
fi

# 获取当前脚本的语言设置，默认中文
LANG_SET="zh"
if [ "$#" -ge 2 ] && [ "$1" == "--lang" ]; then
    LANG_SET="$2"
    shift 2
fi

# 文本定义 (根据语言设置)
set_texts() {
    if [ "$1" == "en" ]; then
        INSTALLATION_MENU="Star Signal Decoder - Management Menu"
        ALREADY_INSTALLED="StarSignalDecoder is already installed."
        NOT_INSTALLED="StarSignalDecoder is not installed."
        INSTALL_MAIN="Install Stable Version (main branch)"
        INSTALL_DEV="Install Development Version (dev branch)"
        UPDATE_GAME="Update Game"
        REPAIR_GAME="Repair Installation"
        CLEAN_SAVES="Clean Save Data and Achievements"
        UNINSTALL_GAME="Uninstall Game"
        START_GAME="Start Game (with options)"
        SHOW_MANUAL="Show Manual Installation Guide (for Windows/manual users)"
        EXIT_OPTION="Exit"
        ENTER_CHOICE="Enter your choice: "
        INVALID_CHOICE="Invalid choice. Please try again."
        INSTALLING_DEPENDENCIES="Installing necessary dependencies (this may take a while)..."
        CHECKING_ENV="Checking environment..."
        PYTHON_FOUND="Python 3 found."
        PYTHON_NOT_FOUND="Python 3 not found. Attempting to install Python 3..."
        PIP_FOUND="pip found."
        PIP_NOT_FOUND="pip not found. Attempting to install pip..."
        GIT_FOUND="Git found."
        GIT_NOT_FOUND="Git not found. Attempting to install Git..."
        INSTALLING_GAME="Installing StarSignalDecoder..."
        INSTALL_SUCCESS="StarSignalDecoder installed successfully!"
        INSTALL_FAILED="Installation failed. Possible network issues, missing dependencies, or outdated pip. Check the output above and your internet connection."
        UPDATE_SUCCESS="StarSignalDecoder updated successfully!"
        UPDATE_FAILED="Update failed. Possible network issues, missing dependencies, or outdated pip. Check the output above and your internet connection."
        REPAIR_SUCCESS="StarSignalDecoder repaired successfully!"
        REPAIR_FAILED="Repair failed. Possible network issues, missing dependencies, or outdated pip. Check the output above and your internet connection."
        CLEAN_SUCCESS="Save data and achievements cleaned successfully!"
        CLEAN_FAILED="Failed to clean save data. Check permissions or try manually."
        UNINSTALL_SUCCESS="StarSignalDecoder uninstalled successfully! Save data also removed."
        UNINSTALL_FAILED="Uninstallation failed. Please check the output above for details."
        PERMISSION_FIX="Attempting to fix save file permissions..."
        PERMISSION_SUCCESS="Save file permissions fixed."
        PERMISSION_FAILED="Failed to fix save file permissions. Please fix manually using 'chmod 666 ~/.starsignal*' or 'icacls %USERPROFILE%\\.starsignal* /grant Everyone:F'."
        PATH_FIX_PROMPT="Python scripts directory might not be in your PATH. Do you want to try fixing it? (y/n): "
        PATH_FIX_LINUX_MACOS="Fixing PATH for Linux/macOS. Please source your shell config (e.g., 'source ~/.bashrc') or restart your terminal for changes to take effect."
        PATH_FIX_WINDOWS="Attempting to fix PATH for Windows. You may need to restart PowerShell/Git Bash or your system for changes to take effect."
        PATH_FIX_FAILED="Failed to fix PATH. Please add Python's Scripts directory to your system's PATH manually."
        WARNING_PIPE="WARNING: This script is designed for interactive use. Running via pipe (e.g., curl ... | sh) may cause input issues. Please download the script and run it locally: ${YELLOW}curl -s ${REPO_URL}/main/starsignal_manager.sh -o starsignal_manager.sh && chmod +x starsignal_manager.sh && ./starsignal_manager.sh${NC}"
        CONFIRM_UNINSTALL="Are you sure you want to uninstall StarSignalDecoder and delete all save data? (y/n): "
        CONFIRM_CLEAN="Are you sure you want to delete all save data and achievements? This cannot be undone. (y/n): "
        CANCELLED="Operation cancelled."
        CHOOSE_BRANCH="Choose branch (main/dev) [main]: "
        CHECKING_TERMINAL_ENCODING="Checking terminal encoding..."
        ENCODING_WARNING="Your terminal encoding might not be UTF-8. This can cause display issues. Please set your terminal to UTF-8 (e.g., ${YELLOW}export LANG=en_US.UTF-8${NC} or ${YELLOW}chcp 65001${NC} on Windows)."
        PRESS_ENTER_TO_CONTINUE="Press Enter to continue..."
        INVALID_INPUT_EMPTY="Input cannot be empty."
        INVALID_INPUT_NOT_NUMBER="Please enter a number from the list."
        GAME_START_OPTIONS="Enter game start options (e.g., --difficulty hard --tutorial): "
        GAME_START_NOTE="If game input seems stuck, try running in a native terminal, or use 'stty sane' and 'export TERM=xterm-256color'."
        MANUAL_INSTALL_HEADER="【Manual Installation Guide】"
        MANUAL_INSTALL_REQUIREMENTS="Requirements:"
        MANUAL_INSTALL_PYTHON_PIP="Python 3.6+ and pip"
        MANUAL_INSTALL_GIT="Git"
        MANUAL_INSTALL_LINUX_MACOS_STEPS="For Linux/macOS:"
        MANUAL_INSTALL_PYTHON_LINUX="sudo apt update && sudo apt install -y python3 python3-dev python3-pip (Ubuntu/Debian) or sudo yum install -y python3 python3-devel python3-pip (CentOS/RHEL)"
        MANUAL_INSTALL_PYTHON_MACOS="brew install python3 (if Homebrew is installed)"
        MANUAL_INSTALL_GIT_LINUX="sudo apt install -y git (Ubuntu/Debian) or sudo yum install -y git (CentOS/RHEL)"
        MANUAL_INSTALL_GIT_MACOS="brew install git (if Homebrew is installed)"
        MANUAL_INSTALL_PIP_PATH="Ensure pip and PATH are correct: python3 -m pip install --upgrade pip; export PATH=\$PATH:\$HOME/.local/bin"
        MANUAL_INSTALL_WINDOWS_STEPS="For Windows:"
        MANUAL_INSTALL_WINDOWS_PYTHON="Install Python 3.6+ from https://www.python.org/downloads/ (check 'Add Python to PATH')"
        MANUAL_INSTALL_WINDOWS_GIT="Install Git for Windows from https://git-scm.com/download/win (check 'Git from the command line...')"
        MANUAL_INSTALL_WINDOWS_PATH="Manually add Python Scripts path to system PATH if 'starsignal' command not found (e.g., C:\\Users\\YOUR_USER\\AppData\\Roaming\\Python\\Python39\\Scripts)"
        MANUAL_INSTALL_GAME_CORE="Install Game Core (after environment is ready):"
        MANUAL_INSTALL_STABLE_VERSION="pip3 install --user git+${REPO_URL}@main (Linux/macOS) / pip install --user git+${REPO_URL}@main (Windows)"
        MANUAL_INSTALL_DEV_VERSION="pip3 install --user git+${REPO_URL}@dev (Linux/macOS) / pip install --user git+${REPO_URL}@dev (Windows)"
        MANUAL_INSTALL_COLORAMA="pip3 install --user colorama (recommended for color output)"
        MANUAL_INSTALL_RUN_GAME="Run Game: starsignal"
    else
        # Chinese Text
        INSTALLATION_MENU="星际迷航：信号解码 - 管理菜单"
        ALREADY_INSTALLED="星际迷航：信号解码 已安装。"
        NOT_INSTALLED="星际迷航：信号解码 未安装。"
        INSTALL_MAIN="安装稳定版（main 分支）"
        INSTALL_DEV="安装开发版（dev 分支）"
        UPDATE_GAME="更新游戏"
        REPAIR_GAME="修复安装"
        CLEAN_SAVES="清理存档和成就数据"
        UNINSTALL_GAME="卸载游戏"
        START_GAME="启动游戏（带选项）"
        SHOW_MANUAL="显示手动安装指南（针对 Windows/手动用户）"
        EXIT_OPTION="退出"
        ENTER_CHOICE="请输入您的选择： "
        INVALID_CHOICE="无效的选择，请重试。"
        INSTALLING_DEPENDENCIES="正在安装必要的依赖（这可能需要一些时间）..."
        CHECKING_ENV="正在检查环境..."
        PYTHON_FOUND="检测到 Python 3。"
        PYTHON_NOT_FOUND="未检测到 Python 3。正在尝试安装 Python 3..."
        PIP_FOUND="检测到 pip。"
        PIP_NOT_FOUND="未检测到 pip。正在尝试安装 pip..."
        GIT_FOUND="检测到 Git。"
        GIT_NOT_FOUND="未检测到 Git。正在尝试安装 Git..."
        INSTALLING_GAME="正在安装 星际迷航：信号解码..."
        INSTALL_SUCCESS="星际迷航：信号解码 安装成功！"
        INSTALL_FAILED="安装失败。可能存在网络问题、依赖缺失或 pip 版本过旧。请检查终端输出、您的互联网连接，并考虑更新 pip。"
        UPDATE_SUCCESS="星际迷航：信号解码 更新成功！"
        UPDATE_FAILED="更新失败。可能存在网络问题、依赖缺失或 pip 版本过旧。请检查终端输出和您的互联网连接。"
        REPAIR_SUCCESS="星际迷航：信号解码 修复成功！"
        REPAIR_FAILED="修复失败。可能存在网络问题、依赖缺失或 pip 版本过旧。请检查终端输出和您的互联网连接。"
        CLEAN_SUCCESS="存档和成就数据清理成功！"
        CLEAN_FAILED="清理存档失败。请检查文件权限或手动尝试。"
        UNINSTALL_SUCCESS="星际迷航：信号解码 卸载成功！存档数据已移除。"
        UNINSTALL_FAILED="卸载失败。请查看终端输出获取详情。"
        PERMISSION_FIX="正在尝试修复存档文件权限..."
        PERMISSION_SUCCESS="存档文件权限已修复。"
        PERMISSION_FAILED="无法修复存档文件权限。请手动运行：'chmod 666 ~/.starsignal*' (Linux/macOS) 或 'icacls %USERPROFILE%\\.starsignal* /grant Everyone:F' (Windows)。"
        PATH_FIX_PROMPT="Python 脚本目录可能不在您的 PATH 环境变量中。是否尝试修复？(y/n)："
        PATH_FIX_LINUX_MACOS="正在修复 Linux/macOS 的 PATH。请重新加载您的 shell 配置（例如 'source ~/.bashrc'）或重启终端以使更改生效。"
        PATH_FIX_WINDOWS="正在尝试修复 Windows 的 PATH。您可能需要重启 PowerShell/Git Bash 或您的系统以使更改生效。"
        PATH_FIX_FAILED="无法修复 PATH。请手动将 Python 的 Scripts 目录添加到系统 PATH 环境变量中。"
        WARNING_PIPE="警告：本脚本设计为交互式使用。通过管道运行（例如 curl ... | sh）可能导致输入问题。请下载脚本后在本地运行：${YELLOW}curl -s ${REPO_URL}/main/starsignal_manager.sh -o starsignal_manager.sh && chmod +x starsignal_manager.sh && ./starsignal_manager.sh${NC}"
        CONFIRM_UNINSTALL="您确定要卸载 星际迷航：信号解码 并删除所有存档数据吗？(y/n)："
        CONFIRM_CLEAN="您确定要删除所有存档和成就数据吗？此操作无法撤销。(y/n)："
        CANCELLED="操作已取消。"
        CHOOSE_BRANCH="选择分支 (main/dev) [main]： "
        CHECKING_TERMINAL_ENCODING="正在检查终端编码..."
        ENCODING_WARNING="您的终端编码可能不是 UTF-8。这可能导致显示问题。请将终端设置为 UTF-8（例如 ${YELLOW}export LANG=zh_CN.UTF-8${NC} 或 Windows 上 ${YELLOW}chcp 65001${NC}）。"
        PRESS_ENTER_TO_CONTINUE="按回车键继续..."
        INVALID_INPUT_EMPTY="输入不能为空。"
        INVALID_INPUT_NOT_NUMBER="请输入列表中的数字。"
        GAME_START_OPTIONS="请输入游戏启动选项（例如 --difficulty hard --tutorial）："
        GAME_START_NOTE="提示：如果游戏输入卡顿，请尝试在本地终端运行，或尝试运行 'stty sane' 和 'export TERM=xterm-256color'。"
        MANUAL_INSTALL_HEADER="【手动安装指南】"
        MANUAL_INSTALL_REQUIREMENTS="要求："
        MANUAL_INSTALL_PYTHON_PIP="Python 3.6+ 和 pip"
        MANUAL_INSTALL_GIT="Git"
        MANUAL_INSTALL_LINUX_MACOS_STEPS="适用于 Linux/macOS："
        MANUAL_INSTALL_PYTHON_LINUX="sudo apt update && sudo apt install -y python3 python3-dev python3-pip (Ubuntu/Debian) 或 sudo yum install -y python3 python3-devel python3-pip (CentOS/RHEL)"
        MANUAL_INSTALL_PYTHON_MACOS="brew install python3 (如果已安装 Homebrew)"
        MANUAL_INSTALL_GIT_LINUX="sudo apt install -y git (Ubuntu/Debian) 或 sudo yum install -y git (CentOS/RHEL)"
        MANUAL_INSTALL_GIT_MACOS="brew install git (如果已安装 Homebrew)"
        MANUAL_INSTALL_PIP_PATH="确保 pip 和 PATH 正确：python3 -m pip install --upgrade pip; export PATH=\$PATH:\$HOME/.local/bin"
        MANUAL_INSTALL_WINDOWS_STEPS="适用于 Windows："
        MANUAL_INSTALL_WINDOWS_PYTHON="从 Python 官网 (https://www.python.org/downloads/) 安装 Python 3.6+（勾选 'Add Python to PATH'）"
        MANUAL_INSTALL_WINDOWS_GIT="从 Git for Windows 官网 (https://git-scm.com/download/win) 安装 Git（勾选 'Git from the command line...'）"
        MANUAL_INSTALL_WINDOWS_PATH="如果 'starsignal' 命令未找到，请手动将 Python Scripts 路径添加到系统 PATH（例如 C:\\Users\\你的用户\\AppData\\Roaming\\Python\\Python39\\Scripts）"
        MANUAL_INSTALL_GAME_CORE="安装游戏核心（环境准备就绪后）："
        MANUAL_INSTALL_STABLE_VERSION="pip3 install --user git+${REPO_URL}@main (Linux/macOS) / pip install --user git+${REPO_URL}@main (Windows)"
        MANUAL_INSTALL_DEV_VERSION="pip3 install --user git+${REPO_URL}@dev (Linux/macOS) / pip install --user git+${REPO_URL}@dev (Windows)"
        MANUAL_INSTALL_COLORAMA="pip3 install --user colorama (推荐用于彩色输出)"
        MANUAL_INSTALL_RUN_GAME="运行游戏：starsignal"
    fi
}

# 调用函数设置文本
set_texts "$LANG_SET"

# --- 辅助函数 ---

# log_message 函数将输出到终端，并记录到日志文件
log_message() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOG_FILE"
}

# print_status/warning/error 函数只输出到终端，不记录到日志文件（但会通过log_message记录到日志）
print_status() {
    echo -e "${GREEN}==> $1 ${NC}" >&2
    log_message "Status: $1"
}

print_warning() {
    echo -e "${YELLOW}警告：$1 ${NC}" >&2
    log_message "Warning: $1"
}

print_error() {
    echo -e "${RED}错误：$1 ${NC}" >&2
    log_message "Error: $1"
}

# 检查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 检查当前系统
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

OS=$(detect_os)

# 通用的用户输入函数，确保在任何环境下都能交互
# 参数1: 提示信息 (会包含颜色和换行)
# 参数2: 输入类型 ("text", "yes_no", "menu_choice_installed", "menu_choice_not_installed")
# 返回值: 用户输入的内容
get_user_input() {
    local prompt="$1"
    local input_type="$2"
    local choice=""
    local valid_input=false
    local attempt=0
    local max_attempts=3

    while ! "$valid_input" && [ "$attempt" -lt "$max_attempts" ]; do
        # Print prompt and force flush
        echo -en "$prompt" >&2
        sync # Ensure prompt is displayed immediately
        
        # Try reading from /dev/tty first
        if [[ -r /dev/tty ]]; then
            if [[ "$input_type" == "yes_no" ]]; then
                read -r -n 1 -t 30 choice < /dev/tty 2>/dev/null
            else
                read -r -t 30 choice < /dev/tty 2>/dev/null
            fi
        else
            # Fallback to standard input
            if [[ "$input_type" == "yes_no" ]]; then
                read -r -n 1 -t 30 choice 2>/dev/null
            else
                read -r -t 30 choice 2>/dev/null
            fi
        fi
        echo # Add newline after input
        log_message "Input attempt $((attempt + 1)): Received '$choice' for type '$input_type'"

        # Validate input based on type
        case "$input_type" in
            "text")
                if [ -z "$choice" ]; then
                    print_error "${INVALID_INPUT_EMPTY}"
                else
                    valid_input=true
                fi
                ;;
            "yes_no")
                if [[ "$choice" =~ ^[YyNn]$ ]]; then
                    valid_input=true
                elif [ -z "$choice" ]; then
                    print_error "${INVALID_INPUT_EMPTY}"
                else
                    print_error "${INVALID_INPUT_NOT_NUMBER}"
                fi
                ;;
            "menu_choice_installed")
                if [[ "$choice" =~ ^[0-6]$ ]]; then
                    valid_input=true
                elif [ -z "$choice" ]; then
                    print_error "${INVALID_INPUT_EMPTY}"
                else
                    print_error "${INVALID_INPUT_NOT_NUMBER}"
                fi
                ;;
            "menu_choice_not_installed")
                if [[ "$choice" =~ ^[0-3]$ ]]; then
                    valid_input=true
                elif [ -z "$choice" ]; then
                    print_error "${INVALID_INPUT_EMPTY}"
                else
                    print_error "${INVALID_INPUT_NOT_NUMBER}"
                fi
                ;;
            *)
                if [ -z "$choice" ]; then
                    print_error "${INVALID_INPUT_EMPTY}"
                else
                    valid_input=true
                fi
                ;;
        esac

        if ! "$valid_input"; then
            ((attempt++))
            if [ "$attempt" -ge "$max_attempts" ]; then
                print_error "Maximum input attempts reached. Aborting."
                log_message "Maximum input attempts reached. Exiting input loop."
                exit 1
            fi
            echo -e "${CYAN}${PRESS_ENTER_TO_CONTINUE}${NC}" >&2
            read -r -s -t 30 2>/dev/null || true
            clear
        fi
    done
    echo "$choice"
}

# 辅助函数：执行需要sudo的命令
run_sudo_cmd() {
    local cmd="$1"
    log_message "Executing sudo command: $cmd"
    echo -e "${CYAN}Running: $cmd ${NC}" >&2
    if ! eval "$cmd"; then
        print_error "Command failed: $cmd"
        return 1
    fi
    return 0
}

# --- 环境检查与安装 ---
install_python() {
    log_message "尝试安装 Python..."
    if [ "$OS" == "Linux" ]; then
        print_status "Running apt update..."
        run_sudo_cmd "sudo apt-get update" || return 1
        print_status "Installing python3, python3-dev, python3-pip..."
        run_sudo_cmd "sudo apt-get install -y python3 python3-dev python3-pip" || return 1
    elif [ "$OS" == "macOS" ]; then
        if command_exists brew; then
            print_status "Installing python3 via Homebrew..."
            brew install python3 || return 1
        else
            print_warning "Homebrew is not installed. Please install Homebrew manually (https://brew.sh/) and retry, or install Python manually."
            return 1
        fi
    elif [ "$OS" == "Windows" ]; then
        print_warning "Windows Python installation requires manual steps or winget. See manual guide."
        return 1
    else
        print_warning "Unsupported OS for automatic Python installation. Please install Python 3.6+ manually."
        return 1
    fi

    # 重新检查 Python 命令是否可用
    if command_exists python3; then
        PYTHON_CMD="python3"
    elif command_exists python; then
        PYTHON_VERSION=$("$PYTHON_CMD" -c 'import sys; print(sys.version_info.major)' 2>/dev/null)
        if [ -n "$PYTHON_VERSION" ] && [ "$PYTHON_VERSION" -ge 3 ]; then
            PYTHON_CMD="python"
        fi
    fi
    if [ -z "$PYTHON_CMD" ]; then
        print_error "Python installation failed or could not be found in PATH."
        return 1
    fi
    log_message "Python 安装尝试完成。"
    return 0
}

install_pip() {
    log_message "尝试安装 pip..."
    if [ -n "$PYTHON_CMD" ]; then
        print_status "Ensuring pip is up-to-date..."
        if ! "$PYTHON_CMD" -m ensurepip --upgrade; then
            print_warning "Failed to ensure pip via ensurepip. Trying direct get-pip.py install."
            if ! curl -s https://bootstrap.pypa.io/get-pip.py | "$PYTHON_CMD"; then
                print_error "Failed to install pip via get-pip.py."
                return 1
            fi
        fi
        print_status "Upgrading pip..."
        "$PYTHON_CMD" -m pip install --upgrade pip || return 1
    else
        print_error "Python command not found, cannot install pip."
        return 1
    fi
    # 重新检查 pip 命令是否可用
    if command_exists pip3; then
        PIP_CMD="pip3"
    elif command_exists pip; then
        PIP_CMD="pip"
    fi
    if [ -z "$PIP_CMD" ]; then
        print_error "pip installation failed or could not be found in PATH."
        return 1
    fi
    log_message "pip 安装尝试完成。"
    return 0
}

install_git() {
    log_message "尝试安装 Git..."
    if [ "$OS" == "Linux" ]; then
        print_status "Installing Git..."
        run_sudo_cmd "sudo apt-get install -y git" || {
            if [ $? -ne 0 ] && command_exists yum; then
                run_sudo_cmd "sudo yum install -y git" || return 1
            else
                print_error "Failed to install Git. Unsupported Linux package manager or installation error."
                return 1
            fi
        }
    elif [ "$OS" == "macOS" ]; then
        if command_exists brew; then
            print_status "Installing Git via Homebrew..."
            brew install git || return 1
        else
            print_warning "Homebrew is not installed. Please install Homebrew manually (https://brew.sh/) and retry, or install Git manually."
            return 1
        fi
    elif [ "$OS" == "Windows" ]; then
        print_warning "Windows Git installation requires manual steps or winget. See manual guide."
        return 1
    else
        print_warning "Unsupported OS for automatic Git installation. Please install Git manually."
        return 1
    fi
    if ! command_exists git; then
        print_error "Git installation failed or could not be found in PATH."
        return 1
    fi
    log_message "Git 安装尝试完成。"
    return 0
}

# 检查 starsignal 命令是否在 PATH 中，并提供修复选项
check_path_for_starsignal() {
    if ! command_exists "$GAME_NAME"; then
        local reply_val=$(get_user_input "${YELLOW}${PATH_FIX_PROMPT}${NC}" "yes_no")
        if [[ "$reply_val" =~ ^[Yy]$ ]]; then
            fix_path
        fi
    fi
}

# 尝试修复 PATH 环境变量
fix_path() {
    log_message "尝试修复 PATH..."
    if [ "$OS" == "Linux" ] || [ "$OS" == "macOS" ]; then
        LOCAL_BIN="$HOME/.local/bin"
        if [[ ":$PATH:" != *":$LOCAL_BIN:"* ]]; then
            echo "export PATH=\$PATH:$LOCAL_BIN" >> "$HOME/.bashrc"
            echo "export PATH=\$PATH:$LOCAL_BIN" >> "$HOME/.zshrc"
            source "$HOME/.bashrc" >/dev/null 2>&1 || true
            source "$HOME/.zshrc" >/dev/null 2>&1 || true
            print_status "${PATH_FIX_LINUX_MACOS}"
            log_message "PATH fixed for Linux/macOS. Added $LOCAL_BIN to bashrc/zshrc."
        else
            print_status "PATH 已包含 $LOCAL_BIN。"
            log_message "PATH already contains $LOCAL_BIN."
        fi
    elif [ "$OS" == "Windows" ]; then
        print_warning "Windows PATH fixing is complex. Please refer to manual instructions if automatic fix fails."
        PYTHON_SCRIPTS_PATH=""
        if [ -n "$PYTHON_CMD" ]; then
            PYTHON_SCRIPTS_PATH=$("$PYTHON_CMD" -c "import site; print(site.USER_BASE + '/Scripts')" 2>/dev/null)
            if [ -z "$PYTHON_SCRIPTS_PATH" ] || [ ! -d "$PYTHON_SCRIPTS_PATH" ]; then
                PYTHON_SCRIPTS_PATH=$("$PYTHON_CMD" -c "import sys; print(sys.prefix + '/Scripts')" 2>/dev/null)
            fi
        fi

        if [ -n "$PYTHON_SCRIPTS_PATH" ] && [ -d "$PYTHON_SCRIPTS_PATH" ]; then
            powershell.exe -Command "[Environment]::SetEnvironmentVariable('Path', ([Environment]::GetEnvironmentVariable('Path', 'User') + ';${PYTHON_SCRIPTS_PATH//\\/\\\\}'), 'User')" >/dev/null 2>&1
            if [ $? -eq 0 ]; then
                print_status "${PATH_FIX_WINDOWS}"
                log_message "PATH fixed for Windows. Added $PYTHON_SCRIPTS_PATH to user PATH."
            else
                print_error "${PATH_FIX_FAILED}"
                log_message "PATH fix failed for Windows (PowerShell command error)."
            fi
        else
            print_error "${PATH_FIX_FAILED}"
            log_message "PATH fix failed for Windows (Python scripts path not found)."
        fi
    fi
    log_message "PATH 修复尝试完成。"
}

# 检查终端编码，并提供提示
check_terminal_encoding() {
    local encoding_ok=true
    
    if [ "$OS" == "Linux" ] || [ "$OS" == "macOS" ]; then
        local current_lang=$(locale | grep -E 'LC_CTYPE|LANG' | head -n 1 | cut -d'=' -f2 | tr -d '"' | cut -d'.' -f2 | tr '[:lower:]' '[:upper:]')
        if [[ "$current_lang" != "UTF-8" ]]; then
            encoding_ok=false
        fi
    elif [ "$OS" == "Windows" ]; then
        local current_lang_windows=$(echo $LANG | cut -d'.' -f2 | tr '[:lower:]' '[:upper:]')
        if [ -z "$current_lang_windows" ] || [[ "$current_lang_windows" != "UTF-8" ]]; then
            local chcp_output=$(chcp 2>/dev/null | grep -oE '[0-9]+')
            if [[ "$chcp_output" != "65001" ]]; then
                encoding_ok=false
            fi
        fi
    fi

    if ! "$encoding_ok"; then
        echo
        print_warning "${ENCODING_WARNING}"
        echo
    fi
}

# 修复存档文件权限
fix_save_permissions() {
    print_status "${PERMISSION_FIX}"
    log_message "${PERMISSION_FIX}"
    if [ "$OS" == "Linux" ] || [ "$OS" == "macOS" ]; then
        if [ -f "${DATA_FILE}" ]; then
            chmod 666 "${DATA_FILE}" || log_message "Failed chmod on $DATA_FILE"
        fi
        for i in {1..3}; do
            if [ -f "${SAVE_FILE_PREFIX}${i}.json" ]; then
                chmod 666 "${SAVE_FILE_PREFIX}${i}.json" || log_message "Failed chmod on ${SAVE_FILE_PREFIX}${i}.json"
            fi
        done
        if [ $? -eq 0 ]; then
            print_status "${PERMISSION_SUCCESS}"
            log_message "${PERMISSION_SUCCESS}"
        else
            print_error "${PERMISSION_FAILED}"
            log_message "${PERMISSION_FAILED}"
        fi
    elif [ "$OS" == "Windows" ]; then
        local data_file_exists=$(powershell.exe -Command "Test-Path \"$env:USERPROFILE\\.starsignal_data.json\"" 2>/dev/null)
        local save_files_exist=$(powershell.exe -Command "Test-Path \"$env:USERPROFILE\\.starsignal_save_*.json\"" 2>/dev/null)

        local success=0
        if [[ "$data_file_exists" == "True" || "$save_files_exist" == "True" ]]; then
            if powershell.exe -Command "icacls \"$env:USERPROFILE\\.starsignal*\" /grant Everyone:F" >/dev/null 2>&1; then
                success=1
            fi
        else
            success=1
        fi

        if [ "$success" -eq 1 ]; then
            print_status "${PERMISSION_SUCCESS}"
            log_message "${PERMISSION_SUCCESS}"
        else
            print_error "${PERMISSION_FAILED}"
            log_message "${PERMISSION_FAILED}"
        fi
    fi
}

# 检查游戏是否已安装
is_installed() {
    command_exists "$GAME_NAME"
}

# --- 核心功能函数 (do_*) ---

# 执行环境检查与安装依赖
run_environment_setup() {
    print_status "${INSTALLING_DEPENDENCIES}"
    if ! install_python; then
        print_error "Python installation/check failed. Cannot proceed."
        return 1
    fi

    if ! install_pip; then
        print_error "pip installation/check failed. Cannot proceed."
        return 1
    fi

    if ! install_git; then
        print_error "Git installation/check failed. Cannot proceed."
        return 1
    fi

    check_path_for_starsignal
    check_terminal_encoding
    
    return 0
}

# 安装游戏
do_install_game() {
    local branch=$1
    if ! run_environment_setup; then
        print_error "Environment setup failed. Installation aborted."
        log_message "Environment setup failed. Installation aborted."
        return 1
    fi

    print_status "${INSTALLING_GAME}"
    log_message "开始安装游戏到 $branch 分支..."
    if "$PIP_CMD" install --user "git+${REPO_URL}@${branch}"; then
        print_status "${INSTALL_SUCCESS}"
        log_message "${INSTALL_SUCCESS}"
        fix_save_permissions
    else
        print_error "${INSTALL_FAILED}"
        log_message "${INSTALL_FAILED}"
        return 1
    fi
    return 0
}

# 更新游戏
do_update_game() {
    if ! run_environment_setup; then
        print_error "Environment setup failed. Cannot proceed with update."
        log_message "Environment setup failed. Update aborted."
        return 1
    fi

    local branch=$(get_user_input "${YELLOW}${CHOOSE_BRANCH}${NC}" "text")
    branch=${branch:-main}

    print_status "${UPDATE_GAME}"
    log_message "开始更新游戏到 $branch 分支..."
    if "$PIP_CMD" install --user --upgrade --force-reinstall "git+${REPO_URL}@${branch}"; then
        print_status "${UPDATE_SUCCESS}"
        log_message "${UPDATE_SUCCESS}"
        fix_save_permissions
    else
        print_error "${UPDATE_FAILED}"
        log_message "${UPDATE_FAILED}"
        return 1
    fi
    return 0
}

# 修复安装
do_repair_game() {
    if ! run_environment_setup; then
        print_error "Environment setup failed. Cannot proceed with repair."
        log_message "Environment setup failed. Repair aborted."
        return 1
    fi

    print_status "${REPAIR_GAME}"
    log_message "尝试修复游戏安装..."
    if "$PIP_CMD" install --user --force-reinstall "git+${REPO_URL}@main"; then
        print_status "${REPAIR_SUCCESS}"
        log_message "${REPAIR_SUCCESS}"
        fix_save_permissions
    else
        print_error "${REPAIR_FAILED}"
        log_message "${REPAIR_FAILED}"
        return 1
    fi
    return 0
}

# 清理存档
do_clean_saves() {
    local reply_val=$(get_user_input "${YELLOW}${CONFIRM_CLEAN}${NC}" "yes_no")
    if [[ "$reply_val" =~ ^[Yy]$ ]]; then
        print_status "${CLEAN_SAVES}"
        log_message "开始清理存档和成就数据..."
        rm -f "$DATA_FILE"
        for i in {1..3}; do
            rm -f "${SAVE_FILE_PREFIX}${i}.json"
        done

        if [ ! -f "$DATA_FILE" ] && [ ! -f "${SAVE_FILE_PREFIX}1.json" ] && [ ! -f "${SAVE_FILE_PREFIX}2.json" ] && [ ! -f "${SAVE_FILE_PREFIX}3.json" ]; then
            print_status "${CLEAN_SUCCESS}"
            log_message "${CLEAN_SUCCESS}"
        else
            print_error "${CLEAN_FAILED}"
            log_message "${CLEAN_FAILED}"
            return 1
        fi
    else
        print_status "${CANCELLED}"
        log_message "Clean saves cancelled."
        return 1
    fi
    return 0
}

# 卸载游戏
do_uninstall_game() {
    local reply_val=$(get_user_input "${YELLOW}${CONFIRM_UNINSTALL}${NC}" "yes_no")
    if [[ "$reply_val" =~ ^[Yy]$ ]]; then
        print_status "${UNINSTALL_GAME}"
        log_message "开始卸载游戏..."
        
        local uninstall_successful=0
        if command_exists "$PIP_CMD"; then
            if "$PIP_CMD" uninstall -y "$GAME_NAME"; then
                uninstall_successful=1
            else
                print_error "Pip uninstall failed. Trying manual file removal."
                log_message "Pip uninstall failed for $GAME_NAME."
            fi
        else
            print_warning "pip command not found. Cannot automatically uninstall via pip. Attempting manual removal of files."
            log_message "Pip command not found for uninstall."
        fi

        rm -f "$DATA_FILE"
        for i in {1..3}; do
            rm -f "${SAVE_FILE_PREFIX}${i}.json"
        done

        if ! is_installed; then
            print_status "${UNINSTALL_SUCCESS}"
            log_message "${UNINSTALL_SUCCESS}"
            return 0
        else
            print_error "${UNINSTALL_FAILED}"
            log_message "${UNINSTALL_FAILED}"
            return 1
        fi
    else
        print_status "${CANCELLED}"
        log_message "Uninstall cancelled."
        return 1
    fi
}

# 启动游戏函数
do_start_game() {
    print_status "准备启动游戏..."
    if ! is_installed; then
        print_error "游戏未安装。请先安装游戏再启动。"
        return 1
    fi
    
    local game_options=$(get_user_input "${BLUE}${GAME_START_OPTIONS}${NC}" "text")
    
    print_status "正在启动游戏: starsignal ${game_options}"
    log_message "Starting game: starsignal ${game_options}"
    
    if command_exists starsignal; then
        print_warning "${GAME_START_NOTE}"
        starsignal ${game_options} < /dev/tty > /dev/tty 2>&1
        if [ $? -ne 0 ]; then
            print_error "游戏运行出错。请检查上述错误信息，或尝试解决终端兼容性问题。"
            log_message "Game exited with error status."
            return 1
        fi
    else
        print_error "starsignal 命令未找到。请确保 PATH 环境变量正确，并重启终端后重试。"
        return 1
    fi
    print_status "游戏运行结束。"
    return 0
}

# 显示手动安装指南函数
do_show_manual_guide() {
    clear
    echo -e "${CYAN}=================================================================="
    echo "${MANUAL_INSTALL_HEADER}"
    echo "==================================================================${NC}"
    echo ""
    echo -e "${GREEN}${MANUAL_INSTALL_REQUIREMENTS}${NC}"
    echo "- ${MANUAL_INSTALL_PYTHON_PIP}"
    echo "- ${MANUAL_INSTALL_GIT}"
    echo ""
    echo -e "${GREEN}${MANUAL_INSTALL_LINUX_MACOS_STEPS}${NC}"
    echo "1. 安装 Python 3.6+ 和 pip："
    echo "   ${MANUAL_INSTALL_PYTHON_LINUX}"
    echo "2. 安装 Git："
    echo "   ${MANUAL_INSTALL_GIT_LINUX}"
    echo "3. 确保 pip 和 PATH 正确："
    echo "   ${MANUAL_INSTALL_PIP_PATH}"
    echo ""
    echo -e "${GREEN}${MANUAL_INSTALL_WINDOWS_STEPS}${NC}"
    echo "1. 安装 Python 3.6+ 和 pip："
    echo "   ${MANUAL_INSTALL_WINDOWS_PYTHON}"
    echo "2. 安装 Git for Windows："
    echo "   ${MANUAL_INSTALL_WINDOWS_GIT}"
    echo "3. 手动添加 PATH (如果 'starsignal' 命令无法找到)："
    echo "   ${MANUAL_INSTALL_WINDOWS_PATH}"
    echo ""
    echo -e "${GREEN}${MANUAL_INSTALL_GAME_CORE}${NC}"
    echo "1. 安装游戏核心（稳定版）："
    echo "   ${MANUAL_INSTALL_STABLE_VERSION}"
    echo "2. 安装游戏核心（开发版）："
    echo "   ${MANUAL_INSTALL_DEV_VERSION}"
    echo "3. 安装彩色输出支持（推荐）："
    echo "   ${MANUAL_INSTALL_COLORAMA}"
    echo ""
    echo -e "${GREEN}${MANUAL_INSTALL_RUN_GAME}${NC}"
    echo ""
    echo -e "${CYAN}==================================================================${NC}"
    echo ""
    get_user_input "${CYAN}${PRESS_ENTER_TO_CONTINUE}${NC}" "text" > /dev/null
}

# --- 主菜单 ---
show_main_menu_and_get_choice() {
    local choice=""
    local valid_choice=false

    while ! "$valid_choice"; do
        clear
        if ! "$IS_TERMINAL"; then
            print_warning "${WARNING_PIPE}"
            log_message "Non-terminal detected, continuing with warning."
        fi

        # Print menu header
        echo -e "${CYAN}╔══════════════════════════════════════╗${NC}" >&2
        echo -e "${CYAN}║    ${INSTALLATION_MENU}           ${NC}" >&2
        echo -e "${CYAN}╚══════════════════════════════════════╝${NC}" >&2
        echo "" >&2
        log_message "Displaying main menu"

        # Print menu options based on installation status
        if is_installed; then
            echo -e "${GREEN}${ALREADY_INSTALLED}${NC}" >&2
            echo "1) ${UPDATE_GAME}" >&2
            echo "2) ${REPAIR_GAME}" >&2
            echo "3) ${CLEAN_SAVES}" >&2
            echo "4) ${UNINSTALL_GAME}" >&2
            echo "5) ${START_GAME}" >&2
            echo "6) ${SHOW_MANUAL}" >&2
            echo "0) ${EXIT_OPTION}" >&2
        else
            echo -e "${YELLOW}${NOT_INSTALLED}${NC}" >&2
            echo "1) ${INSTALL_MAIN}" >&2
            echo "2) ${INSTALL_DEV}" >&2
            echo "3) ${SHOW_MANUAL}" >&2
            echo "0) ${EXIT_OPTION}" >&2
        fi

        # Add spacing and prompt
        echo "" >&2
        echo -e "${BLUE}${ENTER_CHOICE}${NC}" >&2
        sync # Ensure menu is fully displayed
        sleep 0.1 # Brief delay to ensure terminal rendering

        # Get user input
        if is_installed; then
            choice=$(get_user_input "" "menu_choice_installed")
        else
            choice=$(get_user_input "" "menu_choice_not_installed")
        fi
        log_message "Menu choice received: $choice"

        # Validate choice
        if is_installed; then
            case "$choice" in
                0|1|2|3|4|5|6) valid_choice=true ;;
                *) print_error "${INVALID_CHOICE}" ;;
            esac
        else
            case "$choice" in
                0|1|2|3) valid_choice=true ;;
                *) print_error "${INVALID_CHOICE}" ;;
            esac
        fi

        if ! "$valid_choice"; then
            log_message "Invalid choice, retrying menu display"
            echo -e "${CYAN}${PRESS_ENTER_TO_CONTINUE}${NC}" >&2
            read -r -s -t 30 2>/dev/null || true
        fi
    done
    
    echo "$choice"
}

# --- 脚本入口点 ---
main() {
    # 清空并开始记录新的日志会话
    > "$LOG_FILE"
    log_message "----------------------------------------------------"
    log_message "星际迷航：信号解码 管理脚本启动 v${SCRIPT_VERSION}"
    log_message "操作系统: $OS"
    log_message "语言设置: $LANG_SET"
    log_message "运行用户: $(whoami)"
    log_message "终端类型: $TERM"
    log_message "----------------------------------------------------"

    check_terminal_encoding

    while true; do
        local user_choice=$(show_main_menu_and_get_choice)
        log_message "User selected: $user_choice"
        
        clear

        if is_installed; then
            case "$user_choice" in
                1) do_update_game ;;
                2) do_repair_game ;;
                3) do_clean_saves ;;
                4) do_uninstall_game ;;
                5) do_start_game ;;
                6) do_show_manual_guide ;;
                0) exit 0 ;;
                *) print_error "${INVALID_CHOICE}" ;;
            esac
        else
            case "$user_choice" in
                1) do_install_game main ;;
                2) do_install_game dev ;;
                3) do_show_manual_guide ;;
                0) exit 0 ;;
                *) print_error "${INVALID_CHOICE}" ;;
            esac
        fi
        
        echo
        echo -e "${CYAN}${PRESS_ENTER_TO_CONTINUE}${NC}" >&2
        read -r -s -t 30 || true
        echo
    done
}

main "$@"
