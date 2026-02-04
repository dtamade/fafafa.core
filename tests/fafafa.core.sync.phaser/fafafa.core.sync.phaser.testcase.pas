{$CODEPAGE UTF8}
unit fafafa.core.sync.phaser.testcase;

{**
 * fafafa.core.sync.phaser 测试套件
 *}

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.sync.phaser,
  TestHelpers_Sync;

type
  TTestCase_Phaser_Basic = class(TTestCase)
  published
    procedure Test_Create;
    procedure Test_Arrive;
    procedure Test_ArriveAndAwaitAdvance_Single;
    procedure Test_Register;
    procedure Test_ArriveAndDeregister;
  end;

  TTestCase_Phaser_Concurrent = class(TTestCase)
  published
    procedure Test_MultiParty;
    procedure Test_MultiplePhases;
  end;

implementation

{ TTestCase_Phaser_Basic }

procedure TTestCase_Phaser_Basic.Test_Create;
var
  P: IPhaser;
begin
  P := MakePhaser(4);
  AssertNotNull('MakePhaser should return non-nil', P);
  AssertEquals('Initial phase', 0, P.GetPhase);
  AssertEquals('Registered parties', 4, P.GetRegisteredParties);
  AssertEquals('Arrived parties', 0, P.GetArrivedParties);
  AssertFalse('Not terminated', P.IsTerminated);
end;

procedure TTestCase_Phaser_Basic.Test_Arrive;
var
  P: IPhaser;
begin
  P := MakePhaser(2);

  AssertEquals('Arrive returns current phase', 0, P.Arrive);
  AssertEquals('Arrived count', 1, P.GetArrivedParties);

  // 第二个到达应该推进阶段
  AssertEquals('Second arrive returns current phase', 0, P.Arrive);
  AssertEquals('Phase should advance', 1, P.GetPhase);
  AssertEquals('Arrived should reset', 0, P.GetArrivedParties);
end;

procedure TTestCase_Phaser_Basic.Test_ArriveAndAwaitAdvance_Single;
var
  P: IPhaser;
begin
  // 单参与者
  P := MakePhaser(1);
  AssertEquals('Phase after advance', 1, P.ArriveAndAwaitAdvance);
  AssertEquals('Phase after second advance', 2, P.ArriveAndAwaitAdvance);
end;

procedure TTestCase_Phaser_Basic.Test_Register;
var
  P: IPhaser;
begin
  P := MakePhaser(2);
  AssertEquals('Initial parties', 2, P.GetRegisteredParties);

  P.Register;
  AssertEquals('Parties after register', 3, P.GetRegisteredParties);
end;

procedure TTestCase_Phaser_Basic.Test_ArriveAndDeregister;
var
  P: IPhaser;
begin
  P := MakePhaser(2);

  P.ArriveAndDeregister;
  AssertEquals('Parties after deregister', 1, P.GetRegisteredParties);

  // 最后一个也注销
  P.ArriveAndDeregister;
  AssertTrue('Should be terminated', P.IsTerminated);
end;

{ TTestCase_Phaser_Concurrent }

type
  TPhaserWorker = class(TThread)
  private
    FPhaser: IPhaser;
    FPhases: Integer;
    FId: Integer;
    FCompleted: Boolean;
  protected
    procedure Execute; override;
  public
    constructor Create(APhaser: IPhaser; AId, APhases: Integer);
    property Completed: Boolean read FCompleted;
  end;

constructor TPhaserWorker.Create(APhaser: IPhaser; AId, APhases: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FPhaser := APhaser;
  FId := AId;
  FPhases := APhases;
  FCompleted := False;
end;

procedure TPhaserWorker.Execute;
var
  i: Integer;
begin
  for i := 1 to FPhases do
    FPhaser.ArriveAndAwaitAdvance;
  FCompleted := True;
end;

procedure TTestCase_Phaser_Concurrent.Test_MultiParty;
var
  P: IPhaser;
  Workers: array[0..3] of TPhaserWorker;
  i, CompletedCount: Integer;
begin
  P := MakePhaser(4);

  for i := 0 to 3 do
    Workers[i] := TPhaserWorker.Create(P, i, 1);

  for i := 0 to 3 do
    Workers[i].Start;

  CompletedCount := 0;
  for i := 0 to 3 do
  begin
    Workers[i].WaitFor;
    if Workers[i].Completed then
      Inc(CompletedCount);
    Workers[i].Free;
  end;

  AssertEquals('All workers should complete', 4, CompletedCount);
  AssertEquals('Phase should be 1', 1, P.GetPhase);
end;

procedure TTestCase_Phaser_Concurrent.Test_MultiplePhases;
var
  P: IPhaser;
  Workers: array[0..2] of TPhaserWorker;
  i, CompletedCount: Integer;
begin
  P := MakePhaser(3);

  for i := 0 to 2 do
    Workers[i] := TPhaserWorker.Create(P, i, 5);  // 5 个阶段

  for i := 0 to 2 do
    Workers[i].Start;

  CompletedCount := 0;
  for i := 0 to 2 do
  begin
    Workers[i].WaitFor;
    if Workers[i].Completed then
      Inc(CompletedCount);
    Workers[i].Free;
  end;

  AssertEquals('All workers should complete', 3, CompletedCount);
  AssertEquals('Phase should be 5', 5, P.GetPhase);
end;

initialization
  RegisterTest(TTestCase_Phaser_Basic);
  RegisterTest(TTestCase_Phaser_Concurrent);

end.
