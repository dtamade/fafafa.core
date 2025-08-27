{$CODEPAGE UTF8}
unit fafafa.core.mem.enhancedObjectPool;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes, fafafa.core.mem.objectPool, fafafa.core.mem.allocator;

type
  {**
   * TObjectLifecycleState
   * 
   * @desc 对象生命周期状态
   *}
  TObjectLifecycleState = (
    olsCreated,     // 刚创建
    olsInitialized, // 已初始化
    olsActive,      // 活跃使用中
    olsReturned,    // 已返回池中
    olsFinalized,   // 已清理
    olsDestroyed    // 已销毁
  );

  {**
   * TObjectPoolPolicy
   * 
   * @desc 对象池策略配置
   *}
  TObjectPoolPolicy = record
    InitialSize: Integer;        // 初始大小
    MaxSize: Integer;            // 最大大小
    MinSize: Integer;            // 最小大小
    GrowthFactor: Single;        // 增长因子
    ShrinkThreshold: Single;     // 收缩阈值
    MaxIdleTime: Integer;        // 最大空闲时间（毫秒）
    ValidationInterval: Integer; // 验证间隔（毫秒）
    EnableAutoGrow: Boolean;     // 启用自动增长
    EnableAutoShrink: Boolean;   // 启用自动收缩
    EnableValidation: Boolean;   // 启用对象验证
    EnableStatistics: Boolean;   // 启用统计信息
  end;

  {**
   * TObjectPoolStatistics
   * 
   * @desc 对象池统计信息
   *}
  TObjectPoolStatistics = record
    TotalCreated: UInt64;        // 总创建数
    TotalDestroyed: UInt64;      // 总销毁数
    TotalBorrowed: UInt64;       // 总借用数
    TotalReturned: UInt64;       // 总归还数
    TotalValidationFailed: UInt64; // 验证失败数
    TotalGrowthEvents: UInt64;   // 增长事件数
    TotalShrinkEvents: UInt64;   // 收缩事件数
    CurrentSize: Integer;        // 当前大小
    CurrentActive: Integer;      // 当前活跃数
    CurrentIdle: Integer;        // 当前空闲数
    PeakSize: Integer;           // 峰值大小
    PeakActive: Integer;         // 峰值活跃数
    AverageLifetime: Double;     // 平均生命周期（毫秒）
    HitRatio: Double;            // 命中率
  end;

  // 前向声明
  TEnhancedObjectPool = class;

  {**
   * TObjectValidator
   * 
   * @desc 对象验证器函数类型
   *}
  TObjectValidator = function(aObject: TObject): Boolean;

  {**
   * TObjectLifecycleCallback
   * 
   * @desc 对象生命周期回调函数类型
   *}
  TObjectLifecycleCallback = procedure(aPool: TEnhancedObjectPool; aObject: TObject; 
    aOldState, aNewState: TObjectLifecycleState);

  {**
   * TPooledObjectInfo
   * 
   * @desc 池化对象信息
   *}
  TPooledObjectInfo = record
    Obj: TObject;                    // 对象实例
    State: TObjectLifecycleState;    // 生命周期状态
    CreatedTime: TDateTime;          // 创建时间
    LastUsedTime: TDateTime;         // 最后使用时间
    BorrowCount: UInt64;             // 借用次数
    ValidationFailCount: Integer;    // 验证失败次数
  end;
  PPooledObjectInfo = ^TPooledObjectInfo;

  {**
   * TEnhancedObjectPool
   * 
   * @desc 增强版对象池，支持复杂的生命周期管理、自动扩容、预热策略等
   *}
  TEnhancedObjectPool = class(TObjectPool)
  private
    FPolicy: TObjectPoolPolicy;
    FStatistics: TObjectPoolStatistics;
    FValidator: TObjectValidator;
    FLifecycleCallback: TObjectLifecycleCallback;
    FObjectInfos: array of TPooledObjectInfo;
    FLastValidationTime: TDateTime;
    FLastMaintenanceTime: TDateTime;
    
    procedure UpdateStatistics;
    procedure PerformMaintenance;
    function ValidateObject(aObject: TObject): Boolean;
    procedure NotifyLifecycleChange(aObject: TObject; aOldState, aNewState: TObjectLifecycleState);
    function FindObjectInfo(aObject: TObject): PPooledObjectInfo;
    procedure GrowPool(aTargetSize: Integer);
    procedure ShrinkPool(aTargetSize: Integer);
    function CalculateOptimalSize: Integer;
    
  public
    constructor Create(aObjectClass: TClass; const aPolicy: TObjectPoolPolicy;
      aFactory: TObjectFactory = nil; aInitializer: TObjectInitializer = nil;
      aFinalizer: TObjectFinalizer = nil; aAllocator: TAllocator = nil);
    destructor Destroy; override;
    
    {**
     * Get
     * 
     * @desc 从池中获取对象（增强版）
     * @return 对象实例
     *}
    function Get: TObject; override;
    
    {**
     * Return
     * 
     * @desc 将对象返回到池中（增强版）
     * @param aObject 要返回的对象
     *}
    procedure Return(aObject: TObject); override;
    
    {**
     * Warmup
     * 
     * @desc 预热池（创建指定数量的对象）
     * @param aCount 预热对象数量
     * @param aAsync 是否异步执行
     *}
    procedure Warmup(aCount: Integer; aAsync: Boolean = False);
    
    {**
     * Validate
     * 
     * @desc 验证池中所有对象
     * @return 验证失败的对象数量
     *}
    function Validate: Integer;
    
    {**
     * Cleanup
     * 
     * @desc 清理过期或无效的对象
     * @return 清理的对象数量
     *}
    function Cleanup: Integer;
    
    {**
     * Resize
     * 
     * @desc 调整池大小
     * @param aNewSize 新的池大小
     * @return 是否成功
     *}
    function Resize(aNewSize: Integer): Boolean;
    
    {**
     * GetObjectInfo
     * 
     * @desc 获取对象信息
     * @param aObject 对象实例
     * @param aInfo 对象信息（输出）
     * @return 是否找到
     *}
    function GetObjectInfo(aObject: TObject; out aInfo: TPooledObjectInfo): Boolean;
    
    {**
     * SetValidator
     * 
     * @desc 设置对象验证器
     * @param aValidator 验证器函数
     *}
    procedure SetValidator(aValidator: TObjectValidator);
    
    {**
     * SetLifecycleCallback
     * 
     * @desc 设置生命周期回调
     * @param aCallback 回调函数
     *}
    procedure SetLifecycleCallback(aCallback: TObjectLifecycleCallback);
    
    {**
     * GetStatistics
     * 
     * @desc 获取统计信息
     * @return 统计信息结构
     *}
    function GetStatistics: TObjectPoolStatistics;
    
    {**
     * ResetStatistics
     * 
     * @desc 重置统计信息
     *}
    procedure ResetStatistics;
    
    {**
     * GetHealthScore
     * 
     * @desc 获取池健康评分（0-100）
     * @return 健康评分
     *}
    function GetHealthScore: Integer;
    
    // 属性
    property Policy: TObjectPoolPolicy read FPolicy write FPolicy;
    property Statistics: TObjectPoolStatistics read GetStatistics;
    property Validator: TObjectValidator read FValidator write SetValidator;
    property LifecycleCallback: TObjectLifecycleCallback read FLifecycleCallback write SetLifecycleCallback;
  end;

  {**
   * TTypedEnhancedObjectPool<T>
   * 
   * @desc 类型安全的增强版泛型对象池
   *}
  generic TTypedEnhancedObjectPool<T: TObject> = class(TEnhancedObjectPool)
  public
    function Get: T; reintroduce;
    procedure Return(aObject: T); reintroduce;
    function GetObjectInfo(aObject: T; out aInfo: TPooledObjectInfo): Boolean; reintroduce;
  end;

  {**
   * TObjectPoolManager
   * 
   * @desc 对象池管理器，管理多个不同类型的对象池
   *}
  TObjectPoolManager = class
  private
    FPools: TStringList; // 存储 ClassName -> TEnhancedObjectPool 的映射
    FDefaultPolicy: TObjectPoolPolicy;
    
  public
    constructor Create;
    destructor Destroy; override;
    
    {**
     * RegisterPool
     * 
     * @desc 注册对象池
     * @param aObjectClass 对象类型
     * @param aPolicy 池策略
     * @return 是否成功
     *}
    function RegisterPool(aObjectClass: TClass; const aPolicy: TObjectPoolPolicy): Boolean;
    
    {**
     * GetPool
     * 
     * @desc 获取指定类型的对象池
     * @param aObjectClass 对象类型
     * @return 对象池实例
     *}
    function GetPool(aObjectClass: TClass): TEnhancedObjectPool;
    
    {**
     * GetObject
     * 
     * @desc 获取指定类型的对象
     * @param aObjectClass 对象类型
     * @return 对象实例
     *}
    function GetObject(aObjectClass: TClass): TObject;
    
    {**
     * ReturnObject
     * 
     * @desc 返回对象到对应的池
     * @param aObject 对象实例
     *}
    procedure ReturnObject(aObject: TObject);
    
    {**
     * GetTotalStatistics
     * 
     * @desc 获取所有池的汇总统计信息
     * @return 汇总统计信息
     *}
    function GetTotalStatistics: TObjectPoolStatistics;
    
    {**
     * PerformMaintenance
     * 
     * @desc 对所有池执行维护操作
     *}
    procedure PerformMaintenance;
    
    // 属性
    property DefaultPolicy: TObjectPoolPolicy read FDefaultPolicy write FDefaultPolicy;
  end;

// 辅助函数
function CreateDefaultPolicy: TObjectPoolPolicy;
function CreateHighPerformancePolicy: TObjectPoolPolicy;
function CreateMemoryOptimizedPolicy: TObjectPoolPolicy;

implementation

uses
  DateUtils;

{ 辅助函数实现 }

function CreateDefaultPolicy: TObjectPoolPolicy;
begin
  Result.InitialSize := 5;
  Result.MaxSize := 50;
  Result.MinSize := 2;
  Result.GrowthFactor := 1.5;
  Result.ShrinkThreshold := 0.25;
  Result.MaxIdleTime := 300000; // 5分钟
  Result.ValidationInterval := 60000; // 1分钟
  Result.EnableAutoGrow := True;
  Result.EnableAutoShrink := True;
  Result.EnableValidation := True;
  Result.EnableStatistics := True;
end;

function CreateHighPerformancePolicy: TObjectPoolPolicy;
begin
  Result := CreateDefaultPolicy;
  Result.InitialSize := 20;
  Result.MaxSize := 200;
  Result.GrowthFactor := 2.0;
  Result.EnableAutoShrink := False; // 高性能模式不收缩
  Result.EnableValidation := False; // 减少验证开销
end;

function CreateMemoryOptimizedPolicy: TObjectPoolPolicy;
begin
  Result := CreateDefaultPolicy;
  Result.InitialSize := 1;
  Result.MaxSize := 10;
  Result.GrowthFactor := 1.2;
  Result.ShrinkThreshold := 0.5;
  Result.MaxIdleTime := 60000; // 1分钟
  Result.EnableAutoShrink := True;
end;

{ TEnhancedObjectPool }

constructor TEnhancedObjectPool.Create(aObjectClass: TClass; const aPolicy: TObjectPoolPolicy;
  aFactory: TObjectFactory; aInitializer: TObjectInitializer;
  aFinalizer: TObjectFinalizer; aAllocator: TAllocator);
begin
  inherited Create(aObjectClass, aPolicy.MaxSize, aFactory, aInitializer, aFinalizer, aAllocator);

  FPolicy := aPolicy;
  FillChar(FStatistics, SizeOf(FStatistics), 0);
  FValidator := nil;
  FLifecycleCallback := nil;
  FLastValidationTime := Now;
  FLastMaintenanceTime := Now;

  SetLength(FObjectInfos, aPolicy.MaxSize);

  // 初始化池
  if aPolicy.InitialSize > 0 then
    Warmup(aPolicy.InitialSize);
end;

destructor TEnhancedObjectPool.Destroy;
begin
  SetLength(FObjectInfos, 0);
  inherited Destroy;
end;

function TEnhancedObjectPool.Get: TObject;
var
  Info: PPooledObjectInfo;
begin
  // 执行维护操作
  if MilliSecondsBetween(Now, FLastMaintenanceTime) > FPolicy.ValidationInterval then
    PerformMaintenance;

  Result := inherited Get;

  if Result <> nil then
  begin
    Info := FindObjectInfo(Result);
    if Info <> nil then
    begin
      NotifyLifecycleChange(Result, Info^.State, olsActive);
      Info^.State := olsActive;
      Info^.LastUsedTime := Now;
      Inc(Info^.BorrowCount);
    end;

    Inc(FStatistics.TotalBorrowed);
    Inc(FStatistics.CurrentActive);
    Dec(FStatistics.CurrentIdle);

    if FStatistics.CurrentActive > FStatistics.PeakActive then
      FStatistics.PeakActive := FStatistics.CurrentActive;
  end
  else
  begin
    // 如果获取失败且启用自动增长，尝试扩容
    if FPolicy.EnableAutoGrow and (FCurrentCount < FPolicy.MaxSize) then
    begin
      GrowPool(CalculateOptimalSize);
      Result := inherited Get;
      if Result <> nil then
      begin
        Inc(FStatistics.TotalBorrowed);
        Inc(FStatistics.CurrentActive);
      end;
    end;
  end;

  UpdateStatistics;
end;

procedure TEnhancedObjectPool.Return(aObject: TObject);
var
  Info: PPooledObjectInfo;
begin
  if aObject = nil then Exit;

  Info := FindObjectInfo(aObject);
  if Info <> nil then
  begin
    // 验证对象
    if FPolicy.EnableValidation and not ValidateObject(aObject) then
    begin
      Inc(Info^.ValidationFailCount);
      Inc(FStatistics.TotalValidationFailed);
      // 验证失败，销毁对象而不是返回池中
      NotifyLifecycleChange(aObject, Info^.State, olsDestroyed);
      aObject.Free;
      Info^.Obj := nil;
      Info^.State := olsDestroyed;
      Inc(FStatistics.TotalDestroyed);
      Dec(FStatistics.CurrentActive);
      UpdateStatistics;
      Exit;
    end;

    NotifyLifecycleChange(aObject, Info^.State, olsReturned);
    Info^.State := olsReturned;
    Info^.LastUsedTime := Now;
  end;

  inherited Return(aObject);

  Inc(FStatistics.TotalReturned);
  Dec(FStatistics.CurrentActive);
  Inc(FStatistics.CurrentIdle);

  UpdateStatistics;
end;

procedure TEnhancedObjectPool.Warmup(aCount: Integer; aAsync: Boolean);
var
  i: Integer;
  Obj: TObject;
  Info: PPooledObjectInfo;
begin
  if aAsync then
  begin
    // 简化实现：同步执行（实际应该使用线程）
    // TODO: 实现异步预热
  end;

  for i := 1 to aCount do
  begin
    if FCurrentCount >= FPolicy.MaxSize then Break;

    Obj := CreateNewObject;
    if Obj <> nil then
    begin
      // 查找空闲的 ObjectInfo 槽位
      Info := nil;
      for var j := 0 to High(FObjectInfos) do
      begin
        if FObjectInfos[j].Obj = nil then
        begin
          Info := @FObjectInfos[j];
          Break;
        end;
      end;

      if Info <> nil then
      begin
        Info^.Obj := Obj;
        Info^.State := olsCreated;
        Info^.CreatedTime := Now;
        Info^.LastUsedTime := Now;
        Info^.BorrowCount := 0;
        Info^.ValidationFailCount := 0;

        NotifyLifecycleChange(Obj, olsCreated, olsInitialized);
        Info^.State := olsInitialized;
      end;

      FPool[FCurrentCount] := Obj;
      Inc(FCurrentCount);
      Inc(FStatistics.TotalCreated);
      Inc(FStatistics.CurrentIdle);
    end;
  end;

  UpdateStatistics;
end;

function TEnhancedObjectPool.Validate: Integer;
var
  i: Integer;
  Info: PPooledObjectInfo;
begin
  Result := 0;

  if not FPolicy.EnableValidation then Exit;

  for i := 0 to High(FObjectInfos) do
  begin
    Info := @FObjectInfos[i];
    if (Info^.Obj <> nil) and (Info^.State in [olsInitialized, olsReturned]) then
    begin
      if not ValidateObject(Info^.Obj) then
      begin
        Inc(Result);
        Inc(Info^.ValidationFailCount);
        Inc(FStatistics.TotalValidationFailed);
      end;
    end;
  end;

  FLastValidationTime := Now;
end;

function TEnhancedObjectPool.Cleanup: Integer;
var
  i: Integer;
  Info: PPooledObjectInfo;
  IdleTime: Integer;
begin
  Result := 0;

  for i := 0 to High(FObjectInfos) do
  begin
    Info := @FObjectInfos[i];
    if (Info^.Obj <> nil) and (Info^.State = olsReturned) then
    begin
      IdleTime := MilliSecondsBetween(Now, Info^.LastUsedTime);
      if IdleTime > FPolicy.MaxIdleTime then
      begin
        // 清理过期对象
        NotifyLifecycleChange(Info^.Obj, Info^.State, olsDestroyed);
        Info^.Obj.Free;
        Info^.Obj := nil;
        Info^.State := olsDestroyed;
        Inc(Result);
        Inc(FStatistics.TotalDestroyed);
        Dec(FStatistics.CurrentIdle);
      end;
    end;
  end;

  UpdateStatistics;
end;

function TEnhancedObjectPool.Resize(aNewSize: Integer): Boolean;
begin
  Result := False;

  if (aNewSize < FPolicy.MinSize) or (aNewSize > FPolicy.MaxSize) then
    Exit;

  if aNewSize > FCurrentCount then
    GrowPool(aNewSize)
  else if aNewSize < FCurrentCount then
    ShrinkPool(aNewSize);

  Result := True;
end;

function TEnhancedObjectPool.GetObjectInfo(aObject: TObject; out aInfo: TPooledObjectInfo): Boolean;
var
  Info: PPooledObjectInfo;
begin
  Info := FindObjectInfo(aObject);
  Result := Info <> nil;
  if Result then
    aInfo := Info^;
end;

procedure TEnhancedObjectPool.SetValidator(aValidator: TObjectValidator);
begin
  FValidator := aValidator;
end;

procedure TEnhancedObjectPool.SetLifecycleCallback(aCallback: TObjectLifecycleCallback);
begin
  FLifecycleCallback := aCallback;
end;

function TEnhancedObjectPool.GetStatistics: TObjectPoolStatistics;
begin
  UpdateStatistics;
  Result := FStatistics;
end;

procedure TEnhancedObjectPool.ResetStatistics;
begin
  FillChar(FStatistics, SizeOf(FStatistics), 0);
  FStatistics.CurrentSize := FCurrentCount;
  FStatistics.CurrentIdle := FCurrentCount;
end;

function TEnhancedObjectPool.GetHealthScore: Integer;
var
  Score: Double;
begin
  Score := 100.0;

  // 根据各种指标计算健康评分
  if FStatistics.TotalValidationFailed > 0 then
    Score := Score - (FStatistics.TotalValidationFailed / FStatistics.TotalCreated) * 20;

  if FStatistics.HitRatio < 0.8 then
    Score := Score - (0.8 - FStatistics.HitRatio) * 30;

  if FStatistics.CurrentSize > FPolicy.MaxSize * 0.9 then
    Score := Score - 10;

  Result := Round(Score);
  if Result < 0 then Result := 0;
  if Result > 100 then Result := 100;
end;

procedure TEnhancedObjectPool.UpdateStatistics;
begin
  FStatistics.CurrentSize := FCurrentCount;

  if FStatistics.TotalBorrowed > 0 then
    FStatistics.HitRatio := FStatistics.TotalReturned / FStatistics.TotalBorrowed
  else
    FStatistics.HitRatio := 0.0;

  if FStatistics.CurrentSize > FStatistics.PeakSize then
    FStatistics.PeakSize := FStatistics.CurrentSize;
end;

procedure TEnhancedObjectPool.PerformMaintenance;
begin
  if FPolicy.EnableValidation then
    Validate;

  Cleanup;

  if FPolicy.EnableAutoShrink then
  begin
    var OptimalSize := CalculateOptimalSize;
    if OptimalSize < FCurrentCount then
      ShrinkPool(OptimalSize);
  end;

  FLastMaintenanceTime := Now;
end;

function TEnhancedObjectPool.ValidateObject(aObject: TObject): Boolean;
begin
  if Assigned(FValidator) then
    Result := FValidator(aObject)
  else
    Result := aObject <> nil; // 默认验证：对象不为空
end;

procedure TEnhancedObjectPool.NotifyLifecycleChange(aObject: TObject;
  aOldState, aNewState: TObjectLifecycleState);
begin
  if Assigned(FLifecycleCallback) then
    FLifecycleCallback(Self, aObject, aOldState, aNewState);
end;

function TEnhancedObjectPool.FindObjectInfo(aObject: TObject): PPooledObjectInfo;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to High(FObjectInfos) do
  begin
    if FObjectInfos[i].Obj = aObject then
    begin
      Result := @FObjectInfos[i];
      Break;
    end;
  end;
end;

procedure TEnhancedObjectPool.GrowPool(aTargetSize: Integer);
var
  GrowCount: Integer;
begin
  if aTargetSize <= FCurrentCount then Exit;
  if aTargetSize > FPolicy.MaxSize then aTargetSize := FPolicy.MaxSize;

  GrowCount := aTargetSize - FCurrentCount;
  Warmup(GrowCount);
  Inc(FStatistics.TotalGrowthEvents);
end;

procedure TEnhancedObjectPool.ShrinkPool(aTargetSize: Integer);
var
  i, ShrinkCount: Integer;
  Info: PPooledObjectInfo;
begin
  if aTargetSize >= FCurrentCount then Exit;
  if aTargetSize < FPolicy.MinSize then aTargetSize := FPolicy.MinSize;

  ShrinkCount := FCurrentCount - aTargetSize;

  // 从空闲对象开始收缩
  for i := High(FObjectInfos) downto 0 do
  begin
    if ShrinkCount <= 0 then Break;

    Info := @FObjectInfos[i];
    if (Info^.Obj <> nil) and (Info^.State = olsReturned) then
    begin
      NotifyLifecycleChange(Info^.Obj, Info^.State, olsDestroyed);
      Info^.Obj.Free;
      Info^.Obj := nil;
      Info^.State := olsDestroyed;
      Dec(ShrinkCount);
      Dec(FCurrentCount);
      Inc(FStatistics.TotalDestroyed);
      Dec(FStatistics.CurrentIdle);
    end;
  end;

  Inc(FStatistics.TotalShrinkEvents);
  UpdateStatistics;
end;

function TEnhancedObjectPool.CalculateOptimalSize: Integer;
var
  UsageRatio: Double;
begin
  if FStatistics.CurrentSize = 0 then
  begin
    Result := FPolicy.InitialSize;
    Exit;
  end;

  UsageRatio := FStatistics.CurrentActive / FStatistics.CurrentSize;

  if UsageRatio > 0.8 then
    Result := Round(FStatistics.CurrentSize * FPolicy.GrowthFactor)
  else if UsageRatio < FPolicy.ShrinkThreshold then
    Result := Round(FStatistics.CurrentSize / FPolicy.GrowthFactor)
  else
    Result := FStatistics.CurrentSize;

  if Result < FPolicy.MinSize then Result := FPolicy.MinSize;
  if Result > FPolicy.MaxSize then Result := FPolicy.MaxSize;
end;

{ TTypedEnhancedObjectPool<T> }

function TTypedEnhancedObjectPool.Get: T;
begin
  Result := T(inherited Get);
end;

procedure TTypedEnhancedObjectPool.Return(aObject: T);
begin
  inherited Return(aObject);
end;

function TTypedEnhancedObjectPool.GetObjectInfo(aObject: T; out aInfo: TPooledObjectInfo): Boolean;
begin
  Result := inherited GetObjectInfo(aObject, aInfo);
end;

{ TObjectPoolManager }

constructor TObjectPoolManager.Create;
begin
  inherited Create;
  FPools := TStringList.Create;
  FPools.OwnsObjects := True;
  FDefaultPolicy := CreateDefaultPolicy;
end;

destructor TObjectPoolManager.Destroy;
begin
  FPools.Free;
  inherited Destroy;
end;

function TObjectPoolManager.RegisterPool(aObjectClass: TClass; const aPolicy: TObjectPoolPolicy): Boolean;
var
  Pool: TEnhancedObjectPool;
begin
  Result := False;
  if aObjectClass = nil then Exit;

  if FPools.IndexOf(aObjectClass.ClassName) >= 0 then
    Exit; // 已经注册

  Pool := TEnhancedObjectPool.Create(aObjectClass, aPolicy);
  FPools.AddObject(aObjectClass.ClassName, Pool);
  Result := True;
end;

function TObjectPoolManager.GetPool(aObjectClass: TClass): TEnhancedObjectPool;
var
  Index: Integer;
begin
  Result := nil;
  if aObjectClass = nil then Exit;

  Index := FPools.IndexOf(aObjectClass.ClassName);
  if Index >= 0 then
    Result := TEnhancedObjectPool(FPools.Objects[Index])
  else
  begin
    // 自动注册使用默认策略
    if RegisterPool(aObjectClass, FDefaultPolicy) then
    begin
      Index := FPools.IndexOf(aObjectClass.ClassName);
      if Index >= 0 then
        Result := TEnhancedObjectPool(FPools.Objects[Index]);
    end;
  end;
end;

function TObjectPoolManager.GetObject(aObjectClass: TClass): TObject;
var
  Pool: TEnhancedObjectPool;
begin
  Pool := GetPool(aObjectClass);
  if Pool <> nil then
    Result := Pool.Get
  else
    Result := nil;
end;

procedure TObjectPoolManager.ReturnObject(aObject: TObject);
var
  Pool: TEnhancedObjectPool;
begin
  if aObject = nil then Exit;

  Pool := GetPool(aObject.ClassType);
  if Pool <> nil then
    Pool.Return(aObject);
end;

function TObjectPoolManager.GetTotalStatistics: TObjectPoolStatistics;
var
  i: Integer;
  Pool: TEnhancedObjectPool;
  PoolStats: TObjectPoolStatistics;
begin
  FillChar(Result, SizeOf(Result), 0);

  for i := 0 to FPools.Count - 1 do
  begin
    Pool := TEnhancedObjectPool(FPools.Objects[i]);
    PoolStats := Pool.GetStatistics;

    Result.TotalCreated := Result.TotalCreated + PoolStats.TotalCreated;
    Result.TotalDestroyed := Result.TotalDestroyed + PoolStats.TotalDestroyed;
    Result.TotalBorrowed := Result.TotalBorrowed + PoolStats.TotalBorrowed;
    Result.TotalReturned := Result.TotalReturned + PoolStats.TotalReturned;
    Result.TotalValidationFailed := Result.TotalValidationFailed + PoolStats.TotalValidationFailed;
    Result.TotalGrowthEvents := Result.TotalGrowthEvents + PoolStats.TotalGrowthEvents;
    Result.TotalShrinkEvents := Result.TotalShrinkEvents + PoolStats.TotalShrinkEvents;
    Result.CurrentSize := Result.CurrentSize + PoolStats.CurrentSize;
    Result.CurrentActive := Result.CurrentActive + PoolStats.CurrentActive;
    Result.CurrentIdle := Result.CurrentIdle + PoolStats.CurrentIdle;

    if PoolStats.PeakSize > Result.PeakSize then
      Result.PeakSize := PoolStats.PeakSize;
    if PoolStats.PeakActive > Result.PeakActive then
      Result.PeakActive := PoolStats.PeakActive;
  end;

  if Result.TotalBorrowed > 0 then
    Result.HitRatio := Result.TotalReturned / Result.TotalBorrowed
  else
    Result.HitRatio := 0.0;
end;

procedure TObjectPoolManager.PerformMaintenance;
var
  i: Integer;
  Pool: TEnhancedObjectPool;
begin
  for i := 0 to FPools.Count - 1 do
  begin
    Pool := TEnhancedObjectPool(FPools.Objects[i]);
    Pool.PerformMaintenance;
  end;
end;

end.
