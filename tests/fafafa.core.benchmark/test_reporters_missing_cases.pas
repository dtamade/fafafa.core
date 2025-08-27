unit test_reporters_missing_cases;

{$MODE OBJFPC}{$H+}

interface

uses
  SysUtils, Classes, fafafa.core.benchmark;

procedure Test_CSVReporter_MissingZero;
procedure Test_CSVReporter_MissingNA;


procedure ExtraStateTest(aState: IBenchmarkState);
procedure ExtraStateTestExtra(aState: IBenchmarkState);

implementation

procedure GenTwoResults(out R1, R2: IBenchmarkResult);
begin
  R1 := Bench('m.zero.na.1', @ExtraStateTest);
  R2 := Bench('m.zero.na.2', @ExtraStateTestExtra);
end;

procedure Test_CSVReporter_MissingZero;
var R1, R2: IBenchmarkResult; Rep: IBenchmarkReporter; LTmp: string; SL: TStringList; Header, D1, D2: string; i, j, k, colExtra: Integer;
  function SplitCSV(const S: string): TStringList;
  var i: Integer; inQuote: Boolean; cur: string;
  begin
    Result := TStringList.Create; Result.Clear; inQuote := False; cur := '';
    i := 1; while i <= Length(S) do begin
      case S[i] of
        '"': if (i<Length(S)) and (S[i+1]='"') then begin cur:=cur+'"'; Inc(i); end else inQuote := not inQuote;
        ',': if not inQuote then begin Result.Add(cur); cur:=''; end else cur := cur + S[i];
      else cur := cur + S[i]; end; Inc(i);
    end; Result.Add(cur);
  end;
  function IndexOfField(const Arr: array of string; const Value: string): Integer; var t: Integer; begin for t := 0 to High(Arr) do if Arr[t]=Value then Exit(t); Exit(-1); end;
  var fields: array of string; H, L1, L2: TStringList;
  procedure ToArray(L: TStringList); var t: Integer; begin SetLength(fields, L.Count); for t:=0 to L.Count-1 do fields[t]:=L[t]; end;
begin
  GenTwoResults(R1, R2);
  LTmp := IncludeTrailingPathDelimiter(ExtractFileDir(ParamStr(0))) + 'reporter_csv_missing_zero.csv';
  if FileExists(LTmp) then SysUtils.DeleteFile(LTmp);
  Rep := CreateCSVReporter(LTmp); Rep.SetFormat('schema=2;decimals=2;counters=tabular;missing=zero'); Rep.ReportResults([R1, R2]);
  SL := TStringList.Create; try SL.LoadFromFile(LTmp);
    // header/data1/data2
    for i := 0 to SL.Count-1 do if Trim(SL[i])<>'' then begin Header:=SL[i]; j:=i+1; break; end;
    for i := j to SL.Count-1 do if Trim(SL[i])<>'' then begin D1:=SL[i]; k:=i+1; break; end;
    for i := k to SL.Count-1 do if Trim(SL[i])<>'' then begin D2:=SL[i]; break; end;
    if (Header='') or (D1='') or (D2='') then raise Exception.Create('missing=zero lines not found');
    // 找 extra 列
    H := SplitCSV(Header);
    try
      ToArray(H);
    finally
      H.Free;
    end;
    colExtra := IndexOfField(fields, 'Counter:extra[unit]'); if colExtra<0 then raise Exception.Create('extra col missing');
    L1 := SplitCSV(D1);
    try ToArray(L1); finally L1.Free; end;
    if (colExtra>=Length(fields)) or (Trim(fields[colExtra]) <> '0') then raise Exception.Create('missing=zero should render 0');
    L2 := SplitCSV(D2);
    try ToArray(L2); finally L2.Free; end;
    if (colExtra>=Length(fields)) or (Trim(fields[colExtra]) = '') then raise Exception.Create('second row should have value');
  finally SL.Free; if SysUtils.GetEnvironmentVariable('FAFAFA_KEEP_REPORT_FILES')='' then SysUtils.DeleteFile(LTmp); end;
end;

procedure Test_CSVReporter_MissingNA;
var R1, R2: IBenchmarkResult; Rep: IBenchmarkReporter; LTmp: string; SL: TStringList; Header, D1, D2: string; i, j, k, colExtra: Integer; fields: array of string; H, D: TStringList;
  function SplitCSV(const S: string): TStringList; var i: Integer; inQuote: Boolean; cur: string; begin Result := TStringList.Create; Result.Clear; inQuote := False; cur := ''; i := 1; while i <= Length(S) do begin case S[i] of '"': if (i<Length(S)) and (S[i+1]='"') then begin cur:=cur+'"'; Inc(i); end else inQuote := not inQuote; ',': if not inQuote then begin Result.Add(cur); cur:=''; end else cur := cur + S[i]; else cur := cur + S[i]; end; Inc(i); end; Result.Add(cur); end;
  function IndexOfField(const Arr: array of string; const Value: string): Integer; var t: Integer; begin for t := 0 to High(Arr) do if Arr[t]=Value then Exit(t); Exit(-1); end;
  procedure ToArray(L: TStringList); var t: Integer; begin SetLength(fields, L.Count); for t := 0 to L.Count-1 do fields[t] := L[t]; end;
begin
  GenTwoResults(R1, R2);
  LTmp := IncludeTrailingPathDelimiter(ExtractFileDir(ParamStr(0))) + 'reporter_csv_missing_na.csv'; if FileExists(LTmp) then SysUtils.DeleteFile(LTmp);
  Rep := CreateCSVReporter(LTmp); Rep.SetFormat('schema=2;decimals=2;counters=tabular;missing=na'); Rep.ReportResults([R1, R2]);
  SL := TStringList.Create; try SL.LoadFromFile(LTmp);
    // header/data1/data2
    for i := 0 to SL.Count-1 do if Trim(SL[i])<>'' then begin Header:=SL[i]; j:=i+1; break; end;
    for i := j to SL.Count-1 do if Trim(SL[i])<>'' then begin D1:=SL[i]; k:=i+1; break; end;
    for i := k to SL.Count-1 do if Trim(SL[i])<>'' then begin D2:=SL[i]; break; end;
    if (Header='') or (D1='') or (D2='') then raise Exception.Create('missing=na lines not found');
    H := SplitCSV(Header); try ToArray(H); finally H.Free; end;
    colExtra := IndexOfField(fields, 'Counter:extra[unit]'); if colExtra<0 then raise Exception.Create('extra col missing');
    D := SplitCSV(D1); try ToArray(D); finally D.Free; end;
    if (colExtra>=Length(fields)) or (Trim(fields[colExtra]) <> 'NA') then raise Exception.Create('missing=na should render NA');
  finally SL.Free; if SysUtils.GetEnvironmentVariable('FAFAFA_KEEP_REPORT_FILES')='' then SysUtils.DeleteFile(LTmp); end;
end;


// local helpers (duplicated minimal to avoid unit dependency cycle)
procedure ExtraStateTest(aState: IBenchmarkState);
begin
  while aState.KeepRunning do aState.AddCounter('ticks', 1);
  aState.AddCounter('done', 1);
end;

procedure ExtraStateTestExtra(aState: IBenchmarkState);
begin
  while aState.KeepRunning do aState.AddCounter('ticks', 1);
  aState.AddCounter('done', 1);
  aState.AddCounter('extra', 1);
end;

end.

