# Sobel 边缘检测算法 (Python 实现)

这是一个使用 Python 实现的 Sobel 边缘检测算法，可以读取输入图片并输出边缘检测后的图片。

## 功能特点

- 支持常见图片格式（JPG, PNG, BMP 等）
- 实现完整的 Sobel 边缘检测算法
- 支持简单模式和详细模式
- 可选的阈值二值化
- 输出 X 方向、Y 方向梯度和梯度幅值

## 安装依赖

```bash
pip install -r requirements.txt
```

## 使用方法

### 基本用法

```bash
python sobel.py input.jpg output.jpg
```

### 使用阈值二值化

```bash
python sobel.py input.jpg output.jpg --threshold 50
```

### 详细模式（输出所有中间结果）

```bash
python sobel.py input.jpg --detailed --output-dir ./results
```

详细模式会输出以下文件：
- `gray.jpg` - 灰度图
- `sobel_x.jpg` - X 方向梯度
- `sobel_y.jpg` - Y 方向梯度
- `sobel_magnitude.jpg` - 梯度幅值（最终边缘检测结果）

## 命令行参数

- `input` - 输入图片路径（必需）
- `output` - 输出图片路径（简单模式必需）
- `--threshold, -t` - 阈值（0-255），用于二值化边缘图像
- `--detailed, -d` - 启用详细模式，输出所有中间结果
- `--output-dir, -o` - 输出目录（详细模式使用，默认为 ./sobel_output）

## Sobel 算法原理

Sobel 算子是一种用于边缘检测的离散微分算子，它结合了高斯平滑和微分求导。

### Sobel 算子

X 方向（检测垂直边缘）：
```
[-1  0  1]
[-2  0  2]
[-1  0  1]
```

Y 方向（检测水平边缘）：
```
[-1 -2 -1]
[ 0  0  0]
[ 1  2  1]
```

### 处理流程

1. 将彩色图像转换为灰度图
2. 分别应用 X 方向和 Y 方向的 Sobel 算子
3. 计算梯度幅值：`magnitude = sqrt(Gx² + Gy²)`
4. 归一化到 0-255 范围
5. （可选）应用阈值进行二值化

## 示例

创建一个简单的测试图像：

```bash
# 使用详细模式处理图片
python sobel.py test.jpg --detailed --output-dir ./results

# 使用阈值二值化
python sobel.py test.jpg edges.jpg --threshold 100
```

## 技术实现

- 使用 OpenCV 进行图像处理
- 使用 NumPy 进行数值计算
- Sobel 算子核大小：3x3
- 梯度计算使用 64 位浮点数精度

## 许可证

MIT License
