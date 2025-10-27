#ifndef LINKED_LIST_H
#define LINKED_LIST_H

typedef struct Node {
    int data;
    struct Node *next;
} Node;

/**
 * 反转单链表
 * @param head 链表的头节点
 * @return 反转后的链表头节点
 */
Node* reverse_list(Node *head);

/**
 * 创建新节点
 * @param data 节点数据
 * @return 新创建的节点指针
 */
Node* create_node(int data);

/**
 * 打印链表
 * @param head 链表头节点
 */
void print_list(Node *head);

/**
 * 释放链表内存
 * @param head 链表头节点
 */
void free_list(Node *head);

#endif // LINKED_LIST_H
