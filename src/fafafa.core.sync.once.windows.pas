unit fafafa.core.sync.once.windows;

{
  Windows 骞冲彴涓€娆℃€ф墽琛屽疄�?

  鐗规€э細
  - 鍩轰�?InterlockedCompareExchange + CRITICAL_SECTION 瀹炵�?
  - 楂樻€ц兘鍘熷瓙蹇€熻矾�?+ 鎱㈤€熻矾寰勮�?
  - 鏀寔寮傚父鎭㈠鍜屾瘨鍖栫姸鎬佺鐞?
  - 鍒嗘敮棰勬祴浼樺寲鍜岀紦瀛樿瀵归�?
  - 鑷€傚簲绛夊緟绛栫暐锛堣嚜�?+ 鎸囨暟閫€閬匡級

  瀹炵幇绛栫暐�?
  - 蹇€熻矾寰勶細鏃犻攣鍘熷瓙鎿嶄綔妫€鏌ュ畬鎴愮姸鎬?
  - 鎱㈤€熻矾寰勶細浣跨敤杞婚噺绾ч攣杩涜鍚屾鎵ц
  - 寮傚父澶勭悊锛氬け璐ユ椂鏍囪涓烘瘨鍖栫姸鎬?
  - 閫掑綊妫€娴嬶細闃叉鍚屼竴绾跨▼閫掑綊璋冪�?
  - 鎬ц兘浼樺寲锛氬垎鏀娴嬨€佺紦瀛樿瀵归綈銆佽嚜鏃嬬瓑寰?
}

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  {$IFDEF WINDOWS}
  Windows,
  {$ELSE}
  // 浜ゅ弶缂栬瘧鏃朵娇鐢?FreePascal 鐨勮法骞冲彴鍚屾鍘熻
  SyncObjs,
  {$ENDIF}
  SysUtils,
  fafafa.core.base, fafafa.core.sync.base, fafafa.core.sync.once.base, fafafa.core.atomic;

// 鍒嗘敮棰勬祴浼樺寲瀹忓畾涔?
{$IFDEF CPUX86_64}
// x86-64 鏀寔鍒嗘敮棰勬祴鎻愮�?
{$DEFINE BRANCH_PREDICTION_SUPPORTED}
{$ENDIF}

{$IFDEF BRANCH_PREDICTION_SUPPORTED}
// 浣跨敤缂栬瘧鍣ㄥ唴寤哄嚱鏁拌繘琛屽垎鏀娴嬩紭鍖?
function Likely(condition: Boolean): Boolean; inline;
function Unlikely(condition: Boolean): Boolean; inline;
{$ELSE}
// 涓嶆敮鎸佸垎鏀娴嬬殑骞冲彴锛屼娇鐢ㄦ櫘閫氭潯浠跺垽�?
function Likely(condition: Boolean): Boolean; inline;
function Unlikely(condition: Boolean): Boolean; inline;
{$ENDIF}

// 璺ㄥ钩鍙伴攣鎿嶄�?- 浣跨敤鍐呰仈杩囩▼鏇夸唬�?
{$IFDEF WINDOWS}
// Windows 骞冲彴浣跨敤杞婚噺绾ч�?
{$ELSE}
// �?Windows 骞冲彴浣跨敤鏍囧噯涓寸晫�?
{$ENDIF}

type
  // 杞婚噺绾ц嚜鏃嬮攣瀹炵幇锛堟浛浠ｉ噸閲忕骇 CRITICAL_SECTION�?
  TLightweightLock = record
private
  FCs: TRTLCriticalSection;
public
  procedure Initialize;
  procedure Lock;
  procedure Unlock;
  function TryLock: Boolean;
end;

  TOnce = class(TSynchronizable, IOnce)
  private
    // 淇缂撳瓨琛屽榻愶細姝ｇ‘璁＄畻瀛楁澶у皬鍜屽～�?
    // 绗竴涓紦瀛樿锛氱儹璺緞鏁版嵁锛堥珮棰戣闂�?
    FDone: LongInt;               // 4瀛楄妭锛氬師瀛愭爣蹇楋紝0=鏈畬鎴?1=瀹屾�?缁堟�?
    FState: LongInt;              // 4瀛楄妭锛氳缁嗙姸鎬?
    FExecutingThreadId: DWORD;    // 4瀛楄妭锛氬綋鍓嶆墽琛岀嚎绋婭D

    // 绮剧‘璁＄畻濉厖锛氱‘淇濅笅涓€涓瓧娈靛湪鏂扮紦瀛樿寮€濮?
    // 瀵硅薄澶?8瀛楄�? + FDone(1瀛楄�? + 瀵归綈濉厖(3瀛楄�? + FState(4瀛楄�? + FExecutingThreadId(4瀛楄�? = 20瀛楄�?
    // 闇€瑕佸～鍏?64 - 20 = 44瀛楄�?鍒扮紦瀛樿杈圭晫
    FPadding1: array[0..43] of Byte;

    // 绗簩涓紦瀛樿锛氬悓姝ユ暟鎹紙64瀛楄妭瀵归綈锛?
    {$IFDEF WINDOWS}
    FLock: TLightweightLock;      // 杞婚噺绾ц嚜鏃嬮攣
    {$ELSE}
    FLock: TCriticalSection;      // 浜ゅ弶缂栬瘧鏃朵娇鐢ㄦ爣鍑嗕复鐣屽尯
    {$ENDIF}

    // 纭繚閿佹暟鎹笉璺ㄨ秺缂撳瓨琛岃竟�?
    // TLightweightLock 澶у皬闇€瑕佹鏌ワ紝鍙兘闇€瑕侀澶栧～�?
    FPadding2: array[0..31] of Byte; // 棰勭暀32瀛楄妭濉厖

    // 绗笁涓紦瀛樿锛氬洖璋冨瓨鍌紙64瀛楄妭瀵归綈锛?
    FCallback: TOnceCallback;     // 瀛樺偍鐨勫洖璋冨嚱鏁?

    const
      STATE_NOT_STARTED = 0;
      STATE_IN_PROGRESS = 1;
      STATE_COMPLETED = 2;
      STATE_POISONED = 3;

    // 璺ㄥ钩鍙伴攣鎿嶄綔鍐呰仈鏂规�?
    procedure LockAcquire; inline;
    procedure LockRelease; inline;

    // 鍐呴儴鎵ц鏂规硶
    // ✅ P0-2 Fix: 使用统一的核心方法消除代码重复
    // ✅ P0-3 Fix: 递归调用检测移至锁内部，避免竞态条件
    procedure DoInternalCore(const ACallback: TOnceCallback; AForce: Boolean);
    procedure DoInternal(const AProc: TOnceProc; AForce: Boolean); overload;
    procedure DoInternal(const AMethod: TOnceMethod; AForce: Boolean); overload;
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    procedure DoInternal(const AAnonymousProc: TOnceAnonymousProc; AForce: Boolean); overload;
    {$ENDIF}

  public
    constructor Create; overload;
    constructor Create(const AProc: TOnceProc); overload;
    constructor Create(const AMethod: TOnceMethod); overload;
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    constructor Create(const AAnonymousProc: TOnceAnonymousProc); overload;
    {$ENDIF}
    destructor Destroy; override;

    // ISynchronizable 鎺ュ彛瀹炵�?
    function GetLastError: TWaitError;

    // 绉婚櫎ILock鎺ュ彛鏂规硶锛欼Once涓嶅啀缁ф壙ILock锛岄伩鍏嶈涔夋贩涔?
    // 杩欎簺鏂规硶宸茶绉婚櫎锛屽洜涓篛nce涓嶆槸浼犵粺鎰忎箟鐨勯攣

    // IOnce 鏍稿績鎺ュ彛瀹炵幇锛圙o/Rust 椋庢牸锛?
    procedure Execute; overload;
    procedure Execute(const AProc: TOnceProc); overload;
    procedure Execute(const AMethod: TOnceMethod); overload;
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    procedure Execute(const AAnonymousProc: TOnceAnonymousProc); overload;
    {$ENDIF}

    // 寮哄埗鎵ц锛堝拷鐣ユ瘨鍖栫姸鎬侊�?
    procedure ExecuteForce; overload;
    procedure ExecuteForce(const AProc: TOnceProc); overload;
    procedure ExecuteForce(const AMethod: TOnceMethod); overload;
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    procedure ExecuteForce(const AAnonymousProc: TOnceAnonymousProc); overload;
    {$ENDIF}



    // 绛夊緟鏈哄埗
    procedure Wait;
    procedure WaitForce;

    // 鐘舵€佹煡璇紙灞炴€ч鏍硷紝绗﹀�?Pascal 绾﹀畾锛?
    function GetState: TOnceState;
    function GetCompleted: Boolean;
    function GetPoisoned: Boolean;

    // Reset 鍔熻兘宸茬Щ闄?- 璇峰垱寤烘柊�?Once 瀹炰�?
  end;

implementation

// 璺ㄥ钩鍙伴攣鎿嶄綔鏂规硶瀹炵�?
procedure TOnce.LockAcquire;
begin
  {$IFDEF WINDOWS}
  FLock.Lock;
  {$ELSE}
  FLock.Acquire;
  {$ENDIF}
end;

procedure TOnce.LockRelease;
begin
  {$IFDEF WINDOWS}
  FLock.Unlock;
  {$ELSE}
  FLock.Release;
  {$ENDIF}
end;

// 鍒嗘敮棰勬祴浼樺寲鍑芥暟瀹炵�?
{$IFDEF BRANCH_PREDICTION_SUPPORTED}
function Likely(condition: Boolean): Boolean; inline;
begin
  Result := condition;
  // 鍦ㄦ敮鎸佺殑缂栬瘧鍣ㄤ腑锛岃繖閲屽彲浠ユ坊鍔?__builtin_expect 绛変环鐗?
  // FreePascal 鐩墠娌℃湁鐩存帴鐨勫垎鏀娴嬫敮鎸侊紝浣嗗嚱鏁板悕鎻愪緵浜嗚涔夋彁绀?
end;

function Unlikely(condition: Boolean): Boolean; inline;
begin
  Result := condition;
  // 鍦ㄦ敮鎸佺殑缂栬瘧鍣ㄤ腑锛岃繖閲屽彲浠ユ坊鍔?__builtin_expect 绛変环鐗?
end;
{$ELSE}
function Likely(condition: Boolean): Boolean; inline;
begin
  Result := condition;
end;

function Unlikely(condition: Boolean): Boolean; inline;
begin
  Result := condition;
end;
{$ENDIF}

// 閿欒娑堟伅璧勬簮瀛楃涓?
// 错误消息常量（避免资源表生成带来的潜在问�?
const
  rsOnceAlreadyPoisoned = 'Once is poisoned due to previous panic';
  rsOnceRecursiveCall = 'Recursive call to Once.Execute() detected from the same thread';


procedure TLightweightLock.Initialize;
begin
  InitializeCriticalSection(FCs);
end;

procedure TLightweightLock.Lock;
begin
  EnterCriticalSection(FCs);
end;

procedure TLightweightLock.Unlock;
begin
  LeaveCriticalSection(FCs);
end;

function TLightweightLock.TryLock: Boolean;
begin
  Result := TryEnterCriticalSection(FCs);
end;

{ TOnce }

constructor TOnce.Create;
begin
  inherited Create;
  FDone := 0;                   // 鍘熷瓙鏍囧織鍒濆鍖?  FState := STATE_NOT_STARTED;  // 璇︾粏鐘舵€佸垵濮嬪�?
  FExecutingThreadId := 0;      // 鍒濆鍖栨墽琛岀嚎绋婭D
  {$IFDEF WINDOWS}
  FLock.Initialize;             // 鍒濆鍖栬交閲忕骇閿?
  {$ELSE}
  FLock := TCriticalSection.Create;  // 浜ゅ弶缂栬瘧鏃朵娇鐢ㄦ爣鍑嗕复鐣屽尯
  {$ENDIF}

  // 鍒濆鍖栧洖璋冧负绌?
  FCallback.CallbackType := octNone;
  FCallback.Proc := nil;
  FCallback.Method := nil;
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  FCallback.AnonymousProc := nil;
  {$ENDIF}

  // 璋冭瘯閽╁瓙
  {$IFDEF FAFAFA_CORE_DEBUG_ONCE}
  if Assigned(OnceDebugHook) then
    OnceDebugHook(odeCreated, Self, 'Once instance created');
  {$ENDIF}
end;

constructor TOnce.Create(const AProc: TOnceProc);
begin
  Create; // 璋冪敤鍩虹鏋勯€犲嚱鏁?
  FCallback.CallbackType := octProc;
  FCallback.Proc := AProc;
end;

constructor TOnce.Create(const AMethod: TOnceMethod);
begin
  Create; // 璋冪敤鍩虹鏋勯€犲嚱鏁?
  FCallback.CallbackType := octMethod;
  FCallback.Method := AMethod;
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
constructor TOnce.Create(const AAnonymousProc: TOnceAnonymousProc);
begin
  Create; // 璋冪敤鍩虹鏋勯€犲嚱鏁?
  FCallback.CallbackType := octAnonymous;
  FCallback.AnonymousProc := AAnonymousProc;
end;
{$ENDIF}



destructor TOnce.Destroy;
begin
  {$IFDEF WINDOWS}
  // 杞婚噺绾ч攣鏃犻渶鏄惧紡閿€姣?
  {$ELSE}
  FLock.Free;  // 閲婃斁涓寸晫�?
  {$ENDIF}
  inherited Destroy;
end;

// ISynchronizable 鎺ュ彛瀹炵�?
function TOnce.GetLastError: TWaitError;
begin
  // Once 涓嶄娇鐢ㄤ紶缁熺殑绛夊緟閿欒锛屾€绘槸杩斿洖鏃犻敊�?
  Result := weNone;
end;

// ILock 鎺ュ彛鏂规硶宸茬Щ闄わ細IOnce涓嶅啀缁ф壙ILock
// 杩欓伩鍏嶄簡璇箟娣蜂贡锛孫nce涓嶆槸浼犵粺鎰忎箟鐨勯攣

// IOnce Execute 鏂规硶瀹炵�?
procedure TOnce.Execute;
var
  NilProc: TOnceProc;
begin
  case FCallback.CallbackType of
    octNone:
    begin
      NilProc := nil;
      DoInternal(NilProc, False); // 鏃犲洖璋冿紝浣嗕粛闇€鏍囪涓哄畬鎴?
    end;
    octProc: DoInternal(FCallback.Proc, False);
    octMethod: DoInternal(FCallback.Method, False);
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    octAnonymous: DoInternal(FCallback.AnonymousProc, False);
    {$ENDIF}
  end;
end;

procedure TOnce.Execute(const AProc: TOnceProc);
begin
  DoInternal(AProc, False);
end;

procedure TOnce.Execute(const AMethod: TOnceMethod);
begin
  DoInternal(AMethod, False);
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
procedure TOnce.Execute(const AAnonymousProc: TOnceAnonymousProc);
begin
  DoInternal(AAnonymousProc, False);
end;
{$ENDIF}

// ExecuteForce 鏂规硶瀹炵�?
procedure TOnce.ExecuteForce;
var
  NilProc: TOnceProc;
begin
  case FCallback.CallbackType of
    octNone:
    begin
      NilProc := nil;
      DoInternal(NilProc, True); // 鏃犲洖璋冿紝浣嗕粛闇€鏍囪涓哄畬鎴?
    end;
    octProc: DoInternal(FCallback.Proc, True);
    octMethod: DoInternal(FCallback.Method, True);
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    octAnonymous: DoInternal(FCallback.AnonymousProc, True);
    {$ENDIF}
  end;
end;

procedure TOnce.ExecuteForce(const AProc: TOnceProc);
begin
  DoInternal(AProc, True);
end;

procedure TOnce.ExecuteForce(const AMethod: TOnceMethod);
begin
  DoInternal(AMethod, True);
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
procedure TOnce.ExecuteForce(const AAnonymousProc: TOnceAnonymousProc);
begin
  DoInternal(AAnonymousProc, True);
end;
{$ENDIF}


// ✅ P0-2 Fix: 统一的核心执行方法，消除代码重复
// ✅ P0-3 Fix: 递归调用检测移至锁内部，避免竞态条件
procedure TOnce.DoInternalCore(const ACallback: TOnceCallback; AForce: Boolean);
var
  CurrentState: LongInt;
  ExecutionSucceeded: Boolean;
  ShouldExecute: Boolean;
begin
  {$IFDEF FAFAFA_CORE_DEBUG_ONCE}
  WriteLn('[DEBUG] Execute started, Force=', AForce);
  {$ENDIF}

  // 快速路径：原子读取，无锁检查（acquire 语义）
  if Likely(atomic_load(FDone, mo_acquire) <> 0) then
  begin
    if Likely(not AForce) then
    begin
      CurrentState := atomic_load(FState, mo_relaxed);
      if Unlikely(CurrentState = STATE_POISONED) then
        raise ELockError.Create(rsOnceAlreadyPoisoned);
      Exit;
    end;
  end;

  // 慢速路径：三阶段锁控制
  ShouldExecute := False;

  // 第一阶段：获取锁，检查状态，设置执行标志
  LockAcquire;
  try
    // ✅ P0-3 Fix: 递归调用检测移至锁内部
    if FExecutingThreadId = GetCurrentThreadId then
    begin
      {$IFDEF FAFAFA_CORE_DEBUG_ONCE}
      WriteLn('[DEBUG] Recursive call detected from thread ', GetCurrentThreadId);
      {$ENDIF}
      raise EOnceRecursiveCall.Create(rsOnceRecursiveCall);
    end;

    // 双重检查锁定模式
    if (FDone <> 0) and (not AForce) then
    begin
      if FState = STATE_POISONED then
        raise ELockError.Create(rsOnceAlreadyPoisoned);
      Exit;
    end;

    // 检查当前状态，确保并发安全
    case FState of
      STATE_NOT_STARTED:
      begin
        atomic_store(FState, STATE_IN_PROGRESS, mo_release);
        FExecutingThreadId := GetCurrentThreadId;
        ShouldExecute := True;
      end;
      STATE_IN_PROGRESS:
      begin
        if not AForce then
          Exit
        else
        begin
          atomic_store(FState, STATE_IN_PROGRESS, mo_release);
          FExecutingThreadId := GetCurrentThreadId;
          ShouldExecute := True;
        end;
      end;
      STATE_COMPLETED:
      begin
        if AForce then
        begin
          atomic_store(FState, STATE_IN_PROGRESS, mo_release);
          FExecutingThreadId := GetCurrentThreadId;
          ShouldExecute := True;
        end
        else
          Exit;
      end;
      STATE_POISONED:
      begin
        if not AForce then
          raise ELockError.Create(rsOnceAlreadyPoisoned)
        else
        begin
          atomic_store(FState, STATE_IN_PROGRESS, mo_release);
          FExecutingThreadId := GetCurrentThreadId;
          ShouldExecute := True;
        end;
      end;
    end;
  finally
    LockRelease;
  end;

  // 第二阶段：在锁外执行用户回调（提高并发性）
  ExecutionSucceeded := False;
  if ShouldExecute then
  begin
    try
      case ACallback.CallbackType of
        octProc:
          if Assigned(ACallback.Proc) then
            ACallback.Proc();
        octMethod:
          if Assigned(ACallback.Method) then
            ACallback.Method();
        {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
        octAnonymous:
          if Assigned(ACallback.AnonymousProc) then
            ACallback.AnonymousProc();
        {$ENDIF}
      end;
      ExecutionSucceeded := True;
      {$IFDEF FAFAFA_CORE_DEBUG_ONCE}
      WriteLn('[DEBUG] Execution completed successfully');
      {$ENDIF}
    except
      {$IFDEF FAFAFA_CORE_DEBUG_ONCE}
      WriteLn('[DEBUG] Execution failed - Once will be poisoned');
      {$ENDIF}
    end;
  end;

  // 第三阶段：重新获取锁，设置最终状态
  LockAcquire;
  try
    if ExecutionSucceeded then
    begin
      atomic_store(FState, STATE_COMPLETED, mo_release);
      atomic_store(FDone, 1, mo_release);
      FExecutingThreadId := 0;
    end
    else
    begin
      atomic_store(FState, STATE_POISONED, mo_release);
      atomic_store(FDone, 1, mo_release);
      FExecutingThreadId := 0;
      raise ELockError.Create('Once callback failed');
    end;
  finally
    LockRelease;
  end;
end;

// ✅ P0-2 Fix: 简化后的 DoInternal 方法，委托给 DoInternalCore
procedure TOnce.DoInternal(const AProc: TOnceProc; AForce: Boolean);
var
  Callback: TOnceCallback;
begin
  Callback.CallbackType := octProc;
  Callback.Proc := AProc;
  Callback.Method := nil;
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  Callback.AnonymousProc := nil;
  {$ENDIF}
  DoInternalCore(Callback, AForce);
end;

procedure TOnce.DoInternal(const AMethod: TOnceMethod; AForce: Boolean);
var
  Callback: TOnceCallback;
begin
  Callback.CallbackType := octMethod;
  Callback.Proc := nil;
  Callback.Method := AMethod;
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  Callback.AnonymousProc := nil;
  {$ENDIF}
  DoInternalCore(Callback, AForce);
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
procedure TOnce.DoInternal(const AAnonymousProc: TOnceAnonymousProc; AForce: Boolean);
var
  Callback: TOnceCallback;
begin
  Callback.CallbackType := octAnonymous;
  Callback.Proc := nil;
  Callback.Method := nil;
  Callback.AnonymousProc := AAnonymousProc;
  DoInternalCore(Callback, AForce);
end;
{$ENDIF}

// 等待机制实现（高性能版本）
procedure TOnce.Wait;
var
  SpinCount: Integer;
  CurrentState: LongInt;
begin
  // 蹇€熻矾寰勶細濡傛灉宸插畬鎴愶紝鐩存帴杩斿洖锛坅cquire 璇箟锛?
  // 鍒嗘敮棰勬祴浼樺寲锛歐ait璋冪敤鏃堕€氬父宸茬粡瀹屾�?
  if Likely(atomic_load(FDone, mo_acquire) <> 0) then
  begin
    // 淇ABA闂锛氫娇鐢ㄥ師瀛愯鍙栨鏌ユ瘨鍖栫姸�?
    CurrentState := atomic_load(FState, mo_relaxed);
    // 姣掑寲鐘舵€佸緢灏戣�?
    if Unlikely(CurrentState = STATE_POISONED) then
      raise ELockError.Create(rsOnceAlreadyPoisoned);
    Exit;
  end;

  // 楂樻€ц兘绛夊緟绛栫暐锛氳嚜閫傚簲鑷�?+ 鎸囨暟閫€閬?
  SpinCount := 0;

  while atomic_load(FDone, mo_acquire) = 0 do
  begin
    Inc(SpinCount);

    // 鍒嗘敮棰勬祴浼樺寲锛氱煭鏃堕棿鑷棆鏄渶甯歌鐨勬儏鍐?
    if Likely(SpinCount < 1000) then
    begin
      // 闃舵�?锛欳PU鑷棆绛夊緟锛堥€傚悎鐭椂闂寸瓑寰咃級
      // 浣跨�?PAUSE 鎸囦护浼樺寲瓒呯嚎绋嬫€ц�?
      {$IFDEF CPUX86_64}
      asm
        pause
      end;
      {$ELSE}
      // 鍏朵粬鏋舵瀯浣跨敤 YieldProcessor 鎴栫煭鏆傚欢�?
      Sleep(0);
      {$ENDIF}
    end
    else if Likely(SpinCount < 10000) then
    begin
      // 闃舵�?锛氳鍑烘椂闂寸墖锛堥€傚悎涓瓑鏃堕棿绛夊緟�?
      Sleep(0);
    end
    else
    begin
      // 闃舵�?锛氱煭鏆備紤鐪狅紙閫傚悎闀挎椂闂寸瓑寰咃級
      Sleep(1);
      // 閲嶇疆璁℃暟鍣紝閬垮厤鏃犻檺澧為暱
      if Unlikely(SpinCount > 50000) then
        SpinCount := 10000;
    end;
  end;

  // 妫€鏌ユ渶缁堢姸�?
  CurrentState := atomic_load(FState, mo_relaxed);
  if CurrentState = STATE_POISONED then
    raise ELockError.Create(rsOnceAlreadyPoisoned);
end;

procedure TOnce.WaitForce;
var
  SpinCount: Integer;
begin
  // 寮哄埗绛夊緟锛屽拷鐣ユ瘨鍖栫姸鎬侊紙楂樻€ц兘鐗堟湰锛?
  SpinCount := 0;

  while atomic_load(FDone, mo_acquire) = 0 do
  begin
    Inc(SpinCount);

    if SpinCount < 1000 then
    begin
      // 闃舵�?锛欳PU鑷棆绛夊緟
      {$IFDEF CPUX86_64}
      asm
        pause
      end;
      {$ELSE}
      Sleep(0);
      {$ENDIF}
    end
    else if SpinCount < 10000 then
    begin
      // 闃舵�?锛氳鍑烘椂闂寸墖
      Sleep(0);
    end
    else
    begin
      // 闃舵�?锛氱煭鏆備紤�?
      Sleep(1);
      if SpinCount > 50000 then
        SpinCount := 10000;
    end;
  end;
end;



function TOnce.GetState: TOnceState;
var
  CurrentState: LongInt;
begin
  // 浣跨敤鍗曟鍘熷瓙璇诲彇鑰屼笉鏄笁閲嶈鍙?
  CurrentState := atomic_load(FState, mo_relaxed);
  case CurrentState of
    STATE_NOT_STARTED: Result := osNotStarted;
    STATE_IN_PROGRESS: Result := osInProgress;
    STATE_COMPLETED: Result := osCompleted;
    STATE_POISONED: Result := osPoisoned;
  else
    Result := osNotStarted; // 榛樿鍊?
  end;
end;

function TOnce.GetCompleted: Boolean;
begin
  // 鍙湁鍦ㄧ湡姝ｅ畬鎴愶紙闈炴瘨鍖栵級鏃舵墠杩斿洖 True
  Result := (atomic_load(FDone, mo_acquire) <> 0) and
            (atomic_load(FState, mo_relaxed) = STATE_COMPLETED);
end;

function TOnce.GetPoisoned: Boolean;
begin
  // 浣跨敤鍗曟鍘熷瓙璇诲彇妫€鏌ョ姸鎬?
  Result := atomic_load(FState, mo_relaxed) = STATE_POISONED;
end;

// Reset 鏂规硶宸茬Щ闄?- 涓嶅畨鍏ㄤ笖涓嶇鍚堜富娴佽瑷€瀹炶�?
// 濡傞渶閲嶆柊鎵ц锛岃鍒涘缓鏂扮�?Once 瀹炰�?

end.



