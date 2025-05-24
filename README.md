# 星际迷航：信号解码 (StarSignalDecoder)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3](https://img.shields.io/badge/Python-3-blue.svg)](https://www.python.org/)
[![Version](https://img.shields.io/badge/Version-0.1.0-green.svg)](https://github.com/bbb-lsy07/StarSignalDecoder/releases)

**星际迷航：信号解码** 是一款开源的终端解谜游戏，让你在黑漆漆的命令行中遨游星际！化身星际飞船信号官，通过选择正确的信号解码结果，修复导航系统，逃离危机四伏的星域。游戏融合科幻剧情、ASCII 艺术和紧张的时间挑战，每一关都让你心跳加速！

**StarSignalDecoder** is an open-source terminal puzzle game that launches you into a sci-fi adventure! As a starship signal officer, select the correct decoded signal to repair the navigation system and escape a dangerous starfield. Packed with sci-fi storytelling, ASCII art, and thrilling time challenges, every round keeps you on the edge!

## 特色 (Features)

- **简单上手**：多选题玩法，只需输入编号（如 <kbd>1</kbd>），新手也能秒玩。
- **科幻剧情**：解码信号推动故事，收集 3 个能量核心赢得胜利。
- **ASCII 艺术**：动态信号波形（如 <kbd>█</kbd>）和进度条（<kbd>[██▒] 2/3</kbd>），打造沉浸式体验。
- **多难度模式**：
  - 简单：60秒，3个选项
  - 中等：45秒，4个选项
  - 困难：30秒，5个选项
- **跨平台**：仅需 Python 3，完美运行于 Linux、Windows、macOS。
- **一键安装**：单命令快速部署，装完就能开玩！

## 安装 (Installation)

一条命令搞定安装 <span class="p cyan">星际迷航：信号解码</span>：

```bash
pip3 install git+https://github.com/bbb-lsy07/StarSignalDecoder.git
```

**要求 (Requirements)**:
- Python 3.6 或更高版本（运行 <kbd>python3 --version</kbd> 检查）。
- 无外部依赖，安装即玩！

**遇到问题 (Troubleshooting)?**  
- **提示 `<kbd>pip: command not found</kbd>`**？先安装 `pip`：
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
- **提示 `<kbd>starsignal: command not found</kbd>`**？可能是脚本未加入 PATH：
  ```bash
  export PATH=$PATH:/root/.local/bin
  ```
  想永久生效，添加到 <kbd>~/.bashrc</kbd>：
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

```bash
pip3 install git+https://github.com/bbb-lsy07/StarSignalDecoder.git
```

**Requirements**:
- Python 3.6 or higher (check with <kbd>python3 --version</kbd>).
- No external dependencies—install and play!

**Troubleshooting**:
- **See `<kbd>pip: command not found</kbd>`**? Install `pip`:
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
- **See `<kbd>starsignal: command not found</kbd>`**? Ensure pip-installed scripts are in PATH:
  ```bash
  export PATH=$PATH:/root/.local/bin
  ```
  Persist by adding to <kbd>~/.bashrc</kbd>:
  ```bash
  echo 'export PATH=$PATH:/root/.local/bin' >> ~/.bashrc
  source ~/.bashrc
  ```
- **Network issues**? Verify GitHub access (<kbd>ping github.com</kbd>). If failing, update DNS:
  ```bash
  echo "nameserver 8.8.8.8" >> /etc/resolv.conf
  ```
  Or set a proxy:
  ```bash
  export http_proxy=http://your-proxy:port
  export https_proxy=http://your-proxy:port
  ```

## 使用 (Usage)

安装后，运行以下命令启动游戏：

```bash
starsignal
```

### 命令选项 (Command Options)

- `--difficulty {easy,medium,hard}`：选择难度（默认：<kbd>easy</kbd>）
  - <kbd>easy</kbd>：60秒，3个选项
  - <kbd>medium</kbd>：45秒，4个选项
  - <kbd>hard</kbd>：30秒，5个选项
- `--version`：显示当前版本号
- `--help`：查看帮助信息

### 示例 (Example)

运行中等难度：

```bash
starsignal --difficulty medium
```

输出示例：

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

1. **启动游戏**：运行 <kbd>starsignal</kbd>，首次进入有简易教程。
2. **解码信号**：根据信号（如 <kbd>3#5*2</kbd>）和规则（如“忽略非数字字符”），从选项中选正确答案（输入编号，如 <kbd>1</kbd>）。
3. **目标**：在时间限制内解码信号，收集 3 个能量核心逃离星域。
4. **注意**：答错或超时会减少飞船能量，能量耗尽游戏结束。

## 卸载 (Uninstallation)

想卸载 <span class="p cyan">StarSignalDecoder</span>？运行：

```bash
pip3 uninstall starsignal
```

- 输入 <kbd>y</kbd> 确认。
- 验证卸载：运行 <kbd>pip3 show starsignal</kbd>，应无输出。

**Uninstall**:

```bash
pip3 uninstall starsignal
```

- Confirm with <kbd>y</kbd>.
- Verify: Run <kbd>pip3 show starsignal</kbd>, should show no output.

## 更新 (Updating)

想体验最新功能？强制重新安装 GitHub 仓库最新代码：

```bash
pip3 install --force-reinstall git+https://github.com/bbb-lsy07/StarSignalDecoder.git
```

- 检查版本：<kbd>pip3 show starsignal</kbd>（版本号取决于 <kbd>setup.py</kbd>）。
- 测试更新：<kbd>starsignal --difficulty easy</kbd>。

**Update**:

```bash
pip3 install --force-reinstall git+https://github.com/bbb-lsy07/StarSignalDecoder.git
```

- Check version: <kbd>pip3 show starsignal</kbd> (version depends on <kbd>setup.py</kbd>).
- Test update: <kbd>starsignal --difficulty easy</kbd>.

## 开发 (Development)

想加点料或本地开发？按以下步骤：

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
- 在 [Issues](https://github.com/bbb-lsy07/StarSignalDecoder/issues) 提交问题或建议。
- Fork 仓库，提交 Pull Request，欢迎新规则、剧情或功能！
- 推荐改进：
  - 彩色输出：用 <kbd>colorama</kbd> 让信号波形更炫。
  - 新规则：如“奇数加1”或“字母转数字”。
  - 排行榜：记录玩家最高分。

## 常见问题 (FAQ)

**Q: 为什么运行 <kbd>starsignal</kbd> 提示 <kbd>command not found</kbd>？**  
A: 可能是安装路径未加入 PATH。检查：
- Python 版本：<kbd>python3 --version</kbd>（需 3.6+）。
- 安装状态：<kbd>pip3 show starsignal</kbd>。
- 修复 PATH：<kbd>export PATH=$PATH:/root/.local/bin</kbd>。
- 重新安装：<kbd>pip3 install git+https://github.com/bbb-lsy07/StarSignalDecoder.git</kbd>。

**Q: 遇到 <kbd>pip: command not found</kbd> 怎么办？**  
A: 安装 `pip`（以 Ubuntu/Debian 为例）：
```bash
sudo apt update
sudo apt install python3-pip -y
```

**Q: 如何确认游戏更新到最新版？**  
A: 运行 <kbd>pip3 show starsignal</kbd> 检查版本号，或体验游戏内新功能（如新规则）。若版本号未变，仓库代码可能已更新但 <kbd>setup.py</kbd> 未改。

**Q: 游戏卡顿或崩溃怎么办？**  
A: 确保终端支持 UTF-8 编码（Linux 默认支持）。若有问题，请在 [Issues](https://github.com/bbb-lsy07/StarSignalDecoder/issues) 提交日志。

**Q: 可以加什么新功能？**  
A: 欢迎创意！比如：
- 新规则：如“奇数加1”或“字母转数字”。
- 彩色波形：用 <kbd>colorama</kbd> 增强视觉。
- 排行榜：记录玩家得分。

## 许可证 (License)

本项目采用 [MIT 许可证](LICENSE)，可自由使用、修改和分发。

This project is licensed under the [MIT License](LICENSE), free to use, modify, and distribute.

## 联系 (Contact)

- **作者**：bbb-lsy07
- **邮箱**：lisongyue0125@163.com
- **GitHub**：https://github.com/bbb-lsy07
- **博客**：https://i.bbb-lsy07.sbs/

感谢体验 <span class="p cyan">星际迷航：信号解码</span>！快来解码信号，开启你的星际冒险吧！  
Thank you for trying <span class="p cyan">StarSignalDecoder</span>! Decode signals and embark on your interstellar adventure!
