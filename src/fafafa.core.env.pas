unit fafafa.core.env;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes
  {$IFDEF ANDROID}
  , BaseUnix
  {$ENDIF}
  {$IFDEF WINDOWS}
  , Windows
  {$ENDIF}
  , fafafa.core.os
  {$IFDEF FAFAFA_ENV_ENABLE_RESULT}
  , fafafa.core.result
  {$ENDIF}
  ;

// Modern, cross-platform environment helpers inspired by Rust std::env and Go os
// Keep a C-style facade like fs_*: expose env_* functions for consistency.

{ ============================================================================ }
{ === Type Declarations ====================================================== }
{ ============================================================================ }

type
  // Basic types
  TStringArray = array of string;
  TEnvResolver = function(const Key: string; out Value: string): Boolean;

  // Key-Value pair for iteration
  TEnvKVPair = record
    Key: string;
    Value: string;
  end;

  // Key-Value for batch operations
  TEnvKV = record
    Name: string;
    Value: string;
    HasValue: Boolean; // False -> unset; True -> set Value (can be empty string)
  end;

  // Scoped override guard for a single variable.
  // IMPORTANT: FreePascal records have no auto-destructor. You MUST call Done
  // manually when the override scope ends (e.g., in a try/finally block).
  TEnvOverrideGuard = record
  private
    FName: string;
    FHadOriginal: Boolean;
    FOriginalValue: string;
    FActive: Boolean;
  public
    class function New(const AName, AValue: string): TEnvOverrideGuard; static;
    procedure Done; inline;
  end;

  // Scoped override guard for multiple variables.
  // IMPORTANT: FreePascal records have no auto-destructor. You MUST call Done
  // manually when the override scope ends (e.g., in a try/finally block).
  TEnvOverridesGuard = record
  private
    type
      TSnapshot = record
        Name: string;
        HadOriginal: Boolean;
        OriginalValue: string;
      end;
  private
    FSnaps: array of TSnapshot;
    FActive: Boolean;
  public
    class function BeginBatch(const Pairs: array of TEnvKV): TEnvOverridesGuard; static;
    procedure Done; inline;
  end;

  // Iterator for environment variables.
  // On Unix, iterates libc "environ" directly (no prebuilt TStringList snapshot).
  // On Windows, iterates GetEnvironmentStringsW block (no TStringList snapshot).
  // On other platforms, falls back to an os_environ snapshot.
  // Example:
  //   for kv in env_iter do
  //     WriteLn(kv.Key, '=', kv.Value);
  TEnvVarsEnumerator = record
  private
    type
      PState = ^TState;
      TState = record
        RefCount: LongInt;
        List: TStringList;
        Index: Integer;
        {$IFDEF UNIX}
        EnvP: PPChar;
        {$ENDIF}
        {$IFDEF WINDOWS}
        WinStart: PWideChar;
        WinCur: PWideChar;
        {$ENDIF}
        Current: TEnvKVPair;
      end;
  private
    FState: PState;
    function GetCurrent: TEnvKVPair; inline;
    class procedure StateAddRef(const S: PState); static; inline;
    class procedure StateRelease(var S: PState); static;
    class operator Initialize(var r: TEnvVarsEnumerator);
    class operator Finalize(var r: TEnvVarsEnumerator);
    class operator Copy(constref src: TEnvVarsEnumerator; var dst: TEnvVarsEnumerator);
  public
    function GetEnumerator: TEnvVarsEnumerator;
    function MoveNext: Boolean;
    property Current: TEnvKVPair read GetCurrent;
    procedure Free; inline; // Safe to call; releases resources if not already released
  end;

  // Error types (for Result API)
  EVarErrorKind = (
    vekNotDefined
  );

  EVarError = record
    Kind: EVarErrorKind;
    Name: string;
    Msg: string;
  end;

  EPathJoinErrorKind = (
    pjekContainsSeparator
  );

  EPathJoinError = record
    Kind: EPathJoinErrorKind;
    Index: Integer;
    Separator: Char;
    Segment: string;
    Msg: string;
  end;

  EIOErrorKind = (
    ioekGetcwdFailed,
    ioekChdirFailed,
    ioekHomeDirFailed,
    ioekTempDirFailed,
    ioekExePathFailed,
    ioekUserConfigDirFailed,
    ioekUserCacheDirFailed
  );

  EIOError = record
    Kind: EIOErrorKind;
    Op: string; // 'getcwd' or 'chdir'
    Path: string;
    Code: Integer; // OS error code if available, else 0
    SysMsg: string; // OS error message for Code (SysErrorMessage(Code)), or ''
    Msg: string;
  end;

  // Exception
  EEnvVarNotFound = class(Exception);

{$IFDEF FAFAFA_ENV_ENABLE_RESULT}
  // Result types
  TResultString_VarError = specialize TResult<string, EVarError>;
  TResultString_PathJoinError = specialize TResult<string, EPathJoinError>;
  TResultString_IOError = specialize TResult<string, EIOError>;
  TResultUnit_IOError = specialize TResult<Boolean, EIOError>;
{$ENDIF}

{ ============================================================================ }
{ === Basic Operations ======================================================= }
{ ============================================================================ }

function env_get(const AName: string): string; inline;
function env_lookup(const AName: string; out AValue: string): Boolean; inline;
function env_get_or(const AName, ADefault: string): string; inline;
function env_set(const AName, AValue: string): Boolean; inline;
function env_unset(const AName: string): Boolean; inline;
function env_has(const AName: string): Boolean; inline;
procedure env_vars(const ADest: TStrings); inline;
procedure env_vars_masked(const ADest: TStrings);
function env_required(const AName: string): string;
function env_keys: TStringArray;
function env_count: Integer; inline;

{ ============================================================================ }
{ === Typed Getters ========================================================== }
{ ============================================================================ }

function env_get_bool(const AName: string; ADefault: Boolean = False): Boolean;
function env_get_int(const AName: string; ADefault: Integer = 0): Integer;
function env_get_int64(const AName: string; ADefault: Int64 = 0): Int64;
function env_get_uint(const AName: string; ADefault: Cardinal = 0): Cardinal;
function env_get_uint64(const AName: string; ADefault: QWord = 0): QWord;
function env_get_duration_ms(const AName: string; ADefault: QWord = 0): QWord;
function env_get_size_bytes(const AName: string; ADefault: QWord = 0): QWord;
function env_get_float(const AName: string; ADefault: Double = 0.0): Double;
function env_get_list(const AName: string; ASeparator: Char = ','): TStringArray;
function env_get_paths(const AName: string): TStringArray;

{ ============================================================================ }
{ === Convenience & Security Helpers ======================================== }
{ ============================================================================ }

function env_lookup_nonempty(const AName: string; out AValue: string): Boolean; inline;
function env_has_nonempty(const AName: string): Boolean; inline;
function env_get_nonempty_or(const AName, ADefault: string): string; inline;
function env_mask_value_for_name(const AName, AValue: string): string; inline;

{ ============================================================================ }
{ === Scoped Override Guards (Manual Cleanup) ================================ }
{ ============================================================================ }

function env_override(const AName, AValue: string): TEnvOverrideGuard; inline;
function env_override_unset(const AName: string): TEnvOverrideGuard; inline;
function env_overrides(const Pairs: array of TEnvKV): TEnvOverridesGuard; inline;

{ ============================================================================ }
{ === String Expansion ======================================================= }
{ ============================================================================ }

function env_expand(const S: string): string;
function env_expand_with(const S: string; Resolver: TEnvResolver): string;
function env_expand_env(const S: string): string;

{ ============================================================================ }
{ === PATH Handling ========================================================== }
{ ============================================================================ }

function env_path_list_separator: Char; inline;
function env_split_paths(const S: string): TStringArray;
function env_join_paths(const Paths: array of string): string;
function env_join_paths_checked(const Paths: array of string; out ErrIndex: Integer): string;

{ ============================================================================ }
{ === Directories & Process ================================================== }
{ ============================================================================ }

function env_current_dir: string; inline;
function env_set_current_dir(const APath: string): Boolean; inline;
function env_home_dir: string; inline;
function env_temp_dir: string; inline;
function env_executable_path: string; inline;
function env_user_config_dir: string;
function env_user_cache_dir: string;

{ ============================================================================ }
{ === Security Helpers ======================================================= }
{ ============================================================================ }

function env_is_sensitive_name(const AName: string): Boolean;
function env_mask_value(const AValue: string): string;
function env_validate_name(const AName: string): Boolean;

{ ============================================================================ }
{ === Platform Constants ===================================================== }
{ ============================================================================ }

function env_os: string; inline;
function env_arch: string; inline;
function env_family: string; inline;
function env_is_windows: Boolean; inline;
function env_is_unix: Boolean; inline;
function env_is_darwin: Boolean; inline;

{ ============================================================================ }
{ === Iterator API =========================================================== }
{ ============================================================================ }

function env_iter: TEnvVarsEnumerator;

{$IFDEF FAFAFA_ENV_DEBUG_ITER}
function env_iter_debug_active_states: Integer; inline;
procedure env_iter_debug_reset_states; inline;
{$ENDIF}

{ ============================================================================ }
{ === Command-line Arguments ================================================= }
{ ============================================================================ }

function env_args: TStringArray;
function env_args_count: Integer; inline;
function env_arg(Index: Integer): string; inline;

{ ============================================================================ }
{ === Sandbox Operations ===================================================== }
{ ============================================================================ }

procedure env_clear_all; // WARNING: Removes ALL environment variables!

{ ============================================================================ }
{ === Result API (Conditional) =============================================== }
{ ============================================================================ }
// To enable Result-based APIs, define FAFAFA_ENV_ENABLE_RESULT in your project
// or in fafafa.core.settings.inc (enabled by default in settings.inc).
// These functions return TResult<T, E> instead of raising exceptions.

{$IFDEF FAFAFA_ENV_ENABLE_RESULT}
function env_get_result(const AName: string): TResultString_VarError;
function env_join_paths_result(const Paths: array of string): TResultString_PathJoinError;
function env_current_dir_result: TResultString_IOError;
function env_set_current_dir_result(const APath: string): TResultUnit_IOError;
function env_home_dir_result: TResultString_IOError;
function env_temp_dir_result: TResultString_IOError;
function env_executable_path_result: TResultString_IOError;
function env_user_config_dir_result: TResultString_IOError;
function env_user_cache_dir_result: TResultString_IOError;
{$ENDIF}

implementation

{$IFDEF UNIX}
var
  environ: PPChar; cvar; external;
{$ENDIF}

// Internal helper: parse NAME=VALUE line
procedure ParseEnvLine(const Line: string; out Key, Value: string); inline;
var
  EqPos: Integer;
begin
  EqPos := Pos('=', Line);
  if EqPos > 0 then
  begin
    Key := Copy(Line, 1, EqPos - 1);
    Value := Copy(Line, EqPos + 1, Length(Line) - EqPos);
  end
  else
  begin
    Key := Line;
    Value := '';
  end;
end;

// Core override guard functions (always available)
function env_override(const AName, AValue: string): TEnvOverrideGuard; inline;
begin
  Result := TEnvOverrideGuard.New(AName, AValue);
end;

// Internal: OS-based resolver for env_expand_env
function env_resolve_os(const Key: string; out Value: string): Boolean;
begin
  Result := env_lookup(Key, Value);
end;

class function TEnvOverrideGuard.New(const AName, AValue: string): TEnvOverrideGuard;
begin
  Result.FName := AName;
  Result.FOriginalValue := '';
  Result.FHadOriginal := env_lookup(AName, Result.FOriginalValue);
  // New semantics: empty string is a valid value; do not treat as unset
  env_set(AName, AValue);
  Result.FActive := True;
end;

function env_override_unset(const AName: string): TEnvOverrideGuard; inline;
var
  __chk: string;
begin
  // Build guard manually and force empty value during override period (env_get returns '' by contract)
  Result.FName := AName;
  Result.FOriginalValue := '';
  Result.FHadOriginal := env_lookup(AName, Result.FOriginalValue);
  // Try set empty first; if still non-empty, try unset; then set empty again as final fallback
  env_set(AName, '');
  __chk := env_get(AName);
  if __chk <> '' then
  begin
    env_unset(AName);
    __chk := env_get(AName);
    if __chk <> '' then
      env_set(AName, '');
  end;
  Result.FActive := True;
end;


function env_overrides(const Pairs: array of TEnvKV): TEnvOverridesGuard;
begin
  Result := TEnvOverridesGuard.BeginBatch(Pairs);
end;

class function TEnvOverridesGuard.BeginBatch(const Pairs: array of TEnvKV): TEnvOverridesGuard;
var
  I: Integer;
  SnapCount: Integer;
  Seen: TStringList;
  Name, Orig: string;
  Had: Boolean;
  // helper to snapshot once per unique key (keep first occurrence)
  function HasSeen(const K: string): Boolean;
  begin
    Result := Seen.IndexOf(K) >= 0;
  end;
  procedure MarkSeen(const K: string);
  begin
    Seen.Add(K);
  end;
begin
  {$IFDEF FPC}
  Result.FSnaps := nil;
  Result.FActive := False;
  {$ENDIF}
  Seen := TStringList.Create;
  try
    {$IFDEF WINDOWS} Seen.CaseSensitive := False; {$ELSE} Seen.CaseSensitive := True; {$ENDIF}
    Seen.Sorted := True; Seen.Duplicates := dupIgnore;

    // 1) snapshot original values for first occurrence of each key
    SnapCount := 0;
    for I := 0 to High(Pairs) do
    begin
      Name := Pairs[I].Name;
      if Name = '' then Continue;
      if HasSeen(Name) then Continue;
      MarkSeen(Name);
      Had := env_lookup(Name, Orig);
      Inc(SnapCount);
      SetLength(Result.FSnaps, SnapCount);
      Result.FSnaps[SnapCount-1].Name := Name;
      Result.FSnaps[SnapCount-1].HadOriginal := Had;
      Result.FSnaps[SnapCount-1].OriginalValue := Orig;
    end;

    // 2) apply overrides in order so that last one wins
    for I := 0 to High(Pairs) do
    begin
      Name := Pairs[I].Name;
      if Name = '' then Continue;
      if Pairs[I].HasValue then
        env_set(Name, Pairs[I].Value)
      else
        env_unset(Name);
    end;

    Result.FActive := True;
  finally
    Seen.Free;
  end;
end;

{$IFDEF FAFAFA_ENV_ENABLE_RESULT}
// Result-enabled section

function env_get_result(const AName: string): TResultString_VarError;
var
  v: string;
  e: EVarError;
begin
  if env_lookup(AName, v) then
    Exit(TResultString_VarError.Ok(v))
  else
  begin
    e.Kind := vekNotDefined;
    e.Name := AName;
    e.Msg := 'environment variable "' + AName + '" not defined';
    Exit(TResultString_VarError.Err(e));
  end;
end;

function env_join_paths_result(const Paths: array of string): TResultString_PathJoinError;
var
  idx: Integer;
  joined: string;
  pe: EPathJoinError;
  sep: Char;
begin
  joined := env_join_paths_checked(Paths, idx);
  if (joined <> '') or (idx = -1) then
    Exit(TResultString_PathJoinError.Ok(joined))
  else
  begin
    sep := env_path_list_separator;
    pe.Kind := pjekContainsSeparator;
    pe.Index := idx;
    pe.Separator := sep;
    if (idx >= Low(Paths)) and (idx <= High(Paths)) then pe.Segment := Paths[idx] else pe.Segment := '';
    pe.Msg := 'path segment at index=' + IntToStr(idx) + ' contains separator "' + sep + '"' + ': "' + pe.Segment + '"';
    Exit(TResultString_PathJoinError.Err(pe));
  end;
end;

function env_current_dir_result: TResultString_IOError;
var
  cwd: string;
  ioe: EIOError;
begin
  cwd := env_current_dir;
  if cwd <> '' then
    Exit(TResultString_IOError.Ok(cwd))
  else
  begin
    ioe.Kind := ioekGetcwdFailed;
    ioe.Op := 'getcwd';
    ioe.Path := '';
    ioe.Code := GetLastOSError;
    ioe.SysMsg := SysErrorMessage(ioe.Code);
    ioe.Msg := 'getcwd failed (code=' + IntToStr(ioe.Code) + '): ' + ioe.SysMsg;
    Exit(TResultString_IOError.Err(ioe));
  end;
end;

function env_set_current_dir_result(const APath: string): TResultUnit_IOError;
var
  ioe: EIOError;
  code: Integer;
begin
  if env_set_current_dir(APath) then
    Exit(TResultUnit_IOError.Ok(True))
  else
  begin
    code := GetLastOSError;
    ioe.Kind := ioekChdirFailed;
    ioe.Op := 'chdir';
    ioe.Path := APath;
    ioe.Code := code;
    ioe.SysMsg := SysErrorMessage(code);
    ioe.Msg := 'chdir "' + APath + '" failed (code=' + IntToStr(code) + '): ' + ioe.SysMsg;
    Exit(TResultUnit_IOError.Err(ioe));
  end;
end;

function env_home_dir_result: TResultString_IOError;
var s: string; e: EIOError;
begin
  s := env_home_dir;
  if s <> '' then
    Exit(TResultString_IOError.Ok(s))
  else
  begin
    e.Kind := ioekHomeDirFailed;
    e.Op := 'homedir';
    e.Path := '';
    e.Code := 0;
    e.SysMsg := '';
    e.Msg := 'failed to resolve home directory';
    Exit(TResultString_IOError.Err(e));
  end;
end;

function env_temp_dir_result: TResultString_IOError;
var s: string; e: EIOError;
begin
  s := env_temp_dir;
  if s <> '' then
    Exit(TResultString_IOError.Ok(s))
  else
  begin
    e.Kind := ioekTempDirFailed;
    e.Op := 'tempdir';
    e.Path := '';
    e.Code := 0;
    e.SysMsg := '';
    e.Msg := 'failed to resolve temp directory';
    Exit(TResultString_IOError.Err(e));
  end;
end;

function env_executable_path_result: TResultString_IOError;
var s: string; e: EIOError;
begin
  s := env_executable_path;
  if s <> '' then
    Exit(TResultString_IOError.Ok(s))
  else
  begin
    e.Kind := ioekExePathFailed;
    e.Op := 'exepath';
    e.Path := '';
    e.Code := 0;
    e.SysMsg := '';
    e.Msg := 'failed to resolve executable path';
    Exit(TResultString_IOError.Err(e));
  end;
end;

function env_user_config_dir_result: TResultString_IOError;
var s: string; e: EIOError;
begin
  s := env_user_config_dir;
  if s <> '' then
    Exit(TResultString_IOError.Ok(s))
  else
  begin
    e.Kind := ioekUserConfigDirFailed;
    e.Op := 'user_config_dir';
    e.Path := '';
    e.Code := 0;
    e.SysMsg := '';
    e.Msg := 'failed to resolve user config dir';
    Exit(TResultString_IOError.Err(e));
  end;
end;

function env_user_cache_dir_result: TResultString_IOError;
var s: string; e: EIOError;
begin
  s := env_user_cache_dir;
  if s <> '' then
    Exit(TResultString_IOError.Ok(s))
  else
  begin
    e.Kind := ioekUserCacheDirFailed;
    e.Op := 'user_cache_dir';
    e.Path := '';
    e.Code := 0;
    e.SysMsg := '';
    e.Msg := 'failed to resolve user cache dir';
    Exit(TResultString_IOError.Err(e));
  end;
end;

{$ENDIF}

procedure TEnvOverridesGuard.Done; inline;
var
  I: Integer;
begin
  if not FActive then Exit;
  for I := 0 to High(FSnaps) do
  begin
    if FSnaps[I].HadOriginal then
      env_set(FSnaps[I].Name, FSnaps[I].OriginalValue)
    else
      env_unset(FSnaps[I].Name);
  end;
  FActive := False;
end;


procedure TEnvOverrideGuard.Done; inline;
begin
  if not FActive then Exit;
  if FHadOriginal then
    env_set(FName, FOriginalValue)
  else
    env_unset(FName);
  FActive := False;
end;


function env_get(const AName: string): string; inline;
begin
  if AName = '' then Exit('');
  Result := os_getenv(AName);
end;

function env_get_or(const AName, ADefault: string): string; inline;
begin
  if AName = '' then Exit(ADefault);
  if not env_lookup(AName, Result) then
    Result := ADefault;
end;


function env_set(const AName, AValue: string): Boolean; inline;
begin
  if AName = '' then Exit(False);
  Result := os_setenv(AName, AValue);
end;

function env_unset(const AName: string): Boolean; inline;
begin
  if AName = '' then Exit(False);
  Result := os_unsetenv(AName);
end;

procedure env_vars(const ADest: TStrings); inline;
begin
  if not Assigned(ADest) then Exit;
  os_environ(ADest);
end;

procedure env_vars_masked(const ADest: TStrings);
var
  kv: TEnvKVPair;
begin
  if not Assigned(ADest) then Exit;
  ADest.Clear;
  for kv in env_iter do
    ADest.Add(kv.Key + '=' + env_mask_value_for_name(kv.Key, kv.Value));
end;


function env_lookup(const AName: string; out AValue: string): Boolean; inline;
begin
  if AName = '' then
  begin
    AValue := '';
    Exit(False);
  end;
  // Delegate to os_lookupenv for performance and correct semantics (distinguish undefined vs empty)
  Result := os_lookupenv(AName, AValue);
end;

function env_has(const AName: string): Boolean; inline;
var dummy: string;
begin
  if AName = '' then Exit(False);
  Result := env_lookup(AName, dummy);
end;

function env_lookup_nonempty(const AName: string; out AValue: string): Boolean; inline;
var
  V: string;
begin
  AValue := '';
  if not env_lookup(AName, V) then
    Exit(False);
  if V = '' then
    Exit(False);
  AValue := V;
  Result := True;
end;

function env_has_nonempty(const AName: string): Boolean; inline;
var
  Dummy: string;
begin
  Result := env_lookup_nonempty(AName, Dummy);
end;

function env_get_nonempty_or(const AName, ADefault: string): string; inline;
begin
  if not env_lookup_nonempty(AName, Result) then
    Result := ADefault;
end;

function env_mask_value_for_name(const AName, AValue: string): string; inline;
begin
  if env_is_sensitive_name(AName) then
    Result := env_mask_value(AValue)
  else
    Result := AValue;
end;

function env_expand_with(const S: string; Resolver: TEnvResolver): string;
var
  I, L, NameStart, LiteralStart: Integer;
  C: Char;
  Name, Val: string;
  Builder: TStringBuilder;
  HasMarker: Boolean;

  procedure FlushLiteral;
  begin
    if LiteralStart < I then
      Builder.Append(Copy(S, LiteralStart, I - LiteralStart));
  end;

  procedure AppendResolved(const Key: string);
  begin
    if Assigned(Resolver) and Resolver(Key, Val) then
      Builder.Append(Val);
  end;

begin
  if S = '' then Exit('');
  L := Length(S);

  // Fast path: no variable markers -> return original string
  HasMarker := False;
  for I := 1 to L do
  begin
    C := S[I];
    if (C = '$') {$IFDEF WINDOWS} or (C = '%') {$ENDIF} then
    begin
      HasMarker := True;
      Break;
    end;
  end;
  if not HasMarker then Exit(S);

  // Slow path: parse and expand
  Builder := TStringBuilder.Create(L + L div 2);
  try
    I := 1;
    LiteralStart := 1;
    while I <= L do
    begin
      C := S[I];
      if C = '$' then
      begin
        FlushLiteral;
        Inc(I);
        if (I <= L) and (S[I] = '$') then
        begin
          Builder.Append('$');
          Inc(I);
          LiteralStart := I;
          Continue;
        end;
        if (I <= L) and (S[I] = '{') then
        begin
          Inc(I);
          NameStart := I;
          while (I <= L) and (S[I] <> '}') do Inc(I);
          Name := Copy(S, NameStart, I - NameStart);
          if (I <= L) and (S[I] = '}') then Inc(I);
          AppendResolved(Name);
          LiteralStart := I;
        end
        else if (I <= L) and (S[I] in ['A'..'Z','a'..'z','_']) then
        begin
          NameStart := I;
          while (I <= L) and (S[I] in ['A'..'Z','a'..'z','0'..'9','_']) do Inc(I);
          Name := Copy(S, NameStart, I - NameStart);
          AppendResolved(Name);
          LiteralStart := I;
        end
        else
        begin
          Builder.Append('$');
          LiteralStart := I;
        end;
      end
      {$IFDEF WINDOWS}
      else if C = '%' then
      begin
        FlushLiteral;
        if (I+1 <= L) and (S[I+1] = '%') then
        begin
          Builder.Append('%');
          Inc(I, 2);
          LiteralStart := I;
          Continue;
        end;
        Inc(I);
        NameStart := I;
        while (I <= L) and (S[I] <> '%') do Inc(I);
        if (I <= L) and (S[I] = '%') then
        begin
          Name := Copy(S, NameStart, I - NameStart);
          Inc(I);
          AppendResolved(Name);
          LiteralStart := I;
          Continue;
        end;
        // unmatched: treat literally
        Name := Copy(S, NameStart, I - NameStart);
        Builder.Append('%').Append(Name);
        LiteralStart := I;
      end
      {$ENDIF}
      else
        Inc(I);
    end;
    FlushLiteral;
    Result := Builder.ToString;
  finally
    Builder.Free;
  end;
end;

function env_expand_env(const S: string): string;
begin
  // Fallback to OS lookup based expansion to avoid nested resolver incompatibility
  Result := env_expand_with(S, @env_resolve_os);
end;



function env_path_list_separator: Char; inline;
begin
  {$IFDEF WINDOWS}
  Result := ';';
  {$ELSE}
  Result := ':';
  {$ENDIF}
end;

function env_split_paths(const S: string): TStringArray;
var
  Sep: Char;
  I, StartIdx, Count, Capacity: Integer;
  Item: string;

  procedure AddItem(const AItem: string);
  begin
    if AItem = '' then Exit;
    if Count >= Capacity then
    begin
      if Capacity = 0 then
        Capacity := 4
      else
        Capacity := Capacity * 2;
      SetLength(Result, Capacity);
    end;
    Result[Count] := AItem;
    Inc(Count);
  end;

begin
  Result := nil;
  if S = '' then Exit;

  Sep := env_path_list_separator;
  Count := 0;
  Capacity := 0;
  StartIdx := 1;

  for I := 1 to Length(S) do
  begin
    if S[I] = Sep then
    begin
      Item := Copy(S, StartIdx, I - StartIdx);
      AddItem(Item);
      StartIdx := I + 1;
    end;
  end;

  // Handle tail
  Item := Copy(S, StartIdx, Length(S) - StartIdx + 1);
  AddItem(Item);

  // Trim to actual size
  SetLength(Result, Count);
end;

function env_join_paths_checked(const Paths: array of string; out ErrIndex: Integer): string;
var
  Sep: Char;
  I, TotalLen: Integer;
  P: string;
  Builder: TStringBuilder;
  FirstItem: Boolean;
begin
  Sep := env_path_list_separator;
  ErrIndex := -1;

  // Pre-calculate approximate capacity
  TotalLen := 0;
  for I := Low(Paths) to High(Paths) do
    if Paths[I] <> '' then
      Inc(TotalLen, Length(Paths[I]) + 1); // +1 for separator

  if TotalLen = 0 then Exit('');

  Builder := TStringBuilder.Create(TotalLen);
  try
    FirstItem := True;
    for I := Low(Paths) to High(Paths) do
    begin
      P := Paths[I];
      if P = '' then Continue;

      // Check if segment contains the separator, fail like Rust's join_paths
      if Pos(Sep, P) > 0 then
      begin
        ErrIndex := I;
        Exit('');
      end;

      if not FirstItem then
        Builder.Append(Sep);
      Builder.Append(P);
      FirstItem := False;
    end;

    Result := Builder.ToString;
  finally
    Builder.Free;
  end;
end;

function env_join_paths(const Paths: array of string): string;
var
  ErrIndex: Integer;
begin
  Result := env_join_paths_checked(Paths, ErrIndex);
  // if error, we still return '' to keep compatibility
end;


function env_expand(const S: string): string;
begin
  // Delegate to env-based expansion (with $$/%% support and consistent undefined semantics)
  Result := env_expand_env(S);
end;

function env_current_dir: string; inline;
begin
  Result := GetCurrentDir;
end;

function env_set_current_dir(const APath: string): Boolean; inline;
begin
  Result := SetCurrentDir(APath);
end;

{$IFDEF ANDROID}
function _android_read_proc_cmdline: string;
var
  fs: TFileStream;
  buf: array[0..4095] of Byte;
  n, p: Integer;
  s: RawByteString;
begin
  Result := '';
  try
    fs := TFileStream.Create('/proc/self/cmdline', fmOpenRead or fmShareDenyNone);
    try
      n := fs.Read(buf, SizeOf(buf));
      if n <= 0 then Exit('');
      SetString(s, PAnsiChar(@buf[0]), n);
      p := Pos(#0, s);
      if p > 0 then
        SetLength(s, p - 1);
      Result := string(s);
    finally
      fs.Free;
    end;
  except
    Result := '';
  end;
end;

function _android_process_name: string; inline;
begin
  Result := env_get('FAFAFA_ANDROID_PROCESS_NAME');
  if Result <> '' then Exit;
  Result := _android_read_proc_cmdline;
end;

function _android_package_name: string;
var
  s: string;
  i, p: Integer;
  c: Char;
begin
  Result := '';
  s := _android_process_name;
  if s = '' then Exit;

  // Trim optional process suffix like com.example.app:service
  p := Pos(':', s);
  if p > 0 then
    s := Copy(s, 1, p - 1);

  // Basic validation: must look like a Java package name
  if Pos('.', s) <= 0 then Exit;
  for i := 1 to Length(s) do
  begin
    c := s[i];
    if not (c in ['A'..'Z','a'..'z','0'..'9','_','.']) then
      Exit('');
  end;
  Result := s;
end;

function _android_user_id: Integer;
var
  s: string;
  code: Integer;
  uid: LongInt;
begin
  s := env_get('FAFAFA_ANDROID_USER_ID');
  if s <> '' then
  begin
    Val(Trim(s), Result, code);
    if code = 0 then Exit;
  end;

  // Android: userId is encoded in uid (PER_USER_RANGE = 100000)
  uid := fpGetUID;
  if uid < 0 then uid := 0;
  Result := uid div 100000;
end;

function _android_data_root: string; inline;
begin
  Result := env_get('FAFAFA_ANDROID_DATA_ROOT');
  if Result = '' then
    Result := '/data';
  Result := ExcludeTrailingPathDelimiter(Result);
end;

function _android_data_dir: string;
var
  s, root, pkg, cand: string;
  userId: Integer;
begin
  Result := '';

  // Explicit override (useful for tests and exotic runtimes)
  s := env_get('FAFAFA_ANDROID_DATA_DIR');
  if s <> '' then
    Exit(ExcludeTrailingPathDelimiter(s));

  root := _android_data_root;
  pkg := _android_package_name;
  if pkg = '' then Exit('');

  userId := _android_user_id;

  // Primary: /data/user/<userId>/<pkg>
  cand := root + PathDelim + 'user' + PathDelim + IntToStr(userId) + PathDelim + pkg;
  if DirectoryExists(cand) then Exit(cand);

  // Legacy symlink for primary user: /data/data/<pkg>
  cand := root + PathDelim + 'data' + PathDelim + pkg;
  if DirectoryExists(cand) then Exit(cand);

  // Fallback: user 0
  cand := root + PathDelim + 'user' + PathDelim + '0' + PathDelim + pkg;
  if DirectoryExists(cand) then Exit(cand);

  Result := '';
end;

function _android_files_dir: string; inline;
var d: string;
begin
  d := _android_data_dir;
  if d = '' then Exit('');
  Result := d + PathDelim + 'files';
end;

function _android_cache_dir: string; inline;
var d: string;
begin
  d := _android_data_dir;
  if d = '' then Exit('');
  Result := d + PathDelim + 'cache';
end;
{$ENDIF}

function env_home_dir: string; inline;
{$IFDEF ANDROID}
var s: string;
begin
  s := _android_files_dir;
  if s <> '' then Exit(s);
  Result := os_home_dir;
end;
{$ELSE}
begin
  Result := os_home_dir;
end;
{$ENDIF}

function env_temp_dir: string; inline;
{$IFDEF ANDROID}
var s: string;
begin
  // Prefer standard temp env vars first
  s := env_get('TMPDIR');
  if s <> '' then Exit(ExcludeTrailingPathDelimiter(s));

  // Android best-effort: use app cache dir
  s := _android_cache_dir;
  if s <> '' then Exit(s);

  Result := os_temp_dir;
end;
{$ELSE}
begin
  Result := os_temp_dir;
end;
{$ENDIF}

function env_executable_path: string; inline;
begin
  Result := os_exe_path;
end;

function env_user_config_dir: string;
var
  S: string;
begin
  {$IFDEF WINDOWS}
  S := env_get('APPDATA');
  if S <> '' then Exit(S);
  // fallback to home
  S := env_home_dir; if S <> '' then Exit(S + PathDelim + 'AppData' + PathDelim + 'Roaming');
  {$ELSEIF DEFINED(ANDROID)}
  S := _android_files_dir;
  if S <> '' then Exit(S);
  // fallback to XDG
  S := env_get('XDG_CONFIG_HOME');
  if S <> '' then Exit(S);
  S := env_home_dir; if S <> '' then Exit(S + PathDelim + '.config');
  {$ELSEIF DEFINED(DARWIN)}
  S := env_home_dir;
  if S <> '' then Exit(S + PathDelim + 'Library' + PathDelim + 'Application Support');
  {$ELSE}
  S := env_get('XDG_CONFIG_HOME');
  if S <> '' then Exit(S);
  S := env_home_dir; if S <> '' then Exit(S + PathDelim + '.config');
  {$ENDIF}
  Result := '';
end;

function env_user_cache_dir: string;
var
  S: string;
begin
  {$IFDEF WINDOWS}
  S := env_get('LOCALAPPDATA');
  if S <> '' then Exit(S);
  // fallback
  S := env_home_dir; if S <> '' then Exit(S + PathDelim + 'AppData' + PathDelim + 'Local');
  {$ELSEIF DEFINED(ANDROID)}
  S := _android_cache_dir;
  if S <> '' then Exit(S);
  // fallback to XDG
  S := env_get('XDG_CACHE_HOME');
  if S <> '' then Exit(S);
  S := env_home_dir; if S <> '' then Exit(S + PathDelim + '.cache');
  {$ELSEIF DEFINED(DARWIN)}
  S := env_home_dir;
  if S <> '' then Exit(S + PathDelim + 'Library' + PathDelim + 'Caches');
  {$ELSE}
  S := env_get('XDG_CACHE_HOME');
  if S <> '' then Exit(S);
  S := env_home_dir; if S <> '' then Exit(S + PathDelim + '.cache');
  {$ENDIF}
  Result := '';
end;

// Security helpers (2024 best practices)
function env_is_sensitive_name(const AName: string): Boolean;
var
  UpperName: string;
  I, StartIdx: Integer;

  function IsDigitsSuffix(const S: string; const StartAt: Integer): Boolean;
  var
    J: Integer;
  begin
    if (StartAt <= 0) or (StartAt > Length(S)) then Exit(False);
    for J := StartAt to Length(S) do
      if not (S[J] in ['0'..'9']) then
        Exit(False);
    Result := True;
  end;

  function TokenEqualsOrDigitsSuffix(const Token, Base: string): Boolean;
  var
    L: Integer;
  begin
    if Token = Base then Exit(True);
    L := Length(Base);
    if (Length(Token) > L) and (Copy(Token, 1, L) = Base) and IsDigitsSuffix(Token, L + 1) then
      Exit(True);
    Result := False;
  end;

  function IsSensitiveToken(const Token: string): Boolean;
  begin
    // Token is expected to be uppercase and contain only [A-Z0-9]
    if TokenEqualsOrDigitsSuffix(Token, 'PASSWORD') then Exit(True);
    if TokenEqualsOrDigitsSuffix(Token, 'PASSWD') then Exit(True);
    if TokenEqualsOrDigitsSuffix(Token, 'PASS') then Exit(True);
    if TokenEqualsOrDigitsSuffix(Token, 'PWD') then Exit(True);
    if TokenEqualsOrDigitsSuffix(Token, 'SECRET') then Exit(True);
    if TokenEqualsOrDigitsSuffix(Token, 'TOKEN') then Exit(True);
    if TokenEqualsOrDigitsSuffix(Token, 'KEY') then Exit(True);

    if Token = 'PRIVATE' then Exit(True);
    if Token = 'CREDENTIAL' then Exit(True);
    if Token = 'CREDENTIALS' then Exit(True);
    if Token = 'AUTH' then Exit(True);
    if Token = 'OAUTH' then Exit(True);
    if Token = 'CERT' then Exit(True);
    if Token = 'CERTIFICATE' then Exit(True);
    if Token = 'SSL' then Exit(True);
    if Token = 'TLS' then Exit(True);

    // Common compact forms (no separators)
    if Token = 'APIKEY' then Exit(True);
    if Token = 'ACCESSKEY' then Exit(True);
    if Token = 'SECRETKEY' then Exit(True);
    if Token = 'PRIVATEKEY' then Exit(True);
    if Token = 'SIGNINGKEY' then Exit(True);

    Result := False;
  end;

  function IsTokenChar(const C: Char): Boolean; inline;
  begin
    Result := (C in ['A'..'Z', '0'..'9']);
  end;

  function TokenIsSensitive(const AStart, ALen: Integer): Boolean;
  var
    T: string;
  begin
    if ALen <= 0 then Exit(False);
    T := Copy(UpperName, AStart, ALen);
    Result := IsSensitiveToken(T);
  end;

begin
  if AName = '' then Exit(False);

  // Token-based detection avoids common false-positives like "MONKEY" (contains "KEY")
  // and "AUTHOR" (contains "AUTH").
  UpperName := UpperCase(AName);

  Result := False;
  StartIdx := 0;

  for I := 1 to Length(UpperName) do
  begin
    if IsTokenChar(UpperName[I]) then
    begin
      if StartIdx = 0 then
        StartIdx := I;
    end
    else
    begin
      if StartIdx <> 0 then
      begin
        if TokenIsSensitive(StartIdx, I - StartIdx) then Exit(True);
        StartIdx := 0;
      end;
    end;
  end;

  if StartIdx <> 0 then
    Exit(TokenIsSensitive(StartIdx, Length(UpperName) - StartIdx + 1));
end;

function env_mask_value(const AValue: string): string;
var
  Len: Integer;
begin
  Len := Length(AValue);
  if Len = 0 then
    Exit('');

  // Keep masking stable and avoid leaking the prefix.
  // <=4  -> "***"
  // 5..8 -> mask all but last 2
  // >=9  -> mask all but last 4
  if Len <= 4 then
    Exit('***');

  if Len <= 8 then
    Exit(StringOfChar('*', Len - 2) + Copy(AValue, Len - 1, 2));

  Result := StringOfChar('*', Len - 4) + Copy(AValue, Len - 3, 4);
end;

function env_validate_name(const AName: string): Boolean;
var
  I: Integer;
  C: Char;
begin
  if AName = '' then Exit(False);

  // Environment variable names should start with letter or underscore
  // and contain only letters, digits, and underscores
  C := AName[1];
  if not (C in ['A'..'Z', 'a'..'z', '_']) then
    Exit(False);

  for I := 2 to Length(AName) do
  begin
    C := AName[I];
    if not (C in ['A'..'Z', 'a'..'z', '0'..'9', '_']) then
      Exit(False);
  end;

  Result := True;
end;

function env_required(const AName: string): string;
var
  V: string;
begin
  if not env_lookup(AName, V) then
    raise EEnvVarNotFound.CreateFmt('Environment variable "%s" is required but not defined', [AName]);
  Result := V;
end;

function env_keys: TStringArray;
var
  kv: TEnvKVPair;
  Count, Capacity: Integer;

  procedure EnsureCapacity(const Needed: Integer);
  var
    NewCap: Integer;
  begin
    if Capacity >= Needed then Exit;
    NewCap := Capacity;
    if NewCap = 0 then NewCap := 16;
    while NewCap < Needed do NewCap := NewCap * 2;
    Capacity := NewCap;
    SetLength(Result, Capacity);
  end;

begin
  Result := nil;
  Count := 0;
  Capacity := 0;

  for kv in env_iter do
  begin
    EnsureCapacity(Count + 1);
    Result[Count] := kv.Key;
    Inc(Count);
  end;

  SetLength(Result, Count);
end;

function env_count: Integer; inline;
{$IFDEF UNIX}
var
  P: PPChar;
begin
  Result := 0;
  P := environ;
  if P = nil then Exit;
  while P^ <> nil do
  begin
    Inc(Result);
    Inc(P);
  end;
end;
{$ELSEIF DEFINED(WINDOWS)}
var
  P, PStart: PWideChar;
  S: UnicodeString;
begin
  Result := 0;
  PStart := GetEnvironmentStringsW();
  P := PStart;
  try
    if P <> nil then
    begin
      while (P^ <> #0) do
      begin
        S := P;
        if (Length(S) > 0) and (S[1] = '=') then
        begin
          Inc(P, Length(S) + 1);
          Continue; // skip pseudo variables like =C:=...
        end;
        Inc(Result);
        Inc(P, Length(S) + 1);
      end;
    end;
  finally
    if PStart <> nil then FreeEnvironmentStringsW(PStart);
  end;
end;
{$ELSE}
var
  Lst: TStringList;
begin
  // Keep cross-platform behavior consistent with env_keys/env_vars/env_iter fallback
  Lst := TStringList.Create;
  try
    os_environ(Lst);
    Result := Lst.Count;
  finally
    Lst.Free;
  end;
end;
{$ENDIF}

function env_get_bool(const AName: string; ADefault: Boolean): Boolean;
var
  V, Lower: string;
begin
  if not env_lookup(AName, V) then
    Exit(ADefault);
  Lower := LowerCase(Trim(V));
  if (Lower = 'true') or (Lower = '1') or (Lower = 'yes') or (Lower = 'on') then
    Exit(True);
  if (Lower = 'false') or (Lower = '0') or (Lower = 'no') or (Lower = 'off') then
    Exit(False);
  Result := ADefault;
end;

function env_get_int(const AName: string; ADefault: Integer): Integer;
var
  V: string;
  Code: Integer;
begin
  if not env_lookup(AName, V) then
    Exit(ADefault);
  Val(Trim(V), Result, Code);
  if Code <> 0 then
    Result := ADefault;
end;

function env_get_int64(const AName: string; ADefault: Int64): Int64;
var
  V: string;
  Code: Integer;
begin
  if not env_lookup(AName, V) then
    Exit(ADefault);
  Val(Trim(V), Result, Code);
  if Code <> 0 then
    Result := ADefault;
end;

function env_get_uint(const AName: string; ADefault: Cardinal): Cardinal;
var
  V: string;
  Base: QWord;
  Code: Integer;
begin
  if not env_lookup(AName, V) then
    Exit(ADefault);

  V := Trim(V);
  if V = '' then
    Exit(ADefault);
  if (Length(V) > 0) and (V[1] = '-') then
    Exit(ADefault);

  Val(V, Base, Code);
  if (Code <> 0) or (Base > High(Cardinal)) then
    Exit(ADefault);

  Result := Cardinal(Base);
end;

function env_get_uint64(const AName: string; ADefault: QWord): QWord;
var
  V: string;
  Code: Integer;
begin
  if not env_lookup(AName, V) then
    Exit(ADefault);

  V := Trim(V);
  if V = '' then
    Exit(ADefault);
  if (Length(V) > 0) and (V[1] = '-') then
    Exit(ADefault);

  Val(V, Result, Code);
  if Code <> 0 then
    Result := ADefault;
end;

function env_get_duration_ms(const AName: string; ADefault: QWord): QWord;
var
  V, L, NumPart: string;
  Base, Mult: QWord;
  Code: Integer;
  Len: Integer;
begin
  if not env_lookup(AName, V) then
    Exit(ADefault);

  V := Trim(V);
  if V = '' then
    Exit(ADefault);

  // Parse optional suffix: ms/s/m/h/d (case-insensitive)
  L := LowerCase(V);
  Len := Length(L);
  Mult := 1;

  if (Len >= 2) and (Copy(L, Len-1, 2) = 'ms') then
  begin
    Mult := 1;
    NumPart := Copy(L, 1, Len-2);
  end
  else if (Len >= 1) then
  begin
    case L[Len] of
      's': begin Mult := 1000;    NumPart := Copy(L, 1, Len-1); end;
      'm': begin Mult := 60000;   NumPart := Copy(L, 1, Len-1); end;
      'h': begin Mult := 3600000; NumPart := Copy(L, 1, Len-1); end;
      'd': begin Mult := 86400000;NumPart := Copy(L, 1, Len-1); end;
    else
      Mult := 1;
      NumPart := L;
    end;
  end
  else
    NumPart := L;

  NumPart := Trim(NumPart);
  if NumPart = '' then
    Exit(ADefault);
  if (Length(NumPart) > 0) and (NumPart[1] = '-') then
    Exit(ADefault);

  Val(NumPart, Base, Code);
  if Code <> 0 then
    Exit(ADefault);

  // overflow guard
  if (Mult <> 0) and (Base > High(QWord) div Mult) then
    Exit(ADefault);

  Result := Base * Mult;
end;

function env_get_size_bytes(const AName: string; ADefault: QWord): QWord;
var
  V, L, NumPart, UnitPart: string;
  Base, Mult: QWord;
  Code: Integer;
  I, Len: Integer;
begin
  if not env_lookup(AName, V) then
    Exit(ADefault);

  V := Trim(V);
  if V = '' then
    Exit(ADefault);

  L := LowerCase(V);
  Len := Length(L);

  // Split into numeric part and unit suffix (letters at the end)
  I := Len;
  while (I >= 1) and (L[I] in ['a'..'z']) do
    Dec(I);
  UnitPart := Copy(L, I + 1, Len - I);
  NumPart := Trim(Copy(L, 1, I));

  if NumPart = '' then
    Exit(ADefault);
  if (NumPart[1] = '-') then
    Exit(ADefault);

  if (UnitPart = '') or (UnitPart = 'b') then Mult := 1
  else if UnitPart = 'kb' then Mult := 1000
  else if UnitPart = 'mb' then Mult := 1000 * 1000
  else if UnitPart = 'gb' then Mult := 1000 * 1000 * 1000
  else if UnitPart = 'kib' then Mult := 1024
  else if UnitPart = 'mib' then Mult := 1024 * 1024
  else if UnitPart = 'gib' then Mult := 1024 * 1024 * 1024
  else
    Exit(ADefault);

  Val(NumPart, Base, Code);
  if Code <> 0 then
    Exit(ADefault);

  // overflow guard
  if (Mult <> 0) and (Base > High(QWord) div Mult) then
    Exit(ADefault);

  Result := Base * Mult;
end;

function env_get_float(const AName: string; ADefault: Double): Double;
var
  V: string;
  X: Double;
  FS: TFormatSettings;
begin
  if not env_lookup(AName, V) then
    Exit(ADefault);

  V := Trim(V);
  if V = '' then
    Exit(ADefault);

  // Parse as locale-invariant float (decimal separator '.')
  FS := DefaultFormatSettings;
  FS.DecimalSeparator := '.';

  if TryStrToFloat(V, X, FS) then
    Result := X
  else
    Result := ADefault;
end;

function env_get_list(const AName: string; ASeparator: Char): TStringArray;
var
  V: string;
  I, Start, Cnt, Len: Integer;
  C: Char;
begin
  Result := nil;
  if not env_lookup(AName, V) then
    Exit;
  Len := Length(V);
  if Len = 0 then
    Exit;
  // Count separators to pre-allocate
  Cnt := 1;
  for I := 1 to Len do
    if V[I] = ASeparator then Inc(Cnt);
  SetLength(Result, Cnt);
  // Parse
  Cnt := 0;
  Start := 1;
  for I := 1 to Len do
  begin
    C := V[I];
    if C = ASeparator then
    begin
      Result[Cnt] := Copy(V, Start, I - Start);
      Inc(Cnt);
      Start := I + 1;
    end;
  end;
  // Last segment
  Result[Cnt] := Copy(V, Start, Len - Start + 1);
end;

function env_get_paths(const AName: string): TStringArray;
var
  V: string;
begin
  Result := nil;
  if not env_lookup(AName, V) then
    Exit;
  Result := env_split_paths(V);
end;

function env_os: string; inline;
begin
  {$IFDEF WINDOWS}
  Result := 'Windows';
  {$ELSEIF DEFINED(ANDROID)}
  Result := 'Android';
  {$ELSEIF DEFINED(DARWIN)}
  Result := 'Darwin';
  {$ELSEIF DEFINED(LINUX)}
  Result := 'Linux';
  {$ELSEIF DEFINED(FREEBSD)}
  Result := 'FreeBSD';
  {$ELSEIF DEFINED(OPENBSD)}
  Result := 'OpenBSD';
  {$ELSEIF DEFINED(NETBSD)}
  Result := 'NetBSD';
  {$ELSE}
  Result := 'Unknown';
  {$ENDIF}
end;

function env_arch: string; inline;
begin
  {$IFDEF CPUX86_64}
  Result := 'x86_64';
  {$ELSEIF DEFINED(CPUAARCH64)}
  Result := 'aarch64';
  {$ELSEIF DEFINED(CPUI386) OR DEFINED(CPU386)}
  Result := 'i386';
  {$ELSEIF DEFINED(CPUARM)}
  Result := 'arm';
  {$ELSEIF DEFINED(CPUPOWERPC64)}
  Result := 'powerpc64';
  {$ELSEIF DEFINED(CPURISCV64)}
  Result := 'riscv64';
  {$ELSE}
  Result := 'unknown';
  {$ENDIF}
end;

function env_family: string; inline;
begin
  {$IFDEF WINDOWS}
  Result := 'windows';
  {$ELSE}
  Result := 'unix';
  {$ENDIF}
end;

function env_is_windows: Boolean; inline;
begin
  {$IFDEF WINDOWS}
  Result := True;
  {$ELSE}
  Result := False;
  {$ENDIF}
end;

function env_is_unix: Boolean; inline;
begin
  {$IFDEF UNIX}
  Result := True;
  {$ELSE}
  Result := False;
  {$ENDIF}
end;

function env_is_darwin: Boolean; inline;
begin
  {$IFDEF DARWIN}
  Result := True;
  {$ELSE}
  Result := False;
  {$ENDIF}
end;

procedure env_clear_all;
var
  Keys: TStringArray;
  I: Integer;
begin
  // Get all keys first, then unset each
  Keys := env_keys;
  for I := 0 to High(Keys) do
    env_unset(Keys[I]);
end;

{$IFDEF FAFAFA_ENV_DEBUG_ITER}
var
  GEnvIterDebugActiveStates: LongInt = 0;
{$ENDIF}

{$IFDEF FAFAFA_ENV_DEBUG_ITER}
function env_iter_debug_active_states: Integer; inline;
begin
  Result := GEnvIterDebugActiveStates;
end;

procedure env_iter_debug_reset_states; inline;
begin
  GEnvIterDebugActiveStates := 0;
end;
{$ENDIF}

function TEnvVarsEnumerator.GetCurrent: TEnvKVPair; inline;
begin
  if FState <> nil then
    Result := FState^.Current
  else
  begin
    Result.Key := '';
    Result.Value := '';
  end;
end;

class procedure TEnvVarsEnumerator.StateAddRef(const S: PState); static; inline;
begin
  if S <> nil then
    Inc(S^.RefCount);
end;

class procedure TEnvVarsEnumerator.StateRelease(var S: PState); static;
begin
  if S = nil then Exit;

  Dec(S^.RefCount);
  if S^.RefCount = 0 then
  begin
    if S^.List <> nil then
    begin
      S^.List.Free;
      S^.List := nil;
    end;
    {$IFDEF WINDOWS}
    if S^.WinStart <> nil then
    begin
      FreeEnvironmentStringsW(S^.WinStart);
      S^.WinStart := nil;
      S^.WinCur := nil;
    end;
    {$ENDIF}
    {$IFDEF FAFAFA_ENV_DEBUG_ITER}
    Dec(GEnvIterDebugActiveStates);
    {$ENDIF}
    Dispose(S);
  end;

  S := nil;
end;

class operator TEnvVarsEnumerator.Initialize(var r: TEnvVarsEnumerator);
begin
  r.FState := nil;
end;

class operator TEnvVarsEnumerator.Finalize(var r: TEnvVarsEnumerator);
begin
  StateRelease(r.FState);
end;

class operator TEnvVarsEnumerator.Copy(constref src: TEnvVarsEnumerator; var dst: TEnvVarsEnumerator);
begin
  if src.FState = dst.FState then Exit;

  StateRelease(dst.FState);
  dst.FState := src.FState;
  StateAddRef(dst.FState);
end;

function env_iter: TEnvVarsEnumerator;
var
  S: TEnvVarsEnumerator.PState;
begin
  New(S);
  S^.RefCount := 1;
  S^.List := nil;
  S^.Index := -1;
  S^.Current.Key := '';
  S^.Current.Value := '';
  {$IFDEF UNIX}
  S^.EnvP := environ;
  {$ENDIF}
  {$IFDEF WINDOWS}
  S^.WinStart := GetEnvironmentStringsW();
  S^.WinCur := S^.WinStart;
  {$ENDIF}
  {$IFNDEF UNIX}
  {$IFNDEF WINDOWS}
  S^.List := TStringList.Create;
  os_environ(S^.List);
  {$ENDIF}
  {$ENDIF}

  Result.FState := S;
  {$IFDEF FAFAFA_ENV_DEBUG_ITER}
  Inc(GEnvIterDebugActiveStates);
  {$ENDIF}
end;

function TEnvVarsEnumerator.GetEnumerator: TEnvVarsEnumerator;
begin
  Result := Self;
end;

function TEnvVarsEnumerator.MoveNext: Boolean;
var
  Line: string;
  {$IFDEF WINDOWS}
  S: UnicodeString;
  {$ENDIF}
begin
  if FState = nil then
    Exit(False);

  if FState^.List <> nil then
  begin
    Inc(FState^.Index);
    if FState^.Index >= FState^.List.Count then
    begin
      // Auto-free when iteration completes
      FState^.List.Free;
      FState^.List := nil;
      Exit(False);
    end;
    ParseEnvLine(FState^.List[FState^.Index], FState^.Current.Key, FState^.Current.Value);
    Exit(True);
  end;

  {$IFDEF UNIX}
  while (FState^.EnvP <> nil) and (FState^.EnvP^ <> nil) do
  begin
    Line := StrPas(FState^.EnvP^);
    Inc(FState^.EnvP);
    if Line = '' then Continue;
    ParseEnvLine(Line, FState^.Current.Key, FState^.Current.Value);
    if FState^.Current.Key = '' then Continue;
    Exit(True);
  end;
  {$ENDIF}

  {$IFDEF WINDOWS}
  while (FState^.WinCur <> nil) and (FState^.WinCur^ <> #0) do
  begin
    S := FState^.WinCur;
    Inc(FState^.WinCur, Length(S) + 1);
    if (Length(S) > 0) and (S[1] = '=') then
      Continue; // skip pseudo variables like =C:=...
    Line := UTF8Encode(WideString(S));
    if Line = '' then Continue;
    ParseEnvLine(Line, FState^.Current.Key, FState^.Current.Value);
    if FState^.Current.Key = '' then Continue;
    Exit(True);
  end;
  // Auto-free snapshot block when iteration completes
  if FState^.WinStart <> nil then
  begin
    FreeEnvironmentStringsW(FState^.WinStart);
    FState^.WinStart := nil;
    FState^.WinCur := nil;
  end;
  {$ENDIF}

  Result := False;
end;

procedure TEnvVarsEnumerator.Free; inline;
begin
  StateRelease(FState);
end;

function env_args: TStringArray;
var
  I: Integer;
begin
  Result := nil; // Initialize managed type
  SetLength(Result, ParamCount + 1);
  for I := 0 to ParamCount do
    Result[I] := ParamStr(I);
end;

function env_args_count: Integer; inline;
begin
  Result := ParamCount + 1;
end;

function env_arg(Index: Integer): string; inline;
begin
  if (Index < 0) or (Index > ParamCount) then
    Result := ''
  else
    Result := ParamStr(Index);
end;

end.

