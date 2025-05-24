import time
import random
import json
import os
from .signal import SignalGenerator
from .display import Display

class StarSignalGame:
    def __init__(self, difficulty="easy", load_file=None):
        self.difficulty = difficulty
        self.settings = {
            "easy": {"time_limit": 60, "options": 3, "energy_loss": 10},
            "medium": {"time_limit": 45, "options": 4, "energy_loss": 15},
            "hard": {"time_limit": 30, "options": 5, "energy_loss": 20}
        }
        self.time_limit = self.settings[difficulty]["time_limit"]
        self.num_options = self.settings[difficulty]["options"]
        self.energy_loss = self.settings[difficulty]["energy_loss"]
        self.energy = 100
        self.score = 0
        self.cores = 0
        self.story_stage = 0
        self.signal_generator = SignalGenerator(difficulty)
        self.display = Display(use_color=True)
        self.data_file = os.path.expanduser("~/.starsignal_data.json")
        self.skills = {"decode_speed": 1.0, "energy_recovery": 1.0}
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
        else:
            self.high_score = 0
            self.total_wins = 0

    def save_records(self):
        data = {
            "high_score": max(self.score, self.high_score),
            "total_wins": self.total_wins + (1 if self.cores >= 3 else 0)
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
            "difficulty": self.difficulty
        }
        with open(file, 'w') as f:
            json.dump(data, f)
        print(f"游戏已保存至 {file}！")

    def upgrade_skill(self):
        skill = random.choice(["decode_speed", "energy_recovery"])
        self.skills[skill] += 0.3
        print(f"技能提升！{skill} 现在为 {self.skills[skill]:.1f}")

    def start(self):
        self.display.show_intro()
        if self.story_stage == 0 or self.is_first_time():
            self.display.show_tutorial()

        players = 1
        if input("开启双人模式？(y/n)：").lower() == 'y':
            players = 2
            print("双人模式启动！玩家轮流解码，共享飞船状态。")

        while self.energy > 0 and self.cores < 3:
            for player in range(1, players + 1):
                if players > 1:
                    print(f"\n玩家 {player} 的回合")

                signal, rule, answer, distractors, strength = self.signal_generator.generate_signal(self.num_options)
                options = distractors + [answer]
                random.shuffle(options)

                # Random event
                event = random.choices(
                    ["none", "interference", "fault", "bonus"],
                    weights=[60, 20, 10, 10]
                )[0]
                self.display.show_npc_dialogue(event)
                adjusted_time_limit = self.time_limit / self.skills["decode_speed"]
                if event == "interference":
                    adjusted_time_limit = max(10, adjusted_time_limit - 10)
                elif event == "fault":
                    self.energy -= self.energy_loss // 2
                elif event == "bonus":
                    self.score += 5 * strength

                self.display.show_signal(signal, rule, options, self.energy, self.score, self.cores, self.story_stage, strength)
                
                start_time = time.time()
                choice = input("请输入选项编号（1-{}）、's' 保存、'h' 提示、'q' 退出：".format(self.num_options))
                
                if choice.lower() == 's':
                    save_file = input("输入存档文件名（如 save.json）：")
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
                        self.energy -= self.energy_loss // strength
                    elif 0 <= choice < self.num_options and options[choice] == answer:
                        print("信号解码成功！飞船前进！")
                        self.score += 10 * strength
                        self.energy = min(self.energy + 5 * self.skills["energy_recovery"], 100)
                        self.cores += 1
                        self.story_stage += 1
                        self.display.show_story(self.story_stage)
                        if random.random() < 0.3:
                            self.upgrade_skill()
                    else:
                        print(f"解码失败！正确答案是 {answer}。")
                        self.energy -= self.energy_loss * strength
                except (ValueError, IndexError):
                    print("无效输入！请输入正确选项编号。")
                    self.energy -= self.energy_loss // 2

                self.display.show_status(self.energy, self.score, self.cores)
                if self.energy <= 0 or self.cores >= 3:
                    break

            if self.energy <= 0:
                print("游戏结束！飞船能量耗尽！")
                break
            if self.cores >= 3:
                break

        self.display.show_ending(self.score, self.cores)
        self.save_records()
        print(f"最终得分：{self.score} | 能量核心：{self.cores}")
        print(f"历史最高分：{self.high_score} | 通关次数：{self.total_wins}")
