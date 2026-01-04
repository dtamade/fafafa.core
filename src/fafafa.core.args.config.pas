unit fafafa.core.args.config;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes,
  fafafa.core.option.base,
  fafafa.core.option, fafafa.core.result, fafafa.core.env
  {$IFDEF FAFAFA_ARGS_CONFIG_TOML}
  , fafafa.core.toml
  {$ENDIF}
  {$IFDEF FAFAFA_ARGS_CONFIG_JSON}
  , fpjson, jsonparser
  {$ENDIF}
  ;

type
  TStringArray = array of string;

  // Environment value normalization flags
  TEnvFlags = set of (
    efTrimValues,       // trim whitespace around values
    efNormalizeBools    // normalize boolean-like strings (TRUE/yes/1 → 'true', FALSE/no/0 → 'false')
  );

// Option/Result 风格 API
function ArgsValueFromEnvOpt(const Prefix, Key: string; const Flags: TEnvFlags = []): specialize TOption<string>;
function ArgsTokenFromEnvOpt(const Prefix, Key: string; const Flags: TEnvFlags = []): specialize TOption<string>;
function ArgsTokensFromEnvOpt(const Prefix: string; const Allow, Deny: array of string; const Flags: TEnvFlags = []): specialize TOption<TStringArray>;
function ArgsIntFromEnvRes(const Prefix, Key: string; const Flags: TEnvFlags = []): specialize TResult<Integer, string>;

// ENV → argv
function ArgsArgvFromEnv(const Prefix: string): TStringArray;
function ArgsArgvFromEnvEx(const Prefix: string; const Allow, Deny: array of string; const Flags: TEnvFlags = []): TStringArray;

// Config file integration
function ArgsArgvFromToml(const Path: string): TStringArray;
function ArgsArgvFromJson(const Path: string): TStringArray;
// YAML is not supported yet: use the Opt variant to detect unsupported explicitly.
function ArgsArgvFromYaml(const Path: string): TStringArray;
function ArgsArgvFromYamlOpt(const Path: string): specialize TOption<TStringArray>;


implementation

uses
  fafafa.core.args.utils;

// ── 内部辅助函数 ──────────────────────────────────────────────

function LowerDash(const S: string): string; inline;
var i: Integer; R: string;
begin
  R := LowerCase(S);
  for i := 1 to Length(R) do
    if R[i] = '_' then R[i] := '-';
  Result := R;
end;

function ToEnvName(const Prefix, Key: string): string; inline;
var i: Integer; K: string;
begin
  K := Key;
  for i := 1 to Length(K) do
    if (K[i] = '-') or (K[i] = '.') then K[i] := '_';
  K := UpperCase(K);
  Result := UpperCase(Prefix) + K;
end;

function StartsWithCI(const S, Prefix: string): Boolean; inline;
begin
  Result := AnsiSameText(Copy(S, 1, Length(Prefix)), Prefix);
end;

function InSetCI(const S: string; const Arr: array of string): Boolean; inline;
var i: Integer;
begin
  if Length(Arr) = 0 then Exit(False);
  for i := Low(Arr) to High(Arr) do
    if AnsiSameText(S, Arr[i]) then Exit(True);
  Result := False;
end;

function MaybeNormalizeValue(const V: string; const Flags: TEnvFlags): string; inline;
var s: string;
begin
  s := V;
  if efTrimValues in Flags then s := Trim(s);
  // 使用统一的布尔值判断函数，支持 true/false/yes/no/1/0
  if efNormalizeBools in Flags then
  begin
    if IsTrueValue(s) then s := 'true'
    else if IsFalseValue(s) then s := 'false';
  end;
  Result := s;
end;

function NormalizeKeyFromEnv(const Key, Prefix: string): string;
var i: Integer; s: string;
begin
  s := Copy(Key, Length(Prefix) + 1, MaxInt);
  s := LowerCase(s);
  for i := 1 to Length(s) do
    if s[i] = '_' then s[i] := '-';
  Result := s;
end;

// ── Option/Result 风格 API 实现 ─────────────────────────────────

// ✅ P1-1: 新的 Args 前缀函数
function ArgsValueFromEnvOpt(const Prefix, Key: string; const Flags: TEnvFlags): specialize TOption<string>;
var Name, Val: string; Has: Boolean;
begin
  Name := ToEnvName(Prefix, Key);
  Has := env_lookup(Name, Val);
  if not Has then Exit(specialize TOption<string>.None);
  Val := MaybeNormalizeValue(Val, Flags);
  Exit(specialize TOption<string>.Some(Val));
end;

function ArgsTokenFromEnvOpt(const Prefix, Key: string; const Flags: TEnvFlags): specialize TOption<string>;
var OptVal: specialize TOption<string>; TokName, V: string;
begin
  OptVal := ArgsValueFromEnvOpt(Prefix, Key, Flags);
  if OptVal.IsNone then Exit(specialize TOption<string>.None);
  V := OptVal.Unwrap;
  TokName := '--' + LowerDash(Key);
  if V = '' then
    Exit(specialize TOption<string>.Some(TokName))
  else
    Exit(specialize TOption<string>.Some(TokName + '=' + V));
end;

function ArgsTokensFromEnvOpt(const Prefix: string; const Allow, Deny: array of string; const Flags: TEnvFlags): specialize TOption<TStringArray>;
var A: TStringArray;
begin
  A := ArgsArgvFromEnvEx(Prefix, Allow, Deny, Flags);
  if Length(A) = 0 then
    Exit(specialize TOption<TStringArray>.None)
  else
    Exit(specialize TOption<TStringArray>.Some(A));
end;

function ArgsIntFromEnvRes(const Prefix, Key: string; const Flags: TEnvFlags): specialize TResult<Integer, string>;
var OptVal: specialize TOption<string>; S: string; N: Integer;
begin
  OptVal := ArgsValueFromEnvOpt(Prefix, Key, Flags);
  if OptVal.IsNone then
    Exit(specialize TResult<Integer, string>.Err('env not set: ' + ToEnvName(Prefix, Key)));
  S := OptVal.Unwrap;
  if TryStrToInt(S, N) then
    Exit(specialize TResult<Integer, string>.Ok(N))
  else
    Exit(specialize TResult<Integer, string>.Err('invalid int: ' + S));
end;


// ── Argv 构建函数 ────────────────────────────────────────────

// ✅ P1-1: 新的 Args 前缀函数
function ArgsArgvFromEnvEx(const Prefix: string; const Allow, Deny: array of string; const Flags: TEnvFlags): TStringArray;
var
  kvp: TEnvKVPair;
  name, value, pfx, norm: string;

  procedure AddToken(const Tok: string); inline;
  begin
    SetLength(Result, Length(Result) + 1);
    Result[High(Result)] := Tok;
  end;

begin
  SetLength(Result, 0);
  if Prefix = '' then Exit;

  pfx := UpperCase(Prefix);
  for kvp in env_iter do
  begin
    name := kvp.Key;
    value := kvp.Value;

    if not StartsWithCI(UpperCase(name), pfx) then Continue;
    norm := NormalizeKeyFromEnv(name, pfx);
    if norm = '' then Continue;

    if (Length(Allow) > 0) and (not InSetCI(norm, Allow)) then Continue;
    if InSetCI(norm, Deny) then Continue;

    value := MaybeNormalizeValue(value, Flags);
    if value = '' then
      AddToken('--' + norm)
    else
      AddToken('--' + norm + '=' + value);
  end;
end;

function ArgsArgvFromEnv(const Prefix: string): TStringArray;
var
  kvp: TEnvKVPair;
  name, value, pfx, norm: string;

  procedure AddToken(const Tok: string); inline;
  begin
    SetLength(Result, Length(Result) + 1);
    Result[High(Result)] := Tok;
  end;

begin
  SetLength(Result, 0);
  if Prefix = '' then Exit;

  pfx := UpperCase(Prefix);
  for kvp in env_iter do
  begin
    name := kvp.Key;
    value := kvp.Value;

    if not StartsWithCI(UpperCase(name), pfx) then Continue;
    norm := NormalizeKeyFromEnv(name, pfx);
    if norm = '' then Continue;

    if value = '' then
      AddToken('--' + norm)
    else
      AddToken('--' + norm + '=' + value);
  end;
end;


{$IFDEF FAFAFA_ARGS_CONFIG_TOML}
procedure AppendToken(var Arr: TStringArray; const Tok: string); inline;
begin
  SetLength(Arr, Length(Arr)+1);
  Arr[High(Arr)] := Tok;
end;

function ScalarToString(const V: ITomlValue): string;
var s: string; i: Int64; b: Boolean; f: Double; t: string; FS: TFormatSettings;
begin
  Result := '';
  if V = nil then Exit('');
  case V.GetType of
    tvtString:  if V.TryGetString(s) then Exit(s);
    tvtInteger: if V.TryGetInteger(i) then Exit(IntToStr(i));
    tvtFloat:   begin FS := DefaultFormatSettings; FS.DecimalSeparator := '.'; if V.TryGetFloat(f) then Exit(FloatToStr(f, FS)); end;
    tvtBoolean: if V.TryGetBoolean(b) then Exit(LowerCase(BoolToStr(b, True)));
    tvtLocalDateTime, tvtLocalDate, tvtLocalTime, tvtOffsetDateTime:
      if V.TryGetTemporalText(t) then Exit(t);
  end;
end;

procedure WalkToml(const PrefixKey: string; const T: ITomlTable; var OutArr: TStringArray);
var idx: SizeInt; K, FullK, ValS: string; V, Item: ITomlValue; A: ITomlArray; j: SizeInt;
begin
  if (T = nil) then Exit;
  for idx := 0 to T.KeyCount-1 do
  begin
    K := T.KeyAt(idx);
    if PrefixKey<>'' then FullK := PrefixKey + '.' + LowerDash(K) else FullK := LowerDash(K);
    V := T.GetValue(K);
    if V = nil then Continue;
    case V.GetType of
      tvtTable:
        WalkToml(FullK, (V as ITomlTable), OutArr);
      tvtArray:
        begin
          A := (V as ITomlArray);
          for j := 0 to A.Count-1 do
          begin
            Item := A.Item(j);
            ValS := ScalarToString(Item);
            if ValS<>'' then AppendToken(OutArr, '--' + FullK + '=' + ValS);
          end;
        end;
    else
      begin
        ValS := ScalarToString(V);
        AppendToken(OutArr, '--' + FullK + '=' + ValS);
      end;
    end;
  end;
end;

// ✅ P1-1: 新的 Args 前缀函数
function ArgsArgvFromToml(const Path: string): TStringArray;
var Doc: ITomlDocument; Err: TTomlError;
begin
  SetLength(Result, 0);
  if (Path='') or (not FileExists(Path)) then Exit;
  Err.Clear;
  if not ParseFile(Path, Doc, Err) then Exit;
  if (Doc=nil) or (Doc.Root=nil) then Exit;
  WalkToml('', Doc.Root, Result);
end;

{$ELSE}
function ArgsArgvFromToml(const Path: string): TStringArray;
begin
  SetLength(Result, 0); // feature disabled or dependency unavailable
end;
{$ENDIF}


{$IFDEF FAFAFA_ARGS_CONFIG_JSON}
function JSONScalarToString(const D: TJSONData): string; inline;
begin
  if D=nil then Exit('');
  case D.JSONType of
    jtString:  Exit(D.AsString);
    jtNumber:  Exit(D.AsString);
    jtBoolean: if D.AsBoolean then Exit('true') else Exit('false');
  else
    Exit('');
  end;
end;

procedure WalkJson(const PrefixKey: string; const D: TJSONData; var OutArr: TStringArray);
var i: Integer; FullK, ValS, name: string; Obj: TJSONObject; Arr: TJSONArray; item: TJSONData;
begin
  if D=nil then Exit;
  case D.JSONType of
    jtObject:
      begin
        Obj := TJSONObject(D);
        for i := 0 to Obj.Count-1 do
        begin
          name := Obj.Names[i];
          if PrefixKey<>'' then FullK := PrefixKey + '.' + LowerDash(name) else FullK := LowerDash(name);
          item := Obj.Items[i];
          WalkJson(FullK, item, OutArr);
        end;
      end;
    jtArray:
      begin
        Arr := TJSONArray(D);
        for i := 0 to Arr.Count-1 do
        begin
          item := Arr.Items[i];
          ValS := JSONScalarToString(item);
          if ValS<>'' then AppendToken(OutArr, '--' + PrefixKey + '=' + ValS);
        end;
      end;
  else
    begin
      ValS := JSONScalarToString(D);
      if ValS<>'' then
        AppendToken(OutArr, '--' + PrefixKey + '=' + ValS);
    end;
  end;
end;

// ✅ P1-1: 新的 Args 前缀函数
function ArgsArgvFromJson(const Path: string): TStringArray;
var
  fs: TFileStream;
  P: TJSONParser;
  Root: TJSONData;
begin
  SetLength(Result, 0);
  if (Path='') or (not FileExists(Path)) then Exit;

  Root := nil;
  try
    try
      fs := TFileStream.Create(Path, fmOpenRead or fmShareDenyNone);
      try
{$push}
{$warn 5066 off}
        P := TJSONParser.Create(fs);
{$pop}
        try
          Root := P.Parse;
        finally
          P.Free;
        end;
      finally
        fs.Free;
      end;

      // Only object roots are supported for config flattening
      if (Root = nil) or (Root.JSONType <> jtObject) then
        Exit;

      WalkJson('', Root, Result);
    except
      // Parse/IO errors: return empty argv by contract
      SetLength(Result, 0);
    end;
  finally
    if Root <> nil then
      Root.Free;
  end;
end;

{$ELSE}
function ArgsArgvFromJson(const Path: string): TStringArray;
begin
  SetLength(Result, 0);
end;
{$ENDIF}

// ✅ P1-1: 新的 Args 前缀函数
function ArgsArgvFromYaml(const Path: string): TStringArray;
begin
  // YAML support is not ready; reserved for future implementation.
  // Prefer ArgsArgvFromYamlOpt for an explicit unsupported signal.
  SetLength(Result, 0);
end;

function ArgsArgvFromYamlOpt(const Path: string): specialize TOption<TStringArray>;
begin
  // YAML support is not ready; reserved for future implementation.
  Result := specialize TOption<TStringArray>.None;
end;


end.

