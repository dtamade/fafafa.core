# fafafa 框架整体设计方案

> **愿景**: 构建现代化的FreePascal应用程序框架，提供高性能、类型安全、易于使用的核心库

本文档定义了fafafa框架的整体架构、设计理念和各模块间的协作关系。

---

## 🎯 框架设计理念

### 核心价值观

1. **现代化Pascal编程**
   - 充分利用FreePascal的现代特性（泛型、接口、操作符重载）
   - 提供类似现代语言（Rust、C#、TypeScript）的编程体验
   - 强调类型安全和编译期错误检查

2. **高性能导向**
   - 零成本抽象：抽象不应带来运行时开销
   - 内存效率：自定义分配器和内存池
   - 算法优化：针对常见场景的专门优化

3. **可组合性**
   - 模块化设计：每个模块都可独立使用
   - 接口驱动：通过接口实现松耦合
   - 插件化架构：支持用户扩展和定制

4. **开发者友好**
   - 直观的API设计
   - 丰富的文档和示例
   - 强大的调试和诊断工具

### 设计原则

- **SOLID原则**: 单一职责、开闭原则、里氏替换、接口隔离、依赖倒置
- **DRY原则**: 避免重复代码，通过泛型和模板实现代码复用
- **KISS原则**: 保持简单，避免过度设计
- **YAGNI原则**: 只实现当前需要的功能

---

## 🏗️ 框架架构

### 扁平化架构设计

```
fafafa.core (统一命名空间)
├── fafafa.core.base           # 基础设施和异常
├── fafafa.core.mem            # 内存管理和分配器
├── fafafa.core.collections    # 容器库和算法
├── fafafa.core.async          # 异步I/O和事件循环
├── fafafa.core.fs             # 文件系统操作
├── fafafa.core.thread         # 线程和并发原语
├── fafafa.core.net            # 网络通信
├── fafafa.core.json           # JSON数据处理
├── fafafa.core.xml            # XML数据处理
├── fafafa.core.http           # HTTP客户端/服务器
├── fafafa.core.testing        # 测试框架
├── fafafa.core.logging        # 日志系统
└── fafafa.core.profiling      # 性能分析工具
```

### 扁平化设计优势

1. **简化依赖**: 所有模块在同一命名空间下，减少复杂的层次结构
2. **易于导入**: 用户只需要 `uses fafafa.core.xxx` 即可使用对应功能
3. **统一管理**: 版本控制、文档、测试都在统一的结构下
4. **减少抽象**: 避免过度的模块化带来的复杂性

### 模块依赖关系 (扁平化)

```
核心基础层: fafafa.core.base, fafafa.core.mem
         ↑
容器算法层: fafafa.core.collections
         ↑
系统抽象层: fafafa.core.async, fafafa.core.fs, fafafa.core.thread
         ↑
网络通信层: fafafa.core.net, fafafa.core.http
         ↑
数据处理层: fafafa.core.json, fafafa.core.xml
         ↑
开发工具层: fafafa.core.testing, fafafa.core.logging, fafafa.core.profiling
```

---

## 📦 核心模块设计

### 1. fafafa.core.base - 基础设施

**职责**: 提供框架的基础类型、异常、工具函数

```pascal
// 核心异常体系
ECore = class(Exception);
EArgumentNil = class(ECore);
EOutOfRange = class(ECore);
EInvalidOperation = class(ECore);

// 基础接口
IDisposable = interface
  procedure Dispose;
end;

ICloneable<T> = interface
  function Clone: T;
end;

IComparable<T> = interface
  function CompareTo(const aOther: T): Integer;
end;

// 函数式编程支持
generic TFunc<TResult> = function: TResult;
generic TFunc<T, TResult> = function(const aArg: T): TResult;
generic TAction<T> = procedure(const aArg: T);
generic TPredicate<T> = function(const aArg: T): Boolean;
```

### 2. fafafa.core.mem - 内存管理

**职责**: 提供高性能的内存分配器和内存池

```pascal
// 分配器接口
IAllocator = interface
  function Alloc(aSize: SizeUInt): Pointer;
  function Realloc(aPtr: Pointer; aSize: SizeUInt): Pointer;
  procedure Free(aPtr: Pointer);
end;

// 内存池
generic TObjectPool<T: class> = class
  function Get: T;
  procedure Return(aObj: T);
  property Capacity: Integer;
  property Count: Integer;
end;

// 智能指针
generic TSharedPtr<T> = record
  class operator Initialize(var aDest: TSharedPtr<T>);
  class operator Finalize(var aDest: TSharedPtr<T>);
  class operator Assign(var aDest: TSharedPtr<T>; const aSrc: TSharedPtr<T>);
  function Get: T;
  function IsValid: Boolean;
  property RefCount: Integer;
end;
```

### 3. fafafa.core.collections - 容器库

**职责**: 提供高性能的泛型容器和算法

```pascal
// 核心容器接口
generic ICollection<T> = interface
  function GetCount: SizeUInt;
  function IsEmpty: Boolean;
  procedure Clear;
  function Contains(const aItem: T): Boolean;
end;

generic IList<T> = interface(ICollection<T>)
  function GetItem(aIndex: SizeUInt): T;
  procedure SetItem(aIndex: SizeUInt; const aValue: T);
  procedure Add(const aItem: T);
  procedure Insert(aIndex: SizeUInt; const aItem: T);
  function Remove(const aItem: T): Boolean;
  procedure RemoveAt(aIndex: SizeUInt);
end;

// 高性能实现
generic TVec<T> = class(IList<T>)
  // 动态数组实现，类似std::vector
end;

generic THashMap<TKey, TValue> = class
  // 哈希表实现，类似std::unordered_map
end;
```

### 4. fafafa.core.async - 异步I/O

**职责**: 提供事件驱动的异步编程模型

```pascal
// 事件循环
IEventLoop = interface
  function Run(aMode: TRunMode = rmDefault): Boolean;
  procedure Stop;
  procedure QueueWork(aWork: IAsyncWork);
end;

// Future/Promise模式
generic IFuture<T> = interface
  function IsCompleted: Boolean;
  function GetResult: T;
  function Then<TResult>(aFunc: TFunc<T, TResult>): IFuture<TResult>;
  function Catch(aHandler: TAction<Exception>): IFuture<T>;
end;

// 异步操作
generic TAsyncOperation<T> = class abstract
  function Execute: IFuture<T>;
  procedure Cancel;
end;
```

### 5. fafafa.core.fs - 文件系统

**职责**: 提供跨平台的文件系统操作

```pascal
// 文件系统接口
IFileSystem = interface
  function OpenFile(const aPath: string; aMode: TFileOpenMode): IFile;
  function CreateDirectory(const aPath: string): Boolean;
  function GetFileInfo(const aPath: string): TFileInfo;
end;

// 异步文件操作
IAsyncFileSystem = interface
  function OpenFileAsync(const aPath: string; aMode: TFileOpenMode): IFuture<IFile>;
  function ReadAllTextAsync(const aPath: string): IFuture<string>;
  function WriteAllTextAsync(const aPath: string; const aText: string): IFuture<Boolean>;
end;
```

---

## 🔧 跨模块协作机制

### 1. 统一的错误处理

```pascal
// 全局错误处理策略
TErrorHandlingMode = (
  ehmException,     // 抛出异常
  ehmResult,        // 返回Result<T>
  ehmCallback       // 回调处理
);

// 统一的结果类型
generic TResult<T> = record
  Success: Boolean;
  Value: T;
  Error: Exception;
  
  class function Ok(const aValue: T): TResult<T>; static;
  class function Fail(aError: Exception): TResult<T>; static;
  
  function IsOk: Boolean;
  function IsError: Boolean;
  function GetValueOrDefault(const aDefault: T): T;
  function GetValueOrRaise: T;
end;
```

### 2. 统一的配置系统

```pascal
// 配置接口
IConfiguration = interface
  function GetValue(const aKey: string): Variant;
  procedure SetValue(const aKey: string; const aValue: Variant);
  function GetSection(const aSection: string): IConfiguration;
end;

// 全局配置管理
TFrameworkConfig = class
public
  class function GetGlobal: IConfiguration;
  class procedure SetGlobal(aConfig: IConfiguration);
  
  // 模块特定配置
  class function GetMemoryConfig: IMemoryConfiguration;
  class function GetAsyncConfig: IAsyncConfiguration;
  class function GetFileSystemConfig: IFileSystemConfiguration;
end;
```

### 3. 统一的日志系统

```pascal
// 日志级别
TLogLevel = (llTrace, llDebug, llInfo, llWarn, llError, llFatal);

// 日志接口
ILogger = interface
  procedure Log(aLevel: TLogLevel; const aMessage: string);
  procedure Trace(const aMessage: string);
  procedure Debug(const aMessage: string);
  procedure Info(const aMessage: string);
  procedure Warn(const aMessage: string);
  procedure Error(const aMessage: string);
  procedure Fatal(const aMessage: string);
end;

// 全局日志管理
TFrameworkLogger = class
public
  class function GetLogger(const aName: string): ILogger;
  class procedure SetGlobalLevel(aLevel: TLogLevel);
  class procedure AddAppender(aAppender: ILogAppender);
end;
```

---

## 🚀 开发路线图

### 阶段一: 核心基础 (已完成)
- [x] fafafa.core.base - 基础设施
- [x] fafafa.core.mem - 内存管理
- [x] fafafa.core.collections - 基础容器

### 阶段二: I/O和并发 (进行中)
- [/] fafafa.core.async - 异步I/O框架
- [/] fafafa.core.fs - 文件系统模块
- [ ] fafafa.core.thread - 线程和并发

### 阶段三: 网络和数据
- [ ] fafafa.core.net - 网络通信
- [ ] fafafa.data.json - JSON处理
- [ ] fafafa.data.xml - XML处理

### 阶段四: Web和工具
- [ ] fafafa.web.http - HTTP框架
- [ ] fafafa.tools.testing - 测试框架
- [ ] fafafa.tools.logging - 日志系统

---

## 🔗 跨文档指引（Bytes/ByteBuf）
- 统一字节类型与Hex工具：见 docs/fafafa.core.bytes.md（TBytes 单一真源在 core.base，Hex 工具在 core.bytes）
- ByteBuf 读写双指针与零拷贝视图：见 docs/fafafa.core.bytes.buf.md（已实现阶段性 API 与 owner/view 约束）

---

## 📊 质量保证

### 1. 测试策略
- **单元测试**: 每个模块都有完整的单元测试覆盖
- **集成测试**: 测试模块间的协作
- **性能测试**: 基准测试和性能回归检测
- **内存测试**: 内存泄漏和内存安全检测

### 2. 文档标准
- **API文档**: 每个公共接口都有详细文档
- **设计文档**: 每个模块都有设计文档
- **示例代码**: 提供丰富的使用示例
- **最佳实践**: 编程指南和最佳实践

### 3. 代码质量
- **代码审查**: 所有代码都经过审查
- **静态分析**: 使用工具进行静态代码分析
- **编码规范**: 统一的编码风格和命名规范
- **持续集成**: 自动化构建和测试

这个框架设计方案为fafafa项目提供了清晰的发展方向和实现路径，确保各个模块能够协调发展，形成一个统一、高效的现代FreePascal框架。
