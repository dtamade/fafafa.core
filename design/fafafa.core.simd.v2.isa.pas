unit fafafa.core.simd.v2.isa;

{$mode objfpc}{$H+}

interface

uses
  fafafa.core.simd.v2.types;

// === 指令集特化实现架构 ===

type
  // 指令集实现接口
  ISimdImplementation = interface
    ['{B8F7E2A1-4C5D-4E6F-9A8B-1C2D3E4F5A6B}']
    
    // 基础信息
    function GetISA: TSimdISA;
    function GetName: String;
    function IsAvailable: Boolean;
    function GetPerfMultiplier: Single;
    
    // 算术运算
    function AddF32x4(const a, b: TSimdF32x4): TSimdF32x4;
    function SubF32x4(const a, b: TSimdF32x4): TSimdF32x4;
    function MulF32x4(const a, b: TSimdF32x4): TSimdF32x4;
    function DivF32x4(const a, b: TSimdF32x4): TSimdF32x4;
    
    // 比较运算
    function EqF32x4(const a, b: TSimdF32x4): TSimdMask4;
    function LtF32x4(const a, b: TSimdF32x4): TSimdMask4;
    
    // 数学函数
    function SqrtF32x4(const a: TSimdF32x4): TSimdF32x4;
    function AbsF32x4(const a: TSimdF32x4): TSimdF32x4;
    function MinF32x4(const a, b: TSimdF32x4): TSimdF32x4;
    function MaxF32x4(const a, b: TSimdF32x4): TSimdF32x4;
    
    // 聚合运算
    function ReduceAddF32x4(const a: TSimdF32x4): Single;
    function ReduceMinF32x4(const a: TSimdF32x4): Single;
    function ReduceMaxF32x4(const a: TSimdF32x4): Single;
    
    // 内存操作
    function LoadF32x4(p: PSingle): TSimdF32x4;
    function LoaduF32x4(p: PSingle): TSimdF32x4;
    procedure StoreF32x4(p: PSingle; const a: TSimdF32x4);
    procedure StoreuF32x4(p: PSingle; const a: TSimdF32x4);
  end;

  // 实现注册表
  TSimdRegistry = class
  private
    FImplementations: array[TSimdISA] of ISimdImplementation;
    FBestImpl: array[TSimdElementType, TSimdLanes] of ISimdImplementation;
  public
    procedure RegisterImplementation(impl: ISimdImplementation);
    function GetImplementation(isa: TSimdISA): ISimdImplementation;
    function GetBestImplementation(elementType: TSimdElementType; lanes: TSimdLanes): ISimdImplementation;
    procedure RefreshBestImplementations;
  end;

// === 标量实现（基准参考）===
type
  TScalarImplementation = class(TInterfacedObject, ISimdImplementation)
  public
    function GetISA: TSimdISA;
    function GetName: String;
    function IsAvailable: Boolean;
    function GetPerfMultiplier: Single;
    
    // 算术运算
    function AddF32x4(const a, b: TSimdF32x4): TSimdF32x4;
    function SubF32x4(const a, b: TSimdF32x4): TSimdF32x4;
    function MulF32x4(const a, b: TSimdF32x4): TSimdF32x4;
    function DivF32x4(const a, b: TSimdF32x4): TSimdF32x4;
    
    // 比较运算
    function EqF32x4(const a, b: TSimdF32x4): TSimdMask4;
    function LtF32x4(const a, b: TSimdF32x4): TSimdMask4;
    
    // 数学函数
    function SqrtF32x4(const a: TSimdF32x4): TSimdF32x4;
    function AbsF32x4(const a: TSimdF32x4): TSimdF32x4;
    function MinF32x4(const a, b: TSimdF32x4): TSimdF32x4;
    function MaxF32x4(const a, b: TSimdF32x4): TSimdF32x4;
    
    // 聚合运算
    function ReduceAddF32x4(const a: TSimdF32x4): Single;
    function ReduceMinF32x4(const a: TSimdF32x4): Single;
    function ReduceMaxF32x4(const a: TSimdF32x4): Single;
    
    // 内存操作
    function LoadF32x4(p: PSingle): TSimdF32x4;
    function LoaduF32x4(p: PSingle): TSimdF32x4;
    procedure StoreF32x4(p: PSingle; const a: TSimdF32x4);
    procedure StoreuF32x4(p: PSingle; const a: TSimdF32x4);
  end;

// === SSE2 实现 ===
{$IFDEF CPUX86_64}
type
  TSSE2Implementation = class(TInterfacedObject, ISimdImplementation)
  public
    function GetISA: TSimdISA;
    function GetName: String;
    function IsAvailable: Boolean;
    function GetPerfMultiplier: Single;
    
    // 算术运算（真正的 SSE2 汇编实现）
    function AddF32x4(const a, b: TSimdF32x4): TSimdF32x4;
    function SubF32x4(const a, b: TSimdF32x4): TSimdF32x4;
    function MulF32x4(const a, b: TSimdF32x4): TSimdF32x4;
    function DivF32x4(const a, b: TSimdF32x4): TSimdF32x4;
    
    // 比较运算
    function EqF32x4(const a, b: TSimdF32x4): TSimdMask4;
    function LtF32x4(const a, b: TSimdF32x4): TSimdMask4;
    
    // 数学函数
    function SqrtF32x4(const a: TSimdF32x4): TSimdF32x4;
    function AbsF32x4(const a: TSimdF32x4): TSimdF32x4;
    function MinF32x4(const a, b: TSimdF32x4): TSimdF32x4;
    function MaxF32x4(const a, b: TSimdF32x4): TSimdF32x4;
    
    // 聚合运算
    function ReduceAddF32x4(const a: TSimdF32x4): Single;
    function ReduceMinF32x4(const a: TSimdF32x4): Single;
    function ReduceMaxF32x4(const a: TSimdF32x4): Single;
    
    // 内存操作
    function LoadF32x4(p: PSingle): TSimdF32x4;
    function LoaduF32x4(p: PSingle): TSimdF32x4;
    procedure StoreF32x4(p: PSingle; const a: TSimdF32x4);
    procedure StoreuF32x4(p: PSingle; const a: TSimdF32x4);
  end;

// === AVX2 实现 ===
type
  TAVX2Implementation = class(TInterfacedObject, ISimdImplementation)
  public
    function GetISA: TSimdISA;
    function GetName: String;
    function IsAvailable: Boolean;
    function GetPerfMultiplier: Single;
    
    // AVX2 特化实现（256位向量）
    function AddF32x4(const a, b: TSimdF32x4): TSimdF32x4;
    function SubF32x4(const a, b: TSimdF32x4): TSimdF32x4;
    function MulF32x4(const a, b: TSimdF32x4): TSimdF32x4;
    function DivF32x4(const a, b: TSimdF32x4): TSimdF32x4;
    
    // 比较运算
    function EqF32x4(const a, b: TSimdF32x4): TSimdMask4;
    function LtF32x4(const a, b: TSimdF32x4): TSimdMask4;
    
    // 数学函数
    function SqrtF32x4(const a: TSimdF32x4): TSimdF32x4;
    function AbsF32x4(const a: TSimdF32x4): TSimdF32x4;
    function MinF32x4(const a, b: TSimdF32x4): TSimdF32x4;
    function MaxF32x4(const a, b: TSimdF32x4): TSimdF32x4;
    
    // 聚合运算
    function ReduceAddF32x4(const a: TSimdF32x4): Single;
    function ReduceMinF32x4(const a: TSimdF32x4): Single;
    function ReduceMaxF32x4(const a: TSimdF32x4): Single;
    
    // 内存操作
    function LoadF32x4(p: PSingle): TSimdF32x4;
    function LoaduF32x4(p: PSingle): TSimdF32x4;
    procedure StoreF32x4(p: PSingle; const a: TSimdF32x4);
    procedure StoreuF32x4(p: PSingle; const a: TSimdF32x4);
  end;

// === AVX-512 实现 ===
type
  TAVX512Implementation = class(TInterfacedObject, ISimdImplementation)
  public
    function GetISA: TSimdISA;
    function GetName: String;
    function IsAvailable: Boolean;
    function GetPerfMultiplier: Single;
    
    // AVX-512 特化实现（512位向量）
    function AddF32x4(const a, b: TSimdF32x4): TSimdF32x4;
    function SubF32x4(const a, b: TSimdF32x4): TSimdF32x4;
    function MulF32x4(const a, b: TSimdF32x4): TSimdF32x4;
    function DivF32x4(const a, b: TSimdF32x4): TSimdF32x4;
    
    // 比较运算
    function EqF32x4(const a, b: TSimdF32x4): TSimdMask4;
    function LtF32x4(const a, b: TSimdF32x4): TSimdMask4;
    
    // 数学函数
    function SqrtF32x4(const a: TSimdF32x4): TSimdF32x4;
    function AbsF32x4(const a: TSimdF32x4): TSimdF32x4;
    function MinF32x4(const a, b: TSimdF32x4): TSimdF32x4;
    function MaxF32x4(const a, b: TSimdF32x4): TSimdF32x4;
    
    // 聚合运算
    function ReduceAddF32x4(const a: TSimdF32x4): Single;
    function ReduceMinF32x4(const a: TSimdF32x4): Single;
    function ReduceMaxF32x4(const a: TSimdF32x4): Single;
    
    // 内存操作
    function LoadF32x4(p: PSingle): TSimdF32x4;
    function LoaduF32x4(p: PSingle): TSimdF32x4;
    procedure StoreF32x4(p: PSingle; const a: TSimdF32x4);
    procedure StoreuF32x4(p: PSingle; const a: TSimdF32x4);
  end;
{$ENDIF}

// === ARM NEON 实现 ===
{$IFDEF CPUAARCH64}
type
  TNEONImplementation = class(TInterfacedObject, ISimdImplementation)
  public
    function GetISA: TSimdISA;
    function GetName: String;
    function IsAvailable: Boolean;
    function GetPerfMultiplier: Single;
    
    // NEON 特化实现（128位向量）
    function AddF32x4(const a, b: TSimdF32x4): TSimdF32x4;
    function SubF32x4(const a, b: TSimdF32x4): TSimdF32x4;
    function MulF32x4(const a, b: TSimdF32x4): TSimdF32x4;
    function DivF32x4(const a, b: TSimdF32x4): TSimdF32x4;
    
    // 比较运算
    function EqF32x4(const a, b: TSimdF32x4): TSimdMask4;
    function LtF32x4(const a, b: TSimdF32x4): TSimdMask4;
    
    // 数学函数
    function SqrtF32x4(const a: TSimdF32x4): TSimdF32x4;
    function AbsF32x4(const a: TSimdF32x4): TSimdF32x4;
    function MinF32x4(const a, b: TSimdF32x4): TSimdF32x4;
    function MaxF32x4(const a, b: TSimdF32x4): TSimdF32x4;
    
    // 聚合运算
    function ReduceAddF32x4(const a: TSimdF32x4): Single;
    function ReduceMinF32x4(const a: TSimdF32x4): Single;
    function ReduceMaxF32x4(const a: TSimdF32x4): Single;
    
    // 内存操作
    function LoadF32x4(p: PSingle): TSimdF32x4;
    function LoaduF32x4(p: PSingle): TSimdF32x4;
    procedure StoreF32x4(p: PSingle; const a: TSimdF32x4);
    procedure StoreuF32x4(p: PSingle; const a: TSimdF32x4);
  end;
{$ENDIF}

// === 全局注册表 ===
var
  GSimdRegistry: TSimdRegistry;

// === 初始化函数 ===
procedure InitializeSimdImplementations;
procedure FinalizeSimdImplementations;

implementation

// 实现将在各自的指令集模块中提供

end.
