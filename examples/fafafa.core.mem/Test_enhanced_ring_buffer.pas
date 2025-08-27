{$CODEPAGE UTF8}
unit Test_enhanced_ring_buffer;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes, fpcunit, testregistry, fafafa.core.mem.enhancedRingBuffer;

type
  TTestCase_EnhancedRingBuffer = class(TTestCase)
  published
    procedure Test_Basic_Operations;
    procedure Test_Batch_Operations;
    procedure Test_Type_Specific_Operations;
    procedure Test_String_Operations;
    procedure Test_Search_Operations;
    procedure Test_Advanced_Operations;
    procedure Test_StringRingBuffer;
    procedure Test_ByteRingBuffer;
    procedure Test_TypedRingBuffer;
  end;

implementation

procedure TTestCase_EnhancedRingBuffer.Test_Basic_Operations;
var
  rb: TEnhancedRingBuffer;
  data1, data2: Integer;
const
  CAPACITY = 10;
begin
  rb := TEnhancedRingBuffer.Create(CAPACITY, SizeOf(Integer));
  try
    AssertTrue('Should be empty initially', rb.IsEmpty);
    AssertFalse('Should not be full initially', rb.IsFull);
    AssertEquals('Count should be 0', 0, rb.Count);
    
    // 测试基本推入/弹出
    data1 := 42;
    AssertTrue('Push should succeed', rb.Push(@data1));
    AssertFalse('Should not be empty after push', rb.IsEmpty);
    AssertEquals('Count should be 1', 1, rb.Count);
    
    data2 := 0;
    AssertTrue('Pop should succeed', rb.Pop(@data2));
    AssertEquals('Popped value should match', data1, data2);
    AssertTrue('Should be empty after pop', rb.IsEmpty);
    
  finally
    rb.Free;
  end;
end;

procedure TTestCase_EnhancedRingBuffer.Test_Batch_Operations;
var
  rb: TEnhancedRingBuffer;
  inputData, outputData: array[0..4] of Integer;
  i, pushed, popped: SizeUInt;
const
  CAPACITY = 10;
  BATCH_SIZE = 5;
begin
  rb := TEnhancedRingBuffer.Create(CAPACITY, SizeOf(Integer));
  try
    // 准备测试数据
    for i := 0 to BATCH_SIZE - 1 do
      inputData[i] := (i + 1) * 10;
    
    // 测试批量推入
    pushed := rb.PushBatch(@inputData[0], BATCH_SIZE);
    AssertEquals('Should push all elements', BATCH_SIZE, pushed);
    AssertEquals('Count should match', BATCH_SIZE, rb.Count);
    
    // 测试批量弹出
    FillChar(outputData, SizeOf(outputData), 0);
    popped := rb.PopBatch(@outputData[0], BATCH_SIZE);
    AssertEquals('Should pop all elements', BATCH_SIZE, popped);
    
    // 验证数据
    for i := 0 to BATCH_SIZE - 1 do
      AssertEquals(Format('Data %d should match', [i]), inputData[i], outputData[i]);
    
    AssertTrue('Should be empty after batch pop', rb.IsEmpty);
    
  finally
    rb.Free;
  end;
end;

procedure TTestCase_EnhancedRingBuffer.Test_Type_Specific_Operations;
var
  intRb: TEnhancedRingBuffer;
  doubleRb: TEnhancedRingBuffer;
  intVal: Integer;
  doubleVal: Double;
const
  CAPACITY = 5;
begin
  // 测试整数操作
  intRb := TEnhancedRingBuffer.Create(CAPACITY, SizeOf(Integer));
  try
    AssertTrue('PushInteger should succeed', intRb.PushInteger(123));
    AssertTrue('PopInteger should succeed', intRb.PopInteger(intVal));
    AssertEquals('Integer value should match', 123, intVal);
  finally
    intRb.Free;
  end;
  
  // 测试双精度浮点数操作
  doubleRb := TEnhancedRingBuffer.Create(CAPACITY, SizeOf(Double));
  try
    AssertTrue('PushDouble should succeed', doubleRb.PushDouble(3.14159));
    AssertTrue('PopDouble should succeed', doubleRb.PopDouble(doubleVal));
    AssertEquals('Double value should match', 3.14159, doubleVal, 0.00001);
  finally
    doubleRb.Free;
  end;
end;

procedure TTestCase_EnhancedRingBuffer.Test_String_Operations;
var
  rb: TEnhancedRingBuffer;
  testStr, resultStr: string;
const
  CAPACITY = 1000; // 需要足够大以容纳字符串数据
begin
  rb := TEnhancedRingBuffer.Create(CAPACITY, SizeOf(Byte));
  try
    testStr := 'Hello, 世界! 🌍';
    
    AssertTrue('PushString should succeed', rb.PushString(testStr));
    AssertTrue('PopString should succeed', rb.PopString(resultStr));
    AssertEquals('String should match', testStr, resultStr);
    
    // 测试空字符串
    testStr := '';
    AssertTrue('PushString empty should succeed', rb.PushString(testStr));
    AssertTrue('PopString empty should succeed', rb.PopString(resultStr));
    AssertEquals('Empty string should match', testStr, resultStr);
    
  finally
    rb.Free;
  end;
end;

procedure TTestCase_EnhancedRingBuffer.Test_Search_Operations;
var
  rb: TEnhancedRingBuffer;
  data: array[0..4] of Integer;
  i: Integer;
  searchVal: Integer;
const
  CAPACITY = 10;
begin
  rb := TEnhancedRingBuffer.Create(CAPACITY, SizeOf(Integer));
  try
    // 填充数据
    for i := 0 to 4 do
    begin
      data[i] := (i + 1) * 10;
      AssertTrue(Format('Push %d should succeed', [i]), rb.Push(@data[i]));
    end;
    
    // 测试查找存在的元素
    searchVal := 30;
    AssertEquals('Should find element at position 2', 2, rb.FindElement(@searchVal));
    AssertTrue('Should contain element', rb.ContainsElement(@searchVal));
    
    // 测试查找不存在的元素
    searchVal := 99;
    AssertEquals('Should not find non-existent element', -1, rb.FindElement(@searchVal));
    AssertFalse('Should not contain non-existent element', rb.ContainsElement(@searchVal));
    
  finally
    rb.Free;
  end;
end;

procedure TTestCase_EnhancedRingBuffer.Test_Advanced_Operations;
var
  rb: TEnhancedRingBuffer;
  data: array[0..2] of Integer;
  i: Integer;
  getValue, setValue: Integer;
  dropped: SizeUInt;
const
  CAPACITY = 10;
begin
  rb := TEnhancedRingBuffer.Create(CAPACITY, SizeOf(Integer));
  try
    // 填充数据
    for i := 0 to 2 do
    begin
      data[i] := (i + 1) * 100;
      AssertTrue(Format('Push %d should succeed', [i]), rb.Push(@data[i]));
    end;
    
    // 测试 GetElementAt
    AssertTrue('GetElementAt should succeed', rb.GetElementAt(1, @getValue));
    AssertEquals('Element at index 1 should match', 200, getValue);
    
    // 测试 SetElementAt
    setValue := 999;
    AssertTrue('SetElementAt should succeed', rb.SetElementAt(1, @setValue));
    AssertTrue('GetElementAt after set should succeed', rb.GetElementAt(1, @getValue));
    AssertEquals('Modified element should match', 999, getValue);
    
    // 测试 DropElements
    dropped := rb.DropElements(2);
    AssertEquals('Should drop 2 elements', 2, dropped);
    AssertEquals('Count should be 1 after drop', 1, rb.Count);
    
  finally
    rb.Free;
  end;
end;

procedure TTestCase_EnhancedRingBuffer.Test_StringRingBuffer;
var
  srb: TStringRingBuffer;
  testStr, resultStr: string;
  strings: array[0..2] of string;
  pushed: SizeUInt;
const
  CAPACITY = 1000;
begin
  srb := TStringRingBuffer.Create(CAPACITY);
  try
    // 测试单个字符串操作
    testStr := 'Test String';
    AssertTrue('PushStr should succeed', srb.PushStr(testStr));
    AssertTrue('PopStr should succeed', srb.PopStr(resultStr));
    AssertEquals('String should match', testStr, resultStr);
    
    // 测试批量字符串操作
    strings[0] := 'First';
    strings[1] := 'Second';
    strings[2] := 'Third';
    
    pushed := srb.PushStrings(strings);
    AssertEquals('Should push all strings', 3, pushed);
    
  finally
    srb.Free;
  end;
end;

procedure TTestCase_EnhancedRingBuffer.Test_ByteRingBuffer;
var
  brb: TByteRingBuffer;
  testByte, resultByte: Byte;
  bytes: array[0..3] of Byte;
  pushed: SizeUInt;
  i: Integer;
const
  CAPACITY = 100;
begin
  brb := TByteRingBuffer.Create(CAPACITY);
  try
    // 测试单个字节操作
    testByte := $42;
    AssertTrue('PushByte should succeed', brb.PushByte(testByte));
    AssertTrue('PopByte should succeed', brb.PopByte(resultByte));
    AssertEquals('Byte should match', testByte, resultByte);
    
    // 测试字节数组操作
    for i := 0 to 3 do
      bytes[i] := $10 + i;
    
    pushed := brb.PushByteArray(bytes);
    AssertEquals('Should push all bytes', 4, pushed);
    
    // 测试查找字节
    AssertEquals('Should find byte at position 1', 1, brb.FindByte($11));
    AssertEquals('Should not find non-existent byte', -1, brb.FindByte($FF));
    
  finally
    brb.Free;
  end;
end;

procedure TTestCase_EnhancedRingBuffer.Test_TypedRingBuffer;
type
  TIntRingBuffer = specialize TTypedEnhancedRingBuffer<Integer>;
var
  trb: TIntRingBuffer;
  testVal, resultVal: Integer;
  values: array[0..2] of Integer;
  pushed: SizeUInt;
  i: Integer;
const
  CAPACITY = 10;
begin
  trb := TIntRingBuffer.Create(CAPACITY);
  try
    // 测试类型安全的基本操作
    testVal := 42;
    AssertTrue('Push should succeed', trb.Push(testVal));
    AssertTrue('Pop should succeed', trb.Pop(resultVal));
    AssertEquals('Value should match', testVal, resultVal);
    
    // 测试类型安全的数组操作
    for i := 0 to 2 do
      values[i] := (i + 1) * 10;
    
    pushed := trb.PushArray(values);
    AssertEquals('Should push all values', 3, pushed);
    
    // 测试查找
    AssertEquals('Should find value at position 1', 1, trb.Find(20));
    AssertTrue('Should contain value', trb.Contains(30));
    AssertFalse('Should not contain non-existent value', trb.Contains(99));
    
  finally
    trb.Free;
  end;
end;

initialization
  RegisterTest(TTestCase_EnhancedRingBuffer);

end.
