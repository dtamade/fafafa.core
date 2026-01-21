{$CODEPAGE UTF8}
unit Test_ghash_pure_mode_sweep;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, {$IFDEF MSWINDOWS}Windows,{$ELSE}ctypes,{$ENDIF}
  fafafa.core.crypto.aead.gcm.ghash;

type
  TTestCase_GHash_PureMode_Sweep = class(TTestCase)
  published
    procedure Test_Sweep_Modes_Run_KAT_And_Property;
  end;

implementation

{$IFNDEF MSWINDOWS}
function setenv(name: PChar; value: PChar; overwrite: cint): cint; cdecl; external 'c' name 'setenv';
function unsetenv(name: PChar): cint; cdecl; external 'c' name 'unsetenv';
{$ENDIF}

procedure RunKAT_AllZero;
var
  GH: IGHash; H, S: TBytes;
begin
  SetLength(H, 16); FillChar(H[0], 16, 0);
  GH := CreateGHash; GH.Init(H);
  S := GH.Finalize(0, 0);
  fpcunit.TAssert.AssertEquals(16, Length(S));
  fpcunit.TAssert.AssertTrue((S[0]=0) and (S[15]=0));
end;

function BytesConcat(const A, B: TBytes): TBytes;
var lenA, lenB: Integer;
begin
  lenA := Length(A); lenB := Length(B);
  SetLength(Result, lenA + lenB);
  if lenA > 0 then Move(A[0], Result[0], lenA);
  if lenB > 0 then Move(B[0], Result[lenA], lenB);
end;

procedure RunProperty_AssocAndLength;
var
  GH: IGHash; H, A1, C1, S1, S2: TBytes; A2: TBytes;
  i: Integer;
begin
  // associativity-like: Update(A1); Update(A2) == Update(A1+A2)
  SetLength(H, 16); for i := 0 to 15 do H[i] := i;
  A1 := nil; SetLength(A1, 100); for i := 0 to 99 do A1[i] := i;
  A2 := nil; SetLength(A2, 77); for i := 0 to 76 do A2[i] := 255 - i;
  C1 := nil; SetLength(C1, 33); for i := 0 to 32 do C1[i] := i*3;

  GH := CreateGHash; GH.Init(H); GH.Update(A1); GH.Update(A2); GH.Update(C1); S1 := GH.Finalize(Length(A1)+Length(A2), Length(C1));
  GH := CreateGHash; GH.Init(H); GH.Update(BytesConcat(A1, A2)); GH.Update(C1); S2 := GH.Finalize(Length(A1)+Length(A2), Length(C1));

  fpcunit.TAssert.AssertEquals(Length(S1), Length(S2));
  if Length(S1) > 0 then fpcunit.TAssert.AssertTrue(CompareByte(S1[0], S2[0], Length(S1)) = 0);
end;

procedure SetEnv(const Name, Value: String);
begin
  {$IFDEF MSWINDOWS}
  if Value = '' then Windows.SetEnvironmentVariable(PChar(Name), nil)
  else Windows.SetEnvironmentVariable(PChar(Name), PChar(Value));
  {$ELSE}
  if Value = '' then unsetenv(PChar(Name))
  else setenv(PChar(Name), PChar(Value), 1);
  {$ENDIF}
end;

procedure SetMode(const M: String);
begin
  SetEnv('FAFAFA_GHASH_PURE_MODE', M);
end;

procedure TTestCase_GHash_PureMode_Sweep.Test_Sweep_Modes_Run_KAT_And_Property;
var m: String;
begin
  for m in ['bit','nibble','byte'] do
  begin
    SetMode(m);
    RunKAT_AllZero;
    RunProperty_AssocAndLength;
  end;
end;

initialization
  RegisterTest(TTestCase_GHash_PureMode_Sweep);

end.

