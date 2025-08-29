{$CODEPAGE UTF8}
program example_system_info;

uses
  SysUtils, fafafa.core.os;

procedure ShowCPUInfo;
var
  Info: TCPUInfo;
begin
  WriteLn('=== CPU 信息 ===');
  if os_cpu_info_ex(Info) then
  begin
    WriteLn('型号: ', Info.Model);
    WriteLn('厂商: ', Info.Vendor);
    WriteLn('架构: ', Info.Architecture);
    WriteLn('物理核心: ', Info.Cores);
    WriteLn('逻辑线程: ', Info.Threads);
    if Info.Frequency > 0 then
      WriteLn('频率: ', Info.Frequency div 1000000, ' MHz')
    else
      WriteLn('频率: 未知');
    if Info.Usage >= 0 then
      WriteLn('使用率: ', Format('%.1f%%', [Info.Usage * 100]))
    else
      WriteLn('使用率: 未知');
  end
  else
    WriteLn('无法获取 CPU 信息');
  WriteLn;
end;

procedure ShowMemoryInfo;
var
  Info: TMemoryInfo;
begin
  WriteLn('=== 内存信息 ===');
  if os_memory_info_ex(Info) then
  begin
    WriteLn('总内存: ', Format('%.2f GB', [Info.Total / (1024*1024*1024)]));
    WriteLn('可用内存: ', Format('%.2f GB', [Info.Available / (1024*1024*1024)]));
    WriteLn('已用内存: ', Format('%.2f GB', [Info.Used / (1024*1024*1024)]));
    WriteLn('空闲内存: ', Format('%.2f GB', [Info.Free / (1024*1024*1024)]));
    if Info.Cached > 0 then
      WriteLn('缓存内存: ', Format('%.2f GB', [Info.Cached / (1024*1024*1024)]));
    if Info.Pressure >= 0 then
      WriteLn('内存压力: ', Format('%.1f%%', [Info.Pressure * 100]))
    else
      WriteLn('内存压力: 未知');
  end
  else
    WriteLn('无法获取内存信息');
  WriteLn;
end;

procedure ShowStorageInfo;
var
  Info: TStorageInfoArray;
  i: Integer;
begin
  WriteLn('=== 存储信息 ===');
  if os_storage_info_ex(Info) then
  begin
    if Length(Info) = 0 then
      WriteLn('暂无存储设备信息（功能待实现）')
    else
    begin
      for i := 0 to High(Info) do
      begin
        WriteLn('设备 ', i + 1, ':');
        WriteLn('  路径: ', Info[i].Path);
        WriteLn('  文件系统: ', Info[i].FileSystem);
        WriteLn('  总空间: ', Format('%.2f GB', [Info[i].Total / (1024*1024*1024)]));
        WriteLn('  可用空间: ', Format('%.2f GB', [Info[i].Available / (1024*1024*1024)]));
        WriteLn('  已用空间: ', Format('%.2f GB', [Info[i].Used / (1024*1024*1024)]));
        WriteLn('  可移动: ', BoolToStr(Info[i].IsRemovable, True));
        WriteLn('  只读: ', BoolToStr(Info[i].IsReadOnly, True));
      end;
    end;
  end
  else
    WriteLn('无法获取存储信息');
  WriteLn;
end;

procedure ShowNetworkInfo;
var
  Info: TNetworkInterfaceArray;
  i, j: Integer;
begin
  WriteLn('=== 网络接口信息 ===');
  if os_network_interfaces_ex(Info) then
  begin
    if Length(Info) = 0 then
      WriteLn('暂无网络接口信息（功能待实现）')
    else
    begin
      for i := 0 to High(Info) do
      begin
        WriteLn('接口 ', i + 1, ':');
        WriteLn('  名称: ', Info[i].Name);
        WriteLn('  显示名称: ', Info[i].DisplayName);
        WriteLn('  MAC 地址: ', Info[i].HardwareAddress);
        WriteLn('  状态: ', BoolToStr(Info[i].IsUp, '启用', '禁用'));
        WriteLn('  回环: ', BoolToStr(Info[i].IsLoopback, True));
        WriteLn('  无线: ', BoolToStr(Info[i].IsWireless, True));
        if Info[i].MTU > 0 then
          WriteLn('  MTU: ', Info[i].MTU);
        if Length(Info[i].IPAddresses) > 0 then
        begin
          WriteLn('  IP 地址:');
          for j := 0 to High(Info[i].IPAddresses) do
            WriteLn('    ', Info[i].IPAddresses[j]);
        end;
      end;
    end;
  end
  else
    WriteLn('无法获取网络接口信息');
  WriteLn;
end;

procedure ShowSystemLoad;
var
  Info: TSystemLoad;
begin
  WriteLn('=== 系统负载 ===');
  if os_system_load_ex(Info) then
  begin
    if Info.Load1Min >= 0 then
      WriteLn('1分钟负载: ', Format('%.2f', [Info.Load1Min]))
    else
      WriteLn('1分钟负载: 未知');
    if Info.Load5Min >= 0 then
      WriteLn('5分钟负载: ', Format('%.2f', [Info.Load5Min]))
    else
      WriteLn('5分钟负载: 未知');
    if Info.Load15Min >= 0 then
      WriteLn('15分钟负载: ', Format('%.2f', [Info.Load15Min]))
    else
      WriteLn('15分钟负载: 未知');
    if Info.RunningProcesses >= 0 then
      WriteLn('运行进程数: ', Info.RunningProcesses)
    else
      WriteLn('运行进程数: 未知');
    if Info.TotalProcesses >= 0 then
      WriteLn('总进程数: ', Info.TotalProcesses)
    else
      WriteLn('总进程数: 未知');
  end
  else
    WriteLn('无法获取系统负载信息');
  WriteLn;
end;

procedure ShowSystemInfo;
var
  Info: TSystemInfo;
begin
  WriteLn('=== 综合系统信息 ===');
  if os_system_info_ex(Info) then
  begin
    WriteLn('操作系统: ', Info.Platform.OS);
    WriteLn('架构: ', Info.Platform.Architecture);
    WriteLn('CPU 数量: ', Info.Platform.CPUCount);
    WriteLn('OS 版本: ', Info.OSVersion.Name, ' ', Info.OSVersion.VersionString);
    if Info.BootTime > 0 then
      WriteLn('启动时间: ', DateTimeToStr(Info.BootTime));
    if Info.Uptime > 0 then
      WriteLn('运行时间: ', Info.Uptime div 3600, ' 小时 ', (Info.Uptime mod 3600) div 60, ' 分钟');
    WriteLn;
    
    WriteLn('CPU 型号: ', Info.CPU.Model);
    WriteLn('内存总量: ', Format('%.2f GB', [Info.Memory.Total / (1024*1024*1024)]));
    WriteLn('存储设备数: ', Length(Info.Storage));
    WriteLn('网络接口数: ', Length(Info.Network));
  end
  else
    WriteLn('无法获取综合系统信息');
  WriteLn;
end;

begin
  WriteLn('fafafa.core.os 增强系统信息 API 示例');
  WriteLn('=====================================');
  WriteLn;
  
  ShowCPUInfo;
  ShowMemoryInfo;
  ShowStorageInfo;
  ShowNetworkInfo;
  ShowSystemLoad;
  ShowSystemInfo;
  
  WriteLn('注意：部分功能（如存储设备枚举、网络接口枚举、系统负载监控）');
  WriteLn('      目前返回占位符数据，将在后续版本中实现平台特定的功能。');
end.
