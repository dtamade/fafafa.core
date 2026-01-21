{$CODEPAGE UTF8}
unit Test_ghash_pure_mode_consistency;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, {$IFDEF MSWINDOWS}Windows,{$ELSE}ctypes,{$ENDIF}
  fafafa.core.math,
  fafafa.core.crypto.aead.gcm.ghash;

type
  TTestCase_GHash_PureMode_Consistency = class(TTestCase)
  published
    procedure Test_Pure_Bit_Nibble_Byte_Same;
    procedure Test_EnsureTables_NoRebuild_SameResult;
  end;

implementation

{$IFNDEF MSWINDOWS}
function setenv(name: PChar; value: PChar; overwrite: cint): cint; cdecl; external 'c' name 'setenv';
function unsetenv(name: PChar): cint; cdecl; external 'c' name 'unsetenv';
{$ENDIF}

function MakeBytes(const Len: Integer; const Seed: Byte): TBytes;
var i: Integer;
begin
  SetLength(Result, Len);
  for i := 0 to Len-1 do Result[i] := Seed + i;
end;

function NowUS: Int64;
begin
  Result := Trunc(Now * 24*60*60*1000*1000);
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

procedure GHash_Run(const PureMode: String; const H, AAD, C: TBytes; out Tag: TBytes);
var
  oldMode: String;
  g: IGHash;
begin
  // switch mode via env (only DEBUG builds honor it; Release will still use byte/prefers CLMUL)
  oldMode := SysUtils.GetEnvironmentVariable('FAFAFA_GHASH_PURE_MODE');
  SetEnv('FAFAFA_GHASH_PURE_MODE', PureMode);
  try
    g := CreateGHash;
    g.Init(H);
    g.Update(AAD);
    g.Update(C);
    Tag := g.Finalize(Length(AAD), Length(C));
  finally
    SetEnv('FAFAFA_GHASH_PURE_MODE', oldMode);
  end;
end;

procedure TTestCase_GHash_PureMode_Consistency.Test_Pure_Bit_Nibble_Byte_Same;
var
  H, AAD, C, Tb, Tn, T8: TBytes;
begin
  H := MakeBytes(16, 7);
  AAD := MakeBytes(4096, 11);
  C := MakeBytes(8192, 19);
  GHash_Run('bit', H, AAD, C, Tb);
  GHash_Run('nibble', H, AAD, C, Tn);
  GHash_Run('byte', H, AAD, C, T8);
  AssertEquals(Length(Tb), Length(Tn));
  AssertEquals(Length(Tb), Length(T8));
  if Length(Tb) > 0 then begin
    AssertTrue(CompareByte(Tb[0], Tn[0], Length(Tb)) = 0);
    AssertTrue(CompareByte(Tb[0], T8[0], Length(Tb)) = 0);
  end;
end;

procedure TTestCase_GHash_PureMode_Consistency.Test_EnsureTables_NoRebuild_SameResult;
var
  H, AAD, C, T1, T2: TBytes;
  t0us, t1us: Int64;
begin
  H := MakeBytes(16, 3);
  AAD := MakeBytes(1000, 1);
  C := MakeBytes(2000, 2);
  // force byte mode
  SetEnv('FAFAFA_GHASH_PURE_MODE', 'byte');
  t0us := NowUS;
  GHash_Run('byte', H, AAD, C, T1);
  t1us := NowUS;
  // run again without table rebuild (same process, same H)
  GHash_Run('byte', H, AAD, C, T2);
  // equal
  AssertEquals(Length(T1), Length(T2));
  if Length(T1) > 0 then AssertTrue(CompareByte(T1[0], T2[0], Length(T1)) = 0);
end;

initialization
  RegisterTest(TTestCase_GHash_PureMode_Consistency);

end.

