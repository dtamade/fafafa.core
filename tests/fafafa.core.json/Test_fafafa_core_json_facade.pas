unit Test_fafafa_core_json_facade;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.mem.allocator,
  fafafa.core.json;

procedure RegisterTests;

implementation

type
  TTestCase_Facade = class(TTestCase)
  published
    procedure Test_Read_Object_And_Getters;
    procedure Test_Pointer_Get;
  end;

procedure TTestCase_Facade.Test_Read_Object_And_Getters;
var
  R: IJsonReader;
  D: IJsonDocument;
  V, Item: IJsonValue;
begin
  R := CreateJsonReader(GetRtlAllocator);
  D := R.ReadFromString('{"name":"Alice","age":30,"tags":["dev","json"]}');
  V := D.Root;
  AssertTrue(Assigned(V));
  AssertTrue(V.IsObject);
  Item := V.GetObjectValue('name');
  AssertTrue(Assigned(Item));
  AssertTrue(Item.IsString);
  AssertEquals('Alice', Item.GetString);
  Item := V.GetObjectValue('age');
  AssertTrue(Assigned(Item));
  AssertTrue(Item.IsNumber);
  AssertEquals(30, Item.GetInteger);
end;

procedure TTestCase_Facade.Test_Pointer_Get;
var
  R: IJsonReader;
  D: IJsonDocument;
  V: IJsonValue;
begin
  R := CreateJsonReader(GetRtlAllocator);
  D := R.ReadFromString('{"name":"Alice","age":30,"tags":["dev","json"]}');
  V := JsonPointerGet(D, '/tags/1');
  AssertTrue(Assigned(V));
  AssertTrue(V.IsString);
  AssertEquals('json', V.GetString);
end;

procedure RegisterTests;
begin
  RegisterTest('json-facade', TTestCase_Facade.Suite);
end;

initialization
  RegisterTests;

end.

