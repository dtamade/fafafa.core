unit Test_fafafa_core_json_facade_iter_raw;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.mem.allocator,
  fafafa.core.json.core,
  fafafa.core.json;

procedure RegisterTests;

implementation

type
  TTestCase_FacadeIterRaw = class(TTestCase)
  published
    procedure Test_Object_ForEachRaw_Keys_And_EarlyStop;
    procedure Test_ForEachRaw_NonObject_ReturnsFalse;
  end;

procedure TTestCase_FacadeIterRaw.Test_Object_ForEachRaw_Keys_And_EarlyStop;
var
  D: TJsonDocument; Doc: IJsonDocument; Obj: IJsonValue; Keys: array of String; Count: Integer; Ok: Boolean;
begin
  D := JsonRead(PChar('{"a":1,"b":2,"c":3}'), Length('{"a":1,"b":2,"c":3}'), []);
  Doc := JsonWrapDocument(D);
  Obj := Doc.Root;
  SetLength(Keys, 0); Count := 0;
  Ok := JsonObjectForEachRaw(Obj,
    function(KeyPtr: PChar; KeyLen: SizeUInt; Value: IJsonValue): Boolean
    var K: String;
    begin
      Inc(Count);
      SetString(K, KeyPtr, KeyLen);
      SetLength(Keys, Length(Keys)+1);
      Keys[High(Keys)] := K;
      Result := Count < 2; // 只取前两个键
    end);
  AssertTrue('should be object', Ok);
  AssertEquals('two keys visited', 2, Count);
  AssertTrue('keys non-empty', (Length(Keys)>=2) and (Keys[0]<>''));
end;

procedure TTestCase_FacadeIterRaw.Test_ForEachRaw_NonObject_ReturnsFalse;
var
  D: TJsonDocument; Doc: IJsonDocument; Val: IJsonValue; Ok: Boolean;
begin
  D := JsonRead(PChar('123'), Length('123'), []);
  Doc := JsonWrapDocument(D);
  Val := Doc.Root;
  Ok := JsonObjectForEachRaw(Val,
    function(KeyPtr: PChar; KeyLen: SizeUInt; Value: IJsonValue): Boolean begin Result := True; end);
  AssertFalse('number is not object', Ok);
end;

procedure RegisterTests;
begin
  RegisterTest('json-facade', TTestCase_FacadeIterRaw.Suite);
end;

initialization
  RegisterTests;

end.

