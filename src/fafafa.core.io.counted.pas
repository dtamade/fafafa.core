unit fafafa.core.io.counted;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

{
  fafafa.core.io.counted - 字节计数包装器

  提供：
  - TCountedReader: 包装 IReader，统计读取字节数
  - TCountedWriter: 包装 IWriter，统计写入字节数

  适用于进度报告、带宽统计等场景。
}

interface

uses
  SysUtils,
  fafafa.core.io.base;

type
  { TCountedReader - 统计读取字节数

    用法：
      CR := TCountedReader.Create(Inner);
      try
        while CR.Read(...) > 0 do
          WriteLn('已读取: ', CR.BytesRead);
      finally
        CR.Free;
      end;
  }
  TCountedReader = class(TInterfacedObject, IReader)
  private
    FInner: IReader;
    FBytesRead: Int64;
  public
    constructor Create(AInner: IReader);

    { IReader }
    function Read(Buf: Pointer; Count: SizeInt): SizeInt;

    { 统计 }
    property BytesRead: Int64 read FBytesRead;
    procedure ResetCount;
  end;

  { TCountedWriter - 统计写入字节数

    用法：
      CW := TCountedWriter.Create(Inner);
      try
        CW.Write(...);
        WriteLn('已写入: ', CW.BytesWritten);
      finally
        CW.Free;
      end;
  }
  TCountedWriter = class(TInterfacedObject, IWriter)
  private
    FInner: IWriter;
    FBytesWritten: Int64;
  public
    constructor Create(AInner: IWriter);

    { IWriter }
    function Write(Buf: Pointer; Count: SizeInt): SizeInt;

    { 统计 }
    property BytesWritten: Int64 read FBytesWritten;
    procedure ResetCount;
  end;

{ 工厂函数 }
function CountedReader(AInner: IReader): TCountedReader;
function CountedWriter(AInner: IWriter): TCountedWriter;

implementation

{ TCountedReader }

constructor TCountedReader.Create(AInner: IReader);
begin
  inherited Create;
  if AInner = nil then
    raise EIOError.Create('TCountedReader: inner reader is nil');
  FInner := AInner;
  FBytesRead := 0;
end;

function TCountedReader.Read(Buf: Pointer; Count: SizeInt): SizeInt;
begin
  Result := FInner.Read(Buf, Count);
  if Result > 0 then
    Inc(FBytesRead, Result);
end;

procedure TCountedReader.ResetCount;
begin
  FBytesRead := 0;
end;

{ TCountedWriter }

constructor TCountedWriter.Create(AInner: IWriter);
begin
  inherited Create;
  if AInner = nil then
    raise EIOError.Create('TCountedWriter: inner writer is nil');
  FInner := AInner;
  FBytesWritten := 0;
end;

function TCountedWriter.Write(Buf: Pointer; Count: SizeInt): SizeInt;
begin
  Result := FInner.Write(Buf, Count);
  if Result > 0 then
    Inc(FBytesWritten, Result);
end;

procedure TCountedWriter.ResetCount;
begin
  FBytesWritten := 0;
end;

{ 工厂函数 }

function CountedReader(AInner: IReader): TCountedReader;
begin
  Result := TCountedReader.Create(AInner);
end;

function CountedWriter(AInner: IWriter): TCountedWriter;
begin
  Result := TCountedWriter.Create(AInner);
end;

end.
