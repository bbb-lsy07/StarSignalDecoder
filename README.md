# 星际迷航：信号解码

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3](https://img.shields.io/badge/Python-3-blue.svg)](https://www.python.org/)
[![Version](https://img.shields.io/badge/Version-0.7.0-green.svg)](https://github.com/bbb-lsy07/StarSignalDecoder/releases)

**星际迷航：信号解码** 是一款开源终端解谜游戏，让你化身星际信号官，挑战未知星域！通过 3 个关卡，解码信号，击败 Boss，收集核心，最终以 100.0% 能量逃离危机。游戏融合科幻剧情、美观 ASCII 界面、关卡选择、道具解锁、无尽模式和排行榜，带来沉浸式冒险体验！

## 目录

- [游戏特色](#游戏特色)
- [玩法预览](#玩法预览)
- [快速开始](#快速开始)
- [环境准备](#环境准备)
- [手动安装](#手动安装)
- [使用方法](#使用方法)
- [玩法说明](#玩法说明)
- [存档与成就](#存档与成就)
- [更新](#更新)
- [卸载](#卸载)
- [开发指南](#开发指南)
- [故障排除](#故障排除)
- [版本历史](#版本历史)
- [许可证](#许可证)
- [联系方式](#联系方式)

## 游戏特色

- **版本选择**：稳定版（`main`）或开发版（`dev`）。
- **关卡挑战**：3 个关卡，难度递增，包含 Boss 信号，每关需收集核心（1/2/3），最终能量达 100.0% 通关。
- **存档与成就**：支持 3 个存档槽位，解锁成就（如“完美通关”），排行榜展示前 5 高分。
- **沉浸剧情**：包含 NPC 任务、随机事件（风暴、商人），支持多结局（星际传说、险象环生、信号失联）。
- **美观界面**：
  - 动态波形：根据信号长度和强度调整闪烁效果。
  - 能量警告：红色（<30%）、黄色（<80%）、绿色（≥80%）。
  - 动画效果：关卡切换、Boss 出现、商店开启。
- **创新玩法**：
  - **关卡选择**：解锁后可直接进入指定关卡。
  - **道具解锁**：能量电池（+20% 能量）、干扰器（跳过信号）。
  - **动态天气**：风暴（减少 20% 时间）、迷雾（增加 1 个选项）。
  - **无尽模式**：通关后解锁，信号长度无限递增。
  - **双人协作**：连续正确解码触发连携加成（+10 分，+5% 能量）。
- **易上手**：提供练习模式、交互式教程（支持跳过）、玩法预览 GIF。

## 玩法预览

![Gameplay GIF](https://raw.githubusercontent.com/bbb-lsy07/StarSignalDecoder/main/docs/starsignal_preview_v07.gif)

通过解码信号挑战 Boss，解锁无尽模式！观看 GIF，快速了解玩法！

## 快速开始

使用管理脚本（v1.7.1）一键完成安装、更新、修复或卸载，支持 Linux、macOS 和 Windows。

> **注意**：不推荐直接通过 `curl ... | sh` 或 `wget ... | sh` 运行脚本，可能导致输入阻塞（如菜单选项无法响应）。请下载脚本后运行，以确保交互正常。

### Linux/macOS

```bash
# 下载后运行（推荐）
curl -s https://raw.githubusercontent.com/bbb-lsy07/StarSignalDecoder/main/starsignal_manager.sh -o starsignal_manager.sh
chmod +x starsignal_manager.sh
./starsignal_manager.sh
```

### Windows

```powershell
# 下载后运行（推荐，需安装 Git for Windows）
Invoke-WebRequest -Uri https://raw.githubusercontent.com/bbb-lsy07/StarSignalDecoder/main/starsignal_manager.sh -OutFile starsignal_manager.sh
sh starsignal_manager.sh
```

```powershell
# 手动下载后运行
# 1. 下载 starsignal_manager.sh 到本地
# 2. 打开 PowerShell（建议管理员模式）
cd 路径/到/脚本
sh starsignal_manager.sh
```

**语言切换**：

```bash
# 使用英文界面
sh starsignal_manager.sh --lang en
# 默认中文
sh starsignal_manager.sh
```

**功能说明**：
- **未安装**：可选择安装（`main` 或 `dev` 分支）。
- **已安装**：支持更新、修复、清理存档、卸载。
- **环境检查**：自动检测并安装 Python、pip、git，修复 PATH 和权限。

## 环境准备

### 要求
- **Python 3.9+**（推荐）：运行 `python3 --version`（Windows：`python --version`）检查。
- **pip**：Python 包管理工具。
- **git**：用于从 GitHub 下载代码。
- **可选**：安装 `colorama`（>=0.4.6）以启用彩色输出：
  ```bash
  pip3 install --user colorama
  ```

### Linux/macOS

1. **安装 Python**：
   ```bash
   # Ubuntu/Debian
   sudo apt update
   sudo apt install -y python3 python3-dev
   # CentOS/RHEL
   sudo yum install -y python3 python3-devel
   # macOS（使用 Homebrew）
   brew install python3
   ```
2. **安装 pip**：
   ```bash
   python3 -m ensurepip --upgrade
   python3 -m pip install --upgrade pip
   ```
3. **安装 git**：
   ```bash
   # Ubuntu/Debian
   sudo apt install -y git
   # CentOS/RHEL
   sudo yum install -y git
   # macOS
   brew install git
   ```

### Windows

1. **安装 Python**：
   ```powershell
   winget install --id Python.Python.3 --version 3.9.13
   ```
   或从 [Python 官网](https://www.python.org/downloads/) 下载安装。
2. **安装 pip**：
   ```powershell
   python -m ensurepip --upgrade
   python -m pip install --upgrade pip
   ```
3. **安装 git**：
   ```powershell
   winget install --id Git.Git
   ```
   或从 [Git for Windows](https://git-scm.com/download/win) 下载安装。
4. **添加 PATH**：
   ```powershell
   $ScriptsPath = "$env:USERPROFILE\AppData\Roaming\Python\Python39\Scripts"
   [Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path", "User") + ";$ScriptsPath", "User")
   ```

## 手动安装

### Linux/macOS

```bash
# 稳定版（推荐）
pip3 install --user git+https://github.com/bbb-lsy07/StarSignalDecoder.git@main
# 开发版（最新功能）
pip3 install --user git+https://github.com/bbb-lsy07/StarSignalDecoder.git@dev
```

### Windows

```powershell
# 稳定版
pip install --user git+https://github.com/bbb-lsy07/StarSignalDecoder.git@main
# 开发版
pip install --user git+https://github.com/bbb-lsy07/StarSignalDecoder.git@dev
```

## 使用方法

安装完成后，运行以下命令启动游戏：

```bash
starsignal
```

### 命令选项
- `--difficulty {easy,medium,hard,challenge}`：设置难度（`challenge` 为随机规则）。
- `--tutorial`：强制显示交互式教程（支持跳过）。
- `--practice`：进入练习模式（无能量惩罚）。
- `--load {1,2,3}`：加载指定存档槽位（1-3）。
- `--version`：显示当前版本（v0.7.0）。
- `--help`：查看帮助信息。

### 示例

```bash
starsignal --difficulty challenge --practice
```

**输出示例**：

```
╔══════ 模式选择 ══════╗
1) 新游戏（关卡 1）
2) 继续（关卡 2）
3) 选择关卡（已解锁：1,2）
4) 无尽模式（已解锁）
╚═══════════════════════╝
请输入（1-4）：1
╔══════ 关卡 1 | 晴朗 | 装备：无 | 道具：无 ══════╗
NPC任务：无
信号（强度：弱）：
  █ ▒ █
信号：3#5*2
规则：忽略非数字字符
1. 352  2. 35  3. 53
能量：100.0% | 得分：0 | 核心：0/1
进度：[▒] 0/1
╚═══════════════════════════════════════════════╝
请输入（1-3，s 保存，h 提示，i 使用道具，q 退出）：1
解码成功！核心 +1！
```

## 玩法说明

1. **启动游戏**：
   - 运行 `starsignal`，选择模式：新游戏、继续、关卡选择或无尽模式。
2. **关卡目标**：
   - 完成 3 个关卡，每关收集核心（1/2/3），击败 Boss，恢复能量至 100.0%.
3. **信号解码**：
   - 根据屏幕显示的信号和规则，从选项中选择正确答案（输入编号，如 `1`）。
4. **游戏目标**：
   - 通关 3 个关卡，保持 100.0% 能量，追求高分。
5. **操作按键**：
   - `s`：保存游戏（选择槽位 1-3）。
   - `h`：显示提示（消耗少量能量）。
   - `i`：使用道具（如能量电池或干扰器）。
   - `q`：退出游戏。
6. **特色机制**：
   - **关卡选择**：解锁后可直接进入已通关卡。
   - **道具系统**：能量电池（+20% 能量）、干扰器（跳过信号）。
   - **天气效果**：风暴（减少 20% 时间）、迷雾（增加 1 个选项）。
   - **无尽模式**：通关后解锁，信号长度不断增加。
   - **排行榜**：记录前 5 高分，显示关卡、模式和时间。

## 存档与成就

- **存档**：
  - 按 `s` 键保存游戏，选择槽位 1-3。
  - 存档文件保存至：
    - Linux/macOS：`~/.starsignal_save_X.json`
    - Windows：`%USERPROFILE%\.starsignal_save_X.json`
- **成就**：
  - 保存至 `~/.starsignal_data.json`（Windows：`%USERPROFILE%\.starsignal_data.json`）。
  - 示例成就：“Boss 终结者”、“完美通关”。
- **排行榜**：
  - 记录前 5 高分，包括关卡、模式、时间。

## 更新

使用管理脚本更新游戏：

```bash
sh starsignal_manager.sh
# 选择“更新”选项，选择 main 或 dev 分支
```

手动更新：

```bash
pip3 install --user --force-reinstall git+https://github.com/bbb-lsy07/StarSignalDecoder.git@main
```

## 卸载

使用管理脚本卸载：

```bash
sh starsignal_manager.sh
# 选择“卸载”选项
```

手动卸载：

```bash
# Linux/macOS
pip3 uninstall starsignal
rm -f ~/.starsignal*
# Windows
pip uninstall starsignal
del %USERPROFILE%\.starsignal*
```

## 开发指南

1. **克隆仓库**：
   ```bash
   git clone https://github.com/bbb-lsy07/StarSignalDecoder.git
   cd StarSignalDecoder
   ```
2. **安装开发环境**：
   ```bash
   pip3 install --user -e .
   ```
3. **运行游戏**：
   ```bash
   python3 -m starsignal.cli
   ```

### 贡献代码

欢迎为游戏贡献新功能！以下是一些建议：
- **新规则**：添加信号解码规则，如“数字平方”或“奇偶交替”。
- **联网对战**：基于 WebSocket 实现多人竞技模式。
- **音效支持**：添加终端“滴滴”声（Linux 使用 `beep`，Windows 使用 `Console.Beep`）。
- **多语言**：扩展支持日语、韩语等语言。
- **Docker 部署**：提供 Dockerfile 和容器化安装说明。
- **图形界面**：开发简单的 GUI 版本（使用 Tkinter 或 Pygame）。

**提交步骤**：

1. 创建分支：
   ```bash
   git checkout -b feature/新功能
   ```
2. 提交更改：
   ```bash
   git commit -m "添加新功能：描述"
   ```
3. 运行测试：
   ```bash
   python3 -m unittest discover tests
   ```
4. 代码格式化：
   ```bash
   shfmt -w scripts/*.sh
   shellcheck scripts/*.sh
   ```
5. 提交 Pull Request 到 `main` 分支，使用 [PR 模板](.github/pull_request_template.md)。

**贡献要求**：
- 测试覆盖率目标：>80%（使用 `pytest --cov` 检查）。
- 提交前讨论新功能，创建 issue 以获得反馈。
- 遵循代码风格：Python 使用 PEP 8，Shell 使用 `shfmt`。

## 故障排除

### 输入无效或阻塞

**问题**：运行 `starsignal_manager.sh` 时，直接按回车提示“无效选项”重复，或无法输入。

**解决**：
- 避免管道植物（如 `curl ... | sh`），下载脚本后运行：
  ```bash
  curl -s https://raw.githubusercontent.com/bbb-lsy07/StarSignalDecoder/main/starsignal_manager.sh -o starsignal_manager.sh
  chmod +x starsignal_manager.sh
  ./starsignal_manager.sh
  ```
- 检查终端设置：
  ```bash
  stty -a  # 确保 sane 设置
  echo $TERM  # 推荐 xterm 或 xterm-256color
  ```
- 重置终端：
  ```bash
  stty sane
  export TERM=xterm-256color
  ```

### 存档无法加载

**问题**：存档文件无法读取或写入。

**解决**：
```bash
# Linux/macOS
ls -l ~/.starsignal*
chmod 666 ~/.starsignal*
# Windows
icacls "%USERPROFILE%\.starsignal*" /grant Everyone:F
```

### 波形显示异常

**问题**：信号波形或界面显示乱码。

**解决**：确保终端支持 UTF-8：
```bash
# Linux/macOS
echo $LANG
# 设置 UTF-8（例如）
export LANG=zh_CN.UTF-8
# Windows
chcp 65001
```

### starsignal 命令未找到

**问题**：运行 `starsignal` 提示命令不存在。

**解决**：修复 PATH：
```bash
# Linux/macOS
export PATH=$PATH:$HOME/.local/bin
echo 'export PATH=$PATH:$HOME/.local/bin' >> ~/.bashrc
source ~/.bashrc
# Windows
$ScriptsPath = "$env:USERPROFILE\AppData\Roaming\Python\Python39\Scripts"
[Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path", "User") + ";$ScriptsPath", "User")
```

### 网络连接问题

**问题**：无法连接 GitHub，安装失败。

**解决**：检查网络并尝试 Google DNS：
```bash
# Linux/macOS
ping github.com
echo "nameserver 8.8.8.8" | sudo tee -a /etc/resolv.conf
# Windows
netsh interface ip set dns name="Ethernet" source=static addr=8.8.8.8
```

### Windows 安装失败

**问题**：PowerShell 安装 Python/git 失败。

**解决**：以管理员身份运行 PowerShell：
```powershell
Start-Process powershell -Verb RunAs
```

### 日志查看

所有操作日志保存在：
- Linux/macOS：`~/.starsignal_install.log`
- Windows：`%USERPROFILE%\.starsignal_install.log`

```bash
# Linux/macOS
cat ~/.starsignal_install.log
# Windows
type %USERPROFILE%\.starsignal_install.log
```

### 常见问题（FAQ）

- **Q：为什么运行 `curl ... | sh` 后无法输入？**  
  A：管道运行绑定了标准输入，导致交互失败。请下载脚本后运行（见 [快速开始](#快速开始)）。
- **Q：如何确认安装成功？**  
  A：运行 `starsignal --version`，应显示 v0.7.0。
- **Q：存档丢失怎么办？**  
  A：检查存档路径和权限（见 [存档无法加载](#存档无法加载)），或联系作者。

## 版本历史

- **v0.7.0**（2025-05-24）：
  - 新增关卡选择、道具系统、动态天气。
  - 优化无尽模式和排行榜。
  - 修复存档权限问题。
- **v0.6.0**：
  - 引入双人协作模式。
  - 添加 NPC 任务和随机事件。
- **v0.5.0**：
  - 实现动态波形和能量警告。
- **管理脚本 v1.7.1**（2025-05-24）：
  - 修复空输入导致的“无效选项”重复提示和输入阻塞问题。
  - 优化终端交互，确保管道运行提示下载后运行。
  - 添加终端编码检查建议。

## 许可证

[MIT 许可证](LICENSE)

## 联系方式

- **作者**：bbb-lsy07
- **邮箱**：lisongyue0125@163.com
- **GitHub**：https://github.com/bbb-lsy07
- **Issues**：https://github.com/bbb-lsy07/StarSignalDecoder/issues
- **博客**：https://i.bbb-lsy07.sbs/

感谢体验 **星际迷航：信号解码**！挑战星际，铸就传说！
