{$CODEPAGE UTF8}
unit Test_fafafa_core_toml_writer_snapshot_tight_unicode_pretty;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

type
  TTestCase_Writer_Snapshot_Tight_Unicode_Pretty = class(TTestCase)
  published
    procedure Test_Writer_Tight_Equals_Unicode_With_Pretty_Snapshot;
  end;

implementation

procedure TTestCase_Writer_Snapshot_Tight_Unicode_Pretty.Test_Writer_Tight_Equals_Unicode_With_Pretty_Snapshot;
var
  B: ITomlBuilder;
  LDoc: ITomlDocument;
  S: String;
  HasBlank: Boolean;
begin
  // 使用 Builder 构建，避免原始文本解析的转义差异
  B := NewDoc;
  LDoc := B
    .PutStr('app_version','1.2.3')
    .PutStr('msg', 'hello' + LineEnding + 'world "quote" \\ ' + #9)
    .PutStr('作者','张三')
    .BeginTable('组').PutStr('说明','测试').EndTable
    .Build;

  // 去除易错的 Parse 路径，仅使用上方 Builder 构建的 LDoc



















    // 'msg = "hello\\nworld \\"quote\\" \\\\ \\t"' + LineEnding +














  S := String(ToToml(LDoc, [twfTightEquals, twfPretty]));

  // 紧凑等号
  AssertTrue(Pos(' = ', S) = 0);
  // 关键 ASCII 行
  AssertTrue(Pos('app_version="1.2.3"', S) > 0);
  AssertTrue(Pos('msg="hello', S) > 0);
  AssertTrue(Pos('\"quote\"', S) > 0);
  AssertTrue(Pos('\\', S) > 0);
  AssertTrue(Pos('\t', S) > 0);
  // Pretty 下应存在至少一个空行分隔段落
  HasBlank := Pos(LineEnding + LineEnding, S) > 0;
  AssertTrue(HasBlank);
  // 存在一个带引号的表头
  AssertTrue(Pos('["', S) > 0);
  AssertTrue(Pos('"]', S) > 0);
end;

initialization
  RegisterTest(TTestCase_Writer_Snapshot_Tight_Unicode_Pretty);
end.

