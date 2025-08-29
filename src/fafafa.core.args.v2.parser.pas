unit fafafa.core.args.v2.parser;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes,
  fafafa.core.args.v2;

// 高性能解析器实现
function ParseArgs(const Args: array of string; const Opts: TArgsOptions; out Ctx: TArgsContext): TArgsError;
function ParseArgsWithCache(const Args: array of string; const Opts: TArgsOptions; out Ctx: TArgsContext): TArgsError;

implementation

// 内部辅助函数
function IsShortOption(const s: string): Boolean; inline;
begin
  Result := (Length(s) >= 2) and (s[1] = '-') and (s[2] <> '-') and not (s[2] in ['0'..'9']);
end;

function IsLongOption(const s: string): Boolean; inline;
begin
  Result := (Length(s) >= 3) and (s[1] = '-') and (s[2] = '-') and (s[3] <> '-');
end;

function IsWindowsOption(const s: string): Boolean; inline;
begin
  Result := (Length(s) >= 2) and (s[1] = '/') and not (s[2] in ['0'..'9']);
end;

function IsNegativeNumber(const s: string): Boolean; inline;
var
  dummy: Double;
begin
  Result := (Length(s) >= 2) and (s[1] = '-') and TryStrToFloat(s, dummy);
end;

function NormalizeKey(const Key: string; CaseInsensitive: Boolean): string;
begin
  Result := Key;
  if CaseInsensitive then
    Result := LowerCase(Result);
  // 将 dash 转换为 dot
  Result := StringReplace(Result, '-', '.', [rfReplaceAll]);
end;

function ExtractOptionName(const s: string): string;
begin
  if IsLongOption(s) then
    Result := Copy(s, 3, Length(s))
  else if IsShortOption(s) or IsWindowsOption(s) then
    Result := Copy(s, 2, Length(s))
  else
    Result := s;
end;

function SplitOptionValue(const s: string; out Name, Value: string): Boolean;
var
  EqPos: Integer;
begin
  EqPos := Pos('=', s);
  if EqPos > 0 then
  begin
    Name := Copy(s, 1, EqPos - 1);
    Value := Copy(s, EqPos + 1, Length(s));
    Result := True;
  end
  else
  begin
    EqPos := Pos(':', s);
    if EqPos > 0 then
    begin
      Name := Copy(s, 1, EqPos - 1);
      Value := Copy(s, EqPos + 1, Length(s));
      Result := True;
    end
    else
    begin
      Name := s;
      Value := '';
      Result := False;
    end;
  end;
end;

procedure AddFlag(var Ctx: TArgsContext; const Name: string; const Opts: TArgsOptions; Position: Integer);
var
  normName: string;
  idx: Integer;
begin
  normName := NormalizeKey(ExtractOptionName(Name), Opts.CaseInsensitiveKeys);
  
  // 添加到标志查找表
  idx := Ctx.FFlagCount;
  if idx >= Length(Ctx.FFlagLookup) then
    SetLength(Ctx.FFlagLookup, idx + 10);
  Ctx.FFlagLookup[idx].Key := normName;
  Ctx.FFlagLookup[idx].Value := True;
  Inc(Ctx.FFlagCount);
  
  // 添加到项目列表
  idx := Length(Ctx.FItemNames);
  SetLength(Ctx.FItemNames, idx + 1);
  SetLength(Ctx.FItemValues, idx + 1);
  SetLength(Ctx.FItemHasValue, idx + 1);
  SetLength(Ctx.FItemKinds, idx + 1);
  SetLength(Ctx.FItemPositions, idx + 1);
  
  Ctx.FItemNames[idx] := normName;
  Ctx.FItemValues[idx] := '';
  Ctx.FItemHasValue[idx] := False;
  if IsLongOption(Name) then
    Ctx.FItemKinds[idx] := akOptionLong
  else
    Ctx.FItemKinds[idx] := akOptionShort;
  Ctx.FItemPositions[idx] := Position;
end;

procedure AddOption(var Ctx: TArgsContext; const Name, Value: string; const Opts: TArgsOptions; Position: Integer);
var
  normName: string;
  idx: Integer;
begin
  normName := NormalizeKey(ExtractOptionName(Name), Opts.CaseInsensitiveKeys);
  
  // 添加到键查找表
  idx := Ctx.FKeyCount;
  if idx >= Length(Ctx.FKeyLookup) then
    SetLength(Ctx.FKeyLookup, idx + 10);
  Ctx.FKeyLookup[idx].Key := normName;
  Ctx.FKeyLookup[idx].Index := Length(Ctx.FKeys);
  Inc(Ctx.FKeyCount);
  
  // 添加到键值数组
  idx := Length(Ctx.FKeys);
  SetLength(Ctx.FKeys, idx + 1);
  SetLength(Ctx.FValues, idx + 1);
  Ctx.FKeys[idx] := normName;
  Ctx.FValues[idx] := Value;
  
  // 添加到项目列表
  idx := Length(Ctx.FItemNames);
  SetLength(Ctx.FItemNames, idx + 1);
  SetLength(Ctx.FItemValues, idx + 1);
  SetLength(Ctx.FItemHasValue, idx + 1);
  SetLength(Ctx.FItemKinds, idx + 1);
  SetLength(Ctx.FItemPositions, idx + 1);
  
  Ctx.FItemNames[idx] := normName;
  Ctx.FItemValues[idx] := Value;
  Ctx.FItemHasValue[idx] := True;
  if IsLongOption(Name) then
    Ctx.FItemKinds[idx] := akOptionLong
  else
    Ctx.FItemKinds[idx] := akOptionShort;
  Ctx.FItemPositions[idx] := Position;
end;

procedure AddPositional(var Ctx: TArgsContext; const Value: string; Position: Integer);
var
  idx: Integer;
begin
  // 添加到位置参数数组
  idx := Length(Ctx.FPositionals);
  SetLength(Ctx.FPositionals, idx + 1);
  Ctx.FPositionals[idx] := Value;
  
  // 添加到项目列表
  idx := Length(Ctx.FItemNames);
  SetLength(Ctx.FItemNames, idx + 1);
  SetLength(Ctx.FItemValues, idx + 1);
  SetLength(Ctx.FItemHasValue, idx + 1);
  SetLength(Ctx.FItemKinds, idx + 1);
  SetLength(Ctx.FItemPositions, idx + 1);
  
  Ctx.FItemNames[idx] := '';
  Ctx.FItemValues[idx] := Value;
  Ctx.FItemHasValue[idx] := False;
  Ctx.FItemKinds[idx] := akArg;
  Ctx.FItemPositions[idx] := Position;
end;

function ParseArgs(const Args: array of string; const Opts: TArgsOptions; out Ctx: TArgsContext): TArgsError;
var
  i: Integer;
  arg, nextArg: string;
  optName, optValue: string;
  hasValue: Boolean;
  stopParsing: Boolean;
  j: Integer;
begin
  Result := TArgsError.Success;
  // 初始化上下文
  SetLength(Ctx.FFlags, 0);
  SetLength(Ctx.FKeys, 0);
  SetLength(Ctx.FValues, 0);
  SetLength(Ctx.FPositionals, 0);
  SetLength(Ctx.FItemNames, 0);
  SetLength(Ctx.FItemValues, 0);
  SetLength(Ctx.FItemHasValue, 0);
  SetLength(Ctx.FItemKinds, 0);
  SetLength(Ctx.FItemPositions, 0);
  SetLength(Ctx.FKeyLookup, 0);
  SetLength(Ctx.FFlagLookup, 0);
  Ctx.FKeyCount := 0;
  Ctx.FFlagCount := 0;
  Ctx.FInitialized := True;
  
  stopParsing := False;
  i := Low(Args);
  
  while i <= High(Args) do
  begin
    arg := Args[i];
    
    // 检查双破折号停止解析
    if (arg = '--') and Opts.StopAtDoubleDash then
    begin
      stopParsing := True;
      Inc(i);
      continue;
    end;
    
    // 如果停止解析，所有后续参数都是位置参数
    if stopParsing then
    begin
      AddPositional(Ctx, arg, i);
      Inc(i);
      continue;
    end;
    
    // 检查负数
    if Opts.TreatNegativeNumbersAsPositionals and IsNegativeNumber(arg) then
    begin
      AddPositional(Ctx, arg, i);
      Inc(i);
      continue;
    end;
    
    // 处理长选项
    if IsLongOption(arg) then
    begin
      hasValue := SplitOptionValue(arg, optName, optValue);
      optName := ExtractOptionName(optName);
      
      // 处理 --no- 前缀
      if Opts.EnableNoPrefixNegation and (Copy(optName, 1, 3) = 'no-') then
      begin
        optName := Copy(optName, 4, Length(optName));
        if not hasValue then
          optValue := 'false';
        AddOption(Ctx, optName, optValue, Opts, i);
      end
      else if hasValue then
      begin
        AddOption(Ctx, optName, optValue, Opts, i);
      end
      else
      begin
        // 检查下一个参数是否是值
        if (i < High(Args)) and not IsShortOption(Args[i+1]) and not IsLongOption(Args[i+1]) and not IsWindowsOption(Args[i+1]) then
        begin
          Inc(i);
          nextArg := Args[i];
          AddOption(Ctx, optName, nextArg, Opts, i-1);
        end
        else
        begin
          AddFlag(Ctx, optName, Opts, i);
        end;
      end;
    end
    // 处理短选项
    else if IsShortOption(arg) then
    begin
      hasValue := SplitOptionValue(arg, optName, optValue);
      
      if hasValue then
      begin
        optName := ExtractOptionName(optName);
        AddOption(Ctx, optName, optValue, Opts, i);
      end
      else if Opts.AllowShortFlagsCombo and (Length(arg) > 2) then
      begin
        // 展开组合短标志 -abc -> -a -b -c
        for j := 2 to Length(arg) do
          AddFlag(Ctx, '-' + arg[j], Opts, i);
      end
      else
      begin
        optName := ExtractOptionName(arg);
        // 检查下一个参数是否是值
        if Opts.AllowShortKeyValue and (i < High(Args)) and not IsShortOption(Args[i+1]) and not IsLongOption(Args[i+1]) and not IsWindowsOption(Args[i+1]) then
        begin
          Inc(i);
          nextArg := Args[i];
          AddOption(Ctx, optName, nextArg, Opts, i-1);
        end
        else
        begin
          AddFlag(Ctx, optName, Opts, i);
        end;
      end;
    end
    // 处理 Windows 风格选项
    else if IsWindowsOption(arg) then
    begin
      hasValue := SplitOptionValue(arg, optName, optValue);
      optName := ExtractOptionName(optName);
      
      if hasValue then
        AddOption(Ctx, optName, optValue, Opts, i)
      else
        AddFlag(Ctx, optName, Opts, i);
    end
    // 位置参数
    else
    begin
      AddPositional(Ctx, arg, i);
    end;
    
    Inc(i);
  end;
end;

function ParseArgsWithCache(const Args: array of string; const Opts: TArgsOptions; out Ctx: TArgsContext): TArgsError;
begin
  // 简化版本，直接调用 ParseArgs
  Result := ParseArgs(Args, Opts, Ctx);
end;

end.
