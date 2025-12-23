unit fafafa.core.fs.highlevel.optimized;

{$CODEPAGE UTF8}
{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes,
  fafafa.core.fs,
  fafafa.core.fs.errors,
  fafafa.core.fs.path;

type
  // 性能优化的文件操作类
  TFsFileOptimized = class
  private
    FHandle: TfsFile;
    FPath: string;
    FIsOpen: Boolean;
    FBufferSize: Integer;
    FReadBuffer: TBytes;
    FWriteBuffer: TBytes;
    FBufferPos: Integer;
    FBufferUsed: Integer;
    FBufferDirty: Boolean;
    
    function GetSize: Int64;
    function GetPosition: Int64;
    procedure SetPosition(const aValue: Int64);
    procedure FlushWriteBuffer;
    procedure FillReadBuffer;
    
  public
    constructor Create(aBufferSize: Integer = 64 * 1024); // 默认64KB缓冲区
    destructor Destroy; override;
    
    // 基础操作
    procedure Open(const aPath: string; aMode: TFsOpenMode; aShare: TFsShareMode = fsmNone);
    procedure Close;
    function Read(var aBuffer; aCount: Integer): Integer;
    function Write(const aBuffer; aCount: Integer): Integer;
    procedure Flush;
    procedure Truncate(aSize: Int64);
    
    // 优化的便利方法
    function ReadStringOptimized(aEncoding: TEncoding = nil): string;
    procedure WriteStringOptimized(const aText: string; aEncoding: TEncoding = nil);
    function ReadBytesOptimized: TBytes;
    procedure WriteBytesOptimized(const aBytes: TBytes);
    
    // 分块读取方法（适用于大文件）
    function ReadChunk(aChunkSize: Integer): TBytes;
    procedure WriteChunk(const aChunk: TBytes);
    
    // 属性
    property Handle: TfsFile read FHandle;
    property Path: string read FPath;
    property IsOpen: Boolean read FIsOpen;
    property Size: Int64 read GetSize;
    property Position: Int64 read GetPosition write SetPosition;
    property BufferSize: Integer read FBufferSize write FBufferSize;
  end;

// 优化的便利函数
function ReadTextFileOptimized(const aPath: string; aEncoding: TEncoding = nil): string;
procedure WriteTextFileOptimized(const aPath, aText: string; aEncoding: TEncoding = nil);
function ReadBinaryFileOptimized(const aPath: string): TBytes;
procedure WriteBinaryFileOptimized(const aPath: string; const aData: TBytes);

// 批量操作优化
procedure BatchCopyFiles(const aSourceFiles, aDestFiles: array of string);
procedure BatchDeleteFiles(const aFiles: array of string);

implementation

constructor TFsFileOptimized.Create(aBufferSize: Integer);
begin
  inherited Create;
  FHandle := INVALID_HANDLE_VALUE;
  FIsOpen := False;
  FBufferSize := aBufferSize;
  SetLength(FReadBuffer, FBufferSize);
  SetLength(FWriteBuffer, FBufferSize);
  FBufferPos := 0;
  FBufferUsed := 0;
  FBufferDirty := False;
end;

destructor TFsFileOptimized.Destroy;
begin
  if FIsOpen then
    Close;
  inherited Destroy;
end;

procedure TFsFileOptimized.Open(const aPath: string; aMode: TFsOpenMode; aShare: TFsShareMode);
var
  LFlags: Integer;
  LResult: Integer;
  LErrorCode: TFsErrorCode;
begin
  if FIsOpen then
    raise EFsError.Create(FS_ERROR_INVALID_PARAMETER, 'File is already open', 0);

  // 验证路径安全性
  if not ValidatePath(aPath) then
    raise EFsError.Create(FS_ERROR_INVALID_PATH, 'Invalid or unsafe path: ' + aPath, 0);

  // 转换打开模式
  case aMode of
    fomRead: LFlags := O_RDONLY;
    fomWrite: LFlags := O_WRONLY or O_CREAT or O_TRUNC;
    fomReadWrite: LFlags := O_RDWR or O_CREAT;
    fomCreate: LFlags := O_RDWR or O_CREAT or O_TRUNC;
    fomAppend: LFlags := O_WRONLY or O_CREAT or O_APPEND;
  end;

  FHandle := fs_open(aPath, LFlags, S_IRWXU);
  if not IsValidHandle(QWord(FHandle)) then
  begin
    LErrorCode := GetLastFsError();
    raise EFsError.Create(LErrorCode, 'Failed to open file: ' + aPath, GetLastOSError());
  end;

  FPath := aPath;
  FIsOpen := True;
  FBufferPos := 0;
  FBufferUsed := 0;
  FBufferDirty := False;
end;

procedure TFsFileOptimized.Close;
begin
  if FIsOpen then
  begin
    if FBufferDirty then
      FlushWriteBuffer;
    
    fs_close(QWord(FHandle));
    FHandle := INVALID_HANDLE_VALUE;
    FIsOpen := False;
    FPath := '';
    FBufferPos := 0;
    FBufferUsed := 0;
    FBufferDirty := False;
  end;
end;

function TFsFileOptimized.GetSize: Int64;
var
  LStat: TfsStat;
begin
  if not FIsOpen then
    raise EFsError.Create(FS_ERROR_INVALID_PARAMETER, 'File is not open', 0);
    
  CheckFsResult(fs_fstat(QWord(FHandle), LStat), 'get file size');
  Result := LStat.Size;
end;

function TFsFileOptimized.GetPosition: Int64;
var
  LResult: Int64;
begin
  if not FIsOpen then
    raise EFsError.Create(FS_ERROR_INVALID_PARAMETER, 'File is not open', 0);
    
  LResult := fs_seek(QWord(FHandle), 0, SEEK_CUR);
  if LResult < 0 then
    CheckFsResult(Integer(LResult), 'get file position');
  Result := LResult;
end;

procedure TFsFileOptimized.SetPosition(const aValue: Int64);
var
  LResult: Int64;
begin
  if not FIsOpen then
    raise EFsError.Create(FS_ERROR_INVALID_PARAMETER, 'File is not open', 0);
    
  // 刷新缓冲区
  if FBufferDirty then
    FlushWriteBuffer;
  FBufferPos := 0;
  FBufferUsed := 0;
    
  LResult := fs_seek(QWord(FHandle), aValue, SEEK_SET);
  if LResult < 0 then
    CheckFsResult(Integer(LResult), 'set file position');
end;

procedure TFsFileOptimized.FlushWriteBuffer;
var
  LBytesWritten: Integer;
begin
  if FBufferDirty and (FBufferUsed > 0) then
  begin
    LBytesWritten := fs_write(QWord(FHandle), @FWriteBuffer[0], FBufferUsed, 0);
    if LBytesWritten < 0 then
      CheckFsResult(LBytesWritten, 'flush write buffer');
    FBufferUsed := 0;
    FBufferDirty := False;
  end;
end;

procedure TFsFileOptimized.FillReadBuffer;
var
  LBytesRead: Integer;
begin
  LBytesRead := fs_read(QWord(FHandle), @FReadBuffer[0], FBufferSize, 0);
  if LBytesRead < 0 then
    CheckFsResult(LBytesRead, 'fill read buffer');
  FBufferUsed := LBytesRead;
  FBufferPos := 0;
end;

function TFsFileOptimized.Read(var aBuffer; aCount: Integer): Integer;
var
  LDestPtr: PByte;
  LBytesToCopy: Integer;
  LTotalRead: Integer;
begin
  if not FIsOpen then
    raise EFsError.Create(FS_ERROR_INVALID_PARAMETER, 'File is not open', 0);

  LDestPtr := @aBuffer;
  LTotalRead := 0;
  
  while (aCount > 0) and (LTotalRead < aCount) do
  begin
    // 如果缓冲区为空，填充它
    if FBufferPos >= FBufferUsed then
    begin
      FillReadBuffer;
      if FBufferUsed = 0 then
        Break; // 文件结束
    end;
    
    // 从缓冲区复制数据
    LBytesToCopy := Min(aCount - LTotalRead, FBufferUsed - FBufferPos);
    Move(FReadBuffer[FBufferPos], LDestPtr^, LBytesToCopy);
    
    Inc(FBufferPos, LBytesToCopy);
    Inc(LDestPtr, LBytesToCopy);
    Inc(LTotalRead, LBytesToCopy);
  end;
  
  Result := LTotalRead;
end;

function TFsFileOptimized.Write(const aBuffer; aCount: Integer): Integer;
var
  LSrcPtr: PByte;
  LBytesToCopy: Integer;
  LTotalWritten: Integer;
begin
  if not FIsOpen then
    raise EFsError.Create(FS_ERROR_INVALID_PARAMETER, 'File is not open', 0);

  LSrcPtr := @aBuffer;
  LTotalWritten := 0;
  
  while LTotalWritten < aCount do
  begin
    // 如果缓冲区满了，刷新它
    if FBufferUsed >= FBufferSize then
      FlushWriteBuffer;
    
    // 复制数据到缓冲区
    LBytesToCopy := Min(aCount - LTotalWritten, FBufferSize - FBufferUsed);
    Move(LSrcPtr^, FWriteBuffer[FBufferUsed], LBytesToCopy);
    
    Inc(FBufferUsed, LBytesToCopy);
    Inc(LSrcPtr, LBytesToCopy);
    Inc(LTotalWritten, LBytesToCopy);
    FBufferDirty := True;
  end;
  
  Result := LTotalWritten;
end;

procedure TFsFileOptimized.Flush;
begin
  if not FIsOpen then
    raise EFsError.Create(FS_ERROR_INVALID_PARAMETER, 'File is not open', 0);
    
  FlushWriteBuffer;
  CheckFsResult(fs_fsync(QWord(FHandle)), 'flush file');
end;

procedure TFsFileOptimized.Truncate(aSize: Int64);
begin
  if not FIsOpen then
    raise EFsError.Create(FS_ERROR_INVALID_PARAMETER, 'File is not open', 0);
    
  FlushWriteBuffer;
  CheckFsResult(fs_ftruncate(QWord(FHandle), aSize), 'truncate file');
  
  // 重置缓冲区
  FBufferPos := 0;
  FBufferUsed := 0;
  FBufferDirty := False;
end;

function TFsFileOptimized.ReadStringOptimized(aEncoding: TEncoding): string;
var
  LBytes: TBytes;
  LUTF8String: UTF8String;
begin
  LBytes := ReadBytesOptimized;
  if aEncoding = nil then
    aEncoding := TEncoding.UTF8;

  // 优化：直接使用UTF8字符串避免多次转换
  LUTF8String := aEncoding.GetString(LBytes);
  Result := string(LUTF8String);
end;

procedure TFsFileOptimized.WriteStringOptimized(const aText: string; aEncoding: TEncoding);
var
  LBytes: TBytes;
  LUTF8String: UTF8String;
begin
  if aEncoding = nil then
    aEncoding := TEncoding.UTF8;

  // 优化：直接转换避免中间步骤
  LUTF8String := UTF8String(aText);
  LBytes := aEncoding.GetBytes(LUTF8String);
  WriteBytesOptimized(LBytes);
end;

function TFsFileOptimized.ReadBytesOptimized: TBytes;
var
  LFileSize: Int64;
  LBytesRead: Integer;
  LTotalRead: Integer;
  LChunkSize: Integer;
begin
  LFileSize := GetSize;
  SetLength(Result, LFileSize);

  if LFileSize = 0 then
    Exit;

  // 优化：分块读取大文件，避免一次性分配过大内存
  LTotalRead := 0;
  while LTotalRead < LFileSize do
  begin
    LChunkSize := Min(FBufferSize, LFileSize - LTotalRead);
    LBytesRead := Read(Result[LTotalRead], LChunkSize);
    if LBytesRead = 0 then
      Break;
    Inc(LTotalRead, LBytesRead);
  end;

  SetLength(Result, LTotalRead);
end;

procedure TFsFileOptimized.WriteBytesOptimized(const aBytes: TBytes);
begin
  if Length(aBytes) > 0 then
    Write(aBytes[0], Length(aBytes));
end;

function TFsFileOptimized.ReadChunk(aChunkSize: Integer): TBytes;
var
  LBytesRead: Integer;
begin
  SetLength(Result, aChunkSize);
  LBytesRead := Read(Result[0], aChunkSize);
  SetLength(Result, LBytesRead);
end;

procedure TFsFileOptimized.WriteChunk(const aChunk: TBytes);
begin
  if Length(aChunk) > 0 then
    Write(aChunk[0], Length(aChunk));
end;

// 优化的便利函数实现

function ReadTextFileOptimized(const aPath: string; aEncoding: TEncoding): string;
var
  LFile: TFsFileOptimized;
begin
  LFile := TFsFileOptimized.Create;
  try
    LFile.Open(aPath, fomRead);
    Result := LFile.ReadStringOptimized(aEncoding);
  finally
    LFile.Free;
  end;
end;

procedure WriteTextFileOptimized(const aPath, aText: string; aEncoding: TEncoding);
var
  LFile: TFsFileOptimized;
begin
  LFile := TFsFileOptimized.Create;
  try
    LFile.Open(aPath, fomWrite);
    LFile.WriteStringOptimized(aText, aEncoding);
  finally
    LFile.Free;
  end;
end;

function ReadBinaryFileOptimized(const aPath: string): TBytes;
var
  LFile: TFsFileOptimized;
begin
  LFile := TFsFileOptimized.Create;
  try
    LFile.Open(aPath, fomRead);
    Result := LFile.ReadBytesOptimized;
  finally
    LFile.Free;
  end;
end;

procedure WriteBinaryFileOptimized(const aPath: string; const aData: TBytes);
var
  LFile: TFsFileOptimized;
begin
  LFile := TFsFileOptimized.Create;
  try
    LFile.Open(aPath, fomWrite);
    LFile.WriteBytesOptimized(aData);
  finally
    LFile.Free;
  end;
end;

procedure BatchCopyFiles(const aSourceFiles, aDestFiles: array of string);
var
  LI: Integer;
  LSourceFile, LDestFile: TFsFileOptimized;
  LChunk: TBytes;
const
  COPY_BUFFER_SIZE = 1024 * 1024; // 1MB缓冲区
begin
  if Length(aSourceFiles) <> Length(aDestFiles) then
    raise EFsError.Create(FS_ERROR_INVALID_PARAMETER, 'Source and destination arrays must have same length', 0);

  LSourceFile := TFsFileOptimized.Create(COPY_BUFFER_SIZE);
  LDestFile := TFsFileOptimized.Create(COPY_BUFFER_SIZE);
  try
    for LI := 0 to High(aSourceFiles) do
    begin
      LSourceFile.Open(aSourceFiles[LI], fomRead);
      LDestFile.Open(aDestFiles[LI], fomCreate);

      // 分块复制
      repeat
        LChunk := LSourceFile.ReadChunk(COPY_BUFFER_SIZE);
        if Length(LChunk) = 0 then
          Break;
        LDestFile.WriteChunk(LChunk);
      until False;

      LSourceFile.Close;
      LDestFile.Close;
    end;
  finally
    LSourceFile.Free;
    LDestFile.Free;
  end;
end;

procedure BatchDeleteFiles(const aFiles: array of string);
var
  LI: Integer;
begin
  for LI := 0 to High(aFiles) do
  begin
    if FileExists(aFiles[LI]) then
      DeleteFile(aFiles[LI]);
  end;
end;

function Min(a, b: Integer): Integer;
begin
  if a < b then Result := a else Result := b;
end;

initialization

end.
