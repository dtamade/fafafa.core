unit fafafa.core.sync.seqlock;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

{**
 * fafafa.core.sync.seqlock - 序列锁（SeqLock）实现
 *
 * @description
 *   SeqLock 是一种特殊的读写锁，专为"读远多于写"的场景优化。
 *   读操作几乎无锁（只需检查序列号），写操作需要获取独占锁。
 *
 * @characteristics
 *   - 读操作：无等待，通过序列号检测冲突后重试
 *   - 写操作：独占访问，需要获取锁
 *   - 适用场景：配置读取、统计计数器、时间戳等
 *   - 不适用：读操作需要修改共享状态的场景
 *
 * @performance
 *   - 读性能：接近无锁（~10-20ns）
 *   - 写性能：与普通 Mutex 相当（~25-50ns）
 *
 * @usage
 *   var
 *     SeqLock: ISeqLock;
 *     Data: TMyData;
 *     Seq: UInt32;
 *   begin
 *     SeqLock := MakeSeqLock;
 *
 *     // 读取（乐观读，可能需要重试）
 *     repeat
 *       Seq := SeqLock.ReadBegin;
 *       // 复制数据到本地
 *       LocalCopy := SharedData;
 *     until not SeqLock.ReadRetry(Seq);
 *
 *     // 写入（独占）
 *     SeqLock.WriteBegin;
 *     try
 *       SharedData := NewValue;
 *     finally
 *       SeqLock.WriteEnd;
 *     end;
 *   end;
 *}

interface

uses
  SysUtils,
  fafafa.core.atomic,
  fafafa.core.sync.base;

type
  {**
   * ISeqLock - 序列锁接口
   *
   * @description
   *   提供乐观读和独占写的序列锁操作。读操作通过序列号检测
   *   是否有写操作发生，如果有则需要重试。
   *}
  ISeqLock = interface(ISynchronizable)
    ['{E8B2F3A1-5C7D-4E9F-8A6B-1D2C3E4F5A6B}']

    {**
     * ReadBegin - 开始乐观读
     *
     * @returns 当前序列号（用于后续检测冲突）
     *
     * @description
     *   获取当前序列号，如果序列号为奇数说明有写操作正在进行，
     *   此时会自旋等待写操作完成。
     *}
    function ReadBegin: UInt32;

    {**
     * ReadRetry - 检查是否需要重试读取
     *
     * @param ASeq ReadBegin 返回的序列号
     * @returns True 表示数据可能被修改，需要重试；False 表示读取有效
     *
     * @description
     *   比较当前序列号与读取开始时的序列号，如果不同说明
     *   有写操作发生，读取的数据可能不一致，需要重试。
     *}
    function ReadRetry(ASeq: UInt32): Boolean;

    {**
     * WriteBegin - 开始独占写
     *
     * @description
     *   获取写锁，增加序列号（变为奇数）。
     *   会阻塞等待其他写操作完成。
     *}
    procedure WriteBegin;

    {**
     * WriteEnd - 结束写操作
     *
     * @description
     *   释放写锁，增加序列号（变为偶数）。
     *   必须与 WriteBegin 配对使用。
     *}
    procedure WriteEnd;

    {**
     * TryWriteBegin - 尝试开始写操作
     *
     * @returns True 成功获取写锁，False 写锁被占用
     *
     * @description
     *   非阻塞地尝试获取写锁。
     *}
    function TryWriteBegin: Boolean;

    {**
     * WriteGuard - 获取写操作 RAII 守卫
     *
     * @returns 写守卫接口，超出作用域自动释放
     *}
    function WriteGuard: ILockGuard;

    {**
     * GetSequence - 获取当前序列号
     *
     * @returns 当前序列号
     *}
    function GetSequence: UInt32;

    property Sequence: UInt32 read GetSequence;
  end;

  {**
   * ISeqLockData<T> - 泛型序列锁数据容器
   *
   * @description
   *   封装数据和序列锁，提供更便捷的读写操作。
   *   自动处理读重试逻辑。
   *}
  generic ISeqLockData<T> = interface(ISynchronizable)
    ['{F9C3E4B2-6D8E-4F0A-9B7C-2E3D4F5A6B7C}']

    {**
     * Read - 读取数据（自动重试）
     *
     * @returns 数据的一致性快照
     *}
    function Read: T;

    {**
     * Write - 写入数据
     *
     * @param AValue 要写入的值
     *}
    procedure Write(const AValue: T);

    {**
     * GetSeqLock - 获取底层序列锁
     *}
    function GetSeqLock: ISeqLock;

    property SeqLock: ISeqLock read GetSeqLock;
  end;

  {**
   * TSeqLock - 序列锁实现类
   *}
  TSeqLock = class(TInterfacedObject, ISeqLock, ISynchronizable)
  private
    FSequence: UInt32;  // 序列号：偶数=无写操作，奇数=写操作中
    FWriteLock: UInt32; // 写锁：0=空闲，1=占用
    FData: Pointer;     // 用户数据指针

    procedure SpinWaitEven;
  public
    constructor Create;

    // ISeqLock
    function ReadBegin: UInt32;
    function ReadRetry(ASeq: UInt32): Boolean;
    procedure WriteBegin;
    procedure WriteEnd;
    function TryWriteBegin: Boolean;
    function WriteGuard: ILockGuard;
    function GetSequence: UInt32;

    // ISynchronizable
    function GetData: Pointer;
    procedure SetData(aData: Pointer);
    function GetName: String;
    property Name: String read GetName;
  end;

  {**
   * TSeqLockWriteGuard - 写操作 RAII 守卫
   *}
  TSeqLockWriteGuard = class(TInterfacedObject, ILockGuard, IGuard)
  private
    FSeqLock: ISeqLock;
    FReleased: Boolean;
  public
    constructor Create(ASeqLock: ISeqLock);
    destructor Destroy; override;

    // ILockGuard / IGuard
    procedure Release;
    procedure Unlock;
    function IsLocked: Boolean;
  end;

  {**
   * TSeqLockData<T> - 泛型序列锁数据容器实现
   *}
  generic TSeqLockData<T> = class(TInterfacedObject, specialize ISeqLockData<T>, ISynchronizable)
  private
    FSeqLock: ISeqLock;
    FUserData: Pointer;
    FData: T;
  public
    constructor Create(const AInitialValue: T);

    function Read: T;
    procedure Write(const AValue: T);
    function GetSeqLock: ISeqLock;

    // ISynchronizable
    function GetData: Pointer;
    procedure SetData(aData: Pointer);
    function GetName: String;

    property SeqLock: ISeqLock read GetSeqLock;
    property Name: String read GetName;
  end;

{**
 * MakeSeqLock - 创建序列锁
 *
 * @returns 新的序列锁实例
 *}
function MakeSeqLock: ISeqLock;

{**
 * MakeSeqLockData<T> - 创建泛型序列锁数据容器
 *
 * @param AInitialValue 初始值
 * @returns 新的序列锁数据容器
 *}
generic function MakeSeqLockData<T>(const AInitialValue: T): specialize ISeqLockData<T>;

implementation

{ TSeqLock }

constructor TSeqLock.Create;
begin
  inherited Create;
  FSequence := 0;
  FWriteLock := 0;
  FData := nil;
end;

procedure TSeqLock.SpinWaitEven;
var
  SpinCount: Integer;
begin
  SpinCount := 0;
  // 等待序列号变为偶数（无写操作）
  while (atomic_load(FSequence, mo_acquire) and 1) <> 0 do
  begin
    Inc(SpinCount);
    if SpinCount > 1000 then
    begin
      // 长时间自旋后让出 CPU
      Sleep(0);
      SpinCount := 0;
    end;
    // CPU pause hint
    {$IFDEF CPUX86_64}
    asm
      pause
    end;
    {$ENDIF}
    {$IFDEF CPUX86}
    asm
      pause
    end;
    {$ENDIF}
  end;
end;

function TSeqLock.ReadBegin: UInt32;
begin
  // 等待直到没有写操作（序列号为偶数）
  repeat
    Result := atomic_load(FSequence, mo_acquire);
  until (Result and 1) = 0;
end;

function TSeqLock.ReadRetry(ASeq: UInt32): Boolean;
begin
  // 内存屏障确保读取完成
  atomic_thread_fence(mo_acquire);
  // 如果序列号变化了，需要重试
  Result := atomic_load(FSequence, mo_relaxed) <> ASeq;
end;

procedure TSeqLock.WriteBegin;
var
  Expected: UInt32;
begin
  // 获取写锁（自旋）
  repeat
    Expected := 0;
  until atomic_compare_exchange_weak(FWriteLock, Expected, UInt32(1), mo_acquire, mo_relaxed);

  // 增加序列号（变为奇数，表示写操作开始）
  atomic_fetch_add(FSequence, UInt32(1), mo_release);
end;

procedure TSeqLock.WriteEnd;
begin
  // 增加序列号（变为偶数，表示写操作结束）
  atomic_fetch_add(FSequence, UInt32(1), mo_release);

  // 释放写锁
  atomic_store(FWriteLock, UInt32(0), mo_release);
end;

function TSeqLock.TryWriteBegin: Boolean;
var
  Expected: UInt32;
begin
  Expected := 0;
  Result := atomic_compare_exchange_strong(FWriteLock, Expected, UInt32(1), mo_acquire, mo_relaxed);
  if Result then
    atomic_fetch_add(FSequence, UInt32(1), mo_release);
end;

function TSeqLock.WriteGuard: ILockGuard;
begin
  WriteBegin;
  Result := TSeqLockWriteGuard.Create(Self);
end;

function TSeqLock.GetSequence: UInt32;
begin
  Result := atomic_load(FSequence, mo_acquire);
end;

function TSeqLock.GetData: Pointer;
begin
  Result := FData;
end;

procedure TSeqLock.SetData(aData: Pointer);
begin
  FData := aData;
end;

function TSeqLock.GetName: String;
begin
  Result := 'SeqLock';
end;

{ TSeqLockWriteGuard }

constructor TSeqLockWriteGuard.Create(ASeqLock: ISeqLock);
begin
  inherited Create;
  FSeqLock := ASeqLock;
  FReleased := False;
end;

destructor TSeqLockWriteGuard.Destroy;
begin
  if not FReleased then
    Release;
  inherited Destroy;
end;

procedure TSeqLockWriteGuard.Release;
begin
  if not FReleased then
  begin
    FSeqLock.WriteEnd;
    FReleased := True;
  end;
end;

procedure TSeqLockWriteGuard.Unlock;
begin
  Release;
end;

function TSeqLockWriteGuard.IsLocked: Boolean;
begin
  Result := not FReleased;
end;

{ TSeqLockData<T> }

constructor TSeqLockData.Create(const AInitialValue: T);
begin
  inherited Create;
  FSeqLock := MakeSeqLock;
  FData := AInitialValue;
  FUserData := nil;
end;

function TSeqLockData.Read: T;
var
  Seq: UInt32;
begin
  repeat
    Seq := FSeqLock.ReadBegin;
    Result := FData;
  until not FSeqLock.ReadRetry(Seq);
end;

procedure TSeqLockData.Write(const AValue: T);
begin
  FSeqLock.WriteBegin;
  try
    FData := AValue;
  finally
    FSeqLock.WriteEnd;
  end;
end;

function TSeqLockData.GetSeqLock: ISeqLock;
begin
  Result := FSeqLock;
end;

function TSeqLockData.GetData: Pointer;
begin
  Result := FUserData;
end;

procedure TSeqLockData.SetData(aData: Pointer);
begin
  FUserData := aData;
end;

function TSeqLockData.GetName: String;
begin
  Result := 'SeqLockData';
end;

{ Factory Functions }

function MakeSeqLock: ISeqLock;
begin
  Result := TSeqLock.Create;
end;

generic function MakeSeqLockData<T>(const AInitialValue: T): specialize ISeqLockData<T>;
begin
  Result := specialize TSeqLockData<T>.Create(AInitialValue);
end;

end.
