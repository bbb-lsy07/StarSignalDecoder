#!/bin/sh
# 星际迷航：信号解码管理脚本
# 版本：1.6.0
# 作者：bbb-lsy07
# 许可证：MIT
# GitHub：https://github.com/bbb-lsy07/StarSignalDecoder
# 描述：用于星际迷航：信号解码的通用安装、更新、修复和卸载脚本，支持 Linux、macOS 和 Windows
# 使用方法：
#   推荐方式 (Recommended):
#   Linux/macOS：curl -s https://raw.githubusercontent.com/bbb-lsy07/StarSignalDecoder/main/starsignal_manager.sh -o starsignal_manager.sh && sh starsignal_manager.sh
#   Windows：curl -s https://raw.githubusercontent.com/bbb-lsy07/StarSignalDecoder/main/starsignal_manager.sh -o starsignal_manager.sh && sh starsignal_manager.sh
#   本地运行：chmod +x starsignal_manager.sh && ./starsignal_manager.sh

# 初始化变量
LOG_FILE="$HOME/.starsignal_install.log"
REPO_URL="https://github.com/bbb-lsy07/StarSignalDecoder.git"
DEFAULT_BRANCH="main"
PYTHON_MIN_VERSION="3.6"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
LANG_MODE="zh" # Default language, will be detected or chosen
MAX_RETRIES=3
RETRY_DELAY=5

# 检测语言函数 - 仅根据命令行参数或系统设置LANG_MODE
detect_language() {
    local lang_arg_set=0
    # Check for --lang argument first
    local i
    for i in "$@"; do
        if [ "$i" = "--lang" ]; then
            local next_arg_index=0
            local current_arg
            for current_arg in "$@"; do
                next_arg_index=$((next_arg_index + 1))
                if [ "$current_arg" = "--lang" ]; then
                    local lang_val="${!next_arg_index}" # Get argument by index
                    if [ "$lang_val" = "en" ]; then
                        LANG_MODE="en"
                        lang_arg_set=1
                        return
                    elif [ "$lang_val" = "zh" ]; then
                        LANG_MODE="zh"
                        lang_arg_set=1
                        return
                    fi
                fi
            done
        fi
    done

    # If --lang not specified, detect from system
    if [ "$lang_arg_set" -eq 0 ]; then
        if [ -n "$LANG" ] && echo "$LANG" | grep -qi "zh"; then
            LANG_MODE="zh"
        elif [ "$(uname)" = "Darwin" ] && defaults read NSGlobalDomain AppleLanguages 2>/dev/null | grep -q "zh"; then
            LANG_MODE="zh"
        elif [ -n "$SYSTEMROOT" ] && powershell -Command "Get-Culture" 2>/dev/null | grep -qi "zh"; then
            LANG_MODE="zh"
        else
            LANG_MODE="en"
        fi
    fi
}

# 翻译函数 - 仅返回翻译后的字符串，不打印换行
translate() {
    key="$1"
    shift
    local translated_string

    if [ "$LANG_MODE" = "zh" ]; then
        case "$key" in
            "welcome") translated_string="星际迷航：信号解码管理器 v1.6.0";;
            "choose_lang") translated_string="请选择语言 (zh/en) [默认 $(echo "$LANG_MODE" | tr 'a-z' 'A-Z')]: ";;
            "status_installed") printf -v translated_string "状态：已安装（版本：%s，分支：%s）" "$@";;
            "status_not_installed") translated_string="状态：未安装";;
            "save_files_present") translated_string="存档文件：存在";;
            "save_files_none") translated_string="存档文件：无";;
            "choose_option") translated_string="请输入选项编号：";;
            "invalid_choice") translated_string="无效选项，请重新输入";;
            "install_menu") translated_string="1) 安装\n2) 检查/修复环境\n3) 退出";;
            "installed_menu") translated_string="1) 更新\n2) 修复\n3) 清理存档\n4) 卸载\n5) 检查/修复环境\n6) 退出";;
            "branch_prompt") translated_string="请选择安装分支：\n1) main（稳定版，推荐）\n2) dev（开发版，最新功能）";;
            "choose_branch") translated_string="选择（1-2）[默认 1]：";;
            "installing") printf -v translated_string "正在安装 %s 分支..." "$@";;
            "updating") printf -v translated_string "正在更新到 %s 分支..." "$@";;
            "repairing") translated_string="正在修复安装...";;
            "cleaning_saves") translated_string="正在清理存档文件...";;
            "uninstalling") translated_string="正在卸载...";;
            "confirm_clean") translated_string="是否确认删除存档？（y/n）：";;
            "clean_cancelled") translated_string="已取消存档清理";;
            "installation_complete") translated_string="安装完成！运行 'starsignal' 开始游戏！";;
            "update_complete") translated_string="更新完成！";;
            "repair_complete") translated_string="修复完成！";;
            "uninstall_complete") translated_string="卸载完成！";;
            "environment_ready") translated_string="环境检查完成，准备就绪！";;
            "network_error") translated_string="网络错误：无法连接到 GitHub";;
            "network_options") translated_string="1) 尝试 Google DNS (8.8.8.8)\n2) 继续（可能失败）\n3) 退出";;
            "python_not_found") printf -v translated_string "未找到 Python3 或版本过旧（需要 >= %s）。是否安装？（y/n）：" "$@";;
            "pip_not_found") translated_string="未找到 pip3。是否安装？（y/n）：";;
            "git_not_found") translated_string="未找到 git。是否安装？（y/n）：";;
            "path_not_found") translated_string="PATH 未包含所需路径。是否修复？（y/n）：";;
            "permission_warning") translated_string="警告：无法修复存档权限，请手动运行：chmod 666 ~/.starsignal*（Windows：icacls \"%USERPROFILE%\\.starsignal*\" /grant Everyone:F）";;
            "progress") printf -v translated_string "[%s] 正在处理..." "$@";;
            "error") printf -v translated_string "错误：%s" "$@";;
            "check_log") printf -v translated_string "请查看 %s 获取详细信息" "$@";;
            "confirm_action") printf -v translated_string "是否继续执行 %s？（y/n）：" "$@";;
            "error_non_interactive") printf -v translated_string "此脚本需要交互式运行。请下载脚本后执行，例如：\n%s\n%s" "$@";;
            "error_non_interactive_desc_linux_macos") translated_string="Linux/macOS: curl -s https://raw.githubusercontent.com/bbb-lsy07/StarSignalDecoder/main/starsignal_manager.sh -o starsignal_manager.sh && sh starsignal_manager.sh";;
            "error_non_interactive_desc_windows") translated_string="Windows:     curl -s https://raw.githubusercontent.com/bbb-lsy07/StarSignalDecoder/main/starsignal_manager.sh -o starsignal_manager.sh && sh starsignal_manager.sh";;
            "detected_os") printf -v translated_string "检测到操作系统：%s %s" "$@";;
            "network_retry") printf -v translated_string "网络连接失败，尝试重试 %s/%s" "$@";;
            "warn_set_dns_failed") translated_string="警告：无法设置 DNS";;
            "google_dns_added") translated_string="已添加 Google DNS";;
            "skip_network_check") translated_string="跳过网络检查";;
            "python_install_cancelled") translated_string="已取消 Python 安装";;
            "python_install_success") translated_string="Python 安装成功";;
            "installing_homebrew") translated_string="正在安装 Homebrew...";;
            "pip_install_cancelled") translated_string="已取消 pip 安装";;
            "ensurepip_failed") translated_string="ensurepip 失败，正在下载 get-pip.py";;
            "pip_install_success") translated_string="pip 安装成功";;
            "git_install_cancelled") translated_string="已取消 git 安装";;
            "git_install_success") translated_string="git 安装成功";;
            "path_fix_cancelled") translated_string="已取消 PATH 修复";;
            "path_config_updated") printf -v translated_string "已更新 %s 中的 PATH" "$@";;
            "path_updated_reboot_win") translated_string="PATH 已更新，请重启终端或运行 'refreshenv'。";;
            "path_updated_reboot_linux_macos") printf -v translated_string "PATH 已更新，请运行 'source %s' 或重启终端。" "$@";;
            "installed_branch_source") printf -v translated_string "安装来源分支：%s" "$@";;
            "save_files_found_list") printf -v translated_string "找到存档文件：%s" "$@";;
            "save_files_deleted") translated_string="存档文件已删除";;
            "save_files_not_found") translated_string="未找到存档文件";;
            "install_cancelled") translated_string="已取消安装";;
            "update_cancelled") translated_string="已取消更新";;
            "repair_cancelled") translated_string="已取消修复";;
            "uninstall_cancelled") translated_string="已取消卸载";;
            "detected_installed_branch") printf -v translated_string "检测到已安装分支: %s，将尝试修复到此分支。" "$@";;
            "no_starsignal_detected_repair") translated_string="未检测到 starsignal 安装，将尝试修复到 main 分支。";;
            "exiting_program") translated_string="退出程序";;
            "script_interrupted") translated_string="脚本被中断";;
            "starting_manager") translated_string="启动星际迷航：信号解码管理器";;
            "confirm_install_starsignal") translated_string="安装 starsignal";;
            "confirm_update_starsignal") translated_string="更新 starsignal";;
            "confirm_repair_starsignal") translated_string="修复 starsignal";;
            "confirm_uninstall_starsignal") translated_string="卸载 starsignal";;
            "starsignal_installing_branch") printf -v translated_string "正在安装 starsignal，分支：%s" "$@";;
            "starsignal_updating_branch") printf -v translated_string "正在更新 starsignal，分支：%s" "$@";;
            "starsignal_repairing") translated_string="正在修复 starsignal 安装...";;
            "starsignal_reinstalling_branch") printf -v translated_string "正在重新安装 starsignal，分支：%s" "$@";;
            "starsignal_uninstalling") translated_string="正在卸载 starsignal...";;
            "starsignal_not_installed_status") translated_string="未安装 starsignal";; # New for clarity
            "env_check_fix_status") translated_string="正在检查和修复环境...";;
            "warning_colorama_install_fail") translated_string="警告：colorama 安装失败，颜色显示可能受影响";;
            "warning_colorama_update_fail") translated_string="警告：colorama 更新失败";;

            *) translated_string="$key";; # Fallback for untranslated keys
        esac
    else # English
        case "$key" in
            "welcome") translated_string="StarSignalDecoder Manager v1.6.0";;
            "choose_lang") translated_string="Please select language (zh/en) [default $(echo "$LANG_MODE" | tr 'a-z' 'A-Z')]: ";;
            "status_installed") printf -v translated_string "Status: Installed (Version: %s, Branch: %s)" "$@";;
            "status_not_installed") translated_string="Status: Not installed";;
            "save_files_present") translated_string="Save files: Present";;
            "save_files_none") translated_string="Save files: None";;
            "choose_option") translated_string="Enter option number:";;
            "invalid_choice") translated_string="Invalid option, please try again";;
            "install_menu") translated_string="1) Install\n2) Check/Fix environment\n3) Exit";;
            "installed_menu") translated_string="1) Update\n2) Repair\n3) Clean save files\n4) Uninstall\n5) Check/Fix environment\n6) Exit";;
            "branch_prompt") translated_string="Select branch to install:\n1) main (Stable, recommended)\n2) dev (Development, latest features)";;
            "choose_branch") translated_string="Choose (1-2) [default 1]:";;
            "installing") printf -v translated_string "Installing %s branch..." "$@";;
            "updating") printf -v translated_string "Updating to %s branch..." "$@";;
            "repairing") translated_string="Repairing installation...";;
            "cleaning_saves") translated_string="Cleaning save files...";;
            "uninstalling") translated_string="Uninstalling...";;
            "confirm_clean") translated_string="Confirm deletion of save files? (y/n):";;
            "clean_cancelled") translated_string="Save cleaning cancelled";;
            "installation_complete") translated_string="Installation complete! Run 'starsignal' to play!";;
            "update_complete") translated_string="Update complete!";;
            "repair_complete") translated_string="Repair complete!";;
            "uninstall_complete") translated_string="Uninstallation complete!";;
            "environment_ready") translated_string="Environment check complete, ready!";;
            "network_error") translated_string="Network error: Cannot reach GitHub";;
            "network_options") translated_string="1) Try Google DNS (8.8.8.8)\n2) Continue (may fail)\n3) Exit";;
            "python_not_found") printf -v translated_string "Python3 not found or outdated (need >= %s). Install? (y/n):" "$@";;
            "pip_not_found") translated_string="pip3 not found. Install? (y/n):";;
            "git_not_found") translated_string="git not found. Install? (y/n):";;
            "path_not_found") translated_string="PATH does not include required path. Fix? (y/n):";;
            "permission_warning") translated_string="Warning: Failed to fix save file permissions, run: chmod 666 ~/.starsignal* (Windows: icacls \"%USERPROFILE%\\.starsignal*\" /grant Everyone:F)";;
            "progress") printf -v translated_string "[%s] Processing..." "$@";;
            "error") printf -v translated_string "Error: %s" "$@";;
            "check_log") printf -v translated_string "Check %s for details" "$@";;
            "confirm_action") printf -v translated_string "Confirm to proceed with %s? (y/n):" "$@";;
            "error_non_interactive") printf -v translated_string "This script requires an interactive terminal. Please download and execute the script, e.g.:\n%s\n%s" "$@";;
            "error_non_interactive_desc_linux_macos") translated_string="Linux/macOS: curl -s https://raw.githubusercontent.com/bbb-lsy07/StarSignalDecoder/main/starsignal_manager.sh -o starsignal_manager.sh && sh starsignal_manager.sh";;
            "error_non_interactive_desc_windows") translated_string="Windows:     curl -s https://raw.githubusercontent.com/bbb-lsy07/StarSignalDecoder/main/starsignal_manager.sh -o starsignal_manager.sh && sh starsignal_manager.sh";;
            "detected_os") printf -v translated_string "Detected OS: %s %s" "$@";;
            "network_retry") printf -v translated_string "Network connection failed, retrying %s/%s" "$@";;
            "warn_set_dns_failed") translated_string="Warning: Failed to set DNS";;
            "google_dns_added") translated_string="Google DNS added";;
            "skip_network_check") translated_string="Skipping network check";;
            "python_install_cancelled") translated_string="Python installation cancelled";;
            "python_install_success") translated_string="Python installed successfully";;
            "installing_homebrew") translated_string="Installing Homebrew...";;
            "pip_install_cancelled") translated_string="pip installation cancelled";;
            "ensurepip_failed") translated_string="ensurepip failed, downloading get-pip.py";;
            "pip_install_success") translated_string="pip installed successfully";;
            "git_install_cancelled") translated_string="git installation cancelled";;
            "git_install_success") translated_string="git installed successfully";;
            "path_no_python_scripts") translated_string="PATH does not contain Python Scripts";;
            "path_contains_local_bin") translated_string="PATH contains ~/.local/bin";;
            "path_no_local_bin") translated_string="PATH does not contain ~/.local/bin";;
            "path_fix_cancelled") translated_string="PATH fix cancelled";;
            "path_config_updated") printf -v translated_string "PATH updated in %s" "$@";;
            "path_updated_reboot_win") translated_string="PATH updated, please restart terminal or run 'refreshenv'.";;
            "path_updated_reboot_linux_macos") printf -v translated_string "PATH updated, please run 'source %s' or restart terminal." "$@";;
            "installed_branch_source") printf -v translated_string "Installed branch source: %s" "$@";;
            "save_files_found_list") printf -v translated_string "Found save files: %s" "$@";;
            "save_files_deleted") translated_string="Save files deleted";;
            "save_files_not_found") translated_string="No save files found";;
            "install_cancelled") translated_string="Installation cancelled";;
            "update_cancelled") translated_string="Update cancelled";;
            "repair_cancelled") translated_string="Repair cancelled";;
            "uninstall_cancelled") translated_string="Uninstallation cancelled";;
            "detected_installed_branch") printf -v translated_string "Detected installed branch: %s, attempting to repair to this branch." "$@";;
            "no_starsignal_detected_repair") translated_string="No starsignal installation detected, attempting to repair to main branch.";;
            "exiting_program") translated_string="Exiting program";;
            "script_interrupted") translated_string="Script interrupted";;
            "starting_manager") translated_string="Starting StarSignalDecoder Manager";;
            "confirm_install_starsignal") translated_string="install starsignal";;
            "confirm_update_starsignal") translated_string="update starsignal";;
            "confirm_repair_starsignal") translated_string="repair starsignal";;
            "confirm_uninstall_starsignal") translated_string="uninstall starsignal";;
            "starsignal_installing_branch") printf -v translated_string "Installing starsignal, branch: %s" "$@";;
            "starsignal_updating_branch") printf -v translated_string "Updating starsignal, branch: %s" "$@";;
            "starsignal_repairing") translated_string="Repairing starsignal installation...";;
            "starsignal_reinstalling_branch") printf -v translated_string "Reinstalling starsignal, branch: %s" "$@";;
            "starsignal_uninstalling") translated_string="Uninstalling starsignal...";;
            "starsignal_not_installed_status") translated_string="starsignal not installed";; # New for clarity
            "env_check_fix_status") translated_string="Checking and fixing environment...";;
            "warning_colorama_install_fail") translated_string="Warning: colorama installation failed, color display might be affected";;
            "warning_colorama_update_fail") translated_string="Warning: colorama update failed";;

            *) translated_string="$key";; # Fallback for untranslated keys
        esac
    fi
    # Use printf "%b" to ensure backslash escapes like \n are interpreted.
    printf "%b" "$translated_string"
}

# Initial language detection based on args and system. This sets default LANG_MODE.
detect_language "$@"

# 确保日志文件可写
touch "$LOG_FILE" 2>/dev/null || {
    LOG_FILE="/tmp/starsignal_install_$$.log"
    echo "$(translate "error" "无法写入 $HOME/.starsignal_install.log，使用 $LOG_FILE")" >&2
}
chmod 666 "$LOG_FILE" 2>/dev/null

# 日志函数
log() {
    echo "[$TIMESTAMP] $1" >> "$LOG_FILE"
    echo "$1"
}

# 错误退出函数
die() {
    log "$(translate "error" "$1")"
    echo "$(translate "check_log" "$LOG_FILE")"
    exit 1
}

# Check if stdin is a TTY. If not, exit with instructions.
if [ ! -t 0 ]; then
    printf "$(translate "error_non_interactive" "$(translate "error_non_interactive_desc_linux_macos")" "$(translate "error_non_interactive_desc_windows")")\n" >&2
    log "$(translate "error" "脚本以非交互模式运行。请使用推荐的运行方式。")"
    exit 1
fi

# Interactive language selection - overrides detected language if not set by --lang
lang_arg_present=0
for arg in "$@"; do
    if [ "$arg" = "--lang" ]; then
        lang_arg_present=1
        break
    fi
done

if [ "$lang_arg_present" -eq 0 ]; then
    printf "$(translate "choose_lang")"
    read -r chosen_lang
    case "$chosen_lang" in
        "en"|"En"|"EN") LANG_MODE="en";;
        "zh"|"Zh"|"ZH") LANG_MODE="zh";;
        *) log "No language choice or invalid choice '$chosen_lang', defaulting to $LANG_MODE.";;
    esac
fi


# 检查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 检测操作系统
detect_os() {
    if [ -n "$SYSTEMROOT" ]; then
        OS="windows"
        VERSION=$(systeminfo | findstr /B /C:"OS Version" | awk '{print $NF}' | cut -d'.' -f1-2)
        log "$(translate "detected_os" "$OS" "$VERSION")"
    elif [ -f /etc/os-release ]; then
        . /etc/os-release
        OS="$ID"
        VERSION="$VERSION_ID"
        log "$(translate "detected_os" "$OS" "$VERSION")"
    elif [ "$(uname)" = "Darwin" ]; then
        OS="macos"
        VERSION=$(sw_vers -productVersion)
        log "$(translate "detected_os" "$OS" "$VERSION")"
    else
        OS=$(uname | tr '[:upper:]' '[:lower:]')
        VERSION="unknown"
        log "$(translate "detected_os" "$OS" "$VERSION")"
    fi
}

# 显示进度
show_progress() {
    action_key="$1" # This is the translation key for the action (e.g., "installing")
    action_arg="${2:-}" # Optional argument for the action (e.g., branch name)

    for i in 1 2 3 4 5; do
        case $i in
            1) BAR="=>   ";;
            2) BAR="==>  ";;
            3) BAR="===> ";;
            4) BAR="====>";;
            5) BAR="=====";;
        esac
        printf "\r$(translate "progress" "$BAR")"
        sleep 0.5
    done
    # Now use the action_key to translate the final "Done" message, passing the original arg if it exists
    printf "\r$(translate "$action_key" "$action_arg") [完成]\n"
}

# 检查网络
check_network() {
    local network_ok=0
    for i in $(seq 1 $MAX_RETRIES); do
        if [ "$OS" = "windows" ]; then
            ping -n 1 github.com >/dev/null 2>&1
        else
            ping -c 1 github.com >/dev/null 2>&1
        fi
        if [ $? -eq 0 ]; then
            network_ok=1
            break
        fi
        log "$(translate "network_retry" "$i" "$MAX_RETRIES")"
        sleep "$RETRY_DELAY"
    done

    if [ "$network_ok" -eq 0 ]; then
        echo "$(translate "network_error")"
        echo "$(translate "network_options")"
        printf "$(translate "choose_option") "
        read -r choice
        case "$choice" in
            1)
                log "$(translate "尝试设置 Google DNS...")"
                if [ "$OS" = "windows" ]; then
                    powershell -Command "Set-DnsClientServerAddress -InterfaceAlias * -ServerAddresses ('8.8.8.8','8.8.4.4')" || log "$(translate "warn_set_dns_failed")"
                else
                    echo "nameserver 8.8.8.8" | sudo tee -a /etc/resolv.conf >/dev/null
                fi
                log "$(translate "google_dns_added")"
                sleep 2 # Give DNS time to update
                if [ "$OS" = "windows" ]; then
                    ping -n 1 github.com >/dev/null 2>&1 || die "$(translate "error" "$(translate "网络仍然无法连接")")"
                else
                    ping -c 1 github.com >/dev/null 2>&1 || die "$(translate "error" "$(translate "网络仍然无法连接")")"
                fi
                ;;
            2)
                log "$(translate "skip_network_check")"
                ;;
            3)
                die "$(translate "error" "$(translate "网络检查失败")")"
                ;;
            *)
                die "$(translate "invalid_choice")"
                ;;
        esac
    fi
}

# 检查 Python
check_python() {
    if command_exists python3 || command_exists python; then
        PYTHON_CMD=$(command_exists python3 && echo "python3" || echo "python")
        PYTHON_VERSION=$($PYTHON_CMD --version 2>&1 | awk '{print $2}')
        log "$(translate "found_python" "$PYTHON_VERSION")"
        MAJOR=$(echo "$PYTHON_VERSION" | cut -d. -f1)
        MINOR=$(echo "$PYTHON_VERSION" | cut -d. -f2)
        if [ "$MAJOR" -lt 3 ] || { [ "$MAJOR" -eq 3 ] && [ "$MINOR" -lt 6 ]; }; then
            log "$(translate "python_outdated" "$PYTHON_VERSION" "$PYTHON_MIN_VERSION")"
            return 1
        fi
        return 0
    fi
    log "$(translate "python_not_found_msg")"
    return 1
}

# 安装 Python
install_python() {
    log "$(translate "正在安装 Python3...")"
    printf "$(translate "confirm_action" "$(translate "confirm_install_python")") "
    read -r confirm
    [ "$confirm" != "y" ] && [ "$confirm" != "Y" ] && die "$(translate "python_install_cancelled")"
    case "$OS" in
        ubuntu|debian)
            sudo apt-get update || die "$(translate "error" "apt-get 更新失败")"
            sudo apt-get install -y python3 python3-dev || die "$(translate "error" "Python3 安装失败")"
            ;;
        centos|rhel)
            sudo yum install -y python3 python3-devel || die "$(translate "error" "Python3 安装失败")"
            ;;
        macos)
            if command_exists brew; then
                brew install python3 || die "$(translate "error" "Python3 安装失败")"
            else
                log "$(translate "installing_homebrew")"
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || die "$(translate "error" "Homebrew 安装失败")"
                brew install python3 || die "$(translate "error" "Python3 安装失败")"
            fi
            ;;
        windows)
            if command_exists winget; then
                winget install --id Python.Python.3.9 -e || winget install --id Python.Python.3.10 -e || winget install --id Python.Python.3.11 -e || die "$(translate "error" "Python3 安装失败")"
            elif command_exists choco; then
                choco install python --version 3.9.13 || die "$(translate "error" "Python3 安装失败")"
            else
                log "$(translate "正在安装 winget...")"
                powershell -Command "Invoke-WebRequest -Uri https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle -OutFile winget.msixbundle; Add-AppxPackage winget.msixbundle" 2>/dev/null
                winget install --id Python.Python.3.9 -e || winget install --id Python.Python.3.10 -e || winget install --id Python.Python.3.11 -e || die "$(translate "error" "Python3 安装失败")"
            fi
            ;;
        *)
            die "$(translate "error" "不支持的操作系统，请手动安装 Python3")"
            ;;
    esac
    check_python || die "$(translate "error" "Python 安装失败")"
    log "$(translate "python_install_success")"
}

# 检查 pip
check_pip() {
    if command_exists pip3 || command_exists pip; then
        PIP_CMD=$(command_exists pip3 && echo "pip3" || echo "pip")
        PIP_VERSION=$($PIP_CMD --version 2>&1 | awk '{print $2}')
        log "$(translate "found_pip" "$PIP_VERSION")"
        return 0
    fi
    log "$(translate "pip_not_found")"
    return 1
}

# 安装 pip
install_pip() {
    log "$(translate "正在安装 pip...")"
    printf "$(translate "confirm_action" "$(translate "confirm_install_pip")") "
    read -r confirm
    [ "$confirm" != "y" ] && [ "$confirm" != "Y" ] && die "$(translate "pip_install_cancelled")"
    if check_python; then
        $PYTHON_CMD -m ensurepip --upgrade 2>/dev/null || {
            log "$(translate "ensurepip_failed")"
            curl -s https://bootstrap.pypa.io/get-pip.py -o get-pip.py || die "$(translate "error" "无法下载 get-pip.py")"
            $PYTHON_CMD get-pip.py --user || die "$(translate "error" "pip 安装失败")"
            rm -f get-pip.py
        }
        if [ "$OS" = "windows" ]; then
            export PATH="$HOME/AppData/Roaming/Python/Python39/Scripts:$PATH" # This path might vary with Python version
        else
            export PATH="$HOME/.local/bin:$PATH"
        fi
        check_pip || die "$(translate "error" "pip 安装失败")"
        log "$(translate "pip_install_success")"
    else
        die "$(translate "error" "$(translate "未找到 Python，无法安装 pip")")"
    fi
}

# 检查 git
check_git() {
    if command_exists git; then
        GIT_VERSION=$(git --version 2>&1 | awk '{print $3}')
        log "$(translate "found_git" "$GIT_VERSION")"
        return 0
    fi
    log "$(translate "git_not_found")"
    return 1
}

# 安装 git
install_git() {
    log "$(translate "正在安装 git...")"
    printf "$(translate "confirm_action" "$(translate "confirm_install_git")") "
    read -r confirm
    [ "$confirm" != "y" ] && [ "$confirm" != "Y" ] && die "$(translate "git_install_cancelled")"
    case "$OS" in
        ubuntu|debian)
            sudo apt-get update || die "$(translate "error" "apt-get 更新失败")"
            sudo apt-get install -y git || die "$(translate "error" "git 安装失败")"
            ;;
        centos|rhel)
            sudo yum install -y git || die "$(translate "error" "git 安装失败")"
            ;;
        macos)
            if command_exists brew; then
                brew install git || die "$(translate "error" "git 安装失败")"
            else
                log "$(translate "installing_homebrew")"
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || die "$(translate "error" "Homebrew 安装失败")"
                brew install git || die "$(translate "error" "git 安装失败")"
            fi
            ;;
        windows)
            if command_exists winget; then
                winget install --id Git.Git -e || die "$(translate "error" "git 安装失败")"
            elif command_exists choco; then
                choco install git || die "$(translate "error" "git 安装失败")"
            else
                log "$(translate "正在安装 winget...")"
                powershell -Command "Invoke-WebRequest -Uri https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle -OutFile winget.msixbundle; Add-AppxPackage winget.msixbundle" 2>/dev/null
                winget install --id Git.Git -e || die "$(translate "error" "git 安装失败")"
            fi
            ;;
        *)
            die "$(translate "error" "不支持的操作系统，请手动安装 git")"
            ;;
    esac
    check_git || die "$(translate "error" "git 安装失败")"
    log "$(translate "git_install_success")"
}

# 检查 PATH
check_path() {
    if [ "$OS" = "windows" ]; then
        powershell -Command "[Environment]::GetEnvironmentVariable('Path', 'User')" | grep -qi "Python" && return 0
        log "$(translate "path_no_python_scripts")"
        return 1
    else
        if echo "$PATH" | grep -q "$HOME/.local/bin"; then
            log "$(translate "path_contains_local_bin")"
            return 0
        fi
        log "$(translate "path_no_local_bin")"
        return 1
    fi
}

# 修复 PATH
fix_path() {
    log "$(translate "正在修复 PATH...")"
    printf "$(translate "confirm_action" "$(translate "fix_path_action")") "
    read -r confirm
    [ "$confirm" != "y" ] && [ "$confirm" != "Y" ] && die "$(translate "path_fix_cancelled")"
    if [ "$OS" = "windows" ]; then
        PYTHON_SCRIPTS=""
        if check_python; then
            PYTHON_SCRIPTS=$($PYTHON_CMD -c "import sys; print(sys.user_base + '\\Scripts')")
        fi
        if [ -z "$PYTHON_SCRIPTS" ]; then
            PYTHON_SCRIPTS="$HOME/AppData/Roaming/Python/Python39/Scripts"
        fi

        powershell -Command "\$userPath = [Environment]::GetEnvironmentVariable('Path', 'User'); if (\$userPath -notlike '*$PYTHON_SCRIPTS*') { [Environment]::SetEnvironmentVariable('Path', \$userPath + ';$PYTHON_SCRIPTS', 'User') }" || die "$(translate "error" "无法更新 PATH")"
        export PATH="$PYTHON_SCRIPTS:$PATH"
    else
        SHELL_CONFIG=""
        if [ -n "$ZSH_VERSION" ]; then
            SHELL_CONFIG="$HOME/.zshrc"
        elif [ -n "$BASH_VERSION" ]; then
            SHELL_CONFIG="$HOME/.bashrc"
        else
            SHELL_CONFIG="$HOME/.profile"
        fi
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_CONFIG"
        export PATH="$HOME/.local/bin:$PATH"
        log "$(translate "path_config_updated" "$SHELL_CONFIG")"
    fi
    check_path || die "$(translate "error" "无法更新 PATH")"
    if [ "$OS" = "windows" ]; then
        echo "$(translate "path_updated_reboot_win")"
    else
        echo "$(translate "path_updated_reboot_linux_macos" "$SHELL_CONFIG")"
    fi
}

# 检查 starsignal 安装
check_starsignal() {
    if command_exists starsignal; then
        STARSIGNAL_VERSION=$(starsignal --version 2>/dev/null | awk '{print $2}')
        log "$(translate "found_starsignal" "$STARSIGNAL_VERSION")"
        PIP_INFO=$($PIP_CMD show starsignal 2>/dev/null)
        if [ -n "$PIP_INFO" ]; then
            INSTALLED_BRANCH=$(echo "$PIP_INFO" | grep -i "Location" | sed -n 's/.*@\([^#]*\).*#egg=starsignal/\1/p')
            log "$(translate "installed_branch_source" "${INSTALLED_BRANCH:-未知}")"
        else
            INSTALLED_BRANCH="未知"
        fi
        return 0
    fi
    log "$(translate "starsignal_not_installed_status")"
    return 1
}

# 检查存档文件
check_saves() {
    if [ "$OS" = "windows" ]; then
        powershell -Command "Test-Path \$env:USERPROFILE\.starsignal*" | grep -q "True"
    else
        ls "$HOME/.starsignal"* >/dev/null 2>&1
    fi
    return $?
}

# 修复权限
fix_permissions() {
    log "$(translate "正在修复存档文件权限...")"
    if [ "$OS" = "windows" ]; then
        powershell -Command "Get-ChildItem -Path \$env:USERPROFILE\.starsignal* | ForEach-Object { icacls \$_.FullName /grant Everyone:F }" 2>/dev/null || log "$(translate "permission_warning")"
    else
        chmod 666 "$HOME/.starsignal"* 2>/dev/null || log "$(translate "permission_warning")"
    fi
    log "$(translate "权限修复完成")"
}

# 安装 starsignal
install_starsignal() {
    echo "$(translate "branch_prompt")"
    printf "$(translate "choose_branch") "
    read -r branch_choice
    case "$branch_choice" in
        2) BRANCH="dev" ;;
        *) BRANCH="main" ;;
    esac
    log "$(translate "starsignal_installing_branch" "$BRANCH")"
    printf "$(translate "confirm_action" "$(translate "confirm_install_starsignal")") "
    read -r confirm
    [ "$confirm" != "y" ] && [ "$confirm" != "Y" ] && die "$(translate "install_cancelled")"
    show_progress "installing" "$BRANCH"
    $PIP_CMD install --user --force-reinstall "git+$REPO_URL@$BRANCH" || die "$(translate "error" "安装失败")"
    $PIP_CMD install --user colorama 2>/dev/null || log "$(translate "warning_colorama_install_fail")"
    fix_permissions
    check_starsignal || die "$(translate "error" "安装验证失败")"
    log "$(translate "starsignal 安装成功，分支：$BRANCH")"
    echo "$(translate "installation_complete")"
}

# 更新 starsignal
update_starsignal() {
    echo "$(translate "branch_prompt")"
    printf "$(translate "choose_branch") "
    read -r branch_choice
    case "$branch_choice" in
        2) BRANCH="dev" ;;
        *) BRANCH="main" ;;
    esac
    log "$(translate "starsignal_updating_branch" "$BRANCH")"
    printf "$(translate "confirm_action" "$(translate "confirm_update_starsignal")") "
    read -r confirm
    [ "$confirm" != "y" ] && [ "$confirm" != "Y" ] && die "$(translate "update_cancelled")"
    show_progress "updating" "$BRANCH"
    $PIP_CMD install --user --force-reinstall "git+$REPO_URL@$BRANCH" || die "$(translate "error" "更新失败")"
    $PIP_CMD install --user colorama 2>/dev/null || log "$(translate "warning_colorama_update_fail")"
    fix_permissions
    check_starsignal || die "$(translate "error" "更新验证失败")"
    log "$(translate "starsignal 更新成功，分支：$BRANCH")"
    echo "$(translate "update_complete")"
}

# 修复安装
repair_starsignal() {
    log "$(translate "starsignal_repairing")"
    if check_starsignal; then
        INSTALLED_BRANCH_INFO=$($PIP_CMD show starsignal 2>/dev/null | grep -i "Location" | sed -n 's/.*@\([^#]*\).*#egg=starsignal/\1/p')
        BRANCH=${INSTALLED_BRANCH_INFO:-"main"}
        log "$(translate "detected_installed_branch" "${BRANCH}")"
    else
        BRANCH="main"
        log "$(translate "no_starsignal_detected_repair")"
    fi
    log "$(translate "starsignal_reinstalling_branch" "$BRANCH")"
    printf "$(translate "confirm_action" "$(translate "confirm_repair_starsignal")") "
    read -r confirm
    [ "$confirm" != "y" ] && [ "$confirm" != "Y" ] && die "$(translate "repair_cancelled")"
    show_progress "repairing"
    $PIP_CMD install --user --force-reinstall "git+$REPO_URL@$BRANCH" || die "$(translate "error" "修复失败")"
    $PIP_CMD install --user colorama 2>/dev/null || log "$(translate "warning_colorama_install_fail")"
    fix_permissions
    check_starsignal || die "$(translate "error" "修复验证失败")"
    log "$(translate "starsignal 修复完成")"
    echo "$(translate "repair_complete")"
}

# 清理存档
clean_saves() {
    log "$(translate "正在清理存档文件...")"
    if check_saves; then
        echo "$(translate "cleaning_saves")"
        local found_saves
        if [ "$OS" = "windows" ]; then
            found_saves=$(powershell -Command "Get-ChildItem -Path \$env:USERPROFILE\.starsignal* | Select-Object -ExpandProperty Name")
        else
            found_saves=$(ls "$HOME/.starsignal"* 2>/dev/null)
        fi
        echo "$(translate "save_files_found_list" "$found_saves")"
        printf "$(translate "confirm_clean") "
        read -r confirm
        if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
            if [ "$OS" = "windows" ]; then
                powershell -Command "Remove-Item -Path \$env:USERPROFILE\.starsignal* -Force" || die "$(translate "error" "无法清理存档文件")"
            else
                rm -f "$HOME/.starsignal"* || die "$(translate "error" "无法清理存档文件")"
            fi
            log "$(translate "存档文件清理完成")"
            echo "$(translate "save_files_deleted")"
        else
            log "$(translate "存档清理已取消")"
            echo "$(translate "clean_cancelled")"
        fi
    else
        echo "$(translate "save_files_not_found")"
    fi
}

# 卸载 starsignal
uninstall_starsignal() {
    log "$(translate "starsignal_uninstalling")"
    printf "$(translate "confirm_action" "$(translate "confirm_uninstall_starsignal")") "
    read -r confirm
    [ "$confirm" != "y" ] && [ "$confirm" != "Y" ] && die "$(translate "uninstall_cancelled")"
    if check_starsignal; then
        show_progress "uninstalling"
        $PIP_CMD uninstall -y starsignal || die "$(translate "error" "卸载失败")"
        clean_saves
        log "$(translate "starsignal 卸载完成")"
        echo "$(translate "uninstall_complete")"
    else
        echo "$(translate "starsignal_not_installed_status")"
    fi
}

# 修复环境
fix_environment() {
    log "$(translate "env_check_fix_status")"
    if ! check_python; then
        printf "$(translate "python_not_found" "$PYTHON_MIN_VERSION") "
        read -r install_python_choice
        if [ "$install_python_choice" = "y" ] || [ "$install_python_choice" = "Y" ]; then
            install_python
        else
            die "$(translate "error" "需要 Python3")"
        fi
    fi
    if ! check_pip; then
        printf "$(translate "pip_not_found") "
        read -r install_pip_choice
        if [ "$install_pip_choice" = "y" ] || [ "$install_pip_choice" = "Y" ]; then
            install_pip
        else
            die "$(translate "error" "需要 pip3")"
        fi
    fi
    if ! check_git; then
        printf "$(translate "git_not_found") "
        read -r install_git_choice
        if [ "$install_git_choice" = "y" ] || [ "$install_git_choice" = "Y" ]; then
            install_git
        else
            die "$(translate "error" "需要 git")"
        fi
    fi
    if ! check_path; then
        printf "$(translate "path_not_found") "
        read -r fix_path_choice
        if [ "$fix_path_choice" = "y" ] || [ "$fix_path_choice" = "Y" ]; then
            fix_path
        else
            die "$(translate "error" "PATH 必须包含 Python Scripts")"
        fi
    fi
    check_network
    fix_permissions
    log "$(translate "环境检查和修复完成")"
    echo "$(translate "environment_ready")"
}

# 主菜单
main_menu() {
    while true; do
        clear
        echo "$(translate "welcome")"
        echo "================================="
        detect_os
        if check_starsignal; then
            echo "$(translate "status_installed" "$STARSIGNAL_VERSION" "${INSTALLED_BRANCH:-未知}")"
            check_saves && echo "$(translate "save_files_present")" || echo "$(translate "save_files_none")"
            echo "$(translate "installed_menu")"
            printf "$(translate "choose_option") "
            read -r choice
            case "$choice" in
                1) update_starsignal ;;
                2) repair_starsignal ;;
                3) clean_saves ;;
                4) uninstall_starsignal ;;
                5) fix_environment ;;
                6) log "$(translate "exiting_program")"; exit 0 ;;
                *) echo "$(translate "invalid_choice")"; sleep 1; continue ;;
            esac
        else
            echo "$(translate "status_not_installed")"
            echo "$(translate "install_menu")"
            printf "$(translate "choose_option") "
            read -r choice
            case "$choice" in
                1) install_starsignal ;;
                2) fix_environment ;;
                3) log "$(translate "exiting_program")"; exit 0 ;;
                *) echo "$(translate "invalid_choice")"; sleep 1; continue ;;
            esac
        fi
        echo "$(translate "按回车键继续...")"
        read -r _
    done
}

# 处理命令行参数 (This loop remains for argument parsing and should be kept as is,
# as `detect_language` was already called early with `$@`)
while [ $# -gt 0 ]; do
    case "$1" in
        --lang) shift 2 ;; # Already handled by initial detect_language "$@", just consume args
        *) shift ;;
    esac
done

# 捕获中断
trap 'log "$(translate "script_interrupted")"; exit 1' INT TERM

# 启动
log "$(translate "starting_manager")"
main_menu
