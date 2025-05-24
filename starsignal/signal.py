import random
import string

class SignalGenerator:
    def __init__(self, difficulty):
        self.difficulty = difficulty
        self.rules = {
            "easy": ["ignore_symbols"],
            "medium": ["ignore_symbols", "reverse"],
            "hard": ["ignore_symbols", "reverse"]
        }
        self.rule_texts = {
            "ignore_symbols": "忽略所有非数字字符",
            "reverse": "忽略非数字字符并反转序列"
        }

    def generate_signal(self, num_options):
        length = {"easy": 5, "medium": 7, "hard": 10}[self.difficulty]
        digits = [str(random.randint(0, 9)) for _ in range(length)]
        symbols = random.choices(string.punctuation, k=length // 2)
        
        signal = []
        for i in range(length):
            if random.random() < 0.3 and self.difficulty != "easy":
                signal.append(symbols.pop(0))
            else:
                signal.append(digits[i])
        
        rule = random.choice(self.rules[self.difficulty])
        if rule == "ignore_symbols":
            answer = ''.join(c for c in signal if c.isdigit())
        else:  # reverse
            answer = ''.join(c for c in signal if c.isdigit())[::-1]
        
        # 生成干扰选项
        distractors = []
        for _ in range(num_options - 1):
            distractor = ''.join(random.choices("0123456789", k=len(answer)))
            while distractor == answer or distractor in distractors:
                distractor = ''.join(random.choices("0123456789", k=len(answer)))
            distractors.append(distractor)
        
        return ''.join(signal), self.rule_texts[rule], answer, distractors
