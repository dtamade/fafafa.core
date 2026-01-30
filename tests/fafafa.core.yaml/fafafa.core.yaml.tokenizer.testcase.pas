{$CODEPAGE UTF8}
unit fafafa.core.yaml.tokenizer.testcase;

{$MODE OBJFPC}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}
{$M+}

interface

uses
  SysUtils, Classes,
  fpcunit, testregistry,
  fafafa.core.yaml.tokenizer;

type
  TTestCase_YamlTokenizer = class(TTestCase)
  published
    procedure Test_tokenizer_flow_symbols;
    procedure Test_tokenizer_plain_scalar_and_comment;

    procedure Test_tokenizer_quoted_scalars;
    procedure Test_tokenizer_anchors_aliases_tags;
    procedure Test_tokenizer_keywords_and_numbers;
  end;

implementation

procedure TTestCase_YamlTokenizer.Test_tokenizer_flow_symbols;
var tz: PYamlTokenizer; tok: TYamlTok; kind: TYamlTokenKind; s: AnsiString;
begin
  tz := yaml_tokenizer_create;
  try
    s := '[{,}]:';
    AssertEquals(0, yaml_tokenizer_set_string(tz, PChar(s), Length(s)));
    kind := yaml_tokenizer_next(tz, tok); AssertEquals(Ord(YTK_FLOW_SEQ_START), Ord(kind));
    kind := yaml_tokenizer_next(tz, tok); AssertEquals(Ord(YTK_FLOW_MAP_START), Ord(kind));
    kind := yaml_tokenizer_next(tz, tok); AssertEquals(Ord(YTK_COMMA), Ord(kind));
    kind := yaml_tokenizer_next(tz, tok); AssertEquals(Ord(YTK_FLOW_MAP_END), Ord(kind));
    kind := yaml_tokenizer_next(tz, tok); AssertEquals(Ord(YTK_FLOW_SEQ_END), Ord(kind));
    kind := yaml_tokenizer_next(tz, tok); AssertEquals(Ord(YTK_COLON), Ord(kind));
    kind := yaml_tokenizer_next(tz, tok); AssertEquals(Ord(YTK_EOF), Ord(kind));
  finally
    yaml_tokenizer_destroy(tz);
  end;
end;

procedure TTestCase_YamlTokenizer.Test_tokenizer_plain_scalar_and_comment;
var tz: PYamlTokenizer; tok: TYamlTok; kind: TYamlTokenKind; s: AnsiString;
begin
  tz := yaml_tokenizer_create;
  try
    s := 'a1 # comment' + LineEnding + ' { b }';
    AssertEquals(0, yaml_tokenizer_set_string(tz, PChar(s), Length(s)));
    kind := yaml_tokenizer_next(tz, tok); AssertEquals(Ord(YTK_SCALAR), Ord(kind)); AssertEquals(2, tok.value_len); // 'a1'
    kind := yaml_tokenizer_next(tz, tok); AssertEquals(Ord(YTK_FLOW_MAP_START), Ord(kind));
    kind := yaml_tokenizer_next(tz, tok); AssertEquals(Ord(YTK_SCALAR), Ord(kind)); AssertEquals(1, tok.value_len); // 'b'
    kind := yaml_tokenizer_next(tz, tok); AssertEquals(Ord(YTK_FLOW_MAP_END), Ord(kind));
    kind := yaml_tokenizer_next(tz, tok); AssertEquals(Ord(YTK_EOF), Ord(kind));
  finally
    yaml_tokenizer_destroy(tz);
  end;
end;




procedure TestQuoted(Test: TTestCase; const S: AnsiString; const expKinds: array of TYamlTokenKind; const expFirstTokenLen: Integer);
var tz: PYamlTokenizer; tok: TYamlTok; kind: TYamlTokenKind; idx: Integer; firstLen: SizeUInt;
begin
  tz := yaml_tokenizer_create;
  try
    Test.AssertEquals(0, yaml_tokenizer_set_string(tz, PChar(S), Length(S)));
    for idx:=0 to High(expKinds) do begin
      kind := yaml_tokenizer_next(tz, tok);
      if idx=0 then firstLen := tok.value_len;
      Test.AssertEquals(Ord(expKinds[idx]), Ord(kind));
    end;
    if expFirstTokenLen>=0 then begin
      Test.AssertEquals(QWord(expFirstTokenLen), QWord(firstLen));
    end;
  finally
    yaml_tokenizer_destroy(tz);
  end;
end;


procedure TTestCase_YamlTokenizer.Test_tokenizer_quoted_scalars;
begin
  // 双引号，内部包含冒号与逗号，不应被拆分；包含转义 \" 应被整体跳过两个字符
  TestQuoted(Self, '"a:1, b\"c"', [YTK_SCALAR, YTK_EOF], 11);
  // 单引号，内部 '' 视为转义的单引号
  TestQuoted(Self, '''a''''b''', [YTK_SCALAR, YTK_EOF], 6);
  // 引号后接分号：现视为普通字符，落入下一个 SCALAR（例如 ';"y"'）
  TestQuoted(Self, '"x";"y"', [YTK_SCALAR, YTK_SCALAR, YTK_EOF], 3);
end;

procedure TTestCase_YamlTokenizer.Test_tokenizer_anchors_aliases_tags;
var tz: PYamlTokenizer; tok: TYamlTok; kind: TYamlTokenKind; s: AnsiString;
begin
  tz := yaml_tokenizer_create;
  try
    s := '&a1, *b2; !tag !<tag:ns>'; // 简化：只验证切分
    AssertEquals(0, yaml_tokenizer_set_string(tz, PChar(s), Length(s)));
    kind := yaml_tokenizer_next(tz, tok); AssertEquals(Ord(YTK_SCALAR), Ord(kind)); // 目前 tokenizer 层可能统一为 SCALAR
    kind := yaml_tokenizer_next(tz, tok); AssertEquals(Ord(YTK_COMMA), Ord(kind));
    kind := yaml_tokenizer_next(tz, tok); AssertEquals(Ord(YTK_SCALAR), Ord(kind));
    // 分号不再单独作为 token；与后续内容并为 SCALAR
    kind := yaml_tokenizer_next(tz, tok); AssertEquals(Ord(YTK_SCALAR), Ord(kind));
    kind := yaml_tokenizer_next(tz, tok); AssertEquals(Ord(YTK_SCALAR), Ord(kind));
    kind := yaml_tokenizer_next(tz, tok); AssertEquals(Ord(YTK_COLON), Ord(kind));
    kind := yaml_tokenizer_next(tz, tok); AssertEquals(Ord(YTK_SCALAR), Ord(kind));
    kind := yaml_tokenizer_next(tz, tok); AssertEquals(Ord(YTK_EOF), Ord(kind));

    // !!tag:val 切分：期望 SCALAR, COLON, SCALAR
    s := '!!tag:val';
    AssertEquals(0, yaml_tokenizer_set_string(tz, PChar(s), Length(s)));
    kind := yaml_tokenizer_next(tz, tok); AssertEquals(Ord(YTK_SCALAR), Ord(kind));
    kind := yaml_tokenizer_next(tz, tok); AssertEquals(Ord(YTK_COLON), Ord(kind));
    kind := yaml_tokenizer_next(tz, tok); AssertEquals(Ord(YTK_SCALAR), Ord(kind));
    kind := yaml_tokenizer_next(tz, tok); AssertEquals(Ord(YTK_EOF), Ord(kind));
  finally
    yaml_tokenizer_destroy(tz);
  end;
  // 多个分号将并入同一 SCALAR（YAML 中分号非分隔符）
  tz := yaml_tokenizer_create;
  try
    s := 'a;;;b';
    AssertEquals(0, yaml_tokenizer_set_string(tz, PChar(s), Length(s)));
    kind := yaml_tokenizer_next(tz, tok); AssertEquals(Ord(YTK_SCALAR), Ord(kind));
    kind := yaml_tokenizer_next(tz, tok); AssertEquals(Ord(YTK_EOF), Ord(kind));
  finally
    yaml_tokenizer_destroy(tz);
  end;

  // 复杂 TAG 形态：!<ns:tag:more>
  tz := yaml_tokenizer_create;
  try
    s := '!<ns:tag:more>';
    AssertEquals(0, yaml_tokenizer_set_string(tz, PChar(s), Length(s)));
    kind := yaml_tokenizer_next(tz, tok); AssertEquals(Ord(YTK_SCALAR), Ord(kind));
    kind := yaml_tokenizer_next(tz, tok); AssertEquals(Ord(YTK_EOF), Ord(kind));
  finally
    yaml_tokenizer_destroy(tz);
  end;

  // 多重惊叹号前缀 + 冒号：!!!weird:val
  tz := yaml_tokenizer_create;
  try
    s := '!!!weird:val';
    AssertEquals(0, yaml_tokenizer_set_string(tz, PChar(s), Length(s)));
    kind := yaml_tokenizer_next(tz, tok); AssertEquals(Ord(YTK_SCALAR), Ord(kind));
    kind := yaml_tokenizer_next(tz, tok); AssertEquals(Ord(YTK_COLON), Ord(kind));
    kind := yaml_tokenizer_next(tz, tok); AssertEquals(Ord(YTK_SCALAR), Ord(kind));
    kind := yaml_tokenizer_next(tz, tok); AssertEquals(Ord(YTK_EOF), Ord(kind));
  finally
    yaml_tokenizer_destroy(tz);
  end;


  // !<...> 仅在尖括号内恰好 1 个冒号时拆分，否则整体 SCALAR
  tz := yaml_tokenizer_create;
  try
    s := '!<foo:bar>';
    AssertEquals(0, yaml_tokenizer_set_string(tz, PChar(s), Length(s)));
    kind := yaml_tokenizer_next(tz, tok); AssertEquals(Ord(YTK_SCALAR), Ord(kind)); // '!<foo'
    kind := yaml_tokenizer_next(tz, tok); AssertEquals(Ord(YTK_COLON), Ord(kind));
    kind := yaml_tokenizer_next(tz, tok); AssertEquals(Ord(YTK_SCALAR), Ord(kind)); // 'bar>'
    kind := yaml_tokenizer_next(tz, tok); AssertEquals(Ord(YTK_EOF), Ord(kind));
  finally
    yaml_tokenizer_destroy(tz);
  end;

  tz := yaml_tokenizer_create;
  try
    s := '!<ns:tag:more>'; // 多冒号 -> 整体 SCALAR
    AssertEquals(0, yaml_tokenizer_set_string(tz, PChar(s), Length(s)));
    kind := yaml_tokenizer_next(tz, tok); AssertEquals(Ord(YTK_SCALAR), Ord(kind));
    kind := yaml_tokenizer_next(tz, tok); AssertEquals(Ord(YTK_EOF), Ord(kind));
  finally
    yaml_tokenizer_destroy(tz);
  end;

end;

procedure TTestCase_YamlTokenizer.Test_tokenizer_keywords_and_numbers;
var tz: PYamlTokenizer; tok: TYamlTok; kind: TYamlTokenKind; s: AnsiString;
begin
  tz := yaml_tokenizer_create;
  try
    s := 'true, FALSE, null, ~, 123 -45 +6.7 _8.9';
    AssertEquals(0, yaml_tokenizer_set_string(tz, PChar(s), Length(s)));
    // 关键字与数字都以 SCALAR 形式出现，中间逗号/空格分隔
    kind := yaml_tokenizer_next(tz, tok); AssertEquals(Ord(YTK_SCALAR), Ord(kind));
    kind := yaml_tokenizer_next(tz, tok); AssertEquals(Ord(YTK_COMMA), Ord(kind));
    kind := yaml_tokenizer_next(tz, tok); AssertEquals(Ord(YTK_SCALAR), Ord(kind));
    kind := yaml_tokenizer_next(tz, tok); AssertEquals(Ord(YTK_COMMA), Ord(kind));
    kind := yaml_tokenizer_next(tz, tok); AssertEquals(Ord(YTK_SCALAR), Ord(kind));
    kind := yaml_tokenizer_next(tz, tok); AssertEquals(Ord(YTK_COMMA), Ord(kind));
    kind := yaml_tokenizer_next(tz, tok); AssertEquals(Ord(YTK_SCALAR), Ord(kind));
    kind := yaml_tokenizer_next(tz, tok); AssertEquals(Ord(YTK_COMMA), Ord(kind));
    kind := yaml_tokenizer_next(tz, tok); AssertEquals(Ord(YTK_SCALAR), Ord(kind)); // 123
    kind := yaml_tokenizer_next(tz, tok); AssertEquals(Ord(YTK_SCALAR), Ord(kind)); // -45
    kind := yaml_tokenizer_next(tz, tok); AssertEquals(Ord(YTK_SCALAR), Ord(kind)); // +6.7
    kind := yaml_tokenizer_next(tz, tok); AssertEquals(Ord(YTK_SCALAR), Ord(kind)); // _8.9
    kind := yaml_tokenizer_next(tz, tok); AssertEquals(Ord(YTK_EOF), Ord(kind));
  finally
    yaml_tokenizer_destroy(tz);
  end;
end;




initialization
  RegisterTest(TTestCase_YamlTokenizer);

end.
