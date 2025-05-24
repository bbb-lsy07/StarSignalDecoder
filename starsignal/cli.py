import argparse
import sys
from .game import StarSignalGame
from . import __version__

def main():
    parser = argparse.ArgumentParser(
        prog="starsignal",
        description="星际迷航：信号解码 - 一个有趣的终端解谜游戏！解码信号以逃离危险星域！",
        formatter_class=argparse.RawTextHelpFormatter
    )
    parser.add_argument(
        "--version", action="version", version=f"starsignal {__version__}",
        help="显示版本号并退出"
    )
    parser.add_argument(
        "--difficulty", choices=["easy", "medium", "hard"], default="easy",
        help="设置游戏难度：\n  easy（简单：60秒，3选项）\n  medium（中等：45秒，4选项）\n  hard（困难：30秒，5选项）（默认：easy）"
    )
    parser.add_argument(
        "--tutorial", action="store_true",
        help="强制显示教程，适合新手"
    )
    parser.add_argument(
        "--load", type=str,
        help="加载存档文件（例如：save.json）"
    )
    args = parser.parse_args()

    game = StarSignalGame(difficulty=args.difficulty, load_file=args.load)
    if args.tutorial or game.is_first_time():
        game.display.show_tutorial()
    game.start()

if __name__ == "__main__":
    sys.exit(main())
