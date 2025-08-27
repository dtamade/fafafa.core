{$CODEPAGE UTF8}
program play_bench_ids;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils, DateUtils,
  fafafa.core.id, fafafa.core.id.ulid, fafafa.core.id.ksuid, fafafa.core.id.snowflake,
  fafafa.core.id.codec;

function TimeItMs(const Name: string; const Fn: TProc): Int64;
var t0, t1: TDateTime;
begin
  t0 := Now;
  Fn();
  t1 := Now;
  Result := MilliSecondsBetween(t1, t0);
  WriteLn(Name, ' took ', Result, ' ms');
end;

procedure BenchIDs(Count: Integer);
var
  i: Integer;
  g: ISnowflake;
  id: TSnowflakeID;
  r: TUuid128;
  u: TUlid128;
  k: TKsuid160;
  s: string;
begin
  g := CreateSnowflake(1);
  TimeItMs('Snowflake NextID x'+IntToStr(Count),
    procedure begin for i := 1 to Count do id := g.NextID; end);
  TimeItMs('UUID v7 string x'+IntToStr(Count),
    procedure begin for i := 1 to Count do s := UuidV7; end);
  TimeItMs('ULID string x'+IntToStr(Count),
    procedure begin for i := 1 to Count do s := Ulid; end);
  TimeItMs('KSUID string x'+IntToStr(Count),
    procedure begin for i := 1 to Count do s := Ksuid; end);
end;

procedure BenchEncodings(Count: Integer);
var i: Integer; r: TUuid128; u: TUlid128; k: TKsuid160; s: string;
begin
  r := UuidV4_Raw; u := Ulid_Raw(1730000000123); k := Ksuid_Raw(1730000000);
  TimeItMs('UUID Base64URL x'+IntToStr(Count),
    procedure begin for i := 1 to Count do s := UuidToBase64Url(r); end);
  TimeItMs('ULID Base58 x'+IntToStr(Count),
    procedure begin for i := 1 to Count do s := UlidToBase58(u); end);
  TimeItMs('KSUID Base58 x'+IntToStr(Count),
    procedure begin for i := 1 to Count do s := KsuidToBase58(k); end);
end;

procedure BenchBatch(Count: Integer);
var arr: TUuid128Array;
begin
  SetLength(arr, Count);
  TimeItMs('UUID v7 FillRawN x'+IntToStr(Count),
    procedure begin UuidV7_FillRawN(arr); end);
  TimeItMs('UUID v4 FillRawN x'+IntToStr(Count),
    procedure begin UuidV4_FillRawN(arr); end);
end;

begin
  // defaults
  var nIds := 100000;
  var nEnc := 20000;
  var nBatch := 100000;
  // parse simple args: --nIds=, --nEnc=, --nBatch=
  if ParamCount >= 1 then
  begin
    var i: Integer;
    for i := 1 to ParamCount do
    begin
      if AnsiStartsText('--nIds=', ParamStr(i)) then
        nIds := StrToIntDef(Copy(ParamStr(i), 8, MaxInt), nIds)
      else if AnsiStartsText('--nEnc=', ParamStr(i)) then
        nEnc := StrToIntDef(Copy(ParamStr(i), 8, MaxInt), nEnc)
      else if AnsiStartsText('--nBatch=', ParamStr(i)) then
        nBatch := StrToIntDef(Copy(ParamStr(i), 10, MaxInt), nBatch);
    end;
  end;
  WriteLn('bench ids... nIds=', nIds);
  BenchIDs(nIds);
  WriteLn('bench encodings... nEnc=', nEnc);
  BenchEncodings(nEnc);
  WriteLn('bench batch... nBatch=', nBatch);
  BenchBatch(nBatch);
end.

