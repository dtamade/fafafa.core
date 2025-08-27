{$CODEPAGE UTF8}
unit fafafa.core.mem.enhancedStackPool;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes, fafafa.core.mem.stackPool, fafafa.core.mem.allocator;

type
  // Forward declaration for cross-references
  TEnhancedStackPool = class;

  {**
   * TStackScope
   *
   * @desc 栈作用域，支持RAII自动回收
   *}
  TStackScope = class
  private
    FPool: TEnhancedStackPool;
    FSavedState: SizeUInt;
    FActive: Boolean;

  public
    constructor Create(aPool: TEnhancedStackPool);
    destructor Destroy; override;

    {**
     * Alloc
     *
     * @desc 在当前作用域中分配内存
     * @param aSize 请求大小
     * @param aAlignment 对齐要求
     * @return 内存指针
     *}
    function Alloc(aSize: SizeUInt; aAlignment: SizeUInt = SizeOf(Pointer)): Pointer;

    {**
     * Release
     *
     * @desc 手动释放作用域（通常由析构函数自动调用）
     *}
    procedure Release;

    property Active: Boolean read FActive;
  end;

  {**
   * TStackScopeManager
   *
   * @desc 栈作用域管理器，管理嵌套作用域
   *}
  TStackScopeManager = class
  private
    FScopes: TList;
    FPool: TEnhancedStackPool;

  public
    constructor Create(aPool: TEnhancedStackPool);
    destructor Destroy; override;

    {**
     * PushScope
     *
     * @desc 推入新的作用域
     * @return 新的作用域对象
     *}
    function PushScope: TStackScope;

    {**
     * PopScope
     *
     * @desc 弹出当前作用域
     *}
    procedure PopScope;

    {**
     * GetCurrentScope
     *
     * @desc 获取当前作用域
     * @return 当前作用域对象
     *}
    function GetCurrentScope: TStackScope;

    {**
     * GetScopeDepth
     *
     * @desc 获取作用域深度
     * @return 作用域深度
     *}
    function GetScopeDepth: Integer;

    {**
     * ClearAllScopes
     *
     * @desc 清除所有作用域
     *}
    procedure ClearAllScopes;
  end;

  {**
   * TStackPoolStatistics
   *
   * @desc 栈池统计信息
   *}
  TStackPoolStatistics = record
    TotalAllocations: UInt64;     // 总分配次数
    TotalBytes: UInt64;           // 总分配字节数
    PeakUsage: SizeUInt;          // 峰值使用量
    CurrentUsage: SizeUInt;       // 当前使用量
    ScopeCreations: UInt64;       // 作用域创建次数
    ScopeDestructions: UInt64;    // 作用域销毁次数
    MaxScopeDepth: Integer;       // 最大作用域深度
    CurrentScopeDepth: Integer;   // 当前作用域深度
    FragmentationRatio: Double;   // 碎片化比率
  end;

  {**
   * TStackPoolPolicy
   *
   * @desc 栈池策略配置
   *}
  TStackPoolPolicy = record
    EnableStatistics: Boolean;    // 启用统计信息
    EnableScopeTracking: Boolean; // 启用作用域跟踪
    EnableAutoGrow: Boolean;      // 启用自动增长
    GrowthFactor: Single;         // 增长因子
    MaxSize: SizeUInt;            // 最大大小
    DefaultAlignment: SizeUInt;   // 默认对齐
    EnableDebugMode: Boolean;     // 启用调试模式
  end;

  // 调试用内存映射条目类型（替代内联匿名 record）
  TStackMemoryMapEntry = record
    Start: Pointer;
    Size: SizeUInt;
    Used: Boolean;
  end;

  {**
   * TEnhancedStackPool
   *
   * @desc 增强版栈池，支持嵌套作用域、自动回收、RAII等高级功能
   *}
  TEnhancedStackPool = class(TStackPool)
  private
    FPolicy: TStackPoolPolicy;
    FStatistics: TStackPoolStatistics;
    FScopeManager: TStackScopeManager;
    FStateStack: array of SizeUInt;  // 状态栈
    FStateStackTop: Integer;         // 状态栈顶
    FMaxStateStack: Integer;         // 状态栈最大深度

    procedure UpdateStatistics(aAllocSize: SizeUInt);
    procedure GrowPool(aRequiredSize: SizeUInt);
    function CalculateFragmentation: Double;

  public
    constructor Create(aSize: SizeUInt; const aPolicy: TStackPoolPolicy; aAllocator: TAllocator = nil);
    destructor Destroy; override;

    {**
     * Alloc
     *
     * @desc 分配内存（增强版）
     * @param aSize 请求大小
     * @param aAlignment 对齐要求
     * @return 内存指针
     *}
    function Alloc(aSize: SizeUInt; aAlignment: SizeUInt = SizeOf(Pointer)): Pointer; reintroduce;

    {**
     * CreateScope
     *
     * @desc 创建新的作用域
     * @return 作用域对象
     *}
    function CreateScope: TStackScope;

    {**
     * PushState
     *
     * @desc 推入状态到状态栈
     * @return 是否成功
     *}
    function PushState: Boolean;

    {**
     * PopState
     *
     * @desc 从状态栈弹出状态
     * @return 是否成功
     *}
    function PopState: Boolean;

    {**
     * GetStateStackDepth
     *
     * @desc 获取状态栈深度
     * @return 状态栈深度
     *}
    function GetStateStackDepth: Integer;

    {**
     * AllocAligned
     *
     * @desc 分配对齐内存
     * @param aSize 请求大小
     * @param aAlignment 对齐要求
     * @return 内存指针
     *}
    function AllocAligned(aSize: SizeUInt; aAlignment: SizeUInt): Pointer;

    {**
     * AllocZeroed
     *
     * @desc 分配并清零的内存
     * @param aSize 请求大小
     * @param aAlignment 对齐要求
     * @return 内存指针
     *}
    function AllocZeroed(aSize: SizeUInt; aAlignment: SizeUInt = 0): Pointer;

    {**
     * AllocString
     *
     * @desc 分配字符串内存
     * @param aLength 字符串长度
     * @return 字符串指针
     *}
    function AllocString(aLength: SizeUInt): PChar;

    {**
     * AllocArray
     *
     * @desc 分配数组内存
     * @param aElementSize 元素大小
     * @param aCount 元素个数
     * @param aAlignment 对齐要求
     * @return 数组指针
     *}
    function AllocArray(aElementSize: SizeUInt; aCount: SizeUInt; aAlignment: SizeUInt = 0): Pointer;

    {**
     * GetStatistics
     *
     * @desc 获取统计信息
     * @return 统计信息结构
     *}
    function GetStatistics: TStackPoolStatistics;

    {**
     * ResetStatistics
     *
     * @desc 重置统计信息
     *}
    procedure ResetStatistics;

    {**
     * GetFragmentation
     *
     * @desc 获取碎片化比率
     * @return 碎片化比率（0.0-1.0）
     *}
    function GetFragmentation: Double;

    {**
     * Optimize
     *
     * @desc 优化池状态（整理内存等）
     *}
    procedure Optimize;

    {**
     * GetMemoryMap
     *
     * @desc 获取内存映射信息（调试用）
     * @param aMap 内存映射数组（输出）
     * @return 映射条目数
     *}
    function GetMemoryMap(out aMap: array of TStackMemoryMapEntry): Integer;

    // 属性
    property Policy: TStackPoolPolicy read FPolicy write FPolicy;
    property Statistics: TStackPoolStatistics read GetStatistics;
    property ScopeManager: TStackScopeManager read FScopeManager;
  end;

  {**
   * TAutoStackScope
   *
   * @desc 自动栈作用域，支持RAII模式
   *}
  TAutoStackScope = record
  private
    FScope: TStackScope;
    FActive: Boolean;

  public
    {**
     * Initialize
     *
     * @desc 初始化自动作用域
     * @param aPool 栈池
     *}
    class function Initialize(aPool: TEnhancedStackPool): TAutoStackScope; static;

    {**
     * Finalize
     *
     * @desc 清理自动作用域
     *}
    procedure Finalize;

    {**
     * Alloc
     *
     * @desc 在作用域中分配内存
     * @param aSize 请求大小
     * @param aAlignment 对齐要求
     * @return 内存指针
     *}
    function Alloc(aSize: SizeUInt; aAlignment: SizeUInt = SizeOf(Pointer)): Pointer;

    property Active: Boolean read FActive;
  end;

// 辅助函数
function CreateDefaultStackPolicy: TStackPoolPolicy;
function CreateHighPerformanceStackPolicy: TStackPoolPolicy;
function CreateDebugStackPolicy: TStackPoolPolicy;

// 便利宏（占位，不在单元内定义以避免语法歧义）。可在示例/调用方自行定义。
// {$DEFINE STACK_SCOPE_BEGIN := var __scope := TAutoStackScope.Initialize}
// {$DEFINE STACK_SCOPE_END := __scope.Finalize}

implementation

uses
  fafafa.core.mem.utils;

{ 辅助函数实现 }

function CreateDefaultStackPolicy: TStackPoolPolicy;
begin
  Result.EnableStatistics := True;
  Result.EnableScopeTracking := True;
  Result.EnableAutoGrow := True;
  Result.GrowthFactor := 2.0;
  Result.MaxSize := 64 * 1024 * 1024; // 64MB
  Result.DefaultAlignment := SizeOf(Pointer);
  Result.EnableDebugMode := False;
end;

function CreateHighPerformanceStackPolicy: TStackPoolPolicy;
begin
  Result := CreateDefaultStackPolicy;
  Result.EnableStatistics := False;
  Result.EnableScopeTracking := False;
  Result.EnableDebugMode := False;
end;

function CreateDebugStackPolicy: TStackPoolPolicy;
begin
  Result := CreateDefaultStackPolicy;
  Result.EnableDebugMode := True;
  Result.GrowthFactor := 1.5; // 更保守的增长
end;

{ TStackScope }

constructor TStackScope.Create(aPool: TEnhancedStackPool);
begin
  inherited Create;
  FPool := aPool;
  FSavedState := FPool.SaveState;
  FActive := True;

  if FPool.Policy.EnableStatistics then
    Inc(FPool.FStatistics.ScopeCreations);
end;

destructor TStackScope.Destroy;
begin
  if FActive then
    Release;
  inherited Destroy;
end;

function TStackScope.Alloc(aSize: SizeUInt; aAlignment: SizeUInt): Pointer;
begin
  if not FActive then
  begin
    Result := nil;
    Exit;
  end;

  if aAlignment = 0 then
    aAlignment := FPool.Policy.DefaultAlignment;

  Result := FPool.Alloc(aSize, aAlignment);
end;

procedure TStackScope.Release;
begin
  if not FActive then Exit;

  FPool.RestoreState(FSavedState);
  FActive := False;

  if FPool.Policy.EnableStatistics then
    Inc(FPool.FStatistics.ScopeDestructions);
end;

{ TStackScopeManager }

constructor TStackScopeManager.Create(aPool: TEnhancedStackPool);
begin
  inherited Create;
  FPool := aPool;
  FScopes := TList.Create;
end;

destructor TStackScopeManager.Destroy;
begin
  ClearAllScopes;
  FScopes.Free;
  inherited Destroy;
end;

function TStackScopeManager.PushScope: TStackScope;
begin
  Result := TStackScope.Create(FPool);
  FScopes.Add(Result);

  if FPool.Policy.EnableStatistics then
  begin
    FPool.FStatistics.CurrentScopeDepth := FScopes.Count;
    if FScopes.Count > FPool.FStatistics.MaxScopeDepth then
      FPool.FStatistics.MaxScopeDepth := FScopes.Count;
  end;
end;

procedure TStackScopeManager.PopScope;
var
  Scope: TStackScope;
begin
  if FScopes.Count = 0 then Exit;

  Scope := TStackScope(FScopes.Last);
  FScopes.Delete(FScopes.Count - 1);
  Scope.Free;

  if FPool.Policy.EnableStatistics then
    FPool.FStatistics.CurrentScopeDepth := FScopes.Count;
end;

function TStackScopeManager.GetCurrentScope: TStackScope;
begin
  if FScopes.Count > 0 then
    Result := TStackScope(FScopes.Last)
  else
    Result := nil;
end;

function TStackScopeManager.GetScopeDepth: Integer;
begin
  Result := FScopes.Count;
end;

procedure TStackScopeManager.ClearAllScopes;
var
  i: Integer;
begin
  for i := FScopes.Count - 1 downto 0 do
  begin
    TStackScope(FScopes[i]).Free;
  end;
  FScopes.Clear;

  if FPool.Policy.EnableStatistics then
    FPool.FStatistics.CurrentScopeDepth := 0;
end;

{ TEnhancedStackPool }

constructor TEnhancedStackPool.Create(aSize: SizeUInt; const aPolicy: TStackPoolPolicy; aAllocator: TAllocator);
begin
  inherited Create(aSize, aAllocator);

  FPolicy := aPolicy;
  FillChar(FStatistics, SizeOf(FStatistics), 0);

  if FPolicy.EnableScopeTracking then
    FScopeManager := TStackScopeManager.Create(Self)
  else
    FScopeManager := nil;

  // 初始化状态栈
  FMaxStateStack := 32; // 默认支持32层嵌套
  SetLength(FStateStack, FMaxStateStack);
  FStateStackTop := -1;
end;

destructor TEnhancedStackPool.Destroy;
begin
  if Assigned(FScopeManager) then
    FScopeManager.Free;
  SetLength(FStateStack, 0);
  inherited Destroy;
end;

function TEnhancedStackPool.Alloc(aSize: SizeUInt; aAlignment: SizeUInt): Pointer;
begin
  if aAlignment = 0 then
    aAlignment := FPolicy.DefaultAlignment;

  Result := inherited Alloc(aSize, aAlignment);

  if Result = nil then
  begin
    // 如果分配失败且启用自动增长，尝试扩容
    if FPolicy.EnableAutoGrow then
    begin
      GrowPool(aSize);
      Result := inherited Alloc(aSize, aAlignment);
    end;
  end;

  if (Result <> nil) and FPolicy.EnableStatistics then
    UpdateStatistics(aSize);
end;

function TEnhancedStackPool.CreateScope: TStackScope;
begin
  if Assigned(FScopeManager) then
    Result := FScopeManager.PushScope
  else
    Result := TStackScope.Create(Self);
end;

function TEnhancedStackPool.PushState: Boolean;
begin
  Result := False;

  if FStateStackTop >= FMaxStateStack - 1 then
  begin
    // 扩展状态栈
    FMaxStateStack := FMaxStateStack * 2;
    SetLength(FStateStack, FMaxStateStack);
  end;

  Inc(FStateStackTop);
  FStateStack[FStateStackTop] := SaveState;
  Result := True;
end;

function TEnhancedStackPool.PopState: Boolean;
begin
  Result := False;

  if FStateStackTop < 0 then Exit;

  RestoreState(FStateStack[FStateStackTop]);
  Dec(FStateStackTop);
  Result := True;
end;

function TEnhancedStackPool.GetStateStackDepth: Integer;
begin
  Result := FStateStackTop + 1;
end;

function TEnhancedStackPool.AllocAligned(aSize: SizeUInt; aAlignment: SizeUInt): Pointer;
begin
  Result := Alloc(aSize, aAlignment);
end;

function TEnhancedStackPool.AllocZeroed(aSize: SizeUInt; aAlignment: SizeUInt): Pointer;
begin
  Result := Alloc(aSize, aAlignment);
  if Result <> nil then
    FillChar(Result^, aSize, 0);
end;

function TEnhancedStackPool.AllocString(aLength: SizeUInt): PChar;
begin
  Result := PChar(AllocZeroed(aLength + 1, 1)); // +1 for null terminator
end;

function TEnhancedStackPool.AllocArray(aElementSize: SizeUInt; aCount: SizeUInt; aAlignment: SizeUInt): Pointer;
var
  LTotalSize: SizeUInt;
begin
  LTotalSize := aElementSize * aCount;
  Result := AllocZeroed(LTotalSize, aAlignment);
end;

function TEnhancedStackPool.GetStatistics: TStackPoolStatistics;
begin
  if FPolicy.EnableStatistics then
  begin
    FStatistics.CurrentUsage := UsedSize;
    FStatistics.FragmentationRatio := CalculateFragmentation;
    Result := FStatistics;
  end
  else
    FillChar(Result, SizeOf(Result), 0);
end;

procedure TEnhancedStackPool.ResetStatistics;
begin
  FillChar(FStatistics, SizeOf(FStatistics), 0);
end;

function TEnhancedStackPool.GetFragmentation: Double;
begin
  Result := CalculateFragmentation;
end;

procedure TEnhancedStackPool.Optimize;
begin
  // 简化实现：栈池通常不需要优化，因为是顺序分配
  // 实际应用中可以实现内存整理等功能
end;

function TEnhancedStackPool.GetMemoryMap(out aMap: array of TStackMemoryMapEntry): Integer;
begin
  // 简化实现：返回单个已使用块
  Result := 0;
  if Length(aMap) > 0 then
  begin
    aMap[0].Start := FBuffer;
    aMap[0].Size := UsedSize;
    aMap[0].Used := True;
    Result := 1;
  end;
end;

procedure TEnhancedStackPool.UpdateStatistics(aAllocSize: SizeUInt);
begin
  if not FPolicy.EnableStatistics then Exit;

  Inc(FStatistics.TotalAllocations);
  FStatistics.TotalBytes := FStatistics.TotalBytes + aAllocSize;
  FStatistics.CurrentUsage := UsedSize;

  if FStatistics.CurrentUsage > FStatistics.PeakUsage then
    FStatistics.PeakUsage := FStatistics.CurrentUsage;
end;

procedure TEnhancedStackPool.GrowPool(aRequiredSize: SizeUInt);
var
  NewSize: SizeUInt;
  NewBuffer: Pointer;
  OldUsedSize: SizeUInt;
begin
  if not FPolicy.EnableAutoGrow then Exit;

  NewSize := Round(FSize * FPolicy.GrowthFactor);
  if NewSize > FPolicy.MaxSize then
    NewSize := FPolicy.MaxSize;

  if NewSize <= FSize then Exit; // 无法增长

  // 分配新缓冲区
  NewBuffer := FBaseAllocator.GetMem(NewSize);
  if NewBuffer = nil then Exit;

  // 复制现有数据
  OldUsedSize := UsedSize;
  if OldUsedSize > 0 then
    Move(FBuffer^, NewBuffer^, OldUsedSize);

  // 释放旧缓冲区
  FBaseAllocator.FreeMem(FBuffer);

  // 更新池状态
  FBuffer := NewBuffer;
  FSize := NewSize;
end;

function TEnhancedStackPool.CalculateFragmentation: Double;
begin
  // 栈池的碎片化很简单：已使用空间 / 总空间
  if FSize = 0 then
    Result := 0.0
  else
    Result := 1.0 - (UsedSize / FSize);
end;

{ TAutoStackScope }

class function TAutoStackScope.Initialize(aPool: TEnhancedStackPool): TAutoStackScope;
begin
  Result.FScope := aPool.CreateScope;
  Result.FActive := True;
end;

procedure TAutoStackScope.Finalize;
begin
  if FActive and Assigned(FScope) then
  begin
    FScope.Free;
    FScope := nil;
    FActive := False;
  end;
end;

function TAutoStackScope.Alloc(aSize: SizeUInt; aAlignment: SizeUInt): Pointer;
begin
  if FActive and Assigned(FScope) then
    Result := FScope.Alloc(aSize, aAlignment)
  else
    Result := nil;
end;

end.
