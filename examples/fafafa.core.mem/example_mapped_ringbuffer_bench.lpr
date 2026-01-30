program example_mapped_ringbuffer_bench;
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils, Classes, Math, fafafa.core.mem.mappedRingBuffer,
  fafafa.core.mem.mappedRingBuffer.sharded;

function NowMs: QWord; inline;
begin
  Result := GetTickCount64;
end;

function OSName: string;
begin
  {$IFDEF WINDOWS}
  Result := 'Windows';
  {$ELSEIF DEFINED(LINUX)}
  Result := 'Linux';
  {$ELSEIF DEFINED(DARWIN)}
  Result := 'macOS';
  {$ELSE}
  Result := 'UnknownOS';
  {$ENDIF}
end;

function CompilerVer: string;
begin
  {$IFDEF FPC}
  Result := 'FPC ' + IntToStr(FPC_VERSION) + '.' + IntToStr(FPC_RELEASE) + '.' + IntToStr(FPC_PATCH);
  {$ELSE}
  Result := 'UnknownCompiler';
  {$ENDIF}
end;

function CPUCount: Integer;
begin
  try
    CPUCount := TThread.ProcessorCount;
  except
    CPUCount := 0;
  end;
end;


procedure EnsureDir(const P: string);
begin
  if (P <> '') and (not DirectoryExists(P)) then ForceDirectories(P);
end;

function RunPingPong(const Name: string; Capacity: UInt64; ElemSize: UInt32;
  MsgCount: Integer; BatchSize: Integer; Shards: Integer): QWord;
var
  creator: TMappedRingBuffer;
  opener: TMappedRingBuffer;
  creatorS: TMappedRingBufferSharded;
  openerS: TMappedRingBufferSharded;
  i, j, v: Integer;
begin
  if Shards <= 1 then
  begin
    creator := TMappedRingBuffer.Create;
    opener := TMappedRingBuffer.Create;
    try
      if not creator.CreateShared(Name, Capacity, ElemSize) then
        raise Exception.Create('CreateShared failed');
      if not opener.OpenShared(Name) then
        raise Exception.Create('OpenShared failed');

    i := 0;
    Result := NowMs;
    while i < MsgCount do
    begin
      // A->B 批量
      for j := 1 to BatchSize do
      begin
        if i >= MsgCount then Break;
        v := (i+1) * 7;
        while not creator.Push(@v) do ;
        Inc(i);
      end;
      // B 消费并立即回复（B->A）
      for j := 1 to BatchSize do
      begin
        if (i - (j-1)) <= 0 then Break; // 防御
        while not opener.Pop(@v) do ;
        Inc(v);
        while not opener.Push(@v) do ;
      end;
      // A 接收回包
      for j := 1 to BatchSize do
      begin
        if (i - (j-1)) <= 0 then Break;
        while not creator.Pop(@v) do ;
      end;
    end;
    Result := NowMs - Result;
  finally
    opener.Free;
    creator.Free;
  end;
  end
  else
  begin
    creatorS := TMappedRingBufferSharded.Create;
    openerS := TMappedRingBufferSharded.Create;
    try
      if not creatorS.CreateShared(Name, Shards, Capacity, ElemSize) then
        raise Exception.Create('CreateShared(sharded) failed');
      if not openerS.OpenShared(Name, Shards) then
        raise Exception.Create('OpenShared(sharded) failed');

      i := 0;
      Result := NowMs;
      while i < MsgCount do
      begin
        for j := 1 to BatchSize do
        begin
          if i >= MsgCount then Break;
          v := (i+1) * 7;
          while not creatorS.Push(@v) do ;
          Inc(i);
        end;
        for j := 1 to BatchSize do
        begin
          if (i - (j-1)) <= 0 then Break;
          while not openerS.Pop(@v) do ;
          Inc(v);
          while not openerS.Push(@v) do ;
        end;
        for j := 1 to BatchSize do
        begin
          if (i - (j-1)) <= 0 then Break;
          while not openerS.Pop(@v) do ;
        end;
      end;
      Result := NowMs - Result;
    finally
      openerS.Free;
      creatorS.Free;
    end;
  end;
end;

end;

procedure AppendCSV(const FilePath: string; const Line: string);
var
  F: TextFile;
begin
  if not FileExists(FilePath) then
  begin
    AssignFile(F, FilePath);
    Rewrite(F);
    Writeln(F, '# host_os=', OSName, ', compiler=', CompilerVer, ', cpus=', CPUCount);
    Writeln(F, 'capacity,elem_size,msg_count,batch_size,run_count,time_ms_avg,time_ms_median,time_ms_std,qps_avg,qps_median,qps_std');
  end
  else
  begin
    AssignFile(F, FilePath);
    Append(F);
  end;
  try
    Writeln(F, Line);
  finally
    CloseFile(F);
  end;

procedure AppendCSVPerElem(ElemSize: UInt32; const Line: string);
const
  CSV_DIR = 'bench_out';
var
  Path: string;
begin
  EnsureDir(CSV_DIR + DirectorySeparator);
  Path := CSV_DIR + DirectorySeparator + Format('mrb_bidir_bench_e%d.csv', [ElemSize]);
  AppendCSV(Path, Line);
end;

procedure InsertionSortQWord(var A: array of QWord);
var i, j: Integer; key: QWord;
begin
  for i := 1 to High(A) do
  begin
    key := A[i];
    j := i - 1;
    while (j >= 0) and (A[j] > key) do
    begin
      A[j+1] := A[j];
      Dec(j);
    end;
    A[j+1] := key;
  end;
end;

function Median_ms(const A: array of QWord): Double;
var tmp: array of QWord; n: Integer;
begin
  n := Length(A);
  if n = 0 then Exit(0);
  SetLength(tmp, n);
  Move(A[0], tmp[0], n*SizeOf(QWord));
  InsertionSortQWord(tmp);
  if (n and 1) = 1 then Result := tmp[n div 2]
  else Result := (tmp[n div 2 - 1] + tmp[n div 2]) / 2.0;
end;

function StdDev_ms(const A: array of QWord; Avg: Double): Double;
var i: Integer; s: Double;
begin
  if Length(A) = 0 then Exit(0);
  s := 0;
  for i := 0 to High(A) do s := s + Sqr(A[i] - Avg);
  Result := Sqrt(s / Length(A));
end;

function Avg_ms(const A: array of QWord): Double;
var i: Integer; s: QWord;
begin
  if Length(A)=0 then Exit(0);
  s := 0;
  for i := 0 to High(A) do s := s + A[i];
  Result := s / Length(A);
end;

procedure Bench;
const
  CSV_PATH = 'bench_out' + DirectorySeparator + 'mrb_bidir_bench.csv';
var
  Caps: array[0..2] of UInt64 = (4096, 65536, 262144);
  Batches: array[0..3] of Integer = (1, 16, 64, 256);
  MsgCounts: array[0..1] of Integer = (100000, 500000);
  ElemSizes: array[0..2] of UInt32 = (4, 8, 16);
  ci, bi, mi, ei: Integer;
  k, w: Integer;
  name: string;
  ms: QWord;
  line: string;
  times: array of QWord;
  qpsArr: array of Double; // reserved
  avg, med, std: Double;
  avgQ, medQ, stdQ: Double;
begin
  EnsureDir(ExtractFilePath(CSV_PATH));
  // 解析可选参数：runs, warmup
  var Runs: Integer = 5;
  var Warmup: Integer = 1;
  if ParamCount >= 2 then Runs := StrToIntDef(ParamStr(2), Runs);
  if ParamCount >= 3 then Warmup := StrToIntDef(ParamStr(3), Warmup);

  for ci := Low(Caps) to High(Caps) do
  begin
    for ei := Low(ElemSizes) to High(ElemSizes) do
    begin
      for mi := Low(MsgCounts) to High(MsgCounts) do
      begin
        for bi := Low(Batches) to High(Batches) do
        begin
          name := 'MRB_Bench_' + IntToHex(Random(MaxInt), 8);
          // 预热
          for w := 1 to Warmup do
            ms := RunPingPong(name, Caps[ci], ElemSizes[ei], MsgCounts[mi], Batches[bi], 1);
          // 多次运行，统计
          SetLength(times, Runs);
          for k := 0 to Runs-1 do
            times[k] := RunPingPong(name, Caps[ci], ElemSizes[ei], MsgCounts[mi], Batches[bi], 1);
          avg := Avg_ms(times);
          med := Median_ms(times);
          std := StdDev_ms(times, avg);
          avgQ := (MsgCounts[mi] * 2) / (avg / 1000.0);
          medQ := (MsgCounts[mi] * 2) / (med / 1000.0);
          stdQ := (MsgCounts[mi] * 2) / ((avg + std) / 1000.0) - avgQ;
          line := Format('%d,%d,%d,%d,%d,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f',
            [Caps[ci], ElemSizes[ei], MsgCounts[mi], Batches[bi], Runs, avg, med, std, avgQ, medQ, stdQ]);
          Writeln(line);
          AppendCSV(CSV_PATH, line);
          AppendCSVPerElem(ElemSizes[ei], line);
        end;
      end;
    end;
  end;
  Writeln('Results appended to ', CSV_PATH, ' and per-element CSVs');
end;

var
  Quick: Boolean = False;
begin
  Randomize;
  if (ParamCount >= 1) and (LowerCase(ParamStr(1)) = 'quick') then Quick := True;
  if Quick then
  begin
    // 快速模式：一组中等参数
    AppendCSV('bench_out' + DirectorySeparator + 'mrb_bidir_bench.csv', ''); // ensure header
    RunPingPong('MRB_Quick_' + IntToHex(Random(MaxInt), 8), 65536, 4, 50000, 32, QWord(Quick));
  end
  else
    Bench;
end.

