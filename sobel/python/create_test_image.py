#!/usr/bin/env python3
"""
生成测试图像用于 Sobel 边缘检测演示
"""

import numpy as np
import cv2


def create_test_image(filename='test_image.jpg', size=400):
    """
    创建一个包含各种形状的测试图像

    参数:
        filename: 输出文件名
        size: 图像大小
    """
    # 创建白色背景
    img = np.ones((size, size, 3), dtype=np.uint8) * 255

    # 绘制矩形
    cv2.rectangle(img, (50, 50), (150, 150), (0, 0, 255), -1)

    # 绘制圆形
    cv2.circle(img, (300, 100), 50, (0, 255, 0), -1)

    # 绘制三角形
    pts = np.array([[100, 250], [200, 250], [150, 180]], np.int32)
    pts = pts.reshape((-1, 1, 2))
    cv2.fillPoly(img, [pts], (255, 0, 0))

    # 绘制线条
    cv2.line(img, (250, 200), (350, 300), (128, 128, 128), 3)

    # 添加文字
    cv2.putText(img, 'SOBEL', (200, 350), cv2.FONT_HERSHEY_SIMPLEX,
                1, (0, 0, 0), 2, cv2.LINE_AA)

    # 保存图像
    cv2.imwrite(filename, img)
    print(f"测试图像已创建: {filename}")
    print(f"图像尺寸: {size}x{size}")


if __name__ == '__main__':
    create_test_image('test_image.jpg')
