unit fafafa.core.tick;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.time.tick;

type
  // Type re-exports for backward compatibility
  TTickProviderType = fafafa.core.time.tick.TTickProviderType;
  TTickProviderTypeArray = fafafa.core.time.tick.TTickProviderTypeArray;
  ITick = fafafa.core.time.tick.ITick;
  ITickProvider = fafafa.core.time.tick.ITickProvider;

  // Exception type re-exports
  ETickError = fafafa.core.time.tick.ETickError;
  ETickProviderNotAvailable = fafafa.core.time.tick.ETickProviderNotAvailable;
  ETickInvalidArgument = fafafa.core.time.tick.ETickInvalidArgument;

// Factory re-exports
function CreateTickProvider(const AProviderType: TTickProviderType): ITickProvider; inline;
function CreateDefaultTick: ITick; inline;
function GetAvailableProviders: TTickProviderTypeArray; inline;

implementation

function CreateTickProvider(const AProviderType: TTickProviderType): ITickProvider;
begin
  Result := fafafa.core.time.tick.CreateTickProvider(AProviderType);
end;

function CreateDefaultTick: ITick;
begin
  Result := fafafa.core.time.tick.CreateDefaultTick;
end;

function GetAvailableProviders: TTickProviderTypeArray;
begin
  Result := fafafa.core.time.tick.GetAvailableProviders;
end;

end.

