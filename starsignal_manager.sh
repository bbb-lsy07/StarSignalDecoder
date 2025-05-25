#!/bin/bash

# 星际迷航：信号解码 游戏管理脚本 v1.7.1
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
LOG_FILE="$HOME/.starsignal_install.log"
SAVE_FILE_PREFIX="$HOME/.starsignal_save_"

# 检查当前是否在终端运行
IS_TERMINAL=true
if ! [ -t 0 ]; then
  IS_TERMINAL=false
fi

# 获取当前脚本的语言设置，默认中文
LANG_SET="zh"
if [ -n "$1" ] && [ "$1" == "--lang" ] && [ -n "$2" ]; then
    LANG_SET="$2"
    shift 2 # 移除语言参数
fi

# 文本定义 (根据语言设置)
declare -A TXT

if [ "$LANG_SET" == "en" ]; then
    # English Text
    TXT=(
        [INSTALLATION_MENU]="Installation Menu"
        [ALREADY_INSTALLED]="StarSignalDecoder is already installed."
        [NOT_INSTALLED]="StarSignalDecoder is not installed."
        [INSTALL_MAIN]="Install Stable Version (main branch)"
        [INSTALL_DEV]="Install Development Version (dev branch)"
        [UPDATE_GAME]="Update Game"
        [REPAIR_GAME]="Repair Installation"
        [CLEAN_SAVES]="Clean Save Data and Achievements"
        [UNINSTALL_GAME]="Uninstall Game"
        [EXIT]="Exit"
        [ENTER_CHOICE]="Enter your choice: "
        [INVALID_CHOICE]="Invalid choice. Please try again."
        [INSTALLING_DEPENDENCIES]="Installing necessary dependencies..."
        [CHECKING_ENV]="Checking environment..."
        [PYTHON_FOUND]="Python 3 found."
        [PYTHON_NOT_FOUND]="Python 3 not found. Installing Python 3..."
        [PIP_FOUND]="pip found."
        [PIP_NOT_FOUND]="pip not found. Installing pip..."
        [GIT_FOUND]="Git found."
        [GIT_NOT_FOUND]="Git not found. Installing Git..."
        [INSTALLING_GAME]="Installing StarSignalDecoder..."
        [INSTALL_SUCCESS]="StarSignalDecoder installed successfully!"
        [INSTALL_FAILED]="Installation failed. Check the log file for details: ${LOG_FILE}"
        [UPDATE_SUCCESS]="StarSignalDecoder updated successfully!"
        [UPDATE_FAILED]="Update failed. Check the log file for details: ${LOG_FILE}"
        [REPAIR_SUCCESS]="StarSignalDecoder repaired successfully!"
        [REPAIR_FAILED]="Repair failed. Check the log file for details: ${LOG_FILE}"
        [CLEAN_SUCCESS]="Save data and achievements cleaned successfully!"
        [CLEAN_FAILED]="Failed to clean save data. Check permissions."
        [UNINSTALL_SUCCESS]="StarSignalDecoder uninstalled successfully! Save data also removed."
        [UNINSTALL_FAILED]="Uninstallation failed. Check the log file for details: ${LOG_FILE}"
        [PERMISSION_FIX]="Attempting to fix save file permissions..."
        [PERMISSION_SUCCESS]="Save file permissions fixed."
        [PERMISSION_FAILED]="Failed to fix save file permissions. Please fix manually using 'chmod 666 ~/.starsignal*' or 'icacls %USERPROFILE%\.starsignal* /grant Everyone:F'."
        [PATH_FIX_PROMPT]="Python scripts directory might not be in your PATH. Do you want to try fixing it? (y/n): "
        [PATH_FIX_LINUX_MAC]="Fixing PATH for Linux/macOS. Please source your shell config (e.g., 'source ~/.bashrc') or restart your terminal for changes to take effect."
        [PATH_FIX_WINDOWS]="Attempting to fix PATH for Windows. You may need to restart PowerShell/Git Bash or your system for changes to take effect."
        [PATH_FIX_FAILED]="Failed to fix PATH. Please add Python's Scripts directory to your system's PATH manually."
        [WARNING_PIPE]="WARNING: This script is designed for interactive use. Running via pipe (e.g., curl ... | sh) may cause input issues. Please download the script and run it locally: ${YELLOW}curl -s ${REPO_URL/StarSignalDecoder.git/main/starsignal_manager.sh} -o starsignal_manager.sh && chmod +x starsignal_manager.sh && ./starsignal_manager.sh${NC}"
        [CONFIRM_UNINSTALL]="Are you sure you want to uninstall StarSignalDecoder and delete all save data? (y/n): "
        [CONFIRM_CLEAN]="Are you sure you want to delete all save data and achievements? This cannot be undone. (y/n): "
        [CANCELLED]="Operation cancelled."
        [CHOOSE_BRANCH]="Choose branch (main/dev) [main]: "
        [CHECKING_TERMINAL_ENCODING]="Checking terminal encoding..."
        [ENCODING_WARNING]="Your terminal encoding might not be UTF-8. This can cause display issues. Please set your terminal to UTF-8 (e.g., ${YELLOW}export LANG=en_US.UTF-8${NC} or ${YELLOW}chcp 65001${NC} on Windows)."
    )
else
    # Chinese Text
    TXT=(
        [INSTALLATION_MENU]="安装与管理菜单"
        [ALREADY_INSTALLED]="星际迷航：信号解码 已安装。"
        [NOT_INSTALLED]="星际迷航：信号解码 未安装。"
        [INSTALL_MAIN]="安装稳定版（main 分支）"
        [INSTALL_DEV]="安装开发版（dev 分支）"
        [UPDATE_GAME]="更新游戏"
        [REPAIR_GAME]="修复安装"
        [CLEAN_SAVES]="清理存档和成就数据"
        [UNINSTALL_GAME]="卸载游戏"
        [EXIT]="退出"
        [ENTER_CHOICE]="请输入您的选择： "
        [INVALID_CHOICE]="无效的选择，请重试。"
        [INSTALLING_DEPENDENCIES]="正在安装必要的依赖..."
        [CHECKING_ENV]="正在检查环境..."
        [PYTHON_FOUND]="检测到 Python 3。"
        [PYTHON_NOT_FOUND]="未检测到 Python 3。正在安装 Python 3..."
        [PIP_FOUND]="检测到 pip。"
        [PIP_NOT_FOUND]="未检测到 pip。正在安装 pip..."
        [GIT_FOUND]="检测到 Git。"
        [GIT_NOT_FOUND]="未检测到 Git。正在安装 Git..."
        [INSTALLING_GAME]="正在安装 星际迷航：信号解码..."
        [INSTALL_SUCCESS]="星际迷航：信号解码 安装成功！"
        [INSTALL_FAILED]="安装失败。请查看日志文件获取详情：${LOG_FILE}"
        [UPDATE_SUCCESS]="星际迷航：信号解码 更新成功！"
        [UPDATE_FAILED]="更新失败。请查看日志文件获取详情：${LOG_FILE}"
        [REPAIR_SUCCESS]="星际迷航：信号解码 修复成功！"
        [REPAIR_FAILED]="修复失败。请查看日志文件获取详情：${LOG_FILE}"
        [CLEAN_SUCCESS]="存档和成就数据清理成功！"
        [CLEAN_FAILED]="清理存档失败。请检查文件权限。"
        [UNINSTALL_SUCCESS]="星际迷航：信号解码 卸载成功！存档数据已移除。"
        [UNINSTALL_FAILED]="卸载失败。请查看日志文件获取详情：${LOG_FILE}"
        [PERMISSION_FIX]="正在尝试修复存档文件权限..."
        [PERMISSION_SUCCESS]="存档文件权限已修复。"
        [PERMISSION_FAILED]="无法修复存档文件权限。请手动运行：'chmod 666 ~/.starsignal*' (Linux/macOS) 或 'icacls %USERPROFILE%\\.starsignal* /grant Everyone:F' (Windows)。"
        [PATH_FIX_PROMPT]="Python 脚本目录可能不在您的 PATH 环境变量中。是否尝试修复？(y/n): "
        [PATH_FIX_LINUX_MAC]="正在修复 Linux/macOS 的 PATH。请重新加载您的 shell 配置（例如 'source ~/.bashrc'）或重启终端以使更改生效。"
        [PATH_FIX_WINDOWS]="正在尝试修复 Windows 的 PATH。您可能需要重启 PowerShell/Git Bash 或您的系统以使更改生效。"
        [PATH_FIX_FAILED]="无法修复 PATH。请手动将 Python 的 Scripts 目录添加到系统 PATH 环境变量中。"
        [WARNING_PIPE]="警告：本脚本设计为交互式使用。通过管道运行（例如 curl ... | sh）可能导致输入问题。请下载脚本后在本地运行：${YELLOW}curl -s ${REPO_URL/StarSignalDecoder.git/main/starsignal_manager.sh} -o starsignal_manager.sh && chmod +x starsignal_manager.sh && ./starsignal_manager.sh${NC}"
        [CONFIRM_UNINSTALL]="您确定要卸载 星际迷航：信号解码 并删除所有存档数据吗？(y/n): "
        [CONFIRM_CLEAN]="您确定要删除所有存档和成就数据吗？此操作无法撤销。(y/n): "
        [CANCELLED]="操作已取消。"
        [CHOOSE_BRANCH]="选择分支 (main/dev) [main]: "
        [CHECKING_TERMINAL_ENCODING]="正在检查终端编码..."
        [ENCODING_WARNING]="您的终端编码可能不是 UTF-8。这可能导致显示问题。请将终端设置为 UTF-8（例如 ${YELLOW}export LANG=zh_CN.UTF-8${NC} 或 Windows 上 ${YELLOW}chcp 65001${NC}）。"
    )
fi

# --- 辅助函数 ---

log_message() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOG_FILE"
}

print_status() {
    echo -e "${GREEN}==> $1 ${NC}" | tee -a "$LOG_FILE"
}

print_warning() {
    echo -e "${YELLOW}警告：$1 ${NC}" | tee -a "$LOG_FILE"
}

print_error() {
    echo -e "${RED}错误：$1 ${NC}" | tee -a "$LOG_FILE"
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
    print_status "${TXT[CHECKING_ENV]}"
    log_message "${TXT[CHECKING_ENV]}"

    PYTHON_CMD=""
    if command_exists python3; then
        PYTHON_CMD="python3"
        print_status "${TXT[PYTHON_FOUND]}"
    elif command_exists python; then
        PYTHON_VERSION=$(python -c 'import sys; print(sys.version_info.major)')
        if [ "$PYTHON_VERSION" -ge 3 ]; then
            PYTHON_CMD="python"
            print_status "${TXT[PYTHON_FOUND]}"
        fi
    fi

    if [ -z "$PYTHON_CMD" ]; then
        print_warning "${TXT[PYTHON_NOT_FOUND]}"
        install_python
        if [ -z "$PYTHON_CMD" ]; then
            print_error "${TXT[INSTALL_FAILED]}"
            exit 1
        fi
    fi

    PIP_CMD=""
    if command_exists pip3; then
        PIP_CMD="pip3"
        print_status "${TXT[PIP_FOUND]}"
    elif command_exists pip; then
        PIP_CMD="pip"
        print_status "${TXT[PIP_FOUND]}"
    fi

    if [ -z "$PIP_CMD" ]; then
        print_warning "${TXT[PIP_NOT_FOUND]}"
        install_pip
        if [ -z "$PIP_CMD" ]; then
            print_error "${TXT[INSTALL_FAILED]}"
            exit 1
        fi
    fi

    if ! command_exists git; then
        print_warning "${TXT[GIT_NOT_FOUND]}"
        install_git
        if ! command_exists git; then
            print_error "${TXT[INSTALL_FAILED]}"
            exit 1
        fi
    else
        print_status "${TXT[GIT_FOUND]}"
    fi

    check_path_for_starsignal
    check_terminal_encoding
}

install_python() {
    log_message "尝试安装 Python..."
    if [ "$OS" == "Linux" ]; then
        if command_exists apt-get; then
            sudo apt-get update >> "$LOG_FILE" 2>&1
            sudo apt-get install -y python3 python3-dev python3-pip >> "$LOG_FILE" 2>&1
        elif command_exists yum; then
            sudo yum install -y python3 python3-devel python3-pip >> "$LOG_FILE" 2>&1
        fi
    elif [ "$OS" == "macOS" ]; then
        if command_exists brew; then
            brew install python3 >> "$LOG_FILE" 2>&1
        else
            print_warning "Homebrew 未安装。请手动安装 Homebrew 并重试。"
        fi
    elif [ "$OS" == "Windows" ]; then
        if command_exists winget; then
            winget install --id Python.Python.3 --source winget >> "$LOG_FILE" 2>&1
        else
            print_warning "winget 未安装。请手动从 Python 官网下载安装，并确保勾选 'Add Python to PATH'。"
        fi
    fi
    if command_exists python3; then
        PYTHON_CMD="python3"
    elif command_exists python; then
        PYTHON_VERSION=$(python -c 'import sys; print(sys.version_info.major)')
        if [ "$PYTHON_VERSION" -ge 3 ]; then
            PYTHON_CMD="python"
        fi
    fi
    log_message "Python 安装尝试完成。"
}

install_pip() {
    log_message "尝试安装 pip..."
    if [ -n "$PYTHON_CMD" ]; then
        "$PYTHON_CMD" -m ensurepip --upgrade >> "$LOG_FILE" 2>&1
        "$PYTHON_CMD" -m pip install --upgrade pip >> "$LOG_FILE" 2>&1
    fi
    if command_exists pip3; then
        PIP_CMD="pip3"
    elif command_exists pip; then
        PIP_CMD="pip"
    fi
    log_message "pip 安装尝试完成。"
}

install_git() {
    log_message "尝试安装 Git..."
    if [ "$OS" == "Linux" ]; then
        if command_exists apt-get; then
            sudo apt-get install -y git >> "$LOG_FILE" 2>&1
        elif command_exists yum; then
            sudo yum install -y git >> "$LOG_FILE" 2>&1
        fi
    elif [ "$OS" == "macOS" ]; then
        if command_exists brew; then
            brew install git >> "$LOG_FILE" 2>&1
        else
            print_warning "Homebrew 未安装。请手动安装 Homebrew 并重试。"
        fi
    elif [ "$OS" == "Windows" ]; then
        if command_exists winget; then
            winget install --id Git.Git --source winget >> "$LOG_FILE" 2>&1
        else
            print_warning "winget 未安装。请手动从 Git for Windows 官网下载安装。"
        fi
    fi
    log_message "Git 安装尝试完成。"
}

# 检查 starsignal 命令是否在 PATH 中
check_path_for_starsignal() {
    if ! command_exists "$GAME_NAME"; then
        read -p "$(echo -e "${YELLOW}${TXT[PATH_FIX_PROMPT]}${NC}")" -n 1 -r REPLY
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
            source "$HOME/.bashrc" >> "$LOG_FILE" 2>&1 || true # 尝试立即生效
            source "$HOME/.zshrc" >> "$LOG_FILE" 2>&1 || true # 尝试立即生效
            print_status "${TXT[PATH_FIX_LINUX_MAC]}"
        else
            print_status "PATH 已包含 $LOCAL_BIN。"
        fi
    elif [ "$OS" == "Windows" ]; then
        PYTHON_SCRIPTS_PATH=""
        if [ -n "$PYTHON_CMD" ]; then
            PYTHON_SCRIPTS_PATH=$("$PYTHON_CMD" -c "import site; print(site.USER_BASE + '/Scripts')")
            # 兼容 pipx 模式下的路径
            if [ -z "$PYTHON_SCRIPTS_PATH" ]; then
                PYTHON_SCRIPTS_PATH=$("$PYTHON_CMD" -c "import sys; print(sys.prefix + '/Scripts')")
            fi
        fi

        if [ -n "$PYTHON_SCRIPTS_PATH" ]; then
            # PowerShell 命令来修改用户环境变量
            powershell.exe -Command "[Environment]::SetEnvironmentVariable('Path', ([Environment]::GetEnvironmentVariable('Path', 'User') + ';$env:USERPROFILE\.local\bin'), 'User')" >> "$LOG_FILE" 2>&1
            powershell.exe -Command "[Environment]::SetEnvironmentVariable('Path', ([Environment]::GetEnvironmentVariable('Path', 'User') + ';${PYTHON_SCRIPTS_PATH}'), 'User')" >> "$LOG_FILE" 2>&1
            print_status "${TXT[PATH_FIX_WINDOWS]}"
        else
            print_error "${TXT[PATH_FIX_FAILED]}"
        fi
    fi
    log_message "PATH 修复尝试完成。"
}

# 检查终端编码
check_terminal_encoding() {
    print_status "${TXT[CHECKING_TERMINAL_ENCODING]}"
    if [ "$OS" == "Linux" ] || [ "$OS" == "macOS" ]; then
        ENCODING=$(locale | grep -E 'LC_CTYPE|LANG' | head -n 1 | cut -d'=' -f2 | tr -d '"' | cut -d'.' -f2)
        if [ "${ENCODING^^}" != "UTF-8" ]; then
            print_warning "${TXT[ENCODING_WARNING]}"
        fi
    elif [ "$OS" == "Windows" ]; then
        # 在 Git Bash 或 WSL 中，LANG 变量可能已设置
        ENCODING=$(echo $LANG | cut -d'.' -f2)
        if [ -z "$ENCODING" ] || [ "${ENCODING^^}" != "UTF-8" ]; then
            print_warning "${TXT[ENCODING_WARNING]}"
        fi
    fi
}

# 修复存档文件权限
fix_save_permissions() {
    print_status "${TXT[PERMISSION_FIX]}"
    log_message "${TXT[PERMISSION_FIX]}"
    if [ "$OS" == "Linux" ] || [ "$OS" == "macOS" ]; then
        chmod 666 "${DATA_FILE}" >> "$LOG_FILE" 2>&1 || true
        for i in {1..3}; do
            chmod 666 "${SAVE_FILE_PREFIX}${i}.json" >> "$LOG_FILE" 2>&1 || true
        done
    elif [ "$OS" == "Windows" ]; then
        # PowerShell 命令来修改 NTFS 权限
        powershell.exe -Command "icacls \"$env:USERPROFILE\\.starsignal*\" /grant Everyone:F" >> "$LOG_FILE" 2>&1 || true
    fi

    if [ $? -eq 0 ]; then
        print_status "${TXT[PERMISSION_SUCCESS]}"
        log_message "${TXT[PERMISSION_SUCCESS]}"
    else
        print_error "${TXT[PERMISSION_FAILED]}"
        log_message "${TXT[PERMISSION_FAILED]}"
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
    print_status "${TXT[INSTALLING_DEPENDENCIES]}"
    check_python_env

    print_status "${TXT[INSTALLING_GAME]}"
    log_message "开始安装游戏到 $branch 分支..."
    if "$PIP_CMD" install --user "git+${REPO_URL}@${branch}" >> "$LOG_FILE" 2>&1; then
        print_status "${TXT[INSTALL_SUCCESS]}"
        log_message "${TXT[INSTALL_SUCCESS]}"
        fix_save_permissions # 尝试修复新安装的权限
    else
        print_error "${TXT[INSTALL_FAILED]}"
        log_message "${TXT[INSTALL_FAILED]}"
    fi
}

# 更新游戏
update_game() {
    print_status "${TXT[CHECKING_ENV]}"
    check_python_env

    local branch
    read -p "$(echo -e "${YELLOW}${TXT[CHOOSE_BRANCH]}${NC}")" branch
    branch=${branch:-main}

    print_status "${TXT[UPDATE_GAME]}"
    log_message "开始更新游戏到 $branch 分支..."
    if "$PIP_CMD" install --user --upgrade --force-reinstall "git+${REPO_URL}@${branch}" >> "$LOG_FILE" 2>&1; then
        print_status "${TXT[UPDATE_SUCCESS]}"
        log_message "${TXT[UPDATE_SUCCESS]}"
        fix_save_permissions # 尝试修复更新后的权限
    else
        print_error "${TXT[UPDATE_FAILED]}"
        log_message "${TXT[UPDATE_FAILED]}"
    fi
}

# 修复安装
repair_game() {
    print_status "${TXT[CHECKING_ENV]}"
    check_python_env

    print_status "${TXT[REPAIR_GAME]}"
    log_message "尝试修复游戏安装..."
    # 强制重装以修复可能的文件损坏
    if "$PIP_CMD" install --user --force-reinstall "git+${REPO_URL}@main" >> "$LOG_FILE" 2>&1; then
        print_status "${TXT[REPAIR_SUCCESS]}"
        log_message "${TXT[REPAIR_SUCCESS]}"
        fix_save_permissions # 修复权限
    else
        print_error "${TXT[REPAIR_FAILED]}"
        log_message "${TXT[REPAIR_FAILED]}"
    fi
}

# 清理存档
clean_saves() {
    read -p "$(echo -e "${YELLOW}${TXT[CONFIRM_CLEAN]}${NC}")" -n 1 -r REPLY
    echo # 添加换行
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "${TXT[CLEAN_SAVES]}"
        log_message "开始清理存档和成就数据..."
        rm -f "$DATA_FILE" >> "$LOG_FILE" 2>&1 || true
        for i in {1..3}; do
            rm -f "${SAVE_FILE_PREFIX}${i}.json" >> "$LOG_FILE" 2>&1 || true
        done

        if [ ! -f "$DATA_FILE" ]; then # 检查是否删除成功
            print_status "${TXT[CLEAN_SUCCESS]}"
            log_message "${TXT[CLEAN_SUCCESS]}"
        else
            print_error "${TXT[CLEAN_FAILED]}"
            log_message "${TXT[CLEAN_FAILED]}"
        fi
    else
        print_status "${TXT[CANCELLED]}"
    fi
}

# 卸载游戏
uninstall_game() {
    read -p "$(echo -e "${YELLOW}${TXT[CONFIRM_UNINSTALL]}${NC}")" -n 1 -r REPLY
    echo # 添加换行
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "${TXT[UNINSTALL_GAME]}"
        log_message "开始卸载游戏..."
        if command_exists "$PIP_CMD"; then
            "$PIP_CMD" uninstall -y "$GAME_NAME" >> "$LOG_FILE" 2>&1
        else
            print_warning "pip 命令未找到，可能需要手动删除相关文件。"
        fi

        # 移除数据文件和存档文件
        rm -f "$DATA_FILE" >> "$LOG_FILE" 2>&1 || true
        for i in {1..3}; do
            rm -f "${SAVE_FILE_PREFIX}${i}.json" >> "$LOG_FILE" 2>&1 || true
        done

        if ! is_installed; then
            print_status "${TXT[UNINSTALL_SUCCESS]}"
            log_message "${TXT[UNINSTALL_SUCCESS]}"
        else
            print_error "${TXT[UNINSTALL_FAILED]}"
            log_message "${TXT[UNINSTALL_FAILED]}"
        fi
    else
        print_status "${TXT[CANCELLED]}"
    fi
}

# --- 主菜单 ---
show_menu() {
    if ! "$IS_TERMINAL"; then
        print_warning "${TXT[WARNING_PIPE]}"
        return
    fi

    echo -e "${CYAN}╔══════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║    ${TXT[INSTALLATION_MENU]}           ${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════╝${NC}"

    if is_installed; then
        echo -e "${GREEN}${TXT[ALREADY_INSTALLED]}${NC}"
        echo "1) ${TXT[UPDATE_GAME]}"
        echo "2) ${TXT[REPAIR_GAME]}"
        echo "3) ${TXT[CLEAN_SAVES]}"
        echo "4) ${TXT[UNINSTALL_GAME]}"
        echo "0) ${TXT[EXIT]}"
    else
        echo -e "${YELLOW}${TXT[NOT_INSTALLED]}${NC}"
        echo "1) ${TXT[INSTALL_MAIN]}"
        echo "2) ${TXT[INSTALL_DEV]}"
        echo "0) ${TXT[EXIT]}"
    fi

    echo -en "${BLUE}${TXT[ENTER_CHOICE]}${NC}"
    read -r choice
    echo # 添加换行

    if is_installed; then
        case "$choice" in
            1) update_game ;;
            2) repair_game ;;
            3) clean_saves ;;
            4) uninstall_game ;;
            0) exit 0 ;;
            *) print_error "${TXT[INVALID_CHOICE]}" ;;
        esac
    else
        case "$choice" in
            1) install_game main ;;
            2) install_game dev ;;
            0) exit 0 ;;
            *) print_error "${TXT[INVALID_CHOICE]}" ;;
        esac
    fi
}

# --- 脚本入口点 ---
main() {
    # 如果脚本通过管道运行，打印警告并退出
    if ! "$IS_TERMINAL"; then
        print_warning "${TXT[WARNING_PIPE]}"
        exit 1
    fi

    # 创建日志文件或清空
    > "$LOG_FILE"
    log_message "----------------------------------------------------"
    log_message "星际迷航：信号解码 管理脚本启动"
    log_message "操作系统: $OS"
    log_message "语言设置: $LANG_SET"
    log_message "----------------------------------------------------"

    while true; do
        show_menu
        echo -e "${CYAN}按任意键继续...${NC}"
        read -n 1 -s # 等待按键
        echo # 添加换行
    done
}

main "$@"
