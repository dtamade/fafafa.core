{$CODEPAGE UTF8}
unit Test_enhanced_object_pool;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes, fpcunit, testregistry, fafafa.core.mem.enhancedObjectPool;

type
  // 测试对象类
  TTestObject = class
  private
    FValue: Integer;
    FName: string;
    FValid: Boolean;
  public
    constructor Create; overload;
    constructor Create(aValue: Integer; const aName: string); overload;
    procedure Reset;
    property Value: Integer read FValue write FValue;
    property Name: string read FName write FName;
    property Valid: Boolean read FValid write FValid;
  end;

  TTestCase_EnhancedObjectPool = class(TTestCase)
  private
    function CreateTestPolicy: TObjectPoolPolicy;
    function TestObjectValidator(aObject: TObject): Boolean;
    procedure TestLifecycleCallback(aPool: TEnhancedObjectPool; aObject: TObject; 
      aOldState, aNewState: TObjectLifecycleState);
  published
    procedure Test_Basic_Operations;
    procedure Test_Policy_Configuration;
    procedure Test_Warmup_Operations;
    procedure Test_Validation_System;
    procedure Test_Lifecycle_Management;
    procedure Test_Statistics_Tracking;
    procedure Test_Auto_Resize;
    procedure Test_Cleanup_Operations;
    procedure Test_Manager_Operations;
    procedure Test_TypedPool;
  end;

implementation

{ TTestObject }

constructor TTestObject.Create;
begin
  inherited Create;
  FValue := 0;
  FName := '';
  FValid := True;
end;

constructor TTestObject.Create(aValue: Integer; const aName: string);
begin
  inherited Create;
  FValue := aValue;
  FName := aName;
  FValid := True;
end;

procedure TTestObject.Reset;
begin
  FValue := 0;
  FName := '';
  FValid := True;
end;

{ TTestCase_EnhancedObjectPool }

function TTestCase_EnhancedObjectPool.CreateTestPolicy: TObjectPoolPolicy;
begin
  Result := CreateDefaultPolicy;
  Result.InitialSize := 3;
  Result.MaxSize := 10;
  Result.MinSize := 1;
  Result.EnableStatistics := True;
  Result.EnableValidation := True;
end;

function TTestCase_EnhancedObjectPool.TestObjectValidator(aObject: TObject): Boolean;
begin
  Result := (aObject <> nil) and (aObject is TTestObject) and TTestObject(aObject).Valid;
end;

procedure TTestCase_EnhancedObjectPool.TestLifecycleCallback(aPool: TEnhancedObjectPool; 
  aObject: TObject; aOldState, aNewState: TObjectLifecycleState);
begin
  // 简单的生命周期回调，实际应用中可以记录日志等
  WriteLn(Format('Object lifecycle: %s -> %s', [
    GetEnumName(TypeInfo(TObjectLifecycleState), Ord(aOldState)),
    GetEnumName(TypeInfo(TObjectLifecycleState), Ord(aNewState))
  ]));
end;

procedure TTestCase_EnhancedObjectPool.Test_Basic_Operations;
var
  pool: TEnhancedObjectPool;
  policy: TObjectPoolPolicy;
  obj1, obj2: TTestObject;
begin
  policy := CreateTestPolicy;
  pool := TEnhancedObjectPool.Create(TTestObject, policy);
  try
    AssertEquals('Initial size should match policy', policy.InitialSize, pool.CurrentCount);
    AssertFalse('Should not be empty after warmup', pool.IsEmpty);
    
    // 获取对象
    obj1 := TTestObject(pool.Get);
    AssertTrue('Get should return valid object', obj1 <> nil);
    AssertTrue('Object should be TTestObject', obj1 is TTestObject);
    
    obj2 := TTestObject(pool.Get);
    AssertTrue('Second get should succeed', obj2 <> nil);
    AssertTrue('Objects should be different', obj1 <> obj2);
    
    // 返回对象
    pool.Return(obj1);
    pool.Return(obj2);
    
    // 验证统计信息
    var stats := pool.GetStatistics;
    AssertTrue('Should have borrowed objects', stats.TotalBorrowed >= 2);
    AssertTrue('Should have returned objects', stats.TotalReturned >= 2);
    
  finally
    pool.Free;
  end;
end;

procedure TTestCase_EnhancedObjectPool.Test_Policy_Configuration;
var
  pool: TEnhancedObjectPool;
  policy: TObjectPoolPolicy;
begin
  policy := CreateTestPolicy;
  policy.EnableAutoGrow := True;
  policy.EnableAutoShrink := True;
  policy.GrowthFactor := 2.0;
  
  pool := TEnhancedObjectPool.Create(TTestObject, policy);
  try
    AssertEquals('Policy should be applied', policy.InitialSize, pool.CurrentCount);
    AssertEquals('Max size should match', policy.MaxSize, pool.MaxSize);
    
    // 测试策略访问
    var currentPolicy := pool.Policy;
    AssertEquals('Growth factor should match', policy.GrowthFactor, currentPolicy.GrowthFactor, 0.01);
    AssertTrue('Auto grow should be enabled', currentPolicy.EnableAutoGrow);
    
  finally
    pool.Free;
  end;
end;

procedure TTestCase_EnhancedObjectPool.Test_Warmup_Operations;
var
  pool: TEnhancedObjectPool;
  policy: TObjectPoolPolicy;
  initialCount: Integer;
begin
  policy := CreateTestPolicy;
  policy.InitialSize := 1; // 小的初始大小
  
  pool := TEnhancedObjectPool.Create(TTestObject, policy);
  try
    initialCount := pool.CurrentCount;
    
    // 预热更多对象
    pool.Warmup(3);
    AssertTrue('Count should increase after warmup', pool.CurrentCount > initialCount);
    AssertTrue('Should not exceed max size', pool.CurrentCount <= policy.MaxSize);
    
    // 测试异步预热（当前是同步实现）
    pool.Warmup(2, True);
    AssertTrue('Async warmup should work', pool.CurrentCount > 0);
    
  finally
    pool.Free;
  end;
end;

procedure TTestCase_EnhancedObjectPool.Test_Validation_System;
var
  pool: TEnhancedObjectPool;
  policy: TObjectPoolPolicy;
  obj: TTestObject;
  failedCount: Integer;
begin
  policy := CreateTestPolicy;
  policy.EnableValidation := True;
  
  pool := TEnhancedObjectPool.Create(TTestObject, policy);
  try
    pool.SetValidator(@TestObjectValidator);
    
    // 获取对象并使其无效
    obj := TTestObject(pool.Get);
    AssertTrue('Should get valid object', obj <> nil);
    
    obj.Valid := False; // 使对象无效
    
    // 返回无效对象应该导致对象被销毁而不是返回池中
    var beforeCount := pool.CurrentCount;
    pool.Return(obj);
    
    // 验证统计信息
    var stats := pool.GetStatistics;
    AssertTrue('Should have validation failures', stats.TotalValidationFailed > 0);
    
    // 手动验证
    failedCount := pool.Validate;
    AssertTrue('Validate should complete', failedCount >= 0);
    
  finally
    pool.Free;
  end;
end;

procedure TTestCase_EnhancedObjectPool.Test_Lifecycle_Management;
var
  pool: TEnhancedObjectPool;
  policy: TObjectPoolPolicy;
  obj: TTestObject;
  info: TPooledObjectInfo;
begin
  policy := CreateTestPolicy;
  
  pool := TEnhancedObjectPool.Create(TTestObject, policy);
  try
    pool.SetLifecycleCallback(@TestLifecycleCallback);
    
    // 获取对象
    obj := TTestObject(pool.Get);
    AssertTrue('Should get object', obj <> nil);
    
    // 获取对象信息
    AssertTrue('Should get object info', pool.GetObjectInfo(obj, info));
    AssertEquals('State should be active', Ord(olsActive), Ord(info.State));
    AssertTrue('Borrow count should be > 0', info.BorrowCount > 0);
    
    // 返回对象
    pool.Return(obj);
    
    // 再次获取对象信息
    AssertTrue('Should get updated object info', pool.GetObjectInfo(obj, info));
    AssertEquals('State should be returned', Ord(olsReturned), Ord(info.State));
    
  finally
    pool.Free;
  end;
end;

procedure TTestCase_EnhancedObjectPool.Test_Statistics_Tracking;
var
  pool: TEnhancedObjectPool;
  policy: TObjectPoolPolicy;
  obj: TTestObject;
  stats: TObjectPoolStatistics;
begin
  policy := CreateTestPolicy;
  policy.EnableStatistics := True;
  
  pool := TEnhancedObjectPool.Create(TTestObject, policy);
  try
    // 重置统计信息
    pool.ResetStatistics;
    stats := pool.GetStatistics;
    AssertEquals('Initial borrowed should be 0', 0, stats.TotalBorrowed);
    
    // 执行一些操作
    obj := TTestObject(pool.Get);
    pool.Return(obj);
    
    obj := TTestObject(pool.Get);
    pool.Return(obj);
    
    // 检查统计信息
    stats := pool.GetStatistics;
    AssertEquals('Should have 2 borrows', 2, stats.TotalBorrowed);
    AssertEquals('Should have 2 returns', 2, stats.TotalReturned);
    AssertTrue('Hit ratio should be reasonable', stats.HitRatio >= 0.0);
    
    // 测试健康评分
    var healthScore := pool.GetHealthScore;
    AssertTrue('Health score should be valid', (healthScore >= 0) and (healthScore <= 100));
    
  finally
    pool.Free;
  end;
end;

procedure TTestCase_EnhancedObjectPool.Test_Auto_Resize;
var
  pool: TEnhancedObjectPool;
  policy: TObjectPoolPolicy;
  initialSize: Integer;
begin
  policy := CreateTestPolicy;
  policy.EnableAutoGrow := True;
  policy.EnableAutoShrink := True;
  policy.InitialSize := 2;
  policy.MaxSize := 8;
  
  pool := TEnhancedObjectPool.Create(TTestObject, policy);
  try
    initialSize := pool.CurrentCount;
    
    // 测试手动调整大小
    AssertTrue('Resize should succeed', pool.Resize(5));
    AssertTrue('Size should change', pool.CurrentCount <> initialSize);
    
    // 测试调整到无效大小
    AssertFalse('Resize to invalid size should fail', pool.Resize(policy.MaxSize + 1));
    AssertFalse('Resize below min should fail', pool.Resize(0));
    
  finally
    pool.Free;
  end;
end;

procedure TTestCase_EnhancedObjectPool.Test_Cleanup_Operations;
var
  pool: TEnhancedObjectPool;
  policy: TObjectPoolPolicy;
  obj: TTestObject;
  cleanedCount: Integer;
begin
  policy := CreateTestPolicy;
  policy.MaxIdleTime := 1; // 1毫秒，很快过期
  
  pool := TEnhancedObjectPool.Create(TTestObject, policy);
  try
    // 获取并返回对象
    obj := TTestObject(pool.Get);
    pool.Return(obj);
    
    // 等待对象过期
    Sleep(10);
    
    // 执行清理
    cleanedCount := pool.Cleanup;
    AssertTrue('Cleanup should complete', cleanedCount >= 0);
    
  finally
    pool.Free;
  end;
end;

procedure TTestCase_EnhancedObjectPool.Test_Manager_Operations;
var
  manager: TObjectPoolManager;
  policy: TObjectPoolPolicy;
  pool: TEnhancedObjectPool;
  obj: TTestObject;
  stats: TObjectPoolStatistics;
begin
  manager := TObjectPoolManager.Create;
  try
    policy := CreateTestPolicy;
    
    // 注册池
    AssertTrue('Should register pool', manager.RegisterPool(TTestObject, policy));
    AssertFalse('Should not register duplicate', manager.RegisterPool(TTestObject, policy));
    
    // 获取池
    pool := manager.GetPool(TTestObject);
    AssertTrue('Should get registered pool', pool <> nil);
    
    // 通过管理器获取对象
    obj := TTestObject(manager.GetObject(TTestObject));
    AssertTrue('Should get object through manager', obj <> nil);
    
    // 通过管理器返回对象
    manager.ReturnObject(obj);
    
    // 获取汇总统计信息
    stats := manager.GetTotalStatistics;
    AssertTrue('Should have total statistics', stats.TotalBorrowed > 0);
    
    // 执行维护
    manager.PerformMaintenance;
    
  finally
    manager.Free;
  end;
end;

procedure TTestCase_EnhancedObjectPool.Test_TypedPool;
type
  TTestObjectPool = specialize TTypedEnhancedObjectPool<TTestObject>;
var
  pool: TTestObjectPool;
  policy: TObjectPoolPolicy;
  obj: TTestObject;
  info: TPooledObjectInfo;
begin
  policy := CreateTestPolicy;
  
  pool := TTestObjectPool.Create(TTestObject, policy);
  try
    // 类型安全的操作
    obj := pool.Get;
    AssertTrue('Typed get should work', obj <> nil);
    AssertTrue('Should be correct type', obj is TTestObject);
    
    // 类型安全的返回
    pool.Return(obj);
    
    // 类型安全的信息获取
    obj := pool.Get;
    AssertTrue('Typed GetObjectInfo should work', pool.GetObjectInfo(obj, info));
    pool.Return(obj);
    
  finally
    pool.Free;
  end;
end;

initialization
  RegisterTest(TTestCase_EnhancedObjectPool);

end.
