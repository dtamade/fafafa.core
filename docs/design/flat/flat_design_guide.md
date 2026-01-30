# fafafa.core 扁平化设计指南

> **设计理念**: 简洁、直接、易用的扁平化框架架构

本文档定义了fafafa框架采用扁平化设计的具体规范和实施细节。

---

## 🎯 扁平化设计原则

### 核心理念

1. **单一命名空间**: 所有模块都在 `fafafa.core` 命名空间下
2. **最小层次**: 避免过深的目录结构和模块嵌套
3. **直接导入**: 用户通过简单的 `uses fafafa.core.xxx` 即可使用功能
4. **职责清晰**: 每个模块职责明确，避免功能重叠

### 设计优势

- **降低学习成本**: 用户无需理解复杂的模块层次关系
- **简化依赖管理**: 减少模块间的复杂依赖关系
- **提高开发效率**: 开发者能快速定位和使用所需功能
- **便于维护**: 扁平结构更容易维护和重构

---

## 📁 文件组织规范

### 主要模块结构

```
src/
├── fafafa.core.pas                 # 框架主入口，导入所有核心模块
├── fafafa.core.base.pas            # 基础设施：异常、接口、工具函数
├── fafafa.core.mem.pas             # 内存管理：分配器、内存池、智能指针
├── fafafa.core.collections.pas     # 容器库主模块
├── fafafa.core.collections.*.pas   # 具体容器实现
├── fafafa.core.async.pas           # 异步框架主模块
├── fafafa.core.async.*.pas         # 异步相关实现
├── fafafa.core.fs.pas              # 文件系统主模块
├── fafafa.core.fs.*.pas            # 文件系统相关实现
├── fafafa.core.thread.pas          # 线程和并发主模块
├── fafafa.core.net.pas             # 网络通信主模块
├── fafafa.core.json.pas            # JSON处理模块
├── fafafa.core.http.pas            # HTTP客户端/服务器模块
├── fafafa.core.testing.pas         # 测试框架模块
└── fafafa.core.logging.pas         # 日志系统模块
```

### 模块命名规范

1. **主模块**: `fafafa.core.{功能名}.pas`
   - 例如: `fafafa.core.fs.pas`, `fafafa.core.async.pas`

2. **子模块**: `fafafa.core.{功能名}.{子功能}.pas`
   - 例如: `fafafa.core.fs.sync.pas`, `fafafa.core.async.future.pas`

3. **平台特定**: `fafafa.core.{功能名}.{平台}.pas`
   - 例如: `fafafa.core.fs.windows.pas`, `fafafa.core.net.unix.pas`

4. **工具模块**: `fafafa.core.{功能名}.utils.pas`
   - 例如: `fafafa.core.fs.utils.pas`, `fafafa.core.collections.utils.pas`

---

## 🔧 API设计规范

### 统一的导入方式

```pascal
// 用户代码示例
program MyApp;

uses
  // 基础功能
  fafafa.core.base,
  fafafa.core.collections,
  
  // 异步和文件系统
  fafafa.core.async,
  fafafa.core.fs,
  
  // 网络和数据处理
  fafafa.core.net,
  fafafa.core.json;

begin
  // 直接使用框架功能
  var Vec := TVec<Integer>.Create;
  var FileSystem := TFileSystem.Create;
  var JsonParser := TJsonParser.Create;
end.
```

### 主模块设计模式

每个主模块 (`fafafa.core.xxx.pas`) 应该：

```pascal
unit fafafa.core.fs;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  // 导入相关子模块
  fafafa.core.base,
  fafafa.core.fs.types,
  fafafa.core.fs.sync,
  fafafa.core.fs.async;

// 重新导出核心类型和类
type
  // 核心接口
  IFileSystem = fafafa.core.fs.types.IFileSystem;
  IFile = fafafa.core.fs.types.IFile;
  IDirectory = fafafa.core.fs.types.IDirectory;
  
  // 核心实现类
  TFileSystem = fafafa.core.fs.sync.TFileSystem;
  TAsyncFileSystem = fafafa.core.fs.async.TAsyncFileSystem;
  
  // 数据类型
  TFileInfo = fafafa.core.fs.types.TFileInfo;
  TFileOpenMode = fafafa.core.fs.types.TFileOpenMode;

// 便利的全局函数
function CreateFileSystem: IFileSystem;
function CreateAsyncFileSystem(aLoop: IEventLoop): IAsyncFileSystem;

// 静态便利方法
TFile = class
public
  class function ReadAllText(const aPath: string): string;
  class function WriteAllText(const aPath: string; const aText: string): Boolean;
  class function Exists(const aPath: string): Boolean;
end;

implementation

// 实现便利函数
function CreateFileSystem: IFileSystem;
begin
  Result := TFileSystem.Create;
end;

function CreateAsyncFileSystem(aLoop: IEventLoop): IAsyncFileSystem;
begin
  Result := TAsyncFileSystem.Create(aLoop);
end;

// 实现静态方法
class function TFile.ReadAllText(const aPath: string): string;
var
  FS: IFileSystem;
  F: IFile;
begin
  FS := CreateFileSystem;
  F := FS.OpenFile(aPath, fomRead);
  Result := F.ReadString;
end;

end.
```

### 子模块设计模式

子模块专注于具体实现，不对外暴露：

```pascal
unit fafafa.core.fs.sync;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.base,
  fafafa.core.fs.types;

type
  // 同步文件系统实现
  TFileSystem = class(TInterfacedObject, IFileSystem)
  private
    FAllocator: TAllocator;
  public
    constructor Create(aAllocator: TAllocator = nil);
    destructor Destroy; override;
    
    // IFileSystem 接口实现
    function OpenFile(const aPath: string; aMode: TFileOpenMode; 
      aFlags: TFileOpenFlags = []): IFile;
    function CreateFile(const aPath: string; aMode: TFileMode = 644): IFile;
    // ... 其他方法
  end;

implementation

// 具体实现
constructor TFileSystem.Create(aAllocator: TAllocator);
begin
  inherited Create;
  if aAllocator = nil then
    FAllocator := GetDefaultAllocator
  else
    FAllocator := aAllocator;
end;

// ... 其他实现

end.
```

---

## 🔗 模块间协作规范

### 依赖关系管理

1. **基础模块**: `fafafa.core.base`, `fafafa.core.mem`
   - 被所有其他模块依赖
   - 不依赖任何其他框架模块

2. **容器模块**: `fafafa.core.collections`
   - 依赖基础模块
   - 被系统抽象层模块使用

3. **系统抽象层**: `fafafa.core.async`, `fafafa.core.fs`, `fafafa.core.thread`
   - 依赖基础模块和容器模块
   - 相互之间可以有依赖关系

4. **应用层模块**: `fafafa.core.net`, `fafafa.core.http`, `fafafa.core.json`
   - 依赖系统抽象层模块
   - 提供高级应用功能

### 统一的配置系统

```pascal
// 在 fafafa.core.base.pas 中定义
IFrameworkConfig = interface(IInterface)
['{FRAMEWORK-CONFIG-GUID}']
  function GetMemoryConfig: IMemoryConfig;
  function GetAsyncConfig: IAsyncConfig;
  function GetFileSystemConfig: IFileSystemConfig;
  function GetNetworkConfig: INetworkConfig;
end;

// 全局配置访问
function GetFrameworkConfig: IFrameworkConfig;
procedure SetFrameworkConfig(aConfig: IFrameworkConfig);
```

### 统一的错误处理

```pascal
// 在 fafafa.core.base.pas 中定义
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

// 所有模块都使用统一的结果类型
TFileResult<T> = TResult<T>;
TAsyncResult<T> = TResult<T>;
TNetResult<T> = TResult<T>;
```

---

## 📚 使用示例

### 简单文件操作

```pascal
program SimpleFileExample;

uses
  fafafa.core.fs;

begin
  // 直接使用静态方法
  if TFile.Exists('config.txt') then
  begin
    var Content := TFile.ReadAllText('config.txt');
    WriteLn('Config: ', Content);
  end;
  
  // 使用接口
  var FS := CreateFileSystem;
  var F := FS.OpenFile('output.txt', fomWrite);
  F.WriteString('Hello, fafafa!');
  F.Close;
end.
```

### 异步操作示例

```pascal
program AsyncExample;

uses
  fafafa.core.async,
  fafafa.core.fs;

begin
  var Loop := CreateEventLoop;
  var AsyncFS := CreateAsyncFileSystem(Loop);
  
  // 异步读取文件
  AsyncFS.ReadAllTextAsync('large_file.txt')
    .Then<Boolean>(function(const Content: string): Boolean
      begin
        WriteLn('File size: ', Length(Content));
        Result := True;
      end)
    .Catch(procedure(E: Exception)
      begin
        WriteLn('Error: ', E.Message);
      end);
  
  Loop.Run;
end.
```

### 组合使用示例

```pascal
program CombinedExample;

uses
  fafafa.core.base,
  fafafa.core.collections,
  fafafa.core.async,
  fafafa.core.fs,
  fafafa.core.json;

begin
  // 使用容器
  var FileList := TVec<string>.Create;
  FileList.Add('file1.txt');
  FileList.Add('file2.txt');
  
  // 异步处理
  var Loop := CreateEventLoop;
  var AsyncFS := CreateAsyncFileSystem(Loop);
  
  // 批量读取文件并解析JSON
  for var FileName in FileList do
  begin
    AsyncFS.ReadAllTextAsync(FileName)
      .Then<TJsonValue>(function(const Content: string): TJsonValue
        begin
          var Parser := TJsonParser.Create;
          Result := Parser.Parse(Content);
        end)
      .Then<Boolean>(function(const Json: TJsonValue): Boolean
        begin
          WriteLn('Parsed JSON from ', FileName);
          Result := True;
        end);
  end;
  
  Loop.Run;
end.
```

这种扁平化设计让框架更加简洁易用，用户可以快速上手并组合使用各种功能，同时保持了代码的清晰性和可维护性。
