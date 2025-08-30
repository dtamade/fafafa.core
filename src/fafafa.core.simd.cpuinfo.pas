unit fafafa.core.simd.cpuinfo;

{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.simd.types;

// === CPU Feature Detection Facade ===
// 纯门面模式：委托给平台特定的实现模块

type
  // Array type for backend list
  TSimdBackendArray = array of TSimdBackend;

// === 公共门面 API ===

// Get comprehensive CPU information (thread-safe)
function GetCPUInfo: TCPUInfo;

// Check if specific backends are available
function IsBackendAvailable(backend: TSimdBackend): Boolean;

// Get list of all available backends (sorted by priority)
function GetAvailableBackends: TSimdBackendArray;

// Get the best available backend for general use
function GetBestBackend: TSimdBackend;

// Get backend information
function GetBackendInfo(backend: TSimdBackend): TSimdBackendInfo;

// Reset CPU info cache (for testing)
procedure ResetCPUInfo;

implementation

uses
  {$IFDEF SIMD_X86_AVAILABLE}
  fafafa.core.simd.cpuinfo.x86,
  {$ENDIF}
  {$IFDEF SIMD_ARM_AVAILABLE}
  fafafa.core.simd.cpuinfo.arm,
  {$ENDIF}
  {$IFDEF SIMD_RISCV_AVAILABLE}
  fafafa.core.simd.cpuinfo.riscv,
  {$ENDIF}
  {$IFDEF WINDOWS}
  Windows,
  {$ENDIF}
  Classes;

// === 门面实现：纯委托模式 ===

type
  TInitState = (isNotInitialized, isInitializing, isInitialized);

var
  g_CPUInfo: TCPUInfo;
  g_InitState: TInitState = isNotInitialized;
  {$IFDEF WINDOWS}
  g_InitCS: TRTLCriticalSection;
  g_CSInitialized: Boolean = False;
  {$ELSE}
  g_InitLock: Boolean = False;
  {$ENDIF}

procedure InitializeCPUInfo;
begin
  // 初始化 CPU 信息结构
  FillChar(g_CPUInfo, SizeOf(g_CPUInfo), 0);
  g_CPUInfo.Vendor := 'Unknown';
  g_CPUInfo.Model := 'Unknown Processor';
  
  // 委托给平台特定的检测模块
  {$IFDEF SIMD_X86_AVAILABLE}
  DetectX86VendorAndModel(g_CPUInfo);
  g_CPUInfo.X86 := DetectX86Features;
  {$ENDIF}
  
  {$IFDEF SIMD_ARM_AVAILABLE}
  DetectARMVendorAndModel(g_CPUInfo);
  g_CPUInfo.ARM := DetectARMFeatures;
  {$ENDIF}
  
  {$IFDEF SIMD_RISCV_AVAILABLE}
  DetectRISCVVendorAndModel(g_CPUInfo);
  g_CPUInfo.RISCV := DetectRISCVFeatures;
  {$ENDIF}
end;

function GetCPUInfo: TCPUInfo;
begin
  // 快速路径：已经初始化
  if g_InitState = isInitialized then
  begin
    Result := g_CPUInfo;
    Exit;
  end;

  {$IFDEF WINDOWS}
  // 使用临界区的线程安全初始化
  EnterCriticalSection(g_InitCS);
  try
    // 双重检查模式
    if g_InitState = isNotInitialized then
    begin
      g_InitState := isInitializing;
      try
        InitializeCPUInfo;
        g_InitState := isInitialized;
      except
        g_InitState := isNotInitialized;
        raise;
      end;
    end;
  finally
    LeaveCriticalSection(g_InitCS);
  end;
  {$ELSE}
  // 简化的自旋锁（非Windows平台）
  while True do
  begin
    while g_InitLock do
      Sleep(1);
      
    if g_InitState = isNotInitialized then
    begin
      if not g_InitLock then
      begin
        g_InitLock := True;
        if g_InitState = isNotInitialized then
        begin
          g_InitState := isInitializing;
          try
            InitializeCPUInfo;
            g_InitState := isInitialized;
          except
            g_InitState := isNotInitialized;
            raise;
          finally
            g_InitLock := False;
          end;
          Break;
        end
        else
        begin
          g_InitLock := False;
          Break;
        end;
      end;
    end
    else
      Break;
  end;
  {$ENDIF}

  Result := g_CPUInfo;
end;

function IsBackendAvailable(backend: TSimdBackend): Boolean;
var
  cpuInfo: TCPUInfo;
begin
  case backend of
    sbScalar:
      Result := True; // 标量后端总是可用
      
    sbSSE2, sbAVX2, sbAVX512:
      begin
        {$IFDEF SIMD_X86_AVAILABLE}
        cpuInfo := GetCPUInfo;
        case backend of
          sbSSE2: Result := cpuInfo.X86.HasSSE2;
          sbAVX2: Result := cpuInfo.X86.HasAVX2;
          sbAVX512: Result := cpuInfo.X86.HasAVX512F;
        else
          Result := False;
        end;
        {$ELSE}
        Result := False;
        {$ENDIF}
      end;
      
    sbNEON:
      begin
        {$IFDEF SIMD_ARM_AVAILABLE}
        cpuInfo := GetCPUInfo;
        Result := cpuInfo.ARM.HasNEON;
        {$ELSE}
        Result := False;
        {$ENDIF}
      end;
      
    sbRISCVV:
      begin
        {$IFDEF SIMD_RISCV_AVAILABLE}
        cpuInfo := GetCPUInfo;
        Result := cpuInfo.RISCV.HasV;
        {$ELSE}
        Result := False;
        {$ENDIF}
      end;
      
  else
    Result := False;
  end;
end;

function GetAvailableBackends: TSimdBackendArray;
var
  backends: array[0..6] of TSimdBackend;
  count: Integer;
  backend: TSimdBackend;
begin
  count := 0;
  
  // 按优先级顺序检查后端
  for backend := High(TSimdBackend) downto Low(TSimdBackend) do
  begin
    if IsBackendAvailable(backend) then
    begin
      backends[count] := backend;
      Inc(count);
    end;
  end;
  
  // 复制到动态数组
  SetLength(Result, count);
  if count > 0 then
    Move(backends[0], Result[0], count * SizeOf(TSimdBackend));
end;

function GetBestBackend: TSimdBackend;
var
  backends: TSimdBackendArray;
begin
  backends := GetAvailableBackends;
  
  if Length(backends) > 0 then
    Result := backends[0] // 第一个是最高优先级的
  else
    Result := sbScalar; // 回退到标量实现
end;

function GetBackendInfo(backend: TSimdBackend): TSimdBackendInfo;
begin
  Result.Backend := backend;
  Result.Name := GetBackendName(backend);
  Result.Description := GetBackendDescription(backend);
  Result.Available := IsBackendAvailable(backend);
  
  // 设置优先级（数值越高优先级越高）
  case backend of
    sbScalar: Result.Priority := 0;
    sbSSE2: Result.Priority := 10;
    sbNEON: Result.Priority := 15;
    sbAVX2: Result.Priority := 20;
    sbRISCVV: Result.Priority := 25;
    sbAVX512: Result.Priority := 30;
  else
    Result.Priority := -1;
  end;
  
  // 设置能力集
  Result.Capabilities := [];
  if Result.Available then
  begin
    case backend of
      sbScalar:
        Result.Capabilities := [scBasicArithmetic, scComparison, scMathFunctions];
      sbSSE2:
        Result.Capabilities := [scBasicArithmetic, scComparison, scMathFunctions, 
                               scShuffle, scIntegerOps, scLoadStore];
      sbAVX2:
        Result.Capabilities := [scBasicArithmetic, scComparison, scMathFunctions,
                               scReduction, scShuffle, scFMA, scIntegerOps, 
                               scLoadStore, scGather];
      sbAVX512:
        Result.Capabilities := [scBasicArithmetic, scComparison, scMathFunctions,
                               scReduction, scShuffle, scFMA, scIntegerOps,
                               scLoadStore, scGather, scMaskedOps];
      sbNEON:
        Result.Capabilities := [scBasicArithmetic, scComparison, scMathFunctions,
                               scShuffle, scIntegerOps, scLoadStore];
      sbRISCVV:
        Result.Capabilities := [scBasicArithmetic, scComparison, scMathFunctions,
                               scReduction, scShuffle, scIntegerOps, scLoadStore];
    end;
  end;
end;

procedure ResetCPUInfo;
begin
  {$IFDEF WINDOWS}
  EnterCriticalSection(g_InitCS);
  try
    g_InitState := isNotInitialized;
  finally
    LeaveCriticalSection(g_InitCS);
  end;
  {$ELSE}
  while g_InitLock do
    Sleep(1);
  g_InitLock := True;
  try
    g_InitState := isNotInitialized;
  finally
    g_InitLock := False;
  end;
  {$ENDIF}
end;

initialization
  {$IFDEF WINDOWS}
  InitializeCriticalSection(g_InitCS);
  g_CSInitialized := True;
  {$ENDIF}

finalization
  {$IFDEF WINDOWS}
  if g_CSInitialized then
  begin
    DeleteCriticalSection(g_InitCS);
    g_CSInitialized := False;
  end;
  {$ENDIF}

end.
