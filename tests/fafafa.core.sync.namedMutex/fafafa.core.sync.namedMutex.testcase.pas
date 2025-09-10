unit fafafa.core.sync.namedMutex.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.sync.namedMutex, fafafa.core.sync.base;

type
  // 全局函数测试
  TTestCase_Global = class(TTestCase)
  published
    procedure Test_MakeNamedMutex;
    procedure Test_MakeNamedMutex_InitialOwner;
    procedure Test_TryOpenNamedMutex;
    procedure Test_MakeGlobalNamedMutex;
  end;

  // INamedMutex 基本测试
  TTestCase_INamedMutex = class(TTestCase)
  private
    FMutex: INamedMutex;
    FTestName: string;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_GetName;
    procedure Test_IsAbandoned_DefaultFalse;
    procedure Test_Acquire_Release;
    procedure Test_TryAcquire_Immediate;
    procedure Test_TryAcquire_Timeouts;
    procedure Test_InvalidName_AssertException;
  end;

implementation

{ TTestCase_Global }

procedure TTestCase_Global.Test_MakeNamedMutex;
var
  M: INamedMutex;
begin
  M := MakeNamedMutex('test_mutex_basic');
  CheckNotNull(M);
  CheckEquals('test_mutex_basic', M.GetName);
end;

procedure TTestCase_Global.Test_MakeNamedMutex_InitialOwner;
var
  M: INamedMutex;
begin
  M := MakeNamedMutex('test_mutex_owner', True);
  CheckNotNull(M);
  // 初始拥有可直接释放一次
  M.Release;
end;

procedure TTestCase_Global.Test_TryOpenNamedMutex;
var
  M1, M2: INamedMutex;
begin
  M1 := MakeNamedMutex('test_mutex_open');
  CheckNotNull(M1);
  M2 := TryOpenNamedMutex('test_mutex_open');
  CheckNotNull(M2);
  CheckEquals('test_mutex_open', M2.GetName);
end;

procedure TTestCase_Global.Test_MakeGlobalNamedMutex;
var
  M: INamedMutex;
begin
  try
    M := MakeNamedMutex('Global\test_global_mutex');
  except
    on E: ELockError do
    begin
      // 无 SeCreateGlobalPrivilege 环境下，跳过
      Check(True, 'Skipped: requires SeCreateGlobalPrivilege');
      Exit;
    end;
  end;
  CheckNotNull(M);
  {$IFDEF WINDOWS}
  CheckTrue(Pos('Global\', M.GetName) = 1);
  {$ELSE}
  CheckEquals('Global\test_global_mutex', M.GetName);
  {$ENDIF}
end;

{ TTestCase_INamedMutex }

procedure TTestCase_INamedMutex.SetUp;
begin
  inherited SetUp;
  FTestName := 'test_mutex_' + IntToStr(Random(100000));
  FMutex := MakeNamedMutex(FTestName);
end;

procedure TTestCase_INamedMutex.TearDown;
begin
  FMutex := nil;
  inherited TearDown;
end;

procedure TTestCase_INamedMutex.Test_GetName;
begin
  CheckEquals(FTestName, FMutex.GetName);
end;

procedure TTestCase_INamedMutex.Test_IsAbandoned_DefaultFalse;
begin
  CheckFalse(FMutex.IsAbandoned);
end;

procedure TTestCase_INamedMutex.Test_Acquire_Release;
begin
  FMutex.Acquire;
  try
    CheckTrue(True);
  finally
    FMutex.Release;
  end;
end;

procedure TTestCase_INamedMutex.Test_TryAcquire_Immediate;
begin
  CheckTrue(FMutex.TryAcquire);
  FMutex.Release;
end;

procedure TTestCase_INamedMutex.Test_TryAcquire_Timeouts;
begin
  CheckTrue(FMutex.TryAcquire(0));
  FMutex.Release;
  CheckTrue(FMutex.TryAcquire(100));
  FMutex.Release;
end;

procedure TTestCase_INamedMutex.Test_InvalidName_AssertException;
  procedure DoCall; begin MakeNamedMutex(''); end;
begin
  AssertException(fafafa.core.sync.base.EInvalidArgument, @DoCall);
end;

initialization
  RegisterTest(TTestCase_Global);
  RegisterTest(TTestCase_INamedMutex);

end.
