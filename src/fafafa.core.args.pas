unit fafafa.core.args;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$modeswitch typehelpers}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes
  {$IFDEF Windows}
  , Windows, ShellApi
  {$ENDIF}
  ;

type
  TStringArray = array of string;

  // Parsing options (stable core API)
  TArgsOptions = record
    CaseInsensitiveKeys: Boolean;
    AllowShortFlagsCombo: Boolean;            // -abc => -a -b -c
    AllowShortKeyValue: Boolean;              // -o=out or -o out
    StopAtDoubleDash: Boolean;                // "--" stops parsing
    TreatNegativeNumbersAsPositionals: Boolean; // -1.23 not short flags
    EnableNoPrefixNegation: Boolean;          // --no-xxx maps to xxx=false
  end;

function ArgsOptionsDefault: TArgsOptions;

type
  TArgKind = (akArg, akOptionShort, akOptionLong);

  TArgItem = record
    Name: string;
    Value: string;
    HasValue: Boolean;
    Kind: TArgKind;
    Position: Integer; // original argv index
  end;

  TArgsContext = record
  private
    FFlags: TStringArray;      // normalized names (no leading '-'/'/')
    FKeys: TStringArray;       // normalized keys
    FValues: TStringArray;     // raw values
    FPositionals: TStringArray;// raw

    FItemNames: TStringArray;
    FItemValues: TStringArray;
    FItemHasValue: array of Boolean;
    FItemKinds: array of TArgKind;
    FItemPositions: array of Integer;
  public
    function Flags: TStringArray; inline;
    function Keys: TStringArray; inline;
    function Values: TStringArray; inline;
    function Positionals: TStringArray; inline;
    function ItemsCount: Integer; inline;
    function ItemAt(Index: Integer): TArgItem; inline;
  end;

// Core parse
procedure ParseArgs(const Args: array of string; const Opts: TArgsOptions; out Ctx: TArgsContext);

// OO API interface (stable, minimal)
type
  IArgs = interface
    ['{E4F6A76C-4A13-4D4E-9D3A-7E8A3F2F3C21}']
    function Count: Integer;
    function Items(Index: Integer): TArgItem;
    function Positionals: TStringArray;

    function HasFlag(const Name: string): Boolean;
    function TryGetValue(const Key: string; out Value: string): Boolean;
    function GetAll(const Key: string): TStringArray;

    function TryGetInt64(const Key: string; out V: Int64): Boolean;
    function TryGetDouble(const Key: string; out V: Double): Boolean;
    function TryGetBool(const Key: string; out V: Boolean): Boolean;

    function GetStringDefault(const Key, Default: string): string;
    function GetInt64Default(const Key: string; const Default: Int64): Int64;
    function GetDoubleDefault(const Key: string; const Default: Double): Double;
    function GetBoolDefault(const Key: string; const Default: Boolean): Boolean;
  end;

type
  TArgs = class(TInterfacedObject, IArgs)
  private
    FCtx: TArgsContext;
    FOpts: TArgsOptions;
  public
    class function FromProcess: TArgs; overload; static;
    class function FromProcess(const Opts: TArgsOptions): TArgs; overload; static;
    class function FromArray(const A: array of string; const Opts: TArgsOptions): TArgs; static;

    // IArgs
    function Count: Integer;
    function Items(Index: Integer): TArgItem;
    function Positionals: TStringArray;

    function HasFlag(const Name: string): boolean;
    function TryGetValue(const Key: string; out Value: string): boolean;
    function GetAll(const Key: string): TStringArray;

    function TryGetInt64(const Key: string; out V: Int64): boolean;
    function TryGetDouble(const Key: string; out V: Double): boolean;
    function TryGetBool(const Key: string; out V: boolean): boolean;

    function GetStringDefault(const Key, Default: string): string;
    function GetInt64Default(const Key: string; const Default: Int64): Int64;
    function GetDoubleDefault(const Key: string; const Default: Double): Double;
    function GetBoolDefault(const Key: string; const Default: boolean): boolean;

    // Enumerators for for-in
    function GetEnumerator: TObject; // returns TArgsEnumerator
    function GetArgEnumerator: TObject; // returns TArgsArgEnumerator
    function GetOptionEnumerator: TObject; // returns TArgsOptionEnumerator
  end;

  TArgsEnumerator = class
  private
    FArgs: TArgs;
    FIndex: Integer;
  public
    constructor Create(A: TArgs);
    function GetCurrent: TArgItem;
    function MoveNext: boolean;
    property Current: TArgItem read GetCurrent;
  end;

  TArgsArgEnumerator = class
  private
    FArgs: TArgs;
    FIndex: Integer;
  public
    constructor Create(A: TArgs);
    function GetCurrent: string;
    function MoveNext: boolean;
    property Current: string read GetCurrent;
  end;

  TArgsOptionEnumerator = class
  private
    FArgs: TArgs;
    FIndex: Integer;
  public
    constructor Create(A: TArgs);
    function GetCurrent: TArgItem;
    function MoveNext: boolean;
    property Current: TArgItem read GetCurrent;
  end;

// Convenience helpers based on current process argv
function ArgsHasFlag(const Flag: string): boolean;
function ArgsTryGetValue(const Key: string; out Value: string): boolean;
function ArgsGetAll(const Key: string): TStringArray;
function ArgsPositionals: TStringArray;
function ArgsIsHelpRequested: boolean;

implementation

function FindFlag(const Arr: TStringArray; const Flag: string; CaseInsensitive: boolean): boolean; forward;

function ArgsOptionsDefault: TArgsOptions;
begin
  Result.CaseInsensitiveKeys := True;
  Result.AllowShortFlagsCombo := True;
  Result.AllowShortKeyValue := True;
  Result.StopAtDoubleDash := True;
  Result.TreatNegativeNumbersAsPositionals := True;
  Result.EnableNoPrefixNegation := False;
end;

function NormalizeKeyForCheck(const S: string; ACaseInsensitive: boolean): string;
var i, n: Integer; res: string;
begin
  res := S;
  // strip leading '-' or '/'
  i := 1; n := Length(res);
  while (i<=n) and ((res[i]='-') or (res[i]='/')) do Inc(i);
  if i>1 then res := Copy(res, i, MaxInt);
  if (res='?') then res := 'help';
  if ACaseInsensitive then res := LowerCase(res);
  Result := res;
end;

function NormalizeKey(const S: string; ACaseInsensitive: boolean): string;
var i, n: Integer; res: string;
begin
  res := S;
  // strip leading '-' or '/'
  i := 1; n := Length(res);
  while (i<=n) and ((res[i]='-') or (res[i]='/')) do Inc(i);
  if i>1 then res := Copy(res, i, MaxInt);
  if (res='?') then res := 'help';
  // normalize segment separator: treat '-' as '.' so that
  // 'app-name' and 'app.name' are equivalent for lookups and storage
  for i := 1 to Length(res) do if res[i]='-' then res[i] := '.';
  if ACaseInsensitive then res := LowerCase(res);
  Result := res;
end;

function StartsWith(const S, Pref: string): boolean; inline;
begin
  Result := (Length(S)>=Length(Pref)) and (Copy(S,1,Length(Pref))=Pref);
end;

function IsNegativeNumberLike(const S: string): boolean; inline;
begin
  Result := (Length(S)>=2) and (S[1]='-') and (S[2] in ['0'..'9']);
end;

procedure AddString(var Arr: TStringArray; const V: string);
var L: SizeInt;
begin
  L := Length(Arr); SetLength(Arr, L+1); Arr[L] := V;
end;


function TArgsContext.Flags: TStringArray; inline; begin Result := nil; Result := FFlags; end;
function TArgsContext.Keys: TStringArray; inline; begin Result := nil; Result := FKeys; end;
function TArgsContext.Values: TStringArray; inline; begin Result := nil; Result := FValues; end;
function TArgsContext.Positionals: TStringArray; inline; begin Result := nil; Result := FPositionals; end;

procedure ParseArgs(const Args: array of string; const Opts: TArgsOptions; out Ctx: TArgsContext);
var i, j, posOpt: Integer; a, key, val, baseKey: string; stop: boolean; handled: boolean;
  procedure AddItem(const Kind: TArgKind; const Name, Value: string; const HasValue: boolean; const PosIndex: Integer);
  var L: SizeInt;
  begin
    L := Length(Ctx.FItemNames);
    SetLength(Ctx.FItemNames, L+1);
    SetLength(Ctx.FItemValues, L+1);
    SetLength(Ctx.FItemHasValue, L+1);
    SetLength(Ctx.FItemKinds, L+1);
    SetLength(Ctx.FItemPositions, L+1);
    Ctx.FItemNames[L] := Name;
    Ctx.FItemValues[L] := Value;
    Ctx.FItemHasValue[L] := HasValue;
    Ctx.FItemKinds[L] := Kind;
    Ctx.FItemPositions[L] := PosIndex;
  end;
  function NextIsValue: boolean;
  var nextTok: string;
  begin
    if i+1>High(Args) then Exit(False);
    nextTok := Args[i+1];
    // Special: do not consume the sentinel as a value
    if nextTok='--' then Exit(False);
    // If next starts with a dash, it is usually another option.
    // Only treat negative numbers as values when the toggle is enabled.
    if (Length(nextTok)>0) and (nextTok[1]='-') then
    begin
      if Opts.TreatNegativeNumbersAsPositionals and IsNegativeNumberLike(nextTok) then
        Exit(True)
      else
        Exit(False);
    end;
    // Windows style options start with '/': never a value
    if (Length(nextTok)>0) and (nextTok[1]='/') then Exit(False);
    // Otherwise accept as a value
    Result := True;
  end;
begin
  // init
  FillChar(Ctx, SizeOf(Ctx), 0);
  SetLength(Ctx.FFlags, 0);
  SetLength(Ctx.FKeys, 0);
  SetLength(Ctx.FValues, 0);
  SetLength(Ctx.FPositionals, 0);
  stop := False;

  i := Low(Args);
  while i<=High(Args) do
  begin
    a := Args[i];
    // Handle double dash
    if a='--' then
    begin
      if Opts.StopAtDoubleDash then
      begin
        // Do not include the sentinel itself; stop and append the rest later
        stop := True; Inc(i); Break;
      end
      else
      begin
        // Treat "--" as a positional and also switch to positional-only for the rest
        AddString(Ctx.FPositionals, a);
        AddItem(akArg, '', a, False, i);
        stop := True; Inc(i); Break;
      end;
    end;

    if (Length(a)>=2) and StartsWith(a,'--') then
    begin
      // long form
      if Pos('=', a)>0 then
      begin
        key := NormalizeKey(Copy(a,1,Pos('=',a)-1), Opts.CaseInsensitiveKeys);
        val := Copy(a, Pos('=',a)+1, MaxInt);
        // If explicit assignment is on a no- key and negation is enabled,
        // map base key as well so that last-wins semantics affect the base option.
        if Opts.EnableNoPrefixNegation then
        begin
          // original key without dash-to-dot normalization for prefix detection
          baseKey := NormalizeKeyForCheck(Copy(a,1,Pos('=',a)-1), Opts.CaseInsensitiveKeys);
          if StartsWith(baseKey, 'no-') then
          begin
            baseKey := NormalizeKey(Copy(baseKey, Length('no-')+1, MaxInt), Opts.CaseInsensitiveKeys);
            AddString(Ctx.FKeys, baseKey); AddString(Ctx.FValues, val);
            AddItem(akOptionLong, baseKey, val, True, i);
          end;
        end;
        // Always store the literal key too (so queries for 'no-xxx' still work)
        AddString(Ctx.FKeys, key); AddString(Ctx.FValues, val);
        AddItem(akOptionLong, key, val, True, i);
      end
      else if Pos(':', a)>0 then
      begin
        key := NormalizeKey(Copy(a,1,Pos(':',a)-1), Opts.CaseInsensitiveKeys);
        val := Copy(a, Pos(':',a)+1, MaxInt);
        AddString(Ctx.FKeys, key); AddString(Ctx.FValues, val);
        AddItem(akOptionLong, key, val, True, i);
      end
      else
      begin
        key := NormalizeKey(a, Opts.CaseInsensitiveKeys);
        if NextIsValue then
        begin
          posOpt := i;
          val := Args[i+1]; Inc(i);
          AddString(Ctx.FKeys, key); AddString(Ctx.FValues, val);
          AddItem(akOptionLong, key, val, True, posOpt);
        end
        else
        begin
          // Handle no-prefix negation without breaking loop increment
          handled := False;
          if Opts.EnableNoPrefixNegation then
          begin
            // check negation on original token without dash-to-dot normalization
            baseKey := NormalizeKeyForCheck(a, Opts.CaseInsensitiveKeys);
            if StartsWith(baseKey, 'no-') then
            begin
              // --no-xxx  => key 'xxx' with value 'false'
              baseKey := Copy(baseKey, Length('no-')+1, MaxInt);
              AddString(Ctx.FKeys, baseKey); AddString(Ctx.FValues, 'false');
              AddItem(akOptionLong, baseKey, 'false', True, i);
              handled := True;
            end;
          end;
          if not handled then
          begin
            AddString(Ctx.FFlags, key);
            AddItem(akOptionLong, key, '', False, i);
          end;
        end;
      end;
    end
    else if (Length(a)>=2) and (a[1]='-') then
    begin
      // short form(s)
      if (Opts.AllowShortKeyValue) and (Pos('=', a)>0) then
      begin
        key := NormalizeKey(Copy(a,1,Pos('=',a)-1), Opts.CaseInsensitiveKeys);
        val := Copy(a, Pos('=',a)+1, MaxInt);
        AddString(Ctx.FKeys, key); AddString(Ctx.FValues, val);
        AddItem(akOptionShort, key, val, True, i);
      end
      else if (Opts.AllowShortKeyValue) and (Pos(':', a)>0) then
      begin
        key := NormalizeKey(Copy(a,1,Pos(':',a)-1), Opts.CaseInsensitiveKeys);
        val := Copy(a, Pos(':',a)+1, MaxInt);
        AddString(Ctx.FKeys, key); AddString(Ctx.FValues, val);
        AddItem(akOptionShort, key, val, True, i);
      end
      else if (Opts.AllowShortKeyValue) and (Length(a)=2) and NextIsValue then
      begin
        key := NormalizeKey(a, Opts.CaseInsensitiveKeys);
        posOpt := i;
        val := Args[i+1]; Inc(i);
        AddString(Ctx.FKeys, key); AddString(Ctx.FValues, val);
        AddItem(akOptionShort, key, val, True, posOpt);
      end
      else if (Opts.EnableNoPrefixNegation) and (Length(a)>=4) and (Copy(a,1,4)='-no-') then
      begin
        // -no-x ; treat as long-style negation too
        key := NormalizeKey('--'+Copy(a,2,MaxInt), Opts.CaseInsensitiveKeys); // normalize -no-x as --no-x
        // no immediate value by design, map to false
        baseKey := Copy(key, Length('no-')+1, MaxInt);
        AddString(Ctx.FKeys, baseKey); AddString(Ctx.FValues, 'false');
        AddItem(akOptionShort, baseKey, 'false', True, i);
      end
      else if Opts.AllowShortFlagsCombo then
      begin
        // treat each char as a flag: -abc
        for j := 2 to Length(a) do
        begin
          key := NormalizeKey('-'+a[j], Opts.CaseInsensitiveKeys);
          AddString(Ctx.FFlags, key);
          AddItem(akOptionShort, key, '', False, i);
        end;
      end
      else
      begin
        // treat as a single flag name (minus leading '-')
        key := NormalizeKey(a, Opts.CaseInsensitiveKeys);
        AddString(Ctx.FFlags, key);
        AddItem(akOptionShort, key, '', False, i);
      end;
    end
    else if (Length(a)>=1) and (a[1]='/') then
    begin
      // Windows style: support /k, /k=v, /k:v, /long, /long=value, /long:value
      if Pos('=', a)>0 then
      begin
        key := NormalizeKey(Copy(a,1,Pos('=',a)-1), Opts.CaseInsensitiveKeys);
        val := Copy(a, Pos('=',a)+1, MaxInt);
        // Map '/no-xxx=value' to base key as well when negation is enabled (last-wins semantics)
        if Opts.EnableNoPrefixNegation then
        begin
          baseKey := NormalizeKeyForCheck(Copy(a,1,Pos('=',a)-1), Opts.CaseInsensitiveKeys);
          if StartsWith(baseKey, 'no-') then
          begin
            baseKey := NormalizeKey(Copy(baseKey, Length('no-')+1, MaxInt), Opts.CaseInsensitiveKeys);
            AddString(Ctx.FKeys, baseKey); AddString(Ctx.FValues, val);
            AddItem(akOptionLong, baseKey, val, True, i);
          end;
        end;
        // store literal key as-is
        AddString(Ctx.FKeys, key); AddString(Ctx.FValues, val);
        AddItem(akOptionLong, key, val, True, i);
      end
      else if Pos(':', a)>0 then
      begin
        key := NormalizeKey(Copy(a,1,Pos(':',a)-1), Opts.CaseInsensitiveKeys);
        val := Copy(a, Pos(':',a)+1, MaxInt);
        // Map '/no-xxx:value' to base key as well when negation is enabled
        if Opts.EnableNoPrefixNegation then
        begin
          baseKey := NormalizeKeyForCheck(Copy(a,1,Pos(':',a)-1), Opts.CaseInsensitiveKeys);
          if StartsWith(baseKey, 'no-') then
          begin
            baseKey := NormalizeKey(Copy(baseKey, Length('no-')+1, MaxInt), Opts.CaseInsensitiveKeys);
            AddString(Ctx.FKeys, baseKey); AddString(Ctx.FValues, val);
            AddItem(akOptionLong, baseKey, val, True, i);
          end;
        end;
        // store literal key as-is
        AddString(Ctx.FKeys, key); AddString(Ctx.FValues, val);
        AddItem(akOptionLong, key, val, True, i);
      end
      else
      begin
        // treat as flag (short or long)
        key := NormalizeKey(a, Opts.CaseInsensitiveKeys);
        handled := False;
        if Opts.EnableNoPrefixNegation then
        begin
          // Detect no- prefix without dash-to-dot normalization
          baseKey := NormalizeKeyForCheck(a, Opts.CaseInsensitiveKeys);
          if StartsWith(baseKey, 'no-') then
          begin
            baseKey := NormalizeKey(Copy(baseKey, Length('no-')+1, MaxInt), Opts.CaseInsensitiveKeys);
            AddString(Ctx.FKeys, baseKey); AddString(Ctx.FValues, 'false');
            AddItem(akOptionLong, baseKey, 'false', True, i);
            handled := True;
          end;
        end;
        if not handled then
        begin
          AddString(Ctx.FFlags, key);
          AddItem(akOptionLong, key, '', False, i);
        end;
      end;
    end
    else
    begin
      // positional
      AddString(Ctx.FPositionals, a);
      AddItem(akArg, '', a, False, i);
    end;
    Inc(i);
  end;

  // append rest as positionals if stopped by '--'
  if stop then
  begin
    while i<=High(Args) do begin AddString(Ctx.FPositionals, Args[i]); AddItem(akArg, '', Args[i], False, i); Inc(i); end;
  end;
end;

function CollectProcessArgs: TStringArray;
{$IFDEF Windows}
{$IFDEF FAFAFA_ARGS_WIN_WIDE}
  function WideToUtf8(const ws: UnicodeString): UTF8String;
  begin
    Result := UTF8Encode(ws);
  end;
var
  pCmd: PWideChar;
  pArgv: windows.PLPWStr;
  argc: LongInt;
  j: Integer;
  s: UTF8String;
{$ENDIF}
{$ENDIF}
var i: Integer;
begin
  Result := nil;
{$IFDEF Windows}
{$IFDEF FAFAFA_ARGS_WIN_WIDE}
  // Use wide-char API to avoid codepage loss on Windows
  pCmd := GetCommandLineW;
  pArgv := CommandLineToArgvW(pCmd, @argc);
  if pArgv<>nil then
  try
    if argc>0 then
    begin
      // Skip argv[0] (program path) to align with ParamStr(1..ParamCount)
      if argc-1>0 then SetLength(Result, argc-1) else SetLength(Result, 0);
      for j := 1 to argc-1 do
      begin
        s := WideToUtf8(pArgv^[j]);
        Result[j-1] := string(s);
      end;
    end
    else
      SetLength(Result, 0);
  finally
    LocalFree(HLOCAL(pArgv));
  end
  else
  begin
    // Fallback to RTL ParamStr if wide API fails
    SetLength(Result, ParamCount);
    for i := 1 to ParamCount do Result[i-1] := ParamStr(i);
  end;
  Exit;
{$ENDIF}
{$ENDIF}
  SetLength(Result, ParamCount);
  for i := 1 to ParamCount do Result[i-1] := ParamStr(i);
end;

function TArgsContext.ItemsCount: Integer; inline;
begin
  Result := Length(FItemNames);
end;

function TArgsContext.ItemAt(Index: Integer): TArgItem; inline;
begin
  Result.Name := FItemNames[Index];
  Result.Value := FItemValues[Index];
  Result.HasValue := FItemHasValue[Index];
  Result.Kind := FItemKinds[Index];
  Result.Position := FItemPositions[Index];
end;

class function TArgs.FromProcess: TArgs;
begin
  Result := FromProcess(ArgsOptionsDefault);
end;

class function TArgs.FromProcess(const Opts: TArgsOptions): TArgs;
var arr: TStringArray;
begin
  Result := TArgs.Create;
  arr := CollectProcessArgs;
  ParseArgs(arr, Opts, Result.FCtx);
  Result.FOpts := Opts;
end;

class function TArgs.FromArray(const A: array of string; const Opts: TArgsOptions): TArgs;
begin
  Result := TArgs.Create;
  ParseArgs(A, Opts, Result.FCtx);
  Result.FOpts := Opts;
end;

function TArgs.Count: Integer;
begin
  Result := FCtx.ItemsCount;
end;

function TArgs.Items(Index: Integer): TArgItem;
begin
  Result.Name := '';
  Result.Value := '';
  Result.HasValue := False;
  Result.Kind := akArg;
  Result.Position := -1;
  if (Index>=0) and (Index<FCtx.ItemsCount) then
    Result := FCtx.ItemAt(Index);
end;

function TArgs.Positionals: TStringArray;
begin
  Result := nil;
  Result := FCtx.Positionals;
end;

function TArgs.HasFlag(const Name: string): boolean;
begin
  Result := FindFlag(FCtx.Flags, Name, FOpts.CaseInsensitiveKeys);
end;

function TArgs.TryGetValue(const Key: string; out Value: string): boolean;
var i: Integer; k: string;
begin
  Result := False; Value := '';
  k := NormalizeKey(Key, FOpts.CaseInsensitiveKeys);
  for i := High(FCtx.FKeys) downto 0 do
    if FCtx.FKeys[i] = k then begin Value := FCtx.FValues[i]; Exit(True); end;
end;

function TArgs.GetAll(const Key: string): TStringArray;
var i: Integer; k: string;
begin
  Result := nil;
  SetLength(Result, 0);
  k := NormalizeKey(Key, FOpts.CaseInsensitiveKeys);
  for i := 0 to High(FCtx.FKeys) do
    if FCtx.FKeys[i] = k then AddString(Result, FCtx.FValues[i]);
end;

function TArgs.TryGetInt64(const Key: string; out V: Int64): boolean;
var s: string;
begin
  if not TryGetValue(Key, s) then Exit(False);
  Result := TryStrToInt64(s, V);
end;

function TArgs.TryGetDouble(const Key: string; out V: Double): boolean;
var s: string;
begin
  if not TryGetValue(Key, s) then Exit(False);
  Result := TryStrToFloat(s, V);
end;

{ TArgsEnumerator }
constructor TArgsEnumerator.Create(A: TArgs);
begin
  inherited Create;
  FArgs := A;
  FIndex := -1;
end;

function TArgsEnumerator.GetCurrent: TArgItem;
begin
  Result.Name := '';
  Result.Value := '';
  Result.HasValue := False;
  Result.Kind := akArg;
  Result.Position := -1;
  if (FIndex>=0) and (FIndex<FArgs.Count) then
    Result := FArgs.Items(FIndex);
end;

function TArgsEnumerator.MoveNext: boolean;
begin
  Inc(FIndex);
  Result := FIndex < FArgs.Count;
end;

{ TArgsArgEnumerator }
constructor TArgsArgEnumerator.Create(A: TArgs);
begin
  inherited Create;
  FArgs := A;
  FIndex := -1;
end;

function TArgsArgEnumerator.GetCurrent: string;
begin
  if (FIndex>=0) and (FIndex<=High(FArgs.Positionals)) then
    Result := FArgs.Positionals[FIndex]
  else
    Result := '';
end;

function TArgsArgEnumerator.MoveNext: boolean;
begin
  Inc(FIndex);
  Result := FIndex <= High(FArgs.Positionals);
end;

{ TArgsOptionEnumerator }
constructor TArgsOptionEnumerator.Create(A: TArgs);
begin
  inherited Create;
  FArgs := A;
  FIndex := -1;
end;

function TArgsOptionEnumerator.GetCurrent: TArgItem;
begin
  Result.Name := '';
  Result.Value := '';
  Result.HasValue := False;
  Result.Kind := akArg;
  Result.Position := -1;
  if (FIndex>=0) and (FIndex<FArgs.Count) then
    Result := FArgs.Items(FIndex);
end;

function TArgsOptionEnumerator.MoveNext: boolean;
var it: TArgItem;
begin
  while True do
  begin
    Inc(FIndex);
    if FIndex >= FArgs.Count then Exit(False);
    it := FArgs.Items(FIndex);
    if (it.Kind in [akOptionShort, akOptionLong]) then Exit(True);
  end;
end;

function TArgs.GetEnumerator: TObject;
begin
  Result := TArgsEnumerator.Create(Self);
end;

function TArgs.GetArgEnumerator: TObject;
begin
  Result := TArgsArgEnumerator.Create(Self);
end;

function TArgs.GetOptionEnumerator: TObject;
begin
  Result := TArgsOptionEnumerator.Create(Self);
end;

function TArgs.TryGetBool(const Key: string; out V: boolean): boolean;
var s: string;
begin
  if not TryGetValue(Key, s) then Exit(False);
  if SameText(s, 'true') or (s='1') or SameText(s,'yes') then begin V := True; Exit(True); end;
  if SameText(s, 'false') or (s='0') or SameText(s,'no') then begin V := False; Exit(True); end;
  Result := False;
end;

function TArgs.GetStringDefault(const Key, Default: string): string;
var s: string;
begin
  if TryGetValue(Key, s) then Result := s else Result := Default;
end;

function TArgs.GetInt64Default(const Key: string; const Default: Int64): Int64;
var v: Int64;
begin
  if TryGetInt64(Key, v) then Result := v else Result := Default;
end;

function TArgs.GetDoubleDefault(const Key: string; const Default: Double): Double;
var v: Double;
begin
  if TryGetDouble(Key, v) then Result := v else Result := Default;
end;

function TArgs.GetBoolDefault(const Key: string; const Default: boolean): boolean;
var v: boolean;
begin
  if TryGetBool(Key, v) then Result := v else Result := Default;
end;

// internal helpers and convenience wrappers
function FindFlag(const Arr: TStringArray; const Flag: string; CaseInsensitive: boolean): boolean;
var i: Integer; f, norm: string;
begin
  Result := False;
  norm := NormalizeKeyForCheck(Flag, CaseInsensitive);
  for i := 0 to High(Arr) do
  begin
    f := Arr[i];
    if CaseInsensitive then f := LowerCase(f);
    if f = norm then Exit(True);
  end;
  Result := False;
end;

// Convenience API based on current process argv
function ArgsHasFlag(const Flag: string): boolean;
var A: TArgs;
begin
  A := TArgs.FromProcess;
  Result := A.HasFlag(Flag);
end;

function ArgsTryGetValue(const Key: string; out Value: string): boolean;
var A: TArgs;
begin
  A := TArgs.FromProcess;
  Result := A.TryGetValue(Key, Value);
end;

function ArgsGetAll(const Key: string): TStringArray;
var A: TArgs;
begin
  A := TArgs.FromProcess;
  Result := A.GetAll(Key);
end;

function ArgsTryGetBool(const Key: string; out V: boolean): boolean;
var A: TArgs;
begin
  A := TArgs.FromProcess;
  Result := A.TryGetBool(Key, V);
end;

function ArgsGetStringDefault(const Key, Default: string): string;
var A: TArgs;
begin
  A := TArgs.FromProcess;
  Result := A.GetStringDefault(Key, Default);
end;

function ArgsGetInt64Default(const Key: string; const Default: Int64): Int64;
var A: TArgs;
begin
  A := TArgs.FromProcess;
  Result := A.GetInt64Default(Key, Default);
end;

function ArgsGetDoubleDefault(const Key: string; const Default: Double): Double;
var A: TArgs;
begin
  A := TArgs.FromProcess;
  Result := A.GetDoubleDefault(Key, Default);
end;

function ArgsGetBoolDefault(const Key: string; const Default: boolean): boolean;
var A: TArgs;
begin
  A := TArgs.FromProcess;
  Result := A.GetBoolDefault(Key, Default);
end;

function ArgsPositionals: TStringArray;
var A: TArgs;
begin
  A := TArgs.FromProcess;
  Result := A.Positionals;
end;

function ArgsIsHelpRequested: boolean;
var A: TArgs;
begin
  A := TArgs.FromProcess;
  Result := A.HasFlag('help') or A.HasFlag('h') or A.HasFlag('?');
end;


end.
