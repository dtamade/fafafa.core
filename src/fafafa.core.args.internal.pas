unit fafafa.core.args.internal;
{**
 * fafafa.core.args.internal - DEPRECATED
 *
 * 此单元已重命名为 fafafa.core.args.utils
 * 请更新您的代码使用新单元名
 *
 * ✅ P3-2: 重命名为 utils，此文件仅作为兼容存根
 *}

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

// Re-export all from utils for backward compatibility
uses
  fafafa.core.args.utils;

type
  TStringArray = fafafa.core.args.utils.TStringArray;

const
  HELP_ALIAS_CHAR = fafafa.core.args.utils.HELP_ALIAS_CHAR;
  HELP_CANONICAL  = fafafa.core.args.utils.HELP_CANONICAL;
  TRUE_VALUES: array[0..2] of string = ('true', '1', 'yes');
  FALSE_VALUES: array[0..2] of string = ('false', '0', 'no');

procedure AddString(var Arr: TStringArray; const S: string); inline; deprecated 'Use fafafa.core.args.utils instead';
function NormalizeKey(const Key: string; CaseInsensitive: Boolean): string; deprecated 'Use fafafa.core.args.utils instead';
function NormalizeKeyForCheck(const Key: string; CaseInsensitive: Boolean): string; deprecated 'Use fafafa.core.args.utils instead';
function StartsWith(const S, Prefix: string): Boolean; inline; deprecated 'Use fafafa.core.args.utils instead';
function IsNegativeNumberLike(const S: string): Boolean; deprecated 'Use fafafa.core.args.utils instead';
function IsTrueValue(const S: string): Boolean; deprecated 'Use fafafa.core.args.utils instead';
function IsFalseValue(const S: string): Boolean; deprecated 'Use fafafa.core.args.utils instead';

implementation

procedure AddString(var Arr: TStringArray; const S: string); inline;
begin
  fafafa.core.args.utils.AddString(Arr, S);
end;

function NormalizeKey(const Key: string; CaseInsensitive: Boolean): string;
begin
  Result := fafafa.core.args.utils.NormalizeKey(Key, CaseInsensitive);
end;

function NormalizeKeyForCheck(const Key: string; CaseInsensitive: Boolean): string;
begin
  Result := fafafa.core.args.utils.NormalizeKeyForCheck(Key, CaseInsensitive);
end;

function StartsWith(const S, Prefix: string): Boolean; inline;
begin
  Result := fafafa.core.args.utils.StartsWith(S, Prefix);
end;

function IsNegativeNumberLike(const S: string): Boolean;
begin
  Result := fafafa.core.args.utils.IsNegativeNumberLike(S);
end;

function IsTrueValue(const S: string): Boolean;
begin
  Result := fafafa.core.args.utils.IsTrueValue(S);
end;

function IsFalseValue(const S: string): Boolean;
begin
  Result := fafafa.core.args.utils.IsFalseValue(S);
end;

end.
