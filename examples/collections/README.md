# fafafa.core.collections - 示例代码索引

本目录包含 fafafa.core.collections 模块的实用示例代码。

## 📋 示例列表

### 基础容器示例

#### HashMap / HashSet 相关

1. **example_session_manager.pas** - 会话管理器
   - 使用 HashMap 实现用户会话管理
   - 快速会话查找（O(1)）
   - 会话超时清理机制
   - 适合高并发 Web 应用场景

2. **example_word_counter.pas** - 单词统计器
   - 使用 HashMap 统计单词频率
   - 计数器模式演示
   - 排序输出前N名
   - 适合文本分析、日志统计场景

3. **example_log_aggregator.pas** - 日志聚合器
   - 使用 HashMap + Vec 实现多维度日志聚合
   - 按级别分组存储
   - 错误模式分析
   - 适合日志收集、监控系统

4. **example_deduplicator.pas** - 数据去重器
   - 使用 HashSet 实现高效去重
   - O(1) 重复检测
   - 统计去重效果
   - 适合数据清洗、ETL 场景

#### TreeMap / TreeSet 相关

5. **example_event_scheduler.pas** - 事件调度器
   - 使用 TreeMap 实现时间线管理
   - 自动按时间排序
   - 查询最近事件
   - 适合日程表、提醒系统

6. **example_leaderboard.pas** - 排行榜系统
   - 使用 TreeSet 实现游戏排行榜
   - 自动按分数降序排序
   - 同分按名字排序
   - 适合游戏、竞赛系统

#### LinkedHashMap 相关

7. **example_web_cache.pas** - Web 缓存（LRU）
   - 使用 LinkedHashMap 实现 LRU 缓存
   - 插入顺序保持
   - 自动淘汰最久未使用项
   - 适合 HTTP 缓存、API 缓存

8. **example_config_manager.pas** - 配置管理器
   - 使用 LinkedHashMap 保持配置顺序
   - 便于人工编辑的配置文件
   - 顺序遍历输出
   - 适合 INI/TOML 配置解析

9. **linkedhashmap_lru.pas** - LRU 缓存实现
   - LinkedHashMap 的完整 LRU 缓存实现
   - 插入顺序保持
   - 自动淘汰最旧项
   - 容量限制管理

#### Vec / VecDeque / List 相关

10. **example_sliding_window.pas** - 滑动窗口统计
    - 使用 VecDeque 实现滑动窗口
    - 两端 O(1) 操作
    - 实时统计（平均、最大、最小）
    - 适合监控、实时分析场景

11. **example_object_pool.pas** - 对象池
    - 使用 Vec 实现对象池模式
    - 避免频繁创建/销毁对象
    - 性能优化示例
    - 适合数据库连接池、线程池

#### PriorityQueue 相关

12. **example_task_scheduler.pas** - 任务调度器
    - 使用 PriorityQueue 实现优先级调度
    - 自定义优先级比较
    - 动态插入紧急任务
    - 适合任务队列、作业调度

13. **example_priorityqueue_tasks.pas** - 优先队列任务调度
    - 演示 PriorityQueue 基础用法
    - 自定义比较器函数
    - 优先级处理流程

14. **example_pathfinding.pas** - A* 路径查找
    - 使用 PriorityQueue + HashSet 实现 A* 算法
    - 启发式搜索演示
    - 障碍物避让
    - 适合游戏开发、地图导航

#### BitSet 相关

15. **bitset_permissions.pas** - 权限管理系统
    - 使用 BitSet 管理用户权限位
    - 位运算（AND, OR, XOR）进行权限组合
    - 高效内存使用（1 bit/权限）
    - 批量权限操作性能演示

## 🚀 如何运行示例

### 编译单个示例

```bash
cd /home/dtamade/projects/fafafa.core
fpc -Fu./src -Fi./src -FE./bin ./examples/collections/example_priorityqueue_tasks.pas
./bin/example_priorityqueue_tasks
```

### 编译所有示例

```bash
cd examples/collections
for f in example_*.pas; do
    fpc -Fu../../src -Fi../../src -FE../../bin "$f"
done
```

## 📚 更多资源

- **容器选择指南**: `../../docs/COLLECTIONS_DECISION_TREE.md`
- **最佳实践**: `../../docs/COLLECTIONS_BEST_PRACTICES.md`
- **API 参考**: `../../docs/COLLECTIONS_API_REFERENCE.md`
- **性能基准测试**: `../../benchmarks/collections/`
- **测试代码**: `../../tests/fafafa.core.collections.*/`

## 🎯 场景速查表

| 场景 | 推荐示例 | 使用容器 |
|------|----------|----------|
| Web 缓存 | `example_web_cache.pas` | LinkedHashMap |
| 用户会话 | `example_session_manager.pas` | HashMap |
| 任务调度 | `example_task_scheduler.pas` | PriorityQueue |
| 日志聚合 | `example_log_aggregator.pas` | HashMap + Vec |
| 配置管理 | `example_config_manager.pas` | LinkedHashMap |
| 词频统计 | `example_word_counter.pas` | HashMap |
| 事件日程 | `example_event_scheduler.pas` | TreeMap |
| 数据去重 | `example_deduplicator.pas` | HashSet |
| 滑动窗口 | `example_sliding_window.pas` | VecDeque |
| 对象池 | `example_object_pool.pas` | Vec |
| 排行榜 | `example_leaderboard.pas` | TreeSet |
| 路径查找 | `example_pathfinding.pas` | PriorityQueue |
| 权限管理 | `bitset_permissions.pas` | BitSet |

## 💡 推荐阅读顺序

### 初学者路径
1. `example_word_counter.pas` - HashMap 基础用法
2. `example_deduplicator.pas` - HashSet 去重
3. `example_session_manager.pas` - HashMap 实战应用
4. `example_web_cache.pas` - LinkedHashMap LRU 缓存
5. `example_task_scheduler.pas` - PriorityQueue 优先级调度

### 进阶路径
6. `example_log_aggregator.pas` - 多容器组合使用
7. `example_event_scheduler.pas` - TreeMap 有序管理
8. `example_sliding_window.pas` - VecDeque 高效操作
9. `example_pathfinding.pas` - A* 算法实现
10. `example_object_pool.pas` - 对象池模式

### 高级应用
11. `example_leaderboard.pas` - TreeSet 自动排序
12. `example_config_manager.pas` - 配置文件顺序保持
13. `bitset_permissions.pas` - BitSet 极致内存优化

### 完整学习路径
1. 查看上述示例代码
2. 阅读 `docs/COLLECTIONS_DECISION_TREE.md` - 容器选择指南
3. 阅读 `docs/COLLECTIONS_BEST_PRACTICES.md` - 最佳实践
4. 阅读 `docs/COLLECTIONS_API_REFERENCE.md` - 完整 API
5. 浏览 `tests/` 目录查看单元测试示例

## 🤝 贡献

欢迎提交更多实用示例！示例应：
- 演示实际应用场景
- 包含清晰的注释
- 可以独立编译运行
- 输出结果易于理解

---

**维护者**: fafafa.core Team  
**更新日期**: 2025-10-28

