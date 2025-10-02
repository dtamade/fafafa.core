# Warp 操作指南（fafafa.core）

本文件为 Warp (warp.dev) 在本仓库工作的快速参考。默认使用简体中文沟通。内容包含：快速开始、常用命令、架构要点、Agent 操作规范与常见陷阱。

- 目录
  - 快速开始
  - 常用命令（Windows 优先，Linux/macOS 同步提供）
  - 高层架构（大图景）
  - Agent 操作要点
  - 常见陷阱与约定 / 维护

## 快速开始
- Windows（PowerShell）
  1) 运行全量测试：tests\run_all_tests.bat
  2) 本地快速“编译检查”：lazbuild -B -vewnhibq <path-to>.lpi
- Linux/macOS（bash）
  1) 运行全量测试：bash tests/run_all_tests.sh
  2) 本地快速“编译检查”：lazbuild -B -vewnhibq <path-to>.lpi

注意：
- 在 CI 或自动化环境中优先选择“无交互”参数运行，避免 ReadLn 等阻塞。
- 使用 PowerShell 时请确保当前目录为仓库根：D:\projects\Pascal\lazarus\My\libs\fafafa.core

## 常用命令（Windows 优先，Linux/macOS 同步提供）
- 全量测试（统一入口）
  - Windows:
    - tests\run_all_tests.bat
  - Linux/macOS:
    - bash tests/run_all_tests.sh
- 只跑关键模块并失败即停（提交前回归建议）
  - Windows:
    - set STOP_ON_FAIL=1 && tests\run_all_tests.bat fafafa.core.collections.arr fafafa.core.collections.base fafafa.core.collections.vec fafafa.core.collections.vecdeque
  - Linux/macOS:
    - STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.collections.arr fafafa.core.collections.base fafafa.core.collections.vec fafafa.core.collections.vecdeque
- 单模块测试
  - Windows:
    - tests\<模块目录>\BuildOrTest.bat
  - Linux/macOS:
    - bash tests/<模块目录>/BuildOrTest.sh
  - 说明：<模块目录> 为 tests/ 下的二级目录名（如 tests\fafafa.core.collections.vec）
- SIMD CPU 信息子系统（本仓库 test/ 下的独立测试程序）
  - 使用 FPC 配置直接构建并运行（无交互，适合自动化）：
    - 编译：fpc @test\fpc.cfg test\run_cpuinfo_tests.lpr
    - 运行：
      - test\run_cpuinfo_tests.exe --quick
      - test\run_cpuinfo_tests.exe --category performance
      - test\run_cpuinfo_tests.exe --report test\cpuinfo_test_report.txt
      - test\run_cpuinfo_tests.exe --verbose
  - 或使用 Lazarus 工程构建演示程序（注意部分程序运行末尾 ReadLn 需要交互）：
    - lazbuild -B -vewnhibq test\test_cpuinfo.lpi
    - test\test_cpuinfo.exe
- 清理构建产物
  - Windows: .\clean.bat
  - Linux/macOS: ./clean.sh
- 编译检查（零 warning/hint 要求，见 docs/CI.md）
  - 示例：lazbuild -B -vewnhibq <path-to>.lpi（本地快速“lint”）

可选（使用自研 Runner 的模块）：统一报告路径与 CI 友好参数（见 docs/CI.md）
- Windows PowerShell:
  - $env:FAFAFA_TEST_JUNIT_FILE = "out\junit.xml"; $env:FAFAFA_TEST_JSON_FILE = "out\report.json"
  - tests\fafafa.core.test\bin\tests.exe --ci --fail-on-skip --top-slowest=5
- Linux/macOS:
  - FAFAFA_TEST_JUNIT_FILE=out/junit.xml FAFAFA_TEST_JSON_FILE=out/report.json ./tests/fafafa.core.test/bin/tests.exe --ci --fail-on-skip --top-slowest=5

## 高层架构（大图景）
- 单源编译设置（关键约束）
  - 各 Pascal 单元在文件顶部显式声明所需编译模式（如 {$mode objfpc}{$H+}），并在 unit 之后、interface 之前包含：{$I fafafa.core.settings.inc}
  - settings.inc 仅承载宏与平台/特性开关，不声明 {$mode ...}；如需调整模式，请在各单元修改
  - 适用范围：src/、tests/、examples/、benchmarks/ 全部单元
- 模块化命名与目录
  - 核心单元在 src/，采用小写点分命名：fafafa.core.<module>[.<submodule>]
  - 按平台拆分实现通过 .inc 文件注入（如 src\fafafa.core.fs.windows.inc / .unix.inc、os/windows/unix.inc、socket/windows/linux.inc 等）
  - tests/：按模块分目录，提供 BuildOrTest.{bat,sh} 与 LPI/LPR 进行构建与运行；仓库根提供 tests/run_all_tests.{bat,sh} 统一编排
  - examples/：最小可运行示例与演示；benchmarks/：性能与对比基准；docs/：设计、API、测试与 CI 规范
- SIMD CPU 信息子系统（与本仓库 test/ 目录联动）
  - 门面与类型：fafafa.core.simd.cpuinfo（总入口）、fafafa.core.simd.cpuinfo.base、fafafa.core.simd.types
  - 平台/架构实现：fafafa.core.simd.cpuinfo.x86（及其子单元）、.arm、.riscv；延迟检测与诊断：.lazy、.diagnostic
  - 测试组织：test\test_cpuinfo_suite.pas 提供分类（basic、performance、integration 等），test\run_cpuinfo_tests.lpr 暴露 --category / --report / --quick / --verbose 等命令行
- 测试执行约定（统一脚本）
  - run_all_tests.{bat,sh} 递归发现各模块 BuildOrTest 脚本并执行；支持按参数过滤模块名；支持 STOP_ON_FAIL 环境变量
  - 输出与汇总位置、返回码语义详见 docs/TESTING.md

## Agent 操作要点
- 严格遵守“单源设置 include”规则：在 unit 声明后、interface 前包含 {$I fafafa.core.settings.inc}
- 新增或修改公共 API 时，优先添加/更新对应 tests/ 子模块用例；必要时在 examples/ 增加最小复现示例
- 不要重命名已发布的公共单元（fafafa.core.*）；避免引入与现有命名不一致的新前缀

## 常见陷阱与约定
- 路径分隔符：Windows 示例使用 \\，bash 示例使用 /；不要混用同一命令行示例中的分隔符。
- 避免交互：在 CI/自动化环境中，避免运行需要 ReadLn/交互的程序；若必须，使用支持的无交互参数（如 --quick/--ci 等）。
- Git/长输出：若需要查看 VCS 历史，使用 --no-pager 或等效方式避免分页。
- 输出规范：不要通过 echo 输出大段信息给用户阅读；由 Agent 在终端正常输出文本。
- 失败即停：支持 STOP_ON_FAIL 环境变量的测试脚本会在首个失败处返回非零码，便于快速回归。

## 维护
- 若新增模块，请同步补充 tests/<module>/BuildOrTest.{bat,sh} 与 run_all_tests 编排支持。
- 更新公共 API 或测试约定时，请同步更新本文档并在 PR 中说明。

---

# 通用开发规范（适用于所有 fafafa.* 项目）

本节整合了 fafafa.ssl 及其他子项目的通用开发规范，适用于整个 fafafa 生态系统。

## 1. 专业态度与协作原则

### 1.1 专业主见
- **不要过于顺从，要有自己的专业主见**
- 当发现技术方案存在问题时，应主动提出更好的替代方案
- 基于最佳实践和专业经验，勇于质疑不合理的需求
- 在代码质量、架构设计、性能优化等方面保持专业判断
- 优先考虑代码的可维护性、可扩展性和稳定性

### 1.2 明确目标导向

**✅ 好的做法**:
- "测试 collections 模块的核心功能，优先级从高到低"
- "找出性能瓶颈的根本原因"
- "创建完整的测试文档体系"

**❌ 避免**:
- "测试一些东西"
- "看看有什么问题"
- "随便做点什么"

## 2. 代码风格规范

### 2.1 编码设置
- **Windows平台UTF-8支持**：如果程序需要输出中文或Unicode符号，必须添加：
  ```pascal
  {$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}
  ```
  - 原因：Windows下不设置UTF-8代码页会导致输出Unicode字符时出现"Disk Full"等错误
  - 位置：放在程序或单元的编译指令部分（通常在 `{$MODE}` 指令后）
  - 示例：
    ```pascal
    program MyProgram;
    {$MODE ObjFPC}{$H+}
    {$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}
    ```

### 2.2 变量命名规则
- **局部变量**：必须以 `L` 开头
  - 示例：`LCount`, `LIndex`, `LResult`, `LTempString`
  
- **参数命名**：必须以 `a` 开头
  - 示例：`aCount`, `aFileName`, `aOptions`, `aCallback`

### 2.3 其他命名约定
- **类名**：以 `T` 开头，如 `THttpClient`, `TVec`
- **接口名**：以 `I` 开头，如 `IHttpRequest`, `IAllocator`
- **常量名**：全大写，单词间用下划线分隔，如 `MAX_CONNECTIONS`, `DEFAULT_CAPACITY`
- **私有字段**：以 `F` 开头，如 `FConnection`, `FData`
- **属性名**：Pascal 命名法，如 `ConnectionTimeout`, `Capacity`

## 3. 项目配置规范

### 3.1 二进制文件输出
- 二进制文件输出目录：`bin/`
  - 命名格式：`模块名.类型.架构.系统.扩展名`
  - 类型包括：`test`（测试）、`example`（示例）
  - 示例：
    - Windows: `fafafa.core.test.x86_64.windows.exe`
    - Linux: `fafafa.core.test.x86_64.linux`
    - macOS: `fafafa.core.test.x86_64.darwin`

### 3.2 中间文件输出
- 中间文件（.o, .ppu 等）输出目录：`lib/$(TargetCPU)-$(TargetOS)/`
- 项目文件配置示例：
  ```xml
  <Target>
    <Filename Value="bin/模块名.类型.$(TargetCPU).$(TargetOS)"/>
  </Target>
  <SearchPaths>
    <UnitOutputDirectory Value="lib/$(TargetCPU)-$(TargetOS)"/>
  </SearchPaths>
  ```

### 3.3 目录结构规范
```
项目根目录/
├── bin/                    # 二进制输出目录（所有平台二进制放在同一目录）
│   ├── 模块名.test.x86_64.windows.exe
│   ├── 模块名.example.x86_64.windows.exe
│   └── ...
├── lib/                    # 中间文件目录
│   └── x86_64-win64/      # 平台特定目录
├── src/                    # 源代码目录
│   ├── fafafa.core.模块名.pas # 扁平源码目录
│   └── ...
├── tests/                  # 单元测试目录
│   ├── 单元文件名/
│   │   ├── bin/
│   │   ├── lib/s
│   │   ├── test_单元名.pas
│   │   └── test_单元名.lpi
│   └── ...
├── examples/               # 示例代码目录
│   ├── 单元文件名/
│   │   ├── bin/
│   │   ├── lib/
│   │   ├── example_基本用法.pas
│   │   ├── example_高级功能.pas
│   │   └── example_项目.lpi
│   └── ...
├── docs/                   # 文档目录
├── README.md              # 项目说明文件
└── WARP.md               # 本规则文件
```

## 4. 测试与示例规范

### 4.1 单元测试规则
- **必须** 为每个模块单元编写单元测试
- 单元测试存放位置：`tests/单元文件名/` 目录下
- 测试文件命名规范：`test_单元名.pas`
- 确保所有测试用例覆盖主要功能和边界情况

### 4.2 示例代码规则
- **必须** 为每个模块单元编写使用示例
- 示例代码存放位置：`examples/单元文件名/` 目录下
- 示例文件应包含完整的使用场景说明
- 示例代码必须可独立运行

## 5. 代码质量要求
- 所有公共方法必须有注释说明
- 复杂逻辑必须添加解释性注释
- 使用有意义的变量和函数名
- 避免过长的函数（建议不超过 50 行）
- 每个单元文件应只包含一个主要功能

## 6. 代码改动规范

### 6.1 重大架构改变申请审批
- **重大架构改变必须先申请审批**
  - 包括但不限于：改变核心数据结构、引入新的依赖、改变API接口
  - 必须先说明改动理由、影响范围、性能对比
  - 未经批准不得擅自进行重大重构

### 6.2 优先选择简单方案
- 避免过度设计和过早优化
- 优先使用标准库和简单数据结构
- 只有在明确的性能瓶颈时才引入复杂优化

## 7. 模块化设计最佳实践

### 7.1 大文件拆分策略
- **将大型单一文件拆分为多个功能专注的子模块**
  - 每个模块应聚焦于单一职责
  - 模块之间通过清晰的接口进行交互
  - 避免单个文件超过 1000 行代码

### 7.2 模块组织原则
- **按功能域进行划分**
  - 示例 (collections)：
    - `fafafa.core.collections.base` - 基础类型定义
    - `fafafa.core.collections.arr` - 数组类型
    - `fafafa.core.collections.vec` - 动态数组
    - `fafafa.core.collections.vecdeque` - 双端队列
  - 示例 (SSL，来自 fafafa.ssl)：
    - `fafafa.ssl.openssl.types` - 类型定义
    - `fafafa.ssl.openssl.consts` - 常量定义
    - `fafafa.ssl.openssl.core` - 核心功能

### 7.3 模块化的优势
- **提高代码可维护性**
  - 易于定位和修改特定功能
  - 降低代码耦合度
  - 便于团队协作开发
  
- **增强代码可读性**
  - 每个模块功能明确
  - 减少认知负担
  - 便于新开发者理解项目结构
  
- **改善编译性能**
  - 修改单个模块时只需重编译相关部分
  - 减少全量编译时间
  - 支持并行编译

### 7.4 模块依赖管理
- **建立清晰的依赖层次**
  - 基础类型和常量模块不依赖其他模块
  - 核心模块只依赖基础模块
  - 高级功能模块可依赖核心和基础模块
  - 避免循环依赖

### 7.5 接口设计原则
- **最小化公开接口**
  - 只暴露必要的类型和函数
  - 使用 `interface` 部分定义公共 API
  - 内部实现细节保留在 `implementation` 部分
  
- **保持接口稳定性**
  - 一旦发布，避免破坏性变更
  - 使用版本化策略管理 API 演进
  - 提供向后兼容的迁移路径

## 8. 渐进式开发最佳实践

### 8.1 分批完成策略
- **将大型任务分解为多个小批次**
  - 每批完成 3-5 个相关模块
  - 每批次后进行总结和反馈
  - 避免一次性实现所有功能导致上下文溢出

### 8.2 进度追踪方法
- **完成部分总结**
  - 明确列出已完成的模块及其功能
  - 标注每个模块的完成度（骨架/基本/完整）
  - 记录关键功能亮点
  
- **待办事项管理**
  - 清晰列出剩余待实现的模块
  - 按优先级和依赖关系排序
  - 提供继续的明确方向

### 8.3 上下文保持技巧
- **使用"继续"关键词**
  - 用户简单说"继续"即可延续之前的开发
  - AI 会根据之前的总结继续实现下一批模块
  - 避免重复说明需求，节省交流成本
  
- **阶段性总结模板**
  ```markdown
  ## 已完成的模块
  1. 模块A - 功能描述
  2. 模块B - 功能描述
  ...
  
  ## 功能亮点
  - 亮点1
  - 亮点2
  ...
  
  ## 待实现的模块
  - 模块X
  - 模块Y
  ...
  
  您想让我继续创建哪些模块呢？
  ```

## 9. Warp AI 协作最佳实践

### 9.1 分阶段推进工作流程
1. **规划** → 确定优先级和范围
2. **执行** → 系统性完成任务
3. **分析** → 深入理解问题
4. **文档** → 记录发现和解决方案
5. **总结** → 提炼关键洞察

### 9.2 有效的协作模式

#### 测试驱动开发
**模式**: 测试 → 分析 → 文档 → 规划

**示例**:
1. "运行测试并分析结果"
2. "深入调查失败的测试"
3. "记录问题的根本原因"
4. "制定解决方案路线图"

#### 问题驱动调查
**模式**: 发现 → 重现 → 诊断 → 解决 → 预防

#### 文档驱动协作
**模式**: 工作 → 记录 → 分享 → 改进

**关键文档类型**:
- **README**: 导航和快速入门
- **SUMMARY**: 高层次概览
- **ANALYSIS**: 深度技术分析
- **STRATEGY**: 长期规划
- **WORKING**: 工作日志
- **WARP**: 协作范式（本文档）

### 9.3 实用技巧

#### 利用AI的优势
**AI擅长的任务**:
- ✅ 编写重复性代码（测试用例）
- ✅ 生成结构化文档
- ✅ 分析大量数据（测试结果）
- ✅ 查找模式和异常
- ✅ 制定系统化方案

**人类更擅长的**:
- ✅ 战略决策
- ✅ 优先级判断
- ✅ 创造性思维
- ✅ 最终质量把关

#### 清晰的指令示例
```
任务: 创建集合类型测试程序
要求:
- 基于现有测试结构
- 测试 Vec 和 VecDeque
- 包含边界情况测试
- 详细的错误日志
```

#### 迭代改进循环
**循环**: 尝试 → 反馈 → 调整 → 完善

### 9.4 加速协作的技巧

#### 使用"继续"
当工作连续性好时，简单说"继续"，AI会：
- 保持当前上下文
- 按既定方向推进
- 自动进入下一个逻辑步骤

#### 使用"按最佳实践"
当不确定方向时，说"按最佳实践"，AI会：
- 评估当前状态
- 选择最优方案
- 解释选择理由

#### 明确反馈
**有效反馈**:
- "好，继续下一个模块"
- "这个分析很好，创建文档"
- "问题找到了，现在制定解决方案"

### 9.5 常见陷阱

#### 过度依赖
**陷阱**: 不加思考地接受所有建议
**解决**: 
- 理解AI的推理
- 验证关键决策
- 保持批判性思维

#### 目标不清
**陷阱**: "帮我看看这个项目"
**解决**:
- 明确具体目标
- 设定成功标准
- 分阶段推进

#### 忽视文档
**陷阱**: 只关注代码，不记录过程
**解决**:
- 同时进行工作和文档
- 记录决策原因
- 维护工作日志

#### 缺乏验证
**陷阱**: 生成代码后不测试
**解决**:
- 编译验证
- 运行测试
- 检查输出

### 9.6 成功指标

#### 好的协作会话特征
✅ **目标明确**: 知道要做什么  
✅ **进展可见**: 清晰的里程碑  
✅ **质量保证**: 测试和验证  
✅ **文档完整**: 知识可传承  
✅ **价值产出**: 解决实际问题

### 9.7 推荐实践

#### 开始新工作时
1. **回顾上次**: 阅读相关文档了解状态
2. **明确目标**: "我要完成[具体任务]"
3. **确认方法**: "按照[方法]进行"
4. **设定标准**: "成功是指[标准]"

#### 工作进行中
1. **定期确认**: "这样对吗？"
2. **调整方向**: "改成[新方向]"
3. **保存进度**: "提交当前成果"
4. **记录发现**: "更新文档"

#### 工作结束时
1. **总结成果**: "总结今天的工作"
2. **更新日志**: "更新相关文档"
3. **提交代码**: "git commit记录"
4. **计划下次**: "下次应该做[任务]"

## 10. 核心原则总结

1. **目标驱动**: 始终知道要达到什么目标
2. **系统方法**: 用结构化方式解决问题
3. **深度分析**: 找到根本原因，不是表象
4. **完整文档**: 记录过程和决策
5. **持续改进**: 反思和优化工作方式
6. **价值导向**: 聚焦真正重要的事情
7. **质量保证**: 测试验证所有产出

**记住**: Warp AI是工具，你是掌舵者。
- AI提供速度和广度
- 人类提供方向和深度
- 最佳协作 = AI能力 × 人类智慧

## 检查清单

在提交代码前，请确保：
- [ ] 代码遵循命名规范（局部变量 L 开头，参数 a 开头）
- [ ] 已编写对应的单元测试
- [ ] 已编写使用示例
- [ ] 项目文件配置正确（bin 和 lib 目录）
- [ ] 代码有适当的注释
- [ ] 所有测试通过
- [ ] 文档已更新
- [ ] 遵守单源编译设置规则（{$I fafafa.core.settings.inc}）

---

## 更新历史
- 2025-10-01：整合 fafafa.ssl 项目的 WARP.md 通用规范到 fafafa.core
- 2025-09-30：优化文档结构，添加快速开始、常见陷阱与维护指南
- 原文档来源：
  - fafafa.core 项目测试与架构规范
  - fafafa.ssl 项目开发规范与 Warp AI 协作范式
