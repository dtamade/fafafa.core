unit fafafa.core.json.ptr;
{*
  This unit implements JSON Pointer (RFC 6901) semantics aligned with yyjson.
  Portions of the algorithmic behavior are adapted from yyjson (MIT License):
    - Project: https://github.com/ibireme/yyjson
    - Copyright (c) 2020-2025, Tencent.
  This Pascal implementation is original work; behavior is made compatible.
*}


{$MODE OBJFPC}{$H+}

interface

uses
  SysUtils,
  fafafa.core.json.core;

type
  TJsonPointerFlag = (jpfStrict);
  TJsonPointerFlags = set of TJsonPointerFlag;

// RFC 6901 minimal JSON Pointer
//  - Supports "" (root), and tokens separated by '/'
//  - Unescape: ~0 -> ~, ~1 -> /
//  - Works on immutable (PJsonValue) and mutable (PJsonMutValue)

function JsonPtrGet(ARoot: PJsonValue; const APointer: PChar): PJsonValue; overload;
function JsonPtrGet(ARoot: PJsonValue; const APointer: PChar; AFlags: TJsonPointerFlags): PJsonValue; overload;
function JsonMutPtrGet(ARoot: PJsonMutValue; const APointer: PChar): PJsonMutValue; overload;
function JsonMutPtrGet(ARoot: PJsonMutValue; const APointer: PChar; AFlags: TJsonPointerFlags): PJsonMutValue; overload;

implementation

function UnescapeToken(const S: PChar; Len: SizeUInt): String;
var i: SizeUInt;
begin
  Result := '';
  i := 0;
  while i < Len do
  begin
    if (S[i] = '~') and (i + 1 < Len) then
    begin
      if S[i+1] = '0' then begin Result += '~'; Inc(i, 2); Continue; end;
      if S[i+1] = '1' then begin Result += '/'; Inc(i, 2); Continue; end;
    end;
    Result += S[i];
    Inc(i);
  end;
end;

function NextTokenCompat(const P: PChar; PLen: SizeUInt; var Ofs: SizeUInt; out Tok: PChar; out TokLen: SizeUInt): Boolean;
begin
  // expects P^ at a '/' or at start when Ofs=0
  if (Ofs = 0) then
  begin
    // if empty pointer => root
    if PLen = 0 then begin Tok := nil; TokLen := 0; Result := False; Exit; end;
    // first char must be '/'
    if P[0] <> '/' then begin Tok := nil; TokLen := 0; Result := False; Exit; end;
    Ofs := 1;
  end;
  if Ofs >= PLen then begin Tok := nil; TokLen := 0; Result := False; Exit; end;
  // find next '/'
  Tok := @P[Ofs];
  while (Ofs < PLen) and (P[Ofs] <> '/') do Inc(Ofs);
  TokLen := @P[Ofs] - Tok;
  // skip '/'
  if (Ofs < PLen) and (P[Ofs] = '/') then Inc(Ofs);
  Result := True;
end;

function NextTokenStrict(const P: PChar; PLen: SizeUInt; var Ofs: SizeUInt; out Tok: PChar; out TokLen: SizeUInt): Boolean;
begin
  // Strict: allow empty tokens (e.g., trailing slash) exactly once at the end
  if (Ofs = 0) then
  begin
    if PLen = 0 then begin Tok := nil; TokLen := 0; Result := False; Exit; end;
    if P[0] <> '/' then begin Tok := nil; TokLen := 0; Result := False; Exit; end;
    Ofs := 1;
    if Ofs >= PLen then
    begin
      // pointer is exactly "/" -> one empty token
      Tok := @P[PLen]; TokLen := 0; Ofs := PLen + 1; Result := True; Exit;
    end;
  end;
  if Ofs > PLen then begin Tok := nil; TokLen := 0; Result := False; Exit; end;
  if Ofs = PLen then
  begin
    // trailing slash produced an empty token
    Tok := @P[PLen]; TokLen := 0; Ofs := PLen + 1; Result := True; Exit;
  end;
  // find next '/'
  Tok := @P[Ofs];
  while (Ofs < PLen) and (P[Ofs] <> '/') do Inc(Ofs);
  TokLen := @P[Ofs] - Tok;
  // skip '/'
  if (Ofs < PLen) and (P[Ofs] = '/') then Inc(Ofs);
  Result := True;
end;

function StrToIndex(const S: String; out Idx: SizeUInt): Boolean;
var v: QWord; j: SizeInt;
begin
  Result := False; Idx := 0; if S = '' then Exit;
  v := 0;
  for j := 1 to Length(S) do
  begin
    if (S[j] < '0') or (S[j] > '9') then Exit;
    v := v * 10 + Ord(S[j]) - Ord('0');
    {$IFNDEF CPU64}
    if v > High(SizeUInt) then Exit; // only meaningful on 32-bit targets
    {$ENDIF}
  end;
  Idx := SizeUInt(v);
  Result := True;
end;

function JsonPtrGet(ARoot: PJsonValue; const APointer: PChar): PJsonValue; overload;
begin
  Result := JsonPtrGet(ARoot, APointer, []);
end;

function JsonPtrGet(ARoot: PJsonValue; const APointer: PChar; AFlags: TJsonPointerFlags): PJsonValue; overload;
var p: PChar; plen: SizeUInt; ofs: SizeUInt; tok: PChar; tokLen: SizeUInt; key: String; idx: SizeUInt; nextOk: Boolean;
begin
  Result := ARoot;
  if not Assigned(Result) then Exit(nil);
  if (not Assigned(APointer)) or (APointer^ = #0) then Exit(Result); // empty => root
  p := APointer; plen := StrLen(APointer); ofs := 0;
  if (not (jpfStrict in AFlags)) and (plen = 1) and (p[0] = '/') then Exit(nil); // compat: '/' invalid
  repeat
    if (jpfStrict in AFlags) then nextOk := NextTokenStrict(p, plen, ofs, tok, tokLen)
    else nextOk := NextTokenCompat(p, plen, ofs, tok, tokLen);
    if not nextOk then Break;
    // compat: treat empty token as invalid (e.g., '/a//x')
    if (tokLen = 0) and (not (jpfStrict in AFlags)) then Exit(nil);
    key := UnescapeToken(tok, tokLen);
    if UnsafeIsObj(Result) then
    begin
      Result := JsonObjGetN(Result, PChar(key), Length(key));
    end
    else if UnsafeIsArr(Result) and StrToIndex(key, idx) then
    begin
      Result := JsonArrGet(Result, idx);
    end
    else
      Exit(nil);
    if not Assigned(Result) then Exit(nil);
  until False;
end;

function FindMutObjKey(AObj: PJsonMutValue; const Key: String): PJsonMutValue;
var it: TJsonMutObjectIterator; cur: PJsonMutValue;
begin
  Result := nil;
  if not JsonMutObjIterInit(AObj, @it) then Exit;
  while JsonMutObjIterHasNext(@it) do
  begin
    cur := JsonMutObjIterNext(@it);
    if UnsafeEqualsStrN(PJsonValue(cur), PChar(Key), Length(Key)) then
    begin
      Result := cur; Exit;
    end;
  end;
end;

function FindMutArrIndex(AArr: PJsonMutValue; AIdx: SizeUInt): PJsonMutValue;
var len: SizeUInt; last, cur: PJsonMutValue; i: SizeUInt;
begin
  Result := nil;
  if not Assigned(AArr) or (UnsafeGetType(PJsonValue(AArr)) <> YYJSON_TYPE_ARR) then Exit;
  len := UnsafeGetLen(PJsonValue(AArr));
  if AIdx >= len then Exit;
  last := PJsonMutValue(AArr^.Data.Ptr);
  if not Assigned(last) then Exit;
  cur := last^.Next; // head (first element)
  // Move forward AIdx steps from head; when AIdx = 0, do nothing.
  for i := 1 to AIdx do
    cur := cur^.Next;
  Result := cur;
end;

function JsonMutPtrGet(ARoot: PJsonMutValue; const APointer: PChar): PJsonMutValue; overload;
begin
  Result := JsonMutPtrGet(ARoot, APointer, []);
end;

function JsonMutPtrGet(ARoot: PJsonMutValue; const APointer: PChar; AFlags: TJsonPointerFlags): PJsonMutValue; overload;
var p: PChar; plen, ofs, tokLen: SizeUInt; tok: PChar; key: String; idx: SizeUInt; cur: PJsonMutValue; nextOk: Boolean;
begin
  Result := ARoot;
  if not Assigned(Result) then Exit(nil);
  if (not Assigned(APointer)) or (APointer^ = #0) then Exit(Result);
  p := APointer; plen := StrLen(APointer); ofs := 0;
  if (not (jpfStrict in AFlags)) and (plen = 1) and (p[0] = '/') then Exit(nil);
  cur := Result;
  repeat
    if (jpfStrict in AFlags) then nextOk := NextTokenStrict(p, plen, ofs, tok, tokLen)
    else nextOk := NextTokenCompat(p, plen, ofs, tok, tokLen);
    if not nextOk then Break;
    if (tokLen = 0) and (not (jpfStrict in AFlags)) then Exit(nil);
    key := UnescapeToken(tok, tokLen);
    if (UnsafeGetType(PJsonValue(cur)) = YYJSON_TYPE_OBJ) then
    begin
      cur := FindMutObjKey(cur, key);
      if Assigned(cur) then cur := cur^.Next;
    end
    else if (UnsafeGetType(PJsonValue(cur)) = YYJSON_TYPE_ARR) and StrToIndex(key, idx) then
    begin
      cur := FindMutArrIndex(cur, idx);
    end
    else
      Exit(nil);
    if not Assigned(cur) then Exit(nil);
  until False;
  Result := cur;
end;

end.

