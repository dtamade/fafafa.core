# Iteration Archive

每轮迭代结束后，将仓库根目录的三文件归档到本目录的一个子目录中：

```
plans/archive/YYYY-MM-DD-<topic>/
  task_plan.md
  findings.md
  progress.md
```

推荐使用脚本自动完成归档 + 初始化下一轮：

```bash
bash plans/new_iteration.sh "<topic>"
```

