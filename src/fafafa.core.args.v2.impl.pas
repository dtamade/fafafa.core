unit fafafa.core.args.v2.impl;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes,
  fafafa.core.args.v2,
  fafafa.core.args.v2.parser;





implementation

// 实现部分

// 辅助函数实现
function ArgsResultOk(const Value: string): TArgsResult;
begin
  Result.IsOk := True;
  Result.Value := Value;
  Result.Error := TArgsError.Success;
end;

function ArgsResultErr(const Error: TArgsError): TArgsResult;
begin
  Result.IsOk := False;
  Result.Value := '';
  Result.Error := Error;
end;

function ArgsResultIntOk(const Value: Int64): TArgsResultInt;
begin
  Result.IsOk := True;
  Result.Value := Value;
  Result.Error := TArgsError.Success;
end;

function ArgsResultIntErr(const Error: TArgsError): TArgsResultInt;
begin
  Result.IsOk := False;
  Result.Value := 0;
  Result.Error := Error;
end;

function ArgsResultDoubleOk(const Value: Double): TArgsResultDouble;
begin
  Result.IsOk := True;
  Result.Value := Value;
  Result.Error := TArgsError.Success;
end;

function ArgsResultDoubleErr(const Error: TArgsError): TArgsResultDouble;
begin
  Result.IsOk := False;
  Result.Value := 0.0;
  Result.Error := Error;
end;

function ArgsResultBoolOk(const Value: Boolean): TArgsResultBool;
begin
  Result.IsOk := True;
  Result.Value := Value;
  Result.Error := TArgsError.Success;
end;

function ArgsResultBoolErr(const Error: TArgsError): TArgsResultBool;
begin
  Result.IsOk := False;
  Result.Value := False;
  Result.Error := Error;
end;

// TArgsV2 实现
constructor TArgsV2.Create;
begin
  inherited Create;
  // 初始化上下文
  SetLength(FCtx.FFlags, 0);
  SetLength(FCtx.FKeys, 0);
  SetLength(FCtx.FValues, 0);
  SetLength(FCtx.FPositionals, 0);
  SetLength(FCtx.FItemNames, 0);
  SetLength(FCtx.FItemValues, 0);
  SetLength(FCtx.FItemHasValue, 0);
  SetLength(FCtx.FItemKinds, 0);
  SetLength(FCtx.FItemPositions, 0);
  SetLength(FCtx.FKeyLookup, 0);
  SetLength(FCtx.FFlagLookup, 0);
  FCtx.FKeyCount := 0;
  FCtx.FFlagCount := 0;
  FCtx.FInitialized := True;
  FOpts := TArgsOptions.Default;
  FInitialized := False;
end;

destructor TArgsV2.Destroy;
begin
  // 清理上下文
  SetLength(FCtx.FFlags, 0);
  SetLength(FCtx.FKeys, 0);
  SetLength(FCtx.FValues, 0);
  SetLength(FCtx.FPositionals, 0);
  SetLength(FCtx.FItemNames, 0);
  SetLength(FCtx.FItemValues, 0);
  SetLength(FCtx.FItemHasValue, 0);
  SetLength(FCtx.FItemKinds, 0);
  SetLength(FCtx.FItemPositions, 0);
  SetLength(FCtx.FKeyLookup, 0);
  SetLength(FCtx.FFlagLookup, 0);
  inherited Destroy;
end;

procedure TArgsV2.EnsureInitialized;
begin
  if not FInitialized then
    raise Exception.Create('Args not initialized. Use FromProcess or FromArray.');
end;

function TArgsV2.NormalizeKey(const Key: string): string;
begin
  Result := Key;
  if FOpts.CaseInsensitiveKeys then
    Result := LowerCase(Result);
  // 将 dash 转换为 dot (--app-name -> app.name)
  Result := StringReplace(Result, '-', '.', [rfReplaceAll]);
end;

class function TArgsV2.FromProcess(const Opts: TArgsOptions): TArgsV2;
var
  args: TStringArray;
  i: Integer;
  err: TArgsError;
begin
  Result := TArgsV2.Create;
  Result.FOpts := Opts;
  
  // 收集进程参数
  SetLength(args, ParamCount);
  for i := 1 to ParamCount do
    args[i-1] := ParamStr(i);
  
  if Opts.EnableCaching then
    err := ParseArgsWithCache(args, Opts, Result.FCtx)
  else
    err := ParseArgs(args, Opts, Result.FCtx);
    
  if not err.IsSuccess then
    raise Exception.Create(err.ToDetailedString);
    
  Result.FInitialized := True;
end;

class function TArgsV2.FromProcess: TArgsV2;
begin
  Result := FromProcess(TArgsOptions.Default);
end;

class function TArgsV2.FromArray(const A: array of string; const Opts: TArgsOptions): TArgsV2;
var
  err: TArgsError;
begin
  Result := TArgsV2.Create;
  Result.FOpts := Opts;
  
  err := ParseArgs(A, Opts, Result.FCtx);
  if not err.IsSuccess then
    raise Exception.Create(err.ToDetailedString);
    
  Result.FInitialized := True;
end;

class function TArgsV2.FromArrayCached(const A: array of string; const Opts: TArgsOptions): TArgsV2;
var
  err: TArgsError;
begin
  Result := TArgsV2.Create;
  Result.FOpts := Opts;
  
  err := ParseArgsWithCache(A, Opts, Result.FCtx);
  if not err.IsSuccess then
    raise Exception.Create(err.ToDetailedString);
    
  Result.FInitialized := True;
end;

function TArgsV2.Count: Integer;
begin
  EnsureInitialized;
  Result := Length(FCtx.FItemNames);
end;

function TArgsV2.Items(Index: Integer): TArgItem;
begin
  EnsureInitialized;
  if (Index >= 0) and (Index < Length(FCtx.FItemNames)) then
  begin
    Result.Name := FCtx.FItemNames[Index];
    Result.Value := FCtx.FItemValues[Index];
    Result.HasValue := FCtx.FItemHasValue[Index];
    Result.Kind := FCtx.FItemKinds[Index];
    Result.Position := FCtx.FItemPositions[Index];
  end
  else
  begin
    Result.Name := '';
    Result.Value := '';
    Result.HasValue := False;
    Result.Kind := akArg;
    Result.Position := -1;
  end;
end;

function TArgsV2.Positionals: TStringArray;
begin
  EnsureInitialized;
  Result := FCtx.FPositionals;
end;

function TArgsV2.GetValue(const Key: string): TArgsResult;
var
  value: string;
  normKey: string;
  i: Integer;
begin
  EnsureInitialized;
  normKey := NormalizeKey(Key);

  // 快速查找
  for i := 0 to FCtx.FKeyCount - 1 do
  begin
    if LowerCase(FCtx.FKeyLookup[i].Key) = LowerCase(normKey) then
    begin
      if (FCtx.FKeyLookup[i].Index >= 0) and (FCtx.FKeyLookup[i].Index < Length(FCtx.FValues)) then
      begin
        value := FCtx.FValues[FCtx.FKeyLookup[i].Index];
        Result := ArgsResultOk(value);
        Exit;
      end;
    end;
  end;

  Result := ArgsResultErr(TArgsError.UnknownOption(Key));
end;

function TArgsV2.GetInt(const Key: string): TArgsResultInt;
var
  valueResult: TArgsResult;
  intValue: Int64;
begin
  valueResult := GetValue(Key);
  if valueResult.IsOk then
  begin
    if TryStrToInt64(valueResult.Value, intValue) then
      Result := ArgsResultIntOk(intValue)
    else
      Result := ArgsResultIntErr(TArgsError.InvalidValue(Key, 'integer', valueResult.Value));
  end
  else
    Result := ArgsResultIntErr(valueResult.Error);
end;

function TArgsV2.GetDouble(const Key: string): TArgsResultDouble;
var
  valueResult: TArgsResult;
  doubleValue: Double;
begin
  valueResult := GetValue(Key);
  if valueResult.IsOk then
  begin
    if TryStrToFloat(valueResult.Value, doubleValue) then
      Result := ArgsResultDoubleOk(doubleValue)
    else
      Result := ArgsResultDoubleErr(TArgsError.InvalidValue(Key, 'number', valueResult.Value));
  end
  else
    Result := ArgsResultDoubleErr(valueResult.Error);
end;

function TArgsV2.GetBool(const Key: string): TArgsResultBool;
var
  valueResult: TArgsResult;
  value: string;
  boolValue: Boolean;
begin
  // 首先检查是否是标志
  if HasFlag(Key) then
    Exit(ArgsResultBoolOk(True));

  valueResult := GetValue(Key);
  if valueResult.IsOk then
  begin
    value := LowerCase(Trim(valueResult.Value));
    if (value = 'true') or (value = '1') or (value = 'yes') or (value = 'on') then
      boolValue := True
    else if (value = 'false') or (value = '0') or (value = 'no') or (value = 'off') then
      boolValue := False
    else
      Exit(ArgsResultBoolErr(TArgsError.InvalidValue(Key, 'boolean', valueResult.Value)));

    Result := ArgsResultBoolOk(boolValue);
  end
  else
    Result := ArgsResultBoolErr(valueResult.Error);
end;

function TArgsV2.GetAll(const Key: string): TStringArray;
var
  i, count: Integer;
  normKey: string;
  item: TArgItem;
begin
  EnsureInitialized;
  normKey := NormalizeKey(Key);
  
  // 首先计算匹配的数量
  count := 0;
  for i := 0 to Length(FCtx.FItemNames) - 1 do
  begin
    if (NormalizeKey(FCtx.FItemNames[i]) = normKey) and FCtx.FItemHasValue[i] then
      Inc(count);
  end;

  // 分配数组并填充
  SetLength(Result, count);
  count := 0;
  for i := 0 to Length(FCtx.FItemNames) - 1 do
  begin
    if (NormalizeKey(FCtx.FItemNames[i]) = normKey) and FCtx.FItemHasValue[i] then
    begin
      Result[count] := FCtx.FItemValues[i];
      Inc(count);
    end;
  end;
end;

function TArgsV2.HasFlag(const Name: string): Boolean;
var
  normName: string;
  i: Integer;
begin
  EnsureInitialized;
  normName := NormalizeKey(Name);
  Result := False;

  for i := 0 to FCtx.FFlagCount - 1 do
  begin
    if LowerCase(FCtx.FFlagLookup[i].Key) = LowerCase(normName) then
    begin
      Result := FCtx.FFlagLookup[i].Value;
      Exit;
    end;
  end;
end;

function TArgsV2.TryGetValueFast(const Key: string; out Value: string): Boolean;
var
  normKey: string;
  i: Integer;
begin
  EnsureInitialized;
  normKey := NormalizeKey(Key);
  Result := False;
  Value := '';

  for i := 0 to FCtx.FKeyCount - 1 do
  begin
    if LowerCase(FCtx.FKeyLookup[i].Key) = LowerCase(normKey) then
    begin
      if (FCtx.FKeyLookup[i].Index >= 0) and (FCtx.FKeyLookup[i].Index < Length(FCtx.FValues)) then
      begin
        Value := FCtx.FValues[FCtx.FKeyLookup[i].Index];
        Result := True;
      end;
      Exit;
    end;
  end;
end;

// TArgsBuilder 实现
constructor TArgsBuilder.Create;
begin
  inherited Create;
  FOptions := TArgsOptions.Default;
  SetLength(FOptionSpecs, 0);
  SetLength(FValidators, 0);
end;

function TArgsBuilder.WithOption(const Name, Description: string; Required: Boolean): IArgsBuilder;
var
  idx: Integer;
begin
  idx := Length(FOptionSpecs);
  SetLength(FOptionSpecs, idx + 1);
  FOptionSpecs[idx].Name := Name;
  FOptionSpecs[idx].Description := Description;
  FOptionSpecs[idx].Required := Required;
  FOptionSpecs[idx].IsFlag := False;
  Result := Self;
end;

function TArgsBuilder.WithFlag(const Name, Description: string): IArgsBuilder;
var
  idx: Integer;
begin
  idx := Length(FOptionSpecs);
  SetLength(FOptionSpecs, idx + 1);
  FOptionSpecs[idx].Name := Name;
  FOptionSpecs[idx].Description := Description;
  FOptionSpecs[idx].Required := False;
  FOptionSpecs[idx].IsFlag := True;
  Result := Self;
end;

function TArgsBuilder.WithPositional(const Name, Description: string; Required: Boolean): IArgsBuilder;
begin
  // 简化实现，暂时不处理位置参数规范
  Result := Self;
end;

function TArgsBuilder.WithValidation(const Key: string; Validator: TArgsValidator): IArgsBuilder;
var
  idx: Integer;
begin
  idx := Length(FValidators);
  SetLength(FValidators, idx + 1);
  FValidators[idx].Key := Key;
  FValidators[idx].Validator := Validator;
  Result := Self;
end;

function TArgsBuilder.Parse(const Args: array of string): IArgs;
begin
  Result := TArgsV2.FromArray(Args, FOptions);
end;

function TArgsBuilder.ParseProcess: IArgs;
begin
  Result := TArgsV2.FromProcess(FOptions);
end;

// 工厂函数
function NewArgsBuilder: IArgsBuilder;
begin
  Result := TArgsBuilder.Create;
end;

function Args: IArgsBuilder;
begin
  Result := NewArgsBuilder;
end;

end.
