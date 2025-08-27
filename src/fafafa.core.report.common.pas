unit fafafa.core.report.common;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, DateUtils;

// Cross-cutting helpers for reporting/sinks across test/benchmark/logging
// Keep minimal and portable.

function GetHostNameCross: string;
// RFC3339 with 'Z' suffix. If UseUTC=True, convert local time to UTC; otherwise
// use local time directly (legacy behavior in some reporters).
function FormatRFC3339Zulu(const ALocalNow: TDateTime; const PrecMs: boolean; const UseUTC: boolean): string;
// 64-bit FNV-1a hash (stable) for CaseId/RunId derivation
function Hash64FNV1a(const S: string): QWord;

implementation

function GetHostNameCross: string;
var s: string;
begin
  // Try common environment variables first
  s := GetEnvironmentVariable('COMPUTERNAME');
  if s = '' then s := GetEnvironmentVariable('HOSTNAME');
  if s = '' then s := 'localhost';
  Result := s;
end;

function FormatRFC3339Zulu(const ALocalNow: TDateTime; const PrecMs: boolean; const UseUTC: boolean): string;
var dt: TDateTime;
const
  FMT_SEC = 'yyyy"-"mm"-"dd"T"hh":"nn":"ss"Z"';
  FMT_MS  = 'yyyy"-"mm"-"dd"T"hh":"nn":"ss"."zzz"Z"';
begin
  if UseUTC then
    dt := IncMinute(ALocalNow, -GetLocalTimeOffset())
  else
    dt := ALocalNow;
  if PrecMs then
    Result := FormatDateTime(FMT_MS, dt)
  else
    Result := FormatDateTime(FMT_SEC, dt);
end;

function Hash64FNV1a(const S: string): QWord;
const
  FNV_OFFSET_BASIS_64: QWord = QWord($CBF29CE484222325);
  FNV_PRIME_64: QWord = QWord($00000100000001B3);
var
  i: Integer;
  h: QWord;
  c: Byte;
begin
  h := FNV_OFFSET_BASIS_64;
  for i := 1 to Length(S) do
  begin
    c := Byte(Ord(S[i]) and $FF);
    h := h xor c;
    h := h * FNV_PRIME_64;
  end;
  Result := h;
end;

end.

