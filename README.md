# 星际迷航：信号解码 (StarSignalDecoder)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3](https://img.shields.io/badge/Python-3-blue.svg)](https://www.python.org/)
[![Version](https://img.shields.io/badge/Version-0.5.0-green.svg)](https://github.com/bbb-lsy07/StarSignalDecoder/releases)

**星际迷航：信号解码** 是一款开源终端解谜游戏，化身星际信号官，挑战未知星域！通过 3 个关卡，解码信号，击败 Boss，收集核心逃离危机。融合科幻剧情、彩色 ASCII 艺术、关卡选择、无尽模式、多存档槽位和排行榜，带来沉浸冒险！

**StarSignalDecoder** is an open-source terminal puzzle game. As a starship signal officer, conquer 3 levels, decode signals, defeat Bosses, and escape a perilous starfield with sci-fi storytelling, colorful ASCII art, level selection, endless mode, multiple save slots, and leaderboards!

## 特色 (Features)

- **版本选择**：稳定版（`main`）或开发版（`dev`）。
- **关卡挑战**：3 个关卡，Boss 信号，每关核心目标（1/2/3）。
- **存档与成就**：3 槽位存档，解锁成就（“完美通关”），排行榜前 5。
- **沉浸剧情**：NPC 任务、随机事件（风暴、商人）、多结局。
- **精致界面**：彩色输出（需 <kbd>colorama</kbd>）、动态波形、能量警告。
- **创新玩法**：
  - **关卡选择**：解锁关卡或继续进度。
  - **动态天气**：风暴、迷雾影响难度。
  - **装备系统**：星际商店购买“信号放大器”。
  - **无尽模式**：通关解锁，挑战极限。
  - **双人协作**：连携加成提升得分。
- **易上手**：练习模式、交互教程、玩法预览 GIF。

## 玩法预览 (Gameplay Preview)

![Gameplay GIF](https://images.bbb-lsy07.my/starsignal_preview.gif)

解码信号，挑战 Boss，解锁无尽模式！看 GIF 秒懂！

## 安装 (Installation)

### 选择版本
- **稳定版**（推荐）：
  ```bash
  pip3 install --user git+https://github.com/bbb-lsy07/StarSignalDecoder.git@main
  ```
- **开发版**（最新功能）：
  ```bash
  pip3 install --user git+https://github.com/bbb-lsy07/StarSignalDecoder.git@dev
  ```

**要求**:
- Python 3.6+（<kbd>python3 --version</kbd>）。
- 可选：<kbd>pip3 install --user colorama</kbd>（彩色输出）。

**问题解决**:
- **<kbd>pip: command not found</kbd>**：
  ```bash
  sudo apt update
  sudo apt install python3-pip -y
  ```
  或：
  ```bash
  python3 -m ensurepip --upgrade
  python3 -m pip install --upgrade pip
  ```
- **<kbd>starsignal: command not found</kbd>**：
  ```bash
  export PATH=$PATH:/root/.local/bin
  echo 'export PATH=$PATH:/root/.local/bin' >> ~/.bashrc
  source ~/.bashrc
  ```
- **存档权限**：
  ```bash
  chmod 666 ~/.starsignal*
  ```
- **网络问题**：
  ```bash
  ping github.com
  echo "nameserver 8.8.8.8" >> /etc/resolv.conf
  ```

## 使用 (Usage)

```bash
starsignal
```

### 命令选项
- `--difficulty {easy,medium,hard,challenge}`：难度（`challenge` 随机规则）。
- `--tutorial`：教程。
- `--practice`：练习模式（无惩罚）。
- `--load SLOT`：加载存档（1-3）。
- `--endless`：无尽模式（通关解锁）。
- `--version`：版本。
- `--help`：帮助。

### 示例

```bash
starsignal --difficulty challenge --load 1
```

输出：

```
╔══════════════════════════════════════╗
║    星际迷航：信号解码              ║
╚══════════════════════════════════════╝
选择模式：
1) 新游戏（关卡 1）
2) 继续（关卡 2）
3) 选择关卡（已解锁：1）
4) 无尽模式（未解锁）
请输入（1-4）：2
关卡 2 | 天气：风暴 | 装备：信号放大器
NPC任务：连续解码 3 次强信号！
信号（强度：强）：
  █   █   █  
█ █ █ █ █ █ 
信号：3#5*2
规则：仅保留偶数数字
1. 2
2. 35
3. 52
能量：80% | 得分：50 | 核心：0/2
请输入（1-3，s 保存，h 提示，q 退出）：1
解码成功！核心 +1！
```

## 玩法说明 (How to Play)

1. **启动**：运行 <kbd>starsignal</kbd>，选择模式（新游戏/继续/关卡）。
2. **关卡**：通过 3 关，每关收集核心（1/2/3），击败 Boss 信号。
3. **解码**：根据信号和规则，选择正确选项（<kbd>1</kbd>）。
4. **目标**：完成关卡，保持能量 ≥ 60%，达成高分。
5. **操作**：
   - <kbd>s</kbd>：保存（槽位 1-3）。
   - <kbd>h</kbd>：提示。
   - <kbd>q</kbd>：退出。
6. **特色**：
   - **关卡选择**：解锁后直达关卡。
   - **天气**：风暴减时间，迷雾加选项。
   - **商店**：购买装备或能量。
   - **无尽模式**：信号难度递增。
   - **排行榜**：前 5 高分。

## 存档与成就

- **存档**：按 <kbd>s</kbd>，选择槽位 1-3，保存至 <kbd>~/.starsignal_save_X.json</kbd>。
- **成就**：保存在 <kbd>~/.starsignal_data.json</kbd>，如“Boss 终结者”。
- **排行榜**：前 5 高分，含关卡和模式。

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
- 联网对战：WebSocket。
- 音效：终端“滴滴”声。

## 常见问题

**Q: 存档无法加载？**  
A: 检查权限：
```bash
ls -l ~/.starsignal*
chmod 666 ~/.starsignal*
```

**Q: 波形异常？**  
A: 确保终端支持 UTF-8：
```bash
echo $LANG
```

## 许可证

[MIT 许可证](LICENSE)

## 联系

- **作者**：bbb-lsy07
- **邮箱**：lisongyue0125@163.com
- **GitHub**：https://github.com/bbb-lsy07
- **博客**：https://i.bbb-lsy07.sbs/

感谢体验 <span class="p cyan">星际迷航：信号解码</span>！挑战星际，铸就传奇！
