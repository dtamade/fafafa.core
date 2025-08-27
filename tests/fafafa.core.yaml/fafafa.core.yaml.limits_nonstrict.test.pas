{$CODEPAGE UTF8}
unit fafafa.core.yaml.limits_nonstrict.test;

{$MODE OBJFPC}{$H+}
{$modeswitch advancedrecords}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.yaml;

type
  TTestCase_YamlLimits_NonStrict = class(TTestCase)
  published
    procedure Test_scalar_length_limit_nonstrict_collects_diag_and_continues;
    procedure Test_event_count_limit_nonstrict_collects_diag_and_continues;
    procedure Test_depth_limit_nonstrict_collects_diag_and_continues;
  end;

implementation

procedure TTestCase_YamlLimits_NonStrict.Test_scalar_length_limit_nonstrict_collects_diag_and_continues;
var opts: TYamlParserOptions; p: PYamlParser; S: AnsiString; e: PYamlEvent; d: PYamlDiag;
begin
  yaml_parser_options_init_defaults(opts);
  // 非严格：只收集诊断，不终止
  Include(opts.cfg.flags, YAML_PCF_COLLECT_DIAG);
  opts.safety.max_scalar_length := 3;
  d := yaml_diag_create(nil);
  opts.cfg.diag := d;
  p := yaml_parser_create_ex(@opts);
  S := 'abcd';
  AssertEquals(0, yaml_parser_set_string(p, PChar(S), Length(S)));
  // +STR
  e := yaml_parser_parse(p); AssertNotNull(e); yaml_parser_event_free(p, e);
  // +DOC
  e := yaml_parser_parse(p); AssertNotNull(e); yaml_parser_event_free(p, e);
  // SCALAR 超限，但应继续产生事件
  e := yaml_parser_parse(p); AssertNotNull('should continue in non-strict mode', e); yaml_parser_event_free(p, e);
  // 验证诊断被记录
  AssertTrue('diag should be collected', yaml_diag_count(d) > 0);
  yaml_parser_destroy(p);
  yaml_diag_destroy(d);
end;

procedure TTestCase_YamlLimits_NonStrict.Test_event_count_limit_nonstrict_collects_diag_and_continues;
var opts: TYamlParserOptions; p: PYamlParser; S: AnsiString; e: PYamlEvent; d: PYamlDiag;
begin
  yaml_parser_options_init_defaults(opts);
  Include(opts.cfg.flags, YAML_PCF_COLLECT_DIAG);
  opts.safety.max_nodes := 2; // 允许 +STR,+DOC 后立即触发
  d := yaml_diag_create(nil);
  opts.cfg.diag := d;
  p := yaml_parser_create_ex(@opts);
  S := 'x';
  AssertEquals(0, yaml_parser_set_string(p, PChar(S), Length(S)));
  // +STR
  e := yaml_parser_parse(p); AssertNotNull(e); yaml_parser_event_free(p, e);
  // +DOC
  e := yaml_parser_parse(p); AssertNotNull(e); yaml_parser_event_free(p, e);
  // 非严格：达到上限后仍继续（至少返回 SCALAR 或 END 流程）
  e := yaml_parser_parse(p); AssertNotNull('should continue in non-strict mode', e); yaml_parser_event_free(p, e);
  AssertTrue('diag should be collected', yaml_diag_count(d) > 0);
  yaml_parser_destroy(p);
  yaml_diag_destroy(d);
end;

procedure TTestCase_YamlLimits_NonStrict.Test_depth_limit_nonstrict_collects_diag_and_continues;
var opts: TYamlParserOptions; p: PYamlParser; S: AnsiString; e: PYamlEvent; d: PYamlDiag;
begin
  yaml_parser_options_init_defaults(opts);
  Include(opts.cfg.flags, YAML_PCF_COLLECT_DIAG);
  Include(opts.cfg.flags, YAML_PCF_RESOLVE_DOCUMENT);
  opts.safety.max_depth := 1;
  d := yaml_diag_create(nil);
  opts.cfg.diag := d;
  p := yaml_parser_create_ex(@opts);
  S := '{a:[1]}';
  AssertEquals(0, yaml_parser_set_string(p, PChar(S), Length(S)));
  // +STR
  e := yaml_parser_parse(p); AssertNotNull(e); yaml_parser_event_free(p, e);
  // +DOC
  e := yaml_parser_parse(p); AssertNotNull(e); yaml_parser_event_free(p, e);
  // +MAP (depth=1)
  e := yaml_parser_parse(p); AssertNotNull(e); yaml_parser_event_free(p, e);
  // +SCALAR 'a'
  e := yaml_parser_parse(p); AssertNotNull(e); yaml_parser_event_free(p, e);
  // 进入 +SEQ 触发深度超限；非严格下仍应继续返回一个事件（可能是 SEQ_START 或后续）
  e := yaml_parser_parse(p); AssertNotNull('should continue in non-strict mode', e); yaml_parser_event_free(p, e);
  AssertTrue('diag should be collected', yaml_diag_count(d) > 0);
  yaml_parser_destroy(p);
  yaml_diag_destroy(d);
end;

initialization
  RegisterTest(TTestCase_YamlLimits_NonStrict);

end.

