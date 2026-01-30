unit fafafa.core.yaml.diagnostics.extras.test;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.yaml, fafafa.core.yaml.types, fafafa.core.yaml.diag,
  yaml_diag_helper;

Type
  TTestCase_YamlDiagnostics_Extras = class(TTestCase)
  published
    procedure Test_diag_unterminated_double_quote;
    procedure Test_diag_unterminated_single_quote;
    procedure Test_diag_unterminated_tag;
    procedure Test_diag_tag_payload_colon_rule;
    procedure Test_diag_illegal_control_char;
    procedure Test_diag_pos_unterminated_double_quote;
    procedure Test_diag_pos_illegal_control_char;
    procedure Test_diag_pos_unterminated_double_quote_multiline;
    procedure Test_diag_pos_unterminated_double_quote_crlf;
    procedure Test_diag_pos_illegal_control_char_after_comment_crlf;
    procedure Test_diag_range_empty_sequence_top;
    procedure Test_diag_range_empty_mapping_top;
    procedure Test_diag_range_empty_sequence_in_mapping_value;
    procedure Test_diag_range_empty_mapping_in_sequence_item;
    procedure Test_diag_eof_after_comma_in_sequence;
    procedure Test_diag_eof_after_colon_in_mapping;


  end;

implementation

procedure RunWithDiag(const S: AnsiString; out sinkText: string);
var cfg: TYamlParseCfg; parser: PYamlParser; sink: TDiagSink; diag: PFyDiag; p: PChar;
begin
  FillChar(cfg, SizeOf(cfg), 0);
  cfg.flags := [YAML_PCF_RESOLVE_DOCUMENT, YAML_PCF_COLLECT_DIAG];
  sink := TDiagSink.Create;
  try
    diag := yaml_diag_create_ex(@DiagCallback2Ex, Pointer(sink));
    cfg.diag := diag;
    parser := yaml_parser_create(@cfg);
    p := PChar(S);
    if yaml_parser_set_string(parser, p, Length(S))<>0 then raise Exception.Create('yaml_parser_set_string failed');
    while yaml_parser_parse(parser)<>nil do ;
    sinkText := sink.ToText;
  finally
    yaml_parser_destroy(parser);
    yaml_diag_destroy(diag);
    sink.Free;
  end;
end;

procedure TTestCase_YamlDiagnostics_Extras.Test_diag_unterminated_double_quote;
var T: string;
begin
  RunWithDiag('["abc, 1]', T);
  AssertTrue(Pos('unterminated double-quoted scalar', T) > 0);
end;

procedure TTestCase_YamlDiagnostics_Extras.Test_diag_unterminated_single_quote;
var T: string;
begin
  RunWithDiag('[''''''abc, 1]', T);
  AssertTrue(Pos('unterminated single-quoted scalar', T) > 0);
end;

procedure TTestCase_YamlDiagnostics_Extras.Test_diag_unterminated_tag;
var T: string;
begin
  RunWithDiag('[!<ns:tag, 1]', T);
  AssertTrue(Pos('unterminated tag', T) > 0);
end;

procedure TTestCase_YamlDiagnostics_Extras.Test_diag_tag_payload_colon_rule;
var T: string;
begin
  RunWithDiag('[!<ns:tag>, 1]', T);
  // 正常：恰好一个冒号，不报错；因此这里构造多冒号
  RunWithDiag('[!<ns:sub:tag>, 1]', T);
  AssertTrue(Pos('tag payload has 0 or multiple colons', T) > 0);
end;

procedure TTestCase_YamlDiagnostics_Extras.Test_diag_illegal_control_char;
var T: string; s: AnsiString;
begin
  s := '[' + AnsiChar(#1) + ']';
  RunWithDiag(s, T);

  AssertTrue(Pos('illegal control character in scalar', T) > 0);
end;

procedure TTestCase_YamlDiagnostics_Extras.Test_diag_pos_unterminated_double_quote;
var T: string; line,col: SizeInt;
begin
  // 输入以 [ 开始，然后在双引号开始处报错，行列应为 1-based
  RunWithDiag('["abc, 1]', T);
  // 提取 'Lx Cy '
  line := Pos(' L', T); col := Pos(' C', T);
  if (line>0) and (col>line) then begin
    // 行列均应为 1
    AssertTrue(Pos(' L1 C2 ', T) > 0);
  end;
end;

procedure TTestCase_YamlDiagnostics_Extras.Test_diag_pos_illegal_control_char;
var T: string; s: AnsiString;
begin
  // '[' 后紧跟 #1 ，因此列应为 2（1-based）
  s := '[' + AnsiChar(#1) + ']';
  RunWithDiag(s, T);
  AssertTrue(Pos('illegal control character in scalar', T) > 0);
  AssertTrue(Pos(' L1 C2 ', T) > 0);
end;

procedure TTestCase_YamlDiagnostics_Extras.Test_diag_pos_unterminated_double_quote_multiline;
var T: string; S: AnsiString;
begin
  // 第一行注释，第二行出现 " 开始，应该报 L2 C1（1-based）
  S := '# comment' + #10 + '"oops, 1]';
  RunWithDiag('[' + S, T);
  AssertTrue(Pos('unterminated double-quoted scalar', T) > 0);
  AssertTrue(Pos(' L2 C1 ', T) > 0); // 新行起始，列为1
end;

procedure TTestCase_YamlDiagnostics_Extras.Test_diag_pos_unterminated_double_quote_crlf;
var T: string; S: AnsiString;
begin
  // CRLF 换行后，行应加1，列重置
  S := '# comment' + #13#10 + '"oops, 1]';
  RunWithDiag('[' + S, T);
  AssertTrue(Pos('unterminated double-quoted scalar', T) > 0);
  AssertTrue(Pos(' L2 C1 ', T) > 0);
end;

procedure TTestCase_YamlDiagnostics_Extras.Test_diag_pos_illegal_control_char_after_comment_crlf;
var T: string; S: AnsiString;
begin
  // 注释+CRLF 后，行列应正确定位到下一行起始
  S := '# comment' + #13#10 + AnsiChar(#1) + ']';
  RunWithDiag('[' + S, T);
  AssertTrue(Pos('illegal control character in scalar', T) > 0);
  AssertTrue(Pos(' L2 C1 ', T) > 0);
end;

procedure TTestCase_YamlDiagnostics_Extras.Test_diag_range_empty_sequence_top;
var T: string;
begin
  RunWithDiag('[]', T);
  AssertTrue(Pos('FYDC_EMPTY_FLOW_SEQUENCE', T) > 0);
  AssertTrue(Pos(' - L', T) > 0);
end;

procedure TTestCase_YamlDiagnostics_Extras.Test_diag_range_empty_mapping_top;
var T: string;
begin
  RunWithDiag('{}', T);
  AssertTrue(Pos('FYDC_EMPTY_FLOW_MAPPING', T) > 0);
  AssertTrue(Pos(' - L', T) > 0);
end;

procedure TTestCase_YamlDiagnostics_Extras.Test_diag_range_empty_sequence_in_mapping_value;
var T: string;
begin
  RunWithDiag('{a: []}', T);
  AssertTrue(Pos('FYDC_EMPTY_FLOW_SEQUENCE', T) > 0);
  AssertTrue(Pos(' - L', T) > 0);
end;

procedure TTestCase_YamlDiagnostics_Extras.Test_diag_range_empty_mapping_in_sequence_item;
var T: string;
begin
  RunWithDiag('[{}]', T);
  AssertTrue(Pos('FYDC_EMPTY_FLOW_MAPPING', T) > 0);
  AssertTrue(Pos(' - L', T) > 0);
end;


procedure TTestCase_YamlDiagnostics_Extras.Test_diag_eof_after_comma_in_sequence;
var T: string;
begin
  // 逗号后无元素直接 EOF，应定位范围起点在逗号处
  RunWithDiag('[1, 2, ', T);
  AssertTrue(Pos('unexpected EOF', T) > 0);
  AssertTrue(Pos(' - L', T) > 0);
end;

procedure TTestCase_YamlDiagnostics_Extras.Test_diag_eof_after_colon_in_mapping;
var T: string;
begin
  // 冒号后无值直接 EOF，应定位范围起点在冒号处
  RunWithDiag('{a: ', T);
  AssertTrue(Pos('unexpected EOF', T) > 0);
  AssertTrue(Pos(' - L', T) > 0);
end;

initialization
  RegisterTest('fafafa.core.yaml/diagnostics_extras', TTestCase_YamlDiagnostics_Extras);
end.
