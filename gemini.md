# fafafa.core 协作规范 (gemini.md)

本文档旨在帮助 Gemini 与开发者更好地协作，确保代码风格、项目目标和开发实践保持一致，共同构建一个技术卓越、API 设计优雅的高性能 Pascal 核心框架。

---

## 1. 核心架构与设计原则

### 1.1. 模块化与命名空间
*   **目录结构与单元命名**: 为避免与第三方库产生命名冲突，项目**必须**采用**扁平化的 `src/` 目录结构**，并使用**带逻辑命名空间的长单元名** (e.g., `fafafa.core.collections.base.pas`)。
*   **职责单一 (Single Responsibility)**: 每个单元应高度内聚，只负责一块明确的功能。例如:
    *   `fafafa.core.math.pas`: 提供不依赖外部 `Math` 单元的、最基础的数学辅助函数。
    *   `fafafa.core.base.pas`: 提供框架最顶层的异常基类 `ECore` 和通用异常。
    *   `fafafa.core.mem.allocator.pas`: 只负责内存的“分配”与“释放”相关的接口和类。

### 1.2. API 设计哲学
*   **抽象层优于平行实现**: 当需要支持多种底层实现时（如不同的内存管理器），**不应**创建平行的全局函数代理，而应为现有的抽象层（`IAllocator`/`TAllocator`）提供新的实现（`TCrtAllocator`）。通过切换抽象层的具体实例来达到目的，以维护架构的统一性。
*   **处理零元素/零尺寸操作**: 对于接受数量或尺寸参数（如 `aCount`, `aSize`）的操作，当该参数为 0 时，应将其视为一个有效的、无操作的请求 (no-op)。方法应直接 `exit`，**不应**抛出异常。
    *   **空操作原则 (Null Operation Principle)**: 本框架所有接口完全遵守此原则，即当输入参数 `aCount` 或 `aSize` 为 0 时，不进行任何操作，直接 `exit`。
*   **索引与数量参数类型**:
    *   **优先使用无符号整数**: 考虑到索引和数量在概念上天然为非负数，所有接受大小或数量的参数 (如 `aSize`, `aCount`) 以及索引参数，**应优先使用无符号整数类型** (如 `Cardinal`, `UInt64`)。
    *   **溢出安全**: 使用无符号整数时，必须严格防范潜在的**溢出 (Overflow)** 风险，特别是当加法操作 (`aIndex + aCount`) 结果超出类型最大值时可能导致的**静默内存踩踏 (Silent Memory Stomping)**。需要特别注意的是，无符号整数的溢出是无法被运行时检测到的，其行为是定义好的“回绕”，因此必须通过预防性措施来规避。为确保代码健壮性，必须遵循以下安全准则：
        1.  **显式边界检查**: 在任何使用无符号整数作为索引或数量的地方，**必须**进行严格的边界检查，确保其值在有效范围内。
        2.  **避免中间溢出**: 对于涉及范围计算的场景 (如 `aIndex + aCount` 用于检查是否超出容器边界)，**严禁直接进行加法运算**。应改用**减法逻辑**来规避溢出，例如：`if aCount > (FLength - aIndex) then raise EOutOfRange;` (其中 `FLength` 为容器总长度)。
        3.  **全面单元测试**: 针对所有使用无符号整数作为索引或数量的函数和方法，必须编写详尽的单元测试，特别关注边界条件、零值以及可能导致溢出的场景。
        4.  **在与 RTL 函数交互时的类型安全**:
            *   当将无符号整数（如 `Cardinal`, `UInt64`）作为参数传递给可能期望 `SizeInt`（或其他有符号整数类型）的 RTL 函数时，**必须进行显式类型转换**。
            *   在转换前，**务必检查无符号数的值是否在目标有符号类型所能表示的有效范围内**。如果超出范围，应抛出异常或采取其他错误处理措施，而不是让其隐式转换导致 RTL 函数的错误行为。
                ```pascal
                // 示例：假设 SomeRTLFunction 期望 Integer 类型的参数
                var
                  MyUnsignedCount: Cardinal;
                  ConvertedCount: Integer;
                begin
                  MyUnsignedCount := 12345; // 假设这是一个有效值

                  // 检查是否在 Integer 范围内
                  if (MyUnsignedCount > MaxInt) then // MaxInt 是 Integer 的最大值
                    raise EOutOfRange.Create('Unsigned count exceeds Integer max value for RTL function.');

                  ConvertedCount := Integer(MyUnsignedCount); // 显式转换
                  SomeRTLFunction(ConvertedCount); // 调用 RTL 函数
                end;
                ```
            *   当从 RTL 函数接收 `SizeInt` 或其他有符号整数结果，并需要将其用于无符号上下文时，也应进行显式转换，并检查负值。
            *   **处理超出目标类型范围的参数**: 对于接受 `SizeUInt` 类型参数，但底层 RTL 函数只支持 `SizeInt` 范围的操作（如 `FillChar`, `System.Move` 等），如果 `SizeUInt` 的值超出了 `SizeInt` 的最大值，**不应直接抛出异常**。相反，应通过**分块（chunking）**的方式，将大操作分解为多次小操作，每次操作的尺寸都在 RTL 函数支持的 `SizeInt` 范围内，以确保操作能够完整执行并充分利用 `SizeUInt` 的整个范围。这要求函数内部实现循环或递归来处理分块逻辑。
            *   **性能敏感函数的 `SizeInt` 重载**: 对于那些接受 `SizeUInt` 参数且内部可能进行分块处理的性能敏感函数（如内存填充、比较等），应同时提供一个**参数类型为 `SizeInt` 的重载版本**。这个重载版本应直接调用底层的 RTL 函数，不进行分块，以避免在常见尺寸范围内不必要的性能开销。调用者应根据实际需求选择合适的版本。
*   **对齐参数的约束**: 对于接受对齐参数（如 `aAlignment`）的函数，该参数**必须**是2的幂。如果不是，结果可能未定义或抛出异常。在 `UnChecked` 版本中，调用者有责任确保此约束。
*   **函数变体与性能考量**:
    *   **Checked (检查版本)**: 默认情况下，所有公共 API 都应包含必要的参数验证、边界检查和错误处理，以确保健壮性和安全性。当输入无效时，应抛出适当的异常。
    *   **UnChecked (无检查版本)**: 对于某些性能敏感的场景，可以提供 `UnChecked` 变体。这些函数**明确不进行任何安全检查**（包括 `nil` 指针检查、边界检查、溢出检查等）。它们假设调用者已经确保了所有输入参数的有效性，并且不会导致任何运行时错误。使用 `UnChecked` 函数是为了追求极致性能，但**必须由调用者自行承担所有安全风险**。



### 1.3. 异常体系设计
*   **统一基类**: 所有由本框架抛出的异常，都**必须**继承自一个统一的根异常 `ECore`。
*   **扁平化与通用语义**: 避免过度、深度的继承层次。异常类型应尽可能直接继承自 `ECore`，其名称应具备高度通用和自解释的语义（如 `EInvalidOperation`, `EParamOutOfRange`），而不是为每个具体操作都创建一个异常。

---

## 2. 编码规范 (Coding Style)

### 2.1. 命名约定
*   **类型**: 接口 `I...`, 类/对象 `T...`, 指针 `P...`。
*   **变量**: 参数 `a...`, 局部变量 `L...`, 字段 `F...`。
*   **常量**: `ALL_CAPS_WITH_UNDERSCORES`。

### 2.2. 注释风格
*   **注释语法**: 
    *   **整行注释**: 如果一行完全用于注释 (即该行没有任何实际的代码), **必须**使用花括号 `{}`.
    *   **行尾注释**: 如果注释位于一行代码的右侧, **必须**使用双斜杠 `//`.

*   **双语注释**: 所有面向公开接口的文档注释 (`/** ... */`) **必须** 提供双语支持 (英文在前, 中文在后)。

*   **标点符号**: 所有注释和文档中的标点符号, **必须** 使用英文半角标点 (`.`, `,`, `()`)。

*   **参数与异常注释**:
    *   **对齐与格式**: `@desc` 关键字应独占一行. 在 `@params` 和 `@exceptions` 块中, 参数名/异常名, 英文描述应通过空格实现垂直对齐.
    *   **中英文块分离**: 英文描述块应完整地放在前面, 中文描述块应完整地跟在后面, 两者用一个空行隔开.
    *   **条目间距**: 在多个参数或异常定义的条目之间, 应保留一个空行, 以增强可读性.
    *   **示例**:
        ```pascal
        {**
         * SerializeToArrayBuffer
         *
         * @desc
         *   Serializes the collection's elements into a raw memory buffer.
         *   将容器中的元素序列化到原始内存缓冲区.
         *
         * @params
         *   aDst    A pointer to the destination memory buffer.
         *   aCount  The number of elements to serialize.
         *
         *   aDst    指向目标内存缓冲区的指针.
         *   aCount  要序列化的元素数量.
         *
         * @remark 
         *   This operation serializes `aCount` elements starting from the beginning of the collection's logical sequence.
         *   **WARNING:** The caller must ensure the destination buffer is large enough to hold `aCount` elements to prevent buffer overflows.
         *
         *   此操作从容器逻辑序列的起始位置开始序列化 `aCount` 个元素.
         *   **警告:** 调用者必须确保 `aDst` 指向的目标缓冲区足够大,以容纳 `aCount` 个元素, 以防止缓冲区溢出.
         *
         * @exceptions
         *   EArgumentNil      If `aDst` is `nil` and `aCount` > 0.
         *   EInvalidArgument  If the source pointer overlaps with the container's memory range.
         *   EOutOfRange       If `aCount` is out of range.
         *
         *   EArgumentNil      当 `aDst` 为 `nil` 且 `aCount` > 0 时抛出.
         *   EInvalidArgument  如果源指针与当前容器内存范围重叠.
         *   EOutOfRange       如果 `aCount` 超出范围.
         *}
        ```

*   **实现注释**:
    *   **禁止冗余注释**: 实现（`implementation`）部分的代码通常不应包含注释。实现是接口的具体体现，接口已通过详细文档注释充分说明其行为。
    *   **特殊情况**: 仅在极少数情况下，当实现中存在高度复杂、非直观或涉及特定技术决策的代码时，可以添加简洁的、解释“为什么”而非“是什么”的注释。

*   **禁止生成 Banner**:
    *   **统一管理**: 任何文件的顶部都不应包含自动生成的 ASCII 艺术或冗余的 Banner。
    *   **版权信息**: 版权和作者信息应集中在项目根目录的 `GEMINI.md` 或其他指定文件中统一管理。











### 2.3. 代码结构
*   **全局配置**: 每个单元在 `unit` 声明之后、`interface` 之前，**必须** 包含全局配置文件 `{$I fafafa.core.settings.inc}`。
*   **对齐与间距**: 在 `var` 声明块和连续赋值语句中，应垂直对齐类型和 `:=` 操作符。
*   **控制流语句间距**: `for`, `if`, `while` 等控制流关键字，其上方应空一行，且其下方代码块（`begin...end` 或单行语句）与控制流关键字之间也应空一行。

---

## 3. 开发工作流

*   **测试驱动**: 任何新的功能或错误修复都应伴随着相应的单元测试。
*   **零警告编译**: 项目代码必须在编译器默认的最高警告级别下实现零警告和零提示。
*   **编译与测试**: 始终使用项目根目录下的 `.vscode/CompileOmniPascalServerProject.bat` 脚本来执行编译和运行单元测试。

---

## 4. 沟通约定

*   **语言**: 我们将使用**中文**进行所有沟通和交流。
*   **协作原则**:
    *   **追求卓越**: 我们的共同目标是构建一个技术卓越、API 设计优雅的库。
    *   **坦率中立**: Gemini 应始终保持技术中立，从专业角度提供分析和建议，不应为了迎合而妥协技术原则。
    *   **严谨批判**: 当开发者（用户）的设计或决策存在潜在风险、不一致性或有更优方案时，Gemini必须直接、明确地提出反驳和批判性意见，解释其背后的技术权衡。我们鼓励并依赖这种严谨的审查来保证最终的质量。

---

## 5. 项目规划文档 (Project Blueprints)

此部分提供指向 `docs/` 目录下各个核心功能规划文档的链接，这些文档是具体开发工作的路线图。

*   **`docs/refactoring.md`**: 项目模块化重构的行动计划。
*   **`docs/iter.md`**: 迭代器框架的设计与实现路线图。
*   **`docs/associative.md`**: 关联式容器 (Map, Set) 的设计与实现路线图。
*   **`docs/algorithms.md`**: 通用算法库的设计与实现路线图。
*   **`docs/memory.md`**: 高级内存管理器的设计与实现路线图。
*   **`docs/benchmarks.md`**: 性能基准测试框架的搭建计划。
*   **`docs/todo.md`**: 日常的、临时的任务清单与草稿区。
