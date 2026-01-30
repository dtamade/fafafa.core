program simple_json_number_test;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.mem.allocator,
  fafafa.core.json.core;

var
  T, P, F: Integer;

procedure Ok(const Msg: string; Cond: Boolean);
begin
  Inc(T); if Cond then begin Inc(P); WriteLn('✓ ', Msg); end else begin Inc(F); WriteLn('✗ ', Msg); end;
end;

function ReadNumOk(const S: string; out Val: PJsonValue; out Doc: TJsonDocument): Boolean;
var Root: PJsonValue;
begin
  Doc := JsonRead(PChar(S), Length(S), []);
  Result := Assigned(Doc);
  if Result then begin
    Root := JsonDocGetRoot(Doc);
    Result := Assigned(Root) and JsonIsNum(Root);
    if Result then Val := Root else Val := nil;
  end;
end;

procedure Test_Integers;
var V: PJsonValue; D: TJsonDocument;
begin
  Ok('int: 0', ReadNumOk('0', V, D)); if Assigned(D) then try Ok('is uint', JsonGetType(V) = YYJSON_TYPE_NUM); Ok('tag subtype', (JsonGetType(V)=YYJSON_TYPE_NUM)); finally JsonDocFree(D); end;
  Ok('int: 123', ReadNumOk('123', V, D)); if Assigned(D) then try Ok('get uint=123', JsonGetUint(V)=123); finally JsonDocFree(D); end;
  Ok('int: -1', ReadNumOk('-1', V, D)); if Assigned(D) then try Ok('get int=-1', JsonGetInt(V)=-1); finally JsonDocFree(D); end;
end;

procedure Test_Floats;
var V: PJsonValue; D: TJsonDocument;
begin
  Ok('float: 1.5', ReadNumOk('1.5', V, D)); if Assigned(D) then try Ok('get real ~1.5', Abs(JsonGetReal(V)-1.5) < 1e-12); finally JsonDocFree(D); end;
  Ok('float: 1e3', ReadNumOk('1e3', V, D)); if Assigned(D) then try Ok('get real ~1000', Abs(JsonGetReal(V)-1000.0) < 1e-9); finally JsonDocFree(D); end;
  Ok('float: 1.2e-2', ReadNumOk('1.2e-2', V, D)); if Assigned(D) then try Ok('get real ~0.012', Abs(JsonGetReal(V)-0.012) < 1e-12); finally JsonDocFree(D); end;
end;

procedure Test_Invalid;
var Doc: TJsonDocument; Alc: TAllocator; Err: TJsonError;
begin
  Alc := GetRtlAllocator();
  Doc := JsonReadOpts('01', 2, [], Alc, Err); Ok('invalid leading zero', not Assigned(Doc)); if Assigned(Doc) then JsonDocFree(Doc);
  Doc := JsonReadOpts('-', 1, [], Alc, Err); Ok('invalid single minus', not Assigned(Doc)); if Assigned(Doc) then JsonDocFree(Doc);
  Doc := JsonReadOpts('1.', 2, [], Alc, Err); Ok('invalid decimal without digits', not Assigned(Doc)); if Assigned(Doc) then JsonDocFree(Doc);
  Doc := JsonReadOpts('1e', 2, [], Alc, Err); Ok('invalid exponent without digits', not Assigned(Doc)); if Assigned(Doc) then JsonDocFree(Doc);
end;

begin
  try
    Test_Integers;
    Test_Floats;
    Test_Invalid;
  except on E: Exception do begin Inc(F); WriteLn('Exception: ', E.Message); end; end;
  WriteLn('Total: ', T, ', Pass: ', P, ', Fail: ', F); if F <> 0 then Halt(1);
end.

