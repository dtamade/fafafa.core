unit fafafa.core.yaml.diag;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  fafafa.core.yaml.types;

// 仅内部实现暴露 TFy*，门面对外统一 yaml_*

// 诊断项
Type
  PFyDiagItem = ^TFyDiagItem;
  TFyDiagItem = record
    etype: TFyErrorType;
    module: TFyErrorModule;
    code: Integer;         // 预留错误代码空间（对齐 TFyDiagCode）
    msg: PChar;            // 指向内部持有的以 NUL 结尾的字符串
    start_mark: TFyMark;   // 可为 (0,0)
    end_mark: TFyMark;     // 可为 (0,0)
  end;

  TFyDiagArray = array of TFyDiagItem;
  TFyDiagSimpleCB = procedure(userdata: Pointer; level: TFyErrorType; module: TFyErrorModule; line, col: SizeUInt; const msg: PChar); cdecl;
  TFyDiagCodeCB   = procedure(userdata: Pointer; code: TFyDiagCode; level: TFyErrorType; module: TFyErrorModule; line, col: SizeUInt; const msg: PChar); cdecl;
  // 扩展：带 end 位置信息的回调（用于测试输出范围）
  TFyDiagCodeCBEx = procedure(userdata: Pointer; code: TFyDiagCode; level: TFyErrorType; module: TFyErrorModule; line, col, line2, col2: SizeUInt; const msg: PChar); cdecl;


  // 诊断收集器

// 内部实现 API（供门面转发）
function yaml_impl_diag_create_with_simple(cb: TFyDiagSimpleCB; userdata: Pointer): PFyDiag;
function yaml_impl_diag_create_with_code(cb: TFyDiagCodeCB; userdata: Pointer): PFyDiag;
function yaml_impl_diag_create_with_code_ex(cb: TFyDiagCodeCBEx; userdata: Pointer): PFyDiag;

function yaml_impl_diag_create(userdata: Pointer = nil): PFyDiag;
procedure yaml_impl_diag_destroy(p: PFyDiag);
procedure yaml_impl_diag_clear(p: PFyDiag);
procedure yaml_impl_diag_push(p: PFyDiag; etype: TFyErrorType; module: TFyErrorModule;
  code: Integer; const msg: PChar; const start_mark, end_mark: TFyMark);
function yaml_impl_diag_count(p: PFyDiag): SizeInt; inline;
function yaml_impl_diag_item(p: PFyDiag; idx: SizeInt): PFyDiagItem; inline;

implementation

type
  PDiagImpl = ^TDiagImpl;
  TDiagImpl = record
    items: TFyDiagArray;
    capacity: SizeInt;
    count: SizeInt;
    userdata: Pointer;
    // 可选回调（简单/带 code）
    cb_simple: procedure(userdata: Pointer; level: TFyErrorType; module: TFyErrorModule; line, col: SizeUInt; const msg: PChar); cdecl;
    cb_code: procedure(userdata: Pointer; code: TFyDiagCode; level: TFyErrorType; module: TFyErrorModule; line, col: SizeUInt; const msg: PChar); cdecl;
    cb_code_ex: procedure(userdata: Pointer; code: TFyDiagCode; level: TFyErrorType; module: TFyErrorModule; line, col, line2, col2: SizeUInt; const msg: PChar); cdecl;
  end;

// 内部实现 API（供门面转发）

function yaml_impl_diag_create(userdata: Pointer): PFyDiag;
var p: PDiagImpl;
begin
  GetMem(p, SizeOf(TDiagImpl));
  FillChar(p^, SizeOf(TDiagImpl), 0);
  p^.capacity := 8;
  SetLength(p^.items, p^.capacity);
  p^.count := 0;
  p^.userdata := userdata;
  Result := PFyDiag(p);
end;

function yaml_impl_diag_create_with_simple(cb: TFyDiagSimpleCB; userdata: Pointer): PFyDiag;
var p: PDiagImpl;
begin
  p := PDiagImpl(yaml_impl_diag_create(userdata));
  if p<>nil then p^.cb_simple := cb;
  Result := PFyDiag(p);
end;

function yaml_impl_diag_create_with_code(cb: TFyDiagCodeCB; userdata: Pointer): PFyDiag;
var p: PDiagImpl;
begin
  p := PDiagImpl(yaml_impl_diag_create(userdata));
  if p<>nil then p^.cb_code := cb;
  Result := PFyDiag(p);
end;

function yaml_impl_diag_create_with_code_ex(cb: TFyDiagCodeCBEx; userdata: Pointer): PFyDiag;
var p: PDiagImpl;
begin
  p := PDiagImpl(yaml_impl_diag_create(userdata));
  if p<>nil then p^.cb_code_ex := cb;
  Result := PFyDiag(p);
end;


procedure yaml_impl_diag_clear(p: PFyDiag);
var i: SizeInt; impl: PDiagImpl;
begin
  if p=nil then Exit;
  impl := PDiagImpl(p);
  for i:=0 to impl^.count-1 do begin
    if impl^.items[i].msg<>nil then begin
      FreeMem(impl^.items[i].msg);
      impl^.items[i].msg := nil;
    end;
  end;
  impl^.count := 0;
end;

procedure yaml_impl_diag_destroy(p: PFyDiag);
var impl: PDiagImpl;
begin
  if p=nil then Exit;
  impl := PDiagImpl(p);
  yaml_impl_diag_clear(p);
  SetLength(impl^.items, 0);
  FreeMem(impl);
end;

procedure yaml_impl_diag_push(p: PFyDiag; etype: TFyErrorType; module: TFyErrorModule;
  code: Integer; const msg: PChar; const start_mark, end_mark: TFyMark);
var n: SizeInt; L: SizeUInt; buf: PChar; impl: PDiagImpl;
begin
  if p=nil then Exit;
  impl := PDiagImpl(p);
  if impl^.count >= impl^.capacity then begin
    impl^.capacity := impl^.capacity * 2;
    if impl^.capacity < 8 then impl^.capacity := 8;
    SetLength(impl^.items, impl^.capacity);
  end;
  n := impl^.count;
  impl^.items[n].etype := etype;
  impl^.items[n].module := module;
  impl^.items[n].code := code;
  if msg<>nil then begin
    L := StrLen(msg);
    GetMem(buf, L+1);
    Move(msg^, buf^, L+1);
    impl^.items[n].msg := buf;
  end else begin
    impl^.items[n].msg := nil;
  end;
  impl^.items[n].start_mark := start_mark;
  impl^.items[n].end_mark := end_mark;
  Inc(impl^.count);
  // 回调（尽量容错：行/列未知时传 0；优先调用扩展回调，否则回退）
  if Assigned(impl^.cb_code_ex) then
    impl^.cb_code_ex(impl^.userdata, TFyDiagCode(code), etype, module,
      SizeUInt(impl^.items[n].start_mark.line + 1), SizeUInt(impl^.items[n].start_mark.column + 1),
      SizeUInt(impl^.items[n].end_mark.line + 1), SizeUInt(impl^.items[n].end_mark.column + 1), impl^.items[n].msg)
  else if Assigned(impl^.cb_code) then
    impl^.cb_code(impl^.userdata, TFyDiagCode(code), etype, module,
      SizeUInt(impl^.items[n].start_mark.line + 1), SizeUInt(impl^.items[n].start_mark.column + 1), impl^.items[n].msg)
  else if Assigned(impl^.cb_simple) then
    impl^.cb_simple(impl^.userdata, etype, module,
      SizeUInt(impl^.items[n].start_mark.line + 1), SizeUInt(impl^.items[n].start_mark.column + 1), impl^.items[n].msg);
end;

function yaml_impl_diag_count(p: PFyDiag): SizeInt; inline;
var impl: PDiagImpl;
begin
  if p=nil then Exit(0);
  impl := PDiagImpl(p);
  Result := impl^.count;
end;

function yaml_impl_diag_item(p: PFyDiag; idx: SizeInt): PFyDiagItem; inline;
var impl: PDiagImpl;
begin
  if p=nil then Exit(nil);
  impl := PDiagImpl(p);
  if (idx<0) or (idx>=impl^.count) then Exit(nil);
  Result := @impl^.items[idx];
end;

end.

