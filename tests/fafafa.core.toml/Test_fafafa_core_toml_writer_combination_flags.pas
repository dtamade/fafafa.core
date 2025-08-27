{$CODEPAGE UTF8}
unit Test_fafafa_core_toml_writer_combination_flags;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

type
  TTestCase_Writer_Combination_Flags = class(TTestCase)
  published
    procedure Test_Writer_Sort_Pretty_Spaces_Combined_Snapshot;
  end;

implementation

procedure TTestCase_Writer_Combination_Flags.Test_Writer_Sort_Pretty_Spaces_Combined_Snapshot;
var
  LDoc: ITomlDocument;
  LErr: TTomlError;
  S: RawByteString;
  Expected: String;
begin
  LErr.Clear;
  // 构造一个包含标量、子表和数组表的结构
  if not Parse(RawByteString(
    'title = "T"' + LineEnding +
    '[db]' + LineEnding +
    'host = "127.0.0.1"' + LineEnding +
    'port = 5432' + LineEnding +
    '"user name" = "root"' + LineEnding +
    LineEnding +
    '[[servers]]' + LineEnding +
    'name = "alpha"' + LineEnding +
    'ip = "10.0.0.1"' + LineEnding +
    LineEnding +
    '[[servers]]' + LineEnding +
    'name = "beta"' + LineEnding +
    'ip = "10.0.0.2"'
  ), LDoc, LErr) then begin
    Writeln('PARSE ERR: ', LErr.ToString);
    AssertTrue(False);
  end;
  AssertFalse(LErr.HasError);

  // 组合 flags：排序、空格、Pretty
  S := ToToml(LDoc, [twfSortKeys, twfSpacesAroundEquals, twfPretty]);
  // debug dump next to test executable
  with TStringList.Create do
  try
    Text := String(S);
    SaveToFile(IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + '_debug_combined_snapshot.toml');
  finally
    Free;
  end;

  // 快照（按当前 Writer 规则：每表内先标量，后 AoT，再子表；键名排序；等号左右有空格；表段落间空行）
  Expected :=
    'title = "T"' + LineEnding +
    LineEnding +
    '[[servers]]' + LineEnding +
    'ip = "10.0.0.1"' + LineEnding +
    'name = "alpha"' + LineEnding +
    LineEnding +
    '[[servers]]' + LineEnding +
    'ip = "10.0.0.2"' + LineEnding +
    'name = "beta"' + LineEnding +
    LineEnding +
    '[db]' + LineEnding +
    'host = "127.0.0.1"' + LineEnding +
    'port = 5432' + LineEnding +
    '"user name" = "root"';

  // Writer 末尾不强制添加换行；规范快照以严格匹配当前输出为准
  Writeln('---COMBINED FLAGS ACTUAL---');
  Writeln(String(S));
  Writeln('---COMBINED FLAGS EXPECTED---');
  Writeln(Expected);
  AssertEquals(Expected, String(S));
end;

initialization
  RegisterTest(TTestCase_Writer_Combination_Flags);
end.

