from setuptools import setup, find_packages

setup(
    name="starsignal",
    version="0.7.1", # 版本号更新为 0.7.1
    packages=find_packages(),
    # colorama 保持在 extras_require，但会在 README 中强调安装
    install_requires=[],
    extras_require={
        "color": ["colorama>=0.4.6"]
    },
    entry_points={
        "console_scripts": [
            "starsignal = starsignal.cli:main",
        ],
    },
    author="bbb-lsy07",
    author_email="lisongyue0125@163.com",
    description="星际迷航：信号解码 - 一个有趣的终端解谜游戏",
    long_description=open("README.md", encoding="utf-8").read(),
    long_description_content_type="text/markdown",
    url="https://github.com/bbb-lsy07/StarSignalDecoder",
    license="MIT",
    classifiers=[
        "License :: OSI Approved :: MIT License",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.6",
        "Programming Language :: Python :: 3.7",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10", # 兼容更高版本
        "Programming Language :: Python :: 3.11",
        "Operating System :: OS Independent",
        "Environment :: Console",
        "Topic :: Games/Entertainment",
        "Topic :: Text Processing :: General",
    ],
    python_requires=">=3.6",
)
