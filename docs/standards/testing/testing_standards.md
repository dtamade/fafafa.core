# fafafa.core 测试体系规范

## 📋 概述

本文档定义了 fafafa.core 框架的测试体系标准，确保所有模块的测试具有一致性、可维护性和跨平台兼容性。

## 🏗️ 目录结构规范

### 标准测试目录结构

```
tests/{module}/
├── buildOrTest.bat          # Windows 构建/测试脚本
├── buildOrTest.sh           # Unix 构建/测试脚本
├── tests_{module}.lpi       # Lazarus 项目文件
├── tests_{module}.lpr       # 主程序文件
├── test_{feature1}.pas      # 功能测试单元
├── test_{feature2}.pas      # 功能测试单元
├── bin/                     # 输出可执行文件目录
│   └── tests.exe           # 测试可执行文件
└── lib/                     # 编译中间文件目录
    └── {target}/           # 平台特定目录
```

### 命名规范

- **项目文件**: `tests_{module}.lpi`
- **主程序**: `tests_{module}.lpr`
- **测试单元**: `test_{feature}.pas`
- **可执行文件**: `tests.exe` (Windows) / `tests` (Unix)
- **构建脚本**: `buildOrTest.bat` / `buildOrTest.sh`

## 🔧 构建脚本规范

### 功能要求

1. **统一接口**:
   - `./buildOrTest.bat` 或 `./buildOrTest.sh` - 仅构建
   - `./buildOrTest.bat test` 或 `./buildOrTest.sh test` - 构建并运行测试

2. **路径处理**:
   - 使用相对路径，避免硬编码
   - 自动创建输出目录
   - 支持从任意工作目录调用

3. **构建策略**:
   - 优先使用 `tools/lazbuild.bat` (Windows) 或 `lazbuild` (Unix)
   - 失败时回退到直接调用 `fpc`
   - 启用调试信息和内存泄漏检测

4. **错误处理**:
   - 明确的错误代码返回
   - 详细的错误信息输出
   - 构建失败时停止执行

### 模板使用

使用 `tools/test_template.bat` 和 `tools/test_template.sh` 作为新模块测试脚本的起点：

1. 复制模板到 `tests/{module}/`
2. 重命名为 `buildOrTest.bat` / `buildOrTest.sh`
3. 修改 `MODULE_NAME` 变量
4. 根据需要调整特定配置

## 📝 项目文件规范

### Lazarus 项目配置

```xml
<CONFIG>
  <ProjectOptions>
    <General>
      <Title Value="tests_{module}"/>
      <UseAppBundle Value="False"/>
      <ResourceType Value="res"/>
    </General>
    <Target>
      <Filename Value="bin\tests"/>
    </Target>
    <SearchPaths>
      <IncludeFiles Value="$(ProjOutDir);..\..\src"/>
      <OtherUnitFiles Value="..\..\src"/>
      <UnitOutputDirectory Value="lib\$(TargetCPU)-$(TargetOS)"/>
    </SearchPaths>
    <!-- 调试配置 -->
    <Parsing>
      <SyntaxOptions>
        <IncludeAssertionCode Value="True"/>
      </SyntaxOptions>
    </Parsing>
    <CodeGeneration>
      <Checks>
        <IOChecks Value="True"/>
        <RangeChecks Value="True"/>
        <OverflowChecks Value="True"/>
        <StackChecks Value="True"/>
      </Checks>
      <VerifyObjMethodCallValidity Value="True"/>
    </CodeGeneration>
    <Linking>
      <Debugging>
        <DebugInfoType Value="dsDwarf3"/>
        <UseHeaptrc Value="True"/>
        <TrashVariables Value="True"/>
        <UseExternalDbgSyms Value="True"/>
      </Debugging>
    </Linking>
  </ProjectOptions>
</CONFIG>
```

### 主程序结构

```pascal
program tests_{module};

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

uses
  Classes,
  consoletestrunner,
  // 测试单元
  test_{feature1},
  test_{feature2};

var
  Application: TTestRunner;

begin
  Application := TTestRunner.Create(nil);
  Application.Initialize;
  Application.Title := 'fafafa.core.{module} Tests';
  Application.Run;
  Application.Free;
end.
```

## 🧪 测试单元规范

### 单元结构

```pascal
unit test_{feature};

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.{module};

type
  TTestCase_{Feature} = class(TTestCase)
  private
    // 私有成员

  protected
    procedure SetUp; override;
    procedure TearDown; override;

  published
    // 测试方法
    procedure Test{Functionality};
  end;

implementation

{ TTestCase_{Feature} }

procedure TTestCase_{Feature}.SetUp;
begin
  inherited SetUp;
  // 初始化代码
end;

procedure TTestCase_{Feature}.TearDown;
begin
  // 清理代码
  inherited TearDown;
end;

procedure TTestCase_{Feature}.Test{Functionality};
begin
  // 测试实现
end;

initialization
  RegisterTest(TTestCase_{Feature});

end.
```

### 测试命名规范

- **测试类**: `TTestCase_{Feature}`
- **测试方法**: `Test{Functionality}`
- **边界测试**: `Test{Functionality}BoundaryConditions`
- **错误测试**: `Test{Functionality}WithInvalidInput`
- **性能测试**: `Test{Functionality}Performance`

## 🎯 测试质量标准

### 覆盖率要求

1. **功能覆盖**: 所有公开接口必须有对应测试
2. **边界测试**: 包含边界条件和异常情况
3. **错误处理**: 验证异常抛出和错误处理
4. **资源管理**: 验证内存泄漏和资源清理

### 测试原则

1. **独立性**: 每个测试独立运行，不依赖其他测试
2. **可重复性**: 测试结果可重复，不受环境影响
3. **快速执行**: 单个测试应在合理时间内完成
4. **清晰断言**: 使用明确的断言和错误消息

## 🔒 注册用例的生命周期安全

- 使用闭包（reference to procedure）注册测试/子测试，避免使用 `is nested` 的过程：
  - 原因：`RegisterTests` 返回后，nested proc 的静态链可能失效，延迟调用会导致 AV。
  - 详见：docs/partials/testing.best_practices.md


### 性能基准

- **内存泄漏**: 0 个未释放内存块
- **测试时间**: 完整测试套件应在 60 秒内完成
- **成功率**: 100% 测试通过率

## 🔄 持续集成

### 自动化测试

测试脚本应支持以下场景：

1. **本地开发**: 开发者本地运行测试
2. **CI/CD**: 自动化构建系统集成
3. **跨平台**: Windows 和 Unix 平台兼容

### 报告格式

使用标准化的测试输出格式：

```
Number of run tests: {total}
Number of errors:    {errors}
Number of failures:  {failures}

Heap dump by heaptrc unit
{memory_blocks} memory blocks allocated : {allocated_bytes}
{memory_blocks} memory blocks freed     : {freed_bytes}
{unfreed_blocks} unfreed memory blocks : {unfreed_bytes}
```

## 📚 最佳实践

### 测试组织

1. **按功能分组**: 相关测试放在同一个测试类中
2. **逻辑顺序**: 按照功能的逻辑顺序组织测试方法
3. **清晰命名**: 测试名称应清楚表达测试意图

### 断言使用

```pascal
// 推荐的断言模式
AssertTrue('描述性错误消息', 条件);
AssertEquals('期望值与实际值不符', 期望值, 实际值);
AssertNotNull('对象不应为空', 对象);

// 异常测试
try
  // 应该抛出异常的代码
  Fail('应该抛出异常但没有');
except
  on E: EExpectedException do
    AssertTrue('异常消息正确', Pos('期望文本', E.Message) > 0);
end;
```

### 资源管理

```pascal
procedure TTestCase.SetUp;
begin
  inherited SetUp;
  FResource := CreateResource;
end;

procedure TTestCase.TearDown;
begin
  FResource := nil; // 接口自动释放
  inherited TearDown;
end;
```

## 🚀 未来扩展

### 计划改进

1. **测试覆盖率报告**: 集成代码覆盖率工具
2. **性能基准测试**: 自动化性能回归检测
3. **并行测试执行**: 提高大型测试套件的执行速度
4. **测试数据管理**: 标准化测试数据和模拟对象

---

**版本**: 1.0.0
**更新时间**: 2025-08-11
**维护团队**: fafafa.core 开发团队
