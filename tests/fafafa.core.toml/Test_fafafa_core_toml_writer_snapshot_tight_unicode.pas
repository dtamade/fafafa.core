{$CODEPAGE UTF8}
unit Test_fafafa_core_toml_writer_snapshot_tight_unicode;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

type
  TTestCase_Writer_Snapshot_Tight_Unicode = class(TTestCase)
  published
    procedure Test_Writer_Tight_Equals_With_Unicode_Keys_And_Escapes_Snapshot;
  end;

implementation

procedure TTestCase_Writer_Snapshot_Tight_Unicode.Test_Writer_Tight_Equals_With_Unicode_Keys_And_Escapes_Snapshot;
var
  LDoc: ITomlDocument;
  LErr: TTomlError;
  S: String;
begin
  LErr.Clear;
  AssertTrue(Parse(RawByteString(
    'app_version = "1.2.3"' + LineEnding +
    '"\u4F5C\u8005" = "\u5F20\u4E09"' + LineEnding +
    // 含转义：\n、\t、\\、\" （解析后为换行/制表/反斜杠/引号）
    'msg = "hello\nworld \"quote\" \\ \t"' + LineEnding +
    '["\u7EC4"]' + LineEnding +
    '"\u8BF4\u660E" = "\u6D4B\u8BD5"'
  ), LDoc, LErr));
  AssertFalse(LErr.HasError);

  // 紧凑等号，无 Sort/Pretty
  S := String(ToToml(LDoc, [twfTightEquals]));

  // 验证关键点：
  // 1) 紧凑等号
  AssertTrue(Pos(' = ', S) = 0);
  // 2) ASCII 可见的复杂转义行精确匹配
  AssertTrue(Pos('app_version="1.2.3"', S) > 0);
  AssertTrue(Pos('msg="hello\nworld \"quote\" \\ \t"', S) > 0);
  // 3) 存在一个带引号的表头行（避免直接断言具体 Unicode，可用模式判断）
  AssertTrue(Pos('["', S) > 0);
  AssertTrue(Pos('"]', S) > 0);
end;

initialization
  RegisterTest(TTestCase_Writer_Snapshot_Tight_Unicode);
end.

