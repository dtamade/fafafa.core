unit fafafa.core.json.patch;
{*
  This unit implements JSON Merge Patch (RFC 7386) and JSON Patch (RFC 6902)
  semantics aligned with yyjson. Portions of behavior are adapted from yyjson
  (MIT License):
    - Project: https://github.com/ibireme/yyjson
    - Copyright (c) 2020-2025, Tencent.
  This Pascal implementation is original work; behavior is made compatible.
*}


{$MODE OBJFPC}{$H+}

interface

uses
  SysUtils,
  fafafa.core.json.core,
  fafafa.core.json.ptr;

// RFC 7386: JSON Merge Patch (minimal)
// Returns the resulting mutable value; caller should set it back (e.g., as doc root)
function JsonMergePatch(ADoc: TJsonMutDocument; ATarget: PJsonMutValue; APatch: PJsonValue): PJsonMutValue;

// RFC 6902: JSON Patch (minimal: add/remove/replace). Returns success and ErrMsg
function JsonPatchApply(ADoc: TJsonMutDocument; ARoot: PJsonMutValue; APatchArr: PJsonValue; out ErrMsg: String): Boolean;

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

function CloneToMut(ADoc: TJsonMutDocument; AVal: PJsonValue): PJsonMutValue;
var t: UInt8; it: TJsonArrayIterator; o: TJsonObjectIterator; k, v: PJsonValue; arr, obj, child: PJsonMutValue; s: String;
begin
  if not Assigned(AVal) then Exit(nil);
  t := UnsafeGetType(AVal);
  case t of
    YYJSON_TYPE_NULL:   Exit(JsonMutNull(ADoc));
    YYJSON_TYPE_BOOL:   Exit(JsonMutBool(ADoc, UnsafeIsTrue(AVal)));
    YYJSON_TYPE_NUM:    begin
      if JsonIsReal(AVal) then
        Exit(JsonMutReal(ADoc, JsonGetReal(AVal)));
      if JsonIsSint(AVal) then
        Exit(JsonMutSint(ADoc, JsonGetSint(AVal)));
      // default to uint
      Exit(JsonMutUint(ADoc, JsonGetUint(AVal)));
    end;
    YYJSON_TYPE_STR:    begin s := Copy(AVal^.Data.Str, 1, UnsafeGetLen(AVal)); Exit(JsonMutStr(ADoc, s)); end;
    YYJSON_TYPE_ARR:    begin
      arr := JsonMutArr(ADoc);
      if JsonArrIterInit(AVal, @it) then
        while JsonArrIterHasNext(@it) do
        begin
          v := JsonArrIterNext(@it);
          child := CloneToMut(ADoc, v);
          if not JsonMutArrAppend(arr, child) then Exit(nil);
        end;
      Exit(arr);
    end;
    YYJSON_TYPE_OBJ:    begin
      obj := JsonMutObj(ADoc);
      if JsonObjIterInit(AVal, @o) then
        while JsonObjIterHasNext(@o) do
        begin
          k := JsonObjIterNext(@o);
          v := JsonObjIterGetVal(k);
          s := Copy(k^.Data.Str, 1, UnsafeGetLen(k));
          child := CloneToMut(ADoc, v);
          if not JsonMutObjAddVal(ADoc, obj, s, child) then Exit(nil);
        end;
      Exit(obj);
    end;
  else
    Exit(nil);
  end;
end;

function FindMutObjKey(AObj: PJsonMutValue; const Key: String): PJsonMutValue; forward;

function CloneFromMut(ADoc: TJsonMutDocument; AMut: PJsonMutValue): PJsonMutValue; forward;
function DeepEqualImmMut(AImm: PJsonValue; AMut: PJsonMutValue): Boolean; forward;

function CloneFromMut(ADoc: TJsonMutDocument; AMut: PJsonMutValue): PJsonMutValue;
var t: UInt8; itA: TJsonMutArrayIterator; itO: TJsonMutObjectIterator; k, v: PJsonMutValue; arr, obj, child: PJsonMutValue; s: String;
begin
  if not Assigned(AMut) then Exit(nil);
  t := UnsafeGetType(PJsonValue(AMut));
  case t of
    YYJSON_TYPE_NULL:   Exit(JsonMutNull(ADoc));
    YYJSON_TYPE_BOOL:   Exit(JsonMutBool(ADoc, UnsafeIsTrue(PJsonValue(AMut))));
    YYJSON_TYPE_NUM:    begin
      if JsonIsReal(PJsonValue(AMut)) then
        Exit(JsonMutReal(ADoc, JsonGetReal(PJsonValue(AMut))));
      if JsonIsSint(PJsonValue(AMut)) then
        Exit(JsonMutSint(ADoc, JsonGetSint(PJsonValue(AMut))));
      Exit(JsonMutUint(ADoc, JsonGetUint(PJsonValue(AMut))));
    end;
    YYJSON_TYPE_STR:    begin s := Copy(AMut^.Data.Str, 1, UnsafeGetLen(PJsonValue(AMut))); Exit(JsonMutStr(ADoc, s)); end;
    YYJSON_TYPE_ARR:    begin
      arr := JsonMutArr(ADoc);
      if JsonMutArrIterInit(AMut, @itA) then
        while JsonMutArrIterHasNext(@itA) do
        begin
          v := JsonMutArrIterNext(@itA);
          child := CloneFromMut(ADoc, v);
          if not JsonMutArrAppend(arr, child) then Exit(nil);
        end;
      Exit(arr);
    end;
    YYJSON_TYPE_OBJ:    begin
      obj := JsonMutObj(ADoc);
      if JsonMutObjIterInit(AMut, @itO) then
        while JsonMutObjIterHasNext(@itO) do
        begin
          k := JsonMutObjIterNext(@itO);
          v := k^.Next;
          s := Copy(k^.Data.Str, 1, UnsafeGetLen(PJsonValue(k)));
          child := CloneFromMut(ADoc, v);
          if not JsonMutObjAddVal(ADoc, obj, s, child) then Exit(nil);
        end;
      Exit(obj);
    end;
  else
    Exit(nil);
  end;
end;

function DeepEqualImmMut(AImm: PJsonValue; AMut: PJsonMutValue): Boolean;
var tI, tM: UInt8; itI: TJsonArrayIterator; itM: TJsonMutArrayIterator; itO: TJsonObjectIterator; vi: PJsonValue; vm: PJsonMutValue;
    lenI, lenM: SizeUInt; keyI: PJsonValue; valI: PJsonValue; mk: PJsonMutValue; s: String;
begin
  if (not Assigned(AImm)) and (not Assigned(AMut)) then Exit(True);
  if (not Assigned(AImm)) or (not Assigned(AMut)) then Exit(False);
  tI := UnsafeGetType(AImm);
  tM := UnsafeGetType(PJsonValue(AMut));
  if tI <> tM then Exit(False);
  case tI of
    YYJSON_TYPE_NULL:   Exit(True);
    YYJSON_TYPE_BOOL:   Exit(UnsafeIsTrue(AImm) = UnsafeIsTrue(PJsonValue(AMut)));
    YYJSON_TYPE_NUM:    begin
      if JsonIsReal(AImm) or JsonIsReal(PJsonValue(AMut)) then
        Exit(JsonGetNum(AImm) = JsonGetNum(PJsonValue(AMut)));
      // integer compare (handles uint/sint)
      if JsonIsSint(AImm) and JsonIsSint(PJsonValue(AMut)) then
        Exit(JsonGetSint(AImm) = JsonGetSint(PJsonValue(AMut)));
      if (JsonIsSint(AImm) and (JsonGetSint(AImm) >= 0)) and (not JsonIsSint(PJsonValue(AMut))) then
        Exit(UInt64(JsonGetSint(AImm)) = JsonGetUint(PJsonValue(AMut)));
      if (JsonIsSint(PJsonValue(AMut)) and (JsonGetSint(PJsonValue(AMut)) >= 0)) and (not JsonIsSint(AImm)) then
        Exit(UInt64(JsonGetSint(PJsonValue(AMut))) = JsonGetUint(AImm));
      Exit(JsonGetUint(AImm) = JsonGetUint(PJsonValue(AMut)));
    end;
    YYJSON_TYPE_STR:    Exit((UnsafeGetLen(AImm) = UnsafeGetLen(PJsonValue(AMut))) and CompareMem(AImm^.Data.Str, AMut^.Data.Str, UnsafeGetLen(AImm)));
    YYJSON_TYPE_ARR:    begin
      lenI := UnsafeGetLen(AImm); lenM := UnsafeGetLen(PJsonValue(AMut));
      if lenI <> lenM then Exit(False);
      if not JsonArrIterInit(AImm, @itI) then Exit(lenM = 0);
      if not JsonMutArrIterInit(AMut, @itM) then Exit(lenI = 0);
      while JsonArrIterHasNext(@itI) and JsonMutArrIterHasNext(@itM) do
      begin
        vi := JsonArrIterNext(@itI);
        vm := JsonMutArrIterNext(@itM);
        if not DeepEqualImmMut(vi, vm) then Exit(False);
      end;
      Exit(True);
    end;
    YYJSON_TYPE_OBJ:    begin
      lenI := UnsafeGetLen(AImm); lenM := UnsafeGetLen(PJsonValue(AMut));
      if lenI <> lenM then Exit(False);
      // for each key in imm, find mut by key and compare
      if not JsonObjIterInit(AImm, @itO) then Exit(lenM = 0);
      while JsonObjIterHasNext(@itO) do
      begin
        keyI := JsonObjIterNext(@itO);
        valI := JsonObjIterGetVal(keyI);
        s := Copy(keyI^.Data.Str, 1, UnsafeGetLen(keyI));
        mk := FindMutObjKey(AMut, s);
        if not Assigned(mk) then Exit(False);
        if not DeepEqualImmMut(valI, mk^.Next) then Exit(False);
      end;
      Exit(True);
    end;
  else
    Exit(False);
  end;
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

function JsonMergePatch(ADoc: TJsonMutDocument; ATarget: PJsonMutValue; APatch: PJsonValue): PJsonMutValue;
var pt: UInt8; it: TJsonObjectIterator; pk, pv: PJsonValue; key: String; child, existing: PJsonMutValue;
begin
  if not Assigned(APatch) then Exit(ATarget);
  pt := UnsafeGetType(APatch);
  if pt <> YYJSON_TYPE_OBJ then
  begin
    // Replace whole target with patch clone
    Exit(CloneToMut(ADoc, APatch));
  end;

  // If target is not object, convert it to object (new empty object)
  if (not Assigned(ATarget)) or (UnsafeGetType(PJsonValue(ATarget)) <> YYJSON_TYPE_OBJ) then
    ATarget := JsonMutObj(ADoc);

  // For each key in patch object
  if JsonObjIterInit(APatch, @it) then
  begin
    while JsonObjIterHasNext(@it) do
    begin
      pk := JsonObjIterNext(@it);
      pv := JsonObjIterGetVal(pk);
      key := Copy(pk^.Data.Str, 1, UnsafeGetLen(pk));
      if UnsafeGetType(pv) = YYJSON_TYPE_NULL then
      begin
        JsonMutObjRemoveKeyN(ATarget, PChar(key), Length(key));
        Continue;
      end;
      // lookup existing child in target
      existing := nil;
      existing := FindMutObjKey(ATarget, key);
      if Assigned(existing) then existing := existing^.Next;
      if Assigned(existing) and (UnsafeGetType(PJsonValue(existing)) = YYJSON_TYPE_OBJ) and (UnsafeGetType(pv) = YYJSON_TYPE_OBJ) then
      begin
        child := JsonMergePatch(ADoc, existing, pv);
        // existing is updated in place; nothing else to do
        // Note: our merge returns a child, but when both objects, we keep same node
      end
      else
      begin
        child := CloneToMut(ADoc, pv);
        // replace or add
        JsonMutObjRemoveKeyN(ATarget, PChar(key), Length(key));
        JsonMutObjAddVal(ADoc, ATarget, key, child);
      end;
    end;
  end;
  Result := ATarget;
end;

function SplitParentAndLast(const Path: String; out ParentPath: String; out LastToken: String): Boolean;
var p: SizeInt;
begin
  if (Path = '') then begin ParentPath := ''; LastToken := ''; Exit(True); end;
  p := LastDelimiter('/', Path);
  if p <= 0 then begin ParentPath := ''; LastToken := Path; Exit(True); end;
  ParentPath := Copy(Path, 1, p-1);
  LastToken  := Copy(Path, p+1, Length(Path)-p);
  Result := True;
end;

function UnescapeTokenStr(const Tok: String): String;
var i: SizeInt;
begin
  if Pos('~', Tok) = 0 then Exit(Tok);
  Result := '';
  i := 1;
  while i <= Length(Tok) do
  begin
    if (Tok[i] = '~') and (i < Length(Tok)) then
    begin
      if Tok[i+1] = '0' then begin Result += '~'; Inc(i, 2); Continue; end;
      if Tok[i+1] = '1' then begin Result += '/'; Inc(i, 2); Continue; end;
    end;
    Result += Tok[i];
    Inc(i);
  end;
end;

function JsonPatchApply(ADoc: TJsonMutDocument; ARoot: PJsonMutValue; APatchArr: PJsonValue; out ErrMsg: String): Boolean;
var t: UInt8; it: TJsonArrayIterator; opObj, v, opVal, pathVal, valVal: PJsonValue; op, path, parentPath, lastTok, unTok: String;
    parent: PJsonMutValue; idx: SizeUInt; elem: PJsonMutValue;
    fromVal: PJsonValue; fromPath: String; srcMut: PJsonMutValue;
    fParentPath, fLast: String; fPar: PJsonMutValue; fIdx: SizeUInt;
begin
  Result := False; ErrMsg := '';
  if (not Assigned(ADoc)) or (not Assigned(ARoot)) or (not Assigned(APatchArr)) then begin ErrMsg := 'invalid arguments'; Exit; end;
  t := UnsafeGetType(APatchArr);
  if t <> YYJSON_TYPE_ARR then begin ErrMsg := 'patch must be array'; Exit; end;

  if not JsonArrIterInit(APatchArr, @it) then begin Result := True; Exit; end;
  while JsonArrIterHasNext(@it) do
  begin
    opObj := JsonArrIterNext(@it);
    if UnsafeGetType(opObj) <> YYJSON_TYPE_OBJ then begin ErrMsg := 'op item not object'; Exit; end;
    // read fields
    opVal   := JsonObjGet(opObj, 'op');
    pathVal := JsonObjGet(opObj, 'path');
    if (not Assigned(opVal)) or (UnsafeGetType(opVal) <> YYJSON_TYPE_STR) or (not Assigned(pathVal)) or (UnsafeGetType(pathVal) <> YYJSON_TYPE_STR) then
    begin ErrMsg := 'missing op/path'; Exit; end;
    op := Copy(opVal^.Data.Str, 1, UnsafeGetLen(opVal));
    path := Copy(pathVal^.Data.Str, 1, UnsafeGetLen(pathVal));

    // split parent and last token
    SplitParentAndLast(path, parentPath, lastTok);
    parent := ARoot;
    if parentPath <> '' then
    begin
      parent := JsonMutPtrGet(ARoot, PChar(parentPath));
      if not Assigned(parent) then begin ErrMsg := 'parent not found: ' + parentPath; Exit; end;
    end;
    unTok := UnescapeTokenStr(lastTok);

    if op = 'add' then
    begin
      valVal := JsonObjGet(opObj, 'value');
      if not Assigned(valVal) then begin ErrMsg := 'add missing value'; Exit; end;
      if UnsafeGetType(PJsonValue(parent)) = YYJSON_TYPE_OBJ then
      begin
        JsonMutObjRemoveKeyN(parent, PChar(unTok), Length(unTok));
        if not JsonMutObjAddVal(ADoc, parent, unTok, CloneToMut(ADoc, valVal)) then begin ErrMsg := 'add obj failed'; Exit; end;
      end
      else if UnsafeGetType(PJsonValue(parent)) = YYJSON_TYPE_ARR then
      begin
        if (unTok = '-') then
        begin
          // RFC6902 add with '-' means append to array end
          if not JsonMutArrAppend(parent, CloneToMut(ADoc, valVal)) then begin ErrMsg := 'add arr append failed'; Exit; end;
        end
        else if StrToIndex(unTok, idx) then
        begin
          if not JsonMutArrInsert(parent, CloneToMut(ADoc, valVal), idx) then begin ErrMsg := 'add arr insert failed'; Exit; end;
        end
        else begin ErrMsg := 'add arr invalid index'; Exit; end;
      end
      else begin ErrMsg := 'add parent not container'; Exit; end;
    end
    else if op = 'remove' then
    begin
      if UnsafeGetType(PJsonValue(parent)) = YYJSON_TYPE_OBJ then
      begin
        if not Assigned(JsonMutObjRemoveKeyN(parent, PChar(unTok), Length(unTok))) then begin ErrMsg := 'remove obj key not found'; Exit; end;
      end
      else if UnsafeGetType(PJsonValue(parent)) = YYJSON_TYPE_ARR then
      begin
        if not StrToIndex(unTok, idx) then begin ErrMsg := 'remove arr invalid index'; Exit; end;
        if not Assigned(JsonMutArrRemove(parent, idx)) then begin ErrMsg := 'remove arr index not found'; Exit; end;
      end
      else begin ErrMsg := 'remove parent not container'; Exit; end;
    end
    else if op = 'replace' then
    begin
      valVal := JsonObjGet(opObj, 'value');
      if not Assigned(valVal) then begin ErrMsg := 'replace missing value'; Exit; end;
      if UnsafeGetType(PJsonValue(parent)) = YYJSON_TYPE_OBJ then
      begin
        // RFC6902: replace requires the target location to exist for objects
        if not Assigned(FindMutObjKey(parent, unTok)) then begin ErrMsg := 'replace obj key not found'; Exit; end;
        JsonMutObjRemoveKeyN(parent, PChar(unTok), Length(unTok));
        if not JsonMutObjAddVal(ADoc, parent, unTok, CloneToMut(ADoc, valVal)) then begin ErrMsg := 'replace obj failed'; Exit; end;
      end
      else if UnsafeGetType(PJsonValue(parent)) = YYJSON_TYPE_ARR then
      begin
        if not StrToIndex(unTok, idx) then begin ErrMsg := 'replace arr invalid index'; Exit; end;
        elem := CloneToMut(ADoc, valVal);
        if not Assigned(JsonMutArrReplace(parent, idx, elem)) then begin ErrMsg := 'replace arr index not found'; Exit; end;
      end
      else begin ErrMsg := 'replace parent not container'; Exit; end;
    end
    else if op = 'copy' then
    begin
      // RFC6902 copy: deep clone from from-path to path
      fromVal := JsonObjGet(opObj, 'from');
      if (not Assigned(fromVal)) or (UnsafeGetType(fromVal) <> YYJSON_TYPE_STR) then begin ErrMsg := 'copy missing from'; Exit; end;
      fromPath := Copy(fromVal^.Data.Str, 1, UnsafeGetLen(fromVal));
      srcMut := JsonMutPtrGet(ARoot, PChar(fromPath));
      if not Assigned(srcMut) then begin ErrMsg := 'copy source not found'; Exit; end;
      if UnsafeGetType(PJsonValue(parent)) = YYJSON_TYPE_OBJ then
      begin
        JsonMutObjRemoveKeyN(parent, PChar(unTok), Length(unTok));
        if not JsonMutObjAddVal(ADoc, parent, unTok, CloneFromMut(ADoc, srcMut)) then begin ErrMsg := 'copy obj failed'; Exit; end;
      end
      else if UnsafeGetType(PJsonValue(parent)) = YYJSON_TYPE_ARR then
      begin
        if (unTok = '-') then begin if not JsonMutArrAppend(parent, CloneFromMut(ADoc, srcMut)) then begin ErrMsg := 'copy arr append failed'; Exit; end; end
        else if StrToIndex(unTok, idx) then begin if not JsonMutArrInsert(parent, CloneFromMut(ADoc, srcMut), idx) then begin ErrMsg := 'copy arr insert failed'; Exit; end; end
        else begin ErrMsg := 'copy arr invalid index'; Exit; end;
      end
      else begin ErrMsg := 'copy parent not container'; Exit; end;
    end
    else if op = 'move' then
    begin
      // RFC6902 move: copy then remove from source
      fromVal := JsonObjGet(opObj, 'from');
      if (not Assigned(fromVal)) or (UnsafeGetType(fromVal) <> YYJSON_TYPE_STR) then begin ErrMsg := 'move missing from'; Exit; end;
      fromPath := Copy(fromVal^.Data.Str, 1, UnsafeGetLen(fromVal));
      // prevent moving into its own descendant (simple string prefix check)
      if (Length(fromPath) > 0) and (Copy(path, 1, Length(fromPath)) = fromPath) and ((Length(path) = Length(fromPath)) or (path[Length(fromPath)+1] = '/')) then begin ErrMsg := 'move into descendant not allowed'; Exit; end;
      srcMut := JsonMutPtrGet(ARoot, PChar(fromPath));
      if not Assigned(srcMut) then begin ErrMsg := 'move source not found'; Exit; end;
      // insert at destination
      if UnsafeGetType(PJsonValue(parent)) = YYJSON_TYPE_OBJ then
      begin
        JsonMutObjRemoveKeyN(parent, PChar(unTok), Length(unTok));
        if not JsonMutObjAddVal(ADoc, parent, unTok, CloneFromMut(ADoc, srcMut)) then begin ErrMsg := 'move obj failed'; Exit; end;
      end
      else if UnsafeGetType(PJsonValue(parent)) = YYJSON_TYPE_ARR then
      begin
        if (unTok = '-') then begin if not JsonMutArrAppend(parent, CloneFromMut(ADoc, srcMut)) then begin ErrMsg := 'move arr append failed'; Exit; end; end
        else if StrToIndex(unTok, idx) then begin if not JsonMutArrInsert(parent, CloneFromMut(ADoc, srcMut), idx) then begin ErrMsg := 'move arr insert failed'; Exit; end; end
        else begin ErrMsg := 'move arr invalid index'; Exit; end;
      end
      else begin ErrMsg := 'move parent not container'; Exit; end;
      // remove from source
      SplitParentAndLast(fromPath, fParentPath, fLast); fLast := UnescapeTokenStr(fLast);
      fPar := ARoot; if fParentPath <> '' then begin fPar := JsonMutPtrGet(ARoot, PChar(fParentPath)); if not Assigned(fPar) then begin ErrMsg := 'move parent missing'; Exit; end; end;
      if UnsafeGetType(PJsonValue(fPar)) = YYJSON_TYPE_OBJ then begin if not Assigned(JsonMutObjRemoveKeyN(fPar, PChar(fLast), Length(fLast))) then begin ErrMsg := 'move src remove key fail'; Exit; end; end
      else if UnsafeGetType(PJsonValue(fPar)) = YYJSON_TYPE_ARR then begin if not StrToIndex(fLast, fIdx) then begin ErrMsg := 'move src invalid index'; Exit; end; if not Assigned(JsonMutArrRemove(fPar, fIdx)) then begin ErrMsg := 'move src remove index fail'; Exit; end; end
      else begin ErrMsg := 'move src parent not container'; Exit; end;
    end
    else if op = 'test' then
    begin
      // RFC6902 test: deep equal at path
      fPar := JsonMutPtrGet(ARoot, PChar(path));
      v := JsonObjGet(opObj, 'value');
      if not Assigned(v) then begin ErrMsg := 'test missing value'; Exit; end;
      if not DeepEqualImmMut(v, fPar) then begin ErrMsg := 'test failed'; Exit; end;
    end
    else
    begin
      ErrMsg := 'unsupported op: ' + op; Exit;
    end;
  end;
  Result := True;
end;

end.

