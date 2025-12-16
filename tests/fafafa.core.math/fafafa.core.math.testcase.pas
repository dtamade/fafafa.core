unit fafafa.core.math.testcase;

{$MODE OBJFPC}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.base,
  fafafa.core.math;

type
  TTestMath = class(TTestCase)
  published
    // === IsAddOverflow SizeUInt ===
    procedure Test_IsAddOverflow_SizeUInt_NoOverflow_ReturnsFalse;
    procedure Test_IsAddOverflow_SizeUInt_Overflow_ReturnsTrue;
    procedure Test_IsAddOverflow_SizeUInt_BoundaryNoOverflow_ReturnsFalse;
    procedure Test_IsAddOverflow_SizeUInt_BoundaryOverflow_ReturnsTrue;
    procedure Test_IsAddOverflow_SizeUInt_ZeroValues_ReturnsFalse;
    procedure Test_IsAddOverflow_SizeUInt_MaxPlusZero_ReturnsFalse;
    procedure Test_IsAddOverflow_SizeUInt_MaxPlusOne_ReturnsTrue;

    // === IsAddOverflow UInt32 ===
    procedure Test_IsAddOverflow_UInt32_NoOverflow_ReturnsFalse;
    procedure Test_IsAddOverflow_UInt32_Overflow_ReturnsTrue;
    procedure Test_IsAddOverflow_UInt32_BoundaryNoOverflow_ReturnsFalse;
    procedure Test_IsAddOverflow_UInt32_BoundaryOverflow_ReturnsTrue;
    procedure Test_IsAddOverflow_UInt32_ZeroValues_ReturnsFalse;

    // === IsSubUnderflow SizeUInt ===
    procedure Test_IsSubUnderflow_SizeUInt_NoUnderflow_ReturnsFalse;
    procedure Test_IsSubUnderflow_SizeUInt_Underflow_ReturnsTrue;
    procedure Test_IsSubUnderflow_SizeUInt_Equal_ReturnsFalse;
    procedure Test_IsSubUnderflow_SizeUInt_Zero_ReturnsFalse;

    // === IsSubUnderflow UInt32 ===
    procedure Test_IsSubUnderflow_UInt32_NoUnderflow_ReturnsFalse;
    procedure Test_IsSubUnderflow_UInt32_Underflow_ReturnsTrue;
    procedure Test_IsSubUnderflow_UInt32_Equal_ReturnsFalse;

    // === IsMulOverflow SizeUInt ===
    procedure Test_IsMulOverflow_SizeUInt_NoOverflow_ReturnsFalse;
    procedure Test_IsMulOverflow_SizeUInt_Overflow_ReturnsTrue;
    procedure Test_IsMulOverflow_SizeUInt_Zero_ReturnsFalse;
    procedure Test_IsMulOverflow_SizeUInt_One_ReturnsFalse;
    procedure Test_IsMulOverflow_SizeUInt_Boundary_Success;

    // === IsMulOverflow UInt32 ===
    procedure Test_IsMulOverflow_UInt32_NoOverflow_ReturnsFalse;
    procedure Test_IsMulOverflow_UInt32_Overflow_ReturnsTrue;
    procedure Test_IsMulOverflow_UInt32_Zero_ReturnsFalse;

    // === SaturatingAdd SizeUInt ===
    procedure Test_SaturatingAdd_SizeUInt_Normal_ReturnsSum;
    procedure Test_SaturatingAdd_SizeUInt_Overflow_ReturnsMax;
    procedure Test_SaturatingAdd_SizeUInt_MaxPlusOne_ReturnsMax;

    // === SaturatingAdd UInt32 ===
    procedure Test_SaturatingAdd_UInt32_Normal_ReturnsSum;
    procedure Test_SaturatingAdd_UInt32_Overflow_ReturnsMax;

    // === SaturatingSub SizeUInt ===
    procedure Test_SaturatingSub_SizeUInt_Normal_ReturnsDiff;
    procedure Test_SaturatingSub_SizeUInt_Underflow_ReturnsZero;

    // === SaturatingSub UInt32 ===
    procedure Test_SaturatingSub_UInt32_Normal_ReturnsDiff;
    procedure Test_SaturatingSub_UInt32_Underflow_ReturnsZero;

    // === SaturatingMul SizeUInt ===
    procedure Test_SaturatingMul_SizeUInt_Normal_ReturnsProduct;
    procedure Test_SaturatingMul_SizeUInt_Overflow_ReturnsMax;
    procedure Test_SaturatingMul_SizeUInt_Zero_ReturnsZero;

    // === SaturatingMul UInt32 ===
    procedure Test_SaturatingMul_UInt32_Normal_ReturnsProduct;
    procedure Test_SaturatingMul_UInt32_Overflow_ReturnsMax;

    // === Min/Max helpers ===
    procedure Test_Min_SizeUInt_Basic_ReturnsSmaller;
    procedure Test_Max_SizeUInt_Basic_ReturnsLarger;
    procedure Test_Min_Int64_Basic_ReturnsSmaller;
    procedure Test_Max_Int64_Basic_ReturnsLarger;
  end;

  TTestMathRules = class(TTestCase)
  published
    procedure Test_SrcUnits_IncludingIncUsingRoundTruncFrac_MustDependOn_MathFacade;
    procedure Test_CollectionsUnits_UsingRoundTrunc_MustDependOn_MathFacade;
    procedure Test_TimeUnits_UsingRoundTruncFrac_MustDependOn_MathFacade;
    procedure Test_MemUnits_UsingRoundTruncFrac_MustDependOn_MathFacade;
    procedure Test_BenchmarkUnits_UsingRoundTruncFrac_MustDependOn_MathFacade;
    procedure Test_ArchiverUnits_UsingRoundTruncFrac_MustDependOn_MathFacade;
    procedure Test_SyncUnits_UsingRoundTruncFrac_MustDependOn_MathFacade;
  end;

implementation

function GetRepoRootDir: string;
begin
  // bin/ -> tests/fafafa.core.math/ -> tests/ -> repo root
  Result := ExpandFileName(
    ExtractFileDir(ParamStr(0)) + DirectorySeparator +
    '..' + DirectorySeparator +
    '..' + DirectorySeparator +
    '..'
  );
end;

function GetSrcDir: string;
begin
  Result := IncludeTrailingPathDelimiter(GetRepoRootDir) + 'src';
end;

function StripPascalStringsAndComments(const S: string): string;
var
  i, j, len: Integer;
  InStr: Boolean;
  InCurly: Boolean;
  InParen: Boolean;
begin
  len := Length(S);
  SetLength(Result, len);

  InStr := False;
  InCurly := False;
  InParen := False;

  i := 1;
  while i <= len do
  begin
    if InStr then
    begin
      Result[i] := ' ';
      if S[i] = '''' then
      begin
        // escaped quote: '' inside string
        if (i < len) and (S[i + 1] = '''') then
        begin
          Result[i + 1] := ' ';
          Inc(i, 2);
          Continue;
        end;
        InStr := False;
      end;
      Inc(i);
      Continue;
    end;

    if InCurly then
    begin
      Result[i] := ' ';
      if S[i] = '}' then
        InCurly := False;
      Inc(i);
      Continue;
    end;

    if InParen then
    begin
      Result[i] := ' ';
      if (S[i] = '*') and (i < len) and (S[i + 1] = ')') then
      begin
        Result[i + 1] := ' ';
        InParen := False;
        Inc(i, 2);
      end
      else
        Inc(i);
      Continue;
    end;

    // not in any
    if S[i] = '''' then
    begin
      InStr := True;
      Result[i] := ' ';
      Inc(i);
      Continue;
    end;

    if S[i] = '{' then
    begin
      InCurly := True;
      Result[i] := ' ';
      Inc(i);
      Continue;
    end;

    if (S[i] = '(') and (i < len) and (S[i + 1] = '*') then
    begin
      InParen := True;
      Result[i] := ' ';
      Result[i + 1] := ' ';
      Inc(i, 2);
      Continue;
    end;

    if (S[i] = '/') and (i < len) and (S[i + 1] = '/') then
    begin
      // Line comment: strip until end of line, not end of file.
      Result[i] := ' ';
      Result[i + 1] := ' ';
      j := i + 2;
      while (j <= len) and not (S[j] in [#10, #13]) do
      begin
        Result[j] := ' ';
        Inc(j);
      end;
      i := j;
      Continue;
    end;

    Result[i] := S[i];
    Inc(i);
  end;
end;

function IsIdentChar(const C: Char): Boolean; inline;
begin
  Result := (C in ['A'..'Z', 'a'..'z', '0'..'9', '_']);
end;

function LineHasIdentCall(const Line, Ident: string): Boolean;
var
  s: string;
  i, j, len, identLen: Integer;
  cBefore: Char;
begin
  Result := False;
  if Ident = '' then
    Exit;

  s := StripPascalStringsAndComments(Line);
  len := Length(s);
  identLen := Length(Ident);

  i := 1;
  while i <= len - identLen + 1 do
  begin
    if CompareText(Copy(s, i, identLen), Ident) = 0 then
    begin
      if i = 1 then
        cBefore := #0
      else
        cBefore := s[i - 1];

      // Ignore qualified calls like Unit.Ident(
      if (cBefore = '.') or IsIdentChar(cBefore) then
      begin
        Inc(i);
        Continue;
      end;

      j := i + identLen;
      while (j <= len) and (s[j] in [' ', #9, #10, #13]) do
        Inc(j);

      if (j <= len) and (s[j] = '(') then
        Exit(True);
    end;
    Inc(i);
  end;
end;

function TryExtractIncludeFileNameFromLine(const Line: string; out IncName: string): Boolean;
var
  s, u: string;
  pI, pInclude: SizeInt;
  pToken: SizeInt;
  tokenLen: SizeInt;
  i, len: Integer;
  quote: Char;
  j: Integer;
begin
  IncName := '';
  Result := False;

  s := Trim(Line);
  if s = '' then
    Exit;

  u := UpperCase(s);
  pI := Pos('{$I', u);
  pInclude := Pos('{$INCLUDE', u);

  if (pI = 0) and (pInclude = 0) then
    Exit;

  if (pI > 0) and ((pInclude = 0) or (pI < pInclude)) then
  begin
    // Ignore include-switch directives: {$I+} / {$I-}
    if (pI + 3 <= Length(u)) and (u[pI + 3] in ['+', '-']) then
      Exit;

    pToken := pI;
    tokenLen := 3; // {$I
  end
  else
  begin
    pToken := pInclude;
    tokenLen := Length('{$INCLUDE');
  end;

  len := Length(s);
  i := pToken + tokenLen;
  while (i <= len) and (s[i] in [' ', #9]) do
    Inc(i);
  if i > len then
    Exit;

  quote := #0;
  if (s[i] = '''') or (s[i] = '"') then
  begin
    quote := s[i];
    Inc(i);
  end;

  if quote <> #0 then
  begin
    j := i;
    while (j <= len) and (s[j] <> quote) do
      Inc(j);
    if j > len then
      Exit;
    IncName := Copy(s, i, j - i);
  end
  else
  begin
    j := i;
    while (j <= len) and not (s[j] in ['}', ' ', #9]) do
      Inc(j);
    IncName := Copy(s, i, j - i);
  end;

  IncName := Trim(IncName);
  if IncName = '' then
    Exit;

  if LowerCase(ExtractFileExt(IncName)) <> '.inc' then
    Exit;

  Result := True;
end;

procedure CollectIncludedIncFileNames(const HostPasPath: string; IncNames: TStrings);
var
  sl: TStringList;
  i: Integer;
  incName: string;
begin
  IncNames.Clear;

  sl := TStringList.Create;
  try
    sl.LoadFromFile(HostPasPath);
    for i := 0 to sl.Count - 1 do
      if TryExtractIncludeFileNameFromLine(sl[i], incName) then
        IncNames.Add(incName);
  finally
    sl.Free;
  end;
end;

function ResolveIncPath(const HostPasPath, IncName: string; out ResolvedPath: string): Boolean;
var
  cand: string;
  srcDir: string;
begin
  ResolvedPath := '';
  Result := False;

  if IncName = '' then
    Exit;

  // 1) relative to host unit dir
  cand := ExpandFileName(ExtractFileDir(HostPasPath) + DirectorySeparator + IncName);
  if FileExists(cand) then
  begin
    ResolvedPath := cand;
    Exit(True);
  end;

  // 2) relative to src/
  srcDir := IncludeTrailingPathDelimiter(GetSrcDir);
  cand := ExpandFileName(srcDir + IncName);
  if FileExists(cand) then
  begin
    ResolvedPath := cand;
    Exit(True);
  end;
end;

function FileDependsOnUnitOutsideComments(const PasPath, UnitName: string): Boolean;
var
  sl: TStringList;
  text, stripped: string;
  needle: string;
begin
  Result := False;
  needle := LowerCase(UnitName);
  if needle = '' then
    Exit;

  sl := TStringList.Create;
  try
    sl.LoadFromFile(PasPath);
    text := sl.Text;
  finally
    sl.Free;
  end;

  stripped := StripPascalStringsAndComments(text);
  Result := Pos(needle, LowerCase(stripped)) > 0;
end;

function IncFileUsesAnyOfRoundTruncFrac(const IncPath: string; out Evidence: string): Boolean;
var
  sl: TStringList;
  i: Integer;
  line: string;
  hit: string;
begin
  Result := False;
  Evidence := '';

  sl := TStringList.Create;
  try
    sl.LoadFromFile(IncPath);
    for i := 0 to sl.Count - 1 do
    begin
      line := sl[i];
      if LineHasIdentCall(line, 'Round') then hit := 'Round'
      else if LineHasIdentCall(line, 'Trunc') then hit := 'Trunc'
      else if LineHasIdentCall(line, 'Frac') then hit := 'Frac'
      else hit := '';

      if hit <> '' then
      begin
        Evidence := Format('%s:%d: %s', [ExtractFileName(IncPath), i + 1, hit]);
        Exit(True);
      end;
    end;
  finally
    sl.Free;
  end;
end;

procedure TTestMathRules.Test_SrcUnits_IncludingIncUsingRoundTruncFrac_MustDependOn_MathFacade;
var
  srcDir: string;
  sr: TSearchRec;
  hostPath: string;
  incNames: TStringList;
  offenders: TStringList;
  i: Integer;
  incName: string;
  incPath: string;
  evidence: string;
  dependsOnMath: Boolean;
begin
  srcDir := IncludeTrailingPathDelimiter(GetSrcDir);
  if not DirectoryExists(srcDir) then
    Fail('src directory not found: ' + srcDir);

  incNames := TStringList.Create;
  offenders := TStringList.Create;
  try
    if FindFirst(srcDir + '*.pas', faAnyFile, sr) = 0 then
    begin
      repeat
        if (sr.Attr and faDirectory) <> 0 then
          Continue;

        hostPath := srcDir + sr.Name;
        CollectIncludedIncFileNames(hostPath, incNames);
        if incNames.Count = 0 then
          Continue;

        dependsOnMath := FileDependsOnUnitOutsideComments(hostPath, 'fafafa.core.math');
        if dependsOnMath then
          Continue;

        for i := 0 to incNames.Count - 1 do
        begin
          incName := incNames[i];
          if not ResolveIncPath(hostPath, incName, incPath) then
            Continue;

          if IncFileUsesAnyOfRoundTruncFrac(incPath, evidence) then
          begin
            offenders.Add(Format('%s includes %s (%s)', [sr.Name, ExtractFileName(incPath), evidence]));
            Break;
          end;
        end;
      until FindNext(sr) <> 0;
      FindClose(sr);
    end;

    if offenders.Count > 0 then
      Fail(
        'These src units include .inc files that call Round/Trunc/Frac but do not depend on fafafa.core.math:' + LineEnding +
        offenders.Text
      );
  finally
    offenders.Free;
    incNames.Free;
  end;
end;

procedure TTestMathRules.Test_CollectionsUnits_UsingRoundTrunc_MustDependOn_MathFacade;
var
  srcDir: string;
  sr: TSearchRec;
  pasPath: string;
  sl: TStringList;
  offenders: TStringList;
  i: Integer;
  line: string;
  hit: string;
begin
  srcDir := IncludeTrailingPathDelimiter(GetSrcDir);
  if not DirectoryExists(srcDir) then
    Fail('src directory not found: ' + srcDir);

  sl := TStringList.Create;
  offenders := TStringList.Create;
  try
    if FindFirst(srcDir + 'fafafa.core.collections*.pas', faAnyFile, sr) = 0 then
    begin
      repeat
        if (sr.Attr and faDirectory) <> 0 then
          Continue;

        pasPath := srcDir + sr.Name;
        if FileDependsOnUnitOutsideComments(pasPath, 'fafafa.core.math') then
          Continue;

        sl.LoadFromFile(pasPath);
        for i := 0 to sl.Count - 1 do
        begin
          line := sl[i];
          if LineHasIdentCall(line, 'Round') then hit := 'Round'
          else if LineHasIdentCall(line, 'Trunc') then hit := 'Trunc'
          else hit := '';

          if hit <> '' then
          begin
            offenders.Add(Format('%s:%d: %s', [sr.Name, i + 1, hit]));
            Break;
          end;
        end;
      until FindNext(sr) <> 0;
      FindClose(sr);
    end;

    if offenders.Count > 0 then
      Fail(
        'Collections units use Round/Trunc but do not depend on fafafa.core.math:' + LineEnding +
        offenders.Text
      );
  finally
    offenders.Free;
    sl.Free;
  end;
end;

procedure TTestMathRules.Test_TimeUnits_UsingRoundTruncFrac_MustDependOn_MathFacade;
var
  srcDir: string;
  sr: TSearchRec;
  pasPath: string;
  sl: TStringList;
  offenders: TStringList;
  i: Integer;
  line: string;
  hit: string;
begin
  srcDir := IncludeTrailingPathDelimiter(GetSrcDir);
  if not DirectoryExists(srcDir) then
    Fail('src directory not found: ' + srcDir);

  sl := TStringList.Create;
  offenders := TStringList.Create;
  try
    if FindFirst(srcDir + 'fafafa.core.time*.pas', faAnyFile, sr) = 0 then
    begin
      repeat
        if (sr.Attr and faDirectory) <> 0 then
          Continue;

        pasPath := srcDir + sr.Name;
        if FileDependsOnUnitOutsideComments(pasPath, 'fafafa.core.math') then
          Continue;

        sl.LoadFromFile(pasPath);
        for i := 0 to sl.Count - 1 do
        begin
          line := sl[i];
          if LineHasIdentCall(line, 'Round') then hit := 'Round'
          else if LineHasIdentCall(line, 'Trunc') then hit := 'Trunc'
          else if LineHasIdentCall(line, 'Frac') then hit := 'Frac'
          else hit := '';

          if hit <> '' then
          begin
            offenders.Add(Format('%s:%d: %s', [sr.Name, i + 1, hit]));
            Break;
          end;
        end;
      until FindNext(sr) <> 0;
      FindClose(sr);
    end;

    if offenders.Count > 0 then
      Fail(
        'Time units use Round/Trunc/Frac but do not depend on fafafa.core.math:' + LineEnding +
        offenders.Text
      );
  finally
    offenders.Free;
    sl.Free;
  end;
end;

procedure TTestMathRules.Test_MemUnits_UsingRoundTruncFrac_MustDependOn_MathFacade;
var
  srcDir: string;
  sr: TSearchRec;
  pasPath: string;
  sl: TStringList;
  offenders: TStringList;
  i: Integer;
  line: string;
  hit: string;
begin
  srcDir := IncludeTrailingPathDelimiter(GetSrcDir);
  if not DirectoryExists(srcDir) then
    Fail('src directory not found: ' + srcDir);

  sl := TStringList.Create;
  offenders := TStringList.Create;
  try
    if FindFirst(srcDir + 'fafafa.core.mem*.pas', faAnyFile, sr) = 0 then
    begin
      repeat
        if (sr.Attr and faDirectory) <> 0 then
          Continue;

        pasPath := srcDir + sr.Name;
        if FileDependsOnUnitOutsideComments(pasPath, 'fafafa.core.math') then
          Continue;

        sl.LoadFromFile(pasPath);
        for i := 0 to sl.Count - 1 do
        begin
          line := sl[i];
          if LineHasIdentCall(line, 'Round') then hit := 'Round'
          else if LineHasIdentCall(line, 'Trunc') then hit := 'Trunc'
          else if LineHasIdentCall(line, 'Frac') then hit := 'Frac'
          else hit := '';

          if hit <> '' then
          begin
            offenders.Add(Format('%s:%d: %s', [sr.Name, i + 1, hit]));
            Break;
          end;
        end;
      until FindNext(sr) <> 0;
      FindClose(sr);
    end;

    if offenders.Count > 0 then
      Fail(
        'Mem units use Round/Trunc/Frac but do not depend on fafafa.core.math:' + LineEnding +
        offenders.Text
      );
  finally
    offenders.Free;
    sl.Free;
  end;
end;

procedure TTestMathRules.Test_BenchmarkUnits_UsingRoundTruncFrac_MustDependOn_MathFacade;
var
  srcDir: string;
  sr: TSearchRec;
  pasPath: string;
  sl: TStringList;
  offenders: TStringList;
  i: Integer;
  line: string;
  hit: string;
begin
  srcDir := IncludeTrailingPathDelimiter(GetSrcDir);
  if not DirectoryExists(srcDir) then
    Fail('src directory not found: ' + srcDir);

  sl := TStringList.Create;
  offenders := TStringList.Create;
  try
    if FindFirst(srcDir + 'fafafa.core.benchmark*.pas', faAnyFile, sr) = 0 then
    begin
      repeat
        if (sr.Attr and faDirectory) <> 0 then
          Continue;

        pasPath := srcDir + sr.Name;
        if FileDependsOnUnitOutsideComments(pasPath, 'fafafa.core.math') then
          Continue;

        sl.LoadFromFile(pasPath);
        for i := 0 to sl.Count - 1 do
        begin
          line := sl[i];
          if LineHasIdentCall(line, 'Round') then hit := 'Round'
          else if LineHasIdentCall(line, 'Trunc') then hit := 'Trunc'
          else if LineHasIdentCall(line, 'Frac') then hit := 'Frac'
          else hit := '';

          if hit <> '' then
          begin
            offenders.Add(Format('%s:%d: %s', [sr.Name, i + 1, hit]));
            Break;
          end;
        end;
      until FindNext(sr) <> 0;
      FindClose(sr);
    end;

    if offenders.Count > 0 then
      Fail(
        'Benchmark units use Round/Trunc/Frac but do not depend on fafafa.core.math:' + LineEnding +
        offenders.Text
      );
  finally
    offenders.Free;
    sl.Free;
  end;
end;

procedure TTestMathRules.Test_ArchiverUnits_UsingRoundTruncFrac_MustDependOn_MathFacade;
var
  srcDir: string;
  sr: TSearchRec;
  pasPath: string;
  sl: TStringList;
  offenders: TStringList;
  i: Integer;
  line: string;
  hit: string;
begin
  srcDir := IncludeTrailingPathDelimiter(GetSrcDir);
  if not DirectoryExists(srcDir) then
    Fail('src directory not found: ' + srcDir);

  sl := TStringList.Create;
  offenders := TStringList.Create;
  try
    if FindFirst(srcDir + 'fafafa.core.archiver*.pas', faAnyFile, sr) = 0 then
    begin
      repeat
        if (sr.Attr and faDirectory) <> 0 then
          Continue;

        pasPath := srcDir + sr.Name;
        if FileDependsOnUnitOutsideComments(pasPath, 'fafafa.core.math') then
          Continue;

        sl.LoadFromFile(pasPath);
        for i := 0 to sl.Count - 1 do
        begin
          line := sl[i];
          if LineHasIdentCall(line, 'Round') then hit := 'Round'
          else if LineHasIdentCall(line, 'Trunc') then hit := 'Trunc'
          else if LineHasIdentCall(line, 'Frac') then hit := 'Frac'
          else hit := '';

          if hit <> '' then
          begin
            offenders.Add(Format('%s:%d: %s', [sr.Name, i + 1, hit]));
            Break;
          end;
        end;
      until FindNext(sr) <> 0;
      FindClose(sr);
    end;

    if offenders.Count > 0 then
      Fail(
        'Archiver units use Round/Trunc/Frac but do not depend on fafafa.core.math:' + LineEnding +
        offenders.Text
      );
  finally
    offenders.Free;
    sl.Free;
  end;
end;

procedure TTestMathRules.Test_SyncUnits_UsingRoundTruncFrac_MustDependOn_MathFacade;
var
  srcDir: string;
  sr: TSearchRec;
  pasPath: string;
  sl: TStringList;
  offenders: TStringList;
  i: Integer;
  line: string;
  hit: string;
begin
  srcDir := IncludeTrailingPathDelimiter(GetSrcDir);
  if not DirectoryExists(srcDir) then
    Fail('src directory not found: ' + srcDir);

  sl := TStringList.Create;
  offenders := TStringList.Create;
  try
    if FindFirst(srcDir + 'fafafa.core.sync*.pas', faAnyFile, sr) = 0 then
    begin
      repeat
        if (sr.Attr and faDirectory) <> 0 then
          Continue;

        pasPath := srcDir + sr.Name;
        if FileDependsOnUnitOutsideComments(pasPath, 'fafafa.core.math') then
          Continue;

        sl.LoadFromFile(pasPath);
        for i := 0 to sl.Count - 1 do
        begin
          line := sl[i];
          if LineHasIdentCall(line, 'Round') then hit := 'Round'
          else if LineHasIdentCall(line, 'Trunc') then hit := 'Trunc'
          else if LineHasIdentCall(line, 'Frac') then hit := 'Frac'
          else hit := '';

          if hit <> '' then
          begin
            offenders.Add(Format('%s:%d: %s', [sr.Name, i + 1, hit]));
            Break;
          end;
        end;
      until FindNext(sr) <> 0;
      FindClose(sr);
    end;

    if offenders.Count > 0 then
      Fail(
        'Sync units use Round/Trunc/Frac but do not depend on fafafa.core.math:' + LineEnding +
        offenders.Text
      );
  finally
    offenders.Free;
    sl.Free;
  end;
end;

// === IsAddOverflow SizeUInt ===

procedure TTestMath.Test_IsAddOverflow_SizeUInt_NoOverflow_ReturnsFalse;
begin
  AssertFalse(IsAddOverflow(SizeUInt(10), SizeUInt(20)));
  AssertFalse(IsAddOverflow(SizeUInt(100), SizeUInt(200)));
end;

procedure TTestMath.Test_IsAddOverflow_SizeUInt_Overflow_ReturnsTrue;
begin
  AssertTrue(IsAddOverflow(MAX_SIZE_UINT, SizeUInt(1)));
  AssertTrue(IsAddOverflow(MAX_SIZE_UINT - 10, SizeUInt(20)));
end;

procedure TTestMath.Test_IsAddOverflow_SizeUInt_BoundaryNoOverflow_ReturnsFalse;
var
  HalfMax: SizeUInt;
begin
  AssertFalse(IsAddOverflow(MAX_SIZE_UINT - 1, SizeUInt(1)));
  HalfMax := MAX_SIZE_UINT div 2;
  AssertFalse(IsAddOverflow(HalfMax, HalfMax));
end;

procedure TTestMath.Test_IsAddOverflow_SizeUInt_BoundaryOverflow_ReturnsTrue;
var
  HalfMaxPlus1: SizeUInt;
begin
  AssertTrue(IsAddOverflow(MAX_SIZE_UINT, SizeUInt(1)));
  HalfMaxPlus1 := MAX_SIZE_UINT div 2 + 1;
  AssertTrue(IsAddOverflow(HalfMaxPlus1, HalfMaxPlus1));
end;

procedure TTestMath.Test_IsAddOverflow_SizeUInt_ZeroValues_ReturnsFalse;
begin
  AssertFalse(IsAddOverflow(SizeUInt(0), SizeUInt(0)));
  AssertFalse(IsAddOverflow(SizeUInt(0), SizeUInt(100)));
  AssertFalse(IsAddOverflow(SizeUInt(100), SizeUInt(0)));
end;

procedure TTestMath.Test_IsAddOverflow_SizeUInt_MaxPlusZero_ReturnsFalse;
begin
  AssertFalse(IsAddOverflow(MAX_SIZE_UINT, SizeUInt(0)));
  AssertFalse(IsAddOverflow(SizeUInt(0), MAX_SIZE_UINT));
end;

procedure TTestMath.Test_IsAddOverflow_SizeUInt_MaxPlusOne_ReturnsTrue;
begin
  AssertTrue(IsAddOverflow(MAX_SIZE_UINT, SizeUInt(1)));
  AssertTrue(IsAddOverflow(SizeUInt(1), MAX_SIZE_UINT));
end;

// === IsAddOverflow UInt32 ===

procedure TTestMath.Test_IsAddOverflow_UInt32_NoOverflow_ReturnsFalse;
begin
  AssertFalse(IsAddOverflow(UInt32(10), UInt32(20)));
  AssertFalse(IsAddOverflow(UInt32(100), UInt32(200)));
end;

procedure TTestMath.Test_IsAddOverflow_UInt32_Overflow_ReturnsTrue;
begin
  AssertTrue(IsAddOverflow(MAX_UINT32, UInt32(1)));
  AssertTrue(IsAddOverflow(MAX_UINT32 - 10, UInt32(20)));
end;

procedure TTestMath.Test_IsAddOverflow_UInt32_BoundaryNoOverflow_ReturnsFalse;
var
  HalfMax: UInt32;
begin
  AssertFalse(IsAddOverflow(MAX_UINT32 - 1, UInt32(1)));
  HalfMax := MAX_UINT32 div 2;
  AssertFalse(IsAddOverflow(HalfMax, HalfMax));
end;

procedure TTestMath.Test_IsAddOverflow_UInt32_BoundaryOverflow_ReturnsTrue;
var
  HalfMaxPlus1: UInt32;
begin
  AssertTrue(IsAddOverflow(MAX_UINT32, UInt32(1)));
  HalfMaxPlus1 := MAX_UINT32 div 2 + 1;
  AssertTrue(IsAddOverflow(HalfMaxPlus1, HalfMaxPlus1));
end;

procedure TTestMath.Test_IsAddOverflow_UInt32_ZeroValues_ReturnsFalse;
begin
  AssertFalse(IsAddOverflow(UInt32(0), UInt32(0)));
  AssertFalse(IsAddOverflow(UInt32(0), UInt32(100)));
  AssertFalse(IsAddOverflow(UInt32(100), UInt32(0)));
end;

// === IsSubUnderflow SizeUInt ===

procedure TTestMath.Test_IsSubUnderflow_SizeUInt_NoUnderflow_ReturnsFalse;
begin
  AssertFalse(IsSubUnderflow(SizeUInt(100), SizeUInt(50)));
  AssertFalse(IsSubUnderflow(MAX_SIZE_UINT, SizeUInt(1)));
end;

procedure TTestMath.Test_IsSubUnderflow_SizeUInt_Underflow_ReturnsTrue;
begin
  AssertTrue(IsSubUnderflow(SizeUInt(50), SizeUInt(100)));
  AssertTrue(IsSubUnderflow(SizeUInt(0), SizeUInt(1)));
end;

procedure TTestMath.Test_IsSubUnderflow_SizeUInt_Equal_ReturnsFalse;
begin
  AssertFalse(IsSubUnderflow(SizeUInt(100), SizeUInt(100)));
  AssertFalse(IsSubUnderflow(MAX_SIZE_UINT, MAX_SIZE_UINT));
end;

procedure TTestMath.Test_IsSubUnderflow_SizeUInt_Zero_ReturnsFalse;
begin
  AssertFalse(IsSubUnderflow(SizeUInt(100), SizeUInt(0)));
  AssertFalse(IsSubUnderflow(MAX_SIZE_UINT, SizeUInt(0)));
end;

// === IsSubUnderflow UInt32 ===

procedure TTestMath.Test_IsSubUnderflow_UInt32_NoUnderflow_ReturnsFalse;
begin
  AssertFalse(IsSubUnderflow(UInt32(100), UInt32(50)));
  AssertFalse(IsSubUnderflow(MAX_UINT32, UInt32(1)));
end;

procedure TTestMath.Test_IsSubUnderflow_UInt32_Underflow_ReturnsTrue;
begin
  AssertTrue(IsSubUnderflow(UInt32(50), UInt32(100)));
  AssertTrue(IsSubUnderflow(UInt32(0), UInt32(1)));
end;

procedure TTestMath.Test_IsSubUnderflow_UInt32_Equal_ReturnsFalse;
begin
  AssertFalse(IsSubUnderflow(UInt32(100), UInt32(100)));
  AssertFalse(IsSubUnderflow(UInt32(0), UInt32(0)));
end;

// === IsMulOverflow SizeUInt ===

procedure TTestMath.Test_IsMulOverflow_SizeUInt_NoOverflow_ReturnsFalse;
begin
  AssertFalse(IsMulOverflow(SizeUInt(100), SizeUInt(200)));
end;

procedure TTestMath.Test_IsMulOverflow_SizeUInt_Overflow_ReturnsTrue;
begin
  AssertTrue(IsMulOverflow(MAX_SIZE_UINT, SizeUInt(2)));
end;

procedure TTestMath.Test_IsMulOverflow_SizeUInt_Zero_ReturnsFalse;
begin
  AssertFalse(IsMulOverflow(SizeUInt(0), MAX_SIZE_UINT));
  AssertFalse(IsMulOverflow(MAX_SIZE_UINT, SizeUInt(0)));
end;

procedure TTestMath.Test_IsMulOverflow_SizeUInt_One_ReturnsFalse;
begin
  AssertFalse(IsMulOverflow(SizeUInt(1), MAX_SIZE_UINT));
  AssertFalse(IsMulOverflow(MAX_SIZE_UINT, SizeUInt(1)));
end;

procedure TTestMath.Test_IsMulOverflow_SizeUInt_Boundary_Success;
begin
  AssertFalse(IsMulOverflow(SizeUInt(65535), SizeUInt(65535)));
end;

// === IsMulOverflow UInt32 ===

procedure TTestMath.Test_IsMulOverflow_UInt32_NoOverflow_ReturnsFalse;
begin
  AssertFalse(IsMulOverflow(UInt32(100), UInt32(200)));
end;

procedure TTestMath.Test_IsMulOverflow_UInt32_Overflow_ReturnsTrue;
begin
  AssertTrue(IsMulOverflow(MAX_UINT32, UInt32(2)));
  AssertTrue(IsMulOverflow(UInt32(70000), UInt32(70000)));
end;

procedure TTestMath.Test_IsMulOverflow_UInt32_Zero_ReturnsFalse;
begin
  AssertFalse(IsMulOverflow(UInt32(0), MAX_UINT32));
  AssertFalse(IsMulOverflow(MAX_UINT32, UInt32(0)));
end;

// === SaturatingAdd ===

procedure TTestMath.Test_SaturatingAdd_SizeUInt_Normal_ReturnsSum;
begin
  AssertEquals(SizeUInt(150), SaturatingAdd(SizeUInt(100), SizeUInt(50)));
end;

procedure TTestMath.Test_SaturatingAdd_SizeUInt_Overflow_ReturnsMax;
var
  V: SizeUInt;
begin
  V := MAX_SIZE_UINT;
  AssertEquals(MAX_SIZE_UINT, SaturatingAdd(V, V));
end;

procedure TTestMath.Test_SaturatingAdd_SizeUInt_MaxPlusOne_ReturnsMax;
var
  V: SizeUInt;
begin
  V := MAX_SIZE_UINT;
  AssertEquals(MAX_SIZE_UINT, SaturatingAdd(V, SizeUInt(1)));
end;

procedure TTestMath.Test_SaturatingAdd_UInt32_Normal_ReturnsSum;
begin
  AssertEquals(UInt32(150), SaturatingAdd(UInt32(100), UInt32(50)));
end;

procedure TTestMath.Test_SaturatingAdd_UInt32_Overflow_ReturnsMax;
var
  V: UInt32;
begin
  V := MAX_UINT32;
  AssertEquals(MAX_UINT32, SaturatingAdd(V, V));
end;

// === SaturatingSub ===

procedure TTestMath.Test_SaturatingSub_SizeUInt_Normal_ReturnsDiff;
begin
  AssertEquals(SizeUInt(50), SaturatingSub(SizeUInt(100), SizeUInt(50)));
end;

procedure TTestMath.Test_SaturatingSub_SizeUInt_Underflow_ReturnsZero;
var
  Z: SizeUInt;
begin
  Z := 0;
  AssertEquals(SizeUInt(0), SaturatingSub(Z, MAX_SIZE_UINT));
end;

procedure TTestMath.Test_SaturatingSub_UInt32_Normal_ReturnsDiff;
begin
  AssertEquals(UInt32(50), SaturatingSub(UInt32(100), UInt32(50)));
end;

procedure TTestMath.Test_SaturatingSub_UInt32_Underflow_ReturnsZero;
var
  Z: UInt32;
begin
  Z := 0;
  AssertEquals(UInt32(0), SaturatingSub(Z, UInt32(1)));
end;

// === SaturatingMul ===

procedure TTestMath.Test_SaturatingMul_SizeUInt_Normal_ReturnsProduct;
begin
  AssertEquals(SizeUInt(5000), SaturatingMul(SizeUInt(100), SizeUInt(50)));
end;

procedure TTestMath.Test_SaturatingMul_SizeUInt_Overflow_ReturnsMax;
var
  V: SizeUInt;
begin
  V := MAX_SIZE_UINT;
  AssertEquals(MAX_SIZE_UINT, SaturatingMul(V, V));
end;

procedure TTestMath.Test_SaturatingMul_SizeUInt_Zero_ReturnsZero;
begin
  AssertEquals(SizeUInt(0), SaturatingMul(SizeUInt(0), MAX_SIZE_UINT));
end;

procedure TTestMath.Test_SaturatingMul_UInt32_Normal_ReturnsProduct;
begin
  AssertEquals(UInt32(5000), SaturatingMul(UInt32(100), UInt32(50)));
end;

procedure TTestMath.Test_SaturatingMul_UInt32_Overflow_ReturnsMax;
var
  V: UInt32;
begin
  V := MAX_UINT32;
  AssertEquals(MAX_UINT32, SaturatingMul(V, UInt32(2)));
end;

// === Min/Max helpers ===

procedure TTestMath.Test_Min_SizeUInt_Basic_ReturnsSmaller;
begin
  AssertEquals(SizeUInt(1), Min(SizeUInt(1), SizeUInt(2)));
  AssertEquals(SizeUInt(0), Min(MAX_SIZE_UINT, SizeUInt(0)));
end;

procedure TTestMath.Test_Max_SizeUInt_Basic_ReturnsLarger;
begin
  AssertEquals(SizeUInt(2), Max(SizeUInt(1), SizeUInt(2)));
  AssertEquals(MAX_SIZE_UINT, Max(MAX_SIZE_UINT, SizeUInt(0)));
end;

procedure TTestMath.Test_Min_Int64_Basic_ReturnsSmaller;
begin
  AssertEquals(Int64(-5), Min(Int64(-5), Int64(1)));
  AssertEquals(Low(Int64), Min(Low(Int64), Int64(0)));
end;

procedure TTestMath.Test_Max_Int64_Basic_ReturnsLarger;
begin
  AssertEquals(Int64(1), Max(Int64(-5), Int64(1)));
  AssertEquals(High(Int64), Max(Low(Int64), High(Int64)));
end;

initialization
  RegisterTest(TTestMath);
  RegisterTest(TTestMathRules);

end.
