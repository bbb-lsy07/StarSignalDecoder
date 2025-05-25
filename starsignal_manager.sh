#!/bin/bash

# ==============================================================================
# 星际迷航：信号解码 - 全功能管理脚本 v4.0.1
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
#
# 新功能 (v4.0.0):
#   - 全新菜单系统，使用 bash select 命令，消除输入验证错误
#   - 配置文件 (~/.starsignal_config.json) 保存语言、分支、调试模式、主题偏好
#   - 安装/更新/修复操作显示进度条，提升用户体验
#   - 交互式帮助选项，提供每个菜单选项的详细说明
#   - 存档自动备份到 ~/.starsignal_backup/，防止数据丢失
#   - 5分钟无操作自动退出，防止脚本挂起
#   - 支持颜色主题（默认、高对比度、无颜色），通过配置文件设置
#   - 增强 root 执行兼容性，移除 /dev/tty 依赖
#
# 变更日志：
#   v4.0.1 (2025-05-25):
#     - 修复菜单选择逻辑，直接使用 select 的 REPLY 变量，确保输入准确映射到功能
#     - 改进超时处理，使用 read 超时替代 TMOUT，添加 timeout_handler 函数
#     - 增强输入缓冲区清理，确保 root 执行时无残留输入
#     - 添加非数字和超出范围输入的验证，显示无效选择提示
#     - 增强调试日志，记录 select 的 REPLY 值和终端状态
#     - 更新版本号到 4.0.1
#   v4.0.0 (2025-05-25):
#     - 重写菜单逻辑，使用 select 命令，解决输入验证问题
#     - 添加配置文件、进度条、帮助系统、存档备份、超时退出、颜色主题
#     - 优化 root 执行，强制标准输入输出，清理输入缓冲区
#     - 强制终端设置为 UTF-8 和 xterm-256color
#     - 增强调试日志，记录用户上下文和输入事件
# ==============================================================================

# --- 定义颜色 ---
DEFAULT_RED='\033[0;31m'
DEFAULT_GREEN='\033[0;32m'
DEFAULT_YELLOW='\033[0;33m'
DEFAULT_BLUE='\033[0;34m'
DEFAULT_MAGENTA='\033[0;35m'
DEFAULT_CYAN='\033[0;36m'
DEFAULT_NC='\033[0m' # No Color

HIGH_CONTRAST_RED='\033[1;31m'
HIGH_CONTRAST_GREEN='\033[1;32m'
HIGH_CONTRAST_YELLOW='\033[1;33m'
HIGH_CONTRAST_BLUE='\033[1;34m'
HIGH_CONTRAST_MAGENTA='\033[1;35m'
HIGH_CONTRAST_CYAN='\033[1;36m'
HIGH_CONTRAST_NC='\033[0m'

# 默认颜色（稍后根据主题设置）
RED="$DEFAULT_RED"
GREEN="$DEFAULT_GREEN"
YELLOW="$DEFAULT_YELLOW"
BLUE="$DEFAULT_BLUE"
MAGENTA="$DEFAULT_MAGENTA"
CYAN="$DEFAULT_CYAN"
NC="$DEFAULT_NC"

# --- 全局变量和配置 ---
REPO_URL="https://github.com/bbb-lsy07/StarSignalDecoder.git"
GAME_NAME="starsignal"
DATA_FILE="$HOME/.starsignal_data.json"
LOG_FILE="$HOME/.starsignal_manager.log"
CONFIG_FILE="$HOME/.starsignal_config.json"
SAVE_FILE_PREFIX="$HOME/.starsignal_save_"
BACKUP_DIR="$HOME/.starsignal_backup"
SCRIPT_VERSION="4.0.1"
PYTHON_CMD=""
PIP_CMD=""
DEBUG_MODE=false
LANG_SET="zh"
DEFAULT_BRANCH="main"
COLOR_THEME="default"

# 如果以 root 运行，调整文件路径
if [ "$(id -u)" -eq 0 ] && [ -n "$SUDO_USER" ]; then
    DATA_FILE="/home/$SUDO_USER/.starsignal_data.json"
    LOG_FILE="/home/$SUDO_USER/.starsignal_manager.log"
    CONFIG_FILE="/home/$SUDO_USER/.starsignal_config.json"
    SAVE_FILE_PREFIX="/home/$SUDO_USER/.starsignal_save_"
    BACKUP_DIR="/home/$SUDO_USER/.starsignal_backup"
fi

# 检查是否在终端运行
IS_TERMINAL=true
if ! [ -t 0 ]; then
    IS_TERMINAL=false
fi

# 解析命令行参数
while [ "$#" -gt 0 ]; do
    case "$1" in
        --lang)
            LANG_SET="$2"
            shift 2
            ;;
        --debug)
            DEBUG_MODE=true
            shift
            ;;
        *)
            shift
            ;;
    esac
done

# 强制设置终端环境
export TERM=xterm-256color
export LANG=zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8
stty sane 2>/dev/null

# --- 配置文件处理 ---
init_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        mkdir -p "$(dirname "$CONFIG_FILE")" 2>/dev/null
        cat > "$CONFIG_FILE" << EOF
{
    "language": "zh",
    "default_branch": "main",
    "debug_mode": false,
    "color_theme": "default"
}
EOF
        log_message "Created default config file at $CONFIG_FILE"
    fi

    # 读取配置文件（简单解析 JSON）
    LANG_SET=$(grep '"language"' "$CONFIG_FILE" | cut -d'"' -f4 || echo "zh")
    DEFAULT_BRANCH=$(grep '"default_branch"' "$CONFIG_FILE" | cut -d'"' -f4 || echo "main")
    DEBUG_MODE=$(grep '"debug_mode"' "$CONFIG_FILE" | cut -d':' -f2 | tr -d ' ,' || echo "false")
    COLOR_THEME=$(grep '"color_theme"' "$CONFIG_FILE" | cut -d'"' -f4 || echo "default")

    # 应用命令行参数优先级
    if [ -n "$1" ]; then
        LANG_SET="$1"
    fi
    if [ "$DEBUG_MODE" != "true" ] && [ "$2" = "true" ]; then
        DEBUG_MODE=true
    fi

    # 设置颜色主题
    case "$COLOR_THEME" in
        high-contrast)
            RED="$HIGH_CONTRAST_RED"
            GREEN="$HIGH_CONTRAST_GREEN"
            YELLOW="$HIGH_CONTRAST_YELLOW"
            BLUE="$HIGH_CONTRAST_BLUE"
            MAGENTA="$HIGH_CONTRAST_MAGENTA"
            CYAN="$HIGH_CONTRAST_CYAN"
            NC="$HIGH_CONTRAST_NC"
            ;;
        no-color)
            RED=""
            GREEN=""
            YELLOW=""
            BLUE=""
            MAGENTA=""
            CYAN=""
            NC=""
            ;;
        *)
            RED="$DEFAULT_RED"
            GREEN="$DEFAULT_GREEN"
            YELLOW="$DEFAULT_YELLOW"
            BLUE="$DEFAULT_BLUE"
            MAGENTA="$DEFAULT_MAGENTA"
            CYAN="$DEFAULT_CYAN"
            NC="$DEFAULT_NC"
            ;;
    esac

    log_message "Config loaded: language=$LANG_SET, branch=$DEFAULT_BRANCH, debug=$DEBUG_MODE, theme=$COLOR_THEME"
}

# --- 文本定义 ---
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
        SHOW_HELP="Show Help"
        EXIT_OPTION="Exit"
        ENTER_CHOICE="Select an option: "
        INVALID_CHOICE="Invalid choice. Please select a number from the list."
        INSTALLING_DEPENDENCIES="Installing necessary dependencies..."
        CHECKING_ENV="Checking environment..."
        PYTHON_FOUND="Python 3 found."
        PYTHON_NOT_FOUND="Python 3 not found. Attempting to install..."
        PIP_FOUND="pip found."
        PIP_NOT_FOUND="pip not found. Attempting to install..."
        GIT_FOUND="Git found."
        GIT_NOT_FOUND="Git not found. Attempting to install..."
        INSTALLING_GAME="Installing StarSignalDecoder..."
        INSTALL_SUCCESS="StarSignalDecoder installed successfully!"
        INSTALL_FAILED="Installation failed. Check network, dependencies, or pip version."
        UPDATE_SUCCESS="StarSignalDecoder updated successfully!"
        UPDATE_FAILED="Update failed. Check network, dependencies, or pip version."
        REPAIR_SUCCESS="StarSignalDecoder repaired successfully!"
        REPAIR_FAILED="Repair failed. Check network, dependencies, or pip version."
        CLEAN_SUCCESS="Save data and achievements cleaned successfully!"
        CLEAN_FAILED="Failed to clean save data. Check permissions."
        UNINSTALL_SUCCESS="StarSignalDecoder uninstalled successfully! Save data backed up."
        UNINSTALL_FAILED="Uninstallation failed. Check output for details."
        PERMISSION_FIX="Fixing save file permissions..."
        PERMISSION_SUCCESS="Save file permissions fixed."
        PERMISSION_FAILED="Failed to fix permissions. Run 'chmod 666 ~/.starsignal*' or 'icacls %USERPROFILE%\\.starsignal* /grant Everyone:F'."
        PATH_FIX_PROMPT="Python scripts directory not in PATH. Fix it? (y/n): "
        PATH_FIX_LINUX_MACOS="Fixed PATH for Linux/macOS. Run 'source ~/.bashrc' or restart terminal."
        PATH_FIX_WINDOWS="Fixed PATH for Windows. Restart PowerShell/Git Bash or system."
        PATH_FIX_FAILED="Failed to fix PATH. Add Python Scripts to PATH manually."
        WARNING_PIPE="WARNING: Script designed for interactive use. Pipe (e.g., curl ... | sh) may cause issues. Download and run locally: ${YELLOW}curl -s ${REPO_URL}/main/starsignal_manager.sh -o starsignal_manager.sh && chmod +x starsignal_manager.sh && ./starsignal_manager.sh${NC}"
        CONFIRM_UNINSTALL="Uninstall StarSignalDecoder and backup save data? (y/n): "
        CONFIRM_CLEAN="Delete all save data and achievements? This will be backed up. (y/n): "
        CANCELLED="Operation cancelled."
        CHOOSE_BRANCH="Choose branch (main/dev) [${DEFAULT_BRANCH}]: "
        CHECKING_TERMINAL_ENCODING="Checking terminal encoding..."
        ENCODING_WARNING="Terminal encoding is not UTF-8. Set to UTF-8 to avoid issues..."
        TERMINAL_WARNING="Terminal type is not xterm-256color. Forced to xterm-256color."
        PRESS_ENTER_TO_CONTINUE="Press Enter to continue..."
        INVALID_INPUT_EMPTY="Input cannot be empty."
        INVALID_YES_NO="Please enter Y or N."
        GAME_START_OPTIONS="Enter game start options (e.g., --difficulty hard --tutorial): "
        GAME_START_NOTE="If game input is stuck, run in a native terminal or use 'stty sane' and 'export TERM=xterm-256color'."
        BACKUP_SUCCESS="Save data backed up to ${BACKUP_DIR}/"
        BACKUP_FAILED="Failed to backup save data. Check permissions."
        HELP_HEADER="【Help - Star Signal Decoder Manager】"
        HELP_UPDATE="Update Game: Downloads the latest version from the selected branch (main or dev)."
        HELP_REPAIR="Repair Installation: Reinstalls the game to fix corrupted files."
        HELP_CLEAN="Clean Save Data: Deletes all save files and achievements after backing them up."
        HELP_UNINSTALL="Uninstall Game: Removes the game and backs up save data."
        HELP_START="Start Game: Launches the game with optional command-line arguments."
        HELP_MANUAL="Show Manual Guide: Displays instructions for manual installation (e.g., for Windows)."
        HELP_HELP="Show Help: Displays this help information."
        HELP_EXIT="Exit: Quits the script."
        HELP_INSTALL_MAIN="Install Stable Version: Installs the main branch (stable)."
        HELP_INSTALL_DEV="Install Development Version: Installs the dev branch (experimental)."
        MANUAL_INSTALL_HEADER="【Manual Installation Guide】"
        MANUAL_INSTALL_REQUIREMENTS="Requirements:"
        MANUAL_INSTALL_PYTHON_PIP="Python 3.6+ and pip"
        MANUAL_INSTALL_GIT="Git"
        MANUAL_INSTALL_LINUX_MACOS_STEPS="For Linux/macOS:"
        MANUAL_INSTALL_PYTHON_LINUX="sudo apt update && sudo apt install -y python3 python3-dev python3-pip (Ubuntu/Debian) or sudo yum install -y python3 python3-devel python3-pip (CentOS/RHEL)"
        MANUAL_INSTALL_PYTHON_MACOS="brew install python3 (if Homebrew installed)"
        MANUAL_INSTALL_GIT_LINUX="sudo apt install -y git (Ubuntu/Debian) or sudo yum install -y git (CentOS/RHEL)"
        MANUAL_INSTALL_GIT_MACOS="brew install git (if Homebrew installed)"
        MANUAL_INSTALL_PIP_PATH="Ensure pip and PATH: python3 -m pip install --upgrade pip; export PATH=\$PATH:\$HOME/.local/bin"
        MANUAL_INSTALL_WINDOWS_STEPS="For Windows:"
        MANUAL_INSTALL_WINDOWS_PYTHON="Install Python 3.6+ from https://www.python.org/downloads/ (check 'Add Python to PATH')"
        MANUAL_INSTALL_WINDOWS_GIT="Install Git from https://git-scm.com/download/win (check 'Git from the command line...')"
        MANUAL_INSTALL_WINDOWS_PATH="Add Python Scripts to PATH if 'starsignal' not found (e.g., C:\\Users\\YOUR_USER\\AppData\\Roaming\\Python\\Python39\\Scripts)"
        MANUAL_INSTALL_GAME_CORE="Install Game Core:"
        MANUAL_INSTALL_STABLE_VERSION="pip3 install --user git+${REPO_URL}@main (Linux/macOS) / pip install --user git+${REPO_URL}@main (Windows)"
        MANUAL_INSTALL_DEV_VERSION="pip3 install --user git+${REPO_URL}@dev (Linux/macOS) / pip install --user git+${REPO_URL}@dev (Windows)"
        MANUAL_INSTALL_COLORAMA="pip3 install --user colorama (recommended for color output)"
        MANUAL_INSTALL_RUN_GAME="Run Game: starsignal"
        VERSION_WARNING="Warning: Script version (%s) may be outdated. Check %s for updates."
        TIMEOUT_MESSAGE="No input for 5 minutes. Exiting..."
        PROGRESS_BAR="Progress: [%-10s] %d%%"
    else
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
        SHOW_HELP="显示帮助"
        EXIT_OPTION="退出"
        ENTER_CHOICE="请选择一个选项： "
        INVALID_CHOICE="无效的选择，请从列表中选择一个数字。"
        INSTALLING_DEPENDENCIES="正在安装必要的依赖..."
        CHECKING_ENV="正在检查环境..."
        PYTHON_FOUND="检测到 Python 3。"
        PYTHON_NOT_FOUND="未检测到 Python 3。正在尝试安装..."
        PIP_FOUND="检测到 pip。"
        PIP_NOT_FOUND="未检测到 pip。正在尝试安装..."
        GIT_FOUND="检测到 Git。"
        GIT_NOT_FOUND="未检测到 Git。正在尝试安装..."
        INSTALLING_GAME="正在安装 星际迷航：信号解码..."
        INSTALL_SUCCESS="星际迷航：信号解码 安装成功！"
        INSTALL_FAILED="安装失败。请检查网络、依赖或 pip 版本。"
        UPDATE_SUCCESS="星际迷航：信号解码 更新成功！"
        UPDATE_FAILED="更新失败。请检查网络、依赖或 pip 版本。"
        REPAIR_SUCCESS="星际迷航：信号解码 修复成功！"
        REPAIR_FAILED="修复失败。请检查网络、依赖或 pip 版本。"
        CLEAN_SUCCESS="存档和成就数据清理成功！"
        CLEAN_FAILED="清理存档失败。请检查文件权限。"
        UNINSTALL_SUCCESS="星际迷航：信号解码 卸载成功！存档已备份。"
        UNINSTALL_FAILED="卸载失败。请查看终端输出详情。"
        PERMISSION_FIX="正在修复存档文件权限..."
        PERMISSION_SUCCESS="存档文件权限已修复。"
        PERMISSION_FAILED="无法修复权限。请运行：'chmod 666 ~/.starsignal*' (Linux/macOS) 或 'icacls %USERPROFILE%\\.starsignal* /grant Everyone:F' (Windows)。"
        PATH_FIX_PROMPT="Python 脚本目录不在 PATH 中。是否修复？(y/n)："
        PATH_FIX_LINUX_MACOS="已修复 Linux/macOS 的 PATH。请运行 'source ~/.bashrc' 或重启终端。"
        PATH_FIX_WINDOWS="已修复 Windows 的 PATH。请重启 PowerShell/Git Bash 或系统。"
        PATH_FIX_FAILED="无法修复 PATH。请手动添加 Python Scripts 到 PATH。"
        WARNING_PIPE="警告：本脚本设计为交互式使用。通过管道运行（例如 curl ... | sh）可能导致问题。请下载后本地运行：${YELLOW}curl -s ${REPO_URL}/main/starsignal_manager.sh -o starsignal_manager.sh && chmod +x starsignal_manager.sh && ./starsignal_manager.sh${NC}"
        CONFIRM_UNINSTALL="您确定要卸载 星际迷航：信号解码 并备份存档数据吗？(y/n)："
        CONFIRM_CLEAN="您确定要删除所有存档和成就数据吗？数据将先备份。(y/n)："
        CANCELLED="操作已取消。"
        CHOOSE_BRANCH="选择分支 (main/dev) [${DEFAULT_BRANCH}]： "
        CHECKING_TERMINAL_ENCODING="正在检查终端编码..."
        ENCODING_WARNING="终端编码不是 UTF-8，可能导致问题。正在设置为 UTF-8..."
        TERMINAL_WARNING="终端类型不是 xterm-256color，已强制设置为 xterm-256color。"
        PRESS_ENTER_TO_CONTINUE="按回车键继续..."
        INVALID_INPUT_EMPTY="输入不能为空。"
        INVALID_YES_NO="请输入 Y 或 N。"
        GAME_START_OPTIONS="请输入游戏启动选项（例如 --difficulty hard --tutorial）："
        GAME_START_NOTE="提示：如果游戏输入卡顿，请在本地终端运行，或尝试 'stty sane' 和 'export TERM=xterm-256color'。"
        BACKUP_SUCCESS="存档已备份到 ${BACKUP_DIR}/"
        BACKUP_FAILED="存档备份失败。请检查权限。"
        HELP_HEADER="【帮助 - 星际迷航：信号解码 管理器】"
        HELP_UPDATE="更新游戏：从选定分支（main 或 dev）下载最新版本。"
        HELP_REPAIR="修复安装：重新安装游戏以修复损坏的文件。"
        HELP_CLEAN="清理存档：删除所有存档和成就数据，先进行备份。"
        HELP_UNINSTALL="卸载游戏：移除游戏并备份存档数据。"
        HELP_START="启动游戏：使用可选命令行参数启动游戏。"
        HELP_MANUAL="显示手动指南：提供手动安装说明（例如 Windows）。"
        HELP_HELP="显示帮助：显示此帮助信息。"
        HELP_EXIT="退出：退出脚本。"
        HELP_INSTALL_MAIN="安装稳定版：安装 main 分支（稳定）。"
        HELP_INSTALL_DEV="安装开发版：安装 dev 分支（实验性）。"
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
        MANUAL_INSTALL_WINDOWS_PATH="如果 'starsignal' 命令未找到，请手动将 Python Scripts 路径添加到 PATH（例如 C:\\Users\\你的用户\\AppData\\Roaming\\Python\\Python39\\Scripts）"
        MANUAL_INSTALL_GAME_CORE="安装游戏核心："
        MANUAL_INSTALL_STABLE_VERSION="pip3 install --user git+${REPO_URL}@main (Linux/macOS) / pip install --user git+${REPO_URL}@main (Windows)"
        MANUAL_INSTALL_DEV_VERSION="pip3 install --user git+${REPO_URL}@dev (Linux/macOS) / pip install --user git+${REPO_URL}@dev (Windows)"
        MANUAL_INSTALL_COLORAMA="pip3 install --user colorama (推荐用于彩色输出)"
        MANUAL_INSTALL_RUN_GAME="运行游戏：starsignal"
        VERSION_WARNING="警告：脚本版本 (%s) 可能已过时。请访问 %s 检查更新。"
        TIMEOUT_MESSAGE="5 分钟无操作，退出脚本..."
        PROGRESS_BAR="进度：[%-10s] %d%%"
    fi
}

# 初始化配置并设置文本
init_config "$LANG_SET" "$DEBUG_MODE"
set_texts "$LANG_SET"

# --- 辅助函数 ---

# 日志记录
log_message() {
    local message="$1"
    local clean_message=$(echo "$message" | sed 's/\x1b\[[0-9;]*m//g')
    echo "$(date '+%Y-%m-%d %H:%M:%S') $clean_message" >> "$LOG_FILE" 2>/dev/null || {
        echo "Error: Cannot write to log file $LOG_FILE. Check permissions." >&2
        exit 1
    }
    if [ "$DEBUG_MODE" = true ]; then
        printf "${YELLOW}[DEBUG] %s${NC}\n" "$clean_message" >&2
    fi
}

# 状态/警告/错误输出
print_status() {
    printf "${GREEN}==> %s ${NC}\n" "$1" >&2
    log_message "Status: $1"
}

print_warning() {
    printf "${YELLOW}警告：%s ${NC}\n" "$1" >&2
    log_message "Warning: $1"
}

print_error() {
    printf "${RED}错误：%s ${NC}\n" "$1" >&2
    log_message "Error: $1"
}

# 检查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 检测操作系统
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

# 显示进度条
show_progress() {
    local duration=$1
    local steps=10
    local sleep_time=$(echo "$duration / $steps" | bc -l)
    local i
    for ((i=0; i<=steps; i++)); do
        local percent=$((i * 100 / steps))
        local filled=$((i))
        local empty=$((steps - i))
        local bar=$(printf "%${filled}s" | tr ' ' '#')
        bar+=$(printf "%${empty}s" | tr ' ' '-')
        printf "\r${PROGRESS_BAR}" "$bar" "$percent" >&2
        sleep "$sleep_time"
    done
    echo >&2
}

# 获取用户输入（用于非菜单输入，如 y/n 或文本）
get_user_input() {
    local prompt="$1"
    local input_type="$2"
    local choice=""
    local attempt=0
    local max_attempts=3

    stty sane 2>/dev/null
    if [ -t 0 ]; then
        dd if=/dev/stdin of=/dev/null bs=1 count=1000 iflag=nonblock 2>/dev/null
    fi

    while [ "$attempt" -lt "$max_attempts" ]; do
        printf "%b" "$prompt" >&2
        if [[ "$input_type" == "yes_no" ]]; then
            read -r -n 1 -t 60 choice 2>/dev/null
            echo >&2
        else
            read -r -t 60 choice 2>/dev/null
        fi

        log_message "Raw input for $input_type: '$choice'"

        choice=$(echo "$choice" | tr -d '[:space:]')
        log_message "Sanitized input for $input_type: '$choice'"

        case "$input_type" in
            "text")
                echo "$choice"
                return 0
                ;;
            "yes_no")
                if [[ "$choice" =~ ^[YyNn]$ ]]; then
                    echo "$choice"
                    return 0
                elif [ -z "$choice" ]; then
                    print_error "${INVALID_INPUT_EMPTY}"
                else
                    print_error "${INVALID_YES_NO}"
                fi
                ;;
        esac

        ((attempt++))
        if [ "$attempt" -ge "$max_attempts" ]; then
            print_error "Maximum input attempts reached. Aborting."
            log_message "Maximum input attempts reached."
            exit 1
        fi
        printf "${CYAN}%s${NC}\n" "${PRESS_ENTER_TO_CONTINUE}" >&2
        read -r -s -t 60 2>/dev/null || true
    done
    return 1
}

# 执行 sudo 命令
run_sudo_cmd() {
    local cmd="$1"
    log_message "Executing sudo command: $cmd"
    printf "${CYAN}Running: %s ${NC}\n" "$cmd" >&2
    if ! eval "$cmd"; then
        print_error "Command failed: $cmd"
        return 1
    fi
    return 0
}

# 超时处理
timeout_handler() {
    print_status "${TIMEOUT_MESSAGE}"
    log_message "Timeout after 5 minutes"
    exit 0
}

# --- 环境检查与安装 ---

check_python() {
    if command_exists python3; then
        PYTHON_CMD="python3"
        print_status "${PYTHON_FOUND}"
        return 0
    elif command_exists python; then
        local version=$(python -c 'import sys; print(sys.version_info.major)' 2>/dev/null)
        if [ "$version" == "3" ]; then
            PYTHON_CMD="python"
            print_status "${PYTHON_FOUND}"
            return 0
        fi
    fi
    print_warning "${PYTHON_NOT_FOUND}"
    return 1
}

check_pip() {
    if command_exists pip3; then
        PIP_CMD="pip3"
        print_status "${PIP_FOUND}"
        return 0
    elif command_exists pip; then
        PIP_CMD="pip"
        print_status "${PIP_FOUND}"
        return 0
    fi
    print_warning "${PIP_NOT_FOUND}"
    return 1
}

install_python() {
    log_message "Installing Python..."
    if [ "$OS" == "Linux" ]; then
        print_status "Running apt update..."
        if command_exists apt-get; then
            run_sudo_cmd "sudo apt-get update" || return 1
            print_status "Installing python3, python3-dev, python3-pip..."
            run_sudo_cmd "sudo apt-get install -y python3 python3-dev python3-pip" || return 1
        elif command_exists yum; then
            print_status "Installing python3, python3-devel, python3-pip..."
            run_sudo_cmd "sudo yum install -y python3 python3-devel python3-pip" || return 1
        else
            print_error "Unsupported package manager"
            return 1
        fi
    elif [ "$OS" == "macOS" ]; then
        if command_exists brew; then
            print_status "Installing python3 via Homebrew..."
            brew install python3 || return 1
        else
            print_warning "Homebrew not installed. Install Homebrew (https://brew.sh/) or Python manually."
            return 1
        fi
    elif [ "$OS" == "Windows" ]; then
        print_warning "Windows Python installation requires manual steps. See manual guide."
        return 1
    else
        print_warning "Unsupported OS for Python installation. Install Python 3.6+ manually."
        return 1
    fi
    check_python
    local result=$?
    log_message "Python installation attempt completed."
    return $result
}

install_pip() {
    log_message "Installing pip..."
    if [ -n "$PYTHON_CMD" ]; then
        print_status "Ensuring pip is up-to-date..."
        if ! "$PYTHON_CMD" -m ensurepip --upgrade 2>/dev/null; then
            print_warning "Failed to ensure pip. Trying get-pip.py..."
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
    check_pip
    local result=$?
    log_message "pip installation attempt completed."
    return $result
}

install_git() {
    log_message "Installing Git..."
    if [ "$OS" == "Linux" ]; then
        print_status "Installing Git..."
        if command_exists apt-get; then
            run_sudo_cmd "sudo apt-get install -y git" || return 1
        elif command_exists yum; then
            run_sudo_cmd "sudo yum install -y git" || return 1
        else
            print_error "Unsupported Linux package manager."
            return 1
        fi
    elif [ "$OS" == "macOS" ]; then
        if command_exists brew; then
            print_status "Installing Git via Homebrew..."
            brew install git || return 1
        else
            print_warning "Homebrew not installed. Install Homebrew (https://brew.sh/) or Git manually."
            return 1
        fi
    elif [ "$OS" == "Windows" ]; then
        print_warning "Windows Git installation requires manual steps. See manual guide."
        return 1
    else
        print_warning "Unsupported OS for Git installation. Install Git manually."
        return 1
    fi
    if ! command_exists git; then
        print_error "Git installation failed or not found in PATH."
        return 1
    fi
    log_message "Git installation attempt completed."
    return 0
}

check_path_for_starsignal() {
    if ! command_exists "$GAME_NAME"; then
        local reply_val=$(get_user_input "${YELLOW}${PATH_FIX_PROMPT}${NC}" "yes_no")
        if [[ "$reply_val" =~ ^[Yy]$ ]]; then
            fix_path
        fi
    fi
}

fix_path() {
    log_message "Fixing PATH..."
    if [ "$OS" == "Linux" ] || [ "$OS" == "macOS" ]; then
        LOCAL_BIN="$HOME/.local/bin"
        if [[ ":$PATH:" != *":$LOCAL_BIN:"* ]]; then
            touch "$HOME/.bashrc" 2>/dev/null || true
            touch "$HOME/.zshrc" 2>/dev/null
            echo "export PATH=\$PATH:$LOCAL_BIN" >> "$HOME/.bashrc"
            echo "export PATH=\$PATH:$LOCAL_BIN" >> "$HOME/.zshrc"
            export PATH="$PATH:$LOCAL_BIN"
            print_status "${PATH_FIX_LINUX_MACOS}"
            log_message "PATH fixed for Linux/macOS. Added $LOCAL_BIN."
        else
            print_status "PATH 已包含 $LOCAL_BIN。"
            log_message "PATH already contains $LOCAL_BIN."
        fi
    elif [ "$OS" == "Windows" ]; then
        print_warning "Windows PATH fixing is complex. Refer to manual instructions if needed."
        PYTHON_SCRIPTS_PATH=""
        if [ -n "$PYTHON_CMD" ]; then
            PYTHON_SCRIPTS_PATH=$("$PYTHON_CMD" -c "import site; print(site.USER_BASE + '\\\\Scripts')" 2>/dev/null | tr '\\' '/')
            if [ -z "$PYTHON_SCRIPTS_PATH" ] || [ ! -d "$PYTHON_SCRIPTS_PATH" ]; then
                PYTHON_SCRIPTS_PATH=$("$PYTHON_CMD" -c "import sys; print(sys.prefix + '\\\\Scripts')" 2>/dev/null | tr '\\' '/')
            fi
        fi
        if [ -n "$PYTHON_SCRIPTS_PATH" ] && [ -d "$PYTHON_SCRIPTS_PATH" ]; then
            PYTHON_SCRIPTS_PATH_WIN=$(echo "$PYTHON_SCRIPTS_PATH" | tr '/' '\\')
            powershell.exe -Command "[Environment]::SetEnvironmentVariable('Path', ([Environment]::GetEnvironmentVariable('Path', 'User') + ';${PYTHON_SCRIPTS_PATH_WIN}'), 'User')" >/dev/null 2>&1
            if [ $? -eq 0 ]; then
                print_status "${PATH_FIX_WINDOWS}"
                log_message "PATH fixed for Windows. Added $PYTHON_SCRIPTS_PATH."
            else
                print_error "${PATH_FIX_FAILED}"
                log_message "PATH fix failed for Windows (PowerShell error)."
            fi
        else
            print_error "${PATH_FIX_FAILED}"
            log_message "PATH fix failed for Windows (Scripts path not found)."
        fi
    fi
    log_message "PATH fix attempt completed."
}

check_terminal_encoding() {
    local encoding_ok=true
    if [ "$OS" == "Linux" ] || [ "$OS" == "macOS" ]; then
        local current_lang=$(locale | grep -E 'LC_CTYPE|LANG' | head -n 1 | cut -d'=' -f2 | tr -d '"' | cut -d'.' -f2 | tr '[:lower:]' '[:upper:]')
        if [[ "$current_lang" != "UTF-8" && "$current_lang" != "UTF8" ]]; then
            encoding_ok=false
            print_warning "${ENCODING_WARNING}"
            export LANG=zh_CN.UTF-8
            export LC_ALL=zh_CN.UTF-8
            log_message "Set LANG and LC_ALL to zh_CN.UTF-8"
        fi
    elif [ "$OS" == "Windows" ]; then
        local current_lang_windows=$(echo "$LANG" | cut -d'.' -f2 | tr '[:lower:]' '[:upper:]')
        if [ -z "$current_lang_windows" ] || [[ "$current_lang_windows" != "UTF-8" && "$current_lang_windows" != "UTF8" ]]; then
            local chcp_output=$(chcp 2>/dev/null | grep -oE '[0-9]+')
            if [[ "$chcp_output" != "65001" ]]; then
                encoding_ok=false
                print_warning "${ENCODING_WARNING}"
                chcp 65001 >/dev/null 2>&1
                log_message "Set Windows codepage to 65001 (UTF-8)"
            fi
        fi
    fi
    if [ "$TERM" != "xterm-256color" ]; then
        print_warning "${TERMINAL_WARNING}"
        log_message "Terminal type was '$TERM', forced to xterm-256color"
    fi
}

fix_save_permissions() {
    print_status "${PERMISSION_FIX}"
    log_message "${PERMISSION_FIX}"
    local permission_errors=0
    if [ "$OS" == "Linux" ] || [ "$OS" == "macOS" ]; then
        if [ -f "${DATA_FILE}" ]; then
            chmod 666 "${DATA_FILE}" || { log_message "Failed chmod on $DATA_FILE"; ((permission_errors++)); }
        fi
        for i in {1..3}; do
            if [ -f "${SAVE_FILE_PREFIX}${i}.json" ]; then
                chmod 666 "${SAVE_FILE_PREFIX}${i}.json" || { log_message "Failed chmod on ${SAVE_FILE_PREFIX}${i}.json"; ((permission_errors++)); }
            fi
        done
        if [ $permission_errors -eq 0 ]; then
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
        if [ $success -eq 1 ]; then
            print_status "${PERMISSION_SUCCESS}"
            log_message "${PERMISSION_SUCCESS}"
        else
            print_error "${PERMISSION_FAILED}"
            log_message "${PERMISSION_FAILED}"
        fi
    fi
}

backup_saves() {
    log_message "Backing up save data..."
    mkdir -p "$BACKUP_DIR" 2>/dev/null || {
        print_error "${BACKUP_FAILED}"
        log_message "Failed to create backup directory $BACKUP_DIR"
        return 1
    }
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_subdir="$BACKUP_DIR/backup_$timestamp"
    mkdir -p "$backup_subdir" 2>/dev/null
    local backed_up=false
    if [ -f "$DATA_FILE" ]; then
        cp "$DATA_FILE" "$backup_subdir/" && backed_up=true
    fi
    for i in {1..3}; do
        if [ -f "${SAVE_FILE_PREFIX}${i}.json" ]; then
            cp "${SAVE_FILE_PREFIX}${i}.json" "$backup_subdir/" && backed_up=true
        fi
    done
    if [ "$backed_up" = true ]; then
        print_status "${BACKUP_SUCCESS}"
        log_message "Save data backed up to $backup_subdir"
        return 0
    else
        print_warning "No save data found to backup."
        log_message "No save data found for backup."
        return 0
    fi
}

is_installed() {
    command_exists "$GAME_NAME"
}

# --- 核心功能函数 ---

run_environment_setup() {
    print_status "${CHECKING_ENV}"
    if ! check_python; then
        if ! install_python; then
            print_error "Python installation/check failed."
            return 1
        fi
    fi
    if ! check_pip; then
        if ! install_pip; then
            print_error "pip installation/check failed."
            return 1
        fi
    fi
    if ! command_exists git; then
        print_warning "${GIT_NOT_FOUND}"
        if ! install_git; then
            print_error "Git installation/check failed."
            return 1
        fi
    else
        print_status "${GIT_FOUND}"
    fi
    check_path_for_starsignal
    check_terminal_encoding
    return 0
}

do_install_game() {
    local branch=$1
    if ! run_environment_setup; then
        print_error "Environment setup failed."
        log_message "Environment setup failed."
        return 1
    fi
    print_status "${INSTALLING_GAME}"
    log_message "Installing game to $branch branch..."
    (
        show_progress 10 &
        "$PIP_CMD" install --user "git+${REPO_URL}@${branch}" > /tmp/starsignal_install.log 2>&1
    )
    if [ $? -eq 0 ]; then
        print_status "${INSTALL_SUCCESS}"
        log_message "${INSTALL_SUCCESS}"
        fix_save_permissions
    else
        print_error "${INSTALL_FAILED}"
        log_message "${INSTALL_FAILED}"
        cat /tmp/starsignal_install.log >&2
        return 1
    fi
    return 0
}

do_update_game() {
    if ! run_environment_setup; then
        print_error "Environment setup failed."
        log_message "Environment setup failed."
        return 1
    fi
    local branch=$(get_user_input "${YELLOW}${CHOOSE_BRANCH}${NC}" "text")
    branch=${branch:-$DEFAULT_BRANCH}
    print_status "${UPDATE_GAME}"
    log_message "Updating game to $branch branch..."
    (
        show_progress 10 &
        "$PIP_CMD" install --user --upgrade --force-reinstall "git+${REPO_URL}@${branch}" > /tmp/starsignal_update.log 2>&1
    )
    if [ $? -eq 0 ]; then
        print_status "${UPDATE_SUCCESS}"
        log_message "${UPDATE_SUCCESS}"
        fix_save_permissions
    else
        print_error "${UPDATE_FAILED}"
        log_message "${UPDATE_FAILED}"
        cat /tmp/starsignal_update.log >&2
        return 1
    fi
    return 0
}

do_repair_game() {
    if ! run_environment_setup; then
        print_error "Environment setup failed."
        log_message "Environment setup failed."
        return 1
    fi
    print_status "${REPAIR_GAME}"
    log_message "Repairing game installation..."
    (
        show_progress 10 &
        "$PIP_CMD" install --user --force-reinstall "git+${REPO_URL}@main" > /tmp/starsignal_repair.log 2>&1
    )
    if [ $? -eq 0 ]; then
        print_status "${REPAIR_SUCCESS}"
        log_message "${REPAIR_SUCCESS}"
        fix_save_permissions
    else
        print_error "${REPAIR_FAILED}"
        log_message "${REPAIR_FAILED}"
        cat /tmp/starsignal_repair.log >&2
        return 1
    fi
    return 0
}

do_clean_saves() {
    local reply_val=$(get_user_input "${YELLOW}${CONFIRM_CLEAN}${NC}" "yes_no")
    if [[ "$reply_val" =~ ^[Yy]$ ]]; then
        print_status "${CLEAN_SAVES}"
        log_message "Cleaning save data..."
        backup_saves || return 1
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

do_uninstall_game() {
    local reply_val=$(get_user_input "${YELLOW}${CONFIRM_UNINSTALL}${NC}" "yes_no")
    if [[ "$reply_val" =~ ^[Yy]$ ]]; then
        print_status "${UNINSTALL_GAME}"
        log_message "Uninstalling game..."
        backup_saves || return 1
        local uninstall_successful=0
        if command_exists "$PIP_CMD"; then
            if "$PIP_CMD" uninstall -y "$GAME_NAME" > /tmp/starsignal_uninstall.log 2>&1; then
                uninstall_successful=1
            else
                print_error "Pip uninstall failed. Trying manual removal."
                log_message "Pip uninstall failed."
                cat /tmp/starsignal_uninstall.log >&2
            fi
        else
            print_warning "pip not found. Attempting manual removal."
            log_message "Pip not found for uninstall."
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

do_start_game() {
    print_status "准备启动游戏..."
    if ! is_installed; then
        print_error "游戏未安装。请先安装游戏。"
        return 1
    fi
    local game_options=$(get_user_input "${BLUE}${GAME_START_OPTIONS}${NC}" "text")
    print_status "正在启动游戏: starsignal ${game_options}"
    log_message "Starting game: starsignal ${game_options}"
    if command_exists starsignal; then
        print_warning "${GAME_START_NOTE}"
        eval "starsignal ${game_options}" < /dev/stdin > /dev/stdout 2>&1
        if [ $? -ne 0 ]; then
            print_error "游戏运行出错。请检查错误信息或终端兼容性。"
            log_message "Game exited with error."
            return 1
        fi
    else
        print_error "starsignal 命令未找到。请检查 PATH 并重启终端。"
        return 1
    fi
    print_status "游戏运行结束。"
    return 0
}

do_show_manual_guide() {
    clear
    printf "${CYAN}==================================================================\n" >&2
    printf "%s\n" "${MANUAL_INSTALL_HEADER}" >&2
    printf "==================================================================${NC}\n" >&2
    echo >&2
    printf "${GREEN}%s${NC}\n" "${MANUAL_INSTALL_REQUIREMENTS}" >&2
    printf "- %s\n" "${MANUAL_INSTALL_PYTHON_PIP}" >&2
    printf "- %s\n" "${MANUAL_INSTALL_GIT}" >&2
    echo >&2
    printf "${GREEN}%s${NC}\n" "${MANUAL_INSTALL_LINUX_MACOS_STEPS}" >&2
    printf "1. 安装 Python 3.6+ 和 pip：\n" >&2
    printf "   %s\n" "${MANUAL_INSTALL_PYTHON_LINUX}" >&2
    printf "2. 安装 Git：\n" >&2
    printf "   %s\n" "${MANUAL_INSTALL_GIT_LINUX}" >&2
    printf "3. 确保 pip 和 PATH：\n" >&2
    printf "   %s\n" "${MANUAL_INSTALL_PIP_PATH}" >&2
    echo >&2
    printf "${GREEN}%s${NC}\n" "${MANUAL_INSTALL_WINDOWS_STEPS}" >&2
    printf "1. 安装 Python 3.6+ 和 pip：\n" >&2
    printf "   %s\n" "${MANUAL_INSTALL_WINDOWS_PYTHON}" >&2
    printf "2. 安装 Git for Windows：\n" >&2
    printf "   %s\n" "${MANUAL_INSTALL_WINDOWS_GIT}" >&2
    printf "3. 手动添加 PATH（如果 'starsignal' 未找到）：\n" >&2
    printf "   %s\n" "${MANUAL_INSTALL_WINDOWS_PATH}" >&2
    echo >&2
    printf "${GREEN}%s${NC}\n" "${MANUAL_INSTALL_GAME_CORE}" >&2
    printf "1. 安装游戏核心（稳定版）：\n" >&2
    printf "   %s\n" "${MANUAL_INSTALL_STABLE_VERSION}" >&2
    printf "2. 安装游戏核心（开发版）：\n" >&2
    printf "   %s\n" "${MANUAL_INSTALL_DEV_VERSION}" >&2
    printf "3. 安装彩色输出支持（推荐）：\n" >&2
    printf "   %s\n" "${MANUAL_INSTALL_COLORAMA}" >&2
    echo >&2
    printf "${GREEN}%s${NC}\n" "${MANUAL_INSTALL_RUN_GAME}" >&2
    echo >&2
    printf "${CYAN}==================================================================${NC}\n" >&2
    echo >&2
    get_user_input "${CYAN}${PRESS_ENTER_TO_CONTINUE}${NC}" "text" > /dev/null
}

do_show_help() {
    clear
    printf "${CYAN}==================================================================\n" >&2
    printf "%s\n" "${HELP_HEADER}" >&2
    printf "==================================================================${NC}\n" >&2
    echo >&2
    if is_installed; then
        printf "${GREEN}1) %s${NC}\n" "${UPDATE_GAME}" >&2
        printf "   %s\n" "${HELP_UPDATE}" >&2
        printf "${GREEN}2) %s${NC}\n" "${REPAIR_GAME}" >&2
        printf "   %s\n" "${HELP_REPAIR}" >&2
        printf "${GREEN}3) %s${NC}\n" "${CLEAN_SAVES}" >&2
        printf "   %s\n" "${HELP_CLEAN}" >&2
        printf "${GREEN}4) %s${NC}\n" "${UNINSTALL_GAME}" >&2
        printf "   %s\n" "${HELP_UNINSTALL}" >&2
        printf "${GREEN}5) %s${NC}\n" "${START_GAME}" >&2
        printf "   %s\n" "${HELP_START}" >&2
        printf "${GREEN}6) %s${NC}\n" "${SHOW_MANUAL}" >&2
        printf "   %s\n" "${HELP_MANUAL}" >&2
        printf "${GREEN}7) %s${NC}\n" "${SHOW_HELP}" >&2
        printf "   %s\n" "${HELP_HELP}" >&2
        printf "${GREEN}0) %s${NC}\n" "${EXIT_OPTION}" >&2
        printf "   %s\n" "${HELP_EXIT}" >&2
    else
        printf "${GREEN}1) %s${NC}\n" "${INSTALL_MAIN}" >&2
        printf "   %s\n" "${HELP_INSTALL_MAIN}" >&2
        printf "${GREEN}2) %s${NC}\n" "${INSTALL_DEV}" >&2
        printf "   %s\n" "${HELP_INSTALL_DEV}" >&2
        printf "${GREEN}3) %s${NC}\n" "${SHOW_MANUAL}" >&2
        printf "   %s\n" "${HELP_MANUAL}" >&2
        printf "${GREEN}4) %s${NC}\n" "${SHOW_HELP}" >&2
        printf "   %s\n" "${HELP_HELP}" >&2
        printf "${GREEN}0) %s${NC}\n" "${EXIT_OPTION}" >&2
        printf "   %s\n" "${HELP_EXIT}" >&2
    fi
    echo >&2
    printf "${CYAN}==================================================================${NC}\n" >&2
    echo >&2
    get_user_input "${CYAN}${PRESS_ENTER_TO_CONTINUE}${NC}" "text" > /dev/null
}

# --- 主菜单 ---
show_main_menu() {
    clear
    if ! "$IS_TERMINAL"; then
        print_warning "${WARNING_PIPE}"
        log_message "Non-terminal detected."
    fi
    printf "${CYAN}╔══════════════════════════════════════╗${NC}\n" >&2
    printf "${CYAN}║    %s           ${NC}\n" "${INSTALLATION_MENU}" >&2
    printf "${CYAN}╚══════════════════════════════════════╝${NC}\n" >&2
    echo >&2
    log_message "Displaying main menu"
    if is_installed; then
        printf "${GREEN}%s${NC}\n" "${ALREADY_INSTALLED}" >&2
    else
        printf "${YELLOW}%s${NC}\n" "${NOT_INSTALLED}" >&2
    fi
    echo >&2

    local options=()
    if is_installed; then
        options=(
            "${UPDATE_GAME}"
            "${REPAIR_GAME}"
            "${CLEAN_SAVES}"
            "${UNINSTALL_GAME}"
            "${START_GAME}"
            "${SHOW_MANUAL}"
            "${SHOW_HELP}"
            "${EXIT_OPTION}"
        )
    else
        options=(
            "${INSTALL_MAIN}"
            "${INSTALL_DEV}"
            "${SHOW_MANUAL}"
            "${SHOW_HELP}"
            "${EXIT_OPTION}"
        )
    fi

    stty sane 2>/dev/null
    if [ -t 0 ]; then
        dd if=/dev/stdin of=/dev/null bs=1 count=1000 iflag=nonblock 2>/dev/null
    fi

    PS3="${BLUE}${ENTER_CHOICE}${NC}"
    select opt in "${options[@]}"; do
        local choice="$REPLY"
        log_message "Raw select input: '$choice'"

        # 验证输入是否为数字
        if [[ ! "$choice" =~ ^[0-9]+$ ]]; then
            print_error "${INVALID_CHOICE}"
            log_message "Invalid choice: non-numeric input '$choice'"
            continue
        fi

        # 验证输入范围
        if is_installed; then
            if [ "$choice" -lt 0 ] || [ "$choice" -gt 7 ]; then
                print_error "${INVALID_CHOICE}"
                log_message "Invalid choice: out of range '$choice' (expected 0-7)"
                continue
            fi
        else
            if [ "$choice" -lt 0 ] || [ "$choice" -gt 4 ]; then
                print_error "${INVALID_CHOICE}"
                log_message "Invalid choice: out of range '$choice' (expected 0-4)"
                continue
            fi
        fi

        log_message "User selected: $choice ($opt)"
        echo "$choice"
        break
    done
}

# --- 脚本入口点 ---
main() {
    touch "$LOG_FILE" 2>/dev/null || {
        echo "Error: Cannot write to log file $LOG_FILE. Check permissions." >&2
        exit 1
    }
    > "$LOG_FILE"
    log_message "----------------------------------------------------"
    log_message "星际迷航：信号解码 管理脚本启动 v${SCRIPT_VERSION}"
    log_message "操作系统: $OS"
    log_message "语言设置: $LANG_SET"
    log_message "运行用户: $(whoami)"
    log_message "SUDO_USER: ${SUDO_USER:-none}"
    log_message "终端类型: $TERM"
    log_message "调试模式: $DEBUG_MODE"
    log_message "颜色主题: $COLOR_THEME"
    log_message "终端状态: $(stty -a 2>/dev/null)"
    log_message "----------------------------------------------------"

    check_terminal_encoding
    local repo_version="4.0.1"
    if [ "$SCRIPT_VERSION" != "$repo_version" ]; then
        print_warning "$(printf "${VERSION_WARNING}" "$SCRIPT_VERSION" "${REPO_URL}")"
    fi

    while true; do
        local user_choice=$(show_main_menu)
        if [ -z "$user_choice" ] || [[ ! "$user_choice" =~ ^[0-9]+$ ]]; then
            print_error "${INVALID_CHOICE}"
            log_message "Invalid choice: empty or non-numeric '$user_choice'"
            continue
        fi

        # 验证选择范围
        if is_installed; then
            if [ "$user_choice" -lt 0 ] || [ "$user_choice" -gt 7 ]; then
                print_error "${INVALID_CHOICE}"
                log_message "Invalid choice: out of range '$user_choice' (expected 0-7)"
                continue
            fi
        else
            if [ "$user_choice" -lt 0 ] || [ "$user_choice" -gt 4 ]; then
                print_error "${INVALID_CHOICE}"
                log_message "Invalid choice: out of range '$user_choice' (expected 0-4)"
                continue
            fi
        fi

        clear
        if is_installed; then
            case "$user_choice" in
                1) do_update_game ;;
                2) do_repair_game ;;
                3) do_clean_saves ;;
                4) do_uninstall_game ;;
                5) do_start_game ;;
                6) do_show_manual_guide ;;
                7) do_show_help ;;
                0) print_status "退出脚本。"; log_message "Script exited."; exit 0 ;;
            esac
        else
            case "$user_choice" in
                1) do_install_game main ;;
                2) do_install_game dev ;;
                3) do_show_manual_guide ;;
                4) do_show_help ;;
                0) print_status "退出脚本。"; log_message "Script exited."; exit 0 ;;
            esac
        fi
        echo >&2
        printf "${CYAN}%s${NC}\n" "${PRESS_ENTER_TO_CONTINUE}" >&2
        read -r -s -t 60 || true
        echo >&2
    done
}

main "$@"
