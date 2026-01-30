unit fafafa.core.io.tee;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

{
  fafafa.core.io.tee - Tee 和广播流

  提供：
  - TTeeReader: 读取时同时写入另一个流
  - TMultiWriter: 写入时同时写入多个流（广播）

  参考: Go io.TeeReader, io.MultiWriter
}

interface

uses
  SysUtils,
  fafafa.core.io.base,
  fafafa.core.io.utils;

type
  { TTeeReader - 读取时同时写入

    从 Inner 读取数据时，同时写入到 Writer。
    适用于读取时需要保留副本的场景。

    用法：
      Tee := TeeReader(Src, Copy);
      while Tee.Read(@Buf, N) > 0 do
        // 处理数据，同时 Copy 也收到相同数据
  }
  TTeeReader = class(TInterfacedObject, IReader)
  private
    FInner: IReader;
    FWriter: IWriter;
  public
    constructor Create(AInner: IReader; AWriter: IWriter);

    { IReader }
    function Read(Buf: Pointer; Count: SizeInt): SizeInt;
  end;

  { TMultiWriter - 广播写入

    写入数据时同时写入所有 Writers。
    如果某个 Writer 写入失败（返回值小于 Count），立即返回该值。

    用法：
      MW := MultiWriter([File, Console, Log]);
      MW.Write(@Data, N);  // 同时写入三个目标
  }
  TMultiWriter = class(TInterfacedObject, IWriter)
  private
    FWriters: array of IWriter;
  public
    constructor Create(const AWriters: array of IWriter);

    { IWriter }
    function Write(Buf: Pointer; Count: SizeInt): SizeInt;
  end;

{ 工厂函数 }
function TeeReader(AInner: IReader; AWriter: IWriter): IReader;
function MultiWriter(const AWriters: array of IWriter): IWriter;

implementation

{ TTeeReader }

constructor TTeeReader.Create(AInner: IReader; AWriter: IWriter);
begin
  inherited Create;
  if AInner = nil then
    raise EIOError.Create('TTeeReader: inner reader is nil');
  if AWriter = nil then
    raise EIOError.Create('TTeeReader: writer is nil');
  FInner := AInner;
  FWriter := AWriter;
end;

function TTeeReader.Read(Buf: Pointer; Count: SizeInt): SizeInt;
var
  Written: SizeInt;
begin
  Result := 0;
  if (Buf = nil) or (Count <= 0) then
    Exit;

  // 从内部读取器读取
  Result := FInner.Read(Buf, Count);
  if Result > 0 then
  begin
    // 将读取的数据写入 Writer，要求全写成功
    Written := WriteAll(FWriter, Buf, Result);
    if Written <> Result then
      raise EIOError.Create('TTeeReader: internal error (short write)');
  end;
end;

{ TMultiWriter }

constructor TMultiWriter.Create(const AWriters: array of IWriter);
var
  I: Integer;
begin
  inherited Create;
  SetLength(FWriters, Length(AWriters));
  for I := 0 to High(AWriters) do
    FWriters[I] := AWriters[I];
end;

function TMultiWriter.Write(Buf: Pointer; Count: SizeInt): SizeInt;
var
  I: Integer;
  N: SizeInt;
begin
  Result := Count;
  if (Buf = nil) or (Count <= 0) then
    Exit;

  for I := 0 to High(FWriters) do
  begin
    if FWriters[I] <> nil then
    begin
      N := WriteAll(FWriters[I], Buf, Count);
      if N <> Count then
        raise EIOError.Create('TMultiWriter: internal error (short write) on target index ' + IntToStr(I));
    end;
  end;
end;

{ 工厂函数 }

function TeeReader(AInner: IReader; AWriter: IWriter): IReader;
begin
  Result := TTeeReader.Create(AInner, AWriter);
end;

function MultiWriter(const AWriters: array of IWriter): IWriter;
begin
  Result := TMultiWriter.Create(AWriters);
end;

end.
