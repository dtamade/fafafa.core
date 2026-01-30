program example_namedSemaphore_crossprocess;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils, Classes,
  fafafa.core.sync.namedSemaphore;

const
  SEMAPHORE_NAME = 'CrossProcessSemaphoreDemo';
  RESOURCE_POOL_SIZE = 3;

procedure ShowUsage;
begin
  WriteLn('fafafa.core.sync.namedSemaphore 跨进程演示');
  WriteLn('==========================================');
  WriteLn;
  WriteLn('用法:');
  WriteLn('  ', ExtractFileName(ParamStr(0)), ' <模式> [参数]');
  WriteLn;
  WriteLn('模式:');
  WriteLn('  server          - 启动服务器模式（资源提供者）');
  WriteLn('  client <id>     - 启动客户端模式（资源消费者）');
  WriteLn('  producer <count> - 启动生产者模式（释放指定数量的资源）');
  WriteLn('  consumer <id>   - 启动消费者模式（消费资源）');
  WriteLn('  monitor         - 启动监控模式（观察信号量状态）');
  WriteLn('  cleanup         - 清理模式（重置信号量）');
  WriteLn;
  WriteLn('示例:');
  WriteLn('  # 终端1: 启动服务器');
  WriteLn('  ', ExtractFileName(ParamStr(0)), ' server');
  WriteLn;
  WriteLn('  # 终端2-4: 启动多个客户端');
  WriteLn('  ', ExtractFileName(ParamStr(0)), ' client 1');
  WriteLn('  ', ExtractFileName(ParamStr(0)), ' client 2');
  WriteLn('  ', ExtractFileName(ParamStr(0)), ' client 3');
  WriteLn;
  WriteLn('  # 终端5: 监控状态');
  WriteLn('  ', ExtractFileName(ParamStr(0)), ' monitor');
end;

procedure RunServer;
var
  LSemaphore: INamedSemaphore;
  LInput: string;
begin
  WriteLn('=== 服务器模式 ===');
  WriteLn('创建资源池信号量（最大', RESOURCE_POOL_SIZE, '个资源）...');
  
  // 创建计数信号量作为资源池
  LSemaphore := CreateCountingSemaphore(SEMAPHORE_NAME, RESOURCE_POOL_SIZE, RESOURCE_POOL_SIZE);
  WriteLn('信号量已创建: ', LSemaphore.GetName);
  WriteLn('最大资源数: ', LSemaphore.GetMaxCount);
  
  var LCurrentCount := LSemaphore.GetCurrentCount;
  if LCurrentCount >= 0 then
    WriteLn('当前可用资源: ', LCurrentCount);
  
  WriteLn;
  WriteLn('服务器正在运行...');
  WriteLn('现在可以启动客户端来消费资源');
  WriteLn('输入命令:');
  WriteLn('  add <count>  - 添加资源');
  WriteLn('  status       - 显示状态');
  WriteLn('  quit         - 退出');
  WriteLn;
  
  repeat
    Write('server> ');
    ReadLn(LInput);
    LInput := Trim(LowerCase(LInput));
    
    if LInput = 'quit' then
      Break
    else if LInput = 'status' then
    begin
      LCurrentCount := LSemaphore.GetCurrentCount;
      if LCurrentCount >= 0 then
        WriteLn('当前可用资源: ', LCurrentCount, '/', LSemaphore.GetMaxCount)
      else
        WriteLn('无法查询当前资源数（平台不支持）');
    end
    else if Pos('add ', LInput) = 1 then
    begin
      var LCountStr := Copy(LInput, 5, Length(LInput));
      var LCount := StrToIntDef(LCountStr, 0);
      if LCount > 0 then
      begin
        try
          LSemaphore.Release(LCount);
          WriteLn('已添加 ', LCount, ' 个资源');
        except
          on E: Exception do
            WriteLn('添加资源失败: ', E.Message);
        end;
      end
      else
        WriteLn('无效的资源数量: ', LCountStr);
    end
    else if LInput <> '' then
      WriteLn('未知命令: ', LInput);
      
  until False;
  
  WriteLn('服务器已退出');
end;

procedure RunClient(const AClientId: string);
var
  LSemaphore: INamedSemaphore;
  LGuard: INamedSemaphoreGuard;
  LInput: string;
begin
  WriteLn('=== 客户端模式 (ID: ', AClientId, ') ===');
  WriteLn('连接到资源池信号量...');
  
  // 连接到现有的信号量
  LSemaphore := CreateNamedSemaphore(SEMAPHORE_NAME);
  WriteLn('已连接到信号量: ', LSemaphore.GetName);
  
  WriteLn;
  WriteLn('客户端 ', AClientId, ' 正在运行...');
  WriteLn('输入命令:');
  WriteLn('  get          - 获取资源（阻塞）');
  WriteLn('  try          - 尝试获取资源（非阻塞）');
  WriteLn('  timeout <ms> - 带超时获取资源');
  WriteLn('  release      - 释放当前资源');
  WriteLn('  status       - 显示状态');
  WriteLn('  quit         - 退出');
  WriteLn;
  
  repeat
    Write('client[', AClientId, ']> ');
    ReadLn(LInput);
    LInput := Trim(LowerCase(LInput));
    
    if LInput = 'quit' then
      Break
    else if LInput = 'get' then
    begin
      if Assigned(LGuard) then
        WriteLn('已经持有资源，请先释放')
      else
      begin
        WriteLn('正在获取资源（阻塞）...');
        try
          LGuard := LSemaphore.Wait;
          WriteLn('成功获取资源！');
        except
          on E: Exception do
            WriteLn('获取资源失败: ', E.Message);
        end;
      end;
    end
    else if LInput = 'try' then
    begin
      if Assigned(LGuard) then
        WriteLn('已经持有资源，请先释放')
      else
      begin
        WriteLn('尝试获取资源（非阻塞）...');
        LGuard := LSemaphore.TryWait;
        if Assigned(LGuard) then
          WriteLn('成功获取资源！')
        else
          WriteLn('无可用资源');
      end;
    end
    else if Pos('timeout ', LInput) = 1 then
    begin
      if Assigned(LGuard) then
        WriteLn('已经持有资源，请先释放')
      else
      begin
        var LTimeoutStr := Copy(LInput, 9, Length(LInput));
        var LTimeout := StrToIntDef(LTimeoutStr, 1000);
        WriteLn('尝试获取资源（超时 ', LTimeout, ' 毫秒）...');
        var LStartTime := GetTickCount64;
        LGuard := LSemaphore.TryWaitFor(LTimeout);
        var LElapsed := GetTickCount64 - LStartTime;
        if Assigned(LGuard) then
          WriteLn('成功获取资源！耗时 ', LElapsed, ' 毫秒')
        else
          WriteLn('获取资源超时，耗时 ', LElapsed, ' 毫秒');
      end;
    end
    else if LInput = 'release' then
    begin
      if Assigned(LGuard) then
      begin
        LGuard := nil;
        WriteLn('资源已释放');
      end
      else
        WriteLn('当前未持有资源');
    end
    else if LInput = 'status' then
    begin
      WriteLn('客户端状态:');
      WriteLn('  ID: ', AClientId);
      WriteLn('  持有资源: ', IfThen(Assigned(LGuard), '是', '否'));
      var LCurrentCount := LSemaphore.GetCurrentCount;
      if LCurrentCount >= 0 then
        WriteLn('  可用资源: ', LCurrentCount, '/', LSemaphore.GetMaxCount)
      else
        WriteLn('  可用资源: 无法查询（平台不支持）');
    end
    else if LInput <> '' then
      WriteLn('未知命令: ', LInput);
      
  until False;
  
  // 清理资源
  if Assigned(LGuard) then
  begin
    LGuard := nil;
    WriteLn('退出时自动释放了资源');
  end;
  
  WriteLn('客户端 ', AClientId, ' 已退出');
end;

procedure RunProducer(ACount: Integer);
var
  LSemaphore: INamedSemaphore;
begin
  WriteLn('=== 生产者模式 ===');
  WriteLn('连接到信号量并释放 ', ACount, ' 个资源...');
  
  LSemaphore := CreateNamedSemaphore(SEMAPHORE_NAME);
  
  try
    LSemaphore.Release(ACount);
    WriteLn('成功释放 ', ACount, ' 个资源');
    
    var LCurrentCount := LSemaphore.GetCurrentCount;
    if LCurrentCount >= 0 then
      WriteLn('当前可用资源: ', LCurrentCount, '/', LSemaphore.GetMaxCount);
      
  except
    on E: Exception do
      WriteLn('释放资源失败: ', E.Message);
  end;
end;

procedure RunConsumer(const AConsumerId: string);
var
  LSemaphore: INamedSemaphore;
  LGuard: INamedSemaphoreGuard;
begin
  WriteLn('=== 消费者模式 (ID: ', AConsumerId, ') ===');
  WriteLn('连接到信号量并消费一个资源...');
  
  LSemaphore := CreateNamedSemaphore(SEMAPHORE_NAME);
  
  WriteLn('尝试获取资源...');
  LGuard := LSemaphore.TryWait;
  
  if Assigned(LGuard) then
  begin
    WriteLn('成功获取资源！');
    WriteLn('模拟使用资源 5 秒...');
    
    var I: Integer;
    for I := 1 to 5 do
    begin
      WriteLn('使用资源中... (', I, '/5)');
      Sleep(1000);
    end;
    
    LGuard := nil;
    WriteLn('资源已释放');
    
    var LCurrentCount := LSemaphore.GetCurrentCount;
    if LCurrentCount >= 0 then
      WriteLn('当前可用资源: ', LCurrentCount, '/', LSemaphore.GetMaxCount);
  end
  else
    WriteLn('无可用资源');
end;

procedure RunMonitor;
var
  LSemaphore: INamedSemaphore;
begin
  WriteLn('=== 监控模式 ===');
  WriteLn('连接到信号量并监控状态...');
  WriteLn('按 Ctrl+C 退出监控');
  WriteLn;
  
  try
    LSemaphore := CreateNamedSemaphore(SEMAPHORE_NAME);
    WriteLn('已连接到信号量: ', LSemaphore.GetName);
    WriteLn('最大资源数: ', LSemaphore.GetMaxCount);
    WriteLn;
    
    var LLastCount := -2; // 初始值，确保第一次显示
    repeat
      var LCurrentCount := LSemaphore.GetCurrentCount;
      if LCurrentCount <> LLastCount then
      begin
        WriteLn('[', FormatDateTime('hh:nn:ss', Now), '] 可用资源: ', 
                IfThen(LCurrentCount >= 0, IntToStr(LCurrentCount), '未知'), 
                '/', LSemaphore.GetMaxCount);
        LLastCount := LCurrentCount;
      end;
      Sleep(500); // 每500毫秒检查一次
    until False;
    
  except
    on E: Exception do
      WriteLn('监控失败: ', E.Message);
  end;
end;

procedure RunCleanup;
var
  LSemaphore: INamedSemaphore;
begin
  WriteLn('=== 清理模式 ===');
  WriteLn('重置信号量到初始状态...');
  
  try
    // 创建新的信号量实例来重置状态
    LSemaphore := CreateCountingSemaphore(SEMAPHORE_NAME, RESOURCE_POOL_SIZE, RESOURCE_POOL_SIZE);
    WriteLn('信号量已重置');
    WriteLn('可用资源: ', RESOURCE_POOL_SIZE, '/', RESOURCE_POOL_SIZE);
  except
    on E: Exception do
      WriteLn('清理失败: ', E.Message);
  end;
end;

var
  LMode: string;
  LParam: string;
begin
  if ParamCount < 1 then
  begin
    ShowUsage;
    Exit;
  end;
  
  LMode := LowerCase(ParamStr(1));
  
  try
    case LMode of
      'server':
        RunServer;
      'client':
        begin
          if ParamCount >= 2 then
            LParam := ParamStr(2)
          else
            LParam := '1';
          RunClient(LParam);
        end;
      'producer':
        begin
          if ParamCount >= 2 then
            LParam := ParamStr(2)
          else
            LParam := '1';
          RunProducer(StrToIntDef(LParam, 1));
        end;
      'consumer':
        begin
          if ParamCount >= 2 then
            LParam := ParamStr(2)
          else
            LParam := '1';
          RunConsumer(LParam);
        end;
      'monitor':
        RunMonitor;
      'cleanup':
        RunCleanup;
    else
      WriteLn('未知模式: ', LMode);
      WriteLn;
      ShowUsage;
    end;
    
  except
    on E: Exception do
    begin
      WriteLn('发生异常：', E.ClassName, ' - ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
