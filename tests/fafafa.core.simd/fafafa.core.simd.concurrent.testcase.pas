unit fafafa.core.simd.concurrent.testcase;

{**
  @abstract(SIMD 多线程并发测试)

  验证 SIMD 模块在多线程环境下的正确性:
  1. Dispatch table 的并发访问安全性
  2. 多线程同时使用 SIMD 操作时的正确性
  3. 不同向量宽度混合并发测试
  4. 高负载压力测试

  @author(fafafa.core Team)
  @created(2026-02-05)
*}

{$I ../../src/fafafa.core.settings.inc}
{$CODEPAGE UTF8}

interface

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, Math,
  fpcunit, testregistry,
  fafafa.core.simd,
  fafafa.core.simd.base,
  fafafa.core.simd.dispatch;

type
  {** @abstract(SIMD 并发测试套件) *}
  TTestCase_SimdConcurrent = class(TTestCase)
  published
    // === 并发计算正确性测试 ===
    {** 多线程并发 F32x4 加法正确性 *}
    procedure Test_Concurrent_F32x4_Add;
    {** 多线程并发 F32x4 乘法正确性 *}
    procedure Test_Concurrent_F32x4_Mul;
    {** 多线程并发 F64x2 操作正确性 *}
    procedure Test_Concurrent_F64x2_Operations;
    {** 多线程并发复合运算正确性 *}
    procedure Test_Concurrent_Compound_Operations;

    // === Dispatch Table 并发访问测试 ===
    {** 多线程同时访问 dispatch table *}
    procedure Test_Concurrent_Dispatch_Access;
    {** 并发查询后端信息 *}
    procedure Test_Concurrent_Backend_Query;
    {** vector-asm 开关与 dispatch 并发读写保护 *}
    procedure Test_Concurrent_VectorAsmToggle_DispatchRead;
    {** 多 writer 竞争下的 vector-asm 开关并发安全 *}
    procedure Test_Concurrent_VectorAsmToggle_MultiWriter_DispatchRead;
    {** public ABI table 与 vector-asm 重绑并发读写保护 *}
    procedure Test_Concurrent_PublicApiToggle_ReadConsistency;
    {** SetActiveBackend/Reset/GetDispatchTable/SetVectorAsmEnabled 混合并发控制 *}
    procedure Test_Concurrent_DispatchMixed_ControlPlane;

    // === 混合操作并发测试 ===
    {** 混合数学运算并发操作 *}
    procedure Test_Concurrent_Mixed_MathOps;
    {** 归约操作并发测试 *}
    procedure Test_Concurrent_Reduction_Operations;

    // === 高负载压力测试 ===
    {** 16 线程密集 SIMD 计算压力测试 *}
    procedure Test_Stress_Concurrent_SIMD;
    {** 长时间运行稳定性测试 *}
    procedure Test_Stress_LongRunning;
    {** 快速线程创建销毁测试 *}
    procedure Test_Stress_RapidThreadCreation;
    {** 大数据量并发处理测试 *}
    procedure Test_Stress_LargeData_Concurrent;
  end;

  {** @abstract(public ABI 并发回归套件) *}
  TTestCase_SimdConcurrentPublicAbi = class(TTestCase)
  published
    {** public ABI backend pod info 与 RegisterBackend 并发读写保护 *}
    procedure Test_Concurrent_PublicAbiPodInfo_RegisterBackend_ReadConsistency;
    {** public API active metadata 与 RegisterBackend 并发读写保护 *}
    procedure Test_Concurrent_PublicApiActiveMetadata_RegisterBackend_ReadConsistency;
  end;

  {** @abstract(framework active metadata 并发回归套件) *}
  TTestCase_SimdConcurrentFramework = class(TTestCase)
  published
    {** current backend info 与 RegisterBackend 并发读写保护 *}
    procedure Test_Concurrent_CurrentBackendInfo_RegisterBackend_ReadConsistency;
    {** dispatchable helper 与 vector-asm toggle 并发读写保护 *}
    procedure Test_Concurrent_DispatchableHelpers_VectorAsmToggle_ReadConsistency;
  end;

  // === Worker Thread Classes ===

  {** F32x4 加法工作线程 *}
  TF32x4AddWorker = class(TThread)
  private
    FWorkerIndex: Integer;
    FIterations: Integer;
    FSuccess: Boolean;
    FErrorMsg: string;
  protected
    procedure Execute; override;
  public
    constructor Create(AWorkerIndex, AIterations: Integer);
    property Success: Boolean read FSuccess;
    property ErrorMsg: string read FErrorMsg;
  end;

  {** F32x4 乘法工作线程 *}
  TF32x4MulWorker = class(TThread)
  private
    FWorkerIndex: Integer;
    FIterations: Integer;
    FSuccess: Boolean;
    FErrorMsg: string;
  protected
    procedure Execute; override;
  public
    constructor Create(AWorkerIndex, AIterations: Integer);
    property Success: Boolean read FSuccess;
    property ErrorMsg: string read FErrorMsg;
  end;

  {** F64x2 操作工作线程 *}
  TF64x2OpsWorker = class(TThread)
  private
    FWorkerIndex: Integer;
    FIterations: Integer;
    FSuccess: Boolean;
    FErrorMsg: string;
  protected
    procedure Execute; override;
  public
    constructor Create(AWorkerIndex, AIterations: Integer);
    property Success: Boolean read FSuccess;
    property ErrorMsg: string read FErrorMsg;
  end;

  {** Dispatch Table 访问工作线程 *}
  TDispatchAccessWorker = class(TThread)
  private
    FWorkerIndex: Integer;
    FIterations: Integer;
    FSuccess: Boolean;
    FErrorMsg: string;
  protected
    procedure Execute; override;
  public
    constructor Create(AWorkerIndex, AIterations: Integer);
    property Success: Boolean read FSuccess;
    property ErrorMsg: string read FErrorMsg;
  end;

  {** 混合数学运算工作线程 *}
  TMixedMathWorker = class(TThread)
  private
    FWorkerIndex: Integer;
    FIterations: Integer;
    FSuccess: Boolean;
    FErrorMsg: string;
  protected
    procedure Execute; override;
  public
    constructor Create(AWorkerIndex, AIterations: Integer);
    property Success: Boolean read FSuccess;
    property ErrorMsg: string read FErrorMsg;
  end;

  {** 归约操作工作线程 *}
  TReductionWorker = class(TThread)
  private
    FWorkerIndex: Integer;
    FIterations: Integer;
    FSuccess: Boolean;
    FErrorMsg: string;
  protected
    procedure Execute; override;
  public
    constructor Create(AWorkerIndex, AIterations: Integer);
    property Success: Boolean read FSuccess;
    property ErrorMsg: string read FErrorMsg;
  end;

  {** 复合运算工作线程 *}
  TCompoundOpsWorker = class(TThread)
  private
    FWorkerIndex: Integer;
    FIterations: Integer;
    FSuccess: Boolean;
    FErrorMsg: string;
  protected
    procedure Execute; override;
  public
    constructor Create(AWorkerIndex, AIterations: Integer);
    property Success: Boolean read FSuccess;
    property ErrorMsg: string read FErrorMsg;
  end;

  {** 压力测试工作线程 *}
  TStressWorker = class(TThread)
  private
    FWorkerIndex: Integer;
    FIterations: Integer;
    FSuccess: Boolean;
    FErrorMsg: string;
    FOperationsCompleted: Int64;
  protected
    procedure Execute; override;
  public
    constructor Create(AWorkerIndex, AIterations: Integer);
    property Success: Boolean read FSuccess;
    property ErrorMsg: string read FErrorMsg;
    property OperationsCompleted: Int64 read FOperationsCompleted;
  end;

  {** 后端查询工作线程 *}
  TBackendQueryThread = class(TThread)
  private
    FWorkerIndex: Integer;
    FResult: TSimdBackend;
    FSuccess: Boolean;
  protected
    procedure Execute; override;
  public
    constructor Create(AWorkerIndex: Integer);
    property Result: TSimdBackend read FResult;
    property Success: Boolean read FSuccess;
  end;

  {** vector-asm 开关写线程 *}
  TVectorAsmToggleWorker = class(TThread)
  private
    FIterations: Integer;
    FInitialValue: Boolean;
    FSuccess: Boolean;
    FErrorMsg: string;
  protected
    procedure Execute; override;
  public
    constructor Create(AIterations: Integer; AInitialValue: Boolean);
    property Success: Boolean read FSuccess;
    property ErrorMsg: string read FErrorMsg;
  end;

  {** 多 writer 场景下的 vector-asm 开关写线程 *}
  TVectorAsmMultiToggleWorker = class(TThread)
  private
    FIterations: Integer;
    FWriterPhase: Integer;
    FSuccess: Boolean;
    FErrorMsg: string;
  protected
    procedure Execute; override;
  public
    constructor Create(AIterations, AWriterPhase: Integer);
    property Success: Boolean read FSuccess;
    property ErrorMsg: string read FErrorMsg;
  end;

  {** dispatch 只读工作线程（与开关写线程并发） *}
  TVectorAsmReadWorker = class(TThread)
  private
    FIterations: Integer;
    FSuccess: Boolean;
    FErrorMsg: string;
  protected
    procedure Execute; override;
  public
    constructor Create(AIterations: Integer);
    property Success: Boolean read FSuccess;
    property ErrorMsg: string read FErrorMsg;
  end;

  {** public ABI 只读工作线程（与重绑写线程并发） *}
  TPublicApiReadWorker = class(TThread)
  private
    FIterations: Integer;
    FSuccess: Boolean;
    FErrorMsg: string;
  protected
    procedure Execute; override;
  public
    constructor Create(aIterations: Integer);
    property Success: Boolean read FSuccess;
    property ErrorMsg: string read FErrorMsg;
  end;

  {** RegisterBackend 可用性切换写线程（用于 public ABI pod info 并发回归） *}
  TBackendRegisterToggleWorker = class(TThread)
  private
    FIterations: Integer;
    FBackend: TSimdBackend;
    FTableEnabled: TSimdDispatchTable;
    FTableDisabled: TSimdDispatchTable;
    FSuccess: Boolean;
    FErrorMsg: string;
  protected
    procedure Execute; override;
  public
    constructor Create(aIterations: Integer; aBackend: TSimdBackend;
      const aTableEnabled, aTableDisabled: TSimdDispatchTable);
    property Success: Boolean read FSuccess;
    property ErrorMsg: string read FErrorMsg;
  end;

  {** public ABI backend pod info 只读线程（与 RegisterBackend 写线程并发） *}
  TPublicAbiPodInfoReadWorker = class(TThread)
  private
    FIterations: Integer;
    FBackend: TSimdBackend;
    FExpectedCapsA: UInt64;
    FExpectedCapsB: UInt64;
    FExpectedFlagsA: TFafafaSimdAbiFlags;
    FExpectedFlagsB: TFafafaSimdAbiFlags;
    FSuccess: Boolean;
    FErrorMsg: string;
  protected
    procedure Execute; override;
  public
    constructor Create(aIterations: Integer; aBackend: TSimdBackend;
      aExpectedCapsA, aExpectedCapsB: UInt64;
      aExpectedFlagsA, aExpectedFlagsB: TFafafaSimdAbiFlags);
    property Success: Boolean read FSuccess;
    property ErrorMsg: string read FErrorMsg;
  end;

  {** current backend info 只读线程（与 RegisterBackend 写线程并发） *}
  TCurrentBackendInfoReadWorker = class(TThread)
  private
    FIterations: Integer;
    FExpectedInfoA: TSimdBackendInfo;
    FExpectedInfoB: TSimdBackendInfo;
    FSuccess: Boolean;
    FErrorMsg: string;
  protected
    procedure Execute; override;
  public
    constructor Create(aIterations: Integer;
      const aExpectedInfoA, aExpectedInfoB: TSimdBackendInfo);
    property Success: Boolean read FSuccess;
    property ErrorMsg: string read FErrorMsg;
  end;

  {** dispatchable helper 只读线程（与 vector-asm toggle 写线程并发） *}
  TDispatchableHelpersReadWorker = class(TThread)
  private
    FIterations: Integer;
    FExpectedListEnabled: TSimdBackendArray;
    FExpectedListDisabled: TSimdBackendArray;
    FExpectedBestEnabled: TSimdBackend;
    FExpectedBestDisabled: TSimdBackend;
    FSuccess: Boolean;
    FErrorMsg: string;
  protected
    procedure Execute; override;
  public
    constructor Create(aIterations: Integer;
      const aExpectedListEnabled, aExpectedListDisabled: TSimdBackendArray;
      aExpectedBestEnabled, aExpectedBestDisabled: TSimdBackend);
    property Success: Boolean read FSuccess;
    property ErrorMsg: string read FErrorMsg;
  end;

  {** public API active metadata 只读线程（与 RegisterBackend 写线程并发） *}
  TPublicApiActiveMetadataReadWorker = class(TThread)
  private
    FIterations: Integer;
    FExpectedBackendA: TSimdBackend;
    FExpectedBackendB: TSimdBackend;
    FExpectedFlagsA: TFafafaSimdAbiFlags;
    FExpectedFlagsB: TFafafaSimdAbiFlags;
    FSuccess: Boolean;
    FErrorMsg: string;
  protected
    procedure Execute; override;
  public
    constructor Create(aIterations: Integer; aExpectedBackendA, aExpectedBackendB: TSimdBackend;
      aExpectedFlagsA, aExpectedFlagsB: TFafafaSimdAbiFlags);
    property Success: Boolean read FSuccess;
    property ErrorMsg: string read FErrorMsg;
  end;

  {** dispatch 控制面混合并发线程 *}
  TDispatchMixedControlWorker = class(TThread)
  private
    FIterations: Integer;
    FWorkerPhase: Integer;
    FSuccess: Boolean;
    FErrorMsg: string;
  protected
    procedure Execute; override;
  public
    constructor Create(AIterations, AWorkerPhase: Integer);
    property Success: Boolean read FSuccess;
    property ErrorMsg: string read FErrorMsg;
  end;

  {** 大数据处理工作线程 *}
  TLargeDataThread = class(TThread)
  private
    FWorkerIndex: Integer;
    FSuccess: Boolean;
    FErrorMsg: string;
  protected
    procedure Execute; override;
  public
    constructor Create(AWorkerIndex: Integer);
    property Success: Boolean read FSuccess;
    property ErrorMsg: string read FErrorMsg;
  end;

implementation

const
  // 默认并发参数
  DEFAULT_THREAD_COUNT = 8;
  DEFAULT_ITERATIONS = 10000;
  STRESS_THREAD_COUNT = 16;
  STRESS_ITERATIONS = 50000;
  LONG_RUNNING_SECONDS = 2;
  FLOAT_EPSILON: Single = 1e-4;
  DOUBLE_EPSILON: Double = 1e-9;

// === Helper Functions ===

function MakeSplatF32x4(value: Single): TVecF32x4;
begin
  Result := VecF32x4Splat(value);
end;

function MakeSplatF64x2(value: Double): TVecF64x2;
begin
  Result := VecF64x2Splat(value);
end;

function CapabilitiesToAbiBitsLocal(const aCaps: TSimdCapabilities): UInt64;
var
  LCap: TSimdCapability;
begin
  Result := 0;
  for LCap := Low(TSimdCapability) to High(TSimdCapability) do
    if LCap in aCaps then
      Result := Result or (UInt64(1) shl Ord(LCap));
end;

function BuildExpectedAbiFlagsLocal(const aBackend: TSimdBackend;
  const aSupportedOnCPU, aRegistered, aDispatchable, aActive: Boolean): TFafafaSimdAbiFlags;
begin
  Result := 0;
  if aSupportedOnCPU then
    Result := Result or FAF_SIMD_ABI_FLAG_SUPPORTED_ON_CPU;
  if aRegistered then
    Result := Result or FAF_SIMD_ABI_FLAG_REGISTERED;
  if aDispatchable then
    Result := Result or FAF_SIMD_ABI_FLAG_DISPATCHABLE;
  if aActive then
    Result := Result or FAF_SIMD_ABI_FLAG_ACTIVE;
  if aBackend = sbRISCVV then
    Result := Result or FAF_SIMD_ABI_FLAG_EXPERIMENTAL;
end;

function BackendInfoMatchesLocal(const aInfo, aExpected: TSimdBackendInfo): Boolean;
begin
  Result := (aInfo.Backend = aExpected.Backend) and
    (aInfo.Name = aExpected.Name) and
    (aInfo.Description = aExpected.Description) and
    (aInfo.Capabilities = aExpected.Capabilities) and
    (aInfo.Available = aExpected.Available) and
    (aInfo.Priority = aExpected.Priority);
end;

function DescribeBackendInfoLocal(const aInfo: TSimdBackendInfo): string;
begin
  Result := Format('backend=%d available=%s caps=%d priority=%d name=%s',
    [Ord(aInfo.Backend), BoolToStr(aInfo.Available, True),
     CapabilitiesToAbiBitsLocal(aInfo.Capabilities), aInfo.Priority, aInfo.Name]);
end;

function SameBackendArrayLocal(const aLeft, aRight: TSimdBackendArray): Boolean;
var
  LIndex: Integer;
begin
  if Length(aLeft) <> Length(aRight) then
    Exit(False);

  for LIndex := 0 to High(aLeft) do
    if aLeft[LIndex] <> aRight[LIndex] then
      Exit(False);

  Result := True;
end;

function DescribeBackendArrayLocal(const aBackends: TSimdBackendArray): string;
var
  LIndex: Integer;
begin
  Result := '[';
  for LIndex := 0 to High(aBackends) do
  begin
    if LIndex > 0 then
      Result := Result + ',';
    Result := Result + IntToStr(Ord(aBackends[LIndex]));
  end;
  Result := Result + ']';
end;

function TryFindInactiveSupportedBackendForPodInfoMutation(out aBackend: TSimdBackend;
  out aDispatchTable: TSimdDispatchTable): Boolean;
var
  LBackend: TSimdBackend;
  LActiveBackend: TSimdBackend;
begin
  Result := False;
  aBackend := sbScalar;
  aDispatchTable := Default(TSimdDispatchTable);
  LActiveBackend := GetActiveBackend;

  for LBackend := Low(TSimdBackend) to High(TSimdBackend) do
  begin
    if (LBackend = sbScalar) or (LBackend = LActiveBackend) then
      Continue;
    if not IsBackendAvailableOnCPU(LBackend) then
      Continue;
    if not TryGetRegisteredBackendDispatchTable(LBackend, aDispatchTable) then
      Continue;
    if not aDispatchTable.BackendInfo.Available then
      Continue;
    if aDispatchTable.BackendInfo.Capabilities = [] then
      Continue;
    aBackend := LBackend;
    Exit(True);
  end;
end;

// === TF32x4AddWorker ===

constructor TF32x4AddWorker.Create(AWorkerIndex, AIterations: Integer);
begin
  inherited Create(True);  // Create suspended
  FreeOnTerminate := False;
  FWorkerIndex := AWorkerIndex;
  FIterations := AIterations;
  FSuccess := False;
  FErrorMsg := '';
end;

procedure TF32x4AddWorker.Execute;
var
  i: Integer;
  a, b, c: TVecF32x4;
  expected, actual: Single;
  baseVal: Single;
begin
  try
    // 每个线程使用不同的基础值避免缓存效应
    baseVal := FWorkerIndex * 100.0;

    for i := 0 to FIterations - 1 do
    begin
      // 创建向量
      a := MakeSplatF32x4(baseVal + i);
      b := MakeSplatF32x4(i * 0.5);

      // 执行 SIMD 加法
      c := VecF32x4Add(a, b);

      // 验证结果
      expected := (baseVal + i) + (i * 0.5);
      actual := VecF32x4Extract(c, 0);

      if Abs(actual - expected) > FLOAT_EPSILON * Max(1.0, Abs(expected)) then
      begin
        FErrorMsg := Format('Worker %d, iter %d: expected %.6f, got %.6f',
                           [FWorkerIndex, i, expected, actual]);
        Exit;
      end;
    end;

    FSuccess := True;
  except
    on E: Exception do
      FErrorMsg := Format('Worker %d exception: %s', [FWorkerIndex, E.Message]);
  end;
end;

// === TF32x4MulWorker ===

constructor TF32x4MulWorker.Create(AWorkerIndex, AIterations: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FWorkerIndex := AWorkerIndex;
  FIterations := AIterations;
  FSuccess := False;
  FErrorMsg := '';
end;

procedure TF32x4MulWorker.Execute;
var
  i: Integer;
  a, b, c: TVecF32x4;
  expected, actual: Single;
  baseVal: Single;
begin
  try
    baseVal := (FWorkerIndex + 1) * 10.0;

    for i := 0 to FIterations - 1 do
    begin
      a := MakeSplatF32x4(baseVal);
      b := MakeSplatF32x4((i mod 100 + 1) * 0.01);

      c := VecF32x4Mul(a, b);

      expected := baseVal * ((i mod 100 + 1) * 0.01);
      actual := VecF32x4Extract(c, 0);

      if Abs(actual - expected) > FLOAT_EPSILON * Max(1.0, Abs(expected)) then
      begin
        FErrorMsg := Format('Worker %d, iter %d: expected %.6f, got %.6f',
                           [FWorkerIndex, i, expected, actual]);
        Exit;
      end;
    end;

    FSuccess := True;
  except
    on E: Exception do
      FErrorMsg := Format('Worker %d exception: %s', [FWorkerIndex, E.Message]);
  end;
end;

// === TF64x2OpsWorker ===

constructor TF64x2OpsWorker.Create(AWorkerIndex, AIterations: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FWorkerIndex := AWorkerIndex;
  FIterations := AIterations;
  FSuccess := False;
  FErrorMsg := '';
end;

procedure TF64x2OpsWorker.Execute;
var
  i: Integer;
  a, b, c: TVecF64x2;
  expected, actual: Double;
  baseVal: Double;
begin
  try
    baseVal := FWorkerIndex * 10000.0;

    for i := 0 to FIterations - 1 do
    begin
      a := MakeSplatF64x2(baseVal + i);
      b := MakeSplatF64x2((i mod 1000 + 1) * 0.001);

      // 测试乘法
      c := VecF64x2Mul(a, b);

      expected := (baseVal + i) * ((i mod 1000 + 1) * 0.001);
      actual := c.d[0];

      if Abs(actual - expected) > DOUBLE_EPSILON * Abs(expected) + DOUBLE_EPSILON then
      begin
        FErrorMsg := Format('Worker %d, iter %d: expected %.10f, got %.10f',
                           [FWorkerIndex, i, expected, actual]);
        Exit;
      end;
    end;

    FSuccess := True;
  except
    on E: Exception do
      FErrorMsg := Format('Worker %d exception: %s', [FWorkerIndex, E.Message]);
  end;
end;

// === TDispatchAccessWorker ===

constructor TDispatchAccessWorker.Create(AWorkerIndex, AIterations: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FWorkerIndex := AWorkerIndex;
  FIterations := AIterations;
  FSuccess := False;
  FErrorMsg := '';
end;

procedure TDispatchAccessWorker.Execute;
var
  i: Integer;
  backend: TSimdBackend;
  dt: PSimdDispatchTable;
  a, b, c: TVecF32x4;
begin
  try
    for i := 0 to FIterations - 1 do
    begin
      // 并发访问 dispatch table
      backend := GetActiveBackend;
      dt := GetDispatchTable;

      // 验证 dispatch table 有效
      if dt = nil then
      begin
        FErrorMsg := Format('Worker %d, iter %d: dispatch table is nil', [FWorkerIndex, i]);
        Exit;
      end;

      // 验证后端一致性
      if dt^.Backend <> backend then
      begin
        FErrorMsg := Format('Worker %d, iter %d: backend mismatch (table=%d, active=%d)',
                           [FWorkerIndex, i, Ord(dt^.Backend), Ord(backend)]);
        Exit;
      end;

      // 验证函数指针有效
      if not Assigned(dt^.AddF32x4) then
      begin
        FErrorMsg := Format('Worker %d, iter %d: AddF32x4 not assigned', [FWorkerIndex, i]);
        Exit;
      end;

      // 执行实际操作验证功能正常
      a := MakeSplatF32x4(1.0);
      b := MakeSplatF32x4(2.0);
      c := dt^.AddF32x4(a, b);

      if Abs(VecF32x4Extract(c, 0) - 3.0) > FLOAT_EPSILON then
      begin
        FErrorMsg := Format('Worker %d, iter %d: operation result incorrect', [FWorkerIndex, i]);
        Exit;
      end;
    end;

    FSuccess := True;
  except
    on E: Exception do
      FErrorMsg := Format('Worker %d exception: %s', [FWorkerIndex, E.Message]);
  end;
end;

// === TMixedMathWorker ===

constructor TMixedMathWorker.Create(AWorkerIndex, AIterations: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FWorkerIndex := AWorkerIndex;
  FIterations := AIterations;
  FSuccess := False;
  FErrorMsg := '';
end;

procedure TMixedMathWorker.Execute;
var
  i: Integer;
  a, b, c, d: TVecF32x4;
  expected, actual: Single;
  baseVal: Single;
begin
  try
    baseVal := (FWorkerIndex + 1) * 50.0;

    for i := 0 to FIterations - 1 do
    begin
      // 执行一系列混合操作
      a := MakeSplatF32x4(baseVal);
      b := MakeSplatF32x4(i mod 50 + 1);

      // c = a + b
      c := VecF32x4Add(a, b);
      // d = c * a - b
      d := VecF32x4Sub(VecF32x4Mul(c, a), b);

      expected := (baseVal + (i mod 50 + 1)) * baseVal - (i mod 50 + 1);
      actual := VecF32x4Extract(d, 0);

      if Abs(actual - expected) > FLOAT_EPSILON * Max(1.0, Abs(expected)) then
      begin
        FErrorMsg := Format('Worker %d, iter %d: expected %.6f, got %.6f',
                           [FWorkerIndex, i, expected, actual]);
        Exit;
      end;
    end;

    FSuccess := True;
  except
    on E: Exception do
      FErrorMsg := Format('Worker %d exception: %s', [FWorkerIndex, E.Message]);
  end;
end;

// === TReductionWorker ===

constructor TReductionWorker.Create(AWorkerIndex, AIterations: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FWorkerIndex := AWorkerIndex;
  FIterations := AIterations;
  FSuccess := False;
  FErrorMsg := '';
end;

procedure TReductionWorker.Execute;
var
  i: Integer;
  a: TVecF32x4;
  expected, actual: Single;
  baseVal: Single;
begin
  try
    baseVal := FWorkerIndex + 1;

    for i := 0 to FIterations - 1 do
    begin
      // 创建包含不同值的向量并进行归约
      a := MakeSplatF32x4(baseVal * (i mod 100 + 1));

      // 测试归约加法
      actual := VecF32x4ReduceAdd(a);
      expected := baseVal * (i mod 100 + 1) * 4;  // 4个相同的元素相加

      if Abs(actual - expected) > FLOAT_EPSILON * Max(1.0, Abs(expected)) then
      begin
        FErrorMsg := Format('Worker %d, iter %d: expected %.6f, got %.6f',
                           [FWorkerIndex, i, expected, actual]);
        Exit;
      end;
    end;

    FSuccess := True;
  except
    on E: Exception do
      FErrorMsg := Format('Worker %d exception: %s', [FWorkerIndex, E.Message]);
  end;
end;

// === TCompoundOpsWorker ===

constructor TCompoundOpsWorker.Create(AWorkerIndex, AIterations: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FWorkerIndex := AWorkerIndex;
  FIterations := AIterations;
  FSuccess := False;
  FErrorMsg := '';
end;

procedure TCompoundOpsWorker.Execute;
var
  i, j: Integer;
  a, b, c: TVecF32x4;
  sum: Single;
  baseVal: Single;
begin
  try
    baseVal := (FWorkerIndex + 1) * 10.0;

    for i := 0 to FIterations - 1 do
    begin
      // 执行多次迭代的复合运算
      a := MakeSplatF32x4(baseVal);
      b := MakeSplatF32x4(0.1);

      for j := 0 to 9 do
      begin
        c := VecF32x4Add(a, b);
        a := VecF32x4Mul(c, MakeSplatF32x4(0.99));
      end;

      // 验证结果不是 NaN 或 Inf
      sum := VecF32x4ReduceAdd(a);
      if IsNan(sum) or IsInfinite(sum) then
      begin
        FErrorMsg := Format('Worker %d, iter %d: invalid result', [FWorkerIndex, i]);
        Exit;
      end;
    end;

    FSuccess := True;
  except
    on E: Exception do
      FErrorMsg := Format('Worker %d exception: %s', [FWorkerIndex, E.Message]);
  end;
end;

// === TStressWorker ===

constructor TStressWorker.Create(AWorkerIndex, AIterations: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FWorkerIndex := AWorkerIndex;
  FIterations := AIterations;
  FSuccess := False;
  FErrorMsg := '';
  FOperationsCompleted := 0;
end;

procedure TStressWorker.Execute;
var
  i, j: Integer;
  a4, b4, c4: TVecF32x4;
  checksum: Single;
  baseVal: Single;
begin
  try
    baseVal := FWorkerIndex * 10000.0;
    checksum := 0;

    for i := 0 to FIterations - 1 do
    begin
      // 执行多种 SIMD 操作
      a4 := MakeSplatF32x4(baseVal + i);
      b4 := MakeSplatF32x4(0.001);

      for j := 0 to 9 do
      begin
        c4 := VecF32x4Add(a4, b4);
        a4 := VecF32x4Mul(c4, b4);
        Inc(FOperationsCompleted, 2);
      end;

      checksum := checksum + VecF32x4Extract(a4, 0);

      // 防止编译器优化掉计算
      if IsNan(checksum) or IsInfinite(checksum) then
      begin
        // 重置checksum但继续测试
        checksum := 0;
      end;
    end;

    FSuccess := True;
  except
    on E: Exception do
      FErrorMsg := Format('Worker %d exception: %s', [FWorkerIndex, E.Message]);
  end;
end;

// === TBackendQueryThread ===

constructor TBackendQueryThread.Create(AWorkerIndex: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FWorkerIndex := AWorkerIndex;
  FSuccess := False;
end;

procedure TBackendQueryThread.Execute;
var
  k: Integer;
begin
  try
    for k := 0 to 999 do
      FResult := GetActiveBackend;
    FSuccess := True;
  except
    FSuccess := False;
  end;
end;

// === TVectorAsmToggleWorker ===

constructor TVectorAsmToggleWorker.Create(AIterations: Integer; AInitialValue: Boolean);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FIterations := AIterations;
  FInitialValue := AInitialValue;
  FSuccess := False;
  FErrorMsg := '';
end;

procedure TVectorAsmToggleWorker.Execute;
var
  LIndex: Integer;
  LExpected: Boolean;
  LCurrent: Boolean;
  LDispatch: PSimdDispatchTable;
begin
  try
    for LIndex := 0 to FIterations - 1 do
    begin
      if (LIndex and 1) = 0 then
        LExpected := not FInitialValue
      else
        LExpected := FInitialValue;

      SetVectorAsmEnabled(LExpected);
      LCurrent := IsVectorAsmEnabled;
      if LCurrent <> LExpected then
      begin
        FErrorMsg := Format('toggle mismatch at iter %d: expected=%s got=%s',
          [LIndex, BoolToStr(LExpected, True), BoolToStr(LCurrent, True)]);
        Exit;
      end;

      LDispatch := GetDispatchTable;
      if (LDispatch = nil) or (not Assigned(LDispatch^.AddF32x4)) then
      begin
        FErrorMsg := Format('dispatch unavailable at iter %d', [LIndex]);
        Exit;
      end;
    end;
    FSuccess := True;
  except
    on E: Exception do
      FErrorMsg := 'toggle worker exception: ' + E.Message;
  end;
end;

// === TVectorAsmMultiToggleWorker ===

constructor TVectorAsmMultiToggleWorker.Create(AIterations, AWriterPhase: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FIterations := AIterations;
  FWriterPhase := AWriterPhase;
  FSuccess := False;
  FErrorMsg := '';
end;

procedure TVectorAsmMultiToggleWorker.Execute;
var
  LIndex: Integer;
  LTargetEnabled: Boolean;
  LDispatch: PSimdDispatchTable;
  LA, LB, LC: TVecF32x4;
  LValue: Single;
begin
  try
    for LIndex := 0 to FIterations - 1 do
    begin
      LTargetEnabled := ((LIndex + FWriterPhase) and 1) = 0;
      SetVectorAsmEnabled(LTargetEnabled);

      LDispatch := GetDispatchTable;
      if (LDispatch = nil) or (not Assigned(LDispatch^.SubF32x4)) then
      begin
        FErrorMsg := Format('multi-writer dispatch unavailable at iter %d', [LIndex]);
        Exit;
      end;

      LA := MakeSplatF32x4(4.0);
      LB := MakeSplatF32x4(-1.0);
      LC := LDispatch^.SubF32x4(LA, LB);
      LValue := VecF32x4Extract(LC, 0);
      if Abs(LValue - 5.0) > FLOAT_EPSILON then
      begin
        FErrorMsg := Format('multi-writer dispatch sub mismatch at iter %d: %.6f', [LIndex, LValue]);
        Exit;
      end;
    end;
    FSuccess := True;
  except
    on E: Exception do
      FErrorMsg := 'multi-writer toggle exception: ' + E.Message;
  end;
end;

// === TVectorAsmReadWorker ===

constructor TVectorAsmReadWorker.Create(AIterations: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FIterations := AIterations;
  FSuccess := False;
  FErrorMsg := '';
end;

procedure TVectorAsmReadWorker.Execute;
var
  LIndex: Integer;
  LA, LB, LC: TVecF32x4;
  LDispatch: PSimdDispatchTable;
  LValue: Single;
begin
  try
    for LIndex := 0 to FIterations - 1 do
    begin
      LDispatch := GetDispatchTable;
      if (LDispatch = nil) or (not Assigned(LDispatch^.AddF32x4)) then
      begin
        FErrorMsg := Format('dispatch unavailable at iter %d', [LIndex]);
        Exit;
      end;

      LA := MakeSplatF32x4(1.0);
      LB := MakeSplatF32x4(2.0);
      LC := LDispatch^.AddF32x4(LA, LB);
      LValue := VecF32x4Extract(LC, 0);
      if Abs(LValue - 3.0) > FLOAT_EPSILON then
      begin
        FErrorMsg := Format('dispatch add mismatch at iter %d: %.6f', [LIndex, LValue]);
        Exit;
      end;
    end;
    FSuccess := True;
  except
    on E: Exception do
      FErrorMsg := 'reader worker exception: ' + E.Message;
  end;
end;

// === TDispatchMixedControlWorker ===

constructor TPublicApiReadWorker.Create(aIterations: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FIterations := aIterations;
  FSuccess := False;
  FErrorMsg := '';
end;

procedure TPublicApiReadWorker.Execute;
var
  LIndex: Integer;
  LApi: PFafafaSimdPublicApi;
  LExpectedFlags: TFafafaSimdAbiFlags;
  LExpectedAbiMajor: UInt16;
  LExpectedAbiMinor: UInt16;
  LExpectedSigHi: UInt64;
  LExpectedSigLo: UInt64;
  LBufA: array[0..31] of Byte;
  LBufB: array[0..31] of Byte;
begin
  try
    FillChar(LBufA, SizeOf(LBufA), $5A);
    FillChar(LBufB, SizeOf(LBufB), $5A);
    LExpectedFlags := FAF_SIMD_ABI_FLAG_REGISTERED or
      FAF_SIMD_ABI_FLAG_DISPATCHABLE or FAF_SIMD_ABI_FLAG_ACTIVE;
    LExpectedAbiMajor := GetSimdAbiVersionMajor;
    LExpectedAbiMinor := GetSimdAbiVersionMinor;
    GetSimdAbiSignature(LExpectedSigHi, LExpectedSigLo);

    for LIndex := 0 to FIterations - 1 do
    begin
      LApi := GetSimdPublicApi;
      if LApi = nil then
      begin
        FErrorMsg := Format('public api table is nil at iter %d', [LIndex]);
        Exit;
      end;
      if LApi^.StructSize <> SizeOf(TFafafaSimdPublicApi) then
      begin
        FErrorMsg := Format('public api StructSize torn at iter %d: expected=%d got=%d',
          [LIndex, SizeOf(TFafafaSimdPublicApi), LApi^.StructSize]);
        Exit;
      end;
      if LApi^.AbiVersionMajor <> LExpectedAbiMajor then
      begin
        FErrorMsg := Format('public api AbiVersionMajor torn at iter %d: expected=%d got=%d',
          [LIndex, LExpectedAbiMajor, LApi^.AbiVersionMajor]);
        Exit;
      end;
      if LApi^.AbiVersionMinor <> LExpectedAbiMinor then
      begin
        FErrorMsg := Format('public api AbiVersionMinor torn at iter %d: expected=%d got=%d',
          [LIndex, LExpectedAbiMinor, LApi^.AbiVersionMinor]);
        Exit;
      end;
      if (LApi^.AbiSignatureHi <> LExpectedSigHi) or (LApi^.AbiSignatureLo <> LExpectedSigLo) then
      begin
        FErrorMsg := Format('public api signature torn at iter %d', [LIndex]);
        Exit;
      end;
      if LApi^.ActiveBackendId > UInt32(Ord(High(TSimdBackend))) then
      begin
        FErrorMsg := Format('public api ActiveBackendId out of range at iter %d: %d',
          [LIndex, LApi^.ActiveBackendId]);
        Exit;
      end;
      if (LApi^.ActiveFlags and LExpectedFlags) <> LExpectedFlags then
      begin
        FErrorMsg := Format('public api ActiveFlags missing registered/dispatchable/active bits at iter %d: %d',
          [LIndex, LApi^.ActiveFlags]);
        Exit;
      end;
      if (not Assigned(LApi^.MemEqual)) or
         (not Assigned(LApi^.MemFindByte)) or
         (not Assigned(LApi^.MemCopy)) or
         (not Assigned(LApi^.MinMaxBytes)) then
      begin
        FErrorMsg := Format('public api shim pointer torn at iter %d', [LIndex]);
        Exit;
      end;
      if not LApi^.MemEqual(@LBufA[0], @LBufB[0], SizeUInt(Length(LBufA))) then
      begin
        FErrorMsg := Format('public api MemEqual parity mismatch at iter %d', [LIndex]);
        Exit;
      end;
    end;

    FSuccess := True;
  except
    on E: Exception do
      FErrorMsg := 'public api reader exception: ' + E.Message;
  end;
end;

constructor TBackendRegisterToggleWorker.Create(aIterations: Integer; aBackend: TSimdBackend;
  const aTableEnabled, aTableDisabled: TSimdDispatchTable);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FIterations := aIterations;
  FBackend := aBackend;
  FTableEnabled := aTableEnabled;
  FTableDisabled := aTableDisabled;
  FSuccess := False;
  FErrorMsg := '';
end;

procedure TBackendRegisterToggleWorker.Execute;
var
  LIndex: Integer;
begin
  try
    for LIndex := 0 to FIterations - 1 do
    begin
      if (LIndex and 1) = 0 then
        RegisterBackend(FBackend, FTableEnabled)
      else
        RegisterBackend(FBackend, FTableDisabled);
      if (LIndex and 7) = 0 then
        ThreadSwitch;
    end;
    FSuccess := True;
  except
    on E: Exception do
      FErrorMsg := 'register toggle worker exception: ' + E.Message;
  end;
end;

constructor TPublicAbiPodInfoReadWorker.Create(aIterations: Integer; aBackend: TSimdBackend;
  aExpectedCapsA, aExpectedCapsB: UInt64;
  aExpectedFlagsA, aExpectedFlagsB: TFafafaSimdAbiFlags);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FIterations := aIterations;
  FBackend := aBackend;
  FExpectedCapsA := aExpectedCapsA;
  FExpectedCapsB := aExpectedCapsB;
  FExpectedFlagsA := aExpectedFlagsA;
  FExpectedFlagsB := aExpectedFlagsB;
  FSuccess := False;
  FErrorMsg := '';
end;

procedure TPublicAbiPodInfoReadWorker.Execute;
var
  LIndex: Integer;
  LInfo: TFafafaSimdBackendPodInfo;
  LMatchesA: Boolean;
  LMatchesB: Boolean;
begin
  try
    for LIndex := 0 to FIterations - 1 do
    begin
      if (LIndex and 3) = 0 then
        ThreadSwitch;
      if not TryGetSimdBackendPodInfo(FBackend, LInfo) then
      begin
        FErrorMsg := Format('backend pod info query failed at iter %d', [LIndex]);
        Exit;
      end;
      if LInfo.StructSize <> SizeOf(TFafafaSimdBackendPodInfo) then
      begin
        FErrorMsg := Format('backend pod info StructSize torn at iter %d: expected=%d got=%d',
          [LIndex, SizeOf(TFafafaSimdBackendPodInfo), LInfo.StructSize]);
        Exit;
      end;
      if LInfo.BackendId <> UInt32(Ord(FBackend)) then
      begin
        FErrorMsg := Format('backend pod info BackendId torn at iter %d: expected=%d got=%d',
          [LIndex, Ord(FBackend), LInfo.BackendId]);
        Exit;
      end;

      LMatchesA := (LInfo.CapabilityBits = FExpectedCapsA) and
        (LInfo.Flags = FExpectedFlagsA);
      LMatchesB := (LInfo.CapabilityBits = FExpectedCapsB) and
        (LInfo.Flags = FExpectedFlagsB);
      if (not LMatchesA) and (not LMatchesB) then
      begin
        FErrorMsg := Format(
          'backend pod info mixed snapshot at iter %d: caps=%d flags=%d expectedA=(%d,%d) expectedB=(%d,%d)',
          [LIndex, LInfo.CapabilityBits, LInfo.Flags, FExpectedCapsA, FExpectedFlagsA,
           FExpectedCapsB, FExpectedFlagsB]);
        Exit;
      end;
    end;

    FSuccess := True;
  except
    on E: Exception do
      FErrorMsg := 'backend pod info reader exception: ' + E.Message;
  end;
end;

constructor TCurrentBackendInfoReadWorker.Create(aIterations: Integer;
  const aExpectedInfoA, aExpectedInfoB: TSimdBackendInfo);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FIterations := aIterations;
  FExpectedInfoA := aExpectedInfoA;
  FExpectedInfoB := aExpectedInfoB;
  FSuccess := False;
  FErrorMsg := '';
end;

procedure TCurrentBackendInfoReadWorker.Execute;
var
  LIndex: Integer;
  LInfo: TSimdBackendInfo;
begin
  try
    for LIndex := 0 to FIterations - 1 do
    begin
      if (LIndex and 3) = 0 then
        ThreadSwitch;

      LInfo := GetCurrentBackendInfo;
      if (not BackendInfoMatchesLocal(LInfo, FExpectedInfoA)) and
         (not BackendInfoMatchesLocal(LInfo, FExpectedInfoB)) then
      begin
        FErrorMsg := Format('current backend info mixed snapshot at iter %d: got=(%s) expectedA=(%s) expectedB=(%s)',
          [LIndex, DescribeBackendInfoLocal(LInfo),
           DescribeBackendInfoLocal(FExpectedInfoA),
           DescribeBackendInfoLocal(FExpectedInfoB)]);
        Exit;
      end;
    end;

    FSuccess := True;
  except
    on E: Exception do
      FErrorMsg := 'current backend info reader exception: ' + E.Message;
  end;
end;

constructor TDispatchableHelpersReadWorker.Create(aIterations: Integer;
  const aExpectedListEnabled, aExpectedListDisabled: TSimdBackendArray;
  aExpectedBestEnabled, aExpectedBestDisabled: TSimdBackend);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FIterations := aIterations;
  FExpectedListEnabled := Copy(aExpectedListEnabled);
  FExpectedListDisabled := Copy(aExpectedListDisabled);
  FExpectedBestEnabled := aExpectedBestEnabled;
  FExpectedBestDisabled := aExpectedBestDisabled;
  FSuccess := False;
  FErrorMsg := '';
end;

procedure TDispatchableHelpersReadWorker.Execute;
var
  LIndex: Integer;
  LDispatchableView: TSimdBackendArray;
  LAvailableView: TSimdBackendArray;
  LBestBackend: TSimdBackend;
begin
  try
    for LIndex := 0 to FIterations - 1 do
    begin
      LDispatchableView := fafafa.core.simd.GetDispatchableBackendList;
      LAvailableView := fafafa.core.simd.GetAvailableBackendList;
      LBestBackend := fafafa.core.simd.GetBestDispatchableBackend;

      if (not SameBackendArrayLocal(LDispatchableView, FExpectedListEnabled)) and
         (not SameBackendArrayLocal(LDispatchableView, FExpectedListDisabled)) then
      begin
        FErrorMsg := Format(
          'dispatchable helper mixed snapshot at iter %d: got=%s expectedEnabled=%s expectedDisabled=%s',
          [LIndex, DescribeBackendArrayLocal(LDispatchableView),
           DescribeBackendArrayLocal(FExpectedListEnabled),
           DescribeBackendArrayLocal(FExpectedListDisabled)]);
        Exit;
      end;

      if (not SameBackendArrayLocal(LAvailableView, FExpectedListEnabled)) and
         (not SameBackendArrayLocal(LAvailableView, FExpectedListDisabled)) then
      begin
        FErrorMsg := Format(
          'available helper mixed snapshot at iter %d: got=%s expectedEnabled=%s expectedDisabled=%s',
          [LIndex, DescribeBackendArrayLocal(LAvailableView),
           DescribeBackendArrayLocal(FExpectedListEnabled),
           DescribeBackendArrayLocal(FExpectedListDisabled)]);
        Exit;
      end;

      if (LBestBackend <> FExpectedBestEnabled) and (LBestBackend <> FExpectedBestDisabled) then
      begin
        FErrorMsg := Format(
          'best dispatchable backend mixed snapshot at iter %d: got=%d expectedEnabled=%d expectedDisabled=%d',
          [LIndex, Ord(LBestBackend), Ord(FExpectedBestEnabled), Ord(FExpectedBestDisabled)]);
        Exit;
      end;
    end;

    FSuccess := True;
  except
    on E: Exception do
      FErrorMsg := 'dispatchable helper reader exception: ' + E.Message;
  end;
end;

constructor TPublicApiActiveMetadataReadWorker.Create(aIterations: Integer;
  aExpectedBackendA, aExpectedBackendB: TSimdBackend;
  aExpectedFlagsA, aExpectedFlagsB: TFafafaSimdAbiFlags);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FIterations := aIterations;
  FExpectedBackendA := aExpectedBackendA;
  FExpectedBackendB := aExpectedBackendB;
  FExpectedFlagsA := aExpectedFlagsA;
  FExpectedFlagsB := aExpectedFlagsB;
  FSuccess := False;
  FErrorMsg := '';
end;

procedure TPublicApiActiveMetadataReadWorker.Execute;
var
  LIndex: Integer;
  LApi: PFafafaSimdPublicApi;
  LMatchesA: Boolean;
  LMatchesB: Boolean;
  LBufA: array[0..31] of Byte;
  LBufB: array[0..31] of Byte;
begin
  try
    FillChar(LBufA, SizeOf(LBufA), $3C);
    FillChar(LBufB, SizeOf(LBufB), $3C);

    for LIndex := 0 to FIterations - 1 do
    begin
      if (LIndex and 3) = 0 then
        ThreadSwitch;

      LApi := GetSimdPublicApi;
      if LApi = nil then
      begin
        FErrorMsg := Format('public api table is nil at iter %d', [LIndex]);
        Exit;
      end;
      if LApi^.StructSize <> SizeOf(TFafafaSimdPublicApi) then
      begin
        FErrorMsg := Format('public api StructSize torn at iter %d: expected=%d got=%d',
          [LIndex, SizeOf(TFafafaSimdPublicApi), LApi^.StructSize]);
        Exit;
      end;

      LMatchesA := (LApi^.ActiveBackendId = UInt32(Ord(FExpectedBackendA))) and
        (LApi^.ActiveFlags = FExpectedFlagsA);
      LMatchesB := (LApi^.ActiveBackendId = UInt32(Ord(FExpectedBackendB))) and
        (LApi^.ActiveFlags = FExpectedFlagsB);
      if (not LMatchesA) and (not LMatchesB) then
      begin
        FErrorMsg := Format(
          'public api active metadata mixed snapshot at iter %d: id=%d flags=%d expectedA=(%d,%d) expectedB=(%d,%d)',
          [LIndex, LApi^.ActiveBackendId, LApi^.ActiveFlags,
           Ord(FExpectedBackendA), FExpectedFlagsA, Ord(FExpectedBackendB), FExpectedFlagsB]);
        Exit;
      end;

      if (not Assigned(LApi^.MemEqual)) or
         (not LApi^.MemEqual(@LBufA[0], @LBufB[0], SizeUInt(Length(LBufA)))) then
      begin
        FErrorMsg := Format('public api active metadata MemEqual parity mismatch at iter %d', [LIndex]);
        Exit;
      end;
    end;

    FSuccess := True;
  except
    on E: Exception do
      FErrorMsg := 'public api active metadata reader exception: ' + E.Message;
  end;
end;

// === TDispatchMixedControlWorker ===

constructor TDispatchMixedControlWorker.Create(AIterations, AWorkerPhase: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FIterations := AIterations;
  FWorkerPhase := AWorkerPhase;
  FSuccess := False;
  FErrorMsg := '';
end;

procedure TDispatchMixedControlWorker.Execute;
var
  LIndex: Integer;
  LDispatch: PSimdDispatchTable;
  LA, LB, LC, LProbe: TVecF32x4;
  LValue: Single;
begin
  try
    for LIndex := 0 to FIterations - 1 do
    begin
      case ((LIndex + FWorkerPhase) mod 5) of
        0:
          SetVectorAsmEnabled(((LIndex + FWorkerPhase) and 1) = 0);
        1:
          SetActiveBackend(sbScalar);
        2:
          if IsBackendRegistered(sbSSE2) then
            SetActiveBackend(sbSSE2)
          else
            ResetToAutomaticBackend;
        3:
          if IsBackendRegistered(sbAVX2) then
            SetActiveBackend(sbAVX2)
          else
            ResetToAutomaticBackend;
      else
        ResetToAutomaticBackend;
      end;

      LDispatch := GetDispatchTable;
      if (LDispatch = nil) or (not Assigned(LDispatch^.AddF32x4)) then
      begin
        FErrorMsg := Format('mixed-control dispatch unavailable at iter %d', [LIndex]);
        Exit;
      end;
      if (not Assigned(LDispatch^.RoundF32x4)) or (not Assigned(LDispatch^.TruncF32x4)) then
      begin
        FErrorMsg := Format('mixed-control round/trunc unavailable at iter %d', [LIndex]);
        Exit;
      end;

      LA := MakeSplatF32x4(1.0);
      LB := MakeSplatF32x4(2.0);
      LC := LDispatch^.AddF32x4(LA, LB);
      LValue := VecF32x4Extract(LC, 0);
      if Abs(LValue - 3.0) > FLOAT_EPSILON then
      begin
        FErrorMsg := Format('mixed-control AddF32x4 mismatch at iter %d: %.6f', [LIndex, LValue]);
        Exit;
      end;

      LProbe := MakeSplatF32x4(-1.75);
      LC := LDispatch^.RoundF32x4(LProbe);
      LValue := VecF32x4Extract(LC, 0);
      if Abs(LValue - (-2.0)) > FLOAT_EPSILON then
      begin
        FErrorMsg := Format('mixed-control RoundF32x4 mismatch at iter %d: %.6f', [LIndex, LValue]);
        Exit;
      end;

      LC := LDispatch^.TruncF32x4(LProbe);
      LValue := VecF32x4Extract(LC, 0);
      if Abs(LValue - (-1.0)) > FLOAT_EPSILON then
      begin
        FErrorMsg := Format('mixed-control TruncF32x4 mismatch at iter %d: %.6f', [LIndex, LValue]);
        Exit;
      end;
    end;
    FSuccess := True;
  except
    on E: Exception do
      FErrorMsg := 'mixed-control worker exception: ' + E.Message;
  end;
end;

// === TLargeDataThread ===

constructor TLargeDataThread.Create(AWorkerIndex: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FWorkerIndex := AWorkerIndex;
  FSuccess := False;
  FErrorMsg := '';
end;

procedure TLargeDataThread.Execute;
const
  DATA_SIZE = 10000;
var
  data: array of Single;
  i: Integer;
  a, b, c: TVecF32x4;
  sum: Single;
begin
  try
    data := nil;
    SetLength(data, DATA_SIZE);

    // 初始化数据
    for i := 0 to DATA_SIZE - 1 do
      data[i] := FWorkerIndex * 1000.0 + i;

    // 处理数据（每次 4 个元素）
    sum := 0;
    i := 0;
    while i + 3 < DATA_SIZE do
    begin
      a := VecF32x4Load(@data[i]);
      b := MakeSplatF32x4(2.0);
      c := VecF32x4Mul(a, b);
      sum := sum + VecF32x4ReduceAdd(c);
      Inc(i, 4);
    end;

    // 验证结果
    if IsNan(sum) or IsInfinite(sum) then
      FErrorMsg := Format('Thread %d: invalid sum', [FWorkerIndex])
    else
      FSuccess := True;
  except
    on E: Exception do
      FErrorMsg := Format('Thread %d exception: %s', [FWorkerIndex, E.Message]);
  end;
end;

// === TTestCase_SimdConcurrent ===

procedure TTestCase_SimdConcurrent.Test_Concurrent_F32x4_Add;
var
  workers: array of TF32x4AddWorker;
  i: Integer;
  allSuccess: Boolean;
  errorMsgs: string;
begin
  workers := nil;
  SetLength(workers, DEFAULT_THREAD_COUNT);

  // 创建并启动所有线程
  for i := 0 to High(workers) do
    workers[i] := TF32x4AddWorker.Create(i, DEFAULT_ITERATIONS);

  for i := 0 to High(workers) do
    workers[i].Start;

  // 等待所有线程完成
  for i := 0 to High(workers) do
    workers[i].WaitFor;

  // 检查结果
  allSuccess := True;
  errorMsgs := '';
  for i := 0 to High(workers) do
  begin
    if not workers[i].Success then
    begin
      allSuccess := False;
      errorMsgs := errorMsgs + workers[i].ErrorMsg + '; ';
    end;
    workers[i].Free;
  end;

  AssertTrue('Concurrent F32x4 Add failed: ' + errorMsgs, allSuccess);
end;

procedure TTestCase_SimdConcurrent.Test_Concurrent_F32x4_Mul;
var
  workers: array of TF32x4MulWorker;
  i: Integer;
  allSuccess: Boolean;
  errorMsgs: string;
begin
  workers := nil;
  SetLength(workers, DEFAULT_THREAD_COUNT);

  for i := 0 to High(workers) do
    workers[i] := TF32x4MulWorker.Create(i, DEFAULT_ITERATIONS);

  for i := 0 to High(workers) do
    workers[i].Start;

  for i := 0 to High(workers) do
    workers[i].WaitFor;

  allSuccess := True;
  errorMsgs := '';
  for i := 0 to High(workers) do
  begin
    if not workers[i].Success then
    begin
      allSuccess := False;
      errorMsgs := errorMsgs + workers[i].ErrorMsg + '; ';
    end;
    workers[i].Free;
  end;

  AssertTrue('Concurrent F32x4 Mul failed: ' + errorMsgs, allSuccess);
end;

procedure TTestCase_SimdConcurrent.Test_Concurrent_F64x2_Operations;
var
  workers: array of TF64x2OpsWorker;
  i: Integer;
  allSuccess: Boolean;
  errorMsgs: string;
begin
  workers := nil;
  SetLength(workers, DEFAULT_THREAD_COUNT);

  for i := 0 to High(workers) do
    workers[i] := TF64x2OpsWorker.Create(i, DEFAULT_ITERATIONS);

  for i := 0 to High(workers) do
    workers[i].Start;

  for i := 0 to High(workers) do
    workers[i].WaitFor;

  allSuccess := True;
  errorMsgs := '';
  for i := 0 to High(workers) do
  begin
    if not workers[i].Success then
    begin
      allSuccess := False;
      errorMsgs := errorMsgs + workers[i].ErrorMsg + '; ';
    end;
    workers[i].Free;
  end;

  AssertTrue('Concurrent F64x2 Operations failed: ' + errorMsgs, allSuccess);
end;

procedure TTestCase_SimdConcurrent.Test_Concurrent_Compound_Operations;
var
  workers: array of TCompoundOpsWorker;
  i: Integer;
  allSuccess: Boolean;
  errorMsgs: string;
begin
  workers := nil;
  SetLength(workers, DEFAULT_THREAD_COUNT);

  for i := 0 to High(workers) do
    workers[i] := TCompoundOpsWorker.Create(i, DEFAULT_ITERATIONS);

  for i := 0 to High(workers) do
    workers[i].Start;

  for i := 0 to High(workers) do
    workers[i].WaitFor;

  allSuccess := True;
  errorMsgs := '';
  for i := 0 to High(workers) do
  begin
    if not workers[i].Success then
    begin
      allSuccess := False;
      errorMsgs := errorMsgs + workers[i].ErrorMsg + '; ';
    end;
    workers[i].Free;
  end;

  AssertTrue('Concurrent Compound Operations failed: ' + errorMsgs, allSuccess);
end;

procedure TTestCase_SimdConcurrent.Test_Concurrent_Dispatch_Access;
var
  workers: array of TDispatchAccessWorker;
  i: Integer;
  allSuccess: Boolean;
  errorMsgs: string;
begin
  workers := nil;
  SetLength(workers, DEFAULT_THREAD_COUNT);

  for i := 0 to High(workers) do
    workers[i] := TDispatchAccessWorker.Create(i, DEFAULT_ITERATIONS);

  for i := 0 to High(workers) do
    workers[i].Start;

  for i := 0 to High(workers) do
    workers[i].WaitFor;

  allSuccess := True;
  errorMsgs := '';
  for i := 0 to High(workers) do
  begin
    if not workers[i].Success then
    begin
      allSuccess := False;
      errorMsgs := errorMsgs + workers[i].ErrorMsg + '; ';
    end;
    workers[i].Free;
  end;

  AssertTrue('Concurrent Dispatch Access failed: ' + errorMsgs, allSuccess);
end;

procedure TTestCase_SimdConcurrent.Test_Concurrent_Backend_Query;
var
  threads: array of TBackendQueryThread;
  i: Integer;
  expectedBackend: TSimdBackend;
  allSuccess: Boolean;
begin
  // 获取预期后端
  expectedBackend := GetActiveBackend;

  threads := nil;
  SetLength(threads, DEFAULT_THREAD_COUNT);

  // 创建线程
  for i := 0 to High(threads) do
    threads[i] := TBackendQueryThread.Create(i);

  // 启动所有线程
  for i := 0 to High(threads) do
    threads[i].Start;

  // 等待完成
  for i := 0 to High(threads) do
    threads[i].WaitFor;

  // 验证所有结果一致
  allSuccess := True;
  for i := 0 to High(threads) do
  begin
    if not threads[i].Success then
      allSuccess := False
    else if threads[i].Result <> expectedBackend then
      allSuccess := False;
    threads[i].Free;
  end;

  AssertTrue('Concurrent backend query failed', allSuccess);
end;

procedure TTestCase_SimdConcurrent.Test_Concurrent_VectorAsmToggle_DispatchRead;
const
  TOGGLE_ITERATIONS = 2000;
  READER_THREADS = 4;
  READER_ITERATIONS = 5000;
var
  LToggleWorker: TVectorAsmToggleWorker;
  LReaders: array of TVectorAsmReadWorker;
  LIndex: Integer;
  LAllSuccess: Boolean;
  LErrorMsgs: string;
  LOldVectorAsm: Boolean;
begin
  LOldVectorAsm := IsVectorAsmEnabled;
  LToggleWorker := TVectorAsmToggleWorker.Create(TOGGLE_ITERATIONS, LOldVectorAsm);
  LReaders := nil;
  SetLength(LReaders, READER_THREADS);

  for LIndex := 0 to High(LReaders) do
    LReaders[LIndex] := TVectorAsmReadWorker.Create(READER_ITERATIONS);

  try
    LToggleWorker.Start;
    for LIndex := 0 to High(LReaders) do
      LReaders[LIndex].Start;

    LToggleWorker.WaitFor;
    for LIndex := 0 to High(LReaders) do
      LReaders[LIndex].WaitFor;

    LAllSuccess := LToggleWorker.Success;
    LErrorMsgs := '';
    if not LToggleWorker.Success then
      LErrorMsgs := LErrorMsgs + LToggleWorker.ErrorMsg + '; ';

    for LIndex := 0 to High(LReaders) do
    begin
      if not LReaders[LIndex].Success then
      begin
        LAllSuccess := False;
        LErrorMsgs := LErrorMsgs + LReaders[LIndex].ErrorMsg + '; ';
      end;
    end;

    AssertTrue('Concurrent VectorAsm toggle/read failed: ' + LErrorMsgs, LAllSuccess);
  finally
    for LIndex := 0 to High(LReaders) do
      LReaders[LIndex].Free;
    LToggleWorker.Free;
    SetVectorAsmEnabled(LOldVectorAsm);
  end;
end;

procedure TTestCase_SimdConcurrent.Test_Concurrent_VectorAsmToggle_MultiWriter_DispatchRead;
const
  WRITER_THREADS = 4;
  WRITER_ITERATIONS = 2500;
  READER_THREADS = 4;
  READER_ITERATIONS = 5000;
var
  LWriters: array of TVectorAsmMultiToggleWorker;
  LReaders: array of TVectorAsmReadWorker;
  LIndex: Integer;
  LAllSuccess: Boolean;
  LErrorMsgs: string;
  LOldVectorAsm: Boolean;
begin
  LOldVectorAsm := IsVectorAsmEnabled;
  LWriters := nil;
  LReaders := nil;
  SetLength(LWriters, WRITER_THREADS);
  SetLength(LReaders, READER_THREADS);

  for LIndex := 0 to High(LWriters) do
    LWriters[LIndex] := TVectorAsmMultiToggleWorker.Create(WRITER_ITERATIONS, LIndex);
  for LIndex := 0 to High(LReaders) do
    LReaders[LIndex] := TVectorAsmReadWorker.Create(READER_ITERATIONS);

  try
    for LIndex := 0 to High(LWriters) do
      LWriters[LIndex].Start;
    for LIndex := 0 to High(LReaders) do
      LReaders[LIndex].Start;

    for LIndex := 0 to High(LWriters) do
      LWriters[LIndex].WaitFor;
    for LIndex := 0 to High(LReaders) do
      LReaders[LIndex].WaitFor;

    LAllSuccess := True;
    LErrorMsgs := '';
    for LIndex := 0 to High(LWriters) do
      if not LWriters[LIndex].Success then
      begin
        LAllSuccess := False;
        LErrorMsgs := LErrorMsgs + LWriters[LIndex].ErrorMsg + '; ';
      end;

    for LIndex := 0 to High(LReaders) do
      if not LReaders[LIndex].Success then
      begin
        LAllSuccess := False;
        LErrorMsgs := LErrorMsgs + LReaders[LIndex].ErrorMsg + '; ';
      end;

    AssertTrue('Concurrent VectorAsm multi-writer/read failed: ' + LErrorMsgs, LAllSuccess);
  finally
    for LIndex := 0 to High(LWriters) do
      LWriters[LIndex].Free;
    for LIndex := 0 to High(LReaders) do
      LReaders[LIndex].Free;
    SetVectorAsmEnabled(LOldVectorAsm);
  end;
end;

procedure TTestCase_SimdConcurrent.Test_Concurrent_PublicApiToggle_ReadConsistency;
const
  WRITER_THREADS = 4;
  WRITER_ITERATIONS = 4000;
  READER_THREADS = 6;
  READER_ITERATIONS = 30000;
var
  LWriters: array of TVectorAsmMultiToggleWorker;
  LReaders: array of TPublicApiReadWorker;
  LIndex: Integer;
  LAllSuccess: Boolean;
  LErrorMsgs: string;
  LOldVectorAsm: Boolean;
begin
  LOldVectorAsm := IsVectorAsmEnabled;
  LWriters := nil;
  LReaders := nil;
  SetLength(LWriters, WRITER_THREADS);
  SetLength(LReaders, READER_THREADS);

  for LIndex := 0 to High(LWriters) do
    LWriters[LIndex] := TVectorAsmMultiToggleWorker.Create(WRITER_ITERATIONS, LIndex);
  for LIndex := 0 to High(LReaders) do
    LReaders[LIndex] := TPublicApiReadWorker.Create(READER_ITERATIONS);

  try
    GetSimdPublicApi;
    for LIndex := 0 to High(LWriters) do
      LWriters[LIndex].Start;
    for LIndex := 0 to High(LReaders) do
      LReaders[LIndex].Start;

    for LIndex := 0 to High(LWriters) do
      LWriters[LIndex].WaitFor;
    for LIndex := 0 to High(LReaders) do
      LReaders[LIndex].WaitFor;

    LAllSuccess := True;
    LErrorMsgs := '';
    for LIndex := 0 to High(LWriters) do
      if not LWriters[LIndex].Success then
      begin
        LAllSuccess := False;
        LErrorMsgs := LErrorMsgs + LWriters[LIndex].ErrorMsg + '; ';
      end;

    for LIndex := 0 to High(LReaders) do
      if not LReaders[LIndex].Success then
      begin
        LAllSuccess := False;
        LErrorMsgs := LErrorMsgs + LReaders[LIndex].ErrorMsg + '; ';
      end;

    AssertTrue('Concurrent public API toggle/read failed: ' + LErrorMsgs, LAllSuccess);
  finally
    for LIndex := 0 to High(LWriters) do
      LWriters[LIndex].Free;
    for LIndex := 0 to High(LReaders) do
      LReaders[LIndex].Free;
    SetVectorAsmEnabled(LOldVectorAsm);
    ResetToAutomaticBackend;
  end;
end;

procedure TTestCase_SimdConcurrentPublicAbi.Test_Concurrent_PublicAbiPodInfo_RegisterBackend_ReadConsistency;
const
  WRITER_THREADS = 4;
  WRITER_ITERATIONS = 600;
  READER_THREADS = 6;
  READER_ITERATIONS = 12000;
var
  LWriters: array of TBackendRegisterToggleWorker;
  LReaders: array of TPublicAbiPodInfoReadWorker;
  LIndex: Integer;
  LAllSuccess: Boolean;
  LErrorMsgs: string;
  LOldVectorAsm: Boolean;
  LBackend: TSimdBackend;
  LOriginalTable: TSimdDispatchTable;
  LDisabledTable: TSimdDispatchTable;
  LSupportedOnCPU: Boolean;
  LExpectedCapsEnabled: UInt64;
  LExpectedCapsDisabled: UInt64;
  LExpectedFlagsEnabled: TFafafaSimdAbiFlags;
  LExpectedFlagsDisabled: TFafafaSimdAbiFlags;
begin
  LOldVectorAsm := IsVectorAsmEnabled;
  LWriters := nil;
  LReaders := nil;
  LBackend := sbScalar;
  LOriginalTable := Default(TSimdDispatchTable);
  LDisabledTable := Default(TSimdDispatchTable);

  try
    SetVectorAsmEnabled(True);
    ResetToAutomaticBackend;

    if not TryFindInactiveSupportedBackendForPodInfoMutation(LBackend, LOriginalTable) then
      Exit;

    LDisabledTable := LOriginalTable;
    LDisabledTable.BackendInfo.Available := False;
    LDisabledTable.BackendInfo.Capabilities := [];

    LSupportedOnCPU := IsBackendAvailableOnCPU(LBackend);
    LExpectedCapsEnabled := CapabilitiesToAbiBitsLocal(LOriginalTable.BackendInfo.Capabilities);
    LExpectedCapsDisabled := CapabilitiesToAbiBitsLocal(LDisabledTable.BackendInfo.Capabilities);
    LExpectedFlagsEnabled := BuildExpectedAbiFlagsLocal(
      LBackend, LSupportedOnCPU, True, LSupportedOnCPU and LOriginalTable.BackendInfo.Available, False);
    LExpectedFlagsDisabled := BuildExpectedAbiFlagsLocal(
      LBackend, LSupportedOnCPU, True, False, False);

    SetLength(LWriters, WRITER_THREADS);
    SetLength(LReaders, READER_THREADS);
    for LIndex := 0 to High(LWriters) do
      LWriters[LIndex] := TBackendRegisterToggleWorker.Create(
        WRITER_ITERATIONS, LBackend, LOriginalTable, LDisabledTable);
    for LIndex := 0 to High(LReaders) do
      LReaders[LIndex] := TPublicAbiPodInfoReadWorker.Create(
        READER_ITERATIONS, LBackend, LExpectedCapsEnabled, LExpectedCapsDisabled,
        LExpectedFlagsEnabled, LExpectedFlagsDisabled);

    for LIndex := 0 to High(LWriters) do
      LWriters[LIndex].Start;
    for LIndex := 0 to High(LReaders) do
      LReaders[LIndex].Start;

    for LIndex := 0 to High(LWriters) do
      LWriters[LIndex].WaitFor;
    for LIndex := 0 to High(LReaders) do
      LReaders[LIndex].WaitFor;

    LAllSuccess := True;
    LErrorMsgs := '';
    for LIndex := 0 to High(LWriters) do
      if not LWriters[LIndex].Success then
      begin
        LAllSuccess := False;
        LErrorMsgs := LErrorMsgs + LWriters[LIndex].ErrorMsg + '; ';
      end;
    for LIndex := 0 to High(LReaders) do
      if not LReaders[LIndex].Success then
      begin
        LAllSuccess := False;
        LErrorMsgs := LErrorMsgs + LReaders[LIndex].ErrorMsg + '; ';
      end;

    AssertTrue('Concurrent public ABI backend pod info/register read failed: ' + LErrorMsgs,
      LAllSuccess);
  finally
    for LIndex := 0 to High(LWriters) do
      LWriters[LIndex].Free;
    for LIndex := 0 to High(LReaders) do
      LReaders[LIndex].Free;
    if LBackend <> sbScalar then
      RegisterBackend(LBackend, LOriginalTable);
    SetVectorAsmEnabled(LOldVectorAsm);
    ResetToAutomaticBackend;
  end;
end;

procedure TTestCase_SimdConcurrentPublicAbi.Test_Concurrent_PublicApiActiveMetadata_RegisterBackend_ReadConsistency;
const
  WRITER_THREADS = 2;
  WRITER_ITERATIONS = 160;
  READER_THREADS = 3;
  READER_ITERATIONS = 4000;
var
  LWriters: array of TBackendRegisterToggleWorker;
  LReaders: array of TPublicApiActiveMetadataReadWorker;
  LIndex: Integer;
  LAllSuccess: Boolean;
  LErrorMsgs: string;
  LOldVectorAsm: Boolean;
  LBackend: TSimdBackend;
  LFallbackBackend: TSimdBackend;
  LOriginalTable: TSimdDispatchTable;
  LDisabledTable: TSimdDispatchTable;
  LFallbackInfo: TSimdBackendInfo;
  LExpectedFlagsEnabled: TFafafaSimdAbiFlags;
  LExpectedFlagsDisabled: TFafafaSimdAbiFlags;
begin
  LOldVectorAsm := IsVectorAsmEnabled;
  LWriters := nil;
  LReaders := nil;
  LBackend := sbScalar;
  LFallbackBackend := sbScalar;
  LOriginalTable := Default(TSimdDispatchTable);
  LDisabledTable := Default(TSimdDispatchTable);
  LFallbackInfo := Default(TSimdBackendInfo);

  try
    SetVectorAsmEnabled(True);
    ResetToAutomaticBackend;
    LBackend := GetCurrentBackend;
    if LBackend = sbScalar then
      Exit;
    if not TryGetRegisteredBackendDispatchTable(LBackend, LOriginalTable) then
      Exit;
    if (not LOriginalTable.BackendInfo.Available) or
       (LOriginalTable.BackendInfo.Capabilities = []) then
      Exit;

    LDisabledTable := LOriginalTable;
    LDisabledTable.BackendInfo.Available := False;
    LDisabledTable.BackendInfo.Capabilities := [];

    LExpectedFlagsEnabled := BuildExpectedAbiFlagsLocal(
      LBackend, IsBackendAvailableOnCPU(LBackend), True, True, True);

    RegisterBackend(LBackend, LDisabledTable);
    LFallbackBackend := GetCurrentBackend;
    LFallbackInfo := GetCurrentBackendInfo;
    AssertTrue('Disabled current backend should reselect away from the mutated backend',
      LFallbackBackend <> LBackend);
    LExpectedFlagsDisabled := BuildExpectedAbiFlagsLocal(
      LFallbackBackend, IsBackendAvailableOnCPU(LFallbackBackend), True,
      LFallbackInfo.Available and IsBackendAvailableOnCPU(LFallbackBackend), True);

    RegisterBackend(LBackend, LOriginalTable);
    AssertEquals('Restored backend should become current again',
      Ord(LBackend), Ord(GetCurrentBackend));

    SetLength(LWriters, WRITER_THREADS);
    SetLength(LReaders, READER_THREADS);
    for LIndex := 0 to High(LWriters) do
      LWriters[LIndex] := TBackendRegisterToggleWorker.Create(
        WRITER_ITERATIONS, LBackend, LOriginalTable, LDisabledTable);
    for LIndex := 0 to High(LReaders) do
      LReaders[LIndex] := TPublicApiActiveMetadataReadWorker.Create(
        READER_ITERATIONS, LBackend, LFallbackBackend,
        LExpectedFlagsEnabled, LExpectedFlagsDisabled);

    for LIndex := 0 to High(LWriters) do
      LWriters[LIndex].Start;
    for LIndex := 0 to High(LReaders) do
      LReaders[LIndex].Start;

    for LIndex := 0 to High(LWriters) do
      LWriters[LIndex].WaitFor;
    for LIndex := 0 to High(LReaders) do
      LReaders[LIndex].WaitFor;

    LAllSuccess := True;
    LErrorMsgs := '';
    for LIndex := 0 to High(LWriters) do
      if not LWriters[LIndex].Success then
      begin
        LAllSuccess := False;
        LErrorMsgs := LErrorMsgs + LWriters[LIndex].ErrorMsg + '; ';
      end;
    for LIndex := 0 to High(LReaders) do
      if not LReaders[LIndex].Success then
      begin
        LAllSuccess := False;
        LErrorMsgs := LErrorMsgs + LReaders[LIndex].ErrorMsg + '; ';
      end;

    AssertTrue('Concurrent public-api-active-metadata register/read failed: ' + LErrorMsgs, LAllSuccess);
  finally
    if LBackend <> sbScalar then
      RegisterBackend(LBackend, LOriginalTable);
    for LIndex := 0 to High(LWriters) do
      LWriters[LIndex].Free;
    for LIndex := 0 to High(LReaders) do
      LReaders[LIndex].Free;
    SetVectorAsmEnabled(LOldVectorAsm);
    ResetToAutomaticBackend;
  end;
end;

procedure TTestCase_SimdConcurrentFramework.Test_Concurrent_CurrentBackendInfo_RegisterBackend_ReadConsistency;
const
  WRITER_THREADS = 2;
  WRITER_ITERATIONS = 160;
  READER_THREADS = 3;
  READER_ITERATIONS = 4000;
var
  LWriters: array of TBackendRegisterToggleWorker;
  LReaders: array of TCurrentBackendInfoReadWorker;
  LIndex: Integer;
  LAllSuccess: Boolean;
  LErrorMsgs: string;
  LOldVectorAsm: Boolean;
  LBackend: TSimdBackend;
  LOriginalTable: TSimdDispatchTable;
  LDisabledTable: TSimdDispatchTable;
  LExpectedEnabledInfo: TSimdBackendInfo;
  LExpectedDisabledInfo: TSimdBackendInfo;
begin
  LOldVectorAsm := IsVectorAsmEnabled;
  LWriters := nil;
  LReaders := nil;
  LBackend := sbScalar;
  LOriginalTable := Default(TSimdDispatchTable);
  LDisabledTable := Default(TSimdDispatchTable);
  LExpectedEnabledInfo := Default(TSimdBackendInfo);
  LExpectedDisabledInfo := Default(TSimdBackendInfo);

  try
    SetVectorAsmEnabled(True);
    ResetToAutomaticBackend;
    LBackend := GetCurrentBackend;
    if LBackend = sbScalar then
      Exit;
    if not TryGetRegisteredBackendDispatchTable(LBackend, LOriginalTable) then
      Exit;
    if (not LOriginalTable.BackendInfo.Available) or
       (LOriginalTable.BackendInfo.Capabilities = []) then
      Exit;

    LExpectedEnabledInfo := LOriginalTable.BackendInfo;
    LDisabledTable := LOriginalTable;
    LDisabledTable.BackendInfo.Available := False;
    LDisabledTable.BackendInfo.Capabilities := [];

    RegisterBackend(LBackend, LDisabledTable);
    LExpectedDisabledInfo := GetCurrentBackendInfo;
    AssertTrue('Disabled current backend should reselect away from the mutated backend',
      LExpectedDisabledInfo.Backend <> LBackend);

    RegisterBackend(LBackend, LOriginalTable);
    AssertEquals('Restored backend should become current again',
      Ord(LBackend), Ord(GetCurrentBackend));

    SetLength(LWriters, WRITER_THREADS);
    SetLength(LReaders, READER_THREADS);
    for LIndex := 0 to High(LWriters) do
      LWriters[LIndex] := TBackendRegisterToggleWorker.Create(
        WRITER_ITERATIONS, LBackend, LOriginalTable, LDisabledTable);
    for LIndex := 0 to High(LReaders) do
      LReaders[LIndex] := TCurrentBackendInfoReadWorker.Create(
        READER_ITERATIONS, LExpectedEnabledInfo, LExpectedDisabledInfo);

    for LIndex := 0 to High(LWriters) do
      LWriters[LIndex].Start;
    for LIndex := 0 to High(LReaders) do
      LReaders[LIndex].Start;

    for LIndex := 0 to High(LWriters) do
      LWriters[LIndex].WaitFor;
    for LIndex := 0 to High(LReaders) do
      LReaders[LIndex].WaitFor;

    LAllSuccess := True;
    LErrorMsgs := '';
    for LIndex := 0 to High(LWriters) do
      if not LWriters[LIndex].Success then
      begin
        LAllSuccess := False;
        LErrorMsgs := LErrorMsgs + LWriters[LIndex].ErrorMsg + '; ';
      end;
    for LIndex := 0 to High(LReaders) do
      if not LReaders[LIndex].Success then
      begin
        LAllSuccess := False;
        LErrorMsgs := LErrorMsgs + LReaders[LIndex].ErrorMsg + '; ';
      end;

    AssertTrue('Concurrent current-backend-info register/read failed: ' + LErrorMsgs, LAllSuccess);
  finally
    if LBackend <> sbScalar then
      RegisterBackend(LBackend, LOriginalTable);
    for LIndex := 0 to High(LWriters) do
      LWriters[LIndex].Free;
    for LIndex := 0 to High(LReaders) do
      LReaders[LIndex].Free;
    SetVectorAsmEnabled(LOldVectorAsm);
    ResetToAutomaticBackend;
  end;
end;

procedure TTestCase_SimdConcurrentFramework.Test_Concurrent_DispatchableHelpers_VectorAsmToggle_ReadConsistency;
const
  WRITER_THREADS = 4;
  WRITER_ITERATIONS = 4000;
  READER_THREADS = 6;
  READER_ITERATIONS = 30000;
var
  LWriters: array of TVectorAsmMultiToggleWorker;
  LReaders: array of TDispatchableHelpersReadWorker;
  LExpectedEnabledList: TSimdBackendArray;
  LExpectedDisabledList: TSimdBackendArray;
  LExpectedEnabledBest: TSimdBackend;
  LExpectedDisabledBest: TSimdBackend;
  LIndex: Integer;
  LAllSuccess: Boolean;
  LErrorMsgs: string;
  LOldVectorAsm: Boolean;
begin
  LOldVectorAsm := IsVectorAsmEnabled;
  LWriters := nil;
  LReaders := nil;
  LExpectedEnabledList := nil;
  LExpectedDisabledList := nil;

  try
    SetVectorAsmEnabled(True);
    ResetToAutomaticBackend;
    LExpectedEnabledList := fafafa.core.simd.GetDispatchableBackendList;
    LExpectedEnabledBest := fafafa.core.simd.GetBestDispatchableBackend;

    SetVectorAsmEnabled(False);
    ResetToAutomaticBackend;
    LExpectedDisabledList := fafafa.core.simd.GetDispatchableBackendList;
    LExpectedDisabledBest := fafafa.core.simd.GetBestDispatchableBackend;

    if SameBackendArrayLocal(LExpectedEnabledList, LExpectedDisabledList) and
       (LExpectedEnabledBest = LExpectedDisabledBest) then
      Exit;

    SetLength(LWriters, WRITER_THREADS);
    SetLength(LReaders, READER_THREADS);
    for LIndex := 0 to High(LWriters) do
      LWriters[LIndex] := TVectorAsmMultiToggleWorker.Create(WRITER_ITERATIONS, LIndex);
    for LIndex := 0 to High(LReaders) do
      LReaders[LIndex] := TDispatchableHelpersReadWorker.Create(
        READER_ITERATIONS, LExpectedEnabledList, LExpectedDisabledList,
        LExpectedEnabledBest, LExpectedDisabledBest);

    for LIndex := 0 to High(LWriters) do
      LWriters[LIndex].Start;
    for LIndex := 0 to High(LReaders) do
      LReaders[LIndex].Start;

    for LIndex := 0 to High(LWriters) do
      LWriters[LIndex].WaitFor;
    for LIndex := 0 to High(LReaders) do
      LReaders[LIndex].WaitFor;

    LAllSuccess := True;
    LErrorMsgs := '';
    for LIndex := 0 to High(LWriters) do
      if not LWriters[LIndex].Success then
      begin
        LAllSuccess := False;
        LErrorMsgs := LErrorMsgs + LWriters[LIndex].ErrorMsg + '; ';
      end;
    for LIndex := 0 to High(LReaders) do
      if not LReaders[LIndex].Success then
      begin
        LAllSuccess := False;
        LErrorMsgs := LErrorMsgs + LReaders[LIndex].ErrorMsg + '; ';
      end;

    AssertTrue('Concurrent dispatchable helper toggle/read failed: ' + LErrorMsgs, LAllSuccess);
  finally
    for LIndex := 0 to High(LWriters) do
      LWriters[LIndex].Free;
    for LIndex := 0 to High(LReaders) do
      LReaders[LIndex].Free;
    SetVectorAsmEnabled(LOldVectorAsm);
    ResetToAutomaticBackend;
  end;
end;

procedure TTestCase_SimdConcurrent.Test_Concurrent_DispatchMixed_ControlPlane;
const
  ROUNDS = 4;
  WORKER_THREADS = 8;
  READER_THREADS = 4;
  WORKER_ITERATIONS = 3000;
  READER_ITERATIONS = 4500;
var
  LRound, LIndex: Integer;
  LWorkers: array of TDispatchMixedControlWorker;
  LReaders: array of TVectorAsmReadWorker;
  LAllSuccess: Boolean;
  LErrorMsgs: string;
  LOldVectorAsm: Boolean;
  LDispatch: PSimdDispatchTable;
  LA, LB, LC, LProbe: TVecF32x4;
  LValue: Single;
begin
  LOldVectorAsm := IsVectorAsmEnabled;
  LWorkers := nil;
  LReaders := nil;

  try
    for LRound := 1 to ROUNDS do
    begin
      SetLength(LWorkers, WORKER_THREADS);
      SetLength(LReaders, READER_THREADS);
      for LIndex := 0 to High(LWorkers) do
        LWorkers[LIndex] := TDispatchMixedControlWorker.Create(WORKER_ITERATIONS, LRound + LIndex);
      for LIndex := 0 to High(LReaders) do
        LReaders[LIndex] := TVectorAsmReadWorker.Create(READER_ITERATIONS);

      for LIndex := 0 to High(LWorkers) do
        LWorkers[LIndex].Start;
      for LIndex := 0 to High(LReaders) do
        LReaders[LIndex].Start;
      for LIndex := 0 to High(LWorkers) do
        LWorkers[LIndex].WaitFor;
      for LIndex := 0 to High(LReaders) do
        LReaders[LIndex].WaitFor;

      LAllSuccess := True;
      LErrorMsgs := '';
      for LIndex := 0 to High(LWorkers) do
      begin
        if not LWorkers[LIndex].Success then
        begin
          LAllSuccess := False;
          LErrorMsgs := LErrorMsgs + LWorkers[LIndex].ErrorMsg + '; ';
        end;
        LWorkers[LIndex].Free;
        LWorkers[LIndex] := nil;
      end;
      for LIndex := 0 to High(LReaders) do
      begin
        if not LReaders[LIndex].Success then
        begin
          LAllSuccess := False;
          LErrorMsgs := LErrorMsgs + LReaders[LIndex].ErrorMsg + '; ';
        end;
        LReaders[LIndex].Free;
        LReaders[LIndex] := nil;
      end;

      AssertTrue('Dispatch mixed control round ' + IntToStr(LRound) + ' failed: ' + LErrorMsgs, LAllSuccess);

      ResetToAutomaticBackend;
      LDispatch := GetDispatchTable;
      AssertTrue('Post-round dispatch should be available',
        (LDispatch <> nil) and Assigned(LDispatch^.AddF32x4) and
        Assigned(LDispatch^.RoundF32x4) and Assigned(LDispatch^.TruncF32x4));

      LA := MakeSplatF32x4(1.0);
      LB := MakeSplatF32x4(2.0);
      LC := LDispatch^.AddF32x4(LA, LB);
      LValue := VecF32x4Extract(LC, 0);
      AssertTrue('Post-round AddF32x4 sanity mismatch on round ' + IntToStr(LRound),
        Abs(LValue - 3.0) <= FLOAT_EPSILON);

      LProbe := MakeSplatF32x4(-1.75);
      LC := LDispatch^.RoundF32x4(LProbe);
      LValue := VecF32x4Extract(LC, 0);
      AssertTrue('Post-round RoundF32x4 sanity mismatch on round ' + IntToStr(LRound),
        Abs(LValue - (-2.0)) <= FLOAT_EPSILON);
      LC := LDispatch^.TruncF32x4(LProbe);
      LValue := VecF32x4Extract(LC, 0);
      AssertTrue('Post-round TruncF32x4 sanity mismatch on round ' + IntToStr(LRound),
        Abs(LValue - (-1.0)) <= FLOAT_EPSILON);

      SetLength(LWorkers, 0);
      SetLength(LReaders, 0);
    end;
  finally
    for LIndex := 0 to High(LWorkers) do
      if Assigned(LWorkers[LIndex]) then
        LWorkers[LIndex].Free;
    for LIndex := 0 to High(LReaders) do
      if Assigned(LReaders[LIndex]) then
        LReaders[LIndex].Free;
    SetVectorAsmEnabled(LOldVectorAsm);
    ResetToAutomaticBackend;
  end;
end;

procedure TTestCase_SimdConcurrent.Test_Concurrent_Mixed_MathOps;
var
  workers: array of TMixedMathWorker;
  i: Integer;
  allSuccess: Boolean;
  errorMsgs: string;
begin
  workers := nil;
  SetLength(workers, DEFAULT_THREAD_COUNT);

  for i := 0 to High(workers) do
    workers[i] := TMixedMathWorker.Create(i, DEFAULT_ITERATIONS);

  for i := 0 to High(workers) do
    workers[i].Start;

  for i := 0 to High(workers) do
    workers[i].WaitFor;

  allSuccess := True;
  errorMsgs := '';
  for i := 0 to High(workers) do
  begin
    if not workers[i].Success then
    begin
      allSuccess := False;
      errorMsgs := errorMsgs + workers[i].ErrorMsg + '; ';
    end;
    workers[i].Free;
  end;

  AssertTrue('Concurrent Mixed MathOps failed: ' + errorMsgs, allSuccess);
end;

procedure TTestCase_SimdConcurrent.Test_Concurrent_Reduction_Operations;
var
  workers: array of TReductionWorker;
  i: Integer;
  allSuccess: Boolean;
  errorMsgs: string;
begin
  workers := nil;
  SetLength(workers, DEFAULT_THREAD_COUNT);

  for i := 0 to High(workers) do
    workers[i] := TReductionWorker.Create(i, DEFAULT_ITERATIONS);

  for i := 0 to High(workers) do
    workers[i].Start;

  for i := 0 to High(workers) do
    workers[i].WaitFor;

  allSuccess := True;
  errorMsgs := '';
  for i := 0 to High(workers) do
  begin
    if not workers[i].Success then
    begin
      allSuccess := False;
      errorMsgs := errorMsgs + workers[i].ErrorMsg + '; ';
    end;
    workers[i].Free;
  end;

  AssertTrue('Concurrent Reduction Operations failed: ' + errorMsgs, allSuccess);
end;

procedure TTestCase_SimdConcurrent.Test_Stress_Concurrent_SIMD;
var
  workers: array of TStressWorker;
  i: Integer;
  allSuccess: Boolean;
  errorMsgs: string;
  totalOps: Int64;
begin
  workers := nil;
  SetLength(workers, STRESS_THREAD_COUNT);

  for i := 0 to High(workers) do
    workers[i] := TStressWorker.Create(i, STRESS_ITERATIONS);

  for i := 0 to High(workers) do
    workers[i].Start;

  for i := 0 to High(workers) do
    workers[i].WaitFor;

  allSuccess := True;
  errorMsgs := '';
  totalOps := 0;
  for i := 0 to High(workers) do
  begin
    if not workers[i].Success then
    begin
      allSuccess := False;
      errorMsgs := errorMsgs + workers[i].ErrorMsg + '; ';
    end;
    totalOps := totalOps + workers[i].OperationsCompleted;
    workers[i].Free;
  end;

  WriteLn(Format('  Stress test completed: %d threads, %d total SIMD operations',
                [STRESS_THREAD_COUNT, totalOps]));

  AssertTrue('Stress Concurrent SIMD failed: ' + errorMsgs, allSuccess);
end;

procedure TTestCase_SimdConcurrent.Test_Stress_LongRunning;
var
  workers: array of TStressWorker;
  i: Integer;
  allSuccess: Boolean;
  errorMsgs: string;
  startTime: QWord;
  iterations: Integer;
begin
  startTime := GetTickCount64;
  iterations := 0;

  // 运行直到达到时间限制
  while (GetTickCount64 - startTime) < QWord(LONG_RUNNING_SECONDS * 1000) do
  begin
    workers := nil;
    SetLength(workers, 4);  // 使用较少线程以便快速迭代

    for i := 0 to High(workers) do
      workers[i] := TStressWorker.Create(i, 1000);

    for i := 0 to High(workers) do
      workers[i].Start;

    for i := 0 to High(workers) do
      workers[i].WaitFor;

    allSuccess := True;
    errorMsgs := '';
    for i := 0 to High(workers) do
    begin
      if not workers[i].Success then
      begin
        allSuccess := False;
        errorMsgs := errorMsgs + workers[i].ErrorMsg + '; ';
      end;
      workers[i].Free;
    end;

    if not allSuccess then
      Break;

    Inc(iterations);
  end;

  WriteLn(Format('  Long-running test: %d iterations in %d seconds',
                [iterations, LONG_RUNNING_SECONDS]));

  AssertTrue('Long-running stress test failed: ' + errorMsgs, allSuccess);
end;

procedure TTestCase_SimdConcurrent.Test_Stress_RapidThreadCreation;
var
  i: Integer;
  worker: TF32x4AddWorker;
  allSuccess: Boolean;
  errorMsg: string;
const
  RAPID_ITERATIONS = 100;
  OPS_PER_THREAD = 100;
begin
  allSuccess := True;
  errorMsg := '';

  for i := 0 to RAPID_ITERATIONS - 1 do
  begin
    worker := TF32x4AddWorker.Create(i, OPS_PER_THREAD);
    try
      worker.Start;
      worker.WaitFor;

      if not worker.Success then
      begin
        allSuccess := False;
        errorMsg := Format('Iteration %d: %s', [i, worker.ErrorMsg]);
        Break;
      end;
    finally
      worker.Free;
    end;
  end;

  WriteLn(Format('  Rapid thread creation: %d threads created/destroyed', [RAPID_ITERATIONS]));

  AssertTrue('Rapid thread creation failed: ' + errorMsg, allSuccess);
end;

procedure TTestCase_SimdConcurrent.Test_Stress_LargeData_Concurrent;
var
  threads: array of TLargeDataThread;
  i: Integer;
  allSuccess: Boolean;
  errorMsgs: string;
begin
  threads := nil;
  SetLength(threads, DEFAULT_THREAD_COUNT);

  for i := 0 to High(threads) do
    threads[i] := TLargeDataThread.Create(i);

  for i := 0 to High(threads) do
    threads[i].Start;

  for i := 0 to High(threads) do
    threads[i].WaitFor;

  allSuccess := True;
  errorMsgs := '';
  for i := 0 to High(threads) do
  begin
    if not threads[i].Success then
    begin
      allSuccess := False;
      errorMsgs := errorMsgs + threads[i].ErrorMsg + '; ';
    end;
    threads[i].Free;
  end;

  AssertTrue('Large data concurrent processing failed: ' + errorMsgs, allSuccess);
end;

initialization
  RegisterTest(TTestCase_SimdConcurrent);
  RegisterTest(TTestCase_SimdConcurrentPublicAbi);
  RegisterTest(TTestCase_SimdConcurrentFramework);

end.
