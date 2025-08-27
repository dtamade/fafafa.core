unit baseline_utils;

{$codepage utf8}
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpjson, jsonparser, fafafa.core.benchmark;

// 自动根据扩展名选择 JSON/CSV 读取
function LoadBaselineMeansAny(const aFile: string): TStringList;
// 仅 JSON：读取 { results: [ { name, statistics.mean } ] }
function LoadBaselineMeans(const aFile: string): TStringList;
// 仅 CSV：读取由 CSV Reporter 生成的文件（Name, Mean(ns), ...）
function LoadBaselineMeansCSV(const aFile: string): TStringList;

  // 失败摘要：返回阈值以上的最差回归项简述（无则返回空串）
  function WorstRegressionSummary(const aResults: TBenchmarkResultArray; aBaseline: TStringList; aThresholdPct: Integer): string;
function CompareWithBaseline(const aResults: TBenchmarkResultArray; aBaseline: TStringList; aThresholdPct: Integer): Boolean;

implementation

function LoadBaselineMeans(const aFile: string): TStringList;
var
  LJSON: TJSONData;
  LParser: TJSONParser;
  LRoot, LResults, LStats, LItem: TJSONData;
  I: Integer;
  LName: string;
  FS: TFileStream;
begin
  Result := TStringList.Create;
  Result.NameValueSeparator := '=';
  if (aFile = '') or (not FileExists(aFile)) then
    Exit;

  FS := TFileStream.Create(aFile, fmOpenRead or fmShareDenyNone);
  LParser := nil;
  LJSON := nil;
  try
    LParser := TJSONParser.Create(FS, []);
    LJSON := LParser.Parse;
    // 期望结构：{ "results": [ {"name":..., "statistics": {"mean":...}}, ... ] }
    LRoot := LJSON;
    LResults := LRoot.FindPath('results');
    if (LResults <> nil) and (LResults.JSONType = jtArray) then
    begin
      for I := 0 to LResults.Count - 1 do
      begin
        LItem := LResults.Items[I];
        LName := LItem.FindPath('name').AsString;
        LStats := LItem.FindPath('statistics');
        if (LName <> '') and (LStats <> nil) then
          Result.Values[LName] := FloatToStr(LStats.FindPath('mean').AsFloat);
      end;
    end;
  finally
    if Assigned(LJSON) then LJSON.Free;
    if Assigned(LParser) then LParser.Free;
    FS.Free;
  end;

end;

function LoadBaselineMeansCSV(const aFile: string): TStringList;

  function ParseCSVLine(const S: string; const Delim: Char): TStringList;
  var
    I, L: Integer;
    Ch: Char;
    InQuotes: Boolean;
    Field: string;
  begin
    Result := TStringList.Create;
    Result.StrictDelimiter := True; // 我们自己处理分隔
    Result.Delimiter := Delim;

    InQuotes := False;
    Field := '';
    L := Length(S);
    I := 1;
    while I <= L do
    begin
      Ch := S[I];
      if Ch = '"' then
      begin
        if InQuotes and (I < L) and (S[I+1] = '"') then
        begin
          // 转义双引号
          Field := Field + '"';
          Inc(I); // 跳过下一个引号
        end
        else
          InQuotes := not InQuotes;
      end
      else if (Ch = Delim) and (not InQuotes) then
      begin
        Result.Add(Field);
        Field := '';
      end
      else
        Field := Field + Ch;
      Inc(I);
    end;
    // 末尾字段
    Result.Add(Field);
  end;

  function TrimQuotes(const S: string): string;
  begin
    Result := S;
    if (Length(Result) >= 2) and (Result[1] = '"') and (Result[Length(Result)] = '"') then
      Result := Copy(Result, 2, Length(Result) - 2);
  end;

  function IndexOfHeader(const Headers: TStringList; const Candidates: array of string): Integer;
  var
    I, J: Integer;
  begin
    for I := 0 to Headers.Count - 1 do
      for J := Low(Candidates) to High(Candidates) do
        if SameText(Trim(Headers[I]), Candidates[J]) then
          Exit(I);
    Result := -1;
  end;

var
  LSL: TStringList;
  I: Integer;
  LHeader, LFields: TStringList;
  NameIdx, MeanIdx: Integer;
  LName, LMeanStr: string;
begin
  Result := TStringList.Create;
  Result.NameValueSeparator := '=';
  if (aFile = '') or (not FileExists(aFile)) then Exit;

  LSL := TStringList.Create;
  try
    LSL.LoadFromFile(aFile);
    if LSL.Count = 0 then Exit;

    // 解析表头（尝试检测分隔符与小数点本地化）
    // 简化策略：优先逗号','作为分隔；若首行分号更多，则认为分隔符是';'（德式 CSV 常见）
    LHeader := ParseCSVLine(LSL[0], ',');
    if (Pos(';', LSL[0]) > Pos(',', LSL[0])) then
    begin
      FreeAndNil(LHeader);
      LHeader := ParseCSVLine(LSL[0], ';');
    end;
    try
      NameIdx := IndexOfHeader(LHeader, ['Name']);
      MeanIdx := IndexOfHeader(LHeader, ['Mean(ns)', 'Mean']);

      if NameIdx < 0 then NameIdx := 0; // 兜底：第一列
      if MeanIdx < 0 then MeanIdx := 5; // 兜底：第 6 列（与当前 Reporter 一致）

      for I := 1 to LSL.Count - 1 do // 从数据行开始
      begin
        if Trim(LSL[I]) = '' then Continue;
        LFields := ParseCSVLine(LSL[I], LHeader.Delimiter);
        try
          if (LFields.Count <= NameIdx) or (LFields.Count <= MeanIdx) then Continue;
          LName := Trim(TrimQuotes(LFields[NameIdx]));
          LMeanStr := Trim(LFields[MeanIdx]);
          // 本地化小数点处理：如果包含','但不包含'.'，且看起来像数值，则将','替换为'.'
          if (Pos('.', LMeanStr) = 0) and (Pos(',', LMeanStr) > 0) then
          begin
            // 不影响千位分隔的情况，这里简化假设 Mean(ns) 不带千分位
            LMeanStr := StringReplace(LMeanStr, ',', '.', [rfReplaceAll]);
          end;
          if LName <> '' then
            Result.Values[LName] := LMeanStr;
        finally
          LFields.Free;
        end;
      end;
    finally
      LHeader.Free;
    end;
  finally
    LSL.Free;
  end;
end;

function LoadBaselineMeansAny(const aFile: string): TStringList;
var
  LE: string;
begin
  LE := LowerCase(ExtractFileExt(aFile));
  if (LE = '.csv') then
    Result := LoadBaselineMeansCSV(aFile)
  else
    Result := LoadBaselineMeans(aFile);

end;


function WorstRegressionSummary(const aResults: TBenchmarkResultArray; aBaseline: TStringList; aThresholdPct: Integer): string;
var
  I: Integer;
  LName: string;
  LBaseMean, LCurrMean, LRatio: Double;
  LValue: string;
  LStats: TBenchmarkStatistics;
  LWorstName: string;
  LWorstRatio: Double;
  LWorstBase, LWorstCurr: Double;
begin
  Result := '';
  LWorstRatio := 1.0;
  LWorstName := '';
  LWorstBase := 0; LWorstCurr := 0;
  for I := 0 to High(aResults) do
  begin
    if aResults[I] = nil then Continue;
    LName := aResults[I].Name;
    LValue := aBaseline.Values[LName];
    if (LName <> '') and (LValue <> '') then
    begin
      try
        LBaseMean := StrToFloat(LValue);
      except
        Continue;
      end;
      LStats := aResults[I].GetStatistics;
      LCurrMean := LStats.Mean;
      if (LBaseMean > 0) then
      begin
        LRatio := LCurrMean / LBaseMean;
        if LRatio > (1 + aThresholdPct / 100.0) then
        begin
          if (LWorstName = '') or (LRatio > LWorstRatio) then
          begin
            LWorstName := LName;
            LWorstRatio := LRatio;
            LWorstBase := LBaseMean;
            LWorstCurr := LCurrMean;
          end;
        end;
      end;
    end;
  end;
  if LWorstName <> '' then
    Result := Format('worst regression: %s mean %.2fns -> %.2fns (%.1f%% over baseline)',
                     [LWorstName, LWorstBase, LWorstCurr, (LWorstRatio - 1.0) * 100.0]);
end;

function CompareWithBaseline(const aResults: TBenchmarkResultArray; aBaseline: TStringList; aThresholdPct: Integer): Boolean;
var
  I: Integer;
  LName: string;
  LBaseMean, LCurrMean: Double;
  LValue: string;
  LStats: TBenchmarkStatistics;
  LRegressed: Boolean;
begin
  LRegressed := False;
  for I := 0 to High(aResults) do
  begin
    if aResults[I] = nil then Continue;
    LName := aResults[I].Name;
    LValue := aBaseline.Values[LName];
    if (LName <> '') and (LValue <> '') then
    begin
      try
        LBaseMean := StrToFloat(LValue);
      except
        Continue;
      end;
      LStats := aResults[I].GetStatistics;
      LCurrMean := LStats.Mean;
      if (LBaseMean > 0) and (LCurrMean > LBaseMean * (1 + aThresholdPct / 100.0)) then
      begin
        WriteLn('⚠️ 回归：', LName, ' mean 从 ', LBaseMean:0:2, 'ns 增至 ', LCurrMean:0:2, 'ns (阈值 ', aThresholdPct, '%)');
        LRegressed := True;
      end;
    end;
  end;
  Result := not LRegressed;
end;

end.

