# YAML 快速上手（fafafa.core.yaml）

本文展示如何使用门面 API（yaml_* / TYaml* / YAML_*）解析一段 YAML 文本。

## 解析器最小示例

````pascal
uses
  fafafa.core.yaml;

var
  parser: PYamlParser;
  cfg: TYamlParseCfg;
  input: PChar;
  ev: PYamlEvent;
  len: SizeUInt;
  p: PChar;
begin
  // 初始化配置（按需设置 flags）
  cfg.search_path := nil;
  cfg.flags := [YAML_PCF_RESOLVE_DOCUMENT];
  cfg.userdata := nil;
  cfg.diag := nil;

  parser := yaml_parser_create(@cfg);
  input := 'key: value';

  // 绑定输入
  if yaml_parser_set_string(parser, input, StrLen(input)) <> 0 then Halt(1);

  // 事件流：STREAM_START -> DOCUMENT_START -> MAPPING_START -> 'key' -> 'value' -> MAPPING_END -> DOCUMENT_END -> STREAM_END
  // 1) 流起始
  ev := yaml_parser_parse(parser);
  // ...正常应检查 ev^.event_type = YAML_ET_STREAM_START

  // 2) 文档起始
  ev := yaml_parser_parse(parser);
  // ...检查 YAML_ET_DOCUMENT_START

  // 3) 映射起始
  ev := yaml_parser_parse(parser);
  // ...检查 YAML_ET_MAPPING_START

  // 4) 键
  ev := yaml_parser_parse(parser);
  p := yaml_event_scalar_get_text(ev, @len);
  // p 指向 'key'，len=3

  // 5) 值
  ev := yaml_parser_parse(parser);
  p := yaml_event_scalar_get_text(ev, @len);
  // p 指向 'value'，len=5

  // 释放事件与解析器
  yaml_parser_event_free(parser, ev);
  yaml_parser_destroy(parser);
end.
````

## 规范说明
- 仅通过 `fafafa.core.yaml` 暴露的 API 使用：
  - 函数：yaml_* 前缀
  - 类型：TYaml* / PYaml*
  - 常量：YAML_*
- 内部实现（TFy*/PFy*、fy_*）不对外承诺兼容，可能变更
- 实现路线：统一采用 tokenizer（src/fafafa.core.yaml.tokenizer.pas）。历史 scan/input/scanner 栈已移除；解析事件流与示例均基于 tokenizer 驱动。


## 测试
- 运行 tests/fafafa.core.yaml/buildOrTest.bat
- 预期 55/55 测试通过，无内存泄露

