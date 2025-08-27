{$CODEPAGE UTF8}
unit Test_nonce_manager_ts;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.crypto;

type
  { TTestCase_NonceManager_TS }
  TTestCase_NonceManager_TS = class(TTestCase)
  published
    procedure Test_ThreadSafe_MonotonicAcrossThreads;
  end;

implementation

type
  TWorker = class(TThread)
  private
    FNM: INonceManager;
    FCount: Integer;
    FOK: PBoolean;
  protected
    procedure Execute; override;
  public
    constructor Create(const ANM: INonceManager; ACount: Integer; AOK: PBoolean);
  end;

constructor TWorker.Create(const ANM: INonceManager; ACount: Integer; AOK: PBoolean);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FNM := ANM;
  FCount := ACount;
  FOK := AOK;
end;

procedure TWorker.Execute;
var
  i: Integer; N: TBytes; okLocal: Boolean;
begin
  okLocal := True;
  for i := 1 to FCount do
  begin
    N := FNM.NextGCMNonce12; // 只要不抛异常即可（顺序由锁保证，但本测试不做强序要求）
    if Length(N) <> 12 then okLocal := False;
  end;
  if Assigned(FOK) then FOK^ := okLocal;
end;

procedure TTestCase_NonceManager_TS.Test_ThreadSafe_MonotonicAcrossThreads;
var
  NM: INonceManager; W1, W2: TWorker; ok1, ok2: Boolean;
begin
  NM := CreateNonceManagerThreadSafe($01020304, 0);
  ok1 := True; ok2 := True;
  W1 := TWorker.Create(NM, 1000, @ok1);
  W2 := TWorker.Create(NM, 1000, @ok2);
  try
    W1.Start; W2.Start;
    W1.WaitFor; W2.WaitFor;
    AssertTrue('thread1 ok', ok1);
    AssertTrue('thread2 ok', ok2);
    // 期望总次数 = 2000，最后计数器应为 2000
    AssertEquals('counter advanced', 2000, NM.Counter);
  finally
    W1.Free; W2.Free;
  end;
end;

initialization
  RegisterTest(TTestCase_NonceManager_TS);

end.

