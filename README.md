星际迷航：信号解码 (StarSignalDecoder)

星际迷航：信号解码 是一款开源的终端解谜游戏，带你化身星际飞船信号官，在命令行中挑战危机四伏的星域！通过解码随机信号，修复导航系统，收集能量核心逃离险境。游戏融合科幻剧情、彩色 ASCII 艺术、随机事件、技能系统和双人模式，每一局都让你心跳加速！
StarSignalDecoder is an open-source terminal puzzle game where you play as a starship signal officer. Decode signals to repair the navigation system and escape a perilous starfield. With sci-fi storytelling, colorful ASCII art, random events, a skill system, and local co-op, every round is a thrilling adventure!
特色 (Features)

版本选择：安装稳定版或开发版，体验最新功能。
存档与记录：保存游戏进度，记录最高分和通关次数。
沉浸式剧情：NPC 对话、随机事件（干扰、奖励）、多结局（英雄/幸存）。
精致界面：彩色输出（需 colorama）、动态波形、交互式提示（按 H）。
创新玩法：
信号强度（弱/中/强）影响难度和奖励。
技能系统：升级解码速度和能量恢复。
本地双人模式：轮流解码，合作逃离。


易上手：新手模式、强制教程（--tutorial）、玩法预览 GIF。
跨平台：仅需 Python 3，兼容 Linux、Windows、macOS。

玩法预览 (Gameplay Preview)

想知道怎么玩？看这个 GIF！解码信号，收集核心，体验星际冒险！
安装 (Installation)
选择版本

稳定版（推荐，main 分支）：pip3 install git+https://github.com/bbb-lsy07/StarSignalDecoder.git@main


开发版（最新功能，可能不稳定，dev 分支）：pip3 install git+https://github.com/bbb-lsy07/StarSignalDecoder.git@dev



要求 (Requirements):

Python 3.6 或更高版本（运行 python3 --version 检查）。
可选：彩色输出需安装 colorama：pip3 install colorama


无其他依赖，安装即玩！

遇到问题 (Troubleshooting)?  

提示 pip: command not found？先安装 pip：
Ubuntu/Debian：sudo apt update
sudo apt install python3 python3-pip -y


CentOS/RHEL：sudo yum install python3 python3-pip -y


macOS（使用 Homebrew）：brew install python3


Windows：下载 Python 安装包，确保勾选“Add Python to PATH”。


提示 starsignal: command not found？脚本未加入 PATH：export PATH=$PATH:/root/.local/bin

永久生效：echo 'export PATH=$PATH:/root/.local/bin' >> ~/.bashrc
source ~/.bashrc


网络问题？确保能访问 GitHub（ping github.com）。若失败，检查 DNS：echo "nameserver 8.8.8.8" >> /etc/resolv.conf

或设置代理：export http_proxy=http://your-proxy:port
export https_proxy=http://your-proxy:port



Install with one command:

Stable (main branch):pip3 install git+https://github.com/bbb-lsy07/StarSignalDecoder.git@main


Development (dev branch):pip3 install git+https://github.com/bbb-lsy07/StarSignalDecoder.git@dev



Requirements:

Python 3.6+ (check with python3 --version).
Optional: Install colorama for colored output:pip3 install colorama



Troubleshooting:

See pip: command not found? Install pip:
Ubuntu/Debian:sudo apt update
sudo apt install python3 python3-pip -y


CentOS/RHEL:sudo yum install python3 python3-pip -y


macOS (with Homebrew):brew install python3


Windows: Ensure Python is installed with PATH enabled.


See starsignal: command not found? Add scripts to PATH:export PATH=$PATH:/root/.local/bin

Persist:echo 'export PATH=$PATH:/root/.local/bin' >> ~/.bashrc
source ~/.bashrc


Network issues? Verify GitHub access (ping github.com). If failing, update DNS:echo "nameserver 8.8.8.8" >> /etc/resolv.conf



使用 (Usage)
安装后，运行以下命令启动游戏：
starsignal

命令选项 (Command Options)

--difficulty {easy,medium,hard}：选择难度（默认：easy）
easy：60秒，3选项，新手友好
medium：45秒，4选项，适中挑战
hard：30秒，5选项，高手专属


--tutorial：强制显示教程，适合新手
--load FILE：加载存档（例如：save.json）
--version：显示当前版本号
--help：查看帮助信息

示例 (Example)
运行中等难度并加载存档：
starsignal --difficulty medium --load save.json

输出示例：
╔══════════════════════════════════════╗
║    星际迷航：信号解码              ║
╚══════════════════════════════════════╝
欢迎，信号官！你的飞船被困在危险星域！

接收到新信号（强度：中）：
  █       █  
    █   █   
█   █   █   █
信号：3#5*2
规则：忽略所有非数字字符
1. 253
2. 523
3. 532
4. 235
飞船能量：100% | 得分：0 | 能量核心：0
任务进度：[▒] 0/3
NPC: '保持冷静，我们一定能逃出去！'
请输入选项编号（1-4）、's' 保存、'h' 提示、'q' 退出：2
信号解码成功！飞船前进！
故事进展：飞船检测到微弱信号，导航系统开始响应！

玩法说明 (How to Play)

启动游戏：运行 starsignal，首次进入显示教程（或用 --tutorial）。
解码信号：根据信号（如 3#5*2）和规则（如“忽略非数字字符”），输入选项编号（如 1）。
目标：在时间限制内收集 3 个能量核心逃离星域。
操作：
s：保存进度（生成 JSON 文件）。
h：显示提示（规则说明）。
q：退出游戏。


注意：
答错或超时减能量，能量 ≤ 0 游戏结束。
信号强度（弱/中/强）影响难度和奖励。
随机事件（干扰、故障、奖励）增加挑战。


双人模式：启动时选择，玩家轮流解码，共享飞船状态。

存档与记录 (Save & Records)

存档：游戏中输入 s，保存进度到指定 JSON 文件（默认：save.json）。
加载：用 --load save.json 恢复进度。
记录：最高分和通关次数保存在 ~/.starsignal_data.json，每次游戏更新。

卸载 (Uninstallation)
卸载 StarSignalDecoder：
pip3 uninstall starsignal


输入 y 确认。
验证：pip3 show starsignal 无输出。

Uninstall:
pip3 uninstall starsignal


Confirm with y.
Verify: pip3 show starsignal should show no output.

更新 (Updating)
获取最新版本（稳定版）：
pip3 install --force-reinstall git+https://github.com/bbb-lsy07/StarSignalDecoder.git@main


开发版：pip3 install --force-reinstall git+https://github.com/bbb-lsy07/StarSignalDecoder.git@dev


检查：pip3 show starsignal。
测试：starsignal --difficulty easy。

Update:
pip3 install --force-reinstall git+https://github.com/bbb-lsy07/StarSignalDecoder.git@main


Development branch:pip3 install --force-reinstall git+https://github.com/bbb-lsy07/StarSignalDecoder.git@dev


Check: pip3 show starsignal.
Test: starsignal --difficulty easy.

开发 (Development)
想加点新玩法？按以下步骤：

克隆仓库：
git clone https://github.com/bbb-lsy07/StarSignalDecoder.git
cd StarSignalDecoder


安装开发模式：
pip3 install -e .


运行游戏：
python3 -m starsignal.cli



贡献指南 (Contributing):

在 Issues 提建议或问题。
Fork 仓库，提交 Pull Request，欢迎新规则、剧情或功能！
推荐改进：
新规则：如“数字平方”或“替换字符”。
多人在线模式：通过 WebSocket 联网对战。
终端音效：用 beep 模拟信号声。



常见问题 (FAQ)
Q: 为什么运行 starsignal 提示 command not found？A: 检查：

Python 版本：python3 --version（需 3.6+）。
安装状态：pip3 show starsignal。
PATH：export PATH=$PATH:/root/.local/bin。
重新安装：pip3 install git+https://github.com/bbb-lsy07/StarSignalDecoder.git@main。

Q: 遇到 pip: command not found 怎么办？A: 安装 pip：
sudo apt update
sudo apt install python3-pip -y

Q: 游戏卡顿或崩溃怎么办？A: 确保终端支持 UTF-8（Linux 默认支持）。若问题持续，提交 Issues。
Q: 如何保存和加载进度？A: 游戏中按 s 保存，启动时用 --load save.json 加载。
Q: 可以加什么新功能？A: 欢迎创意！如：

动态天气：影响信号强度。
装备系统：解锁解码工具。
剧情分支：根据选择改变结局。

许可证 (License)
本项目采用 MIT 许可证，可自由使用、修改和分发。
This project is licensed under the MIT License, free to use, modify, and distribute.
联系 (Contact)

作者：bbb-lsy07
邮箱：lisongyue0125@163.com
GitHub：https://github.com/bbb-lsy07
博客：https://i.bbb-lsy07.sbs/

感谢体验 星际迷航：信号解码！快来解码信号，开启星际冒险吧！Thank you for trying StarSignalDecoder! Decode signals and embark on your interstellar adventure!
