program example_object_pool;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}
{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}

uses
  SysUtils,
  fafafa.core.collections.base,
  fafafa.core.collections.vec;

type
  { 模拟数据库连接 }
  TDatabaseConnection = class
  private
    FID: Integer;
    FInUse: Boolean;
  public
    constructor Create(aID: Integer);
    procedure Execute(const aSQL: string);
    property ID: Integer read FID;
    property InUse: Boolean read FInUse write FInUse;
  end;

  { 对象池 }
  generic TObjectPool<T: class> = class
  private
    FAvailable: specialize IVec<T>;
    FInUse: specialize IVec<T>;
    FMaxSize: SizeUInt;
    FCreateFunc: function: T;
  public
    constructor Create(aCreateFunc: function: T; aInitialSize, aMaxSize: SizeUInt);
    destructor Destroy; override;
    function Acquire: T;
    procedure Release(aObj: T);
    procedure PrintStats;
  end;

constructor TDatabaseConnection.Create(aID: Integer);
begin
  FID := aID;
  FInUse := False;
  WriteLn(Format('[创建] 数据库连接 #%d', [FID]));
end;

procedure TDatabaseConnection.Execute(const aSQL: string);
begin
  WriteLn(Format('[执行] 连接 #%d: %s', [FID, aSQL]));
  Sleep(10); // 模拟查询耗时
end;

constructor TObjectPool.Create(aCreateFunc: function: T; aInitialSize, aMaxSize: SizeUInt);
var
  i: SizeUInt;
begin
  FCreateFunc := aCreateFunc;
  FMaxSize := aMaxSize;
  FAvailable := specialize MakeVec<T>(aInitialSize);
  FInUse := specialize MakeVec<T>();
  
  // 预创建对象
  for i := 0 to aInitialSize - 1 do
    FAvailable.Append(FCreateFunc());
end;

destructor TObjectPool.Destroy;
var
  i: SizeUInt;
begin
  // 释放所有对象
  for i := 0 to FAvailable.GetCount - 1 do
    FAvailable[i].Free;
  for i := 0 to FInUse.GetCount - 1 do
    FInUse[i].Free;
  inherited;
end;

function TObjectPool.Acquire: T;
begin
  if FAvailable.GetCount > 0 then
  begin
    // 从可用池获取
    Result := FAvailable[FAvailable.GetCount - 1];
    FAvailable.RemoveAt(FAvailable.GetCount - 1);
  end
  else if FInUse.GetCount < FMaxSize then
  begin
    // 池空但未达上限，创建新对象
    Result := FCreateFunc();
    WriteLn('[扩展] 池已扩展');
  end
  else
    raise Exception.Create('对象池已满，无可用对象');
  
  FInUse.Append(Result);
end;

procedure TObjectPool.Release(aObj: T);
var
  i: SizeUInt;
begin
  // 从使用中移除
  for i := 0 to FInUse.GetCount - 1 do
    if FInUse[i] = aObj then
    begin
      FInUse.RemoveAt(i);
      Break;
    end;
  
  // 归还到可用池
  FAvailable.Append(aObj);
end;

procedure TObjectPool.PrintStats;
begin
  WriteLn(Format('对象池状态: 可用=%d, 使用中=%d, 总数=%d/%d', [
    FAvailable.GetCount,
    FInUse.GetCount,
    FAvailable.GetCount + FInUse.GetCount,
    FMaxSize
  ]));
end;

var
  LNextID: Integer = 1;

function CreateConnection: TDatabaseConnection;
begin
  Result := TDatabaseConnection.Create(LNextID);
  Inc(LNextID);
end;

var
  LPool: specialize TObjectPool<TDatabaseConnection>;
  LConn1, LConn2, LConn3: TDatabaseConnection;
begin
  WriteLn('=== 对象池示例（数据库连接池）===');
  WriteLn;
  
  LPool := specialize TObjectPool<TDatabaseConnection>.Create(@CreateConnection, 2, 5);
  try
    WriteLn('--- 初始状态 ---');
    LPool.PrintStats;
    WriteLn;
    
    // 场景1：获取连接
    WriteLn('--- 场景1：获取连接 ---');
    LConn1 := LPool.Acquire;
    LConn1.Execute('SELECT * FROM users');
    LPool.PrintStats;
    WriteLn;
    
    // 场景2：获取多个连接
    WriteLn('--- 场景2：获取多个连接 ---');
    LConn2 := LPool.Acquire;
    LConn2.Execute('SELECT * FROM orders');
    LConn3 := LPool.Acquire; // 触发扩展
    LConn3.Execute('SELECT * FROM products');
    LPool.PrintStats;
    WriteLn;
    
    // 场景3：归还连接
    WriteLn('--- 场景3：归还连接 ---');
    LPool.Release(LConn1);
    LPool.Release(LConn2);
    LPool.PrintStats;
    WriteLn;
    
    // 场景4：复用连接
    WriteLn('--- 场景4：复用连接（无需创建新对象）---');
    LConn1 := LPool.Acquire; // 复用之前的连接
    LConn1.Execute('UPDATE users SET status=1');
    LPool.PrintStats;
    WriteLn;
    
    WriteLn('=== 示例完成 ===');
    WriteLn('提示：对象池避免频繁创建/销毁对象，提升性能');
  finally
    LPool.Free;
  end;
end.

