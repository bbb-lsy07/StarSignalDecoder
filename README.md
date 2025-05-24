# 星际迷航：信号解码 (StarSignalDecoder)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3](https://img.shields.io/badge/Python-3-blue.svg)](https://www.python.org/)
[![Version](https://img.shields.io/badge/Version-0.3.0-green.svg)](https://github.com/bbb-lsy07/StarSignalDecoder/releases)

**星际迷航：信号解码** 是一款开源终端解谜游戏，带你化身星际信号官，在命令行中挑战未知星域！解码信号，修复飞船，逃离危机。游戏融合科幻剧情、彩色 ASCII 艺术、随机天气、成就系统和装备解锁，每局都充满惊喜！

**StarSignalDecoder** is an open-source terminal puzzle game where you play as a starship signal officer. Decode signals to escape a perilous starfield with sci-fi storytelling, colorful ASCII art, dynamic weather, achievements, and unlockable gear!

## 特色 (Features)

- **版本选择**：稳定版（`main`）或开发版（`dev`）。
- **存档与成就**：保存进度，解锁成就（如“快速解码者”），记录最高分。
- **沉浸剧情**：NPC 对话、随机事件（风暴、奖励）、多结局。
- **精致界面**：彩色输出（需 <kbd>colorama</kbd>）、动态波形、信号闪烁。
- **创新玩法**：
  - **动态天气**：晴朗、风暴、迷雾影响信号和难度。
  - **装备系统**：解锁“信号放大器”等，提升解码效率。
  - **挑战模式**：随机规则（如“仅偶数”），增加多样性。
  - **双人模式**：本地合作，共享飞船状态。
- **易上手**：练习模式、交互教程、玩法预览 GIF。

## 玩法预览 (Gameplay Preview)

![Gameplay GIF](https://images.bbb-lsy07.my/starsignal_preview.gif)

秒懂玩法！解码信号，收集核心，解锁装备，挑战星际冒险！

## 安装 (Installation)

### 选择版本
- **稳定版**（推荐，<kbd>main</kbd> 分支）：
  ```bash
  pip3 install --user git+https://github.com/bbb-lsy07/StarSignalDecoder.git@main
  ```
- **开发版**（最新功能，<kbd>dev</kbd> 分支）：
  ```bash
  pip3 install --user git+https://github.com/bbb-lsy07/StarSignalDecoder.git@dev
  ```

**要求 (Requirements)**:
- Python 3.6+（<kbd>python3 --version</kbd>）。
- 可选：<kbd>pip3 install --user colorama</kbd>（彩色输出）。

**遇到问题 (Troubleshooting)?**  
- **提示 <kbd>pip: command not found</kbd>**？安装 `pip`：
  ```bash
  sudo apt update
  sudo apt install python3-pip -y
  ```
  或使用：
  ```bash
  python3 -m ensurepip --upgrade
  python3 -m pip install --upgrade pip
  ```
- **提示 <kbd>starsignal: command not found</kbd>**？添加 PATH：
  ```bash
  export PATH=$PATH:/root/.local/bin
  echo 'export PATH=$PATH:/root/.local/bin' >> ~/.bashrc
  source ~/.bashrc
  ```
- **网络问题**？检查 GitHub 连接：
  ```bash
  ping github.com
  ```
  若失败，设置 DNS：
  ```bash
  echo "nameserver 8.8.8.8" >> /etc/resolv.conf
  ```

**Install**:
- Stable:
  ```bash
  pip3 install --user git+https://github.com/bbb-lsy07/StarSignalDecoder.git@main
  ```
- Development:
  ```bash
  pip3 install --user git+https://github.com/bbb-lsy07/StarSignalDecoder.git@dev
  ```

## 使用 (Usage)

```bash
starsignal
```

### 命令选项
- `--difficulty {easy,medium,hard,challenge}`：难度（`challenge` 为随机规则）
- `--tutorial`：显示教程
- `--load FILE`：加载存档
- `--practice`：练习模式（无惩罚）
- `--version`：显示版本
- `--help`：帮助

### 示例

```bash
starsignal --difficulty challenge --tutorial
```

输出：

```
╔══════════════════════════════════════╗
║    星际迷航：信号解码              ║
╚══════════════════════════════════════╝
天气：风暴 | 装备：信号放大器
NPC: '风暴干扰信号，时间更紧张！'
接收到新信号（强度：强）：
  █   █   █  
█   █ █ █ █ 
█ █ █ █ █ █ 
信号：3#5*2
规则：仅保留偶数数字
1. 52
2. 35
3. 2
飞船能量：100% | 得分：0 | 核心：0
进度：[▒▒▒] 0/3
请输入（1-3，s 保存，h 提示，q 退出）：3
解码成功！获得核心！
```

## 玩法说明 (How to Play)

1. **启动**：运行 <kbd>starsignal</kbd>，首次显示教程。
2. **解码**：根据信号和规则，选择正确选项（<kbd>1</kbd>）。
3. **目标**：收集 3 个能量核心。
4. **操作**：
   - <kbd>s</kbd>：保存（<kbd>save.json</kbd>）。
   - <kbd>h</kbd>：提示。
   - <kbd>q</kbd>：退出。
5. **特色**：
   - **天气**：风暴减时间，迷雾加选项。
   - **装备**：用得分兑换，提升解码。
   - **成就**：如“解码 10 次不失误”。

## 存档与成就

- **存档**：按 <kbd>s</kbd> 保存至 JSON。
- **成就**：保存在 <kbd>~/.starsignal_data.json</kbd>，如“双人传奇”。
- **记录**：最高分、通关次数、装备状态。

## 卸载

```bash
pip3 uninstall starsignal
```

## 更新

```bash
pip3 install --user --force-reinstall git+https://github.com/bbb-lsy07/StarSignalDecoder.git@main
```

## 开发

1. 克隆：
   ```bash
   git clone https://github.com/bbb-lsy07/StarSignalDecoder.git
   cd StarSignalDecoder
   ```
2. 安装：
   ```bash
   pip3 install --user -e .
   ```
3. 运行：
   ```bash
   python3 -m starsignal.cli
   ```

**贡献**：
- 新规则：如“数字平方”。
- 联网模式：WebSocket 对战。
- 音效：终端“滴滴”声。

## 常见问题

**Q: 提示 <kbd>pip: command not found</kbd>？**  
A: 安装：
```bash
sudo apt install python3-pip -y
```

**Q: 存档丢失？**  
A: 检查 <kbd>save.json</kbd> 或 <kbd>~/.starsignal_data.json</kbd> 是否可写。

## 许可证

[MIT 许可证](LICENSE)

## 联系

- **作者**：bbb-lsy07
- **邮箱**：lisongyue0125@163.com
- **GitHub**：https://github.com/bbb-lsy07
- **博客**：https://i.bbb-lsy07.sbs/

感谢体验 <span class="p cyan">星际迷航：信号解码</span>！解码信号，挑战星际！
