unit fafafa.core.simd.cpuinfo.lazy;

{$mode objfpc}
{$I fafafa.core.settings.inc}
interface

uses
  fafafa.core.simd.types,
  fafafa.core.simd.cpuinfo.base,
  fafafa.core.simd.sync;

type
  // 懒加载的 CPU 信息管理�?
  TLazyCPUInfo = class
  private
    // 各部分的初始化状�?
    FBasicInitialized: Boolean;
    FCacheInitialized: Boolean;
    FExtendedInitialized: Boolean;
    FAVXInitialized: Boolean;
    FAVX512Initialized: Boolean;
    
    // 分层存储�?CPU 信息
    FBasicInfo: record
      Arch: TCPUArch;
      Vendor: string;
      Model: string;
      LogicalCores: Integer;
      PhysicalCores: Integer;
    end;
    
    FCacheInfo: TCacheInfo;
    
    {$IFDEF SIMD_X86_AVAILABLE}
    FX86Basic: record  // 常用特�?
      HasSSE2: Boolean;
      HasSSE3: Boolean;
      HasSSSE3: Boolean;
      HasSSE41: Boolean;
      HasSSE42: Boolean;
    end;
    
    FX86AVX: record  // AVX 相关
      HasAVX: Boolean;
      HasAVX2: Boolean;
      HasFMA: Boolean;
      OSXSAVE: Boolean;
      XCR0: UInt64;
    end;
    
    FX86AVX512: record  // AVX-512 相关
      HasAVX512F: Boolean;
      HasAVX512DQ: Boolean;
      HasAVX512BW: Boolean;
      HasAVX512VL: Boolean;
      HasAVX512VBMI: Boolean;
    end;
    
    FX86Extended: TX86Features;  // 完整特性集
    {$ENDIF}
    
    // 同步�?
    FLock: Integer;
    
    // 初始化方�?
    procedure InitBasicInfo;
    procedure InitCacheInfo;
    {$IFDEF SIMD_X86_AVAILABLE}
    procedure InitX86Basic;
    procedure InitX86AVX;
    procedure InitX86AVX512;
    procedure InitX86Extended;
    {$ENDIF}
    
    // 属性访问器
    function GetArch: TCPUArch;
    function GetVendor: string;
    function GetModel: string;
    function GetLogicalCores: Integer;
    function GetCacheInfo: TCacheInfo;
    
    {$IFDEF SIMD_X86_AVAILABLE}
    function GetHasSSE2: Boolean;
    function GetHasAVX2: Boolean;
    function GetHasAVX512F: Boolean;
    function GetX86Features: TX86Features;
    {$ENDIF}
    
  public
    constructor Create;
    
    // 基本信息（总是快速的�?
    property Arch: TCPUArch read GetArch;
    property Vendor: string read GetVendor;
    property Model: string read GetModel;
    property LogicalCores: Integer read GetLogicalCores;
    
    // 缓存信息（按需加载�?
    property CacheInfo: TCacheInfo read GetCacheInfo;
    
    {$IFDEF SIMD_X86_AVAILABLE}
    // 常用 x86 特性（分层加载�?
    property HasSSE2: Boolean read GetHasSSE2;
    property HasAVX2: Boolean read GetHasAVX2;
    property HasAVX512F: Boolean read GetHasAVX512F;
    
    // 完整特性集（延迟加载）
    property X86Features: TX86Features read GetX86Features;
    {$ENDIF}
    
    // 预加载指定级别的信息
    procedure PreloadBasic;
    procedure PreloadCommon;  // 包含 SSE/AVX
    procedure PreloadAll;      // 加载所有信�?
    
    // 重置缓存
    procedure Reset;
    
    // 获取加载统计
    function GetLoadStatistics: string;
  end;

// 全局单例实例
function LazyCPUInfo: TLazyCPUInfo;

// 兼容性接�?
function GetCPUInfoLazy: TCPUInfo;
function HasFeatureLazy(f: TGenericFeature): Boolean;

implementation

uses
  SysUtils
  {$IFDEF SIMD_X86_AVAILABLE}
  , fafafa.core.simd.cpuinfo.x86
  {$ENDIF}
  {$IFDEF SIMD_ARM_AVAILABLE}
  , fafafa.core.simd.cpuinfo.arm
  {$ENDIF}
  ;

var
  g_LazyCPUInfo: TLazyCPUInfo = nil;
  g_SingletonLock: Integer = 0;

function LazyCPUInfo: TLazyCPUInfo;
var
  OldValue: Integer;
begin
  if g_LazyCPUInfo <> nil then
  begin
    Result := g_LazyCPUInfo;
    Exit;
  end;
  
  // 双重检查锁定创建单�?
  repeat
    OldValue := InterlockedCompareExchange(g_SingletonLock, 1, 0);
    if OldValue = 0 then
    begin
      if g_LazyCPUInfo = nil then
        g_LazyCPUInfo := TLazyCPUInfo.Create;
      InterlockedExchange(g_SingletonLock, 0);
      Break;
    end
    else
    begin
      while g_SingletonLock <> 0 do
        ThreadSwitch;
    end;
  until False;
  
  Result := g_LazyCPUInfo;
end;

{ TLazyCPUInfo }

constructor TLazyCPUInfo.Create;
begin
  inherited;
  FLock := 0;
  FBasicInitialized := False;
  FCacheInitialized := False;
  FExtendedInitialized := False;
  FAVXInitialized := False;
  FAVX512Initialized := False;
end;

procedure TLazyCPUInfo.InitBasicInfo;
var
  OldValue: Integer;
begin
  if FBasicInitialized then Exit;
  
  repeat
    OldValue := InterlockedCompareExchange(FLock, 1, 0);
    if OldValue = 0 then
    begin
      if not FBasicInitialized then
      begin
        // 基本架构检�?
        {$IFDEF CPUX86_64}
        FBasicInfo.Arch := caX86;
        {$ELSEIF DEFINED(CPUARM)}
        FBasicInfo.Arch := caARM;
        {$ELSE}
        FBasicInfo.Arch := caUnknown;
        {$ENDIF}
        
        // 厂商和型号（快速检测）
        {$IFDEF SIMD_X86_AVAILABLE}
        FBasicInfo.Vendor := GetVendorString;
        FBasicInfo.Model := GetBrandString;
        {$ELSE}
        FBasicInfo.Vendor := 'Unknown';
        FBasicInfo.Model := 'Unknown Processor';
        {$ENDIF}
        
        // 核心�?
        {$IFDEF WINDOWS}
        var s := GetEnvironmentVariable('NUMBER_OF_PROCESSORS');
        FBasicInfo.LogicalCores := StrToIntDef(s, 1);
        {$ELSE}
        FBasicInfo.LogicalCores := 1;
        {$ENDIF}
        FBasicInfo.PhysicalCores := FBasicInfo.LogicalCores;
        
        WriteBarrier;
        FBasicInitialized := True;
      end;
      InterlockedExchange(FLock, 0);
      Break;
    end
    else
    begin
      while not FBasicInitialized do
        ThreadSwitch;
      Break;
    end;
  until False;
end;

procedure TLazyCPUInfo.InitCacheInfo;
var
  OldValue: Integer;
begin
  if FCacheInitialized then Exit;
  
  repeat
    OldValue := InterlockedCompareExchange(FLock, 1, 0);
    if OldValue = 0 then
    begin
      if not FCacheInitialized then
      begin
        {$IFDEF SIMD_X86_AVAILABLE}
        var xc := GetX86CacheInfo;
        FCacheInfo.L1DataKB := xc.L1DataCache;
        FCacheInfo.L1InstrKB := xc.L1InstructionCache;
        FCacheInfo.L2KB := xc.L2Cache;
        FCacheInfo.L3KB := xc.L3Cache;
        FCacheInfo.LineSize := xc.CacheLineSize;
        {$ELSE}
        FillChar(FCacheInfo, SizeOf(FCacheInfo), 0);
        {$ENDIF}
        
        WriteBarrier;
        FCacheInitialized := True;
      end;
      InterlockedExchange(FLock, 0);
      Break;
    end
    else
    begin
      while not FCacheInitialized do
        ThreadSwitch;
      Break;
    end;
  until False;
end;

{$IFDEF SIMD_X86_AVAILABLE}
procedure TLazyCPUInfo.InitX86Basic;
var
  OldValue: Integer;
  eax, ebx, ecx, edx: DWord;
begin
  if FBasicInitialized then Exit;
  
  repeat
    OldValue := InterlockedCompareExchange(FLock, 1, 0);
    if OldValue = 0 then
    begin
      if not FBasicInitialized then
      begin
        // 检测基�?SSE 支持
        CPUID(1, eax, ebx, ecx, edx);
        
        FX86Basic.HasSSE2 := (edx and (1 shl 26)) <> 0;
        FX86Basic.HasSSE3 := (ecx and 1) <> 0;
        FX86Basic.HasSSSE3 := (ecx and (1 shl 9)) <> 0;
        FX86Basic.HasSSE41 := (ecx and (1 shl 19)) <> 0;
        FX86Basic.HasSSE42 := (ecx and (1 shl 20)) <> 0;
        
        WriteBarrier;
        FBasicInitialized := True;
      end;
      InterlockedExchange(FLock, 0);
      Break;
    end
    else
    begin
      while not FBasicInitialized do
        ThreadSwitch;
      Break;
    end;
  until False;
end;

procedure TLazyCPUInfo.InitX86AVX;
var
  OldValue: Integer;
begin
  if FAVXInitialized then Exit;
  
  // 确保基本信息已加�?
  InitX86Basic;
  
  repeat
    OldValue := InterlockedCompareExchange(FLock, 1, 0);
    if OldValue = 0 then
    begin
      if not FAVXInitialized then
      begin
        var eax, ebx, ecx, edx: DWord;
        
        // 检�?AVX 支持
        CPUID(1, eax, ebx, ecx, edx);
        FX86AVX.HasAVX := (ecx and (1 shl 28)) <> 0;
        FX86AVX.OSXSAVE := (ecx and (1 shl 27)) <> 0;
        FX86AVX.HasFMA := (ecx and (1 shl 12)) <> 0;
        
        // 检�?AVX2
        if FX86AVX.HasAVX and FX86AVX.OSXSAVE then
        begin
          FX86AVX.XCR0 := GetXCR0Value;
          if (FX86AVX.XCR0 and 6) = 6 then  // YMM 状态支�?
          begin
            CPUIDEX(7, 0, eax, ebx, ecx, edx);
            FX86AVX.HasAVX2 := (ebx and (1 shl 5)) <> 0;
          end;
        end;
        
        WriteBarrier;
        FAVXInitialized := True;
      end;
      InterlockedExchange(FLock, 0);
      Break;
    end
    else
    begin
      while not FAVXInitialized do
        ThreadSwitch;
      Break;
    end;
  until False;
end;

procedure TLazyCPUInfo.InitX86AVX512;
var
  OldValue: Integer;
begin
  if FAVX512Initialized then Exit;
  
  // 确保 AVX 信息已加�?
  InitX86AVX;
  
  repeat
    OldValue := InterlockedCompareExchange(FLock, 1, 0);
    if OldValue = 0 then
    begin
      if not FAVX512Initialized then
      begin
        FX86AVX512.HasAVX512F := False;
        FX86AVX512.HasAVX512DQ := False;
        FX86AVX512.HasAVX512BW := False;
        FX86AVX512.HasAVX512VL := False;
        FX86AVX512.HasAVX512VBMI := False;
        
        // 只有�?OS 支持的情况下才检�?AVX-512
        if FX86AVX.OSXSAVE and ((FX86AVX.XCR0 and $E6) = $E6) then
        begin
          var eax, ebx, ecx, edx: DWord;
          CPUIDEX(7, 0, eax, ebx, ecx, edx);
          
          FX86AVX512.HasAVX512F := (ebx and (1 shl 16)) <> 0;
          FX86AVX512.HasAVX512DQ := (ebx and (1 shl 17)) <> 0;
          FX86AVX512.HasAVX512BW := (ebx and (1 shl 30)) <> 0;
          FX86AVX512.HasAVX512VL := (ebx and (1 shl 31)) <> 0;
          FX86AVX512.HasAVX512VBMI := (ecx and (1 shl 1)) <> 0;
        end;
        
        WriteBarrier;
        FAVX512Initialized := True;
      end;
      InterlockedExchange(FLock, 0);
      Break;
    end
    else
    begin
      while not FAVX512Initialized do
        ThreadSwitch;
      Break;
    end;
  until False;
end;

procedure TLazyCPUInfo.InitX86Extended;
begin
  if FExtendedInitialized then Exit;
  
  // 确保所有基本信息已加载
  InitX86Basic;
  InitX86AVX;
  InitX86AVX512;
  
  // 获取完整特性集
  FX86Extended := DetectX86Features;
  
  WriteBarrier;
  FExtendedInitialized := True;
end;
{$ENDIF}

function TLazyCPUInfo.GetArch: TCPUArch;
begin
  InitBasicInfo;
  Result := FBasicInfo.Arch;
end;

function TLazyCPUInfo.GetVendor: string;
begin
  InitBasicInfo;
  Result := FBasicInfo.Vendor;
end;

function TLazyCPUInfo.GetModel: string;
begin
  InitBasicInfo;
  Result := FBasicInfo.Model;
end;

function TLazyCPUInfo.GetLogicalCores: Integer;
begin
  InitBasicInfo;
  Result := FBasicInfo.LogicalCores;
end;

function TLazyCPUInfo.GetCacheInfo: TCacheInfo;
begin
  InitCacheInfo;
  Result := FCacheInfo;
end;

{$IFDEF SIMD_X86_AVAILABLE}
function TLazyCPUInfo.GetHasSSE2: Boolean;
begin
  InitX86Basic;
  Result := FX86Basic.HasSSE2;
end;

function TLazyCPUInfo.GetHasAVX2: Boolean;
begin
  InitX86AVX;
  Result := FX86AVX.HasAVX2;
end;

function TLazyCPUInfo.GetHasAVX512F: Boolean;
begin
  InitX86AVX512;
  Result := FX86AVX512.HasAVX512F;
end;

function TLazyCPUInfo.GetX86Features: TX86Features;
begin
  InitX86Extended;
  Result := FX86Extended;
end;
{$ENDIF}

procedure TLazyCPUInfo.PreloadBasic;
begin
  InitBasicInfo;
end;

procedure TLazyCPUInfo.PreloadCommon;
begin
  InitBasicInfo;
  {$IFDEF SIMD_X86_AVAILABLE}
  InitX86Basic;
  InitX86AVX;
  {$ENDIF}
end;

procedure TLazyCPUInfo.PreloadAll;
begin
  InitBasicInfo;
  InitCacheInfo;
  {$IFDEF SIMD_X86_AVAILABLE}
  InitX86Basic;
  InitX86AVX;
  InitX86AVX512;
  InitX86Extended;
  {$ENDIF}
end;

procedure TLazyCPUInfo.Reset;
begin
  InterlockedExchange(FLock, 1);
  try
    FBasicInitialized := False;
    FCacheInitialized := False;
    FExtendedInitialized := False;
    FAVXInitialized := False;
    FAVX512Initialized := False;
  finally
    InterlockedExchange(FLock, 0);
  end;
end;

function TLazyCPUInfo.GetLoadStatistics: string;
var
  Stats: TStringList;
begin
  Stats := TStringList.Create;
  try
    Stats.Add('=== Lazy Load Statistics ===');
    Stats.Add('Basic Info: ' + BoolToStr(FBasicInitialized, 'Loaded', 'Not Loaded'));
    Stats.Add('Cache Info: ' + BoolToStr(FCacheInitialized, 'Loaded', 'Not Loaded'));
    {$IFDEF SIMD_X86_AVAILABLE}
    Stats.Add('X86 Basic: ' + BoolToStr(FBasicInitialized, 'Loaded', 'Not Loaded'));
    Stats.Add('X86 AVX: ' + BoolToStr(FAVXInitialized, 'Loaded', 'Not Loaded'));
    Stats.Add('X86 AVX-512: ' + BoolToStr(FAVX512Initialized, 'Loaded', 'Not Loaded'));
    Stats.Add('X86 Extended: ' + BoolToStr(FExtendedInitialized, 'Loaded', 'Not Loaded'));
    {$ENDIF}
    Result := Stats.Text;
  finally
    Stats.Free;
  end;
end;

// 兼容性接口实�?

function GetCPUInfoLazy: TCPUInfo;
var
  Lazy: TLazyCPUInfo;
begin
  Lazy := LazyCPUInfo;
  
  FillChar(Result, SizeOf(Result), 0);
  Result.Arch := Lazy.Arch;
  Result.Vendor := Lazy.Vendor;
  Result.Model := Lazy.Model;
  Result.LogicalCores := Lazy.LogicalCores;
  Result.Cache := Lazy.CacheInfo;
  
  {$IFDEF SIMD_X86_AVAILABLE}
  Result.X86 := Lazy.X86Features;
  {$ENDIF}
end;

function HasFeatureLazy(f: TGenericFeature): Boolean;
var
  Lazy: TLazyCPUInfo;
begin
  Lazy := LazyCPUInfo;
  Result := False;
  
  case f of
    gfSimd128:
      {$IFDEF SIMD_X86_AVAILABLE}
      Result := Lazy.HasSSE2;
      {$ENDIF}
    
    gfSimd256:
      {$IFDEF SIMD_X86_AVAILABLE}
      Result := Lazy.HasAVX2;
      {$ENDIF}
    
    gfSimd512:
      {$IFDEF SIMD_X86_AVAILABLE}
      Result := Lazy.HasAVX512F;
      {$ENDIF}
  end;
end;

finalization
  if g_LazyCPUInfo <> nil then
  begin
    g_LazyCPUInfo.Free;
    g_LazyCPUInfo := nil;
  end;

end.


