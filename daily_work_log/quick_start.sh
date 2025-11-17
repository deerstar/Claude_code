#!/bin/bash
# 办公日志生成工具 - 快速启动脚本

echo "========================================"
echo "  办公日志生成工具"
echo "========================================"
echo ""
echo "请选择操作模式："
echo ""
echo "1) 交互式输入（推荐）"
echo "2) 自动生成（基于现有数据）"
echo "3) 快速记录"
echo "4) 查看今日日志"
echo "5) 帮助信息"
echo ""
read -p "请输入选项 (1-5): " choice

case $choice in
    1)
        echo ""
        echo "启动交互式输入模式..."
        python3 generate_log.py --interactive
        ;;
    2)
        echo ""
        echo "自动生成日志..."
        python3 generate_log.py --view
        ;;
    3)
        echo ""
        read -p "请输入今日完成的工作: " work
        python3 generate_log.py --quick "$work"
        ;;
    4)
        echo ""
        today=$(date +%Y-%m-%d)
        month=$(date +%Y-%m)
        if [ -f "logs/$month/$today.md" ]; then
            cat "logs/$month/$today.md"
        else
            echo "今日还没有生成日志，请先运行生成命令。"
        fi
        ;;
    5)
        echo ""
        python3 generate_log.py --help
        ;;
    *)
        echo "无效选项"
        exit 1
        ;;
esac

echo ""
echo "操作完成！"
