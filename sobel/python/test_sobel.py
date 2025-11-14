#!/usr/bin/env python3
"""
测试 Sobel 边缘检测算法
"""

import os
import sys
import subprocess


def run_command(cmd):
    """运行命令并打印输出"""
    print(f"\n运行: {' '.join(cmd)}")
    print("-" * 60)
    result = subprocess.run(cmd, capture_output=True, text=True)
    print(result.stdout)
    if result.stderr:
        print("错误:", result.stderr, file=sys.stderr)
    return result.returncode == 0


def main():
    """运行测试"""
    print("=" * 60)
    print("Sobel 边缘检测算法测试")
    print("=" * 60)

    # 1. 创建测试图像
    print("\n步骤 1: 创建测试图像")
    if not run_command([sys.executable, 'create_test_image.py']):
        print("创建测试图像失败!")
        return 1

    # 检查测试图像是否存在
    if not os.path.exists('test_image.jpg'):
        print("错误: test_image.jpg 未创建")
        return 1

    # 2. 基本 Sobel 边缘检测
    print("\n步骤 2: 基本 Sobel 边缘检测")
    if not run_command([sys.executable, 'sobel.py', 'test_image.jpg', 'output_basic.jpg']):
        print("基本边缘检测失败!")
        return 1

    # 3. 使用阈值的 Sobel 边缘检测
    print("\n步骤 3: 使用阈值的 Sobel 边缘检测")
    if not run_command([sys.executable, 'sobel.py', 'test_image.jpg', 'output_threshold.jpg', '--threshold', '100']):
        print("阈值边缘检测失败!")
        return 1

    # 4. 详细模式
    print("\n步骤 4: 详细模式（输出所有中间结果）")
    if not run_command([sys.executable, 'sobel.py', 'test_image.jpg', '--detailed', '--output-dir', 'test_output']):
        print("详细模式失败!")
        return 1

    # 检查输出文件
    print("\n检查输出文件:")
    print("-" * 60)
    expected_files = [
        'output_basic.jpg',
        'output_threshold.jpg',
        'test_output/gray.jpg',
        'test_output/sobel_x.jpg',
        'test_output/sobel_y.jpg',
        'test_output/sobel_magnitude.jpg'
    ]

    all_exist = True
    for f in expected_files:
        exists = os.path.exists(f)
        status = "✓" if exists else "✗"
        print(f"{status} {f}")
        if not exists:
            all_exist = False

    if all_exist:
        print("\n" + "=" * 60)
        print("所有测试通过！")
        print("=" * 60)
        print("\n生成的文件:")
        print("  - test_image.jpg: 原始测试图像")
        print("  - output_basic.jpg: 基本边缘检测结果")
        print("  - output_threshold.jpg: 阈值边缘检测结果")
        print("  - test_output/: 详细模式输出目录")
        print("    - gray.jpg: 灰度图")
        print("    - sobel_x.jpg: X方向梯度")
        print("    - sobel_y.jpg: Y方向梯度")
        print("    - sobel_magnitude.jpg: 梯度幅值")
        return 0
    else:
        print("\n部分测试失败！")
        return 1


if __name__ == '__main__':
    sys.exit(main())
