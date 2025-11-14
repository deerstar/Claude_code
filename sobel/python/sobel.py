#!/usr/bin/env python3
"""
Sobel边缘检测算法实现

功能：读取输入图片，应用Sobel算子进行边缘检测，输出处理后的图片
"""

import numpy as np
import cv2
import argparse
import os
import sys


def apply_sobel(image_path, output_path, threshold=None):
    """
    应用Sobel边缘检测算法

    参数:
        image_path: 输入图片路径
        output_path: 输出图片路径
        threshold: 可选的阈值，用于二值化边缘图像

    返回:
        bool: 处理是否成功
    """
    # 读取图片
    if not os.path.exists(image_path):
        print(f"错误：找不到输入图片 {image_path}")
        return False

    img = cv2.imread(image_path)
    if img is None:
        print(f"错误：无法读取图片 {image_path}")
        return False

    # 转换为灰度图
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

    # 应用Sobel算子
    # 计算X方向梯度
    sobelx = cv2.Sobel(gray, cv2.CV_64F, 1, 0, ksize=3)

    # 计算Y方向梯度
    sobely = cv2.Sobel(gray, cv2.CV_64F, 0, 1, ksize=3)

    # 计算梯度幅值
    sobel_magnitude = np.sqrt(sobelx**2 + sobely**2)

    # 归一化到0-255范围
    sobel_magnitude = np.uint8(sobel_magnitude * 255 / np.max(sobel_magnitude))

    # 如果指定了阈值，进行二值化
    if threshold is not None:
        _, sobel_magnitude = cv2.threshold(sobel_magnitude, threshold, 255, cv2.THRESH_BINARY)

    # 保存结果
    cv2.imwrite(output_path, sobel_magnitude)
    print(f"成功！边缘检测结果已保存到: {output_path}")

    return True


def apply_sobel_detailed(image_path, output_dir):
    """
    应用Sobel边缘检测并输出详细的中间结果

    参数:
        image_path: 输入图片路径
        output_dir: 输出目录

    返回:
        bool: 处理是否成功
    """
    # 读取图片
    if not os.path.exists(image_path):
        print(f"错误：找不到输入图片 {image_path}")
        return False

    img = cv2.imread(image_path)
    if img is None:
        print(f"错误：无法读取图片 {image_path}")
        return False

    # 创建输出目录
    os.makedirs(output_dir, exist_ok=True)

    # 转换为灰度图
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    cv2.imwrite(os.path.join(output_dir, 'gray.jpg'), gray)

    # 应用Sobel算子
    sobelx = cv2.Sobel(gray, cv2.CV_64F, 1, 0, ksize=3)
    sobely = cv2.Sobel(gray, cv2.CV_64F, 0, 1, ksize=3)

    # 归一化并保存X方向梯度
    sobelx_abs = np.absolute(sobelx)
    sobelx_8u = np.uint8(sobelx_abs * 255 / np.max(sobelx_abs))
    cv2.imwrite(os.path.join(output_dir, 'sobel_x.jpg'), sobelx_8u)

    # 归一化并保存Y方向梯度
    sobely_abs = np.absolute(sobely)
    sobely_8u = np.uint8(sobely_abs * 255 / np.max(sobely_abs))
    cv2.imwrite(os.path.join(output_dir, 'sobel_y.jpg'), sobely_8u)

    # 计算梯度幅值
    sobel_magnitude = np.sqrt(sobelx**2 + sobely**2)
    sobel_magnitude = np.uint8(sobel_magnitude * 255 / np.max(sobel_magnitude))
    cv2.imwrite(os.path.join(output_dir, 'sobel_magnitude.jpg'), sobel_magnitude)

    print(f"成功！详细结果已保存到目录: {output_dir}")
    print(f"  - gray.jpg: 灰度图")
    print(f"  - sobel_x.jpg: X方向梯度")
    print(f"  - sobel_y.jpg: Y方向梯度")
    print(f"  - sobel_magnitude.jpg: 梯度幅值（边缘检测结果）")

    return True


def main():
    """主函数，处理命令行参数"""
    parser = argparse.ArgumentParser(
        description='Sobel边缘检测算法 - 输入图片，输出边缘检测后的图片',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  %(prog)s input.jpg output.jpg
  %(prog)s input.jpg output.jpg --threshold 50
  %(prog)s input.jpg --detailed --output-dir ./results
        """
    )

    parser.add_argument('input', help='输入图片路径')
    parser.add_argument('output', nargs='?', help='输出图片路径（简单模式）')
    parser.add_argument('--threshold', '-t', type=int,
                       help='阈值（0-255），用于二值化边缘图像')
    parser.add_argument('--detailed', '-d', action='store_true',
                       help='输出详细的中间结果（包括X/Y方向梯度）')
    parser.add_argument('--output-dir', '-o',
                       help='输出目录（详细模式）', default='./sobel_output')

    args = parser.parse_args()

    # 检查参数
    if args.detailed:
        # 详细模式
        success = apply_sobel_detailed(args.input, args.output_dir)
    else:
        # 简单模式
        if not args.output:
            print("错误：简单模式需要指定输出图片路径")
            parser.print_help()
            return 1

        success = apply_sobel(args.input, args.output, args.threshold)

    return 0 if success else 1


if __name__ == '__main__':
    sys.exit(main())
