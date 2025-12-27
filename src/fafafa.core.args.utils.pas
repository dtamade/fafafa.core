unit fafafa.core.args.utils;
{**
 * fafafa.core.args.utils - 参数解析工具函数
 *
 * 提供键规范化、布尔值解析等通用工具
 * ✅ P3-2: 从 internal 重命名为 utils
 *}

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

type
  TStringArray = array of string;

const
  // 帮助选项别名
  HELP_ALIAS_CHAR = '?';
  HELP_CANONICAL  = 'help';

  // 布尔真值列表（大小写不敏感匹配）
  TRUE_VALUES: array[0..2] of string = ('true', '1', 'yes');

  // 布尔假值列表（大小写不敏感匹配）
  FALSE_VALUES: array[0..2] of string = ('false', '0', 'no');

// 字符串数组辅助
procedure AddString(var Arr: TStringArray; const S: string); inline;

// 键规范化
function NormalizeKey(const Key: string; CaseInsensitive: Boolean): string;
function NormalizeKeyForCheck(const Key: string; CaseInsensitive: Boolean): string;

// 字符串工具
function StartsWith(const S, Prefix: string): Boolean; inline;
function IsNegativeNumberLike(const S: string): Boolean;

// 布尔值解析辅助
function IsTrueValue(const S: string): Boolean;
function IsFalseValue(const S: string): Boolean;

implementation

uses
  SysUtils;

procedure AddString(var Arr: TStringArray; const S: string); inline;
var
  L: SizeInt;
begin
  L := Length(Arr);
  SetLength(Arr, L + 1);
  Arr[L] := S;
end;

function NormalizeKey(const Key: string; CaseInsensitive: Boolean): string;
var
  i: Integer;
  res: string;
begin
  res := Key;
  // 移除前导 - 或 /
  while (Length(res) > 0) and (res[1] in ['-', '/']) do
    Delete(res, 1, 1);
  // 处理 '?' 作为 'help' 的别名
  if res = HELP_ALIAS_CHAR then
    res := HELP_CANONICAL;
  // 大小写处理
  if CaseInsensitive then
    res := LowerCase(res);
  // 规范化路径: _ → - → . (统一为点分隔符，便于配置集成)
  for i := 1 to Length(res) do
    if res[i] in ['_', '-'] then
      res[i] := '.';
  Result := res;
end;

function NormalizeKeyForCheck(const Key: string; CaseInsensitive: Boolean): string;
var
  i: Integer;
  res: string;
begin
  res := Key;
  // 移除前导 - 或 /
  while (Length(res) > 0) and (res[1] in ['-', '/']) do
    Delete(res, 1, 1);
  // 大小写处理 (不转换 '?' 为 'help'，用于 no- 前缀检查)
  if CaseInsensitive then
    res := LowerCase(res);
  // 规范化路径: _ → - → . (统一为点分隔符，便于配置集成)
  for i := 1 to Length(res) do
    if res[i] in ['_', '-'] then
      res[i] := '.';
  Result := res;
end;

function StartsWith(const S, Prefix: string): Boolean; inline;
begin
  if Length(Prefix) > Length(S) then
    Exit(False);
  Result := Copy(S, 1, Length(Prefix)) = Prefix;
end;

function IsNegativeNumberLike(const S: string): Boolean;
var
  i: Integer;
  hasDot: Boolean;
begin
  Result := False;
  if Length(S) < 2 then
    Exit;
  if S[1] <> '-' then
    Exit;
  // 检查第二个字符是否是数字
  if not (S[2] in ['0'..'9']) then
    Exit;
  // 验证剩余部分是有效数字格式
  hasDot := False;
  for i := 3 to Length(S) do
  begin
    case S[i] of
      '0'..'9': ; // 继续
      '.':
        begin
          if hasDot then Exit; // 多个小数点
          hasDot := True;
        end;
      'e', 'E':
        begin
          // 科学记数法 - 简化处理，认为是数字
          if i < Length(S) then
            Exit(True);
        end;
    else
      Exit; // 非数字字符
    end;
  end;
  Result := True;
end;

function IsTrueValue(const S: string): Boolean;
var
  i: Integer;
begin
  for i := Low(TRUE_VALUES) to High(TRUE_VALUES) do
    if SameText(S, TRUE_VALUES[i]) then
      Exit(True);
  Result := False;
end;

function IsFalseValue(const S: string): Boolean;
var
  i: Integer;
begin
  for i := Low(FALSE_VALUES) to High(FALSE_VALUES) do
    if SameText(S, FALSE_VALUES[i]) then
      Exit(True);
  Result := False;
end;

end.
