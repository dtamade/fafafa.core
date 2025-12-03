unit fafafa.core.lockfree.channel.select;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.lockfree.ifaces,
  fafafa.core.lockfree.channel.wait;

generic function ChannelSelectReceive<T>(const aChannels: array of specialize ILockFreeChannel<T>;
  out aValue: T; aTimeoutUs: Int64 = -1): SizeInt;
generic function ChannelSelectSend<T>(const aChannels: array of specialize ILockFreeChannel<T>;
  const aValues: array of T; aTimeoutUs: Int64 = -1): SizeInt;

implementation

generic function ChannelSelectReceive<T>(const aChannels: array of specialize ILockFreeChannel<T>;
  out aValue: T; aTimeoutUs: Int64): SizeInt;
var
  LIndex: SizeInt;
begin
  LIndex := fafafa.core.lockfree.channel.wait.WaitAnyReceiveReady<T>(aChannels, aTimeoutUs);
  if LIndex < 0 then
    Exit(-1);
  if (aChannels[LIndex] = nil) or (aChannels[LIndex].Receive(aValue, 0) <> rrOk) then
    Exit(-1);
  Result := LIndex;
end;

generic function ChannelSelectSend<T>(const aChannels: array of specialize ILockFreeChannel<T>;
  const aValues: array of T; aTimeoutUs: Int64): SizeInt;
var
  LIndex: SizeInt;
begin
  if Length(aChannels) <> Length(aValues) then
    raise EInvalidArgument.Create('ChannelSelectSend: channels and values length mismatch');
  LIndex := fafafa.core.lockfree.channel.wait.WaitAnySendReady<T>(aChannels, aTimeoutUs);
  if LIndex < 0 then
    Exit(-1);
  if (aChannels[LIndex] = nil) or (aChannels[LIndex].Send(aValues[LIndex], 0) <> srOk) then
    Exit(-1);
  Result := LIndex;
end;

end.

