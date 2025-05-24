import random

try:
    from colorama import Fore, Style, init
    init(autoreset=True)
    COLOR_AVAILABLE = True
except ImportError:
    COLOR_AVAILABLE = False
    Fore = Style = None

class Display:
    def __init__(self, use_color=True):
        self.use_color = use_color and COLOR_AVAILABLE

    def color_text(self, text, color):
        if self.use_color:
            return f"{color}{text}{Style.RESET_ALL}"
        return text

    def show_intro(self):
        intro = """
        ╔══════════════════════════════════════╗
        ║    星际迷航：信号解码              ║
        ╚══════════════════════════════════════╝
        欢迎，信号官！你的飞船被困在危险星域！
        解码随机信号以修复导航系统，逃离险境！
        每次解码有时间限制，正确解码可获得能量核心。
        收集 3 个核心以赢得胜利，保持能量高于 0！
        提示：按 'h' 查看规则，'s' 保存，'q' 退出。
        """
        print(self.color_text(intro, Fore.CYAN if self.use_color else ""))

    def show_tutorial(self):
        tutorial = """
        ╔══════ 教程 ══════╗
        1. 你将看到一个信号（如 3#5*2）和规则（如“忽略非数字字符”）。
        2. 从多个选项中选择正确答案（输入编号，如 1）。
        3. 信号强度（弱/中/强）影响难度和奖励。
        4. 快速回答避免超时，错误或超时会减能量。
        5. 按 'h' 查看提示，'s' 保存，'q' 退出。
        6. 收集 3 个能量核心以逃离星域！
        按回车继续...
        """
        print(self.color_text(tutorial, Fore.YELLOW if self.use_color else ""))
        input()

    def show_signal(self, signal, rule, options, energy, score, cores, stage, signal_strength):
        strength_text = ["弱", "中", "强"][signal_strength - 1]
        print(self.color_text(f"\n接收到新信号（强度：{strength_text}）：", Fore.GREEN if self.use_color else ""))
        print(self._generate_waveform(signal))
        print(f"信号：{signal}")
        print(f"规则：{rule}")
        for i, opt in enumerate(options, 1):
            print(f"{i}. {opt}")
        print(f"飞船能量：{energy}% | 得分：{score} | 能量核心：{cores}")
        print(f"任务进度：{self._progress_bar(stage)}")

    def show_status(self, energy, score, cores):
        status = f"\n状态：能量 = {energy}%，得分 = {score}，能量核心 = {cores}"
        print(self.color_text(status, Fore.MAGENTA if self.use_color else ""))

    def show_story(self, stage):
        stories = [
            "飞船检测到微弱信号，导航系统开始响应！",
            "你修复了部分导航，星域边缘在望！",
            "最后一核心激活，飞船准备跳跃！"
        ]
        if stage <= len(stories):
            print(self.color_text(f"\n故事进展：{stories[stage-1]}", Fore.CYAN if self.use_color else ""))

    def show_npc_dialogue(self, event_type=None):
        if event_type == "interference":
            print(self.color_text("NPC: '信号受到干扰，时间更紧张了！'", Fore.RED if self.use_color else ""))
        elif event_type == "fault":
            print(self.color_text("NPC: '飞船系统故障，能量下降！'", Fore.RED if self.use_color else ""))
        elif event_type == "bonus":
            print(self.color_text("NPC: '发现能量脉冲，抓住机会！'", Fore.GREEN if self.use_color else ""))
        else:
            dialogues = [
                "NPC: '保持冷静，我们一定能逃出去！'",
                "NPC: '信号强度很关键，注意观察！'",
                "NPC: '你的解码技术越来越棒了！'"
            ]
            print(self.color_text(random.choice(dialogues), Fore.BLUE if self.use_color else ""))

    def show_hint(self, rule):
        hint = f"提示：规则是“{rule}”。仔细分析信号，忽略干扰字符！按编号（如 1）选择，'s' 保存，'q' 退出。"
        print(self.color_text(hint, Fore.YELLOW if self.use_color else ""))

    def show_ending(self, score, cores):
        if cores >= 3 and score > 50:
            ending = "结局：英雄归来！你以高分逃离星域，成为传奇信号官！"
            color = Fore.GREEN
        elif cores >= 3:
            ending = "结局：艰难逃脱！你成功逃离，但飞船伤痕累累。"
            color = Fore.YELLOW
        else:
            ending = "结局：信号中断！飞船未能逃脱，任务失败。"
            color = Fore.RED
        print(self.color_text(ending, color if self.use_color else ""))

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
