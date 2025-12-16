unit fafafa.core.io.utils;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

{
  fafafa.core.io.utils - IO 工具函数

  提供：
  - Copy / CopyN / CopyBuffer: 数据复制
  - ReadAll / ReadAtLeast / ReadFull: 完整读取
  - WriteAll / WriteString: 完整写入

  参考: Rust std::io / Go io 包
}

interface

uses
  SysUtils,
  fafafa.core.io.base;

const
  { 默认复制缓冲区大小: 32KB }
  DefaultCopyBufSize = 32 * 1024;

{ Copy - 从 Reader 复制到 Writer 直到 EOF

  返回复制的总字节数。
  使用默认 32KB 缓冲区。
}
function Copy(Dst: IWriter; Src: IReader): Int64;

{ CopyN - 复制恰好 N 字节

  如果 Src 不足 N 字节，抛出 EUnexpectedEOF。
  返回 N。
}
function CopyN(Dst: IWriter; Src: IReader; N: Int64): Int64;

{ CopyBuffer - 使用指定缓冲区复制

  返回复制的总字节数。
}
function CopyBuffer(Dst: IWriter; Src: IReader; BufSize: SizeInt): Int64;

{ ReadAll - 读取所有数据直到 EOF

  返回读取的所有字节。
  注意：大文件可能消耗大量内存。
}
function ReadAll(Src: IReader): TBytes;

{ ReadAtLeast - 至少读取 Min 字节

  读取至少 Min 字节到 Buf。
  如果在读取 Min 字节前遇到 EOF，抛出 EUnexpectedEOF。
  返回实际读取的字节数（>= Min）。
}
function ReadAtLeast(Src: IReader; Buf: Pointer; BufSize: SizeInt; Min: SizeInt): SizeInt;

{ ReadFull - 完整填充缓冲区

  读取恰好 Count 字节到 Buf。
  如果在填满前遇到 EOF，抛出 EUnexpectedEOF。
  返回 Count。
}
function ReadFull(Src: IReader; Buf: Pointer; Count: SizeInt): SizeInt;

{ WriteAll - 写入所有数据

  确保所有数据都写入。
  如果无法写入全部数据，抛出 EIOError。
  返回写入的字节数。
}
function WriteAll(Dst: IWriter; Buf: Pointer; Count: SizeInt): SizeInt;

{ WriteString - 写入字符串

  将字符串作为 UTF-8 字节写入。
  返回写入的字节数。
}
function WriteString(Dst: IWriter; const S: string): SizeInt;

{ WriteBytes - 写入字节数组

  返回写入的字节数。
}
function WriteBytes(Dst: IWriter; const Data: TBytes): SizeInt;

{ ReadString - 读取所有数据并转为字符串

  将所有字节作为 UTF-8 解码为字符串。
  返回解码后的字符串。
}
function ReadString(Src: IReader): string;

{ ReadVFallback - 向量化读取的回退实现

  使用普通 Read 调用逐个填充多个缓冲区。
  适用于底层不支持 IReaderVectored 的情况。
  返回实际读取的总字节数，0 表示 EOF。
}
function ReadVFallback(Src: IReader; const IOV: TIOVecArray): SizeInt;

{ WriteVFallback - 向量化写入的回退实现

  使用普通 Write 调用逐个写入多个缓冲区。
  适用于底层不支持 IWriterVectored 的情况。
  返回实际写入的总字节数。
}
function WriteVFallback(Dst: IWriter; const IOV: TIOVecArray): SizeInt;

implementation

function Copy(Dst: IWriter; Src: IReader): Int64;
begin
  Result := CopyBuffer(Dst, Src, DefaultCopyBufSize);
end;

function CopyN(Dst: IWriter; Src: IReader; N: Int64): Int64;
var
  LBuf: array[0..DefaultCopyBufSize - 1] of Byte;
  LToRead, LRead, LWritten: SizeInt;
  LRemaining: Int64;
begin
  Result := 0;
  if N <= 0 then
    Exit;

  LRemaining := N;
  while LRemaining > 0 do
  begin
    if LRemaining > DefaultCopyBufSize then
      LToRead := DefaultCopyBufSize
    else
      LToRead := LRemaining;

    LRead := Src.Read(@LBuf[0], LToRead);
    if LRead = 0 then
      raise EUnexpectedEOF.Create('CopyN: unexpected EOF');

    LWritten := WriteAll(Dst, @LBuf[0], LRead);
    Inc(Result, LWritten);
    Dec(LRemaining, LRead);
  end;
end;

function CopyBuffer(Dst: IWriter; Src: IReader; BufSize: SizeInt): Int64;
var
  LBuf: TBytes;
  LRead, LWritten: SizeInt;
begin
  Result := 0;
  if BufSize <= 0 then
    BufSize := DefaultCopyBufSize;

  SetLength(LBuf, BufSize);

  while True do
  begin
    LRead := Src.Read(@LBuf[0], BufSize);
    if LRead = 0 then
      Break;  // EOF

    LWritten := WriteAll(Dst, @LBuf[0], LRead);
    Inc(Result, LWritten);
  end;
end;

function ReadAll(Src: IReader): TBytes;
const
  InitialSize = 512;
  GrowFactor = 2;
var
  LBuf: TBytes;
  LPos, LRead, LCap: SizeInt;
begin
  SetLength(LBuf, InitialSize);
  LPos := 0;
  LCap := InitialSize;

  while True do
  begin
    // 扩展缓冲区
    if LPos >= LCap then
    begin
      LCap := LCap * GrowFactor;
      SetLength(LBuf, LCap);
    end;

    try
      LRead := Src.Read(@LBuf[LPos], LCap - LPos);
    except
      on E: EIOError do
      begin
        if E.Kind = ekInterrupted then
          Continue;
        raise;
      end;
    end;
    if LRead = 0 then
      Break;  // EOF

    Inc(LPos, LRead);
  end;

  // 裁剪到实际大小
  SetLength(LBuf, LPos);
  Result := LBuf;
end;

function ReadAtLeast(Src: IReader; Buf: Pointer; BufSize: SizeInt; Min: SizeInt): SizeInt;
var
  LRead: SizeInt;
  LPtr: PByte;
begin
  if Min > BufSize then
    raise EIOError.Create('ReadAtLeast: min > buffer size');
  if Min < 0 then
    Min := 0;

  Result := 0;
  LPtr := PByte(Buf);

  while Result < Min do
  begin
    try
      LRead := Src.Read(LPtr, BufSize - Result);
    except
      on E: EIOError do
      begin
        if E.Kind = ekInterrupted then
          Continue;
        raise;
      end;
    end;
    if LRead = 0 then
      raise EUnexpectedEOF.Create('ReadAtLeast: unexpected EOF');

    Inc(Result, LRead);
    Inc(LPtr, LRead);
  end;

  // 继续读取直到缓冲区满或 EOF
  while Result < BufSize do
  begin
    try
      LRead := Src.Read(LPtr, BufSize - Result);
    except
      on E: EIOError do
      begin
        if E.Kind = ekInterrupted then
          Continue;
        raise;
      end;
    end;
    if LRead = 0 then
      Break;

    Inc(Result, LRead);
    Inc(LPtr, LRead);
  end;
end;

function ReadFull(Src: IReader; Buf: Pointer; Count: SizeInt): SizeInt;
var
  LRead: SizeInt;
  LPtr: PByte;
  LRemaining: SizeInt;
begin
  Result := 0;
  if Count <= 0 then
    Exit;

  LPtr := PByte(Buf);
  LRemaining := Count;

  while LRemaining > 0 do
  begin
    try
      LRead := Src.Read(LPtr, LRemaining);
    except
      on E: EIOError do
      begin
        if E.Kind = ekInterrupted then
          Continue;
        raise;
      end;
    end;
    if LRead = 0 then
      raise EUnexpectedEOF.Create('ReadFull: unexpected EOF');

    Inc(Result, LRead);
    Inc(LPtr, LRead);
    Dec(LRemaining, LRead);
  end;
end;

function WriteAll(Dst: IWriter; Buf: Pointer; Count: SizeInt): SizeInt;
var
  LWritten: SizeInt;
  LPtr: PByte;
  LRemaining: SizeInt;
begin
  Result := 0;
  if Count <= 0 then
    Exit;

  LPtr := PByte(Buf);
  LRemaining := Count;

  while LRemaining > 0 do
  begin
    try
      LWritten := Dst.Write(LPtr, LRemaining);
    except
      on E: EIOError do
      begin
        if E.Kind = ekInterrupted then
          Continue;
        raise;
      end;
    end;
    if LWritten = 0 then
      raise EIOError.Create(ekWriteZero, 'WriteAll: write returned 0');

    Inc(Result, LWritten);
    Inc(LPtr, LWritten);
    Dec(LRemaining, LWritten);
  end;
end;

function WriteString(Dst: IWriter; const S: string): SizeInt;
var
  LBytes: TBytes;
  LStr: UTF8String;
begin
  if S = '' then
  begin
    Result := 0;
    Exit;
  end;

  // 直接转换为 UTF8String 避免隐式转换警告
  LStr := UTF8String(S);
  SetLength(LBytes, Length(LStr));
  if Length(LStr) > 0 then
    Move(LStr[1], LBytes[0], Length(LStr));
  Result := WriteAll(Dst, @LBytes[0], Length(LBytes));
end;

function WriteBytes(Dst: IWriter; const Data: TBytes): SizeInt;
begin
  if Length(Data) = 0 then
  begin
    Result := 0;
    Exit;
  end;

  Result := WriteAll(Dst, @Data[0], Length(Data));
end;

function ReadString(Src: IReader): string;
var
  LBytes: TBytes;
begin
  LBytes := ReadAll(Src);
  if Length(LBytes) = 0 then
  begin
    Result := '';
    Exit;
  end;
  // 转换为 UTF-8 字符串
  SetLength(Result, Length(LBytes));
  SetCodePage(RawByteString(Result), CP_UTF8, False);
  Move(LBytes[0], Result[1], Length(LBytes));
end;

function ReadVFallback(Src: IReader; const IOV: TIOVecArray): SizeInt;
var
  I: Integer;
  N: SizeInt;
begin
  Result := 0;
  for I := 0 to High(IOV) do
  begin
    if (IOV[I].Base = nil) or (IOV[I].Len <= 0) then
      Continue;

    N := Src.Read(IOV[I].Base, IOV[I].Len);
    Inc(Result, N);

    // 如果未完全填充，停止（可能 EOF 或短读）
    if N < IOV[I].Len then
      Break;
  end;
end;

function WriteVFallback(Dst: IWriter; const IOV: TIOVecArray): SizeInt;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to High(IOV) do
  begin
    if (IOV[I].Base = nil) or (IOV[I].Len <= 0) then
      Continue;

    Inc(Result, WriteAll(Dst, IOV[I].Base, IOV[I].Len));
  end;
end;

end.
