{$CODEPAGE UTF8}
unit Test_fafafa_core_json;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.mem.allocator,
  fafafa.core.json.core; // 切换为 core 实现

// 全局函数/过程测试
type
  TTestCase_Global = class(TTestCase)
  published
    procedure Test_Read_Null;
    procedure Test_Read_Boolean;
    procedure Test_Read_Number_Int;
    procedure Test_Read_Number_Float;
    procedure Test_Read_String;
    procedure Test_Read_Array;
    procedure Test_Read_Object;
    procedure Test_Error_Position_UnexpectedChar;
  end;

implementation

procedure TTestCase_Global.Test_Read_Null;
var
  LDoc: TJsonDocument;
  LErr: TJsonError;
begin
  LErr := Default(TJsonError);
  LDoc := JsonReadOpts('null', 4, [jrfDefault], GetRtlAllocator(), LErr);
  AssertTrue('Doc should not be nil', Assigned(LDoc));
  AssertTrue('Root should be null', UnsafeIsNull(LDoc.Root));
  LDoc.Free;
end;

procedure TTestCase_Global.Test_Read_Boolean;
var
  LDoc: TJsonDocument;
  LErr: TJsonError;
begin
  LErr := Default(TJsonError);
  LDoc := JsonReadOpts('true', 4, [jrfDefault], GetRtlAllocator(), LErr);
  AssertTrue(Assigned(LDoc));
  AssertTrue('Root should be bool true', UnsafeIsTrue(LDoc.Root));
  LDoc.Free;

  LDoc := JsonReadOpts('false', 5, [jrfDefault], GetRtlAllocator(), LErr);
  AssertTrue(Assigned(LDoc));
  AssertTrue('Root should be bool false', UnsafeIsFalse(LDoc.Root));
  LDoc.Free;
end;

procedure TTestCase_Global.Test_Read_Number_Int;
var
  LDoc: TJsonDocument;
  LErr: TJsonError;
begin
  LErr := Default(TJsonError);
  LDoc := JsonReadOpts('123', 3, [jrfDefault], GetRtlAllocator(), LErr);
  AssertTrue(Assigned(LDoc));
  AssertTrue('Root should be number', UnsafeIsNum(LDoc.Root));
  AssertEquals('123', WriteJsonNumber(LDoc.Root, []));
  LDoc.Free;
end;

procedure TTestCase_Global.Test_Read_Number_Float;
var LDoc: TJsonDocument; LErr: TJsonError;
begin
  LErr := Default(TJsonError);
  LDoc := JsonReadOpts('3.14', 4, [jrfDefault], GetRtlAllocator(), LErr);
  AssertTrue(Assigned(LDoc));
  AssertTrue('Root should be number', UnsafeIsNum(LDoc.Root));
  AssertEquals('3.14', WriteJsonNumber(LDoc.Root, []));
  LDoc.Free;
end;

procedure TTestCase_Global.Test_Read_String;
var LDoc: TJsonDocument; LErr: TJsonError;
begin
  LErr := Default(TJsonError);
  LDoc := JsonReadOpts('"hi"', 4, [jrfDefault], GetRtlAllocator(), LErr);
  AssertTrue(Assigned(LDoc));
  AssertTrue('Root should be string', UnsafeIsStr(LDoc.Root));
  AssertTrue('String equals', JsonEqualsStrUtf8(LDoc.Root, UTF8String('hi')));
  LDoc.Free;
end;

procedure TTestCase_Global.Test_Read_Array;
var LDoc: TJsonDocument; LErr: TJsonError; Iter: TJsonArrayIterator; PIter: PJsonArrayIterator; Item: PJsonValue;
begin
  LErr := Default(TJsonError);
  LDoc := JsonReadOpts('[1,2,3]', 7, [jrfDefault], GetRtlAllocator(), LErr);
  AssertTrue(Assigned(LDoc));
  AssertTrue('Root should be array', UnsafeIsArr(LDoc.Root));
  PIter := @Iter;
  AssertTrue('Iter init', JsonArrIterInit(LDoc.Root, PIter));
  Item := JsonArrIterNext(PIter);
  AssertTrue(Assigned(Item) and UnsafeIsNum(Item));
  Item := JsonArrIterNext(PIter);
  AssertTrue(Assigned(Item) and UnsafeIsNum(Item));
  Item := JsonArrIterNext(PIter);
  AssertTrue(Assigned(Item) and UnsafeIsNum(Item));
  AssertTrue('No more', JsonArrIterNext(PIter) = nil);
  LDoc.Free;
end;

procedure TTestCase_Global.Test_Read_Object;
var LDoc: TJsonDocument; LErr: TJsonError; Iter: TJsonObjectIterator; PIter: PJsonObjectIterator; Key, Val: PJsonValue;
begin
  LErr := Default(TJsonError);
  LDoc := JsonReadOpts('{"a":1,"b":2}', 13, [jrfDefault], GetRtlAllocator(), LErr);
  AssertTrue(Assigned(LDoc));
  AssertTrue('Root should be object', UnsafeIsObj(LDoc.Root));
  PIter := @Iter;
  AssertTrue('Iter init', JsonObjIterInit(LDoc.Root, PIter));
  Key := JsonObjIterNext(PIter);
  AssertTrue(Assigned(Key));
  Val := JsonObjIterGetVal(Key);
  AssertTrue(UnsafeIsStr(Key) and UnsafeIsNum(Val));
  Key := JsonObjIterNext(PIter);
  AssertTrue(Assigned(Key));
  Val := JsonObjIterGetVal(Key);
  AssertTrue(UnsafeIsStr(Key) and UnsafeIsNum(Val));
  AssertFalse(JsonObjIterHasNext(PIter));
  LDoc.Free;
end;

procedure TTestCase_Global.Test_Error_Position_UnexpectedChar;
var LDoc: TJsonDocument; LErr: TJsonError;
begin
  LErr := Default(TJsonError);
  LDoc := JsonReadOpts('x', 1, [jrfDefault], GetRtlAllocator(), LErr);
  AssertTrue('Should fail doc', not Assigned(LDoc));
  AssertTrue('Error should be set', LErr.Code <> jecSuccess);
  AssertEquals('Unexpected', Copy(LErr.Message, 1, 10));
end;

initialization
  RegisterTest(TTestCase_Global);
end.

