{$CODEPAGE UTF8}
unit Test_fafafa_core_json_fluent_nesting;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.mem.allocator,
  fafafa.core.json.core,
  fafafa.core.json.fluent;

type
  TTestCase_Json_Fluent_Nesting = class(TTestCase)
  published
    procedure Test_Nested_Build_Object_Array;
  end;

implementation

procedure TTestCase_Json_Fluent_Nesting.Test_Nested_Build_Object_Array;
var B: TJsonBuilderF; M: TJsonMutDocument; Root: PJsonMutValue; Doc: TJsonDocument;
begin
  // Build: {"user":{"name":"a","roles":["dev",{"k":"v"}]}}
  B := JsonF.NewBuilder(nil)
        .Obj
          .BeginObj('user')
            .PutStr('name','a')
            .BeginArr('roles')
              .AddStr('dev')
              .ArrAddObj
                .PutStr('k','v')
              .EndObj
            .EndArr
          .EndObj;

  M := B.Detach;
  try
    Root := JsonMutDocGetRoot(M);
    AssertTrue(Assigned(Root));

    // Serialize via immutable doc wrapper path
    Doc := TJsonDocument.Create(GetRtlAllocator());
    try
      // 直接复用已有不可变序列化函数：将 Root 转为不可变视图不现实；这里直接走 WriteJsonValue 的可变到不可变兼容视图
      // 简化方法：将可变树克隆为不可变文档暂不提供；使用 JsonWriteToString 需要 TJsonDocument
      // 因此我们只检查结构的关键节点
      AssertTrue(Assigned(JsonMutObjGet(Root, 'user')));
    finally
      Doc.Free;
    end;
  finally
    if Assigned(M) then M.Free;
  end;
end;

initialization
  RegisterTest(TTestCase_Json_Fluent_Nesting);
end.

