import time
import random
import json
import os
from datetime import datetime
from .signal import SignalGenerator
from .display import Display

class StarSignalGame:
    def __init__(self, difficulty="easy", load_slot=None, practice=False):
        self.difficulty = difficulty
        self.practice = practice
        self.endless = False
        self.settings = {
            "easy": {"time_limit": 60, "options": 3, "energy_loss": 5, "signal_length": 5},
            "medium": {"time_limit": 45, "options": 4, "energy_loss": 10, "signal_length": 7},
            "hard": {"time_limit": 30, "options": 5, "energy_loss": 15, "signal_length": 10},
            "challenge": {"time_limit": 40, "options": 4, "energy_loss": 10, "signal_length": 8}
        }
        self.time_limit = self.settings[difficulty]["time_limit"]
        self.num_options = self.settings[difficulty]["options"]
        self.energy_loss = self.settings[difficulty]["energy_loss"]
        self.base_signal_length = self.settings[difficulty]["signal_length"]
        self.energy = 100.0
        self.score = 0
        self.cores = 0
        self.level = 1
        self.consecutive_correct = 0
        self.signal_generator = SignalGenerator(difficulty)
        self.display = Display(use_color=True)
        self.data_file = os.path.expanduser("~/.starsignal_data.json")
        self.skills = {"decode_speed": 1.0, "energy_recovery": 1.0}
        self.equipment = None
        self.items = []
        self.achievements = set()
        self.rankings = []
        self.unlocked_levels = [1]
        self.current_task = None
        self.task_progress = 0
        self.players = 1
        self.current_player = 1
        self.load_records()
        if load_slot:
            self.load_game(load_slot)
        self.check_permissions()

    def check_permissions(self):
        try:
            if os.path.exists(self.data_file):
                os.chmod(self.data_file, 0o666)
            for slot in range(1, 4):
                save_file = os.path.expanduser(f"~/.starsignal_save_{slot}.json")
                if os.path.exists(save_file):
                    os.chmod(save_file, 0o666)
        except PermissionError:
            print("警告：无法设置存档权限，请手动运行：chmod 666 ~/.starsignal*")

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
                self.items = data.get("items", [])
                self.rankings = data.get("rankings", [])
                self.unlocked_levels = data.get("unlocked_levels", [1])
        else:
            self.high_score = 0
            self.total_wins = 0
            self.achievements = set()
            self.equipment = None
            self.items = []
            self.rankings = []
            self.unlocked_levels = [1]

    def save_records(self):
        data = {
            "high_score": max(self.score, self.high_score),
            "total_wins": self.total_wins + (1 if self.level > 3 and self.energy == 100.0 else 0),
            "achievements": list(self.achievements),
            "equipment": self.equipment,
            "items": self.items,
            "rankings": sorted(
                self.rankings + [{
                    "score": self.score,
                    "level": self.level,
                    "mode": "无尽" if self.endless else self.difficulty,
                    "time": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                }],
                key=lambda x: x["score"], reverse=True
            )[:5],
            "unlocked_levels": self.unlocked_levels
        }
        with open(self.data_file, 'w') as f:
            json.dump(data, f, indent=2)
        os.chmod(self.data_file, 0o666)

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
                self.items = data.get("items", [])
                self.current_task = data.get("current_task", None)
                self.task_progress = data.get("task_progress", 0)
                self.players = data.get("players", 1)
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
            "items": self.items,
            "current_task": self.current_task,
            "task_progress": self.task_progress,
            "players": self.players
        }
        with open(save_file, 'w') as f:
            json.dump(data, f, indent=2)
        os.chmod(save_file, 0o666)
        print(f"游戏保存至槽位 {slot}！")

    def unlock_achievement(self, name):
        if name not in self.achievements:
            self.achievements.add(name)
            self.display.show_achievement(name)
            self.save_records()

    def upgrade_skill(self):
        skill = random.choice(["decode_speed", "energy_recovery"])
        self.skills[skill] += 0.3
        print(f"技能提升！{skill} 现在为 {self.skills[skill]:.1f}")

    def purchase_item(self, available_items):
        self.display.show_store(self.score, available_items)
        choice = input("选择装备或道具（0-{}）：".format(len(available_items))).strip()
        if choice == "0":
            return None
        try:
            choice = int(choice) - 1
            item = available_items[choice]
            if self.score >= item["cost"]:
                self.score -= item["cost"]
                if item["type"] == "equipment":
                    self.equipment = item["name"]
                    print(f"装备 {item['name']} 成功！")
                    return item["effect"]
                else:
                    self.items.append(item["name"])
                    print(f"获得道具 {item['name']}！")
                    return item["effect"]
            else:
                print("得分不足！")
        except (ValueError, IndexError):
            print("无效选择！")
        return None

    def use_item(self, signal_strength):
        if not self.items:
            print("无可用道具！")
            return False
        print("可用道具：", ", ".join(self.items))
        choice = input("输入道具名称（或 '取消'）：").strip().lower()
        if choice == "取消":
            return False
        if choice == "干扰器" and "干扰器" in self.items:
            self.items.remove("干扰器")
            print("使用干扰器，跳过当前信号！")
            return True
        elif choice == "能量电池" and "能量电池" in self.items:
            self.items.remove("能量电池")
            self.energy = min(self.energy + 20.0, 100.0)
            print("使用能量电池，能量 +20%！")
            return False
        else:
            print("无效道具！")
            return False

    def assign_task(self):
        if self.level >= 3:
            tasks = [
                {"type": "strong_signals", "description": "连续解码 3 次强信号", "count": 3, "reward": "30 分"},
                {"type": "no_mistakes", "description": "连续 5 次解码无误", "count": 5, "reward": "能量 +20"}
            ]
            self.current_task = random.choice(tasks)
            self.task_progress = 0
            return self.current_task
        return None

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
                self.energy = min(self.energy + int(reward.split()[1]), 100.0)
            self.current_task = None
            self.task_progress = 0

    def start(self):
        self.display.show_intro()
        if self.is_first_time():
            self.display.show_tutorial()

        has_progress = self.level > 1 or self.cores > 0 or self.score > 0
        self.display.show_mode_selection(self.unlocked_levels, has_progress and {"level": self.level}, self.total_wins > 0)
        mode = input("请输入（1-4）：").strip()

        if mode == "1":
            self.level = 1
            self.energy = 100.0
            self.score = 0
            self.cores = 0
            self.equipment = None
            self.items = []
            self.skills = {"decode_speed": 1.0, "energy_recovery": 1.0}
        elif mode == "2" and not has_progress:
            print("无进度，从关卡 1 开始！")
            self.level = 1
        elif mode == "3":
            print(f"已解锁关卡：{', '.join(map(str, self.unlocked_levels))}")
            level = input("选择关卡（输入编号）：").strip()
            if level.isdigit() and int(level) in self.unlocked_levels:
                self.level = int(level)
                self.energy = 100.0
                self.score = 0
                self.cores = 0
                self.equipment = None
                self.items = []
            else:
                print("无效或未解锁关卡，从关卡 1 开始！")
                self.level = 1
        elif mode == "4" and self.total_wins > 0:
            self.endless = True
            self.level = 1
            self.energy = 100.0
            self.score = 0
            self.cores = 0
            self.equipment = None
            self.items = []
        else:
            print("无效选择，从关卡 1 开始！")
            self.level = 1

        play_style = input("玩法：1) 单人 2) 双人 [1]：").strip() or "1"
        if play_style == "2":
            self.players = 2
            print("双人模式启动！连续正确触发连携加成！")
            self.unlock_achievement("双人冒险者")
        else:
            self.players = 1

        core_targets = [1, 2, 3]
        max_level = 3 if not self.endless else float("inf")

        while self.level <= max_level and self.energy > 0:
            core_target = core_targets[min(self.level - 1, len(core_targets) - 1)]
            self.cores = 0
            self.display.show_level_transition(self.level)
            if not self.current_task and self.level >= 3:
                self.assign_task()

            is_boss = False
            signals_decoded = 0
            max_signals = 5 if self.level < 3 else 7
            energy_recovery_mode = False

            while (self.cores < core_target or (self.cores >= core_target and self.energy < 100.0)) and self.energy > 0:
                if self.cores >= core_target and not energy_recovery_mode:
                    energy_recovery_mode = True
                    print(self.color_text("核心收集完成！需恢复能量至 100.0%！", Fore.YELLOW))
                    self.display.show_story(4)

                if signals_decoded >= max_signals and not is_boss and not energy_recovery_mode:
                    is_boss = True
                    self.display.show_boss()

                weather = random.choice(["clear"] if self.level == 1 else ["clear", "storm", "fog"])
                signal_length = 12 if is_boss else self.base_signal_length + self.level * 2
                signal, rule, answer, distractors, strength = self.signal_generator.generate_signal(self.num_options, signal_length)
                options = distractors + [answer]
                random.shuffle(options)

                event = random.choices(
                    ["none", "interference", "fault", "bonus", "storm", "merchant"],
                    weights=[40, 15, 10, 10, 15, 10]
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
                    self.energy -= adjusted_energy_loss / 2
                elif event == "bonus":
                    self.score += 5 * strength
                elif event == "storm":
                    effect = random.choice(["energy_loss", "energy_gain"])
                    if effect == "energy_loss":
                        self.energy -= 10.0
                        print("能量风暴！能量 -10%！")
                    else:
                        self.energy = min(self.energy + 10.0, 100.0)
                        print("能量风暴！能量 +10%！")
                elif event == "merchant":
                    item = self.purchase_item(self.get_available_items())
                    if item:
                        if "time_limit" in item:
                            adjusted_time_limit += item["time_limit"]
                        elif "energy_loss" in item:
                            adjusted_energy_loss = max(5, adjusted_energy_loss + item["energy_loss"])

                if self.equipment:
                    if self.equipment == "信号放大器":
                        adjusted_time_limit += 10
                    elif self.equipment == "能量护盾":
                        adjusted_energy_loss = max(5, adjusted_energy_loss - 5)
                    elif self.equipment == "快速解码器":
                        self.skills["decode_speed"] += 0.3

                if self.players > 1:
                    print(self.color_text(f"\n玩家 {self.current_player} 的回合", Fore.CYAN))

                self.display.show_signal(
                    signal, rule, options, self.energy, self.score, self.cores,
                    core_target, self.level, strength, weather, self.equipment, self.items, self.current_task, energy_recovery_mode
                )
                
                start_time = time.time()
                choice = input("请输入（1-{}, s 保存，h 提示，i 使用道具，q 退出）：".format(self.num_options)).strip()
                
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
                elif choice.lower() == 'i':
                    if self.use_item(strength):
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
                            self.energy -= adjusted_energy_loss * strength
                        self.consecutive_correct = 0
                    elif 0 <= choice < self.num_options and options[choice] == answer:
                        print("解码成功！飞船前进！")
                        correct = True
                        energy_gain = [10.0, 12.0, 15.0][strength - 1] * self.skills["energy_recovery"]
                        score_gain = (10 * strength + (30 if is_boss else 0))
                        if energy_recovery_mode:
                            energy_gain *= 1.5  # 恢复阶段能量奖励增加
                            score_gain //= 2  # 减少得分
                        self.score += score_gain
                        self.energy = min(self.energy + energy_gain, 100.0)
                        if not energy_recovery_mode:
                            self.cores += 1
                        self.consecutive_correct += 1
                        if self.consecutive_correct >= 3:
                            self.unlock_achievement("快速解码者")
                        if is_boss:
                            self.unlock_achievement("Boss 终结者")
                        if self.players > 1 and self.consecutive_correct >= 2:
                            self.score += 10
                            self.energy = min(self.energy + 5.0, 100.0)
                            print("连携加成！+10 分，+5% 能量！")
                            self.unlock_achievement("连携大师")
                        if random.random() < 0.3:
                            self.upgrade_skill()
                    else:
                        print(f"解码失败！正确答案是 {answer}。")
                        if not self.practice:
                            self.energy -= adjusted_energy_loss * strength
                        self.consecutive_correct = 0
                except (ValueError, IndexError):
                    print("无效输入！请输入正确选项编号。")
                    if not self.practice:
                        self.energy -= 5.0
                    self.consecutive_correct = 0

                self.check_task_progress(strength, correct)
                self.display.show_status(self.energy, self.score, self.cores, self.level)
                if self.energy <= 0:
                    break

                if self.players > 1:
                    self.current_player = 2 if self.current_player == 1 else 1

            if self.energy <= 0:
                print("游戏结束！飞船能量耗尽！")
                break
            if self.cores >= core_target and self.energy == 100.0:
                self.display.show_story(self.cores)
                if self.level == 3 and not self.endless:
                    if self.score > 100:
                        self.unlock_achievement("完美通关")
                    self.unlock_achievement("星域征服者")
                self.unlocked_levels = list(set(self.unlocked_levels + [self.level + 1]))
                self.level += 1
                if self.level <= 3 and not self.endless:
                    item = self.purchase_item(self.get_available_items())
                    if item:
                        if "time_limit" in item:
                            self.time_limit += item["time_limit"]
                        elif "energy_loss" in item:
                            self.energy_loss = max(5, self.energy_loss + item["energy_loss"])
                    self.energy = min(self.energy + 10.0, 100.0)
                    print("关卡奖励：能量 +10%！")
                if self.endless:
                    self.base_signal_length += 1
                    self.num_options = min(self.num_options + 1, 6)

        self.display.show_ending(self.score, self.cores, self.level - 1, self.energy)
        self.save_records()
        print(f"最终得分：{self.score} | 核心：{self.cores} | 关卡：{self.level - 1}")
        print(f"最高分：{self.high_score} | 通关次数：{self.total_wins}")
        if self.achievements:
            print(f"成就：{', '.join(self.achievements)}")
        if self.rankings:
            self.display.show_rankings(self.rankings)

    def get_available_items(self):
        items = [
            {"name": "信号放大器", "cost": 50, "type": "equipment", "effect": {"time_limit": 10}, "description": "增加 10 秒解码时间"},
            {"name": "能量护盾", "cost": 40, "type": "equipment", "effect": {"energy_loss": -5}, "description": "减少 5 点能量损失"},
            {"name": "快速解码器", "cost": 60, "type": "equipment", "effect": {"decode_speed": 0.3}, "description": "提升 0.3 解码速度"},
            {"name": "能量电池", "cost": 30, "type": "item", "effect": {"energy": 20}, "description": "使用后恢复 20% 能量"},
        ]
        if self.level >= 2:
            items.append({"name": "干扰器", "cost": 50, "type": "item", "effect": {"skip": True}, "description": "跳过当前信号"})
        return items
