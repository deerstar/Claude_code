#include "linked_list.h"
#include <stdio.h>

int main() {
    printf("=== 单链表反转测试程序 ===\n\n");

    // 测试1：空链表
    printf("测试1：空链表\n");
    Node *empty_list = NULL;
    empty_list = reverse_list(empty_list);
    printf("反转后：");
    print_list(empty_list);
    printf("\n");

    // 测试2：单个节点
    printf("测试2：单个节点\n");
    Node *single = create_node(1);
    printf("反转前：");
    print_list(single);
    single = reverse_list(single);
    printf("反转后：");
    print_list(single);
    free_list(single);
    printf("\n");

    // 测试3：多个节点
    printf("测试3：多个节点 (1 -> 2 -> 3 -> 4 -> 5)\n");
    Node *head = create_node(1);
    head->next = create_node(2);
    head->next->next = create_node(3);
    head->next->next->next = create_node(4);
    head->next->next->next->next = create_node(5);

    printf("反转前：");
    print_list(head);

    head = reverse_list(head);

    printf("反转后：");
    print_list(head);
    free_list(head);
    printf("\n");

    // 测试4：两个节点
    printf("测试4：两个节点 (10 -> 20)\n");
    Node *two_nodes = create_node(10);
    two_nodes->next = create_node(20);

    printf("反转前：");
    print_list(two_nodes);

    two_nodes = reverse_list(two_nodes);

    printf("反转后：");
    print_list(two_nodes);
    free_list(two_nodes);
    printf("\n");

    // 测试5：再次反转（验证可以反转回去）
    printf("测试5：双重反转 (1 -> 2 -> 3)\n");
    Node *double_reverse = create_node(1);
    double_reverse->next = create_node(2);
    double_reverse->next->next = create_node(3);

    printf("原始链表：");
    print_list(double_reverse);

    double_reverse = reverse_list(double_reverse);
    printf("第一次反转：");
    print_list(double_reverse);

    double_reverse = reverse_list(double_reverse);
    printf("第二次反转：");
    print_list(double_reverse);
    free_list(double_reverse);

    printf("\n所有测试完成！\n");
    return 0;
}
