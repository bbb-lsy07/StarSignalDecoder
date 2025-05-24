import random
import time
import sys
import os

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
        挑战 3 关，收集核心，最终能量 100% 逃离！
        按 'h' 提示，'s' 保存，'q' 退出。
        """
        self._animate_text(intro, Fore.CYAN)

    def show_tutorial(self):
        tutorial = """
        ╔══════ 教程 ══════╗
        1. 信号示例：3#5*2，规则“忽略非数字字符”。
        2. 输入编号（如 1）选择答案。
        3. 强度（弱/中/强）、天气、道具影响难度。
        4. 完成 NPC 任务获奖励。
        5. 按 'h' 提示，'s' 保存，'q' 退出。
        试试：信号 7*3#1，规则：忽略非数字字符
        答案：A) 731 B) 137 C) 713
        输入编号（1-3）或 'skip' 跳过：
        """
        print(self.color_text(tutorial, Fore.YELLOW))
        choice = input().strip().lower()
        if choice == "skip":
            print(self.color_text("教程已跳过！", Fore.YELLOW))
        elif choice == "1":
            print(self.color_text("正确！答案是 731！", Fore.GREEN))
        else:
            print(self.color_text("答案是 731，继续练习！", Fore.YELLOW))
        print("按回车继续...")
        input()

    def show_mode_selection(self, unlocked_levels, has_progress, endless_unlocked):
        print(self.color_text("\n选择模式：", Fore.CYAN))
        print("1) 新游戏（关卡 1）")
        print(f"2) 继续（关卡 {has_progress['level'] if has_progress else 1}）" if has_progress else "2) 继续（无进度）")
        print(f"3) 选择关卡（已解锁：{', '.join(map(str, unlocked_levels))})")
        print(f"4) 无尽模式（{'已解锁' if endless_unlocked else '未解锁'}）")

    def show_signal(self, signal, rule, options, energy, score, cores, stage, level, signal_strength, weather, equipment, items, task):
        strength_text = ["弱", "中", "强"][signal_strength - 1]
        weather_text = {"clear": "晴朗", "storm": "风暴", "fog": "迷雾"}[weather]
        equip_text = equipment or "无"
        items_text = ", ".join(items) or "无"
        task_text = task["description"] if task else "无"
        warning = Fore.RED if energy < 30 else Fore.YELLOW if energy < 80 else Fore.GREEN
        print(self.color_text(f"\n关卡 {level} | 天气：{weather_text} | 装备：{equip_text} | 道具：{items_text}", Fore.MAGENTA))
        print(self.color_text(f"NPC任务：{task_text}", Fore.BLUE))
        print(self.color_text(f"信号（强度：{strength_text}）：", Fore.GREEN))
        self._animate_waveform(signal, strength_text)
        print(f"信号：{signal}")
        print(f"规则：{rule}")
        for i, opt in enumerate(options, 1):
            print(f"{i}. {opt}")
        print(self.color_text(f"能量：{energy}% | 得分：{score} | 核心：{cores}/{stage}", warning))
        print(f"进度：{self._progress_bar(cores, stage)}")

    def show_status(self, energy, score, cores, level):
        status = f"\n状态：关卡 = {level}，能量 = {energy}%，得分 = {score}，核心 = {cores}"
        print(self.color_text(status, Fore.MAGENTA))

    def show_level_transition(self, level):
        print(self.color_text(f"\n进入关卡 {level}...", Fore.CYAN))
        for i in range(3):
            print(self.color_text("信号同步中" + "." * i, Fore.YELLOW))
            sys.stdout.flush()
            time.sleep(0.5)
            print("\033[1A\033[K", end="")
        print(self.color_text(f"关卡 {level} 启动！", Fore.GREEN))

    def show_boss(self):
        boss = """
        ╔══════ Boss 信号 ══════╗
        警告：检测到超强信号！
        准备解码，成功获高额奖励！
        ╚═══════════════════════╝
        """
        self._animate_text(boss, Fore.RED)

    def show_store(self, score, available_items):
        print(self.color_text(f"\n星际商店（得分：{score}）", Fore.CYAN))
        for i, item in enumerate(available_items, 1):
            print(f"{i}. {item['name']}（{item['cost']} 分）：{item['description']}")
        print("0. 离开商店")

    def show_task_complete(self, reward):
        print(self.color_text(f"\n任务完成！奖励：{reward}", Fore.GREEN))

    def show_story(self, level):
        stories = [
            "信号微弱，导航系统启动！",
            "导航修复，星域出口接近！",
            "核心齐全，飞船跃迁准备！"
        ]
        if level <= len(stories):
            print(self.color_text(f"\n故事：{stories[level-1]}", Fore.CYAN))

    def show_npc_dialogue(self, event_type=None, weather=None, task=None):
        weather_dialogues = {
            "clear": "NPC: '晴朗天气，解码好时机！'",
            "storm": "NPC: '风暴干扰，抓紧解码！'",
            "fog": "NPC: '迷雾增加干扰，小心选择！'"
        }
        event_dialogues = {
            "interference": "NPC: '信号干扰，时间减少！'",
            "fault": "NPC: '系统故障，能量下降！'",
            "bonus": "NPC: '能量脉冲，抓住机会！'",
            "storm": "NPC: '能量风暴，随机效果！'",
            "merchant": "NPC: '我是星际商人，换点装备？'"
        }
        task_dialogues = {
            "strong_signals": "NPC: '优先解码强信号，奖励更高！'",
            "no_mistakes": "NPC: '连续无误，证明你的技术！'"
        }
        if event_type:
            print(self.color_text(event_dialogues[event_type], Fore.RED if event_type in ["interference", "fault", "storm"] else Fore.GREEN))
        elif task:
            print(self.color_text(task_dialogues[task["type"]], Fore.BLUE))
        elif weather:
            print(self.color_text(weather_dialogues[weather], Fore.BLUE))
        else:
            dialogues = [
                "NPC: '你的技术让我刮目相看！'",
                "NPC: '冷静，我们会成功的！'"
            ]
            print(self.color_text(random.choice(dialogues), Fore.BLUE))

    def show_hint(self, rule):
        hint = f"提示：规则“{rule}”。分析信号，忽略干扰！输入编号（如 1），'s' 保存，'i' 使用道具，'q' 退出。"
        print(self.color_text(hint, Fore.YELLOW))

    def show_ending(self, score, cores, levels_cleared, energy):
        if levels_cleared >= 3 and energy == 100 and score > 100:
            ending = "结局：星际传奇！你以完美能量和高分通关，成为信号官神话！"
            color = Fore.GREEN
        elif levels_cleared >= 3 and energy >= 80:
            ending = "结局：险象环生！你通关，但飞船伤痕累累。"
            color = Fore.YELLOW
        else:
            ending = "结局：信号失联！飞船未能逃脱，任务失败。"
            color = Fore.RED
        print(self.color_text(ending, color))

    def show_achievement(self, achievement):
        print(self.color_text(f"\n成就解锁：{achievement}！", Fore.GREEN))

    def show_rankings(self, rankings):
        print(self.color_text("\n排行榜：", Fore.CYAN))
        for i, rank in enumerate(rankings, 1):
            print(f"{i}. 得分：{rank['score']} | 关卡：{rank['level']} | 模式：{rank['mode']} | 时间：{rank['time']}")

    def _animate_waveform(self, signal, strength):
        waveform = ["  " * len(signal) for _ in range(3)]
        for i, char in enumerate(signal):
            height = 2 if char.isdigit() else 1
            waveform[2 - height] = waveform[2 - height][:i*2] + "█" + waveform[2 - height][i*2+1:]
        strength_mod = {"弱": 1, "中": 2, "强": 3}[strength]
        for _ in range(strength_mod):
            for line in waveform:
                print(self.color_text(line, Fore.GREEN))
                sys.stdout.flush()
                time.sleep(0.1)
            print("\033[3A\033[K", end="")
        for line in waveform:
            print(self.color_text(line, Fore.GREEN))
        if strength == "强":
            print(self.color_text("[滴滴！强信号！]", Fore.YELLOW))

    def _progress_bar(self, cores, total):
        filled = min(cores, total)
        bar = "█" * filled + "▒" * (total - filled)
        return f"[{bar}] {filled}/{total}"

    def _animate_text(self, text, color):
        for char in text:
            print(self.color_text(char, color), end="", flush=True)
            time.sleep(0.01)
        print()
