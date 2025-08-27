unit fafafa.core.color.resultadapter;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.result,
  fafafa.core.color;

type
  // 统一的字符串错误类型
  color_error_t = type string;

// 通用泛型版本：通过 mapErr 将字符串映射为任意错误类型 TErr
generic function color_parse_hex_result<TErr>(const s: string; const mapErr: specialize TResultFunc<string, TErr>): specialize TResult<color_rgba_t, TErr>;
generic function color_parse_hex_rgba_result<TErr>(const s: string; const mapErr: specialize TResultFunc<string, TErr>): specialize TResult<color_rgba_t, TErr>;

// 便捷版本：错误为字符串
type TResultColor = specialize TResult<color_rgba_t, color_error_t>;
function color_parse_hex_result_s(const s: string): TResultColor;
function color_parse_hex_rgba_result_s(const s: string): TResultColor;

implementation

generic function color_parse_hex_result<TErr>(const s: string; const mapErr: specialize TResultFunc<string, TErr>): specialize TResult<color_rgba_t, TErr>;
var c: color_rgba_t;
begin
  if color_try_from_hex(s, c) then Exit(specialize TResult<color_rgba_t, TErr>.Ok(c))
  else Exit(specialize TResult<color_rgba_t, TErr>.Err(mapErr('invalid hex color: '+s)));
end;

generic function color_parse_hex_rgba_result<TErr>(const s: string; const mapErr: specialize TResultFunc<string, TErr>): specialize TResult<color_rgba_t, TErr>;
var c: color_rgba_t;
begin
  if color_try_from_hex_rgba(s, c) then Exit(specialize TResult<color_rgba_t, TErr>.Ok(c))
  else Exit(specialize TResult<color_rgba_t, TErr>.Err(mapErr('invalid hex rgba color: '+s)));
end;

function color_parse_hex_result_s(const s: string): TResultColor;
begin
  Result := specialize color_parse_hex_result<color_error_t>(s, function (const msg: string): color_error_t begin Result := msg; end);
end;

function color_parse_hex_rgba_result_s(const s: string): TResultColor;
begin
  Result := specialize color_parse_hex_rgba_result<color_error_t>(s, function (const msg: string): color_error_t begin Result := msg; end);
end;

end.

