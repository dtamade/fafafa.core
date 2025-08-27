unit fafafa.core.env;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes,
  fafafa.core.os
  {$IFDEF FAFAFA_ENV_ENABLE_RESULT}
  , fafafa.core.result
  {$ENDIF}
  , fafafa.core.stringBuilder
  ;

// Modern, cross-platform environment helpers inspired by Rust std::env and Go os
// Keep a C-style facade like fs_*: expose env_* functions for consistency.

type
  TStringArray = array of string;


  // RAII-style temporary environment override for tests/tools
  type
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

  // Batch override support
  type
    TEnvKV = record
      Name: string;
      Value: string;
      HasValue: Boolean; // False -> unset; True -> set Value (can be empty string)
    end;

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


// Basic environment variable operations
function env_get(const AName: string): string; inline;
function env_lookup(const AName: string; out AValue: string): Boolean; inline; // distinguish undefined vs empty

function env_get_or(const AName, ADefault: string): string; inline;

function env_set(const AName, AValue: string): Boolean; inline;
function env_unset(const AName: string): Boolean; inline;
function env_has(const AName: string): Boolean; inline;

procedure env_vars(const ADest: TStrings); inline; // NAME=VALUE pairs snapshot

  // RAII helper: create a guard that sets AName to AValue (or unsets if AValue='')
  function env_override(const AName, AValue: string): TEnvOverrideGuard; inline;

// Expand with custom resolver, and env-based convenience
type
  TEnvResolver = function(const Key: string; out Value: string): Boolean;
function env_overrides(const Pairs: array of TEnvKV): TEnvOverridesGuard; inline;

function env_expand_with(const S: string; Resolver: TEnvResolver): string;
function env_expand_env(const S: string): string;



// Expansion: replace $VAR / ${VAR} (Unix-style); on Windows also %VAR%
function env_expand(const S: string): string;

  // Explicit unset helper for tests/tools
  function env_override_unset(const AName: string): TEnvOverrideGuard; inline;

// PATH helpers (platform-aware list separator)
function env_path_list_separator: Char; inline;
function env_split_paths(const S: string): TStringArray; // split PATH-like var
function env_join_paths_checked(const Paths: array of string; out ErrIndex: Integer): string; // returns '' on error

function env_join_paths(const Paths: array of string): string; // join with sep

// Directories and process info
  // Result-style error types
  type
    EVarError = record
      Name: string;
      Msg: string;
    end;

    EPathJoinError = record
      Index: Integer;
      Segment: string;
      Msg: string;
    end;

    EIOError = record
      Op: string; // 'getcwd' or 'chdir'
      Path: string;
      Msg: string;
    end;

  {$IFDEF FAFAFA_ENV_ENABLE_RESULT}
  // Result-style wrappers
  type
    TResultString_VarError = specialize TResult<string, EVarError>;
    TResultString_PathJoinError = specialize TResult<string, EPathJoinError>;
    TResultString_IOError = specialize TResult<string, EIOError>;
    TResultUnit_IOError = specialize TResult<Boolean, EIOError>; // use True as unit-ok; Err carries EIOError

  function env_get_result(const AName: string): TResultString_VarError;
  function env_join_paths_result(const Paths: array of string): TResultString_PathJoinError;
  function env_current_dir_result: TResultString_IOError;
  function env_set_current_dir_result(const APath: string): TResultUnit_IOError;
  // Additional query wrappers
  function env_home_dir_result: TResultString_IOError;
  function env_temp_dir_result: TResultString_IOError;
  function env_executable_path_result: TResultString_IOError;
  function env_user_config_dir_result: TResultString_IOError;
  function env_user_cache_dir_result: TResultString_IOError;
  {$ENDIF}

function env_current_dir: string; inline;
function env_set_current_dir(const APath: string): Boolean; inline;
function env_home_dir: string; inline;

function env_temp_dir: string; inline;
function env_executable_path: string; inline;

// User directories (best-effort)
function env_user_config_dir: string; // XDG/APPDATA
function env_user_cache_dir: string;  // XDG/LOCALAPPDATA/~/Library/Caches

// Security helpers (2024 best practices)
function env_is_sensitive_name(const AName: string): Boolean; // Check if env var name suggests sensitive content
function env_mask_value(const AValue: string): string; // Mask sensitive values for logging
function env_validate_name(const AName: string): Boolean; // Validate env var name format

implementation

// Core RAII functions (always available)
function env_override(const AName, AValue: string): TEnvOverrideGuard; inline;
begin
  Result := TEnvOverrideGuard.New(AName, AValue);
end;

{$IFDEF FAFAFA_ENV_ENABLE_RESULT}
// Result-enabled section

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
  if env_set(AName, AValue) then ;
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


function env_overrides(const Pairs: array of TEnvKV): TEnvOverridesGuard; inline;
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

function env_get_result(const AName: string): TResultString_VarError;
var
  v: string;
  e: EVarError;
begin
  if env_lookup(AName, v) then
    Exit(TResultString_VarError.Ok(v))
  else
  begin
    e.Name := AName;
    e.Msg := 'environment variable not defined';
    Exit(TResultString_VarError.Err(e));
  end;
end;

function env_join_paths_result(const Paths: array of string): TResultString_PathJoinError;
var
  idx: Integer;
  joined: string;
  pe: EPathJoinError;
begin
  joined := env_join_paths_checked(Paths, idx);
  if (joined <> '') or (idx = -1) then
    Exit(TResultString_PathJoinError.Ok(joined))
  else
  begin
    pe.Index := idx;
    if (idx >= Low(Paths)) and (idx <= High(Paths)) then pe.Segment := Paths[idx] else pe.Segment := '';
    pe.Msg := 'path segment contains separator';
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
    ioe.Op := 'getcwd'; ioe.Path := ''; ioe.Msg := 'failed to get current directory';
    Exit(TResultString_IOError.Err(ioe));
  end;
end;

function env_set_current_dir_result(const APath: string): TResultUnit_IOError;
var
  ioe: EIOError;
begin
  if env_set_current_dir(APath) then
    Exit(TResultUnit_IOError.Ok(True))
  else
  begin
    ioe.Op := 'chdir'; ioe.Path := APath; ioe.Msg := 'failed to change directory';
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
    e.Op := 'homedir'; e.Path := ''; e.Msg := 'failed to resolve home directory';
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
    e.Op := 'tempdir'; e.Path := ''; e.Msg := 'failed to resolve temp directory';
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
    e.Op := 'exepath'; e.Path := ''; e.Msg := 'failed to resolve executable path';
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
    e.Op := 'user_config_dir'; e.Path := ''; e.Msg := 'failed to resolve user config dir';
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
    e.Op := 'user_cache_dir'; e.Path := ''; e.Msg := 'failed to resolve user cache dir';
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

function env_expand_with(const S: string; Resolver: TEnvResolver): string;
var
  I, L: Integer;
  C: Char;
  Name, Val: string;
  Builder: TStringBuilder;

  procedure AppendResolved(const Key: string);
  begin
    if Assigned(Resolver) and Resolver(Key, Val) then
      Builder.Append(Val);
    // Note: if resolver fails or returns false, append nothing (empty expansion)
  end;
begin
  if S = '' then Exit('');

  Builder := TStringBuilder.Create(Length(S) * 2); // Pre-allocate with reasonable capacity
  try
    I := 1; L := Length(S);
    while I <= L do
    begin
      C := S[I];
      if C = '$' then
      begin
        Inc(I);
        if (I <= L) and (S[I] = '$') then
        begin
          Builder.Append('$');
          Inc(I);
          Continue;
        end;
        if (I <= L) and (S[I] = '{') then
        begin
          Inc(I); Name := '';
          while (I <= L) and (S[I] <> '}') do begin Name := Name + S[I]; Inc(I); end;
          if (I <= L) and (S[I] = '}') then Inc(I);
          AppendResolved(Name);
        end
        else
        begin
          Name := '';
          if (I <= L) and (S[I] in ['A'..'Z','a'..'z','_']) then
          begin
            while (I <= L) and (S[I] in ['A'..'Z','a'..'z','0'..'9','_']) do
            begin
              Name := Name + S[I]; Inc(I);
            end;
            AppendResolved(Name);
          end
          else
            Builder.Append('$');
        end;
      end
      {$IFDEF WINDOWS}
      else if C = '%' then
      begin
        if (I+1 <= L) and (S[I+1] = '%') then
        begin
          Builder.Append('%');
          Inc(I, 2);
          Continue;
        end;
        // %NAME%
        Name := '';
        Inc(I);
        while (I <= L) and (S[I] <> '%') do begin Name := Name + S[I]; Inc(I); end;
        if (I <= L) and (S[I] = '%') then
        begin
          Inc(I);
          AppendResolved(Name);
          Continue;
        end;
        // unmatched: treat literally
        Builder.Append('%').Append(Name);
      end
      {$ENDIF}
      else
      begin
        Builder.Append(C);
        Inc(I);
      end;
    end;

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
{$IFDEF FAFAFA_CORE_ENV_KEEP_REFERENCE_IMPL}


function env_expand_unix_like(const S: string): string;
var
  I, L: Integer;
  C: Char;
  Name: string;
begin
  Result := '';
  I := 1; L := Length(S);
  while I <= L do
  begin
    C := S[I];
    if C = '$' then
    begin
      Inc(I); // look at the char after '$'
      if (I <= L) and (S[I] = '$') then
      begin
        // $$ -> literal $
        Result := Result + '$';
        Inc(I);
        Continue;
      end;
      if (I <= L) and (S[I] = '{') then
      begin
        // ${VAR}
        Inc(I); Name := '';
        while (I <= L) and (S[I] <> '}') do
        begin
          Name := Name + S[I]; Inc(I);
        end;
        if (I <= L) and (S[I] = '}') then Inc(I);
        Result := Result + env_get(Name);
      end
      else
      begin
        // $VAR: first char must be letter or '_', then letters/digits/_
        Name := '';
        if (I <= L) and (S[I] in ['A'..'Z','a'..'z','_']) then
        begin
          while (I <= L) and (S[I] in ['A'..'Z','a'..'z','0'..'9','_']) do
          begin
            Name := Name + S[I]; Inc(I);
          end;
          Result := Result + env_get(Name);
        end
        else
        begin
          // Not a valid variable start, treat '$' as literal
          Result := Result + '$';
        end;
      end;
    end
    else
    begin
      Result := Result + C;
      Inc(I);
    end;
  end;
end;

function env_expand_windows_percent(const S: string): string;
var
  I, L, J: Integer;
  Name: string;
begin
  Result := '';
  I := 1; L := Length(S);
  while I <= L do
  begin
    if S[I] = '%' then
    begin
      // Handle literal %% -> '%'
      if (I+1 <= L) and (S[I+1] = '%') then
      begin
        Result := Result + '%';
        Inc(I, 2);
        Continue;
      end;
      J := I + 1; Name := '';
      while (J <= L) and (S[J] <> '%') do
      begin
        Name := Name + S[J]; Inc(J);
      end;
      if (J <= L) and (S[J] = '%') then
      begin
        // %NAME%
        Result := Result + env_get(Name);
        I := J + 1;
        Continue;
      end;
    end;
    Result := Result + S[I];
    Inc(I);
  end;
end;
{$ENDIF // FAFAFA_CORE_ENV_KEEP_REFERENCE_IMPL}


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

function env_home_dir: string; inline;
begin
  Result := os_home_dir;
end;

function env_temp_dir: string; inline;
begin
  Result := os_temp_dir;
end;

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
begin
  if AName = '' then Exit(False);

  UpperName := UpperCase(AName);

  // Common patterns for sensitive environment variables
  Result := (Pos('PASSWORD', UpperName) > 0) or
            (Pos('SECRET', UpperName) > 0) or
            (Pos('KEY', UpperName) > 0) or
            (Pos('TOKEN', UpperName) > 0) or
            (Pos('CREDENTIAL', UpperName) > 0) or
            (Pos('AUTH', UpperName) > 0) or
            (Pos('PRIVATE', UpperName) > 0) or
            (Pos('CERT', UpperName) > 0) or
            (Pos('SSL', UpperName) > 0) or
            (Pos('TLS', UpperName) > 0);
end;

function env_mask_value(const AValue: string): string;
var
  Len: Integer;
begin
  Len := Length(AValue);
  if Len = 0 then
    Exit('');
  if Len <= 4 then
    Exit('***')
  else
    Exit(Copy(AValue, 1, 2) + StringOfChar('*', Len - 4) + Copy(AValue, Len - 1, 2));
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

end.

