unit fafafa.core.lockfree.channel.select;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.base,
  fafafa.core.lockfree.ifaces,
  fafafa.core.lockfree.channel.wait;

generic function ChannelSelectReceive<T>(const aChannels: specialize TChannelArray<T>;
  out aValue: T; aTimeoutUs: Int64 = -1): SizeInt;
generic function ChannelSelectSend<T>(const aChannels: specialize TChannelArray<T>;
  const aValues: array of T; aTimeoutUs: Int64 = -1): SizeInt;

implementation

generic function ChannelSelectReceive<T>(const aChannels: specialize TChannelArray<T>;
  out aValue: T; aTimeoutUs: Int64): SizeInt;
var
  LIndex: SizeInt;
begin
  LIndex := specialize WaitAnyReceiveReady<T>(aChannels, aTimeoutUs);
  if LIndex < 0 then
    Exit(-1);
  if (aChannels[LIndex] = nil) or (aChannels[LIndex].Receive(aValue, 0) <> rrOk) then
    Exit(-1);
  Result := LIndex;
end;

generic function ChannelSelectSend<T>(const aChannels: specialize TChannelArray<T>;
  const aValues: array of T; aTimeoutUs: Int64): SizeInt;
var
  LIndex: SizeInt;
begin
  if Length(aChannels) <> Length(aValues) then
    raise EInvalidArgument.Create('ChannelSelectSend: channels and values length mismatch');
  LIndex := specialize WaitAnySendReady<T>(aChannels, aTimeoutUs);
  if LIndex < 0 then
    Exit(-1);
  if (aChannels[LIndex] = nil) or (aChannels[LIndex].Send(aValues[LIndex], 0) <> srOk) then
    Exit(-1);
  Result := LIndex;
end;

end.

