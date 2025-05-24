class Display:
    def show_intro(self):
        print("""
        ╔══════════════════════════════════════╗
        ║    星际迷航：信号解码              ║
        ╚══════════════════════════════════════╝
        欢迎，信号官！你的飞船被困在危险星域！
        解码随机信号以修复导航系统，逃离险境！
        每次解码有时间限制，正确解码可获得能量核心。
        收集 3 个核心以赢得胜利，保持能量高于 0！
        """)

    def show_tutorial(self):
        print("""
        ╔══════ 教程 ══════╗
        1. 你将看到一个信号（如 3#5*2）和规则（如“忽略非数字字符”）。
        2. 从多个选项中选择正确的解码结果（输入编号，如 1）。
        3. 快速回答以节省时间，错误或超时会减少能量。
        4. 收集 3 个能量核心以逃离星域！
        按回车继续...
        """)
        input()

    def show_signal(self, signal, rule, options, energy, score, cores, stage):
        print("\n接收到新信号：")
        print(self._generate_waveform(signal))
        print(f"信号：{signal}")
        print(f"规则：{rule}")
        for i, opt in enumerate(options, 1):
            print(f"{i}. {opt}")
        print(f"飞船能量：{energy}% | 得分：{score} | 能量核心：{cores}")
        print(f"任务进度：{self._progress_bar(stage)}")

    def show_status(self, energy, score, cores):
        print(f"\n状态：能量 = {energy}%，得分 = {score}，能量核心 = {cores}")

    def show_story(self, stage):
        stories = [
            "飞船检测到微弱信号，导航系统开始响应！",
            "你修复了部分导航，星域边缘在望！",
            "最后一核心激活，飞船准备跳跃！"
        ]
        if stage <= len(stories):
            print(f"\n故事进展：{stories[stage-1]}")

    def _generate_waveform(self, signal):
        waveform = ["  " * len(signal) for _ in range(3)]
        for i, char in enumerate(signal):
            height = 1 if char.isdigit() else 2
            waveform[2 - height] = waveform[2 - height][:i*2] + "█" + waveform[2 - height][i*2+1:]
        return "\n".join(waveform)

    def _progress_bar(self, stage):
        total = 3
        filled = min(stage, total)
        bar = "█" * filled + "▒" * (total - filled)
        return f"[{bar}] {filled}/{total}"
