unit fafafa.core.bytes.buf.testcase;

{$MODE OBJFPC}{$H+}
{$modeswitch advancedrecords}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.base,
  fafafa.core.bytes, // 为 HexToBytes/TBytesBuilder
  fafafa.core.bytes.buf;

type
  TTestCase_ByteBuf = class(TTestCase)
  published
    procedure Test_Construct_Write_Read;
    procedure Test_Duplicate_Independent_Indices;
    procedure Test_Slice_Bounds_And_View;
    procedure Test_EnsureWritable_Grow;
    procedure Test_ReadWrite_U16_U32_LE_BE;
    procedure Test_ReadWrite_U64_LE_BE;
    procedure Test_WriteReadBytes_And_Compact;
    procedure Test_View_EnsureWritable_And_Compact_ShouldFail;
    procedure Test_Interop_ByteBufToBuilder_RoundTrip;
    procedure Test_Slice_Write_Visibility;
    procedure Test_Nested_Slice_Write_Visibility;
    procedure Test_Duplicate_Write_Visibility;
    procedure Test_Mixed_Slice_Duplicate_Nesting;
    procedure Test_ReadBytes_OutOfRange;
    procedure Test_WriteBytes_Zero_NoOp;

    // 新增：批量操作测试
    procedure Test_BatchOperations_ReadBytesInto_WriteBytesFrom;
    procedure Test_WriteBytesUnchecked_Performance;
  end;

implementation

procedure TTestCase_ByteBuf.Test_Construct_Write_Read;
var buf: IByteBuf; i: Integer; outB: TBytes;
begin
  buf := TByteBufImpl.New(2);
  buf.WriteU8($AA);
  buf.WriteU8($BB);
  AssertEquals(2, buf.ReadableBytes);
  AssertEquals(0, buf.WritableBytes);
  buf.EnsureWritable(1);
  buf.WriteU8($CC);
  AssertEquals(Byte($AA), buf.ReadU8);
  AssertEquals(Byte($BB), buf.ReadU8);
  AssertEquals(Byte($CC), buf.ReadU8);
  outB := buf.ToBytes;
  AssertEquals(3, Length(outB));
end;

procedure TTestCase_ByteBuf.Test_Duplicate_Independent_Indices;
var a,b: IByteBuf;
begin
  a := TByteBufImpl.New(0);
  a.EnsureWritable(3);
  a.WriteU8(1); a.WriteU8(2); a.WriteU8(3);
  b := a.Duplicate;
  AssertEquals(3, a.ReadableBytes);
  AssertEquals(3, b.ReadableBytes);
  AssertEquals(1, a.ReadU8);
  AssertEquals(1, b.ReadU8);
  // 索引独立推进
  AssertEquals(2, a.ReadU8);
  AssertEquals(2, b.ReadU8);
end;

procedure TTestCase_ByteBuf.Test_Slice_Bounds_And_View;
var a,s: IByteBuf;
begin
  a := TByteBufImpl.New(0);
  a.EnsureWritable(5);
  a.WriteU8(10); a.WriteU8(11); a.WriteU8(12); a.WriteU8(13); a.WriteU8(14);
  // 切出 [1..3] 视图
  s := a.Slice(1,3);
  AssertEquals(3, s.ReadableBytes);
  AssertEquals(Byte(11), s.ReadU8);
  AssertEquals(Byte(12), s.ReadU8);
  AssertEquals(Byte(13), s.ReadU8);
  // 越界切片
  AssertException('oob slice', EOutOfRange,
    procedure begin s := a.Slice(4, 3); end);
end;

procedure TTestCase_ByteBuf.Test_EnsureWritable_Grow;
var a: IByteBuf; cap0, cap1: SizeInt;
begin
  a := TByteBufImpl.New(1);
  cap0 := a.Capacity;
  a.EnsureWritable(10);
  cap1 := a.Capacity;
  AssertTrue('grew', cap1 > cap0);
end;

procedure TTestCase_ByteBuf.Test_ReadWrite_U16_U32_LE_BE;
var b: IByteBuf; u32: UInt32;
begin
  b := TByteBufImpl.New(0);
  b.WriteU16LE($1234);
  b.WriteU16BE($5678);
  b.WriteU32LE($89ABCDEF);
  b.WriteU32BE($10203040);
  AssertEquals($1234, b.ReadU16LE);
  AssertEquals($5678, b.ReadU16BE);
  u32 := b.ReadU32LE; AssertEquals($89ABCDEF, u32);
  u32 := b.ReadU32BE; AssertEquals($10203040, u32);
end;

// 补充 U64 测试
procedure TTestCase_ByteBuf.Test_ReadWrite_U64_LE_BE;
var b: IByteBuf; u64: UInt64;
begin
  b := TByteBufImpl.New(0);
  b.WriteU64LE(UInt64($1122334455667788));
  b.WriteU64BE(UInt64($99AABBCCDDEEFF00));
  u64 := b.ReadU64LE; AssertEquals(UInt64($1122334455667788), u64);
  u64 := b.ReadU64BE; AssertEquals(UInt64($99AABBCCDDEEFF00), u64);
end;

procedure TTestCase_ByteBuf.Test_WriteReadBytes_And_Compact;
var b: IByteBuf; outB: TBytes; bb: TBytesBuilder; fromBB: IByteBuf;
begin
  b := TByteBufImpl.New(0);
  b.WriteBytes(HexToBytes('0102030405'));
  // 读前两个字节
  outB := b.ReadBytes(2);
  AssertEquals(2, Length(outB));
  AssertEquals(Byte($01), outB[0]);
  AssertEquals(Byte($02), outB[1]);
  // Compact 回收前部空间并重置索引
  b.Compact;
  AssertEquals(3, b.ReadableBytes);
  // 再写入两个字节，确保可追加
  b.WriteBytes(HexToBytes('A0A1'));
  AssertEquals(5, b.ReadableBytes);
  // 验证剩余顺序
  outB := b.ReadBytes(5);
  AssertEquals(5, Length(outB));
  AssertEquals(Byte($03), outB[0]);
  AssertEquals(Byte($04), outB[1]);
  AssertEquals(Byte($05), outB[2]);
  AssertEquals(Byte($A0), outB[3]);
  AssertEquals(Byte($A1), outB[4]);

  // FromBuilder 互操作：构造 builder -> ByteBuf
  bb.Init(0);
  bb.AppendHex('0A0B0C');
  fromBB := TByteBufImpl.FromBuilder(bb);
  AssertEquals(3, fromBB.ReadableBytes);
  AssertEquals(Byte($0A), fromBB.ReadU8);
  AssertEquals(Byte($0B), fromBB.ReadU8);
  AssertEquals(Byte($0C), fromBB.ReadU8);
end;

procedure TTestCase_ByteBuf.Test_View_EnsureWritable_And_Compact_ShouldFail;
var root,view: IByteBuf;
begin
  root := TByteBufImpl.New(0);
  root.WriteBytes(HexToBytes('010203'));
  view := root.Slice(1,2);
  AssertException('ensure on view', EOutOfRange,
    procedure begin view.EnsureWritable(1); end);
  AssertException('compact on view', EOutOfRange,
    procedure begin view.Compact; end);
end;

procedure TTestCase_ByteBuf.Test_Interop_ByteBufToBuilder_RoundTrip;
var bb: TBytesBuilder; buf: IByteBuf; bb2: TBytesBuilder; b: TBytes;
begin
  // builder -> buf -> builder 回环
  bb.Init(0);
  bb.AppendHex('DEADBEEF');
  buf := TByteBufImpl.FromBuilder(bb);
  bb2 := ByteBufToBuilder(buf);
  b := bb2.ToBytes;
  AssertEquals(4, Length(b));
  AssertEquals(Byte($DE), b[0]);
  AssertEquals(Byte($AD), b[1]);
  AssertEquals(Byte($BE), b[2]);
  AssertEquals(Byte($EF), b[3]);
end;

procedure TTestCase_ByteBuf.Test_Slice_Write_Visibility;
var root, s: IByteBuf; b: TBytes;
begin
  root := TByteBufImpl.New(0);
  root.WriteBytes(HexToBytes('00010203'));
  s := root.Slice(1,2); // bytes at [1,2]
  // Reset indices to overwrite within the slice without growth
  s.ReaderIndex := 0; s.WriterIndex := 0;
  s.WriteU8($AA); s.WriteU8($BB);
  b := root.ToBytes;
  // root bytes should become 00 AABB 03
  AssertEquals(Byte($00), b[0]);
  AssertEquals(Byte($AA), b[1]);
  AssertEquals(Byte($BB), b[2]);
  AssertEquals(Byte($03), b[3]);
end;

procedure TTestCase_ByteBuf.Test_Nested_Slice_Write_Visibility;
var root, s1, s2: IByteBuf; b: TBytes;
begin
  root := TByteBufImpl.New(0);
  root.WriteBytes(HexToBytes('0001020304'));
  s1 := root.Slice(1,3);  // 01 02 03
  s2 := s1.Slice(1,2);    // 02 03
  s2.ReaderIndex := 0; s2.WriterIndex := 0;
  s2.WriteU8($CC); s2.WriteU8($DD);
  b := root.ToBytes;
  // root should become 00 01 CC DD 04
  AssertEquals(Byte($00), b[0]);
  AssertEquals(Byte($01), b[1]);
  AssertEquals(Byte($CC), b[2]);
  AssertEquals(Byte($DD), b[3]);
  AssertEquals(Byte($04), b[4]);
end;

procedure TTestCase_ByteBuf.Test_Duplicate_Write_Visibility;
var root, a, b: IByteBuf; data: TBytes;
begin
  root := TByteBufImpl.New(0);
  root.WriteBytes(HexToBytes('01020304'));
  a := root.Duplicate;
  b := root.Duplicate;
  // 在 a 上覆盖前两个字节
  a.ReaderIndex := 0; a.WriterIndex := 0;
  a.WriteU8($AA); a.WriteU8($BB);
  data := root.ToBytes;
  AssertEquals(Byte($AA), data[0]);
  AssertEquals(Byte($BB), data[1]);
  // b 的读取应从其自己的 readerIndex 开始（独立），但内容应为最新
  AssertEquals(Byte($AA), b.ReadU8);
  AssertEquals(Byte($BB), b.ReadU8);
end;

procedure TTestCase_ByteBuf.Test_Mixed_Slice_Duplicate_Nesting;
var root, s1, d1, s2: IByteBuf; data: TBytes;
begin
  root := TByteBufImpl.New(0);
  root.WriteBytes(HexToBytes('000102030405'));
  s1 := root.Slice(1,4);    // 01 02 03 04
  d1 := s1.Duplicate;        // view on same region
  s2 := d1.Slice(1,2);       // 02 03
  s2.ReaderIndex := 0; s2.WriterIndex := 0;
  s2.WriteU8($CC); s2.WriteU8($DD);
  data := root.ToBytes;
  // root: 00 01 CC DD 04 05
  AssertEquals(Byte($00), data[0]);
  AssertEquals(Byte($01), data[1]);
  AssertEquals(Byte($CC), data[2]);
  AssertEquals(Byte($DD), data[3]);
  AssertEquals(Byte($04), data[4]);
  AssertEquals(Byte($05), data[5]);
end;

procedure TTestCase_ByteBuf.Test_ReadBytes_OutOfRange;
var b: IByteBuf;
begin
  b := TByteBufImpl.New(0);
  b.WriteBytes(HexToBytes('0102'));
  AssertException('read oob', EOutOfRange,
    procedure begin
      // consume exception
      b.ReadBytes(3);
    end);
end;

procedure TTestCase_ByteBuf.Test_WriteBytes_Zero_NoOp;
var b: IByteBuf; before: SizeInt;
begin
  b := TByteBufImpl.New(0);
  before := b.ReadableBytes;
  b.WriteBytes(nil);
  AssertEquals(before, b.ReadableBytes);
end;

procedure TTestCase_ByteBuf.Test_BatchOperations_ReadBytesInto_WriteBytesFrom;
var buf: IByteBuf; srcData: array[0..3] of Byte; destData: array[0..3] of Byte; i: Integer;
begin
  buf := TByteBufImpl.New(10);

  // 准备源数据
  srcData[0] := $AA; srcData[1] := $BB; srcData[2] := $CC; srcData[3] := $DD;

  // 使用 WriteBytesFrom 写入数据
  buf.WriteBytesFrom(@srcData[0], 4);
  AssertEquals(4, buf.ReadableBytes);

  // 使用 ReadBytesInto 读取数据
  FillChar(destData, SizeOf(destData), 0);
  buf.ReadBytesInto(@destData[0], 4);

  // 验证数据正确性
  for i := 0 to 3 do
    AssertEquals(srcData[i], destData[i]);

  AssertEquals(0, buf.ReadableBytes);
end;

procedure TTestCase_ByteBuf.Test_WriteBytesUnchecked_Performance;
var buf: IByteBuf; testData: TBytes; i: Integer;
begin
  buf := TByteBufImpl.New(0);
  SetLength(testData, 4);
  testData[0] := $11; testData[1] := $22; testData[2] := $33; testData[3] := $44;

  // 预先确保有足够容量
  buf.EnsureWritable(4);

  // 使用 WriteBytesUnchecked（假设容量已足够）
  buf.WriteBytesUnchecked(testData);
  AssertEquals(4, buf.ReadableBytes);

  // 验证数据正确性
  for i := 0 to 3 do
    AssertEquals(testData[i], buf.ReadU8);
end;

initialization
  RegisterTest(TTestCase_ByteBuf);

end.

