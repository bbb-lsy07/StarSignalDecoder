import time
import random
import json
import os
from .signal import SignalGenerator
from .display import Display

class StarSignalGame:
    def __init__(self, difficulty="easy", load_slot=None, practice=False, endless=False):
        self.difficulty = difficulty
        self.practice = practice
        self.endless = endless
        self.settings = {
            "easy": {"time_limit": 60, "options": 3, "energy_loss": 10},
            "medium": {"time_limit": 45, "options": 4, "energy_loss": 15},
            "hard": {"time_limit": 30, "options": 5, "energy_loss": 20},
            "challenge": {"time_limit": 40, "options": 4, "energy_loss": 15}
        }
        self.time_limit = self.settings[difficulty]["time_limit"]
        self.num_options = self.settings[difficulty]["options"]
        self.energy_loss = self.settings[difficulty]["energy_loss"]
        self.energy = 100
        self.score = 0
        self.cores = 0
        self.level = 1
        self.consecutive_correct = 0
        self.signal_generator = SignalGenerator(difficulty)
        self.display = Display(use_color=True)
        self.data_file = os.path.expanduser("~/.starsignal_data.json")
        self.skills = {"decode_speed": 1.0, "energy_recovery": 1.0}
        self.equipment = None
        self.achievements = set()
        self.rankings = []
        self.current_task = None
        self.task_progress = 0
        self.load_records()
        if load_slot:
            self.load_game(load_slot)

    def is_first_time(self):
        return not os.path.exists(self.data_file)

    def load_records(self):
        if os.path.exists(self.data_file):
            with open(self.data_file, 'r') as f:
                data = json.load(f)
                self.high_score = data.get("high_score", 0)
                self.total_wins = data.get("total_wins", 0)
                self.achievements = set(data.get("achievements", []))
                self.equipment = data.get("equipment", None)
                self.rankings = data.get("rankings", [])
        else:
            self.high_score = 0
            self.total_wins = 0
            self.achievements = set()
            self.equipment = None
            self.rankings = []

    def save_records(self):
        data = {
            "high_score": max(self.score, self.high_score),
            "total_wins": self.total_wins + (1 if self.level > 3 else 0),
            "achievements": list(self.achievements),
            "equipment": self.equipment,
            "rankings": sorted(
                self.rankings + [{"score": self.score, "level": self.level, "mode": "无尽" if self.endless else self.difficulty}],
                key=lambda x: x["score"], reverse=True
            )[:5]
        }
        with open(self.data_file, 'w') as f:
            json.dump(data, f, indent=2)

    def load_game(self, slot):
        save_file = os.path.expanduser(f"~/.starsignal_save_{slot}.json")
        try:
            with open(save_file, 'r') as f:
                data = json.load(f)
                self.energy = data["energy"]
                self.score = data["score"]
                self.cores = data["cores"]
                self.level = data["level"]
                self.skills = data.get("skills", {"decode_speed": 1.0, "energy_recovery": 1.0})
                self.equipment = data.get("equipment", None)
                self.current_task = data.get("current_task", None)
                self.task_progress = data.get("task_progress", 0)
            print(f"存档槽位 {slot} 加载成功！")
        except (FileNotFoundError, json.JSONDecodeError):
            print(f"无法加载槽位 {slot}，从新游戏开始。")

    def save_game(self, slot):
        save_file = os.path.expanduser(f"~/.starsignal_save_{slot}.json")
        data = {
            "energy": self.energy,
            "score": self.score,
            "cores": self.cores,
            "level": self.level,
            "skills": self.skills,
            "difficulty": self.difficulty,
            "equipment": self.equipment,
            "current_task": self.current_task,
            "task_progress": self.task_progress
        }
        with open(save_file, 'w') as f:
            json.dump(data, f, indent=2)
        print(f"游戏保存至槽位 {slot}（{save_file}）！")

    def unlock_achievement(self, name):
        if name not in self.achievements:
            self.achievements.add(name)
            self.display.show_achievement(name)
            self.save_records()

    def upgrade_skill(self):
        skill = random.choice(["decode_speed", "energy_recovery"])
        self.skills[skill] += 0.3
        print(f"技能提升！{skill} 现在为 {self.skills[skill]:.1f}")

    def equip_gear(self, available_gear):
        self.display.show_store(self.score, available_gear)
        choice = input("选择装备（0-{}）：".format(len(available_gear))).strip()
        if choice == "0":
            return None
        try:
            choice = int(choice) - 1
            gear = available_gear[choice]
            if self.score >= gear["cost"]:
                self.score -= gear["cost"]
                self.equipment = gear["name"]
                print(f"装备 {gear['name']} 成功！")
                return gear["effect"]
            else:
                print("得分不足！")
        except (ValueError, IndexError):
            print("无效选择！")
        return None

    def assign_task(self):
        tasks = [
            {"type": "strong_signals", "description": "连续解码 3 次强信号", "count": 3, "reward": "30 分"},
            {"type": "no_mistakes", "description": "连续 5 次解码无误", "count": 5, "reward": "能量 +20"}
        ]
        self.current_task = random.choice(tasks)
        self.task_progress = 0
        return self.current_task

    def check_task_progress(self, signal_strength, correct):
        if not self.current_task:
            return
        if self.current_task["type"] == "strong_signals" and signal_strength == 3 and correct:
            self.task_progress += 1
        elif self.current_task["type"] == "no_mistakes" and correct:
            self.task_progress += 1
        elif self.current_task["type"] == "no_mistakes" and not correct:
            self.task_progress = 0
        if self.task_progress >= self.current_task["count"]:
            reward = self.current_task["reward"]
            self.display.show_task_complete(reward)
            if "分" in reward:
                self.score += int(reward.split()[0])
            elif "能量" in reward:
                self.energy = min(self.energy + int(reward.split()[1]), 100)
            self.current_task = None
            self.task_progress = 0

    def start(self):
        if self.endless and self.total_wins == 0:
            print("需通关一次以解锁无尽模式！")
            return

        self.display.show_intro()
        if self.is_first_time():
            self.display.show_tutorial()

        players = 1
        play_style = input("玩法：1) 单人 2) 双人 3) 冒险模式 [1]：").strip() or "1"
        if play_style == "2":
            players = 2
            print("双人模式启动！玩家轮流解码，连续正确触发连携加成！")
            self.unlock_achievement("双人冒险者")
        elif play_style == "3":
            self.adventure_mode = True
            print("冒险模式启动！选择影响剧情！")
        else:
            self.adventure_mode = False

        core_targets = [1, 2, 3]  # 每关核心数
        max_level = 3 if not self.endless else float("inf")

        while self.level <= max_level and self.energy > 0:
            core_target = core_targets[min(self.level - 1, len(core_targets) - 1)]
            self.cores = 0
            self.display.show_level_transition(self.level)
            if not self.current_task:
                self.assign_task()

            is_boss = False
            signals_decoded = 0
            max_signals = 5 if self.level < 3 else 7

            while self.cores < core_target and self.energy > 0:
                if signals_decoded >= max_signals and not is_boss:
                    is_boss = True
                    self.display.show_boss()

                weather = random.choice(["clear", "storm", "fog"])
                signal_length = 10 if is_boss else 5 + self.level * 2
                signal, rule, answer, distractors, strength = self.signal_generator.generate_signal(self.num_options, signal_length)
                options = distractors + [answer]
                random.shuffle(options)

                event = random.choices(
                    ["none", "interference", "fault", "bonus", "merchant"],
                    weights=[50, 20, 10, 10, 10]
                )[0]
                self.display.show_npc_dialogue(event, weather, self.current_task)
                
                adjusted_time_limit = self.time_limit / self.skills["decode_speed"]
                adjusted_energy_loss = self.energy_loss
                if weather == "storm":
                    adjusted_time_limit *= 0.8
                elif weather == "fog":
                    self.num_options = min(self.num_options + 1, 6)
                if event == "interference":
                    adjusted_time_limit = max(10, adjusted_time_limit - 10)
                elif event == "fault":
                    self.energy -= adjusted_energy_loss // 2
                elif event == "bonus":
                    self.score += 5 * strength
                elif event == "merchant":
                    gear = self.equip_gear(self.get_available_gear())
                    if gear:
                        if "time_limit" in gear:
                            adjusted_time_limit += gear["time_limit"]
                        elif "energy_loss" in gear:
                            adjusted_energy_loss = max(5, adjusted_energy_loss + gear["energy_loss"])

                if self.equipment:
                    if self.equipment == "信号放大器":
                        adjusted_time_limit += 10
                    elif self.equipment == "能量护盾":
                        adjusted_energy_loss = max(5, adjusted_energy_loss - 5)
                    elif self.equipment == "快速解码器":
                        self.skills["decode_speed"] += 0.3

                self.display.show_signal(
                    signal, rule, options, self.energy, self.score, self.cores,
                    core_target, self.level, strength, weather, self.equipment, self.current_task
                )
                
                start_time = time.time()
                choice = input("请输入（1-{}，s 保存，h 提示，q 退出）：".format(self.num_options)).strip()
                
                if choice.lower() == 's':
                    slot = input("选择存档槽位（1-3）：").strip()
                    if slot in ["1", "2", "3"]:
                        self.save_game(int(slot))
                    else:
                        print("无效槽位！")
                    continue
                elif choice.lower() == 'h':
                    self.display.show_hint(rule)
                    continue
                elif choice.lower() == 'q':
                    print("游戏退出！")
                    self.save_records()
                    return

                signals_decoded += 1
                correct = False
                try:
                    choice = int(choice) - 1
                    elapsed_time = time.time() - start_time

                    if elapsed_time > adjusted_time_limit:
                        print("时间到！信号丢失！")
                        if not self.practice:
                            self.energy -= adjusted_energy_loss // strength
                        self.consecutive_correct = 0
                    elif 0 <= choice < self.num_options and options[choice] == answer:
                        print("解码成功！飞船前进！")
                        correct = True
                        self.score += (10 * strength + (20 if is_boss else 0))
                        self.energy = min(self.energy + 5 * self.skills["energy_recovery"], 100)
                        self.cores += 1
                        self.consecutive_correct += 1
                        if self.consecutive_correct >= 3:
                            self.unlock_achievement("快速解码者")
                        if is_boss:
                            self.unlock_achievement("Boss 终结者")
                        if players > 1 and self.consecutive_correct % 2 == 0:
                            self.score += 10
                            print("连携加成！额外 10 分！")
                        if random.random() < 0.3:
                            self.upgrade_skill()
                    else:
                        print(f"解码失败！正确答案是 {answer}。")
                        if not self.practice:
                            self.energy -= adjusted_energy_loss * strength
                        self.consecutive_correct = 0
                except (ValueError, IndexError):
                    print("无效输入！")
                    if not self.practice:
                        self.energy -= adjusted_energy_loss // 2
                    self.consecutive_correct = 0

                self.check_task_progress(strength, correct)
                self.display.show_status(self.energy, self.score, self.cores, self.level)
                if self.energy <= 0 or (self.cores >= core_target and not self.endless):
                    break

                if self.adventure_mode and random.random() < 0.3:
                    choice = input("未知信号！1) 冒险探索 2) 保守绕行 [1]：").strip() or "1"
                    if choice == "1":
                        self.score += 10
                        print("探索成功！发现能量！")
                    else:
                        self.energy -= 5
                        print("绕行耗费能量，避开风险。")

            if self.energy <= 0:
                print("游戏结束！飞船能量耗尽！")
                break
            if self.cores >= core_target:
                self.display.show_story(self.level)
                if self.level == 3 and not self.endless:
                    self.unlock_achievement("星域征服者")
                    if self.energy >= 80:
                        self.unlock_achievement("完美通关")
                self.level += 1
                if self.level <= 3 and not self.endless:
                    gear = self.equip_gear(self.get_available_gear())
                    if gear:
                        if "time_limit" in gear:
                            self.time_limit += gear["time_limit"]
                        elif "energy_loss" in gear:
                            self.energy_loss = max(5, self.energy_loss + gear["energy_loss"])
                    self.energy = min(self.energy + 20, 100)
                    print("关卡奖励：能量 +20！")

        self.display.show_ending(self.score, self.cores, self.level - 1)
        self.save_records()
        print(f"最终得分：{self.score} | 核心：{self.cores} | 关卡：{self.level - 1}")
        print(f"最高分：{self.high_score} | 通关次数：{self.total_wins}")
        if self.achievements:
            print(f"成就：{', '.join(self.achievements)}")
        if self.rankings:
            self.display.show_rankings(self.rankings)

    def get_available_gear(self):
        return [
            {"name": "信号放大器", "cost": 50, "effect": {"time_limit": 10}, "description": "增加 10 秒解码时间"},
            {"name": "能量护盾", "cost": 40, "effect": {"energy_loss": -5}, "description": "减少 5 点能量损失"},
            {"name": "快速解码器", "cost": 60, "effect": {"decode_speed": 0.3}, "description": "提升 0.3 解码速度"}
        ]
