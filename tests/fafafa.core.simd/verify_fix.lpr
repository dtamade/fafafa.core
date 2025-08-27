program verify_fix;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.simd,
  fafafa.core.simd.search;

procedure AssertTrue(cond: Boolean; const msg: string);
begin
  if not cond then 
  begin 
    Writeln('FAIL: ', msg); 
    Halt(1); 
  end;
end;

procedure TestBasicIndexOf;
var
  hay, ned: TBytes;
  idx: PtrInt;
begin
  Writeln('Testing basic IndexOf...');
  
  // 测试基本情况
  SetLength(hay, 11);
  Move(PAnsiChar(AnsiString('hello world'))^, hay[0], 11);
  SetLength(ned, 5);
  Move(PAnsiChar(AnsiString('world'))^, ned[0], 5);
  
  idx := BytesIndexOf(@hay[0], Length(hay), @ned[0], Length(ned));
  AssertTrue(idx = 6, 'Basic IndexOf should find "world" at position 6');
  
  // 测试边界情况：needle 在开头
  SetLength(ned, 5);
  Move(PAnsiChar(AnsiString('hello'))^, ned[0], 5);
  idx := BytesIndexOf(@hay[0], Length(hay), @ned[0], Length(ned));
  AssertTrue(idx = 0, 'IndexOf should find "hello" at position 0');
  
  // 测试边界情况：needle 不存在
  SetLength(ned, 3);
  Move(PAnsiChar(AnsiString('xyz'))^, ned[0], 3);
  idx := BytesIndexOf(@hay[0], Length(hay), @ned[0], Length(ned));
  AssertTrue(idx = -1, 'IndexOf should return -1 for non-existent needle');
  
  Writeln('Basic IndexOf tests passed.');
end;

procedure TestEdgeCases;
var
  hay, ned: TBytes;
  idx: PtrInt;
begin
  Writeln('Testing edge cases...');
  
  // 空 needle
  SetLength(hay, 5);
  Move(PAnsiChar(AnsiString('hello'))^, hay[0], 5);
  idx := BytesIndexOf(@hay[0], Length(hay), nil, 0);
  AssertTrue(idx = 0, 'Empty needle should return 0');
  
  // needle 长于 haystack
  SetLength(ned, 10);
  Move(PAnsiChar(AnsiString('1234567890'))^, ned[0], 10);
  idx := BytesIndexOf(@hay[0], Length(hay), @ned[0], Length(ned));
  AssertTrue(idx = -1, 'Needle longer than haystack should return -1');
  
  // 单字符 needle
  SetLength(ned, 1);
  ned[0] := Ord('e');
  idx := BytesIndexOf(@hay[0], Length(hay), @ned[0], Length(ned));
  AssertTrue(idx = 1, 'Single char needle should find "e" at position 1');
  
  Writeln('Edge case tests passed.');
end;

procedure TestSIMDConsistency;
var
  hay, ned: TBytes;
  idxScalar, idxSSE2, idxAVX2: PtrInt;
  i: Integer;
begin
  Writeln('Testing SIMD consistency...');
  
  // 创建测试数据
  SetLength(hay, 100);
  for i := 0 to 99 do
    hay[i] := Ord('a') + (i mod 26);
  
  // 插入目标模式
  SetLength(ned, 8);
  Move(PAnsiChar(AnsiString('pattern1'))^, ned[0], 8);
  Move(ned[0], hay[50], 8);
  
  // 比较不同实现的结果
  idxScalar := BytesIndexOf_Scalar(@hay[0], Length(hay), @ned[0], Length(ned));
  {$IFDEF CPUX86_64}
  idxSSE2 := BytesIndexOf_SSE2(@hay[0], Length(hay), @ned[0], Length(ned));
  idxAVX2 := BytesIndexOf_AVX2(@hay[0], Length(hay), @ned[0], Length(ned));
  
  AssertTrue(idxScalar = idxSSE2, Format('Scalar vs SSE2 mismatch: %d vs %d', [idxScalar, idxSSE2]));
  AssertTrue(idxScalar = idxAVX2, Format('Scalar vs AVX2 mismatch: %d vs %d', [idxScalar, idxAVX2]));
  
  Writeln(Format('All implementations agree: found at position %d', [idxScalar]));
  {$ELSE}
  Writeln(Format('Scalar implementation found at position %d', [idxScalar]));
  {$ENDIF}
  
  Writeln('SIMD consistency tests passed.');
end;

begin
  Writeln('=== SIMD BytesIndexOf Fix Verification ===');
  Writeln('Current SIMD profile: ', SimdInfo);
  
  TestBasicIndexOf;
  TestEdgeCases;
  TestSIMDConsistency;
  
  Writeln('=== All tests passed! ===');
end.
