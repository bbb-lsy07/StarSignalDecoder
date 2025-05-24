import random
import string

class SignalGenerator:
    def __init__(self, difficulty):
        self.difficulty = difficulty
        self.rules = {
            "easy": ["ignore_symbols"],
            "medium": ["ignore_symbols", "reverse"],
            "hard": ["ignore_symbols", "reverse", "repeat", "odd_plus_one"]
        }
        self.rule_texts = {
            "ignore_symbols": "忽略所有非数字字符",
            "reverse": "忽略非数字字符并反转序列",
            "repeat": "忽略非数字字符并将序列重复两次",
            "odd_plus_one": "忽略非数字字符，奇数数字加1"
        }

    def generate_signal(self, num_options):
        length = {"easy": 5, "medium": 7, "hard": 10}[self.difficulty]
        digits = [str(random.randint(0, 9)) for _ in range(length)]
        symbols = random.choices(string.punctuation, k=length // 2)
        
        signal = []
        for i in range(length):
            if random.random() < 0.3 and self.difficulty != "easy":
                signal.append(symbols.pop(0) if symbols else random.choice(string.punctuation))
            else:
                signal.append(digits[i])
        
        rule = random.choice(self.rules[self.difficulty])
        digit_sequence = [c for c in signal if c.isdigit()]
        
        if rule == "ignore_symbols":
            answer = ''.join(digit_sequence)
        elif rule == "reverse":
            answer = ''.join(digit_sequence)[::-1]
        elif rule == "repeat":
            answer = ''.join(digit_sequence) * 2
        else:  # odd_plus_one
            answer = ''.join(str((int(c) + 1) % 10) if int(c) % 2 == 1 else c for c in digit_sequence)
        
        distractors = []
        for _ in range(num_options - 1):
            distractor = ''.join(random.choices("0123456789", k=len(answer)))
            while distractor == answer or distractor in distractors:
                distractor = ''.join(random.choices("0123456789", k=len(answer)))
            distractors.append(distractor)
        
        strength = random.randint(1, 3)
        return ''.join(signal), self.rule_texts[rule], answer, distractors, strength
