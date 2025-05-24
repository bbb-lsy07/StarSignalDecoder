# 星际迷航：信号解码 (StarSignalDecoder)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3](https://img.shields.io/badge/Python-3-blue.svg)](https://www.python.org/)
[![Version](https://img.shields.io/badge/Version-0.2.0-green.svg)](https://github.com/bbb-lsy07/StarSignalDecoder/releases)

**星际迷航：信号解码** 是一款开源的终端解谜游戏，带你化身星际飞船信号官，在命令行中挑战危机四伏的星域！通过解码随机信号，修复导航系统，收集能量核心逃离险境。游戏融合科幻剧情、彩色 ASCII 艺术、随机事件、技能系统和双人模式，每一局都让你心跳加速！

**StarSignalDecoder** is an open-source terminal puzzle game where you play as a starship signal officer. Decode signals to repair the navigation system and escape a perilous starfield. With sci-fi storytelling, colorful ASCII art, random events, a skill system, and local co-op, every round is a thrilling adventure!

## 特色 (Features)

- **版本选择**：安装稳定版或开发版，体验最新功能。
- **存档与记录**：保存游戏进度，记录最高分和通关次数。
- **沉浸式剧情**：NPC 对话、随机事件（干扰、奖励）、多结局（英雄/幸存）。
- **精致界面**：彩色输出（需 <kbd>colorama</kbd>）、动态波形、交互式提示（按 <kbd>H</kbd>）。
- **创新玩法**：
  - 信号强度（弱/中/强）影响难度和奖励。
  - 技能系统：升级解码速度和能量恢复。
  - 本地双人模式：轮流解码，合作逃离。
- **易上手**：新手模式、强制教程（<kbd>--tutorial</kbd>）、玩法预览 GIF。
- **跨平台**：仅需 Python 3，兼容 Linux、Windows、macOS。

## 玩法预览 (Gameplay Preview)

![Gameplay GIF](https://images.bbb-lsy07.my/starsignal_preview.gif)

想知道怎么玩？看这个 GIF！解码信号，收集核心，体验星际冒险！

## 安装 (Installation)

### 选择版本
- **稳定版**（推荐，<kbd>main</kbd> 分支）：
  ```bash
  pip3 install git+https://github.com/bbb-lsy07/StarSignalDecoder.git@main
  ```
- **开发版**（最新功能，可能不稳定，<kbd>dev</kbd> 分支）：
  ```bash
  pip3 install git+https://github.com/bbb-lsy07/StarSignalDecoder.git@dev
  ```

**要求 (Requirements)**:
- Python 3.6 或更高版本（运行 <kbd>python3 --version</kbd> 检查）。
- 可选：彩色输出需安装 <kbd>colorama</kbd>：
  ```bash
  pip3 install colorama
  ```
- 无其他依赖，安装即玩！

**遇到问题 (Troubleshooting)?**  
- **提示 <kbd>pip: command not found</kbd>**？先安装 `pip`：
  - **Ubuntu/Debian**：
    ```bash
    sudo apt update
    sudo apt install python3 python3-pip -y
    ```
  - **CentOS/RHEL**：
    ```bash
    sudo yum install python3 python3-pip -y
    ```
  - **macOS**（使用 Homebrew）：
    ```bash
    brew install python3
    ```
  - **Windows**：下载 Python 安装包，确保勾选“Add Python to PATH”。
- **提示 <kbd>starsignal: command not found</kbd>**？脚本未加入 PATH：
  ```bash
  export PATH=$PATH:/root/.local/bin
  ```
  永久生效：
  ```bash
  echo 'export PATH=$PATH:/root/.local/bin' >> ~/.bashrc
  source ~/.bashrc
  ```
- **网络问题**？确保能访问 GitHub（<kbd>ping github.com</kbd>）。若失败，检查 DNS：
  ```bash
  echo "nameserver 8.8.8.8" >> /etc/resolv.conf
  ```
  或设置代理：
  ```bash
  export http_proxy=http://your-proxy:port
  export https_proxy=http://your-proxy:port
  ```

**Install with one command**:

- **Stable (main branch)**:
  ```bash
  pip3 install git+https://github.com/bbb-lsy07/StarSignalDecoder.git@main
  ```
- **Development (dev branch)**:
  ```bash
  pip3 install git+https://github.com/bbb-lsy07/StarSignalDecoder.git@dev
  ```

**Requirements**:
- Python 3.6+ (check with <kbd>python3 --version</kbd>).
- Optional: Install <kbd>colorama</kbd> for colored output:
  ```bash
  pip3 install colorama
  ```

**Troubleshooting**:
- **See <kbd>pip: command not found</kbd>**? Install `pip`:
  - **Ubuntu/Debian**:
    ```bash
    sudo apt update
    sudo apt install python3 python3-pip -y
    ```
  - **CentOS/RHEL**:
    ```bash
    sudo yum install python3 python3-pip -y
    ```
  - **macOS** (with Homebrew):
    ```bash
    brew install python3
    ```
  - **Windows**: Ensure Python is installed with PATH enabled.
- **See <kbd>starsignal: command not found</kbd>**? Add scripts to PATH:
  ```bash
  export PATH=$PATH:/root/.local/bin
  ```
  Persist:
  ```bash
  echo 'export PATH=$PATH:/root/.local/bin' >> ~/.bashrc
  source ~/.bashrc
  ```
- **Network issues**? Verify GitHub access (<kbd>ping github.com</kbd>). If failing, update DNS:
  ```bash
  echo "nameserver 8.8.8.8" >> /etc/resolv.conf
  ```

## 使用 (Usage)

安装后，运行以下命令启动游戏：

```bash
starsignal
```

### 命令选项 (Command Options)

- `--difficulty {easy,medium,hard}`：选择难度（默认：<kbd>easy</kbd>）
  - <kbd>easy</kbd>：60秒，3选项，新手友好
  - <kbd>medium</kbd>：45秒，4选项，适中挑战
  - <kbd>hard</kbd>：30秒，5选项，高手专属
- `--tutorial`：强制显示教程，适合新手
- `--load FILE`：加载存档（例如：<kbd>save.json</kbd>）
- `--version`：显示当前版本号
- `--help`：查看帮助信息

### 示例 (Example)

运行中等难度并加载存档：

```bash
starsignal --difficulty medium --load save.json
```

输出示例：

```
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
```

## 玩法说明 (How to Play)

1. **启动游戏**：运行 <kbd>starsignal</kbd>，首次进入显示教程（或用 <kbd>--tutorial</kbd>）。
2. **解码信号**：根据信号（如 <kbd>3#5*2</kbd>）和规则（如“忽略非数字字符”），输入选项编号（如 <kbd>1</kbd>）。
3. **目标**：在时间限制内收集 3 个能量核心逃离星域。
4. **操作**：
   - <kbd>s</kbd>：保存进度（生成 JSON 文件）。
   - <kbd>h</kbd>：显示提示（规则说明）。
   - <kbd>q</kbd>：退出游戏。
5. **注意**：
   - 答错或超时减能量，能量 ≤ 0 游戏结束。
   - 信号强度（弱/中/强）影响难度和奖励。
   - 随机事件（干扰、故障、奖励）增加挑战。
6. **双人模式**：启动时选择，玩家轮流解码，共享飞船状态。

## 存档与记录 (Save & Records)

- **存档**：游戏中输入 <kbd>s</kbd>，保存进度到指定 JSON 文件（默认：<kbd>save.json</kbd>）。
- **加载**：用 <kbd>--load save.json</kbd> 恢复进度。
- **记录**：最高分和通关次数保存在 <kbd>~/.starsignal_data.json</kbd>，每次游戏更新。

## 卸载 (Uninstallation)

卸载 <span class="p cyan">StarSignalDecoder</span>：

```bash
pip3 uninstall starsignal
```

- 输入 <kbd>y</kbd> 确认。
- 验证：<kbd>pip3 show starsignal</kbd> 无输出。

**Uninstall**:

```bash
pip3 uninstall starsignal
```

- Confirm with <kbd>y</kbd>.
- Verify: <kbd>pip3 show starsignal</kbd> should show no output.

## 更新 (Updating)

获取最新版本（稳定版）：

```bash
pip3 install --force-reinstall git+https://github.com/bbb-lsy07/StarSignalDecoder.git@main
```

- 开发版：
  ```bash
  pip3 install --force-reinstall git+https://github.com/bbb-lsy07/StarSignalDecoder.git@dev
  ```
- 检查：<kbd>pip3 show starsignal</kbd>。
- 测试：<kbd>starsignal --difficulty easy</kbd>。

**Update**:

```bash
pip3 install --force-reinstall git+https://github.com/bbb-lsy07/StarSignalDecoder.git@main
```

- Development branch:
  ```bash
  pip3 install --force-reinstall git+https://github.com/bbb-lsy07/StarSignalDecoder.git@dev
  ```
- Check: <kbd>pip3 show starsignal</kbd>.
- Test: <kbd>starsignal --difficulty easy</kbd>.

## 开发 (Development)

想加点新玩法？按以下步骤：

1. **克隆仓库**：
   ```bash
   git clone https://github.com/bbb-lsy07/StarSignalDecoder.git
   cd StarSignalDecoder
   ```

2. **安装开发模式**：
   ```bash
   pip3 install -e .
   ```

3. **运行游戏**：
   ```bash
   python3 -m starsignal.cli
   ```

**贡献指南 (Contributing)**:
- 在 [Issues](https://github.com/bbb-lsy07/StarSignalDecoder/issues) 提建议或问题。
- Fork 仓库，提交 Pull Request，欢迎新规则、剧情或功能！
- 推荐改进：
  - 新规则：如“数字平方”或“替换字符”。
  - 多人在线模式：通过 WebSocket 联网对战。
  - 终端音效：用 <kbd>beep</kbd> 模拟信号声。

## 常见问题 (FAQ)

**Q: 为什么运行 <kbd>starsignal</kbd> 提示 <kbd>command not found</kbd>？**  
A: 检查：
- Python 版本：<kbd>python3 --version</kbd>（需 3.6+）。
- 安装状态：<kbd>pip3 show starsignal</kbd>。
- PATH：<kbd>export PATH=$PATH:/root/.local/bin</kbd>。
- 重新安装：<kbd>pip3 install git+https://github.com/bbb-lsy07/StarSignalDecoder.git@main</kbd>。

**Q: 遇到 <kbd>pip: command not found</kbd> 怎么办？**  
A: 安装 `pip`：
```bash
sudo apt update
sudo apt install python3-pip -y
```

**Q: 游戏卡顿或崩溃怎么办？**  
A: 确保终端支持 UTF-8（Linux 默认支持）。若问题持续，提交 [Issues](https://github.com/bbb-lsy07/StarSignalDecoder/issues)。

**Q: 如何保存和加载进度？**  
A: 游戏中按 <kbd>s</kbd> 保存，启动时用 <kbd>--load save.json</kbd> 加载。

**Q: 可以加什么新功能？**  
A: 欢迎创意！如：
- 动态天气：影响信号强度。
- 装备系统：解锁解码工具。
- 剧情分支：根据选择改变结局。

## 许可证 (License)

本项目采用 [MIT 许可证](LICENSE)，可自由使用、修改和分发。

This project is licensed under the [MIT License](LICENSE), free to use, modify, and distribute.

## 联系 (Contact)

- **作者**：bbb-lsy07
- **邮箱**：lisongyue0125@163.com
- **GitHub**：https://github.com/bbb-lsy07
- **博客**：https://i.bbb-lsy07.sbs/

感谢体验 <span class="p cyan">星际迷航：信号解码</span>！快来解码信号，开启星际冒险吧！  
Thank you for trying <span class="p cyan">StarSignalDecoder</span>! Decode signals and embark on your interstellar adventure!
