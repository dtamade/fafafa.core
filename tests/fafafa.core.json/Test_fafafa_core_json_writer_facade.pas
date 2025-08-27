unit Test_fafafa_core_json_writer_facade;

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
  TTestCase_WriterFacade = class(TTestCase)
  published
    procedure Test_Write_Object_Min;
  end;

procedure TTestCase_WriterFacade.Test_Write_Object_Min;
var
  D: TJsonDocument;
  S: String;
  W: IJsonWriter;
  DocFacade: IJsonDocument;
  D2: TJsonDocument;
  Root, VA: PJsonValue;
begin
  // 使用 fixed 构建一个最小文档：{"a":1}
  D := JsonRead(PChar('{"a":1}'), Length('{"a":1}'), [jrfDefault]);
  try
    // 转为门面 Document
    DocFacade := JsonWrapDocument(D);
    W := CreateJsonWriter;
    S := W.WriteToString(DocFacade, [jwfPretty]);
    // 更稳健：用 round-trip 校验
    AssertTrue('Writer returned empty string', Length(S) > 0);
    D2 := JsonRead(PChar(S), Length(S), [jrfDefault]);
    AssertTrue('Round-trip parse failed', D2 <> nil);
    try
      Root := JsonDocGetRoot(D2);
      AssertTrue('Root should be object', JsonIsObj(Root));
      VA := JsonObjGet(Root, 'a');
      AssertTrue('Key a not found', VA <> nil);
      AssertTrue('Value of a must be number', JsonIsNum(VA));
      AssertEquals(1, Integer(JsonGetUint(VA)));
    finally
      JsonDocFree(D2);
    end;
  finally
    // 注意：DocFacade.Destroy 会释放 D，此处不调用 JsonDocFree(D)
  end;
end;

procedure RegisterTests;
begin
  RegisterTest('json-facade', TTestCase_WriterFacade.Suite);
end;

initialization
  RegisterTests;

end.

