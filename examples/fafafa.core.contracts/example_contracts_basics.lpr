program example_contracts_basics;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.base,
  fafafa.core.contracts;

procedure DemoHappyPath;
var
  LValue: Pointer;
begin
  WriteLn('=== happy path ===');
  LValue := Pointer(PtrUInt(1));
  ContractsRequire(True, 'should not raise');
  ContractsRequireAssigned(LValue <> nil, 'LValue');
  WriteLn('preconditions passed');
  WriteLn;
end;

procedure DemoExceptionalPath;
begin
  WriteLn('=== exceptional path ===');
  try
    ContractsRequire(False, 'demo failure');
  except
    on LE: EInvalidArgument do
      WriteLn('ContractsRequire raised: ', LE.Message);
  end;

  try
    ContractsRequireAssigned(False, 'aCallback');
  except
    on LE: EArgumentNil do
      WriteLn('ContractsRequireAssigned raised: ', LE.Message);
  end;
  WriteLn;
end;

begin
  WriteLn('fafafa.core.contracts example');
  WriteLn('=============================');
  WriteLn;
  DemoHappyPath;
  {$IFDEF FAFAFA_CORE_CONTRACTS}
  DemoExceptionalPath;
  {$ELSE}
  WriteLn('contracts are disabled in this build; exceptional path is a no-op.');
  {$ENDIF}
end.
