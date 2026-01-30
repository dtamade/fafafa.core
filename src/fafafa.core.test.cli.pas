unit fafafa.core.test.cli;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

function CliHasFlag(const aFlag: string): Boolean; // case-insensitive exact match
function CliTryGetValue(const aKey: string; out aValue: string): Boolean; // expects --key=value
function CliIsHelpRequested: Boolean; // --help or -h or /?

implementation

uses SysUtils;

function CliHasFlag(const aFlag: string): Boolean;
var
  I: Integer;
begin
  for I := 1 to ParamCount do
    if SameText(ParamStr(I), aFlag) then Exit(True);
  Result := False;
end;

function CliTryGetValue(const aKey: string; out aValue: string): Boolean;
var
  I, L: Integer;
  S, K: string;
begin
  K := aKey;
  if (Length(K) > 0) and (K[1] <> '-') then
    K := '--' + K; // normalize to --key
  K := K + '=';
  L := Length(K);
  for I := 1 to ParamCount do
  begin
    S := ParamStr(I);
    if (Length(S) > L) and SameText(Copy(S, 1, L), K) then
    begin
      aValue := Copy(S, L+1, MaxInt);
      Exit(True);
    end;
  end;
  aValue := '';
  Result := False;
end;

function CliIsHelpRequested: Boolean;
begin
  Result := CliHasFlag('--help') or CliHasFlag('-h') or CliHasFlag('/?');
end;

end.

