# 单链表反转实现

这个项目实现了一个经典的数据结构算法：单链表反转。

## 文件说明

- `linked_list.h` - 头文件，包含结构定义和函数声明
- `linked_list.c` - 实现文件，包含所有函数的具体实现
- `test_linked_list.c` - 测试程序，包含多个测试用例
- `Makefile.linked_list` - 编译配置文件

## 核心功能

### 数据结构

```c
typedef struct Node {
    int data;
    struct Node *next;
} Node;
```

### 主要函数

- **reverse_list(Node *head)** - 反转单链表的核心函数
  - 算法：迭代法
  - 时间复杂度：O(n)
  - 空间复杂度：O(1)

### 辅助函数

- **create_node(int data)** - 创建新节点
- **print_list(Node *head)** - 打印链表内容
- **free_list(Node *head)** - 释放链表内存

## 算法原理

反转链表使用迭代法，核心思路：

1. 使用三个指针：
   - `prev` - 指向前一个节点
   - `current` - 指向当前节点
   - `next` - 指向下一个节点

2. 遍历链表，逐个反转每个节点的 `next` 指针

3. 最终返回新的头节点（原链表的尾节点）

示例：
```
原链表：1 -> 2 -> 3 -> 4 -> 5
反转后：5 -> 4 -> 3 -> 2 -> 1
```

## 编译和运行

### 编译

```bash
make -f Makefile.linked_list
```

### 运行测试

```bash
make -f Makefile.linked_list run
```

或直接运行：

```bash
./test_linked_list
```

### 清理

```bash
make -f Makefile.linked_list clean
```

## 测试用例

测试程序包含以下测试场景：

1. **空链表** - 测试边界情况
2. **单个节点** - 测试最小情况
3. **多个节点** - 测试正常情况 (1->2->3->4->5)
4. **两个节点** - 测试简单情况
5. **双重反转** - 验证算法正确性（反转两次应该回到原状态）

## 使用示例

```c
#include "linked_list.h"

int main() {
    // 创建链表：1 -> 2 -> 3
    Node *head = create_node(1);
    head->next = create_node(2);
    head->next->next = create_node(3);

    printf("原链表：");
    print_list(head);  // 输出：1 -> 2 -> 3

    // 反转链表
    head = reverse_list(head);

    printf("反转后：");
    print_list(head);  // 输出：3 -> 2 -> 1

    // 释放内存
    free_list(head);

    return 0;
}
```

## 技术要点

- 使用标准C99语法
- 启用所有编译警告 (-Wall -Wextra)
- 正确的内存管理（malloc/free）
- 完善的错误处理
- 详细的代码注释
