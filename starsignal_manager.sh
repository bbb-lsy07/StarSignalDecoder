#!/bin/sh
# 星际迷航：信号解码管理脚本
# 版本：1.5.0
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
LANG_MODE="zh" # Default language, will be detected
MAX_RETRIES=3
RETRY_DELAY=5

# 检测语言
detect_language() {
    # Check for --lang argument first
    local i
    for i in "$@"; do
        if [ "$i" = "--lang" ]; then
            # Find the value after --lang
            local next_arg_index=0
            local current_arg
            for current_arg in "$@"; do
                next_arg_index=$((next_arg_index + 1))
                if [ "$current_arg" = "--lang" ]; then
                    local lang_val="${!next_arg_index}" # Get argument by index
                    if [ "$lang_val" = "en" ]; then
                        LANG_MODE="en"
                        return
                    fi
                fi
            done
        fi
    done

    # If --lang not specified or not 'en', detect from system
    if [ -n "$LANG" ] && echo "$LANG" | grep -qi "zh"; then
        LANG_MODE="zh"
    elif [ "$(uname)" = "Darwin" ] && defaults read NSGlobalDomain AppleLanguages 2>/dev/null | grep -q "zh"; then
        LANG_MODE="zh"
    elif [ -n "$SYSTEMROOT" ] && powershell -Command "Get-Culture" 2>/dev/null | grep -qi "zh"; then
        LANG_MODE="zh"
    else
        LANG_MODE="en"
    fi
}

# 翻译函数
translate() {
    key="$1"
    # Shift arguments to handle printf format strings properly
    shift
    if [ "$LANG_MODE" = "zh" ]; then
        case "$key" in
            "welcome") echo "星际迷航：信号解码管理器 v1.5.0";;
            "status_installed") printf "状态：已安装（版本：%s，分支：%s）\n" "$@";;
            "status_not_installed") echo "状态：未安装";;
            "save_files_present") echo "存档文件：存在";;
            "save_files_none") echo "存档文件：无";;
            "choose_option") echo "请输入选项编号：";;
            "invalid_choice") echo "无效选项，请重新输入";;
            "install_menu") echo "1) 安装\n2) 检查/修复环境\n3) 退出";;
            "installed_menu") echo "1) 更新\n2) 修复\n3) 清理存档\n4) 卸载\n5) 检查/修复环境\n6) 退出";;
            "branch_prompt") echo "请选择安装分支：\n1) main（稳定版，推荐）\n2) dev（开发版，最新功能）";;
            "choose_branch") echo "选择（1-2）[默认 1]：";;
            "installing") printf "正在安装 %s 分支...\n" "$@";;
            "updating") printf "正在更新到 %s 分支...\n" "$@";;
            "repairing") echo "正在修复安装...";;
            "cleaning_saves") echo "正在清理存档文件...";;
            "uninstalling") echo "正在卸载...";;
            "confirm_clean") echo "是否确认删除存档？（y/n）：";;
            "clean_cancelled") echo "已取消存档清理";;
            "installation_complete") echo "安装完成！运行 'starsignal' 开始游戏！";;
            "update_complete") echo "更新完成！";;
            "repair_complete") echo "修复完成！";;
            "uninstall_complete") echo "卸载完成！";;
            "environment_ready") echo "环境检查完成，准备就绪！";;
            "network_error") echo "网络错误：无法连接到 GitHub";;
            "network_options") echo "1) 尝试 Google DNS (8.8.8.8)\n2) 继续（可能失败）\n3) 退出";;
            "python_not_found") printf "未找到 Python3 或版本过旧（需要 >= %s）。是否安装？（y/n）：" "$@";;
            "pip_not_found") echo "未找到 pip3。是否安装？（y/n）：";;
            "git_not_found") echo "未找到 git。是否安装？（y/n）：";;
            "path_not_found") echo "PATH 未包含所需路径。是否修复？（y/n）：";;
            "permission_warning") echo "警告：无法修复存档权限，请手动运行：chmod 666 ~/.starsignal*（Windows：icacls \"%USERPROFILE%\\.starsignal*\" /grant Everyone:F）";;
            "progress") printf "[%s] 正在处理..." "$@";;
            "error") printf "错误：%s\n" "$@";;
            "check_log") printf "请查看 %s 获取详细信息\n" "$@";;
            "confirm_action") printf "是否继续执行 %s？（y/n）：" "$@";;
            "error_non_interactive") printf "此脚本需要交互式运行。请下载脚本后执行，例如：\n%s\n%s\n" "$@";;
            "error_non_interactive_desc_linux_macos") echo "Linux/macOS: curl -s https://raw.githubusercontent.com/bbb-lsy07/StarSignalDecoder/main/starsignal_manager.sh -o starsignal_manager.sh && sh starsignal_manager.sh";;
            "error_non_interactive_desc_windows") echo "Windows:     curl -s https://raw.githubusercontent.com/bbb-lsy07/StarSignalDecoder/main/starsignal_manager.sh -o starsignal_manager.sh && sh starsignal_manager.sh";;
            *) echo "$key";;
        esac
    else
        case "$key" in
            "welcome") echo "StarSignalDecoder Manager v1.5.0";;
            "status_installed") printf "Status: Installed (Version: %s, Branch: %s)\n" "$@";;
            "status_not_installed") echo "Status: Not installed";;
            "save_files_present") echo "Save files: Present";;
            "save_files_none") echo "Save files: None";;
            "choose_option") echo "Enter option number:";;
            "invalid_choice") echo "Invalid option, please try again";;
            "install_menu") echo "1) Install\n2) Check/Fix environment\n3) Exit";;
            "installed_menu") echo "1) Update\n2) Repair\n3) Clean save files\n4) Uninstall\n5) Check/Fix environment\n6) Exit";;
            "branch_prompt") echo "Select branch to install:\n1) main (Stable, recommended)\n2) dev (Development, latest features)";;
            "choose_branch") echo "Choose (1-2) [default 1]:";;
            "installing") printf "Installing %s branch...\n" "$@";;
            "updating") printf "Updating to %s branch...\n" "$@";;
            "repairing") echo "Repairing installation...";;
            "cleaning_saves") echo "Cleaning save files...";;
            "uninstalling") echo "Uninstalling...";;
            "confirm_clean") echo "Confirm deletion of save files? (y/n):";;
            "clean_cancelled") echo "Save cleaning cancelled";;
            "installation_complete") echo "Installation complete! Run 'starsignal' to play!";;
            "update_complete") echo "Update complete!";;
            "repair_complete") echo "Repair complete!";;
            "uninstall_complete") echo "Uninstallation complete!";;
            "environment_ready") echo "Environment check complete, ready!";;
            "network_error") echo "Network error: Cannot reach GitHub";;
            "network_options") echo "1) Try Google DNS (8.8.8.8)\n2) Continue (may fail)\n3) Exit";;
            "python_not_found") printf "Python3 not found or outdated (need >= %s). Install? (y/n):" "$@";;
            "pip_not_found") echo "pip3 not found. Install? (y/n):";;
            "git_not_found") echo "git not found. Install? (y/n):";;
            "path_not_found") echo "PATH does not include required path. Fix? (y/n):";;
            "permission_warning") echo "Warning: Failed to fix save file permissions, run: chmod 666 ~/.starsignal* (Windows: icacls \"%USERPROFILE%\\.starsignal*\" /grant Everyone:F)";;
            "progress") printf "[%s] Processing..." "$@";;
            "error") printf "Error: %s\n" "$@";;
            "check_log") printf "Check %s for details\n" "$@";;
            "confirm_action") printf "Confirm to proceed with %s? (y/n):" "$@";;
            "error_non_interactive") printf "This script requires an interactive terminal. Please download and execute the script, e.g.:\n%s\n%s\n" "$@";;
            "error_non_interactive_desc_linux_macos") echo "Linux/macOS: curl -s https://raw.githubusercontent.com/bbb-lsy07/StarSignalDecoder/main/starsignal_manager.sh -o starsignal_manager.sh && sh starsignal_manager.sh";;
            "error_non_interactive_desc_windows") echo "Windows:     curl -s https://raw.githubusercontent.com/bbb-lsy07/StarSignalDecoder/main/starsignal_manager.sh -o starsignal_manager.sh && sh starsignal_manager.sh";;
            *) echo "$key";;
        esac
    fi
}

# Initial language detection (before log setup potentially uses translate)
# Pass all script arguments so --lang can be detected early.
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
    log "$(translate "check_log" "$LOG_FILE")"
    exit 1
}

# Check if stdin is a TTY. If not, exit with instructions.
if [ ! -t 0 ]; then
    printf "$(translate "error_non_interactive" "$(translate "error_non_interactive_desc_linux_macos")" "$(translate "error_non_interactive_desc_windows")")" >&2
    log "$(translate "error" "脚本以非交互模式运行。请使用推荐的运行方式。")"
    exit 1
fi

# 检查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 检测操作系统
detect_os() {
    if [ -n "$SYSTEMROOT" ]; then
        OS="windows"
        # Using systeminfo to get OS version on Windows for better compatibility
        VERSION=$(systeminfo | findstr /B /C:"OS Version" | awk '{print $NF}' | cut -d'.' -f1-2)
        log "检测到操作系统：$OS $VERSION"
    elif [ -f /etc/os-release ]; then
        . /etc/os-release
        OS="$ID"
        VERSION="$VERSION_ID"
        log "检测到操作系统：$OS $VERSION"
    elif [ "$(uname)" = "Darwin" ]; then
        OS="macos"
        VERSION=$(sw_vers -productVersion)
        log "检测到操作系统：$OS $VERSION"
    else
        OS=$(uname | tr '[:upper:]' '[:lower:]')
        VERSION="unknown"
        log "检测到操作系统：$OS $VERSION"
    fi
}

# 显示进度
show_progress() {
    action="$1"
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
    printf "\r$(translate "$action") [完成]\n"
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
        log "网络连接失败，尝试重试 $i/$MAX_RETRIES"
        sleep "$RETRY_DELAY"
    done

    if [ "$network_ok" -eq 0 ]; then
        log "$(translate "network_error")"
        echo "$(translate "network_options")"
        printf "$(translate "choose_option") "
        read -r choice
        case "$choice" in
            1)
                log "尝试设置 Google DNS..."
                if [ "$OS" = "windows" ]; then
                    powershell -Command "Set-DnsClientServerAddress -InterfaceAlias * -ServerAddresses ('8.8.8.8','8.8.4.4')" || log "警告：无法设置 DNS"
                else
                    echo "nameserver 8.8.8.8" | sudo tee -a /etc/resolv.conf >/dev/null
                fi
                log "已添加 Google DNS"
                sleep 2 # Give DNS time to update
                if [ "$OS" = "windows" ]; then
                    ping -n 1 github.com >/dev/null 2>&1 || die "$(translate "error" "网络仍然无法连接")"
                else
                    ping -c 1 github.com >/dev/null 2>&1 || die "$(translate "error" "网络仍然无法连接")"
                fi
                ;;
            2)
                log "跳过网络检查"
                ;;
            3)
                die "$(translate "error" "网络检查失败")"
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
        log "找到 Python：$PYTHON_VERSION"
        MAJOR=$(echo "$PYTHON_VERSION" | cut -d. -f1)
        MINOR=$(echo "$PYTHON_VERSION" | cut -d. -f2)
        if [ "$MAJOR" -lt 3 ] || { [ "$MAJOR" -eq 3 ] && [ "$MINOR" -lt 6 ]; }; then
            log "Python $PYTHON_VERSION 版本过旧，需要 >= $PYTHON_MIN_VERSION"
            return 1
        fi
        return 0
    fi
    log "未找到 Python"
    return 1
}

# 安装 Python
install_python() {
    log "正在安装 Python3..."
    printf "$(translate "confirm_action" "安装 Python3") "
    read -r confirm
    [ "$confirm" != "y" ] && [ "$confirm" != "Y" ] && die "已取消 Python 安装"
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
                log "正在安装 Homebrew..."
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
                log "正在安装 winget..."
                # Attempt to install winget via appxbundle if not found. This is complex and might fail silently.
                # A better approach might be to tell user to install it manually.
                powershell -Command "Invoke-WebRequest -Uri https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle -OutFile winget.msixbundle; Add-AppxPackage winget.msixbundle" 2>/dev/null
                winget install --id Python.Python.3.9 -e || winget install --id Python.Python.3.10 -e || winget install --id Python.Python.3.11 -e || die "$(translate "error" "Python3 安装失败")"
            fi
            ;;
        *)
            die "$(translate "error" "不支持的操作系统，请手动安装 Python3")"
            ;;
    esac
    check_python || die "$(translate "error" "Python 安装失败")"
    log "Python 安装成功"
}

# 检查 pip
check_pip() {
    if command_exists pip3 || command_exists pip; then
        PIP_CMD=$(command_exists pip3 && echo "pip3" || echo "pip")
        PIP_VERSION=$($PIP_CMD --version 2>&1 | awk '{print $2}')
        log "找到 pip：$PIP_VERSION"
        return 0
    fi
    log "未找到 pip"
    return 1
}

# 安装 pip
install_pip() {
    log "正在安装 pip..."
    printf "$(translate "confirm_action" "安装 pip") "
    read -r confirm
    [ "$confirm" != "y" ] && [ "$confirm" != "Y" ] && die "已取消 pip 安装"
    if check_python; then
        $PYTHON_CMD -m ensurepip --upgrade 2>/dev/null || {
            log "ensurepip 失败，正在下载 get-pip.py"
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
        log "pip 安装成功"
    else
        die "$(translate "error" "未找到 Python，无法安装 pip")"
    fi
}

# 检查 git
check_git() {
    if command_exists git; then
        GIT_VERSION=$(git --version 2>&1 | awk '{print $3}')
        log "找到 git：$GIT_VERSION"
        return 0
    fi
    log "未找到 git"
    return 1
}

# 安装 git
install_git() {
    log "正在安装 git..."
    printf "$(translate "confirm_action" "安装 git") "
    read -r confirm
    [ "$confirm" != "y" ] && [ "$confirm" != "Y" ] && die "已取消 git 安装"
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
                log "正在安装 Homebrew..."
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
                log "正在安装 winget..."
                powershell -Command "Invoke-WebRequest -Uri https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle -OutFile winget.msixbundle; Add-AppxPackage winget.msixbundle" 2>/dev/null
                winget install --id Git.Git -e || die "$(translate "error" "git 安装失败")"
            fi
            ;;
        *)
            die "$(translate "error" "不支持的操作系统，请手动安装 git")"
            ;;
    esac
    check_git || die "$(translate "error" "git 安装失败")"
    log "git 安装成功"
}

# 检查 PATH
check_path() {
    if [ "$OS" = "windows" ]; then
        powershell -Command "[Environment]::GetEnvironmentVariable('Path', 'User')" | grep -qi "Python" && return 0
        log "PATH 未包含 Python Scripts"
        return 1
    else
        if echo "$PATH" | grep -q "$HOME/.local/bin"; then
            log "PATH 包含 ~/.local/bin"
            return 0
        fi
        log "PATH 未包含 ~/.local/bin"
        return 1
    fi
}

# 修复 PATH
fix_path() {
    log "正在修复 PATH..."
    printf "$(translate "confirm_action" "修复 PATH") "
    read -r confirm
    [ "$confirm" != "y" ] && [ "$confirm" != "Y" ] && die "已取消 PATH 修复"
    if [ "$OS" = "windows" ]; then
        # Dynamically find Python Scripts path on Windows
        PYTHON_SCRIPTS=""
        if check_python; then
            PYTHON_SCRIPTS=$($PYTHON_CMD -c "import sys; print(sys.user_base + '\\Scripts')")
        fi
        if [ -z "$PYTHON_SCRIPTS" ]; then
            PYTHON_SCRIPTS="$HOME/AppData/Roaming/Python/Python39/Scripts" # Fallback
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
        log "已更新 $SHELL_CONFIG 中的 PATH"
    fi
    check_path || die "$(translate "error" "无法更新 PATH")"
    if [ "$OS" = "windows" ]; then
        echo "PATH 已更新，请重启终端或运行 'refreshenv'。"
    else
        echo "PATH 已更新，请运行 'source $SHELL_CONFIG' 或重启终端。"
    fi
}

# 检查 starsignal 安装
check_starsignal() {
    if command_exists starsignal; then
        STARSIGNAL_VERSION=$(starsignal --version 2>/dev/null | awk '{print $2}')
        log "找到 starsignal：$STARSIGNAL_VERSION"
        PIP_INFO=$($PIP_CMD show starsignal 2>/dev/null)
        if [ -n "$PIP_INFO" ]; then
            # Extract branch from Location line which looks like: Location: .../git+https_github.com_bbb-lsy07_StarSignalDecoder.git@main#egg=starsignal
            INSTALLED_BRANCH=$(echo "$PIP_INFO" | grep -i "Location" | sed -n 's/.*@\([^#]*\).*#egg=starsignal/\1/p')
            log "安装来源分支：${INSTALLED_BRANCH:-未知}"
        else
            INSTALLED_BRANCH="未知"
        fi
        return 0
    fi
    log "未找到 starsignal"
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
    log "正在修复存档文件权限..."
    if [ "$OS" = "windows" ]; then
        powershell -Command "Get-ChildItem -Path \$env:USERPROFILE\.starsignal* | ForEach-Object { icacls \$_.FullName /grant Everyone:F }" 2>/dev/null || log "$(translate "permission_warning")"
    else
        chmod 666 "$HOME/.starsignal"* 2>/dev/null || log "$(translate "permission_warning")"
    fi
    log "权限修复完成"
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
    log "正在安装 starsignal，分支：$BRANCH"
    printf "$(translate "confirm_action" "安装 starsignal") "
    read -r confirm
    [ "$confirm" != "y" ] && [ "$confirm" != "Y" ] && die "已取消安装"
    show_progress "installing" "$BRANCH"
    $PIP_CMD install --user --force-reinstall "git+$REPO_URL@$BRANCH" || die "$(translate "error" "安装失败")"
    $PIP_CMD install --user colorama 2>/dev/null || log "警告：colorama 安装失败，颜色显示可能受影响"
    fix_permissions
    check_starsignal || die "$(translate "error" "安装验证失败")"
    log "starsignal 安装成功，分支：$BRANCH"
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
    log "正在更新 starsignal，分支：$BRANCH"
    printf "$(translate "confirm_action" "更新 starsignal") "
    read -r confirm
    [ "$confirm" != "y" ] && [ "$confirm" != "Y" ] && die "已取消更新"
    show_progress "updating" "$BRANCH"
    $PIP_CMD install --user --force-reinstall "git+$REPO_URL@$BRANCH" || die "$(translate "error" "更新失败")"
    $PIP_CMD install --user colorama 2>/dev/null || log "警告：colorama 更新失败"
    fix_permissions
    check_starsignal || die "$(translate "error" "更新验证失败")"
    log "starsignal 更新成功，分支：$BRANCH"
    echo "$(translate "update_complete")"
}

# 修复安装
repair_starsignal() {
    log "正在修复 starsignal 安装..."
    if check_starsignal; then
        # Try to use the currently installed branch for repair
        INSTALLED_BRANCH_INFO=$($PIP_CMD show starsignal 2>/dev/null | grep -i "Location" | sed -n 's/.*@\([^#]*\).*#egg=starsignal/\1/p')
        BRANCH=${INSTALLED_BRANCH_INFO:-"main"}
        log "检测到已安装分支: ${BRANCH}，将尝试修复到此分支。"
    else
        BRANCH="main"
        log "未检测到 starsignal 安装，将尝试修复到 main 分支。"
    fi
    log "正在重新安装 starsignal，分支：$BRANCH"
    printf "$(translate "confirm_action" "修复 starsignal") "
    read -r confirm
    [ "$confirm" != "y" ] && [ "$confirm" != "Y" ] && die "已取消修复"
    show_progress "repairing"
    $PIP_CMD install --user --force-reinstall "git+$REPO_URL@$BRANCH" || die "$(translate "error" "修复失败")"
    $PIP_CMD install --user colorama 2>/dev/null || log "警告：colorama 安装失败"
    fix_permissions
    check_starsignal || die "$(translate "error" "修复验证失败")"
    log "starsignal 修复完成"
    echo "$(translate "repair_complete")"
}

# 清理存档
clean_saves() {
    log "正在清理存档文件..."
    if check_saves; then
        echo "$(translate "cleaning_saves")"
        if [ "$OS" = "windows" ]; then
            echo "找到存档文件：$(powershell -Command "Get-ChildItem -Path \$env:USERPROFILE\.starsignal* | Select-Object -ExpandProperty Name")"
        else
            echo "找到存档文件：$(ls "$HOME/.starsignal"* 2>/dev/null)"
        fi
        printf "$(translate "confirm_clean") "
        read -r confirm
        if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
            if [ "$OS" = "windows" ]; then
                powershell -Command "Remove-Item -Path \$env:USERPROFILE\.starsignal* -Force" || die "$(translate "error" "无法清理存档文件")"
            else
                rm -f "$HOME/.starsignal"* || die "$(translate "error" "无法清理存档文件")"
            fi
            log "存档文件清理完成"
            echo "存档文件已删除"
        else
            log "存档清理已取消"
            echo "$(translate "clean_cancelled")"
        fi
    else
        echo "未找到存档文件"
    fi
}

# 卸载 starsignal
uninstall_starsignal() {
    log "正在卸载 starsignal..."
    printf "$(translate "confirm_action" "卸载 starsignal") "
    read -r confirm
    [ "$confirm" != "y" ] && [ "$confirm" != "Y" ] && die "已取消卸载"
    if check_starsignal; then
        show_progress "uninstalling"
        $PIP_CMD uninstall -y starsignal || die "$(translate "error" "卸载失败")"
        clean_saves
        log "starsignal 卸载完成"
        echo "$(translate "uninstall_complete")"
    else
        echo "未安装 starsignal"
    fi
}

# 修复环境
fix_environment() {
    log "正在检查和修复环境..."
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
    log "环境检查和修复完成"
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
            printf "$(translate "status_installed" "$STARSIGNAL_VERSION" "${INSTALLED_BRANCH:-未知}")"
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
                6) log "退出程序"; exit 0 ;;
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
                3) log "退出程序"; exit 0 ;;
                *) echo "$(translate "invalid_choice")"; sleep 1; continue ;;
            esac
        fi
        echo "按回车键继续..."
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
trap 'log "脚本被中断"; exit 1' INT TERM

# 启动
log "启动星际迷航：信号解码管理器"
main_menu
