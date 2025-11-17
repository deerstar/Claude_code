# 办公工作日志自动生成工具

一个智能的日志生成工具，帮助你自动记录和管理日常办公工作。

## 功能特性

- ✅ **项目进度管理** - 跟踪多个项目的进展
- ✅ **任务管理** - 待办事项列表和完成记录
- ✅ **智能生成** - 基于数据自动生成日志
- ✅ **交互式输入** - 友好的命令行交互界面
- ✅ **模板定制** - 支持自定义日志格式
- ✅ **统计分析** - 自动计算工作统计信息

## 目录结构

```
daily_work_log/
├── generate_log.py          # 主程序
├── config.yaml              # 配置文件
├── data/
│   ├── projects.json        # 项目数据
│   └── tasks.json           # 任务数据
├── logs/
│   └── YYYY-MM/             # 按月份存储的日志
├── templates/
│   └── default_template.md  # 日志模板
└── README.md                # 本文件
```

## 快速开始

### 1. 安装依赖

```bash
pip install pyyaml
```

### 2. 运行程序

```bash
cd daily_work_log

# 方式1: 自动模式（基于现有数据生成）
python generate_log.py

# 方式2: 交互式输入（推荐）
python generate_log.py --interactive

# 方式3: 快速记录
python generate_log.py --quick "完成了项目文档编写"

# 查看生成的日志
python generate_log.py --view
```

## 使用指南

### 交互式输入模式

推荐使用交互式模式，按照提示逐步输入工作内容：

```bash
python generate_log.py -i
```

程序会引导你：
1. 查看并选择完成的待办任务
2. 输入其他完成的工作
3. 添加新的待办任务
4. 记录遇到的问题
5. 规划明日计划
6. 记录会议信息

### 项目管理

编辑 `data/projects.json` 文件来管理你的项目：

```json
{
  "projects": [
    {
      "id": "proj001",
      "name": "项目名称",
      "description": "项目描述",
      "progress": 75,
      "status": "进行中",
      "start_date": "2025-10-01",
      "deadline": "2025-12-31",
      "priority": "high",
      "tasks": [
        {
          "name": "任务1",
          "status": "completed",
          "completion_date": "2025-11-15"
        }
      ]
    }
  ]
}
```

**状态值说明：**
- `进行中` - 正在进行的项目
- `已完成` - 已结束的项目
- `即将开始` - 计划中的项目
- `暂停` - 暂时搁置的项目

### 任务管理

编辑 `data/tasks.json` 文件来管理待办事项：

```json
{
  "tasks": [
    {
      "id": "task001",
      "content": "任务描述",
      "project_id": "proj001",
      "priority": "high",
      "status": "pending",
      "created_date": "2025-11-17",
      "due_date": "2025-11-20",
      "estimated_hours": 4
    }
  ],
  "completed_today": []
}
```

**优先级：**
- `high` - 高优先级 🔴
- `medium` - 中优先级 🟡
- `low` - 低优先级 🟢

**状态：**
- `pending` - 待处理
- `in_progress` - 进行中
- `completed` - 已完成

### 自定义模板

编辑 `templates/default_template.md` 来自定义日志格式。

模板支持以下变量：
- `{date_cn}` - 中文日期
- `{weekday}` - 星期几
- `{summary}` - 工作概要
- `{work_content}` - 主要工作内容
- `{tasks}` - 任务列表
- `{completed_count}` - 完成任务数
- `{total_count}` - 总任务数
- `{meetings_section}` - 会议记录
- `{problems_section}` - 问题记录
- `{statistics_section}` - 统计信息
- `{next_plan}` - 明日计划
- `{generated_time}` - 生成时间

### 配置选项

编辑 `config.yaml` 来调整配置：

```yaml
# 日志存储目录
log_directory: "./logs"

# 日期格式
date_format: "%Y-%m-%d"
chinese_date_format: "%Y年%m月%d日"

# 日志模板
template_file: "./templates/default_template.md"

# 日志格式偏好
preferences:
  show_progress: true      # 显示项目进度
  show_statistics: true    # 显示统计信息
  show_time_spent: true    # 显示时间统计
  show_next_plan: true     # 显示明日计划
```

## 命令行参数

```bash
# 交互式输入模式
python generate_log.py --interactive
python generate_log.py -i

# 指定日期生成日志
python generate_log.py --date 2025-11-16

# 快速记录工作
python generate_log.py --quick "完成XX工作"
python generate_log.py -q "完成XX工作"

# 生成并查看日志
python generate_log.py --view
```

## 生成的日志示例

```markdown
# 工作日志 - 2025年11月17日 星期日

## 今日工作概要
今日完成3项工作，主要推进：以太网MAC控制器开发。

## 主要工作内容
### 以太网MAC控制器开发 - 进度：75%
- ✅ 需求分析
- ✅ 设计方案
- 🔄 代码实现 (80%)
- ⏸️ 测试验证

## 完成事项 (3/5)
- [x] 完成MAC控制器测试用例编写 `以太网MAC控制器开发`
- [x] 更新项目文档 `以太网MAC控制器开发`
- [x] 准备周报
- [ ] 其他待办任务...

## 明日计划
- [ ] 继续完成MAC控制器代码实现
- [ ] 开始测试验证工作

## 工作统计
- 进行中项目：2/2
- 任务完成率：15/20 (75%)
- 待办任务：5个

---
*本日志由自动生成工具创建于 2025-11-17 14:30:00*
```

## 工作流程建议

### 每日开始
1. 查看 `tasks.json` 中的待办事项
2. 规划今日工作优先级

### 每日结束
1. 运行 `python generate_log.py -i`
2. 选择完成的任务
3. 记录工作内容
4. 添加明日计划
5. 查看生成的日志

### 每周总结
1. 查看本周所有日志文件
2. 更新项目进度
3. 调整下周计划

## 高级技巧

### 1. 批量生成历史日志

```bash
# 生成指定日期的日志
for date in 2025-11-15 2025-11-16; do
    python generate_log.py --date $date
done
```

### 2. 导出项目报告

可以编写脚本汇总月度/周度日志，生成项目报告。

### 3. 结合Git使用

```bash
# 每天自动提交日志
python generate_log.py -i
git add logs/
git commit -m "docs: 添加$(date +%Y-%m-%d)工作日志"
```

## 常见问题

**Q: 如何修改已生成的日志？**
A: 直接编辑 `logs/YYYY-MM/YYYY-MM-DD.md` 文件即可。

**Q: 可以导出为其他格式吗？**
A: 日志使用Markdown格式，可以使用pandoc等工具转换为PDF、Word等格式。

**Q: 如何备份数据？**
A: 定期备份 `data/` 和 `logs/` 目录即可。

**Q: 支持多人协作吗？**
A: 可以将数据文件放在Git仓库中，通过版本控制实现协作。

## 未来计划

- [ ] Web界面支持
- [ ] 数据可视化（图表统计）
- [ ] AI辅助生成工作总结
- [ ] 周报/月报自动汇总
- [ ] 移动端应用
- [ ] 与日历/任务管理工具集成

## 贡献

欢迎提交Issue和Pull Request！

## 许可证

MIT License

---

**祝你工作高效！** 🚀
