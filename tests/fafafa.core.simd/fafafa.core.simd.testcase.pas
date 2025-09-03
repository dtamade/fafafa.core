unit fafafa.core.simd.testcase;

{$I ../../src/fafafa.core.settings.inc}
{$CODEPAGE UTF8}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.simd.api;

type
  // 全局函数测试
  TTestCase_Global = class(TTestCase)
  published
    // 内存操作函数测试
    procedure Test_MemEqual;
    procedure Test_MemEqual_Empty;
    procedure Test_MemEqual_Nil;
    procedure Test_MemFindByte;
    procedure Test_MemFindByte_NotFound;
    procedure Test_MemFindByte_Empty;
    procedure Test_MemDiffRange;
    procedure Test_MemDiffRange_NoDiff;
    procedure Test_MemCopy;
    procedure Test_MemSet;
    procedure Test_MemReverse;
    
    // 统计函数测试
    procedure Test_SumBytes;
    procedure Test_SumBytes_Empty;
    procedure Test_MinMaxBytes;
    procedure Test_MinMaxBytes_Single;
    procedure Test_CountByte;
    procedure Test_CountByte_None;
    
    // 文本处理函数测试
    procedure Test_Utf8Validate;
    procedure Test_Utf8Validate_Invalid;
    procedure Test_AsciiIEqual;
    procedure Test_AsciiIEqual_CaseDiff;
    procedure Test_ToLowerAscii;
    procedure Test_ToUpperAscii;
    
    // 搜索函数测试
    procedure Test_BytesIndexOf;
    procedure Test_BytesIndexOf_NotFound;
    procedure Test_BytesIndexOf_Empty;
    
    // 位集函数测试
    procedure Test_BitsetPopCount;
    procedure Test_BitsetPopCount_Empty;
    procedure Test_BitsetPopCount_AllSet;
  end;

implementation

{ TTestCase_Global }

// === 内存操作函数测试 ===

procedure TTestCase_Global.Test_MemEqual;
var
  buf1, buf2: array[0..15] of Byte;
  i: Integer;
begin
  // 测试相等的内存区域
  for i := 0 to 15 do
  begin
    buf1[i] := i;
    buf2[i] := i;
  end;
  
  AssertTrue('MemEqual should return True for equal buffers', MemEqual(@buf1[0], @buf2[0], 16));
  
  // 测试不相等的内存区域
  buf2[8] := 255;
  AssertFalse('MemEqual should return False for different buffers', MemEqual(@buf1[0], @buf2[0], 16));
end;

procedure TTestCase_Global.Test_MemEqual_Empty;
begin
  AssertTrue('MemEqual should return True for zero length', MemEqual(nil, nil, 0));
end;

procedure TTestCase_Global.Test_MemEqual_Nil;
begin
  AssertTrue('MemEqual should return True for both nil pointers', MemEqual(nil, nil, 10));
  AssertFalse('MemEqual should return False for one nil pointer', MemEqual(@Self, nil, 10));
end;

procedure TTestCase_Global.Test_MemFindByte;
var
  buf: array[0..15] of Byte;
  i: Integer;
begin
  for i := 0 to 15 do
    buf[i] := i;
    
  AssertEquals('Should find byte at correct position', 5, MemFindByte(@buf[0], 16, 5));
  AssertEquals('Should find first occurrence', 0, MemFindByte(@buf[0], 16, 0));
  AssertEquals('Should find last occurrence', 15, MemFindByte(@buf[0], 16, 15));
end;

procedure TTestCase_Global.Test_MemFindByte_NotFound;
var
  buf: array[0..15] of Byte;
  i: Integer;
begin
  for i := 0 to 15 do
    buf[i] := i;
    
  AssertEquals('Should return -1 when byte not found', -1, MemFindByte(@buf[0], 16, 255));
end;

procedure TTestCase_Global.Test_MemFindByte_Empty;
begin
  AssertEquals('Should return -1 for empty buffer', -1, MemFindByte(nil, 0, 5));
end;

procedure TTestCase_Global.Test_MemDiffRange;
var
  buf1, buf2: array[0..15] of Byte;
  i: Integer;
  firstDiff, lastDiff: SizeUInt;
  hasDiff: Boolean;
begin
  // 设置相同的缓冲区
  for i := 0 to 15 do
  begin
    buf1[i] := i;
    buf2[i] := i;
  end;
  
  // 在中间创建差异
  buf2[5] := 255;
  buf2[10] := 254;
  
  hasDiff := MemDiffRange(@buf1[0], @buf2[0], 16, firstDiff, lastDiff);
  
  AssertTrue('Should detect differences', hasDiff);
  AssertEquals('First difference should be at position 5', 5, firstDiff);
  AssertEquals('Last difference should be at position 10', 10, lastDiff);
end;

procedure TTestCase_Global.Test_MemDiffRange_NoDiff;
var
  buf1, buf2: array[0..15] of Byte;
  i: Integer;
  firstDiff, lastDiff: SizeUInt;
  hasDiff: Boolean;
begin
  for i := 0 to 15 do
  begin
    buf1[i] := i;
    buf2[i] := i;
  end;
  
  hasDiff := MemDiffRange(@buf1[0], @buf2[0], 16, firstDiff, lastDiff);
  
  AssertFalse('Should not detect differences in identical buffers', hasDiff);
end;

procedure TTestCase_Global.Test_MemCopy;
var
  src, dst: array[0..15] of Byte;
  i: Integer;
begin
  for i := 0 to 15 do
  begin
    src[i] := i;
    dst[i] := 255;
  end;
  
  MemCopy(@src[0], @dst[0], 16);
  
  for i := 0 to 15 do
    AssertEquals('Copied data should match source', src[i], dst[i]);
end;

procedure TTestCase_Global.Test_MemSet;
var
  buf: array[0..15] of Byte;
  i: Integer;
begin
  // 初始化为不同值
  for i := 0 to 15 do
    buf[i] := i;
    
  MemSet(@buf[0], 16, 42);
  
  for i := 0 to 15 do
    AssertEquals('All bytes should be set to 42', 42, buf[i]);
end;

procedure TTestCase_Global.Test_MemReverse;
var
  buf: array[0..7] of Byte;
  i: Integer;
begin
  for i := 0 to 7 do
    buf[i] := i;
    
  MemReverse(@buf[0], 8);
  
  for i := 0 to 7 do
    AssertEquals('Reversed buffer should have correct values', 7 - i, buf[i]);
end;

// === 统计函数测试 ===

procedure TTestCase_Global.Test_SumBytes;
var
  buf: array[0..3] of Byte;
  sum: UInt64;
begin
  buf[0] := 1;
  buf[1] := 2;
  buf[2] := 3;
  buf[3] := 4;
  
  sum := SumBytes(@buf[0], 4);
  AssertEquals('Sum should be 10', 10, sum);
end;

procedure TTestCase_Global.Test_SumBytes_Empty;
var
  sum: UInt64;
begin
  sum := SumBytes(nil, 0);
  AssertEquals('Sum of empty buffer should be 0', 0, sum);
end;

procedure TTestCase_Global.Test_MinMaxBytes;
var
  buf: array[0..4] of Byte;
  minVal, maxVal: Byte;
begin
  buf[0] := 10;
  buf[1] := 5;
  buf[2] := 20;
  buf[3] := 1;
  buf[4] := 15;
  
  MinMaxBytes(@buf[0], 5, minVal, maxVal);
  
  AssertEquals('Min value should be 1', 1, minVal);
  AssertEquals('Max value should be 20', 20, maxVal);
end;

procedure TTestCase_Global.Test_MinMaxBytes_Single;
var
  buf: array[0..0] of Byte;
  minVal, maxVal: Byte;
begin
  buf[0] := 42;
  
  MinMaxBytes(@buf[0], 1, minVal, maxVal);
  
  AssertEquals('Min value should be 42', 42, minVal);
  AssertEquals('Max value should be 42', 42, maxVal);
end;

procedure TTestCase_Global.Test_CountByte;
var
  buf: array[0..7] of Byte;
  count: SizeUInt;
begin
  buf[0] := 1;
  buf[1] := 2;
  buf[2] := 1;
  buf[3] := 3;
  buf[4] := 1;
  buf[5] := 4;
  buf[6] := 1;
  buf[7] := 5;
  
  count := CountByte(@buf[0], 8, 1);
  AssertEquals('Should count 4 occurrences of byte 1', 4, count);
end;

procedure TTestCase_Global.Test_CountByte_None;
var
  buf: array[0..7] of Byte;
  count: SizeUInt;
  i: Integer;
begin
  for i := 0 to 7 do
    buf[i] := i;
    
  count := CountByte(@buf[0], 8, 255);
  AssertEquals('Should count 0 occurrences of byte 255', 0, count);
end;

// === 文本处理函数测试 ===

procedure TTestCase_Global.Test_Utf8Validate;
var
  validUtf8: array[0..6] of Byte;
  isValid: Boolean;
begin
  // 测试有效的 UTF-8 序列: "Hello"
  validUtf8[0] := Ord('H');
  validUtf8[1] := Ord('e');
  validUtf8[2] := Ord('l');
  validUtf8[3] := Ord('l');
  validUtf8[4] := Ord('o');

  isValid := Utf8Validate(@validUtf8[0], 5);
  AssertTrue('Valid ASCII should pass UTF-8 validation', isValid);
end;

procedure TTestCase_Global.Test_Utf8Validate_Invalid;
var
  invalidUtf8: array[0..3] of Byte;
  isValid: Boolean;
begin
  // 测试无效的 UTF-8 序列
  invalidUtf8[0] := $C0;  // 无效的起始字节
  invalidUtf8[1] := $80;

  isValid := Utf8Validate(@invalidUtf8[0], 2);
  AssertFalse('Invalid UTF-8 sequence should fail validation', isValid);
end;

procedure TTestCase_Global.Test_AsciiIEqual;
var
  buf1, buf2: array[0..4] of Byte;
  isEqual: Boolean;
begin
  // 测试大小写不敏感比较
  buf1[0] := Ord('H');
  buf1[1] := Ord('e');
  buf1[2] := Ord('L');
  buf1[3] := Ord('L');
  buf1[4] := Ord('o');

  buf2[0] := Ord('h');
  buf2[1] := Ord('E');
  buf2[2] := Ord('l');
  buf2[3] := Ord('l');
  buf2[4] := Ord('O');

  isEqual := AsciiIEqual(@buf1[0], @buf2[0], 5);
  AssertTrue('Case-insensitive comparison should return true', isEqual);
end;

procedure TTestCase_Global.Test_AsciiIEqual_CaseDiff;
var
  buf1, buf2: array[0..4] of Byte;
  isEqual: Boolean;
begin
  buf1[0] := Ord('H');
  buf1[1] := Ord('e');
  buf1[2] := Ord('l');
  buf1[3] := Ord('l');
  buf1[4] := Ord('o');

  buf2[0] := Ord('W');
  buf2[1] := Ord('o');
  buf2[2] := Ord('r');
  buf2[3] := Ord('l');
  buf2[4] := Ord('d');

  isEqual := AsciiIEqual(@buf1[0], @buf2[0], 5);
  AssertFalse('Different strings should return false', isEqual);
end;

procedure TTestCase_Global.Test_ToLowerAscii;
var
  buf: array[0..4] of Byte;
begin
  buf[0] := Ord('H');
  buf[1] := Ord('E');
  buf[2] := Ord('L');
  buf[3] := Ord('L');
  buf[4] := Ord('O');

  ToLowerAscii(@buf[0], 5);

  AssertEquals('H should become h', Ord('h'), buf[0]);
  AssertEquals('E should become e', Ord('e'), buf[1]);
  AssertEquals('L should become l', Ord('l'), buf[2]);
  AssertEquals('L should become l', Ord('l'), buf[3]);
  AssertEquals('O should become o', Ord('o'), buf[4]);
end;

procedure TTestCase_Global.Test_ToUpperAscii;
var
  buf: array[0..4] of Byte;
begin
  buf[0] := Ord('h');
  buf[1] := Ord('e');
  buf[2] := Ord('l');
  buf[3] := Ord('l');
  buf[4] := Ord('o');

  ToUpperAscii(@buf[0], 5);

  AssertEquals('h should become H', Ord('H'), buf[0]);
  AssertEquals('e should become E', Ord('E'), buf[1]);
  AssertEquals('l should become L', Ord('L'), buf[2]);
  AssertEquals('l should become L', Ord('L'), buf[3]);
  AssertEquals('o should become O', Ord('O'), buf[4]);
end;

// === 搜索函数测试 ===

procedure TTestCase_Global.Test_BytesIndexOf;
var
  haystack: array[0..9] of Byte;
  needle: array[0..2] of Byte;
  index: PtrInt;
  i: Integer;
begin
  // 设置 haystack: [0,1,2,3,4,5,6,7,8,9]
  for i := 0 to 9 do
    haystack[i] := i;

  // 设置 needle: [3,4,5]
  needle[0] := 3;
  needle[1] := 4;
  needle[2] := 5;

  index := BytesIndexOf(@haystack[0], 10, @needle[0], 3);
  AssertEquals('Should find needle at position 3', 3, index);
end;

procedure TTestCase_Global.Test_BytesIndexOf_NotFound;
var
  haystack: array[0..9] of Byte;
  needle: array[0..2] of Byte;
  index: PtrInt;
  i: Integer;
begin
  for i := 0 to 9 do
    haystack[i] := i;

  needle[0] := 20;
  needle[1] := 21;
  needle[2] := 22;

  index := BytesIndexOf(@haystack[0], 10, @needle[0], 3);
  AssertEquals('Should return -1 when needle not found', -1, index);
end;

procedure TTestCase_Global.Test_BytesIndexOf_Empty;
var
  haystack: array[0..9] of Byte;
  index: PtrInt;
begin
  index := BytesIndexOf(@haystack[0], 10, nil, 0);
  AssertEquals('Should return -1 for empty needle', -1, index);
end;

// === 位集函数测试 ===

procedure TTestCase_Global.Test_BitsetPopCount;
var
  buf: array[0..3] of Byte;
  count: SizeUInt;
begin
  buf[0] := $FF;  // 11111111 = 8 bits
  buf[1] := $0F;  // 00001111 = 4 bits
  buf[2] := $AA;  // 10101010 = 4 bits
  buf[3] := $00;  // 00000000 = 0 bits

  count := BitsetPopCount(@buf[0], 4);
  AssertEquals('Should count 16 set bits total', 16, count);
end;

procedure TTestCase_Global.Test_BitsetPopCount_Empty;
var
  count: SizeUInt;
begin
  count := BitsetPopCount(nil, 0);
  AssertEquals('Empty bitset should have 0 bits set', 0, count);
end;

procedure TTestCase_Global.Test_BitsetPopCount_AllSet;
var
  buf: array[0..1] of Byte;
  count: SizeUInt;
begin
  buf[0] := $FF;
  buf[1] := $FF;

  count := BitsetPopCount(@buf[0], 2);
  AssertEquals('All bits set should count 16', 16, count);
end;

end.
