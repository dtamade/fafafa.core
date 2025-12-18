unit fafafa.core.test.snapshot;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes, fpjson, jsonparser, fafafa.core.toml;

// Minimal text snapshot compare. Returns true if equal; optionally update baseline.
function CompareTextSnapshot(const ASnapDir, AName, AActual: string; AUpdate: boolean = False): boolean;

// TOML snapshot compare (Phase 1: text-only normalization, no canonicalization yet)
function CompareTomlSnapshot(const ASnapDir, AName, ATomlText: string; AUpdate: boolean = False): boolean;

// JSON snapshot compare with canonical key order and normalized formatting.
function CompareJsonSnapshot(const ASnapDir, AName, AJsonText: string; AUpdate: boolean = False): boolean;

implementation

uses
  fafafa.core.math;

// Forward declarations for helpers used earlier
function EnvTrue(const AName: string): boolean; forward;
function ShouldUpdate(AParam: boolean): boolean; forward;
function CanonicalizeJsonText(const AJson: string): string; forward;
function CopyDataSorted(D: TJSONData): TJSONData; forward;
procedure WriteDiffFile(const ADiffPath, AExpected, AActual: string); forward;
function EnvToInt(const AName: string; const ADefault: Integer): Integer; forward;
function BuildSimpleLineDiff(const AExpected, AActual: string; AContext: Integer): string; forward;

function EnvToInt(const AName: string; const ADefault: Integer): Integer;
var v: string; n: Integer;
begin
  v := Trim(GetEnvironmentVariable(AName));
  if TryStrToInt(v, n) then Exit(n)
  else Exit(ADefault);
end;

function BuildSimpleLineDiff(const AExpected, AActual: string; AContext: Integer): string;
var
  ExpLines, ActLines, OutLines: TStringList;
  iMax, i, blockStart, blockEnd, ctx: Integer;
  lineE, lineA: string;
  function Min(a,b: Integer): Integer; begin if a<b then exit(a) else exit(b); end;
  function Max(a,b: Integer): Integer; begin if a>b then exit(a) else exit(b); end;
  var j: Integer; // dedicated loop index to avoid clobbering i
begin
  if AContext < 0 then AContext := 2;
  ExpLines := TStringList.Create;
  ActLines := TStringList.Create;
  OutLines := TStringList.Create;
  try
    ExpLines.Text := AExpected + LineEnding;
    ActLines.Text := AActual + LineEnding;
    OutLines.Add('--- expected');
    OutLines.Add('+++ actual');
    iMax := Max(ExpLines.Count, ActLines.Count);
    i := 0;
    while i < iMax do
    begin
      lineE := ''; if i < ExpLines.Count then lineE := ExpLines[i];
      lineA := ''; if i < ActLines.Count then lineA := ActLines[i];
      if lineE = lineA then
      begin
        Inc(i);
        Continue;
      end;
      // found a diff block starting at i
      blockStart := Max(0, i - AContext);
      // advance to end of contiguous diff
      blockEnd := i;
      while (blockEnd < iMax) do
      begin
        if (blockEnd < ExpLines.Count) then lineE := ExpLines[blockEnd] else lineE := '';
        if (blockEnd < ActLines.Count) then lineA := ActLines[blockEnd] else lineA := '';
        if lineE = lineA then Break;
        Inc(blockEnd);
      end;
      ctx := AContext;
      OutLines.Add(Format('@@ %d,%d @@', [blockStart+1, blockEnd - i + 1]));
      // context before
      for j := blockStart to Min(i-1, blockStart + AContext - 1) do
      begin
        if j < ExpLines.Count then OutLines.Add(' ' + ExpLines[j]);
      end;
      // diff region
      for j := i to blockEnd - 1 do
      begin
        if j < ExpLines.Count then OutLines.Add('-' + ExpLines[j]);
        if j < ActLines.Count then OutLines.Add('+' + ActLines[j]);
      end;
      // context after
      for j := blockEnd to Min(blockEnd + AContext - 1, iMax - 1) do
      begin
        if j < ExpLines.Count then OutLines.Add(' ' + ExpLines[j]);
      end;
      // continue from blockEnd
      i := blockEnd + ctx; // allow overlap context skip
    end;
    Result := OutLines.Text;
  finally
    ExpLines.Free; ActLines.Free; OutLines.Free;
  end;
end;


procedure WriteDiffFile(const ADiffPath, AExpected, AActual: string);
var
  Diff: string;
  Ctx: Integer;
  SL: TStringList;
begin
  Ctx := EnvToInt('TEST_SNAPSHOT_DIFF_CONTEXT', 2);
  Diff := BuildSimpleLineDiff(AExpected, AActual, Ctx);
  SL := TStringList.Create;
  try
    SL.Text := Diff;
    SL.SaveToFile(ADiffPath);
  finally
    SL.Free;
  end;
end;

procedure DeleteFileIfExists(const APath: string);
begin
  if (APath<>'') and FileExists(APath) then
    DeleteFile(APath);
end;



function NormalizeText(const S: string): string;
var
  T: string;
begin
  // Normalize line endings to LF and trim trailing newlines
  T := StringReplace(S, #13#10, #10, [rfReplaceAll]);
  T := StringReplace(T, #13, #10, [rfReplaceAll]);
  while (Length(T) > 0) and ((T[Length(T)] = #10) or (T[Length(T)] = #13)) do
    SetLength(T, Length(T)-1);
  Result := T;
end;

function CompareTextSnapshot(const ASnapDir, AName, AActual: string; AUpdate: boolean): boolean;
var
  BasePath, ActualNorm, BaseNorm: string;
  SL: TStringList;
  DoUpdate: boolean;
begin
  Result := False;
  if ASnapDir = '' then Exit;
  if AName = '' then Exit;

  if not DirectoryExists(ASnapDir) then
    if not ForceDirectories(ASnapDir) then
      Exit;

  BasePath := IncludeTrailingPathDelimiter(ASnapDir) + AName + '.snap.txt';
  ActualNorm := NormalizeText(AActual);
  DoUpdate := ShouldUpdate(AUpdate);

  if FileExists(BasePath) then
  begin
    SL := TStringList.Create;
    try
      SL.LoadFromFile(BasePath);
      BaseNorm := NormalizeText(SL.Text);
    finally
      SL.Free;
    end;

    Result := (BaseNorm = ActualNorm);
    if (not Result) then
    begin
      // write diff file on mismatch
      WriteDiffFile(IncludeTrailingPathDelimiter(ASnapDir)+AName+'.snap.diff.txt', BaseNorm, ActualNorm);
      if DoUpdate then
      begin
        SL := TStringList.Create;
        try
          SL.Text := ActualNorm;
          SL.SaveToFile(BasePath);
          Result := True;
          // cleanup diff after update
          DeleteFileIfExists(IncludeTrailingPathDelimiter(ASnapDir)+AName+'.snap.diff.txt');
        finally
          SL.Free;
        end;
      end;
    end;
  end
  else
  begin
    if DoUpdate then
    begin
      SL := TStringList.Create;
      try
        SL.Text := ActualNorm;
        SL.SaveToFile(BasePath);
        Result := True;
      finally
        SL.Free;
      end;
    end
    else
      Result := False;
  end;
end;

function CompareTomlSnapshot(const ASnapDir, AName, ATomlText: string; AUpdate: boolean): boolean;
var
  BasePath, ActualNorm, BaseNorm: string;
  SL: TStringList;
  DoUpdate: boolean;
  Doc: ITomlDocument; Err: TTomlError;
begin
  Result := False;
  if ASnapDir = '' then Exit;
  if AName = '' then Exit;

  if not DirectoryExists(ASnapDir) then
    if not ForceDirectories(ASnapDir) then
      Exit;

  BasePath := IncludeTrailingPathDelimiter(ASnapDir) + AName + '.snap.toml';
  // Canonicalize TOML by parsing and re-serializing with sorted keys + pretty
  // Fallback to text normalization if parsing fails
  try
    Doc := nil;
    if Parse(ATomlText, Doc, Err, []) then
      ActualNorm := String(ToToml(Doc, [twfPretty, twfSortKeys]))
    else
      ActualNorm := NormalizeText(ATomlText);
  except
    ActualNorm := NormalizeText(ATomlText);
  end;
  DoUpdate := ShouldUpdate(AUpdate);

  if FileExists(BasePath) then
  begin
    SL := TStringList.Create;
    try
      SL.LoadFromFile(BasePath);
      BaseNorm := NormalizeText(SL.Text);
    finally
      SL.Free;
    end;

    Result := (BaseNorm = ActualNorm);
    if (not Result) then
    begin
      // write diff file on mismatch
      WriteDiffFile(IncludeTrailingPathDelimiter(ASnapDir)+AName+'.snap.diff.txt', BaseNorm, ActualNorm);
      if DoUpdate then
      begin
        SL := TStringList.Create;
        try
          SL.Text := ActualNorm;
          SL.SaveToFile(BasePath);
          Result := True;
          DeleteFileIfExists(IncludeTrailingPathDelimiter(ASnapDir)+AName+'.snap.diff.txt');
        finally
          SL.Free;
        end;
      end;
    end;
  end
  else
  begin
    if DoUpdate then
    begin
      SL := TStringList.Create;
      try
        SL.Text := ActualNorm;
        SL.SaveToFile(BasePath);
        Result := True;
      finally
        SL.Free;
      end;
    end
    else
      Result := False;
  end;
end;

function EnvTrue(const AName: string): boolean;
var v: string;
begin
  v := GetEnvironmentVariable(AName);
  v := LowerCase(Trim(v));
  Result := (v='1') or (v='true') or (v='yes') or (v='on');
end;

function ShouldUpdate(AParam: boolean): boolean;
begin
  // Prefer explicit parameter for determinism; allow opt-in via env in local runs.
  // Disallow updates on CI environments to avoid unintended baseline changes.
  Result := AParam;
  if not Result then
    Result := EnvTrue('TEST_SNAPSHOT_UPDATE') or EnvTrue('FAFAFA_TEST_SNAPSHOT_UPDATE');
  if Result and EnvTrue('CI') then
    Result := False;
end;

function CopyDataSorted(D: TJSONData): TJSONData;
var
  I: Integer;
  SL: TStringList;
  Obj, NewObj: TJSONObject;
  Arr, NewArr: TJSONArray;
  Name: string;
  Child: TJSONData;
begin
  case D.JSONType of
    jtObject:
      begin
        Obj := TJSONObject(D);
        NewObj := TJSONObject.Create;
        SL := TStringList.Create;
        try
          SL.Sorted := True;
          SL.Duplicates := dupError;
          for I := 0 to Obj.Count-1 do
            SL.Add(Obj.Names[I]);
          for I := 0 to SL.Count-1 do
          begin
            Name := SL[I];
            Child := Obj.Find(Name);
            if Assigned(Child) then
              NewObj.Add(Name, CopyDataSorted(Child))
            else
              NewObj.Add(Name, TJSONNull.Create);
          end;
        finally
          SL.Free;
        end;
        Exit(NewObj);
      end;
    jtArray:
      begin
        Arr := TJSONArray(D);
        NewArr := TJSONArray.Create;
        for I := 0 to Arr.Count-1 do
          NewArr.Add(CopyDataSorted(Arr.Items[I]));
        Exit(NewArr);
      end;
  else
    Exit(D.Clone);
  end;
end;

function CanonicalizeJsonText(const AJson: string): string;
var
  Parser: TJSONParser;
  Data, Sorted: TJSONData;
begin
  Result := '';
{$push}
{$warn 5066 off}
  Parser := TJSONParser.Create(AJson);
{$pop}
  try
    Data := Parser.Parse;
    try
      Sorted := CopyDataSorted(Data);
      try
        Result := Sorted.FormatJSON([]);
      finally
        Sorted.Free;
      end;
    finally
      Data.Free;
    end;
  finally
    Parser.Free;
  end;
end;

function CompareJsonSnapshot(const ASnapDir, AName, AJsonText: string; AUpdate: boolean): boolean;
var
  BasePath, ActualNorm, BaseNorm: string;
  SL: TStringList;
  DoUpdate: boolean;
begin
  Result := False;
  if ASnapDir = '' then Exit;
  if AName = '' then Exit;

  if not DirectoryExists(ASnapDir) then
    if not ForceDirectories(ASnapDir) then
      Exit;

  BasePath := IncludeTrailingPathDelimiter(ASnapDir) + AName + '.snap.json';
  ActualNorm := CanonicalizeJsonText(AJsonText);
  DoUpdate := ShouldUpdate(AUpdate);

  if FileExists(BasePath) then
  begin
    SL := TStringList.Create;
    try
      SL.LoadFromFile(BasePath);
      BaseNorm := NormalizeText(SL.Text);
    finally
      SL.Free;
    end;

    Result := (BaseNorm = NormalizeText(ActualNorm));
    if (not Result) then
    begin
      WriteDiffFile(IncludeTrailingPathDelimiter(ASnapDir)+AName+'.snap.diff.txt', BaseNorm, NormalizeText(ActualNorm));
      if DoUpdate then
      begin
        SL := TStringList.Create;
        try
          SL.Text := ActualNorm;
          SL.SaveToFile(BasePath);
          Result := True;
          DeleteFileIfExists(IncludeTrailingPathDelimiter(ASnapDir)+AName+'.snap.diff.txt');
        finally
          SL.Free;
        end;
      end;
    end;
  end
  else
  begin
    if DoUpdate then
    begin
      SL := TStringList.Create;
      try
        SL.Text := ActualNorm;
        SL.SaveToFile(BasePath);
        Result := True;
      finally
        SL.Free;
      end;
    end
    else
      Result := False;
  end;
end;

end.

