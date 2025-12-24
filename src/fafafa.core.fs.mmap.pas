unit fafafa.core.fs.mmap;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  SysUtils,
  fafafa.core.fs,
  fafafa.core.fs.errors;

type
  // 内存映射保护模式
  TMemoryProtection = (
    mpReadOnly,    // 只读
    mpReadWrite,   // 读写
    mpExecute      // 可执行
  );

  // 内存映射标志
  TMemoryMapFlags = set of (
    mmfShared,     // 共享映射
    mmfPrivate,    // 私有映射
    mmfAnonymous   // 匿名映射
  );

  // 内存映射文件类
  TMemoryMappedFile = class
  private
    FFile: TfsFile;
    FMappedMemory: Pointer;       // 实际映射的基地址（页对齐）
    FUserMemory: Pointer;         // 用户请求的地址（可能在页内偏移）
    FSize: Int64;                 // 用户请求的映射大小
    FActualMappedSize: Int64;     // 实际映射的大小（含对齐补偿）
    FOffsetAdjustment: PtrUInt;   // 偏移调整量（页对齐补偿）
    FProtection: TMemoryProtection;
    FFlags: TMemoryMapFlags;
    FIsMapped: Boolean;
    {$IFDEF WINDOWS}
    FMappingHandle: THandle;
    {$ENDIF}
    function GetMemory: Pointer;
  public
    constructor Create;
    destructor Destroy; override;
    
    // 映射操作
    procedure MapFile(aFile: TfsFile; aOffset: Int64 = 0; aSize: Int64 = 0; 
                     aProtection: TMemoryProtection = mpReadOnly; 
                     aFlags: TMemoryMapFlags = [mmfShared]);
    procedure MapAnonymous(aSize: Int64; aProtection: TMemoryProtection = mpReadWrite);
    procedure Unmap;
    
    // 同步操作
    procedure Sync(aAsync: Boolean = False);
    procedure SyncRange(aOffset: Int64; aSize: Int64; aAsync: Boolean = False);
    
    // 属性
    property Memory: Pointer read GetMemory;
    property Size: Int64 read FSize;
    property IsMapped: Boolean read FIsMapped;
    property Protection: TMemoryProtection read FProtection;
  end;

// 便利函数
function MapFileToMemory(const aPath: string; aProtection: TMemoryProtection = mpReadOnly): TMemoryMappedFile;
function CreateAnonymousMapping(aSize: Int64; aProtection: TMemoryProtection = mpReadWrite): TMemoryMappedFile;

implementation

{$IFDEF WINDOWS}
uses Windows;
{$ELSE}
uses BaseUnix, Unix, syscall;

const
  // msync 标志 (如果 syscall 单元未定义)
  {$IF NOT DECLARED(MS_ASYNC)}
  MS_ASYNC = 1;
  MS_SYNC  = 4;
  MS_INVALIDATE = 2;
  {$ENDIF}

// msync wrapper (如果 syscall 单元未提供)
{$IF NOT DECLARED(fpmsync)}
function fpmsync(aAddr: Pointer; aLen: size_t; aFlags: cint): cint;
begin
  Result := do_syscall(syscall_nr_msync, TSysParam(aAddr), TSysParam(aLen), TSysParam(aFlags));
end;
{$ENDIF}
{$ENDIF}

{ TMemoryMappedFile }

constructor TMemoryMappedFile.Create;
begin
  inherited Create;
  FFile := INVALID_HANDLE_VALUE;
  FMappedMemory := nil;
  FUserMemory := nil;
  FSize := 0;
  FActualMappedSize := 0;
  FOffsetAdjustment := 0;
  FIsMapped := False;
  {$IFDEF WINDOWS}
  FMappingHandle := INVALID_HANDLE_VALUE;
  {$ENDIF}
end;

function TMemoryMappedFile.GetMemory: Pointer;
begin
  // 返回用户期望的地址（已调整偏移）
  Result := FUserMemory;
end;

destructor TMemoryMappedFile.Destroy;
begin
  if FIsMapped then
    Unmap;
  inherited Destroy;
end;

procedure TMemoryMappedFile.MapFile(aFile: TfsFile; aOffset: Int64; aSize: Int64; 
                                   aProtection: TMemoryProtection; aFlags: TMemoryMapFlags);
{$IFDEF WINDOWS}
var
  LFileSize: Int64;
  LStat: TfsStat;
  LProtect, LAccess: DWORD;
  LOffsetLow, LOffsetHigh: DWORD;
begin
  if FIsMapped then
    raise EFsError.Create(FS_ERROR_INVALID_PARAMETER, 'Already mapped', 0);

  FFile := aFile;
  FProtection := aProtection;
  FFlags := aFlags;

  // 获取文件大小
  CheckFsResult(fs_fstat(aFile, LStat), 'get file size for mapping');
  LFileSize := LStat.Size;

  if aSize = 0 then
    FSize := LFileSize - aOffset
  else
    FSize := aSize;

  if (aOffset + FSize) > LFileSize then
    raise EFsError.Create(FS_ERROR_INVALID_PARAMETER, 'Mapping size exceeds file size', 0);

  // 设置保护模式
  case aProtection of
    mpReadOnly: begin
      LProtect := PAGE_READONLY;
      LAccess := FILE_MAP_READ;
    end;
    mpReadWrite: begin
      LProtect := PAGE_READWRITE;
      LAccess := FILE_MAP_WRITE;
    end;
    mpExecute: begin
      LProtect := PAGE_EXECUTE_READ;
      LAccess := FILE_MAP_READ; // FILE_MAP_EXECUTE不是标准常量
    end;
  end;

  // 创建文件映射对象
  FMappingHandle := CreateFileMappingW(aFile, nil, LProtect, 0, 0, nil);
  if FMappingHandle = 0 then
    raise EFsError.Create(GetLastFsError(), 'Failed to create file mapping', GetLastError());

  // 映射视图
  LOffsetLow := DWORD(aOffset and $FFFFFFFF);
  LOffsetHigh := DWORD(aOffset shr 32);
  
  FMappedMemory := MapViewOfFile(FMappingHandle, LAccess, LOffsetHigh, LOffsetLow, FSize);
  if FMappedMemory = nil then
  begin
    CloseHandle(FMappingHandle);
    FMappingHandle := INVALID_HANDLE_VALUE;
    raise EFsError.Create(GetLastFsError(), 'Failed to map view of file', GetLastError());
  end;

  // Windows MapViewOfFile 无需页对齐，直接设置
  FUserMemory := FMappedMemory;
  FActualMappedSize := FSize;
  FOffsetAdjustment := 0;
  FIsMapped := True;
end;
{$ELSE}
var
  LFileSize: Int64;
  LStat: TfsStat;
  LProt, LFlags: Integer;
  LPageSize: PtrUInt;
  LAlignedOffset: Int64;
begin
  if FIsMapped then
    raise EFsError.Create(FS_ERROR_INVALID_PARAMETER, 'Already mapped', 0);

  FFile := aFile;
  FProtection := aProtection;
  FFlags := aFlags;

  // 获取文件大小
  CheckFsResult(fs_fstat(aFile, LStat), 'get file size for mapping');
  LFileSize := LStat.Size;

  if aSize = 0 then
    FSize := LFileSize - aOffset
  else
    FSize := aSize;

  if (aOffset + FSize) > LFileSize then
    raise EFsError.Create(FS_ERROR_INVALID_PARAMETER, 'Mapping size exceeds file size', 0);

  // 设置保护模式
  LProt := PROT_NONE;
  case aProtection of
    mpReadOnly: LProt := PROT_READ;
    mpReadWrite: LProt := PROT_READ or PROT_WRITE;
    mpExecute: LProt := PROT_READ or PROT_EXEC;
  end;

  // 设置映射标志
  LFlags := 0;
  if mmfShared in aFlags then
    LFlags := LFlags or MAP_SHARED
  else
    LFlags := LFlags or MAP_PRIVATE;

  // ✅ 修复: Linux mmap 要求 offset 必须是页大小的倍数
  // 使用标准页大小 4096（适用于 x86/x86_64/ARM64 等）
  LPageSize := 4096;

  // 将 offset 向下对齐到页边界
  LAlignedOffset := aOffset and (not Int64(LPageSize - 1));
  FOffsetAdjustment := PtrUInt(aOffset - LAlignedOffset);
  FActualMappedSize := FSize + Int64(FOffsetAdjustment);

  // 执行映射（使用对齐后的偏移和扩展后的大小）
  FMappedMemory := fpmmap(nil, FActualMappedSize, LProt, LFlags, aFile, LAlignedOffset);
  if FMappedMemory = MAP_FAILED then
    raise EFsError.Create(GetLastFsError(), 'Failed to map file', fpgeterrno);

  // 计算用户期望的地址（页内偏移）
  FUserMemory := Pointer(PtrUInt(FMappedMemory) + FOffsetAdjustment);
  FIsMapped := True;
end;
{$ENDIF}

procedure TMemoryMappedFile.MapAnonymous(aSize: Int64; aProtection: TMemoryProtection);
{$IFDEF WINDOWS}
var
  LProtect: DWORD;
begin
  if FIsMapped then
    raise EFsError.Create(FS_ERROR_INVALID_PARAMETER, 'Already mapped', 0);

  FSize := aSize;
  FProtection := aProtection;
  FFlags := [mmfAnonymous, mmfPrivate];

  // 设置保护模式
  case aProtection of
    mpReadOnly: LProtect := PAGE_READONLY;
    mpReadWrite: LProtect := PAGE_READWRITE;
    mpExecute: LProtect := PAGE_EXECUTE_READ;
  end;

  // 创建匿名映射
  FMappingHandle := CreateFileMappingW(INVALID_HANDLE_VALUE, nil, LProtect, 
                                      DWORD(aSize shr 32), DWORD(aSize and $FFFFFFFF), nil);
  if FMappingHandle = 0 then
    raise EFsError.Create(GetLastFsError(), 'Failed to create anonymous mapping', GetLastError());

  FMappedMemory := MapViewOfFile(FMappingHandle, FILE_MAP_WRITE, 0, 0, aSize);
  if FMappedMemory = nil then
  begin
    CloseHandle(FMappingHandle);
    FMappingHandle := INVALID_HANDLE_VALUE;
    raise EFsError.Create(GetLastFsError(), 'Failed to map anonymous memory', GetLastError());
  end;

  // 匿名映射无偏移调整
  FUserMemory := FMappedMemory;
  FActualMappedSize := FSize;
  FOffsetAdjustment := 0;
  FIsMapped := True;
end;
{$ELSE}
var
  LProt, LFlags: Integer;
begin
  if FIsMapped then
    raise EFsError.Create(FS_ERROR_INVALID_PARAMETER, 'Already mapped', 0);

  FSize := aSize;
  FProtection := aProtection;
  FFlags := [mmfAnonymous, mmfPrivate];

  // 设置保护模式
  case aProtection of
    mpReadOnly: LProt := PROT_READ;
    mpReadWrite: LProt := PROT_READ or PROT_WRITE;
    mpExecute: LProt := PROT_READ or PROT_EXEC;
  end;

  // 创建匿名映射
  LFlags := MAP_PRIVATE or MAP_ANONYMOUS;
  FMappedMemory := fpmmap(nil, aSize, LProt, LFlags, -1, 0);
  if FMappedMemory = MAP_FAILED then
    raise EFsError.Create(GetLastFsError(), 'Failed to create anonymous mapping', fpgeterrno);

  // 匿名映射无偏移调整
  FUserMemory := FMappedMemory;
  FActualMappedSize := FSize;
  FOffsetAdjustment := 0;
  FIsMapped := True;
end;
{$ENDIF}

procedure TMemoryMappedFile.Unmap;
begin
  if not FIsMapped then
    Exit;

{$IFDEF WINDOWS}
  if FMappedMemory <> nil then
  begin
    UnmapViewOfFile(FMappedMemory);
    FMappedMemory := nil;
  end;

  if FMappingHandle <> INVALID_HANDLE_VALUE then
  begin
    CloseHandle(FMappingHandle);
    FMappingHandle := INVALID_HANDLE_VALUE;
  end;
{$ELSE}
  // ✅ 修复: 使用实际映射大小（含对齐补偿）进行 unmap
  if FMappedMemory <> nil then
  begin
    fpmunmap(FMappedMemory, FActualMappedSize);
    FMappedMemory := nil;
  end;
{$ENDIF}

  FUserMemory := nil;
  FIsMapped := False;
  FSize := 0;
  FActualMappedSize := 0;
  FOffsetAdjustment := 0;
end;

procedure TMemoryMappedFile.Sync(aAsync: Boolean);
{$IFNDEF WINDOWS}
var
  LFlags: Integer;
{$ENDIF}
begin
  if not FIsMapped then
    raise EFsError.Create(FS_ERROR_INVALID_PARAMETER, 'Not mapped', 0);

{$IFDEF WINDOWS}
  if not FlushViewOfFile(FMappedMemory, FSize) then
    raise EFsError.Create(GetLastFsError(), 'Failed to sync memory mapping', GetLastError());
{$ELSE}
  if aAsync then
    LFlags := MS_ASYNC
  else
    LFlags := MS_SYNC;

  if fpmsync(FMappedMemory, FSize, LFlags) <> 0 then
    raise EFsError.Create(GetLastFsError(), 'Failed to sync memory mapping', fpgeterrno);
{$ENDIF}
end;

procedure TMemoryMappedFile.SyncRange(aOffset: Int64; aSize: Int64; aAsync: Boolean);
{$IFDEF WINDOWS}
var
  LPtr: Pointer;
begin
  if not FIsMapped then
    raise EFsError.Create(FS_ERROR_INVALID_PARAMETER, 'Not mapped', 0);

  LPtr := Pointer(PtrUInt(FMappedMemory) + PtrUInt(aOffset));
  if not FlushViewOfFile(LPtr, aSize) then
    raise EFsError.Create(GetLastFsError(), 'Failed to sync memory range', GetLastError());
end;
{$ELSE}
var
  LPtr: Pointer;
  LFlags: Integer;
begin
  if not FIsMapped then
    raise EFsError.Create(FS_ERROR_INVALID_PARAMETER, 'Not mapped', 0);

  LPtr := Pointer(PtrUInt(FMappedMemory) + PtrUInt(aOffset));
  
  if aAsync then
    LFlags := MS_ASYNC
  else
    LFlags := MS_SYNC;
    
  if fpmsync(LPtr, aSize, LFlags) <> 0 then
    raise EFsError.Create(GetLastFsError(), 'Failed to sync memory range', fpgeterrno);
end;
{$ENDIF}

// 便利函数实现

function MapFileToMemory(const aPath: string; aProtection: TMemoryProtection): TMemoryMappedFile;
var
  LFile: TfsFile;
  LFlags: Integer;
begin
  Result := TMemoryMappedFile.Create;
  try
    // 根据保护模式选择打开标志
    case aProtection of
      mpReadOnly: LFlags := O_RDONLY;
      mpReadWrite: LFlags := O_RDWR;
      mpExecute: LFlags := O_RDONLY;
    end;
    
    LFile := fs_open(aPath, LFlags, 0);
    if not IsValidHandle(LFile) then
    begin
      Result.Free;
      raise EFsError.Create(GetLastFsError(), 'Failed to open file for mapping: ' + aPath, 0);
    end;
    
    Result.MapFile(LFile, 0, 0, aProtection, [mmfShared]);
  except
    Result.Free;
    raise;
  end;
end;

function CreateAnonymousMapping(aSize: Int64; aProtection: TMemoryProtection): TMemoryMappedFile;
begin
  Result := TMemoryMappedFile.Create;
  try
    Result.MapAnonymous(aSize, aProtection);
  except
    Result.Free;
    raise;
  end;
end;

end.
