import time
import random
import json
import os
from datetime import datetime
from .signal import SignalGenerator
from .display import Display
import sys

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
        
        # 确保目录存在
        self.data_dir = os.path.expanduser("~")
        if not os.path.exists(self.data_dir):
            os.makedirs(self.data_dir, exist_ok=True) # 通常 home 目录是存在的，但以防万一
        self.data_file = os.path.join(self.data_dir, ".starsignal_data.json")
        
        self.skills = {"decode_speed": 1.0, "energy_recovery": 1.0}
        self.equipment = None
        self.items = []
        self.achievements = set()
        self.rankings = []
        self.unlocked_levels = [1] # 默认解锁关卡1
        self.current_task = None
        self.task_progress = 0
        self.players = 1
        self.current_player = 1
        
        self.load_records() # 先加载全局记录，再看是否加载存档
        if load_slot:
            self.load_game(load_slot)
        self.check_permissions() # 检查并修复文件权限

    def check_permissions(self):
        """检查并尝试修复存档文件权限"""
        try:
            if os.path.exists(self.data_file):
                os.chmod(self.data_file, 0o666)
            for slot in range(1, 4):
                save_file = os.path.join(self.data_dir, f".starsignal_save_{slot}.json")
                if os.path.exists(save_file):
                    os.chmod(save_file, 0o666)
        except PermissionError:
            print("警告：无法设置存档权限，请手动运行：chmod 666 ~/.starsignal*")
        except Exception as e:
            print(f"检查权限时发生错误: {e}")

    def is_first_time(self):
        """判断是否是第一次运行游戏"""
        return not os.path.exists(self.data_file)

    def load_records(self):
        """加载游戏全局记录（成就、排行榜等）"""
        if os.path.exists(self.data_file):
            try:
                with open(self.data_file, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    self.high_score = data.get("high_score", 0)
                    self.total_wins = data.get("total_wins", 0)
                    self.achievements = set(data.get("achievements", []))
                    self.equipment = data.get("equipment", None)
                    self.items = data.get("items", [])
                    self.rankings = data.get("rankings", [])
                    self.unlocked_levels = data.get("unlocked_levels", [1])
            except (FileNotFoundError, json.JSONDecodeError, UnicodeDecodeError) as e:
                print(f"警告：加载全局记录文件失败 ({e})，将创建新文件。")
                self._reset_records() # 文件损坏，重置
        else:
            self._reset_records()

    def _reset_records(self):
        """重置全局记录为默认值"""
        self.high_score = 0
        self.total_wins = 0
        self.achievements = set()
        self.equipment = None
        self.items = []
        self.rankings = []
        self.unlocked_levels = [1]

    def save_records(self):
        """保存游戏全局记录"""
        data = {
            "high_score": max(self.score, self.high_score),
            "total_wins": self.total_wins + (1 if self.level > 3 and self.energy == 100.0 else 0), # 只有通关3关且能量100%才算一次通关
            "achievements": list(self.achievements),
            "equipment": self.equipment, # 保存当前装备和道具
            "items": self.items,
            "rankings": sorted(
                self.rankings + [{ # 将本次成绩加入排行榜
                    "score": self.score,
                    "level": self.level -1 if not self.endless else self.level, # 最终通关的关卡数
                    "mode": "无尽" if self.endless else self.difficulty,
                    "time": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                }],
                key=lambda x: x["score"], reverse=True
            )[:5], # 只保留前5名
            "unlocked_levels": sorted(list(set(self.unlocked_levels))) # 保存已解锁关卡，并去重排序
        }
        try:
            with open(self.data_file, 'w', encoding='utf-8') as f:
                json.dump(data, f, indent=2, ensure_ascii=False)
            os.chmod(self.data_file, 0o666)
        except Exception as e:
            print(f"错误：保存全局记录文件失败: {e}")

    def load_game(self, slot):
        """加载指定存档槽位游戏"""
        save_file = os.path.join(self.data_dir, f".starsignal_save_{slot}.json")
        try:
            with open(save_file, 'r', encoding='utf-8') as f:
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
                self.difficulty = data.get("difficulty", self.difficulty) # 加载难度
                self.time_limit = self.settings[self.difficulty]["time_limit"]
                self.num_options = self.settings[self.difficulty]["options"]
                self.energy_loss = self.settings[self.difficulty]["energy_loss"]
                self.base_signal_length = self.settings[self.difficulty]["signal_length"]
            print(f"存档槽位 {slot} 加载成功！")
        except (FileNotFoundError, json.JSONDecodeError, UnicodeDecodeError):
            print(f"无法加载槽位 {slot}，将从新游戏开始。")
            self._reset_game_state() # 重置当前游戏状态
        except Exception as e:
            print(f"加载存档时发生未知错误: {e}")
            self._reset_game_state()

    def _reset_game_state(self):
        """重置当前游戏状态为新游戏默认值"""
        self.energy = 100.0
        self.score = 0
        self.cores = 0
        self.level = 1
        self.consecutive_correct = 0
        self.equipment = None
        self.items = []
        self.skills = {"decode_speed": 1.0, "energy_recovery": 1.0}
        self.current_task = None
        self.task_progress = 0
        self.players = 1
        self.endless = False


    def save_game(self, slot):
        """保存当前游戏进度到指定存档槽位"""
        save_file = os.path.join(self.data_dir, f".starsignal_save_{slot}.json")
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
        try:
            with open(save_file, 'w', encoding='utf-8') as f:
                json.dump(data, f, indent=2, ensure_ascii=False)
            os.chmod(save_file, 0o666)
            print(f"游戏保存至槽位 {slot}！")
        except Exception as e:
            print(f"错误：保存游戏失败: {e}")

    def unlock_achievement(self, name):
        """解锁成就"""
        if name not in self.achievements:
            self.achievements.add(name)
            self.display.show_achievement(name)
            self.save_records() # 解锁成就后立即保存记录

    def upgrade_skill(self):
        """随机升级技能"""
        skill = random.choice(["decode_speed", "energy_recovery"])
        self.skills[skill] += 0.3
        print(f"技能提升！{skill} 现在为 {self.skills[skill]:.1f}")

    def purchase_item(self, available_items):
        """购买道具或装备"""
        self.display.show_store(self.score, available_items)
        try:
            choice = input("选择装备或道具（0-{}）：".format(len(available_items))).strip()
            if choice == "0":
                return None
            
            choice_idx = int(choice) - 1
            if not (0 <= choice_idx < len(available_items)):
                print("无效选择！")
                return None

            item = available_items[choice_idx]
            if self.score >= item["cost"]:
                self.score -= item["cost"]
                if item["type"] == "equipment":
                    # 替换旧装备
                    if self.equipment:
                        print(f"旧装备 {self.equipment} 已被 {item['name']} 替换。")
                    self.equipment = item["name"]
                    print(f"装备 {item['name']} 成功！")
                    return item["effect"] # 返回装备效果以在游戏循环中应用
                else: # type == "item"
                    self.items.append(item["name"])
                    print(f"获得道具 {item['name']}！")
                    return item["effect"] # 返回道具效果
            else:
                print("得分不足！")
        except ValueError:
            print("无效输入！请输入数字。")
        except IndexError:
            print("选择超出范围！")
        return None

    def use_item(self, signal_strength):
        """使用道具"""
        if not self.items:
            print("无可用道具！")
            return False, False # (skipped_signal, item_used)
        
        print("可用道具：", ", ".join(self.items))
        choice = input("输入道具名称（或 '取消'）：").strip().lower()
        
        if choice == "取消":
            return False, False
        
        if choice == "干扰器" and "干扰器" in self.items:
            self.items.remove("干扰器")
            print("使用干扰器，跳过当前信号！")
            return True, True # (skipped_signal=True, item_used=True)
        elif choice == "能量电池" and "能量电池" in self.items:
            self.items.remove("能量电池")
            self.energy = min(self.energy + 20.0, 100.0)
            print("使用能量电池，能量 +20%！")
            self.display._play_sound(frequency=600, duration=100)
            return False, True # (skipped_signal=False, item_used=True)
        else:
            print("无效道具！")
            return False, False

    def assign_task(self):
        """分配 NPC 任务"""
        # 任务只在关卡3及以后可用
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
        """检查 NPC 任务进度"""
        if not self.current_task:
            return
        
        task_type = self.current_task["type"]
        task_count = self.current_task["count"]

        if task_type == "strong_signals":
            if signal_strength == 3 and correct:
                self.task_progress += 1
            else:
                self.task_progress = 0 # 失败或非强信号，进度重置
        elif task_type == "no_mistakes":
            if correct:
                self.task_progress += 1
            else:
                self.task_progress = 0 # 失败，进度重置
        
        if self.task_progress >= task_count:
            reward = self.current_task["reward"]
            self.display.show_task_complete(reward)
            if "分" in reward:
                self.score += int(reward.split()[0])
            elif "能量" in reward:
                self.energy = min(self.energy + int(reward.split()[1]), 100.0)
            self.current_task = None
            self.task_progress = 0

    def start(self):
        """游戏主循环"""
        self.display.show_intro()
        if self.is_first_time():
            self.display.show_tutorial()

        # has_progress 检查是否有旧进度，用于显示“继续”选项
        has_progress = self.level > 1 or self.cores > 0 or self.score > 0
        self.display.show_mode_selection(self.unlocked_levels, self.level if has_progress else 1, self.total_wins > 0)
        mode = input("请输入（1-4）：").strip()

        # 根据选择初始化游戏状态
        if mode == "1": # 新游戏
            self._reset_game_state()
        elif mode == "2": # 继续游戏（如果当前有进度）
            if not has_progress:
                print("无进度，将从关卡 1 开始新游戏！")
                self._reset_game_state()
            # 如果有进度，则当前的 self 状态就是加载的存档状态
        elif mode == "3": # 选择关卡
            print(f"已解锁关卡：{', '.join(map(str, self.unlocked_levels))}")
            level_choice = input("选择关卡（输入编号）：").strip()
            if level_choice.isdigit() and int(level_choice) in self.unlocked_levels:
                self._reset_game_state() # 重置为新游戏状态
                self.level = int(level_choice)
                print(f"已选择从关卡 {self.level} 开始。")
            else:
                print("无效或未解锁关卡，将从关卡 1 开始新游戏！")
                self._reset_game_state()
        elif mode == "4": # 无尽模式
            if self.total_wins > 0: # 必须通关一次才能解锁无尽模式
                self._reset_game_state() # 重置为新游戏状态
                self.endless = True
                print("无尽模式已启动！挑战你的极限！")
            else:
                print("无尽模式未解锁（需先通关一次游戏），将从关卡 1 开始新游戏！")
                self._reset_game_state()
        else:
            print("无效选择，将从关卡 1 开始新游戏！")
            self._reset_game_state()

        # 玩家数量选择
        play_style = input("玩法：1) 单人 2) 双人 [1]：").strip()
        if play_style == "2":
            self.players = 2
            print("双人模式启动！连续正确触发连携加成！")
            self.unlock_achievement("双人冒险者")
        else:
            self.players = 1

        core_targets = [1, 2, 3] # 每关所需核心数量

        # 游戏主循环：持续进行直到能量耗尽或通关
        while self.level <= 3 or self.endless: # 3关或无尽模式
            # 获取当前关卡所需核心数
            core_target = core_targets[min(self.level - 1, len(core_targets) - 1)]
            self.cores = 0 # 每关核心数重置
            
            self.display.show_level_transition(self.level) # 关卡过渡动画

            if not self.current_task and self.level >= 3 and not self.endless: # 关卡3及以后才分配NPC任务，无尽模式不分配
                self.assign_task()

            is_boss_signal = False # 是否是Boss信号
            signals_decoded_in_current_level = 0
            max_signals_before_boss = 5 if self.level < 3 else 7 # Boss前信号数量
            energy_recovery_mode = False # 是否进入能量恢复模式

            # 关卡内循环：收集核心或恢复能量
            while (self.cores < core_target or (energy_recovery_mode and self.energy < 100.0)) and self.energy > 0:
                if self.cores >= core_target and not energy_recovery_mode:
                    energy_recovery_mode = True
                    print(self.display.color_text("核心收集完成！现在，必须将能量恢复至 100.0% 才能跃迁！", Fore.YELLOW))
                    self.display.show_story(4) # 显示能量恢复阶段的剧情

                if signals_decoded_in_current_level >= max_signals_before_boss and not is_boss_signal and not energy_recovery_mode:
                    is_boss_signal = True
                    self.display.show_boss()

                # 随机天气和事件
                weather = random.choice(["clear"] if self.level == 1 else ["clear", "storm", "fog"])
                event = random.choices(
                    ["none", "interference", "fault", "bonus", "storm", "merchant"],
                    weights=[40, 15, 10, 10, 15, 10]
                )[0]
                self.display.show_npc_dialogue(event, weather, self.current_task)
                
                # 生成信号
                current_signal_length = 12 if is_boss_signal else self.base_signal_length + self.level * 2
                # 无尽模式下信号长度持续增长
                if self.endless:
                    current_signal_length = self.base_signal_length + (self.level * 2) + (signals_decoded_in_current_level // 2)

                signal, rule, answer, distractors, strength = self.signal_generator.generate_signal(self.num_options, current_signal_length)
                options = distractors + [answer]
                random.shuffle(options)

                # 应用环境和装备效果
                adjusted_time_limit = self.time_limit / self.skills["decode_speed"]
                adjusted_energy_loss = self.energy_loss

                if weather == "storm":
                    adjusted_time_limit *= 0.8 # 风暴减少时间
                elif weather == "fog":
                    # 迷雾增加一个干扰选项，但这里已经生成了num_options个选项，直接在显示时说明即可
                    pass # num_options已经在signal_generator里处理了，这里无需额外调整

                if event == "interference":
                    adjusted_time_limit = max(10, adjusted_time_limit - 10) # 干扰减少时间
                    print(self.display.color_text("信号干扰！解码时间大幅减少！", Fore.RED))
                elif event == "fault":
                    self.energy -= adjusted_energy_loss / 2 # 故障减少能量
                    print(self.display.color_text("系统故障！能量小幅流失！", Fore.RED))
                elif event == "bonus":
                    self.score += 5 * strength # 奖励增加得分
                    print(self.display.color_text("能量脉冲！获得额外分数！", Fore.GREEN))
                elif event == "storm":
                    effect = random.choice(["energy_loss", "energy_gain"])
                    if effect == "energy_loss":
                        self.energy -= 10.0
                        print(self.display.color_text("能量风暴！能量 -10%！", Fore.RED))
                    else:
                        self.energy = min(self.energy + 10.0, 100.0)
                        print(self.display.color_text("能量风暴！能量 +10%！", Fore.GREEN))
                elif event == "merchant":
                    item_effect = self.purchase_item(self.get_available_items())
                    if item_effect:
                        # 应用购买的装备/道具效果
                        if "time_limit_bonus" in item_effect: # 装备增加时间
                            adjusted_time_limit += item_effect["time_limit_bonus"]
                        elif "energy_loss_reduction" in item_effect: # 装备减少能量损失
                            adjusted_energy_loss = max(5, adjusted_energy_loss + item_effect["energy_loss_reduction"]) # 减少能量损失是负值
                        elif "decode_speed_bonus" in item_effect: # 装备提升解码速度
                            self.skills["decode_speed"] += item_effect["decode_speed_bonus"]

                # 应用已装备的装备效果
                if self.equipment == "信号放大器":
                    adjusted_time_limit += 10
                elif self.equipment == "能量护盾":
                    adjusted_energy_loss = max(5, adjusted_energy_loss - 5)
                elif self.equipment == "快速解码器":
                    self.skills["decode_speed"] += 0.3 # 这应该在装备时一次性应用，而不是每轮叠加

                if self.players > 1:
                    print(self.display.color_text(f"\n玩家 {self.current_player} 的回合", Fore.CYAN))

                # 显示当前信号和游戏状态
                self.display.show_signal(
                    signal, rule, options, self.energy, self.score, self.cores,
                    core_target, self.level, strength, weather, self.equipment, self.items, self.current_task, energy_recovery_mode
                )
                
                start_time = time.time()
                player_input = input("请输入（1-{}, s 保存，h 提示，i 使用道具，q 退出）：".format(len(options))).strip()
                
                skipped_signal = False
                item_used = False

                # 处理用户输入
                if player_input.lower() == 's':
                    slot = input("选择存档槽位（1-3）：").strip()
                    if slot in ["1", "2", "3"]:
                        self.save_game(int(slot))
                    else:
                        print("无效槽位！")
                    continue # 不计入本轮信号解码
                elif player_input.lower() == 'h':
                    self.display.show_hint(rule)
                    if not self.practice:
                        self.energy -= 2.0 # 提示消耗能量
                    continue # 不计入本轮信号解码
                elif player_input.lower() == 'i':
                    skipped_signal, item_used = self.use_item(strength)
                    if skipped_signal:
                        continue # 跳过当前信号，重新开始一轮
                    if item_used:
                        continue # 使用道具后不进行信号解码，重新开始一轮
                    else: # 尝试使用道具但无效
                        continue
                elif player_input.lower() == 'q':
                    print("游戏退出！")
                    self.save_records()
                    sys.exit() # 退出游戏

                signals_decoded_in_current_level += 1 # 计数当前关卡解码的信号数量

                correct_answer_chosen = False
                try:
                    choice_idx = int(player_input) - 1
                    elapsed_time = time.time() - start_time

                    if not (0 <= choice_idx < len(options)):
                        print("无效输入！请输入正确选项编号。")
                        if not self.practice:
                            self.energy -= 5.0 # 无效输入也扣能量
                        self.consecutive_correct = 0
                        self.display._play_sound(frequency=200, duration=100) # 失败音效
                    elif elapsed_time > adjusted_time_limit:
                        print(self.display.color_text("时间到！信号丢失！", Fore.RED))
                        if not self.practice:
                            self.energy -= adjusted_energy_loss * strength
                        self.consecutive_correct = 0
                        self.display._play_sound(frequency=200, duration=100) # 失败音效
                    elif options[choice_idx] == answer:
                        print(self.display.color_text("解码成功！飞船前进！", Fore.GREEN))
                        self.display._play_sound(frequency=600, duration=100) # 成功音效
                        correct_answer_chosen = True
                        
                        energy_gain = ([10.0, 12.0, 15.0][strength - 1] * self.skills["energy_recovery"])
                        score_gain = (10 * strength + (30 if is_boss_signal else 0))
                        
                        if energy_recovery_mode:
                            energy_gain *= 1.5 # 恢复阶段能量奖励增加
                            score_gain //= 2 # 恢复阶段得分减少

                        self.score += score_gain
                        self.energy = min(self.energy + energy_gain, 100.0)
                        
                        if not energy_recovery_mode:
                            self.cores += 1
                        
                        self.consecutive_correct += 1
                        if self.consecutive_correct >= 3:
                            self.unlock_achievement("快速解码者")
                        if is_boss_signal:
                            self.unlock_achievement("Boss 终结者")
                        
                        if self.players > 1 and self.consecutive_correct >= 2:
                            self.score += 10
                            self.energy = min(self.energy + 5.0, 100.0)
                            print(self.display.color_text("连携加成！+10 分，+5% 能量！", Fore.CYAN))
                            self.unlock_achievement("连携大师")
                        
                        if random.random() < 0.3: # 随机技能提升
                            self.upgrade_skill()
                    else:
                        print(self.display.color_text(f"解码失败！正确答案是 {answer}。", Fore.RED))
                        if not self.practice:
                            self.energy -= adjusted_energy_loss * strength
                        self.consecutive_correct = 0
                        self.display._play_sound(frequency=200, duration=100) # 失败音效

                except ValueError:
                    print("无效输入！请输入数字选项或有效命令。")
                    if not self.practice:
                        self.energy -= 5.0
                    self.consecutive_correct = 0
                    self.display._play_sound(frequency=200, duration=100) # 失败音效
                
                self.check_task_progress(strength, correct_answer_chosen)
                self.display.show_status(self.energy, self.score, self.cores, self.level)
                
                if self.energy <= 0:
                    break # 能量耗尽，游戏结束

                if self.players > 1:
                    self.current_player = 2 if self.current_player == 1 else 1 # 切换玩家

            # 关卡内循环结束，检查退出条件
            if self.energy <= 0:
                print(self.display.color_text("游戏结束！飞船能量耗尽！", Fore.RED))
                break # 能量耗尽，跳出游戏主循环

            # 如果完成了当前关卡目标并且能量达到100%
            if self.cores >= core_target and self.energy == 100.0:
                self.display.show_story(self.cores) # 显示关卡完成剧情
                
                if self.level == 3 and not self.endless: # 通关最终关卡
                    if self.score > 100:
                        self.unlock_achievement("完美通关")
                    self.unlock_achievement("星域征服者")
                
                # 解锁下一关
                if not self.endless:
                    self.unlocked_levels = list(set(self.unlocked_levels + [self.level + 1]))
                    self.save_records() # 解锁关卡后保存一下记录

                # 关卡结束，进入商店或获得奖励
                if self.level <= 3 and not self.endless: # 非无尽模式的关卡结束
                    item_effect = self.purchase_item(self.get_available_items())
                    if item_effect:
                        # 商店购买的装备效果已在 purchase_item 中处理
                        pass
                    self.energy = min(self.energy + 10.0, 100.0) # 关卡奖励能量
                    print(self.display.color_text("关卡奖励：能量 +10%！", Fore.GREEN))
                
                if self.endless: # 无尽模式，增加难度
                    self.base_signal_length += 1
                    self.num_options = min(self.num_options + 1, 6) # 选项最多到6个
                    print(self.display.color_text(f"无尽模式难度提升：信号长度增加到 {self.base_signal_length}，选项增加到 {self.num_options}！", Fore.YELLOW))

                self.level += 1 # 进入下一关
            else:
                # 核心已收集，但能量未满100%时退出循环的情况（通常是用户Q退出）
                # 或者能量耗尽
                break

        # 游戏结束，显示结局和最终得分
        self.display.show_ending(self.score, self.cores, self.level - 1, self.energy)
        self.save_records() # 游戏结束后保存最终记录
        
        print(f"最终得分：{self.score} | 核心：{self.cores} | 关卡：{self.level - 1 if not self.endless else self.level} (无尽)")
        print(f"历史最高分：{self.high_score} | 总通关次数：{self.total_wins}")
        
        if self.achievements:
            print(f"成就：{', '.join(self.achievements)}")
        if self.rankings:
            self.display.show_rankings(self.rankings)

    def get_available_items(self):
        """获取当前可用的商店物品列表"""
        items = [
            {"name": "信号放大器", "cost": 50, "type": "equipment", "effect": {"time_limit_bonus": 10}, "description": "增加 10 秒解码时间"},
            {"name": "能量护盾", "cost": 40, "type": "equipment", "effect": {"energy_loss_reduction": -5}, "description": "减少 5 点能量损失"},
            {"name": "快速解码器", "cost": 60, "type": "equipment", "effect": {"decode_speed_bonus": 0.3}, "description": "提升 0.3 解码速度"},
            {"name": "能量电池", "cost": 30, "type": "item", "effect": {"energy_recovery_amount": 20}, "description": "使用后恢复 20% 能量"},
        ]
        if self.level >= 2: # 干扰器在关卡2及以后解锁
            items.append({"name": "干扰器", "cost": 50, "type": "item", "effect": {"skip_signal": True}, "description": "跳过当前信号"})
        return items
