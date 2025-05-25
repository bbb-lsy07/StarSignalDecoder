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
        
        # 确保信号中至少包含一些数字
        digits_pool = [str(random.randint(0, 9)) for _ in range(length)] # 生成足够多的数字
        all_chars = []

        # 构造信号，保证有数字和符号混合
        for i in range(length):
            if random.random() < 0.6: # 大概率添加数字
                all_chars.append(digits_pool.pop(0))
            else:
                all_chars.append(random.choice(string.punctuation)) # 添加标点符号作为干扰

        # 如果数字不够，补充数字直到达到长度
        while len(all_chars) < length:
            all_chars.append(digits_pool.pop(0))
        
        random.shuffle(all_chars) # 打乱顺序
        signal = ''.join(all_chars)
        
        is_boss = length >= 12
        
        chosen_rules = []
        if is_boss and len(self.rules[self.difficulty]) >= 2:
            # Boss信号随机选择2条规则
            chosen_rules = random.sample(self.rules[self.difficulty], 2)
            rule_text = "和".join(self.rule_texts[r] for r in chosen_rules)
        else:
            # 普通信号随机选择1条规则
            chosen_rules = [random.choice(self.rules[self.difficulty])]
            rule_text = self.rule_texts[chosen_rules[0]]
        
        # 计算正确答案
        current_answer_digits = [c for c in signal if c.isdigit()]
        current_answer = ''.join(current_answer_digits)
        
        # 应用所有选定的规则
        for rule_type in chosen_rules:
            if rule_type == "ignore_symbols":
                # 这一步已经在 current_answer_digits 中完成了
                pass
            elif rule_type == "reverse":
                current_answer = current_answer[::-1]
            elif rule_type == "odd_plus_one":
                current_answer = ''.join(str((int(c) + 1) % 10) if int(c) % 2 == 1 else c for c in current_answer)
            elif rule_type == "even_only":
                current_answer = ''.join(c for c in current_answer if int(c) % 2 == 0)
            elif rule_type == "replace_char":
                current_answer = ''.join('0' if c == '5' else c for c in current_answer)
        
        # 如果规则导致答案为空（例如，"仅保留偶数数字"但在信号中没有偶数），给一个默认值
        if not current_answer:
            current_answer = "0"
        
        # 生成干扰项
        distractors = []
        for _ in range(num_options - 1): # num_options 是总选项数，所以减1是为了干扰项
            distractor = ''.join(random.choices("0123456789", k=max(1, len(current_answer))))
            # 确保干扰项与正确答案和已生成的干扰项不同
            while distractor == current_answer or distractor in distractors:
                distractor = ''.join(random.choices("0123456789", k=max(1, len(current_answer))))
            distractors.append(distractor)
        
        strength = random.randint(1, 3) # 信号强度：1 (弱), 2 (中), 3 (强)
        return signal, rule_text, current_answer, distractors, strength
