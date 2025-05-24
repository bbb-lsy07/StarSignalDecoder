from setuptools import setup, find_packages

setup(
    name="starsignal",
    version="0.1.0",
    packages=find_packages(),
    install_requires=[],
    entry_points={
        "console_scripts": [
            "starsignal = starsignal.cli:main",
        ],
    },
    author="bbb-lsy07",
    author_email="lisongyue0125@163.com",
    description="星际迷航：信号解码 - 一个有趣的终端解谜游戏",
    long_description=open("README.md").read(),
    long_description_content_type="text/markdown",
    url="https://github.com/bbb-lsy07/StarSignalDecoder",
    license="MIT",
    classifiers=[
        "License :: OSI Approved :: MIT License",
        "Programming Language :: Python :: 3",
        "Operating System :: OS Independent",
    ],
)
