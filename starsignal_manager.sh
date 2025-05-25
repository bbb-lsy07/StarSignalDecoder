#!/bin/bash

# 星际迷航：信号解码 游戏管理脚本 v1.7.2
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
LOG_FILE="$HOME/.starsignal_manager.log" # 更改日志文件名为 manager.log，仅记录脚本自身运行信息
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
        INSTALLATION_MENU="Installation Menu"
        ALREADY_INSTALLED="StarSignalDecoder is already installed."
        NOT_INSTALLED="StarSignalDecoder is not installed."
        INSTALL_MAIN="Install Stable Version (main branch)"
        INSTALL_DEV="Install Development Version (dev branch)"
        UPDATE_GAME="Update Game"
        REPAIR_GAME="Repair Installation"
        CLEAN_SAVES="Clean Save Data and Achievements"
        UNINSTALL_GAME="Uninstall Game"
        EXIT_OPTION="Exit" # Renamed to avoid conflict with 'exit' command
        ENTER_CHOICE="Enter your choice: "
        INVALID_CHOICE="Invalid choice. Please try again."
        INSTALLING_DEPENDENCIES="Installing necessary dependencies..."
        CHECKING_ENV="Checking environment..."
        PYTHON_FOUND="Python 3 found."
        PYTHON_NOT_FOUND="Python 3 not found. Installing Python 3..."
        PIP_FOUND="pip found."
        PIP_NOT_FOUND="pip not found. Installing pip..."
        GIT_FOUND="Git found."
        GIT_NOT_FOUND="Git not found. Installing Git..."
        INSTALLING_GAME="Installing StarSignalDecoder..."
        INSTALL_SUCCESS="StarSignalDecoder installed successfully!"
        INSTALL_FAILED="Installation failed. Check the output above for details." # 提示看终端输出
        UPDATE_SUCCESS="StarSignalDecoder updated successfully!"
        UPDATE_FAILED="Update failed. Check the output above for details." # 提示看终端输出
        REPAIR_SUCCESS="StarSignalDecoder repaired successfully!"
        REPAIR_FAILED="Repair failed. Check the output above for details." # 提示看终端输出
        CLEAN_SUCCESS="Save data and achievements cleaned successfully!"
        CLEAN_FAILED="Failed to clean save data. Check permissions."
        UNINSTALL_SUCCESS="StarSignalDecoder uninstalled successfully! Save data also removed."
        UNINSTALL_FAILED="Uninstallation failed. Check the output above for details." # 提示看终端输出
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
        INSTALLING_DEPENDENCIES="正在安装必要的依赖..."
        CHECKING_ENV="正在检查环境..."
        PYTHON_FOUND="检测到 Python 3。"
        PYTHON_NOT_FOUND="未检测到 Python 3。正在安装 Python 3..."
        PIP_FOUND="检测到 pip。"
        PIP_NOT_FOUND="未检测到 pip。正在安装 pip..."
        GIT_FOUND="检测到 Git。"
        GIT_NOT_FOUND="未检测到 Git。正在安装 Git..."
        INSTALLING_GAME="正在安装 星际迷航：信号解码..."
        INSTALL_SUCCESS="星际迷航：信号解码 安装成功！"
        INSTALL_FAILED="安装失败。请查看终端输出获取详情。" # 提示看终端输出
        UPDATE_SUCCESS="星际迷航：信号解码 更新成功！"
        UPDATE_FAILED="更新失败。请查看终端输出获取详情。" # 提示看终端输出
        REPAIR_SUCCESS="星际迷航：信号解码 修复成功！"
        REPAIR_FAILED="修复失败。请查看终端输出获取详情。" # 提示看终端输出
        CLEAN_SUCCESS="存档和成就数据清理成功！"
        CLEAN_FAILED="清理存档失败。请检查文件权限。"
        UNINSTALL_SUCCESS="星际迷航：信号解码 卸载成功！存档数据已移除。"
        UNINSTALL_FAILED="卸载失败。请查看终端输出获取详情。" # 提示看终端输出
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
}

print_warning() {
    echo -e "${YELLOW}警告：$1 ${NC}"
}

print_error() {
    echo -e "${RED}错误：$1 ${NC}"
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
            exit 1
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
            exit 1
        fi
    fi

    if ! command_exists git; then
        print_warning "${GIT_NOT_FOUND}"
        install_git # 此函数将直接输出到终端
        if ! command_exists git; then
            print_error "${INSTALL_FAILED}"
            exit 1
        fi
    else
        print_status "${GIT_FOUND}"
    fi

    check_path_for_starsignal
    check_terminal_encoding
}

install_python() {
    log_message "尝试安装 Python..." # 仅记录开始信息
    if [ "$OS" == "Linux" ]; then
        if command_exists apt-get; then
            sudo apt-get update # 不重定向，实时输出
            sudo apt-get install -y python3 python3-dev python3-pip # 不重定向，实时输出
        elif command_exists yum; then
            sudo yum install -y python3 python3-devel python3-pip # 不重定向，实时输出
        fi
    elif [ "$OS" == "macOS" ]; then
        if command_exists brew; then
            brew install python3 # 不重定向，实时输出
        else
            print_warning "Homebrew 未安装。请手动安装 Homebrew 并重试。"
        fi
    elif [ "$OS" == "Windows" ]; then
        if command_exists winget; then
            winget install --id Python.Python.3 --source winget # 不重定向，实时输出
        else
            print_warning "winget 未安装。请手动从 Python 官网下载安装，并确保勾选 'Add Python to PATH'。"
        fi
    fi
    # 重新检查 Python 命令是否可用
    if command_exists python3; then
        PYTHON_CMD="python3"
    elif command_exists python; then
        PYTHON_VERSION=$(python -c 'import sys; print(sys.version_info.major)')
        if [ "$PYTHON_VERSION" -ge 3 ]; then
            PYTHON_CMD="python"
        fi
    fi
    log_message "Python 安装尝试完成。" # 仅记录结束信息
}

install_pip() {
    log_message "尝试安装 pip..." # 仅记录开始信息
    if [ -n "$PYTHON_CMD" ]; then
        "$PYTHON_CMD" -m ensurepip --upgrade # 不重定向，实时输出
        "$PYTHON_CMD" -m pip install --upgrade pip # 不重定向，实时输出
    fi
    # 重新检查 pip 命令是否可用
    if command_exists pip3; then
        PIP_CMD="pip3"
    elif command_exists pip; then
        PIP_CMD="pip"
    fi
    log_message "pip 安装尝试完成。" # 仅记录结束信息
}

install_git() {
    log_message "尝试安装 Git..." # 仅记录开始信息
    if [ "$OS" == "Linux" ]; then
        if command_exists apt-get; then
            sudo apt-get install -y git # 不重定向，实时输出
        elif command_exists yum; then
            sudo yum install -y git # 不重定向，实时输出
        fi
    elif [ "$OS" == "macOS" ]; then
        if command_exists brew; then
            brew install git # 不重定向，实时输出
        else
            print_warning "Homebrew 未安装。请手动安装 Homebrew 并重试。"
        fi
    elif [ "$OS" == "Windows" ]; then
        if command_exists winget; then
            winget install --id Git.Git --source winget # 不重定向，实时输出
        else
            print_warning "winget 未安装。请手动从 Git for Windows 官网下载安装。"
        fi
    fi
    log_message "Git 安装尝试完成。" # 仅记录结束信息
}

# 检查 starsignal 命令是否在 PATH 中
check_path_for_starsignal() {
    if ! command_exists "$GAME_NAME"; then
        read -p "$(echo -e "${YELLOW}${PATH_FIX_PROMPT}${NC}")" -n 1 -r REPLY
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
            echo "export PATH=\$PATH:$LOCAL_BIN" >> "$HOME/.bashrc"
            echo "export PATH=\$PATH:$LOCAL_BIN" >> "$HOME/.zshrc" # 考虑到 zsh 用户
            source "$HOME/.bashrc" || true # 尝试立即生效，不重定向错误
            source "$HOME/.zshrc" || true # 尝试立即生效，不重定向错误
            print_status "${PATH_FIX_LINUX_MAC}"
        else
            print_status "PATH 已包含 $LOCAL_BIN。"
        fi
    elif [ "$OS" == "Windows" ]; then
        PYTHON_SCRIPTS_PATH=""
        if [ -n "$PYTHON_CMD" ]; then
            # 尝试获取用户site-packages的Scripts目录
            PYTHON_SCRIPTS_PATH=$("$PYTHON_CMD" -c "import site; print(site.USER_BASE + '/Scripts')" 2>/dev/null)
            # 如果USER_BASE/Scripts不存在，尝试系统Scripts目录
            if [ -z "$PYTHON_SCRIPTS_PATH" ] || [ ! -d "$PYTHON_SCRIPTS_PATH" ]; then
                PYTHON_SCRIPTS_PATH=$("$PYTHON_CMD" -c "import sys; print(sys.prefix + '/Scripts')" 2>/dev/null)
            fi
        fi

        if [ -n "$PYTHON_SCRIPTS_PATH" ] && [ -d "$PYTHON_SCRIPTS_PATH" ]; then
            # 使用 PowerShell 命令来修改用户环境变量，确保路径中的反斜杠被转义
            # 注意：这里需要确保 powershell.exe 可用
            powershell.exe -Command "$path = [Environment]::GetEnvironmentVariable('Path', 'User'); $newPath = \"$path;${PYTHON_SCRIPTS_PATH//\\/\\\\}\"; [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')" # 不重定向
            print_status "${PATH_FIX_WINDOWS}"
        else
            print_error "${PATH_FIX_FAILED}"
        fi
    fi
    log_message "PATH 修复尝试完成。"
}

# 检查终端编码
check_terminal_encoding() {
    # 假设默认是UTF-8，如果检测到非UTF-8才警告
    local encoding_ok=true
    
    if [ "$OS" == "Linux" ] || [ "$OS" == "macOS" ]; then
        # 尝试获取LC_CTYPE或LANG，并转换为大写比较
        local current_lang=$(locale | grep -E 'LC_CTYPE|LANG' | head -n 1 | cut -d'=' -f2 | tr -d '"' | cut -d'.' -f2 | tr '[:lower:]' '[:upper:]')
        if [[ "$current_lang" != "UTF-8" ]]; then
            encoding_ok=false
        fi
    elif [ "$OS" == "Windows" ]; then
        # 在Git Bash/WSL中，检查LANG变量
        local current_lang_windows=$(echo $LANG | cut -d'.' -f2 | tr '[:lower:]' '[:upper:]')
        if [ -z "$current_lang_windows" ] || [[ "$current_lang_windows" != "UTF-8" ]]; then
            # 如果LANG不是UTF-8，进一步检查chcp (CMD Code Page)
            local chcp_output=$(chcp 2>/dev/null | grep -oE '[0-9]+')
            if [[ "$chcp_output" != "65001" ]]; then # 65001 是 UTF-8 的代码页
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
        # 仅当文件存在时才尝试chmod
        if [ -f "${DATA_FILE}" ]; then
            chmod 666 "${DATA_FILE}" || true
        fi
        for i in {1..3}; do
            if [ -f "${SAVE_FILE_PREFIX}${i}.json" ]; then
                chmod 666 "${SAVE_FILE_PREFIX}${i}.json" || true
            fi
        done
    elif [ "$OS" == "Windows" ]; then
        # PowerShell 命令来修改 NTFS 权限
        # 仅当文件存在时才尝试 icacls
        # 注意：这里需要确保 powershell.exe 可用
        powershell.exe -Command "If (Test-Path \"$env:USERPROFILE\\.starsignal*\") { icacls \"$env:USERPROFILE\\.starsignal*\" /grant Everyone:F }" || true
    fi

    if [ $? -eq 0 ]; then
        print_status "${PERMISSION_SUCCESS}"
        log_message "${PERMISSION_SUCCESS}"
    else
        print_error "${PERMISSION_FAILED}"
        log_message "${PERMISSION_FAILED}"
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
    check_python_env

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
    check_python_env

    local branch
    # 使用 -r 确保读取原始内容，防止转义，使用 -p 提示
    # bash的read命令在交互式shell中会等待用户输入
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
    check_python_env

    print_status "${REPAIR_GAME}"
    log_message "尝试修复游戏安装..."
    # 强制重装以修复可能的文件损坏
    if "$PIP_CMD" install --user --force-reinstall "git+${REPO_URL}@main"; then # 不再重定向输出
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

        # 检查是否删除成功，如果文件不存在，则认为删除成功
        if [ ! -f "$DATA_FILE" ]; then
            print_status "${CLEAN_SUCCESS}"
            log_message "${CLEAN_SUCCESS}"
        else
            print_error "${CLEAN_FAILED}"
            log_message "${CLEAN_FAILED}"
        fi
    else
        print_status "${CANCELLED}"
    fi
}

# 卸载游戏
uninstall_game() {
    read -r -p "$(echo -e "${YELLOW}${CONFIRM_UNINSTALL}${NC}")" -n 1 REPLY
    echo # 添加换行
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "${UNINSTALL_GAME}"
        log_message "开始卸载游戏..."
        if command_exists "$PIP_CMD"; then
            "$PIP_CMD" uninstall -y "$GAME_NAME" # 不再重定向输出
        else
            print_warning "pip 命令未找到，可能需要手动删除相关文件。"
        fi

        # 移除数据文件和存档文件
        rm -f "$DATA_FILE" # 不再重定向
        for i in {1..3}; do
            rm -f "${SAVE_FILE_PREFIX}${i}.json" # 不再重定向
        done

        if ! is_installed; then
            print_status "${UNINSTALL_SUCCESS}"
            log_message "${UNINSTALL_SUCCESS}"
        else
            print_error "${UNINSTALL_FAILED}"
            log_message "${UNINSTALL_FAILED}"
        fi
    else
        print_status "${CANCELLED}"
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
        read -r choice || true # Read user input
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
        read -r choice || true # Read user input
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

    # 创建日志文件或清空
    # 注意：这里日志文件仅用于记录脚本自身的关键运行点，不记录安装/更新等命令的详细输出
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
