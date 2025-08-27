{$CODEPAGE UTF8}
unit Test_ghash_clmul_bench;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.crypto.aead.gcm.ghash;

type
  TTestCase_GHASH_CLMUL_Bench = class(TTestCase)
  published
    procedure Bench_1MB_and_8MB_MBps_Report;
  end;

implementation

uses
  fafafa.core.benchmark.format_utils;

procedure AppendBenchLine(const Line: string);
var baseDir, reports: string;
begin
  baseDir := ExtractFileDir(ParamStr(0));
  reports := IncludeTrailingPathDelimiter(baseDir) + 'reports';
  if not DirectoryExists(reports) then SysUtils.ForceDirectories(reports);
  WriteTextUTF8(IncludeTrailingPathDelimiter(reports) + 'ghash_clmul_bench.txt', Line + LineEnding, True);
end;

procedure AppendBenchCsvLine(const LabelName, Impl: string; SizeBytes, DtMs: Integer; Mbps: Double);
var baseDir, reports, f: string; line: string; needHeader: Boolean;
begin
  baseDir := ExtractFileDir(ParamStr(0));
  reports := IncludeTrailingPathDelimiter(baseDir) + 'reports';
  if not DirectoryExists(reports) then SysUtils.ForceDirectories(reports);
  f := IncludeTrailingPathDelimiter(reports) + 'ghash_clmul_bench.csv';
  needHeader := not FileExists(f);
  if needHeader then
    WriteTextUTF8(f, 'timestamp,label,impl,size_bytes,dt_ms,mbps' + LineEnding, True);
  line := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + ',' +
          CsvEscape(LabelName) + ',' + CsvEscape(Impl) + ',' +
          IntToStr(SizeBytes) + ',' + IntToStr(DtMs) + ',' + FmtFixed(Mbps, 2);
  WriteTextUTF8(f, line + LineEnding, True);
end;


function NowMs: QWord; inline;
begin
  Result := GetTickCount64;
end;

procedure RunOneBench(const LabelName: string; SizeBytes: Integer);
var
  H, Data, S: TBytes; GH: IGHash; t0, t1: QWord; dt_ms: QWord; mbps: Double;
begin
  SetLength(H, 16); FillChar(H[0], 16, 0);
  SetLength(Data, SizeBytes);
  if SizeBytes > 0 then FillChar(Data[0], SizeBytes, 1);

  AppendBenchLine(Format('[GHASH] bench start %s', [FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now)]));

  // CLMUL first (if requested)
{$IFDEF FAFAFA_CRYPTO_X86_CLMUL}
  if SameText(GetEnvironmentVariable('FAFAFA_GHASH_IMPL'), 'clmul') then
  begin
    GHash_SelectBackend(1);
    GH := CreateGHash; GH.Init(H);
    t0 := NowMs; GH.Update(Data); S := GH.Finalize(0, Length(Data)); t1 := NowMs;
    dt_ms := t1 - t0; if dt_ms = 0 then dt_ms := 1;
    mbps := (Length(Data) / 1048576.0) / (dt_ms / 1000.0);
    AppendBenchLine('[GHASH][CLMUL] ' + LabelName + ': ' + FormatFloat('0.00', mbps) + ' MB/s');
    AppendBenchCsvLine(LabelName, 'clmul', SizeBytes, dt_ms, mbps);
  end;
{$ENDIF}

  // Pure
  GHash_SelectBackend(0);
  GH := CreateGHash; GH.Init(H);
  t0 := NowMs; GH.Update(Data); S := GH.Finalize(0, Length(Data)); t1 := NowMs;
  dt_ms := t1 - t0; if dt_ms = 0 then dt_ms := 1;
  mbps := (Length(Data) / 1048576.0) / (dt_ms / 1000.0);
  AppendBenchLine('[GHASH][Pure] ' + LabelName + ': ' + FormatFloat('0.00', mbps) + ' MB/s');
  AppendBenchCsvLine(LabelName, 'pure', SizeBytes, dt_ms, mbps);
end;

procedure TTestCase_GHASH_CLMUL_Bench.Bench_1MB_and_8MB_MBps_Report;
begin
  {$IFDEF FAFAFA_CRYPTO_X86_CLMUL}
  AppendBenchLine('----');
  RunOneBench('1MB', 1*1024*1024);
  RunOneBench('8MB', 8*1024*1024);
  AppendBenchLine('----');
  {$ELSE}
  // 宏未启用则跳过性能报告
  {$ENDIF}
end;

initialization
  RegisterTest(TTestCase_GHASH_CLMUL_Bench);

end.

