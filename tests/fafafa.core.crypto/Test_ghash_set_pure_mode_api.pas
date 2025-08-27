{$CODEPAGE UTF8}
unit Test_ghash_set_pure_mode_api;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.crypto.aead.gcm.ghash;

type
  TTestCase_GHash_SetPureModeAPI = class(TTestCase)
  published
    procedure Test_SetPureMode_Affects_NewContexts_DebugOnly;
  end;

implementation

procedure TTestCase_GHash_SetPureModeAPI.Test_SetPureMode_Affects_NewContexts_DebugOnly;
var
  H, A, C, S1, S2: TBytes; i: Integer;
begin
  SetLength(H, 16); for i := 0 to 15 do H[i] := i;
  SetLength(A, 64); for i := 0 to 63 do A[i] := 255 - i;
  SetLength(C, 64); for i := 0 to 63 do C[i] := i*7;

  // bit
  GHash_SetPureMode('bit');
  with CreateGHash do begin Init(H); Update(A); Update(C); S1 := Finalize(Length(A), Length(C)); end;
  // nibble
  GHash_SetPureMode('nibble');
  with CreateGHash do begin Init(H); Update(A); Update(C); S2 := Finalize(Length(A), Length(C)); end;

  // 两者应一致（不同纯路径实现等价）；Release 下该 API 不改变行为（默认 byte），测试仍能比较一致性
  AssertEquals(Length(S1), Length(S2));
  if Length(S1) > 0 then AssertTrue(CompareByte(S1[0], S2[0], Length(S1)) = 0);
end;

initialization
  RegisterTest(TTestCase_GHash_SetPureModeAPI);

end.

