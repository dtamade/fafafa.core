# CHANGELOG · fafafa.core.fs

## Unreleased

### Added
- Walk OnError policy (weaContinue/weaSkipSubtree/weaAbort) semantics and docs; default behavior preserved when OnError=nil
- OpenFileEx factory with exception-safe resource release
- FsOptsReadOnly/FsOptsWriteTruncate/FsOptsReadWrite shorthand helpers
- Minimal examples and centralized FAQ entries
- New unit tests: OnError Continue/Abort/SkipSubtree; streaming consistency + filters/stats

### Notes
- OnError=weaContinue on invalid root returns 0 (empty traversal)
- OnError=nil keeps legacy negative error return for invalid root



## 2025-08-19

### Added
- Docs: 目录树 Copy/Move 小节新增“更多实践与示例”直链（partials + example_copytree_follow）
- Docs: 增补 PreserveTimes/Perms 示例（best‑effort），说明 POSIX/Windows 差异
- Examples: 新增 example_copytree_preserve（展示 PreserveTimes/Perms 行为）

### Changed
- Windows: 微调 windows.inc，注释未使用常量、初始化受管 WideString，降低提示噪声（无语义变化）
- Highlevel: 移除多余的 SetLength(Result,0) 与不必要的受管数组初始化；保持 TEncoding 的显式编解码（无语义变化）

### Tests
- 维持现有用例并注释澄清变量用途；全量回归 101/101 通过，heaptrc 0
- Build: 清理 4104/4105 字符串隐式转换（highlevel：ReadString/WriteString/WriteTextFileAtomic 显式转换；无语义变化）


- Build: 清理 InternalWalkEx 冗余默认分支（Unreachable 消除）、SortStable 受管数组显式初始化（无语义变化）

- Build: 测试提示收敛（walk 预/后过滤与 OnError 计数回调的未用参数静默）；Windows 层 fs_stat/fs_lstat 出参初始化；均为无语义变化

- Tests: walk 用例第三轮提示收敛：OnErrSkipSubtree 静默参数；Windows 分支静默 LSym/LRes/LOpts 并安全初始化（无语义变化）
