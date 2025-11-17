#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
办公工作日志自动生成工具
支持项目管理、任务跟踪、日志生成
"""

import json
import os
import sys
from datetime import datetime, timedelta
from pathlib import Path
import yaml


class LogGenerator:
    """日志生成器主类"""

    def __init__(self, config_file="config.yaml"):
        self.base_dir = Path(__file__).parent
        self.config = self.load_config(config_file)
        self.projects = self.load_projects()
        self.tasks = self.load_tasks()

    def load_config(self, config_file):
        """加载配置文件"""
        config_path = self.base_dir / config_file
        try:
            with open(config_path, 'r', encoding='utf-8') as f:
                return yaml.safe_load(f)
        except FileNotFoundError:
            print(f"警告: 配置文件 {config_file} 不存在，使用默认配置")
            return self.get_default_config()

    def get_default_config(self):
        """默认配置"""
        return {
            'log_directory': './logs',
            'date_format': '%Y-%m-%d',
            'chinese_date_format': '%Y年%m月%d日',
            'template_file': './templates/default_template.md',
            'language': 'zh-CN',
            'auto_save': True,
            'default_work_hours': 8,
            'preferences': {
                'show_progress': True,
                'show_statistics': True,
                'show_time_spent': True,
                'show_next_plan': True
            }
        }

    def load_projects(self):
        """加载项目数据"""
        projects_file = self.base_dir / 'data' / 'projects.json'
        try:
            with open(projects_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
                return data.get('projects', [])
        except FileNotFoundError:
            print("警告: projects.json 不存在，返回空列表")
            return []

    def load_tasks(self):
        """加载任务数据"""
        tasks_file = self.base_dir / 'data' / 'tasks.json'
        try:
            with open(tasks_file, 'r', encoding='utf-8') as f:
                return json.load(f)
        except FileNotFoundError:
            print("警告: tasks.json 不存在，返回空字典")
            return {'tasks': [], 'completed_today': []}

    def save_tasks(self):
        """保存任务数据"""
        tasks_file = self.base_dir / 'data' / 'tasks.json'
        with open(tasks_file, 'w', encoding='utf-8') as f:
            json.dump(self.tasks, f, ensure_ascii=False, indent=2)

    def save_projects(self):
        """保存项目数据"""
        projects_file = self.base_dir / 'data' / 'projects.json'
        with open(projects_file, 'w', encoding='utf-8') as f:
            json.dump({'projects': self.projects}, f, ensure_ascii=False, indent=2)

    def get_weekday(self, date):
        """获取星期几（中文）"""
        weekdays = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日']
        return weekdays[date.weekday()]

    def interactive_input(self):
        """交互式输入今日工作"""
        print("\n" + "="*60)
        print("  办公日志生成工具 - 交互式输入")
        print("="*60)

        # 显示待办事项
        pending_tasks = [t for t in self.tasks['tasks'] if t['status'] == 'pending']
        if pending_tasks:
            print("\n📋 今日待办事项：")
            for i, task in enumerate(pending_tasks, 1):
                priority_icon = "🔴" if task['priority'] == 'high' else "🟡" if task['priority'] == 'medium' else "🟢"
                project_name = self.get_project_name(task.get('project_id'))
                print(f"  {i}. {priority_icon} {task['content']}")
                if project_name:
                    print(f"     项目: {project_name}")

        # 选择完成的任务
        print("\n✅ 请选择今天完成的任务（输入序号，多个用逗号分隔，按回车跳过）：")
        completed_input = input("完成的任务: ").strip()

        completed_tasks = []
        if completed_input:
            try:
                indices = [int(x.strip()) - 1 for x in completed_input.split(',')]
                for idx in indices:
                    if 0 <= idx < len(pending_tasks):
                        task = pending_tasks[idx]
                        task['status'] = 'completed'
                        task['completion_date'] = datetime.now().strftime('%Y-%m-%d')
                        completed_tasks.append(task)
                        self.tasks['completed_today'].append(task['id'])
            except ValueError:
                print("输入格式错误，跳过任务选择")

        # 输入额外工作内容
        print("\n📝 其他完成的工作（每行一项，空行结束）：")
        additional_work = []
        while True:
            work = input("  - ").strip()
            if not work:
                break
            additional_work.append(work)

        # 添加新任务
        print("\n➕ 添加新的待办任务（可选，空行跳过）：")
        new_task = input("新任务: ").strip()
        if new_task:
            self.add_new_task(new_task)

        # 输入遇到的问题
        print("\n❓ 遇到的问题或需要注意的事项（可选，空行跳过）：")
        problems = []
        while True:
            problem = input("  - ").strip()
            if not problem:
                break
            problems.append(problem)

        # 输入明日计划
        print("\n📅 明日计划（每行一项，空行结束）：")
        next_plan = []
        while True:
            plan = input("  - ").strip()
            if not plan:
                break
            next_plan.append(plan)

        # 会议记录
        print("\n🗓️ 是否有会议需要记录？(y/n): ")
        has_meeting = input().strip().lower() == 'y'
        meetings = []
        if has_meeting:
            print("会议时间（如 10:00-11:00）: ")
            meeting_time = input().strip()
            print("会议主题: ")
            meeting_topic = input().strip()
            print("参会人员: ")
            meeting_attendees = input().strip()
            print("会议要点: ")
            meeting_notes = input().strip()
            meetings.append({
                'time': meeting_time,
                'topic': meeting_topic,
                'attendees': meeting_attendees,
                'notes': meeting_notes
            })

        return {
            'completed_tasks': completed_tasks,
            'additional_work': additional_work,
            'problems': problems,
            'next_plan': next_plan,
            'meetings': meetings
        }

    def get_project_name(self, project_id):
        """根据项目ID获取项目名称"""
        if not project_id:
            return None
        for proj in self.projects:
            if proj['id'] == project_id:
                return proj['name']
        return None

    def add_new_task(self, content):
        """添加新任务"""
        new_id = f"task{len(self.tasks['tasks']) + 1:03d}"
        new_task = {
            'id': new_id,
            'content': content,
            'project_id': None,
            'priority': 'medium',
            'status': 'pending',
            'created_date': datetime.now().strftime('%Y-%m-%d'),
            'due_date': (datetime.now() + timedelta(days=1)).strftime('%Y-%m-%d'),
            'estimated_hours': 2
        }
        self.tasks['tasks'].append(new_task)
        print(f"✅ 已添加新任务: {content}")

    def generate_log(self, work_data=None, date=None):
        """生成日志"""
        if date is None:
            date = datetime.now()

        if work_data is None:
            # 自动模式：基于数据生成
            work_data = self.get_auto_work_data()

        # 准备模板变量
        template_vars = self.prepare_template_vars(date, work_data)

        # 渲染模板
        log_content = self.render_template(template_vars)

        # 保存日志
        log_file = self.save_log(log_content, date)

        return log_file, log_content

    def get_auto_work_data(self):
        """自动模式：从数据中提取今日工作"""
        today = datetime.now().strftime('%Y-%m-%d')
        completed_today = [
            t for t in self.tasks['tasks']
            if t.get('completion_date') == today
        ]

        return {
            'completed_tasks': completed_today,
            'additional_work': [],
            'problems': [],
            'next_plan': [],
            'meetings': []
        }

    def prepare_template_vars(self, date, work_data):
        """准备模板变量"""
        weekday = self.get_weekday(date)
        date_cn = date.strftime(self.config['chinese_date_format'])

        # 生成工作内容
        work_content = self.generate_work_content()

        # 生成任务列表
        tasks_content = self.generate_tasks_content(work_data)

        # 统计信息
        completed_count = len(work_data['completed_tasks']) + len(work_data['additional_work'])
        total_count = len([t for t in self.tasks['tasks'] if t['status'] in ['pending', 'completed']])

        # 会议部分
        meetings_section = self.generate_meetings_section(work_data['meetings'])

        # 问题部分
        problems_section = self.generate_problems_section(work_data['problems'])

        # 统计部分
        statistics_section = self.generate_statistics_section()

        # 明日计划
        next_plan = self.generate_next_plan(work_data['next_plan'])

        # 生成概要
        summary = self.generate_summary(work_data, completed_count)

        return {
            'date_cn': date_cn,
            'weekday': weekday,
            'summary': summary,
            'work_content': work_content,
            'tasks': tasks_content,
            'completed_count': completed_count,
            'total_count': total_count,
            'meetings_section': meetings_section,
            'problems_section': problems_section,
            'statistics_section': statistics_section,
            'next_plan': next_plan,
            'generated_time': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        }

    def generate_work_content(self):
        """生成主要工作内容"""
        content_lines = []

        for project in self.projects:
            if project['status'] in ['进行中', '即将开始']:
                content_lines.append(f"### {project['name']} - 进度：{project['progress']}%")

                for task in project['tasks']:
                    if task['status'] == 'completed':
                        content_lines.append(f"- ✅ {task['name']}")
                    elif task['status'] == 'in_progress':
                        progress_info = f" ({task.get('progress', 0)}%)" if 'progress' in task else ""
                        content_lines.append(f"- 🔄 {task['name']}{progress_info}")
                    elif task['status'] == 'pending':
                        content_lines.append(f"- ⏸️ {task['name']}")

                content_lines.append("")  # 空行

        return '\n'.join(content_lines) if content_lines else "无进行中的项目"

    def generate_tasks_content(self, work_data):
        """生成完成事项内容"""
        lines = []

        # 已完成的任务
        for task in work_data['completed_tasks']:
            project_name = self.get_project_name(task.get('project_id'))
            task_line = f"- [x] {task['content']}"
            if project_name:
                task_line += f" `{project_name}`"
            lines.append(task_line)

        # 额外的工作
        for work in work_data['additional_work']:
            lines.append(f"- [x] {work}")

        # 未完成的任务
        pending_tasks = [t for t in self.tasks['tasks'] if t['status'] == 'pending']
        for task in pending_tasks[:3]:  # 只显示前3个
            project_name = self.get_project_name(task.get('project_id'))
            task_line = f"- [ ] {task['content']}"
            if project_name:
                task_line += f" `{project_name}`"
            lines.append(task_line)

        return '\n'.join(lines) if lines else "- 暂无任务记录"

    def generate_meetings_section(self, meetings):
        """生成会议记录部分"""
        if not meetings:
            return ""

        lines = ["\n## 会议记录"]
        for meeting in meetings:
            lines.append(f"- **{meeting['time']}** {meeting['topic']}")
            if meeting.get('attendees'):
                lines.append(f"  - 参会人员：{meeting['attendees']}")
            if meeting.get('notes'):
                lines.append(f"  - 要点：{meeting['notes']}")

        return '\n'.join(lines)

    def generate_problems_section(self, problems):
        """生成问题部分"""
        if not problems:
            return ""

        lines = ["\n## 遇到的问题"]
        for problem in problems:
            lines.append(f"- {problem}")

        return '\n'.join(lines)

    def generate_statistics_section(self):
        """生成统计部分"""
        if not self.config['preferences']['show_statistics']:
            return ""

        lines = ["\n## 工作统计"]

        # 项目进度统计
        total_projects = len(self.projects)
        active_projects = len([p for p in self.projects if p['status'] == '进行中'])
        lines.append(f"- 进行中项目：{active_projects}/{total_projects}")

        # 任务统计
        total_tasks = len(self.tasks['tasks'])
        completed_tasks = len([t for t in self.tasks['tasks'] if t['status'] == 'completed'])
        pending_tasks = len([t for t in self.tasks['tasks'] if t['status'] == 'pending'])
        lines.append(f"- 任务完成率：{completed_tasks}/{total_tasks} ({completed_tasks*100//total_tasks if total_tasks > 0 else 0}%)")
        lines.append(f"- 待办任务：{pending_tasks}个")

        return '\n'.join(lines)

    def generate_next_plan(self, plan_items):
        """生成明日计划"""
        if not plan_items:
            # 自动生成：从待办任务中选择
            pending = [t for t in self.tasks['tasks'] if t['status'] == 'pending'][:3]
            if pending:
                lines = [f"- [ ] {t['content']}" for t in pending]
                return '\n'.join(lines)
            else:
                return "- 待规划"

        lines = [f"- [ ] {item}" for item in plan_items]
        return '\n'.join(lines)

    def generate_summary(self, work_data, completed_count):
        """生成今日概要"""
        summary_parts = []

        if completed_count > 0:
            summary_parts.append(f"今日完成{completed_count}项工作")

        if work_data['meetings']:
            summary_parts.append(f"参加{len(work_data['meetings'])}个会议")

        # 获取主要项目
        active_projects = [p['name'] for p in self.projects if p['status'] == '进行中']
        if active_projects:
            summary_parts.append(f"主要推进：{active_projects[0]}")

        if not summary_parts:
            summary_parts.append("正常工作进行中")

        return "，".join(summary_parts) + "。"

    def render_template(self, template_vars):
        """渲染模板"""
        template_file = self.base_dir / self.config['template_file']

        try:
            with open(template_file, 'r', encoding='utf-8') as f:
                template = f.read()
        except FileNotFoundError:
            print("警告: 模板文件不存在，使用默认模板")
            template = self.get_default_template()

        # 简单的变量替换
        for key, value in template_vars.items():
            template = template.replace(f'{{{key}}}', str(value))

        return template

    def get_default_template(self):
        """默认模板"""
        return """# 工作日志 - {date_cn} {weekday}

## 今日工作概要
{summary}

## 主要工作内容
{work_content}

## 完成事项 ({completed_count}/{total_count})
{tasks}

{meetings_section}

{problems_section}

## 明日计划
{next_plan}

{statistics_section}

---
*本日志由自动生成工具创建于 {generated_time}*
"""

    def save_log(self, content, date):
        """保存日志文件"""
        # 创建日志目录
        log_dir = self.base_dir / self.config['log_directory']
        month_dir = log_dir / date.strftime('%Y-%m')
        month_dir.mkdir(parents=True, exist_ok=True)

        # 生成文件名
        filename = date.strftime('%Y-%m-%d') + '.md'
        log_file = month_dir / filename

        # 保存文件
        with open(log_file, 'w', encoding='utf-8') as f:
            f.write(content)

        return log_file


def main():
    """主函数"""
    import argparse

    parser = argparse.ArgumentParser(description='办公工作日志生成工具')
    parser.add_argument('-i', '--interactive', action='store_true', help='交互式输入模式')
    parser.add_argument('-d', '--date', type=str, help='指定日期 (格式: YYYY-MM-DD)')
    parser.add_argument('-q', '--quick', type=str, help='快速记录工作内容')
    parser.add_argument('--view', action='store_true', help='查看生成的日志')

    args = parser.parse_args()

    # 初始化生成器
    generator = LogGenerator()

    # 确定日期
    if args.date:
        try:
            target_date = datetime.strptime(args.date, '%Y-%m-%d')
        except ValueError:
            print("错误: 日期格式不正确，请使用 YYYY-MM-DD 格式")
            return
    else:
        target_date = datetime.now()

    # 获取工作数据
    if args.interactive:
        work_data = generator.interactive_input()
    elif args.quick:
        work_data = {
            'completed_tasks': [],
            'additional_work': [args.quick],
            'problems': [],
            'next_plan': [],
            'meetings': []
        }
    else:
        work_data = None  # 自动模式

    # 生成日志
    log_file, log_content = generator.generate_log(work_data, target_date)

    # 保存数据
    if args.interactive or args.quick:
        generator.save_tasks()
        generator.save_projects()

    print(f"\n✅ 日志生成成功！")
    print(f"📁 保存位置: {log_file}")

    # 显示日志内容
    if args.view:
        print("\n" + "="*60)
        print(log_content)
        print("="*60)


if __name__ == '__main__':
    main()
