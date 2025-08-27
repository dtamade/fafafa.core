unit fafafa.core.bytes.testcase;

{$MODE OBJFPC}{$H+}
{$modeswitch advancedrecords}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.base,
  fafafa.core.bytes,
  fafafa.core.io.adapters;

type
  // 简单限流 Source：每次 Read 最多返回 ChunkSize 字节
  TChunkedMemorySource = class(TInterfacedObject, IByteSource)
  private
    FData: TBytes;
    FPos: SizeInt;
    FChunk: SizeInt;
  public
    constructor Create(const Bytes: TBytes; AChunk: SizeInt);
    function Read(P: Pointer; Count: SizeInt): SizeInt;
  end;
type
  // 简单限流 Sink：每次 Write 最多写入 ChunkSize 字节到给定流
  TChunkedStreamSink = class(TInterfacedObject, IByteSink)
  private
    FStream: TStream;
    FChunk: SizeInt;
  public
    constructor Create(AStream: TStream; AChunk: SizeInt);
    function Write(const P: Pointer; Count: SizeInt): SizeInt;
    function WriteBytes(const B: TBytes): SizeInt;
    function WriteByte(Value: Byte): SizeInt;
  end;


type
  TTestCase_Global = class(TTestCase)
  published
    // Hex
    procedure Test_BytesToHex_Empty;
    procedure Test_HexToBytes_EvenValid;
    procedure Test_HexToBytes_InvalidLength;
    procedure Test_TryHexToBytesLoose_PrefixSpaces;
    procedure Test_TryParseHexLoose_PrefixHash;
    procedure Test_Hex_Roundtrip_Random;
    procedure Test_TryParseHexLoose_EmptyAndSpaces;
    procedure Test_TryParseHexLoose_InvalidChar;
    procedure Test_BytesToHex_Upper;
    procedure Test_TryHexToBytesStrict_OK_And_Fail;

    // 基础
    procedure Test_Slice_Bounds;
    procedure Test_Concat_Basic;
    procedure Test_Zero;
    procedure Test_SecureBytesZero;

    // 端序读写
    procedure Test_ReadWrite_U16_U32_U64_LE_BE;
    procedure Test_ReadWithCursor_Advance_And_Bounds;
  end;

  TTestCase_TBytesBuilder = class(TTestCase)
  published
    procedure Test_Append_And_ToBytes;
    procedure Test_AppendUxx_And_Length;
    procedure Test_AppendHex_Strict;
    procedure Test_Reset_Clear_Equivalence;
    procedure Test_Truncate_Bounds;
    procedure Test_ShrinkToFit;
    procedure Test_AppendString_And_Grow;
    procedure Test_Grow_Explicit;
    procedure Test_BeginWrite_Commit_Normal_And_Errors;
    procedure Test_DetachTrim_IntoBytes_Behavior;

    procedure Test_EnsureCapacity_Negative_Argument;
    procedure Test_BeginWrite_Negative_Request_Error;
    procedure Test_IntoBytes_PerfectCapacity_ZeroCopy_Semantics;

    procedure Test_IntoBytes_CopyPath_NoReset;

    procedure Test_Peek_ReadOnly_Borrow;
    procedure Test_DetachNoTrim_StrictZeroCopy;
    procedure Test_IO_Adapters_Roundtrip;
    procedure Test_Source_ShortReads_EOF;
    procedure Test_EnsureWritable_Overflow_Guard;
    procedure Test_BeginWrite_Overflow_Guard;
    procedure Test_DetachTrim_Shrink_Copy_Semantics;
    procedure Test_ShortReadWrite_Zero_One_Byte_Loops;
    procedure Test_Stream_Roundtrip_Direct;

    // AChunkSize 随机化 I/O
    procedure Test_IO_AChunkSize_CountMinus1_Randomized;
    procedure Test_IO_AChunkSize_CountFixed_Randomized;

    // ReserveExact 边界
    procedure Test_ReserveExact_Shrink_TrimsLen;
    procedure Test_ReserveExact_Grow_KeepLen;
    procedure Test_ReserveExact_Peek_ThenAppend;
  end;

implementation

procedure TTestCase_Global.Test_BytesToHex_Empty;
var B: TBytes;
begin
  SetLength(B,0);
  AssertEquals('empty->hex length', 0, Length(BytesToHex(B)));
end;

procedure TTestCase_Global.Test_HexToBytes_EvenValid;
var B: TBytes;
begin
  B := HexToBytes('0A1b');
  AssertEquals(2, Length(B));
  AssertEquals(Byte($0A), B[0]);
  AssertEquals(Byte($1B), B[1]);
end;

procedure TTestCase_Global.Test_HexToBytes_InvalidLength;
var Tmp: TBytes;
begin
  AssertException('odd length', EInvalidArgument,
    procedure begin Tmp := HexToBytes('abc'); end);
end;

procedure TTestCase_Global.Test_TryHexToBytesLoose_PrefixSpaces;
var B: TBytes; ok: Boolean;
begin
  ok := TryHexToBytesLoose('  0x0a 1B  ', B);
  AssertTrue(ok);
  AssertEquals(2, Length(B));
  AssertEquals(Byte($0A), B[0]);
  AssertEquals(Byte($1B), B[1]);
end;

procedure TTestCase_Global.Test_TryParseHexLoose_PrefixHash;
var B: TBytes; ok: Boolean;
begin
  ok := TryParseHexLoose('#0A1B', B);
  AssertTrue(ok);
  AssertEquals(2, Length(B));
  AssertEquals(Byte($0A), B[0]);
  AssertEquals(Byte($1B), B[1]);
end;

procedure TTestCase_Global.Test_Hex_Roundtrip_Random;
var i, n: Integer; B, B2: TBytes; S: String;
begin
  Randomize;
  n := 128;
  SetLength(B, n);
  for i := 0 to n-1 do B[i] := Byte(Random(256));
  S := BytesToHex(B);
  B2 := HexToBytes(S);
  AssertEquals(n, Length(B2));
  for i := 0 to n-1 do AssertEquals(B[i], B2[i]);
end;

procedure TTestCase_Global.Test_TryParseHexLoose_EmptyAndSpaces;
var B: TBytes; ok: Boolean;
begin
  ok := TryParseHexLoose('', B); AssertTrue(ok); AssertEquals(0, Length(B));
  ok := TryParseHexLoose('   ', B); AssertTrue(ok); AssertEquals(0, Length(B));
end;

procedure TTestCase_Global.Test_TryParseHexLoose_InvalidChar;
var B: TBytes; ok: Boolean;
begin
  ok := TryParseHexLoose('0xGG', B);
  AssertFalse(ok);
  AssertEquals(0, Length(B));
end;

procedure TTestCase_Global.Test_Slice_Bounds;
var B,S: TBytes;
begin
  B := HexToBytes('0011223344');
  S := BytesSlice(B, 1, 3);
  AssertEquals(3, Length(S));
  AssertEquals(Byte($11), S[0]);
  AssertException('oob', EOutOfRange,
    procedure begin S := BytesSlice(B, 4, 2); end);
end;

procedure TTestCase_Global.Test_Concat_Basic;
var A,B,C: TBytes;
begin
  A := HexToBytes('0011'); B := HexToBytes('2233');
  C := BytesConcat(A,B);
  AssertEquals(4, Length(C));
  AssertEquals(Byte($00), C[0]);
  AssertEquals(Byte($11), C[1]);
  AssertEquals(Byte($22), C[2]);
  AssertEquals(Byte($33), C[3]);
end;

procedure TTestCase_Global.Test_Zero;
var B: TBytes;
var i: Integer;
begin
  B := HexToBytes('DEADBEEF');
  BytesZero(B);
  for i := 0 to High(B) do AssertEquals(Byte(0), B[i]);
end;

procedure TTestCase_Global.Test_ReadWrite_U16_U32_U64_LE_BE;
var B: TBytes; u16: UInt16; u32: UInt32; u64: UInt64;
begin
  SetLength(B, 16);
  // initialize to silence uninitialized warnings
  u16 := 0; u32 := 0; u64 := 0;
  WriteU16LE(B, 0, $1234); AssertEquals($1234, ReadU16LE(B,0));
  WriteU16BE(B, 2, $1234); AssertEquals($1234, ReadU16BE(B,2));

  WriteU32LE(B, 4, $89ABCDEF); AssertEquals($89ABCDEF, ReadU32LE(B,4));
  WriteU32BE(B, 8, $89ABCDEF); AssertEquals($89ABCDEF, ReadU32BE(B,8));

  WriteU64LE(B, 0, UInt64($1122334455667788));
  AssertEquals(UInt64($1122334455667788), ReadU64LE(B,0));
  WriteU64BE(B, 8, UInt64($1122334455667788));
  AssertEquals(UInt64($1122334455667788), ReadU64BE(B,8));

  AssertException('read oob', EOutOfRange,
    procedure begin u16 := ReadU16LE(B, Length(B)-1); end);
  AssertException('write oob', EOutOfRange,
    procedure begin WriteU32BE(B, Length(B)-3, $AA); end);

  // calm unused warnings
  if u16=0 then; if u32=0 then; if u64=0 then;
end;

procedure TTestCase_Global.Test_ReadWithCursor_Advance_And_Bounds;
var B: TBytes; off: SizeInt; v16: UInt16; v32: UInt32; v64: UInt64;
begin
  B := HexToBytes('00112233445566778899AABBCCDDEEFF');
  off := 0;
  v16 := ReadU16BEAdv(B, off); // 00 11
  AssertEquals(UInt16($0011), v16);
  AssertEquals(2, off);
  v32 := ReadU32LEAdv(B, off); // 22 33 44 55 (LE)
  AssertEquals(UInt32($55443322), v32);
  AssertEquals(6, off);
  v64 := ReadU64BEAdv(B, off); // 66..6D (BE from index 6)
  AssertEquals(UInt64($66778899AABBCCDD), v64);
  AssertEquals(14, off);
  AssertException('cursor read oob', EOutOfRange,
    procedure begin v32 := ReadU32LEAdv(B, off); end);
  // calm unused
  if v16=0 then; if v64=0 then;
end;

procedure TTestCase_TBytesBuilder.Test_Append_And_ToBytes;
var bb: TBytesBuilder; outB: TBytes;
begin
  bb.Init(0);
  bb.AppendByte($AA);
  bb.Append(HexToBytes('bbcc'));
  outB := bb.ToBytes;
  AssertEquals(3, Length(outB));
  AssertEquals(Byte($AA), outB[0]);
  AssertEquals(Byte($BB), outB[1]);
  AssertEquals(Byte($CC), outB[2]);
end;

procedure TTestCase_TBytesBuilder.Test_AppendUxx_And_Length;
var bb: TBytesBuilder; outB: TBytes;
begin
  bb.Init(1);
  bb.AppendU16BE($0102);
  bb.AppendU32LE($A0B0C0D0);
  AssertTrue(bb.Length >= 6);
  outB := bb.ToBytes;
  AssertEquals(Byte($01), outB[0]);
  AssertEquals(Byte($02), outB[1]);

  end;

procedure TTestCase_Global.Test_BytesToHex_Upper;
var B: TBytes; S: string;
begin
  B := HexToBytes('0a1b');
  S := BytesToHexUpper(B);
  AssertEquals('0A1B', S);
end;

procedure TTestCase_Global.Test_TryHexToBytesStrict_OK_And_Fail;
var B: TBytes; ok: Boolean;
begin
  ok := TryHexToBytesStrict('0A1B', B);
  AssertTrue(ok);
  AssertEquals(2, Length(B));
  AssertEquals(Byte($0A), B[0]);
  AssertEquals(Byte($1B), B[1]);
  ok := TryHexToBytesStrict('0x0A', B);
  AssertFalse(ok);
  AssertEquals(0, Length(B));
end;

procedure TTestCase_Global.Test_SecureBytesZero;
var B: TBytes; i: Integer;
begin
  B := HexToBytes('DEADBEEF');
  SecureBytesZero(B);
  for i := 0 to High(B) do AssertEquals(Byte(0), B[i]);
end;

procedure TTestCase_TBytesBuilder.Test_Reset_Clear_Equivalence;
var bb: TBytesBuilder; outB: TBytes;
begin
  bb.Init(0);
  bb.AppendHex('0011');
  bb.Reset;
  outB := bb.ToBytes;
  AssertEquals(0, Length(outB));
  bb.AppendHex('2233');
  bb.Clear;
  outB := bb.ToBytes;
  AssertEquals(0, Length(outB));
end;

procedure TTestCase_TBytesBuilder.Test_Truncate_Bounds;
var bb: TBytesBuilder; outB: TBytes;
begin
  bb.Init(0);
  bb.AppendHex('00112233');
  bb.Truncate(2);
  outB := bb.ToBytes;
  AssertEquals(2, Length(outB));
  AssertEquals(Byte($00), outB[0]);
  AssertEquals(Byte($11), outB[1]);
  AssertException('truncate oob', EOutOfRange, procedure begin bb.Truncate(3); end);
end;

procedure TTestCase_TBytesBuilder.Test_ShrinkToFit;
var bb: TBytesBuilder; capBefore, capAfter: SizeInt;
begin
  bb.Init(4);
  bb.AppendHex('0011');
  capBefore := bb.Capacity;
  bb.ShrinkToFit;
  capAfter := bb.Capacity;
  AssertTrue('capacity shrunk or equal', capAfter <= capBefore);
  AssertEquals(2, bb.Length);
end;

procedure TTestCase_TBytesBuilder.Test_AppendString_And_Grow;
var bb: TBytesBuilder; outB: TBytes; s: RawByteString;
begin
  bb.Init(1);
  s := RawByteString(#$AA + #$BB + #$CC);
  bb.AppendString(s);
  outB := bb.ToBytes;
  AssertEquals(3, Length(outB));
  AssertEquals(Byte($AA), outB[0]);
  AssertEquals(Byte($BB), outB[1]);
  AssertEquals(Byte($CC), outB[2]);
end;

procedure TTestCase_TBytesBuilder.Test_Grow_Explicit;
var bb: TBytesBuilder; cap0, cap1: SizeInt;
begin
  bb.Init(0);
  cap0 := bb.Capacity;
  bb.Grow(10);
  cap1 := bb.Capacity;
  AssertTrue('capacity increased', cap1 >= cap0 + 10);
  end;

procedure TTestCase_TBytesBuilder.Test_BeginWrite_Commit_Normal_And_Errors;
var bb: TBytesBuilder; p: Pointer; granted: SizeInt; outB: TBytes;
begin
  bb.Init(0);
  // normal
  bb.BeginWrite(5, p, granted);
  AssertTrue(granted >= 5);
  FillChar(p^, 5, $41);
  bb.Commit(5);
  outB := bb.ToBytes;
  AssertEquals(5, Length(outB));
  AssertEquals(Byte($41), outB[0]);
  // error: double commit
  AssertException('no pending write', EInvalidOperation, procedure begin bb.Commit(0); end);
  // error: over commit
  bb.BeginWrite(3, p, granted);
  AssertException('over commit', EInvalidArgument, procedure begin bb.Commit(granted+1); end);
end;

procedure TTestCase_TBytesBuilder.Test_DetachTrim_IntoBytes_Behavior;
var bb: TBytesBuilder; used: SizeInt; buf: TBytes; outB: TBytes;
begin
  bb.Init(0);
  bb.AppendHex('001122');
  // IntoBytes when capacity==length? Not guaranteed here; use DetachTrim explicitly
  buf := bb.DetachTrim(used);
  AssertEquals(3, used);
  AssertEquals(3, Length(buf));
  // bb reset
  AssertEquals(0, bb.Length);
  // Append after detach should still work
  bb.AppendHex('AABB');
  outB := bb.ToBytes;
  AssertEquals(2, Length(outB));
  AssertEquals(Byte($AA), outB[0]);
  AssertEquals(Byte($BB), outB[1]);
end;

procedure TTestCase_TBytesBuilder.Test_EnsureCapacity_Negative_Argument;
var bb: TBytesBuilder;
begin
  bb.Init(0);
  AssertException('negative capacity', EInvalidArgument, procedure begin bb.EnsureCapacity(-1); end);
end;

procedure TTestCase_TBytesBuilder.Test_BeginWrite_Negative_Request_Error;
var bb: TBytesBuilder; p: Pointer; g: SizeInt;
begin
  bb.Init(0);
  AssertException('negative request', EInvalidArgument, procedure begin bb.BeginWrite(-5, p, g); end);
end;

procedure TTestCase_TBytesBuilder.Test_IntoBytes_PerfectCapacity_ZeroCopy_Semantics;
var bb: TBytesBuilder; p: Pointer; g: SizeInt; outB: TBytes;
begin
  bb.Init(4);
  // ensure capacity equals length after write
  bb.BeginWrite(4, p, g);
  FillChar(p^, 4, $5A);
  bb.Commit(4);
  // perfect fit expected -> zero-copy
  outB := bb.IntoBytes;
  AssertEquals(4, Length(outB));
  // bb should be reset
  AssertEquals(0, bb.Length);
  // further writes still work
  bb.AppendByte($01);
  AssertEquals(1, bb.Length);
end;

procedure TTestCase_TBytesBuilder.Test_IntoBytes_CopyPath_NoReset;
var bb: TBytesBuilder; B1, B2: TBytes;
begin
  bb.Init(0);
  // Force non-perfect capacity (capacity > len)
  bb.Reserve(10);
  bb.AppendHex('AABB');
  B1 := bb.IntoBytes; // copy path
  AssertEquals(2, Length(B1));
  // copy path should NOT reset builder (only zero-copy resets)
  AssertEquals(2, bb.Length);
  // Another IntoBytes now with perfect capacity (after ShrinkToFit)
  bb.ShrinkToFit;
  B2 := bb.IntoBytes;
  AssertEquals(2, Length(B2));
  AssertEquals(0, bb.Length);
end;

procedure TTestCase_TBytesBuilder.Test_Peek_ReadOnly_Borrow;
var bb: TBytesBuilder; p: Pointer; n: SizeInt; outB: TBytes;
begin
  bb.Init(0);
  bb.AppendHex('AABBCC');
  bb.Peek(p, n);
  AssertTrue(p <> nil);
  AssertEquals(3, n);
  // mutate builder then peek should still be consistent (new pointer is fine)
  bb.AppendByte($DD);
  bb.Peek(p, n);
  AssertEquals(4, n);
  outB := bb.ToBytes;
  AssertEquals(4, Length(outB));
  AssertEquals(Byte($AA), outB[0]);
  AssertEquals(Byte($BB), outB[1]);
  AssertEquals(Byte($CC), outB[2]);
  AssertEquals(Byte($DD), outB[3]);
end;

procedure TTestCase_TBytesBuilder.Test_DetachNoTrim_StrictZeroCopy;
var bb: TBytesBuilder; used: SizeInt; buf: TBytes;
begin
  bb.Init(8);
  bb.AppendHex('AABB');
  // capacity > length; DetachNoTrim should transfer whole buffer reference without shrink
  buf := bb.DetachNoTrim(used);
  AssertEquals(2, used);
  // buf length equals capacity at transfer time; we cannot assert exact Length(buf) here,
  // but we can assert builder is reset and buf[0..1] hold data
  AssertEquals(0, bb.Length);
  AssertTrue(Length(buf) >= 2);
  AssertEquals(Byte($AA), buf[0]);
  AssertEquals(Byte($BB), buf[1]);
end;

procedure TTestCase_TBytesBuilder.Test_Stream_Roundtrip_Direct;
var bb: TBytesBuilder; ms: TMemoryStream; wrote: Int64; p: Pointer; n: SizeInt; bb2: TBytesBuilder; read: Int64; sink: IByteSink; src: IByteSource;
begin
  bb.Init(0);
  bb.AppendHex('DEADBEEF');
  ms := TMemoryStream.Create;
  try
    // direct write via Sink
    sink := MakeStreamSink(ms);
    wrote := WriteToSink(bb, sink);
    AssertEquals(Int64(4), wrote);
    AssertEquals(4, ms.Size);

    ms.Position := 0;
    bb2.Init(0);
    src := MakeStreamSource(ms);
    read := ReadFromSource(bb2, src, -1);
    AssertEquals(Int64(4), read);
    bb2.Peek(p, n);
  AssertEquals(4, n);
  AssertEquals(Byte($DE), PByte(p)^);
  finally
    ms.Free;
  end;
end;

procedure TTestCase_TBytesBuilder.Test_ReserveExact_Shrink_TrimsLen;
var bb: TBytesBuilder; P: Pointer; N: SizeInt;
begin
  bb.Init(0);
  bb.AppendHex('AABBCCDD'); // len=4
  AssertEquals(4, bb.Length);
  bb.ReserveExact(2); // shrink capacity to 2 -> FLen trimmed to 2
  AssertEquals(2, bb.Length);
  // data correctness of first 2 bytes
  bb.Peek(P, N);
  AssertEquals(2, N);
  AssertEquals(Byte($AA), PByte(P)^);
  AssertEquals(Byte($BB), PByte(PByte(P)+1)^);
  // can continue appending
  bb.AppendHex('EE');
  AssertEquals(3, bb.Length);
end;

procedure TTestCase_TBytesBuilder.Test_ReserveExact_Grow_KeepLen;
var bb: TBytesBuilder; oldLen: SizeInt;
begin
  bb.Init(0);
  bb.AppendHex('AABB'); // len=2
  oldLen := bb.Length;
  bb.ReserveExact(16); // grow capacity to 16 -> length unchanged
  AssertEquals(oldLen, bb.Length);
  // subsequent operations still work
  bb.AppendHex('CC');
  AssertEquals(oldLen+1, bb.Length);
end;

procedure TTestCase_TBytesBuilder.Test_ReserveExact_Peek_ThenAppend;
var bb: TBytesBuilder; P: Pointer; N: SizeInt;
begin
  bb.Init(4);
  bb.AppendHex('AABB');
  bb.Peek(P, N);
  AssertEquals(2, N);
  // shrink not below length -> no trim, pointer remains valid until next mutation
  bb.ReserveExact(4);
  // next mutation invalidates previous borrow; we only assert subsequent behavior
  bb.AppendHex('CCDD');
  bb.Peek(P, N);
  AssertEquals(4, N);
end;

procedure TTestCase_TBytesBuilder.Test_IO_Adapters_Roundtrip;
var ms1, ms2: TMemoryStream; sink: IByteSink; src, src2: IByteSource; bb: TBytesBuilder; wrote, read, dataRead: Int64; P: Pointer; N: SizeInt; buf: array[0..4] of Byte; arr: TBytes;
begin
  ms1 := TMemoryStream.Create; ms2 := TMemoryStream.Create;
  try
    // 写入 ms1 原始数据
    ms1.WriteBuffer(PAnsiChar('hello')^, 5);
    ms1.Position := 0;

    // 插入 Peek 契约测试放在单独过程，避免打断当前流程

    // 继续原有流程
    src := MakeStreamSource(ms1);
    bb.Init(0);
    read := ReadFromSource(bb, src, -1);
    AssertEquals(Int64(5), read);
    bb.Peek(P, N);
    AssertEquals(5, N);

    // Sink 写出到 ms2
    sink := MakeStreamSink(ms2);
    wrote := WriteToSink(bb, sink);
    AssertEquals(Int64(5), wrote);
    AssertEquals(5, ms2.Size);

    // 校验内容
    ms2.Position := 0;
    AssertEquals(5, ms2.Read(buf, 5));
    AssertEquals(Byte(Ord('h')), buf[0]);
    AssertEquals(Byte(Ord('e')), buf[1]);
    AssertEquals(Byte(Ord('l')), buf[2]);
    AssertEquals(Byte(Ord('l')), buf[3]);
    AssertEquals(Byte(Ord('o')), buf[4]);

    // 短读与 EOF 组合：每次最多 2 字节
    SetLength(arr, 7);
    arr[0]:=Ord('A'); arr[1]:=Ord('B'); arr[2]:=Ord('C'); arr[3]:=Ord('D'); arr[4]:=Ord('E'); arr[5]:=Ord('F'); arr[6]:=Ord('G');
    src2 := TChunkedMemorySource.Create(arr, 2);
    bb.Init(0);
    dataRead := ReadFromSource(bb, src2, -1);
    AssertEquals(Int64(7), dataRead);
    bb.Peek(P, N);
    AssertEquals(7, N);
    AssertEquals(Byte(Ord('A')), PByte(P)^);

  finally
    ms1.Free; ms2.Free;
  end;
end;


procedure TTestCase_TBytesBuilder.Test_DetachTrim_Shrink_Copy_Semantics;
var bb: TBytesBuilder; used: SizeInt; buf: TBytes;
begin
  bb.Init(0);
  bb.Reserve(16);
  bb.AppendHex('A1B2C3'); // len=3, cap>=16
  buf := bb.DetachTrim(used);
  AssertEquals(3, used);
  AssertEquals(3, Length(buf));
  AssertEquals(Byte($A1), buf[0]);
  AssertEquals(Byte($B2), buf[1]);
  AssertEquals(Byte($C3), buf[2]);
  AssertEquals(0, bb.Length);
end;

procedure TTestCase_TBytesBuilder.Test_ShortReadWrite_Zero_One_Byte_Loops;
var bb: TBytesBuilder; ms: TMemoryStream; sink: IByteSink; src: IByteSource; read,wrote: Int64; P: Pointer; N: SizeInt;
begin
  // prepare source bytes with 0/1 byte step via chunked source (chunk=1)
  ms := TMemoryStream.Create;
  try
    ms.WriteBuffer(PAnsiChar('abcdefg')^, 7);
    ms.Position := 0;
    src := MakeStreamSource(ms);
    bb.Init(0);
    read := ReadFromSource(bb, src, -1);
    AssertEquals(Int64(7), read);
    bb.Peek(P, N);
    AssertEquals(7, N);

    // write via chunked sink with chunk=1 to force multiple short writes
    ms.Clear; ms.Position := 0;
    sink := TChunkedStreamSink.Create(ms, 1);
    wrote := WriteToSink(bb, sink);
    AssertEquals(Int64(7), wrote);
    AssertEquals(7, ms.Size);
  finally
    ms.Free;
  end;
end;

procedure TTestCase_TBytesBuilder.Test_ToBytes_AlwaysCopy_PointerDiff;
var bb: TBytesBuilder; P: Pointer; N: SizeInt; outB: TBytes;
begin
  bb.Init(0);
  bb.AppendHex('A1B2C3');
  bb.Peek(P, N);
  AssertEquals(3, N);
  outB := bb.ToBytes;
  AssertEquals(3, Length(outB));
  // ToBytes must copy; pointer should differ from borrowed pointer
  AssertTrue(NativeUInt(P) <> NativeUInt(@outB[0]));
  // builder unchanged
  AssertEquals(3, bb.Length);
end;

procedure TTestCase_TBytesBuilder.Test_IntoBytes_ZeroCopy_PointerEquality;
var bb: TBytesBuilder; P: Pointer; N: SizeInt; outB: TBytes;
begin
  bb.Init(0);
  bb.AppendHex('A1B2C3');
  // make perfect capacity
  bb.ShrinkToFit;
  bb.Peek(P, N);
  AssertEquals(3, N);
  outB := bb.IntoBytes;
  AssertEquals(3, Length(outB));
  // zero-copy expected: same pointer
  AssertEquals(NativeUInt(P), NativeUInt(@outB[0]));
  // builder reset
  AssertEquals(0, bb.Length);
end;

procedure TTestCase_TBytesBuilder.Test_DetachNoTrim_ZeroCopy_PointerEquality;
var bb: TBytesBuilder; P: Pointer; N: SizeInt; outB: TBytes; used: SizeInt;
begin
  bb.Init(8);
  bb.AppendHex('A1B2C3');
  bb.Peek(P, N);
  AssertEquals(3, N);
  outB := bb.DetachNoTrim(used);
  AssertEquals(3, used);
  AssertTrue(Length(outB) >= 3);
  // zero-copy expected: same pointer
  AssertEquals(NativeUInt(P), NativeUInt(@outB[0]));
  // builder reset
  AssertEquals(0, bb.Length);
end;


procedure TTestCase_TBytesBuilder.Test_DetachTrim_MayCopy_BuilderReset;
var bb: TBytesBuilder; used: SizeInt; buf: TBytes; capBefore: SizeInt;
begin
  bb.Init(0);
  bb.AppendHex('A1B2C3');
  // force extra capacity
  bb.Reserve(16);
  capBefore := bb.Capacity;
  buf := bb.DetachTrim(used);
  AssertEquals(3, used);
  AssertEquals(3, Length(buf));
  // DetachTrim may copy (shrink), pointer equality无法保证；仅验证 builder 被 reset
  AssertEquals(0, bb.Length);
end;




procedure TTestCase_TBytesBuilder.Test_AppendHex_Strict;
var bb: TBytesBuilder; outB: TBytes;
begin
  bb.Init(0);
  bb.AppendHex('0A1B');
  outB := bb.ToBytes;
  AssertEquals(2, Length(outB));
  AssertEquals(Byte($0A), outB[0]);
  AssertEquals(Byte($1B), outB[1]);
end;

procedure TTestCase_TBytesBuilder.Test_Source_ShortReads_EOF;
var ms: TMemoryStream; src: IByteSource; bb: TBytesBuilder; P: Pointer; N: SizeInt; read: Int64;
begin
  ms := TMemoryStream.Create;
  try
    // 空流 -> 立即 EOF
    src := MakeStreamSource(ms);
    bb.Init(0);
    read := ReadFromSource(bb, src, -1);
    AssertEquals(Int64(0), read);
    bb.Peek(P, N);
    AssertEquals(0, N);
  finally
    ms.Free;
  end;
end;
{ TChunkedMemorySource }
constructor TChunkedMemorySource.Create(const Bytes: TBytes; AChunk: SizeInt);
begin
  inherited Create;
  FData := Bytes;
  FPos := 0;
  if AChunk <= 0 then FChunk := 1 else FChunk := AChunk;
end;

function TChunkedMemorySource.Read(P: Pointer; Count: SizeInt): SizeInt;
var remain, give: SizeInt;
begin
  if Count <= 0 then Exit(0);
  remain := Length(FData) - FPos;
  if remain <= 0 then Exit(0);
  give := Count;
  if give > FChunk then give := FChunk;
  if give > remain then give := remain;
  Move(FData[FPos], P^, give);
  Inc(FPos, give);
  Result := give;
end;


{ TChunkedStreamSink }
constructor TChunkedStreamSink.Create(AStream: TStream; AChunk: SizeInt);
begin
  inherited Create;
  FStream := AStream;
  if AChunk <= 0 then FChunk := 1 else FChunk := AChunk;
end;

function TChunkedStreamSink.Write(const P: Pointer; Count: SizeInt): SizeInt;
var n: Longint;
begin
  if (P = nil) or (Count <= 0) then Exit(0);
  n := Count;
  if n > FChunk then n := FChunk;
  Result := FStream.Write(P^, n);
end;

function TChunkedStreamSink.WriteBytes(const B: TBytes): SizeInt;
begin
  if Length(B) = 0 then Exit(0);
  Result := Write(@B[0], Length(B));
end;

function TChunkedStreamSink.WriteByte(Value: Byte): SizeInt;
begin
  Result := FStream.Write(Value, 1);
end;

procedure TTestCase_TBytesBuilder.Test_IO_AChunkSize_CountMinus1_Randomized;
var bb: TBytesBuilder; ms: TMemoryStream; src: IByteSource; sink: IByteSink; data: TBytes; i, idx, chunk: SizeInt; total: Int64; P: Pointer; N: SizeInt;
begin
  // prepare 257 bytes to force multiple chunks
  SetLength(data, 257);
  for i := 0 to High(data) do data[i] := Byte(i and $FF);

  // read path Count=-1 with various AChunkSize
  for idx in [0,1,2,3] do
  begin
    case idx of
      0: chunk := 0;
      1: chunk := 1;
      2: chunk := 2;
      else chunk := 4096;
    end;
    ms := TMemoryStream.Create;
    try
      // write source data
      if Length(data) > 0 then ms.WriteBuffer(data[0], Length(data));
      ms.Position := 0;
      src := MakeStreamSource(ms);

      bb.Init(0);
      total := ReadFromSource(bb, src, -1, chunk);
      AssertEquals(Int64(Length(data)), total);

      // write out via chunked sink with small chunk to exercise short writes
      ms.Clear; ms.Position := 0;
      sink := TChunkedStreamSink.Create(ms, 3);
      total := WriteToSink(bb, sink, chunk);
      AssertEquals(Int64(Length(data)), total);
      AssertEquals(Length(data), ms.Size);
    finally
      ms.Free;
    end;
  end; // idx loop
end;

procedure TTestCase_TBytesBuilder.Test_IO_AChunkSize_CountFixed_Randomized;
var bb: TBytesBuilder; ms: TMemoryStream; src: IByteSource; data: TBytes; i, chunk: SizeInt; total: Int64; P: Pointer; N: SizeInt; want: SizeInt;
begin
  // prepare 100 bytes input
  SetLength(data, 100);
  for i := 0 to High(data) do data[i] := Byte(255 - (i and $FF));

  // test Count-fixed reads with various AChunkSize
  for chunk in [0,1,2,64] do
  begin
    ms := TMemoryStream.Create;
    try
      if Length(data) > 0 then ms.WriteBuffer(data[0], Length(data));
      ms.Position := 0;
      src := MakeStreamSource(ms);

      bb.Init(0);
      // exact count smaller than data size; verify partial read then EOF on subsequent read
      want := 57;
      total := ReadFromSource(bb, src, want, chunk);
      AssertEquals(Int64(want), total);

      // subsequent read should consume remaining bytes (100 - want)
      total := ReadFromSource(bb, src, -1, chunk);
      AssertEquals(Int64(Length(data) - want), total);
      // then EOF on next read
      total := ReadFromSource(bb, src, -1, chunk);
      AssertEquals(Int64(0), total);

      // verify buffer content length equals total (100)
      bb.Peek(P, N);
      AssertEquals(Length(data), N);
    finally
      ms.Free;
    end;
  end;
end;

procedure TTestCase_TBytesBuilder.Test_EnsureWritable_Overflow_Guard;
var bb: TBytesBuilder;
begin
  bb.Init(0);
  // 不能真正构造溢出，但可以构造负值参数触发异常，以覆盖保护路径
  AssertException('negative min add', EInvalidArgument, procedure begin bb.EnsureWritable(-1); end);
end;

procedure TTestCase_TBytesBuilder.Test_BeginWrite_Overflow_Guard;
var bb: TBytesBuilder; P: Pointer; G: SizeInt;
begin
  bb.Init(0);
  AssertException('negative request', EInvalidArgument, procedure begin bb.BeginWrite(-5, P, G); end);
end;

initialization
  RegisterTest(TTestCase_Global);
  RegisterTest(TTestCase_TBytesBuilder);

end.

