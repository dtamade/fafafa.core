{$CODEPAGE UTF8}
unit Test_fafafa_core_ini_write_flags_extras;

{$MODE OBJFPC}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.ini;

type
  TTestCase_WriteFlags_Extras = class(TTestCase)
  published
    procedure Test_WriteBOM_ToFile;
    procedure Test_StableKeyOrder_Reassembled;
  end;

implementation

procedure TTestCase_WriteFlags_Extras.Test_WriteBOM_ToFile;
var Doc: IIniDocument; Err: TIniError; tmp: String; FS: TFileStream; B: array[0..2] of Byte; R: LongInt;
begin
  Err.Clear;
  AssertTrue(Parse(RawByteString('[a]'#10'a=1'#10), Doc, Err));
  tmp := 'tmp_bom.ini';
  AssertTrue(ToFile(Doc, tmp, [iwfWriteBOM, iwfSpacesAroundEquals]));
  FS := TFileStream.Create(tmp, fmOpenRead or fmShareDenyNone);
  try
    R := FS.Read(B, 3);
    AssertEquals(3, R);
    AssertEquals($EF, B[0]);
    AssertEquals($BB, B[1]);
    AssertEquals($BF, B[2]);
  finally
    FS.Free;
  end;
  if FileExists(tmp) then DeleteFile(tmp);
end;

procedure TTestCase_WriteFlags_Extras.Test_StableKeyOrder_Reassembled;
const
  SRC = '[s]'+LineEnding+'b=2'+LineEnding+'a=1'+LineEnding; // 原始 b 在前
var Doc: IIniDocument; Err: TIniError; Out1: RawByteString;
begin
  Err.Clear;
  AssertTrue(Parse(RawByteString(SRC), Doc, Err));
  // 使节脏以触发重组
  SetString(Doc, 's', 'c', '3');
  Out1 := ToIni(Doc, [iwfStableKeyOrder]);
  // 期望按字母序：a, b, c
  AssertTrue(Pos('a=1', String(Out1)) < Pos('b=2', String(Out1)));
  AssertTrue(Pos('b=2', String(Out1)) < Pos('c=3', String(Out1)));
end;

initialization
  RegisterTest(TTestCase_WriteFlags_Extras);
end.

