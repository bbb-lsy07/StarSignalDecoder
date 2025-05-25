#!/bin/bash

# 星际迷航：信号解码 游戏管理脚本 v1.7.2beta
# 作者：bbb-lsy07
# 邮箱：lisongyue0125@163.com

# 定义颜色
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

# 检查当前是否在终端运行
IS_TERMINAL=true
if ! [ -t 0 ]; then
  IS_TERMINAL=false
fi

# 获取当前脚本的语言设置，默认中文
LANG_SET="zh"
# 检查第一个参数是否为 --lang 并且有第二个参数作为语言代码
if [ "$#" -ge 2 ] && [ "$1" == "--lang" ]; then
    LANG_SET="$2"
    shift 2 # 移除 --lang 和语言代码参数
fi

# 文本定义 (根据语言设置)
# 使用函数来设置变量，以避免 declare -A 的兼容性问题
set_texts() {
    if [ "$1" == "en" ]; then
        # English Text
        INSTALLATION_MENU="Installation and Management Menu"
        ALREADY_INSTALLED="StarSignalDecoder is already installed."
        NOT_INSTALLED="StarSignalDecoder is not installed."
        INSTALL_MAIN="Install Stable Version (main branch)"
        INSTALL_DEV="Install Development Version (dev branch)"
        UPDATE_GAME="Update Game"
        REPAIR_GAME="Repair Installation"
        CLEAN_SAVES="Clean Save Data and Achievements"
        UNINSTALL_GAME="Uninstall Game"
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
        INSTALL_FAILED="Installation failed. Please check the output above for details."
        UPDATE_SUCCESS="StarSignalDecoder updated successfully!"
        UPDATE_FAILED="Update failed. Please check the output above for details."
        REPAIR_SUCCESS="StarSignalDecoder repaired successfully!"
        REPAIR_FAILED="Repair failed. Please check the output above for details."
        CLEAN_SUCCESS="Save data and achievements cleaned successfully!"
        CLEAN_FAILED="Failed to clean save data. Check permissions or try manually."
        UNINSTALL_SUCCESS="StarSignalDecoder uninstalled successfully! Save data also removed."
        UNINSTALL_FAILED="Uninstallation failed. Please check the output above for details."
        PERMISSION_FIX="Attempting to fix save file permissions..."
        PERMISSION_SUCCESS="Save file permissions fixed."
        PERMISSION_FAILED="Failed to fix save file permissions. Please fix manually using 'chmod 666 ~/.starsignal*' or 'icacls %USERPROFILE%\.starsignal* /grant Everyone:F'."
        PATH_FIX_PROMPT="Python scripts directory might not be in your PATH. Do you want to try fixing it? (y/n): "
        PATH_FIX_LINUX_MAC="Fixing PATH for Linux/macOS. Please source your shell config (e.g., 'source ~/.bashrc') or restart your terminal for changes to take effect."
        PATH_FIX_WINDOWS="Attempting to fix PATH for Windows. You may need to restart PowerShell/Git Bash or your system for changes to take effect."
        PATH_FIX_FAILED="Failed to fix PATH. Please add Python's Scripts directory to your system's PATH manually."
        WARNING_PIPE="WARNING: This script is designed for interactive use. Running via pipe (e.g., curl ... | sh) may cause input issues. Please download the script and run it locally: ${YELLOW}curl -s ${REPO_URL/StarSignalDecoder.git/main/starsignal_manager.sh} -o starsignal_manager.sh && chmod +x starsignal_manager.sh && ./starsignal_manager.sh${NC}"
        CONFIRM_UNINSTALL="Are you sure you want to uninstall StarSignalDecoder and delete all save data? (y/n): "
        CONFIRM_CLEAN="Are you sure you want to delete all save data and achievements? This cannot be undone. (y/n): "
        CANCELLED="Operation cancelled."
        CHOOSE_BRANCH="Choose branch (main/dev) [main]: "
        CHECKING_TERMINAL_ENCODING="Checking terminal encoding..."
        ENCODING_WARNING="Your terminal encoding might not be UTF-8. This can cause display issues. Please set your terminal to UTF-8 (e.g., ${YELLOW}export LANG=en_US.UTF-8${NC} or ${YELLOW}chcp 65001${NC} on Windows)."
        PRESS_ANY_KEY="Press any key to continue..."
    else
        # Chinese Text
        INSTALLATION_MENU="安装与管理菜单"
        ALREADY_INSTALLED="星际迷航：信号解码 已安装。"
        NOT_INSTALLED="星际迷航：信号解码 未安装。"
        INSTALL_MAIN="安装稳定版（main 分支）"
        INSTALL_DEV="安装开发版（dev 分支）"
        UPDATE_GAME="更新游戏"
        REPAIR_GAME="修复安装"
        CLEAN_SAVES="清理存档和成就数据"
        UNINSTALL_GAME="卸载游戏"
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
        INSTALL_FAILED="安装失败。请查看终端输出获取详情。"
        UPDATE_SUCCESS="星际迷航：信号解码 更新成功！"
        UPDATE_FAILED="更新失败。请查看终端输出获取详情。"
        REPAIR_SUCCESS="星际迷航：信号解码 修复成功！"
        REPAIR_FAILED="修复失败。请查看终端输出获取详情。"
        CLEAN_SUCCESS="存档和成就数据清理成功！"
        CLEAN_FAILED="清理存档失败。请检查文件权限或手动尝试。"
        UNINSTALL_SUCCESS="星际迷航：信号解码 卸载成功！存档数据已移除。"
        UNINSTALL_FAILED="卸载失败。请查看终端输出获取详情。"
        PERMISSION_FIX="正在尝试修复存档文件权限..."
        PERMISSION_SUCCESS="存档文件权限已修复。"
        PERMISSION_FAILED="无法修复存档文件权限。请手动运行：'chmod 666 ~/.starsignal*' (Linux/macOS) 或 'icacls %USERPROFILE%\\.starsignal* /grant Everyone:F' (Windows)。"
        PATH_FIX_PROMPT="Python 脚本目录可能不在您的 PATH 环境变量中。是否尝试修复？(y/n): "
        PATH_FIX_LINUX_MAC="正在修复 Linux/macOS 的 PATH。请重新加载您的 shell 配置（例如 'source ~/.bashrc'）或重启终端以使更改生效。"
        PATH_FIX_WINDOWS="正在尝试修复 Windows 的 PATH。您可能需要重启 PowerShell/Git Bash 或您的系统以使更改生效。"
        PATH_FIX_FAILED="无法修复 PATH。请手动将 Python 的 Scripts 目录添加到系统 PATH 环境变量中。"
        WARNING_PIPE="警告：本脚本设计为交互式使用。通过管道运行（例如 curl ... | sh）可能导致输入问题。请下载脚本后在本地运行：${YELLOW}curl -s ${REPO_URL/StarSignalDecoder.git/main/starsignal_manager.sh} -o starsignal_manager.sh && chmod +x starsignal_manager.sh && ./starsignal_manager.sh${NC}"
        CONFIRM_UNINSTALL="您确定要卸载 星际迷航：信号解码 并删除所有存档数据吗？(y/n): "
        CONFIRM_CLEAN="您确定要删除所有存档和成就数据吗？此操作无法撤销。(y/n): "
        CANCELLED="操作已取消。"
        CHOOSE_BRANCH="选择分支 (main/dev) [main]: "
        CHECKING_TERMINAL_ENCODING="正在检查终端编码..."
        ENCODING_WARNING="您的终端编码可能不是 UTF-8。这可能导致显示问题。请将终端设置为 UTF-8（例如 ${YELLOW}export LANG=zh_CN.UTF-8${NC} 或 Windows 上 ${YELLOW}chcp 65001${NC}）。"
        PRESS_ANY_KEY="按任意键继续..."
    fi
}

# 调用函数设置文本
set_texts "$LANG_SET"

# --- 辅助函数 ---

# log_message 函数将输出到终端，并记录到日志文件
log_message() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOG_FILE"
}

# print_status/warning/error 函数只输出到终端，不记录到日志文件
print_status() {
    echo -e "${GREEN}==> $1 ${NC}"
    log_message "Status: $1" # 同时记录到日志
}

print_warning() {
    echo -e "${YELLOW}警告：$1 ${NC}"
    log_message "Warning: $1" # 同时记录到日志
}

print_error() {
    echo -e "${RED}错误：$1 ${NC}"
    log_message "Error: $1" # 同时记录到日志
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

# 检查 Python 环境
check_python_env() {
    print_status "${CHECKING_ENV}"
    log_message "${CHECKING_ENV}"

    PYTHON_CMD=""
    if command_exists python3; then
        PYTHON_CMD="python3"
        print_status "${PYTHON_FOUND}"
    elif command_exists python; then
        PYTHON_VERSION=$(python -c 'import sys; print(sys.version_info.major)')
        if [ "$PYTHON_VERSION" -ge 3 ]; then
            PYTHON_CMD="python"
            print_status "${PYTHON_FOUND}"
        fi
    fi

    if [ -z "$PYTHON_CMD" ]; then
        print_warning "${PYTHON_NOT_FOUND}"
        install_python # 此函数将直接输出到终端
        if [ -z "$PYTHON_CMD" ]; then
            print_error "${INSTALL_FAILED}"
            return 1 # 确保父函数知道安装失败
        fi
    fi

    PIP_CMD=""
    if command_exists pip3; then
        PIP_CMD="pip3"
        print_status "${PIP_FOUND}"
    elif command_exists pip; then
        PIP_CMD="pip"
        print_status "${PIP_FOUND}"
    fi

    if [ -z "$PIP_CMD" ]; then
        print_warning "${PIP_NOT_FOUND}"
        install_pip # 此函数将直接输出到终端
        if [ -z "$PIP_CMD" ]; then
            print_error "${INSTALL_FAILED}"
            return 1 # 确保父函数知道安装失败
        fi
    fi

    if ! command_exists git; then
        print_warning "${GIT_NOT_FOUND}"
        install_git # 此函数将直接输出到终端
        if ! command_exists git; then
            print_error "${INSTALL_FAILED}"
            return 1 # 确保父函数知道安装失败
        fi
    else
        print_status "${GIT_FOUND}"
    fi

    check_path_for_starsignal
    check_terminal_encoding
    return 0 # 环境检查成功
}

# 辅助函数：执行需要sudo的命令
run_sudo_cmd() {
    local cmd="$1"
    log_message "Executing sudo command: $cmd"
    if ! eval "$cmd"; then
        print_error "Command failed: $cmd"
        return 1
    fi
    return 0
}

install_python() {
    log_message "尝试安装 Python..." # 仅记录开始信息
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
        if command_exists winget; then
            print_status "Installing Python 3 via winget..."
            winget install --id Python.Python.3 --source winget || return 1
            print_status "Please ensure Python is added to your PATH environment variable during installation or manually."
        else
            print_warning "winget is not installed. Please manually download and install Python from https://www.python.org/downloads/ and ensure 'Add Python to PATH' is checked during installation."
            return 1
        fi
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
    log_message "尝试安装 pip..." # 仅记录开始信息
    if [ -n "$PYTHON_CMD" ]; then
        print_status "Ensuring pip is up-to-date..."
        if ! "$PYTHON_CMD" -m ensurepip --upgrade; then
            print_error "Failed to ensure pip. Trying direct pip install."
            # Fallback for some systems where ensurepip might struggle
            curl -s https://bootstrap.pypa.io/get-pip.py | "$PYTHON_CMD" || return 1
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
    log_message "pip 安装尝试完成。" # 仅记录结束信息
    return 0
}

install_git() {
    log_message "尝试安装 Git..." # 仅记录开始信息
    if [ "$OS" == "Linux" ]; then
        print_status "Installing Git..."
        run_sudo_cmd "sudo apt-get install -y git" || return 1 # Debian/Ubuntu
        if [ $? -ne 0 ] && command_exists yum; then # Fallback for CentOS/RHEL
            run_sudo_cmd "sudo yum install -y git" || return 1
        fi
    elif [ "$OS" == "macOS" ]; then
        if command_exists brew; then
            print_status "Installing Git via Homebrew..."
            brew install git || return 1
        else
            print_warning "Homebrew is not installed. Please install Homebrew manually (https://brew.sh/) and retry, or install Git manually."
            return 1
        fi
    elif [ "$OS" == "Windows" ]; then
        if command_exists winget; then
            print_status "Installing Git via winget..."
            winget install --id Git.Git --source winget || return 1
            print_status "Please ensure Git is added to your PATH environment variable during installation or manually."
        else
            print_warning "winget is not installed. Please manually download and install Git for Windows from https://git-scm.com/download/win."
            return 1
        fi
    else
        print_warning "Unsupported OS for automatic Git installation. Please install Git manually."
        return 1
    fi
    if ! command_exists git; then
        print_error "Git installation failed or could not be found in PATH."
        return 1
    fi
    log_message "Git 安装尝试完成。" # 仅记录结束信息
    return 0
}

# 检查 starsignal 命令是否在 PATH 中
check_path_for_starsignal() {
    if ! command_exists "$GAME_NAME"; then
        read -r -p "$(echo -e "${YELLOW}${PATH_FIX_PROMPT}${NC}")" -n 1 REPLY
        echo # 添加换行
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            fix_path
        fi
    fi
}

fix_path() {
    log_message "尝试修复 PATH..."
    if [ "$OS" == "Linux" ] || [ "$OS" == "macOS" ]; then
        LOCAL_BIN="$HOME/.local/bin"
        if [[ ":$PATH:" != *":$LOCAL_BIN:"* ]]; then
            # 尝试写入 .bashrc 和 .zshrc
            echo "export PATH=\$PATH:$LOCAL_BIN" >> "$HOME/.bashrc"
            echo "export PATH=\$PATH:$LOCAL_BIN" >> "$HOME/.zshrc"
            # 立即尝试加载以影响当前会话
            source "$HOME/.bashrc" >/dev/null 2>&1 || true
            source "$HOME/.zshrc" >/dev/null 2>&1 || true
            print_status "${PATH_FIX_LINUX_MAC}"
            log_message "PATH fixed for Linux/macOS. Added $LOCAL_BIN to bashrc/zshrc."
        else
            print_status "PATH 已包含 $LOCAL_BIN。"
            log_message "PATH already contains $LOCAL_BIN."
        fi
    elif [ "$OS" == "Windows" ]; then
        PYTHON_SCRIPTS_PATH=""
        if [ -n "$PYTHON_CMD" ]; then
            PYTHON_SCRIPTS_PATH=$("$PYTHON_CMD" -c "import site; print(site.USER_BASE + '/Scripts')" 2>/dev/null)
            if [ -z "$PYTHON_SCRIPTS_PATH" ] || [ ! -d "$PYTHON_SCRIPTS_PATH" ]; then
                PYTHON_SCRIPTS_PATH=$("$PYTHON_CMD" -c "import sys; print(sys.prefix + '/Scripts')" 2>/dev/null)
            fi
        fi

        if [ -n "$PYTHON_SCRIPTS_PATH" ] && [ -d "$PYTHON_SCRIPTS_PATH" ]; then
            # PowerShell 命令来修改用户环境变量
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

# 检查终端编码
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
        echo # 添加换行
        print_warning "${ENCODING_WARNING}"
        echo # 添加换行
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
        if powershell.exe -Command "If (Test-Path \"$env:USERPROFILE\\.starsignal_data.json\") { icacls \"$env:USERPROFILE\\.starsignal_data.json\" /grant Everyone:F }" >/dev/null 2>&1 && \
           powershell.exe -Command "If (Test-Path \"$env:USERPROFILE\\.starsignal_save_*.json\") { icacls \"$env:USERPROFILE\\.starsignal_save_*.json\" /grant Everyone:F }" >/dev/null 2>&1; then
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

# --- 核心功能函数 ---

# 安装游戏
install_game() {
    local branch=$1
    print_status "${INSTALLING_DEPENDENCIES}"
    # 检查环境，如果环境检查失败，则不继续安装
    if ! check_python_env; then
        print_error "Environment check failed. Cannot proceed with installation."
        log_message "Environment check failed. Installation aborted."
        return 1
    fi

    print_status "${INSTALLING_GAME}"
    log_message "开始安装游戏到 $branch 分支..."
    # pip install 命令的输出将直接显示在终端
    if "$PIP_CMD" install --user "git+${REPO_URL}@${branch}"; then
        print_status "${INSTALL_SUCCESS}"
        log_message "${INSTALL_SUCCESS}"
        fix_save_permissions # 尝试修复新安装的权限
    else
        print_error "${INSTALL_FAILED}"
        log_message "${INSTALL_FAILED}"
    fi
}

# 更新游戏
update_game() {
    print_status "${CHECKING_ENV}"
    if ! check_python_env; then
        print_error "Environment check failed. Cannot proceed with update."
        log_message "Environment check failed. Update aborted."
        return 1
    fi

    local branch
    read -r -p "$(echo -e "${YELLOW}${CHOOSE_BRANCH}${NC}")" branch
    branch=${branch:-main} # 默认是 main 分支

    print_status "${UPDATE_GAME}"
    log_message "开始更新游戏到 $branch 分支..."
    # pip install 命令的输出将直接显示在终端
    if "$PIP_CMD" install --user --upgrade --force-reinstall "git+${REPO_URL}@${branch}"; then
        print_status "${UPDATE_SUCCESS}"
        log_message "${UPDATE_SUCCESS}"
        fix_save_permissions # 尝试修复更新后的权限
    else
        print_error "${UPDATE_FAILED}"
        log_message "${UPDATE_FAILED}"
    fi
}

# 修复安装
repair_game() {
    print_status "${CHECKING_ENV}"
    if ! check_python_env; then
        print_error "Environment check failed. Cannot proceed with repair."
        log_message "Environment check failed. Repair aborted."
        return 1
    fi

    print_status "${REPAIR_GAME}"
    log_message "尝试修复游戏安装..."
    # 强制重装以修复可能的文件损坏
    if "$PIP_CMD" install --user --force-reinstall "git+${REPO_URL}@main"; then
        print_status "${REPAIR_SUCCESS}"
        log_message "${REPAIR_SUCCESS}"
        fix_save_permissions # 修复权限
    else
        print_error "${REPAIR_FAILED}"
        log_message "${REPAIR_FAILED}"
    fi
}

# 清理存档
clean_saves() {
    read -r -p "$(echo -e "${YELLOW}${CONFIRM_CLEAN}${NC}")" -n 1 REPLY
    echo # 添加换行
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "${CLEAN_SAVES}"
        log_message "开始清理存档和成就数据..."
        rm -f "$DATA_FILE" # 不再重定向
        for i in {1..3}; do
            rm -f "${SAVE_FILE_PREFIX}${i}.json" # 不再重定向
        done

        if [ ! -f "$DATA_FILE" ] && [ ! -f "${SAVE_FILE_PREFIX}1.json" ] && [ ! -f "${SAVE_FILE_PREFIX}2.json" ] && [ ! -f "${SAVE_FILE_PREFIX}3.json" ]; then
            print_status "${CLEAN_SUCCESS}"
            log_message "${CLEAN_SUCCESS}"
        else
            print_error "${CLEAN_FAILED}"
            log_message "${CLEAN_FAILED}"
        fi
    else
        print_status "${CANCELLED}"
        log_message "Clean saves cancelled."
    fi
}

# 卸载游戏
uninstall_game() {
    read -r -p "$(echo -e "${YELLOW}${CONFIRM_UNINSTALL}${NC}")" -n 1 REPLY
    echo # 添加换行
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "${UNINSTALL_GAME}"
        log_message "开始卸载游戏..."
        
        # 尝试卸载游戏
        if command_exists "$PIP_CMD"; then
            if ! "$PIP_CMD" uninstall -y "$GAME_NAME"; then
                print_error "Pip uninstall failed. Trying manual file removal."
                log_message "Pip uninstall failed for $GAME_NAME."
            fi
        else
            print_warning "pip command not found. Cannot automatically uninstall via pip. Attempting manual removal of files."
            log_message "Pip command not found for uninstall."
        fi

        # 移除数据文件和存档文件
        rm -f "$DATA_FILE"
        for i in {1..3}; do
            rm -f "${SAVE_FILE_PREFIX}${i}.json"
        done

        # 最终检查是否已卸载
        if ! is_installed; then
            print_status "${UNINSTALL_SUCCESS}"
            log_message "${UNINSTALL_SUCCESS}"
        else
            print_error "${UNINSTALL_FAILED}"
            log_message "${UNINSTALL_FAILED}"
        fi
    else
        print_status "${CANCELLED}"
        log_message "Uninstall cancelled."
    fi
}

# --- 主菜单 ---
show_menu() {
    if ! "$IS_TERMINAL"; then
        print_warning "${WARNING_PIPE}"
        return
    fi

    echo -e "${CYAN}╔══════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║    ${INSTALLATION_MENU}           ${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════╝${NC}"

    if is_installed; then
        echo -e "${GREEN}${ALREADY_INSTALLED}${NC}"
        echo "1) ${UPDATE_GAME}"
        echo "2) ${REPAIR_GAME}"
        echo "3) ${CLEAN_SAVES}"
        echo "4) ${UNINSTALL_GAME}"
        echo "0) ${EXIT_OPTION}"
        echo -en "${BLUE}${ENTER_CHOICE}${NC}"
        read -r choice # Read user input
        echo # Add newline after input

        case "$choice" in
            1) update_game ;;
            2) repair_game ;;
            3) clean_saves ;;
            4) uninstall_game ;;
            0) exit 0 ;;
            *) print_error "${INVALID_CHOICE}" ;;
        esac
    else
        echo -e "${YELLOW}${NOT_INSTALLED}${NC}"
        echo "1) ${INSTALL_MAIN}"
        echo "2) ${INSTALL_DEV}"
        echo "0) ${EXIT_OPTION}"
        echo -en "${BLUE}${ENTER_CHOICE}${NC}"
        read -r choice # Read user input
        echo # Add newline after input

        case "$choice" in
            1) install_game main ;;
            2) install_game dev ;;
            0) exit 0 ;;
            *) print_error "${INVALID_CHOICE}" ;;
        esac
    fi
}

# --- 脚本入口点 ---
main() {
    # 如果脚本通过管道运行，打印警告并退出
    if ! "$IS_TERMINAL"; then
        print_warning "${WARNING_PIPE}"
        exit 1
    fi

    # 清空并开始记录新的日志会话
    > "$LOG_FILE"
    log_message "----------------------------------------------------"
    log_message "星际迷航：信号解码 管理脚本启动 v1.7.2"
    log_message "操作系统: $OS"
    log_message "语言设置: $LANG_SET"
    log_message "----------------------------------------------------"

    # 在显示菜单前，先检查并打印编码警告
    check_terminal_encoding

    while true; do
        show_menu
        echo # 添加空行，视觉效果
        echo -e "${CYAN}${PRESS_ANY_KEY}${NC}"
        read -n 1 -s # 等待按键
        echo # 添加换行
    done
}

main "$@"
