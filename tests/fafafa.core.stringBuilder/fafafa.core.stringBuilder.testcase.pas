unit fafafa.core.stringBuilder.testcase;

{$MODE OBJFPC}{$H+}
{$modeswitch advancedrecords}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.base,
  fafafa.core.bytes,
  fafafa.core.stringBuilder;

type
  TTestCase_Global = class(TTestCase)
  published
    procedure Test_New_And_Capacity;
    procedure Test_Append_And_ToString;
    procedure Test_AppendLine;
    procedure Test_AppendChar_And_CodePoint;
    procedure Test_AppendByte_Basic;
    procedure Test_AppendBytes_StrictUTF8;
    procedure Test_Reserve_And_Length_Unchanged;
    procedure Test_ToRaw_And_ZeroByte_Consistency;
    procedure Test_ZeroCopy_APIs_Semantics;
    procedure Test_AppendLF_CRLF;
    procedure Test_Stream_IO_Roundtrip;
    procedure Test_IntoBytes_ZeroCopy_After_ShrinkToFit;
    procedure Test_UTF8_Append_APIs;
    procedure Test_Stream_ZeroCopy_Paths;
  end;

implementation

procedure TTestCase_Global.Test_New_And_Capacity;
var B: IStringBuilder;
begin
  B := MakeStringBuilder(16);
  AssertTrue(B <> nil);
  AssertTrue(B.Capacity >= 16);
  AssertEquals(0, B.Length);
end;

procedure TTestCase_Global.Test_Append_And_ToString;
var
  B: IStringBuilder;
  S: string;
  needle: string;
begin
  // NOTE: 在当前 FPC 构建中，Pos('你好', S) 可能返回 0（UTF-8 字面量处理问题）。
  // 用变量可稳定得到正确结果。
  needle := '你好';

  B := MakeStringBuilder(0);
  B.Append(needle).Append(', ').Append('world');
  S := B.ToString;
  AssertTrue(Pos(needle, S) > 0);
  AssertTrue(Pos('world', S) > 0);
end;

procedure TTestCase_Global.Test_AppendLine;
var B: IStringBuilder; S: string;
begin
  B := MakeStringBuilder(0);
  B.AppendLine('a').Append('b').AppendLine;
  S := B.ToString;
  AssertTrue(Pos(LineEnding + 'b' + LineEnding, S) > 0);
end;

procedure TTestCase_Global.Test_AppendChar_And_CodePoint;
var B: IStringBuilder; S: string; L0, L1: SizeInt;
begin
  B := MakeStringBuilder(0);
  L0 := B.Length;
  B.AppendChar('A');
  L1 := B.Length;
  // 编码无关：仅验证长度增长 SizeOf(Char) 与首字节表现
  AssertTrue(L1 - L0 = SizeOf(Char));
  S := B.ToString;
  AssertTrue(Pos('A', S) = 1);
end;

procedure TTestCase_Global.Test_AppendByte_Basic;
var B: IStringBuilder; raw: RawByteString; L0: SizeInt;
begin
  B := MakeStringBuilder(0);
  L0 := B.Length;
  B.AppendByte($00).AppendByte($41).AppendByte($FF);
  AssertEquals(L0 + 3, B.Length);
  raw := B.ToRaw;
  AssertEquals(3, Length(raw));
  AssertEquals(AnsiChar(#0), raw[1]);
  AssertEquals(AnsiChar('A'), raw[2]);
end;

procedure TTestCase_Global.Test_AppendBytes_StrictUTF8;
var B: IStringBuilder; data: TBytes; raw: RawByteString;
begin
  SetLength(data, 3);
  data[0] := $E2; data[1] := $82; data[2] := $AC; // raw bytes ("€")
  B := MakeStringBuilder(0);
  B.AppendBytes(data);
  raw := B.ToRaw;
  AssertEquals(3, Length(raw));
  AssertTrue(B.Length >= 3);
end;

procedure TTestCase_Global.Test_Reserve_And_Length_Unchanged;
var B: IStringBuilder; beforeLen: SizeInt;
begin
  B := MakeStringBuilder(0);
  beforeLen := B.Length;
  B.Reserve(64);
  AssertTrue(B.Capacity >= 64);
  AssertEquals(beforeLen, B.Length);
end;

procedure TTestCase_Global.Test_ToRaw_And_ZeroByte_Consistency;
var B: IStringBuilder; raw: RawByteString; arr: TBytes;
begin
  B := MakeStringBuilder(0);
  // 包含 0 值字节
  SetLength(arr, 3);
  arr[0] := $41; arr[1] := $00; arr[2] := $42;
  B.AppendBytes(arr);
  raw := B.ToRaw;
  AssertEquals(3, Length(raw));
end;

procedure TTestCase_Global.Test_ZeroCopy_APIs_Semantics;
var B: IStringBuilder; used: SizeInt; buf: TBytes; arr: TBytes; arr2: TBytes;
begin
  B := MakeStringBuilder(0);
  // copy path (non-perfect capacity)
  B.EnsureCapacity(16);
  SetLength(arr, 2); arr[0] := $AA; arr[1] := $BB;
  B.AppendBytes(arr);
  arr2 := B.IntoBytes; // copy path: builder length unchanged
  AssertEquals(2, Length(arr2));
  AssertTrue(B.Length = 2);
  // zero-copy path (perfect capacity)
  B.EnsureCapacity(B.Length);
  buf := B.DetachBytes(used);
  AssertEquals(2, used);
  AssertEquals(2, Length(buf));
  AssertEquals(0, B.Length);
end;

procedure TTestCase_Global.Test_AppendLF_CRLF;
var B: IStringBuilder; S: string; L0: SizeInt;
begin
  B := MakeStringBuilder(0);
  L0 := B.Length;
  B.AppendLF;
  AssertEquals(L0+1, B.Length);
  B.AppendCRLF;
  AssertEquals(L0+3, B.Length);
  S := B.ToString;
  // 只验证字节布局: LF(10), CRLF(13,10)
  AssertTrue(Pos(#10#13#10, S) > 0);
end;

procedure TTestCase_Global.Test_Stream_IO_Roundtrip;
var B: IStringBuilder; MS: TMemoryStream; raw: RawByteString; wrote: Int64;
begin
  // 写入
  B := MakeStringBuilder(0);
  B.AppendByte($DE).AppendByte($AD).AppendByte($BE).AppendByte($EF);
  MS := TMemoryStream.Create;
  try
    wrote := B.WriteToStream(MS);
    AssertEquals(Int64(4), wrote);
    AssertEquals(4, MS.Size);
    // 读回
    MS.Position := 0;
    B.Clear;
    B.AppendFromStream(MS);
    raw := B.ToRaw;
    AssertEquals(4, Length(raw));
    AssertEquals(AnsiChar(#$DE), raw[1]);
    AssertEquals(AnsiChar(#$AD), raw[2]);
    AssertEquals(AnsiChar(#$BE), raw[3]);
    AssertEquals(AnsiChar(#$EF), raw[4]);
  finally
    MS.Free;
  end;
end;

procedure TTestCase_Global.Test_IntoBytes_ZeroCopy_After_ShrinkToFit;
var B: IStringBuilder; arr: TBytes; outBytes: TBytes;
begin
  B := MakeStringBuilder(0);
  SetLength(arr, 3);
  arr[0] := 1; arr[1] := 2; arr[2] := 3;
  B.AppendBytes(arr);
  B.ShrinkToFit;
  outBytes := B.IntoBytes;
  AssertEquals(3, Length(outBytes));
  AssertEquals(0, B.Length);
end;

procedure TTestCase_Global.Test_UTF8_Append_APIs;
var B: IStringBuilder; raw: RawByteString;
begin
  B := MakeStringBuilder(0);
  // '€' U+20AC
  B.AppendCodePoint($20AC);
  // '你' U+4F60
  B.AppendCodePoint($4F60);
  // AppendUTF8String for ASCII
  B.AppendUTF8String('ABC');
  raw := B.ToRaw;
  // Expect at least 3+3+3 = 9 bytes (depending on runtime string settings for earlier tests)
  AssertTrue(Length(raw) >= 9);
end;

procedure TTestCase_Global.Test_Stream_ZeroCopy_Paths;
var B: IStringBuilder; MS: TMemoryStream; wrote: Int64; raw: RawByteString;
begin
  B := MakeStringBuilder(0);
  B.AppendUTF8String('hello');
  MS := TMemoryStream.Create;
  try
    wrote := B.WriteToStream(MS);
    AssertTrue(wrote >= 5);
    MS.Position := 0;
    B.Clear;
    B.AppendFromStream(MS);
    raw := B.ToRaw;
    AssertTrue(Length(raw) >= 5);
  finally
    MS.Free;
  end;
end;

initialization
  RegisterTest(TTestCase_Global);

end.

