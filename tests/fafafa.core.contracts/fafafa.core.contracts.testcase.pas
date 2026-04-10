{$CODEPAGE UTF8}
unit fafafa.core.contracts.testcase;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.base,
  fafafa.core.contracts;

type
  TTestCoreContracts = class(TTestCase)
  published
    procedure Test_ContractsRequire_TrueCondition_Passes;
    procedure Test_ContractsRequire_FalseCondition_MatchesBuildMode;
    procedure Test_ContractsRequireAssigned_AssignedCondition_Passes;
    procedure Test_ContractsRequireAssigned_UnassignedCondition_MatchesBuildMode;
  end;

implementation

procedure TTestCoreContracts.Test_ContractsRequire_TrueCondition_Passes;
begin
  ContractsRequire(True, 'should not raise');
end;

procedure TTestCoreContracts.Test_ContractsRequire_FalseCondition_MatchesBuildMode;
begin
  {$IFDEF FAFAFA_CORE_CONTRACTS}
  try
    ContractsRequire(False, 'contracts failed');
    Fail('ContractsRequire(False) should raise in contracts-enabled builds');
  except
    on E: EInvalidArgument do
      CheckEquals('contracts failed', E.Message);
  end;
  {$ELSE}
  ContractsRequire(False, 'contracts failed');
  AssertTrue('NoContracts build should treat ContractsRequire as no-op', True);
  {$ENDIF}
end;

procedure TTestCoreContracts.Test_ContractsRequireAssigned_AssignedCondition_Passes;
var
  LValue: Pointer;
begin
  LValue := Pointer(PtrUInt(1));
  ContractsRequireAssigned(LValue <> nil, 'aValue');
end;

procedure TTestCoreContracts.Test_ContractsRequireAssigned_UnassignedCondition_MatchesBuildMode;
begin
  {$IFDEF FAFAFA_CORE_CONTRACTS}
  try
    ContractsRequireAssigned(False, 'aValue');
    Fail('Expected exception: aValue is nil');
  except
    on E: EArgumentNil do
      CheckEquals('aValue is nil', E.Message);
  end;
  {$ELSE}
  ContractsRequireAssigned(False, 'aValue');
  AssertTrue('NoContracts build should treat ContractsRequireAssigned as no-op', True);
  {$ENDIF}
end;

initialization
  RegisterTest(TTestCoreContracts);

end.
