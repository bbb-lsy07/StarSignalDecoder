# 星际迷航：信号解码 (StarSignalDecoder)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3](https://img.shields.io/badge/Python-3-blue.svg)](https://www.python.org/)
[![Version](https://img.shields.io/badge/Version-0.1.0-green.svg)](https://github.com/bbb-lsy07/StarSignalDecoder/releases)

**星际迷航：信号解码** 是一个开源的终端解谜游戏，带你体验星际冒险的乐趣！扮演星际飞船的信号官，通过选择正确的信号解码结果，修复导航系统，逃离危险星域。游戏结合了科幻故事、ASCII 艺术和时间挑战，每次解码都有新惊喜！

**StarSignalDecoder** is an open-source terminal puzzle game that immerses you in a sci-fi adventure! As a starship signal officer, select the correct decoded signal to repair the navigation system and escape a dangerous starfield. With dynamic signals, ASCII art, and time challenges, every round is a new thrill!

## 特色 (Features)
- **简单有趣**：从多选选项中选择正确答案，无需复杂输入。
- **科幻冒险**：解码信号推进故事，收集能量核心以赢得胜利。
- **ASCII 艺术**：独特的信号波形显示，增强沉浸感。
- **多难度模式**：简单（60秒，3选项）、中等（45秒，4选项）、困难（30秒，5选项）。
- **跨平台**：仅需 Python 3，支持 Linux、Windows、macOS。
- **一键安装**：通过单一命令快速安装和运行。

## 安装 (Installation)
只需一条命令即可安装游戏：

```bash
pip install git+https://github.com/bbb-lsy07/StarSignalDecoder.git
```

**要求**：
- Python 3.6 或以上（运行 `python3 --version` 检查）。
- 无其他依赖，安装即玩！

**Install with one command**:

```bash
pip install git+https://github.com/bbb-lsy07/StarSignalDecoder.git
```

**Requirements**:
- Python 3.6 or higher (check with `python3 --version`).
- No external dependencies, install and play!

**遇到问题？**  
如果提示 `pip: command not found`，先安装 `pip`：
- Ubuntu/Debian：
  ```bash
  sudo apt update
  sudo apt install python3-pip -y
  ```
- CentOS/RHEL：
  ```bash
  sudo yum install python3-pip -y
  ```
然后重新运行安装命令。

## 使用 (Usage)
安装后，通过以下命令启动游戏：

```bash
starsignal
```

### 选项 (Options)
- `--difficulty {easy,medium,hard}`：设置难度（默认：easy）
  - 简单：60秒，3个选项
  - 中等：45秒，4个选项
  - 困难：30秒，5个选项
- `--version`：显示版本号
- `--help`：显示帮助信息

### 示例 (Example)
运行 `starsignal --difficulty medium`：
```
╔══════════════════════════════════════╗
║    星际迷航：信号解码              ║
╚══════════════════════════════════════╝
欢迎，信号官！你的飞船被困在危险星域！
...
接收到新信号：
  █       █  
    █   █   
█   █   █   █
信号：3#5*2
规则：忽略非数字字符并反转序列
1. 253
2. 523
3. 532
4. 235
飞船能量：100% | 得分：0 | 能量核心：0
任务进度：[▒] 0/3
请输入正确选项编号（1-4）：2
信号解码成功！飞船前进！
故事进展：飞船检测到微弱信号，导航系统开始响应！
```

## 玩法说明 (How to Play)
1. **启动游戏**：运行 `starsignal`，首次进入会显示教程。
2. **解码信号**：根据信号（如 `3#5*2`）和规则（如“忽略非数字字符”），从选项中选择正确答案（输入编号，如 `1`）。
3. **目标**：在时间限制内解码信号，收集 3 个能量核心以逃离星域。
4. **注意**：错误或超时会减少飞船能量，能量耗尽则游戏结束。

## 开发 (Development)
想贡献代码或本地运行？按照以下步骤：

1. 克隆仓库：
   ```bash
   git clone https://github.com/bbb-lsy07/StarSignalDecoder.git
   cd StarSignalDecoder
   ```
2. 安装开发模式：
   ```bash
   pip install -e .
   ```
3. 运行游戏：
   ```bash
   python -m starsignal.cli
   ```

**贡献指南**：
- 提交问题或建议到 [Issues](https://github.com/bbb-lsy07/StarSignalDecoder/issues)。
- 提交 Pull Request，欢迎添加新规则、故事或功能！

## 许可证 (License)
本项目采用 [MIT 许可证](LICENSE)，允许自由使用、修改和分发。

This project is licensed under the [MIT License](LICENSE), free to use, modify, and distribute.

## 联系 (Contact)
- 作者：bbb-lsy07
- 邮箱：lisongyue0125@163.com
- GitHub：https://github.com/bbb-lsy07

感谢体验 **星际迷航：信号解码**！快来解码信号，开启星际冒险吧！

Thank you for trying **StarSignalDecoder**! Start decoding signals and embark on your interstellar adventure!
