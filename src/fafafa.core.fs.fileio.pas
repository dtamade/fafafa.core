unit fafafa.core.fs.fileio;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

{!
  fafafa.core.fs.fileio - 文件操作核心类型

  从 highlevel.pas 拆分，包含：
  - IFsFile 接口
  - TFsFile 实现类
  - TFsFileNoExcept 无异常包装
  - 文件便利函数 (ReadTextFile, WriteTextFile 等)
  - 单文件复制/移动 (FsCopyFileEx, FsMoveFileEx)
}

interface

uses
  SysUtils, Classes,
  fafafa.core.fs,
  fafafa.core.fs.errors,
  fafafa.core.fs.path,
  fafafa.core.fs.options;

type
  // 文件操作接口
  IFsFile = interface
    ['{6B7925C9-4E32-4E4D-9B3A-0D1E3D3B8A71}']
    // 生命周期
    procedure Open(const APath: string; AMode: TFsOpenMode);
    procedure Close;
    function  IsOpen: Boolean;
    // 位置与大小
    function  Seek(ADistance: Int64; AWhence: Integer): Int64;
    function  Tell: Int64;
    function  Size: Int64;
    procedure Truncate(ANewSize: Int64);
    // 同步
    procedure Flush;
    // 读写
    function  Read(var ABuffer; ACount: Integer): Integer;
    function  Write(const ABuffer; ACount: Integer): Integer;
    // 定位读写
    function  PRead(var ABuffer; ACount: Integer; AOffset: Int64): Integer;
    function  PWrite(const ABuffer; ACount: Integer; AOffset: Int64): Integer;
  end;

  // 文件操作实现类
  TFsFile = class(TInterfacedObject, IFsFile)
  private
    FHandle: fafafa.core.fs.TfsFile;
    FPath: string;
    FIsOpen: Boolean;
    function GetSize: Int64;
    function GetPosition: Int64;
    procedure SetPosition(const aValue: Int64);
  public
    constructor Create;
    destructor Destroy; override;

    // 文件操作
    procedure Open(const aPath: string; aMode: TFsOpenMode; aShare: TFsShareMode); overload;
    procedure Open(const APath: string; AMode: TFsOpenMode); overload;
    procedure OpenEx(const APath: string; const Opts: TFsOpenOptions);
    procedure Close;
    function Read(var aBuffer; aCount: Integer): Integer;
    function Write(const aBuffer; aCount: Integer): Integer;
    procedure Flush;
    procedure Truncate(aSize: Int64);

    function IsOpen: Boolean;
    function Seek(ADistance: Int64; AWhence: Integer): Int64;
    function Tell: Int64;
    function Size: Int64;
    function PRead(var ABuffer; ACount: Integer; AOffset: Int64): Integer;
    function PWrite(const ABuffer; ACount: Integer; AOffset: Int64): Integer;

    // 便利方法
    function ReadString(aEncoding: TEncoding = nil): string;
    procedure WriteString(const aText: string; aEncoding: TEncoding = nil);
    function ReadBytes: TBytes;
    procedure WriteBytes(const aBytes: TBytes);

    // 属性
    property Handle: fafafa.core.fs.TfsFile read FHandle;
    property Path: string read FPath;
    property IsOpenProp: Boolean read FIsOpen;
    property SizeProp: Int64 read GetSize;
    property Position: Int64 read GetPosition write SetPosition;
  end;

  // 无异常包装
  TFsFileNoExcept = object
    FileIntf: IFsFile;
    function Open(const APath: string; AMode: TFsOpenMode): Integer;
    function Close: Integer;
    function Read(var ABuffer; ACount: Integer; out N: Integer): Integer;
    function Write(const ABuffer; ACount: Integer; out N: Integer): Integer;
    function Seek(ADistance: Int64; AWhence: Integer; out NewPos: Int64): Integer;
    function Tell(out Pos: Int64): Integer;
    function Size(out ASize: Int64): Integer;
    function Truncate(ANewSize: Int64): Integer;
    function Flush: Integer;
    function PRead(var ABuffer; ACount: Integer; AOffset: Int64; out N: Integer): Integer;
    function PWrite(const ABuffer; ACount: Integer; AOffset: Int64; out N: Integer): Integer;
  end;

// 工厂函数
function NewFsFile: IFsFile;
function NewFsFileNoExcept: TFsFileNoExcept;
function OpenFileEx(const APath: string; const Opts: TFsOpenOptions): IFsFile;

// 便利函数
function ReadTextFile(const aPath: string; aEncoding: TEncoding = nil): string;
procedure WriteTextFile(const aPath, aText: string; aEncoding: TEncoding = nil);
function ReadBinaryFile(const aPath: string): TBytes;
procedure WriteBinaryFile(const aPath: string; const aData: TBytes);
procedure WriteFileAtomic(const aPath: string; const aData: TBytes);
procedure WriteTextFileAtomic(const aPath, aText: string; aEncoding: TEncoding = nil);

// 单文件复制/移动
procedure FsCopyFileEx(const aSrc, aDst: string; const aOpts: TFsCopyOptions);
procedure FsMoveFileEx(const aSrc, aDst: string; const aOpts: TFsMoveOptions);

// 文件存在检查
function FileExists(const aPath: string): Boolean;

implementation

uses
  fafafa.core.fs.copyaccel;

{ TFsFile }

constructor TFsFile.Create;
begin
  inherited Create;
  FHandle := INVALID_HANDLE_VALUE;
  FPath := '';
  FIsOpen := False;
end;

destructor TFsFile.Destroy;
begin
  try
    if FIsOpen then
      Close;
  except
    if FHandle <> INVALID_HANDLE_VALUE then
    begin
      fs_close(FHandle);
      FHandle := INVALID_HANDLE_VALUE;
    end;
    FIsOpen := False;
  end;
  inherited Destroy;
end;

procedure TFsFile.Open(const aPath: string; aMode: TFsOpenMode; aShare: TFsShareMode);
var
  LFlags: Integer;
  LResult: Integer;
  LErrorCode: TFsErrorCode;
begin
  if FIsOpen then
    raise EFsError.Create(FS_ERROR_INVALID_PARAMETER, 'File is already open', 0);

  if not ValidatePath(aPath) then
    raise EFsError.Create(FS_ERROR_INVALID_PATH, 'Invalid or unsafe path: ' + aPath, 0);

  case aMode of
    fomRead: LFlags := O_RDONLY;
    fomWrite: LFlags := O_WRONLY or O_CREAT or O_TRUNC;
    fomReadWrite: LFlags := O_RDWR or O_CREAT;
    fomAppend: LFlags := O_WRONLY or O_CREAT or O_APPEND;
    fomCreate: LFlags := O_RDWR or O_CREAT or O_TRUNC;
    fomCreateExclusive: LFlags := O_RDWR or O_CREAT or O_EXCL;
  end;

  if fsmRead   in aShare then LFlags := LFlags or O_SHARE_READ;
  if fsmWrite  in aShare then LFlags := LFlags or O_SHARE_WRITE;
  if fsmDelete in aShare then LFlags := LFlags or O_SHARE_DELETE;
  if aShare = [] then
    LFlags := LFlags or O_SHARE_READ or O_SHARE_WRITE or O_SHARE_DELETE;

  FHandle := fs_open(aPath, LFlags, S_IRWXU);
  if not IsValidHandle(FHandle) then
  begin
    LErrorCode := GetLastFsError();
    LResult := Integer(LErrorCode);
    raise EFsError.Create(LErrorCode, Format('Failed to open file "%s"', [aPath]), -LResult);
  end
  else
  begin
    FPath := aPath;
    FIsOpen := True;
  end;
end;

procedure TFsFile.Open(const APath: string; AMode: TFsOpenMode);
begin
  Open(APath, AMode, [fsmRead]);
end;

procedure TFsFile.OpenEx(const APath: string; const Opts: TFsOpenOptions);
var
  Flags: Integer;
  Share: TFsShareMode;
begin
  Share := Opts.Share;
  Flags := FsOpenOptions_ToFlags(Opts);
  if fsmRead   in Share then Flags := Flags or O_SHARE_READ;
  if fsmWrite  in Share then Flags := Flags or O_SHARE_WRITE;
  if fsmDelete in Share then Flags := Flags or O_SHARE_DELETE;
  if Share = [] then
    Flags := Flags or O_SHARE_READ or O_SHARE_WRITE or O_SHARE_DELETE;
  if FIsOpen then
    raise EFsError.Create(FS_ERROR_INVALID_PARAMETER, 'File is already open', 0);
  if not ValidatePath(APath) then
    raise EFsError.Create(FS_ERROR_INVALID_PATH, 'Invalid or unsafe path: ' + APath, 0);
  FHandle := fs_open(APath, Flags, S_IRWXU);
  if not IsValidHandle(FHandle) then
    CheckFsResult(Integer(GetLastFsError), 'open file via options')
  else
  begin
    FPath := APath;
    FIsOpen := True;
  end;
end;

function TFsFile.IsOpen: Boolean;
begin
  Result := FIsOpen;
end;

procedure TFsFile.Close;
begin
  if FIsOpen then
  begin
    CheckFsResult(fs_close(FHandle), 'close file');
    FHandle := INVALID_HANDLE_VALUE;
    FIsOpen := False;
    FPath := '';
  end;
end;

function TFsFile.Read(var aBuffer; aCount: Integer): Integer;
begin
  if not FIsOpen then
    raise EFsError.Create(FS_ERROR_INVALID_HANDLE, 'File is not open', 0);
  Result := fs_read(FHandle, @aBuffer, aCount, -1);
  if Result < 0 then
    CheckFsResult(Result, 'read from file');
end;

function TFsFile.Write(const aBuffer; aCount: Integer): Integer;
begin
  if not FIsOpen then
    raise EFsError.Create(FS_ERROR_INVALID_HANDLE, 'File is not open', 0);
  Result := fs_write(FHandle, @aBuffer, aCount, -1);
  if Result < 0 then
    CheckFsResult(Result, 'write to file');
end;

procedure TFsFile.Flush;
var
  R: Integer;
begin
  if not FIsOpen then
    raise EFsError.Create(FS_ERROR_INVALID_HANDLE, 'File is not open', 0);
  R := fs_fsync(FHandle);
  CheckFsResult(R, 'flush (fsync)');
end;

procedure TFsFile.Truncate(aSize: Int64);
begin
  if not FIsOpen then
    raise EFsError.Create(FS_ERROR_INVALID_HANDLE, 'File is not open', 0);
  CheckFsResult(fs_ftruncate(FHandle, aSize), 'truncate file');
end;

function TFsFile.Seek(ADistance: Int64; AWhence: Integer): Int64;
begin
  if not FIsOpen then
    raise EFsError.Create(FS_ERROR_INVALID_HANDLE, 'File is not open', 0);
  Result := fs_seek(FHandle, ADistance, AWhence);
  if Result < 0 then
    CheckFsResult(Integer(Result), 'seek');
end;

function TFsFile.Tell: Int64;
begin
  Result := GetPosition;
end;

function TFsFile.Size: Int64;
begin
  Result := GetSize;
end;

function TFsFile.PRead(var ABuffer; ACount: Integer; AOffset: Int64): Integer;
var
  LPos: Int64;
begin
  if not FIsOpen then
    raise EFsError.Create(FS_ERROR_INVALID_HANDLE, 'File is not open', 0);
  LPos := fs_seek(FHandle, 0, SEEK_CUR);
  if LPos < 0 then CheckFsResult(Integer(LPos), 'pread.tell');
  try
    Result := fs_read(FHandle, @ABuffer, ACount, AOffset);
    if Result < 0 then
      CheckFsResult(Result, 'pread');
  finally
    fs_seek(FHandle, LPos, SEEK_SET);
  end;
end;

function TFsFile.PWrite(const ABuffer; ACount: Integer; AOffset: Int64): Integer;
var
  LPos: Int64;
begin
  if not FIsOpen then
    raise EFsError.Create(FS_ERROR_INVALID_HANDLE, 'File is not open', 0);
  LPos := fs_seek(FHandle, 0, SEEK_CUR);
  if LPos < 0 then CheckFsResult(Integer(LPos), 'pwrite.tell');
  try
    Result := fs_write(FHandle, @ABuffer, ACount, AOffset);
    if Result < 0 then
      CheckFsResult(Result, 'pwrite');
  finally
    fs_seek(FHandle, LPos, SEEK_SET);
  end;
end;

function TFsFile.GetSize: Int64;
var
  LStat: TfsStat;
begin
  if not FIsOpen then
    raise EFsError.Create(FS_ERROR_INVALID_HANDLE, 'File is not open', 0);
  CheckFsResult(fs_fstat(FHandle, LStat), 'get file size');
  Result := LStat.Size;
end;

function TFsFile.GetPosition: Int64;
begin
  if not FIsOpen then
    raise EFsError.Create(FS_ERROR_INVALID_HANDLE, 'File is not open', 0);
  Result := fs_tell(FHandle);
  if Result < 0 then
    CheckFsResult(Integer(Result), 'get file position');
end;

procedure TFsFile.SetPosition(const aValue: Int64);
var
  LResult: Int64;
begin
  if not FIsOpen then
    raise EFsError.Create(FS_ERROR_INVALID_HANDLE, 'File is not open', 0);
  LResult := fs_seek(FHandle, aValue, SEEK_SET);
  if LResult < 0 then
    CheckFsResult(Integer(LResult), 'set file position');
end;

function TFsFile.ReadString(aEncoding: TEncoding): string;
var
  LBytes: TBytes;
begin
  LBytes := ReadBytes;
  if aEncoding = nil then
    aEncoding := TEncoding.UTF8;
  Result := string(aEncoding.GetString(LBytes));
end;

procedure TFsFile.WriteString(const aText: string; aEncoding: TEncoding);
var
  LBytes: TBytes;
begin
  if aEncoding = nil then
    aEncoding := TEncoding.UTF8;
  LBytes := aEncoding.GetBytes(UnicodeString(aText));
  WriteBytes(LBytes);
end;

function TFsFile.ReadBytes: TBytes;
var
  LSize: Int64;
  LBytesRead: Integer;
begin
  Result := nil;
  LSize := GetSize;
  if LSize > 0 then
  begin
    SetLength(Result, LSize);
    LBytesRead := Read(Result[0], LSize);
    SetLength(Result, LBytesRead);
  end;
end;

procedure TFsFile.WriteBytes(const aBytes: TBytes);
begin
  if Length(aBytes) > 0 then
    Write(aBytes[0], Length(aBytes));
end;

{ TFsFileNoExcept }

function TFsFileNoExcept.Open(const APath: string; AMode: TFsOpenMode): Integer;
begin
  try
    FileIntf := NewFsFile;
    FileIntf.Open(APath, AMode);
    Result := 0;
  except
    on E: EFsError do begin FileIntf := nil; Result := Integer(E.ErrorCode); end;
    on E: Exception do begin FileIntf := nil; Result := Integer(FS_ERROR_UNKNOWN); end;
  end;
end;

function TFsFileNoExcept.Close: Integer;
begin
  try
    if FileIntf <> nil then
      FileIntf.Close;
    FileIntf := nil;
    Result := 0;
  except
    on E: EFsError do begin FileIntf := nil; Result := Integer(E.ErrorCode); end;
    on E: Exception do begin FileIntf := nil; Result := Integer(FS_ERROR_UNKNOWN); end;
  end;
end;

function TFsFileNoExcept.Read(var ABuffer; ACount: Integer; out N: Integer): Integer;
begin
  if FileIntf = nil then begin N := 0; Result := Integer(FS_ERROR_INVALID_HANDLE); Exit; end;
  try
    N := FileIntf.Read(ABuffer, ACount);
    Result := 0;
  except
    on E: EFsError do begin N := 0; Result := Integer(E.ErrorCode); end;
    on E: Exception do begin N := 0; Result := Integer(FS_ERROR_UNKNOWN); end;
  end;
end;

function TFsFileNoExcept.Write(const ABuffer; ACount: Integer; out N: Integer): Integer;
begin
  if FileIntf = nil then begin N := 0; Result := Integer(FS_ERROR_INVALID_HANDLE); Exit; end;
  if @ABuffer = nil then ;
  try
    N := FileIntf.Write(ABuffer, ACount);
    Result := 0;
  except
    on E: EFsError do begin N := 0; Result := Integer(E.ErrorCode); end;
    on E: Exception do begin N := 0; Result := Integer(FS_ERROR_UNKNOWN); end;
  end;
end;

function TFsFileNoExcept.Seek(ADistance: Int64; AWhence: Integer; out NewPos: Int64): Integer;
begin
  if FileIntf = nil then begin NewPos := -1; Result := Integer(FS_ERROR_INVALID_HANDLE); Exit; end;
  try
    NewPos := FileIntf.Seek(ADistance, AWhence);
    Result := 0;
  except
    on E: EFsError do begin NewPos := -1; Result := Integer(E.ErrorCode); end;
    on E: Exception do begin NewPos := -1; Result := Integer(FS_ERROR_UNKNOWN); end;
  end;
end;

function TFsFileNoExcept.Tell(out Pos: Int64): Integer;
begin
  if FileIntf = nil then begin Pos := -1; Result := Integer(FS_ERROR_INVALID_HANDLE); Exit; end;
  try
    Pos := FileIntf.Tell;
    Result := 0;
  except
    on E: EFsError do begin Pos := -1; Result := Integer(E.ErrorCode); end;
    on E: Exception do begin Pos := -1; Result := Integer(FS_ERROR_UNKNOWN); end;
  end;
end;

function TFsFileNoExcept.Size(out ASize: Int64): Integer;
begin
  if FileIntf = nil then begin ASize := -1; Result := Integer(FS_ERROR_INVALID_HANDLE); Exit; end;
  try
    ASize := FileIntf.Size;
    Result := 0;
  except
    on E: EFsError do begin ASize := -1; Result := Integer(E.ErrorCode); end;
    on E: Exception do begin ASize := -1; Result := Integer(FS_ERROR_UNKNOWN); end;
  end;
end;

function TFsFileNoExcept.Truncate(ANewSize: Int64): Integer;
begin
  if FileIntf = nil then begin Result := Integer(FS_ERROR_INVALID_HANDLE); Exit; end;
  try
    FileIntf.Truncate(ANewSize);
    Result := 0;
  except
    on E: EFsError do Result := Integer(E.ErrorCode);
    on E: Exception do Result := Integer(FS_ERROR_UNKNOWN);
  end;
end;

function TFsFileNoExcept.Flush: Integer;
begin
  if FileIntf = nil then begin Result := Integer(FS_ERROR_INVALID_HANDLE); Exit; end;
  try
    FileIntf.Flush;
    Result := 0;
  except
    on E: EFsError do Result := Integer(E.ErrorCode);
    on E: Exception do Result := Integer(FS_ERROR_UNKNOWN);
  end;
end;

function TFsFileNoExcept.PRead(var ABuffer; ACount: Integer; AOffset: Int64; out N: Integer): Integer;
begin
  if FileIntf = nil then begin N := 0; Result := Integer(FS_ERROR_INVALID_HANDLE); Exit; end;
  try
    N := FileIntf.PRead(ABuffer, ACount, AOffset);
    Result := 0;
  except
    on E: EFsError do begin N := 0; Result := Integer(E.ErrorCode); end;
    on E: Exception do begin N := 0; Result := Integer(FS_ERROR_UNKNOWN); end;
  end;
end;

function TFsFileNoExcept.PWrite(const ABuffer; ACount: Integer; AOffset: Int64; out N: Integer): Integer;
begin
  if FileIntf = nil then begin N := 0; Result := Integer(FS_ERROR_INVALID_HANDLE); Exit; end;
  if @ABuffer = nil then ;
  try
    N := FileIntf.PWrite(ABuffer, ACount, AOffset);
    Result := 0;
  except
    on E: EFsError do begin N := 0; Result := Integer(E.ErrorCode); end;
    on E: Exception do begin N := 0; Result := Integer(FS_ERROR_UNKNOWN); end;
  end;
end;

{ Factory functions }

function NewFsFile: IFsFile;
begin
  Result := TFsFile.Create;
end;

function NewFsFileNoExcept: TFsFileNoExcept;
begin
  Result.FileIntf := nil;
end;

function OpenFileEx(const APath: string; const Opts: TFsOpenOptions): IFsFile;
var
  V: TFsFile;
begin
  V := TFsFile.Create;
  try
    V.OpenEx(APath, Opts);
    Result := V;
  except
    V.Free;
    raise;
  end;
end;

{ Convenience functions }

function ReadTextFile(const aPath: string; aEncoding: TEncoding): string;
var
  LFile: TFsFile;
begin
  LFile := TFsFile.Create;
  try
    LFile.Open(aPath, fomRead);
    Result := LFile.ReadString(aEncoding);
  finally
    LFile.Free;
  end;
end;

procedure WriteTextFile(const aPath, aText: string; aEncoding: TEncoding);
var
  LFile: TFsFile;
begin
  LFile := TFsFile.Create;
  try
    LFile.Open(aPath, fomWrite);
    LFile.WriteString(aText, aEncoding);
  finally
    LFile.Free;
  end;
end;

function ReadBinaryFile(const aPath: string): TBytes;
var
  LFile: TFsFile;
begin
  LFile := TFsFile.Create;
  try
    LFile.Open(aPath, fomRead);
    Result := LFile.ReadBytes;
  finally
    LFile.Free;
  end;
end;

procedure WriteBinaryFile(const aPath: string; const aData: TBytes);
var
  LFile: TFsFile;
begin
  LFile := TFsFile.Create;
  try
    LFile.Open(aPath, fomWrite);
    LFile.WriteBytes(aData);
  finally
    LFile.Free;
  end;
end;

procedure WriteFileAtomic(const aPath: string; const aData: TBytes);
var
  LTmpPath: string;
  LFile: TFsFile;
begin
  LTmpPath := aPath + '.tmp.' + IntToStr(Random(MaxInt));
  LFile := TFsFile.Create;
  try
    LFile.Open(LTmpPath, fomWrite);
    if Length(aData) > 0 then
      LFile.Write(aData[0], Length(aData));
    LFile.Close;
    CheckFsResult(fs_replace(LTmpPath, aPath), 'atomic replace');
  finally
    LFile.Free;
    // 清理临时文件（如果还存在）
    fs_unlink(LTmpPath);
  end;
end;

procedure WriteTextFileAtomic(const aPath, aText: string; aEncoding: TEncoding);
var
  LBytes: TBytes;
begin
  if aEncoding = nil then
    aEncoding := TEncoding.UTF8;
  LBytes := aEncoding.GetBytes(UnicodeString(aText));
  WriteFileAtomic(aPath, LBytes);
end;

{ File copy/move }

procedure FsCopyFileEx(const aSrc, aDst: string; const aOpts: TFsCopyOptions);
var
  LSrcStat, LDstStat: TfsStat;
  LRes: Integer;
begin
  // 检查源文件
  LRes := fs_stat(aSrc, LSrcStat);
  if LRes < 0 then
    CheckFsResult(LRes, 'stat source for copy');

  // 检查目标是否存在
  if not aOpts.Overwrite then
  begin
    LRes := fs_stat(aDst, LDstStat);
    if LRes = 0 then
      raise EFsError.Create(FS_ERROR_FILE_EXISTS, 'Target already exists: ' + aDst, 0);
  end;

  // 尝试加速复制
  LRes := FsCopyAccelTryCopyFile(aSrc, aDst);
  if LRes <> 0 then
  begin
    // 回退到传统复制
    WriteBinaryFile(aDst, ReadBinaryFile(aSrc));
  end;

  // 保留时间/权限（无论是加速复制还是回退复制都执行）
  if aOpts.PreserveTimes or aOpts.PreservePerms then
  begin
    if aOpts.PreserveTimes then
      fs_utime(aDst, LSrcStat.ATime.Sec + LSrcStat.ATime.Nsec / 1e9,
                     LSrcStat.MTime.Sec + LSrcStat.MTime.Nsec / 1e9);
    if aOpts.PreservePerms then
      fs_chmod(aDst, LSrcStat.Mode and $1FF);
  end;
end;

procedure FsMoveFileEx(const aSrc, aDst: string; const aOpts: TFsMoveOptions);
var
  LSrcStat, LDstStat: TfsStat;
  LRes: Integer;
begin
  // 检查源文件
  LRes := fs_stat(aSrc, LSrcStat);
  if LRes < 0 then
    CheckFsResult(LRes, 'stat source for move');

  // 检查目标是否存在
  if not aOpts.Overwrite then
  begin
    LRes := fs_stat(aDst, LDstStat);
    if LRes = 0 then
      raise EFsError.Create(FS_ERROR_FILE_EXISTS, 'Target already exists: ' + aDst, 0);
  end;

  // 尝试加速移动（rename）
  LRes := FsCopyAccelTryMoveFile(aSrc, aDst);
  if LRes = 0 then Exit;

  // 回退到复制+删除
  FsCopyFileEx(aSrc, aDst, TFsCopyOptions(aOpts));
  fs_unlink(aSrc);
end;

function FileExists(const aPath: string): Boolean;
var
  LStat: TfsStat;
begin
  Result := (fs_stat(aPath, LStat) = 0) and ((LStat.Mode and S_IFMT) = S_IFREG);
end;

end.
