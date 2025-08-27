program toml_bench;

{$mode objfpc}{$H+}
{$I ../../fafafa.core.settings.inc}

uses
  SysUtils, DateUtils, fafafa.core.toml;

function NowNs: Int64;
var t: TDateTime;
begin
  t := Now;
  // 粗略转换：毫秒->纳秒（用于相对比较，非精准）
  Result := MilliSecondsBetween(t, 0) * 1000 * 1000;
end;

procedure ComputeMedianP90(var A: array of Int64; Count: Integer; out Median, P90: Int64);
var
  i, j: Integer;
  tmp: Int64;
begin
  // 简单插入排序（Count 通常较小）
  for i := 1 to Count - 1 do
  begin
    tmp := A[i]; j := i - 1;
    while (j >= 0) and (A[j] > tmp) do begin A[j+1] := A[j]; Dec(j); end;
    A[j+1] := tmp;
  end;
  if Count <= 0 then begin Median := 0; P90 := 0; Exit; end;
  if (Count and 1) = 1 then Median := A[Count div 2]
  else Median := (A[Count div 2 - 1] + A[Count div 2]) div 2;
  // p90 采用上取整位置（1-based）：ceil(0.9*n)
  j := ((Count * 9) + 9) div 10; // ceil
  if j < 1 then j := 1; if j > Count then j := Count;
  P90 := A[j - 1];
end;

procedure BenchWriter(const KeyCount, Depth, AoTItems: Integer; const WriteFlags: TTomlWriteFlags;
  out P50, P90: Int64; out OutBytes: Integer);
const
  MaxIters = 11;
var
  i, iter: Integer;
  B: ITomlBuilder;
  D: ITomlDocument;
  startNs, endNs: Int64;
  path, key: String;
  outS: RawByteString;
  times: array[0..MaxIters-1] of Int64;
  med, p90v: Int64;
begin
  B := NewDoc;
  // 深层子表
  path := 'root';
  for i := 1 to Depth do
  begin
    B.BeginTable(path).EndTable;
    path := path + '.sub' + IntToStr(i);
  end;
  // 标量键
  B.BeginTable('root');
  for i := 1 to KeyCount do
  begin
    key := 'k' + IntToStr(i);
    if (i and 3) = 0 then B.PutInt(key, i)
    else if (i and 3) = 1 then B.PutStr(key, 'v'+IntToStr(i))
    else if (i and 3) = 2 then B.PutBool(key, (i and 1)=0)
    else B.PutFloat(key, i/3.0);
  end;
  B.EndTable;
  // AoT
  if AoTItems > 0 then
  begin
    B.EnsureArray('root.items');
    for i := 1 to AoTItems do
    begin
      B.PushTable('root.items').PutInt('id', i).EndTable;
    end;
  end;
  D := B.Build;
  // 多次测量收集中位数与P90
  for iter := 0 to MaxIters-1 do
  begin
    startNs := NowNs;
    outS := ToToml(D, WriteFlags);
    endNs := NowNs;
    times[iter] := (endNs - startNs);
  end;
  ComputeMedianP90(times, MaxIters, med, p90v);
  OutBytes := Length(outS);
  P50 := med; P90 := p90v;
  Writeln('Writer: keys=', KeyCount, ' depth=', Depth, ' aot=', AoTItems,
          ' bytes=', OutBytes, ' p50(ns)=', P50, ' p90(ns)=', P90);
end;

procedure BenchReader(const KeyCount, Depth, AoTItems: Integer; const WriteFlags: TTomlWriteFlags;
  const BigReader: Boolean; out P50, P90: Int64; out Size: Integer);
const
  MaxIters = 11;
var
  B: ITomlBuilder; D: ITomlDocument; txt: RawByteString; Err: TTomlError;
  startNs, endNs: Int64;
  times: array[0..MaxIters-1] of Int64; med, p90v: Int64;
  iter, i, j: Integer;
  path, key: String;
  kCount, aCount, dCount: Integer;
begin
  // 构造较大的可解析文本（避免重复键冲突）
  if BigReader then begin kCount := KeyCount * 2; aCount := AoTItems * 2; dCount := Depth + 2; end
  else begin kCount := KeyCount; aCount := AoTItems; dCount := Depth; end;

  B := NewDoc;
  // 深层结构
  path := 'root';
  for i := 1 to dCount do begin B.BeginTable(path).EndTable; path := path + '.sub' + IntToStr(i); end;
  // root 标量
  B.BeginTable('root');
  for i := 1 to kCount do
  begin
    key := 'rk' + IntToStr(i);
    case i and 3 of
      0: B.PutInt(key, i);
      1: B.PutStr(key, 'v'+IntToStr(i));
      2: B.PutBool(key, (i and 1)=0);
    else B.PutFloat(key, i/3.0);
    end;
  end;
  B.EndTable;
  // AoT
  if aCount > 0 then
  begin
    B.EnsureArray('root.items');
    for j := 1 to aCount do begin B.PushTable('root.items').PutInt('id', j).EndTable; end;
  end;

  D := B.Build;
  txt := ToToml(D, WriteFlags);
  Err.Clear;
  for iter := 0 to MaxIters-1 do
  begin
    startNs := NowNs;
    if not Parse(txt, D, Err) then Writeln('Parse failed: ', Err.ToString);
    endNs := NowNs;
    times[iter] := (endNs - startNs);
  end;
  ComputeMedianP90(times, MaxIters, med, p90v);
  Size := Length(txt);
  P50 := med; P90 := p90v;
  Writeln('Reader: size=', Size, ' p50(ns)=', P50, ' p90(ns)=', P90);
end;

var
  keys, depth, aot: Integer;
  flags, csvPath, bigReaderStr, commit, runId, remark: String;
  usePretty, useSort, useSpaced: Boolean;
  wf: TTomlWriteFlags;
  useBigReader: Boolean;
  wP50, wP90, rP50, rP90: Int64;
  outBytes, inBytes: Integer;
  csv: Text;
  csvName: String; needHeader: Boolean; sr: TSearchRec;
begin
  keys := 2000; depth := 6; aot := 500;
  flags := 'ps'; // p=pretty, s=sort, e=spaces-around-equals
  if ParamCount >= 1 then Val(ParamStr(1), keys);
  if ParamCount >= 2 then Val(ParamStr(2), depth);
  if ParamCount >= 3 then Val(ParamStr(3), aot);
  if ParamCount >= 4 then flags := ParamStr(4) else flags := 'ps';
  // 可选参数：第5个参数为 --csv=path；第6个参数为 --bigreader=true/false；第7个参数为 --runid=...；第8个参数为 --remark=...
  if ParamCount >= 5 then csvPath := ParamStr(5) else csvPath := '';
  if ParamCount >= 6 then bigReaderStr := ParamStr(6) else bigReaderStr := '';
  if ParamCount >= 7 then runId := ParamStr(7) else runId := '';
  if ParamCount >= 8 then remark := ParamStr(8) else remark := '';

  usePretty := Pos('p', flags) > 0;
  useSort := Pos('s', flags) > 0;
  useSpaced := Pos('e', flags) > 0;

  wf := [];
  if usePretty then Include(wf, twfPretty);
  if useSort then Include(wf, twfSortKeys);
  if useSpaced then Include(wf, twfSpacesAroundEquals);

  useBigReader := (Pos('true', LowerCase(bigReaderStr)) > 0);

  commit := GetEnvironmentVariable('GIT_COMMIT');
  Writeln('TOML microbench (relative)');
  Writeln('args: keys=', keys, ' depth=', depth, ' aot=', aot, ' flags=', flags,
          ' csv=', csvPath, ' bigReader=', useBigReader, ' commit=', commit,
          ' runId=', runId, ' remark=', remark);

  // Writer bench with selected flags (p50/p90)
  BenchWriter(keys, depth, aot, wf, wP50, wP90, outBytes);
  // Reader bench (p50/p90)
  BenchReader(keys, depth, aot, wf, useBigReader, rP50, rP90, inBytes);

  if (csvPath <> '') and (Copy(csvPath, 1, 6) = '--csv=') then
  begin
    csvName := Copy(csvPath, 7, MaxInt);
    needHeader := True;
    if FileExists(csvName) then
    begin
      if FindFirst(csvName, faAnyFile, sr) = 0 then
      begin
        needHeader := (sr.Size = 0);
        FindClose(sr);
      end
      else
        needHeader := True;
      Assign(csv, csvName);
      {$I-} Append(csv); {$I+}
    end
    else
    begin
      Assign(csv, csvName);
      {$I-} Rewrite(csv); {$I+}
    end;
    if IOResult = 0 then
    begin
      if needHeader then
        Writeln(csv, 'ts,host,commit,run_id,remark,keys,depth,aot,flags,out_bytes,in_bytes,writer_p50,writer_p90,reader_p50,reader_p90');
      // 解析 --runid= 与 --remark=
      if (Copy(runId,1,9)='--runid=') then runId := Copy(runId,10,MaxInt);
      if (Copy(remark,1,9)='--remark=') then remark := Copy(remark,10,MaxInt);
      Writeln(csv, FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', Now), ',', GetEnvironmentVariable('COMPUTERNAME'), ',', commit, ',',
              runId, ',', remark, ',', keys, ',', depth, ',', aot, ',', flags, ',', outBytes, ',', inBytes, ',', wP50, ',', wP90, ',', rP50, ',', rP90);
      Close(csv);
      Writeln('CSV appended to ', csvName);
    end
    else
      Writeln('CSV open/append failed');
  end;
end.

