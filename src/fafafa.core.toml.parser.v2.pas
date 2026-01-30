{$CODEPAGE UTF8}
unit fafafa.core.toml.parser.v2;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes,
  fafafa.core.toml,
  fafafa.core.toml.lexer.t99;

function TomlParseV2(const AText: RawByteString; out ADoc: ITomlDocument; out AErr: TTomlError): Boolean;

implementation

type
  TParserV2 = record
    L: TTomlLexer;
    Tok: TTomlToken;
    HasTok: Boolean;
    B: ITomlBuilder;
    CurPath: String; // 当前表路径（dotted），空表示 root
    Keys: TStringList;       // 已赋值的完整键路径集合（防重复）
    Tables: TStringList;     // 已出现的表路径集合（检测冲突）
    Arrays: TStringList;     // 声明为 AoT 的表路径集合
    // AoT 上下文：当处于 [[path]] 的当前表项时，记录其路径与项内键集合，仅用于本项内去重
    CurrentAoTPath: String;
    ItemKeys: TStringList;
    LastErrorMessage: String;
  end;

procedure InitSets(var P: TParserV2);
begin
  if P.Keys = nil then begin P.Keys := TStringList.Create; P.Keys.Sorted := True; P.Keys.Duplicates := dupIgnore; end;
  if P.Tables = nil then begin P.Tables := TStringList.Create; P.Tables.Sorted := True; P.Tables.Duplicates := dupIgnore; end;
  if P.Arrays = nil then begin P.Arrays := TStringList.Create; P.Arrays.Sorted := True; P.Arrays.Duplicates := dupIgnore; end;
  if P.ItemKeys = nil then begin P.ItemKeys := TStringList.Create; P.ItemKeys.Sorted := True; P.ItemKeys.Duplicates := dupError; end;
  P.CurrentAoTPath := '';
end;

procedure FreeSets(var P: TParserV2);
begin
  if P.Keys <> nil then begin P.Keys.Free; P.Keys := nil; end;
  if P.Tables <> nil then begin P.Tables.Free; P.Tables := nil; end;
  if P.Arrays <> nil then begin P.Arrays.Free; P.Arrays := nil; end;
  if P.ItemKeys <> nil then begin P.ItemKeys.Free; P.ItemKeys := nil; end;
end;


procedure Next(var P: TParserV2);
begin
  P.HasTok := NextToken(P.L, P.Tok);
end;

function TokIs(const P: TParserV2; K: TTomlTokenKind): Boolean; inline;
begin
  Result := (P.HasTok) and (P.Tok.Kind = K);
end;

function Consume(var P: TParserV2; K: TTomlTokenKind): Boolean; inline;
begin
  Result := TokIs(P, K);
  if Result then Next(P);
end;

function ReadKeyPart(const T: TTomlToken): String; inline;
begin
  case T.Kind of
    ttIdent, ttString, ttLiteralString: Exit(String(T.Text));
  else
    Exit('');
  end;
end;

function ParseDottedKey(var P: TParserV2; out KeyPath: String): Boolean;
var parts: array of String; part: String; i: Integer;
begin
  Result := False;
  SetLength(parts, 0);
  if not (TokIs(P, ttIdent) or TokIs(P, ttString) or TokIs(P, ttLiteralString)) then Exit(False);
  repeat
    part := ReadKeyPart(P.Tok);
    if part = '' then Exit(False);
    i := Length(parts);
    SetLength(parts, i+1);
    parts[i] := part;
    Next(P);
    if not TokIs(P, ttDot) then Break;
    // 连续点号 a..b → 空段，判为错误
    Next(P);
    if not (TokIs(P, ttIdent) or TokIs(P, ttString) or TokIs(P, ttLiteralString)) then Exit(False);
  until False;
  // 拼接 dotted
  KeyPath := '';
  if Length(parts) > 0 then KeyPath := parts[0];
  if Length(parts) > 1 then
  begin
    for i := 1 to High(parts) do
      KeyPath := KeyPath + '.' + parts[i];
  end;
  Result := True;
end;

// 数值与格式辅助函数（顶层）
function IsSign(ch: Char): Boolean; inline; begin Result := (ch = '+') or (ch = '-'); end;
function IsDecDigit(ch: Char): Boolean; inline; begin Result := (ch >= '0') and (ch <= '9'); end;

function ValidateUnderscoresRaw(const raw: String; const Specials: String): Boolean;
var i, n: Integer;
begin
  n := Length(raw);
  if n = 0 then Exit(False);
  if (raw[1] = '_') or (raw[n] = '_') then Exit(False);
  for i := 1 to n-1 do if (raw[i] = '_') and (raw[i+1] = '_') then Exit(False);
  for i := 1 to n do if (raw[i] = '_') then begin
    if (i>1) and (Pos(raw[i-1], Specials) > 0) then Exit(False);
    if (i<n) and (Pos(raw[i+1], Specials) > 0) then Exit(False);
  end;
  Result := True;
end;

function StripSign(const raw: String; out sign: Integer; out body: String): Boolean;
begin
  sign := 1; body := raw;
  if (Length(raw) > 0) and ((raw[1] = '+') or (raw[1] = '-')) then
  begin
    if raw[1] = '-' then sign := -1;
    body := Copy(raw, 2, MaxInt);
  end;
  Result := True;
end;

function ParseIntWithBase(const body: String; base: Integer; out v: Int64): Boolean;
var i: Integer; ch: Char; d: Integer; acc: QWord; s: String;
begin
  acc := 0; s := body;
  if s = '' then Exit(False);
  for i := 1 to Length(s) do
  begin
    ch := s[i];
    if ch = '_' then Continue;
    case base of
      2:  if (ch in ['0','1']) then d := Ord(ch) - Ord('0') else Exit(False);
      8:  if (ch in ['0'..'7']) then d := Ord(ch) - Ord('0') else Exit(False);
      10: if (ch in ['0'..'9']) then d := Ord(ch) - Ord('0') else Exit(False);
      16:
        if (ch in ['0'..'9']) then d := Ord(ch) - Ord('0')
        else if (ch in ['a'..'f']) then d := 10 + Ord(ch) - Ord('a')
        else if (ch in ['A'..'F']) then d := 10 + Ord(ch) - Ord('A')
        else Exit(False);
    else Exit(False);

    end;
    acc := acc * QWord(base) + QWord(d);
    if acc > QWord(High(Int64)) then Exit(False);
  end;
  v := Int64(acc);
  Result := True;
end;

function LooksLikeTemporal(const s: String): Boolean;
var cntDash, i: Integer;
begin
  cntDash := 0;
  for i := 1 to Length(s) do if s[i] = '-' then Inc(cntDash);
  if (Pos('T', s) > 0) or (Pos(':', s) > 0) or (Pos('Z', s) > 0) then Exit(True);
  if cntDash >= 2 then Exit(True);
  Result := False;
end;


// 数值与格式辅助函数
function StripUnderscores(const s: String): String;
var i: Integer;
begin
  Result := '';
  for i := 1 to Length(s) do if s[i] <> '_' then Result := Result + s[i];
end;

function IsFloatRaw(const s: String): Boolean; inline;
begin
  Result := (Pos('.', s) > 0) or (Pos('e', s) > 0) or (Pos('E', s) > 0);
end;

function ParseStrictInt(const raw: String; out outVal: Int64; out ErrMsg: String): Boolean;
var sgn: Integer; body, tmp: String; base: Integer; v: Int64;
begin
  Result := False; ErrMsg := '';
  if not StripSign(raw, sgn, body) then Exit(False);
  base := 10;
  if (Length(body) >= 2) and (body[1] = '0') and (body[2] in ['x','X','o','O','b','B']) then
  begin
    case body[2] of
      'x','X': base := 16;
      'o','O': base := 8;
      'b','B': base := 2;
    end;
    tmp := Copy(body, 3, MaxInt);
    if not ValidateUnderscoresRaw(tmp, '') then begin ErrMsg := 'invalid integer underscore'; Exit(False); end;
    if not ParseIntWithBase(tmp, base, v) then begin ErrMsg := 'invalid integer base digits'; Exit(False); end;
    if sgn < 0 then v := -v;
    outVal := v; Exit(True);
  end
  else
  begin
    if (Length(body) > 1) and (body[1] = '0') then begin ErrMsg := 'invalid integer leading zero'; Exit(False); end;
    if not ValidateUnderscoresRaw(body, '') then begin ErrMsg := 'invalid integer underscore'; Exit(False); end;
    tmp := StripUnderscores(body);
    if not TryStrToInt64(tmp, v) then begin ErrMsg := 'invalid integer'; Exit(False); end;
    if sgn < 0 then v := -v;
    outVal := v; Exit(True);
  end;
end;

function ParseStrictFloat(const raw: String; out outVal: Double; out ErrMsg: String): Boolean;
var sgn: Integer; body, tmp: String; pDot, pE: SizeInt; FS: TFormatSettings;
begin
  Result := False; ErrMsg := '';
  if not StripSign(raw, sgn, body) then Exit(False);
  if not ValidateUnderscoresRaw(body, '.eE+-') then begin ErrMsg := 'invalid float underscore'; Exit(False); end;
  if (Pos('.', body) = 0) and (Pos('e', body) = 0) and (Pos('E', body) = 0) then begin ErrMsg := 'invalid float format'; Exit(False); end;
  pDot := Pos('.', body);
  if pDot > 0 then
  begin
    if (pDot = 1) or (pDot = Length(body)) then begin ErrMsg := 'invalid float format'; Exit(False); end;
    if not (IsDecDigit(body[pDot-1]) or (body[pDot-1] = '_')) then begin ErrMsg := 'invalid float format'; Exit(False); end;
    if not (IsDecDigit(body[pDot+1]) or (body[pDot+1] = '_')) then begin ErrMsg := 'invalid float format'; Exit(False); end;
  end;
  pE := Pos('e', body); if pE = 0 then pE := Pos('E', body);
  if pE > 0 then
  begin
    if pE = Length(body) then begin ErrMsg := 'invalid float format'; Exit(False); end;
    if (body[pE+1] in ['+','-']) then
    begin
      if pE+1 = Length(body) then begin ErrMsg := 'invalid float format'; Exit(False); end;
      if not IsDecDigit(body[pE+2]) then begin ErrMsg := 'invalid float format'; Exit(False); end;
    end
    else if not IsDecDigit(body[pE+1]) then begin ErrMsg := 'invalid float format'; Exit(False); end;
  end;
  tmp := StripUnderscores(body);
  FS := DefaultFormatSettings; FS.DecimalSeparator := '.';
  if not TryStrToFloat(tmp, outVal, FS) then begin ErrMsg := 'invalid float'; Exit(False); end;
  if sgn < 0 then outVal := -outVal;
  Result := True;
end;



// AoT 表头：[[a.b]]
function ParseArrayOfTablesHeader(var P: TParserV2; out Path: String): Boolean;
var saveTok: TTomlToken; saveHas: Boolean;
begin
  Result := False; Path := '';
  if not TokIs(P, ttLBracket) then Exit(False);
  // 消费第二个 '['
  saveTok := P.Tok; saveHas := P.HasTok;
  Next(P);
  if not ParseDottedKey(P, Path) then begin P.Tok := saveTok; P.HasTok := saveHas; Exit(False); end;
  if not TokIs(P, ttRBracket) then begin P.Tok := saveTok; P.HasTok := saveHas; Exit(False); end;
  // 消费第一个 ']'（当前 token）
  Next(P);
  // 期待第二个 ']' 紧随其后
  if not TokIs(P, ttRBracket) then begin P.Tok := saveTok; P.HasTok := saveHas; Exit(False); end;
  // 消费第二个 ']'
  Next(P);
  // 冲突检查：与普通表冲突
  if (P.Tables.IndexOf(Path) >= 0) and (P.Arrays.IndexOf(Path) < 0) then
  begin
    P.LastErrorMessage := 'type conflict (table vs array) at ' + Path; Exit(False);
  end;
  if P.Arrays.IndexOf(Path) < 0 then P.Arrays.Add(Path);
  Result := True;
end;


// 冲突检测：确保路径上的每一级都是表，且未与键冲突
function EnsureTablePath(var P: TParserV2; const Path: String): Boolean;
var segs: TStringList; i: Integer; curr: String;
begin
  Result := False; P.LastErrorMessage := '';
  if Path = '' then begin Result := True; Exit; end;
  segs := TStringList.Create;
  try
    segs.Delimiter := '.'; segs.StrictDelimiter := True; segs.DelimitedText := Path;
    curr := '';
    for i := 0 to segs.Count-1 do
    begin
      if curr = '' then curr := segs[i] else curr := curr + '.' + segs[i];
      if (P.Keys.IndexOf(curr) >= 0) then
      begin
        P.LastErrorMessage := 'type conflict at ' + curr;
        Exit(False);
      end;
      if P.Tables.IndexOf(curr) < 0 then P.Tables.Add(curr);
    end;
    Result := True;
  finally
    segs.Free;
  end;
end;


function CleanNumberText(const S: String): String;
var i: Integer;
begin
  // 去除下划线，保持小数点与指数；TOML 要求 _ 仅作分隔
  Result := '';
  for i := 1 to Length(S) do
    if S[i] <> '_' then Result := Result + S[i];
end;

function LastKeyOf(const Path: String): String;
var p: SizeInt;
begin
  for p := Length(Path) downto 1 do if Path[p] = '.' then Exit(Copy(Path, p+1, MaxInt));
  Exit(Path);
end;

function ParentPathOf(const Path: String): String; forward;

function ParseValueAndStore(var P: TParserV2; const FullPath: String): Boolean;
var
  FS: TFormatSettings;
  txt, keyOnly: String;
  i64: Int64;
  f64: Double;
  b: Boolean;
  useRelative: Boolean;
  localKeys: TStringList;
  subKey, subPath, parentPath: String;
  expectComma: Boolean;
  sgn: Integer;
  body: String;
  tmpIntArr: array of Int64;
  // for inline array-of-tables / nested arrays
  arrPath: String;
  first, done: Boolean;
  outer: ITomlMutableArray;
  expectOuterComma, finishOuter: Boolean;
  innerI: array of Int64;
  innerF: array of Double;
  innerB: array of Boolean;
  innerS: array of String;
  tI, tF, tB, tS, hasT, expC, doneInner: Boolean;
  innerArr: ITomlMutableArray;
  k: SizeInt; k2: SizeInt;
  // arrays for fallback scalar array parsing
  itemsI: array of Int64;
  itemsF: array of Double;
  itemsB: array of Boolean;
  itemsS: array of String;
  tInt, tFloat, tBool, tStr, hasType: Boolean;

begin
  Result := False;
  // 禁用相对写入优化：统一使用绝对路径，避免上下文与栈不同步导致的误写
  useRelative := False;
  keyOnly := LastKeyOf(FullPath);

  if TokIs(P, ttString) or TokIs(P, ttLiteralString) then
  begin
    txt := String(P.Tok.Text);
    if useRelative then P.B.PutStr(keyOnly, txt) else P.B.PutAtStr(FullPath, txt);
    Next(P);
    Exit(True);
  end
  else if TokIs(P, ttBool) then
  begin
    txt := LowerCase(String(P.Tok.Text));
    b := (txt = 'true');
    if useRelative then P.B.PutBool(keyOnly, b) else P.B.PutAtBool(FullPath, b);
    Next(P);
    Exit(True);
  end





  else if TokIs(P, ttIdent) then
  begin
    txt := LowerCase(String(P.Tok.Text));
    // TOML v1.0: 禁止 NaN/Inf，遇到应报错
    if (txt = 'inf') or (txt = '+inf') or (txt = '-inf') or
       (txt = 'nan') or (txt = '+nan') or (txt = '-nan') then
    begin
      P.LastErrorMessage := 'NaN/Inf not allowed in TOML';
      Exit(False);
    end
    else begin P.LastErrorMessage := 'invalid identifier value'; Exit(False); end;
  end
  else if TokIs(P, ttInt) then
  begin
    txt := String(P.Tok.Text);
    // 先判断是否为进制前缀整数（避免 0x... 中的 'e' 触发浮点判定）
    // 使用临时变量，避免内联 var 语法与 FPC 方言冲突
    sgn := 1; body := txt;
    StripSign(txt, sgn, body);
    if (Length(body) >= 2) and (body[1] = '0') and (body[2] in ['x','X','o','O','b','B']) then
    begin
      if not ParseStrictInt(txt, i64, P.LastErrorMessage) then Exit(False);
      if useRelative then P.B.PutInt(keyOnly, i64) else P.B.PutAtInt(FullPath, i64);
      Next(P); Exit(True);
    end;
    // 日期/时间优先（词法器将其归入 ttInt，需在此识别）
    if LooksLikeTemporal(txt) then
    begin
      // 简单分类：包含 'T' 则可能是日期时间；仅有两处 '-' 则可能是日期；含 ':' 则可能是时间
      if Pos('T', txt) > 0 then
      begin
        if (Pos('Z', txt) > 0) or (Pos('+', txt) > 0) or (Pos('-', Copy(txt, 2, MaxInt)) > 0) then
        begin
          if useRelative then P.B.PutTemporalText(keyOnly, txt, tvtOffsetDateTime)
          else P.B.PutAtTemporalText(FullPath, txt, tvtOffsetDateTime);
        end
        else
        begin
          if useRelative then P.B.PutTemporalText(keyOnly, txt, tvtLocalDateTime)
          else P.B.PutAtTemporalText(FullPath, txt, tvtLocalDateTime);
        end;
      end
      else if (Pos(':', txt) > 0) and (Pos('-', txt) = 0) then
      begin
        if useRelative then P.B.PutTemporalText(keyOnly, txt, tvtLocalTime)
        else P.B.PutAtTemporalText(FullPath, txt, tvtLocalTime);
      end
      else
      begin
        if useRelative then P.B.PutTemporalText(keyOnly, txt, tvtLocalDate)
        else P.B.PutAtTemporalText(FullPath, txt, tvtLocalDate);
      end;
      Next(P); Exit(True);
    end;
    // 特殊浮点：inf/-inf、nan/-nan
    if SameText(txt, 'inf') or SameText(txt, '+inf') or SameText(txt, '-inf') then
    begin
      if SameText(txt, '-inf') then f64 := -1/0 else f64 := 1/0;
      if useRelative then P.B.PutFloat(keyOnly, f64) else P.B.PutAtFloat(FullPath, f64);
      Next(P); Exit(True);
    end
    else if SameText(txt, 'nan') or SameText(txt, '+nan') or SameText(txt, '-nan') then
    begin
      f64 := 0/0; // NaN
      if useRelative then P.B.PutFloat(keyOnly, f64) else P.B.PutAtFloat(FullPath, f64);
      Next(P); Exit(True);
    end;
    // 浮点/整数判定与严格解析
    if IsFloatRaw(txt) then
    begin
      if not ParseStrictFloat(txt, f64, P.LastErrorMessage) then Exit(False);
      if useRelative then P.B.PutFloat(keyOnly, f64) else P.B.PutAtFloat(FullPath, f64);
      Next(P); Exit(True);
    end
    else
    begin
      if not ParseStrictInt(txt, i64, P.LastErrorMessage) then Exit(False);
      if useRelative then P.B.PutInt(keyOnly, i64) else P.B.PutAtInt(FullPath, i64);
      Next(P); Exit(True);
    end;
  end
  else if TokIs(P, ttFloat) then
  begin
    txt := String(P.Tok.Text);
    if not ParseStrictFloat(txt, f64, P.LastErrorMessage) then Exit(False);
    if useRelative then P.B.PutFloat(keyOnly, f64) else P.B.PutAtFloat(FullPath, f64);
    Next(P); Exit(True);
  end
  else if TokIs(P, ttDateTime) then
  begin
    // 暂存为字符串（后续扩展 Builder 支持 Temporal 类型时切换）
    txt := String(P.Tok.Text);
    if useRelative then P.B.PutStr(keyOnly, txt) else P.B.PutAtStr(FullPath, txt);
    Next(P); Exit(True);
  end
  else if TokIs(P, ttLBracket) then
  begin
    // 值数组：[ ... ]；先尝试内联数组表与嵌套数组，否则退化为标量同构数组
    Next(P); // 消费 '['
    // 1) 直接遇到 ']' => 空数组（默认整型空数组）
    if TokIs(P, ttRBracket) then
    begin
      // 创建一个空整型数组（显式传空 open array 需通过动态数组变量）
      SetLength(tmpIntArr, 0);
      if useRelative then P.B.PutArrayOfInt(keyOnly, tmpIntArr) else P.B.PutAtArrayOfInt(FullPath, tmpIntArr);
      Next(P); Exit(True);
    end;
    // 2) 判定是否为内联数组表（元素形如 {...}）
    if TokIs(P, ttLBrace) then
    begin
      // 内联数组表：每个元素是一个内联表，写入策略：在 FullPath 创建数组表，逐个添加表项
      // 构建一个临时路径，使用 EnsureArray + PushTable + 递归 ParseValueAndStore 实现
      // 具体：我们在 Builder 侧没有“数组表写入”直达 API，这里让 FullPath 标记为 AoT，并为每个元素生成子表并填充
      // 操作：确保 FullPath 的父路径存在；然后循环解析 { ... }，对每个元素：PushTable(FullPath)，并在该表上下文下写 key
      // 为此，我们临时保存 CurPath，切换至 FullPath 的 AoT 最新项，再解析内部键值
      // 由于当前 ParseValueAndStore 是针对单个“值”调用，这里直接内联一个小循环，调用内部的内联表解析逻辑
      // 为避免大改：复用已有内联表解析分支，将 FullPath 作为容器，逐个把 { ... } 解析成一个子表对象并塞入数组中
      arrPath := FullPath;
      first := True; done := False;
      // 在集合上登记为 AoT，避免与普通表冲突
      if (P.Tables.IndexOf(arrPath) >= 0) and (P.Arrays.IndexOf(arrPath) < 0) then begin P.LastErrorMessage := 'type conflict (table vs array) at ' + arrPath; Exit(False); end;
      if P.Arrays.IndexOf(arrPath) < 0 then P.Arrays.Add(arrPath);
      while not done do
      begin
        // 元素必须是 '{'
        if not TokIs(P, ttLBrace) then begin P.LastErrorMessage := 'inline array-of-tables expects { element'; Exit(False); end;
        // Push 一个新表到数组
        P.B.PushTable(arrPath);
        // 进入内联表体：我们借用 ParseValueAndStore 的内联表分支，需要一个子路径，如 arrPath.<temp>
        // 但为了在新推的表中直接写键值，我们暂时设置 CurPath=arrPath，让 ParseLine/ParseValueAndStore 写入到当前表
        // 简化处理：直接使用现有“内联表”解析块的逻辑，复制一份最小实现（与下方 ttLBrace 分支一致），但目标是当前 AoT 最新表
        Next(P); // consume '{'
        localKeys := TStringList.Create; localKeys.Sorted := True; localKeys.Duplicates := dupError;
        try
          expectComma := False;
          while True do
          begin
            if TokIs(P, ttRBrace) then begin Next(P); Break; end;
            if expectComma then
            begin
              if not TokIs(P, ttComma) then begin P.LastErrorMessage := 'comma expected in inline table within array'; Exit(False); end;
              Next(P); expectComma := False; Continue;
            end;
            if not ParseDottedKey(P, subKey) then begin P.LastErrorMessage := 'key expected in inline table within array'; Exit(False); end;
            if not Consume(P, ttEqual) then begin P.LastErrorMessage := 'equal expected in inline table within array'; Exit(False); end;
            // 写入至 AoT 最新表：直接使用相对写入方式
            // 由于 PushTable(arrPath) 已将 Builder 栈切至新表，这里使用 useRelative= True 路径即可
            // 构造子键完整路径仅用于冲突校验
            subPath := arrPath + '.' + subKey; parentPath := ParentPathOf(subPath);
            if not EnsureTablePath(P, parentPath) then Exit(False);
            if (P.Keys.IndexOf(subPath) >= 0) or (localKeys.IndexOf(subKey) >= 0) then begin P.LastErrorMessage := 'duplicate key in inline table within array: ' + subPath; Exit(False); end;
            P.Keys.Add(subPath); localKeys.Add(subKey);
            // 递归解析值并写入当前表
            if not ParseValueAndStore(P, subPath) then Exit(False);
            expectComma := True;
            if TokIs(P, ttRBrace) then begin Next(P); Break; end;
          end;
        finally
          localKeys.Free;
        end;
        // 一个元素完成，接下来要么逗号要么结束
        if TokIs(P, ttComma) then begin Next(P); end
        else if TokIs(P, ttRBracket) then begin done := True; Break; end
        else begin P.LastErrorMessage := 'comma or ] expected after inline table'; Exit(False); end;
      end;
      // 消费 ']'
      if not TokIs(P, ttRBracket) then begin P.LastErrorMessage := '] expected after array-of-tables'; Exit(False); end;
      Next(P);
      Exit(True);
    end;
    // 3) 判定是否为嵌套数组：下一个 token 仍为 '['
    if TokIs(P, ttLBracket) then
    begin
      // 简化：嵌套数组限定为标量数组的数组，且内层各个数组必须同构且长度不做强制
      outer := P.B.NewArray;
      expectOuterComma := False; finishOuter := False;
      while not finishOuter do
      begin
        if expectOuterComma then
begin
  while TokIs(P, ttNewline) do Next(P);
  if TokIs(P, ttComma) then begin Next(P); expectOuterComma := False; end
  else if TokIs(P, ttRBracket) then begin finishOuter := True; Break; end
  else begin P.LastErrorMessage := 'comma expected between nested arrays'; Exit(False); end;
end;
        if not TokIs(P, ttLBracket) then begin P.LastErrorMessage := 'nested array must begin with ['; Exit(False); end;
        // 解析内层标量数组
        Next(P);
        // 允许内层数组混合标量类型：直接就地构建 innerArr
        innerArr := P.B.NewArray;
        innerArr.SetAllowMixed(True);
        tI := False; tF := False; tB := False; tS := False; hasT := False; expC := False; doneInner := False;
        while P.HasTok and not doneInner do
        begin
          if TokIs(P, ttRBracket) then begin Next(P); doneInner := True; Break; end;
          if expC then
begin
  while TokIs(P, ttNewline) do Next(P);
  if TokIs(P, ttComma) then begin Next(P); expC := False; end
  else if TokIs(P, ttRBracket) then begin Next(P); doneInner := True; Break; end
  else begin P.LastErrorMessage := 'expected comma in nested array'; Exit(False); end;
end;
          while TokIs(P, ttNewline) do Next(P);
          if TokIs(P, ttString) or TokIs(P, ttLiteralString) then
          begin
            txt := String(P.Tok.Text);
            innerArr.AddItem(P.B.NewStrValue(txt));
            Next(P);
          end
          else if TokIs(P, ttBool) then
          begin
            txt := LowerCase(String(P.Tok.Text)); b := (txt='true');
            innerArr.AddItem(P.B.NewBoolValue(b));
            Next(P);
          end
          else if TokIs(P, ttInt) then
          begin
            txt := String(P.Tok.Text);
            if IsFloatRaw(txt) then
            begin
              if not ParseStrictFloat(txt, f64, P.LastErrorMessage) then Exit(False);
              innerArr.AddItem(P.B.NewFloatValue(f64));
              Next(P);
            end
            else
            begin
              if not ParseStrictInt(txt, i64, P.LastErrorMessage) then Exit(False);
              innerArr.AddItem(P.B.NewIntValue(i64));
              Next(P);
            end;
          end
          else begin P.LastErrorMessage := 'unsupported nested array element'; Exit(False); end;
          while TokIs(P, ttNewline) do Next(P);
          expC := True;
        end;
        if not doneInner then begin P.LastErrorMessage := 'unterminated nested array'; Exit(False); end;
        // 已在读取过程中直接构建 innerArr
        outer.AddItem((innerArr as ITomlValue));
        // 结束本内层数组，期待逗号或外层闭合
        if TokIs(P, ttComma) then begin Next(P); expectOuterComma := False; end
        else if TokIs(P, ttRBracket) then begin finishOuter := True; end
        else begin expectOuterComma := True; end;
      end;
      // outer 完成，绑定到键（使用通用 PutArray 接口）
      if useRelative then P.B.PutArray(keyOnly, outer as ITomlArray) else P.B.PutAtArray(FullPath, outer as ITomlArray);
      if TokIs(P, ttRBracket) then Next(P) else begin P.LastErrorMessage := '] expected after nested arrays'; Exit(False); end;
      Exit(True);
    end;
    // 4) 否则：退化为标量同构数组（原实现）
    expectComma := False; done := False;
    tInt := False; tFloat := False; tBool := False; tStr := False; hasType := False;
    SetLength(itemsI,0); SetLength(itemsF,0); SetLength(itemsB,0); SetLength(itemsS,0);
    while P.HasTok and not done do
    begin
      if TokIs(P, ttRBracket) then begin done := True; Break; end;
      if expectComma then
begin
  while TokIs(P, ttNewline) do Next(P);
  if TokIs(P, ttComma) then begin Next(P); expectComma := False; Continue; end
  else if TokIs(P, ttRBracket) then begin done := True; Break; end
  else begin P.LastErrorMessage := 'expected comma'; Exit(False); end;
end;
      while TokIs(P, ttNewline) do Next(P);
      if TokIs(P, ttString) or TokIs(P, ttLiteralString) then
      begin
        if hasType and (not tStr) then begin P.LastErrorMessage := 'array type mismatch'; Exit(False); end;
        tStr := True; hasType := True; txt := String(P.Tok.Text);
        k := Length(itemsS); SetLength(itemsS, k+1); itemsS[k] := txt;
        Next(P);
      end
      else if TokIs(P, ttBool) then
      begin
        if hasType and (not tBool) then begin P.LastErrorMessage := 'array type mismatch'; Exit(False); end;
        tBool := True; hasType := True; txt := LowerCase(String(P.Tok.Text)); b := (txt='true');
        k := Length(itemsB); SetLength(itemsB, k+1); itemsB[k] := b;
        Next(P);
      end
      else if TokIs(P, ttInt) then
      begin
        txt := String(P.Tok.Text);
        if IsFloatRaw(txt) then
        begin
          if hasType and (not tFloat) then begin P.LastErrorMessage := 'array type mismatch'; Exit(False); end;
          if not ParseStrictFloat(txt, f64, P.LastErrorMessage) then Exit(False);
          tFloat := True; hasType := True; k := Length(itemsF); SetLength(itemsF, k+1); itemsF[k] := f64;
          Next(P);
        end
        else
        begin
          if hasType and (not tInt) then begin P.LastErrorMessage := 'array type mismatch'; Exit(False); end;
          if not ParseStrictInt(txt, i64, P.LastErrorMessage) then Exit(False);
          tInt := True; hasType := True; k := Length(itemsI); SetLength(itemsI, k+1); itemsI[k] := i64;
          Next(P);
        end;
      end
      else begin P.LastErrorMessage := 'unsupported array element'; Exit(False); end;
      while TokIs(P, ttNewline) do Next(P);
      expectComma := True;
    end;
    if not done then begin P.LastErrorMessage := 'unterminated array'; Exit(False); end;
    if tInt then begin if useRelative then P.B.PutArrayOfInt(keyOnly, itemsI) else P.B.PutAtArrayOfInt(FullPath, itemsI); end
    else if tFloat then begin if useRelative then P.B.PutArrayOfFloat(keyOnly, itemsF) else P.B.PutAtArrayOfFloat(FullPath, itemsF); end
    else if tBool then begin if useRelative then P.B.PutArrayOfBool(keyOnly, itemsB) else P.B.PutAtArrayOfBool(FullPath, itemsB); end
    else if tStr then begin if useRelative then P.B.PutArrayOfStr(keyOnly, itemsS) else P.B.PutAtArrayOfStr(FullPath, itemsS); end
    else begin if useRelative then P.B.PutArrayOfInt(keyOnly, itemsI) else P.B.PutAtArrayOfInt(FullPath, itemsI); end;
    Next(P); Exit(True);
  end
  else if TokIs(P, ttLBrace) then
  begin
    // 解析内联表 { k = v, ... }
    localKeys := TStringList.Create; localKeys.Sorted := True; localKeys.Duplicates := dupError;
    try
      // 进入内联表体
      Next(P);
      // 确保容器表存在
      P.B.BeginTable(FullPath).EndTable;
      expectComma := False;
      while True do
      begin
        // 允许空表：直接闭合
        if TokIs(P, ttRBrace) then begin Next(P); Break; end;
        // 逗号分隔处理（允许尾逗号与换行）
        if expectComma then
        begin
          while TokIs(P, ttNewline) do Next(P);
          if TokIs(P, ttComma) then begin Next(P); expectComma := False; Continue; end
          else if TokIs(P, ttRBrace) then begin Next(P); Break; end
          else begin P.LastErrorMessage := 'comma expected in inline table at ' + FullPath; Exit(False); end;
        end;
        // 读取键（允许换行）
        while TokIs(P, ttNewline) do Next(P);
        // 读取键
        if not ParseDottedKey(P, subKey) then begin P.LastErrorMessage := 'key expected in inline table at ' + FullPath; Exit(False); end;
        if not Consume(P, ttEqual) then begin P.LastErrorMessage := 'equal expected in inline table at ' + FullPath; Exit(False); end;
        subPath := FullPath + '.' + subKey;
        parentPath := ParentPathOf(subPath);
        if not EnsureTablePath(P, parentPath) then Exit(False);
        if (P.Keys.IndexOf(subPath) >= 0) or (localKeys.IndexOf(subKey) >= 0) then begin P.LastErrorMessage := 'duplicate key: ' + subPath; Exit(False); end;
        // 登记并写入
        P.Keys.Add(subPath);
        localKeys.Add(subKey);
        if not ParseValueAndStore(P, subPath) then Exit(False);
        expectComma := True;
        // 紧随其后允许直接闭合
        if TokIs(P, ttRBrace) then begin Next(P); Break; end;
      end;
      Exit(True);
    finally
      localKeys.Free;
    end;
  end;
end;
function ParentPathOf(const Path: String): String;
var p: SizeInt;
begin
  for p := Length(Path) downto 1 do
    if Path[p] = '.' then Exit(Copy(Path, 1, p-1));
  Exit('');
end;


function ParseLine(var P: TParserV2): Boolean;
var keyPath, fullPath: String;
begin
  Result := False;
  // 词法错误直接失败，并透传错误码
  if TokIs(P, ttError) then begin
    if Length(P.Tok.Text) > 0 then P.LastErrorMessage := String(P.Tok.Text) else P.LastErrorMessage := 'lex error';
    Exit(False);
  end;
  // 空行或换行
  if TokIs(P, ttNewline) then begin Next(P); Exit(True); end;
  if TokIs(P, ttEOF) then Exit(True);
  // 表头或 AoT： [a.b] 或 [[a.b]]
  if TokIs(P, ttLBracket) then
  begin
    Next(P);
    if TokIs(P, ttLBracket) then
    begin
      // AoT：[[a.b]]
      if not ParseArrayOfTablesHeader(P, keyPath) then Exit(False);
      // AoT 的父路径也必须是表
      if not EnsureTablePath(P, ParentPathOf(keyPath)) then Exit(False);
      // 让 Builder 在该路径上 push 一个新表
      P.B.PushTable(keyPath);
      // 切换上下文到 AoT 的新表路径，并重置本项内去重集合
      P.CurPath := keyPath;
      P.CurrentAoTPath := keyPath;
      P.ItemKeys.Clear;
      Exit(True);
    end
    else
    begin
      // 普通表 [a.b]
      if not ParseDottedKey(P, keyPath) then Exit(False);
      if not Consume(P, ttRBracket) then Exit(False);
      if not EnsureTablePath(P, keyPath) then Exit(False);
      P.B.BeginTable(keyPath).EndTable; // 确保该表在构建器里建立
      P.CurPath := keyPath; // 切换当前表路径
      Exit(True);
    end;
  end;
  // 键值对：key = value
  if TokIs(P, ttIdent) or TokIs(P, ttString) or TokIs(P, ttLiteralString) then
  begin
    if not ParseDottedKey(P, keyPath) then begin P.LastErrorMessage := 'invalid dotted key'; Exit(False); end;
    if not Consume(P, ttEqual) then Exit(False);
    if P.CurPath <> '' then fullPath := P.CurPath + '.' + keyPath else fullPath := keyPath;
    if not EnsureTablePath(P, ParentPathOf(fullPath)) then Exit(False);
    // 在 AoT 当前项内，允许不同项使用相同相对键；仅对本项内重复报错
    if (P.CurrentAoTPath <> '') and (Copy(fullPath, 1, Length(P.CurrentAoTPath)+1) = P.CurrentAoTPath + '.') then
    begin
      if P.ItemKeys.IndexOf(keyPath) >= 0 then begin P.LastErrorMessage := 'duplicate key in array-of-tables item: ' + fullPath; Exit(False); end;
      P.ItemKeys.Add(keyPath);
    end
    else
    begin
      if P.Keys.IndexOf(fullPath) >= 0 then begin P.LastErrorMessage := 'duplicate key: ' + fullPath; Exit(False); end;
      P.Keys.Add(fullPath);
    end;
    if not ParseValueAndStore(P, fullPath) then Exit(False);
    Exit(True);
  end;
  // 未识别，尝试跳过至行尾
  while P.HasTok and not TokIs(P, ttNewline) and not TokIs(P, ttEOF) do Next(P);
  Result := True;
end;

function TomlParseV2(const AText: RawByteString; out ADoc: ITomlDocument; out AErr: TTomlError): Boolean;
var P: TParserV2;
begin
  AErr.Clear;
  ADoc := nil;
  // 初始化记录，避免释放未初始化指针
  FillChar(P, SizeOf(P), 0);

  P.B := NewDoc;
  InitSets(P);

  P.CurPath := '';
  InitLexer(P.L, AText);
  Next(P);
  while P.HasTok and (P.Tok.Kind <> ttEOF) do
  begin
    if not ParseLine(P) then
    begin
      AErr.Code := tecInvalidToml;
      if P.LastErrorMessage <> '' then AErr.Message := P.LastErrorMessage else AErr.Message := 'parse error';
      AErr.Position := P.Tok.StartPos;
      AErr.Line := P.Tok.Line;
      AErr.Column := P.Tok.Col;
      FreeSets(P);
      Exit(False);
    end;
    // 行末可选换行
    if TokIs(P, ttNewline) then Next(P);
  end;
  ADoc := P.B.Build;
  FreeSets(P);
  Result := True;
end;

end.

