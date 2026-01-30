unit fafafa.core.fs.bufio;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

{!
  fafafa.core.fs.bufio - 缓冲读写器

  对标 Rust std::io::BufReader/BufWriter，提供：
  - TFsBufReader: 带缓冲的读取器，包装 TFile
  - TFsBufWriter: 带缓冲的写入器，包装 TFile

  设计原则：
  - 复用 TFile 层，不重复实现底层 I/O
  - 缓冲区提升小块读写性能
  - 提供逐行读取等便捷方法

  用法示例：
    var
      F: TFile;
      Reader: TFsBufReader;
      Line: string;
    begin
      F := TFile.Open('data.txt');
      Reader := TFsBufReader.Create(F);
      try
        while Reader.ReadLine(Line) do
          WriteLn(Line);
      finally
        Reader.Free;
        F.Free;
      end;
    end;

    var
      F: TFile;
      Writer: TFsBufWriter;
    begin
      F := TFile.Create_('output.txt');
      Writer := TFsBufWriter.Create(F);
      try
        Writer.WriteString('Line 1');
        Writer.WriteLn;
        Writer.WriteString('Line 2');
        Writer.Flush;  // 确保写入磁盘
      finally
        Writer.Free;
        F.Free;
      end;
    end;
}

interface

uses
  SysUtils,
  fafafa.core.fs.traits,
  fafafa.core.fs.fileobj;

const
  DEFAULT_BUF_SIZE = 8192;  // 8KB 默认缓冲区大小

type
  // 逐行回调类型
  TFsLineCallback = procedure(const ALine: string);
  TFsLineCallbackMethod = procedure(const ALine: string) of object;

  // ============================================================================
  // TFsBufReader - 缓冲读取器
  // ============================================================================
  // 对标 Rust std::io::BufReader
  // 注意：手动管理生命周期，不使用接口引用计数自动释放
  TFsBufReader = class(TInterfacedObject, IFsRead, IFsBufRead)
  private
    FFile: TFile;           // 底层文件对象
    FOwnsFile: Boolean;     // 是否拥有文件对象
    FBuffer: TBytes;
    FBufPos: Integer;       // 当前读取位置
    FBufLen: Integer;       // 缓冲区有效数据长度
    FEof: Boolean;

    function FillBuffer: Boolean;
  protected
    // 禁用引用计数自动释放
    function _AddRef: LongInt; {$IFNDEF WINDOWS}cdecl{$ELSE}stdcall{$ENDIF};
    function _Release: LongInt; {$IFNDEF WINDOWS}cdecl{$ELSE}stdcall{$ENDIF};
  public
    constructor Create(AFile: TFile; ABufSize: Integer = DEFAULT_BUF_SIZE; AOwnsFile: Boolean = False);
    destructor Destroy; override;

    // IFsRead 接口方法
    function Read(var ABuffer; ACount: Integer): Integer;
    function ReadBytes(ACount: Integer): TBytes;
    function ReadAll: TBytes;
    function ReadString: string;

    // IFsBufRead 扩展方法
    function ReadByte: Integer;  // 返回 -1 表示 EOF
    function ReadLine(out ALine: string): Boolean;
    function BufferedBytes: Integer;  // 缓冲区中未读取的字节数
    function IsEof: Boolean;

    // 其他方法
    function ReadAllText: string;  // 读取全部内容为字符串
    function BufferSize: Integer;

    // 底层文件访问
    property InnerFile: TFile read FFile;
  end;

  // ============================================================================
  // TFsBufWriter - 缓冲写入器
  // ============================================================================
  // 对标 Rust std::io::BufWriter
  // 注意：手动管理生命周期，不使用接口引用计数自动释放
  TFsBufWriter = class(TInterfacedObject, IFsWrite)
  private
    FFile: TFile;           // 底层文件对象
    FOwnsFile: Boolean;     // 是否拥有文件对象
    FBuffer: TBytes;
    FBufPos: Integer;       // 当前写入位置

    procedure FlushBuffer;
  protected
    // 禁用引用计数自动释放
    function _AddRef: LongInt; {$IFNDEF WINDOWS}cdecl{$ELSE}stdcall{$ENDIF};
    function _Release: LongInt; {$IFNDEF WINDOWS}cdecl{$ELSE}stdcall{$ENDIF};
  public
    constructor Create(AFile: TFile; ABufSize: Integer = DEFAULT_BUF_SIZE; AOwnsFile: Boolean = False);
    destructor Destroy; override;

    // IFsWrite 接口方法
    function Write(const ABuffer; ACount: Integer): Integer;
    function WriteBytes(const AData: TBytes): Integer;
    function WriteString(const AStr: string): Integer;
    procedure Flush;

    // 扩展方法
    procedure WriteByte(AByte: Byte);
    procedure WriteLn(const AStr: string = '');

    // 缓冲区信息
    function BufferSize: Integer;
    function BufferedBytes: Integer;  // 缓冲区中待写入的字节数

    // 底层文件访问
    property InnerFile: TFile read FFile;
  end;

// ============================================================================
// 便捷函数
// ============================================================================

// 创建缓冲读取器并打开文件（自动管理文件生命周期）
function FsBufReader(const APath: string; ABufSize: Integer = DEFAULT_BUF_SIZE): TFsBufReader;

// 创建缓冲写入器并打开文件（自动管理文件生命周期）
function FsBufWriter(const APath: string; ABufSize: Integer = DEFAULT_BUF_SIZE): TFsBufWriter;

// 逐行读取文件（回调方式）
procedure FsForEachLine(const APath: string; ACallback: TFsLineCallback);

implementation

// ============================================================================
// TFsBufReader
// ============================================================================

function TFsBufReader._AddRef: LongInt; {$IFNDEF WINDOWS}cdecl{$ELSE}stdcall{$ENDIF};
begin
  Result := -1;  // 禁用引用计数
end;

function TFsBufReader._Release: LongInt; {$IFNDEF WINDOWS}cdecl{$ELSE}stdcall{$ENDIF};
begin
  Result := -1;  // 不自动释放
end;

constructor TFsBufReader.Create(AFile: TFile; ABufSize: Integer; AOwnsFile: Boolean);
begin
  inherited Create;
  FFile := AFile;
  FOwnsFile := AOwnsFile;
  SetLength(FBuffer, ABufSize);
  FBufPos := 0;
  FBufLen := 0;
  FEof := False;
end;

destructor TFsBufReader.Destroy;
begin
  if FOwnsFile and Assigned(FFile) then
    FFile.Free;
  inherited Destroy;
end;

function TFsBufReader.FillBuffer: Boolean;
var
  N: Integer;
begin
  if FEof then
    Exit(False);

  // 调用底层 TFile.Read
  N := FFile.Read(FBuffer[0], Length(FBuffer));
  if N <= 0 then
  begin
    FEof := True;
    FBufPos := 0;
    FBufLen := 0;
    Result := False;
  end
  else
  begin
    FBufPos := 0;
    FBufLen := N;
    Result := True;
  end;
end;

function TFsBufReader.Read(var ABuffer; ACount: Integer): Integer;
var
  Dest: PByte;
  Remaining, ToCopy: Integer;
begin
  Result := 0;
  Dest := @ABuffer;
  Remaining := ACount;

  while Remaining > 0 do
  begin
    // 缓冲区空了，需要填充
    if FBufPos >= FBufLen then
    begin
      if not FillBuffer then
        Break;
    end;

    // 从缓冲区复制数据
    ToCopy := FBufLen - FBufPos;
    if ToCopy > Remaining then
      ToCopy := Remaining;

    Move(FBuffer[FBufPos], Dest^, ToCopy);
    Inc(FBufPos, ToCopy);
    Inc(Dest, ToCopy);
    Inc(Result, ToCopy);
    Dec(Remaining, ToCopy);
  end;
end;

function TFsBufReader.ReadByte: Integer;
begin
  if FBufPos >= FBufLen then
  begin
    if not FillBuffer then
      Exit(-1);
  end;

  Result := FBuffer[FBufPos];
  Inc(FBufPos);
end;

function TFsBufReader.ReadBytes(ACount: Integer): TBytes;
var
  N: Integer;
begin
  SetLength(Result, ACount);
  if ACount = 0 then
    Exit;

  N := Read(Result[0], ACount);
  if N < ACount then
    SetLength(Result, N);
end;

function TFsBufReader.ReadLine(out ALine: string): Boolean;
var
  Builder: TStringBuilder;
  B: Integer;
  C: AnsiChar;
begin
  ALine := '';

  // 检查是否已到文件末尾
  if FEof and (FBufPos >= FBufLen) then
    Exit(False);

  Builder := TStringBuilder.Create;
  try
    while True do
    begin
      B := ReadByte;
      if B < 0 then
      begin
        // EOF
        if Builder.Length > 0 then
        begin
          ALine := Builder.ToString;
          Result := True;
        end
        else
          Result := False;
        Exit;
      end;

      C := AnsiChar(B);
      if C = #10 then  // LF
      begin
        ALine := Builder.ToString;
        Exit(True);
      end
      else if C = #13 then  // CR
      begin
        // 检查是否是 CRLF
        B := ReadByte;
        if (B >= 0) and (AnsiChar(B) <> #10) then
        begin
          // 不是 CRLF，回退一个字节
          Dec(FBufPos);
        end;
        ALine := Builder.ToString;
        Exit(True);
      end
      else
        Builder.Append(C);
    end;
  finally
    Builder.Free;
  end;
end;

function TFsBufReader.ReadAll: TBytes;
var
  Chunks: array of TBytes;
  ChunkCount, TotalLen, I, Offset: Integer;
  Chunk: TBytes;
begin
  ChunkCount := 0;
  TotalLen := 0;
  SetLength(Chunks, 0);

  // 读取所有数据块
  repeat
    SetLength(Chunk, 8192);
    I := Read(Chunk[0], 8192);
    if I > 0 then
    begin
      SetLength(Chunk, I);
      Inc(ChunkCount);
      SetLength(Chunks, ChunkCount);
      Chunks[ChunkCount - 1] := Chunk;
      Inc(TotalLen, I);
    end;
  until I <= 0;

  // 合并所有块
  SetLength(Result, TotalLen);
  Offset := 0;
  for I := 0 to ChunkCount - 1 do
  begin
    Move(Chunks[I][0], Result[Offset], Length(Chunks[I]));
    Inc(Offset, Length(Chunks[I]));
  end;
end;

function TFsBufReader.ReadString: string;
var
  Data: TBytes;
begin
  Data := ReadAll;
  if Length(Data) = 0 then
    Result := ''
  else
    SetString(Result, PAnsiChar(@Data[0]), Length(Data));
end;

function TFsBufReader.ReadAllText: string;
var
  Builder: TStringBuilder;
  Line: string;
begin
  Builder := TStringBuilder.Create;
  try
    while ReadLine(Line) do
    begin
      if Builder.Length > 0 then
        Builder.AppendLine;
      Builder.Append(Line);
    end;
    Result := Builder.ToString;
  finally
    Builder.Free;
  end;
end;

function TFsBufReader.BufferSize: Integer;
begin
  Result := Length(FBuffer);
end;

function TFsBufReader.BufferedBytes: Integer;
begin
  Result := FBufLen - FBufPos;
end;

function TFsBufReader.IsEof: Boolean;
begin
  Result := FEof and (FBufPos >= FBufLen);
end;

// ============================================================================
// TFsBufWriter
// ============================================================================

function TFsBufWriter._AddRef: LongInt; {$IFNDEF WINDOWS}cdecl{$ELSE}stdcall{$ENDIF};
begin
  Result := -1;  // 禁用引用计数
end;

function TFsBufWriter._Release: LongInt; {$IFNDEF WINDOWS}cdecl{$ELSE}stdcall{$ENDIF};
begin
  Result := -1;  // 不自动释放
end;

constructor TFsBufWriter.Create(AFile: TFile; ABufSize: Integer; AOwnsFile: Boolean);
begin
  inherited Create;
  FFile := AFile;
  FOwnsFile := AOwnsFile;
  SetLength(FBuffer, ABufSize);
  FBufPos := 0;
end;

destructor TFsBufWriter.Destroy;
begin
  // 确保缓冲区被刷新
  if FBufPos > 0 then
    FlushBuffer;

  if FOwnsFile and Assigned(FFile) then
    FFile.Free;

  inherited Destroy;
end;

procedure TFsBufWriter.FlushBuffer;
begin
  if FBufPos > 0 then
  begin
    // 调用底层 TFile.Write
    FFile.Write(FBuffer[0], FBufPos);
    FBufPos := 0;
  end;
end;

function TFsBufWriter.Write(const ABuffer; ACount: Integer): Integer;
var
  Src: PByte;
  Remaining, ToCopy, BufSpace: Integer;
begin
  Result := ACount;
  Src := @ABuffer;
  Remaining := ACount;

  while Remaining > 0 do
  begin
    BufSpace := Length(FBuffer) - FBufPos;

    // 如果数据量大于剩余缓冲区空间
    if Remaining >= BufSpace then
    begin
      // 先填满缓冲区
      Move(Src^, FBuffer[FBufPos], BufSpace);
      FBufPos := Length(FBuffer);
      FlushBuffer;
      Inc(Src, BufSpace);
      Dec(Remaining, BufSpace);
    end
    else
    begin
      // 数据量小于剩余空间，直接复制到缓冲区
      Move(Src^, FBuffer[FBufPos], Remaining);
      Inc(FBufPos, Remaining);
      Remaining := 0;
    end;
  end;
end;

procedure TFsBufWriter.WriteByte(AByte: Byte);
begin
  if FBufPos >= Length(FBuffer) then
    FlushBuffer;

  FBuffer[FBufPos] := AByte;
  Inc(FBufPos);
end;

function TFsBufWriter.WriteBytes(const AData: TBytes): Integer;
begin
  if Length(AData) > 0 then
    Result := Write(AData[0], Length(AData))
  else
    Result := 0;
end;

function TFsBufWriter.WriteString(const AStr: string): Integer;
begin
  if Length(AStr) > 0 then
    Result := Write(AStr[1], Length(AStr))
  else
    Result := 0;
end;

procedure TFsBufWriter.WriteLn(const AStr: string);
const
  LF: AnsiChar = #10;
begin
  if Length(AStr) > 0 then
    WriteString(AStr);
  Write(LF, 1);
end;

procedure TFsBufWriter.Flush;
begin
  FlushBuffer;
  FFile.Sync;  // 调用底层 TFile 的 Sync
end;

function TFsBufWriter.BufferSize: Integer;
begin
  Result := Length(FBuffer);
end;

function TFsBufWriter.BufferedBytes: Integer;
begin
  Result := FBufPos;
end;

// ============================================================================
// 便捷函数
// ============================================================================

function FsBufReader(const APath: string; ABufSize: Integer): TFsBufReader;
var
  F: TFile;
begin
  F := TFile.Open(APath);
  Result := TFsBufReader.Create(F, ABufSize, True);  // OwnsFile = True
end;

function FsBufWriter(const APath: string; ABufSize: Integer): TFsBufWriter;
var
  F: TFile;
begin
  F := TFile.Create_(APath);
  Result := TFsBufWriter.Create(F, ABufSize, True);  // OwnsFile = True
end;

procedure FsForEachLine(const APath: string; ACallback: TFsLineCallback);
var
  Reader: TFsBufReader;
  Line: string;
begin
  Reader := FsBufReader(APath);
  try
    while Reader.ReadLine(Line) do
      ACallback(Line);
  finally
    Reader.Free;
  end;
end;

end.
