{
  Test_fafafa_core_id_threadsafe - 多线程安全压力测试

  测试目标:
  - 验证 UUID v7 单调生成器的线程安全性
  - 验证 Snowflake 生成器在高并发下的唯一性
  - 验证 XID/ObjectId/Timeflake 在多线程环境下无重复
  - 压力测试全局单例初始化的线程安全性
}

unit Test_fafafa_core_id_threadsafe;

{$MODE OBJFPC}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, SyncObjs;

type
  TThreadSafeIdTest = class(TTestCase)
  published
    procedure Test_UuidV7Monotonic_MultiThread_Uniqueness;
    procedure Test_Snowflake_HighContention_Uniqueness;
    procedure Test_Xid_MultiThread_Uniqueness;
    procedure Test_ObjectId_MultiThread_Uniqueness;
    procedure Test_Timeflake_MultiThread_Uniqueness;
    procedure Test_GlobalSingleton_ConcurrentInit;
  end;

implementation

uses
  fafafa.core.id,
  fafafa.core.id.base,  // ✅ TTimeflake, TXid96, TObjectId 类型定义
  fafafa.core.id.v7.monotonic,
  fafafa.core.id.snowflake,
  fafafa.core.id.xid,
  fafafa.core.id.objectid,
  fafafa.core.id.timeflake;

const
  THREAD_COUNT = 8;
  IDS_PER_THREAD = 5000;

type
  { 通用 ID 收集结构 }
  TIdSet = class
  private
    FLock: TCriticalSection;
    FIds: TStringList;
    FDuplicates: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(const Id: string);
    function GetDuplicateCount: Integer;
    function GetTotalCount: Integer;
  end;

  { UUID v7 单调测试线程 }
  TUuidV7MonotonicThread = class(TThread)
  private
    FGen: IUuidV7Generator;
    FIdSet: TIdSet;
    FCount: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(AGen: IUuidV7Generator; AIdSet: TIdSet; ACount: Integer);
  end;

  { Snowflake 测试线程 }
  TSnowflakeThread = class(TThread)
  private
    FGen: ISnowflake;
    FIdSet: TIdSet;
    FCount: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(AGen: ISnowflake; AIdSet: TIdSet; ACount: Integer);
  end;

  { XID 测试线程 }
  TXidThread = class(TThread)
  private
    FIdSet: TIdSet;
    FCount: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(AIdSet: TIdSet; ACount: Integer);
  end;

  { ObjectId 测试线程 }
  TObjectIdThread = class(TThread)
  private
    FIdSet: TIdSet;
    FCount: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(AIdSet: TIdSet; ACount: Integer);
  end;

  { Timeflake 测试线程 }
  TTimeflakeThread = class(TThread)
  private
    FIdSet: TIdSet;
    FCount: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(AIdSet: TIdSet; ACount: Integer);
  end;

  { 全局单例初始化测试线程 }
  TSingletonInitThread = class(TThread)
  private
    FSuccess: Boolean;
  protected
    procedure Execute; override;
  public
    property Success: Boolean read FSuccess;
    constructor Create;
  end;

{ TIdSet }

constructor TIdSet.Create;
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  FIds := TStringList.Create;
  FIds.Sorted := True;          // ✅ 排序以使用 Find 二分搜索
  FIds.CaseSensitive := True;   // ✅ 区分大小写！Base62/Hex 需要
  FIds.Duplicates := dupAccept;
  FDuplicates := 0;
end;

destructor TIdSet.Destroy;
begin
  FIds.Free;
  FLock.Free;
  inherited Destroy;
end;

procedure TIdSet.Add(const Id: string);
var
  Idx: Integer;
begin
  FLock.Acquire;
  try
    // ✅ 使用 Find 二分搜索（CaseSensitive=True 确保正确比较）
    if FIds.Find(Id, Idx) then
      Inc(FDuplicates)
    else
      FIds.Add(Id);
  finally
    FLock.Release;
  end;
end;

function TIdSet.GetDuplicateCount: Integer;
begin
  FLock.Acquire;
  try
    Result := FDuplicates;
  finally
    FLock.Release;
  end;
end;

function TIdSet.GetTotalCount: Integer;
begin
  FLock.Acquire;
  try
    Result := FIds.Count + FDuplicates;
  finally
    FLock.Release;
  end;
end;

{ TUuidV7MonotonicThread }

constructor TUuidV7MonotonicThread.Create(AGen: IUuidV7Generator; AIdSet: TIdSet; ACount: Integer);
begin
  inherited Create(True);  // 创建挂起
  FGen := AGen;
  FIdSet := AIdSet;
  FCount := ACount;
  FreeOnTerminate := False;
end;

procedure TUuidV7MonotonicThread.Execute;
var
  I: Integer;
  Id: TUuid128;
begin
  for I := 1 to FCount do
  begin
    Id := FGen.NextRaw;
    FIdSet.Add(UuidToString(Id));
  end;
end;

{ TSnowflakeThread }

constructor TSnowflakeThread.Create(AGen: ISnowflake; AIdSet: TIdSet; ACount: Integer);
begin
  inherited Create(True);
  FGen := AGen;
  FIdSet := AIdSet;
  FCount := ACount;
  FreeOnTerminate := False;
end;

procedure TSnowflakeThread.Execute;
var
  I: Integer;
  Id: TSnowflakeID;
begin
  for I := 1 to FCount do
  begin
    Id := FGen.NextID;
    FIdSet.Add(IntToStr(Id));
  end;
end;

{ TXidThread }

constructor TXidThread.Create(AIdSet: TIdSet; ACount: Integer);
begin
  inherited Create(True);
  FIdSet := AIdSet;
  FCount := ACount;
  FreeOnTerminate := False;
end;

procedure TXidThread.Execute;
var
  I: Integer;
begin
  for I := 1 to FCount do
    FIdSet.Add(XidString);
end;

{ TObjectIdThread }

constructor TObjectIdThread.Create(AIdSet: TIdSet; ACount: Integer);
begin
  inherited Create(True);
  FIdSet := AIdSet;
  FCount := ACount;
  FreeOnTerminate := False;
end;

procedure TObjectIdThread.Execute;
var
  I: Integer;
begin
  for I := 1 to FCount do
    FIdSet.Add(ObjectIdToString(ObjectId));
end;

{ TTimeflakeThread }

constructor TTimeflakeThread.Create(AIdSet: TIdSet; ACount: Integer);
begin
  inherited Create(True);
  FIdSet := AIdSet;
  FCount := ACount;
  FreeOnTerminate := False;
end;

procedure TTimeflakeThread.Execute;
var
  I: Integer;
begin
  for I := 1 to FCount do
    FIdSet.Add(TimeflakeToString(TimeflakeMonotonic));
end;

{ TSingletonInitThread }

constructor TSingletonInitThread.Create;
begin
  inherited Create(True);
  FSuccess := False;
  FreeOnTerminate := False;
end;

procedure TSingletonInitThread.Execute;
begin
  try
    // 同时触发多个单例初始化
    XidString;
    ObjectIdToString(ObjectId);
    TimeflakeToString(Timeflake);
    FSuccess := True;
  except
    FSuccess := False;
  end;
end;

{ TThreadSafeIdTest }

procedure TThreadSafeIdTest.Test_UuidV7Monotonic_MultiThread_Uniqueness;
var
  Gen: IUuidV7Generator;
  IdSet: TIdSet;
  Threads: array[0..THREAD_COUNT - 1] of TUuidV7MonotonicThread;
  I: Integer;
  ExpectedTotal: Integer;
begin
  Gen := CreateUuidV7Monotonic;
  IdSet := TIdSet.Create;
  try
    // 创建线程
    for I := 0 to THREAD_COUNT - 1 do
      Threads[I] := TUuidV7MonotonicThread.Create(Gen, IdSet, IDS_PER_THREAD);

    // 启动所有线程
    for I := 0 to THREAD_COUNT - 1 do
      Threads[I].Start;

    // 等待完成
    for I := 0 to THREAD_COUNT - 1 do
    begin
      Threads[I].WaitFor;
      Threads[I].Free;
    end;

    // 验证结果
    ExpectedTotal := THREAD_COUNT * IDS_PER_THREAD;
    AssertEquals('Total IDs generated', ExpectedTotal, IdSet.GetTotalCount);
    AssertEquals('No duplicates in UUID v7 monotonic', 0, IdSet.GetDuplicateCount);
  finally
    IdSet.Free;
  end;
end;

procedure TThreadSafeIdTest.Test_Snowflake_HighContention_Uniqueness;
var
  Gen: ISnowflake;
  IdSet: TIdSet;
  Threads: array[0..THREAD_COUNT - 1] of TSnowflakeThread;
  I: Integer;
  ExpectedTotal: Integer;
begin
  Gen := CreateSnowflake(1);  // Worker ID = 1
  IdSet := TIdSet.Create;
  try
    // 创建线程
    for I := 0 to THREAD_COUNT - 1 do
      Threads[I] := TSnowflakeThread.Create(Gen, IdSet, IDS_PER_THREAD);

    // 启动所有线程
    for I := 0 to THREAD_COUNT - 1 do
      Threads[I].Start;

    // 等待完成
    for I := 0 to THREAD_COUNT - 1 do
    begin
      Threads[I].WaitFor;
      Threads[I].Free;
    end;

    // 验证结果
    ExpectedTotal := THREAD_COUNT * IDS_PER_THREAD;
    AssertEquals('Total IDs generated', ExpectedTotal, IdSet.GetTotalCount);
    AssertEquals('No duplicates in Snowflake', 0, IdSet.GetDuplicateCount);
  finally
    IdSet.Free;
  end;
end;

procedure TThreadSafeIdTest.Test_Xid_MultiThread_Uniqueness;
var
  IdSet: TIdSet;
  Threads: array[0..THREAD_COUNT - 1] of TXidThread;
  I: Integer;
  ExpectedTotal: Integer;
begin
  IdSet := TIdSet.Create;
  try
    // 创建线程
    for I := 0 to THREAD_COUNT - 1 do
      Threads[I] := TXidThread.Create(IdSet, IDS_PER_THREAD);

    // 启动所有线程
    for I := 0 to THREAD_COUNT - 1 do
      Threads[I].Start;

    // 等待完成
    for I := 0 to THREAD_COUNT - 1 do
    begin
      Threads[I].WaitFor;
      Threads[I].Free;
    end;

    // 验证结果
    ExpectedTotal := THREAD_COUNT * IDS_PER_THREAD;
    AssertEquals('Total IDs generated', ExpectedTotal, IdSet.GetTotalCount);
    AssertEquals('No duplicates in XID', 0, IdSet.GetDuplicateCount);
  finally
    IdSet.Free;
  end;
end;

procedure TThreadSafeIdTest.Test_ObjectId_MultiThread_Uniqueness;
var
  IdSet: TIdSet;
  Threads: array[0..THREAD_COUNT - 1] of TObjectIdThread;
  I: Integer;
  ExpectedTotal: Integer;
begin
  IdSet := TIdSet.Create;
  try
    // 创建线程
    for I := 0 to THREAD_COUNT - 1 do
      Threads[I] := TObjectIdThread.Create(IdSet, IDS_PER_THREAD);

    // 启动所有线程
    for I := 0 to THREAD_COUNT - 1 do
      Threads[I].Start;

    // 等待完成
    for I := 0 to THREAD_COUNT - 1 do
    begin
      Threads[I].WaitFor;
      Threads[I].Free;
    end;

    // 验证结果
    ExpectedTotal := THREAD_COUNT * IDS_PER_THREAD;
    AssertEquals('Total IDs generated', ExpectedTotal, IdSet.GetTotalCount);
    AssertEquals('No duplicates in ObjectId', 0, IdSet.GetDuplicateCount);
  finally
    IdSet.Free;
  end;
end;

procedure TThreadSafeIdTest.Test_Timeflake_MultiThread_Uniqueness;
var
  IdSet: TIdSet;
  Threads: array[0..THREAD_COUNT - 1] of TTimeflakeThread;
  I: Integer;
  ExpectedTotal: Integer;
begin
  IdSet := TIdSet.Create;
  try
    // 创建线程
    for I := 0 to THREAD_COUNT - 1 do
      Threads[I] := TTimeflakeThread.Create(IdSet, IDS_PER_THREAD);

    // 启动所有线程
    for I := 0 to THREAD_COUNT - 1 do
      Threads[I].Start;

    // 等待完成
    for I := 0 to THREAD_COUNT - 1 do
    begin
      Threads[I].WaitFor;
      Threads[I].Free;
    end;

    // 验证结果
    ExpectedTotal := THREAD_COUNT * IDS_PER_THREAD;
    AssertEquals('Total IDs generated', ExpectedTotal, IdSet.GetTotalCount);
    AssertEquals('No duplicates in Timeflake monotonic', 0, IdSet.GetDuplicateCount);
  finally
    IdSet.Free;
  end;
end;

procedure TThreadSafeIdTest.Test_GlobalSingleton_ConcurrentInit;
var
  Threads: array[0..15] of TSingletonInitThread;
  I: Integer;
  AllSuccess: Boolean;
begin
  // 创建 16 个线程同时触发单例初始化
  for I := 0 to 15 do
    Threads[I] := TSingletonInitThread.Create;

  // 同时启动所有线程
  for I := 0 to 15 do
    Threads[I].Start;

  // 等待完成并检查结果
  AllSuccess := True;
  for I := 0 to 15 do
  begin
    Threads[I].WaitFor;
    if not Threads[I].Success then
      AllSuccess := False;
    Threads[I].Free;
  end;

  AssertTrue('All singleton initializations succeeded', AllSuccess);
end;

initialization
  RegisterTest(TThreadSafeIdTest);

end.
