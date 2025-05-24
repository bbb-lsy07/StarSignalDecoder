import random
import string

class SignalGenerator:
    def __init__(self, difficulty):
        self.difficulty = difficulty
        self.rules = {
            "easy": ["ignore_symbols"],
            "medium": ["ignore_symbols", "reverse", "odd_plus_one"],
            "hard": ["ignore_symbols", "reverse", "odd_plus_one", "even_only", "replace_char"],
            "challenge": ["ignore_symbols", "reverse", "odd_plus_one", "even_only", "replace_char"]
        }
        self.rule_texts = {
            "ignore_symbols": "忽略所有非数字字符",
            "reverse": "忽略非数字字符并反转序列",
            "odd_plus_one": "忽略非数字字符，奇数数字加1",
            "even_only": "忽略非数字字符，仅保留偶数数字",
            "replace_char": "忽略非数字字符，替换5为0"
        }

    def generate_signal(self, num_options, length=None):
        length = length or {"easy": 5, "medium": 7, "hard": 10, "challenge": 8}[self.difficulty]
        digits = [str(random.randint(0, 9)) for _ in range(length)]
        symbols = random.choices(string.punctuation, k=length // 2)
        
        signal = []
        for i in range(length):
            if random.random() < 0.4 and self.difficulty != "easy":
                signal.append(symbols.pop(0) if symbols else random.choice(string.punctuation))
            else:
                signal.append(digits[i])
        
        is_boss = length >= 12
        if is_boss:
            rule = random.sample(self.rules[self.difficulty], 2)
            rule_text = "和".join(self.rule_texts[r] for r in rule)
        else:
            rule = [random.choice(self.rules[self.difficulty])]
            rule_text = self.rule_texts[rule[0]]
        
        digit_sequence = [c for c in signal if c.isdigit()]
        answer = ''.join(digit_sequence)
        
        for r in rule:
            if r == "ignore_symbols":
                answer = ''.join(digit_sequence)
            elif r == "reverse":
                answer = answer[::-1]
            elif r == "odd_plus_one":
                answer = ''.join(str((int(c) + 1) % 10) if int(c) % 2 == 1 else c for c in answer)
            elif r == "even_only":
                answer = ''.join(c for c in answer if int(c) % 2 == 0)
            elif r == "replace_char":
                answer = ''.join('0' if c == '5' else c for c in answer)
        
        if not answer:
            answer = "0"
        
        distractors = []
        for _ in range(num_options - 1):
            distractor = ''.join(random.choices("0123456789", k=max(1, len(answer))))
            while distractor == answer or distractor in distractors:
                distractor = ''.join(random.choices("0123456789", k=max(1, len(answer))))
            distractors.append(distractor)
        
        strength = random.randint(1, 3)
        return ''.join(signal), rule_text, answer, distractors, strength
