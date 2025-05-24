import time
import random
import json
import os
from .signal import SignalGenerator
from .display import Display

class StarSignalGame:
    def __init__(self, difficulty="easy", load_file=None, practice=False):
        self.difficulty = difficulty
        self.practice = practice
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
        self.story_stage = 0
        self.consecutive_correct = 0
        self.signal_generator = SignalGenerator(difficulty)
        self.display = Display(use_color=True)
        self.data_file = os.path.expanduser("~/.starsignal_data.json")
        self.skills = {"decode_speed": 1.0, "energy_recovery": 1.0}
        self.equipment = None
        self.achievements = set()
        self.load_records()
        if load_file:
            self.load_game(load_file)

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
        else:
            self.high_score = 0
            self.total_wins = 0
            self.achievements = set()
            self.equipment = None

    def save_records(self):
        data = {
            "high_score": max(self.score, self.high_score),
            "total_wins": self.total_wins + (1 if self.cores >= 3 else 0),
            "achievements": list(self.achievements),
            "equipment": self.equipment
        }
        with open(self.data_file, 'w') as f:
            json.dump(data, f)

    def load_game(self, file):
        try:
            with open(file, 'r') as f:
                data = json.load(f)
                self.energy = data["energy"]
                self.score = data["score"]
                self.cores = data["cores"]
                self.story_stage = data["story_stage"]
                self.skills = data.get("skills", {"decode_speed": 1.0, "energy_recovery": 1.0})
                self.equipment = data.get("equipment", None)
            print(f"存档 {file} 加载成功！")
        except (FileNotFoundError, json.JSONDecodeError):
            print(f"无法加载存档 {file}，从新游戏开始。")

    def save_game(self, file):
        data = {
            "energy": self.energy,
            "score": self.score,
            "cores": self.cores,
            "story_stage": self.story_stage,
            "skills": self.skills,
            "difficulty": self.difficulty,
            "equipment": self.equipment
        }
        with open(file, 'w') as f:
            json.dump(data, f)
        print(f"游戏已保存至 {file}！")

    def unlock_achievement(self, name):
        if name not in self.achievements:
            self.achievements.add(name)
            self.display.show_achievement(name)
            self.save_records()

    def upgrade_skill(self):
        skill = random.choice(["decode_speed", "energy_recovery"])
        self.skills[skill] += 0.3
        print(f"技能提升！{skill} 现在为 {self.skills[skill]:.1f}")

    def equip_gear(self):
        available_gear = [
            {"name": "信号放大器", "cost": 50, "effect": {"time_limit": 10}},
            {"name": "能量护盾", "cost": 40, "effect": {"energy_loss": -5}},
            {"name": "快速解码器", "cost": 60, "effect": {"decode_speed": 0.3}}
        ]
        if self.score >= min(g["cost"] for g in available_gear):
            print("\n可用装备：")
            for i, gear in enumerate(available_gear, 1):
                print(f"{i}. {gear['name']}（{gear['cost']} 分）")
            choice = input("选择装备编号（1-{}）或按回车跳过：".format(len(available_gear)))
            if choice.isdigit() and 1 <= int(choice) <= len(available_gear):
                gear = available_gear[int(choice) - 1]
                if self.score >= gear["cost"]:
                    self.score -= gear["cost"]
                    self.equipment = gear["name"]
                    print(f"装备 {gear['name']} 成功！")
                    return gear["effect"]
        return None

    def start(self):
        self.display.show_intro()
        if self.story_stage == 0 or self.is_first_time():
            self.display.show_tutorial()

        players = 1
        play_style = input("选择玩法：1) 单人 2) 双人 3) 冒险模式（剧情分支）[1]：").strip() or "1"
        if play_style == "2":
            players = 2
            print("双人模式启动！玩家轮流解码，共享飞船状态。")
            self.unlock_achievement("双人冒险者")
        elif play_style == "3":
            self.adventure_mode = True
            print("冒险模式启动！你的选择将影响剧情！")
        else:
            self.adventure_mode = False

        while self.energy > 0 and self.cores < 3:
            for player in range(1, players + 1):
                if players > 1:
                    print(f"\n玩家 {player} 的回合")

                weather = random.choice(["clear", "storm", "fog"])
                signal, rule, answer, distractors, strength = self.signal_generator.generate_signal(self.num_options)
                options = distractors + [answer]
                random.shuffle(options)

                event = random.choices(
                    ["none", "interference", "fault", "bonus"],
                    weights=[60, 20, 10, 10]
                )[0]
                self.display.show_npc_dialogue(event, weather)
                
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

                if self.equipment:
                    if self.equipment == "信号放大器":
                        adjusted_time_limit += 10
                    elif self.equipment == "能量护盾":
                        adjusted_energy_loss = max(5, adjusted_energy_loss - 5)
                    elif self.equipment == "快速解码器":
                        self.skills["decode_speed"] += 0.3

                self.display.show_signal(signal, rule, options, self.energy, self.score, self.cores, self.story_stage, strength, weather, self.equipment)
                
                start_time = time.time()
                choice = input("请输入（1-{}，s 保存，h 提示，q 退出）：".format(self.num_options)).strip()
                
                if choice.lower() == 's':
                    save_file = input("存档文件名（如 save.json）：")
                    self.save_game(save_file)
                    continue
                elif choice.lower() == 'h':
                    self.display.show_hint(rule)
                    continue
                elif choice.lower() == 'q':
                    print("游戏退出！")
                    self.save_records()
                    return

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
                        self.score += 10 * strength
                        self.energy = min(self.energy + 5 * self.skills["energy_recovery"], 100)
                        self.cores += 1
                        self.story_stage += 1
                        self.consecutive_correct += 1
                        self.display.show_story(self.story_stage)
                        if self.consecutive_correct >= 3:
                            self.unlock_achievement("快速解码者")
                        if random.random() < 0.3:
                            self.upgrade_skill()
                        if self.score >= 40 and random.random() < 0.5:
                            effect = self.equip_gear()
                            if effect:
                                if "time_limit" in effect:
                                    adjusted_time_limit += effect["time_limit"]
                                elif "energy_loss" in effect:
                                    adjusted_energy_loss = max(5, adjusted_energy_loss + effect["energy_loss"])
                                elif "decode_speed" in effect:
                                    self.skills["decode_speed"] += effect["decode_speed"]
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

                self.display.show_status(self.energy, self.score, self.cores)
                if self.energy <= 0 or self.cores >= 3:
                    break

                if self.adventure_mode and random.random() < 0.3:
                    choice = input("发现未知信号！1) 冒险探索 2) 保守绕行 [1]：").strip() or "1"
                    if choice == "1":
                        self.score += 10
                        print("探索成功！发现额外能量！")
                    else:
                        self.energy -= 5
                        print("绕行耗费能量，但避开风险。")

            if self.energy <= 0:
                print("游戏结束！飞船能量耗尽！")
                break
            if self.cores >= 3:
                if players > 1:
                    self.unlock_achievement("双人传奇")
                break

        self.display.show_ending(self.score, self.cores)
        self.save_records()
        print(f"最终得分：{self.score} | 核心：{self.cores}")
        print(f"最高分：{self.high_score} | 通关次数：{self.total_wins}")
        if self.achievements:
            print(f"成就：{', '.join(self.achievements)}")
