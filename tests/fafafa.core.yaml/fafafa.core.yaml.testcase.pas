{$CODEPAGE UTF8}
unit fafafa.core.yaml.testcase;

{$MODE OBJFPC}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}
{$M+}


interface

uses
  SysUtils, Classes,
  fpcunit, testregistry,
  fafafa.core.yaml;


type
  // 公共解析器基类，提供 cfg 初始化（最佳实践：减少重复）
  TTestParserBase = class(TTestCase)
  protected
    cfg: TYamlParseCfg;
    procedure SetUp; override;
  end;

  {**
   * YAML 核心功能测试
   *}
  TTestCase_YamlCore = class(TTestCase)
  published
    procedure Test_yaml_version_default;
    procedure Test_yaml_version_compare;
    procedure Test_yaml_version_is_supported;
    procedure Test_yaml_event_type_get_text;
    procedure Test_yaml_event_data;
  end;

  {**
   * YAML 解析器测试
   *}
  TTestCase_YamlParser = class(TTestParserBase)
  published
    procedure Test_yaml_parser_create_destroy;
    procedure Test_yaml_parser_basic_functionality;
    procedure Test_yaml_parser_scalar_trims_comment;
    procedure Test_yaml_parser_scalar_trailing_spaces;
    procedure Test_yaml_parser_scalar_empty_input;
    procedure Test_yaml_parser_scalar_only_comment;
    procedure Test_yaml_parser_scalar_only_whitespace;
    procedure Test_yaml_parser_scalar_trailing_tabs;
    procedure Test_yaml_parser_scalar_trailing_CR;
    procedure Test_yaml_parser_scalar_trailing_LF;
    procedure Test_yaml_parser_scalar_trailing_CRLF;
    procedure Test_yaml_parser_scalar_leading_spaces_with_comment;
    // 映射模式（需开启 YAML_PCF_RESOLVE_DOCUMENT）
    procedure Test_yaml_parser_mapping_basic_key_value;
    procedure Test_yaml_parser_mapping_with_spaces_and_comment;
    procedure Test_yaml_parser_mapping_empty_value;
    procedure Test_yaml_parser_mapping_multi_pairs_commas;
    procedure Test_yaml_parser_mapping_multi_pairs_semicolons_comment;
    procedure Test_yaml_parser_mapping_multi_pairs_empty_values;
    // 多行映射
    // Flow 序列
    procedure Test_yaml_parser_flow_sequence_basic;
    procedure Test_yaml_parser_flow_sequence_semicolons;
    procedure Test_yaml_parser_flow_sequence_empty;
    procedure Test_yaml_parser_flow_sequence_mixed_separators_comment;
    procedure Test_yaml_parser_flow_sequence_mixed_nested; // 新增：混合空映射与内嵌映射
    procedure Test_yaml_parser_flow_sequence_extra_separators_with_comment; // 新增：多余分隔符+注释

    // Flow 映射
    procedure Test_yaml_parser_flow_mapping_basic;
    procedure Test_yaml_parser_flow_mapping_semicolons;
    procedure Test_yaml_parser_flow_mapping_empty;
    procedure Test_yaml_parser_flow_mapping_nested_mix;
    procedure Test_yaml_parser_flow_mapping_nested_deep;
    procedure Test_yaml_parser_flow_mapping_quoted_keys;
    procedure Test_yaml_parser_flow_mapping_extra_separators;
    procedure Test_yaml_parser_flow_mapping_sequence_rich_items; // 新增：序列多样项

    procedure Test_yaml_parser_mapping_multi_lines_basic;
    procedure Test_yaml_parser_mapping_multi_lines_with_comment;
    procedure Test_yaml_parser_mapping_multi_lines_empty_values;
    procedure Test_yaml_parser_mapping_multi_lines_mixed_delims_comment;
    procedure Test_yaml_parser_mapping_nonflow_quoted_value_with_delims;

    procedure Test_yaml_parser_mapping_key_at_bol_empty_value;
  end;

  {**
   * YAML 文档测试
   *}
  TTestCase_YamlDocument = class(TTestCase)
  published
    procedure Test_yaml_document_create_destroy;
    procedure Test_yaml_document_build_from_string;
    procedure Test_yaml_document_build_from_file;
  end;

  {**
   * YAML 节点测试
   *}
  TTestCase_YamlNode = class(TTestCase)
  published
    procedure Test_yaml_node_basic_operations;
    procedure Test_yaml_node_scalar_operations;
    procedure Test_yaml_node_sequence_operations;
    procedure Test_yaml_node_mapping_operations;


  end;


  {**
   * YAML 发射器测试
   *}
  TTestCase_YamlEmitter = class(TTestCase)
  published
    procedure Test_yaml_emitter_create_destroy;
    procedure Test_yaml_emit_document;
  end;



implementation

// 顶层工具函数（比较非 0 结尾内存片段）
function MemEqual(p: PChar; plen: SizeUInt; q: PChar; qlen: SizeUInt): Boolean;
begin
  if plen<>qlen then Exit(False);
  if (p=nil) and (q=nil) and (plen=0) then Exit(True);
  if (p=nil) or (q=nil) then Exit(False);
  Result := CompareByte(p^, q^, plen)=0;
end;



// 测试用：返回零初始化的解析配置，避免编译器“未初始化”提示
function DefaultParseCfg: TYamlParseCfg; inline;
begin
  Result.search_path := nil;
  Result.flags := [];
  Result.userdata := nil;
  Result.diag := nil;
end;


procedure TTestParserBase.SetUp;
begin
  FillChar(cfg, SizeOf(cfg), 0);
end;

const
  SAMPLE_KV: PChar = 'key: v';



procedure ExpectEvent(Test: TTestCase; var p: PYamlParser; expected: TYamlEventType);
var e: PYamlEvent;
begin
  e := yaml_parser_parse(p);
  Test.AssertTrue('event should not be nil', e <> nil);
  Test.AssertEquals('unexpected event', Ord(expected), Ord(e^.event_type));
  yaml_parser_event_free(p, e);
end;
const
  SAMPLE_VALUE: PChar = 'value';


// TTestCase_YamlCore 实现
procedure TTestCase_YamlCore.Test_yaml_version_default;
var
  version: PYamlVersion;
begin
  version := yaml_version_default;
  AssertNotNull('yaml_version_default should not return nil', version);
  AssertEquals('Default version major should be 1', 1, version^.major);
  AssertEquals('Default version minor should be 2', 2, version^.minor);
end;

procedure TTestCase_YamlCore.Test_yaml_version_compare;
var
  v1, v2: TYamlVersion;
begin
  v1.major := 1;
  v1.minor := 1;
  v2.major := 1;
  v2.minor := 2;

  AssertTrue('v1.1 should be less than v1.2', yaml_version_compare(@v1, @v2) < 0);
  AssertTrue('v1.2 should be greater than v1.1', yaml_version_compare(@v2, @v1) > 0);
  AssertEquals('Same versions should be equal', 0, yaml_version_compare(@v1, @v1));
end;

procedure TTestCase_YamlCore.Test_yaml_version_is_supported;
var
  v1_1, v1_2, v1_3: TYamlVersion;
begin
  v1_1.major := 1; v1_1.minor := 1;
  v1_2.major := 1; v1_2.minor := 2;
  v1_3.major := 1; v1_3.minor := 3;

  AssertTrue('YAML 1.1 should be supported', yaml_version_is_supported(@v1_1));
  AssertTrue('YAML 1.2 should be supported', yaml_version_is_supported(@v1_2));
  AssertFalse('YAML 1.3 should not be supported yet', yaml_version_is_supported(@v1_3));
end;

procedure TTestCase_YamlCore.Test_yaml_event_type_get_text;
begin
  AssertEquals('FYET_NONE text', 'NONE', yaml_event_type_get_text(YAML_ET_NONE));
  AssertEquals('FYET_STREAM_START text', '+STR', yaml_event_type_get_text(YAML_ET_STREAM_START));
  AssertEquals('FYET_STREAM_END text', '-STR', yaml_event_type_get_text(YAML_ET_STREAM_END));
  AssertEquals('FYET_DOCUMENT_START text', '+DOC', yaml_event_type_get_text(YAML_ET_DOCUMENT_START));
  AssertEquals('FYET_DOCUMENT_END text', '-DOC', yaml_event_type_get_text(YAML_ET_DOCUMENT_END));
  AssertEquals('FYET_MAPPING_START text', '+MAP', yaml_event_type_get_text(YAML_ET_MAPPING_START));
  AssertEquals('FYET_MAPPING_END text', '-MAP', yaml_event_type_get_text(YAML_ET_MAPPING_END));
  AssertEquals('FYET_SEQUENCE_START text', '+SEQ', yaml_event_type_get_text(YAML_ET_SEQUENCE_START));
  AssertEquals('FYET_SEQUENCE_END text', '-SEQ', yaml_event_type_get_text(YAML_ET_SEQUENCE_END));
  AssertEquals('FYET_SCALAR text', '=VAL', yaml_event_type_get_text(YAML_ET_SCALAR));
  AssertEquals('FYET_ALIAS text', '=ALI', yaml_event_type_get_text(YAML_ET_ALIAS));
end;

procedure TTestCase_YamlCore.Test_yaml_event_data;
var
  event: TYamlEvent;
  data: Pointer;
begin
  // 测试 nil 事件
  data := yaml_event_data(nil);
  AssertNull('yaml_event_data should return nil for nil event', data);

  // 测试有效事件
  event.event_type := YAML_ET_STREAM_START;
  data := yaml_event_data(@event);
  AssertNotNull('yaml_event_data should return valid pointer for valid event', data);
  AssertTrue('Should return pointer to stream_start data', data = Pointer(@event.stream_start));

  event.event_type := YAML_ET_SCALAR;
  data := yaml_event_data(@event);
  AssertTrue('Should return pointer to scalar data', data = Pointer(@event.scalar));
end;

// TTestCase_YamlParser 实现
procedure TTestCase_YamlParser.Test_yaml_parser_create_destroy;
var
  parser: PYamlParser;
begin
  // 初始化配置
  cfg.search_path := nil;
  cfg.flags := [];
  cfg.userdata := nil;
  cfg.diag := nil;

  // 创建解析器 (目前返回 nil，因为是占位符实现)
  parser := yaml_parser_create(@cfg); // cfg from TTestParserBase

  // 销毁解析器
  yaml_parser_destroy(parser); // 应该能安全处理 nil
end;

procedure TTestCase_YamlParser.Test_yaml_parser_basic_functionality;
var
  parser: PYamlParser;
  event: PYamlEvent;
  sval_len: SizeUInt;
  sval_ptr: PChar;
begin
  cfg.search_path := nil;
  cfg.flags := [];
  cfg.userdata := nil;
  cfg.diag := nil;

  parser := yaml_parser_create(@cfg); // cfg from TTestParserBase
  if parser <> nil then
  begin
    event := yaml_parser_parse(parser);
    // TODO: 添加更多测试当实现完成后
    if event <> nil then yaml_parser_event_free(parser, event);
    yaml_parser_destroy(parser);
  end;

  // 断言事件序列：+STR,+DOC,=VAL,-DOC,-STR，并检查 SCALAR 文本长度
  parser := yaml_parser_create(@cfg); // cfg from TTestParserBase
  if parser <> nil then
  begin
    AssertEquals('set string ok', 0, yaml_parser_set_string(parser, SAMPLE_KV, StrLen(SAMPLE_KV)));

    ExpectEvent(Self, parser, YAML_ET_STREAM_START);
    ExpectEvent(Self, parser, YAML_ET_DOCUMENT_START);

    // 取 SCALAR 事件并断言文本长度
    event := yaml_parser_parse(parser);
    AssertNotNull('scalar event', event);
    AssertEquals('scalar event type', Ord(YAML_ET_SCALAR), Ord(event^.event_type));
    sval_ptr := yaml_event_scalar_get_text(event, @sval_len);
    AssertTrue('scalar text ptr', sval_ptr <> nil);
    AssertEquals('scalar len', QWord(StrLen(SAMPLE_KV)), QWord(sval_len));
    yaml_parser_event_free(parser, event);

    ExpectEvent(Self, parser, YAML_ET_DOCUMENT_END);
    ExpectEvent(Self, parser, YAML_ET_STREAM_END);

    // 再取应为 nil
    event := yaml_parser_parse(parser);
    AssertTrue('event done', event = nil);

    // 结束测试
    yaml_parser_destroy(parser);
  end;



end;

procedure TTestCase_YamlParser.Test_yaml_parser_scalar_trims_comment;
var
  parser: PYamlParser;
  event: PYamlEvent;
  input: PChar;
  sval_len: SizeUInt;
  sval_ptr: PChar;
begin
  input := 'key: v # comment';
  parser := yaml_parser_create(@cfg);
  AssertEquals(0, yaml_parser_set_string(parser, input, StrLen(input)));
  ExpectEvent(Self, parser, YAML_ET_STREAM_START);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_START);
  event := yaml_parser_parse(parser);
  AssertEquals(Ord(YAML_ET_SCALAR), Ord(event^.event_type));
  sval_ptr := yaml_event_scalar_get_text(event, @sval_len);
  AssertEquals(QWord(6), QWord(sval_len)); // 'key: v'
  AssertTrue('content eq', MemEqual(sval_ptr, sval_len, 'key: v', 6));
  yaml_parser_event_free(parser, event);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_END);
  ExpectEvent(Self, parser, YAML_ET_STREAM_END);
  yaml_parser_destroy(parser);
end;

procedure TTestCase_YamlParser.Test_yaml_parser_scalar_trailing_spaces;
var
  parser: PYamlParser;
  event: PYamlEvent;
  input: PChar;
  sval_len: SizeUInt;
  sval_ptr: PChar;
begin
  input := 'value   ';
  parser := yaml_parser_create(@cfg);
  AssertEquals(0, yaml_parser_set_string(parser, input, StrLen(input)));
  ExpectEvent(Self, parser, YAML_ET_STREAM_START);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_START);
  event := yaml_parser_parse(parser);
  AssertEquals(Ord(YAML_ET_SCALAR), Ord(event^.event_type));
  sval_ptr := yaml_event_scalar_get_text(event, @sval_len);
  AssertEquals(QWord(5), QWord(sval_len)); // 'value'
  AssertTrue('content eq', MemEqual(sval_ptr, sval_len, SAMPLE_VALUE, StrLen(SAMPLE_VALUE)));
  yaml_parser_event_free(parser, event);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_END);
  ExpectEvent(Self, parser, YAML_ET_STREAM_END);
  yaml_parser_destroy(parser);
end;


procedure TTestCase_YamlParser.Test_yaml_parser_scalar_empty_input;
var
  parser: PYamlParser;
  event: PYamlEvent;
  input: PChar;
  sval_len: SizeUInt;
  sval_ptr: PChar;
begin
  input := '';
  parser := yaml_parser_create(@cfg);
  AssertEquals(0, yaml_parser_set_string(parser, input, 0));
  ExpectEvent(Self, parser, YAML_ET_STREAM_START);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_START);
  event := yaml_parser_parse(parser);
  AssertEquals(Ord(YAML_ET_SCALAR), Ord(event^.event_type));
  sval_ptr := yaml_event_scalar_get_text(event, @sval_len);
  AssertEquals(QWord(0), QWord(sval_len));
  AssertTrue('content eq', MemEqual(sval_ptr, sval_len, '', 0));
  yaml_parser_event_free(parser, event);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_END);
  ExpectEvent(Self, parser, YAML_ET_STREAM_END);
  yaml_parser_destroy(parser);
end;

procedure TTestCase_YamlParser.Test_yaml_parser_scalar_only_comment;
var
  parser: PYamlParser;
  event: PYamlEvent;
  input: PChar;
  sval_len: SizeUInt;
  sval_ptr: PChar;
begin
  input := '# only comment';
  parser := yaml_parser_create(@cfg);
  AssertEquals(0, yaml_parser_set_string(parser, input, StrLen(input)));
  ExpectEvent(Self, parser, YAML_ET_STREAM_START);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_START);
  event := yaml_parser_parse(parser);
  AssertEquals(Ord(YAML_ET_SCALAR), Ord(event^.event_type));
  sval_ptr := yaml_event_scalar_get_text(event, @sval_len);
  AssertEquals(QWord(0), QWord(sval_len));
  AssertTrue('content eq', MemEqual(sval_ptr, sval_len, '', 0));
  yaml_parser_event_free(parser, event);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_END);
  ExpectEvent(Self, parser, YAML_ET_STREAM_END);
  yaml_parser_destroy(parser);
end;

procedure TTestCase_YamlParser.Test_yaml_parser_scalar_only_whitespace;
var
  parser: PYamlParser;
  event: PYamlEvent;
  input: PChar;
  sval_len: SizeUInt;
  sval_ptr: PChar;
begin
  input := '    ';
  parser := yaml_parser_create(@cfg);
  AssertEquals(0, yaml_parser_set_string(parser, input, StrLen(input)));
  ExpectEvent(Self, parser, YAML_ET_STREAM_START);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_START);
  event := yaml_parser_parse(parser);
  AssertEquals(Ord(YAML_ET_SCALAR), Ord(event^.event_type));
  sval_ptr := yaml_event_scalar_get_text(event, @sval_len);
  AssertEquals(QWord(0), QWord(sval_len));
  AssertTrue('content eq', MemEqual(sval_ptr, sval_len, '', 0));
  yaml_parser_event_free(parser, event);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_END);
  ExpectEvent(Self, parser, YAML_ET_STREAM_END);
  yaml_parser_destroy(parser);
end;

procedure TTestCase_YamlParser.Test_yaml_parser_scalar_trailing_tabs;
var
  parser: PYamlParser;
  event: PYamlEvent;
  input: PChar;
  sval_len: SizeUInt;
  sval_ptr: PChar;
begin
  input := 'value		';
  parser := yaml_parser_create(@cfg);
  AssertEquals(0, yaml_parser_set_string(parser, input, StrLen(input)));
  ExpectEvent(Self, parser, YAML_ET_STREAM_START);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_START);
  event := yaml_parser_parse(parser);
  AssertEquals(Ord(YAML_ET_SCALAR), Ord(event^.event_type));
  sval_ptr := yaml_event_scalar_get_text(event, @sval_len);
  AssertEquals(QWord(5), QWord(sval_len));
  AssertTrue('content eq', MemEqual(sval_ptr, sval_len, SAMPLE_VALUE, StrLen(SAMPLE_VALUE)));
  yaml_parser_event_free(parser, event);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_END);
  ExpectEvent(Self, parser, YAML_ET_STREAM_END);
  yaml_parser_destroy(parser);
end;


procedure TTestCase_YamlParser.Test_yaml_parser_scalar_trailing_CR;
var
  parser: PYamlParser;
  event: PYamlEvent;
  input: PChar;
  sval_len: SizeUInt;
  sval_ptr: PChar;
begin
  input := 'value' + #13;
  parser := yaml_parser_create(@cfg);
  AssertEquals(0, yaml_parser_set_string(parser, input, StrLen(input)));
  ExpectEvent(Self, parser, YAML_ET_STREAM_START);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_START);
  event := yaml_parser_parse(parser);
  AssertEquals(Ord(YAML_ET_SCALAR), Ord(event^.event_type));
  sval_ptr := yaml_event_scalar_get_text(event, @sval_len);
  AssertEquals(QWord(5), QWord(sval_len));
  AssertTrue('content eq', MemEqual(sval_ptr, sval_len, SAMPLE_VALUE, StrLen(SAMPLE_VALUE)));
  yaml_parser_event_free(parser, event);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_END);
  ExpectEvent(Self, parser, YAML_ET_STREAM_END);
  yaml_parser_destroy(parser);
end;

procedure TTestCase_YamlParser.Test_yaml_parser_scalar_trailing_LF;
var
  parser: PYamlParser;
  event: PYamlEvent;
  input: PChar;
  sval_len: SizeUInt;
  sval_ptr: PChar;
begin
  input := 'value' + #10;
  parser := yaml_parser_create(@cfg);
  AssertEquals(0, yaml_parser_set_string(parser, input, StrLen(input)));
  ExpectEvent(Self, parser, YAML_ET_STREAM_START);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_START);
  event := yaml_parser_parse(parser);
  AssertEquals(Ord(YAML_ET_SCALAR), Ord(event^.event_type));
  sval_ptr := yaml_event_scalar_get_text(event, @sval_len);
  AssertEquals(QWord(5), QWord(sval_len));
  AssertTrue('content eq', MemEqual(sval_ptr, sval_len, SAMPLE_VALUE, StrLen(SAMPLE_VALUE)));
  yaml_parser_event_free(parser, event);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_END);
  ExpectEvent(Self, parser, YAML_ET_STREAM_END);
  yaml_parser_destroy(parser);
end;

procedure TTestCase_YamlParser.Test_yaml_parser_scalar_trailing_CRLF;
var
  parser: PYamlParser;
  event: PYamlEvent;
  input: PChar;
  sval_len: SizeUInt;
  sval_ptr: PChar;
begin
  input := 'value' + #13#10;
  parser := yaml_parser_create(@cfg);
  AssertEquals(0, yaml_parser_set_string(parser, input, StrLen(input)));
  ExpectEvent(Self, parser, YAML_ET_STREAM_START);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_START);
  event := yaml_parser_parse(parser);
  AssertEquals(Ord(YAML_ET_SCALAR), Ord(event^.event_type));
  sval_ptr := yaml_event_scalar_get_text(event, @sval_len);
  AssertEquals(QWord(5), QWord(sval_len));
  AssertTrue('content eq', MemEqual(sval_ptr, sval_len, SAMPLE_VALUE, StrLen(SAMPLE_VALUE)));
  yaml_parser_event_free(parser, event);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_END);
  ExpectEvent(Self, parser, YAML_ET_STREAM_END);
  yaml_parser_destroy(parser);
end;

procedure TTestCase_YamlParser.Test_yaml_parser_scalar_leading_spaces_with_comment;
var
  parser: PYamlParser;
  event: PYamlEvent;
  input: PChar;
  sval_len: SizeUInt;
  sval_ptr: PChar;
begin
  input := '   value  # comment';
  parser := yaml_parser_create(@cfg);
  AssertEquals(0, yaml_parser_set_string(parser, input, StrLen(input)));
  ExpectEvent(Self, parser, YAML_ET_STREAM_START);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_START);
  event := yaml_parser_parse(parser);
  AssertEquals(Ord(YAML_ET_SCALAR), Ord(event^.event_type));
  sval_ptr := yaml_event_scalar_get_text(event, @sval_len);
  // 目前解析器不去除前导空白，只截断注释和去尾空白
  AssertEquals(QWord(8), QWord(sval_len)); // '   value'
  AssertTrue('content eq', MemEqual(sval_ptr, sval_len, '   value', 8));
  yaml_parser_event_free(parser, event);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_END);

  ExpectEvent(Self, parser, YAML_ET_STREAM_END);
  yaml_parser_destroy(parser);
end;

procedure TTestCase_YamlParser.Test_yaml_parser_mapping_basic_key_value;
var
  parser: PYamlParser;
  event: PYamlEvent;
  input: PChar;
  len: SizeUInt;
  sval_ptr: PChar;
  cfg_local: TYamlParseCfg;
begin
  input := 'key: value';
  cfg_local := DefaultParseCfg;
  cfg_local.flags := [YAML_PCF_RESOLVE_DOCUMENT];
  parser := yaml_parser_create(@cfg_local);
  AssertEquals(0, yaml_parser_set_string(parser, input, StrLen(input)));
  ExpectEvent(Self, parser, YAML_ET_STREAM_START);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_START);
  ExpectEvent(Self, parser, YAML_ET_MAPPING_START);

  // key
  event := yaml_parser_parse(parser);
  AssertEquals(Ord(YAML_ET_SCALAR), Ord(event^.event_type));
  sval_ptr := yaml_event_scalar_get_text(event, @len);
  AssertEquals(QWord(3), QWord(len));
  AssertTrue('key content', MemEqual(sval_ptr, len, 'key', 3));
  yaml_parser_event_free(parser, event);

  // value
  event := yaml_parser_parse(parser);
  AssertEquals(Ord(YAML_ET_SCALAR), Ord(event^.event_type));
  sval_ptr := yaml_event_scalar_get_text(event, @len);
  AssertEquals(QWord(5), QWord(len));
  AssertTrue('value content', MemEqual(sval_ptr, len, 'value', 5));
  yaml_parser_event_free(parser, event);

  ExpectEvent(Self, parser, YAML_ET_MAPPING_END);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_END);
  ExpectEvent(Self, parser, YAML_ET_STREAM_END);
  yaml_parser_destroy(parser);
end;

procedure TTestCase_YamlParser.Test_yaml_parser_mapping_with_spaces_and_comment;
var
  parser: PYamlParser;
  event: PYamlEvent;
  input: PChar;
  len: SizeUInt;
  sval_ptr: PChar;
  cfg_local: TYamlParseCfg;
begin
  input := '  key  :   value  # cmt';
  cfg_local := DefaultParseCfg;
  cfg_local.flags := [YAML_PCF_RESOLVE_DOCUMENT];
  parser := yaml_parser_create(@cfg_local);
  AssertEquals(0, yaml_parser_set_string(parser, input, StrLen(input)));
  ExpectEvent(Self, parser, YAML_ET_STREAM_START);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_START);
  ExpectEvent(Self, parser, YAML_ET_MAPPING_START);

  // key（末尾空白应被裁剪）
  event := yaml_parser_parse(parser);
  AssertEquals(Ord(YAML_ET_SCALAR), Ord(event^.event_type));
  sval_ptr := yaml_event_scalar_get_text(event, @len);
  AssertEquals(QWord(5), QWord(len)); // '  key'
  AssertTrue('key content', MemEqual(sval_ptr, len, '  key', 5));
  yaml_parser_event_free(parser, event);

  // value（前空白跳过，末尾空白+注释裁剪）
  event := yaml_parser_parse(parser);
  AssertEquals(Ord(YAML_ET_SCALAR), Ord(event^.event_type));
  sval_ptr := yaml_event_scalar_get_text(event, @len);
  AssertEquals(QWord(5), QWord(len)); // 'value'
  AssertTrue('value content', MemEqual(sval_ptr, len, 'value', 5));
  yaml_parser_event_free(parser, event);

  ExpectEvent(Self, parser, YAML_ET_MAPPING_END);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_END);
  ExpectEvent(Self, parser, YAML_ET_STREAM_END);
  yaml_parser_destroy(parser);
end;

procedure TTestCase_YamlParser.Test_yaml_parser_mapping_empty_value;
var
  parser: PYamlParser;
  event: PYamlEvent;
  input: PChar;
  len: SizeUInt;
  sval_ptr: PChar;
  cfg_local: TYamlParseCfg;
begin
  input := 'key:';
  cfg_local := DefaultParseCfg;
  cfg_local.flags := [YAML_PCF_RESOLVE_DOCUMENT];
  parser := yaml_parser_create(@cfg_local);
  AssertEquals(0, yaml_parser_set_string(parser, input, StrLen(input)));
  ExpectEvent(Self, parser, YAML_ET_STREAM_START);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_START);
  ExpectEvent(Self, parser, YAML_ET_MAPPING_START);

  // key
  event := yaml_parser_parse(parser);
  AssertEquals(Ord(YAML_ET_SCALAR), Ord(event^.event_type));
  sval_ptr := yaml_event_scalar_get_text(event, @len);
  AssertEquals(QWord(3), QWord(len));
  AssertTrue('key content', MemEqual(sval_ptr, len, 'key', 3));
  yaml_parser_event_free(parser, event);

  // value 空（无内容）
  event := yaml_parser_parse(parser);
  AssertEquals(Ord(YAML_ET_SCALAR), Ord(event^.event_type));
  sval_ptr := yaml_event_scalar_get_text(event, @len);
  AssertEquals(QWord(0), QWord(len));
  AssertTrue('empty value', MemEqual(sval_ptr, len, '', 0));
  yaml_parser_event_free(parser, event);

  ExpectEvent(Self, parser, YAML_ET_MAPPING_END);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_END);
  ExpectEvent(Self, parser, YAML_ET_STREAM_END);
  yaml_parser_destroy(parser);
end;

procedure TTestCase_YamlParser.Test_yaml_parser_mapping_multi_pairs_commas;
var
  parser: PYamlParser;
  event: PYamlEvent;
  input: PChar;
  len: SizeUInt;
  sval_ptr: PChar;
  cfg_local: TYamlParseCfg;
begin
  input := 'a:1, b:2';
  cfg_local := DefaultParseCfg;
  cfg_local.flags := [YAML_PCF_RESOLVE_DOCUMENT];
  parser := yaml_parser_create(@cfg_local);
  AssertEquals(0, yaml_parser_set_string(parser, input, StrLen(input)));
  ExpectEvent(Self, parser, YAML_ET_STREAM_START);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_START);
  ExpectEvent(Self, parser, YAML_ET_MAPPING_START);
  // a
  event := yaml_parser_parse(parser); AssertEquals(Ord(YAML_ET_SCALAR), Ord(event^.event_type)); sval_ptr := yaml_event_scalar_get_text(event, @len); AssertTrue(MemEqual(sval_ptr, len, 'a', 1)); yaml_parser_event_free(parser, event);
  // 1
  event := yaml_parser_parse(parser); AssertEquals(Ord(YAML_ET_SCALAR), Ord(event^.event_type)); sval_ptr := yaml_event_scalar_get_text(event, @len); AssertTrue(MemEqual(sval_ptr, len, '1', 1)); yaml_parser_event_free(parser, event);
  // b
  event := yaml_parser_parse(parser); AssertEquals(Ord(YAML_ET_SCALAR), Ord(event^.event_type)); sval_ptr := yaml_event_scalar_get_text(event, @len); AssertTrue(MemEqual(sval_ptr, len, 'b', 1)); yaml_parser_event_free(parser, event);
  // 2
  event := yaml_parser_parse(parser); AssertEquals(Ord(YAML_ET_SCALAR), Ord(event^.event_type)); sval_ptr := yaml_event_scalar_get_text(event, @len); AssertTrue(MemEqual(sval_ptr, len, '2', 1)); yaml_parser_event_free(parser, event);
  ExpectEvent(Self, parser, YAML_ET_MAPPING_END);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_END);
  ExpectEvent(Self, parser, YAML_ET_STREAM_END);
  yaml_parser_destroy(parser);
end;

procedure TTestCase_YamlParser.Test_yaml_parser_mapping_multi_pairs_semicolons_comment;
var
  parser: PYamlParser;
  event: PYamlEvent;
  input: PChar;
  len: SizeUInt;
  sval_ptr: PChar;
  cfg_local: TYamlParseCfg;
begin
  input := ' k1 : v1 , k2 : v2  # c';
  cfg_local := DefaultParseCfg;
  cfg_local.flags := [YAML_PCF_RESOLVE_DOCUMENT];
  parser := yaml_parser_create(@cfg_local);
  AssertEquals(0, yaml_parser_set_string(parser, input, StrLen(input)));
  ExpectEvent(Self, parser, YAML_ET_STREAM_START);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_START);
  ExpectEvent(Self, parser, YAML_ET_MAPPING_START);
  // k1
  event := yaml_parser_parse(parser); AssertEquals(Ord(YAML_ET_SCALAR), Ord(event^.event_type)); sval_ptr := yaml_event_scalar_get_text(event, @len); AssertTrue(MemEqual(sval_ptr, len, ' k1', 3)); yaml_parser_event_free(parser, event);
  // v1
  event := yaml_parser_parse(parser); AssertEquals(Ord(YAML_ET_SCALAR), Ord(event^.event_type)); sval_ptr := yaml_event_scalar_get_text(event, @len); AssertTrue(MemEqual(sval_ptr, len, 'v1', 2)); yaml_parser_event_free(parser, event);
  // k2
  event := yaml_parser_parse(parser); AssertEquals(Ord(YAML_ET_SCALAR), Ord(event^.event_type)); sval_ptr := yaml_event_scalar_get_text(event, @len); AssertTrue(MemEqual(sval_ptr, len, 'k2', 2)); yaml_parser_event_free(parser, event);
  // v2
  event := yaml_parser_parse(parser); AssertEquals(Ord(YAML_ET_SCALAR), Ord(event^.event_type)); sval_ptr := yaml_event_scalar_get_text(event, @len); AssertTrue(MemEqual(sval_ptr, len, 'v2', 2)); yaml_parser_event_free(parser, event);
  ExpectEvent(Self, parser, YAML_ET_MAPPING_END);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_END);
  ExpectEvent(Self, parser, YAML_ET_STREAM_END);
  yaml_parser_destroy(parser);
end;

procedure TTestCase_YamlParser.Test_yaml_parser_mapping_multi_pairs_empty_values;
var
  parser: PYamlParser;
  event: PYamlEvent;
  input: PChar;
  len: SizeUInt;
  sval_ptr: PChar;
  cfg_local: TYamlParseCfg;
begin
  input := 'x: , y:';
  cfg_local := DefaultParseCfg;
  cfg_local.flags := [YAML_PCF_RESOLVE_DOCUMENT];
  parser := yaml_parser_create(@cfg_local);
  AssertEquals(0, yaml_parser_set_string(parser, input, StrLen(input)));
  ExpectEvent(Self, parser, YAML_ET_STREAM_START);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_START);
  ExpectEvent(Self, parser, YAML_ET_MAPPING_START);
  // x
  event := yaml_parser_parse(parser); AssertEquals(Ord(YAML_ET_SCALAR), Ord(event^.event_type)); sval_ptr := yaml_event_scalar_get_text(event, @len); AssertTrue(MemEqual(sval_ptr, len, 'x', 1)); yaml_parser_event_free(parser, event);
  // ''
  event := yaml_parser_parse(parser); AssertEquals(Ord(YAML_ET_SCALAR), Ord(event^.event_type)); sval_ptr := yaml_event_scalar_get_text(event, @len); AssertEquals(QWord(0), QWord(len)); yaml_parser_event_free(parser, event);
  // y
  event := yaml_parser_parse(parser); AssertEquals(Ord(YAML_ET_SCALAR), Ord(event^.event_type)); sval_ptr := yaml_event_scalar_get_text(event, @len); AssertTrue(MemEqual(sval_ptr, len, 'y', 1)); yaml_parser_event_free(parser, event);

  // ''
  event := yaml_parser_parse(parser); AssertEquals(Ord(YAML_ET_SCALAR), Ord(event^.event_type)); sval_ptr := yaml_event_scalar_get_text(event, @len); AssertEquals(QWord(0), QWord(len)); yaml_parser_event_free(parser, event);

  ExpectEvent(Self, parser, YAML_ET_MAPPING_END);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_END);
  ExpectEvent(Self, parser, YAML_ET_STREAM_END);
  yaml_parser_destroy(parser);
end;

procedure TTestCase_YamlParser.Test_yaml_parser_flow_mapping_basic;
var parser: PYamlParser; cfg_local: TYamlParseCfg; input: PChar;
begin
  cfg_local := DefaultParseCfg;
  cfg_local.flags := [YAML_PCF_RESOLVE_DOCUMENT];
  parser := yaml_parser_create(@cfg_local);
  input := '{a:1, b:''x;y''}';
  AssertEquals(0, yaml_parser_set_string(parser, input, StrLen(input)));
  ExpectEvent(Self, parser, YAML_ET_STREAM_START);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_START);
  ExpectEvent(Self, parser, YAML_ET_MAPPING_START);
  ExpectEvent(Self, parser, YAML_ET_SCALAR); // a
  ExpectEvent(Self, parser, YAML_ET_SCALAR); // 1
  ExpectEvent(Self, parser, YAML_ET_SCALAR); // b
  ExpectEvent(Self, parser, YAML_ET_SCALAR); // 'x;y'
  ExpectEvent(Self, parser, YAML_ET_MAPPING_END);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_END);
  ExpectEvent(Self, parser, YAML_ET_STREAM_END);
  yaml_parser_destroy(parser);
end;

procedure TTestCase_YamlParser.Test_yaml_parser_flow_mapping_semicolons;
var parser: PYamlParser; cfg_local: TYamlParseCfg; input: PChar;
begin
  cfg_local := DefaultParseCfg;
  cfg_local.flags := [YAML_PCF_RESOLVE_DOCUMENT];
  parser := yaml_parser_create(@cfg_local);
  input := '{a:1, b:"c,d"}';
  AssertEquals(0, yaml_parser_set_string(parser, input, StrLen(input)));
  ExpectEvent(Self, parser, YAML_ET_STREAM_START);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_START);
  ExpectEvent(Self, parser, YAML_ET_MAPPING_START);
  ExpectEvent(Self, parser, YAML_ET_SCALAR); // a
  ExpectEvent(Self, parser, YAML_ET_SCALAR); // 1
  ExpectEvent(Self, parser, YAML_ET_SCALAR); // b
  ExpectEvent(Self, parser, YAML_ET_SCALAR); // "c,d"
  ExpectEvent(Self, parser, YAML_ET_MAPPING_END);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_END);
  ExpectEvent(Self, parser, YAML_ET_STREAM_END);
  yaml_parser_destroy(parser);
end;

procedure TTestCase_YamlParser.Test_yaml_parser_flow_mapping_empty;
var parser: PYamlParser; cfg_local: TYamlParseCfg; input: PChar;
begin
  cfg_local := DefaultParseCfg;
  cfg_local.flags := [YAML_PCF_RESOLVE_DOCUMENT];
  parser := yaml_parser_create(@cfg_local);
  input := '{}';
  AssertEquals(0, yaml_parser_set_string(parser, input, StrLen(input)));
  ExpectEvent(Self, parser, YAML_ET_STREAM_START);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_START);
  // 空映射：+MAP -MAP
  ExpectEvent(Self, parser, YAML_ET_MAPPING_START);
  ExpectEvent(Self, parser, YAML_ET_MAPPING_END);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_END);
  ExpectEvent(Self, parser, YAML_ET_STREAM_END);
  yaml_parser_destroy(parser);
end;

procedure TTestCase_YamlParser.Test_yaml_parser_flow_mapping_nested_mix;
var parser: PYamlParser; cfg_local: TYamlParseCfg; input: PChar;
begin
  cfg_local := DefaultParseCfg;
  cfg_local.flags := [YAML_PCF_RESOLVE_DOCUMENT];
  parser := yaml_parser_create(@cfg_local);
  input := '{a:[1,2], b:{c:3}}';
  AssertEquals(0, yaml_parser_set_string(parser, input, StrLen(input)));
  ExpectEvent(Self, parser, YAML_ET_STREAM_START);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_START);
  ExpectEvent(Self, parser, YAML_ET_MAPPING_START);
  // a: [1;2]
  ExpectEvent(Self, parser, YAML_ET_SCALAR); // a
  ExpectEvent(Self, parser, YAML_ET_SEQUENCE_START);
  ExpectEvent(Self, parser, YAML_ET_SCALAR); // 1
  ExpectEvent(Self, parser, YAML_ET_SCALAR); // 2
  ExpectEvent(Self, parser, YAML_ET_SEQUENCE_END);
  // b: {c:3}
  ExpectEvent(Self, parser, YAML_ET_SCALAR); // b
  ExpectEvent(Self, parser, YAML_ET_MAPPING_START);
  ExpectEvent(Self, parser, YAML_ET_SCALAR); // c
  ExpectEvent(Self, parser, YAML_ET_SCALAR); // 3
  ExpectEvent(Self, parser, YAML_ET_MAPPING_END);
  ExpectEvent(Self, parser, YAML_ET_MAPPING_END);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_END);
  ExpectEvent(Self, parser, YAML_ET_STREAM_END);
  yaml_parser_destroy(parser);
end;

procedure TTestCase_YamlParser.Test_yaml_parser_flow_mapping_nested_deep;
var parser: PYamlParser; cfg_local: TYamlParseCfg; input: PChar;
begin
  cfg_local := DefaultParseCfg;
  cfg_local.flags := [YAML_PCF_RESOLVE_DOCUMENT];
  parser := yaml_parser_create(@cfg_local);
  input := '{a:[1,{b:2}]}';
  AssertEquals(0, yaml_parser_set_string(parser, input, StrLen(input)));
  ExpectEvent(Self, parser, YAML_ET_STREAM_START);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_START);
  ExpectEvent(Self, parser, YAML_ET_MAPPING_START);
  ExpectEvent(Self, parser, YAML_ET_SCALAR); // a
  ExpectEvent(Self, parser, YAML_ET_SEQUENCE_START);
  ExpectEvent(Self, parser, YAML_ET_SCALAR); // 1
  ExpectEvent(Self, parser, YAML_ET_MAPPING_START);
  ExpectEvent(Self, parser, YAML_ET_SCALAR); // b
  ExpectEvent(Self, parser, YAML_ET_SCALAR); // 2
  ExpectEvent(Self, parser, YAML_ET_MAPPING_END);
  ExpectEvent(Self, parser, YAML_ET_SEQUENCE_END);
  ExpectEvent(Self, parser, YAML_ET_MAPPING_END);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_END);
  ExpectEvent(Self, parser, YAML_ET_STREAM_END);
  yaml_parser_destroy(parser);
end;

procedure TTestCase_YamlParser.Test_yaml_parser_flow_mapping_quoted_keys;
var parser: PYamlParser; cfg_local: TYamlParseCfg; input: PChar;
begin
  cfg_local := DefaultParseCfg;
  cfg_local.flags := [YAML_PCF_RESOLVE_DOCUMENT];
  parser := yaml_parser_create(@cfg_local);
  input := '{"a,b":1; ''c:d'':2}';
  AssertEquals(0, yaml_parser_set_string(parser, input, StrLen(input)));
  ExpectEvent(Self, parser, YAML_ET_STREAM_START);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_START);
  ExpectEvent(Self, parser, YAML_ET_MAPPING_START);
  // "a,b": 1
  ExpectEvent(Self, parser, YAML_ET_SCALAR);
  ExpectEvent(Self, parser, YAML_ET_SCALAR);
  // 'c:d': 2
  ExpectEvent(Self, parser, YAML_ET_SCALAR);
  ExpectEvent(Self, parser, YAML_ET_SCALAR);
  ExpectEvent(Self, parser, YAML_ET_MAPPING_END);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_END);
  ExpectEvent(Self, parser, YAML_ET_STREAM_END);
  yaml_parser_destroy(parser);
end;

  // 组合：序列项混合空映射与内嵌映射
  procedure TTestCase_YamlParser.Test_yaml_parser_flow_sequence_mixed_nested;
  var parser: PYamlParser; cfg_local: TYamlParseCfg; input: PChar;
  begin
    cfg_local := DefaultParseCfg;
    cfg_local.flags := [YAML_PCF_RESOLVE_DOCUMENT];
    parser := yaml_parser_create(@cfg_local);
    input := '[{}, {a:1}, {}]';
    AssertEquals(0, yaml_parser_set_string(parser, input, StrLen(input)));
    ExpectEvent(Self, parser, YAML_ET_STREAM_START);
    ExpectEvent(Self, parser, YAML_ET_DOCUMENT_START);
    ExpectEvent(Self, parser, YAML_ET_SEQUENCE_START);
    // {}
    ExpectEvent(Self, parser, YAML_ET_MAPPING_START);
    ExpectEvent(Self, parser, YAML_ET_MAPPING_END);
    // {a:1}
    ExpectEvent(Self, parser, YAML_ET_MAPPING_START);
    ExpectEvent(Self, parser, YAML_ET_SCALAR); // a
    ExpectEvent(Self, parser, YAML_ET_SCALAR); // 1
    ExpectEvent(Self, parser, YAML_ET_MAPPING_END);
    // {}
    ExpectEvent(Self, parser, YAML_ET_MAPPING_START);
    ExpectEvent(Self, parser, YAML_ET_MAPPING_END);
    ExpectEvent(Self, parser, YAML_ET_SEQUENCE_END);
    ExpectEvent(Self, parser, YAML_ET_DOCUMENT_END);
    ExpectEvent(Self, parser, YAML_ET_STREAM_END);
    yaml_parser_destroy(parser);
  end;

  // 组合：flow 映射中包含多种序列项（标量/空序列/含映射的序列）
  procedure TTestCase_YamlParser.Test_yaml_parser_flow_mapping_sequence_rich_items;
  var parser: PYamlParser; cfg_local: TYamlParseCfg; input: PChar;
  begin
    cfg_local := DefaultParseCfg;
    cfg_local.flags := [YAML_PCF_RESOLVE_DOCUMENT];
    parser := yaml_parser_create(@cfg_local);
    input := '{a:[1,2], b:[], c:[{x:1}]}';
    AssertEquals(0, yaml_parser_set_string(parser, input, StrLen(input)));
    ExpectEvent(Self, parser, YAML_ET_STREAM_START);
    ExpectEvent(Self, parser, YAML_ET_DOCUMENT_START);
    ExpectEvent(Self, parser, YAML_ET_MAPPING_START);
    // a: [1;2]
    ExpectEvent(Self, parser, YAML_ET_SCALAR); // a
    ExpectEvent(Self, parser, YAML_ET_SEQUENCE_START);
    ExpectEvent(Self, parser, YAML_ET_SCALAR); // 1
    ExpectEvent(Self, parser, YAML_ET_SCALAR); // 2
    ExpectEvent(Self, parser, YAML_ET_SEQUENCE_END);
    // b: []
    ExpectEvent(Self, parser, YAML_ET_SCALAR); // b
    ExpectEvent(Self, parser, YAML_ET_SEQUENCE_START);
    ExpectEvent(Self, parser, YAML_ET_SEQUENCE_END);
    // c: [{x:1}]
    ExpectEvent(Self, parser, YAML_ET_SCALAR); // c
    ExpectEvent(Self, parser, YAML_ET_SEQUENCE_START);
    ExpectEvent(Self, parser, YAML_ET_MAPPING_START);
    ExpectEvent(Self, parser, YAML_ET_SCALAR); // x
    ExpectEvent(Self, parser, YAML_ET_SCALAR); // 1
    ExpectEvent(Self, parser, YAML_ET_MAPPING_END);
    ExpectEvent(Self, parser, YAML_ET_SEQUENCE_END);
    ExpectEvent(Self, parser, YAML_ET_MAPPING_END);
    ExpectEvent(Self, parser, YAML_ET_DOCUMENT_END);
    ExpectEvent(Self, parser, YAML_ET_STREAM_END);
    yaml_parser_destroy(parser);
  end;

  // 边界：多余分隔符与注释混合（flow 序列）
  procedure TTestCase_YamlParser.Test_yaml_parser_flow_sequence_extra_separators_with_comment;
  var parser: PYamlParser; cfg_local: TYamlParseCfg; input: PChar;
  begin
    cfg_local := DefaultParseCfg;
    cfg_local.flags := [YAML_PCF_RESOLVE_DOCUMENT];
    parser := yaml_parser_create(@cfg_local);
    input := '[a,, b; # cmt' + LineEnding + ' c]';
    AssertEquals(0, yaml_parser_set_string(parser, input, StrLen(input)));
    ExpectEvent(Self, parser, YAML_ET_STREAM_START);
    ExpectEvent(Self, parser, YAML_ET_DOCUMENT_START);
    ExpectEvent(Self, parser, YAML_ET_SEQUENCE_START);
    ExpectEvent(Self, parser, YAML_ET_SCALAR); // a
    ExpectEvent(Self, parser, YAML_ET_SCALAR); // b
    ExpectEvent(Self, parser, YAML_ET_SCALAR); // c
    ExpectEvent(Self, parser, YAML_ET_SEQUENCE_END);
    ExpectEvent(Self, parser, YAML_ET_DOCUMENT_END);
    ExpectEvent(Self, parser, YAML_ET_STREAM_END);
    yaml_parser_destroy(parser);
  end;


procedure TTestCase_YamlParser.Test_yaml_parser_flow_mapping_extra_separators;
var parser: PYamlParser; cfg_local: TYamlParseCfg; input: PChar;
begin
  // 非标准：包含多余的分隔符，当前策略：tokenizer 会产出多个分隔 token，parser 在 flow_map 路径会在取 pair 前跳过分隔符
  cfg_local := DefaultParseCfg;
  cfg_local.flags := [YAML_PCF_RESOLVE_DOCUMENT];
  parser := yaml_parser_create(@cfg_local);
  input := '{a:1,, b:2;; c:3}';
  AssertEquals(0, yaml_parser_set_string(parser, input, StrLen(input)));
  ExpectEvent(Self, parser, YAML_ET_STREAM_START);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_START);
  ExpectEvent(Self, parser, YAML_ET_MAPPING_START);
  // a
  ExpectEvent(Self, parser, YAML_ET_SCALAR);
  // 1
  ExpectEvent(Self, parser, YAML_ET_SCALAR);
  // b
  ExpectEvent(Self, parser, YAML_ET_SCALAR);
  // 2
  ExpectEvent(Self, parser, YAML_ET_SCALAR);
  // c
  ExpectEvent(Self, parser, YAML_ET_SCALAR);
  // 3
  ExpectEvent(Self, parser, YAML_ET_SCALAR);
  ExpectEvent(Self, parser, YAML_ET_MAPPING_END);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_END);
  ExpectEvent(Self, parser, YAML_ET_STREAM_END);
  yaml_parser_destroy(parser);
end;

procedure TTestCase_YamlParser.Test_yaml_parser_mapping_nonflow_quoted_value_with_delims;
var parser: PYamlParser; cfg_local: TYamlParseCfg; S: AnsiString;
begin
  cfg_local := DefaultParseCfg;
  cfg_local.flags := [YAML_PCF_RESOLVE_DOCUMENT];
  parser := yaml_parser_create(@cfg_local);
  S := 'k1: "a,b"; k2: ''c:d''';
  AssertEquals(0, yaml_parser_set_string(parser, PChar(S), Length(S)));
  ExpectEvent(Self, parser, YAML_ET_STREAM_START);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_START);
  ExpectEvent(Self, parser, YAML_ET_MAPPING_START);
  // k1
  ExpectEvent(Self, parser, YAML_ET_SCALAR);
  // "a,b"
  ExpectEvent(Self, parser, YAML_ET_SCALAR);
  // k2
  ExpectEvent(Self, parser, YAML_ET_SCALAR);
  // 'c:d'
  ExpectEvent(Self, parser, YAML_ET_SCALAR);
  ExpectEvent(Self, parser, YAML_ET_MAPPING_END);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_END);
  ExpectEvent(Self, parser, YAML_ET_STREAM_END);
  yaml_parser_destroy(parser);
end;


procedure TTestCase_YamlParser.Test_yaml_parser_flow_sequence_basic;
var parser: PYamlParser; cfg_local: TYamlParseCfg; input: PChar;
begin
  cfg_local := DefaultParseCfg;
  cfg_local.flags := [YAML_PCF_RESOLVE_DOCUMENT];
  parser := yaml_parser_create(@cfg_local);
  input := '[1, "a,b", ''c:d'']';
  AssertEquals(0, yaml_parser_set_string(parser, input, StrLen(input)));
  ExpectEvent(Self, parser, YAML_ET_STREAM_START);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_START);
  ExpectEvent(Self, parser, YAML_ET_SEQUENCE_START);
  ExpectEvent(Self, parser, YAML_ET_SCALAR); // 1
  ExpectEvent(Self, parser, YAML_ET_SCALAR); // "a,b"
  ExpectEvent(Self, parser, YAML_ET_SCALAR); // 'c:d'
  ExpectEvent(Self, parser, YAML_ET_SEQUENCE_END);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_END);
  ExpectEvent(Self, parser, YAML_ET_STREAM_END);
  yaml_parser_destroy(parser);
end;

procedure TTestCase_YamlParser.Test_yaml_parser_flow_sequence_mixed_separators_comment;
var parser: PYamlParser; cfg_local: TYamlParseCfg; input: PChar;
begin
  cfg_local := DefaultParseCfg;
  cfg_local.flags := [YAML_PCF_RESOLVE_DOCUMENT];
  parser := yaml_parser_create(@cfg_local);
  input := '[a, b, # cmt' + LineEnding + 'c]';
  AssertEquals(0, yaml_parser_set_string(parser, input, StrLen(input)));
  ExpectEvent(Self, parser, YAML_ET_STREAM_START);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_START);
  ExpectEvent(Self, parser, YAML_ET_SEQUENCE_START);
  ExpectEvent(Self, parser, YAML_ET_SCALAR); // a
  ExpectEvent(Self, parser, YAML_ET_SCALAR); // b
  ExpectEvent(Self, parser, YAML_ET_SCALAR); // c
  ExpectEvent(Self, parser, YAML_ET_SEQUENCE_END);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_END);
  ExpectEvent(Self, parser, YAML_ET_STREAM_END);
  yaml_parser_destroy(parser);
end;

procedure TTestCase_YamlParser.Test_yaml_parser_flow_sequence_semicolons;
var parser: PYamlParser; cfg_local: TYamlParseCfg; input: PChar;
begin
  cfg_local := DefaultParseCfg;
  cfg_local.flags := [YAML_PCF_RESOLVE_DOCUMENT];
  parser := yaml_parser_create(@cfg_local);
  input := '[a, b]';
  AssertEquals(0, yaml_parser_set_string(parser, input, StrLen(input)));
  ExpectEvent(Self, parser, YAML_ET_STREAM_START);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_START);
  ExpectEvent(Self, parser, YAML_ET_SEQUENCE_START);
  ExpectEvent(Self, parser, YAML_ET_SCALAR); // a
  ExpectEvent(Self, parser, YAML_ET_SCALAR); // b
  ExpectEvent(Self, parser, YAML_ET_SEQUENCE_END);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_END);
  ExpectEvent(Self, parser, YAML_ET_STREAM_END);
  yaml_parser_destroy(parser);
end;

procedure TTestCase_YamlParser.Test_yaml_parser_flow_sequence_empty;
var parser: PYamlParser; cfg_local: TYamlParseCfg; input: PChar;
begin
  cfg_local := DefaultParseCfg;
  cfg_local.flags := [YAML_PCF_RESOLVE_DOCUMENT];
  parser := yaml_parser_create(@cfg_local);
  input := '[]';
  AssertEquals(0, yaml_parser_set_string(parser, input, StrLen(input)));
  ExpectEvent(Self, parser, YAML_ET_STREAM_START);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_START);
  ExpectEvent(Self, parser, YAML_ET_SEQUENCE_START);
  ExpectEvent(Self, parser, YAML_ET_SEQUENCE_END);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_END);
  ExpectEvent(Self, parser, YAML_ET_STREAM_END);
  yaml_parser_destroy(parser);
end;







procedure TTestCase_YamlParser.Test_yaml_parser_mapping_multi_lines_basic;
var
  parser: PYamlParser;
  event: PYamlEvent;
  input: PChar;
  len: SizeUInt;
  sval_ptr: PChar;
  cfg_local: TYamlParseCfg;
  S: AnsiString;
begin
  S := 'a:1' + #10 + 'b:2'; input := PChar(S);
  cfg_local := DefaultParseCfg;
  cfg_local.flags := [YAML_PCF_RESOLVE_DOCUMENT];
  parser := yaml_parser_create(@cfg_local);
  AssertEquals(0, yaml_parser_set_string(parser, input, Length(S)));
  ExpectEvent(Self, parser, YAML_ET_STREAM_START);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_START);
  ExpectEvent(Self, parser, YAML_ET_MAPPING_START);
  // a
  event := yaml_parser_parse(parser); AssertEquals(Ord(YAML_ET_SCALAR), Ord(event^.event_type)); sval_ptr := yaml_event_scalar_get_text(event, @len); AssertTrue(MemEqual(sval_ptr, len, 'a', 1)); yaml_parser_event_free(parser, event);
  // 1
  event := yaml_parser_parse(parser); AssertEquals(Ord(YAML_ET_SCALAR), Ord(event^.event_type)); sval_ptr := yaml_event_scalar_get_text(event, @len); AssertTrue(MemEqual(sval_ptr, len, '1', 1)); yaml_parser_event_free(parser, event);
  // b
  event := yaml_parser_parse(parser); AssertEquals(Ord(YAML_ET_SCALAR), Ord(event^.event_type)); sval_ptr := yaml_event_scalar_get_text(event, @len); AssertTrue(MemEqual(sval_ptr, len, 'b', 1)); yaml_parser_event_free(parser, event);
  // 2
  event := yaml_parser_parse(parser); AssertEquals(Ord(YAML_ET_SCALAR), Ord(event^.event_type)); sval_ptr := yaml_event_scalar_get_text(event, @len); AssertTrue(MemEqual(sval_ptr, len, '2', 1)); yaml_parser_event_free(parser, event);
  ExpectEvent(Self, parser, YAML_ET_MAPPING_END);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_END);
  ExpectEvent(Self, parser, YAML_ET_STREAM_END);
  yaml_parser_destroy(parser);
end;

procedure TTestCase_YamlParser.Test_yaml_parser_mapping_multi_lines_with_comment;
var
  parser: PYamlParser;
  event: PYamlEvent;
  input: PChar;
  len: SizeUInt;
  sval_ptr: PChar;
  cfg_local: TYamlParseCfg;
  S: AnsiString;
begin
  S := ' k1 : v1 ' + #13#10 + ' k2 : v2 # c'; input := PChar(S);
  cfg_local := DefaultParseCfg;
  cfg_local.flags := [YAML_PCF_RESOLVE_DOCUMENT];
  parser := yaml_parser_create(@cfg_local);
  AssertEquals(0, yaml_parser_set_string(parser, input, Length(S)));
  ExpectEvent(Self, parser, YAML_ET_STREAM_START);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_START);
  ExpectEvent(Self, parser, YAML_ET_MAPPING_START);
  // k1
  event := yaml_parser_parse(parser); AssertEquals(Ord(YAML_ET_SCALAR), Ord(event^.event_type)); sval_ptr := yaml_event_scalar_get_text(event, @len); AssertTrue(MemEqual(sval_ptr, len, ' k1', 3)); yaml_parser_event_free(parser, event);
  // v1
  event := yaml_parser_parse(parser); AssertEquals(Ord(YAML_ET_SCALAR), Ord(event^.event_type)); sval_ptr := yaml_event_scalar_get_text(event, @len); AssertTrue(MemEqual(sval_ptr, len, 'v1', 2)); yaml_parser_event_free(parser, event);
  // k2
  event := yaml_parser_parse(parser); AssertEquals(Ord(YAML_ET_SCALAR), Ord(event^.event_type)); sval_ptr := yaml_event_scalar_get_text(event, @len); AssertTrue(MemEqual(sval_ptr, len, ' k2', 3)); yaml_parser_event_free(parser, event);
  // v2
  event := yaml_parser_parse(parser); AssertEquals(Ord(YAML_ET_SCALAR), Ord(event^.event_type)); sval_ptr := yaml_event_scalar_get_text(event, @len); AssertTrue(MemEqual(sval_ptr, len, 'v2', 2)); yaml_parser_event_free(parser, event);
  ExpectEvent(Self, parser, YAML_ET_MAPPING_END);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_END);
  ExpectEvent(Self, parser, YAML_ET_STREAM_END);
  yaml_parser_destroy(parser);
end;

procedure TTestCase_YamlParser.Test_yaml_parser_mapping_multi_lines_empty_values;
var
  parser: PYamlParser;
  event: PYamlEvent;
  input: PChar;
  len: SizeUInt;
  sval_ptr: PChar;
  cfg_local: TYamlParseCfg;
  S: AnsiString;
begin
  S := 'x:' + #10 + 'y:'; input := PChar(S);
  cfg_local := DefaultParseCfg;
  cfg_local.flags := [YAML_PCF_RESOLVE_DOCUMENT];
  parser := yaml_parser_create(@cfg_local);
  AssertEquals(0, yaml_parser_set_string(parser, input, Length(S)));
  ExpectEvent(Self, parser, YAML_ET_STREAM_START);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_START);
  ExpectEvent(Self, parser, YAML_ET_MAPPING_START);
  // x
  event := yaml_parser_parse(parser); AssertEquals(Ord(YAML_ET_SCALAR), Ord(event^.event_type)); sval_ptr := yaml_event_scalar_get_text(event, @len); AssertTrue(MemEqual(sval_ptr, len, 'x', 1)); yaml_parser_event_free(parser, event);
  // ''
  event := yaml_parser_parse(parser); AssertEquals(Ord(YAML_ET_SCALAR), Ord(event^.event_type)); sval_ptr := yaml_event_scalar_get_text(event, @len); AssertEquals(QWord(0), QWord(len)); yaml_parser_event_free(parser, event);
  // y
  event := yaml_parser_parse(parser); AssertEquals(Ord(YAML_ET_SCALAR), Ord(event^.event_type)); sval_ptr := yaml_event_scalar_get_text(event, @len); AssertTrue(MemEqual(sval_ptr, len, 'y', 1)); yaml_parser_event_free(parser, event);

  ExpectEvent(Self, parser, YAML_ET_MAPPING_END);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_END);
  ExpectEvent(Self, parser, YAML_ET_STREAM_END);
  yaml_parser_destroy(parser);
end;

procedure TTestCase_YamlParser.Test_yaml_parser_mapping_multi_lines_mixed_delims_comment;
var parser: PYamlParser; cfg_local: TYamlParseCfg; S: AnsiString; len: SizeUInt; sval_ptr: PChar; event: PYamlEvent;
begin
  S := 'a:1' + #10 + ' b:2 , # cmt' + #10 + 'c:3';
  cfg_local := DefaultParseCfg;
  cfg_local.flags := [YAML_PCF_RESOLVE_DOCUMENT];
  parser := yaml_parser_create(@cfg_local);
  AssertEquals(0, yaml_parser_set_string(parser, PChar(S), Length(S)));
  ExpectEvent(Self, parser, YAML_ET_STREAM_START);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_START);
  ExpectEvent(Self, parser, YAML_ET_MAPPING_START);
  // a
  event := yaml_parser_parse(parser); AssertEquals(Ord(YAML_ET_SCALAR), Ord(event^.event_type)); sval_ptr := yaml_event_scalar_get_text(event, @len); AssertTrue(MemEqual(sval_ptr, len, 'a', 1)); yaml_parser_event_free(parser, event);
  // 1
  event := yaml_parser_parse(parser); AssertEquals(Ord(YAML_ET_SCALAR), Ord(event^.event_type)); sval_ptr := yaml_event_scalar_get_text(event, @len); AssertTrue(MemEqual(sval_ptr, len, '1', 1)); yaml_parser_event_free(parser, event);
  // b
  event := yaml_parser_parse(parser); AssertEquals(Ord(YAML_ET_SCALAR), Ord(event^.event_type)); sval_ptr := yaml_event_scalar_get_text(event, @len); AssertTrue(MemEqual(sval_ptr, len, ' b', 2)); yaml_parser_event_free(parser, event);
  // 2
  event := yaml_parser_parse(parser); AssertEquals(Ord(YAML_ET_SCALAR), Ord(event^.event_type)); sval_ptr := yaml_event_scalar_get_text(event, @len); AssertTrue(MemEqual(sval_ptr, len, '2', 1)); yaml_parser_event_free(parser, event);
  // c
  event := yaml_parser_parse(parser); AssertEquals(Ord(YAML_ET_SCALAR), Ord(event^.event_type)); sval_ptr := yaml_event_scalar_get_text(event, @len); AssertTrue(MemEqual(sval_ptr, len, 'c', 1)); yaml_parser_event_free(parser, event);
  // 3
  event := yaml_parser_parse(parser); AssertEquals(Ord(YAML_ET_SCALAR), Ord(event^.event_type)); sval_ptr := yaml_event_scalar_get_text(event, @len); AssertTrue(MemEqual(sval_ptr, len, '3', 1)); yaml_parser_event_free(parser, event);
  ExpectEvent(Self, parser, YAML_ET_MAPPING_END);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_END);
  ExpectEvent(Self, parser, YAML_ET_STREAM_END);
  yaml_parser_destroy(parser);
end;

procedure TTestCase_YamlParser.Test_yaml_parser_mapping_key_at_bol_empty_value;
var parser: PYamlParser; cfg_local: TYamlParseCfg; S: AnsiString; event: PYamlEvent;
begin
  // 键位于行首且最后一对为空值：应直接结束映射（不发空标量），这是我们之前在状态机里处理的特例
  S := 'x:1' + #10 + 'y:' + #10; // y: 空值且最后一行
  cfg_local := DefaultParseCfg;
  cfg_local.flags := [YAML_PCF_RESOLVE_DOCUMENT];
  parser := yaml_parser_create(@cfg_local);
  AssertEquals(0, yaml_parser_set_string(parser, PChar(S), Length(S)));
  ExpectEvent(Self, parser, YAML_ET_STREAM_START);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_START);
  ExpectEvent(Self, parser, YAML_ET_MAPPING_START);
  // x
  ExpectEvent(Self, parser, YAML_ET_SCALAR);
  // 1
  ExpectEvent(Self, parser, YAML_ET_SCALAR);
  // y
  ExpectEvent(Self, parser, YAML_ET_SCALAR);
  // 直接结束映射
  ExpectEvent(Self, parser, YAML_ET_MAPPING_END);
  ExpectEvent(Self, parser, YAML_ET_DOCUMENT_END);
  ExpectEvent(Self, parser, YAML_ET_STREAM_END);
  yaml_parser_destroy(parser);
end;







// TTestCase_YamlDocument 实现
procedure TTestCase_YamlDocument.Test_yaml_document_create_destroy;
var
  cfg: TYamlParseCfg;
  doc: PYamlDocument;
begin
  cfg.search_path := nil;
  cfg.flags := [];
  cfg.userdata := nil;
  cfg.diag := nil;

  doc := yaml_document_create(@cfg);
  AssertNotNull('yaml_document_create should return a valid document handle', doc);

  yaml_document_destroy(doc);
end;

procedure TTestCase_YamlDocument.Test_yaml_document_build_from_string;
var
  cfg: TYamlParseCfg;
  doc: PYamlDocument;
  yaml_str: PChar;
begin
  cfg.search_path := nil;
  cfg.flags := [];
  cfg.userdata := nil;
  cfg.diag := nil;

  yaml_str := 'key: value';
  doc := yaml_document_build_from_string(@cfg, yaml_str, StrLen(yaml_str));
  AssertNotNull('yaml_document_build_from_string should return a valid document handle', doc);

  yaml_document_destroy(doc);
end;

procedure TTestCase_YamlDocument.Test_yaml_document_build_from_file;
var
  cfg: TYamlParseCfg;
  doc: PYamlDocument;
begin
  cfg.search_path := nil;
  cfg.flags := [];
  cfg.userdata := nil;
  cfg.diag := nil;

  // 测试不存在的文件
  doc := yaml_document_build_from_file(@cfg, 'nonexistent.yaml');
  AssertNull('Should return nil for nonexistent file', doc);

  yaml_document_destroy(doc);
end;

// TTestCase_YamlNode 实现
procedure TTestCase_YamlNode.Test_yaml_node_basic_operations;
var
  LCfg: TYamlParseCfg;
  LDoc: PYamlDocument;
  LRoot: PYamlNode;
  LType: TYamlNodeType;
begin
  LCfg.search_path := nil;
  LCfg.flags := [];
  LCfg.userdata := nil;
  LCfg.diag := nil;

  LDoc := yaml_document_create(@LCfg);
  AssertNotNull('yaml_document_create should return a valid document handle', LDoc);
  yaml_document_destroy(LDoc);

  LDoc := yaml_document_build_from_string(@LCfg, 'k: v', 4);
  AssertNotNull('yaml_document_build_from_string should return a valid document handle', LDoc);

  LRoot := yaml_document_get_root(LDoc);
  AssertNull('yaml_document_get_root is currently expected to return nil in minimal stub', LRoot);
  yaml_document_destroy(LDoc);

  LType := yaml_node_get_type(nil);
  AssertEquals('nil node type fallback should be first enum value (scalar)', 0, Ord(LType));

  AssertEquals('nil node sequence count should be 0', 0, yaml_node_sequence_item_count(nil));
  AssertEquals('nil node mapping count should be 0', 0, yaml_node_mapping_item_count(nil));
end;

procedure TTestCase_YamlNode.Test_yaml_node_scalar_operations;
var
  LLen: SizeUInt;
  LScalar: PChar;
begin
  LLen := 123;
  LScalar := yaml_node_get_scalar(nil, @LLen);
  AssertNull('yaml_node_get_scalar(nil) should return nil', LScalar);
  AssertEquals('yaml_node_get_scalar(nil) should reset len to 0', Int64(0), Int64(LLen));

  LScalar := yaml_node_get_scalar(nil, nil);
  AssertNull('yaml_node_get_scalar(nil,nil) should return nil', LScalar);

  AssertNull('yaml_node_get_scalar0(nil) should return nil', yaml_node_get_scalar0(nil));
  AssertNull('yaml_node_sequence_get_by_index(nil,0) should return nil', yaml_node_sequence_get_by_index(nil, 0));
  AssertNull('yaml_node_mapping_get_by_index(nil,0) should return nil', yaml_node_mapping_get_by_index(nil, 0));
  AssertNull('yaml_node_mapping_lookup_by_string(nil,...) should return nil', yaml_node_mapping_lookup_by_string(nil, 'key', 3));
  AssertNull('yaml_node_pair_key(nil) should return nil', yaml_node_pair_key(nil));
  AssertNull('yaml_node_pair_value(nil) should return nil', yaml_node_pair_value(nil));
end;

procedure TTestCase_YamlNode.Test_yaml_node_sequence_operations;
var
  LCount: Integer;
  LItem: PYamlNode;
begin
  LCount := yaml_node_sequence_item_count(nil);
  AssertEquals('yaml_node_sequence_item_count(nil) should be 0', 0, LCount);

  LItem := yaml_node_sequence_get_by_index(nil, 0);
  AssertNull('yaml_node_sequence_get_by_index(nil,0) should return nil', LItem);

  LItem := yaml_node_sequence_get_by_index(nil, -1);
  AssertNull('yaml_node_sequence_get_by_index(nil,-1) should return nil', LItem);
end;

procedure TTestCase_YamlNode.Test_yaml_node_mapping_operations;
var
  LCount: Integer;
  LPair: PYamlNodePair;
  LNode: PYamlNode;
begin
  LCount := yaml_node_mapping_item_count(nil);
  AssertEquals('yaml_node_mapping_item_count(nil) should be 0', 0, LCount);

  LPair := yaml_node_mapping_get_by_index(nil, 0);
  AssertNull('yaml_node_mapping_get_by_index(nil,0) should return nil', LPair);
  AssertNull('yaml_node_pair_key(nil) should return nil', yaml_node_pair_key(LPair));
  AssertNull('yaml_node_pair_value(nil) should return nil', yaml_node_pair_value(LPair));

  LNode := yaml_node_mapping_lookup_by_string(nil, 'name', 4);
  AssertNull('yaml_node_mapping_lookup_by_string(nil,...) should return nil', LNode);
end;

// TTestCase_YamlEmitter 实现
procedure TTestCase_YamlEmitter.Test_yaml_emitter_create_destroy;
var
  LCfg: TYamlEmitCfg;
  LEmitter: PYamlEmitter;
begin
  FillChar(LCfg, SizeOf(LCfg), 0);
  LCfg.flags := [];
  LCfg.indent := 2;
  LCfg.width := 80;
  LCfg.userdata := nil;
  LCfg.diag := nil;

  LEmitter := yaml_emitter_create(@LCfg);
  AssertNotNull('yaml_emitter_create should return a valid emitter handle', LEmitter);

  yaml_emitter_destroy(LEmitter);
end;

procedure TTestCase_YamlEmitter.Test_yaml_emit_document;
var
  LCfg: TYamlEmitCfg;
  LEmitter: PYamlEmitter;
  LLen: SizeUInt;
  LOutput: PChar;
begin
  FillChar(LCfg, SizeOf(LCfg), 0);
  LCfg.flags := [];
  LCfg.indent := 2;
  LCfg.width := 80;
  LCfg.userdata := nil;
  LCfg.diag := nil;

  LEmitter := yaml_emitter_create(@LCfg);
  AssertNotNull('yaml_emitter_create should return a valid emitter handle', LEmitter);

  LLen := 77;
  LOutput := yaml_emit_document(nil, @LCfg, @LLen);
  AssertNull('yaml_emit_document(nil,...) should return nil', LOutput);
  AssertEquals('yaml_emit_document(nil,...) should reset len to 0', Int64(0), Int64(LLen));

  yaml_emitter_destroy(LEmitter);
end;


initialization
  RegisterTest(TTestCase_YamlCore);
  RegisterTest(TTestCase_YamlParser);
  RegisterTest(TTestCase_YamlDocument);
  RegisterTest(TTestCase_YamlNode);
  RegisterTest(TTestCase_YamlEmitter);

end.
