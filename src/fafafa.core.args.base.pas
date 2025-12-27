unit fafafa.core.args.base;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$modeswitch typehelpers}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes,
  fafafa.core.args.utils,
  fafafa.core.option.base,
  fafafa.core.option,
  fafafa.core.sync.oncelock,
  fafafa.core.atomic  // ✅ P0 修复: 线程安全的全局缓存初始化
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
procedure ArgsOptionsSetDefault(const Opts: TArgsOptions);

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

    // Option-style API (Rust-like)
    function GetOpt(const Key: string): specialize TOption<string>;
    function GetInt64Opt(const Key: string): specialize TOption<Int64>;
    function GetDoubleOpt(const Key: string): specialize TOption<Double>;
    function GetBoolOpt(const Key: string): specialize TOption<Boolean>;
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

    // Option-style API (Rust-like)
    function GetOpt(const Key: string): specialize TOption<string>;
    function GetInt64Opt(const Key: string): specialize TOption<Int64>;
    function GetDoubleOpt(const Key: string): specialize TOption<Double>;
    function GetBoolOpt(const Key: string): specialize TOption<Boolean>;

    // Enumerators for for-in
    function GetEnumerator: TObject;
    function GetArgEnumerator: TObject;
    function GetOptionEnumerator: TObject;
  end;

  TArgsEnumerator = class
  private
    FArgs: TArgs;
    FIndex: Integer;
  public
    constructor Create(A: TArgs);
    function GetCurrent: TArgItem;
    function MoveNext: Boolean;
    property Current: TArgItem read GetCurrent;
  end;

  TArgsArgEnumerator = class
  private
    FArgs: TArgs;
    FIndex: Integer;
  public
    constructor Create(A: TArgs);
    function GetCurrent: string;
    function MoveNext: Boolean;
    property Current: string read GetCurrent;
  end;

  TArgsOptionEnumerator = class
  private
    FArgs: TArgs;
    FIndex: Integer;
  public
    constructor Create(A: TArgs);
    function GetCurrent: TArgItem;
    function MoveNext: Boolean;
    property Current: TArgItem read GetCurrent;
  end;

// Convenience helpers based on current process argv
function ArgsHasFlag(const Flag: string): Boolean;
function ArgsTryGetValue(const Key: string; out Value: string): Boolean;
function ArgsGetAll(const Key: string): TStringArray;
function ArgsPositionals: TStringArray;
function ArgsIsHelpRequested: Boolean;

// Option-style convenience API (Rust-like)
function ArgsGetOpt(const Key: string): specialize TOption<string>;
function ArgsGetInt64Opt(const Key: string): specialize TOption<Int64>;
function ArgsGetDoubleOpt(const Key: string): specialize TOption<Double>;
function ArgsGetBoolOpt(const Key: string): specialize TOption<Boolean>;

implementation

type
  TArgsOnceLock = specialize TOnceLock<TArgs>;

var
  _CachedProcessArgsLock: TArgsOnceLock = nil;
  _DefaultArgsOptions: TArgsOptions;
  _DefaultArgsOptionsSet: Boolean = False;
  _InvariantFormatSettings: TFormatSettings;

// ✅ A5 修复: 使用固定 locale 解析浮点数，避免依赖系统区域设置
function TryStrToFloatInvariant(const S: string; out V: Double): Boolean;
begin
  Result := TryStrToFloat(S, V, _InvariantFormatSettings);
end;

function InitProcessArgs: TArgs;
begin
  if _DefaultArgsOptionsSet then
    Result := TArgs.FromProcess(_DefaultArgsOptions)
  else
    Result := TArgs.FromProcess;
end;

// ✅ P0 修复: 使用原子 CAS 解决竞态条件
// 原始代码存在 TOCTOU 问题：多个线程可能同时看到 nil 并创建多个实例
function GetCachedProcessArgs: TArgs;
var
  NewLock: TArgsOnceLock;
  Expected: Pointer;
begin
  // 快速路径：已初始化时直接返回（原子读）
  if atomic_load(Pointer(_CachedProcessArgsLock), mo_acquire) <> nil then
  begin
    Result := _CachedProcessArgsLock.GetOrInit(@InitProcessArgs);
    Exit;
  end;

  // 慢路径：尝试初始化
  NewLock := TArgsOnceLock.Create;
  Expected := nil;

  // 原子 CAS：仅当 _CachedProcessArgsLock 仍为 nil 时才设置
  if atomic_compare_exchange_strong_ptr(
       Pointer(_CachedProcessArgsLock),
       Expected,
       Pointer(NewLock)) then
  begin
    // CAS 成功，我们的 NewLock 被采用
    Result := _CachedProcessArgsLock.GetOrInit(@InitProcessArgs);
  end
  else
  begin
    // CAS 失败，另一个线程赢了，释放我们创建的实例
    NewLock.Free;
    Result := _CachedProcessArgsLock.GetOrInit(@InitProcessArgs);
  end;
end;

function FindFlag(const Arr: TStringArray; const Flag: string; CaseInsensitive: Boolean): Boolean; forward;

function ArgsOptionsDefault: TArgsOptions;
begin
  Result.CaseInsensitiveKeys := True;
  Result.AllowShortFlagsCombo := True;
  Result.AllowShortKeyValue := True;
  Result.StopAtDoubleDash := True;
  Result.TreatNegativeNumbersAsPositionals := True;
  Result.EnableNoPrefixNegation := False;
end;

procedure ArgsOptionsSetDefault(const Opts: TArgsOptions);
begin
  _DefaultArgsOptions := Opts;
  _DefaultArgsOptionsSet := True;
end;

// ✅ Phase 2: 辅助类型和函数 - 减少 ParseArgs 复杂度

type
  TKeyValuePair = record
    Key: string;
    Value: string;
    HasValue: Boolean;
    Separator: Char;  // '=' or ':' or #0
  end;

function ExtractKeyValue(const Arg: string; const Sep: Char; CaseInsensitive: Boolean): TKeyValuePair; inline;
var sepPos: SizeInt;
begin
  sepPos := Pos(Sep, Arg);
  if sepPos > 0 then
  begin
    Result.Key := NormalizeKey(Copy(Arg, 1, sepPos - 1), CaseInsensitive);
    Result.Value := Copy(Arg, sepPos + 1, MaxInt);
    Result.HasValue := True;
    Result.Separator := Sep;
  end
  else
  begin
    Result.Key := NormalizeKey(Arg, CaseInsensitive);
    Result.Value := '';
    Result.HasValue := False;
    Result.Separator := #0;
  end;
end;

function TryExtractKeyValueWithSep(const Arg: string; CaseInsensitive: Boolean; out KV: TKeyValuePair): Boolean; inline;
begin
  if Pos('=', Arg) > 0 then
  begin
    KV := ExtractKeyValue(Arg, '=', CaseInsensitive);
    Exit(True);
  end;
  if Pos(':', Arg) > 0 then
  begin
    KV := ExtractKeyValue(Arg, ':', CaseInsensitive);
    Exit(True);
  end;
  Result := False;
end;

function CheckNoPrefixNegation(const Arg: string; CaseInsensitive: Boolean; out BaseKey: string): Boolean; inline;
var checkKey: string;
begin
  checkKey := NormalizeKeyForCheck(Arg, CaseInsensitive);
  // 规范化后 no-xxx 变为 no.xxx，所以检查 'no.' 前缀
  if StartsWith(checkKey, 'no.') then
  begin
    BaseKey := NormalizeKey(Copy(checkKey, Length('no.') + 1, MaxInt), CaseInsensitive);
    Exit(True);
  end;
  Result := False;
end;

function TArgsContext.Flags: TStringArray; inline; begin Result := nil; Result := FFlags; end;
function TArgsContext.Keys: TStringArray; inline; begin Result := nil; Result := FKeys; end;
function TArgsContext.Values: TStringArray; inline; begin Result := nil; Result := FValues; end;
function TArgsContext.Positionals: TStringArray; inline; begin Result := nil; Result := FPositionals; end;

procedure ParseArgs(const Args: array of string; const Opts: TArgsOptions; out Ctx: TArgsContext);
var i, posOpt: Integer; a, key, val, baseKey: string; stop: Boolean; kv: TKeyValuePair;
  procedure AddItem(const Kind: TArgKind; const Name, Value: string; const HasValue: Boolean; const PosIndex: Integer);
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
  procedure AddKeyValue(const Kind: TArgKind; const K, V: string; const PosIdx: Integer); inline;
  begin
    AddString(Ctx.FKeys, K); AddString(Ctx.FValues, V);
    AddItem(Kind, K, V, True, PosIdx);
  end;
  procedure AddFlag(const Kind: TArgKind; const K: string; const PosIdx: Integer); inline;
  begin
    AddString(Ctx.FFlags, K);
    AddItem(Kind, K, '', False, PosIdx);
  end;
  function NextIsValue: Boolean;
  var nextTok: string;
  begin
    if i+1>High(Args) then Exit(False);
    nextTok := Args[i+1];
    if nextTok='--' then Exit(False);
    if (Length(nextTok)>0) and (nextTok[1]='-') then
    begin
      if Opts.TreatNegativeNumbersAsPositionals and IsNegativeNumberLike(nextTok) then
        Exit(True)
      else
        Exit(False);
    end;
    if (Length(nextTok)>0) and (nextTok[1]='/') then Exit(False);
    Result := True;
  end;
  procedure HandleLongOption;
  var noKey: string;
  begin
    // --key=value 或 --key:value 或 --key 或 --key value
    if TryExtractKeyValueWithSep(a, Opts.CaseInsensitiveKeys, kv) then
    begin
      // 处理 --no-xxx=value 情况
      if Opts.EnableNoPrefixNegation and CheckNoPrefixNegation(Copy(a, 1, Pos(kv.Separator, a)-1), Opts.CaseInsensitiveKeys, baseKey) then
        AddKeyValue(akOptionLong, baseKey, kv.Value, i);
      AddKeyValue(akOptionLong, kv.Key, kv.Value, i);
    end
    else
    begin
      key := NormalizeKey(a, Opts.CaseInsensitiveKeys);
      if NextIsValue then
      begin
        posOpt := i;
        val := Args[i+1]; Inc(i);
        AddKeyValue(akOptionLong, key, val, posOpt);
      end
      else if Opts.EnableNoPrefixNegation and CheckNoPrefixNegation(a, Opts.CaseInsensitiveKeys, baseKey) then
      begin
        // ✅ A4 修复: 同时添加 baseKey=false 和 no.xxx 标志
        AddKeyValue(akOptionLong, baseKey, 'false', i);
        noKey := NormalizeKey(a, Opts.CaseInsensitiveKeys);
        AddFlag(akOptionLong, noKey, i);
      end
      else
        AddFlag(akOptionLong, key, i);
    end;
  end;
  procedure HandleShortOption;
  var jj: Integer; noKey: string;
  begin
    // -k=value 或 -k:value 或 -k value 或 -abc (组合标志)
    if Opts.AllowShortKeyValue and TryExtractKeyValueWithSep(a, Opts.CaseInsensitiveKeys, kv) then
      AddKeyValue(akOptionShort, kv.Key, kv.Value, i)
    else if Opts.AllowShortKeyValue and (Length(a)=2) and NextIsValue then
    begin
      key := NormalizeKey(a, Opts.CaseInsensitiveKeys);
      posOpt := i;
      val := Args[i+1]; Inc(i);
      AddKeyValue(akOptionShort, key, val, posOpt);
    end
    else if Opts.EnableNoPrefixNegation and (Length(a)>=4) and (Copy(a,1,4)='-no-') then
    begin
      // ✅ A4 修复: 同时添加 baseKey=false 和 no.xxx 标志
      baseKey := NormalizeKey(Copy(a, 5, MaxInt), Opts.CaseInsensitiveKeys);
      AddKeyValue(akOptionShort, baseKey, 'false', i);
      noKey := NormalizeKey(a, Opts.CaseInsensitiveKeys);
      AddFlag(akOptionShort, noKey, i);
    end
    else if Opts.AllowShortFlagsCombo then
    begin
      for jj := 2 to Length(a) do
      begin
        key := NormalizeKey('-'+a[jj], Opts.CaseInsensitiveKeys);
        AddFlag(akOptionShort, key, i);
      end;
    end
    else
    begin
      key := NormalizeKey(a, Opts.CaseInsensitiveKeys);
      AddFlag(akOptionShort, key, i);
    end;
  end;
  procedure HandleSlashOption;
  var noKey: string;
  begin
    // /key=value 或 /key:value 或 /key
    if TryExtractKeyValueWithSep(a, Opts.CaseInsensitiveKeys, kv) then
    begin
      if Opts.EnableNoPrefixNegation and CheckNoPrefixNegation(Copy(a, 1, Pos(kv.Separator, a)-1), Opts.CaseInsensitiveKeys, baseKey) then
        AddKeyValue(akOptionLong, baseKey, kv.Value, i);
      AddKeyValue(akOptionLong, kv.Key, kv.Value, i);
    end
    else
    begin
      key := NormalizeKey(a, Opts.CaseInsensitiveKeys);
      if Opts.EnableNoPrefixNegation and CheckNoPrefixNegation(a, Opts.CaseInsensitiveKeys, baseKey) then
      begin
        // ✅ A4 修复: 同时添加 baseKey=false 和 no.xxx 标志
        AddKeyValue(akOptionLong, baseKey, 'false', i);
        noKey := NormalizeKey(a, Opts.CaseInsensitiveKeys);
        AddFlag(akOptionLong, noKey, i);
      end
      else
        AddFlag(akOptionLong, key, i);
    end;
  end;
begin
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

    // 处理 -- 停止解析标记
    if a='--' then
    begin
      if Opts.StopAtDoubleDash then
      begin
        stop := True; Inc(i); Break;
      end
      else
      begin
        AddString(Ctx.FPositionals, a);
        AddItem(akArg, '', a, False, i);
        stop := True; Inc(i); Break;
      end;
    end;

    // 根据前缀分派处理
    if (Length(a)>=2) and StartsWith(a,'--') then
      HandleLongOption
    else if (Length(a)>=2) and (a[1]='-') then
      HandleShortOption
    else if (Length(a)>=1) and (a[1]='/') then
      HandleSlashOption
    else
    begin
      AddString(Ctx.FPositionals, a);
      AddItem(akArg, '', a, False, i);
    end;
    Inc(i);
  end;

  // 处理 -- 之后的剩余参数
  if stop then
    while i<=High(Args) do
    begin
      AddString(Ctx.FPositionals, Args[i]);
      AddItem(akArg, '', Args[i], False, i);
      Inc(i);
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
  pCmd := GetCommandLineW;
  pArgv := CommandLineToArgvW(pCmd, @argc);
  if pArgv<>nil then
  try
    if argc>0 then
    begin
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

function TArgs.HasFlag(const Name: string): Boolean;
begin
  Result := FindFlag(FCtx.Flags, Name, FOpts.CaseInsensitiveKeys);
end;

function TArgs.TryGetValue(const Key: string; out Value: string): Boolean;
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

function TArgs.TryGetInt64(const Key: string; out V: Int64): Boolean;
var s: string;
begin
  if not TryGetValue(Key, s) then Exit(False);
  Result := TryStrToInt64(s, V);
end;

function TArgs.TryGetDouble(const Key: string; out V: Double): Boolean;
var s: string;
begin
  if not TryGetValue(Key, s) then Exit(False);
  Result := TryStrToFloatInvariant(s, V);
end;

function TArgs.TryGetBool(const Key: string; out V: Boolean): Boolean;
var s: string;
begin
  if not TryGetValue(Key, s) then Exit(False);
  if IsTrueValue(s) then begin V := True; Exit(True); end;
  if IsFalseValue(s) then begin V := False; Exit(True); end;
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

function TArgs.GetBoolDefault(const Key: string; const Default: Boolean): Boolean;
var v: Boolean;
begin
  if TryGetBool(Key, v) then Result := v else Result := Default;
end;

function TArgs.GetOpt(const Key: string): specialize TOption<string>;
var s: string;
begin
  if TryGetValue(Key, s) then
    Result := specialize TOption<string>.Some(s)
  else
    Result := specialize TOption<string>.None;
end;

function TArgs.GetInt64Opt(const Key: string): specialize TOption<Int64>;
var s: string; v: Int64;
begin
  s := '';
  if TryGetValue(Key, s) and TryStrToInt64(s, v) then
    Result := specialize TOption<Int64>.Some(v)
  else
    Result := specialize TOption<Int64>.None;
end;

function TArgs.GetDoubleOpt(const Key: string): specialize TOption<Double>;
var s: string; v: Double;
begin
  s := '';
  if TryGetValue(Key, s) and TryStrToFloatInvariant(s, v) then
    Result := specialize TOption<Double>.Some(v)
  else
    Result := specialize TOption<Double>.None;
end;

function TArgs.GetBoolOpt(const Key: string): specialize TOption<Boolean>;
var s: string;
begin
  if not TryGetValue(Key, s) then
    Exit(specialize TOption<Boolean>.None);
  if IsTrueValue(s) then
    Exit(specialize TOption<Boolean>.Some(True));
  if IsFalseValue(s) then
    Exit(specialize TOption<Boolean>.Some(False));
  Result := specialize TOption<Boolean>.None;
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

function TArgsEnumerator.MoveNext: Boolean;
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

function TArgsArgEnumerator.MoveNext: Boolean;
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

function TArgsOptionEnumerator.MoveNext: Boolean;
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

function FindFlag(const Arr: TStringArray; const Flag: string; CaseInsensitive: Boolean): Boolean;
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
end;

// Convenience API
function ArgsHasFlag(const Flag: string): Boolean;
begin
  Result := GetCachedProcessArgs.HasFlag(Flag);
end;

function ArgsTryGetValue(const Key: string; out Value: string): Boolean;
begin
  Result := GetCachedProcessArgs.TryGetValue(Key, Value);
end;

function ArgsGetAll(const Key: string): TStringArray;
begin
  Result := GetCachedProcessArgs.GetAll(Key);
end;

function ArgsPositionals: TStringArray;
begin
  Result := GetCachedProcessArgs.Positionals;
end;

function ArgsIsHelpRequested: Boolean;
var A: TArgs;
begin
  A := GetCachedProcessArgs;
  Result := A.HasFlag('help') or A.HasFlag('h') or A.HasFlag('?');
end;

function ArgsGetOpt(const Key: string): specialize TOption<string>;
begin
  Result := GetCachedProcessArgs.GetOpt(Key);
end;

function ArgsGetInt64Opt(const Key: string): specialize TOption<Int64>;
begin
  Result := GetCachedProcessArgs.GetInt64Opt(Key);
end;

function ArgsGetDoubleOpt(const Key: string): specialize TOption<Double>;
begin
  Result := GetCachedProcessArgs.GetDoubleOpt(Key);
end;

function ArgsGetBoolOpt(const Key: string): specialize TOption<Boolean>;
begin
  Result := GetCachedProcessArgs.GetBoolOpt(Key);
end;

initialization
  // ✅ A5: 初始化固定 locale 的 FormatSettings
  _InvariantFormatSettings := DefaultFormatSettings;
  _InvariantFormatSettings.DecimalSeparator := '.';
  _InvariantFormatSettings.ThousandSeparator := ',';

finalization
  // 清理 OnceLock
  if _CachedProcessArgsLock <> nil then
    _CachedProcessArgsLock.Free;

end.
