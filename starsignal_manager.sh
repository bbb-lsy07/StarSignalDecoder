#!/bin/bash

# ==============================================================================
# 星际迷航：信号解码 - 快速部署管理脚本 v4.0.2
# 作者：bbb-lsy07
# 邮箱：lisongyue0125@163.com
#
# 功能：
#   - 跨平台支持 (Linux/macOS 自动化，Windows 提供手动指南)
#   - 自动检测和安装依赖 (Python3, pip, Git)
#   - 一键安装稳定版 (main) 或开发版 (dev) 游戏
#   - 支持游戏更新、修复、清理存档、卸载
#   - 启动游戏，支持命令行选项 (难度、教程等)
#   - 自动修复 PATH 和终端编码
#   - 所有日志和错误直接输出到终端
#
# 变更日志：
#   v4.0.2 (2025-05-25):
#     - 移除配置文件依赖，硬编码语言(zh)、分支(main)、主题(default)
#     - 将日志输出整合到终端，移除单独日志文件
#     - 修复菜单选择逻辑，确保数字输入(如1)正确处理
#     - 修正函数定义顺序，防止“未找到命令”错误
#     - 移除存档备份和超时退出，简化快速部署
#     - 增强错误报告，安装/更新失败时显示详细输出
#   v4.0.0 (2025-05-25):
#     - 全新菜单系统，使用 bash select 命令
#     - 添加配置文件、进度条、帮助系统、存档备份
# ==============================================================================

# --- 定义颜色 ---
DEFAULT_RED='\033[0;31m'
DEFAULT_GREEN='\033[0;32m'
DEFAULT_YELLOW='\033[0;33m'
DEFAULT_BLUE='\033[0;34m'
DEFAULT_NC='\033[0m' # No Color

RED="$DEFAULT_RED"
GREEN="$DEFAULT_GREEN"
YELLOW="$DEFAULT_YELLOW"
BLUE="$DEFAULT_BLUE"
NC="$DEFAULT_NC"

# --- 全局变量 ---
REPO_URL="https://github.com/bbb-lsy07/StarSignalDecoder.git"
GAME_NAME="starsignal"
DATA_FILE="$HOME/.starsignal_data.json"
SAVE_FILE_PREFIX="$HOME/.starsignal_save_"
SCRIPT_VERSION="4.0.2"
PYTHON_CMD=""
PIP_CMD=""
DEBUG_MODE=false
LANG_SET="zh"
DEFAULT_BRANCH="main"

# 如果以 root 运行，调整文件路径
if [ "$(id -u)" -eq 0 ] && [ -n "$SUDO_USER" ]; then
    DATA_FILE="/home/$SUDO_USER/.starsignal_data.json"
    SAVE_FILE_PREFIX="/home/$SUDO_USER/.starsignal_save_"
fi

# 检查是否在终端运行
IS_TERMINAL=true
if ! [ -t 0 ]; then
    IS_TERMINAL=false
fi

# 解析命令行参数
while [ "$#" -gt 0 ]; do
    case "$1" in
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

# --- 文本定义 ---
set_texts() {
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
    INSTALL_FAILED="安装失败。请检查网络、依赖或 pip 版本："
    UPDATE_SUCCESS="星际迷航：信号解码 更新成功！"
    UPDATE_FAILED="更新失败。请检查网络、依赖或 pip 版本："
    REPAIR_SUCCESS="星际迷航：信号解码 修复成功！"
    REPAIR_FAILED="修复失败。请检查网络、依赖或 pip 版本："
    CLEAN_SUCCESS="存档和成就数据清理成功！"
    CLEAN_FAILED="清理存档失败。请检查文件权限。"
    UNINSTALL_SUCCESS="星际迷航：信号解码 卸载成功！"
    UNINSTALL_FAILED="卸载失败。请查看输出详情："
    PERMISSION_FIX="正在修复存档文件权限..."
    PERMISSION_SUCCESS="存档文件权限已修复。"
    PERMISSION_FAILED="无法修复权限。请运行：'chmod 666 ~/.starsignal*'。"
    PATH_FIX_PROMPT="Python 脚本目录不在 PATH 中。是否修复？(y/n)："
    PATH_FIX_LINUX="已修复 Linux 的 PATH。请运行 'source ~/.bashrc' 或重启终端。"
    PATH_FIX_FAILED="无法修复 PATH。请手动添加 Python Scripts 到 PATH。"
    WARNING_PIPE="警告：本脚本设计为交互式使用。通过管道运行（例如 curl ... | sh）可能导致问题。请下载后本地运行：${YELLOW}curl -s ${REPO_URL}/main/starsignal_manager.sh -o starsignal_manager.sh && chmod +x starsignal_manager.sh && ./starsignal_manager.sh${NC}"
    CONFIRM_UNINSTALL="您确定要卸载 星际迷航：信号解码吗？(y/n)："
    CONFIRM_CLEAN="您确定要删除所有存档和成就数据吗？(y/n)："
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
    HELP_HEADER="【帮助 - 星际迷航：信号解码 管理器】"
    HELP_UPDATE="更新游戏：从选定分支（main 或 dev）下载最新版本。"
    HELP_REPAIR="修复安装：重新安装游戏以修复损坏的文件。"
    HELP_CLEAN="清理存档：删除所有存档和成就数据。"
    HELP_UNINSTALL="卸载游戏：移除游戏。"
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
    MANUAL_INSTALL_LINUX_STEPS="适用于 Linux："
    MANUAL_INSTALL_PYTHON_LINUX="sudo apt update && sudo apt install -y python3 python3-dev python3-pip"
    MANUAL_INSTALL_GIT_LINUX="sudo apt install -y git"
    MANUAL_INSTALL_PIP_PATH="确保 pip 和 PATH：python3 -m pip install --upgrade pip; export PATH=\$PATH:\$HOME/.local/bin"
    MANUAL_INSTALL_GAME_CORE="安装游戏核心："
    MANUAL_INSTALL_STABLE_VERSION="pip3 install --user git+${REPO_URL}@main"
    MANUAL_INSTALL_DEV_VERSION="pip3 install --user git+${REPO_URL}@dev"
    MANUAL_INSTALL_COLORAMA="pip3 install --user colorama (推荐用于彩色输出)"
    MANUAL_INSTALL_RUN_GAME="运行游戏：starsignal"
    VERSION_WARNING="警告：脚本版本 (%s) 可能已过时。请访问 %s 检查更新。"
    PROGRESS_BAR="进度：[%-10s] %d%%"
}

# 初始化文本
set_texts

# --- 辅助函数 ---

# 日志输出到终端
print_log() {
    local message="$1"
    local clean_message=$(echo "$message" | sed 's/\x1b\[[0-9;]*m//g')
    printf "${YELLOW}[%s] %s${NC}\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$clean_message" >&2
    if [ "$DEBUG_MODE" = true ]; then
        printf "${YELLOW}[DEBUG] %s${NC}\n" "$clean_message" >&2
    fi
}

# 状态/警告/错误输出
print_status() {
    printf "${GREEN}==> %s ${NC}\n" "$1" >&2
    print_log "Status: $1"
}

print_warning() {
    printf "${YELLOW}警告：%s ${NC}\n" "$1" >&2
    print_log "Warning: $1"
}

print_error() {
    printf "${RED}错误：%s ${NC}\n" "$1" >&2
    print_log "Error: $1"
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

        print_log "Raw input for $input_type: '$choice'"
        choice=$(echo "$choice" | tr -d '[:space:]')
        print_log "Sanitized input for $input_type: '$choice'"

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
            print_error "达到最大输入尝试次数，中止。"
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
    print_log "Executing sudo command: $cmd"
    printf "${CYAN}Running: %s ${NC}\n" "$cmd" >&2
    if ! eval "$cmd"; then
        print_error "命令失败: $cmd"
        return 1
    fi
    return 0
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
    print_log "Installing Python..."
    if [ "$OS" == "Linux" ]; then
        print_status "运行 apt update..."
        if command_exists apt-get; then
            run_sudo_cmd "sudo apt-get update" || return 1
            print_status "安装 python3, python3-dev, python3-pip..."
            run_sudo_cmd "sudo apt-get install -y python3 python3-dev python3-pip" || return 1
        else
            print_error "不支持的包管理器"
            return 1
        fi
    else
        print_warning "不支持的操作系统用于 Python 安装。请手动安装 Python 3.6+。"
        return 1
    fi
    check_python
    local result=$?
    print_log "Python 安装尝试完成。"
    return $result
}

install_pip() {
    print_log "Installing pip..."
    if [ -n "$PYTHON_CMD" ]; then
        print_status "确保 pip 最新..."
        if ! "$PYTHON_CMD" -m ensurepip --upgrade 2>/dev/null; then
            print_warning "无法确保 pip。尝试 get-pip.py..."
            if ! curl -s https://bootstrap.pypa.io/get-pip.py | "$PYTHON_CMD"; then
                print_error "通过 get-pip.py 安装 pip 失败。"
                return 1
            fi
        fi
        print_status "升级 pip..."
        "$PYTHON_CMD" -m pip install --upgrade pip || return 1
    else
        print_error "未找到 Python 命令，无法安装 pip。"
        return 1
    fi
    check_pip
    local result=$?
    print_log "pip 安装尝试完成。"
    return $result
}

install_git() {
    print_log "Installing Git..."
    if [ "$OS" == "Linux" ]; then
        print_status "安装 Git..."
        if command_exists apt-get; then
            run_sudo_cmd "sudo apt-get install -y git" || return 1
        else
            print_error "不支持的 Linux 包管理器。"
            return 1
        fi
    else
        print_warning "不支持的操作系统用于 Git 安装。请手动安装 Git。"
        return 1
    fi
    if ! command_exists git; then
        print_error "Git 安装失败或在 PATH 中未找到。"
        return 1
    fi
    print_log "Git 安装尝试完成。"
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
    print_log "Fixing PATH..."
    if [ "$OS" == "Linux" ]; then
        LOCAL_BIN="$HOME/.local/bin"
        if [[ ":$PATH:" != *":$LOCAL_BIN:"* ]]; then
            touch "$HOME/.bashrc" 2>/dev/null || true
            echo "export PATH=\$PATH:$LOCAL_BIN" >> "$HOME/.bashrc"
            export PATH="$PATH:$LOCAL_BIN"
            print_status "${PATH_FIX_LINUX}"
            print_log "PATH fixed for Linux. Added $LOCAL_BIN."
        else
            print_status "PATH 已包含 $LOCAL_BIN。"
            print_log "PATH already contains $LOCAL_BIN."
        fi
    else
        print_error "${PATH_FIX_FAILED}"
        print_log "PATH fix failed for non-Linux OS."
    fi
    print_log "PATH fix attempt completed."
}

check_terminal_encoding() {
    local encoding_ok=true
    if [ "$OS" == "Linux" ]; then
        local current_lang=$(locale | grep -E 'LC_CTYPE|LANG' | head -n 1 | cut -d'=' -f2 | tr -d '"' | cut -d'.' -f2 | tr '[:lower:]' '[:upper:]')
        if [[ "$current_lang" != "UTF-8" && "$current_lang" != "UTF8" ]]; then
            encoding_ok=false
            print_warning "${ENCODING_WARNING}"
            export LANG=zh_CN.UTF-8
            export LC_ALL=zh_CN.UTF-8
            print_log "Set LANG and LC_ALL to zh_CN.UTF-8"
        fi
    fi
    if [ "$TERM" != "xterm-256color" ]; then
        print_warning "${TERMINAL_WARNING}"
        print_log "Terminal type was '$TERM', forced to xterm-256color"
    fi
}

fix_save_permissions() {
    print_status "${PERMISSION_FIX}"
    print_log "${PERMISSION_FIX}"
    if [ "$OS" == "Linux" ]; then
        if [ -f "${DATA_FILE}" ]; then
            chmod 666 "${DATA_FILE}" || print_error "${PERMISSION_FAILED}"
        fi
        for i in {1..3}; do
            if [ -f "${SAVE_FILE_PREFIX}${i}.json" ]; then
                chmod 666 "${SAVE_FILE_PREFIX}${i}.json" || print_error "${PERMISSION_FAILED}"
            fi
        done
        print_status "${PERMISSION_SUCCESS}"
        print_log "${PERMISSION_SUCCESS}"
    else
        print_warning "权限修复仅支持 Linux。"
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
            print_error "Python 安装/检查失败。"
            return 1
        fi
    fi
    if ! check_pip; then
        if ! install_pip; then
            print_error "pip 安装/检查失败。"
            return 1
        fi
    fi
    if ! command_exists git; then
        print_warning "${GIT_NOT_FOUND}"
        if ! install_git; then
            print_error "Git 安装/检查失败。"
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
        print_error "环境设置失败。"
        print_log "Environment setup failed."
        return 1
    fi
    print_status "${INSTALLING_GAME}"
    print_log "Installing game to $branch branch..."
    (
        show_progress 10 &
        "$PIP_CMD" install --user "git+${REPO_URL}@${branch}" > /tmp/starsignal_install.log 2>&1
    )
    if [ $? -eq 0 ]; then
        print_status "${INSTALL_SUCCESS}"
        print_log "${INSTALL_SUCCESS}"
        fix_save_permissions
    else
        print_error "${INSTALL_FAILED}"
        print_log "${INSTALL_FAILED}"
        cat /tmp/starsignal_install.log >&2
        return 1
    fi
    return 0
}

do_update_game() {
    if ! run_environment_setup; then
        print_error "环境设置失败。"
        print_log "Environment setup failed."
        return 1
    fi
    local branch=$(get_user_input "${YELLOW}${CHOOSE_BRANCH}${NC}" "text")
    branch=${branch:-$DEFAULT_BRANCH}
    print_status "${UPDATE_GAME}"
    print_log "Updating game to $branch branch..."
    (
        show_progress 10 &
        "$PIP_CMD" install --user --upgrade --force-reinstall "git+${REPO_URL}@${branch}" > /tmp/starsignal_update.log 2>&1
    )
    if [ $? -eq 0 ]; then
        print_status "${UPDATE_SUCCESS}"
        print_log "${UPDATE_SUCCESS}"
        fix_save_permissions
    else
        print_error "${UPDATE_FAILED}"
        print_log "${UPDATE_FAILED}"
        cat /tmp/starsignal_update.log >&2
        return 1
    fi
    return 0
}

do_repair_game() {
    if ! run_environment_setup; then
        print_error "环境设置失败。"
        print_log "Environment setup failed."
        return 1
    fi
    print_status "${REPAIR_GAME}"
    print_log "Repairing game installation..."
    (
        show_progress 10 &
        "$PIP_CMD" install --user --force-reinstall "git+${REPO_URL}@main" > /tmp/starsignal_repair.log 2>&1
    )
    if [ $? -eq 0 ]; then
        print_status "${REPAIR_SUCCESS}"
        print_log "${REPAIR_SUCCESS}"
        fix_save_permissions
    else
        print_error "${REPAIR_FAILED}"
        print_log "${REPAIR_FAILED}"
        cat /tmp/starsignal_repair.log >&2
        return 1
    fi
    return 0
}

do_clean_saves() {
    local reply_val=$(get_user_input "${YELLOW}${CONFIRM_CLEAN}${NC}" "yes_no")
    if [[ "$reply_val" =~ ^[Yy]$ ]]; then
        print_status "${CLEAN_SAVES}"
        print_log "Cleaning save data..."
        rm -f "$DATA_FILE"
        for i in {1..3}; do
            rm -f "${SAVE_FILE_PREFIX}${i}.json"
        done
        if [ ! -f "$DATA_FILE" ] && [ ! -f "${SAVE_FILE_PREFIX}1.json" ] && [ ! -f "${SAVE_FILE_PREFIX}2.json" ] && [ ! -f "${SAVE_FILE_PREFIX}3.json" ]; then
            print_status "${CLEAN_SUCCESS}"
            print_log "${CLEAN_SUCCESS}"
        else
            print_error "${CLEAN_FAILED}"
            print_log "${CLEAN_FAILED}"
            return 1
        fi
    else
        print_status "${CANCELLED}"
        print_log "Clean saves cancelled."
        return 1
    fi
    return 0
}

do_uninstall_game() {
    local reply_val=$(get_user_input "${YELLOW}${CONFIRM_UNINSTALL}${NC}" "yes_no")
    if [[ "$reply_val" =~ ^[Yy]$ ]]; then
        print_status "${UNINSTALL_GAME}"
        print_log "Uninstalling game..."
        local uninstall_successful=0
        if command_exists "$PIP_CMD"; then
            if "$PIP_CMD" uninstall -y "$GAME_NAME" > /tmp/starsignal_uninstall.log 2>&1; then
                uninstall_successful=1
            else
                print_error "Pip 卸载失败。尝试手动移除。"
                print_log "Pip uninstall failed."
                cat /tmp/starsignal_uninstall.log >&2
            fi
        else
            print_warning "未找到 pip。尝试手动移除。"
            print_log "Pip not found for uninstall."
        fi
        rm -f "$DATA_FILE"
        for i in {1..3}; do
            rm -f "${SAVE_FILE_PREFIX}${i}.json"
        done
        if ! is_installed; then
            print_status "${UNINSTALL_SUCCESS}"
            print_log "${UNINSTALL_SUCCESS}"
            return 0
        else
            print_error "${UNINSTALL_FAILED}"
            print_log "${UNINSTALL_FAILED}"
            return 1
        fi
    else
        print_status "${CANCELLED}"
        print_log "Uninstall cancelled."
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
    print_log "Starting game: starsignal ${game_options}"
    if command_exists starsignal; then
        print_warning "${GAME_START_NOTE}"
        eval "starsignal ${game_options}" < /dev/stdin > /dev/stdout 2>&1
        if [ $? -ne 0 ]; then
            print_error "游戏运行出错。请检查错误信息或终端兼容性。"
            print_log "Game exited with error."
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
    printf "${GREEN}%s${NC}\n" "${MANUAL_INSTALL_LINUX_STEPS}" >&2
    printf "1. 安装 Python 3.6+ 和 pip：\n" >&2
    printf "   %s\n" "${MANUAL_INSTALL_PYTHON_LINUX}" >&2
    printf "2. 安装 Git：\n" >&2
    printf "   %s\n" "${MANUAL_INSTALL_GIT_LINUX}" >&2
    printf "3. 确保 pip 和 PATH：\n" >&2
    printf "   %s\n" "${MANUAL_INSTALL_PIP_PATH}" >&2
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
        print_log "Non-terminal detected."
    fi
    printf "${CYAN}╔══════════════════════════════════════╗${NC}\n" >&2
    printf "${CYAN}║    %s           ${NC}\n" "${INSTALLATION_MENU}" >&2
    printf "${CYAN}╚══════════════════════════════════════╝${NC}\n" >&2
    echo >&2
    print_log "Displaying main menu"
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
        print_log "Raw select input: '$choice'"

        # 验证输入是否为数字
        if [[ ! "$choice" =~ ^[0-9]+$ ]]; then
            print_error "${INVALID_CHOICE}"
            print_log "Invalid choice: non-numeric input '$choice'"
            continue
        fi

        # 验证输入范围
        if is_installed; then
            if [ "$choice" -lt 0 ] || [ "$choice" -gt 7 ]; then
                print_error "${INVALID_CHOICE}"
                print_log "Invalid choice: out of range '$choice' (expected 0-7)"
                continue
            fi
        else
            if [ "$choice" -lt 0 ] || [ "$choice" -gt 4 ]; then
                print_error "${INVALID_CHOICE}"
                print_log "Invalid choice: out of range '$choice' (expected 0-4)"
                continue
            fi
        fi

        print_log "User selected: $choice ($opt)"
        echo "$choice"
        break
    done
}

# --- 脚本入口点 ---
main() {
    print_log "星际迷航：信号解码 管理脚本启动 v${SCRIPT_VERSION}"
    print_log "操作系统: $OS"
    print_log "运行用户: $(whoami)"
    print_log "SUDO_USER: ${SUDO_USER:-none}"
    print_log "终端类型: $TERM"
    print_log "调试模式: $DEBUG_MODE"

    check_terminal_encoding
    local repo_version="4.0.2"
    if [ "$SCRIPT_VERSION" != "$repo_version" ]; then
        print_warning "$(printf "${VERSION_WARNING}" "$SCRIPT_VERSION" "${REPO_URL}")"
    fi

    while true; do
        local user_choice=$(show_main_menu)
        if [ -z "$user_choice" ] || [[ ! "$user_choice" =~ ^[0-9]+$ ]]; then
            print_error "${INVALID_CHOICE}"
            print_log "Invalid choice: empty or non-numeric '$user_choice'"
            continue
        fi

        if is_installed; then
            if [ "$user_choice" -lt 0 ] || [ "$user_choice" -gt 7 ]; then
                print_error "${INVALID_CHOICE}"
                print_log "Invalid choice: out of range '$user_choice' (expected 0-7)"
                continue
            fi
        else
            if [ "$user_choice" -lt 0 ] || [ "$user_choice" -gt 4 ]; then
                print_error "${INVALID_CHOICE}"
                print_log "Invalid choice: out of range '$user_choice' (expected 0-4)"
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
                0) print_status "退出脚本。"; print_log "Script exited."; exit 0 ;;
            esac
        else
            case "$user_choice" in
                1) do_install_game main ;;
                2) do_install_game dev ;;
                3) do_show_manual_guide ;;
                4) do_show_help ;;
                0) print_status "退出脚本。"; print_log "Script exited."; exit 0 ;;
            esac
        fi
        echo >&2
        printf "${CYAN}%s${NC}\n" "${PRESS_ENTER_TO_CONTINUE}" >&2
        read -r -s -t 60 || true
        echo >&2
    done
}

main "$@"
