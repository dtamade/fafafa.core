# fafafa.core.sync.sem 修复与统一（2025-09-05)

## 变更摘要
- Windows 与 Unix 实现风格统一：`LockGuard` 统一委派到 `AcquireGuard`（返回 `ISemGuard`）。
- Windows 增强异常安全：`Acquire(ACount)` 出错时回滚已获取许可。
- Windows 统一错误码：设置 `FLastError`（weNone/weTimeout/weResourceExhausted/weSystemError）。
- 移除 Windows 冗余的 `Data` 字段与 `GetData/SetData` 覆盖，复用基类 `TSynchronizable.Data`。
- 文档修正：`ISem` 继承 `ITryLock`；示例移除“内联变量”写法，改为标准 `var` 声明。

## 受影响文件
- src/fafafa.core.sync.sem.windows.pas
- docs/fafafa.core.sync.sem.md

## 细节说明
1) LockGuard 统一
- 之前 Windows 返回 `MakeLockGuardFromAcquired(Self as ILock)`；现改为 `Result := AcquireGuard;`，与 Unix 行为一致。

2) 强异常安全
- `Acquire(ACount)` 在发生系统错误（极少见）时，对已获取的 `acquired` 许可执行安全回滚（`ReleaseSemaphore + 本地计数同步`）。

3) LastError 统一
- 成功路径：`weNone`
- 超时返回 False：`weTimeout`
- 请求超过 Max 或资源不足：`weResourceExhausted`
- 系统错误（WAIT_FAILED 等）：`weSystemError` 并抛出 `ELockError`

4) 文档修正
- 接口继承关系与代码一致；示例去除不被项目允许的内联变量写法。

## 验证
- 尝试执行 tests/fafafa.core.sync.sem/build_only.bat，但本机未检测到 `lazbuild`（PATH 未配置），无法自动构建。
- 建议在已配置 Lazarus 的环境下运行：
  - build: tests/fafafa.core.sync.sem/build_only.bat
  - run:   tests/fafafa.core.sync.sem/run_tests.bat

## 后续建议
- 添加针对 LastError 的断言用例（需公开/访问 LastError 的接口，或在 ISem/ITryLock 暴露只读访问器）。
- 将 Unix `GetLastError` 的公开方式与接口统一（若计划对外暴露）。
- 在 CI 环境配置 `lazbuild`，自动运行单元测试以持续验证跨平台一致性。

