unit fafafa.core.sync.namedShm.unix;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, BaseUnix, Unix, UnixType;

const
  // 跨架构 futex 系统调用号
  {$IFDEF CPUX86_64}
  SYS_futex = 202;
  {$ENDIF}
  {$IFDEF CPUAARCH64}
  SYS_futex = 98;
  {$ENDIF}
  {$IFDEF CPU386}
  SYS_futex = 240;
  {$ENDIF}
  {$IFDEF CPUARM}
  SYS_futex = 240;
  {$ENDIF}

  // Futex 操作码
  FUTEX_WAIT = 0;
  FUTEX_WAKE = 1;

  // 共享内存名称最大长度
  SHM_NAME_MAX = 255;

  // 默认初始化超时（毫秒）
  DEFAULT_INIT_TIMEOUT_MS = 5000;

  // ✅ P1-2 Fix: 安全的共享内存权限常量
  // 默认仅所有者可读写（0600），避免未授权进程访问
  SHM_PERM_OWNER_ONLY = S_IRUSR or S_IWUSR;
  // 所有者+组可读写（0660），用于同组进程间共享
  SHM_PERM_WITH_GROUP = S_IRUSR or S_IWUSR or S_IRGRP or S_IWGRP;

type
  // 引用计数共享内存头部
  PNamedShmHeader = ^TNamedShmHeader;
  TNamedShmHeader = record
    Magic: UInt32;        // 魔数，用于验证
    RefCount: Int32;      // 引用计数
    DataSize: UInt32;     // 数据区大小
    Initialized: Int32;   // 初始化标志（0=未完成，1=已完成，-1=已废弃）
    CreatorPid: Int32;    // ★ 创建者进程 ID（用于检测孤儿共享内存）
    Generation: Int32;    // ★ 代数（每次重建递增，用于检测重建竞态）
  end;

const
  NAMED_SHM_MAGIC = $FAFA5348;  // 'FASH' - fafafa shared

// POSIX 共享内存函数声明
function shm_open(name: PAnsiChar; oflag: cint; mode: mode_t): cint; cdecl; external 'rt';
function shm_unlink(name: PAnsiChar): cint; cdecl; external 'rt';
function ftruncate(fd: cint; length: off_t): cint; cdecl; external 'c';

// syscall 声明
function fpSyscall(sysnr: clong; arg1, arg2, arg3, arg4, arg5, arg6: clong): clong;
  cdecl; external name 'syscall';

// 辅助函数

// 检测进程是否存活
function IsShmCreatorAlive(APid: Int32): Boolean;

// 创建安全的共享内存路径
function CreateSafeShmPath(const APrefix, AName: string): string;

// 验证名称长度
function ValidateShmName(const APrefix, AName: string): Boolean;

// Futex 等待（带超时）
function FutexWait(AAddr: PInt32; AExpected: Int32; ATimeoutMs: Cardinal): Boolean;

// Futex 唤醒所有等待者
procedure FutexWakeAll(AAddr: PInt32);

// Futex 唤醒指定数量的等待者
procedure FutexWake(AAddr: PInt32; ACount: Integer);

// 打开或创建共享内存（带引用计数）
// 返回: 共享内存文件描述符，-1 表示失败
// AIsCreator: 输出是否为创建者
// AInitTimeoutMs: 等待创建者初始化的超时时间
function OpenOrCreateShm(const AShmPath: string; ADataSize: csize_t;
  out AIsCreator: Boolean; AInitTimeoutMs: Cardinal = DEFAULT_INIT_TIMEOUT_MS): cint;

// 映射共享内存（包含头部）
// 返回: 数据区指针（跳过头部），nil 表示失败
function MapShm(AFd: cint; ADataSize: csize_t; out AHeader: PNamedShmHeader): Pointer;

// 增加引用计数（返回是否成功）
// ★ 当 RefCount=0 时（正在被清理），返回 False
function ShmAddRef(AHeader: PNamedShmHeader): Boolean;

// 减少引用计数，返回是否为最后一个引用
function ShmRelease(AHeader: PNamedShmHeader): Boolean;

// 标记初始化完成
procedure ShmMarkInitialized(AHeader: PNamedShmHeader);

// ★ 创建者初始化头部（在映射后立即调用）
// 设置 CreatorPid 以便在初始化过程中崩溃时能被检测到
procedure ShmInitCreatorHeader(AHeader: PNamedShmHeader);

// 等待初始化完成
function ShmWaitInitialized(AHeader: PNamedShmHeader; ATimeoutMs: Cardinal): Boolean;

// 解除映射并关闭共享内存
procedure UnmapAndCloseShm(AHeader: PNamedShmHeader; ADataSize: csize_t;
  AFd: cint; const AShmPath: string; AIsLastRef: Boolean);

implementation

uses
  fafafa.core.atomic;

// ★ 检测进程是否存活
function IsShmCreatorAlive(APid: Int32): Boolean;
begin
  if APid <= 0 then
    Exit(False);
  // kill(pid, 0) - 不发送信号，只检查进程是否存在
  // 返回 0 表示进程存在；返回 -1 且 errno=ESRCH 表示进程不存在
  Result := (FpKill(APid, 0) = 0) or (fpGetErrno <> ESysESRCH);
end;

function CreateSafeShmPath(const APrefix, AName: string): string;
var
  SafeName: string;
  I: Integer;
begin
  SafeName := AName;
  for I := 1 to Length(SafeName) do
    if not (SafeName[I] in ['a'..'z', 'A'..'Z', '0'..'9', '_']) then
      SafeName[I] := '_';

  // 确保不超过最大长度
  if Length(APrefix) + Length(SafeName) > SHM_NAME_MAX - 1 then
    SafeName := Copy(SafeName, 1, SHM_NAME_MAX - 1 - Length(APrefix));

  Result := APrefix + SafeName;
end;

function ValidateShmName(const APrefix, AName: string): Boolean;
begin
  // ✅ P1-2 Fix: 增强名称验证，防止安全问题
  // 1. 名称不能为空
  if Length(AName) = 0 then
    Exit(False);
  // 2. 名称不能以点开头（防止隐藏文件）
  if (Length(AName) > 0) and (AName[1] = '.') then
    Exit(False);
  // 3. 名称不能包含路径分隔符（防止路径遍历）
  if (Pos('/', AName) > 0) or (Pos('\', AName) > 0) then
    Exit(False);
  // 4. 总长度检查
  Result := (Length(APrefix) + Length(AName) <= SHM_NAME_MAX - 1);
end;

function FutexWait(AAddr: PInt32; AExpected: Int32; ATimeoutMs: Cardinal): Boolean;
var
  TimeSpec: TTimeSpec;
  TimeSpecPtr: PTimeSpec;
  Res: clong;
begin
  if ATimeoutMs = High(Cardinal) then
    TimeSpecPtr := nil
  else
  begin
    TimeSpec.tv_sec := ATimeoutMs div 1000;
    TimeSpec.tv_nsec := (ATimeoutMs mod 1000) * 1000000;
    TimeSpecPtr := @TimeSpec;
  end;

  Res := fpSyscall(SYS_futex,
    clong(PtrUInt(AAddr)),
    FUTEX_WAIT,
    AExpected,
    clong(PtrUInt(TimeSpecPtr)),
    0, 0);

  // 成功返回 0，EINTR（被信号中断）和 EAGAIN（值已改变）都视为正常
  Result := (Res = 0) or (fpgeterrno = ESysEINTR) or (fpgeterrno = ESysEAGAIN);
end;

procedure FutexWakeAll(AAddr: PInt32);
begin
  fpSyscall(SYS_futex,
    clong(PtrUInt(AAddr)),
    FUTEX_WAKE,
    High(Int32),
    0, 0, 0);
end;

procedure FutexWake(AAddr: PInt32; ACount: Integer);
begin
  fpSyscall(SYS_futex,
    clong(PtrUInt(AAddr)),
    FUTEX_WAKE,
    ACount,
    0, 0, 0);
end;

function OpenOrCreateShm(const AShmPath: string; ADataSize: csize_t;
  out AIsCreator: Boolean; AInitTimeoutMs: Cardinal): cint;
var
  Flags: cint;
  TotalSize: csize_t;
  StatBuf: Stat;
  StartTime, Elapsed: QWord;
begin
  Result := -1;
  AIsCreator := False;
  StatBuf := Default(Stat);
  TotalSize := SizeOf(TNamedShmHeader) + ADataSize;

  // 首先尝试独占创建
  Flags := O_CREAT or O_EXCL or O_RDWR;
  // ✅ P1-2 Fix: 使用安全默认权限（仅所有者可访问）
  Result := shm_open(PAnsiChar(AShmPath), Flags, SHM_PERM_OWNER_ONLY);

  if Result >= 0 then
  begin
    // 成功创建
    AIsCreator := True;
    if ftruncate(Result, TotalSize) <> 0 then
    begin
      FpClose(Result);
      shm_unlink(PAnsiChar(AShmPath));
      Result := -1;
      Exit;
    end;
  end
  else
  begin
    // 已存在，打开现有的
    Result := shm_open(PAnsiChar(AShmPath), O_RDWR, 0);
    if Result < 0 then
      Exit;

    // 等待创建者完成 ftruncate（带超时）
    StartTime := GetTickCount64;
    repeat
      if FpFStat(Result, StatBuf) <> 0 then
      begin
        FpClose(Result);
        Result := -1;
        Exit;
      end;

      if StatBuf.st_size >= TotalSize then
        Break;

      Elapsed := GetTickCount64 - StartTime;
      if Elapsed >= AInitTimeoutMs then
      begin
        // 超时
        FpClose(Result);
        Result := -1;
        Exit;
      end;

      Sleep(1);
    until False;
  end;
end;

function MapShm(AFd: cint; ADataSize: csize_t; out AHeader: PNamedShmHeader): Pointer;
var
  TotalSize: csize_t;
  MappedPtr: Pointer;
begin
  Result := nil;
  AHeader := nil;
  TotalSize := SizeOf(TNamedShmHeader) + ADataSize;

  MappedPtr := Fpmmap(nil, TotalSize, PROT_READ or PROT_WRITE, MAP_SHARED, AFd, 0);
  if MappedPtr = MAP_FAILED then
    Exit;

  AHeader := PNamedShmHeader(MappedPtr);
  Result := Pointer(PByte(MappedPtr) + SizeOf(TNamedShmHeader));
end;

function ShmAddRef(AHeader: PNamedShmHeader): Boolean;
var
  OldRef: Int32;
begin
  Result := False;
  if AHeader = nil then Exit;

  // ★ 关键修复：使用 CAS 循环，拒绝在 RefCount=0 时增加引用
  // 这防止了在清理过程中新进程增加引用
  repeat
    OldRef := atomic_load(AHeader^.RefCount);
    if OldRef <= 0 then
      Exit;  // 已经被标记为废弃，返回 False
  until atomic_compare_exchange_strong(AHeader^.RefCount, OldRef, OldRef + 1);
  Result := True;
end;

function ShmRelease(AHeader: PNamedShmHeader): Boolean;
var
  OldRef: Int32;
begin
  Result := False;
  if AHeader = nil then Exit;

  // ★ 关键修复：使用 CAS 循环安全地减少引用
  repeat
    OldRef := atomic_load(AHeader^.RefCount);
    if OldRef <= 0 then
      Exit;  // 已经被其他进程清理

    if OldRef = 1 then
    begin
      // 尝试从 1 减到 0（成为最后一个持有者）
      if atomic_compare_exchange_strong(AHeader^.RefCount, OldRef, 0) then
      begin
        Result := True;  // 成功，我们是最后一个
        Exit;
      end;
      // CAS 失败，说明有其他进程增加了引用，重试
    end
    else
    begin
      // RefCount > 1，可以安全减少
      if atomic_compare_exchange_strong(AHeader^.RefCount, OldRef, OldRef - 1) then
        Exit;  // 成功，不是最后一个
      // CAS 失败，重试
    end;
  until False;
end;

procedure ShmMarkInitialized(AHeader: PNamedShmHeader);
begin
  if AHeader <> nil then
  begin
    AHeader^.Magic := NAMED_SHM_MAGIC;
    // CreatorPid 应该已经在 ShmInitCreatorHeader 中设置了
    // 这里再设置一次以确保安全
    if atomic_load(AHeader^.CreatorPid) = 0 then
      atomic_store(AHeader^.CreatorPid, FpGetpid);
    atomic_store(AHeader^.Initialized, 1);
    FutexWakeAll(@AHeader^.Initialized);
  end;
end;

// ★ 创建者初始化头部（在映射后立即调用）
procedure ShmInitCreatorHeader(AHeader: PNamedShmHeader);
begin
  if AHeader <> nil then
  begin
    // 立即设置 CreatorPid，这样即使后续初始化过程崩溃也能被检测到
    atomic_store(AHeader^.CreatorPid, FpGetpid);
    atomic_store(AHeader^.Initialized, 0);
    atomic_store(AHeader^.Generation, 0);
  end;
end;

function ShmWaitInitialized(AHeader: PNamedShmHeader; ATimeoutMs: Cardinal): Boolean;
var
  StartTime, Elapsed: QWord;
  RemainingMs: Cardinal;
  InitState: Int32;
  CreatorPid: Int32;
const
  CREATOR_CHECK_INTERVAL_MS = 500;  // 检查创建者存活的间隔
begin
  Result := False;
  if AHeader = nil then
    Exit;

  // 快速路径
  InitState := atomic_load(AHeader^.Initialized);
  if InitState = 1 then
    Exit(True);
  if InitState = -1 then
    Exit(False);  // 已废弃

  StartTime := GetTickCount64;
  while True do
  begin
    InitState := atomic_load(AHeader^.Initialized);
    if InitState = 1 then
      Exit(True);
    if InitState = -1 then
      Exit(False);  // 已废弃

    // ★ 关键修复：检测创建者进程是否存活
    CreatorPid := atomic_load(AHeader^.CreatorPid);
    if (CreatorPid > 0) and (not IsShmCreatorAlive(CreatorPid)) then
    begin
      // 创建者已死但未完成初始化，标记为废弃
      // 使用 CAS 避免多个进程同时标记
      if atomic_compare_exchange_strong(AHeader^.Initialized, InitState, -1) then
        FutexWakeAll(@AHeader^.Initialized);
      Exit(False);
    end;

    Elapsed := GetTickCount64 - StartTime;
    if (ATimeoutMs <> High(Cardinal)) and (Elapsed >= ATimeoutMs) then
      Exit(False);

    // 计算等待时间：取超时剩余时间和创建者检查间隔的最小值
    if ATimeoutMs = High(Cardinal) then
      RemainingMs := CREATOR_CHECK_INTERVAL_MS
    else
    begin
      RemainingMs := ATimeoutMs - Cardinal(Elapsed);
      if RemainingMs > CREATOR_CHECK_INTERVAL_MS then
        RemainingMs := CREATOR_CHECK_INTERVAL_MS;
    end;

    FutexWait(@AHeader^.Initialized, 0, RemainingMs);
  end;
end;

procedure UnmapAndCloseShm(AHeader: PNamedShmHeader; ADataSize: csize_t;
  AFd: cint; const AShmPath: string; AIsLastRef: Boolean);
var
  TotalSize: csize_t;
begin
  TotalSize := SizeOf(TNamedShmHeader) + ADataSize;

  if AHeader <> nil then
    Fpmunmap(AHeader, TotalSize);

  if AFd >= 0 then
    FpClose(AFd);

  // 最后一个引用负责清理共享内存
  if AIsLastRef and (AShmPath <> '') then
    shm_unlink(PAnsiChar(AShmPath));
end;

end.
