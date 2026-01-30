unit fafafa.core.yaml.atom;

{$MODE OBJFPC}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fafafa.core.yaml.types;

// 说明：
// - 本单元为 libfyaml fy-atom.* 的移植承载，采用最小可用实现，后续再补齐行为细节
// - 对外不导出 fy_* 名称，仅供内部实现使用（yaml_impl_* 等）

Type
  PFyAtom = ^TFyAtom;
  TFyAtom = record
    ptr: PChar;
    len: SizeUInt;
    // 可选的样式/标志位，后续按需扩展
    // style: TFyScalarStyle;
    class function From(p: PChar; aLen: SizeUInt): TFyAtom; static; inline;
    function IsEmpty: Boolean; inline;
  end;

// 基础操作
procedure fy_atom_init(out a: TFyAtom; ptr: PChar; len: SizeUInt); inline;
procedure fy_atom_reset(out a: TFyAtom); inline;
function  fy_atom_equals(const a, b: TFyAtom): Boolean; inline;
function  fy_atom_cmp(const a, b: TFyAtom): Integer; inline;

implementation

class function TFyAtom.From(p: PChar; aLen: SizeUInt): TFyAtom;
begin
  Result.ptr := p;
  Result.len := aLen;
end;

function TFyAtom.IsEmpty: Boolean;
begin
  Result := (ptr=nil) or (len=0);
end;

procedure fy_atom_init(out a: TFyAtom; ptr: PChar; len: SizeUInt);
begin
  a.ptr := ptr; a.len := len;
end;

procedure fy_atom_reset(out a: TFyAtom);
begin
  a.ptr := nil; a.len := 0;
end;

function fy_atom_equals(const a, b: TFyAtom): Boolean;
begin
  if a.len<>b.len then Exit(False);
  if (a.len=0) then Exit(True);
  if (a.ptr=nil) or (b.ptr=nil) then Exit(False);
  Result := CompareByte(a.ptr^, b.ptr^, a.len)=0;
end;

function fy_atom_cmp(const a, b: TFyAtom): Integer;
var la, lb: SizeUInt; n: SizeUInt; c: Integer;
begin
  la := a.len; lb := b.len;
  n := la; if lb<n then n := lb;
  if n>0 then begin
    if (a.ptr=nil) or (b.ptr=nil) then begin
      if a.ptr=b.ptr then c := 0 else if a.ptr=nil then c := -1 else c := 1;
    end else
      c := CompareByte(a.ptr^, b.ptr^, n);
    if c<>0 then Exit(c);
  end;
  if la=lb then Exit(0) else if la<lb then Exit(-1) else Exit(1);
end;

end.

