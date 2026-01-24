unit fafafa.core.sync.namedMutex.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.sync,  // 门面单元，导出 MakeNamed* 函数
  fafafa.core.sync.namedMutex, fafafa.core.sync.base;

type
  // 全局函数测试
  TTestCase_Global = class(TTestCase)
  published
    procedure Test_MakeNamedMutex;
    procedure Test_MakeNamedMutex_InitialOwner;
    procedure Test_MakeNamedMutex_Existing;
    procedure Test_MakeNamedMutex_WithTimeout;
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
    procedure Test_LockNamed_Unlock;
    procedure Test_TryLockNamed;
    procedure Test_TryLockForNamed;
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
  LConfig: TNamedMutexConfig;
begin
  LConfig := DefaultNamedMutexConfig;
  LConfig.InitialOwner := True;
  M := MakeNamedMutex('test_mutex_owner', LConfig);
  CheckNotNull(M);
  // 初始拥有可直接释放一次
  M.Release;
end;

procedure TTestCase_Global.Test_MakeNamedMutex_Existing;
var
  M1, M2: INamedMutex;
begin
  M1 := MakeNamedMutex('test_mutex_open');
  CheckNotNull(M1);
  M2 := MakeNamedMutex('test_mutex_open');
  CheckNotNull(M2);
  CheckEquals('test_mutex_open', M2.GetName);
end;

procedure TTestCase_Global.Test_MakeGlobalNamedMutex;
var
  M: INamedMutex;
begin
  try
    M := MakeGlobalNamedMutex('test_global_mutex');
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
  // Windows: Global\ 前缀被添加
  CheckTrue(Pos('Global\', M.GetName) = 1);
  {$ELSE}
  // Unix: 命名互斥锁默认就是全局的，不需要前缀
  CheckEquals('test_global_mutex', M.GetName);
  {$ENDIF}
end;

procedure TTestCase_Global.Test_MakeNamedMutex_WithTimeout;
var
  M: INamedMutex;
begin
  M := MakeNamedMutex('test_make_mutex_timeout', 1000);
  CheckNotNull(M);
  CheckEquals('test_make_mutex_timeout', M.GetName);
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

procedure TTestCase_INamedMutex.Test_LockNamed_Unlock;
var
  G: INamedMutexGuard;
begin
  G := FMutex.LockNamed;
  CheckNotNull(G);
  CheckTrue(G.IsLocked);
  G := nil;
end;

procedure TTestCase_INamedMutex.Test_TryLockNamed;
var
  G: INamedMutexGuard;
begin
  G := FMutex.TryLockNamed;
  CheckNotNull(G);
  CheckTrue(G.IsLocked);
  G := nil;
end;

procedure TTestCase_INamedMutex.Test_TryLockForNamed;
var
  G: INamedMutexGuard;
begin
  G := FMutex.TryLockForNamed(0);
  CheckNotNull(G);
  G := nil;
  
  G := FMutex.TryLockForNamed(100);
  CheckNotNull(G);
  G := nil;
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
