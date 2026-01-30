# Examples for fafafa.core.json

本目录包含 JSON 模块的可运行示例，覆盖读取遍历、JSON Pointer、JSON Patch、以及 Fluent 流畅 API。

## 示例清单

- example_json_read_traverse.lpr
  - 基础读取与遍历、错误定位
- example_json_pointer_min.lpr
  - JSON Pointer (RFC 6901) 最小示例
- example_json_patch_min.lpr
  - JSON Patch (RFC 6902) 最小示例
- example_fluent_min.lpr
  - Fluent Builder 嵌套构造 + ToJson/SaveToFile + ParseFile 回读
- example_hot_path_min.lpr
  - 热路径实践：Raw-Key 对象遍历避免 String 分配，TryGet/OrDefault 组合；见 docs/fafafa.core.json.md 的“热路径最佳实践”


## 构建与运行

推荐在 Windows 的 cmd.exe 环境下使用批处理脚本：

```
examples\fafafa.core.json\BuildAndRunExamples.bat
```

或仅构建运行最小示例（Flags/StopWhenDone）：

Windows（cmd.exe）
```
examples\fafafa.core.json\BuildOrRun_Min.bat
```

Linux/macOS（bash）
```
bash examples/fafafa.core.json/BuildOrRun_Min.sh
```

脚本会在 bin/ 下生成可执行文件，并将部分运行输出保存至：

- ..\..\todo\fafafa.core.json\logs\pointer_min_run.txt
- ..\..\todo\fafafa.core.json\logs\patch_min_run.txt
- ..\..\todo\fafafa.core.json\logs\fluent_min_run.txt

注意：在 PowerShell 中直接运行 .bat 可能出现重定向解析差异（例如“此时不应有 .。”提示）。若在 PowerShell 中调用，请加上 `cmd /c`。

## 直接构建单个示例（可选）

示例：直接编译 Fluent 最小示例

```
fpc -MObjFPC -Scghi -O1 -g -gl -Fu.\src -Feexamples\fafafa.core.json\bin examples\fafafa.core.json\example_fluent_min.lpr
examples\fafafa.core.json\bin\example_fluent_min.exe
```

## 相关文档

- docs/fluent.md：Fluent API 快速开始、迁移对照、调试与断言说明



- example_json_noexcept.lpr
  - 无异常（No-Exception）用法示例：以整数错误码返回结果，避免异常路径

### 独立构建/运行 No-Exception 示例

Windows:
```
examples\fafafa.core.json\BuildOrRun_NoExcept.bat
```

Linux/macOS:
```
bash examples/fafafa.core.json/BuildOrRun_NoExcept.sh
```
