{
```text
   ______   ______     ______   ______     ______   ______
  /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \
  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \
   \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\
    \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/  Studio

```
# fafafa.core.mem.memoryMap

## Abstract 摘要

Cross-platform memory mapped file implementation for efficient large file processing.
跨平台内存映射文件实现，用于高效的大文件处理。

## Declaration 声明

For forwarding or using it for your own project, please retain the copyright notice of this project. Thank you.
转发或者用于自己项目请保留本项目的版权声明,谢谢.

Author:    fafafaStudio
Contact:   dtamade@gmail.com | QQ Group: 685403987 | QQ:179033731
Copyright: (c) 2025 fafafaStudio. All rights reserved.
}

unit fafafa.core.mem.memoryMap;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes,
  {$IFDEF WINDOWS}
  Windows,
  {$ELSE}
  BaseUnix, Unix,
  {$ENDIF}
  fafafa.core.base,
  fafafa.core.mem.allocator;

type
  {**
   * TMemoryMapAccess
   *
   * @desc 内存映射访问模式
   *       Memory map access mode
   *}
  TMemoryMapAccess = (
    mmaRead,      // 只读 Read-only
    mmaWrite,     // 只写 Write-only  
    mmaReadWrite, // 读写 Read-write
    mmaCopyOnWrite // 写时复制 Copy-on-write
  );

  {**
   * TMemoryMapFlags
   *
   * @desc 内存映射标志
   *       Memory map flags
   *}
  TMemoryMapFlags = set of (
    mmfShared,    // 共享映射 Shared mapping
    mmfPrivate,   // 私有映射 Private mapping
    mmfAnonymous, // 匿名映射 Anonymous mapping
    mmfFixed,     // 固定地址 Fixed address
    mmfLocked     // 锁定内存 Locked memory
  );

  {**
   * TMemoryMap
   *
   * @desc 跨平台内存映射文件类
   *       Cross-platform memory mapped file class
   *}
  TMemoryMap = class
  private
    FFileName: string;
    FFileHandle: THandle;
    FMapHandle: THandle;
    FBaseAddress: Pointer;
    FSize: UInt64;
    FAccess: TMemoryMapAccess;
    FFlags: TMemoryMapFlags;
    FIsOpen: Boolean;
    FIsAnonymous: Boolean;

    {$IFDEF WINDOWS}
    function GetWindowsProtection: DWORD;
    function GetWindowsAccess: DWORD;
    {$ELSE}
    function GetUnixProtection: Integer;
    function GetUnixFlags: Integer;
    {$ENDIF}

    procedure CloseMapping;
    procedure CloseFile;

  public
    {**
     * Create
     *
     * @desc 创建内存映射对象
     *       Create memory map object
     *}
    constructor Create;

    {**
     * Destroy
     *
     * @desc 销毁内存映射对象
     *       Destroy memory map object
     *}
    destructor Destroy; override;

    {**
     * OpenFile
     *
     * @desc 打开文件进行内存映射
     *       Open file for memory mapping
     *
     * @param aFileName 文件名 File name
     * @param aAccess 访问模式 Access mode
     * @param aFlags 映射标志 Mapping flags
     * @param aSize 映射大小 Mapping size (0 = entire file)
     * @param aOffset 文件偏移 File offset
     * @return 是否成功 Success flag
     *}
    function OpenFile(const aFileName: string; aAccess: TMemoryMapAccess = mmaReadWrite;
      aFlags: TMemoryMapFlags = [mmfShared]; aSize: UInt64 = 0; aOffset: UInt64 = 0): Boolean;

    {**
     * CreateAnonymous
     *
     * @desc 创建匿名内存映射
     *       Create anonymous memory mapping
     *
     * @param aSize 映射大小 Mapping size
     * @param aAccess 访问模式 Access mode
     * @param aFlags 映射标志 Mapping flags
     * @return 是否成功 Success flag
     *}
    function CreateAnonymous(aSize: UInt64; aAccess: TMemoryMapAccess = mmaReadWrite;
      aFlags: TMemoryMapFlags = [mmfPrivate]): Boolean;

    {**
     * Close
     *
     * @desc 关闭内存映射
     *       Close memory mapping
     *}
    procedure Close;

    {**
     * Flush
     *
     * @desc 刷新内存映射到磁盘
     *       Flush memory mapping to disk
     *
     * @param aOffset 刷新偏移 Flush offset
     * @param aSize 刷新大小 Flush size (0 = entire mapping)
     * @return 是否成功 Success flag
     *}
    function Flush(aOffset: UInt64 = 0; aSize: UInt64 = 0): Boolean;
    function FlushRange(aOffset: UInt64; aSize: UInt64): Boolean; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

    {**
     * Resize
     *
     * @desc 调整映射大小
     *       Resize mapping
     *
     * @param aNewSize 新大小 New size
     * @return 是否成功 Success flag
     *}
    function Resize(aNewSize: UInt64): Boolean;

    {**
     * Lock
     *
     * @desc 锁定内存页面
     *       Lock memory pages
     *
     * @param aOffset 锁定偏移 Lock offset
     * @param aSize 锁定大小 Lock size (0 = entire mapping)
     * @return 是否成功 Success flag
     *}
    function Lock(aOffset: UInt64 = 0; aSize: UInt64 = 0): Boolean;

    {**
     * Unlock
     *
     * @desc 解锁内存页面
     *       Unlock memory pages
     *
     * @param aOffset 解锁偏移 Unlock offset
     * @param aSize 解锁大小 Unlock size (0 = entire mapping)
     * @return 是否成功 Success flag
     *}
    function Unlock(aOffset: UInt64 = 0; aSize: UInt64 = 0): Boolean;

    {**
     * WriteLPBytes / ReadLPBytes
     *
     * @desc 写入/读取 4 字节长度前缀的原始字节序列（length-prefixed bytes）
     *       Write/Read 4-byte length-prefixed raw bytes
     *
     * @param aOffset 偏移 Offset
     * @param aBuf    字节序列 Raw bytes (UTF-8 or any)
     * @return 是否成功 Success flag（边界不足返回 False）
     *}
    function WriteLPBytes(aOffset: UInt64; const aBuf: RawByteString): Boolean;
    function ReadLPBytes(aOffset: UInt64; out aBuf: RawByteString): Boolean;
    function WriteLPUTF8(aOffset: UInt64; const S: UnicodeString): Boolean;
    function ReadLPUTF8(aOffset: UInt64; out S: UTF8String): Boolean;

    // 属性 Properties
    property FileName: string read FFileName;
    property BaseAddress: Pointer read FBaseAddress;
    property Size: UInt64 read FSize;
    property Access: TMemoryMapAccess read FAccess;
    property Flags: TMemoryMapFlags read FFlags;
    property IsOpen: Boolean read FIsOpen;
    property IsAnonymous: Boolean read FIsAnonymous;

    // 状态查询 Status queries
    function IsValid: Boolean; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
    function GetPointer(aOffset: UInt64 = 0): Pointer; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
  end;

  {**
   * TSharedMemory
   *
   * @desc 跨进程共享内存类
   *       Cross-process shared memory class
   *}
  TSharedMemory = class
  private
    FName: string;
    FSize: UInt64;
    FMemoryMap: TMemoryMap;
    FIsCreator: Boolean;

  public
    {**
     * Create
     *
     * @desc 创建共享内存对象
     *       Create shared memory object
     *}
    constructor Create;

    {**
     * Destroy
     *
     * @desc 销毁共享内存对象
     *       Destroy shared memory object
     *}
    destructor Destroy; override;

    {**
     * CreateShared
     *
     * @desc 创建或打开共享内存
     *       Create or open shared memory
     *
     * @param aName 共享内存名称 Shared memory name
     * @param aSize 大小 Size
     * @param aAccess 访问模式 Access mode
     * @return 是否成功 Success flag
     *}
    function CreateShared(const aName: string; aSize: UInt64;
      aAccess: TMemoryMapAccess = mmaReadWrite): Boolean;

    {**
     * OpenShared
     *
     * @desc 打开现有共享内存
     *       Open existing shared memory
     *
     * @param aName 共享内存名称 Shared memory name
     * @param aAccess 访问模式 Access mode
     * @return 是否成功 Success flag
     *}
    function OpenShared(const aName: string; aAccess: TMemoryMapAccess = mmaReadWrite): Boolean;

    {**
     * Close
     *
     * @desc 关闭共享内存
     *       Close shared memory
     *}
    procedure Close;

    // 状态查询 Status queries
    function IsValid: Boolean; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
    function GetPointer(aOffset: UInt64 = 0): Pointer; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
    function GetBaseAddress: Pointer; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

    // 便捷 LPBytes 读写
    function WriteLPBytes(aOffset: UInt64; const aBuf: RawByteString): Boolean; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
    function ReadLPBytes(aOffset: UInt64; out aBuf: RawByteString): Boolean; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

    // UTF-8 字符串便捷方法（基于 LPBytes）
    function WriteLPUTF8(aOffset: UInt64; const S: UnicodeString): Boolean;
    function ReadLPUTF8(aOffset: UInt64; out S: UTF8String): Boolean;

    // 刷新便捷方法（转发到内部 MemoryMap）
    function Flush(aOffset: UInt64 = 0; aSize: UInt64 = 0): Boolean; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
    function FlushRange(aOffset: UInt64; aSize: UInt64): Boolean; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

    // 属性 Properties
    property Name: string read FName;
    property Size: UInt64 read FSize;
    property BaseAddress: Pointer read GetBaseAddress;
    property IsCreator: Boolean read FIsCreator;
  end;

implementation

{ TMemoryMap }

constructor TMemoryMap.Create;
begin
  inherited Create;
  FFileName := '';
  FFileHandle := INVALID_HANDLE_VALUE;
  FMapHandle := 0;
  FBaseAddress := nil;
  FSize := 0;
  FAccess := mmaReadWrite;
  FFlags := [mmfShared];
  FIsOpen := False;
  FIsAnonymous := False;
end;

destructor TMemoryMap.Destroy;
begin
  Close;
  inherited Destroy;
end;

{$IFDEF WINDOWS}
{$PUSH}
{$WARN 6018 OFF}
function TMemoryMap.GetWindowsProtection: DWORD;
begin
  case FAccess of
    mmaRead: Result := PAGE_READONLY;
    mmaWrite: Result := PAGE_READWRITE; // Windows需要读权限才能写
    mmaReadWrite: Result := PAGE_READWRITE;
    mmaCopyOnWrite: Result := PAGE_WRITECOPY;
  else
    Result := PAGE_READONLY;
  end;
end;
{$POP}

{$PUSH}
{$WARN 6018 OFF}
function TMemoryMap.GetWindowsAccess: DWORD;
begin
  case FAccess of
    mmaRead: Result := FILE_MAP_READ;
    mmaWrite: Result := FILE_MAP_WRITE;
    mmaReadWrite: Result := FILE_MAP_READ or FILE_MAP_WRITE;
    mmaCopyOnWrite: Result := FILE_MAP_COPY;
  else
    Result := FILE_MAP_READ;
  end;
end;
{$POP}
{$ELSE}
function TMemoryMap.GetUnixProtection: Integer;
begin
  Result := PROT_NONE;

  case FAccess of
    mmaRead: Result := PROT_READ;
    mmaWrite: Result := PROT_WRITE;
    mmaReadWrite: Result := PROT_READ or PROT_WRITE;
    mmaCopyOnWrite: Result := PROT_READ or PROT_WRITE;
  end;
end;

function TMemoryMap.GetUnixFlags: Integer;
begin
  Result := 0;

  if mmfShared in FFlags then
    Result := Result or MAP_SHARED
  else if mmfPrivate in FFlags then
    Result := Result or MAP_PRIVATE;

  if mmfAnonymous in FFlags then
    Result := Result or MAP_ANONYMOUS;

  if mmfFixed in FFlags then
    Result := Result or MAP_FIXED;

  {$IFDEF LINUX}
  if mmfLocked in FFlags then
    Result := Result or MAP_LOCKED;
  {$ENDIF}
end;
{$ENDIF}

procedure TMemoryMap.CloseMapping;
begin
  if FBaseAddress <> nil then
  begin
    {$IFDEF WINDOWS}
    UnmapViewOfFile(FBaseAddress);
    {$ELSE}
    FpMunmap(FBaseAddress, FSize);
    {$ENDIF}
    FBaseAddress := nil;
  end;

  if FMapHandle <> 0 then
  begin
    {$IFDEF WINDOWS}
    CloseHandle(FMapHandle);
    {$ENDIF}
    FMapHandle := 0;
  end;
end;

procedure TMemoryMap.CloseFile;
begin
  if (FFileHandle <> INVALID_HANDLE_VALUE) and not FIsAnonymous then
  begin
    {$IFDEF WINDOWS}
    CloseHandle(FFileHandle);
    {$ELSE}
    FpClose(FFileHandle);
    {$ENDIF}
    FFileHandle := INVALID_HANDLE_VALUE;
  end;
end;

{$PUSH}
{$WARN 6018 OFF}
function TMemoryMap.OpenFile(const aFileName: string; aAccess: TMemoryMapAccess;
  aFlags: TMemoryMapFlags; aSize: UInt64; aOffset: UInt64): Boolean;
var
  LFileSize: UInt64;
  {$IFDEF WINDOWS}
  LDesiredAccess: DWORD;
  LCreationDisposition: DWORD;
  LFileSizeHigh, LFileSizeLow: DWORD;
  NewPtrHigh, NewPtrLow: DWORD;
  {$ELSE}
  LOpenFlags: Integer;
  LStatBuf: TStat;
  {$ENDIF}
begin
  Result := False;

  // 关闭现有映射
  Close;

  FFileName := aFileName;
  FAccess := aAccess;
  FFlags := aFlags;
  FIsAnonymous := False;

  {$IFDEF WINDOWS}
  // Windows实现
  case aAccess of
    mmaRead: LDesiredAccess := GENERIC_READ;
    mmaWrite: LDesiredAccess := GENERIC_WRITE;
    mmaReadWrite: LDesiredAccess := GENERIC_READ or GENERIC_WRITE;
    mmaCopyOnWrite: LDesiredAccess := GENERIC_READ;
  end;

  if FileExists(aFileName) then
    LCreationDisposition := OPEN_EXISTING
  else
    LCreationDisposition := CREATE_ALWAYS;

  FFileHandle := CreateFile(PChar(aFileName), LDesiredAccess, FILE_SHARE_READ,
    nil, LCreationDisposition, FILE_ATTRIBUTE_NORMAL, 0);

  if FFileHandle = INVALID_HANDLE_VALUE then Exit;

  // 获取文件大小
  LFileSizeLow := GetFileSize(FFileHandle, @LFileSizeHigh);
  if (LFileSizeLow = INVALID_FILE_SIZE) and (GetLastError <> NO_ERROR) then
  begin
    CloseFile;
    Exit;
  end;

  LFileSize := (UInt64(LFileSizeHigh) shl 32) or LFileSizeLow;

  // 确定映射大小
  if aSize = 0 then
    FSize := LFileSize
  else
    FSize := aSize;

  if FSize = 0 then
  begin
    CloseFile;
    Exit;
  end;

  // 如果文件太小，先扩展它以保证映射长度可写
  if LFileSize < FSize then
  begin
    // 扩展文件：FPC 3.3 兼容写法，避免内联 var 声明
    {$IFDEF WINDOWS}
    NewPtrHigh := Hi(FSize);
    NewPtrLow := Lo(FSize);
    if (SetFilePointer(FFileHandle, Integer(NewPtrLow), @NewPtrHigh, FILE_BEGIN) = INVALID_SET_FILE_POINTER)
       and (GetLastError() <> NO_ERROR) then
    begin
      CloseFile;
      Exit;
    end;
    if not SetEndOfFile(FFileHandle) then
    begin
      CloseFile;
      Exit;
    end;
    // 复位到文件开头
    NewPtrHigh := 0;
    NewPtrLow := 0;
    SetFilePointer(FFileHandle, 0, @NewPtrHigh, FILE_BEGIN);
    {$ELSE}
    // 非 Windows 平台已在下方统一处理
    {$ENDIF}
  end;

  // 创建文件映射
  FMapHandle := CreateFileMapping(FFileHandle, nil, GetWindowsProtection,
    Hi(FSize), Lo(FSize), nil);

  if FMapHandle = 0 then
  begin
    CloseFile;
    Exit;
  end;

  // 映射视图
  FBaseAddress := MapViewOfFile(FMapHandle, GetWindowsAccess,
    Hi(aOffset), Lo(aOffset), FSize);

  if FBaseAddress = nil then
  begin
    CloseMapping;
    CloseFile;
    Exit;
  end;

  {$ELSE}
  // Unix/Linux实现
  case aAccess of
    mmaRead: LOpenFlags := O_RDONLY;
    mmaWrite: LOpenFlags := O_WRONLY;
    mmaReadWrite: LOpenFlags := O_RDWR;
    mmaCopyOnWrite: LOpenFlags := O_RDONLY;
  end;

  if not FileExists(aFileName) then
    LOpenFlags := LOpenFlags or O_CREAT;

  FFileHandle := FpOpen(aFileName, LOpenFlags, &666);
  if FFileHandle = -1 then Exit;

  // 获取文件大小
  if FpFStat(FFileHandle, LStatBuf) <> 0 then
  begin
    CloseFile;
    Exit;
  end;

  LFileSize := LStatBuf.st_size;

  // 确定映射大小
  if aSize = 0 then
    FSize := LFileSize
  else
    FSize := aSize;

  if FSize = 0 then
  begin
    CloseFile;
    Exit;
  end;

  // 如果文件太小，扩展它
  if LFileSize < FSize then
  begin
    if FpFTruncate(FFileHandle, FSize) <> 0 then
    begin
      CloseFile;
      Exit;
    end;
  end;

  // 创建内存映射
  FBaseAddress := FpMmap(nil, FSize, GetUnixProtection, GetUnixFlags, FFileHandle, aOffset);
  if FBaseAddress = MAP_FAILED then
  begin
    FBaseAddress := nil;
    CloseFile;
    Exit;
  end;
  {$ENDIF}

  FIsOpen := True;
  Result := True;
end;

{$PUSH}
{$WARN 6018 OFF}
function TMemoryMap.CreateAnonymous(aSize: UInt64; aAccess: TMemoryMapAccess;
  aFlags: TMemoryMapFlags): Boolean;
begin
  Result := False;

  // 关闭现有映射
  Close;

  FFileName := '';
  FAccess := aAccess;
  FFlags := aFlags + [mmfAnonymous];
  FSize := aSize;
  FIsAnonymous := True;

  if FSize = 0 then Exit;

  {$IFDEF WINDOWS}
  // Windows匿名映射
  FMapHandle := CreateFileMapping(INVALID_HANDLE_VALUE, nil, GetWindowsProtection,
    Hi(FSize), Lo(FSize), nil);

  if FMapHandle = 0 then Exit;

  FBaseAddress := MapViewOfFile(FMapHandle, GetWindowsAccess, 0, 0, FSize);
  if FBaseAddress = nil then
  begin
    CloseMapping;
    Exit;
  end;

  {$ELSE}
  // Unix/Linux匿名映射
  FBaseAddress := FpMmap(nil, FSize, GetUnixProtection,
    GetUnixFlags or MAP_ANONYMOUS, -1, 0);
  if FBaseAddress = MAP_FAILED then
  begin
    FBaseAddress := nil;
    Exit;
  end;
  {$ENDIF}

  FIsOpen := True;
  Result := True;
end;

procedure TMemoryMap.Close;
begin
  if FIsOpen then
  begin
    CloseMapping;
    CloseFile;
    FIsOpen := False;
    FIsAnonymous := False;
    FFileName := '';
    FSize := 0;
  end;
end;

function TMemoryMap.Flush(aOffset: UInt64; aSize: UInt64): Boolean;
var
  LFlushSize: UInt64;
  LFlushPtr: Pointer;
begin
  Result := False;
  if not IsValid then Exit;

  if aSize = 0 then
    LFlushSize := FSize - aOffset
  else
    LFlushSize := aSize;

  if aOffset + LFlushSize > FSize then Exit;

  LFlushPtr := Pointer(PByte(FBaseAddress) + aOffset);

  {$IFDEF WINDOWS}
  Result := FlushViewOfFile(LFlushPtr, LFlushSize);
  {$ELSE}
  Result := FpMsync(LFlushPtr, LFlushSize, MS_SYNC) = 0;
  {$ENDIF}
end;

function TMemoryMap.FlushRange(aOffset: UInt64; aSize: UInt64): Boolean;
begin
  if aSize = 0 then Exit(False);
  Result := Flush(aOffset, aSize);
end;

{$PUSH}
{$WARN 6018 OFF}
function TMemoryMap.Resize(aNewSize: UInt64): Boolean;
var
  LOldFileName: string;
  LOldAccess: TMemoryMapAccess;
  LOldFlags: TMemoryMapFlags;
  {$IFDEF WINDOWS}
  NewPtrHigh, NewPtrLow: DWORD;
  {$ENDIF}
begin
  Result := False;
  if not FIsOpen or FIsAnonymous then Exit;

  // 对于文件映射，需要重新映射
  // 这是一个简化实现，实际可能需要更复杂的处理
  if aNewSize = FSize then
  begin
    Result := True;
    Exit;
  end;

  // 保存当前状态
  LOldFileName := FFileName;
  LOldAccess := FAccess;
  LOldFlags := FFlags;

  // 关闭当前映射
  Close;

  // 重新打开（Windows 下确保文件先扩容）
  {$IFDEF WINDOWS}
  // 打开文件句柄，仅用于扩容（避免内联 var 写法）
  FFileHandle := CreateFile(PChar(LOldFileName), GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ,
    nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  if FFileHandle <> INVALID_HANDLE_VALUE then
  begin
    NewPtrHigh := Hi(aNewSize);
    NewPtrLow := Lo(aNewSize);
    if (SetFilePointer(FFileHandle, Integer(NewPtrLow), @NewPtrHigh, FILE_BEGIN) <> INVALID_SET_FILE_POINTER)
       or (GetLastError() = NO_ERROR) then
    begin
      SetEndOfFile(FFileHandle);
    end;
    CloseFile;
  end;
  {$ENDIF}
  Result := OpenFile(LOldFileName, LOldAccess, LOldFlags, aNewSize);
end;

{$PUSH}
{$WARN 6018 OFF}
function TMemoryMap.Lock(aOffset: UInt64; aSize: UInt64): Boolean;
var
  LLockSize: UInt64;
  LLockPtr: Pointer;
begin
  Result := False;
  if not IsValid then Exit;

  if aSize = 0 then
    LLockSize := FSize - aOffset
  else
    LLockSize := aSize;

  if aOffset + LLockSize > FSize then Exit;

  LLockPtr := Pointer(PByte(FBaseAddress) + aOffset);

  {$IFDEF WINDOWS}
  Result := VirtualLock(LLockPtr, LLockSize);
  {$ELSE}
  Result := FpMLock(LLockPtr, LLockSize) = 0;
  {$ENDIF}
end;
{$POP}

{$PUSH}
{$WARN 6018 OFF}
function TMemoryMap.Unlock(aOffset: UInt64; aSize: UInt64): Boolean;
var
  LUnlockSize: UInt64;
  LUnlockPtr: Pointer;
begin
  Result := False;
  if not IsValid then Exit;

  if aSize = 0 then
    LUnlockSize := FSize - aOffset
  else
    LUnlockSize := aSize;

  if aOffset + LUnlockSize > FSize then Exit;

  LUnlockPtr := Pointer(PByte(FBaseAddress) + aOffset);

  {$IFDEF WINDOWS}
  Result := VirtualUnlock(LUnlockPtr, LUnlockSize);
  {$ELSE}
  Result := FpMUnlock(LUnlockPtr, LUnlockSize) = 0;
  {$ENDIF}
end;

function TMemoryMap.IsValid: Boolean;
begin
  Result := FIsOpen and (FBaseAddress <> nil) and (FSize > 0);
end;

function TMemoryMap.GetPointer(aOffset: UInt64): Pointer;
begin
  if IsValid and (aOffset < FSize) then
    Result := Pointer(PByte(FBaseAddress) + aOffset)
  else
    Result := nil;
end;

function TMemoryMap.WriteLPBytes(aOffset: UInt64; const aBuf: RawByteString): Boolean;
var
  P: PByte;
  L: UInt32;
  Need: UInt64;
begin
  Result := False;
  if not IsValid then Exit;
  // 只读映射不允许写入，避免触发访问冲突
  if FAccess = mmaRead then Exit;
  L := Length(aBuf);
  Need := SizeOf(L) + UInt64(L);
  if (aOffset + Need) > FSize then Exit;
  P := PByte(PByte(FBaseAddress) + aOffset);
  Move(L, P^, SizeOf(L));
  Inc(P, SizeOf(L));
  if L > 0 then Move(aBuf[1], P^, L);
  Result := True;
end;

function TMemoryMap.ReadLPBytes(aOffset: UInt64; out aBuf: RawByteString): Boolean;
var
  P: PByte;
  L: UInt32;
  Need: UInt64;
{$PUSH}
{$WARN 5057 OFF} // L/Need 后续会被 Move/计算赋值，抑制“似乎未初始化”
{$POP}
begin
  Result := False;
  aBuf := '';
  if not IsValid then Exit;
  if (aOffset + SizeOf(L)) > FSize then Exit;
  P := PByte(PByte(FBaseAddress) + aOffset);
  Move(P^, L, SizeOf(L));
  Need := SizeOf(L) + UInt64(L);
  if (aOffset + Need) > FSize then Exit;
  Inc(P, SizeOf(L));
  SetLength(aBuf, L);
  if L > 0 then Move(P^, aBuf[1], L);
  Result := True;
end;

function TMemoryMap.WriteLPUTF8(aOffset: UInt64; const S: UnicodeString): Boolean;
var
  bytes: RawByteString;
begin
  bytes := UTF8Encode(S);
  Result := WriteLPBytes(aOffset, bytes);
end;

function TMemoryMap.ReadLPUTF8(aOffset: UInt64; out S: UTF8String): Boolean;
var
  bytes: RawByteString;
begin
  Result := ReadLPBytes(aOffset, bytes);
  if Result then
  begin
    SetCodePage(bytes, CP_UTF8, False);
    S := UTF8String(bytes);
  end;
end;

{ TSharedMemory }

constructor TSharedMemory.Create;
begin
  inherited Create;
  FName := '';
  FSize := 0;
  FMemoryMap := TMemoryMap.Create;
  FIsCreator := False;
end;

destructor TSharedMemory.Destroy;
begin
  Close;
  FMemoryMap.Free;
  inherited Destroy;
end;

{$PUSH}
{$WARN 6018 OFF}
{$WARN 5057 OFF} // 局部: L/LMapHandle 等后续均赋值
function TSharedMemory.CreateShared(const aName: string; aSize: UInt64;
  aAccess: TMemoryMapAccess): Boolean;
{$IFDEF WINDOWS}
var
  LMapHandle: THandle;
  LProtection: DWORD;
  LWinName: string;
{$ELSE}
var
  LSharedName: string;
  LFileHandle: Integer;
{$ENDIF}
begin
  Result := False;

  // 关闭现有共享内存
  Close;

  FName := aName;
  FSize := aSize;

  if (FName = '') or (FSize = 0) then Exit;

  {$IFDEF WINDOWS}
  // Windows命名共享内存
  // Windows命名共享内存：统一使用可读写的保护，视图访问再按 aAccess 控制
  case aAccess of
    mmaRead: LProtection := PAGE_READWRITE;
    mmaWrite: LProtection := PAGE_READWRITE;
    mmaReadWrite: LProtection := PAGE_READWRITE;
    mmaCopyOnWrite: LProtection := PAGE_WRITECOPY;
  else
    LProtection := PAGE_READWRITE;
  end;

  // Windows: 自动补全 Local\ 前缀（未指定命名空间时）
  if Pos('\', FName) = 0 then LWinName := 'Local\' + FName else LWinName := FName;
  LMapHandle := CreateFileMapping(INVALID_HANDLE_VALUE, nil, LProtection,
    Hi(FSize), Lo(FSize), PChar(LWinName));

  if LMapHandle = 0 then Exit;

  // 检查是否是新创建的
  FIsCreator := GetLastError <> ERROR_ALREADY_EXISTS;

  // 使用内存映射对象来管理
  FMemoryMap.FMapHandle := LMapHandle;
  FMemoryMap.FAccess := aAccess;
  FMemoryMap.FSize := FSize;
  FMemoryMap.FIsAnonymous := True;
  FMemoryMap.FIsOpen := True;

  case aAccess of
    mmaRead: FMemoryMap.FBaseAddress := MapViewOfFile(LMapHandle, FILE_MAP_READ, 0, 0, FSize);
    mmaWrite: FMemoryMap.FBaseAddress := MapViewOfFile(LMapHandle, FILE_MAP_WRITE, 0, 0, FSize);
    mmaReadWrite: FMemoryMap.FBaseAddress := MapViewOfFile(LMapHandle, FILE_MAP_ALL_ACCESS, 0, 0, FSize);
    mmaCopyOnWrite: FMemoryMap.FBaseAddress := MapViewOfFile(LMapHandle, FILE_MAP_COPY, 0, 0, FSize);
  end;  // 视图访问标志与上面的 PAGE 保护配合，保证读写一致

  if FMemoryMap.FBaseAddress = nil then
  begin
    CloseHandle(LMapHandle);
    FMemoryMap.FMapHandle := 0;
    FMemoryMap.FIsOpen := False;
    Exit;
  end;

  {$ELSE}
  // Unix/Linux共享内存 (POSIX shm_open)
  {$POP}
  if (Length(FName) = 0) or (FName[1] <> '/') then
    LSharedName := '/' + FName
  else
    LSharedName := FName;

  // O_EXCL 避免覆盖已存在的对象
  LFileHandle := fpShmOpen(PChar(LSharedName), O_CREAT or O_EXCL or O_RDWR, &666);
  if LFileHandle = -1 then
  begin
    // 已存在则仅打开
    LFileHandle := fpShmOpen(PChar(LSharedName), O_RDWR, 0);
    if LFileHandle = -1 then Exit;
    FIsCreator := False;
  end
  else
  begin
    FIsCreator := True;
    // 设置大小
    if FpFTruncate(LFileHandle, FSize) <> 0 then
    begin
      FpClose(LFileHandle);
      fpShmUnlink(PChar(LSharedName));
      Exit;
    end;
  end;

  // 使用内存映射对象来管理
  FMemoryMap.FFileHandle := LFileHandle;
  FMemoryMap.FAccess := aAccess;
  FMemoryMap.FSize := FSize;
  FMemoryMap.FIsAnonymous := False;
  FMemoryMap.FIsOpen := True;
  FMemoryMap.FFlags := [mmfShared];

  FMemoryMap.FBaseAddress := FpMmap(nil, FSize, FMemoryMap.GetUnixProtection,
    MAP_SHARED, LFileHandle, 0);

  if FMemoryMap.FBaseAddress = MAP_FAILED then
  begin
    FMemoryMap.FBaseAddress := nil;
    FpClose(LFileHandle);
    if FIsCreator then
      fpShmUnlink(PChar(LSharedName));
    FMemoryMap.FFileHandle := INVALID_HANDLE_VALUE;
    FMemoryMap.FIsOpen := False;
    Exit;
  end;
  {$ENDIF}

  Result := True;
end;

function TSharedMemory.OpenShared(const aName: string; aAccess: TMemoryMapAccess): Boolean;
{$IFDEF WINDOWS}
var
  LMapHandle: THandle;
  LDesiredAccess: DWORD;
  LMemInfo: TMemoryBasicInformation;
  LWinName: string;
{$ELSE}
var
  LSharedName: string;
  LFileHandle: Integer;
  LStatBuf: TStat;
{$ENDIF}
begin
  Result := False;

  // 关闭现有共享内存
  Close;

  FName := aName;
  FIsCreator := False;

  if FName = '' then Exit;

  {$IFDEF WINDOWS}
  // Windows打开现有共享内存
  case aAccess of
    mmaRead: LDesiredAccess := FILE_MAP_READ;
    mmaWrite: LDesiredAccess := FILE_MAP_WRITE;
    mmaReadWrite: LDesiredAccess := FILE_MAP_READ or FILE_MAP_WRITE;
    mmaCopyOnWrite: LDesiredAccess := FILE_MAP_COPY;
  else
    LDesiredAccess := FILE_MAP_READ;
  end;

  // Windows: 自动补全 Local\ 前缀（未指定命名空间时）
  LWinName := FName;
  if Pos('\', FName) = 0 then LWinName := 'Local\' + FName;
  {$PUSH}
  {$WARN 5057 OFF} // LMemInfo 后续由 VirtualQuery 填充，抑制“似乎未初始化”
  LMapHandle := OpenFileMapping(LDesiredAccess, False, PChar(LWinName));
  if LMapHandle = 0 then
  begin
    // 降级尝试只读打开，提升兼容性
    LDesiredAccess := FILE_MAP_READ;
    LMapHandle := OpenFileMapping(LDesiredAccess, False, PChar(LWinName));
    if LMapHandle = 0 then Exit;
  end;

  // 映射视图以获取大小信息
  FMemoryMap.FBaseAddress := MapViewOfFile(LMapHandle, LDesiredAccess, 0, 0, 0);
  if FMemoryMap.FBaseAddress = nil then
  begin
    CloseHandle(LMapHandle);
    Exit;
  end;

  // 获取映射大小 (Windows没有直接方法，使用VirtualQuery)
  if VirtualQuery(FMemoryMap.FBaseAddress, LMemInfo, SizeOf(LMemInfo)) = 0 then
  begin
    UnmapViewOfFile(FMemoryMap.FBaseAddress);
    CloseHandle(LMapHandle);
    Exit;
  end;

  FSize := LMemInfo.RegionSize;

  {$ELSE}
  // Unix/Linux打开现有共享内存（POSIX shm_open）
  if (Length(FName) = 0) or (FName[1] <> '/') then
    LSharedName := '/' + FName
  else
    LSharedName := FName;

  // 根据访问模式确定打开标志
  case aAccess of
    mmaRead: LFileHandle := fpShmOpen(PChar(LSharedName), O_RDONLY, 0);
    mmaWrite, mmaReadWrite: LFileHandle := fpShmOpen(PChar(LSharedName), O_RDWR, 0);
    mmaCopyOnWrite: LFileHandle := fpShmOpen(PChar(LSharedName), O_RDONLY, 0);
  else
    LFileHandle := fpShmOpen(PChar(LSharedName), O_RDWR, 0);
  end;
  if LFileHandle = -1 then Exit;

  // 获取大小
  if FpFStat(LFileHandle, LStatBuf) <> 0 then
  begin
    FpClose(LFileHandle);
    Exit;
  end;

  FSize := LStatBuf.st_size;

  FMemoryMap.FFileHandle := LFileHandle;
  FMemoryMap.FBaseAddress := FpMmap(nil, FSize, FMemoryMap.GetUnixProtection,
    MAP_SHARED, LFileHandle, 0);

  if FMemoryMap.FBaseAddress = MAP_FAILED then
  begin
    FMemoryMap.FBaseAddress := nil;
    FpClose(LFileHandle);
    Exit;
  end;
  {$ENDIF}

  // 设置内存映射对象状态
  FMemoryMap.FAccess := aAccess;
  FMemoryMap.FSize := FSize;
  FMemoryMap.FIsAnonymous := False;  // 共享内存不是匿名的
  FMemoryMap.FIsOpen := True;
  FMemoryMap.FFlags := [mmfShared];
  {$IFDEF WINDOWS}
  FMemoryMap.FMapHandle := LMapHandle;
  {$ENDIF}

  Result := True;
end;

procedure TSharedMemory.Close;
{$IFNDEF WINDOWS}
var
  LSharedName: string;
{$ENDIF}
begin
  if FMemoryMap.IsOpen then
  begin
    FMemoryMap.Close;

    {$IFNDEF WINDOWS}
    // Unix/Linux: 如果是创建者，删除共享内存对象
    if FIsCreator and (FName <> '') then
    begin
      if (Length(FName) = 0) or (FName[1] <> '/') then
        LSharedName := '/' + FName
      else
        LSharedName := FName;
      fpShmUnlink(PChar(LSharedName));
    end;
    {$ENDIF}

    FName := '';
    FSize := 0;
    FIsCreator := False;
  end;
end;

function TSharedMemory.IsValid: Boolean;
begin
  Result := FMemoryMap.IsValid;
end;

function TSharedMemory.GetPointer(aOffset: UInt64): Pointer;
begin
  Result := FMemoryMap.GetPointer(aOffset);
end;

function TSharedMemory.GetBaseAddress: Pointer;
begin
  Result := FMemoryMap.BaseAddress;
end;

function TSharedMemory.WriteLPBytes(aOffset: UInt64; const aBuf: RawByteString): Boolean;
begin
  Result := FMemoryMap.WriteLPBytes(aOffset, aBuf);
end;

function TSharedMemory.ReadLPBytes(aOffset: UInt64; out aBuf: RawByteString): Boolean;
begin
  Result := FMemoryMap.ReadLPBytes(aOffset, aBuf);
end;

function TSharedMemory.WriteLPUTF8(aOffset: UInt64; const S: UnicodeString): Boolean;
begin
  Result := FMemoryMap.WriteLPUTF8(aOffset, S);
end;

function TSharedMemory.ReadLPUTF8(aOffset: UInt64; out S: UTF8String): Boolean;
begin
  Result := FMemoryMap.ReadLPUTF8(aOffset, S);
end;

function TSharedMemory.Flush(aOffset: UInt64; aSize: UInt64): Boolean;
begin
  Result := FMemoryMap.Flush(aOffset, aSize);
end;

function TSharedMemory.FlushRange(aOffset: UInt64; aSize: UInt64): Boolean;
begin
  Result := FMemoryMap.FlushRange(aOffset, aSize);
end;

end.
