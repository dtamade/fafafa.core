unit test_treiber_concurrency;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  Classes, fpcunit, testutils, testregistry,
  {$IFDEF UNIX}cthreads,{$ENDIF}
  fafafa.core.lockfree.stack;

type
  { 并发与长稳基础用例（不做基准） }
  TTestTreiberConcurrency = class(TTestCase)
  published
    procedure PushPop_Concurrent_Smoke;
  end;

implementation

uses
  SysUtils;

type
  TIntStack = specialize TTreiberStack<Integer>;

  TPushThread = class(TThread)
  private
    FStack: TIntStack;
    FStart: Integer;
    FCount: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(const S: TIntStack; AStart, ACount: Integer);
  end;

  TPopThread = class(TThread)
  private
    FStack: TIntStack;
    FPopped: PInteger;
    FDurationMs: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(const S: TIntStack; var Popped: Integer; DurationMs: Integer);
  end;

{ TPushThread }
constructor TPushThread.Create(const S: TIntStack; AStart, ACount: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FStack := S;
  FStart := AStart;
  FCount := ACount;
end;

procedure TPushThread.Execute;
var
  i: Integer;
begin
  for i := 0 to FCount - 1 do
    FStack.Push(FStart + i);
end;

{ TPopThread }
constructor TPopThread.Create(const S: TIntStack; var Popped: Integer; DurationMs: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FStack := S;
  FPopped := @Popped;
  FDurationMs := DurationMs;
end;

procedure TPopThread.Execute;
var
  x: Integer;
  t0: QWord;
begin
  FPopped^ := 0;
  t0 := GetTickCount64;
  while (GetTickCount64 - t0 < QWord(FDurationMs)) do
  begin
    if FStack.Pop(x) then Inc(FPopped^);
  end;
end;

procedure TTestTreiberConcurrency.PushPop_Concurrent_Smoke;
var
  S: TIntStack;
  TPush1, TPush2: TPushThread;
  TPop1, TPop2: TPopThread;
  P1, P2: Integer;
begin
  S := TIntStack.Create;
  try
    P1 := 0; P2 := 0;
    // 两个生产者持续 Push，两个消费者持续 Pop（短时烟囱测试）
    TPush1 := TPushThread.Create(S, 0, 100000);
    TPush2 := TPushThread.Create(S, 1000000, 100000);
    TPop1 := TPopThread.Create(S, P1, 500);
    TPop2 := TPopThread.Create(S, P2, 500);

    TPush1.Start; TPush2.Start; TPop1.Start; TPop2.Start;
    TPush1.WaitFor; TPush2.WaitFor; TPop1.WaitFor; TPop2.WaitFor;

    // 验证：至少弹出一些元素（这只是烟囱测试，不是基准或严格正确性检查）
    AssertTrue('Expected some pops', (P1 + P2) > 0);
  finally
    TPush1.Free; TPush2.Free; TPop1.Free; TPop2.Free;
    S.Free;
  end;
end;

initialization
  RegisterTest(TTestTreiberConcurrency);

end.

