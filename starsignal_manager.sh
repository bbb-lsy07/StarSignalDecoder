#!/bin/sh
# 星际迷航：信号解码管理脚本
# 版本：1.8.0
# 作者：bbb-lsy07
# 许可证：MIT
# GitHub：https://github.com/bbb-lsy07/StarSignalDecoder
# 描述：用于星际迷航：信号解码的通用安装、更新、修复和卸载脚本，支持 Linux、macOS 和 Windows
# 使用方法：
#   推荐方式 (Recommended):
#   Linux/macOS：curl -s https://raw.githubusercontent.com/bbb-lsy07/StarSignalDecoder/main/starsignal_manager.sh -o starsignal_manager.sh && chmod +x starsignal_manager.sh && ./starsignal_manager.sh
#   Windows：Invoke-WebRequest -Uri https://raw.githubusercontent.com/bbb-lsy07/StarSignalDecoder/main/starsignal_manager.sh -OutFile starsignal_manager.sh; sh starsignal_manager.sh
#   本地运行：chmod +x starsignal_manager.sh && ./starsignal_manager.sh

# 初始化变量
LOG_FILE="$HOME/.starsignal_install.log"
REPO_URL="https://github.com/bbb-lsy07/StarSignalDecoder.git"
DEFAULT_BRANCH="main"
PYTHON_MIN_VERSION="3.6"
PYTHON_RECOMMENDED_VERSION="3.9"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
LANG_MODE="zh" # 默认语言，将被检测或选择
MAX_RETRIES=3
RETRY_DELAY=5

# 全局变量来存储 Python 和 pip 命令，确保在整个脚本中一致使用
PYTHON_CMD=""
PIP_CMD=""

# 检测语言函数 - 仅根据命令行参数或系统设置LANG_MODE
detect_language() {
    local lang_arg_set=0
    # 首先检查 --lang 参数
    local i
    for i in "$@"; do
        if [ "$i" = "--lang" ]; then
            local next_arg_index=0
            local current_arg
            for current_arg in "$@"; do
                next_arg_index=$((next_arg_index + 1))
                if [ "$current_arg" = "--lang" ]; then
                    local lang_val="${!next_arg_index}" # 获取索引对应的参数值
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

    # 如果没有指定 --lang，则从系统检测
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
    shift # 移除第一个参数 (key)，让 "$@" 仅包含格式化参数
    local translated_string

    if [ "$LANG_MODE" = "zh" ]; then
        case "$key" in
            "welcome") translated_string="星际迷航：信号解码管理器 v1.8.0";;
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
            "python_upgrade_prompt") printf -v translated_string "Python %s 低于推荐版本 %s，可能不兼容。是否升级？（y/n）：" "$@";;
            "pip_not_found") translated_string="未找到 pip3。是否安装？（y/n）：";;
            "git_not_found") translated_string="未找到 git。是否安装？（y/n）：";;
            "path_not_found") translated_string="PATH 未包含所需路径。是否修复？（y/n）：";;
            "path_fix_automatic") translated_string="正在自动修复 PATH 以包含安装路径...";;
            "permission_warning") translated_string="警告：无法修复存档权限，请手动运行：chmod 666 ~/.starsignal*（Windows：icacls \"%USERPROFILE%\\.starsignal*\" /grant Everyone:F）";;
            "progress") printf -v translated_string "[%s] 正在处理..." "$@";;
            "error") printf -v translated_string "错误：%s" "$@";;
            "check_log") printf -v translated_string "请查看 %s 获取详细信息" "$@";;
            "confirm_action") printf -v translated_string "是否继续执行 %s？（y/n）：" "$@";;
            "error_non_interactive") printf -v translated_string "此脚本需要交互式运行。请下载脚本后执行，例如：\n%s\n%s" "$@";;
            "error_non_interactive_desc_linux_macos") translated_string="Linux/macOS: curl -s https://raw.githubusercontent.com/bbb-lsy07/StarSignalDecoder/main/starsignal_manager.sh -o starsignal_manager.sh && chmod +x starsignal_manager.sh && ./starsignal_manager.sh";;
            "error_non_interactive_desc_windows") translated_string="Windows:     Invoke-WebRequest -Uri https://raw.githubusercontent.com/bbb-lsy07/StarSignalDecoder/main/starsignal_manager.sh -OutFile starsignal_manager.sh && sh starsignal_manager.sh";;
            "detected_os") printf -v translated_string "检测到操作系统：%s %s" "$@";;
            "network_connecting_to") printf -v translated_string "正在连接到 %s..." "$@";;
            "network_connection_failed_retry") printf -v translated_string "网络连接失败，尝试重试 %s/%s" "$@";;
            "network_proxy_suggestion") translated_string="网络仍然失败，请检查代理设置或手动下载代码库。";;
            "warn_set_dns_failed") translated_string="警告：无法设置 DNS";;
            "google_dns_added") translated_string="已添加 Google DNS";;
            "skip_network_check") translated_string="跳过网络检查";;
            "python_install_cancelled") translated_string="已取消 Python 安装";;
            "python_install_success") translated_string="Python 安装成功";;
            "installing_homebrew") translated_string="正在安装 Homebrew...";;
            "pip_install_cancelled") translated_string="已取消 pip 安装";;
            "ensurepip_failed") translated_string="ensurepip 失败，正在下载 get-pip.py";;
            "pip_install_success") translated_string="pip 安装成功";;
            "pip_upgrade_prompt") printf -v translated_string "pip %s 版本过旧，建议升级。是否升级？（y/n）：" "$@";;
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
            "starsignal_repairing_progress") translated_string="正在修复 starsignal 安装...";;
            "starsignal_reinstalling_branch") printf -v translated_string "正在重新安装 starsignal，分支：%s" "$@";;
            "starsignal_uninstalling_progress") translated_string="正在卸载 starsignal...";;
            "starsignal_not_installed_status_msg") translated_string="未安装 starsignal";;
            "env_check_fix_status") translated_string="正在检查和修复环境...";;
            "warning_colorama_install_fail") translated_string="警告：colorama 安装失败，颜色显示可能受影响";;
            "warning_colorama_update_fail") translated_string="警告：colorama 更新失败";;
            "found_python") printf -v translated_string "找到 Python：%s" "$@";;
            "python_outdated") printf -v translated_string "Python %s 版本过旧，需要 >= %s" "$@";;
            "python_not_found_msg") translated_string="未找到 Python";;
            "confirm_install_python") translated_string="安装 Python3";;
            "found_pip") printf -v translated_string "找到 pip：%s" "$@";;
            "confirm_install_pip") translated_string="安装 pip";;
            "found_git") printf -v translated_string "找到 git：%s" "$@";;
            "confirm_install_git") translated_string="安装 git";;
            "path_no_python_scripts") translated_string="PATH 未包含 Python Scripts";;
            "path_contains_local_bin") translated_string="PATH 包含 ~/.local/bin";;
            "path_no_local_bin") translated_string="PATH 未包含 ~/.local/bin";;
            "path_contains_root_local_bin") translated_string="PATH 包含 /root/.local/bin";;
            "path_no_root_local_bin") translated_string="PATH 未包含 /root/.local/bin";;
            "fix_path_action") translated_string="修复 PATH";;
            "found_starsignal") printf -v translated_string "找到 starsignal：%s" "$@";;
            "path_contains_python_scripts") translated_string="PATH 包含 Python Scripts";;
            "path_already_contains_local_bin") printf -v translated_string "PATH 已包含 ~/.local/bin 在 %s 中" "$@";;
            "prompt_press_enter") translated_string="按回车键继续...";;
            "network_still_failed") translated_string="网络仍然无法连接";;
            "env_dependencies_checking") translated_string="正在检查以下依赖：";;
            "dependency_status_found") printf -v translated_string "  - %s: 已找到 (版本: %s)" "$@";;
            "dependency_status_not_found") printf -v translated_string "  - %s: 未找到" "$@";;
            "dependency_status_outdated") printf -v translated_string "  - %s: 版本过旧 (当前: %s, 需要: %s)" "$@";;
            "dependency_status_missing_path") printf -v translated_string "  - %s: PATH 缺失" "$@";;
            "dependency_status_ok") printf -v translated_string "  - %s: 正常" "$@";;
            "all_dependencies_met") translated_string="所有核心依赖已满足。";;
            "some_dependencies_missing") translated_string="某些核心依赖缺失或不符合要求。";;
            "dependency_check_summary") translated_string="依赖检查总结：";;
            "auto_detect_python_pip") translated_string="正在自动检测 Python 和 pip...";;
            "error_python_required") translated_string="需要 Python3";;
            "error_pip_required") translated_string="需要 pip3";;
            "error_git_required") translated_string="需要 git";;
            "error_path_required") translated_string="PATH 必须包含 Python Scripts 或 ~/.local/bin";;
            "error_writing_log") printf -v translated_string "无法写入日志文件 %s" "$@";;
            "error_apt_update") translated_string="apt update 失败";;
            "error_install_failed") translated_string="安装失败";;
            "error_homebrew_install") translated_string="Homebrew 安装失败";;
            "error_unsupported_os_manual_install") translated_string="不支持的操作系统，请手动安装 Python 3.9+";;
            "error_download_get_pip") translated_string="无法下载 get-pip.py";;
            "error_update_path") translated_string="无法更新 PATH";;
            "error_pip_not_found_check_branch") translated_string="pip 未找到，无法检查 starsignal 分支信息";;
            "error_cannot_clean_saves") translated_string="无法清理存档";;
            "current_status") translated_string="当前状态";;
            "found_starsignal_not_in_path_hint") printf -v translated_string "在 %s 中找到 starsignal，但不在 PATH 中" "$@";;
            "starsignal_branch_info_unavailable") translated_string="无法从 pip 提取分支信息";;
            "PATH_already_contains_python_scripts_user_env") translated_string="PATH 已包含 Python Scripts 在用户环境中。";;


            *) translated_string="$key";; # Fall回未翻译的键
        esac
    else # English
        case "$key" in
            "welcome") translated_string="StarSignalDecoder Manager v1.8.0";;
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
            "python_upgrade_prompt") printf -v translated_string "Python %s is below recommended version %s, may cause issues. Upgrade? (y/n):" "$@";;
            "pip_not_found") translated_string="pip3 not found. Install? (y/n):";;
            "git_not_found") translated_string="git not found. Install? (y/n):";;
            "path_not_found") translated_string="PATH does not include required path. Fix? (y/n):";;
            "path_fix_automatic") translated_string="Automatically fixing PATH to include installation paths...";;
            "permission_warning") translated_string="Warning: Failed to fix save file permissions, run: chmod 666 ~/.starsignal* (Windows: icacls \"%USERPROFILE%\\.starsignal*\" /grant Everyone:F)";;
            "progress") printf -v translated_string "[%s] Processing..." "$@";;
            "error") printf -v translated_string "Error: %s" "$@";;
            "check_log") printf -v translated_string "Check %s for details" "$@";;
            "confirm_action") printf -v translated_string "Confirm to proceed with %s? (y/n):" "$@";;
            "error_non_interactive") printf -v translated_string "This script requires an interactive terminal. Please download and execute the script, e.g.:\n%s\n%s" "$@";;
            "error_non_interactive_desc_linux_macos") translated_string="Linux/macOS: curl -s https://raw.githubusercontent.com/bbb-lsy07/StarSignalDecoder/main/starsignal_manager.sh -o starsignal_manager.sh && chmod +x starsignal_manager.sh && ./starsignal_manager.sh";;
            "error_non_interactive_desc_windows") translated_string="Windows:     Invoke-WebRequest -Uri https://raw.githubusercontent.com/bbb-lsy07/StarSignalDecoder/main/starsignal_manager.sh -OutFile starsignal_manager.sh && sh starsignal_manager.sh";;
            "detected_os") printf -v translated_string "Detected OS: %s %s" "$@";;
            "network_connecting_to") printf -v translated_string "Connecting to %s..." "$@";;
            "network_connection_failed_retry") printf -v translated_string "Network connection failed, retrying %s/%s" "$@";;
            "network_proxy_suggestion") translated_string="Network still failed, please check proxy settings or manually download the repository.";;
            "warn_set_dns_failed") translated_string="Warning: Failed to set DNS";;
            "google_dns_added") translated_string="Google DNS added";;
            "skip_network_check") translated_string="Skipping network check";;
            "python_install_cancelled") translated_string="Python installation cancelled";;
            "python_install_success") translated_string="Python installed successfully";;
            "installing_homebrew") translated_string="Installing Homebrew...";;
            "pip_install_cancelled") translated_string="pip installation cancelled";;
            "ensurepip_failed") translated_string="ensurepip failed, downloading get-pip.py";;
            "pip_install_success") translated_string="pip installed successfully";;
            "pip_upgrade_prompt") printf -v translated_string "pip %s is outdated, upgrade recommended. Upgrade? (y/n):" "$@";;
            "git_install_cancelled") translated_string="git installation cancelled";;
            "git_install_success") translated_string="git installed successfully";;
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
            "starsignal_repairing_progress") translated_string="Repairing starsignal installation...";;
            "starsignal_reinstalling_branch") printf -v translated_string "Reinstalling starsignal, branch: %s" "$@";;
            "starsignal_uninstalling_progress") translated_string="Uninstalling starsignal...";;
            "starsignal_not_installed_status_msg") translated_string="starsignal not installed";;
            "env_check_fix_status") translated_string="Checking and fixing environment...";;
            "warning_colorama_install_fail") translated_string="Warning: colorama installation failed, color display might be affected";;
            "warning_colorama_update_fail") translated_string="Warning: colorama update failed";;
            "found_python") printf -v translated_string "Found Python: %s" "$@";;
            "python_outdated") printf -v translated_string "Python %s is outdated, need >= %s" "$@";;
            "python_not_found_msg") translated_string="Python not found";;
            "confirm_install_python") translated_string="install Python3";;
            "found_pip") printf -v translated_string "Found pip: %s" "$@";;
            "confirm_install_pip") translated_string="install pip";;
            "found_git") printf -v translated_string "Found git: %s" "$@";;
            "confirm_install_git") translated_string="install git";;
            "path_no_python_scripts") translated_string="PATH does not contain Python Scripts";;
            "path_contains_local_bin") translated_string="PATH contains ~/.local/bin";;
            "path_no_local_bin") translated_string="PATH does not contain ~/.local/bin";;
            "path_contains_root_local_bin") translated_string="PATH contains /root/.local/bin";;
            "path_no_root_local_bin") translated_string="PATH does not contain /root/.local/bin";;
            "fix_path_action") translated_string="fix PATH";;
            "found_starsignal") printf -v translated_string "Found starsignal: %s" "$@";;
            "path_contains_python_scripts") translated_string="PATH contains Python Scripts";;
            "path_already_contains_local_bin") printf -v translated_string "PATH already contains ~/.local/bin in %s" "$@";;
            "prompt_press_enter") translated_string="Press Enter to continue...";;
            "network_still_failed") translated_string="Network connection still failed";;
            "env_dependencies_checking") translated_string="Checking the following dependencies:";;
            "dependency_status_found") printf -v translated_string "  - %s: Found (Version: %s)" "$@";;
            "dependency_status_not_found") printf -v translated_string "  - %s: Not found" "$@";;
            "dependency_status_outdated") printf -v translated_string "  - %s: Outdated (Current: %s, Needed: %s)" "$@";;
            "dependency_status_missing_path") printf -v translated_string "  - %s: PATH missing" "$@";;
            "dependency_status_ok") printf -v translated_string "  - %s: OK" "$@";;
            "all_dependencies_met") translated_string="All core dependencies are met.";;
            "some_dependencies_missing") translated_string="Some core dependencies are missing or not meeting requirements.";;
            "dependency_check_summary") translated_string="Dependency Check Summary:";;
            "auto_detect_python_pip") translated_string="Automatically detecting Python and pip...";;
            "error_python_required") translated_string="Python3 is required";;
            "error_pip_required") translated_string="pip3 is required";;
            "error_git_required") translated_string="git is required";;
            "error_path_required") translated_string="PATH must include Python Scripts or ~/.local/bin";;
            "error_writing_log") printf -v translated_string "Failed to write to log file %s" "$@";;
            "error_apt_update") translated_string="apt update failed";;
            "error_install_failed") translated_string="Installation failed";;
            "error_homebrew_install") translated_string="Homebrew installation failed";;
            "error_unsupported_os_manual_install") translated_string="Unsupported OS, please manually install Python 3.9+";;
            "error_download_get_pip") translated_string="Failed to download get-pip.py";;
            "error_update_path") translated_string="Failed to update PATH";;
            "error_pip_not_found_check_branch") translated_string="pip not found, cannot check starsignal branch information";;
            "error_cannot_clean_saves") translated_string="Failed to clean save files";;
            "current_status") translated_string="Current Status";;
            "found_starsignal_not_in_path_hint") printf -v translated_string "Found starsignal in %s, but not in PATH" "$@";;
            "starsignal_branch_info_unavailable") translated_string="Failed to extract branch information from pip";;
            "PATH_already_contains_python_scripts_user_env") translated_string="PATH already contains Python Scripts in user environment.";;

            *) translated_string="$key";; # Fallback for untranslated keys
        esac
    fi
    # 使用 printf "%b" 确保反斜杠转义序列（如 \n）被正确解释。
    printf "%b" "$translated_string"
}

# 初始语言检测（在日志设置之前，可能需要翻译）
detect_language "$@"

# 确保日志文件可写
# 如果是root用户，默认日志文件在 /root/.starsignal_install.log
if [ "$(whoami)" = "root" ]; then
    LOG_FILE="/root/.starsignal_install.log"
fi
touch "$LOG_FILE" 2>/dev/null || {
    # 如果无法在默认位置写入，则尝试使用 /tmp
    LOG_FILE="/tmp/starsignal_install_$$.log"
    echo "$(translate "error" "$(translate "error_writing_log" "$HOME/.starsignal_install.log")")" >&2
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

# 检查 stdin 是否连接到 TTY。如果不是，则以说明退出。
if [ ! -t 0 ]; then
    printf "$(translate "error_non_interactive" "$(translate "error_non_interactive_desc_linux_macos")" "$(translate "error_non_interactive_desc_windows")")\n" >&2
    log "$(translate "error" "脚本以非交互模式运行。请使用推荐的运行方式。")"
    exit 1
fi

# 交互式语言选择 - 如果未通过 --lang 设置，则覆盖检测到的语言
lang_arg_present=0
for arg in "$@"; do
    if [ "$arg" = "--lang" ]; then
        lang_arg_present=1
        break
    fi
done

if [ "$lang_arg_present" -eq 0 ]; then
    printf "$(translate "choose_lang")"
    # 强制从 /dev/tty 读取，以确保即使 stdin 被重定向也能获取用户输入
    read -r chosen_lang < /dev/tty
    case "$chosen_lang" in
        "en"|"En"|"EN") LANG_MODE="en";;
        "zh"|"Zh"|"ZH") LANG_MODE="zh";;
        *) log "$(translate "No language choice or invalid choice '%s', defaulting to %s." "$chosen_lang" "$LANG_MODE")";;
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
    action_key="$1" # 动作的翻译键（例如："installing"）
    action_arg="${2:-}" # 动作的可选参数（例如：分支名称）

    # 改进的进度条样式
    for i in 1 2 3 4 5 6 7 8; do
        case $i in
            1) BAR=">       ";; # 8 spaces for fixed length
            2) BAR="=>      ";;
            3) BAR="==>     ";;
            4) BAR="===>    ";;
            5) BAR="====>   ";;
            6) BAR="=====>  ";;
            7) BAR="======> ";;
            8) BAR="========>";;
        esac
        printf "\r$(translate "progress" "$BAR")"
        sleep 0.3
    done
    printf "\r$(translate "$action_key" "$action_arg") [完成]\n"
}

# 检查网络
check_network() {
    local network_ok=0
    log "$(translate "network_connecting_to" "github.com")"
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
        log "$(translate "network_connection_failed_retry" "$i" "$MAX_RETRIES")"
        sleep "$RETRY_DELAY"
    done

    if [ "$network_ok" -eq 0 ]; then
        echo "$(translate "network_error")"
        echo "$(translate "network_options")"
        printf "$(translate "choose_option") "
        read -r choice < /dev/tty
        case "$choice" in
            1)
                log "$(translate "尝试设置 Google DNS...")"
                if [ "$OS" = "windows" ]; then
                    powershell -Command "Set-DnsClientServerAddress -InterfaceAlias * -ServerAddresses ('8.8.8.8','8.8.4.4')" || log "$(translate "warn_set_dns_failed")"
                else
                    echo "nameserver 8.8.8.8" | sudo tee -a /etc/resolv.conf >/dev/null
                fi
                log "$(translate "google_dns_added")"
                sleep 2
                if [ "$OS" = "windows" ]; then
                    ping -n 1 github.com >/dev/null 2>&1 || {
                        echo "$(translate "network_proxy_suggestion")"
                        die "$(translate "error" "$(translate "network_still_failed")")"
                    }
                else
                    ping -c 1 github.com >/dev/null 2>&1 || {
                        echo "$(translate "network_proxy_suggestion")"
                        die "$(translate "error" "$(translate "network_still_failed")")"
                    }
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
    if command_exists python3; then
        PYTHON_CMD="python3"
    elif command_exists python; then
        PYTHON_CMD="python"
    else
        PYTHON_CMD="" # 确保如果未找到则为空
        log "$(translate "python_not_found_msg")"
        return 1 # 未找到 Python
    fi

    local current_python_version_full=$("$PYTHON_CMD" --version 2>&1 | awk '{print $2}')
    PYTHON_VERSION="$current_python_version_full" # 保存完整版本号
    log "$(translate "found_python" "$PYTHON_VERSION")"

    # 将版本号拆分为主次版本号进行比较
    local major_version=$(echo "$PYTHON_VERSION" | cut -d. -f1)
    local minor_version=$(echo "$PYTHON_VERSION" | cut -d. -f2)
    local min_major=$(echo "$PYTHON_MIN_VERSION" | cut -d. -f1)
    local min_minor=$(echo "$PYTHON_MIN_VERSION" | cut -d. -f2)
    local rec_major=$(echo "$PYTHON_RECOMMENDED_VERSION" | cut -d. -f1)
    local rec_minor=$(echo "$PYTHON_RECOMMENDED_VERSION" | cut -d. -f2)

    if [ "$major_version" -lt "$min_major" ] || \
       { [ "$major_version" -eq "$min_major" ] && [ "$minor_version" -lt "$min_minor" ]; }; then
        log "$(translate "python_outdated" "$PYTHON_VERSION" "$PYTHON_MIN_VERSION")"
        return 1 # 版本过旧（低于最低要求）
    fi

    if [ "$major_version" -lt "$rec_major" ] || \
       { [ "$major_version" -eq "$rec_major" ] && [ "$minor_version" -lt "$rec_minor" ]; }; then
        log "$(translate "python_upgrade_prompt" "$PYTHON_VERSION" "$PYTHON_RECOMMENDED_VERSION")"
        return 2 # 版本较低（低于推荐）
    fi

    return 0 # 版本正常
}

# 安装 Python
install_python() {
    log "$(translate "正在安装 Python3...")"
    printf "$(translate "confirm_action" "$(translate "confirm_install_python")") "
    read -r confirm < /dev/tty
    [ "$confirm" != "y" ] && [ "$confirm" != "Y" ] && die "$(translate "python_install_cancelled")"
    case "$OS" in
        ubuntu|debian)
            sudo apt-get update || die "$(translate "error" "$(translate "error_apt_update")")"
            # 尝试安装推荐版本，如果不行就安装默认的
            sudo apt-get install -y python3.9 python3.9-dev || sudo apt-get install -y python3 python3-dev || die "$(translate "error" "$(translate "error_install_failed")")"
            if command_exists python3.9; then PYTHON_CMD="python3.9"; else PYTHON_CMD="python3"; fi
            ;;
        centos|rhel)
            # CentOS/RHEL 7 默认 Python3 版本较低，通常需要通过 SCL 安装新版本
            sudo yum install -y centos-release-scl || die "$(translate "error" "无法安装 SCL 仓库")"
            sudo yum install -y rh-python39 rh-python39-python-devel || die "$(translate "error" "Python 3.9 安装失败")"
            # 激活 SCL 中的 Python 环境
            export PATH="/opt/rh/rh-python39/root/usr/bin:$PATH"
            PYTHON_CMD="python3" # SCL 的 python3 命令通常指向其提供的版本
            hash -r # 更新 shell 对命令的查找路径
            ;;
        macos)
            if command_exists brew; then
                brew install python@3.9 || brew install python3 || die "$(translate "error" "$(translate "error_install_failed")")"
            else
                log "$(translate "installing_homebrew")"
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || die "$(translate "error" "$(translate "error_homebrew_install")")"
                brew install python@3.9 || brew install python3 || die "$(translate "error" "$(translate "error_install_failed")")"
            fi
            if command_exists python3.9; then PYTHON_CMD="python3.9"; else PYTHON_CMD="python3"; fi
            ;;
        windows)
            if command_exists winget; then
                winget install --id Python.Python.3.9 -e || die "$(translate "error" "$(translate "error_install_failed")")"
                PYTHON_CMD="python" # winget 安装后通常在 PATH 中是 python.exe
            else
                log "$(translate "正在安装 winget...")"
                powershell -Command "Invoke-WebRequest -Uri https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle -OutFile winget.msixbundle; Add-AppxPackage winget.msixbundle" 2>/dev/null
                winget install --id Python.Python.3.9 -e || die "$(translate "error" "$(translate "error_install_failed")")"
                PYTHON_CMD="python"
            fi
            ;;
        *)
            die "$(translate "error" "$(translate "error_unsupported_os_manual_install")")"
            ;;
    esac
    check_python || die "$(translate "error" "$(translate "Python 安装失败")")" # 再次检查以确保 PYTHON_CMD 已设置
    log "$(translate "python_install_success")"
}

# 检查 pip
check_pip() {
    if command_exists pip3; then
        PIP_CMD="pip3"
    elif command_exists pip; then
        PIP_CMD="pip"
    else
        PIP_CMD=""
        log "$(translate "pip_not_found")"
        return 1 # 未找到 pip
    fi

    local current_pip_version_full=$("$PIP_CMD" --version 2>&1 | awk '{print $2}')
    PIP_VERSION="$current_pip_version_full" # 保存完整版本号
    log "$(translate "found_pip" "$PIP_VERSION")"

    local major_version=$(echo "$PIP_VERSION" | cut -d. -f1)
    if [ "$major_version" -lt 20 ]; then # pip 版本 20.x 开始有较大变化
        log "$(translate "pip_upgrade_prompt" "$PIP_VERSION")"
        return 2 # 版本过旧
    fi
    return 0 # 版本正常
}

# 升级 pip
upgrade_pip() {
    log "$(translate "正在升级 pip...")"
    printf "$(translate "confirm_action" "$(translate "pip_upgrade_action")") "
    read -r confirm < /dev/tty
    [ "$confirm" != "y" ] && [ "$confirm" != "Y" ] && return 1 # 用户选择不升级
    if [ -z "$PYTHON_CMD" ]; then # 确保 Python 已被检测到
        check_python || die "$(translate "error" "$(translate "error_python_required")")"
    fi
    "$PYTHON_CMD" -m pip install --upgrade pip || die "$(translate "error" "pip 升级失败")"
    check_pip || die "$(translate "error" "pip 升级后仍不可用")"
    log "$(translate "pip_install_success")" # 复用成功安装的翻译
}

# 安装 pip
install_pip() {
    log "$(translate "正在安装 pip...")"
    printf "$(translate "confirm_action" "$(translate "confirm_install_pip")") "
    read -r confirm < /dev/tty
    [ "$confirm" != "y" ] && [ "$confirm" != "Y" ] && die "$(translate "pip_install_cancelled")"
    if [ -z "$PYTHON_CMD" ]; then # 确保 Python 已被检测到
        check_python || die "$(translate "error" "$(translate "error_python_required")")"
    fi
    "$PYTHON_CMD" -m ensurepip --upgrade 2>/dev/null || {
        log "$(translate "ensurepip_failed")"
        curl -s https://bootstrap.pypa.io/get-pip.py -o get-pip.py || die "$(translate "error" "$(translate "error_download_get_pip")")"
        "$PYTHON_CMD" get-pip.py --user || die "$(translate "error" "pip 安装失败")"
        rm -f get-pip.py
    }
    # 确保 pip 的安装路径在 PATH 中 (这部分由 fix_path 处理，但这里做个快速检查)
    # 自动修复 PATH 逻辑在 fix_environment 或安装/更新完成后触发
    check_pip || die "$(translate "error" "pip 安装失败")"
    log "$(translate "pip_install_success")"
}

# 检查 git
check_git() {
    if command_exists git; then
        GIT_VERSION=$(git --version 2>&1 | awk '{print $3}')
        log "$(translate "found_git" "$GIT_VERSION")"
        local major_version=$(echo "$GIT_VERSION" | cut -d. -f1)
        local minor_version=$(echo "$GIT_VERSION" | cut -d. -f2)
        if [ "$major_version" -lt 2 ] || { [ "$major_version" -eq 2 ] && [ "$minor_version" -lt 9 ]; }; then # 推荐 Git 2.9+
            log "$(translate "dependency_status_outdated" "git" "$GIT_VERSION" "2.9+")"
            return 2 # 版本过旧
        fi
        return 0 # 版本正常
    fi
    log "$(translate "git_not_found")"
    return 1 # 未找到 git
}

# 安装 git
install_git() {
    log "$(translate "正在安装 git...")"
    printf "$(translate "confirm_action" "$(translate "confirm_install_git")") "
    read -r confirm < /dev/tty
    [ "$confirm" != "y" ] && [ "$confirm" != "Y" ] && die "$(translate "git_install_cancelled")"
    case "$OS" in
        ubuntu|debian)
            sudo apt-get update || die "$(translate "error" "$(translate "error_apt_update")")"
            sudo apt-get install -y git || die "$(translate "error" "$(translate "error_install_failed")")"
            ;;
        centos|rhel)
            sudo yum install -y git || die "$(translate "error" "$(translate "error_install_failed")")"
            ;;
        macos)
            if command_exists brew; then
                brew install git || die "$(translate "error" "$(translate "error_install_failed")")"
            else
                log "$(translate "installing_homebrew")"
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || die "$(translate "error" "$(translate "error_homebrew_install")")"
                brew install git || die "$(translate "error" "$(translate "error_install_failed")")"
            fi
            ;;
        windows)
            if command_exists winget; then
                winget install --id Git.Git -e || die "$(translate "error" "$(translate "error_install_failed")")"
            else
                log "$(translate "正在安装 winget...")"
                powershell -Command "Invoke-WebRequest -Uri https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle -OutFile winget.msixbundle; Add-AppxPackage winget.msixbundle" 2>/dev/null
                winget install --id Git.Git -e || die "$(translate "error" "$(translate "error_install_failed")")"
            fi
            ;;
        *)
            die "$(translate "error" "$(translate "error_unsupported_os_manual_install")")"
            ;;
    esac
    check_git || die "$(translate "error" "$(translate "git 安装失败")")"
    log "$(translate "git_install_success")"
}

# 检查 PATH
check_path() {
    local shell_path_status=1 # 默认 PATH 不包含必要路径

    if [ "$OS" = "windows" ]; then
        local python_user_scripts=""
        if [ -n "$PYTHON_CMD" ]; then
            python_user_scripts=$("$PYTHON_CMD" -c "import site; print(site.USER_BASE + '\\Scripts')" 2>/dev/null)
        fi
        if [ -n "$python_user_scripts" ] && powershell -Command "[Environment]::GetEnvironmentVariable('Path', 'User')" | grep -qi "$python_user_scripts"; then
            log "$(translate "path_contains_python_scripts")"
            shell_path_status=0
        else
            log "$(translate "path_no_python_scripts")"
        fi
    else
        local local_bin_path="$HOME/.local/bin"
        if [ "$(whoami)" = "root" ]; then
            local_bin_path="/root/.local/bin"
        fi

        if echo "$PATH" | grep -q "$local_bin_path"; then
            log "$(translate "path_contains_local_bin" "$local_bin_path")" # New translation key
            shell_path_status=0
        else
            log "$(translate "path_no_local_bin" "$local_bin_path")" # New translation key
        fi
    fi
    return "$shell_path_status"
}

# 修复 PATH
fix_path() {
    log "$(translate "path_fix_automatic")"
    if [ "$OS" = "windows" ]; then
        local python_user_scripts=""
        if [ -n "$PYTHON_CMD" ]; then
            python_user_scripts=$("$PYTHON_CMD" -c "import site; print(site.USER_BASE + '\\Scripts')" 2>/dev/null)
        fi
        if [ -z "$python_user_scripts" ]; then
            python_user_scripts="$HOME/AppData/Roaming/Python/Python39/Scripts" # Fallback
        fi

        if [ -n "$python_user_scripts" ] && ! powershell -Command "[Environment]::GetEnvironmentVariable('Path', 'User')" | grep -qi "$python_user_scripts"; then
            powershell -Command "[Environment]::SetEnvironmentVariable('Path', [Environment]::GetEnvironmentVariable('Path', 'User') + ';$python_user_scripts', 'User')" || die "$(translate "error" "$(translate "error_update_path")")"
            export PATH="$python_user_scripts:$PATH" # Export for current session
            log "$(translate "path_updated_reboot_win")"
        else
            log "$(translate "PATH_already_contains_python_scripts_user_env")"
        fi
    else
        SHELL_CONFIG=""
        local path_to_add=""
        local local_bin_path="$HOME/.local/bin"

        if [ "$(whoami)" = "root" ]; then
            SHELL_CONFIG="/root/.bashrc"
            local_bin_path="/root/.local/bin"
        else
            if [ -n "$ZSH_VERSION" ]; then
                SHELL_CONFIG="$HOME/.zshrc"
            elif [ -n "$BASH_VERSION" ]; then
                SHELL_CONFIG="$HOME/.bashrc"
            else
                SHELL_CONFIG="$HOME/.profile"
            fi
        fi

        # 检查是否已包含 .local/bin
        if ! grep -q "export PATH=.*${local_bin_path}:" "$SHELL_CONFIG" 2>/dev/null && \
           ! grep -q "export PATH=\"\$PATH:.*${local_bin_path}\"" "$SHELL_CONFIG" 2>/dev/null; then
            # 如果不包含，则添加到 PATH 的开头
            echo "export PATH=\"${local_bin_path}:\$PATH\"" >> "$SHELL_CONFIG"
            log "$(translate "path_config_updated" "$SHELL_CONFIG")"
        else
            log "$(translate "path_already_contains_local_bin" "$SHELL_CONFIG")"
        fi
        export PATH="${local_bin_path}:$PATH" # Export for current session
        echo "$(translate "path_updated_reboot_linux_macos" "$SHELL_CONFIG")"
    fi
    check_path || die "$(translate "error" "$(translate "无法验证 PATH 更新")")"
}

# 检查 starsignal 安装
check_starsignal() {
    local starsignal_status=1 # 默认未安装
    if command_exists starsignal; then
        STARSIGNAL_VERSION=$(starsignal --version 2>/dev/null | awk '{print $2}')
        log "$(translate "found_starsignal" "$STARSIGNAL_VERSION")"
        starsignal_status=0 # 已找到并可执行
    else
        # 如果 starsignal 命令不在 PATH 中，尝试在常见安装路径查找
        local possible_paths
        if [ "$(whoami)" = "root" ]; then
            possible_paths="/root/.local/bin/starsignal /usr/local/bin/starsignal"
        else
            possible_paths="$HOME/.local/bin/starsignal /usr/local/bin/starsignal"
        fi

        for path in $possible_paths; do
            if [ -x "$path" ]; then
                log "$(translate "found_starsignal_not_in_path_hint" "$path")"
                # 尝试修复 PATH，然后重新检查
                fix_path
                if command_exists starsignal; then
                    STARSIGNAL_VERSION=$(starsignal --version 2>/dev/null | awk '{print $2}')
                    log "$(translate "found_starsignal" "$STARSIGNAL_VERSION")" # 修复后再次日志
                    starsignal_status=0
                    break
                fi
            fi
        done
    fi

    # 检查 PIP 信息，无论 starsignal 是否在 PATH 中
    if [ "$starsignal_status" -eq 0 ]; then
        if [ -z "$PIP_CMD" ]; then
            check_pip || { log "$(translate "error" "$(translate "error_pip_not_found_check_branch")")"; INSTALLED_BRANCH="未知"; return 0; }
        fi
        PIP_INFO=$("$PIP_CMD" show starsignal 2>/dev/null)
        if [ -n "$PIP_INFO" ]; then
            INSTALLED_BRANCH=$(echo "$PIP_INFO" | grep -i "Location" | sed -n 's/.*@\([^#]*\).*#egg=starsignal/\1/p')
            log "$(translate "installed_branch_source" "${INSTALLED_BRANCH:-未知}")"
        else
            INSTALLED_BRANCH="未知"
            log "$(translate "starsignal_branch_info_unavailable")"
        fi
    else
        log "$(translate "starsignal_not_installed_status_msg")"
    fi
    return "$starsignal_status"
}


# 检查存档文件
check_saves() {
    if [ "$OS" = "windows" ]; then
        powershell -Command "Test-Path \$env:USERPROFILE\.starsignal*" | grep -q "True"
    else
        # 检查用户目录和root目录下的存档文件
        ls "$HOME/.starsignal"* >/dev/null 2>&1 || ls "/root/.starsignal"* >/dev/null 2>&1
    fi
    return $?
}

# 修复权限
fix_permissions() {
    log "$(translate "正在修复存档文件权限...")"
    if [ "$OS" = "windows" ]; then
        powershell -Command "Get-ChildItem -Path \$env:USERPROFILE\.starsignal* | ForEach-Object { icacls \$_.FullName /grant Everyone:F }" 2>/dev/null || log "$(translate "permission_warning")"
    else
        # 修复用户目录和root目录下的存档文件权限
        chmod 666 "$HOME/.starsignal"* 2>/dev/null
        chmod 666 "/root/.starsignal"* 2>/dev/null || log "$(translate "permission_warning")"
    fi
    log "$(translate "权限修复完成")"
}

# 安装 starsignal
install_starsignal() {
    if [ -z "$PIP_CMD" ]; then
        check_pip || die "$(translate "error" "$(translate "error_pip_required")")"
    fi
    local pip_check_result=$(check_pip; echo $?)
    if [ "$pip_check_result" -eq 2 ]; then # pip 版本过旧，提示升级
        upgrade_pip || log "$(translate "pip_upgrade_cancelled")" # 用户选择不升级，日志记录
    fi

    echo "$(translate "branch_prompt")"
    printf "$(translate "choose_branch") "
    read -r branch_choice < /dev/tty
    case "$branch_choice" in
        2) BRANCH="dev" ;;
        *) BRANCH="main" ;;
    esac
    log "$(translate "starsignal_installing_branch" "$BRANCH")"
    printf "$(translate "confirm_action" "$(translate "confirm_install_starsignal")") "
    read -r confirm < /dev/tty
    [ "$confirm" != "y" ] && [ "$confirm" != "Y" ] && die "$(translate "install_cancelled")"
    show_progress "installing" "$BRANCH"
    # 使用 --no-warn-script-location 避免 pip 在安装可执行脚本时发出警告
    "$PIP_CMD" install --user --force-reinstall --no-warn-script-location "git+$REPO_URL@$BRANCH" || {
        log "$(translate "error" "pip 安装失败，尝试使用 virtualenv")"
        # 尝试使用 virtualenv 隔离安装
        if [ -n "$PYTHON_CMD" ]; then
            "$PYTHON_CMD" -m venv "$HOME/starsignal_env" || "$PYTHON_CMD" -m venv "/tmp/starsignal_env" || die "$(translate "error" "无法创建虚拟环境")"
            local venv_path="$HOME/starsignal_env"
            if [ ! -d "$venv_path" ]; then venv_path="/tmp/starsignal_env"; fi

            log "激活虚拟环境：$venv_path/bin/activate"
            # 兼容不同shell和Windows的激活方式
            if [ "$OS" = "windows" ]; then
                powershell -Command "& \"$venv_path/Scripts/activate\""
            else
                . "$venv_path/bin/activate"
            fi
            
            # 重新检查 pip 命令在虚拟环境中是否可用
            check_pip # 确保PIP_CMD在虚拟环境中是正确的
            "$PIP_CMD" install --no-warn-script-location "git+$REPO_URL@$BRANCH" || die "$(translate "error" "虚拟环境安装失败")"
            log "已安装到虚拟环境：$venv_path"
            log "请运行 'source $venv_path/bin/activate' 后执行 'starsignal' 启动。"
            log "（Windows: 请运行 '$venv_path\\Scripts\\activate.ps1' 或 '$venv_path\\Scripts\\activate.bat' 后执行 'starsignal' 启动。）"
            die "$(translate "error" "安装完成，但需要手动激活虚拟环境")"
        else
            die "$(translate "error" "安装失败，且未找到 Python，无法尝试虚拟环境")"
        fi
    }
    "$PIP_CMD" install --user colorama 2>/dev/null || log "$(translate "warning_colorama_install_fail")"
    fix_permissions
    if ! check_path; then
        fix_path
    fi
    check_starsignal || {
        log "$(translate "error" "starsignal 未在 PATH 中，请检查 ~/.local/bin 或 /root/.local/bin")"
        die "$(translate "error" "安装验证失败，请检查 PATH 或手动安装")"
    }
    log "$(translate "starsignal 安装成功，分支：$BRANCH")"
    echo "$(translate "installation_complete")"
}

# 更新 starsignal
update_starsignal() {
    if [ -z "$PIP_CMD" ]; then
        check_pip || die "$(translate "error" "$(translate "error_pip_required")")"
    fi
    local pip_check_result=$(check_pip; echo $?)
    if [ "$pip_check_result" -eq 2 ]; then # pip 版本过旧，提示升级
        upgrade_pip || log "$(translate "pip_upgrade_cancelled")"
    fi

    echo "$(translate "branch_prompt")"
    printf "$(translate "choose_branch") "
    read -r branch_choice < /dev/tty
    case "$branch_choice" in
        2) BRANCH="dev" ;;
        *) BRANCH="main" ;;
    esac
    log "$(translate "starsignal_updating_branch" "$BRANCH")"
    printf "$(translate "confirm_action" "$(translate "confirm_update_starsignal")") "
    read -r confirm < /dev/tty
    [ "$confirm" != "y" ] && [ "$confirm" != "Y" ] && die "$(translate "update_cancelled")"
    show_progress "updating" "$BRANCH"
    "$PIP_CMD" install --user --force-reinstall --no-warn-script-location "git+$REPO_URL@$BRANCH" || die "$(translate "error" "更新失败")"
    "$PIP_CMD" install --user colorama 2>/dev/null || log "$(translate "warning_colorama_update_fail")"
    fix_permissions
    if ! check_path; then
        fix_path
    fi
    check_starsignal || die "$(translate "error" "更新验证失败")"
    log "$(translate "starsignal 更新成功，分支：$BRANCH")"
    echo "$(translate "update_complete")"
}

# 修复安装
repair_starsignal() {
    log "$(translate "starsignal_repairing_progress")"
    if [ -z "$PIP_CMD" ]; then
        check_pip || die "$(translate "error" "$(translate "error_pip_required")")"
    fi
    local pip_check_result=$(check_pip; echo $?)
    if [ "$pip_check_result" -eq 2 ]; then # pip 版本过旧，提示升级
        upgrade_pip || log "$(translate "pip_upgrade_cancelled")"
    fi

    if check_starsignal; then
        INSTALLED_BRANCH_INFO=$("$PIP_CMD" show starsignal 2>/dev/null | grep -i "Location" | sed -n 's/.*@\([^#]*\).*#egg=starsignal/\1/p')
        BRANCH=${INSTALLED_BRANCH_INFO:-"main"}
        log "$(translate "detected_installed_branch" "${BRANCH}")"
    else
        BRANCH="main"
        log "$(translate "no_starsignal_detected_repair")"
    fi
    log "$(translate "starsignal_reinstalling_branch" "$BRANCH")"
    printf "$(translate "confirm_action" "$(translate "confirm_repair_starsignal")") "
    read -r confirm < /dev/tty
    [ "$confirm" != "y" ] && [ "$confirm" != "Y" ] && die "$(translate "repair_cancelled")"
    show_progress "repairing"
    "$PIP_CMD" install --user --force-reinstall --no-warn-script-location "git+$REPO_URL@$BRANCH" || die "$(translate "error" "修复失败")"
    "$PIP_CMD" install --user colorama 2>/dev/null || log "$(translate "warning_colorama_install_fail")"
    fix_permissions
    if ! check_path; then
        fix_path
    fi
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
            found_saves=$(powershell -Command "Get-ChildItem -Path \$env:USERPROFILE\.starsignal* | Select-Object -ExpandProperty Name" 2>/dev/null)
        else
            found_saves=$(ls "$HOME/.starsignal"* 2>/dev/null || ls "/root/.starsignal"* 2>/dev/null)
        fi
        echo "$(translate "save_files_found_list" "$found_saves")"
        printf "$(translate "confirm_clean") "
        read -r confirm < /dev/tty
        if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
            if [ "$OS" = "windows" ]; then
                powershell -Command "Remove-Item -Path \$env:USERPROFILE\.starsignal* -Force" || die "$(translate "error" "$(translate "error_cannot_clean_saves")")"
            else
                rm -f "$HOME/.starsignal"* "/root/.starsignal"* 2>/dev/null || die "$(translate "error" "$(translate "error_cannot_clean_saves")")"
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
    log "$(translate "starsignal_uninstalling_progress")"
    printf "$(translate "confirm_action" "$(translate "confirm_uninstall_starsignal")") "
    read -r confirm < /dev/tty
    [ "$confirm" != "y" ] && [ "$confirm" != "Y" ] && die "$(translate "uninstall_cancelled")"
    if check_starsignal; then
        show_progress "uninstalling"
        if [ -z "$PIP_CMD" ]; then
            check_pip || die "$(translate "error" "$(translate "error_pip_required")")"
        fi
        "$PIP_CMD" uninstall -y starsignal || die "$(translate "error" "卸载失败")"
        clean_saves
        log "$(translate "starsignal 卸载完成")"
        echo "$(translate "uninstall_complete")"
    else
        echo "$(translate "starsignal_not_installed_status_msg")"
    fi
}

# 修复环境
fix_environment() {
    log "$(translate "env_check_fix_status")"
    echo "$(translate "env_dependencies_checking")"
    local all_dependencies_met=true

    # Python 检查和安装/升级
    local python_status=$(check_python; echo $?)
    if [ "$python_status" -eq 0 ]; then
        echo "$(translate "dependency_status_ok" "Python3")"
    elif [ "$python_status" -eq 1 ]; then
        echo "$(translate "dependency_status_not_found" "Python3")"
        printf "$(translate "python_not_found" "$PYTHON_MIN_VERSION") "
        read -r install_python_choice < /dev/tty
        if [ "$install_python_choice" = "y" ] || [ "$install_python_choice" = "Y" ]; then
            install_python
            if [ "$(check_python; echo $?)" -ne 0 ]; then all_dependencies_met=false; fi
        else
            all_dependencies_met=false
            log "$(translate "error" "$(translate "error_python_required")")"
        fi
    elif [ "$python_status" -eq 2 ]; then
        echo "$(translate "dependency_status_outdated" "Python3" "$PYTHON_VERSION" "$PYTHON_RECOMMENDED_VERSION")"
        printf "$(translate "python_upgrade_prompt" "$PYTHON_VERSION" "$PYTHON_RECOMMENDED_VERSION") "
        read -r upgrade_python_choice < /dev/tty
        if [ "$upgrade_python_choice" = "y" ] || [ "$upgrade_python_choice" = "Y" ]; then
            install_python
            if [ "$(check_python; echo $?)" -ne 0 ]; then all_dependencies_met=false; fi
        else
            echo "$(translate "dependency_status_ok" "Python3")" # 用户选择不升级，但已满足最低要求
        fi
    fi

    # Pip 检查和安装/升级
    local pip_status=$(check_pip; echo $?)
    if [ "$pip_status" -eq 0 ]; then
        echo "$(translate "dependency_status_ok" "pip3")"
    elif [ "$pip_status" -eq 1 ]; then
        echo "$(translate "dependency_status_not_found" "pip3")"
        printf "$(translate "pip_not_found") "
        read -r install_pip_choice < /dev/tty
        if [ "$install_pip_choice" = "y" ] || [ "$install_pip_choice" = "Y" ]; then
            install_pip
            if [ "$(check_pip; echo $?)" -ne 0 ]; then all_dependencies_met=false; fi
        else
            all_dependencies_met=false
            log "$(translate "error" "$(translate "error_pip_required")")"
        fi
    elif [ "$pip_status" -eq 2 ]; then
        echo "$(translate "dependency_status_outdated" "pip3" "$PIP_VERSION" "20.x+")"
        printf "$(translate "pip_upgrade_prompt" "$PIP_VERSION") "
        read -r upgrade_pip_choice < /dev/tty
        if [ "$upgrade_pip_choice" = "y" ] || [ "$upgrade_pip_choice" = "Y" ]; then
            upgrade_pip
            if [ "$(check_pip; echo $?)" -ne 0 ]; then all_dependencies_met=false; fi
        else
            echo "$(translate "dependency_status_ok" "pip3")"
        fi
    fi

    # Git 检查和安装
    local git_status=$(check_git; echo $?)
    if [ "$git_status" -eq 0 ]; then
        echo "$(translate "dependency_status_ok" "git")"
    elif [ "$git_status" -eq 1 ]; then
        echo "$(translate "dependency_status_not_found" "git")"
        printf "$(translate "git_not_found") "
        read -r install_git_choice < /dev/tty
        if [ "$install_git_choice" = "y" ] || [ "$install_git_choice" = "Y" ]; then
            install_git
            if [ "$(check_git; echo $?)" -ne 0 ]; then all_dependencies_met=false; fi
        else
            all_dependencies_met=false
            log "$(translate "error" "$(translate "error_git_required")")"
        fi
    elif [ "$git_status" -eq 2 ]; then
        echo "$(translate "dependency_status_outdated" "git" "$GIT_VERSION" "2.9+")"
        printf "$(translate "confirm_action" "$(translate "upgrade_git_action")") "
        read -r upgrade_git_choice < /dev/tty
        if [ "$upgrade_git_choice" = "y" ] || [ "$upgrade_git_choice" = "Y" ]; then
            install_git # 安装函数会处理升级
            if [ "$(check_git; echo $?)" -ne 0 ]; then all_dependencies_met=false; fi
        else
            echo "$(translate "dependency_status_ok" "git")"
        fi
    fi

    # PATH 检查和修复
    if check_path; then
        echo "$(translate "dependency_status_ok" "PATH")"
    else
        echo "$(translate "dependency_status_missing_path" "PATH")"
        fix_path # 自动尝试修复 PATH
        if check_path; then
            echo "$(translate "dependency_status_ok" "PATH")"
        else
            echo "$(translate "dependency_status_missing_path" "PATH")"
            all_dependencies_met=false
        fi
    fi

    # 网络检查
    check_network

    # 权限修复
    fix_permissions

    echo "---------------------------------"
    echo "$(translate "dependency_check_summary")"
    if "$all_dependencies_met"; then
        echo "$(translate "all_dependencies_met")"
        log "$(translate "环境检查和修复完成")"
        echo "$(translate "environment_ready")"
    else
        echo "$(translate "some_dependencies_missing")"
        log "$(translate "环境检查完成，但存在问题")"
        die "$(translate "error" "环境检查失败，请检查日志")"
    fi
}

# 主菜单
main_menu() {
    while true; do
        clear
        echo "=========================================="
        echo "$(translate "welcome")"
        echo "=========================================="
        detect_os

        log "$(translate "auto_detect_python_pip")"
        # 确保 PYTHON_CMD 和 PIP_CMD 在进入菜单前已尝试自动检测并设置
        if [ -z "$PYTHON_CMD" ]; then check_python >/dev/null 2>&1; fi
        if [ -z "$PIP_CMD" ]; then check_pip >/dev/null 2>&1; fi


        if check_starsignal; then
            echo "------------------------------------------"
            echo "$(translate "current_status")"
            printf "$(translate "status_installed" "$STARSIGNAL_VERSION" "${INSTALLED_BRANCH:-未知}")\n"
            check_saves && echo "$(translate "save_files_present")" || echo "$(translate "save_files_none")"
            echo "------------------------------------------"
            echo "$(translate "installed_menu")"
            printf "$(translate "choose_option") "
            # 增加超时，防止无限等待
            read -r -t 60 choice < /dev/tty
            if [ -z "$choice" ]; then
                log "$(translate "Error: No input received for 60 seconds, re-displaying menu.")" # New log message
                continue # 无输入则重新显示菜单
            fi
            case "$choice" in
                1) update_starsignal ;;
                2) repair_starsignal ;;
                3) clean_saves ;;
                4) uninstall_starsignal ;;
                5) fix_environment ;;
                6) log "$(translate "exiting_program")"; echo "$(translate "exiting_program")"; exit 0 ;;
                *) echo "$(translate "invalid_choice")"; sleep 1; continue ;;
            esac
        else
            echo "------------------------------------------"
            echo "$(translate "current_status")"
            echo "$(translate "status_not_installed")"
            echo "------------------------------------------"
            echo "$(translate "install_menu")"
            printf "$(translate "choose_option") "
            read -r -t 60 choice < /dev/tty
            if [ -z "$choice" ]; then
                log "$(translate "Error: No input received for 60 seconds, re-displaying menu.")"
                continue # 无输入则重新显示菜单
            fi
            case "$choice" in
                1) install_starsignal ;;
                2) fix_environment ;;
                3) log "$(translate "exiting_program")"; echo "$(translate "exiting_program")"; exit 0 ;;
                *) echo "$(translate "invalid_choice")"; sleep 1; continue ;;
            esac
        fi
        echo "------------------------------------------"
        echo "$(translate "prompt_press_enter")"
        read -r _ < /dev/tty # 强制从 /dev/tty 读取
    done
}

# 处理命令行参数 (此循环用于处理参数，应保留)
while [ $# -gt 0 ]; do
    case "$1" in
        --lang) shift 2 ;; # 语言参数已在初始 detect_language "$@" 中处理，此处仅消费参数
        *) shift ;;
    esac
done

# 捕获中断信号
trap 'log "$(translate "script_interrupted")"; echo "$(translate "script_interrupted")"; exit 1' INT TERM

# 启动脚本
log "$(translate "starting_manager")"
main_menu
