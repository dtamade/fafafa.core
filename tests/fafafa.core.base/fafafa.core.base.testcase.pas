unit fafafa.core.base.testcase;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.base, fafafa.core.xml;

type
  { TTestCoreBase - fafafa.core.base 模块测试 }
  TTestCoreBase = class(TTestCase)
  published
    { 版本常量测试 }
    procedure Test_Version_Constant_Exists;
    procedure Test_Version_Format;

    { TTuple2 测试 }
    procedure Test_TTuple2_Create_IntString;
    procedure Test_TTuple2_Create_IntInt;
    procedure Test_TTuple2_Create_StringString;
    procedure Test_TTuple2_Fields_Access;

    { TTuple3 测试 }
    procedure Test_TTuple3_Create;
    procedure Test_TTuple3_Fields_Access;
    procedure Test_TTuple3_Create_DifferentTypes;

    { TTuple4 测试 }
    procedure Test_TTuple4_Create;
    procedure Test_TTuple4_Fields_Access;
    procedure Test_TTuple4_Create_DifferentTypes;

    { 常量测试 }
    procedure Test_MAX_SIZE_INT;
    procedure Test_MIN_SIZE_INT;
    procedure Test_MAX_INT64;
    procedure Test_MIN_INT64;
    procedure Test_SIZE_PTR;

    { P2: 泛型函数类型测试 }
    procedure Test_TFunc_Basic;
    procedure Test_TAction_Basic;
    procedure Test_TThunk_Basic;
    procedure Test_TPredicate_Basic;
    procedure Test_TComparer_Basic;
    procedure Test_TEquality_Basic;
    procedure Test_TBiFunc_Basic;

    { P2: 其他常量测试 }
    procedure Test_MAX_UINT8;
    procedure Test_MAX_INT8;
    procedure Test_MAX_UINT16;
    procedure Test_MAX_INT16;
    procedure Test_MAX_UINT32;
    procedure Test_MAX_INT32;
    procedure Test_MIN_INT8;
    procedure Test_MIN_INT16;
    procedure Test_MIN_INT32;
    procedure Test_SIZE_8;
    procedure Test_SIZE_16;
    procedure Test_SIZE_32;
    procedure Test_SIZE_64;

    { 异常层次结构测试 }
    procedure Test_ECore_Is_Exception;
    procedure Test_EWow_Inherits_ECore;
    procedure Test_EArgumentNil_Inherits_ECore;
    procedure Test_EEmptyCollection_Inherits_ECore;
    procedure Test_EInvalidArgument_Inherits_ECore;
    procedure Test_EInvalidResult_Inherits_ECore;
    procedure Test_ETimeoutError_Inherits_ECore;
    procedure Test_EInvalidState_Inherits_ECore;
    procedure Test_EOutOfRange_Inherits_ECore;
    procedure Test_ENotSupported_Inherits_ECore;
    procedure Test_ENotCompatible_Inherits_ECore;
    procedure Test_EInvalidOperation_Inherits_ECore;
    procedure Test_EOutOfMemory_Inherits_ECore;
    procedure Test_EOverflow_Inherits_ECore;

    { Phase 3.3: Batch 1 - 基础过程类型和类型别名测试 }
    procedure Test_TProc_Basic;
    procedure Test_TObjProc_Basic;
    procedure Test_TStringArray_Basic;
    procedure Test_TBytes_Basic;

    { Phase 3.3: Batch 2 - 缺失常量和异常抛出测试 }
    procedure Test_MAX_SIZE_UINT;
    procedure Test_MAX_UINT64;
    procedure Test_ECore_RaiseAndCatch;
    procedure Test_EArgumentNil_RaiseAndCatch;
    procedure Test_EOutOfRange_RaiseAndCatch;

    { Phase 3.3: Batch 3 - 边界测试和随机生成器测试 }
    procedure Test_TTuple2_EmptyStrings;
    procedure Test_TTuple3_ZeroValues;
    procedure Test_TRandomGeneratorFunc_Basic;
    procedure Test_TRandomGeneratorMethod_Basic;
  end;

implementation

{ Helper functions for generic function type tests }

var
  GlobalTestValue: Integer;

function IntToStrHelper(const Value: Integer): string;
begin
  Result := IntToStr(Value);
end;

procedure SetGlobalValueHelper(const Value: Integer);
begin
  GlobalTestValue := Value;
end;

function GetFortyTwoHelper: Integer;
begin
  Result := 42;
end;

function IsEvenHelper(const Value: Integer): Boolean;
begin
  Result := (Value mod 2) = 0;
end;

function CompareIntHelper(const A, B: Integer): Integer;
begin
  if A < B then
    Result := -1
  else if A > B then
    Result := 1
  else
    Result := 0;
end;

function EqualIntHelper(const A, B: Integer): Boolean;
begin
  Result := A = B;
end;

function AddIntHelper(const A, B: Integer): Integer;
begin
  Result := A + B;
end;

{ TTestCoreBase }

procedure TTestCoreBase.Test_Version_Constant_Exists;
begin
  AssertTrue('Version constant should not be empty', FAFAFA_CORE_BASE_VERSION <> '');
end;

procedure TTestCoreBase.Test_Version_Format;
var
  Parts: TStringArray;
begin
  Parts := FAFAFA_CORE_BASE_VERSION.Split(['.']);
  AssertEquals('Version should have 3 parts (major.minor.patch)', 3, Length(Parts));
end;

{ TTuple2 测试 }

procedure TTestCoreBase.Test_TTuple2_Create_IntString;
type
  TIntStrTuple = specialize TTuple2<Integer, string>;
var
  T: TIntStrTuple;
begin
  T := TIntStrTuple.Create(42, 'hello');
  AssertEquals('First should be 42', 42, T.First);
  AssertEquals('Second should be hello', 'hello', T.Second);
end;

procedure TTestCoreBase.Test_TTuple2_Create_IntInt;
type
  TIntIntTuple = specialize TTuple2<Integer, Integer>;
var
  T: TIntIntTuple;
begin
  T := TIntIntTuple.Create(10, 20);
  AssertEquals('First should be 10', 10, T.First);
  AssertEquals('Second should be 20', 20, T.Second);
end;

procedure TTestCoreBase.Test_TTuple2_Create_StringString;
type
  TStrStrTuple = specialize TTuple2<string, string>;
var
  T: TStrStrTuple;
begin
  T := TStrStrTuple.Create('key', 'value');
  AssertEquals('First should be key', 'key', T.First);
  AssertEquals('Second should be value', 'value', T.Second);
end;

procedure TTestCoreBase.Test_TTuple2_Fields_Access;
type
  TIntStrTuple = specialize TTuple2<Integer, string>;
var
  T: TIntStrTuple;
begin
  T.First := 100;
  T.Second := 'test';
  AssertEquals('First should be 100', 100, T.First);
  AssertEquals('Second should be test', 'test', T.Second);
end;

{ TTuple3 测试 }

procedure TTestCoreBase.Test_TTuple3_Create;
type
  TIntStrBoolTuple = specialize TTuple3<Integer, string, Boolean>;
var
  T: TIntStrBoolTuple;
begin
  T := TIntStrBoolTuple.Create(42, 'hello', True);
  AssertEquals('First should be 42', 42, T.First);
  AssertEquals('Second should be hello', 'hello', T.Second);
  AssertTrue('Third should be True', T.Third);
end;

procedure TTestCoreBase.Test_TTuple3_Fields_Access;
type
  TIntStrBoolTuple = specialize TTuple3<Integer, string, Boolean>;
var
  T: TIntStrBoolTuple;
begin
  T.First := 100;
  T.Second := 'test';
  T.Third := False;
  AssertEquals('First should be 100', 100, T.First);
  AssertEquals('Second should be test', 'test', T.Second);
  AssertFalse('Third should be False', T.Third);
end;

procedure TTestCoreBase.Test_TTuple3_Create_DifferentTypes;
type
  TStrIntDoubleTuple = specialize TTuple3<string, Integer, Double>;
var
  T: TStrIntDoubleTuple;
begin
  T := TStrIntDoubleTuple.Create('key', 123, 45.67);
  AssertEquals('First should be key', 'key', T.First);
  AssertEquals('Second should be 123', 123, T.Second);
  AssertEquals('Third should be 45.67', 45.67, T.Third, 0.001);
end;

{ TTuple4 测试 }

procedure TTestCoreBase.Test_TTuple4_Create;
type
  TIntStrBoolDoubleTuple = specialize TTuple4<Integer, string, Boolean, Double>;
var
  T: TIntStrBoolDoubleTuple;
begin
  T := TIntStrBoolDoubleTuple.Create(42, 'hello', True, 3.14);
  AssertEquals('First should be 42', 42, T.First);
  AssertEquals('Second should be hello', 'hello', T.Second);
  AssertTrue('Third should be True', T.Third);
  AssertEquals('Fourth should be 3.14', 3.14, T.Fourth, 0.001);
end;

procedure TTestCoreBase.Test_TTuple4_Fields_Access;
type
  TIntStrBoolDoubleTuple = specialize TTuple4<Integer, string, Boolean, Double>;
var
  T: TIntStrBoolDoubleTuple;
begin
  T.First := 100;
  T.Second := 'test';
  T.Third := False;
  T.Fourth := 2.71;
  AssertEquals('First should be 100', 100, T.First);
  AssertEquals('Second should be test', 'test', T.Second);
  AssertFalse('Third should be False', T.Third);
  AssertEquals('Fourth should be 2.71', 2.71, T.Fourth, 0.001);
end;

procedure TTestCoreBase.Test_TTuple4_Create_DifferentTypes;
type
  TStrIntDoubleInt64Tuple = specialize TTuple4<string, Integer, Double, Int64>;
var
  T: TStrIntDoubleInt64Tuple;
begin
  T := TStrIntDoubleInt64Tuple.Create('key', 123, 45.67, 9876543210);
  AssertEquals('First should be key', 'key', T.First);
  AssertEquals('Second should be 123', 123, T.Second);
  AssertEquals('Third should be 45.67', 45.67, T.Third, 0.001);
  AssertEquals('Fourth should be 9876543210', Int64(9876543210), T.Fourth);
end;

{ 常量测试 }

procedure TTestCoreBase.Test_MAX_SIZE_INT;
begin
  AssertEquals('MAX_SIZE_INT should equal High(SizeInt)', High(SizeInt), MAX_SIZE_INT);
end;

procedure TTestCoreBase.Test_MIN_SIZE_INT;
begin
  AssertEquals('MIN_SIZE_INT should equal Low(SizeInt)', Low(SizeInt), MIN_SIZE_INT);
end;

procedure TTestCoreBase.Test_MAX_INT64;
begin
  AssertEquals('MAX_INT64 should equal High(Int64)', High(Int64), MAX_INT64);
end;

procedure TTestCoreBase.Test_MIN_INT64;
begin
  AssertEquals('MIN_INT64 should equal Low(Int64)', Low(Int64), MIN_INT64);
end;

procedure TTestCoreBase.Test_SIZE_PTR;
begin
  AssertEquals('SIZE_PTR should equal SizeOf(Pointer)', SizeOf(Pointer), SIZE_PTR);
end;

{ 异常层次结构测试 }

procedure TTestCoreBase.Test_ECore_Is_Exception;
var
  E: ECore;
begin
  E := ECore.Create('test');
  try
    AssertTrue('ECore should be an Exception', E is Exception);
  finally
    E.Free;
  end;
end;

procedure TTestCoreBase.Test_EWow_Inherits_ECore;
var
  E: EWow;
begin
  E := EWow.Create('test');
  try
    AssertTrue('EWow should inherit from ECore', E is ECore);
  finally
    E.Free;
  end;
end;

procedure TTestCoreBase.Test_EArgumentNil_Inherits_ECore;
var
  E: EArgumentNil;
begin
  E := EArgumentNil.Create('test');
  try
    AssertTrue('EArgumentNil should inherit from ECore', E is ECore);
  finally
    E.Free;
  end;
end;

procedure TTestCoreBase.Test_EEmptyCollection_Inherits_ECore;
var
  E: EEmptyCollection;
begin
  E := EEmptyCollection.Create('test');
  try
    AssertTrue('EEmptyCollection should inherit from ECore', E is ECore);
  finally
    E.Free;
  end;
end;

procedure TTestCoreBase.Test_EInvalidArgument_Inherits_ECore;
var
  E: EInvalidArgument;
begin
  E := EInvalidArgument.Create('test');
  try
    AssertTrue('EInvalidArgument should inherit from ECore', E is ECore);
  finally
    E.Free;
  end;
end;

procedure TTestCoreBase.Test_EInvalidResult_Inherits_ECore;
var
  E: EInvalidResult;
begin
  E := EInvalidResult.Create('test');
  try
    AssertTrue('EInvalidResult should inherit from ECore', E is ECore);
  finally
    E.Free;
  end;
end;

procedure TTestCoreBase.Test_ETimeoutError_Inherits_ECore;
var
  E: ETimeoutError;
begin
  E := ETimeoutError.Create('test');
  try
    AssertTrue('ETimeoutError should inherit from ECore', E is ECore);
  finally
    E.Free;
  end;
end;

procedure TTestCoreBase.Test_EInvalidState_Inherits_ECore;
var
  E: EInvalidState;
begin
  E := EInvalidState.Create('test');
  try
    AssertTrue('EInvalidState should inherit from ECore', E is ECore);
  finally
    E.Free;
  end;
end;

procedure TTestCoreBase.Test_EOutOfRange_Inherits_ECore;
var
  E: EOutOfRange;
begin
  E := EOutOfRange.Create('test');
  try
    AssertTrue('EOutOfRange should inherit from ECore', E is ECore);
  finally
    E.Free;
  end;
end;

procedure TTestCoreBase.Test_ENotSupported_Inherits_ECore;
var
  E: ENotSupported;
begin
  E := ENotSupported.Create('test');
  try
    AssertTrue('ENotSupported should inherit from ECore', E is ECore);
  finally
    E.Free;
  end;
end;

procedure TTestCoreBase.Test_ENotCompatible_Inherits_ECore;
var
  E: ENotCompatible;
begin
  E := ENotCompatible.Create('test');
  try
    AssertTrue('ENotCompatible should inherit from ECore', E is ECore);
  finally
    E.Free;
  end;
end;

procedure TTestCoreBase.Test_EInvalidOperation_Inherits_ECore;
var
  E: EInvalidOperation;
begin
  E := EInvalidOperation.Create('test');
  try
    AssertTrue('EInvalidOperation should inherit from ECore', E is ECore);
  finally
    E.Free;
  end;
end;

procedure TTestCoreBase.Test_EOutOfMemory_Inherits_ECore;
var
  E: EOutOfMemory;
begin
  E := EOutOfMemory.Create('test');
  try
    AssertTrue('EOutOfMemory should inherit from ECore', E is ECore);
  finally
    E.Free;
  end;
end;

procedure TTestCoreBase.Test_EOverflow_Inherits_ECore;
var
  E: EOverflow;
begin
  E := EOverflow.Create('test');
  try
    AssertTrue('EOverflow should inherit from ECore', E is ECore);
  finally
    E.Free;
  end;
end;

{ P2: 泛型函数类型测试 }

procedure TTestCoreBase.Test_TFunc_Basic;
type
  TIntToStr = specialize TFunc<Integer, string>;
var
  F: TIntToStr;
  Result: string;
begin
  F := @IntToStrHelper;
  Result := F(42);
  AssertEquals('TFunc should convert 42 to string', '42', Result);
end;

procedure TTestCoreBase.Test_TAction_Basic;
type
  TIntAction = specialize TAction<Integer>;
var
  A: TIntAction;
begin
  GlobalTestValue := 0;
  A := @SetGlobalValueHelper;
  A(42);
  AssertEquals('TAction should set global value to 42', 42, GlobalTestValue);
end;

procedure TTestCoreBase.Test_TThunk_Basic;
type
  TIntThunk = specialize TThunk<Integer>;
var
  T: TIntThunk;
  Result: Integer;
begin
  T := @GetFortyTwoHelper;
  Result := T();
  AssertEquals('TThunk should return 42', 42, Result);
end;

procedure TTestCoreBase.Test_TPredicate_Basic;
type
  TIntPredicate = specialize TPredicate<Integer>;
var
  P: TIntPredicate;
begin
  P := @IsEvenHelper;
  AssertTrue('TPredicate should return True for 42', P(42));
  AssertFalse('TPredicate should return False for 43', P(43));
end;

procedure TTestCoreBase.Test_TComparer_Basic;
type
  TIntComparer = specialize TComparer<Integer>;
var
  C: TIntComparer;
begin
  C := @CompareIntHelper;
  AssertTrue('TComparer should return negative for 10 < 20', C(10, 20) < 0);
  AssertTrue('TComparer should return positive for 20 > 10', C(20, 10) > 0);
  AssertEquals('TComparer should return 0 for 15 = 15', 0, C(15, 15));
end;

procedure TTestCoreBase.Test_TEquality_Basic;
type
  TIntEquality = specialize TEquality<Integer>;
var
  E: TIntEquality;
begin
  E := @EqualIntHelper;
  AssertTrue('TEquality should return True for 42 = 42', E(42, 42));
  AssertFalse('TEquality should return False for 42 <> 43', E(42, 43));
end;

procedure TTestCoreBase.Test_TBiFunc_Basic;
type
  TIntBiFunc = specialize TBiFunc<Integer, Integer, Integer>;
var
  F: TIntBiFunc;
  Result: Integer;
begin
  F := @AddIntHelper;
  Result := F(10, 20);
  AssertEquals('TBiFunc should return 30 for 10 + 20', 30, Result);
end;

{ P2: 其他常量测试 }

procedure TTestCoreBase.Test_MAX_UINT8;
begin
  AssertEquals('MAX_UINT8 should equal High(UInt8)', High(UInt8), MAX_UINT8);
end;

procedure TTestCoreBase.Test_MAX_INT8;
begin
  AssertEquals('MAX_INT8 should equal High(Int8)', High(Int8), MAX_INT8);
end;

procedure TTestCoreBase.Test_MAX_UINT16;
begin
  AssertEquals('MAX_UINT16 should equal High(UInt16)', High(UInt16), MAX_UINT16);
end;

procedure TTestCoreBase.Test_MAX_INT16;
begin
  AssertEquals('MAX_INT16 should equal High(Int16)', High(Int16), MAX_INT16);
end;

procedure TTestCoreBase.Test_MAX_UINT32;
begin
  AssertEquals('MAX_UINT32 should equal High(UInt32)', High(UInt32), MAX_UINT32);
end;

procedure TTestCoreBase.Test_MAX_INT32;
begin
  AssertEquals('MAX_INT32 should equal High(Int32)', High(Int32), MAX_INT32);
end;

procedure TTestCoreBase.Test_MIN_INT8;
begin
  AssertEquals('MIN_INT8 should equal Low(Int8)', Low(Int8), MIN_INT8);
end;

procedure TTestCoreBase.Test_MIN_INT16;
begin
  AssertEquals('MIN_INT16 should equal Low(Int16)', Low(Int16), MIN_INT16);
end;

procedure TTestCoreBase.Test_MIN_INT32;
begin
  AssertEquals('MIN_INT32 should equal Low(Int32)', Low(Int32), MIN_INT32);
end;

procedure TTestCoreBase.Test_SIZE_8;
begin
  AssertEquals('SIZE_8 should equal 1', 1, SIZE_8);
end;

procedure TTestCoreBase.Test_SIZE_16;
begin
  AssertEquals('SIZE_16 should equal 2', 2, SIZE_16);
end;

procedure TTestCoreBase.Test_SIZE_32;
begin
  AssertEquals('SIZE_32 should equal 4', 4, SIZE_32);
end;

procedure TTestCoreBase.Test_SIZE_64;
begin
  AssertEquals('SIZE_64 should equal 8', 8, SIZE_64);
end;

{ Phase 3.3: Batch 1 - 基础过程类型和类型别名测试 }

var
  GlobalProcCalled: Boolean;
  GlobalObjProcValue: Integer;

procedure GlobalProcHelper;
begin
  GlobalProcCalled := True;
end;

type
  TTestObject = class
  public
    procedure ObjProcHelper;
  end;

procedure TTestObject.ObjProcHelper;
begin
  GlobalObjProcValue := 42;
end;

procedure TTestCoreBase.Test_TProc_Basic;
var
  P: TProc;
begin
  GlobalProcCalled := False;
  P := @GlobalProcHelper;
  P();
  AssertTrue('TProc should call the procedure', GlobalProcCalled);
end;

procedure TTestCoreBase.Test_TObjProc_Basic;
var
  Obj: TTestObject;
  P: TObjProc;
begin
  Obj := TTestObject.Create;
  try
    GlobalObjProcValue := 0;
    P := @Obj.ObjProcHelper;
    P();
    AssertEquals('TObjProc should call the object method', 42, GlobalObjProcValue);
  finally
    Obj.Free;
  end;
end;

procedure TTestCoreBase.Test_TStringArray_Basic;
var
  Arr: TStringArray;
begin
  SetLength(Arr, 3);
  Arr[0] := 'first';
  Arr[1] := 'second';
  Arr[2] := 'third';

  AssertEquals('Array length should be 3', 3, Length(Arr));
  AssertEquals('First element should be "first"', 'first', Arr[0]);
  AssertEquals('Second element should be "second"', 'second', Arr[1]);
  AssertEquals('Third element should be "third"', 'third', Arr[2]);
end;

procedure TTestCoreBase.Test_TBytes_Basic;
var
  Bytes: TBytes;
begin
  SetLength(Bytes, 4);
  Bytes[0] := $01;
  Bytes[1] := $02;
  Bytes[2] := $03;
  Bytes[3] := $FF;

  AssertEquals('Bytes length should be 4', 4, Length(Bytes));
  AssertEquals('First byte should be $01', $01, Bytes[0]);
  AssertEquals('Second byte should be $02', $02, Bytes[1]);
  AssertEquals('Third byte should be $03', $03, Bytes[2]);
  AssertEquals('Fourth byte should be $FF', $FF, Bytes[3]);
end;

{ Phase 3.3: Batch 2 - 缺失常量和异常抛出测试 }

procedure TTestCoreBase.Test_MAX_SIZE_UINT;
begin
  AssertEquals('MAX_SIZE_UINT should equal High(SizeUInt)', High(SizeUInt), MAX_SIZE_UINT);
end;

procedure TTestCoreBase.Test_MAX_UINT64;
begin
  AssertEquals('MAX_UINT64 should equal High(UInt64)', High(UInt64), MAX_UINT64);
end;

procedure TTestCoreBase.Test_ECore_RaiseAndCatch;
var
  ExceptionCaught: Boolean;
  ExceptionMessage: string;
begin
  ExceptionCaught := False;
  ExceptionMessage := '';

  try
    raise ECore.Create('Test ECore exception');
  except
    on E: ECore do
    begin
      ExceptionCaught := True;
      ExceptionMessage := E.Message;
    end;
  end;

  AssertTrue('ECore exception should be caught', ExceptionCaught);
  AssertEquals('Exception message should match', 'Test ECore exception', ExceptionMessage);
end;

procedure TTestCoreBase.Test_EArgumentNil_RaiseAndCatch;
var
  ExceptionCaught: Boolean;
  ExceptionMessage: string;
begin
  ExceptionCaught := False;
  ExceptionMessage := '';

  try
    raise EArgumentNil.Create('Argument cannot be nil');
  except
    on E: EArgumentNil do
    begin
      ExceptionCaught := True;
      ExceptionMessage := E.Message;
    end;
  end;

  AssertTrue('EArgumentNil exception should be caught', ExceptionCaught);
  AssertEquals('Exception message should match', 'Argument cannot be nil', ExceptionMessage);
end;

procedure TTestCoreBase.Test_EOutOfRange_RaiseAndCatch;
var
  ExceptionCaught: Boolean;
  ExceptionMessage: string;
begin
  ExceptionCaught := False;
  ExceptionMessage := '';

  try
    raise EOutOfRange.Create('Index out of range');
  except
    on E: EOutOfRange do
    begin
      ExceptionCaught := True;
      ExceptionMessage := E.Message;
    end;
  end;

  AssertTrue('EOutOfRange exception should be caught', ExceptionCaught);
  AssertEquals('Exception message should match', 'Index out of range', ExceptionMessage);
end;

{ Phase 3.3: Batch 3 - 边界测试和随机生成器测试 }

procedure TTestCoreBase.Test_TTuple2_EmptyStrings;
type
  TStrStrTuple = specialize TTuple2<string, string>;
var
  T: TStrStrTuple;
begin
  T := TStrStrTuple.Create('', '');
  AssertEquals('First should be empty string', '', T.First);
  AssertEquals('Second should be empty string', '', T.Second);

  // Test with one empty, one non-empty
  T := TStrStrTuple.Create('', 'value');
  AssertEquals('First should be empty', '', T.First);
  AssertEquals('Second should be value', 'value', T.Second);
end;

procedure TTestCoreBase.Test_TTuple3_ZeroValues;
type
  TIntIntIntTuple = specialize TTuple3<Integer, Integer, Integer>;
var
  T: TIntIntIntTuple;
begin
  T := TIntIntIntTuple.Create(0, 0, 0);
  AssertEquals('First should be 0', 0, T.First);
  AssertEquals('Second should be 0', 0, T.Second);
  AssertEquals('Third should be 0', 0, T.Third);

  // Test with mixed zero and non-zero
  T := TIntIntIntTuple.Create(0, 42, 0);
  AssertEquals('First should be 0', 0, T.First);
  AssertEquals('Second should be 42', 42, T.Second);
  AssertEquals('Third should be 0', 0, T.Third);
end;

function TestRandomGeneratorFunc(aRange: Int64; aData: Pointer): Int64;
begin
  // Simple test implementation: return half of range
  Result := aRange div 2;
end;

procedure TTestCoreBase.Test_TRandomGeneratorFunc_Basic;
var
  Generator: TRandomGeneratorFunc;
  Result: Int64;
begin
  Generator := @TestRandomGeneratorFunc;
  Result := Generator(100, nil);
  AssertEquals('Generator should return 50 for range 100', 50, Result);

  Result := Generator(200, nil);
  AssertEquals('Generator should return 100 for range 200', 100, Result);
end;

type
  TRandomGeneratorObject = class
  public
    function GenerateRandom(aRange: Int64; aData: Pointer): Int64;
  end;

function TRandomGeneratorObject.GenerateRandom(aRange: Int64; aData: Pointer): Int64;
begin
  // Simple test implementation: return one third of range
  Result := aRange div 3;
end;

procedure TTestCoreBase.Test_TRandomGeneratorMethod_Basic;
var
  Obj: TRandomGeneratorObject;
  Generator: TRandomGeneratorMethod;
  Result: Int64;
begin
  Obj := TRandomGeneratorObject.Create;
  try
    Generator := @Obj.GenerateRandom;
    Result := Generator(90, nil);
    AssertEquals('Generator should return 30 for range 90', 30, Result);

    Result := Generator(300, nil);
    AssertEquals('Generator should return 100 for range 300', 100, Result);
  finally
    Obj.Free;
  end;
end;

initialization
  RegisterTest(TTestCoreBase);

end.
