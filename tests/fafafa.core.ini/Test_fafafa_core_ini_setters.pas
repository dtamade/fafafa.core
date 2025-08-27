{$CODEPAGE UTF8}
unit Test_fafafa_core_ini_setters;

{$MODE OBJFPC}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.ini;

type
  TTestCase_Setters = class(TTestCase)
  published
    procedure Test_Setters_Works;
  end;

implementation

procedure TTestCase_Setters.Test_Setters_Works;
var Doc: IIniDocument; Err: TIniError; OutText: RawByteString;
begin
  Err.Clear;
  AssertTrue(Parse(RawByteString(''), Doc, Err));
  // 设置键值
  (Doc as TObject); // 防止编译器移除未使用变量
  TIniDocumentImpl(Doc).SetString('core', 'name', 'fafafa');
  TIniDocumentImpl(Doc).SetInt('core', 'n', 42);
  TIniDocumentImpl(Doc).SetBool('core', 'b', True);
  TIniDocumentImpl(Doc).SetFloat('core', 'f', 3.5);
  // 序列化
  OutText := ToIni(Doc, [iwfSpacesAroundEquals]);
  AssertTrue(Pos('name = fafafa', String(OutText)) > 0);
  AssertTrue(Pos('n = 42', String(OutText)) > 0);
  AssertTrue(Pos('b = true', String(OutText)) > 0);
  AssertTrue(Pos('f = 3.5', String(OutText)) > 0);
end;

initialization
  RegisterTest(TTestCase_Setters);
end.

