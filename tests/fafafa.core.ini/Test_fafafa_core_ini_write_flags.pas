{$CODEPAGE UTF8}
unit Test_fafafa_core_ini_write_flags;

{$MODE OBJFPC}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.ini;

type
  TTestCase_WriteFlags = class(TTestCase)
  published
    procedure Test_WriteFlags_Simple_NoBodyLines;
    procedure Test_WriteFlags_Ignored_When_BodyLines;
    procedure Test_WriteFlags_ForceLF;
  end;

implementation

procedure TTestCase_WriteFlags.Test_WriteFlags_Simple_NoBodyLines;
var Doc: IIniDocument; Err: TIniError; OutText: RawByteString; S: String;
begin
  Err.Clear;
  AssertTrue(Parse(RawByteString(''), Doc, Err));
  // 通过公共接口读写小烟测
  AssertTrue(Doc.TryGetString('core','_nonexistent_',S)=False);
  // 使用 Facade Set*，避免单元内直接 downcast
  SetBool(Doc, 'core', 'b', True);
  SetString(Doc, 'core', 'name', 'x');
  OutText := ToIni(Doc, [iwfSpacesAroundEquals, iwfPreferColon, iwfBoolUpperCase]);
  // 无 BodyLines，应该按策略写出
  AssertTrue(Pos('b : TRUE', String(OutText)) > 0);
  AssertTrue(Pos('name : x', String(OutText)) > 0);
end;

procedure TTestCase_WriteFlags.Test_WriteFlags_Ignored_When_BodyLines;
const
  SRC = '[core]'+LineEnding+
        'b = true'+LineEnding+
        '; trailing comment to ensure BodyLines'+LineEnding;
var Doc: IIniDocument; Err: TIniError; OutText: RawByteString;
begin
  Err.Clear;
  AssertTrue(Parse(RawByteString(SRC), Doc, Err));
  OutText := ToIni(Doc, [iwfSpacesAroundEquals, iwfPreferColon, iwfBoolUpperCase]);
  // 存在 BodyLines，应当原样回放，不受策略影响
  AssertTrue(Pos('b = true', String(OutText)) > 0);
  AssertTrue(Pos(':', String(OutText)) = 0); // 不应替换为冒号
end;

procedure TTestCase_WriteFlags.Test_WriteFlags_ForceLF;
var Doc: IIniDocument; Err: TIniError; OutText: RawByteString;
begin
  Err.Clear;
  AssertTrue(Parse(RawByteString('[a]'+LineEnding+'x=1'+LineEnding), Doc, Err));
  // Dirty path ensures reassemble, so flags apply
  SetInt(Doc, 'a', 'x', 2);
  OutText := ToIni(Doc, [iwfForceLF]);
  // Expect LF only
  AssertTrue(Pos(#13, String(OutText)) = 0);
  AssertTrue(Pos('x=2'+#10, String(OutText)) > 0);
end;

initialization
  RegisterTest(TTestCase_WriteFlags);
end.

unit Test_fafafa_core_ini_write_flags;

{$MODE OBJFPC}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.ini;

type
  TTestCase_WriteFlags = class(TTestCase)
  published
    procedure Test_WriteFlags_Simple_NoBodyLines;
    procedure Test_WriteFlags_Ignored_When_BodyLines;
  end;

implementation

procedure TTestCase_WriteFlags.Test_WriteFlags_Simple_NoBodyLines;
var Doc: IIniDocument; Err: TIniError; OutText: RawByteString; S: String;
begin
  Err.Clear;
  AssertTrue(Parse(RawByteString(''), Doc, Err));
  // 通过公共接口读写小烟测
  AssertTrue(Doc.TryGetString('core','_nonexistent_',S)=False);
  // 使用 Facade Set*，避免单元内直接 downcast
  SetBool(Doc, 'core', 'b', True);
  SetString(Doc, 'core', 'name', 'x');
  OutText := ToIni(Doc, [iwfSpacesAroundEquals, iwfPreferColon, iwfBoolUpperCase]);
  // 无 BodyLines，应该按策略写出
  AssertTrue(Pos('b : TRUE', String(OutText)) > 0);
  AssertTrue(Pos('name : x', String(OutText)) > 0);
end;

procedure TTestCase_WriteFlags.Test_WriteFlags_Ignored_When_BodyLines;
const
  SRC = '[core]'+LineEnding+
        'b = true'+LineEnding+
        '; trailing comment to ensure BodyLines'+LineEnding;
var Doc: IIniDocument; Err: TIniError; OutText: RawByteString;
begin
  Err.Clear;
  AssertTrue(Parse(RawByteString(SRC), Doc, Err));
  OutText := ToIni(Doc, [iwfSpacesAroundEquals, iwfPreferColon, iwfBoolUpperCase]);
  // 存在 BodyLines，应当原样回放，不受策略影响
  AssertTrue(Pos('b = true', String(OutText)) > 0);
  AssertTrue(Pos(':', String(OutText)) = 0); // 不应替换为冒号
end;

initialization
  RegisterTest(TTestCase_WriteFlags);
end.

