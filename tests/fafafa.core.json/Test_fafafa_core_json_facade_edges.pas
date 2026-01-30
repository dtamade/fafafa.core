unit Test_fafafa_core_json_facade_edges;

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
  TTestCase_FacadeEdges = class(TTestCase)
  published
    procedure Test_Writer_NoRoot_Raises;
    procedure Test_Pointer_SlashOnly_Invalid_ReturnsNil;
  end;

procedure TTestCase_FacadeEdges.Test_Writer_NoRoot_Raises;
var
  Alc: TAllocator;
  MD: TJsonMutDocument;
  D: TJsonDocument;
  DocFacade: IJsonDocument;
  W: IJsonWriter;
begin
  // 构造一个无 Root 的不可变文档：先建 mut，再不设 Root，转不可变
  Alc := GetRtlAllocator();
  MD := JsonMutDocNew(Alc);
  try
    // 不设置 Root，直接包成不可变文档，模拟无 Root
    D := TJsonDocument.Create(Alc);
    try
      DocFacade := JsonWrapDocument(D);
      W := CreateJsonWriter;
      try
        W.WriteToString(DocFacade, []);
        Fail('Expected EJsonParseError not raised');
      except
        on E: EJsonParseError do;
      end;
    finally
      // DocFacade 持有 D，按门面约定不重复释放
    end;
  finally
    JsonMutDocFree(MD);
  end;
end;

procedure TTestCase_FacadeEdges.Test_Pointer_SlashOnly_Invalid_ReturnsNil;
var
  D: TJsonDocument;
  DocFacade: IJsonDocument;
  V: IJsonValue;
begin
  D := JsonRead(PChar('{"a":1}'), Length('{"a":1}'), [jrfDefault]);
  DocFacade := JsonWrapDocument(D);
  V := JsonPointerGet(DocFacade, '/');
  AssertTrue('Slash only pointer should return nil', V = nil);
end;

procedure RegisterTests;
begin
  RegisterTest('json-facade', TTestCase_FacadeEdges.Suite);
end;

initialization
  RegisterTests;

end.

