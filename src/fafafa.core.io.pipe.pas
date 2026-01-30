unit fafafa.core.io.pipe;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

{
  fafafa.core.io.pipe - 进程内同步管道

  提供：
  - TPipe: 内存管道，连接 Reader 和 Writer
  - Pipe(): 创建基本管道
  - PipeCloser(): 创建可关闭的管道

  这是同步单线程管道，适用于流式数据传递。
  多线程场景需要额外的同步机制。

  参考: Go io.Pipe
}

interface

uses
  SysUtils,
  fafafa.core.io.base;

type
  { IPipeBuffer - 内部管道缓冲区接口 }
  IPipeBuffer = interface
    ['{1A2B3C4D-5E6F-7890-ABCD-EF0123456789}']
    function Write(Buf: Pointer; Count: SizeInt): SizeInt;
    function Read(Buf: Pointer; Count: SizeInt): SizeInt;
    procedure Close;
  end;

  { TPipeBuffer - 内部管道缓冲区实现
    Reader 和 Writer 共享此对象，通过接口引用计数管理生命周期
  }
  TPipeBuffer = class(TInterfacedObject, IPipeBuffer)
  private
    FData: TBytes;
    FReadPos: SizeInt;
    FClosed: Boolean;
  public
    constructor Create;
    function Write(Buf: Pointer; Count: SizeInt): SizeInt;
    function Read(Buf: Pointer; Count: SizeInt): SizeInt;
    procedure Close;
  end;

  { TPipeReader - 管道读取端 }
  TPipeReader = class(TInterfacedObject, IReader)
  private
    FBuffer: IPipeBuffer;
  public
    constructor Create(ABuffer: IPipeBuffer);
    function Read(Buf: Pointer; Count: SizeInt): SizeInt;
  end;

  { TPipeWriter - 管道写入端 }
  TPipeWriter = class(TInterfacedObject, IWriter, ICloser, IWriteCloser)
  private
    FBuffer: IPipeBuffer;
  public
    constructor Create(ABuffer: IPipeBuffer);

    { IWriter }
    function Write(Buf: Pointer; Count: SizeInt): SizeInt;

    { ICloser }
    procedure Close;
  end;

{ 工厂函数 }

{ 创建基本管道 }
procedure Pipe(out AReader: IReader; out AWriter: IWriter);

{ 创建可关闭的管道 }
procedure PipeCloser(out AReader: IReader; out AWriter: IWriteCloser);

implementation

{ TPipeBuffer }

constructor TPipeBuffer.Create;
begin
  inherited Create;
  SetLength(FData, 0);
  FReadPos := 0;
  FClosed := False;
end;

function TPipeBuffer.Write(Buf: Pointer; Count: SizeInt): SizeInt;
var
  OldLen: SizeInt;
begin
  Result := 0;
  if FClosed then
    raise EIOError.Create(ekBrokenPipe, 'Pipe closed');

  if (Buf = nil) or (Count <= 0) then
    Exit;

  // 追加数据到缓冲区
  OldLen := Length(FData);
  SetLength(FData, OldLen + Count);
  Move(Buf^, FData[OldLen], Count);
  Result := Count;
end;

function TPipeBuffer.Read(Buf: Pointer; Count: SizeInt): SizeInt;
var
  Avail: SizeInt;
begin
  Result := 0;
  if (Buf = nil) or (Count <= 0) then
    Exit;

  Avail := Length(FData) - FReadPos;
  if Avail <= 0 then
  begin
    // 缓冲区为空
    // 如果已关闭，返回 EOF (0)
    // 如果未关闭，也返回 0（同步管道无阻塞）
    Exit;
  end;

  if Count > Avail then
    Count := Avail;

  Move(FData[FReadPos], Buf^, Count);
  Inc(FReadPos, Count);

  // 如果全部读取完毕，重置缓冲区以节省内存
  if FReadPos >= Length(FData) then
  begin
    SetLength(FData, 0);
    FReadPos := 0;
  end;

  Result := Count;
end;

procedure TPipeBuffer.Close;
begin
  FClosed := True;
end;

{ TPipeReader }

constructor TPipeReader.Create(ABuffer: IPipeBuffer);
begin
  inherited Create;
  if ABuffer = nil then
    raise EIOError.Create('TPipeReader: buffer is nil');
  FBuffer := ABuffer;
end;

function TPipeReader.Read(Buf: Pointer; Count: SizeInt): SizeInt;
begin
  Result := FBuffer.Read(Buf, Count);
end;

{ TPipeWriter }

constructor TPipeWriter.Create(ABuffer: IPipeBuffer);
begin
  inherited Create;
  if ABuffer = nil then
    raise EIOError.Create('TPipeWriter: buffer is nil');
  FBuffer := ABuffer;
end;

function TPipeWriter.Write(Buf: Pointer; Count: SizeInt): SizeInt;
begin
  Result := FBuffer.Write(Buf, Count);
end;

procedure TPipeWriter.Close;
begin
  if FBuffer <> nil then
    FBuffer.Close;
end;

{ 工厂函数 }

procedure Pipe(out AReader: IReader; out AWriter: IWriter);
var
  Buffer: IPipeBuffer;
begin
  Buffer := TPipeBuffer.Create;
  AWriter := TPipeWriter.Create(Buffer);
  AReader := TPipeReader.Create(Buffer);
end;

procedure PipeCloser(out AReader: IReader; out AWriter: IWriteCloser);
var
  Buffer: IPipeBuffer;
begin
  Buffer := TPipeBuffer.Create;
  AWriter := TPipeWriter.Create(Buffer);
  AReader := TPipeReader.Create(Buffer);
end;

end.
