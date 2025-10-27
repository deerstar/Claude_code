#include "linked_list.h"
#include <stdio.h>
#include <stdlib.h>

/**
 * 反转单链表 - 使用迭代法
 *
 * 算法思路：
 * 1. 使用三个指针：prev（前一个节点）、current（当前节点）、next（下一个节点）
 * 2. 遍历链表，逐个反转每个节点的 next 指针
 * 3. 返回新的头节点（原链表的尾节点）
 *
 * 时间复杂度：O(n)
 * 空间复杂度：O(1)
 */
Node* reverse_list(Node *head) {
    // 空链表或只有一个节点，直接返回
    if (head == NULL || head->next == NULL) {
        return head;
    }

    Node *prev = NULL;      // 前一个节点
    Node *current = head;   // 当前节点
    Node *next = NULL;      // 下一个节点

    // 遍历链表，反转每个节点的指针
    while (current != NULL) {
        next = current->next;     // 保存下一个节点
        current->next = prev;     // 反转当前节点的指针
        prev = current;           // prev 向前移动
        current = next;           // current 向前移动
    }

    // prev 现在指向原链表的最后一个节点，即新链表的头节点
    return prev;
}

/**
 * 创建新节点
 */
Node* create_node(int data) {
    Node *new_node = (Node*)malloc(sizeof(Node));
    if (new_node == NULL) {
        fprintf(stderr, "内存分配失败\n");
        exit(1);
    }
    new_node->data = data;
    new_node->next = NULL;
    return new_node;
}

/**
 * 打印链表
 */
void print_list(Node *head) {
    Node *current = head;
    while (current != NULL) {
        printf("%d", current->data);
        if (current->next != NULL) {
            printf(" -> ");
        }
        current = current->next;
    }
    printf("\n");
}

/**
 * 释放链表内存
 */
void free_list(Node *head) {
    Node *current = head;
    Node *next;

    while (current != NULL) {
        next = current->next;
        free(current);
        current = next;
    }
}
