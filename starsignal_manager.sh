#!/bin/bash

# 脚本信息
echo "StarSignalDecoder 管理脚本"
echo "================================="
echo "1. 安装 StarSignalDecoder"
echo "2. 卸载 StarSignalDecoder"
echo "3. 更新 StarSignalDecoder"
echo "4. 修复安装"
echo "5. 启动 StarSignalDecoder"
echo "6. 退出"
echo "================================="

# 检查和安装依赖的函数
check_dependencies() {
    # 检查 Python 3.6+
    if ! command -v python3 >/dev/null 2>&1 || ! python3 -c "import sys; assert sys.version_info >= (3, 6)" >/dev/null 2>&1; then
        echo "未安装 Python 3.6+。"
        read -p "是否安装 Python 3？(y/n): " install_python
        if [ "$install_python" = "y" ]; then
            sudo apt-get update
            sudo apt-get install -y python3
        else
            echo "需要 Python 3.6+，退出。"
            exit 1
        fi
    fi

    # 检查 pip
    if ! command -v pip3 >/dev/null 2>&1; then
        echo "未安装 pip3。"
        read -p "是否安装 pip3？(y/n): " install_pip
        if [ "$install_pip" = "y" ]; then
            sudo apt-get install -y python3-pip
        else
            echo "需要 pip3，退出。"
            exit 1
        fi
    fi

    # 检查 git
    if ! command -v git >/dev/null 2>&1; then
        echo "未安装 git。"
        read -p "是否安装 git？(y/n): " install_git
        if [ "$install_git" = "y" ]; then
            sudo apt-get update
            sudo apt-get install -y git
        else
            echo "需要 git，退出。"
            exit 1
        fi
    fi
}

# 安装 StarSignalDecoder 的函数
install_starsignaldecoder() {
    check_dependencies
    echo "选择安装类型："
    echo "1. 稳定版（推荐）"
    echo "2. 开发版（最新功能）"
    read -p "请输入选择 (1 或 2): " install_choice
    if [ "$install_choice" = "1" ]; then
        pip3 install --user git+https://github.com/bbb-lsy07/StarSignalDecoder.git@main
    elif [ "$install_choice" = "2" ]; then
        pip3 install --user git+https://github.com/bbb-lsy07/StarSignalDecoder.git@dev
    else
        echo "无效选择，退出。"
        exit 1
    fi
    # 安装 colorama 以启用彩色输出
    pip3 install --user colorama
    echo "安装完成。"
}

# 卸载 StarSignalDecoder 的函数
uninstall_starsignaldecoder() {
    pip3 uninstall -y StarSignalDecoder colorama
    echo "卸载完成。"
}

# 更新 StarSignalDecoder 的函数
update_starsignaldecoder() {
    echo "正在更新 StarSignalDecoder..."
    pip3 install --user --upgrade git+https://github.com/bbb-lsy07/StarSignalDecoder.git@main
    pip3 install --user --upgrade colorama
    echo "更新完成。"
}

# 修复安装的函数
repair_starsignaldecoder() {
    check_dependencies
    echo "正在修复 StarSignalDecoder 安装..."
    pip3 install --user --force-reinstall git+https://github.com/bbb-lsy07/StarSignalDecoder.git@main
    pip3 install --user --force-reinstall colorama
    echo "修复完成。"
}

# 启动 StarSignalDecoder 的函数
start_starsignaldecoder() {
    echo "正在启动 StarSignalDecoder..."
    echo "可用选项："
    echo "--difficulty {easy,medium,hard,challenge}：设置难度"
    echo "  easy：60秒，3选项，能量损失少"
    echo "  medium：45秒，4选项，能量损失中等"
    echo "  hard：30秒，5选项，能量损失高"
    echo "  challenge：40秒，4选项，随机规则，能量损失中等"
    echo "--tutorial：强制显示交互式教程（支持跳过）"
    echo "--practice：进入练习模式（无能量惩罚）"
    echo "--load {1,2,3}：加载指定存档槽位（1-3）"
    echo "--version：显示当前版本（v0.7.1）"
    echo "--help：查看帮助信息"
    read -p "请输入命令选项（或直接回车以无选项运行）： " options
    starsignal $options
}

# 主菜单逻辑
read -p "请输入您的选择 (1-6): " choice
case $choice in
    1)
        install_starsignaldecoder
        ;;
    2)
        uninstall_starsignaldecoder
        ;;
    3)
        update_starsignaldecoder
        ;;
    4)
        repair_starsignaldecoder
        ;;
    5)
        start_starsignaldecoder
        ;;
    6)
        echo "退出。"
        exit 0
        ;;
    *)
        echo "无效选择，退出。"
        exit 1
        ;;
esac
