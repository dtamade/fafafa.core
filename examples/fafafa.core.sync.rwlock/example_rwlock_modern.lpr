program example_rwlock_modern;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  fafafa.core.sync.rwlock;

type
  // 示例：线程安全的配置管理器
  TConfigManager = class
  private
    FRWLock: IRWLock;
    FConfig: TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    
    // 现代化 API：使用 RAII 守卫
    function GetValue(const Key: string): string;
    procedure SetValue(const Key, Value: string);
    function GetAllKeys: TStringArray;
    procedure LoadFromFile(const FileName: string);
    
    // 传统 API：手动管理锁
    function GetValueManual(const Key: string): string;
    procedure SetValueManual(const Key, Value: string);
  end;

{ TConfigManager }

constructor TConfigManager.Create;
begin
  inherited Create;
  FRWLock := CreateRWLock;
  FConfig := TStringList.Create;
  FConfig.NameValueSeparator := '=';
end;

destructor TConfigManager.Destroy;
begin
  FConfig.Free;
  FRWLock := nil;
  inherited Destroy;
end;

// ===== 现代化 API：使用 RAII 守卫 =====

function TConfigManager.GetValue(const Key: string): string;
var
  ReadGuard: IRWLockReadGuard;
  Index: Integer;
begin
  ReadGuard := FRWLock.Read;  // 自动获取读锁
  
  Index := FConfig.IndexOfName(Key);
  if Index >= 0 then
    Result := FConfig.ValueFromIndex[Index]
  else
    Result := '';
  
  // ReadGuard 自动释放读锁
end;

procedure TConfigManager.SetValue(const Key, Value: string);
var
  WriteGuard: IRWLockWriteGuard;
begin
  WriteGuard := FRWLock.Write;  // 自动获取写锁
  
  FConfig.Values[Key] := Value;
  
  // WriteGuard 自动释放写锁
end;

function TConfigManager.GetAllKeys: TStringArray;
var
  ReadGuard: IRWLockReadGuard;
  i: Integer;
begin
  ReadGuard := FRWLock.Read;  // 自动获取读锁
  
  SetLength(Result, FConfig.Count);
  for i := 0 to FConfig.Count - 1 do
    Result[i] := FConfig.Names[i];
  
  // ReadGuard 自动释放读锁
end;

procedure TConfigManager.LoadFromFile(const FileName: string);
var
  WriteGuard: IRWLockWriteGuard;
begin
  WriteGuard := FRWLock.Write;  // 自动获取写锁
  
  if FileExists(FileName) then
    FConfig.LoadFromFile(FileName);
  
  // WriteGuard 自动释放写锁
end;

// ===== 传统 API：手动管理锁 =====

function TConfigManager.GetValueManual(const Key: string): string;
var
  Index: Integer;
begin
  FRWLock.AcquireRead;
  try
    Index := FConfig.IndexOfName(Key);
    if Index >= 0 then
      Result := FConfig.ValueFromIndex[Index]
    else
      Result := '';
  finally
    FRWLock.ReleaseRead;
  end;
end;

procedure TConfigManager.SetValueManual(const Key, Value: string);
begin
  FRWLock.AcquireWrite;
  try
    FConfig.Values[Key] := Value;
  finally
    FRWLock.ReleaseWrite;
  end;
end;

// ===== 示例使用 =====

procedure DemonstrateModernAPI;
var
  Config: TConfigManager;
  Keys: TStringArray;
  i: Integer;
begin
  WriteLn('=== 现代化 API 演示 ===');
  
  Config := TConfigManager.Create;
  try
    // 使用现代化 API（RAII 守卫）
    WriteLn('1. 设置配置值');
    Config.SetValue('database.host', 'localhost');
    Config.SetValue('database.port', '5432');
    Config.SetValue('database.name', 'myapp');
    Config.SetValue('app.version', '1.0.0');
    
    WriteLn('2. 读取配置值');
    WriteLn('  数据库主机: ', Config.GetValue('database.host'));
    WriteLn('  数据库端口: ', Config.GetValue('database.port'));
    WriteLn('  应用版本: ', Config.GetValue('app.version'));
    
    WriteLn('3. 获取所有配置键');
    Keys := Config.GetAllKeys;
    for i := 0 to High(Keys) do
      WriteLn('  ', Keys[i], ' = ', Config.GetValue(Keys[i]));
    
  finally
    Config.Free;
  end;
end;

procedure DemonstrateTraditionalAPI;
var
  Config: TConfigManager;
begin
  WriteLn('=== 传统 API 演示 ===');
  
  Config := TConfigManager.Create;
  try
    // 使用传统 API（手动管理锁）
    WriteLn('1. 手动管理锁的方式');
    Config.SetValueManual('manual.test', 'value');
    WriteLn('  手动设置的值: ', Config.GetValueManual('manual.test'));
    
  finally
    Config.Free;
  end;
end;

procedure DemonstrateConcurrentAccess;
var
  Config: TConfigManager;
  ReaderThreads: array[1..3] of TThreadID;
  WriterThread: TThreadID;
  i: Integer;
  
  function ReaderProc(Data: Pointer): PtrInt;
  var
    ThreadNum: Integer;
    j: Integer;
    Value: string;
  begin
    ThreadNum := PtrUInt(Data);
    
    for j := 1 to 10 do
    begin
      Value := Config.GetValue('shared.counter');
      WriteLn('读者线程 ', ThreadNum, ' 读取到: ', Value);
      Sleep(Random(50) + 10);
    end;
    
    Result := 0;
  end;
  
  function WriterProc(Data: Pointer): PtrInt;
  var
    i: Integer;
  begin
    for i := 1 to 5 do
    begin
      Config.SetValue('shared.counter', IntToStr(i));
      WriteLn('写者线程更新计数器为: ', i);
      Sleep(Random(100) + 50);
    end;
    
    Result := 0;
  end;
  
begin
  WriteLn('=== 并发访问演示 ===');
  
  Config := TConfigManager.Create;
  try
    Config.SetValue('shared.counter', '0');
    
    WriteLn('启动并发线程...');
    
    // 启动读者线程
    for i := 1 to 3 do
      ReaderThreads[i] := BeginThread(@ReaderProc, Pointer(i));
    
    // 启动写者线程
    WriterThread := BeginThread(@WriterProc, nil);
    
    // 等待所有线程完成
    for i := 1 to 3 do
      WaitForThreadTerminate(ReaderThreads[i], 5000);
    WaitForThreadTerminate(WriterThread, 5000);
    
    WriteLn('最终计数器值: ', Config.GetValue('shared.counter'));
    
  finally
    Config.Free;
  end;
end;

procedure DemonstratePerformance;
var
  Config: TConfigManager;
  StartTime: QWord;
  i: Integer;
  ReadOps, WriteOps: Integer;
begin
  WriteLn('=== 性能演示 ===');
  
  Config := TConfigManager.Create;
  try
    // 写性能测试
    WriteLn('1. 写操作性能测试');
    StartTime := GetTickCount64;
    WriteOps := 10000;
    
    for i := 1 to WriteOps do
      Config.SetValue('perf.key' + IntToStr(i mod 100), IntToStr(i));
    
    WriteLn('  ', WriteOps, ' 次写操作耗时: ', GetTickCount64 - StartTime, 'ms');
    WriteLn('  写吞吐量: ', Round(WriteOps * 1000.0 / (GetTickCount64 - StartTime)), ' ops/sec');
    
    // 读性能测试
    WriteLn('2. 读操作性能测试');
    StartTime := GetTickCount64;
    ReadOps := 50000;
    
    for i := 1 to ReadOps do
      Config.GetValue('perf.key' + IntToStr(i mod 100));
    
    WriteLn('  ', ReadOps, ' 次读操作耗时: ', GetTickCount64 - StartTime, 'ms');
    WriteLn('  读吞吐量: ', Round(ReadOps * 1000.0 / (GetTickCount64 - StartTime)), ' ops/sec');
    
  finally
    Config.Free;
  end;
end;

begin
  WriteLn('=== fafafa.core.sync.rwlock 现代化 API 示例 ===');
  WriteLn;
  
  try
    DemonstrateModernAPI;
    WriteLn;
    
    DemonstrateTraditionalAPI;
    WriteLn;
    
    DemonstrateConcurrentAccess;
    WriteLn;
    
    DemonstratePerformance;
    
    WriteLn;
    WriteLn('示例完成。按回车键退出...');
    ReadLn;
  except
    on E: Exception do
    begin
      WriteLn('错误: ', E.Message);
      WriteLn('按回车键退出...');
      ReadLn;
    end;
  end;
end.
