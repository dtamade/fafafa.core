# fafafa.core.yaml - YAML 解析和发射库

## 概述

fafafa.core.yaml 是一个高性能的 YAML 解析和发射库，移植自 libfyaml (https://github.com/pantoniou/libfyaml)。它目标对齐 libfyaml 的 API 与行为，并逐步对齐 YAML 1.2 规范（当前实现子集，详见 docs/yaml_support_matrix.md），并针对 FreePascal 进行了优化。

## 特性

### 核心特性
- **目标兼容 YAML 1.2** - 当前实现子集（见支持矩阵），持续增强中
- **高性能** - 零拷贝操作，优化的内存管理
- **事件驱动** - 支持流式解析，适合大文件处理
- **文档模型** - 提供完整的文档对象模型 API
- **错误诊断** - 详细的错误信息和位置追踪
- **跨平台** - 支持 Windows、Linux、macOS 等平台

### API 兼容性
- **1:1 移植** - 与 libfyaml 保持完全一致的 API
- **C 风格接口** - 熟悉的函数命名和参数约定
- **不透明指针** - 安全的对象封装和内存管理

## 快速开始

### 基本用法

```pascal
uses fafafa.core.yaml;

var
  cfg: TFyParseCfg;
  doc: PFyDocument;
  root: PFyNode;
  yaml_text: PChar;
begin
  // 初始化解析配置
  cfg.search_path := nil;
  cfg.flags := [];
  cfg.userdata := nil;
  cfg.diag := nil;
  
  // 解析 YAML 字符串
  yaml_text := 'name: John Doe' + #10 + 'age: 30';
  doc := yaml_document_build_from_string(@cfg, yaml_text, StrLen(yaml_text));
  
  if doc <> nil then
  begin
    // 获取根节点
    root := yaml_document_get_root(doc);
    
    // 处理文档...
    
    // 清理资源
    yaml_document_destroy(doc);
  end;
end;
```

### 事件驱动解析

```pascal
uses fafafa.core.yaml;

var
  cfg: TFyParseCfg;
  parser: PFyParser;
  event: PFyEvent;
begin
  // 创建解析器
  cfg.search_path := nil;
  cfg.flags := [];
  cfg.userdata := nil;
  cfg.diag := nil;
  
  parser := yaml_parser_create(@cfg);
  if parser <> nil then
  begin
    // 设置输入
    yaml_parser_set_string(parser, 'key: value', 10);
    
    // 解析事件
    repeat
      event := yaml_parser_parse(parser);
      if event <> nil then
      begin
        WriteLn('Event: ', yaml_event_type_get_text(event^.event_type));
        yaml_parser_event_free(parser, event);
      end;
    until event = nil;

    // 清理资源
    yaml_parser_destroy(parser);
  end;
end.
```

### 基本用法（yaml_* 门面）

```pascal
uses fafafa.core.yaml;

var
  parser: PYamlParser;
  event: PYamlEvent;
  cfg: TYamlParseCfg;
begin
  FillChar(cfg, SizeOf(cfg), 0);
  parser := yaml_parser_create(@cfg);
  if parser <> nil then
  begin
    // 设置输入（可解析 flow 映射/序列与行内映射）
    yaml_parser_set_string(parser, 'key: value', 10);

    // 解析事件：+STR, +DOC, (=VAL|+MAP/+SEQ ...), -DOC, -STR
    repeat
      event := yaml_parser_parse(parser);
      if event <> nil then
      begin
        WriteLn('Event: ', yaml_event_type_get_text(event^.event_type));
        yaml_parser_event_free(parser, event);
      end;
    until event = nil;

    yaml_parser_destroy(parser);
  end;
end.
```

### 事件驱动解析（flow 与非 flow 混合示例）

```pascal
uses fafafa.core.yaml;

var
  parser: PYamlParser;
  event: PYamlEvent;
  cfg: TYamlParseCfg;
begin
  FillChar(cfg, SizeOf(cfg), 0);
  cfg.flags := [YAML_PCF_RESOLVE_DOCUMENT];
  parser := yaml_parser_create(@cfg);
  if parser <> nil then
  begin
    yaml_parser_set_string(parser, '{a:[1,2], b:{c:3}}', Length('{a:[1,2], b:{c:3}}'));

    repeat
      event := yaml_parser_parse(parser);
      if event <> nil then
      begin
        WriteLn('Event: ', yaml_event_type_get_text(event^.event_type));
        yaml_parser_event_free(parser, event);
      end;
    until event = nil;

    yaml_parser_destroy(parser);
  end;
end.
```

## API 参考

### 版本管理

#### yaml_version_default
```pascal
function yaml_version_default: PYamlVersion;
```
返回库的默认 YAML 版本。

#### yaml_version_compare
```pascal
function yaml_version_compare(const va, vb: PYamlVersion): Integer;
```
比较两个 YAML 版本。返回值：
- `< 0` - va 低于 vb
- `= 0` - 版本相等  
- `> 0` - va 高于 vb

#### yaml_version_is_supported
```pascal
function yaml_version_is_supported(const vers: PYamlVersion): Boolean;
```
检查指定版本是否受支持。

### 解析器 API

#### yaml_parser_create
```pascal
function yaml_parser_create(const cfg: PYamlParseCfg): PYamlParser;
```
创建新的解析器实例。

#### yaml_parser_destroy
```pascal
procedure yaml_parser_destroy(fyp: PYamlParser);
```
销毁解析器并释放资源。

#### yaml_parser_parse
```pascal
function yaml_parser_parse(fyp: PYamlParser): PYamlEvent;
```
解析下一个事件。返回 nil 表示解析结束。

#### yaml_parser_event_free
```pascal
procedure yaml_parser_event_free(fyp: PYamlParser; fye: PYamlEvent);
```
释放事件资源。

### 文档 API

#### yaml_document_build_from_string
```pascal
function yaml_document_build_from_string(const cfg: PYamlParseCfg; const str: PChar; len: SizeUInt): PYamlDocument;
```
从字符串构建 YAML 文档。

#### yaml_document_build_from_file
```pascal
function yaml_document_build_from_file(const cfg: PYamlParseCfg; const filename: PChar): PYamlDocument;
```
从文件构建 YAML 文档。

#### yaml_document_get_root
```pascal
function yaml_document_get_root(fyd: PYamlDocument): PYamlNode;
```
获取文档的根节点。

#### yaml_document_destroy
```pascal
procedure yaml_document_destroy(fyd: PYamlDocument);
```
销毁文档并释放所有资源。

### 节点 API

#### yaml_node_get_type
```pascal
function yaml_node_get_type(fyn: PYamlNode): TYamlNodeType;
```
获取节点类型 (SCALAR, SEQUENCE, MAPPING)。

#### yaml_node_get_scalar
```pascal
function yaml_node_get_scalar(fyn: PYamlNode; len: PSizeUInt): PChar;
```
获取标量节点的值。

#### yaml_node_sequence_item_count
```pascal
function yaml_node_sequence_item_count(fyn: PYamlNode): Integer;
```
获取序列节点的项目数量。

#### yaml_node_sequence_get_by_index
```pascal
function yaml_node_sequence_get_by_index(fyn: PYamlNode; index: Integer): PYamlNode;
```
按索引获取序列项目。

#### yaml_node_mapping_lookup_by_string
```pascal
function yaml_node_mapping_lookup_by_string(fyn: PYamlNode; const key: PChar; keylen: SizeUInt): PYamlNode;
```
在映射节点中查找指定键的值。

### 发射器 API

#### yaml_emit_document
```pascal
function yaml_emit_document(fyd: PYamlDocument; const cfg: PYamlEmitCfg; len: PSizeUInt): PChar;
```
将文档发射为 YAML 字符串。

## 类型定义

### 基础类型

#### TFyVersion
```pascal
TFyVersion = record
  major: Integer;  // 主版本号
  minor: Integer;  // 次版本号
end;
```

#### TFyEventType
```pascal
TFyEventType = (
  FYET_NONE,           // 无事件
  FYET_STREAM_START,   // 流开始
  FYET_STREAM_END,     // 流结束
  FYET_DOCUMENT_START, // 文档开始
  FYET_DOCUMENT_END,   // 文档结束
  FYET_MAPPING_START,  // 映射开始
  FYET_MAPPING_END,    // 映射结束
  FYET_SEQUENCE_START, // 序列开始
  FYET_SEQUENCE_END,   // 序列结束
  FYET_SCALAR,         // 标量
  FYET_ALIAS           // 别名
);
```

#### TFyNodeType
```pascal
TFyNodeType = (
  FYNT_SCALAR,   // 标量节点
  FYNT_SEQUENCE, // 序列节点
  FYNT_MAPPING   // 映射节点
);
```

### 配置类型

#### TFyParseCfg
```pascal
TFyParseCfg = record
  search_path: PChar;           // 搜索路径
  flags: TFyParseCfgFlags;      // 解析标志
  userdata: Pointer;           // 用户数据
  diag: PFyDiag;              // 诊断接口
end;
```

#### TFyEmitCfg
```pascal
TFyEmitCfg = record
  flags: TFyEmitCfgFlags;      // 发射标志
  indent: Integer;             // 缩进空格数
  width: Integer;              // 行宽度
  userdata: Pointer;           // 用户数据
  diag: PFyDiag;              // 诊断接口
end;
```

## 错误处理

### 错误类型
```pascal
TFyErrorType = (
  FYET_DEBUG,    // 调试信息
  FYET_INFO,     // 一般信息
  FYET_NOTICE,   // 通知
  FYET_WARNING,  // 警告
  FYET_ERROR     // 错误
);
```

### 错误检查
大多数函数在失败时返回 nil 或负值。应该始终检查返回值：

```pascal
doc := yaml_document_build_from_string(@cfg, yaml_text, len);
if doc = nil then
begin
  WriteLn('解析失败');
  Exit;
end;
```

## 最佳实践

### 内存管理
- 始终配对调用创建和销毁函数
- 使用完事件后立即释放
- 避免在循环中创建大量对象

### 性能优化
- 对于大文件，使用事件驱动解析
- 重用解析器和发射器实例
- 合理设置缓冲区大小

### 错误处理
- 检查所有函数的返回值
- 使用诊断接口获取详细错误信息
- 在错误情况下正确清理资源

## 示例

### 解析配置文件
```pascal
function LoadConfig(const filename: String): Boolean;
var
  cfg: TFyParseCfg;
  doc: PFyDocument;
  root, node: PFyNode;
begin
  Result := False;
  
  cfg.search_path := nil;
  cfg.flags := [];
  cfg.userdata := nil;
  cfg.diag := nil;
  
  doc := yaml_document_build_from_file(@cfg, PChar(filename));
  if doc = nil then Exit;
  
  try
    root := yaml_document_get_root(doc);
    if root = nil then Exit;
    
    // 读取配置项
    node := yaml_node_mapping_lookup_by_string(root, 'server_port', 11);
    if node <> nil then
    begin
      // 处理端口配置...
    end;
    
    Result := True;
  finally
    yaml_document_destroy(doc);
  end;
end;
```

## 兼容性

### YAML 版本支持
- YAML 1.1 - 完全支持
- YAML 1.2 - 完全支持 (默认)
- YAML 1.3 - 计划支持

### 平台支持
- Windows (32/64 位)
- Linux (x86/x64/ARM)
- macOS (Intel/Apple Silicon)
- FreeBSD

### 编译器支持
- Free Pascal 3.2.0+
- Lazarus 2.0.0+

## 许可证

本库基于 MIT 许可证，与原始 libfyaml 保持一致。

## 参考资料

- [YAML 1.2 规范](https://yaml.org/spec/1.2/spec.html)
- [libfyaml 项目](https://github.com/pantoniou/libfyaml)
- [FreePascal 文档](https://www.freepascal.org/docs.html)
