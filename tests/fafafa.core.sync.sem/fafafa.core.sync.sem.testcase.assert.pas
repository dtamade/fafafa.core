unit fafafa.core.sync.sem.testcase.assert;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.sync.sem, fafafa.core.sync.base;

type
  TTestCase_Sem_Assert = class(TTestCase)
  private
    FSem: ISem;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_Constructors_Valid;
    procedure Test_Constructors_Invalid_MaxLEZero;
    procedure Test_Constructors_Invalid_InitialNegative;
    procedure Test_Constructors_Invalid_InitialGreaterThanMax;
    procedure Test_ParamValidation_AcquireRelease_Invalid;
    procedure Test_ParamValidation_TryAcquire_Invalid;
    procedure Test_Error_ReleaseBeyondMax;
  end;

implementation

procedure TTestCase_Sem_Assert.SetUp;
begin
  inherited SetUp;
  // initial=1, max=3
  FSem := MakeSem(1, 3);
end;

procedure TTestCase_Sem_Assert.TearDown;
begin
  FSem := nil;
  inherited TearDown;
end;

procedure TTestCase_Sem_Assert.Test_Constructors_Valid;
var S: ISem;
begin
  S := MakeSem(0, 1);
  AssertEquals(0, S.GetAvailableCount);
  AssertEquals(1, S.GetMaxCount);

  S := MakeSem(2, 5);
  AssertEquals(2, S.GetAvailableCount);
  AssertEquals(5, S.GetMaxCount);
end;

procedure TTestCase_Sem_Assert.Test_Constructors_Invalid_MaxLEZero;
  procedure DoCall; begin MakeSem(0, 0); end;
begin
  AssertException(EInvalidArgument, @DoCall);
end;

procedure TTestCase_Sem_Assert.Test_Constructors_Invalid_InitialNegative;
  procedure DoCall; begin MakeSem(-1, 1); end;
begin
  AssertException(EInvalidArgument, @DoCall);
end;

procedure TTestCase_Sem_Assert.Test_Constructors_Invalid_InitialGreaterThanMax;
  procedure DoCall; begin MakeSem(2, 1); end;
begin
  AssertException(EInvalidArgument, @DoCall);
end;

procedure TTestCase_Sem_Assert.Test_ParamValidation_AcquireRelease_Invalid;
  procedure DoAcquireNeg; begin FSem.Acquire(-1); end;
  procedure DoAcquireTooMany; begin FSem.Acquire(FSem.GetMaxCount + 1); end;
  procedure DoReleaseNeg; begin FSem.Release(-1); end;
begin
  AssertException(EInvalidArgument, @DoAcquireNeg);
  AssertException(EInvalidArgument, @DoAcquireTooMany);
  AssertException(EInvalidArgument, @DoReleaseNeg);
end;

procedure TTestCase_Sem_Assert.Test_ParamValidation_TryAcquire_Invalid;
var ok: Boolean;
  procedure DoTryNeg; begin ok := FSem.TryAcquire(-1); end;
  procedure DoTryNegTimeout; begin ok := FSem.TryAcquire(-1, 10); end;
begin
  AssertException(EInvalidArgument, @DoTryNeg);
  AssertException(EInvalidArgument, @DoTryNegTimeout);
end;

procedure TTestCase_Sem_Assert.Test_Error_ReleaseBeyondMax;
var i: Integer;
  procedure DoRel; begin FSem.Release; end;
begin
  // bump to max
  for i := FSem.GetAvailableCount to FSem.GetMaxCount - 1 do FSem.Release;
  AssertException(ELockError, @DoRel);
end;

initialization
  RegisterTest(TTestCase_Sem_Assert);

end.
