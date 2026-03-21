unit fafafa.core.simd.public_smoke_support;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$CODEPAGE UTF8}

interface

uses
  fafafa.core.simd.base;

function GetExpectedPublicSmokeDefaultBackend: TSimdBackend;

implementation

uses
  fafafa.core.simd.dispatch;

function GetExpectedPublicSmokeDefaultBackend: TSimdBackend;
begin
  Result := GetBestDispatchableBackend;
end;

end.
