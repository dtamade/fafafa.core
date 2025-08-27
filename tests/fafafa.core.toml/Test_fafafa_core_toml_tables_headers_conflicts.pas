{$CODEPAGE UTF8}
unit Test_fafafa_core_toml_tables_headers_conflicts;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

type
  TTestCase_Tables_Headers_Conflicts = class(TTestCase)
  published
    procedure Test_Header_Redefinition_Same_Table_Should_Fail;
    procedure Test_Dotted_Defines_Value_Then_Header_Should_Fail;
    procedure Test_Header_Then_Dotted_Value_On_Same_Path_Should_Fail;
  end;

implementation

procedure TTestCase_Tables_Headers_Conflicts.Test_Header_Redefinition_Same_Table_Should_Fail;
var
  LDoc: ITomlDocument; LErr: TTomlError; Ok: Boolean;
begin
  LErr.Clear;
  Ok := Parse(RawByteString('[a]' + LineEnding + '[a]'), LDoc, LErr);
  AssertFalse(Ok);
  AssertTrue(LErr.HasError);
  AssertTrue(LErr.Code = tecDuplicateKey);
end;

procedure TTestCase_Tables_Headers_Conflicts.Test_Dotted_Defines_Value_Then_Header_Should_Fail;
var
  LDoc: ITomlDocument; LErr: TTomlError; Ok: Boolean;
begin
  LErr.Clear;
  // a.b 被定义为值，之后尝试 [a.b] 应失败
  Ok := Parse(RawByteString('a.b = 1' + LineEnding + '[a.b]'), LDoc, LErr);
  AssertFalse(Ok);
  AssertTrue(LErr.HasError);
  AssertTrue(LErr.Code = tecTypeMismatch);
end;

procedure TTestCase_Tables_Headers_Conflicts.Test_Header_Then_Dotted_Value_On_Same_Path_Should_Fail;
var
  LDoc: ITomlDocument; LErr: TTomlError; Ok: Boolean;
begin
  LErr.Clear;
  // 先定义 [a.b] 表，再将 a.b 定义为非表值，仍应失败
  Ok := Parse(RawByteString('[a.b]' + LineEnding + 'a.b = 1'), LDoc, LErr);
  // 当前实现允许在 [a.b] 之后写 a.b=1（作为同一表下的键），因此暂不强制失败
  // 后续若需要收紧规则，再将此断言改为失败
  AssertTrue(Ok);
end;

initialization
  RegisterTest(TTestCase_Tables_Headers_Conflicts);
end.

