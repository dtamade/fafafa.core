unit fafafa.core.io.peek;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

{
  fafafa.core.io.peek - 窥视读取器

  提供 Peek 功能，允许预读数据而不消费（不移动读取位置）。

  用法:
    var PR: IPeekReader; Buf: array[0..3] of Byte;
    begin
      PR := IO.Peekable(SomeReader);
      PR.Peek(@Buf[0], 4);   // 预读 4 字节，不消费
      PR.Read(@Buf[0], 4);   // 读取相同的 4 字节，消费
    end;
}

interface

uses
  SysUtils,
  fafafa.core.io.base;

type
  { IPeekReader - 支持窥视的读取器接口 }
  IPeekReader = interface(IReader)
    ['{8E6C5A3D-2B1F-4C9E-A7D8-3F5E6B9C4D2A}']
    { 预读数据但不消费（不移动读取位置）}
    function Peek(Buf: Pointer; Count: SizeInt): SizeInt;
  end;

  { TPeekReader - 带内部缓冲区的窥视读取器 }
  TPeekReader = class(TInterfacedObject, IReader, IPeekReader)
  private
    FInner: IReader;
    FBuffer: TBytes;
    FBufStart: SizeInt;  // 缓冲区中有效数据的起始位置
    FBufLen: SizeInt;    // 缓冲区中有效数据的长度
  public
    constructor Create(AInner: IReader);
    function Read(Buf: Pointer; Count: SizeInt): SizeInt;
    function Peek(Buf: Pointer; Count: SizeInt): SizeInt;
  end;

{ 工厂函数 }
function PeekReader(AInner: IReader): IPeekReader;

implementation

const
  DefaultPeekBufSize = 4096;

{ TPeekReader }

constructor TPeekReader.Create(AInner: IReader);
begin
  inherited Create;
  FInner := AInner;
  SetLength(FBuffer, DefaultPeekBufSize);
  FBufStart := 0;
  FBufLen := 0;
end;

function TPeekReader.Read(Buf: Pointer; Count: SizeInt): SizeInt;
var
  FromBuf, FromInner: SizeInt;
begin
  Result := 0;
  if Count <= 0 then
    Exit;

  // 先从缓冲区读取
  if FBufLen > 0 then
  begin
    FromBuf := FBufLen;
    if FromBuf > Count then
      FromBuf := Count;
    Move(FBuffer[FBufStart], Buf^, FromBuf);
    Inc(FBufStart, FromBuf);
    Dec(FBufLen, FromBuf);
    Inc(Result, FromBuf);
    Dec(Count, FromBuf);
    Buf := Buf + FromBuf;
    
    // 如果缓冲区已空，重置指针
    if FBufLen = 0 then
      FBufStart := 0;
  end;

  // 如果还需要更多数据，直接从内部读取器读
  if Count > 0 then
  begin
    FromInner := FInner.Read(Buf, Count);
    Inc(Result, FromInner);
  end;
end;

function TPeekReader.Peek(Buf: Pointer; Count: SizeInt): SizeInt;
var
  Need, Got: SizeInt;
begin
  Result := 0;
  if Count <= 0 then
    Exit;

  // 如果缓冲区数据不够，需要从内部读取更多
  if FBufLen < Count then
  begin
    // 如果缓冲区太小，扩展它
    if Length(FBuffer) < FBufStart + FBufLen + (Count - FBufLen) then
    begin
      // 移动数据到缓冲区开头
      if FBufStart > 0 then
      begin
        Move(FBuffer[FBufStart], FBuffer[0], FBufLen);
        FBufStart := 0;
      end;
      // 如果还不够，扩展缓冲区
      if Length(FBuffer) < Count then
        SetLength(FBuffer, Count);
    end;

    // 读取更多数据到缓冲区
    Need := Count - FBufLen;
    Got := FInner.Read(@FBuffer[FBufStart + FBufLen], Need);
    Inc(FBufLen, Got);
  end;

  // 返回缓冲区中可用的数据量
  Result := FBufLen;
  if Result > Count then
    Result := Count;

  if Result > 0 then
    Move(FBuffer[FBufStart], Buf^, Result);
end;

{ 工厂函数 }

function PeekReader(AInner: IReader): IPeekReader;
begin
  Result := TPeekReader.Create(AInner);
end;

end.
