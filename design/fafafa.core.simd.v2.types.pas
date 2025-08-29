unit fafafa.core.simd.v2.types;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

interface

// === 核心类型系统（对标 Rust std::simd）===

type
  // SIMD 向量长度（编译时常量）
  TSimdLanes = (
    simd2   = 2,    // 2 lanes
    simd4   = 4,    // 4 lanes  
    simd8   = 8,    // 8 lanes
    simd16  = 16,   // 16 lanes
    simd32  = 32,   // 32 lanes (AVX-512)
    simd64  = 64    // 64 lanes (AVX-512 bytes)
  );

  // 数据类型标识
  TSimdElementType = (
    setF32, setF64,                    // 浮点
    setI8, setI16, setI32, setI64,     // 有符号整数
    setU8, setU16, setU32, setU64      // 无符号整数
  );

  // 指令集能力
  TSimdISA = (
    isaScalar,
    isaSSE2, isaSSE3, isaSSSE3, isaSSE41, isaSSE42,
    isaAVX, isaAVX2, 
    isaAVX512F, isaAVX512VL, isaAVX512BW, isaAVX512DQ,
    isaAVX512CD, isaAVX512ER, isaAVX512PF, isaAVX512VBMI,
    isaNEON, isaSVE, isaSVE2
  );

  // 错误处理
  TSimdError = record
    Code: Integer;
    Message: String;
    ISA: TSimdISA;
  end;

  TSimdResult<T> = record
    case Success: Boolean of
      True: (Value: T);
      False: (Error: TSimdError);
  end;

  // 性能上下文
  TSimdContext = record
    ActiveISA: TSimdISA;
    Capabilities: set of TSimdISA;
    PerfMultiplier: array[TSimdISA] of Single;
    FallbackChain: array[0..7] of TSimdISA;
  end;

  // === 向量类型定义（泛型模拟）===

  // 32位浮点向量
  TSimdF32x2  = array[0..1] of Single;
  TSimdF32x4  = array[0..3] of Single;
  TSimdF32x8  = array[0..7] of Single;
  TSimdF32x16 = array[0..15] of Single;

  // 64位浮点向量
  TSimdF64x2  = array[0..1] of Double;
  TSimdF64x4  = array[0..3] of Double;
  TSimdF64x8  = array[0..7] of Double;

  // 32位整数向量
  TSimdI32x2  = array[0..1] of Int32;
  TSimdI32x4  = array[0..3] of Int32;
  TSimdI32x8  = array[0..7] of Int32;
  TSimdI32x16 = array[0..15] of Int32;

  // 8位无符号整数向量
  TSimdU8x16  = array[0..15] of Byte;
  TSimdU8x32  = array[0..31] of Byte;
  TSimdU8x64  = array[0..63] of Byte;

  // 掩码类型
  TSimdMask2  = array[0..1] of Boolean;
  TSimdMask4  = array[0..3] of Boolean;
  TSimdMask8  = array[0..7] of Boolean;
  TSimdMask16 = array[0..15] of Boolean;
  TSimdMask32 = array[0..31] of Boolean;

  // === 函数指针类型（统一命名规范）===

  // 算术运算
  TSimdAddF32Func = function(const a, b: TSimdF32x4): TSimdF32x4;
  TSimdSubF32Func = function(const a, b: TSimdF32x4): TSimdF32x4;
  TSimdMulF32Func = function(const a, b: TSimdF32x4): TSimdF32x4;
  TSimdDivF32Func = function(const a, b: TSimdF32x4): TSimdF32x4;

  // 比较运算
  TSimdEqF32Func = function(const a, b: TSimdF32x4): TSimdMask4;
  TSimdLtF32Func = function(const a, b: TSimdF32x4): TSimdMask4;
  TSimdLeF32Func = function(const a, b: TSimdF32x4): TSimdMask4;

  // 数学函数
  TSimdSqrtF32Func = function(const a: TSimdF32x4): TSimdF32x4;
  TSimdAbsF32Func = function(const a: TSimdF32x4): TSimdF32x4;
  TSimdMinF32Func = function(const a, b: TSimdF32x4): TSimdF32x4;
  TSimdMaxF32Func = function(const a, b: TSimdF32x4): TSimdF32x4;

  // 聚合运算
  TSimdReduceAddF32Func = function(const a: TSimdF32x4): Single;
  TSimdReduceMulF32Func = function(const a: TSimdF32x4): Single;
  TSimdReduceMinF32Func = function(const a: TSimdF32x4): Single;
  TSimdReduceMaxF32Func = function(const a: TSimdF32x4): Single;

  // 内存操作
  TSimdLoadF32Func = function(p: PSingle): TSimdF32x4;
  TSimdStoreF32Func = procedure(p: PSingle; const a: TSimdF32x4);
  TSimdLoadUnalignedF32Func = function(p: PSingle): TSimdF32x4;
  TSimdStoreUnalignedF32Func = procedure(p: PSingle; const a: TSimdF32x4);

  // 位运算
  TSimdAndFunc = function(const a, b: TSimdU8x16): TSimdU8x16;
  TSimdOrFunc = function(const a, b: TSimdU8x16): TSimdU8x16;
  TSimdXorFunc = function(const a, b: TSimdU8x16): TSimdU8x16;
  TSimdNotFunc = function(const a: TSimdU8x16): TSimdU8x16;

  // 移位运算
  TSimdShlI32Func = function(const a: TSimdI32x4; count: Integer): TSimdI32x4;
  TSimdShrI32Func = function(const a: TSimdI32x4; count: Integer): TSimdI32x4;

  // 类型转换
  TSimdCastF32ToI32Func = function(const a: TSimdF32x4): TSimdI32x4;
  TSimdCastI32ToF32Func = function(const a: TSimdI32x4): TSimdF32x4;
  TSimdConvertF32ToI32Func = function(const a: TSimdF32x4): TSimdI32x4;

  // 重排和混洗
  TSimdShuffleF32Func = function(const a, b: TSimdF32x4; const mask: array of Integer): TSimdF32x4;
  TSimdSplatF32Func = function(value: Single): TSimdF32x4;

  // 条件选择
  TSimdSelectF32Func = function(const mask: TSimdMask4; const a, b: TSimdF32x4): TSimdF32x4;

// === 全局上下文 ===
var
  GSimdContext: TSimdContext;

// === 上下文管理 ===
function simd_init_context: TSimdContext;
procedure simd_set_context(const ctx: TSimdContext);
function simd_get_context: TSimdContext;
function simd_detect_capabilities: set of TSimdISA;
function simd_get_best_isa(elementType: TSimdElementType; lanes: TSimdLanes): TSimdISA;

// === 错误处理 ===
function simd_make_error(code: Integer; const msg: String; isa: TSimdISA): TSimdError;
function simd_ok<T>(const value: T): TSimdResult<T>;
function simd_error<T>(const err: TSimdError): TSimdResult<T>;

implementation

function simd_init_context: TSimdContext;
begin
  Result.Capabilities := simd_detect_capabilities;
  Result.ActiveISA := isaScalar;
  // 初始化性能倍数和回退链
  FillChar(Result.PerfMultiplier, SizeOf(Result.PerfMultiplier), 0);
  Result.PerfMultiplier[isaScalar] := 1.0;
  Result.PerfMultiplier[isaSSE2] := 2.0;
  Result.PerfMultiplier[isaAVX2] := 4.0;
  Result.PerfMultiplier[isaAVX512F] := 8.0;
end;

function simd_detect_capabilities: set of TSimdISA;
begin
  Result := [isaScalar];
  // TODO: 实现真正的CPUID检测
end;

function simd_get_best_isa(elementType: TSimdElementType; lanes: TSimdLanes): TSimdISA;
begin
  // TODO: 根据元素类型和向量长度选择最佳ISA
  Result := isaScalar;
end;

procedure simd_set_context(const ctx: TSimdContext);
begin
  GSimdContext := ctx;
end;

function simd_get_context: TSimdContext;
begin
  Result := GSimdContext;
end;

function simd_make_error(code: Integer; const msg: String; isa: TSimdISA): TSimdError;
begin
  Result.Code := code;
  Result.Message := msg;
  Result.ISA := isa;
end;

function simd_ok<T>(const value: T): TSimdResult<T>;
begin
  Result.Success := True;
  Result.Value := value;
end;

function simd_error<T>(const err: TSimdError): TSimdResult<T>;
begin
  Result.Success := False;
  Result.Error := err;
end;

initialization
  GSimdContext := simd_init_context;

end.
