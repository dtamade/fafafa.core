unit fafafa.core.io.std;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

{
  fafafa.core.io.std - 标准输入输出流

  提供：
  - Stdin: 标准输入 (IReader)
  - Stdout: 标准输出 (IWriter)
  - Stderr: 标准错误 (IWriter)

  实现：使用 fpRead/fpWrite 直接操作系统句柄，避免逻字节 IO。
  参考: Rust std::io (stdin/stdout/stderr)
}

interface

uses
  fafafa.core.io.base;

{ Stdin - 获取标准输入流

  返回实现 IReader 的标准输入。
  注意：此实现非线程安全。
}
function Stdin: IReader;

{ Stdout - 获取标准输出流

  返回实现 IWriter + IFlusher 的标准输出。
  默认行缓冲。
}
function Stdout: IWriter;

{ Stderr - 获取标准错误流

  返回实现 IWriter + IFlusher 的标准错误。
  默认无缓冲（立即输出）。
}
function Stderr: IWriter;

{ StdoutFlusher - 获取可刷新的标准输出 }
function StdoutFlusher: IFlusher;

{ StderrFlusher - 获取可刷新的标准错误 }
function StderrFlusher: IFlusher;

implementation

uses
  {$IFDEF UNIX}
  BaseUnix,
  {$ENDIF}
  {$IFDEF WINDOWS}
  Windows,
  {$ENDIF}
  SysUtils;

type
  { TStdinReader - 标准输入实现 }
  TStdinReader = class(TInterfacedObject, IReader)
  public
    function Read(Buf: Pointer; Count: SizeInt): SizeInt;
  end;

  { TStdoutWriter - 标准输出实现 }
  TStdoutWriter = class(TInterfacedObject, IWriter, IFlusher)
  public
    function Write(Buf: Pointer; Count: SizeInt): SizeInt;
    procedure Flush;
  end;

  { TStderrWriter - 标准错误实现 }
  TStderrWriter = class(TInterfacedObject, IWriter, IFlusher)
  public
    function Write(Buf: Pointer; Count: SizeInt): SizeInt;
    procedure Flush;
  end;

var
  GStdin: IReader = nil;
  GStdout: IWriter = nil;
  GStdoutFlusher: IFlusher = nil;
  GStderr: IWriter = nil;
  GStderrFlusher: IFlusher = nil;

{ TStdinReader }

function TStdinReader.Read(Buf: Pointer; Count: SizeInt): SizeInt;
{$IFDEF UNIX}
var
  LRead: TSSize;
  Err: LongInt;
{$ENDIF}
{$IFDEF WINDOWS}
var
  BytesRead: DWORD;
  Err: DWORD;
{$ENDIF}
begin
  Result := 0;
  if (Buf = nil) or (Count <= 0) then
    Exit;

  {$IFDEF UNIX}
  // 使用 fpRead 直接从标准输入句柄(0)读取
  LRead := fpRead(0, Buf, Count);
  if LRead < 0 then
  begin
    Err := fpgeterrno;
    raise EIOError.Create(IOUnixErrorKind(Err),
      'Stdin: read failed (errno=' + IntToStr(Err) + ')');
  end
  else
    Result := LRead;
  {$ELSE}
  // Windows: 使用 ReadFile
  {$IFDEF WINDOWS}
  if not ReadFile(GetStdHandle(STD_INPUT_HANDLE), Buf^, Count, BytesRead, nil) then
  begin
    Err := GetLastError;
    raise EIOError.Create(IOWinErrorKind(Err),
      'Stdin: read failed (GetLastError=' + IntToStr(Err) + ')');
  end;
  Result := BytesRead;
  {$ENDIF}
  {$ENDIF}
end;

{ TStdoutWriter }

function TStdoutWriter.Write(Buf: Pointer; Count: SizeInt): SizeInt;
{$IFDEF UNIX}
var
  LWritten: TSSize;
  Err: LongInt;
{$ENDIF}
{$IFDEF WINDOWS}
var
  BytesWritten: DWORD;
  Err: DWORD;
{$ENDIF}
begin
  Result := 0;
  if (Buf = nil) or (Count <= 0) then
    Exit;

  {$IFDEF UNIX}
  // 使用 fpWrite 直接写入标准输出句柄(1)
  LWritten := fpWrite(1, Buf, Count);
  if LWritten < 0 then
  begin
    Err := fpgeterrno;
    raise EIOError.Create(IOUnixErrorKind(Err),
      'Stdout: write failed (errno=' + IntToStr(Err) + ')');
  end
  else
    Result := LWritten;
  {$ELSE}
  {$IFDEF WINDOWS}
  if not WriteFile(GetStdHandle(STD_OUTPUT_HANDLE), Buf^, Count, BytesWritten, nil) then
  begin
    Err := GetLastError;
    raise EIOError.Create(IOWinErrorKind(Err),
      'Stdout: write failed (GetLastError=' + IntToStr(Err) + ')');
  end;
  Result := BytesWritten;
  {$ENDIF}
  {$ENDIF}
end;

procedure TStdoutWriter.Flush;
begin
  // Unix: 无缓冲写入无需 flush
  // Windows: 也无需额外 flush
end;

{ TStderrWriter }

function TStderrWriter.Write(Buf: Pointer; Count: SizeInt): SizeInt;
{$IFDEF UNIX}
var
  LWritten: TSSize;
  Err: LongInt;
{$ENDIF}
{$IFDEF WINDOWS}
var
  BytesWritten: DWORD;
  Err: DWORD;
{$ENDIF}
begin
  Result := 0;
  if (Buf = nil) or (Count <= 0) then
    Exit;

  {$IFDEF UNIX}
  // 使用 fpWrite 直接写入标准错误句柄(2)
  LWritten := fpWrite(2, Buf, Count);
  if LWritten < 0 then
  begin
    Err := fpgeterrno;
    raise EIOError.Create(IOUnixErrorKind(Err),
      'Stderr: write failed (errno=' + IntToStr(Err) + ')');
  end
  else
    Result := LWritten;
  {$ELSE}
  {$IFDEF WINDOWS}
  if not WriteFile(GetStdHandle(STD_ERROR_HANDLE), Buf^, Count, BytesWritten, nil) then
  begin
    Err := GetLastError;
    raise EIOError.Create(IOWinErrorKind(Err),
      'Stderr: write failed (GetLastError=' + IntToStr(Err) + ')');
  end;
  Result := BytesWritten;
  {$ENDIF}
  {$ENDIF}
end;

procedure TStderrWriter.Flush;
begin
  // 标准错误无缓冲，无需 flush
end;

{ 单例访问器 }

function Stdin: IReader;
begin
  if GStdin = nil then
    GStdin := TStdinReader.Create;
  Result := GStdin;
end;

function Stdout: IWriter;
var
  LWriter: TStdoutWriter;
begin
  if GStdout = nil then
  begin
    LWriter := TStdoutWriter.Create;
    GStdout := LWriter;
    GStdoutFlusher := LWriter;
  end;
  Result := GStdout;
end;

function Stderr: IWriter;
var
  LWriter: TStderrWriter;
begin
  if GStderr = nil then
  begin
    LWriter := TStderrWriter.Create;
    GStderr := LWriter;
    GStderrFlusher := LWriter;
  end;
  Result := GStderr;
end;

function StdoutFlusher: IFlusher;
begin
  if GStdoutFlusher = nil then
    Stdout;  // 初始化
  Result := GStdoutFlusher;
end;

function StderrFlusher: IFlusher;
begin
  if GStderrFlusher = nil then
    Stderr;  // 初始化
  Result := GStderrFlusher;
end;

end.
