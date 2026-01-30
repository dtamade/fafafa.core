unit fafafa.core.lockfree.channel.wait;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.lockfree.ifaces;

type
  generic TChannelArray<T> = array of specialize ILockFreeChannel<T>;

function NowMicroseconds: Int64; inline;
function ComputeDeadline(aTimeoutUs: Int64): Int64; inline;
function IsDeadlineExpired(aDeadline: Int64): Boolean; inline;

generic function WaitAnyReceiveReady<T>(const aChannels: specialize TChannelArray<T>; aTimeoutUs: Int64 = -1): SizeInt;
generic function WaitAnySendReady<T>(const aChannels: specialize TChannelArray<T>; aTimeoutUs: Int64 = -1): SizeInt;

implementation

function NowMicroseconds: Int64; inline;
begin
  Result := Int64(GetTickCount64) * 1000;
end;

function ComputeDeadline(aTimeoutUs: Int64): Int64; inline;
begin
  if aTimeoutUs < 0 then
    Exit(-1);
  Result := NowMicroseconds + aTimeoutUs;
end;

function IsDeadlineExpired(aDeadline: Int64): Boolean; inline;
begin
  Result := (aDeadline >= 0) and (NowMicroseconds >= aDeadline);
end;

generic function WaitAnyReceiveReady<T>(const aChannels: specialize TChannelArray<T>; aTimeoutUs: Int64): SizeInt;
var
  LDeadline: Int64;
  i: SizeInt;
begin
  if Length(aChannels) = 0 then
    raise Exception.Create('WaitAnyReceiveReady: channel array is empty');
  LDeadline := ComputeDeadline(aTimeoutUs);
  repeat
    for i := 0 to High(aChannels) do
    begin
      if (aChannels[i] <> nil) and aChannels[i].WaitReceiveReady(0) then
        Exit(i);
    end;
    if IsDeadlineExpired(LDeadline) then
      Exit(-1);
    Sleep(0);
  until False;
end;

generic function WaitAnySendReady<T>(const aChannels: specialize TChannelArray<T>; aTimeoutUs: Int64): SizeInt;
var
  LDeadline: Int64;
  i: SizeInt;
begin
  if Length(aChannels) = 0 then
    raise Exception.Create('WaitAnySendReady: channel array is empty');
  LDeadline := ComputeDeadline(aTimeoutUs);
  repeat
    for i := 0 to High(aChannels) do
    begin
      if (aChannels[i] <> nil) and aChannels[i].WaitSendReady(0) then
        Exit(i);
    end;
    if IsDeadlineExpired(LDeadline) then
      Exit(-1);
    Sleep(0);
  until False;
end;

end.
