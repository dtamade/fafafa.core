unit Test_fafafa_core_json_facade_iter;

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
  TTestCase_FacadeIter = class(TTestCase)
  published
    procedure Test_Array_ForEach_Order_And_EarlyStop;
    procedure Test_Object_ForEach_Keys_And_EarlyStop;
    procedure Test_ForEach_NonContainer_ReturnsFalse;
  end;

procedure TTestCase_FacadeIter.Test_Array_ForEach_Order_And_EarlyStop;
var
  D: TJsonDocument; Doc: IJsonDocument; Arr: IJsonValue; Sum, Count: Integer; Ok: Boolean;
begin
  D := JsonRead(PChar('[1,2,3,4]'), Length('[1,2,3,4]'), [jrfDefault]);
  Doc := JsonWrapDocument(D);
  Arr := Doc.Root;
  Sum := 0; Count := 0;
  Ok := JsonArrayForEach(Arr,
    function(Index: SizeUInt; Item: IJsonValue): Boolean
    begin
      Inc(Count);
      Sum := Sum + Item.GetInteger;
      Result := Index < 1; // 只遍历 0,1 两个元素
    end);
  AssertTrue('should be array', Ok);
  AssertEquals('two elements counted', 2, Count);
  AssertEquals('sum of first two', 1+2, Sum);
end;

procedure TTestCase_FacadeIter.Test_Object_ForEach_Keys_And_EarlyStop;
var
  D: TJsonDocument; Doc: IJsonDocument; Obj: IJsonValue; Keys: array of String; Count: Integer; Ok: Boolean;
begin
  D := JsonRead(PChar('{"a":1,"b":2,"c":3}'), Length('{"a":1,"b":2,"c":3}'), [jrfDefault]);
  Doc := JsonWrapDocument(D);
  Obj := Doc.Root;
  SetLength(Keys, 0); Count := 0;
  Ok := JsonObjectForEach(Obj,
    function(const Key: String; Value: IJsonValue): Boolean
    begin
      Inc(Count);
      SetLength(Keys, Length(Keys)+1);
      Keys[High(Keys)] := Key;
      Result := Count < 2; // 只取前两个键
    end);
  AssertTrue('should be object', Ok);
  AssertEquals('two keys visited', 2, Count);
  AssertTrue('keys non-empty', (Length(Keys)>=2) and (Keys[0]<>''));
end;

procedure TTestCase_FacadeIter.Test_ForEach_NonContainer_ReturnsFalse;
var
  D: TJsonDocument; Doc: IJsonDocument; Val: IJsonValue; Ok: Boolean;
begin
  D := JsonRead(PChar('123'), Length('123'), [jrfDefault]);
  Doc := JsonWrapDocument(D);
  Val := Doc.Root;
  Ok := JsonArrayForEach(Val,
    function(Index: SizeUInt; Item: IJsonValue): Boolean begin Result := True; end);
  AssertFalse('number is not array', Ok);
  Ok := JsonObjectForEach(Val,
    function(const Key: String; Value: IJsonValue): Boolean begin Result := True; end);
  AssertFalse('number is not object', Ok);
end;

procedure RegisterTests;
begin
  RegisterTest('json-facade', TTestCase_FacadeIter.Suite);
end;

initialization
  RegisterTests;

end.

