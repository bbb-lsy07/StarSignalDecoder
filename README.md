# 星际迷航：信号解码 (StarSignalDecoder)

**星际迷航：信号解码** 是一个开源的终端解谜游戏。你将扮演星际飞船信号官，通过选择正确的信号解码结果逃离危险星域。每次解码有时间限制，正确解码可获得能量核心，收集 3 个核心即可胜利！

**StarSignalDecoder** is an open-source terminal puzzle game. Play as a starship signal officer, selecting the correct decoded signal to escape a dangerous starfield. Each decoding has a time limit, and collecting 3 energy cores leads to victory!

## 安装 (Installation)

一键安装：
```bash
pip install git+https://github.com/bbb-lsy07/StarSignalDecoder.git
```

One-command installation:
```bash
pip install git+https://github.com/bbb-lsy07/StarSignalDecoder.git
```

## 使用 (Usage)

运行游戏：
```bash
starsignal
```

选项：
- `--difficulty {easy,medium,hard}`：设置难度（简单：60秒3选项，中等：45秒4选项，困难：30秒5选项，默认：easy）
- `--version`：显示版本号
- `--help`：显示帮助信息

Options:
- `--difficulty {easy,medium,hard}`: Set difficulty (easy: 60s 3 options, medium: 45s 4 options, hard: 30s 5 options, default: easy)
- `--version`: Show version number
- `--help`: Show help message

## 示例 (Example)
```bash
$ starsignal --difficulty medium
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
```

## 开发 (Development)
- 克隆仓库：`git clone https://github.com/bbb-lsy07/StarSignalDecoder.git`
- 安装开发模式：`pip install -e .`
- 本地运行：`python -m starsignal.cli`

- Clone the repo: `git clone https://github.com/bbb-lsy07/StarSignalDecoder.git`
- Install in dev mode: `pip install -e .`
- Run locally: `python -m starsignal.cli`

## 许可证 (License)
MIT 许可证，详见 `LICENSE` 文件。

MIT License, see `LICENSE` for details.
