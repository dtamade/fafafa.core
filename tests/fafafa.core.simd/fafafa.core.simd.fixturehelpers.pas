unit fafafa.core.simd.fixturehelpers;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  fafafa.core.simd.base;

type
  TSimdSavedBackendState = record
    Backend: TSimdBackend;
  end;

procedure SaveActiveBackendState(out aState: TSimdSavedBackendState);
function RestoreSavedBackendState(aOriginalBackend: TSimdBackend): Boolean;
function RestoreSavedBackendAndVectorAsmState(aOriginalVectorAsm: Boolean;
  aOriginalBackend: TSimdBackend): Boolean;

implementation

uses
  fafafa.core.simd,
  fafafa.core.simd.dispatch;

procedure SaveActiveBackendState(out aState: TSimdSavedBackendState);
begin
  GetDispatchTable;
  aState.Backend := GetActiveBackend;
end;

function RestoreSavedBackendState(aOriginalBackend: TSimdBackend): Boolean;
begin
  ResetToAutomaticBackend;
  if GetCurrentBackend = aOriginalBackend then
    Exit(True);

  Result := TrySetActiveBackend(aOriginalBackend);
end;

function RestoreSavedBackendAndVectorAsmState(aOriginalVectorAsm: Boolean;
  aOriginalBackend: TSimdBackend): Boolean;
begin
  SetVectorAsmEnabled(aOriginalVectorAsm);
  Result := RestoreSavedBackendState(aOriginalBackend);
end;

end.
