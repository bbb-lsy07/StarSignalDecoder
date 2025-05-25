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
        self.OS = self._detect_os()

    def _detect_os(self):
        if sys.platform.startswith('linux'):
            return 'Linux'
        elif sys.platform == 'darwin':
            return 'macOS'
        elif sys.platform == 'win32':
            return 'Windows'
        return 'Unknown'

    def _play_sound(self, frequency=440, duration=100):
        """播放一个简单的蜂鸣声"""
        try:
            if self.OS == 'Windows':
                import winsound
                winsound.Beep(frequency, duration)
            elif self.OS in ['Linux', 'macOS']:
                # 使用 ANSI 转义序列播放终端蜂鸣声
                # 注意：不是所有终端都支持或默认启用
                sys.stdout.write('\a')
                sys.stdout.flush()
            # 其他系统暂时不实现声音
        except Exception as e:
            # print(f"无法播放声音: {e}", file=sys.stderr) # 调试用，避免频繁输出
            pass # 静默失败

    def color_text(self, text, color):
        if self.use_color:
            return f"{color}{text}{Style.RESET_ALL}"
        return text

    def _animate_text(self, text, color, delay=0.01):
        """逐字或逐行显示文本，带颜色"""
        lines = text.strip().split('\n')
        for line in lines:
            for char in line:
                sys.stdout.write(self.color_text(char, color))
                sys.stdout.flush()
                time.sleep(delay)
            sys.stdout.write('\n')
        time.sleep(0.5)

    def show_intro(self):
        intro = """
        ╔══════════════════════════════════════╗
        ║    星际迷航：信号解码 v0.7.1       ║
        ╚══════════════════════════════════════╝
        欢迎，信号官！飞船被困危险星域！
        挑战 3 关，收集核心，能量 100.0% 逃离！
        按 'h' 提示，'s' 保存，'i' 道具，'q' 退出。
        """
        self._animate_text(intro, Fore.CYAN, delay=0.005) # 稍微加快动画速度

    def show_tutorial(self):
        tutorial = """
        ╔══════ 教程 ══════╗
        1. 信号示例：3#5*2，规则“忽略非数字字符”。
        2. 输入编号（如 1）选择答案。
        3. 强度（弱/中/强）、天气、道具影响难度。
        4. 完成 NPC 任务获奖励。
        5. 按 'h' 提示，'s' 保存，'i' 道具，'q' 退出。
        试试：信号 7*3#1，规则：忽略非数字字符
        答案：1) 731 2) 137 3) 713
        输入编号（1-3）或 'skip' 跳过：
        """
        print(self.color_text(tutorial, Fore.YELLOW))
        choice = input().strip().lower()
        if choice == "skip":
            print(self.color_text("教程已跳过！", Fore.YELLOW))
        elif choice == "1":
            print(self.color_text("正确！答案是 731！", Fore.GREEN))
            self._play_sound(frequency=600, duration=100)
        else:
            print(self.color_text("答案是 731，继续练习！", Fore.YELLOW))
            self._play_sound(frequency=200, duration=100)
        print("按回车继续...")
        input()

    def show_mode_selection(self, unlocked_levels, current_level, endless_unlocked):
        print(self.color_text("\n╔══════ 模式选择 ══════╗", Fore.CYAN))
        print(f"1) 新游戏（关卡 1）")
        print(f"2) 继续（关卡 {current_level}）" if current_level > 1 else "2) 继续（无进度）")
        print(f"3) 选择关卡（已解锁：{', '.join(map(str, unlocked_levels))})")
        print(f"4) 无尽模式（{'已解锁' if endless_unlocked else '未解锁'}）")
        print(self.color_text("╚═══════════════════════╝", Fore.CYAN))

    def show_signal(self, signal, rule, options, energy, score, cores, stage, level, signal_strength, weather, equipment, items, task, energy_recovery_mode):
        strength_text = ["弱", "中", "强"][signal_strength - 1]
        weather_text = {"clear": "晴朗", "storm": "风暴", "fog": "迷雾"}[weather]
        equip_text = equipment or "无"
        items_text = ", ".join(items) or "无"
        task_text = task["description"] if task else "无"
        warning = Fore.RED if energy < 30 else Fore.YELLOW if energy < 80 else Fore.GREEN
        header = f"╔══════ 关卡 {level} | {weather_text} | 装备：{equip_text} | 道具：{items_text} ══════╗"
        print(self.color_text(header, Fore.MAGENTA))
        print(self.color_text(f"NPC任务：{task_text}", Fore.BLUE))
        print(self.color_text(f"信号（强度：{strength_text}）：", Fore.GREEN))
        self._animate_waveform(signal, strength_text)
        print(f"信号：{signal}")
        print(f"规则：{rule}")
        for i, opt in enumerate(options, 1):
            print(f"{i}. {opt}")
        print(self.color_text(f"能量：{energy:.1f}% | 得分：{score} | 核心：{cores}/{stage}", warning))
        status = "能量恢复中" if energy_recovery_mode else f"{cores}/{stage}"
        print(f"进度：{self._progress_bar(cores, stage, energy_recovery_mode)} {status}")
        print(self.color_text("╚═══════════════════════════════════════════════╝", Fore.MAGENTA))

    def show_status(self, energy, score, cores, level):
        status = f"状态：关卡 = {level}，能量 = {energy:.1f}%，得分 = {score}，核心 = {cores}"
        print(self.color_text(status, Fore.MAGENTA))

    def show_level_transition(self, level):
        print(self.color_text(f"\n进入关卡 {level}...", Fore.CYAN))
        for i in range(3):
            print(self.color_text("信号同步中" + "." * i, Fore.YELLOW))
            sys.stdout.flush()
            time.sleep(0.5)
            # 移动光标到上一行开头并清空
            sys.stdout.write("\033[1A\033[K")
            sys.stdout.flush()
        print(self.color_text(f"关卡 {level} 启动！", Fore.GREEN))
        self._play_sound(frequency=800, duration=150)


    def show_boss(self):
        boss = """
        ╔══════ Boss 信号 ══════╗
        警告：检测到超强信号！
        准备解码，成功获高额奖励！
        ╚═══════════════════════╝
        """
        self._animate_text(boss, Fore.RED)
        self._play_sound(frequency=1000, duration=300) # Boss 出现时的特殊音效

    def show_store(self, score, available_items):
        print(self.color_text(f"\n╔══════ 星际商店（得分：{score}） ══════╗", Fore.CYAN))
        for i, item in enumerate(available_items, 1):
            print(f"{i}. {item['name']}（{item['cost']} 分）：{item['description']}")
        print("0. 离开商店")
        print(self.color_text("╚═══════════════════════════════╝", Fore.CYAN))

    def show_task_complete(self, reward):
        print(self.color_text(f"\n任务完成！奖励：{reward}", Fore.GREEN))
        self._play_sound(frequency=700, duration=100)

    def show_story(self, cores):
        stories = [
            "信号微弱，导航系统启动！",
            "导航修复，星域出口接近！",
            "核心齐全，飞船跃迁准备！",
            "能量不足，继续解码至 100%！"
        ]
        if cores <= len(stories):
            print(self.color_text(f"\n故事：{stories[cores-1]}", Fore.CYAN))

    def show_npc_dialogue(self, event_type=None, weather=None, task=None):
        weather_dialogues = {
            "clear": ["NPC: '晴朗天气，解码好时机！'", "NPC: '信号清晰，抓住机会！'"],
            "storm": ["NPC: '风暴干扰，抓紧解码！'", "NPC: '风暴来袭，小心超时！'"],
            "fog": ["NPC: '迷雾增加干扰，小心选择！'", "NPC: '迷雾中信号混乱，保持冷静！'"]
        }
        event_dialogues = {
            "interference": ["NPC: '信号干扰，时间减少！'", "NPC: '干扰增强，快速反应！'"],
            "fault": ["NPC: '系统故障，能量下降！'", "NPC: '飞船受损，检查能量！'"],
            "bonus": ["NPC: '能量脉冲，抓住机会！'", "NPC: '发现能量源，快解码！'"],
            "storm": ["NPC: '能量风暴，随机效果！'", "NPC: '风暴冲击，准备应对！'"],
            "merchant": ["NPC: '我是星际商人，换点装备？'", "NPC: '商人信号，来看看货！'"]
        }
        task_dialogues = {
            "strong_signals": ["NPC: '优先解码强信号，奖励更高！'", "NPC: '强信号是关键，继续！'"],
            "no_mistakes": ["NPC: '连续无误，证明你的技术！'", "NPC: '保持完美解码！'"]
        }
        if event_type:
            print(self.color_text(random.choice(event_dialogues[event_type]), Fore.RED if event_type in ["interference", "fault", "storm"] else Fore.GREEN))
        elif task:
            print(self.color_text(random.choice(task_dialogues[task["type"]]), Fore.BLUE))
        elif weather:
            print(self.color_text(random.choice(weather_dialogues[weather]), Fore.BLUE))
        else:
            dialogues = [
                "NPC: '你的技术让我刮目相看！'",
                "NPC: '冷静，我们会成功的！'",
                "NPC: '信号官，你的解码无人能敌！'",
                "NPC: '星域危机，靠你了！'",
                "NPC: '每一步都在接近胜利！'"
            ]
            print(self.color_text(random.choice(dialogues), Fore.BLUE))

    def show_hint(self, rule):
        hint = f"提示：规则“{rule}”。分析信号，忽略干扰！输入编号（如 1），'s' 保存，'i' 使用道具，'q' 退出。"
        print(self.color_text(hint, Fore.YELLOW))

    def show_ending(self, score, cores, levels_cleared, energy):
        if levels_cleared >= 3 and energy == 100.0 and score > 100:
            ending = "结局：星际传奇！你以完美能量和高分通关，成为信号官神话！"
            color = Fore.GREEN
        elif levels_cleared >= 3 and energy == 100.0:
            ending = "结局：险象环生！你成功通关，飞船成功跃迁！"
            color = Fore.YELLOW
        else:
            ending = "结局：信号失联！飞船未能逃脱，任务失败。"
            color = Fore.RED
        print(self.color_text(ending, color))

    def show_achievement(self, achievement):
        print(self.color_text(f"\n成就解锁：{achievement}！", Fore.GREEN))
        self._play_sound(frequency=900, duration=200)

    def show_rankings(self, rankings):
        print(self.color_text("\n╔══════ 排行榜 ══════╗", Fore.CYAN))
        for i, rank in enumerate(rankings, 1):
            print(f"{i}. 得分：{rank['score']} | 关卡：{rank['level']} | 模式：{rank['mode']} | 时间：{rank['time']}")
        print(self.color_text("╚═════════════════════╝", Fore.CYAN))

    def _animate_waveform(self, signal, strength):
        waveform_chars = []
        for char in signal:
            waveform_chars.append("█" if char.isdigit() else "▒")
        
        # 根据信号强度调整闪烁效果
        strength_mod = {"弱": 0.2, "中": 0.1, "强": 0.05}[strength]
        
        # 模拟波形闪烁 3 次
        for _ in range(3):
            print(self.color_text(" ".join(waveform_chars), Fore.GREEN))
            sys.stdout.flush()
            time.sleep(strength_mod)
            # 移动光标到上一行开头并清空
            sys.stdout.write("\033[1A\033[K")
            sys.stdout.flush()
        
        # 最终显示波形
        print(self.color_text(" ".join(waveform_chars), Fore.GREEN))
        if strength == "强":
            print(self.color_text("[滴滴！强信号！]", Fore.YELLOW))
            self._play_sound(frequency=500, duration=100) # 强信号提示音

    def _progress_bar(self, cores, total, energy_recovery_mode):
        filled = min(cores, total)
        bar = "█" * filled + "▒" * (total - filled) if not energy_recovery_mode else "█" * total
        return f"[{bar}]"
