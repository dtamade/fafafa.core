unit test_reporters_schema_in_col_and_names;

{$MODE OBJFPC}{$H+}

interface

uses
  SysUtils, Classes, fafafa.core.benchmark;

procedure Test_CSVReporter_SchemaInColumn_First;
procedure Test_JSONReporter_ExtremeNames;

implementation

procedure StateExtremeNames(aState: IBenchmarkState);
begin
  while aState.KeepRunning do
  begin
    aState.AddCounter('tick one', 1);
    aState.AddCounter('tick"two"', 2);
    aState.AddCounter('中文 计数', 3);
  end;
  aState.AddCounter('done', 1);
end;

procedure Test_CSVReporter_SchemaInColumn_First;
var R: IBenchmarkResult; Rep: IBenchmarkReporter; LTmp: string; SL: TStringList; Header, Data: string; i, j: Integer;
  function SplitCSV(const S: string): TStringList; var i: Integer; inQuote: Boolean; cur: string; begin Result := TStringList.Create; Result.Clear; inQuote := False; cur := ''; i := 1; while i <= Length(S) do begin case S[i] of '"': if (i<Length(S)) and (S[i+1]='"') then begin cur:=cur+'"'; Inc(i); end else inQuote := not inQuote; ',': if not inQuote then begin Result.Add(cur); cur:=''; end else cur := cur + S[i]; else cur := cur + S[i]; end; Inc(i); end; Result.Add(cur); end;
begin
  R := Bench('schema.in.col', @StateExtremeNames);
  LTmp := IncludeTrailingPathDelimiter(ExtractFileDir(ParamStr(0))) + 'reporter_csv_schema_in_col.csv'; if FileExists(LTmp) then SysUtils.DeleteFile(LTmp);
  Rep := CreateCSVReporter(LTmp); Rep.SetFormat('schema=2;decimals=2;counters=tabular;schema_in_column=true'); Rep.ReportResult(R);
  SL := TStringList.Create; try SL.LoadFromFile(LTmp);
    for i := 0 to SL.Count-1 do if Trim(SL[i])<>'' then begin Header:=SL[i]; j:=i+1; break; end;
    for i := j to SL.Count-1 do if Trim(SL[i])<>'' then begin Data:=SL[i]; break; end;
    if (Header='') or (Data='') then raise Exception.Create('schema_in_column lines not found');
    // （已验证）不再打印额外调试输出，保持控制台干净
    // 首列应为 SchemaVersion，且数据首格也应是版本号（去掉 UTF-8 BOM 兼容）
    if (Length(Header)>=3) and (Header[1]=#239) and (Header[2]=#187) and (Header[3]=#191) then
      Header := Copy(Header, 4, MaxInt);
    if Copy(Header,1,13) <> 'SchemaVersion' then raise Exception.Create('SchemaVersion not first header col; header='+Header);
    if (Length(Data)>=3) and (Data[1]=#239) and (Data[2]=#187) and (Data[3]=#191) then
      Data := Copy(Data, 4, MaxInt);
    if Copy(Data,1,1) = '"' then raise Exception.Create('schema version should not be quoted');
  finally SL.Free; if SysUtils.GetEnvironmentVariable('FAFAFA_KEEP_REPORT_FILES')='' then SysUtils.DeleteFile(LTmp); end;
end;

procedure Test_JSONReporter_ExtremeNames;
var R: IBenchmarkResult; Rep: IBenchmarkReporter; LTmp: string; SL: TStringList; S: string;
begin
  R := Bench('json.extreme.names', @StateExtremeNames);
  LTmp := IncludeTrailingPathDelimiter(ExtractFileDir(ParamStr(0))) + 'reporter_json_extreme_names.json'; if FileExists(LTmp) then SysUtils.DeleteFile(LTmp);
  Rep := CreateJSONReporter(LTmp); Rep.SetFormat('schema=2;decimals=2'); Rep.ReportResult(R);
  SL := TStringList.Create; try SL.LoadFromFile(LTmp); S := SL.Text;
    // 断言 JSON 中正确转义/包含这些计数器名（不要求顺序）
    if (Pos('"name": "tick one"', S)=0) or (Pos('"name": "tick\"two\""', S)=0) or (Pos('"name": "中文 计数"', S)=0) then
      raise Exception.Create('JSON counter_list names escaped/missing');
  finally SL.Free; if SysUtils.GetEnvironmentVariable('FAFAFA_KEEP_REPORT_FILES')='' then SysUtils.DeleteFile(LTmp); end;
end;

end.

