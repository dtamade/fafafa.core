{
```text
   ______   ______     ______   ______     ______   ______
  /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \
  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \
   \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\
    \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/  Studio

```
# fafafa.core.mem.objectPool

## Abstract 摘要

Generic object pool implementation providing efficient object reuse and lifecycle management.
泛型对象池实现，提供高效的对象复用和生命周期管理。

## Declaration 声明

For forwarding or using it for your own project, please retain the copyright notice of this project. Thank you.
转发或者用于自己项目请保留本项目的版权声明,谢谢.

Author:    fafafaStudio
Contact:   dtamade@gmail.com | QQ Group: 685403987 | QQ:179033731
Copyright: (c) 2025 fafafaStudio. All rights reserved.
}

unit fafafa.core.mem.objectPool;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.base,
  fafafa.core.mem.allocator;

type
  {**
   * TObjectFactory
   *
   * @desc 对象工厂函数类型
   *       Object factory function type
   *}
  TObjectFactory = function: TObject;
  TObjectInitializer = procedure(aObject: TObject);
  TObjectFinalizer = procedure(aObject: TObject);

  {**
   * TObjectPool
   *
   * @desc 通用对象池，支持对象复用和生命周期管理
   *       Generic object pool with object reuse and lifecycle management
   *}
  TObjectPool = class
  private
    FObjectClass: TClass;
    FFactory: TObjectFactory;
    FInitializer: TObjectInitializer;
    FFinalizer: TObjectFinalizer;
    FPool: array of TObject;
    FPoolSize: Integer;
    FCurrentCount: Integer;
    FMaxSize: Integer;
    FTotalCreated: Integer;
    FTotalReused: Integer;
    FBaseAllocator: IAllocator;

    function CreateNewObject: TObject;
    procedure InitializeObject(aObject: TObject);
    procedure FinalizeObject(aObject: TObject);

  public
    {**
     * Create
     *
     * @desc 创建对象池
     *       Create object pool
     *
     * @param aObjectClass 对象类型 Object class
     * @param aMaxSize 最大池大小 Maximum pool size
     * @param aFactory 对象工厂函数 Object factory function (optional)
     * @param aInitializer 对象初始化函数 Object initializer (optional)
     * @param aFinalizer 对象清理函数 Object finalizer (optional)
     * @param aAllocator 基础分配器 Base allocator (optional)
     *}
    constructor Create(aObjectClass: TClass; aMaxSize: Integer = 100;
      aFactory: TObjectFactory = nil; aInitializer: TObjectInitializer = nil;
      aFinalizer: TObjectFinalizer = nil; aAllocator: IAllocator = nil);

    {**
     * Destroy
     *
     * @desc 销毁对象池
     *       Destroy object pool
     *}
    destructor Destroy; override;

    {**
     * Get
     *
     * @desc 从池中获取对象
     *       Get object from pool
     *
     * @return 对象实例 Object instance
     *}
    function Get: TObject;

    {**
     * Return
     *
     * @desc 将对象返回到池中
     *       Return object to pool
     *
     * @param aObject 要返回的对象 Object to return
     *}
    procedure Return(aObject: TObject);

    {**
     * Clear
     *
     * @desc 清空池中所有对象
     *       Clear all objects in pool
     *}
    procedure Clear;

    {**
     * Preallocate
     *
     * @desc 预分配指定数量的对象
     *       Preallocate specified number of objects
     *
     * @param aCount 预分配数量 Number to preallocate
     *}
    procedure Preallocate(aCount: Integer);

    // 属性 Properties
    property ObjectClass: TClass read FObjectClass;
    property MaxSize: Integer read FMaxSize;
    property CurrentCount: Integer read FCurrentCount;
    property TotalCreated: Integer read FTotalCreated;
    property TotalReused: Integer read FTotalReused;

    // 状态查询 Status queries
    function IsEmpty: Boolean;
    function IsFull: Boolean;
    function GetReuseRatio: Single; // 复用率
  end;

  {**
   * TTypedObjectPool<T>
   *
   * @desc 类型安全的泛型对象池
   *       Type-safe generic object pool
   *}
  generic TTypedObjectPool<T: TObject> = class(TObjectPool)
  public
    function Get: T; reintroduce;
    procedure Return(aObject: T); reintroduce;
  end;

implementation

{ TObjectPool }

constructor TObjectPool.Create(aObjectClass: TClass; aMaxSize: Integer;
  aFactory: TObjectFactory; aInitializer: TObjectInitializer;
  aFinalizer: TObjectFinalizer; aAllocator: IAllocator);
begin
  inherited Create;

  if aObjectClass = nil then
    raise Exception.Create('Object class cannot be nil');
  if aMaxSize <= 0 then
    raise Exception.Create('Max size must be positive');

  FObjectClass := aObjectClass;
  FMaxSize := aMaxSize;
  FFactory := aFactory;
  FInitializer := aInitializer;
  FFinalizer := aFinalizer;
  FCurrentCount := 0;
  FTotalCreated := 0;
  FTotalReused := 0;

  if aAllocator = nil then
    FBaseAllocator := fafafa.core.mem.allocator.GetRtlAllocator
  else
    FBaseAllocator := aAllocator;

  SetLength(FPool, aMaxSize);
end;

destructor TObjectPool.Destroy;
begin
  Clear;
  SetLength(FPool, 0);
  inherited Destroy;
end;

function TObjectPool.CreateNewObject: TObject;
begin
  if Assigned(FFactory) then
    Result := FFactory()
  else
    Result := FObjectClass.Create;

  Inc(FTotalCreated);
end;

procedure TObjectPool.InitializeObject(aObject: TObject);
begin
  if Assigned(FInitializer) then
    FInitializer(aObject);
end;

procedure TObjectPool.FinalizeObject(aObject: TObject);
begin
  if Assigned(FFinalizer) then
    FFinalizer(aObject);
end;

function TObjectPool.Get: TObject;
begin
  if FCurrentCount > 0 then
  begin
    // 从池中获取现有对象
    Dec(FCurrentCount);
    Result := FPool[FCurrentCount];
    FPool[FCurrentCount] := nil;
    Inc(FTotalReused);
  end
  else
  begin
    // 创建新对象
    Result := CreateNewObject;
  end;

  // 初始化对象
  InitializeObject(Result);
end;

procedure TObjectPool.Return(aObject: TObject);
begin
  if aObject = nil then Exit;

  // 检查对象类型
  if not aObject.InheritsFrom(FObjectClass) then
    raise Exception.Create('Object type mismatch');

  // 清理对象
  FinalizeObject(aObject);

  // 如果池未满，将对象放回池中
  if FCurrentCount < FMaxSize then
  begin
    FPool[FCurrentCount] := aObject;
    Inc(FCurrentCount);
  end
  else
  begin
    // 池已满，直接销毁对象
    aObject.Free;
  end;
end;

procedure TObjectPool.Clear;
var
  I: Integer;
begin
  for I := 0 to FCurrentCount - 1 do
  begin
    if FPool[I] <> nil then
    begin
      FPool[I].Free;
      FPool[I] := nil;
    end;
  end;
  FCurrentCount := 0;
end;

procedure TObjectPool.Preallocate(aCount: Integer);
var
  I: Integer;
  LObject: TObject;
begin
  if aCount <= 0 then Exit;
  if aCount > FMaxSize then aCount := FMaxSize;

  for I := 1 to aCount do
  begin
    if FCurrentCount >= FMaxSize then Break;

    LObject := CreateNewObject;
    FPool[FCurrentCount] := LObject;
    Inc(FCurrentCount);
  end;
end;

function TObjectPool.IsEmpty: Boolean;
begin
  Result := FCurrentCount = 0;
end;

function TObjectPool.IsFull: Boolean;
begin
  Result := FCurrentCount = FMaxSize;
end;

function TObjectPool.GetReuseRatio: Single;
begin
  if FTotalCreated = 0 then
  begin
    Result := 0.0;
    Exit;
  end;

  Result := (FTotalReused / (FTotalCreated + FTotalReused)) * 100;
end;

{ TTypedObjectPool<T> }

function TTypedObjectPool.Get: T;
begin
  Result := T(inherited Get);
end;

procedure TTypedObjectPool.Return(aObject: T);
begin
  inherited Return(aObject);
end;

end.
