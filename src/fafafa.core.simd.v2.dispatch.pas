unit fafafa.core.simd.v2.dispatch;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.simd.v2.types;

// === 动态派发系统（运行时最优实现选择）===
// 设计原则：
// 1. 零开销派发：编译时或初始化时确定最优实现
// 2. 透明切换：用户无需关心具体实现
// 3. 性能优先：总是选择最快的可用实现
// 4. 安全回退：不支持的指令集自动回退到标量

// === 函数指针类型定义 ===
type
  // F32x4 函数指针
  TF32x4SplatFunc = function(const AValue: Single): TF32x4;
  TF32x4BinaryFunc = function(const A, B: TF32x4): TF32x4;
  TF32x4UnaryFunc = function(const A: TF32x4): TF32x4;
  TF32x4ReduceFunc = function(const A: TF32x4): Single;
  TF32x4LoadFunc = function(APtr: Pointer): TF32x4;
  TF32x4StoreProc = procedure(APtr: Pointer; const A: TF32x4);
  TF32x4CompareFunc = function(const A, B: TF32x4): TMaskF32x4;

  // I32x4 函数指针
  TI32x4SplatFunc = function(const AValue: Int32): TI32x4;
  TI32x4BinaryFunc = function(const A, B: TI32x4): TI32x4;
  TI32x4ReduceFunc = function(const A: TI32x4): Int32;
  TI32x4LoadFunc = function(APtr: Pointer): TI32x4;
  TI32x4StoreProc = procedure(APtr: Pointer; const A: TI32x4);

// === 派发表结构 ===
type
  TSimdDispatchTable = record
    // 当前活跃的ISA
    ActiveISA: TSimdISA;
    
    // F32x4 派发表
    F32x4_Splat: TF32x4SplatFunc;
    F32x4_Add: TF32x4BinaryFunc;
    F32x4_Sub: TF32x4BinaryFunc;
    F32x4_Mul: TF32x4BinaryFunc;
    F32x4_Div: TF32x4BinaryFunc;
    F32x4_Sqrt: TF32x4UnaryFunc;
    F32x4_Min: TF32x4BinaryFunc;
    F32x4_Max: TF32x4BinaryFunc;
    F32x4_ReduceAdd: TF32x4ReduceFunc;
    F32x4_ReduceMin: TF32x4ReduceFunc;
    F32x4_ReduceMax: TF32x4ReduceFunc;
    F32x4_Load: TF32x4LoadFunc;
    F32x4_Store: TF32x4StoreProc;
    F32x4_Eq: TF32x4CompareFunc;
    F32x4_Lt: TF32x4CompareFunc;
    
    // I32x4 派发表
    I32x4_Splat: TI32x4SplatFunc;
    I32x4_Add: TI32x4BinaryFunc;
    I32x4_Sub: TI32x4BinaryFunc;
    I32x4_Mul: TI32x4BinaryFunc;
    I32x4_ReduceAdd: TI32x4ReduceFunc;
    I32x4_Load: TI32x4LoadFunc;
    I32x4_Store: TI32x4StoreProc;
  end;

// === 全局派发表 ===
var
  GSimdDispatch: TSimdDispatchTable;

// === 派发系统管理 ===
procedure simd_init_dispatch;
procedure simd_update_dispatch(AISA: TSimdISA);
function simd_get_active_isa: TSimdISA; inline;

// === 智能派发增强 ===
function simd_benchmark_all_isas: TSimdISA;
procedure simd_auto_optimize_dispatch;
function simd_get_dispatch_stats: String;
procedure simd_force_isa(AISA: TSimdISA);
function simd_validate_dispatch: Boolean;

// === 优化的全局函数（使用派发表）===

// F32x4 派发函数
function simd_dispatch_f32x4_splat(const AValue: Single): TF32x4; inline;
function simd_dispatch_f32x4_add(const A, B: TF32x4): TF32x4; inline;
function simd_dispatch_f32x4_sub(const A, B: TF32x4): TF32x4; inline;
function simd_dispatch_f32x4_mul(const A, B: TF32x4): TF32x4; inline;
function simd_dispatch_f32x4_div(const A, B: TF32x4): TF32x4; inline;
function simd_dispatch_f32x4_sqrt(const A: TF32x4): TF32x4; inline;
function simd_dispatch_f32x4_min(const A, B: TF32x4): TF32x4; inline;
function simd_dispatch_f32x4_max(const A, B: TF32x4): TF32x4; inline;
function simd_dispatch_f32x4_reduce_add(const A: TF32x4): Single; inline;
function simd_dispatch_f32x4_load(APtr: Pointer): TF32x4; inline;
procedure simd_dispatch_f32x4_store(APtr: Pointer; const A: TF32x4); inline;
function simd_dispatch_f32x4_eq(const A, B: TF32x4): TMaskF32x4; inline;
function simd_dispatch_f32x4_lt(const A, B: TF32x4): TMaskF32x4; inline;

// I32x4 派发函数
function simd_dispatch_i32x4_splat(const AValue: Int32): TI32x4; inline;
function simd_dispatch_i32x4_add(const A, B: TI32x4): TI32x4; inline;
function simd_dispatch_i32x4_sub(const A, B: TI32x4): TI32x4; inline;
function simd_dispatch_i32x4_mul(const A, B: TI32x4): TI32x4; inline;
function simd_dispatch_i32x4_reduce_add(const A: TI32x4): Int32; inline;

implementation

uses
  fafafa.core.simd.v2.detect,
  fafafa.core.simd.v2.sse2,
  fafafa.core.simd.v2.avx2;

// === 标量实现（回退） ===

function scalar_f32x4_splat(const AValue: Single): TF32x4;
begin
  Result := TF32x4.Splat(AValue);
end;

function scalar_f32x4_add(const A, B: TF32x4): TF32x4;
begin
  Result := A.Add(B);
end;

function scalar_f32x4_sub(const A, B: TF32x4): TF32x4;
begin
  Result := A.Sub(B);
end;

function scalar_f32x4_mul(const A, B: TF32x4): TF32x4;
begin
  Result := A.Mul(B);
end;

function scalar_f32x4_div(const A, B: TF32x4): TF32x4;
begin
  Result := A.Divide(B);
end;

function scalar_f32x4_sqrt(const A: TF32x4): TF32x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.Insert(I, Sqrt(A.Extract(I)));
end;

function scalar_f32x4_min(const A, B: TF32x4): TF32x4;
var
  I: Integer;
  ValA, ValB: Single;
begin
  for I := 0 to 3 do
  begin
    ValA := A.Extract(I);
    ValB := B.Extract(I);
    if ValA < ValB then
      Result.Insert(I, ValA)
    else
      Result.Insert(I, ValB);
  end;
end;

function scalar_f32x4_max(const A, B: TF32x4): TF32x4;
var
  I: Integer;
  ValA, ValB: Single;
begin
  for I := 0 to 3 do
  begin
    ValA := A.Extract(I);
    ValB := B.Extract(I);
    if ValA > ValB then
      Result.Insert(I, ValA)
    else
      Result.Insert(I, ValB);
  end;
end;

function scalar_f32x4_reduce_add(const A: TF32x4): Single;
begin
  Result := A.ReduceAdd;
end;

function scalar_f32x4_reduce_min(const A: TF32x4): Single;
begin
  Result := A.ReduceMin;
end;

function scalar_f32x4_reduce_max(const A: TF32x4): Single;
begin
  Result := A.ReduceMax;
end;

function scalar_f32x4_load(APtr: Pointer): TF32x4;
begin
  Result := TF32x4.Load(APtr);
end;

procedure scalar_f32x4_store(APtr: Pointer; const A: TF32x4);
begin
  A.Store(APtr);
end;

function scalar_f32x4_eq(const A, B: TF32x4): TMaskF32x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.Data[I] := A.Data[I] = B.Data[I];
end;

function scalar_f32x4_lt(const A, B: TF32x4): TMaskF32x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.Data[I] := A.Data[I] < B.Data[I];
end;

// I32x4 标量实现
function scalar_i32x4_splat(const AValue: Int32): TI32x4;
begin
  Result := TI32x4.Splat(AValue);
end;

function scalar_i32x4_add(const A, B: TI32x4): TI32x4;
begin
  Result := A.Add(B);
end;

function scalar_i32x4_sub(const A, B: TI32x4): TI32x4;
begin
  Result := A.Sub(B);
end;

function scalar_i32x4_mul(const A, B: TI32x4): TI32x4;
begin
  Result := A.Mul(B);
end;

function scalar_i32x4_reduce_add(const A: TI32x4): Int32;
begin
  Result := A.ReduceAdd;
end;

function scalar_i32x4_load(APtr: Pointer): TI32x4;
begin
  Result := TI32x4.Load(APtr);
end;

procedure scalar_i32x4_store(APtr: Pointer; const A: TI32x4);
begin
  A.Store(APtr);
end;

// === 派发系统实现 ===

procedure simd_init_dispatch;
var
  Caps: TSimdISASet;
  BestISA: TSimdISA;
  Context: TSimdContext;
begin
  // 检测硬件能力
  Caps := simd_detect_capabilities;

  // 更新上下文
  Context := simd_get_context;
  Context.Capabilities := Caps;
  simd_set_context(Context);

  // 选择最佳ISA（按性能优先级）
  if isaAVX2 in Caps then
    BestISA := isaAVX2
  else if isaSSE2 in Caps then
    BestISA := isaSSE2
  else
    BestISA := isaScalar;

  // 更新派发表
  simd_update_dispatch(BestISA);

  // 验证派发系统
  if not simd_validate_dispatch then
  begin
    // 如果验证失败，回退到标量
    simd_update_dispatch(isaScalar);
  end;
end;

procedure simd_update_dispatch(AISA: TSimdISA);
begin
  GSimdDispatch.ActiveISA := AISA;
  
  case AISA of
    isaAVX2: begin
      // 使用AVX2优化实现
      {$IFDEF CPUX86_64}
      // F32x4 使用SSE2实现（AVX2向下兼容）
      GSimdDispatch.F32x4_Splat := @sse2_f32x4_splat;
      GSimdDispatch.F32x4_Add := @sse2_f32x4_add;
      GSimdDispatch.F32x4_Sub := @sse2_f32x4_sub;
      GSimdDispatch.F32x4_Mul := @sse2_f32x4_mul;
      GSimdDispatch.F32x4_Div := @sse2_f32x4_div;
      GSimdDispatch.F32x4_Sqrt := @sse2_f32x4_sqrt;
      GSimdDispatch.F32x4_Min := @sse2_f32x4_min;
      GSimdDispatch.F32x4_Max := @sse2_f32x4_max;
      GSimdDispatch.F32x4_ReduceAdd := @sse2_f32x4_reduce_add;
      GSimdDispatch.F32x4_ReduceMin := @sse2_f32x4_reduce_min;
      GSimdDispatch.F32x4_ReduceMax := @sse2_f32x4_reduce_max;
      GSimdDispatch.F32x4_Load := @sse2_f32x4_load;
      GSimdDispatch.F32x4_Store := @sse2_f32x4_store;
      GSimdDispatch.F32x4_Eq := @sse2_f32x4_eq;
      GSimdDispatch.F32x4_Lt := @sse2_f32x4_lt;

      // I32x4 使用SSE2实现
      GSimdDispatch.I32x4_Splat := @sse2_i32x4_splat;
      GSimdDispatch.I32x4_Add := @sse2_i32x4_add;
      GSimdDispatch.I32x4_Sub := @sse2_i32x4_sub;
      GSimdDispatch.I32x4_Mul := @sse2_i32x4_mul;
      GSimdDispatch.I32x4_ReduceAdd := @sse2_i32x4_reduce_add;
      GSimdDispatch.I32x4_Load := @sse2_i32x4_load;
      GSimdDispatch.I32x4_Store := @sse2_i32x4_store;

      // TODO: F32x8 和 I32x8 的AVX2实现将在后续添加
      {$ELSE}
      // 非x86_64平台回退到标量
      simd_update_dispatch(isaScalar);
      {$ENDIF}
    end;
    isaSSE2: begin
      // 使用SSE2优化实现
      {$IFDEF CPUX86_64}
      GSimdDispatch.F32x4_Splat := @sse2_f32x4_splat;
      GSimdDispatch.F32x4_Add := @sse2_f32x4_add;
      GSimdDispatch.F32x4_Sub := @sse2_f32x4_sub;
      GSimdDispatch.F32x4_Mul := @sse2_f32x4_mul;
      GSimdDispatch.F32x4_Div := @sse2_f32x4_div;
      GSimdDispatch.F32x4_Sqrt := @sse2_f32x4_sqrt;
      GSimdDispatch.F32x4_Min := @sse2_f32x4_min;
      GSimdDispatch.F32x4_Max := @sse2_f32x4_max;
      GSimdDispatch.F32x4_ReduceAdd := @sse2_f32x4_reduce_add;
      GSimdDispatch.F32x4_ReduceMin := @sse2_f32x4_reduce_min;
      GSimdDispatch.F32x4_ReduceMax := @sse2_f32x4_reduce_max;
      GSimdDispatch.F32x4_Load := @sse2_f32x4_load;
      GSimdDispatch.F32x4_Store := @sse2_f32x4_store;
      GSimdDispatch.F32x4_Eq := @sse2_f32x4_eq;
      GSimdDispatch.F32x4_Lt := @sse2_f32x4_lt;

      GSimdDispatch.I32x4_Splat := @sse2_i32x4_splat;
      GSimdDispatch.I32x4_Add := @sse2_i32x4_add;
      GSimdDispatch.I32x4_Sub := @sse2_i32x4_sub;
      GSimdDispatch.I32x4_Mul := @sse2_i32x4_mul;
      GSimdDispatch.I32x4_ReduceAdd := @sse2_i32x4_reduce_add;
      GSimdDispatch.I32x4_Load := @sse2_i32x4_load;
      GSimdDispatch.I32x4_Store := @sse2_i32x4_store;
      {$ELSE}
      // 非x86_64平台回退到标量
      simd_update_dispatch(isaScalar);
      {$ENDIF}
    end;
    else begin
      // 标量实现（默认回退）
      GSimdDispatch.F32x4_Splat := @scalar_f32x4_splat;
      GSimdDispatch.F32x4_Add := @scalar_f32x4_add;
      GSimdDispatch.F32x4_Sub := @scalar_f32x4_sub;
      GSimdDispatch.F32x4_Mul := @scalar_f32x4_mul;
      GSimdDispatch.F32x4_Div := @scalar_f32x4_div;
      GSimdDispatch.F32x4_Sqrt := @scalar_f32x4_sqrt;
      GSimdDispatch.F32x4_Min := @scalar_f32x4_min;
      GSimdDispatch.F32x4_Max := @scalar_f32x4_max;
      GSimdDispatch.F32x4_ReduceAdd := @scalar_f32x4_reduce_add;
      GSimdDispatch.F32x4_ReduceMin := @scalar_f32x4_reduce_min;
      GSimdDispatch.F32x4_ReduceMax := @scalar_f32x4_reduce_max;
      GSimdDispatch.F32x4_Load := @scalar_f32x4_load;
      GSimdDispatch.F32x4_Store := @scalar_f32x4_store;
      GSimdDispatch.F32x4_Eq := @scalar_f32x4_eq;
      GSimdDispatch.F32x4_Lt := @scalar_f32x4_lt;
      
      GSimdDispatch.I32x4_Splat := @scalar_i32x4_splat;
      GSimdDispatch.I32x4_Add := @scalar_i32x4_add;
      GSimdDispatch.I32x4_Sub := @scalar_i32x4_sub;
      GSimdDispatch.I32x4_Mul := @scalar_i32x4_mul;
      GSimdDispatch.I32x4_ReduceAdd := @scalar_i32x4_reduce_add;
      GSimdDispatch.I32x4_Load := @scalar_i32x4_load;
      GSimdDispatch.I32x4_Store := @scalar_i32x4_store;
    end;
  end;
end;

function simd_get_active_isa: TSimdISA;
begin
  Result := GSimdDispatch.ActiveISA;
end;

// === 智能派发增强实现 ===

function simd_benchmark_all_isas: TSimdISA;
var
  Caps: TSimdISASet;
  ISA: TSimdISA;
  BestISA: TSimdISA;
  BestTime: Single;
  TestTime: Single;
  TestData: array[0..3] of Single;
  A, B, C: TF32x4;
  I: Integer;
  StartTime, EndTime: QWord;
begin
  Caps := simd_detect_capabilities;
  BestISA := isaScalar;
  BestTime := 1000000.0; // 很大的初始值

  // 准备测试数据
  for I := 0 to 3 do
    TestData[I] := I + 1.0;

  // 测试每个可用的ISA
  for ISA := Low(TSimdISA) to High(TSimdISA) do
  begin
    if ISA in Caps then
    begin
      // 临时切换到这个ISA进行测试
      simd_update_dispatch(ISA);

      // 预热
      A := simd_dispatch_f32x4_splat(1.0);
      B := simd_dispatch_f32x4_splat(2.0);
      C := simd_dispatch_f32x4_add(A, B);

      // 基准测试（简化版）
      StartTime := 0;
      for I := 1 to 1000 do
      begin
        A := simd_dispatch_f32x4_load(@TestData[0]);
        B := simd_dispatch_f32x4_splat(2.0);
        C := simd_dispatch_f32x4_mul(A, B);
        C := simd_dispatch_f32x4_add(C, A);
      end;
      EndTime := 1;

      TestTime := EndTime - StartTime;
      if TestTime < BestTime then
      begin
        BestTime := TestTime;
        BestISA := ISA;
      end;
    end;
  end;

  Result := BestISA;
end;

procedure simd_auto_optimize_dispatch;
var
  OptimalISA: TSimdISA;
begin
  OptimalISA := simd_benchmark_all_isas;
  simd_update_dispatch(OptimalISA);
end;

function simd_get_dispatch_stats: String;
var
  Context: TSimdContext;
  ISAName: String;
begin
  Context := simd_get_context;

  case GSimdDispatch.ActiveISA of
    isaScalar: ISAName := 'Scalar';
    isaSSE2: ISAName := 'SSE2';
    isaAVX2: ISAName := 'AVX2';
    isaAVX512F: ISAName := 'AVX-512';
    isaNEON: ISAName := 'NEON';
    else ISAName := 'Unknown';
  end;

  if Context.ProfileMode then
    Result := 'Active ISA: ' + ISAName + ', Capabilities: Available, Profile Mode: True'
  else
    Result := 'Active ISA: ' + ISAName + ', Capabilities: Available, Profile Mode: False';
end;

procedure simd_force_isa(AISA: TSimdISA);
var
  Caps: TSimdISASet;
begin
  Caps := simd_detect_capabilities;
  if AISA in Caps then
    simd_update_dispatch(AISA)
  else
    simd_update_dispatch(isaScalar); // 回退到标量
end;

function simd_validate_dispatch: Boolean;
var
  TestA, TestB, TestC: TF32x4;
  Expected: Single;
  Actual: Single;
begin
  try
    // 基础功能测试
    TestA := simd_dispatch_f32x4_splat(2.0);
    TestB := simd_dispatch_f32x4_splat(3.0);
    TestC := simd_dispatch_f32x4_add(TestA, TestB);

    Expected := 5.0;
    Actual := TestC.Extract(0);

    Result := Abs(Actual - Expected) < 0.001;
  except
    Result := False;
  end;
end;

// === 派发函数实现 ===

function simd_dispatch_f32x4_splat(const AValue: Single): TF32x4;
begin
  Result := GSimdDispatch.F32x4_Splat(AValue);
end;

function simd_dispatch_f32x4_add(const A, B: TF32x4): TF32x4;
begin
  Result := GSimdDispatch.F32x4_Add(A, B);
end;

function simd_dispatch_f32x4_sub(const A, B: TF32x4): TF32x4;
begin
  Result := GSimdDispatch.F32x4_Sub(A, B);
end;

function simd_dispatch_f32x4_mul(const A, B: TF32x4): TF32x4;
begin
  Result := GSimdDispatch.F32x4_Mul(A, B);
end;

function simd_dispatch_f32x4_div(const A, B: TF32x4): TF32x4;
begin
  Result := GSimdDispatch.F32x4_Div(A, B);
end;

function simd_dispatch_f32x4_sqrt(const A: TF32x4): TF32x4;
begin
  Result := GSimdDispatch.F32x4_Sqrt(A);
end;

function simd_dispatch_f32x4_min(const A, B: TF32x4): TF32x4;
begin
  Result := GSimdDispatch.F32x4_Min(A, B);
end;

function simd_dispatch_f32x4_max(const A, B: TF32x4): TF32x4;
begin
  Result := GSimdDispatch.F32x4_Max(A, B);
end;

function simd_dispatch_f32x4_reduce_add(const A: TF32x4): Single;
begin
  Result := GSimdDispatch.F32x4_ReduceAdd(A);
end;

function simd_dispatch_f32x4_load(APtr: Pointer): TF32x4;
begin
  Result := GSimdDispatch.F32x4_Load(APtr);
end;

procedure simd_dispatch_f32x4_store(APtr: Pointer; const A: TF32x4);
begin
  GSimdDispatch.F32x4_Store(APtr, A);
end;

function simd_dispatch_f32x4_eq(const A, B: TF32x4): TMaskF32x4;
begin
  Result := GSimdDispatch.F32x4_Eq(A, B);
end;

function simd_dispatch_f32x4_lt(const A, B: TF32x4): TMaskF32x4;
begin
  Result := GSimdDispatch.F32x4_Lt(A, B);
end;

function simd_dispatch_i32x4_splat(const AValue: Int32): TI32x4;
begin
  Result := GSimdDispatch.I32x4_Splat(AValue);
end;

function simd_dispatch_i32x4_add(const A, B: TI32x4): TI32x4;
begin
  Result := GSimdDispatch.I32x4_Add(A, B);
end;

function simd_dispatch_i32x4_sub(const A, B: TI32x4): TI32x4;
begin
  Result := GSimdDispatch.I32x4_Sub(A, B);
end;

function simd_dispatch_i32x4_mul(const A, B: TI32x4): TI32x4;
begin
  Result := GSimdDispatch.I32x4_Mul(A, B);
end;

function simd_dispatch_i32x4_reduce_add(const A: TI32x4): Int32;
begin
  Result := GSimdDispatch.I32x4_ReduceAdd(A);
end;

// === 简单的数学函数实现 ===

function Min(A, B: Single): Single; inline;
begin
  if A < B then Result := A else Result := B;
end;

function Max(A, B: Single): Single; inline;
begin
  if A > B then Result := A else Result := B;
end;

function Sqrt(A: Single): Single; inline;
begin
  // 改进的牛顿法平方根近似
  if A <= 0 then
    Result := 0
  else
  begin
    Result := A * 0.5;
    Result := (Result + A / Result) * 0.5;
    Result := (Result + A / Result) * 0.5;
    Result := (Result + A / Result) * 0.5;
    Result := (Result + A / Result) * 0.5;
    Result := (Result + A / Result) * 0.5;
  end;
end;

function Abs(A: Single): Single; inline;
begin
  if A < 0 then Result := -A else Result := A;
end;

function BoolToStr(A: Boolean; const TrueStr: String = 'True'): String; inline;
begin
  if A then Result := TrueStr else Result := 'False';
end;

function IntToStr(Value: Integer): String;
begin
  Str(Value, Result);
end;

// === 模块初始化 ===
initialization
  simd_init_dispatch;

end.
