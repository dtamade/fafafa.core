# Working Directory - 模块工作进度跟踪

此目录包含各个活跃模块的详细工作进度文档。

---

## 📂 目录结构

```
working/
├── README.md               # 本文件
├── sync.WORKING.md        # Sync 模块工作进度
├── simd.WORKING.md        # SIMD 模块工作进度
├── time.WORKING.md        # Time 模块工作进度
├── atomic.WORKING.md      # Atomic 模块工作进度
└── graphics.WORKING.md    # Graphics 模块工作进度
```

---

## 🎯 使用指南

### 查看特定模块进度
```bash
# PowerShell
Get-Content working/sync.WORKING.md
Get-Content working/simd.WORKING.md

# Bash/Linux
cat working/sync.WORKING.md
cat working/simd.WORKING.md
```

### 查找包含特定关键词的模块
```bash
# PowerShell
Get-ChildItem working/*.WORKING.md | Select-String "condvar"

# Bash/Linux
grep -l "condvar" working/*.WORKING.md
```

### 查看所有模块的状态摘要
```bash
# 查看主 WORKING.md
Get-Content WORKING.md  # or: cat WORKING.md
```

---

## 📋 文件命名规范

- **格式**: `<module>.WORKING.md`
- **示例**: `sync.WORKING.md`, `simd.WORKING.md`
- **规则**: 
  - 使用小写模块名
  - 使用 `.WORKING.md` 后缀
  - 一个模块一个文件

---

## ✍️ 编写指南

每个 WORKING.md 文件应包含：

1. **模块元信息**
   - 模块名称
   - 最后更新日期
   - 当前状态（稳定/重构中/实验性等）

2. **当前任务**
   - 正在进行的工作
   - 待办事项列表
   - 优先级标注

3. **文件状态**
   - 已修改的文件
   - 新增的文件
   - 已删除的文件

4. **已知问题**
   - 当前遇到的问题
   - 解决方案或工作进展

5. **下一步行动**
   - 具体的命令或步骤
   - 决策点和选择

---

## 🔄 更新频率

- **高频**: 活跃开发中的模块（每天更新）
- **中频**: 维护中的模块（每周更新）
- **低频**: 稳定模块（有变更时更新）

---

## 📝 模板

创建新模块的 WORKING.md 时可以参考此模板：

```markdown
# <Module> 模块工作进度

**模块**: fafafa.core.<module>  
**最后更新**: YYYY-MM-DD  
**状态**: 🔄 状态描述

---

## 📋 当前任务

### 🔥 正在进行
- [ ] 任务 1
- [ ] 任务 2

---

## 📁 文件状态

### 🔄 已修改
- file1.pas
- file2.pas

### 🆕 新增
- newfile.pas

---

## 🎯 待办事项

- [ ] 待办 1
- [ ] 待办 2

---

## 🐛 已知问题

1. **问题描述**
   - 解决方案

---

## 🚀 下一步行动

```bash
# 具体命令
```

---

**下次工作从这里开始** 👇
```bash
# 下一步命令
```
```

---

## 🔗 相关文件

- **主进度文件**: `../WORKING.md`
- **模块 TODO**: `../todos/fafafa.core.<module>.md`
- **模块文档**: `../docs/fafafa.core.<module>.md`

---

**维护者**: 开发团队  
**创建日期**: 2025-10-02
