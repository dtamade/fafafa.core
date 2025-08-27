# fafafa.core.fs 开发计划日志（2025-08-14）

## 当日进展
- [x] 跑通 tests/fafafa.core.fs/BuildOrTest.bat：78/78 用例通过，0 错误/失败，heaptrc 0 泄漏。
- [x] 核实并修正文档：FS_UNIFIED_ERRORS 默认状态（工程为默认启用）。
- [x] 盘点接口与测试一致性：路径、IFsFile、Walk、统一错误码模型。
- [x] 新增 ResolvePathEx 与用例；新增 Win 长路径/符号链接 条件化用例；新增 symlink 深链/自环/小环/父环 稳健性用例（Tests-first）。

- [x] WalkDir FOLLOW_LINKS 防环（内部实现，不改 API/默认）：
  - [x] InternalWalkEx 增加 visited 集合，递归前判重（Dev+Ino / realpath 退化）
  - [x] 仅在 FollowSymlinks=True 启用，默认零开销
  - [x] 全量回归 82/82 通过，heaptrc 0 泄漏

## 下一步可执行计划（本周内）
1) 路径增强 API（不破坏现有 ResolvePath 语义）
   - [ ] 设计并实现 ResolvePathEx(const Path: string; FollowLinks: Boolean; TouchDisk: Boolean = False): string
   - [ ] 测试：存在/不存在/符号链接，Win/Unix 大小写差异
   - [ ] 示例：examples/fafafa.core.fs/example_fs_path_ex.lpr

2) Windows 长路径支持验证（条件化）
   - [ ] 在 tests/fafafa.core.fs 增加基于宏/环境检测的长路径测试
   - [ ] 文档说明启用方式与限制

3) Walk/Scandir 微基准与回归阈值
   - [ ] 完善 tests/fafafa.core.fs/BuildOrRunPerf.* 与 ArchivePerfResult.*
   - [ ] baseline.txt 自动对比，输出回归提示

4) 异步简化通道（等待线程池稳定）
   - [ ] tests/fafafa.core.fs.async：添加最小 Read/Write/Exists/FileSize 用例

## 决策与约束
- 错误码：维持 FS_UNIFIED_ERRORS 默认启用；对外建议基于 FsErrorKind 分类。
- 兼容性：ResolvePath 保持“不触盘”行为；真实路径解析放入 ResolvePathEx（可选 TouchDisk）。

## 风险
- Windows 长路径依赖系统策略；测试需条件化。
- 符号链接行为差异（尤其 Windows）需要在 CI 环境中做条件跳过。



## 2025-08-18 计划更新（最佳实践落地）
- [x] 新增 Canonicalize（触盘真实路径，FollowLinks 可选），与 Rust canonicalize 对齐
- [x] 新增 WriteFileAtomic/WriteTextFileAtomic（写临时 + fs_replace 原子覆盖）
- [x] 全量回归 93/93 通过，heaptrc 0 泄漏

### 下一步（按优先级）
1) 文档与示例
   - [ ] docs/fafafa.core.fs.md 补充 Resolve vs ResolveEx vs Canonicalize 行为矩阵与示例
   - [ ] examples：example_canonicalize_vs_resolve、example_writefileatomic
2) 便利 API 合流
   - [ ] ReadAll/WriteAll 文档化，统一示例
   - [ ] Copy/Move Options 化外观（Overwrite/PreserveTimes/Perms/FollowLinks）
3) Walk 迭代器外观
   - [ ] 提供 Walk 返回迭代器接口；Sort/Streaming 可选，默认 Streaming=True


## 2025-08-19 计划更新（文档微调）
- [x] docs/fafafa.core.fs.md：在目录树 Copy/Move 小节新增“更多实践与示例”直链（partials + example_copytree_follow）
- [x] docs/partials/fs.best_practices.md：强化 Windows 符号链接测试提示（FAFAFA_TEST_SYMLINK=1 或管理员/开发者模式）

## 2025-08-19（晚-7）计划补记：用例补齐 + 文档微调（已完成）
- [x] tests/Test_fafafa_core_fs_copytree_move.pas：新增 Test_MoveTree_OverwriteFalse_TargetExists_Raises
- [x] docs/fafafa.core.fs.md：强调 FollowSymlinks 默认 False 并直链示例
- [x] examples/fafafa.core.fs/README.md：补充 Windows symlink 前置条件与 Preserve 平台差异提示
- [x] 回归：tests\\fafafa.core.fs\\BuildOrTest.bat test → 102/102 通过；0 错误/失败；heaptrc 0

- [ ] 可选：下一轮补充 docs 示例代码段，标注 PreserveTimes/Perms 的 best‑effort 平台差异


## 2025-08-19（晚）计划补记：Windows 实现告警清理
- [x] src/fafafa.core.fs.windows.inc：
  - [x] 注释未使用的可选常量，仅保留实际使用的标志位
  - [x] 初始化受管 WideString（LTempPath 等），降低“受管类型未初始化”提示
  - [x] 保持 FillChar 归零的初始化模式，避免改变行为
- [x] 回归：tests\\fafafa.core.fs\\BuildOrTest.bat test → 101/101 通过；0 错误/失败；heaptrc 0
- [ ] 后续（可选）：在下一轮针对 highlevel 与 tests 做一次“隐式字符串转换/未用变量”提示清理（不改语义）


## 2025-08-19（晚-2）计划补记：highlevel 与测试提示清理
- [x] src/fafafa.core.fs.highlevel.pas：
  - [x] 移除多余的 SetLength(Result,0)，保留 Result:=nil 初始化
  - [x] 稳定排序实现中移除不必要的 SetLength(SortedTypes,0)
  - [x] 维持 TFsFile.ReadString/WriteString 使用 TEncoding.GetString/GetBytes，避免隐式转换
- [x] tests/fafafa.core.fs/Test_fafafa_core_fs_symlink.pas：增加用途注释，澄清变量用途
- [x] 回归：tests\\fafafa.core.fs\\BuildOrTest.bat test → 101/101 通过；0 错误/失败；heaptrc 0

## 2025-08-19（晚-3）计划补记：字符串隐式转换告警清理
- [x] src/fafafa.core.fs.highlevel.pas：
  - [x] TFsFile.ReadString 显式 Result := string(aEncoding.GetString(...))
  - [x] TFsFile.WriteString/WriteTextFileAtomic 使用 aEncoding.GetBytes(UnicodeString(...))
- [x] 回归：tests\\fafafa.core.fs\\BuildOrTest.bat test → 101/101 通过；heaptrc 0



## 2025-08-19（晚-4）计划补记：Unreachable 清理 + 细节降噪
- [x] src/fafafa.core.fs.highlevel.pas：InternalWalkEx 去除冗余默认分支（Unreachable 消除）
- [x] src/fafafa.core.fs.highlevel.pas：SortStable 中 SortedTypes := nil 显式初始化
- [x] 回归：tests\\fafafa.core.fs\\BuildOrTest.bat test → 101/101 通过；heaptrc 0


## 2025-08-19（晚-5）计划补记：测试提示收敛 + Windows 出参初始化
- [x] tests/fafafa.core.fs/Test_fafafa_core_fs_walk.pas：预/后过滤与 OnError 计数回调静默未用参数
- [x] src/fafafa.core.fs.windows.inc：fs_stat/fs_lstat 在进入处 FillChar(aStat,0)
- [x] 回归：tests\\fafafa.core.fs\\BuildOrTest.bat test → 101/101 通过；heaptrc 0


## 2025-08-19（晚-6）计划补记：测试提示收敛（第三轮）
- [x] tests/fafafa.core.fs/Test_fafafa_core_fs_walk.pas：
  - [x] OnErrSkipSubtree 静默 aError/aDepth
  - [x] 符号链接相关用例在函数开头安全初始化 LSym/LRes/LOpts，且 Windows 分支静默这些局部
- [x] 回归：tests\\fafafa.core.fs\\BuildOrTest.bat test → 101/101 通过；heaptrc 0


## 2025-08-22 计划补记（文档与示例）
- [x] docs/fafafa.core.fs.md：补充 Resolve/ResolveEx/Canonicalize 行为矩阵后的示例片段与一键脚本位置
- [x] examples：example_canonicalize_vs_resolve（已存在，校验通过）
- [x] 回归：scripts/test-fs-only.bat → 110/110 通过；0 错误/失败；heaptrc 0

### 下一步（建议）
1) examples/README.md 增加示例索引条目
2) 最小警告清理（不改语义）：
   - 注释层级（Comment level 2）
   - 受管结果初始化（FillChar 出参/Result 显式初始化）
3) 基准守护输出增强：对 baseline 友好比对


## 2025-08-24 更新

- [x] 回归：tests/fafafa.core.fs/BuildOrTest.bat test → 130/130 通过；0 错误/失败；heaptrc 0
- [x] 文档：补充 Resolve/ResolvePathEx/Canonicalize 行为矩阵；新增 Darwin/macOS 注记
- [ ] 用例补齐计划：mkdtemp/mkstemp/realpath（小缓冲）/flock（非阻塞竞争）/fchmod（Windows：OK 或 Unsupported）
- [ ] IFsFile 迁移计划：文档澄清门面策略与别名建议
- [ ] 可选：最小告警清理（显式初始化/注释层级），不改语义
- [ ] 基准守护：Resolve/Walk 输出对齐 report/latest，阈值 25%

— 负责人：Augment Agent（2025-08-24）


## 2025-08-25 更新

- [x] 回归：tests/fafafa.core.fs/BuildOrTest.bat test → 137/137 通过；0 错误/失败；heaptrc 0
- [x] ValidatePath（Windows）长路径长度判定与 FAFAFA_CORE_FS_ENABLE_WIN_LONGPATH 宏对齐
  - 启用宏：~32767 宽字符（保守检查）；未启用：MAX_PATH=260
- [x] 文档同步：docs/fafafa.core.fs.md 增补“ValidatePath 的长路径长度判定”说明

### 下一步（可选）
1) 条件化测试：根据 FAFAFA_TEST_WIN_LONGPATH 增加 ValidatePath 超长路径正反用例（默认跳过）
2) 观察期：收集反馈，决定是否需要在更多高层入口展示长路径提示

