{$CODEPAGE UTF8}
unit Test_fafafa_core_json_fluent;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.mem.allocator,
  fafafa.core.json.core,
  fafafa.core.json.fluent;

type
  TTestCase_Json_Fluent = class(TTestCase)
  published
    procedure Test_Parse_Ptr_AsJson;
    procedure Test_Builder_Obj_Arr;
  end;

implementation

procedure TTestCase_Json_Fluent.Test_Parse_Ptr_AsJson;
var E: TJsonError; D: IJsonDocF; S: String; V: PJsonValue;
begin
  D := JsonF.Parse('{"o":{"k":"v"}}', [], nil, E);
  AssertTrue(Assigned(D));
  V := D.Ptr('/o/k');
  AssertTrue(Assigned(V));
  S := D.AsJson([jwfPretty], 2);
  AssertTrue(Pos('"k"', S) > 0);
end;

procedure TTestCase_Json_Fluent.Test_Builder_Obj_Arr;
var B: TJsonBuilderF; M: TJsonMutDocument; Root: PJsonMutValue;
begin
  B := JsonF.NewBuilder(nil)
         .Obj
         .PutStr('k','v')
         .PutInt('n', 1)
         .PutBool('b', True);
  M := B.Detach; // transfer ownership
  try
    Root := JsonMutDocGetRoot(M);
    AssertTrue(Assigned(Root));
    AssertTrue(Assigned(JsonMutObjGet(Root, 'k')));
  finally
    if Assigned(M) then M.Free;
  end;
end;

initialization
  RegisterTest(TTestCase_Json_Fluent);
end.

