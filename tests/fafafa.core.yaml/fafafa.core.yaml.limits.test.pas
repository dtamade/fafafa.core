{$CODEPAGE UTF8}
unit fafafa.core.yaml.limits.test;

{$MODE OBJFPC}{$H+}
{$modeswitch advancedrecords}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.yaml;

type
  TTestCase_YamlLimits = class(TTestCase)
  published
    procedure Test_scalar_length_limit_strict;
    procedure Test_event_count_limit_strict;
    procedure Test_depth_limit_strict_flow;
  end;

implementation

procedure TTestCase_YamlLimits.Test_scalar_length_limit_strict;
var opts: TYamlParserOptions; p: PYamlParser; S: AnsiString; e: PYamlEvent;
begin
  yaml_parser_options_init_defaults(opts);
  // 严格 + 小标量上限
  Include(opts.cfg.flags, YAML_PCF_STRICT_LIMITS);
  opts.safety.max_scalar_length := 3;
  p := yaml_parser_create_ex(@opts);
  S := 'abcd';
  AssertEquals(0, yaml_parser_set_string(p, PChar(S), Length(S)));
  // +STR +DOC 后，遇到 SCALAR 超限应返回 nil（严格终止）
  e := yaml_parser_parse(p); AssertNotNull(e); yaml_parser_event_free(p, e);
  e := yaml_parser_parse(p); AssertNotNull(e); yaml_parser_event_free(p, e);
  e := yaml_parser_parse(p); AssertTrue('expect nil due to scalar limit', e=nil);
  yaml_parser_destroy(p);
end;

procedure TTestCase_YamlLimits.Test_event_count_limit_strict;
var opts: TYamlParserOptions; p: PYamlParser; S: AnsiString; e: PYamlEvent;
begin
  yaml_parser_options_init_defaults(opts);
  Include(opts.cfg.flags, YAML_PCF_STRICT_LIMITS);
  opts.safety.max_nodes := 2; // 允许 +STR,+DOC 之后立即触发
  p := yaml_parser_create_ex(@opts);
  S := 'x';
  AssertEquals(0, yaml_parser_set_string(p, PChar(S), Length(S)));
  // +STR
  e := yaml_parser_parse(p); AssertNotNull(e); yaml_parser_event_free(p, e);
  // +DOC
  e := yaml_parser_parse(p); AssertNotNull(e); yaml_parser_event_free(p, e);
  // 达到上限，下一次应 nil
  e := yaml_parser_parse(p); AssertTrue('expect nil due to event limit', e=nil);
  yaml_parser_destroy(p);
end;

procedure TTestCase_YamlLimits.Test_depth_limit_strict_flow;
var opts: TYamlParserOptions; p: PYamlParser; S: AnsiString; e: PYamlEvent;
begin
  yaml_parser_options_init_defaults(opts);
  Include(opts.cfg.flags, YAML_PCF_STRICT_LIMITS);
  opts.safety.max_depth := 1; // 只允许进入一层容器（例如最外层）
  Include(opts.cfg.flags, YAML_PCF_RESOLVE_DOCUMENT);
  p := yaml_parser_create_ex(@opts);
  S := '{a:[1]}';
  AssertEquals(0, yaml_parser_set_string(p, PChar(S), Length(S)));
  // +STR
  e := yaml_parser_parse(p); AssertNotNull(e); yaml_parser_event_free(p, e);
  // +DOC
  e := yaml_parser_parse(p); AssertNotNull(e); yaml_parser_event_free(p, e);
  // +MAP (depth=1)
  e := yaml_parser_parse(p); AssertNotNull(e); AssertEquals(Ord(YAML_ET_MAPPING_START), Ord(e^.event_type)); yaml_parser_event_free(p, e);
  // +SCALAR 'a'
  e := yaml_parser_parse(p); AssertNotNull(e); yaml_parser_event_free(p, e);
  // +SEQ (depth=2) -> 超限应直接 nil
  e := yaml_parser_parse(p); AssertTrue('expect nil due to depth limit', e=nil);
  yaml_parser_destroy(p);
end;

initialization
  RegisterTest(TTestCase_YamlLimits);

end.

