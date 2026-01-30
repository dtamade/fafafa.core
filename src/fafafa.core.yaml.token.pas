unit fafafa.core.yaml.token;

{$MODE OBJFPC}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fafafa.core.yaml.types;

// 说明：
type
  // 对齐 libfyaml 的 token 类型（最小子集，占位）
  TFyTokenType = (
    FYTT_NONE,
    FYTT_STREAM_START, FYTT_STREAM_END,
    FYTT_DOCUMENT_START, FYTT_DOCUMENT_END,
    FYTT_BLOCK_SEQUENCE_START, FYTT_BLOCK_SEQUENCE_END,
    FYTT_FLOW_SEQUENCE_START, FYTT_FLOW_SEQUENCE_END,
    FYTT_BLOCK_MAPPING_START, FYTT_BLOCK_MAPPING_END,
    FYTT_FLOW_MAPPING_START, FYTT_FLOW_MAPPING_END,
    FYTT_SCALAR,
    FYTT_COUNT
  );

function fy_token_type_is_sequence_start(t: TFyTokenType): Boolean; inline;
function fy_token_type_is_sequence_end(t: TFyTokenType): Boolean; inline;
function fy_token_type_is_sequence_marker(t: TFyTokenType): Boolean; inline;
function fy_token_type_is_mapping_start(t: TFyTokenType): Boolean; inline;
function fy_token_type_is_mapping_end(t: TFyTokenType): Boolean; inline;
function fy_token_type_is_mapping_marker(t: TFyTokenType): Boolean; inline;
function fy_token_type_is_valid(t: TFyTokenType): Boolean; inline;
function fy_token_type_is_yaml(t: TFyTokenType): Boolean; inline;
function fy_token_type_is_content(t: TFyTokenType): Boolean; inline;

// 兼容接口占位（与 libfyaml 名称相近）
function fy_token_get_type_dummy: TFyTokenType; inline;
function fy_token_format_text_length_dummy: Integer; inline;
function fy_token_format_text_length(const tok: TFyToken): Integer; inline;
function fy_token_format_text(const tok: TFyToken; buf: PChar; maxsz: SizeUInt): PChar; inline;
function fy_scalar_token_get_style_dummy: TFyScalarStyle; inline;
// 参考 libfyaml：提供 create/free/ref/unref 的简化实现
function fy_token_create(kind: TFyTokenKind; ptr: PChar; len: SizeUInt): PFyToken; inline;
procedure fy_token_free(p: PFyToken); inline;
function fy_token_ref(p: PFyToken): PFyToken; inline;
procedure fy_token_unref(p: PFyToken); inline;

// 类型文本（便于调试）
function fy_token_type_get_text(t: TFyTokenType): PChar; inline;
function fy_token_kind_get_text(k: TFyTokenKind): PChar; inline;

// 基础操作（与 tokenizer 交互）
procedure fy_token_init(out tok: TFyToken; kind: TFyTokenKind; ptr: PChar; len: SizeUInt); inline;
procedure fy_token_reset(out tok: TFyToken); inline;
procedure fy_token_set_scalar(out tok: TFyToken; ptr: PChar; len: SizeUInt); inline;
function  fy_token_text(const tok: TFyToken; out len: SizeUInt): PChar; inline;

// - 本单元承载 libfyaml fy-token.* 相关的最小实现/占位
// - 使用 TFyToken/TFyTokenKind（见 types），仅提供基础操作

implementation

function fy_token_type_is_sequence_start(t: TFyTokenType): Boolean; inline;
begin
  Result := (t = FYTT_BLOCK_SEQUENCE_START) or (t = FYTT_FLOW_SEQUENCE_START);
end;

function fy_token_type_is_sequence_end(t: TFyTokenType): Boolean; inline;
begin
  Result := (t = FYTT_BLOCK_SEQUENCE_END) or (t = FYTT_FLOW_SEQUENCE_END);
end;

function fy_token_type_is_sequence_marker(t: TFyTokenType): Boolean; inline;
begin
  Result := fy_token_type_is_sequence_start(t) or fy_token_type_is_sequence_end(t);
end;

function fy_token_type_is_mapping_start(t: TFyTokenType): Boolean; inline;
begin
  Result := (t = FYTT_BLOCK_MAPPING_START) or (t = FYTT_FLOW_MAPPING_START);
end;

function fy_token_type_is_mapping_end(t: TFyTokenType): Boolean; inline;
begin
  Result := (t = FYTT_BLOCK_MAPPING_END) or (t = FYTT_FLOW_MAPPING_END);
end;

function fy_token_type_is_mapping_marker(t: TFyTokenType): Boolean; inline;
begin
  Result := fy_token_type_is_mapping_start(t) or fy_token_type_is_mapping_end(t);
end;

function fy_token_type_is_valid(t: TFyTokenType): Boolean; inline;
begin
  Result := (t>=FYTT_NONE) and (t<FYTT_COUNT);
end;

function fy_token_type_is_yaml(t: TFyTokenType): Boolean; inline;
begin
  Result := (t>=FYTT_STREAM_START) and (t<=FYTT_SCALAR);
end;

function fy_token_type_is_content(t: TFyTokenType): Boolean; inline;
begin
  Result := (t>=FYTT_BLOCK_SEQUENCE_START) and (t<=FYTT_SCALAR);
end;

function fy_token_get_type_dummy: TFyTokenType; inline;
begin
  Result := FYTT_NONE;
end;

function fy_token_format_text_length_dummy: Integer; inline;
begin
  Result := 0;
end;

function fy_token_format_text_length(const tok: TFyToken): Integer; inline;
begin
  Result := Integer(tok.len);
end;

function fy_token_format_text(const tok: TFyToken; buf: PChar; maxsz: SizeUInt): PChar; inline;
var n: SizeUInt;
begin
  if (buf=nil) or (maxsz=0) then Exit(nil);
  n := tok.len; if n>0 then begin if n>maxsz-1 then n:=maxsz-1; Move(tok.ptr^, buf^, n); end;
  buf[n] := #0; Result := buf;
end;
function fy_token_create(kind: TFyTokenKind; ptr: PChar; len: SizeUInt): PFyToken; inline;
var p: PFyToken;
begin
  GetMem(p, SizeOf(TFyToken));
  p^.kind := kind; p^.ptr := ptr; p^.len := len; p^.refs := 1;
  Result := p;
end;

procedure fy_token_free(p: PFyToken); inline;
begin
  if p=nil then Exit; Freemem(p);
end;

function fy_token_ref(p: PFyToken): PFyToken; inline;
begin
  if p<>nil then Inc(p^.refs);
  Result := p;
end;

procedure fy_token_unref(p: PFyToken); inline;
begin
  if p=nil then Exit;
  Dec(p^.refs);
  if p^.refs<=0 then fy_token_free(p);
end;

function fy_token_type_get_text(t: TFyTokenType): PChar; inline;
begin
  case t of
    FYTT_NONE: Result:='NONE';
    FYTT_STREAM_START: Result:='STREAM_START';
    FYTT_STREAM_END: Result:='STREAM_END';
    FYTT_DOCUMENT_START: Result:='DOCUMENT_START';
    FYTT_DOCUMENT_END: Result:='DOCUMENT_END';
    FYTT_BLOCK_SEQUENCE_START: Result:='BLOCK_SEQUENCE_START';
    FYTT_BLOCK_SEQUENCE_END: Result:='BLOCK_SEQUENCE_END';
    FYTT_FLOW_SEQUENCE_START: Result:='FLOW_SEQUENCE_START';
    FYTT_FLOW_SEQUENCE_END: Result:='FLOW_SEQUENCE_END';
    FYTT_BLOCK_MAPPING_START: Result:='BLOCK_MAPPING_START';
    FYTT_BLOCK_MAPPING_END: Result:='BLOCK_MAPPING_END';
    FYTT_FLOW_MAPPING_START: Result:='FLOW_MAPPING_START';
    FYTT_FLOW_MAPPING_END: Result:='FLOW_MAPPING_END';
    FYTT_SCALAR: Result:='SCALAR';
    else Result:='?';
  end;
end;

function fy_token_kind_get_text(k: TFyTokenKind): PChar; inline;
begin
  case k of
    FYTK_UNKNOWN: Result:='UNKNOWN';
    FYTK_SCALAR: Result:='SCALAR';
    FYTK_LBRACKET: Result:='[';
    FYTK_RBRACKET: Result:=']';
    FYTK_LBRACE: Result:='{';
    FYTK_RBRACE: Result:='}';
    FYTK_COLON: Result:=':';
    FYTK_COMMA: Result:=',';
    FYTK_SEMICOLON: Result:=';';
    else Result:='?';
  end;
end;


function fy_scalar_token_get_style_dummy: TFyScalarStyle; inline;
begin
  Result := FYSS_PLAIN;
end;

procedure fy_token_init(out tok: TFyToken; kind: TFyTokenKind; ptr: PChar; len: SizeUInt); inline;
procedure fy_token_reset(out tok: TFyToken); inline;
procedure fy_token_set_scalar(out tok: TFyToken; ptr: PChar; len: SizeUInt); inline;
function  fy_token_text(const tok: TFyToken; out len: SizeUInt): PChar; inline;

implementation

procedure fy_token_init(out tok: TFyToken; kind: TFyTokenKind; ptr: PChar; len: SizeUInt);
begin
  tok.kind := kind; tok.ptr := ptr; tok.len := len;
end;

procedure fy_token_reset(out tok: TFyToken);
begin
  tok.kind := FYTK_UNKNOWN; tok.ptr := nil; tok.len := 0;
end;

procedure fy_token_set_scalar(out tok: TFyToken; ptr: PChar; len: SizeUInt);
begin
  tok.kind := FYTK_SCALAR; tok.ptr := ptr; tok.len := len;
end;

function fy_token_text(const tok: TFyToken; out len: SizeUInt): PChar;
begin
  len := tok.len; Result := tok.ptr;
end;

end.

