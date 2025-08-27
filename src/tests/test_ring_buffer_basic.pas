unit test_ring_buffer_basic;

{$mode objfpc}{$H+}
{$I ../fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testutils, testregistry,
  fafafa.core.base,
  fafafa.core.mem.ringBuffer;

procedure RegisterRingBufferTests;

implementation

type
  TRingBufferCase = class(TTestCase)
  published
    procedure Test_Create_Push_Pop_UInt32;
    procedure Test_Peek_Offsets;
    procedure Test_Resize_Grow_Shrink_POD;
    procedure Test_Large_ElementSize_Over4KB;
    procedure Test_Clear_And_State;
    procedure Test_Usage_Ratio_And_Percent;
    procedure Test_Create_Overflow_Throws;
    procedure Test_Generic_Typed_Wrap_UInt32;
    procedure Test_Batch_PushN_PopN_WrapAround;
    procedure Test_Spans_Basic;
  end;

procedure TRingBufferCase.Test_Create_Push_Pop_UInt32;
var
  rb: TRingBuffer;
  vIn, vOut: UInt32;
  ok: Boolean;
begin
  rb := TRingBuffer.Create(4, SizeOf(UInt32));
  try
    AssertEquals(SizeUInt(4), rb.Capacity);
    AssertEquals(SizeUInt(SizeOf(UInt32)), rb.ElementSize);
    AssertEquals(SizeUInt(0), rb.Count);
    AssertTrue(rb.IsEmpty);
    AssertEquals(0.0, rb.GetUsageRatio, 1e-6);

    vIn := 123456789;
    ok := rb.Push(@vIn);
    AssertTrue(ok);
    AssertEquals(SizeUInt(1), rb.Count);
    AssertFalse(rb.IsEmpty);

    vOut := 0;
    ok := rb.Pop(@vOut);
    AssertTrue(ok);
    AssertEquals(vIn, vOut);
    AssertTrue(rb.IsEmpty);
  finally
    rb.Free;
  end;
end;

procedure TRingBufferCase.Test_Peek_Offsets;
var
  rb: TRingBuffer;
  vals: array[0..2] of UInt32 = (10, 20, 30);
  tmp: UInt32;
  i: Integer;
begin
  rb := TRingBuffer.Create(3, SizeOf(UInt32));
  try
    for i := 0 to 2 do AssertTrue(rb.Push(@vals[i]));
    AssertTrue(rb.IsFull);

    AssertTrue(rb.Peek(@tmp, 0)); AssertEquals(UInt32(10), tmp);
    AssertTrue(rb.Peek(@tmp, 1)); AssertEquals(UInt32(20), tmp);
    AssertTrue(rb.Peek(@tmp, 2)); AssertEquals(UInt32(30), tmp);

    // 越界 peek 返回 False
    AssertFalse(rb.Peek(@tmp, 3));
  finally
    rb.Free;
  end;
end;

procedure TRingBufferCase.Test_Resize_Grow_Shrink_POD;
var
  rb: TRingBuffer;
  i: Integer;
  v, outv: UInt32;
begin
  rb := TRingBuffer.Create(3, SizeOf(UInt32));
  try
    // 填满
    for i := 1 to 3 do begin v := i; AssertTrue(rb.Push(@v)); end;
    // 扩容到 5，顺序应保持
    AssertTrue(rb.Resize(5));
    AssertEquals(SizeUInt(3), rb.Count);
    for i := 1 to 3 do begin outv := 0; AssertTrue(rb.Pop(@outv)); AssertEquals(UInt32(i), outv); end;

    // 再写入 1..5
    for i := 1 to 5 do begin v := i; AssertTrue(rb.Push(@v)); end;
    AssertTrue(rb.IsFull);
    // 收缩到 3：应保留最旧的前三个（1,2,3）
    AssertTrue(rb.Resize(3));
    AssertEquals(SizeUInt(3), rb.Count);
    for i := 1 to 3 do begin outv := 0; AssertTrue(rb.Pop(@outv)); AssertEquals(UInt32(i), outv); end;
    AssertTrue(rb.IsEmpty);
  finally
    rb.Free;
  end;
end;

type
  TLarge = record
    Data: array[0..8191] of Byte; // 8KB > 4KB
  end;

procedure TRingBufferCase.Test_Large_ElementSize_Over4KB;
var
  rb: specialize TTypedRingBuffer<TLarge>;
  a, b: TLarge;
  i: Integer;
  ok: Boolean;
begin
  // 容量 2，元素尺寸 8KB，验证 Resize 迁移不受 4KB 限制
  rb := specialize TTypedRingBuffer<TLarge>.Create(2);
  try
    for i := 0 to High(a.Data) do a.Data[i] := Byte(i and $FF);
    ok := rb.Push(a); AssertTrue(ok);
    ok := rb.Pop(b); AssertTrue(ok);
    for i := 0 to High(a.Data) do AssertEquals(a.Data[i], b.Data[i]);
  finally
    rb.Free;
  end;
end;

procedure TRingBufferCase.Test_Clear_And_State;
var
  rb: TRingBuffer;
  v: UInt32;
begin
  rb := TRingBuffer.Create(2, SizeOf(UInt32));
  try
    v := 42; AssertTrue(rb.Push(@v));
    rb.Clear;
    AssertTrue(rb.IsEmpty);
    AssertEquals(SizeUInt(0), rb.Count);
    // 清空后可继续使用
    v := 7; AssertTrue(rb.Push(@v));
    AssertTrue(rb.Pop(@v));
    AssertEquals(UInt32(7), v);
  finally
    rb.Free;
  end;
end;

procedure TRingBufferCase.Test_Usage_Ratio_And_Percent;
var
  rb: TRingBuffer;
  v: UInt32;
begin
  rb := TRingBuffer.Create(4, SizeOf(UInt32));
  try
    AssertEquals(0.0, rb.GetUsageRatio, 1e-6);
    v := 1; AssertTrue(rb.Push(@v));
    AssertTrue(rb.GetUsageRatio > 0.24); // 1/4 = 0.25
    AssertTrue(rb.GetUsageRatio < 0.26);
    AssertTrue(rb.GetUsagePercent > 24.9);
    AssertTrue(rb.GetUsagePercent < 25.1);
  finally
    rb.Free;
  end;
end;

procedure TRingBufferCase.Test_Create_Overflow_Throws;
var
  cap, esz: SizeUInt;
  raised: Boolean;
  rb: TRingBuffer;
begin
  // 选择 esz=16，构造一个使得 cap*esz 溢出的 cap
  esz := 16;
  cap := (MAX_SIZE_UINT div esz) + 1;
  raised := False;
  try
    rb := TRingBuffer.Create(cap, esz);
    rb.Free;
  except
    on E: Exception do
      raised := True;
  end;
  AssertTrue('overflow check', raised);
end;

procedure TRingBufferCase.Test_Generic_Typed_Wrap_UInt32;
var
  rb: specialize TTypedRingBuffer<UInt32>;
  i, outv: UInt32;
  k: Integer;
  ok: Boolean;
begin
  rb := specialize TTypedRingBuffer<UInt32>.Create(3);
  try
    for k := 1 to 3 do begin i := k; ok := rb.Push(i); AssertTrue(ok); end;
    for k := 1 to 3 do begin ok := rb.Pop(outv); AssertTrue(ok); AssertEquals(UInt32(k), outv); end;
  finally
    rb.Free;
  end;
end;

procedure TRingBufferCase.Test_Batch_PushN_PopN_WrapAround;
var
  rb: TRingBuffer;
  src, dst: array[0..9] of UInt32;
  pushed, popped: SizeUInt;
  i: Integer;
begin
  for i := 0 to 9 do src[i] := UInt32(i + 1);

  rb := TRingBuffer.Create(8, SizeOf(UInt32));
  try
    // 先写3，尾=3
    AssertTrue(rb.PushN(@src[0], 3, pushed));
    AssertEquals(SizeUInt(3), pushed);
    // 读2，使头=2、尾=3、count=1，制造空洞
    AssertTrue(rb.PopN(@dst[0], 2, popped));
    AssertEquals(SizeUInt(2), popped);
    // 再写5，跨越尾->末尾并回绕到0，最终尾=0，count=6
    AssertTrue(rb.PushN(@src[3], 5, pushed));
    AssertEquals(SizeUInt(5), pushed);
    AssertEquals(SizeUInt(6), rb.Count);

    // 读出6，顺序应为剩余的 3,4,5,6,7,8
    AssertTrue(rb.PopN(@dst[0], 6, popped));
    AssertEquals(SizeUInt(6), popped);
    for i := 0 to 5 do AssertEquals(UInt32(3 + i), dst[i]);
    AssertTrue(rb.IsEmpty);

    // 写入超过剩余空间：只应写入可用的8
    AssertTrue(rb.PushN(@src[0], 10, pushed));
    AssertEquals(SizeUInt(8), pushed);
    // 读取超过已有：应只读8
    AssertTrue(rb.PopN(@dst[0], 10, popped));
    AssertEquals(SizeUInt(8), popped);
    for i := 0 to 7 do AssertEquals(UInt32(i + 1), dst[i]);
  finally
    rb.Free;
  end;
end;

procedure TRingBufferCase.Test_Spans_Basic;
var
  rb: TRingBuffer;
  ptr: Pointer;
  len: SizeUInt;
  src: array[0..7] of UInt32;
  pushed: SizeUInt;
  tmp: UInt32;
begin
  rb := TRingBuffer.Create(8, SizeOf(UInt32));
  try
    // 初始：可写跨度应为 8
    rb.GetContiguousWriteSpan(ptr, len);
    AssertEquals(SizeUInt(8), len);

    // 写入3：尾=3
    AssertTrue(rb.PushN(@src[0], 3, pushed));
    rb.GetContiguousWriteSpan(ptr, len);
    AssertEquals(SizeUInt(5), len); // capacity - tail

    // 读出2：头=2，count=1
    AssertTrue(rb.Pop(@tmp));
    AssertTrue(rb.Pop(@tmp));
    rb.GetContiguousWriteSpan(ptr, len);
    AssertEquals(SizeUInt(5), len); // 尾仍为3

    // 写入5：跨越并回绕，尾=0，count=6
    AssertTrue(rb.PushN(@src[0], 5, pushed));
    rb.GetContiguousWriteSpan(ptr, len);
    AssertEquals(SizeUInt(2), len); // 可写=2，尾=0 -> 取 min(2, 8-0)=2

    // 读跨度：头=2，count=6 -> min(6, 8-2)=6
    rb.GetContiguousReadSpan(ptr, len);
    AssertEquals(SizeUInt(6), len);
  finally
    rb.Free;
  end;
end;

procedure RegisterRingBufferTests;
begin
  RegisterTest('ringbuffer-basic', TRingBufferCase);
end;

end.

