unit fafafa.core.test.core;

{$mode objfpc}{$H+}
{$modeswitch nestedprocvars}
{$modeswitch anonymousfunctions}

{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes, fafafa.core.test.utils;

type
  ETestFailure = class(Exception);
  // Export ETestSkip so runner can recognize top-level Skip/Assume
  ETestSkip = class(Exception);

  ITestContext = interface; // forward
  // Use managed closures so registered tests remain valid after RegisterTests returns
  TTestProc = reference to procedure(const ctx: ITestContext);
  TStrCaseProc = reference to procedure(const ctx: ITestContext; const Value: string);
  TNoArgProc = reference to procedure;
  // 注意：不要使用 "is nested" 的过程类型来注册测试
  // 因为 RegisterTests 返回后，nested proc 的静态链可能失效，延迟调用时会引发 AV。
  // 使用 "reference to procedure"（闭包）能安全捕获上下文，避免生命周期问题。


  ITestListener = interface
    ['{1E0E3B9E-2E53-4BAA-A2E6-7F1B1B0E8E95}']
    procedure OnStart(ATotal: Integer);
    procedure OnTestStart(const AName: string);
    procedure OnTestSuccess(const AName: string; AElapsedMs: QWord);
    procedure OnTestFailure(const AName, AMessage: string; AElapsedMs: QWord);
    procedure OnTestSkipped(const AName: string; AElapsedMs: QWord);
    procedure OnEnd(ATotal, AFailed: Integer; AElapsedMs: QWord);
  end;

  // Clock abstraction for test determinism
  IClock = interface
    ['{4C06E6B9-5E2E-4B70-96B2-8A3F7E04B7E1}']
    function NowUTC: TDateTime;
    function NowMonotonicMs: QWord;
  end;

  ITestContext = interface
    ['{E06B7A4D-AD69-4C16-93B3-9B4C04D8B4E1}']
    procedure AssertTrue(ACondition: boolean; const AMsg: string = '');
    procedure AssertEquals(const AExpected, AActual: string; const AMsg: string = '');
    procedure Fail(const AMsg: string);
    procedure Log(const AMsg: string);
    function TempDir: string;
    // Clock accessors
    function GetClock: IClock;
    procedure SetClock(const AClock: IClock);
    property Clock: IClock read GetClock write SetClock;
    // Cleanup registration (LIFO)
    procedure AddCleanup(const P: TNoArgProc);
    procedure RunCleanupsNow;
    // Drain cleanups and capture errors without raising; returns True if any error occurred
    function RunCleanupsCapture(out AErrors: string): boolean;
    // Exception helpers
    procedure AssertRaises(const EClass: ExceptClass; const Proc: TNoArgProc; const AMsg: string = '');
    procedure Throws(const EClass: ExceptClass; const Proc: TNoArgProc; const AMsg: string = '');
    procedure NotThrows(const Proc: TNoArgProc; const AMsg: string = '');
    // Skip/Assume
    procedure Skip(const Reason: string = '');
    procedure Assume(ACondition: boolean; const Reason: string = '');
    // Naming for subtests
    function GetName: string;
    procedure SetName(const AName: string);
    // Subtest
    procedure Run(const AName: string; const AProc: TTestProc);
    // Table-driven helper (string)
    procedure ForEachStr(const Prefix: string; const Cases: array of string; const Each: TStrCaseProc);
    property Name: string read GetName write SetName;
  end;

procedure Test(const APath: string; const AProc: TTestProc);
procedure ClearRegisteredTests;

type
  TTestItem = record
    Name: string;
    Proc: TTestProc;
  end;

  // Built-in clocks
  TSystemClock = class(TInterfacedObject, IClock)
  public
    function NowUTC: TDateTime;
    function NowMonotonicMs: QWord;
  end;

  TFixedClock = class(TInterfacedObject, IClock)
  private
    FNowUTC: TDateTime;
    FNowMs: QWord;
  public
    constructor Create(const AUTC: TDateTime; const AMonotonicMs: QWord);
    function NowUTC: TDateTime;
    function NowMonotonicMs: QWord;
    procedure SetNowUTC(const AUTC: TDateTime);
    procedure SetNowMonotonicMs(const AMonotonicMs: QWord);
  end;

// Factory for creating default test context
function NewTestContext: ITestContext;

// Listener management and notifications (declarations)
procedure AddListener(const L: ITestListener);
procedure ClearListeners;
procedure NotifyStart(ATotal: Integer);
procedure NotifyTestStart(const AName: string);
procedure NotifyTestSuccess(const AName: string; AElapsedMs: QWord);
procedure NotifyTestFailure(const AName, AMessage: string; AElapsedMs: QWord);
procedure NotifyTestSkipped(const AName: string; AElapsedMs: QWord);
procedure NotifyEnd(ATotal, AFailed: Integer; AElapsedMs: QWord);

// Runner activation hook (used by custom runner to enable skip exceptions)
procedure _SetRunnerActive(AActive: boolean);


// Internal structures for runner/listener
function RegisteredTestCount: Integer;
procedure GetRegisteredTest(AIndex: Integer; out AName: string; out AProc: TTestProc);

implementation

uses
  {$IFDEF WINDOWS} Windows {$ELSE} BaseUnix {$ENDIF};

procedure SetEnvCross(const AName, AValue: string);
begin
  {$IFDEF WINDOWS}
  Windows.SetEnvironmentVariable(PChar(AName), PChar(AValue));
  {$ELSE}
  if AValue = '' then
    fpunsetenv(PChar(AName))
  else
    fpsetenv(PChar(AnsiString(AName + '=' + AValue)));
  {$ENDIF}
end;


function _Hash64FNV1a(const S: string): QWord;
const
  FNV_OFFSET_BASIS_64: QWord = QWord($CBF29CE484222325);
  FNV_PRIME_64: QWord = QWord($00000100000001B3);
var
  i: Integer;
  h: QWord;
  c: Byte;
begin
  h := FNV_OFFSET_BASIS_64;
  for i := 1 to Length(S) do
  begin
    c := Byte(Ord(S[i]) and $FF);
    h := h xor c;
    h := h * FNV_PRIME_64;
  end;
  Result := h;
end;


var
  GTests: array of TTestItem;
threadvar
  GRunnerActive: boolean;

  GListeners: array of ITestListener;
  // default context name for top-level will be set by runner

procedure Test(const APath: string; const AProc: TTestProc);
begin
  SetLength(GTests, Length(GTests)+1);
  GTests[High(GTests)].Name := APath;
  GTests[High(GTests)].Proc := AProc;
end;

procedure ClearRegisteredTests;
begin
  SetLength(GTests, 0);
end;

function RegisteredTestCount: Integer;
begin
  Result := Length(GTests);
end;

procedure GetRegisteredTest(AIndex: Integer; out AName: string; out AProc: TTestProc);
begin
  if (AIndex < 0) or (AIndex >= Length(GTests)) then
    raise Exception.CreateFmt('Invalid test index %d', [AIndex]);
  AName := GTests[AIndex].Name;
  AProc := GTests[AIndex].Proc;

end;

type

  TTestContext = class(TInterfacedObject, ITestContext)
    function GetName: string;
    procedure SetName(const AName: string);
    procedure Run(const AName: string; const AProc: TTestProc);
    procedure ForEachStr(const Prefix: string; const Cases: array of string; const Each: TStrCaseProc);
    function RunCleanupsCapture(out AErrors: string): boolean;

  private
    FTempDir: string;
    FName: string;
    FClock: IClock;
    FCleanups: array of TNoArgProc;
  public
    class function New: ITestContext; static;
    procedure AssertTrue(ACondition: boolean; const AMsg: string = '');
    procedure AssertEquals(const AExpected, AActual: string; const AMsg: string = '');
    procedure AssertRaises(const EClass: ExceptClass; const Proc: TNoArgProc; const AMsg: string = '');
    procedure Throws(const EClass: ExceptClass; const Proc: TNoArgProc; const AMsg: string = '');
    procedure NotThrows(const Proc: TNoArgProc; const AMsg: string = '');
    procedure Skip(const Reason: string = '');
    procedure Assume(ACondition: boolean; const Reason: string = '');
    procedure Fail(const AMsg: string);
    procedure Log(const AMsg: string);
    function TempDir: string;
    // ITestContext clock
    function GetClock: IClock;
    procedure SetClock(const AClock: IClock);
    // ITestContext cleanup
    procedure AddCleanup(const P: TNoArgProc);
    procedure RunCleanupsNow;
  end;

function TTestContext.GetName: string;
begin
  Result := FName;
end;

procedure TTestContext.SetName(const AName: string);
begin
  FName := AName;
end;

procedure TTestContext.Run(const AName: string; const AProc: TTestProc);
var
  Child: ITestContext;
  FullName: string;
  Start: QWord;
  Elapsed: QWord;
  var CleanupErrs: string;
begin
  if not Assigned(AProc) then Exit;
  // Compose hierarchical name
  if (FName <> '') and (AName <> '') then FullName := FName + '/' + AName
  else if AName <> '' then FullName := AName
  else FullName := FName;

  Child := TTestContext.New;
  Child.SetName(FullName);

  NotifyTestStart(FullName);
  Start := GetTickCount64;
  try
    try
      AProc(Child);
      Elapsed := GetTickCount64 - Start;
      // even on success, ensure we try cleanups and capture errors
      CleanupErrs := '';
      if (Child as TTestContext).RunCleanupsCapture(CleanupErrs) then
        NotifyTestFailure(FullName, 'cleanup errors:'+LineEnding+CleanupErrs, Elapsed)
      else
        NotifyTestSuccess(FullName, Elapsed);
    except
      on E: ETestSkip do
      begin
        Elapsed := GetTickCount64 - Start;
        // run cleanups, ignore cleanup errors for skipped
        (Child as TTestContext).RunCleanupsNow;
        NotifyTestSkipped(FullName, Elapsed);
      end;
      on E: ETestFailure do
      begin
        Elapsed := GetTickCount64 - Start;
        CleanupErrs := '';
        (Child as TTestContext).RunCleanupsCapture(CleanupErrs);
        if CleanupErrs<>'' then
          NotifyTestFailure(FullName, E.Message+LineEnding+'[cleanup]'+LineEnding+CleanupErrs, Elapsed)
        else
          NotifyTestFailure(FullName, E.Message, Elapsed);
      end;
      on E: Exception do
      begin
        Elapsed := GetTickCount64 - Start;
        CleanupErrs := '';
        (Child as TTestContext).RunCleanupsCapture(CleanupErrs);
        if CleanupErrs<>'' then
          NotifyTestFailure(FullName, E.ClassName+': '+E.Message+LineEnding+'[cleanup]'+LineEnding+CleanupErrs, Elapsed)
        else
          NotifyTestFailure(FullName, E.ClassName+': '+E.Message, Elapsed);
      end;
    end;
  finally
    // FCleanups already drained; nothing else to run here
  end;
end;

procedure TTestContext.ForEachStr(const Prefix: string; const Cases: array of string; const Each: TStrCaseProc);
var i: Integer; n, nm, val: string;
begin
  for i := 0 to High(Cases) do
  begin
    if Assigned(Each) then
    begin
      n := IntToStr(i);
      if Prefix <> '' then nm := Prefix + '/' + n else nm := n;
      val := Cases[i];
      Run(nm, procedure(const ctx: ITestContext)
      begin
        Each(ctx, val);
      end);
    end;
  end;
end;

function NewTestContext: ITestContext;
begin
  Result := TTestContext.New;
end;



class function TTestContext.New: ITestContext;
begin
  Result := TTestContext.Create;
  // default to system clock
  (Result as TTestContext).FClock := TSystemClock.Create;
end;

procedure TTestContext.AssertTrue(ACondition: boolean; const AMsg: string);
begin
  if not ACondition then
    raise ETestFailure.Create(AMsg);
end;

// Listener implementations
procedure AddListener(const L: ITestListener);
begin
  SetLength(GListeners, Length(GListeners)+1);
  GListeners[High(GListeners)] := L;
end;

procedure ClearListeners;
begin
  SetLength(GListeners, 0);
end;

procedure NotifyStart(ATotal: Integer);
var L: ITestListener;
begin
  for L in GListeners do L.OnStart(ATotal);
end;

procedure NotifyTestStart(const AName: string);
var L: ITestListener; id: QWord;
begin
  // export current test name for diagnostics in library code
  SetEnvCross('FAFAFA_CURRENT_TEST', AName);
  // also export a stable CaseId for report consumers
  id := _Hash64FNV1a(AName);
  SetEnvCross('FAFAFA_CURRENT_TEST_ID', IntToHex(id, 16));
  for L in GListeners do L.OnTestStart(AName);
end;

procedure NotifyTestSuccess(const AName: string; AElapsedMs: QWord);
var L: ITestListener;
begin
  for L in GListeners do L.OnTestSuccess(AName, AElapsedMs);
end;

procedure NotifyTestFailure(const AName, AMessage: string; AElapsedMs: QWord);
var L: ITestListener;
begin
  for L in GListeners do L.OnTestFailure(AName, AMessage, AElapsedMs);
end;

procedure NotifyEnd(ATotal, AFailed: Integer; AElapsedMs: QWord);
var L: ITestListener;
begin
  // clear current test-related environment vars at suite end
  SetEnvCross('FAFAFA_CURRENT_TEST', '');
  SetEnvCross('FAFAFA_CURRENT_TEST_ID', '');
  for L in GListeners do L.OnEnd(ATotal, AFailed, AElapsedMs);
end;

procedure NotifyTestSkipped(const AName: string; AElapsedMs: QWord);
var L: ITestListener;
begin
  for L in GListeners do L.OnTestSkipped(AName, AElapsedMs);
end;

procedure TTestContext.AssertEquals(const AExpected, AActual: string; const AMsg: string);
var
  Msg: string;
begin
  if AExpected <> AActual then
  begin
    if AMsg <> '' then Msg := AMsg else Msg := 'Expected <> Actual';
    raise ETestFailure.Create(Format('%s; expected="%s" actual="%s"',[Msg, AExpected, AActual]));
  end;
end;

procedure TTestContext.Fail(const AMsg: string);
begin
  raise ETestFailure.Create(AMsg);
end;

procedure TTestContext.Log(const AMsg: string);
begin
  // minimal: write to stdout
  if AMsg <> '' then
    WriteLn('[LOG] ', AMsg);
end;

function TTestContext.TempDir: string;
begin
  if FTempDir = '' then
    FTempDir := CreateTempDir('test_');
  Result := FTempDir;
end;

// IClock implementations
function TSystemClock.NowUTC: TDateTime;
begin
  Result := Now; // local time; for UTC use Now + TZ offset if needed
end;

function TSystemClock.NowMonotonicMs: QWord;
begin
  Result := GetTickCount64;
end;

constructor TFixedClock.Create(const AUTC: TDateTime; const AMonotonicMs: QWord);
begin
  inherited Create;
  FNowUTC := AUTC;
  FNowMs := AMonotonicMs;
end;

function TFixedClock.NowUTC: TDateTime;
begin
  Result := FNowUTC;
end;

function TFixedClock.NowMonotonicMs: QWord;
begin
  Result := FNowMs;
end;

procedure TFixedClock.SetNowUTC(const AUTC: TDateTime);
begin
  FNowUTC := AUTC;
end;

procedure TFixedClock.SetNowMonotonicMs(const AMonotonicMs: QWord);
begin
  FNowMs := AMonotonicMs;
end;

// ITestContext clock
function TTestContext.GetClock: IClock;
begin
  Result := FClock;
end;

procedure TTestContext.SetClock(const AClock: IClock);
begin
  FClock := AClock;
end;

procedure TTestContext.AssertRaises(const EClass: ExceptClass; const Proc: TNoArgProc; const AMsg: string);
var
  Pref: string;
begin
  if not Assigned(Proc) then raise ETestFailure.Create('AssertRaises: Proc=nil');
  if AMsg<>'' then Pref := AMsg+': ' else Pref := '';
  try
    Proc;
  except
    on E: Exception do
    begin
      if (EClass <> nil) and (E is EClass) then Exit
      else
        raise ETestFailure.CreateFmt('%sExpected exception %s, got %s: %s',
          [Pref, EClass.ClassName, E.ClassName, E.Message]);
    end;
  end;
  // no exception thrown
  raise ETestFailure.CreateFmt('%sExpected exception %s, but none was raised',
    [Pref, EClass.ClassName]);
end;

procedure TTestContext.AddCleanup(const P: TNoArgProc);
begin
  if not Assigned(P) then Exit;
  SetLength(FCleanups, Length(FCleanups)+1);
  FCleanups[High(FCleanups)] := P;
end;
function TTestContext.RunCleanupsCapture(out AErrors: string): boolean;
var i: Integer; err: TStringList;
begin
  Result := False;
  err := TStringList.Create;
  try
    for i := High(FCleanups) downto 0 do
    begin
      try
        if Assigned(FCleanups[i]) then FCleanups[i]();
      except
        on E: Exception do
        begin
          err.Add(E.ClassName+': '+E.Message);
          Result := True;
        end;
      end;
    end;
    if Result then AErrors := err.Text else AErrors := '';
  finally
    err.Free;
  end;
end;


procedure TTestContext.RunCleanupsNow;
var i: Integer;
begin
  for i := High(FCleanups) downto 0 do
  begin
    try
      if Assigned(FCleanups[i]) then FCleanups[i]();
    except
      on E: Exception do
        Log('Cleanup error: '+E.ClassName+': '+E.Message);
    end;
  end;
  SetLength(FCleanups, 0);
end;

procedure TTestContext.Throws(const EClass: ExceptClass; const Proc: TNoArgProc; const AMsg: string);
begin
  AssertRaises(EClass, Proc, AMsg);
end;

procedure TTestContext.NotThrows(const Proc: TNoArgProc; const AMsg: string);
var
  Pref: string;
begin
  if not Assigned(Proc) then raise ETestFailure.Create('NotThrows: Proc=nil');
  if AMsg<>'' then Pref := AMsg+': ' else Pref := '';
  try
    Proc;
  except
    on E: Exception do
      raise ETestFailure.CreateFmt('%sExpected no exception, got %s: %s',
        [Pref, E.ClassName, E.Message]);
  end;
end;

procedure TTestContext.Skip(const Reason: string);
begin
  if Reason<>'' then Log('[SKIP] '+Reason);
  // If running under our custom runner, raise to unwind and mark as skipped.
  // If called from external frameworks (e.g., FPCUnit), do not raise to avoid marking Error.
  if GRunnerActive then
    raise ETestSkip.Create(Reason)
  else
    Exit; // treat as successful no-op skip in foreign runners
end;

procedure TTestContext.Assume(ACondition: boolean; const Reason: string);
begin
  if not ACondition then
    Skip('assume failed: '+Reason);
end;

procedure _SetRunnerActive(AActive: boolean);
begin
  GRunnerActive := AActive;
end;

end.

