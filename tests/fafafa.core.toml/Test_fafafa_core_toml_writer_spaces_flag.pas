{$CODEPAGE UTF8}
unit Test_fafafa_core_toml_writer_spaces_flag;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

type
  TTestCase_Writer_Spaces = class(TTestCase)
  published
    procedure Test_Writer_Default_Equals_With_Spaces;
    procedure Test_Writer_SpacesAroundEquals_Flag_Works;
    procedure Test_Writer_TightEquals_Flag_Works;
  end;

implementation

procedure TTestCase_Writer_Spaces.Test_Writer_Default_Equals_With_Spaces;
var
  LDoc: ITomlDocument;
  LErr: TTomlError;
  S: String;
begin
  LErr.Clear;
  AssertTrue(Parse(RawByteString('a.b.c = 1' + LineEnding + 'foo = 2'), LDoc, LErr));
  AssertFalse(LErr.HasError);
  S := String(ToToml(LDoc, []));
  // 默认：等号两侧有空格（当前版本默认更可读）
  AssertTrue(Pos('foo = 2', S) > 0);
end;

procedure TTestCase_Writer_Spaces.Test_Writer_SpacesAroundEquals_Flag_Works;
var
  LDoc: ITomlDocument;
  LErr: TTomlError;
  S: String;
begin
  LErr.Clear;
  AssertTrue(Parse(RawByteString('a.b.c = 1' + LineEnding + 'foo = 2'), LDoc, LErr));
  AssertFalse(LErr.HasError);
  S := String(ToToml(LDoc, [twfSpacesAroundEquals]));
  // 开启 flag：等号两侧有空格
  AssertTrue(Pos('foo = 2', S) > 0);
end;

procedure TTestCase_Writer_Spaces.Test_Writer_TightEquals_Flag_Works;
var
  LDoc: ITomlDocument; LErr: TTomlError; S: String;
begin
  LErr.Clear;
  AssertTrue(Parse(RawByteString('a.b.c = 1' + LineEnding + 'foo = 2'), LDoc, LErr));
  AssertFalse(LErr.HasError);
  S := String(ToToml(LDoc, [twfTightEquals]));
  // 紧凑等号：不带空格
  AssertTrue(Pos('foo=2', S) > 0);
end;

initialization
  RegisterTest(TTestCase_Writer_Spaces);
end.

