unit fafafa.core.simd.base;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.simd.types;

// === SIMD 基础接口定义 ===

type
  // SIMD 向量接口
  ISimdVector = interface
    ['{B8F5E2A1-4C3D-4E5F-9A8B-1C2D3E4F5A6B}']
    function GetSize: Integer;
    function GetElementCount: Integer;
    function GetElementType: TSimdElementType;
    function GetBackend: TSimdBackend;
    
    property Size: Integer read GetSize;
    property ElementCount: Integer read GetElementCount;
    property ElementType: TSimdElementType read GetElementType;
    property Backend: TSimdBackend read GetBackend;
  end;

  // SIMD 数学运算接口
  ISimdMath = interface
    ['{C9A6F3B2-5D4E-4F6A-8B9C-2D3E4F5A6B7C}']
    function Add(const A, B: ISimdVector): ISimdVector;
    function Sub(const A, B: ISimdVector): ISimdVector;
    function Mul(const A, B: ISimdVector): ISimdVector;
    function Divide(const A, B: ISimdVector): ISimdVector;
    function Sqrt(const A: ISimdVector): ISimdVector;
    function Abs(const A: ISimdVector): ISimdVector;
    function Min(const A, B: ISimdVector): ISimdVector;
    function Max(const A, B: ISimdVector): ISimdVector;
  end;

  // SIMD 内存操作接口
  ISimdMemory = interface
    ['{D0B7A4C3-6E5F-5A7B-9C0D-3E4F5A6B7C8D}']
    function Load(const Data: Pointer; Count: Integer): ISimdVector;
    function LoadAligned(const Data: Pointer; Count: Integer): ISimdVector;
    procedure Store(const Vector: ISimdVector; Data: Pointer);
    procedure StoreAligned(const Vector: ISimdVector; Data: Pointer);
    function Gather(const BaseAddr: Pointer; const Indices: array of Integer): ISimdVector;
    procedure Scatter(const Vector: ISimdVector; BaseAddr: Pointer; const Indices: array of Integer);
  end;

  // SIMD 转换操作接口
  ISimdConversion = interface
    ['{E1C8B5D4-7F6A-6B8C-0D1E-4F5A6B7C8D9E}']
    function ConvertToFloat(const A: ISimdVector): ISimdVector;
    function ConvertToInt(const A: ISimdVector): ISimdVector;
    function ConvertToDouble(const A: ISimdVector): ISimdVector;
    function Pack(const A, B: ISimdVector): ISimdVector;
    function Unpack(const A: ISimdVector): ISimdVector;
    function Shuffle(const A: ISimdVector; const Mask: array of Integer): ISimdVector;
  end;

  // SIMD 后端工厂接口
  ISimdBackendFactory = interface
    ['{F2D9C6E5-8A7B-7C9D-1E2F-5A6B7C8D9E0F}']
    function GetBackend: TSimdBackend;
    function IsAvailable: Boolean;
    function CreateMath: ISimdMath;
    function CreateMemory: ISimdMemory;
    function CreateConversion: ISimdConversion;
    function GetCapabilities: TSimdCapabilitySet;
  end;

// === 全局工厂管理 ===

// 注册后端工厂
procedure RegisterBackendFactory(Backend: TSimdBackend; Factory: ISimdBackendFactory);

// 获取后端工厂
function GetBackendFactory(Backend: TSimdBackend): ISimdBackendFactory;

// 获取最佳可用后端工�?function GetBestBackendFactory: ISimdBackendFactory;

// 获取所有可用后端工�?type
  TSimdBackendFactoryArray = array of ISimdBackendFactory;

function GetAvailableBackendFactories: TSimdBackendFactoryArray;

implementation

uses
  SysUtils,
  fafafa.core.simd.cpuinfo;

var
  g_BackendFactories: array[TSimdBackend] of ISimdBackendFactory;
  g_FactoriesInitialized: Boolean = False;

procedure RegisterBackendFactory(Backend: TSimdBackend; Factory: ISimdBackendFactory);
begin
  if Factory = nil then
    raise EArgumentNilException.Create('Factory cannot be nil');
    
  g_BackendFactories[Backend] := Factory;
end;

function GetBackendFactory(Backend: TSimdBackend): ISimdBackendFactory;
begin
  Result := g_BackendFactories[Backend];
  
  if (Result = nil) or not Result.IsAvailable then
    Result := nil;
end;

function GetBestBackendFactory: ISimdBackendFactory;
var
  backend: TSimdBackend;
  factory: ISimdBackendFactory;
begin
  Result := nil;
  
  // 按优先级顺序检查后�?  for backend := High(TSimdBackend) downto Low(TSimdBackend) do
  begin
    factory := GetBackendFactory(backend);
    if factory <> nil then
    begin
      Result := factory;
      Break;
    end;
  end;
  
  // 如果没有找到任何后端，抛出异�?  if Result = nil then
    raise Exception.Create('No SIMD backend available');
end;

function GetAvailableBackendFactories: TSimdBackendFactoryArray;
var
  backend: TSimdBackend;
  factory: ISimdBackendFactory;
  factories: TSimdBackendFactoryArray;
  count: Integer;
begin
  SetLength(factories, Ord(High(TSimdBackend)) - Ord(Low(TSimdBackend)) + 1);
  count := 0;
  
  // 按优先级顺序收集可用后端
  for backend := High(TSimdBackend) downto Low(TSimdBackend) do
  begin
    factory := GetBackendFactory(backend);
    if factory <> nil then
    begin
      factories[count] := factory;
      Inc(count);
    end;
  end;
  
  // 调整数组大小
  SetLength(factories, count);
  Result := factories;
end;

// === 自动初始�?===

procedure InitializeDefaultFactories;
begin
  if g_FactoriesInitialized then
    Exit;
    
  // 这里会在各个平台特定模块中注册工�?  // 例如�?  // - fafafa.core.simd.math.x86 会注�?x86 数学工厂
  // - fafafa.core.simd.math.arm 会注�?ARM 数学工厂
  // - fafafa.core.simd.math.scalar 会注册标量工�?  
  g_FactoriesInitialized := True;
end;

initialization
  InitializeDefaultFactories;

finalization
  // 清理工厂引用
  var backend: TSimdBackend;
  for backend := Low(TSimdBackend) to High(TSimdBackend) do
    g_BackendFactories[backend] := nil;

end.


