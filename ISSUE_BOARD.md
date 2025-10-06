# 🐛 fafafa.core.time - 问题跟踪看板

> **最后更新：** 2025-10-05  
> **总问题数：** 48 个（9 个已关闭）  
> **预计工作量：** 49 天

---

## 📊 快速统计

### 按优先级
- 🔴 **P0 (Critical)**: 0 个 - ✅ 全部完成！
- 🟠 **P1 (High)**: 24 个 - 尽快完成
- 🟡 **P2 (Medium)**: 10 个 - 逐步改进
- 🟢 **P3 (Low)**: 6 个 - 可选增强

### 按类别
- 🐛 Bug: 21 个
- 📝 Documentation: 10 个
- ⚡ Performance: 6 个
- 🎨 Design: 6 个
- 🔒 Security: 3 个
- ✨ Enhancement: 1 个
- 🧪 Testing: 1 个

### 按状态
- ⏳ Open: 39 个
- ✅ Closed: 9 个

---

## 🔥 P0 - 必须立即修复（本周内）

✅ **所有 P0 Critical 问题已修复！**

### ~~ISSUE-6~~ ✅ Closed - Sub 使用双重取反
**模块:** Instant | **文件:** `instant.pas:153-159` | **已完成：** 2025-10-05

~~**问题：** `TInstant.Sub()` 使用 `-D.AsNs` 导致 `Low(Int64)` 溢出产生完全错误的结果~~

~~**影响：** 💥 数据损坏 - 产生完全错误的结果~~

**✅ 已修复：** 
- 避免双重取反操作，直接根据 `D` 的符号执行加法或减法
- 显式检测并处理 `Low(Int64)` 边界情况，饱和到 `High(UInt64)`
- 新增 9 个专门的边界测试用例
- 所有 130 个测试通过，无内存泄漏

**详细报告：** `docs/reports/ISSUE-6-fix-report.md`

---

## 🟠 P1 - 高优先级（2-3 周内完成）

### 核心类型系统（1 个）

#### ~~ISSUE-1~~ ✅ Closed - 除零返回 High/Low(Int64)
**模块:** Duration | **文件:** `duration.pas:402-412` | **已完成：** 2025-10-05

~~div 运算符在除数为 0 时返回 High/Low(Int64) 而不是抛出异常，可能隐藏 bug~~

**✅ 已修复：** `div` 和 `Divi` 除零时抛出 `EDivByZero` 异常，保留 `CheckedDivBy` 和 `SaturatingDiv` 用于特殊场景

**详细报告：** `docs/reports/ISSUE-1-2-fix-report.md`

---

#### ~~ISSUE-2~~ ✅ Closed - 模零返回 0
**模块:** Duration | **文件:** `duration.pas:439-442` | **已完成：** 2025-10-05

~~Modulo 函数在除数为 0 时返回 0，数学上未定义~~

**✅ 已修复：** `Modulo` 除零时抛出 `EDivByZero` 异常，保留 `CheckedModulo` 用于特殊场景

**详细报告：** `docs/reports/ISSUE-1-2-fix-report.md`

---

#### ISSUE-3 🟠 High - 舍入函数未处理 Low(Int64)
**模块:** Duration | **文件:** `duration.pas:333-363` | **预计:** 1 天

`FloorToUs`/`CeilToUs`/`RoundToUs` 在处理 `Low(Int64)` 时 `absNs := -FNs` 可能溢出

**建议：** 添加边界检查：
```pascal
if FNs = Low(Int64) then
  Exit(TDuration.FromNs(Low(Int64) div 1000 * 1000));
```

---

### 时钟系统（9 个）

#### ISSUE-13 🟠 High - 时钟语义混淆
**模块:** Clock | **文件:** `clock.pas:63-67` | **预计:** 3 天

`IMonotonicClock` 返回 `TInstant` 但语义不同（单调时钟 vs Unix epoch）

**影响：** 用户可能混淆使用，将单调时间当作绝对时间

**建议：** 
- **选项 A：** 类型分离（`TMonotonicInstant` vs `TSystemInstant`）
- **选项 B：** 强化文档警告

---

#### ISSUE-14 🟠 High - Windows QPC 溢出
**模块:** Clock | **文件:** `clock.pas:470-478` | **预计:** 1 天

`(UInt64(li) * 1000000000)` 在 58 年后可能溢出

**建议：** 先除后乘或使用 128 位中间结果

---

#### ISSUE-16 🟠 High - macOS 溢出
**模块:** Clock | **文件:** `clock.pas:494-501` | **预计:** 1 天

`(t * FTBNumer)` 在 175 天后可能溢出

**建议：** 添加溢出检查并饱和

---

#### ISSUE-17 🟠 High - WaitFor 自旋 CPU 高
**模块:** Clock | **文件:** `clock.pas:552-593` | **预计:** 2 天

最后 50us 持续 `SchedYield` 导致 CPU 100%

**建议：** 添加最小睡眠时间（1us）

---

#### ISSUE-19 🟠 High - NowUTC 依赖 RTL
**模块:** Clock | **文件:** `clock.pas:642-645` | **预计:** 1 天

`LocalTimeToUniversal` 在 DST 边界不准确

**建议：** Windows 使用 `GetSystemTime`，Unix 使用 `gettimeofday`

---

#### ISSUE-20 🟠 High - NowUnixMs 精度损失
**模块:** Clock | **文件:** `clock.pas:652-658` | **预计:** 1 天

`TDateTime` 精度不足（~1.3ms）

**建议：** 直接使用原生 API

---

#### ISSUE-21 🟠 High - TFixedClock 数据竞争
**模块:** Clock | **文件:** `clock.pas:482-501` | **预计:** 2 天

`FFixedInstant` 和 `FFixedDateTime` 分开更新，并发读取不一致

**建议：** 使用记录结构原子更新

---

#### ISSUE-22 🟠 High - TTimerEntry 裸指针
**模块:** Timer | **文件:** `timer.pas:97-114` | **预计:** 3 天

使用 record 指针手动引用计数容易泄漏

**建议：** 改为 class 或智能指针

---

#### ISSUE-23 🟠 High - 全局变量线程安全
**模块:** Timer | **文件:** `timer.pas:92-93` | **预计:** 1 天

`GTimerExceptionHandler` 无锁保护，读写竞争

**建议：** 添加 `TRTLCriticalSection` 保护

---

#### ISSUE-24 🟠 High - FixedRate 追赶风暴
**模块:** Timer | **文件:** `timer.pas:62` | **预计:** 0.5 天

默认无限制追赶，回调慢时可能连续执行大量次

**建议：** 默认值改为 3

---

### 格式化与解析（6 个）

#### ~~ISSUE-29~~ ✅ Closed - TDateTime 精度问题
**模块:** Format | **文件:** `format.pas:116-118` | **已完成：** 2025-10-05

~~Double 精度约 1ms，`ShowMilliseconds` 选项可能不准确~~

**✅ 已修复：** 添加详细 XML 文档说明 Double 精度限制，并提供 TInstant 等替代方案

---

#### ~~ISSUE-30~~ ✅ Closed - Locale 格式未标准化
**模块:** Format | **文件:** `format.pas:79` | **已完成：** 2025-10-05

~~Locale 字符串格式不明确~~

**✅ 已修复：** 文档化 BCP 47 标准格式，提供常用示例（en-US, zh-CN, ja-JP）

---

#### ~~ISSUE-31~~ ✅ Closed - CustomPattern 未文档化
**模块:** Format | **文件:** `format.pas:80` | **已完成：** 2025-10-05

~~用户不知道支持哪些模式标记~~

**✅ 已修复：** 添加完整的模式标记参考文档，包括日期/时间格式和示例

---

#### ~~ISSUE-36~~ ✅ Closed - 解析模式未定义
**模块:** Parse | **文件:** `parse.pas:59-63` | **已完成：** 2025-10-05

~~`pmStrict`/`pmLenient`/`pmSmart` 行为未定义~~

**✅ 已修复：** 详细文档化三种模式的特点、适用场景和示例，包括性能/准确性对比

**详细报告：** `docs/reports/ISSUE-29-30-31-36-doc-fix-report.md`

---

#### ISSUE-37 🟠 High - 时区处理冲突
**模块:** Parse | **文件:** `parse.pas:66-78` | **预计:** 2 天

`DefaultTimeZone` 和 `AssumeUTC` 可能冲突

**建议：** 重新设计为枚举选择

---

#### ISSUE-38 🟠 High - 错误消息国际化
**模块:** Parse | **文件:** `parse.pas:81-89` | **预计:** 2 天

错误消息语言未定义，无错误代码

**建议：** 添加 `TParseErrorCode` 枚举

---

#### ISSUE-40 🟠 High - 正则注入风险
**模块:** Parse | **文件:** `parse.pas:249` | **预计:** 1 天

用户提供格式可能包含恶意正则（回溯炸弹）

**影响：** 🔒 DoS - CPU 100% 挂起

**建议：** 白名单验证或超时机制

---

#### ~~ISSUE-41~~ ✅ Closed - ISO 周日期边界
**模块:** ISO8601 | **文件:** `iso8601.pas:149-154` | **已完成：** 2025-10-04

~~周日期边界情况（12/29-31 和 1/1-3）可能计算错误~~

**✅ 已修复：** 实现完全符合 ISO 8601-1:2019 标准的算法，添加了 27 个边界测试用例，所有测试通过

**详细报告：** 见 `docs/reports/ISSUE-41-fix-report.md`

---

#### ISSUE-42 🟠 High - 月份/年份转换
**模块:** ISO8601 | **文件:** `iso8601.pas:100-112` | **预计:** 1 天

ISO Duration 月份/年份无法精确转换为固定时长

**建议：** 文档说明限制或拒绝转换

---

#### ISSUE-44 🟠 High - DST 时区偏移
**模块:** ISO8601 | **文件:** `iso8601.pas:268-270` | **预计:** 1 天

`GetLocalTimeZoneOffset` 不接受时间参数，DST 期间不准确

**建议：** 接受时间参数判断是否使用 DST

---

### 增强功能（1 个）

#### ISSUE-25 🟠 High - Scheduler 无实现
**模块:** Scheduler | **文件:** `scheduler.pas:All` | **预计:** 10 天

只有接口定义没有实现

**建议：** 实现完整的 Scheduler 功能

---

### 其他（1 个）

#### ISSUE-28 🟠 High - 异常静默吞掉
**模块:** Timer | **文件:** `timer.pas:Multiple` | **预计:** 1 天

未设置异常处理器时异常被静默吞掉

**建议：** 提供默认处理器输出到 stderr

---

## 🟡 P2 - 中优先级（3-4 周内）

### 文档改进（4 个）

- **ISSUE-4**: FromSecF 精度损失未文档化 (0.5 天)
- **ISSUE-5**: Diff 饱和行为未文档化 (0.5 天)
- **ISSUE-10**: 缺少 XML 文档 (5 天) ⚠️ **大任务**
- **ISSUE-34**: 相对时间基准不明 (0.5 天)

### 性能优化（5 个）

- **ISSUE-7**: 比较运算符冗余实现 (1 天)
- **ISSUE-18**: 取消令牌检查频率 (1 天)
- **ISSUE-26**: 数组返回性能 (1 天)
- **ISSUE-35**: 本地化查找性能 (2 天)
- **ISSUE-39**: 正则缓存泄漏 (2 天)

### 设计改进（4 个）

- **ISSUE-9**: 缺少比较运算符 (0.5 天)
- **ISSUE-11**: 命名约定不一致 (1 天)
- **ISSUE-27**: 定时器时钟语义 (2 天)
- **ISSUE-32**: dfHuman 格式不一致 (0.5 天)
- **ISSUE-33**: 默认参数不一致 (0.5 天)

### 测试（1 个）

- **ISSUE-45**: 往返一致性 (2 天)

### 增强功能（1 个）

- **ISSUE-46**: 跨 locale 解析 (1 天)

---

## 🟢 P3 - 低优先级（持续改进）

### 代码质量（1 个）

- **ISSUE-8**: Overdue 重复逻辑 (0.5 天)

### 性能优化（1 个）

- **ISSUE-12**: 缺少 inline 关键字 (1 天)

### 安全性（2 个）

- **ISSUE-47**: 输入长度限制 (0.5 天)
- **ISSUE-48**: 格式字符串注入 (1 天)

### 增强功能（1 个）

- **ISSUE-43**: 小数秒精度 (2 天)

---

## ✅ 已关闭问题

### ISSUE-15 ✅ Closed - POSIX 溢出（理论）
**模块:** Clock | **文件:** `clock.pas:505-513` | **关闭日期:** 早期

`MonoNowNs` 溢出需要 584 年，实际不可能发生

**决定：** 可接受的理论风险，无需修复

---

### ISSUE-1 & ISSUE-2 ✅ Closed - TDuration 除零和模零处理
**模块:** Duration | **文件:** `duration.pas` | **关闭日期:** 2025-10-05

`div`、`Divi` 和 `Modulo` 除零时返回错误值而不是抛出异常

**修复方案：** 
- `div` 和 `Divi` 除零时抛出 `EDivByZero` 异常
- `Modulo` 除零时抛出 `EDivByZero` 异常
- 保留 `CheckedDivBy`、`CheckedModulo` 和 `SaturatingDiv` 用于特殊场景
- 新增 13 个专门的边界测试用例
- 所有 143 个测试通过，无内存泄漏

**影响：** 破坏性变更（符合 Pascal 标准行为），中等影响

**详细报告：** `docs/reports/ISSUE-1-2-fix-report.md`

---

### ISSUE-6 ✅ Closed - TInstant.Sub 双重取反溢出
**模块:** Instant | **文件:** `instant.pas:153-159` | **关闭日期:** 2025-10-05

`TInstant.Sub()` 使用 `-D.AsNs` 导致 `Low(Int64)` 溢出，产生完全错误的结果

**修复方案：** 
- 避免双重取反操作，直接根据 `D` 的符号处理
- 显式检测 `Low(Int64)` 边界情况并饱和到 `High(UInt64)`
- 零值快速返回优化
- 新增 9 个专门的边界测试用例
- 所有 130 个测试通过，无内存泄漏

**影响：** 破坏性变更（但修复了错误行为），影响极小

**详细报告：** `docs/reports/ISSUE-6-fix-report.md`

---

### ISSUE-41 ✅ Closed - ISO 周日期边界问题
**模块:** ISO8601 | **文件:** `iso8601.pas` | **关闭日期:** 2025-10-04

ISO 8601周日期格式在年份边界处（12月29-31日和1月1-3日）计算错误

**修复方案：** 
- 实现了完全符合 ISO 8601-1:2019 标准的算法
- 新增 `ISODayOfWeek`, `ISOWeekNumber`, `ISOWeekYear`, `EncodeISOWeekDate` 辅助函数
- 修复了 `ParseWeekDate` 和 `FormatWeekDate` 函数
- 添加了 27 个专门的边界测试用例
- 所有测试通过，与外部参考实现（Python）验证一致

**注意：** 这是一个破坏性变更，跨年边界日期的解析结果与旧版本不同

**详细报告：** `docs/reports/ISSUE-41-fix-report.md`

---

## 📈 进度追踪

### 里程碑 1：P0 修复 ✅ 已完成
- [x] ISSUE-6: TInstant.Sub() 修复 ✅ 2025-10-05 完成

**完成日期：** 2025-10-05

---

### 里程碑 2：P1 核心修复（进行中）
- [x] 核心类型系统（3 个问题）✅ 2025-10-05 完成 ISSUE-1, ISSUE-2
- [ ] 时钟系统关键 bug（6 个问题）
- [ ] 格式化解析基础（5 个问题）

**目标日期：** 第 3 周结束

---

### 里程碑 3：P1 完整修复（第 4-5 周）
- [ ] 剩余 P1 问题
- [ ] Scheduler 实现

**目标日期：** 第 5 周结束

---

### 里程碑 4：P2 改进（第 6-8 周）
- [ ] 文档补充
- [ ] 性能优化
- [ ] 测试覆盖

**目标日期：** 第 8 周结束

---

## 📋 使用指南

### 导入 CSV 到 Excel/Google Sheets
1. 打开 `ISSUE_TRACKER.csv`
2. 使用 Excel/Google Sheets 的"导入"功能
3. 选择逗号作为分隔符
4. 可以按 Priority/Severity/Module 等字段排序和筛选

### 创建 GitHub Issues
```bash
# 使用 gh CLI 批量创建（示例）
gh issue create --title "ISSUE-6: TInstant.Sub() 边界情况" \
  --body "$(cat ISSUE-6-description.md)" \
  --label "bug,P0,critical"
```

### 更新状态
1. 在 CSV 中修改 `Status` 列（Open/In Progress/Testing/Closed）
2. 填写 `Assignee` 列
3. 更新 `ActualDays` 列记录实际耗时

---

## 📞 联系方式

**问题反馈：**
- Email: dtamade@gmail.com
- QQ 群：685403987

**代码审查文档：**
- [核心类型审查](CODE_REVIEW_CORE_TYPES.md)
- [时钟系统审查](CODE_REVIEW_CLOCK_TIMER_SYSTEMS.md)
- [格式化解析审查](CODE_REVIEW_FORMAT_PARSE_SYSTEMS.md)
- [总结报告](CODE_REVIEW_SUMMARY_AND_ROADMAP.md)

---

*最后更新：2025-01-XX*  
*由 AI 代码审查系统生成*
