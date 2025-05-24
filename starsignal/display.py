import random
import time
import sys

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
        欢迎，信号官！飞船被困危险星域！
        解码信号，修复导航，逃离险境！
        收集 3 个核心获胜，保持能量 > 0！
        按 'h' 提示，'s' 保存，'q' 退出。
        """
        self._animate_text(intro, Fore.CYAN)

    def show_tutorial(self):
        tutorial = """
        ╔══════ 教程 ══════╗
        1. 信号示例：3#5*2，规则如“忽略非数字字符”。
        2. 输入编号（如 1）选择答案。
        3. 信号强度（弱/中/强）影响奖励。
        4. 天气（风暴/迷雾）改变难度。
        5. 按 'h' 提示，'s' 保存，'q' 退出。
        6. 目标：收集 3 个能量核心！
        试试这个信号：7*3#1，规则：忽略非数字字符
        答案是：A) 731 B) 137 C) 713
        输入正确编号（1-3）：
        """
        print(self.color_text(tutorial, Fore.YELLOW))
        choice = input().strip()
        if choice == "1":
            print(self.color_text("正确！答案是 731！", Fore.GREEN))
        else:
            print(self.color_text("答案是 731，继续练习吧！", Fore.YELLOW))
        print("按回车继续...")
        input()

    def show_signal(self, signal, rule, options, energy, score, cores, stage, signal_strength, weather, equipment):
        strength_text = ["弱", "中", "强"][signal_strength - 1]
        weather_text = {"clear": "晴朗", "storm": "风暴", "fog": "迷雾"}[weather]
        equip_text = equipment or "无"
        print(self.color_text(f"\n天气：{weather_text} | 装备：{equip_text}", Fore.MAGENTA))
        print(self.color_text(f"接收到新信号（强度：{strength_text}）：", Fore.GREEN))
        self._animate_waveform(signal)
        print(f"信号：{signal}")
        print(f"规则：{rule}")
        for i, opt in enumerate(options, 1):
            print(f"{i}. {opt}")
        print(f"飞船能量：{energy}% | 得分：{score} | 核心：{cores}")
        print(f"进度：{self._progress_bar(stage)}")

    def show_status(self, energy, score, cores):
        status = f"\n状态：能量 = {energy}%，得分 = {score}，核心 = {cores}"
        print(self.color_text(status, Fore.MAGENTA))

    def show_story(self, stage):
        stories = [
            "飞船捕获微弱信号，导航系统启动！",
            "导航部分修复，星域出口在望！",
            "核心齐全，飞船准备跃迁！"
        ]
        if stage <= len(stories):
            print(self.color_text(f"\n故事：{stories[stage-1]}", Fore.CYAN))

    def show_npc_dialogue(self, event_type=None, weather=None):
        weather_dialogues = {
            "storm": "NPC: '风暴干扰信号，抓紧时间！'",
            "fog": "NPC: '迷雾让信号更复杂，小心！'",
            "clear": "NPC: '晴朗天气，解码好时机！'"
        }
        event_dialogues = {
            "interference": "NPC: '信号干扰，时间减少！'",
            "fault": "NPC: '系统故障，能量下降！'",
            "bonus": "NPC: '发现能量脉冲，额外奖励！'"
        }
        if event_type:
            print(self.color_text(event_dialogues[event_type], Fore.RED if event_type in ["interference", "fault"] else Fore.GREEN))
        elif weather:
            print(self.color_text(weather_dialogues[weather], Fore.BLUE))
        else:
            dialogues = [
                "NPC: '你的技术让我刮目相看！'",
                "NPC: '保持冷静，我们会成功的！'"
            ]
            print(self.color_text(random.choice(dialogues), Fore.BLUE))

    def show_hint(self, rule):
        hint = f"提示：规则是“{rule}”。分析信号，忽略干扰！输入编号（如 1），'s' 保存，'q' 退出。"
        print(self.color_text(hint, Fore.YELLOW))

    def show_ending(self, score, cores):
        if cores >= 3 and score > 60:
            ending = "结局：星际传奇！你以高分逃离，成为信号官神话！"
            color = Fore.GREEN
        elif cores >= 3:
            ending = "结局：险象环生！你逃离星域，但飞船受损严重。"
            color = Fore.YELLOW
        else:
            ending = "结局：信号失联！飞船未能逃脱，任务失败。"
            color = Fore.RED
        print(self.color_text(ending, color))

    def show_achievement(self, achievement):
        print(self.color_text(f"\n成就解锁：{achievement}！", Fore.GREEN))

    def _animate_waveform(self, signal):
        waveform = ["  " * len(signal) for _ in range(3)]
        for i, char in enumerate(signal):
            height = 2 if char.isdigit() else 1
            waveform[2 - height] = waveform[2 - height][:i*2] + "█" + waveform[2 - height][i*2+1:]
        for _ in range(2):
            for line in waveform:
                print(self.color_text(line, Fore.GREEN))
                sys.stdout.flush()
                time.sleep(0.1)
            print("\033[3A\033[K", end="")

    def _progress_bar(self, stage):
        total = 3
        filled = min(stage, total)
        bar = "█" * filled + "▒" * (total - filled)
        return f"[{bar}] {filled}/{total}"

    def _animate_text(self, text, color):
        for char in text:
            print(self.color_text(char, color), end="", flush=True)
            time.sleep(0.01)
        print()
