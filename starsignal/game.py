import time
import random
from .signal import SignalGenerator
from .display import Display

class StarSignalGame:
    def __init__(self, difficulty="easy"):
        self.difficulty = difficulty
        self.settings = {
            "easy": {"time_limit": 60, "options": 3},
            "medium": {"time_limit": 45, "options": 4},
            "hard": {"time_limit": 30, "options": 5}
        }
        self.time_limit = self.settings[difficulty]["time_limit"]
        self.num_options = self.settings[difficulty]["options"]
        self.energy = 100  # 飞船能量
        self.score = 0
        self.cores = 0  # 能量核心
        self.signal_generator = SignalGenerator(difficulty)
        self.display = Display()
        self.story_stage = 0

    def start(self):
        self.display.show_intro()
        if self.score == 0:
            self.display.show_tutorial()
        
        while self.energy > 0:
            signal, rule, answer, distractors = self.signal_generator.generate_signal(self.num_options)
            options = distractors + [answer]
            random.shuffle(options)
            self.display.show_signal(signal, rule, options, self.energy, self.score, self.cores, self.story_stage)
            
            start_time = time.time()
            try:
                choice = int(input("请输入正确选项编号（1-{}）：".format(self.num_options))) - 1
                elapsed_time = time.time() - start_time

                if elapsed_time > self.time_limit:
                    print("时间到！信号丢失！")
                    self.energy -= 20
                elif 0 <= choice < self.num_options and options[choice] == answer:
                    print("信号解码成功！飞船前进！")
                    self.score += 10
                    self.energy = min(self.energy + 5, 100)
                    self.cores += 1
                    self.story_stage += 1
                    self.display.show_story(self.story_stage)
                else:
                    print(f"解码失败！正确答案是 {answer}。")
                    self.energy -= 10
            except (ValueError, IndexError):
                print("无效输入！请输入正确选项编号。")
                self.energy -= 10

            self.display.show_status(self.energy, self.score, self.cores)
            if self.energy <= 0:
                print("游戏结束！飞船能量耗尽！")
                break
            if self.cores >= 3:
                print("你收集了足够的核心，飞船成功逃离星域！")
                break
            if input("继续解码？(y/n)：").lower() != 'y':
                break
        
        print(f"最终得分：{self.score} | 能量核心：{self.cores}")
