# fafafa.core.fs 开发者须知（最佳实践与 PR 自检）

> 面向工程落地：跨平台一致性、性能稳定、无意外行为。

## 一、API 使用与错误处理
- 高层 vs 低层：
  - 业务/应用：IFsFile、WalkDir
  - 系统/工具：fs_*（追求极致开销）
- 错误模型：FS_UNIFIED_ERRORS 默认启用
  - 业务侧仅用 FsErrorKind 分类，不比较具体负值
  - fs_open 失败：用 IsValidHandle 判定 → 取系统错码 → SystemErrorToFsError 统一
- 便捷函数优先：realpath_s/readlink_s；遍历首选 WalkDir 或 fs_scandir_each

## 二、路径最佳实践
- 规范化：ResolvePath（不触盘）
- 真实路径：ResolvePathEx(Path, FollowLinks=True, TouchDisk=True)（存在时 realpath，失败回退）
- 比较：一律 PathsEqual / IsSubPath；避免大小写与分隔符坑
- Windows 长路径：需要显式环境/策略支持；仅绝对路径加前缀；默认测试跳过
- Symlink：默认不跟随；跟随时务必限制 MaxDepth 并防环

## 三、遍历（Walk）
- FollowSymlinks 默认 False；需要时与 MaxDepth 搭配
- IncludeFiles/IncludeDirs 明确；用 PreFilter/PostFilter 减少无效 stat
- 回调返回 False 早停；回调里避免多次触盘

## 四、I/O 性能
- 大块读写（如 64KB）；顺序优先
- 并发：优先 PRead/PWrite（不共享位置）；句柄共享需同步
- 枚举：优先 fs_scandir_each（边枚举边处理）

## 五、测试（TDD 平衡效率）
- 覆盖：每个公开函数/重载均有 Test_函数名；全局函数放 TTestCase_Global
- 确定性：避免依赖系统时间/权限/磁盘状态；断言顺序稳定
- 条件化：
  - Win 长路径：FAFAFA_TEST_WIN_LONGPATH=1 才运行
  - Symlink：Unix 默认开；Windows 需 FAFAFA_TEST_SYMLINK=1
- 资源：临时文件/目录用 try/finally 清理；heaptrc 必须 0 泄漏

## 六、构建与文档
- lazbuild 标准化；lib/ 存中间文件，bin/ 存二进制
- 文档与实现一致（特别是 FS_UNIFIED_ERRORS、路径语义）
- 示例需能编能跑（阻塞性问题最小修复）

## 七、渐进弃用策略
- 先文档弱化（推荐替代），再加 deprecated 提示（工具链允许），大版本移除

---

## PR 自检清单（提交前逐条确认）
- [ ] 未改变对外行为或默认值；若有，已获批准并附迁移说明
- [ ] 未引入不必要的触盘/realpath；ResolvePathEx 仅在需要时使用
- [ ] 新/改代码已覆盖测试；命名规范（Test_函数名…）且确定性
- [ ] 条件化测试默认跳过；环境开关说明清晰
- [ ] 临时资源清理完毕；heaptrc 0 泄漏
- [ ] 文档已同步（docs 与 settings.inc 一致）；示例可编可跑
- [ ] 性能无明显回退；如有，已记录到 perf-baseline 并报备（冻结期不做优化）

---

参考索引：
- 模块文档：docs/fafafa.core.fs.md
- 冻结说明：report/fafafa.core.fs.freeze.md
- API 清单：report/fafafa.core.fs.api-inventory.md
- 性能基线：report/fafafa.core.fs.perf-baseline.md
- 条件化测试开关：README.md & docs/fafafa.core.fs.md

