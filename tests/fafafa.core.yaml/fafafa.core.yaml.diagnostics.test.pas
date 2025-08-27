unit fafafa.core.yaml.diagnostics.test;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.yaml, fafafa.core.yaml.types, fafafa.core.yaml.diag,
  yaml_diag_helper;

Type
  TTestCase_YamlDiagnostics = class(TTestCase)
  published
    procedure Test_diag_flow_sequence_empty_and_eof;
    procedure Test_diag_flow_mapping_empty_and_eof;
    procedure Test_diag_flow_sequence_unexpected_eof_after_item;
    procedure Test_diag_flow_sequence_contains_empty_mapping;
    procedure Test_diag_flow_mapping_contains_empty_sequence;

  end;

implementation

procedure TTestCase_YamlDiagnostics.Test_diag_flow_sequence_empty_and_eof;
var cfg: TYamlParseCfg; parser: PYamlParser; sink: TDiagSink; diag: PFyDiag; input: PChar; S: AnsiString;
begin
  FillChar(cfg, SizeOf(cfg), 0);
  cfg.flags := [YAML_PCF_RESOLVE_DOCUMENT, YAML_PCF_COLLECT_DIAG];

  // case 1: empty [] -> INFO
  sink := TDiagSink.Create;
  try
    diag := yaml_diag_create2(@DiagCallback2, Pointer(sink));
    cfg.diag := diag;
    parser := yaml_parser_create(@cfg);
    input := '[]';
    AssertEquals(0, yaml_parser_set_string(parser, input, StrLen(input)));
    // 消费到结束
    while yaml_parser_parse(parser)<>nil do ;
    AssertTrue('expect diag message for empty sequence', Pos('empty/closed flow sequence', sink.ToText) > 0);
  finally
    yaml_parser_destroy(parser);
    yaml_diag_destroy(diag);
    sink.Free;
  end;

  // case 2: EOF in sequence item
  sink := TDiagSink.Create;
  try
    FillChar(cfg, SizeOf(cfg), 0);
    cfg.flags := [YAML_PCF_RESOLVE_DOCUMENT, YAML_PCF_COLLECT_DIAG];
    diag := yaml_diag_create2(@DiagCallback2, Pointer(sink));
    cfg.diag := diag;
    parser := yaml_parser_create(@cfg);
    S := '[1,2'; input := PChar(S);
    AssertEquals(0, yaml_parser_set_string(parser, input, Length(S)));
    while yaml_parser_parse(parser)<>nil do ;
    AssertTrue('expect EOF diag for sequence', Pos('unexpected EOF', sink.ToText) > 0);
  finally
    yaml_parser_destroy(parser);
    yaml_diag_destroy(diag);
    sink.Free;
  end;
end;

procedure TTestCase_YamlDiagnostics.Test_diag_flow_mapping_empty_and_eof;
var cfg: TYamlParseCfg; parser: PYamlParser; sink: TDiagSink; diag: PFyDiag; input: PChar; S: AnsiString;
begin
  FillChar(cfg, SizeOf(cfg), 0);
  cfg.flags := [YAML_PCF_RESOLVE_DOCUMENT, YAML_PCF_COLLECT_DIAG];

  // case 1: empty {} -> INFO
  sink := TDiagSink.Create;
  try
    diag := yaml_diag_create2(@DiagCallback2, Pointer(sink));
    cfg.diag := diag;
    parser := yaml_parser_create(@cfg);
    input := '{}';
    AssertEquals(0, yaml_parser_set_string(parser, input, StrLen(input)));
    while yaml_parser_parse(parser)<>nil do ;
    AssertTrue('expect diag message for empty mapping', Pos('empty/closed flow mapping', sink.ToText) > 0);
  finally
    yaml_parser_destroy(parser);
    yaml_diag_destroy(diag);
    sink.Free;
  end;

  // case 2: EOF in mapping
  sink := TDiagSink.Create;
  try
    FillChar(cfg, SizeOf(cfg), 0);
    cfg.flags := [YAML_PCF_RESOLVE_DOCUMENT, YAML_PCF_COLLECT_DIAG];
    diag := yaml_diag_create(@DiagCallback, Pointer(sink));
    cfg.diag := diag;
    parser := yaml_parser_create(@cfg);
    S := '{a:1, b'; input := PChar(S);
    AssertEquals(0, yaml_parser_set_string(parser, input, Length(S)));
    while yaml_parser_parse(parser)<>nil do ;
    AssertTrue('expect EOF diag for mapping', Pos('unexpected EOF', sink.ToText) > 0);
  finally
    yaml_parser_destroy(parser);
    yaml_diag_destroy(diag);
    sink.Free;
  end;
end;


procedure TTestCase_YamlDiagnostics.Test_diag_flow_sequence_unexpected_eof_after_item;
var cfg: TYamlParseCfg; parser: PYamlParser; sink: TDiagSink; diag: PFyDiag; S: AnsiString; input: PChar;
begin
  FillChar(cfg, SizeOf(cfg), 0);
  cfg.flags := [YAML_PCF_RESOLVE_DOCUMENT, YAML_PCF_COLLECT_DIAG];
  sink := TDiagSink.Create;
  try
    diag := yaml_diag_create(@DiagCallback, Pointer(sink));
    cfg.diag := diag;
    parser := yaml_parser_create(@cfg);
    S := '[1, '; input := PChar(S);
    AssertEquals(0, yaml_parser_set_string(parser, input, Length(S)));
    while yaml_parser_parse(parser)<>nil do ;
    AssertTrue('unexpected EOF after item', Pos('unexpected EOF', sink.ToText) > 0);
  finally
    yaml_parser_destroy(parser);
    yaml_diag_destroy(diag);
    sink.Free;
  end;
end;

procedure TTestCase_YamlDiagnostics.Test_diag_flow_sequence_contains_empty_mapping;
var cfg: TYamlParseCfg; parser: PYamlParser; sink: TDiagSink; diag: PFyDiag; input: PChar;
begin
  FillChar(cfg, SizeOf(cfg), 0);
  cfg.flags := [YAML_PCF_RESOLVE_DOCUMENT, YAML_PCF_COLLECT_DIAG];
  sink := TDiagSink.Create;
  try
    diag := yaml_diag_create2(@DiagCallback2, Pointer(sink));
    cfg.diag := diag;
    parser := yaml_parser_create(@cfg);
    input := '[{}]';
    AssertEquals(0, yaml_parser_set_string(parser, input, StrLen(input)));
    while yaml_parser_parse(parser)<>nil do ;
    AssertTrue('contains empty mapping reported', Pos('empty/closed flow mapping', sink.ToText) > 0);
  finally
    yaml_parser_destroy(parser);
    yaml_diag_destroy(diag);
    sink.Free;
  end;
end;

procedure TTestCase_YamlDiagnostics.Test_diag_flow_mapping_contains_empty_sequence;
var cfg: TYamlParseCfg; parser: PYamlParser; sink: TDiagSink; diag: PFyDiag; input: PChar;
begin
  FillChar(cfg, SizeOf(cfg), 0);
  cfg.flags := [YAML_PCF_RESOLVE_DOCUMENT, YAML_PCF_COLLECT_DIAG];
  sink := TDiagSink.Create;
  try
    diag := yaml_diag_create2(@DiagCallback2, Pointer(sink));
    cfg.diag := diag;
    parser := yaml_parser_create(@cfg);
    input := '{a: []}';
    AssertEquals(0, yaml_parser_set_string(parser, input, StrLen(input)));
    while yaml_parser_parse(parser)<>nil do ;
    AssertTrue('contains empty sequence reported', Pos('empty/closed flow sequence', sink.ToText) > 0);
  finally
    yaml_parser_destroy(parser);
    yaml_diag_destroy(diag);
    sink.Free;
  end;
end;


initialization
  RegisterTest('fafafa.core.yaml/diagnostics', TTestCase_YamlDiagnostics);
end.

