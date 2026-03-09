{$CODEPAGE UTF8}
unit fafafa.core.toml.lexer.t99;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

interface

uses
  SysUtils;

type
  TTomlTokenKind = (
    ttEOF,
    ttError,
    ttString,           // "..." 普通字符串（支持转义）
    ttLiteralString,    // '...' 字面量字符串（无转义）
    ttIdent,            // bare key / 标识符
    ttInt,
    ttFloat,
    ttBool,
    ttDateTime,
    // 符号
    ttLBracket, ttRBracket,  // [ ]
    ttLBrace, ttRBrace,      // { }
    ttDot, ttComma, ttEqual, // . , =
    ttNewline
  );

  TTomlToken = record
    Kind: TTomlTokenKind;
    StartPos, EndPos: SizeUInt;  // 字节偏移（相对输入起点）
    Line, Col: SizeUInt;         // 1-based
    Text: RawByteString;         // 词素文本（必要时填充；大多数符号类可为空）
  end;

  { tomlc99 风格：指针扫描、零/少拷贝；严格换行/列计数 }
  TTomlLexer = record
  private
    P, PEnd: PChar;
    LineStart: PChar;
    CurLine, CurCol: SizeUInt;
    Base: PChar;
    LastErr: RawByteString; // 最近错误码
  public
    Input: RawByteString;
    procedure Init(const AText: RawByteString);
    function Next(out Tok: TTomlToken): Boolean; inline;
  end;

// 便捷过程式接口（可选）
procedure InitLexer(var L: TTomlLexer; const S: RawByteString);
function NextToken(var L: TTomlLexer; out Tok: TTomlToken): Boolean;

{ 对外暴露的指针级字符串解析（用于与现 Parser 渐进集成）}
function T99_ParseBasicString(var P: PChar; const PEnd: PChar; out S: String): Boolean; // 入口要求 P^ = '"'
function T99_ParseLiteralString(var P: PChar; const PEnd: PChar; out S: String): Boolean; // 入口要求 P^ = '\''

implementation

function IsIdentStart(ch: Char): Boolean; inline;
begin
  Result := (ch in ['A'..'Z','a'..'z','_']);
end;

function IsIdentCont(ch: Char): Boolean; inline;
begin
  Result := (ch in ['A'..'Z','a'..'z','0'..'9','_','-']);
end;

function HexVal(ch: Char; out v: Integer): Boolean; inline;
begin
  case ch of
    '0'..'9': begin v := Ord(ch) - Ord('0');  Exit(True); end;
    'a'..'f': begin v := 10 + Ord(ch) - Ord('a'); Exit(True); end;
    'A'..'F': begin v := 10 + Ord(ch) - Ord('A'); Exit(True); end;
  end;
  v := 0; Result := False;
end;

procedure SetTok(var L: TTomlLexer; var Tok: TTomlToken; K: TTomlTokenKind;
  const StartP, EndP: PChar; const AText: RawByteString);
begin
  Tok.Kind := K;
  Tok.StartPos := SizeUInt(StartP - L.Base);
  Tok.EndPos   := SizeUInt(EndP   - L.Base);
  Tok.Line := L.CurLine;
  Tok.Col  := L.CurCol;
  Tok.Text := AText;
end;

procedure BumpNewline(var L: TTomlLexer);
begin
  Inc(L.CurLine);
  L.CurCol := 1;
  L.LineStart := L.P;
end;

procedure Advance(var L: TTomlLexer; n: SizeInt = 1); inline;
begin
  while (n > 0) and (L.P < L.PEnd) do
  begin
    if L.P^ = #10 then BumpNewline(L) else Inc(L.CurCol);
    Inc(L.P);
    Dec(n);
  end;
end;

procedure SkipSpaces(var L: TTomlLexer);
begin
  while (L.P < L.PEnd) and (L.P^ in [#9,' ']) do begin Inc(L.CurCol); Inc(L.P); end;
end;

procedure SkipCommentToEOL(var L: TTomlLexer);
begin
  while (L.P < L.PEnd) and not (L.P^ in [#10,#13]) do Inc(L.P);
end;

// 指针级 Unicode 转义读取（不依赖词法器状态），供 Parser 直接使用
function ReadEscapedUnicode4_P(var P: PChar; const PEnd: PChar; out OutBytes: RawByteString): Boolean;
var i,v: Integer; cp: Cardinal; Q: PChar; tmp: RawByteString;
begin
  OutBytes := '';
  Result := False;
  if (P + 4 > PEnd) then Exit(False);
  cp := 0; Q := P;
  for i := 1 to 4 do
  begin
    if not HexVal(Q^, v) then Exit(False);
    cp := (cp shl 4) or Cardinal(v);
    Inc(Q);
  end;
  if (cp >= $D800) and (cp <= $DFFF) then Exit(False);
  if cp <= $7F then tmp := AnsiChar(cp)
  else if cp <= $7FF then tmp := AnsiChar($C0 or (cp shr 6)) + AnsiChar($80 or (cp and $3F))
  else tmp := AnsiChar($E0 or (cp shr 12)) + AnsiChar($80 or ((cp shr 6) and $3F)) + AnsiChar($80 or (cp and $3F));
  OutBytes := OutBytes + tmp;
  P := Q;
  Result := True;
end;

function ReadEscapedUnicode8_P(var P: PChar; const PEnd: PChar; out OutBytes: RawByteString): Boolean;
var i,v: Integer; cp: QWord; Q: PChar; tmp: RawByteString;
begin
  OutBytes := '';
  Result := False;
  if (P + 8 > PEnd) then Exit(False);
  cp := 0; Q := P;
  for i := 1 to 8 do
  begin
    if not HexVal(Q^, v) then Exit(False);
    cp := (cp shl 4) or QWord(v);
    Inc(Q);
  end;
  if (cp > $10FFFF) or ((cp >= $D800) and (cp <= $DFFF)) then Exit(False);
  if cp <= $7F then tmp := AnsiChar(cp)
  else if cp <= $7FF then tmp := AnsiChar($C0 or (cp shr 6)) + AnsiChar($80 or (cp and $3F))
  else if cp <= $FFFF then tmp := AnsiChar($E0 or (cp shr 12)) + AnsiChar($80 or ((cp shr 6) and $3F)) + AnsiChar($80 or (cp and $3F))
  else tmp := AnsiChar($F0 or (cp shr 18)) + AnsiChar($80 or ((cp shr 12) and $3F)) + AnsiChar($80 or ((cp shr 6) and $3F)) + AnsiChar($80 or (cp and $3F));
  OutBytes := OutBytes + tmp;
  P := Q;
  Result := True;
end;

function T99_ParseBasicString(var P: PChar; const PEnd: PChar; out S: String): Boolean;
var ch, esc: Char; buf: RawByteString;
begin
  Result := False; S := '';
  buf := '';
  if (P = nil) or (P >= PEnd) or (P^ <> '"') then Exit(False);
  Inc(P); // skip opening
  while (P < PEnd) do
  begin
    ch := P^; Inc(P);
    if ch = '"' then begin Result := True; Break; end;
    if (ch = #10) or (ch = #13) then Exit(False); // 单行基本字符串不允许换行
    if ch = '\' then
    begin
      if P >= PEnd then Exit(False);
      esc := P^; Inc(P);
      case esc of
        '"':  buf := buf + '"';
        '\':  buf := buf + '\';
        'n':   buf := buf + #10;
        'r':   buf := buf + #13;
        't':   buf := buf + #9;
        'b':   buf := buf + #8;
        'f':   buf := buf + #12;
        'u':   if not ReadEscapedUnicode4_P(P, PEnd, buf) then Exit(False);
        'U':   if not ReadEscapedUnicode8_P(P, PEnd, buf) then Exit(False);
      else
        Exit(False);
      end;
    end
    else
      buf := buf + AnsiChar(ch);
  end;
  S := String(buf);
end;

function T99_ParseLiteralString(var P: PChar; const PEnd: PChar; out S: String): Boolean;
var ch: Char; buf: RawByteString;
begin
  Result := False; S := '';
  buf := '';
  if (P = nil) or (P >= PEnd) or (P^ <> #39) then Exit(False);
  Inc(P); // skip opening
  while (P < PEnd) do
  begin
    ch := P^; Inc(P);
    if ch = #39 then begin Result := True; Break; end;
    if (ch = #10) or (ch = #13) then Exit(False); // 单行
    buf := buf + AnsiChar(ch);
  end;
  S := String(buf);
end;

function ReadEscapedUnicode4(var L: TTomlLexer; var OutBytes: RawByteString): Boolean;
var i,v: Integer; cp: Cardinal; P: PChar; tmp: RawByteString;
begin
  Result := False;
  L.LastErr := '';
  if (L.P + 4 > L.PEnd) then begin L.LastErr := 'unicode_escape_invalid'; Exit(False); end;
  cp := 0; P := L.P;
  for i := 1 to 4 do
  begin
    if not HexVal(P^, v) then begin L.LastErr := 'unicode_escape_invalid'; Exit(False); end;
    cp := (cp shl 4) or Cardinal(v);
    Inc(P);
  end;
  // 禁止代理项范围
  if (cp >= $D800) and (cp <= $DFFF) then begin L.LastErr := 'unicode_escape_invalid'; Exit(False); end;
  // 按 UTF-8 编码到 tmp
  if cp <= $7F then tmp := AnsiChar(cp)
  else if cp <= $7FF then tmp := AnsiChar($C0 or (cp shr 6)) + AnsiChar($80 or (cp and $3F))
  else tmp := AnsiChar($E0 or (cp shr 12)) + AnsiChar($80 or ((cp shr 6) and $3F)) + AnsiChar($80 or (cp and $3F));
  OutBytes := OutBytes + tmp;
  L.P := P; Inc(L.CurCol, 4);
  Result := True;
end;

function ReadEscapedUnicode8(var L: TTomlLexer; var OutBytes: RawByteString): Boolean;
var i,v: Integer; cp: QWord; P: PChar; tmp: RawByteString;
begin
  Result := False;
  L.LastErr := '';
  if (L.P + 8 > L.PEnd) then begin L.LastErr := 'unicode_escape_invalid'; Exit(False); end;
  cp := 0; P := L.P;
  for i := 1 to 8 do
  begin
    if not HexVal(P^, v) then begin L.LastErr := 'unicode_escape_invalid'; Exit(False); end;
    cp := (cp shl 4) or QWord(v);
    Inc(P);
  end;
  if (cp > $10FFFF) or ((cp >= $D800) and (cp <= $DFFF)) then begin L.LastErr := 'unicode_escape_invalid'; Exit(False); end;
  if cp <= $7F then tmp := AnsiChar(cp)
  else if cp <= $7FF then tmp := AnsiChar($C0 or (cp shr 6)) + AnsiChar($80 or (cp and $3F))
  else if cp <= $FFFF then tmp := AnsiChar($E0 or (cp shr 12)) + AnsiChar($80 or ((cp shr 6) and $3F)) + AnsiChar($80 or (cp and $3F))
  else tmp := AnsiChar($F0 or (cp shr 18)) + AnsiChar($80 or ((cp shr 12) and $3F)) + AnsiChar($80 or ((cp shr 6) and $3F)) + AnsiChar($80 or (cp and $3F));
  OutBytes := OutBytes + tmp;
  L.P := P; Inc(L.CurCol, 8);
  Result := True;
end;

function ReadDQString(var L: TTomlLexer; out S: RawByteString): Boolean;
var startP: PChar; ch: Char; buf: RawByteString; esc: Char;
begin
  Result := False; S := ''; buf := '';
  // 入口前应位于 '"' 之后
  startP := L.P;
  while (L.P < L.PEnd) do
  begin
    ch := L.P^; Inc(L.P); Inc(L.CurCol);
    if ch = '"' then begin Result := True; Break; end;
    if (ch = #10) or (ch = #13) then Exit(False); // 单行
    if ch = '\\' then
    begin
      if L.P >= L.PEnd then Exit(False);
      esc := L.P^; Inc(L.P); Inc(L.CurCol);
      case esc of
        '"':  buf := buf + '"';
        '\':  buf := buf + '\';
        'n':   buf := buf + #10;
        'r':   buf := buf + #13;
        't':   buf := buf + #9;
        'b':   buf := buf + #8;
        'f':   buf := buf + #12;
        'u':   if not ReadEscapedUnicode4(L, buf) then Exit(False);
        'U':   if not ReadEscapedUnicode8(L, buf) then Exit(False);
      else
        Exit(False);
      end;
    end
    else
      buf := buf + AnsiChar(ch);
  end;
  S := buf;
end;

function ReadSQString(var L: TTomlLexer; out S: RawByteString): Boolean;
var ch: Char; buf: RawByteString;
begin
  Result := False; S := ''; buf := '';
  while (L.P < L.PEnd) do
  begin
    ch := L.P^; Inc(L.P); Inc(L.CurCol);
    if ch = #39 then begin Result := True; Break; end;
    if (ch = #10) or (ch = #13) then Exit(False); // 单行
    buf := buf + AnsiChar(ch);
  end;
  S := buf;
end;

function ReadDQStringML(var L: TTomlLexer; out S: RawByteString): Boolean;
var buf, tmp: RawByteString; ch, esc: Char; Q: PChar;
begin
  Result := False; S := ''; buf := '';
  while (L.P < L.PEnd) do
  begin
    // 结束条件：三引号
    if (L.PEnd - L.P >= 3) and (L.P^='"') and ((L.P+1)^='"') and ((L.P+2)^='"') then
    begin Inc(L.P,3); Inc(L.CurCol,3); Result := True; Break; end;
    // 续行检查：反斜杠在行尾允许续行，后面必须紧跟换行
    if (L.P^='\') and ((L.P+1)<L.PEnd) and not ((L.P+1)^ in [#10,#13]) then Exit(False);
    ch := L.P^; Inc(L.P); Inc(L.CurCol);
    if (ch = #13) then
    begin
      // 归一化 CRLF/CR 为 LF
      if (L.P < L.PEnd) and (L.P^ = #10) then Inc(L.P) else ;
      BumpNewline(L);
      buf := buf + #10;
      Continue;
    end
    else if (ch = #10) then
    begin
      BumpNewline(L);
      buf := buf + #10;
      Continue;
    end;
    if ch = '\' then
    begin
      // 续行：反斜杠 + 仅空白直到行终止
      Q := L.P;
      while (Q < L.PEnd) and ((Q^ = ' ') or (Q^ = #9)) do Inc(Q);
      if (Q < L.PEnd) and ((Q^ = #10) or (Q^ = #13)) then
      begin
        // 跳过行结束
        L.P := Q;
        if L.P^ = #13 then begin Inc(L.P); if (L.P < L.PEnd) and (L.P^ = #10) then Inc(L.P); end
        else Inc(L.P);
        BumpNewline(L);
        // 修剪下一行起始空白
        while (L.P < L.PEnd) and ((L.P^ = ' ') or (L.P^ = #9)) do begin Inc(L.P); Inc(L.CurCol); end;
        Continue;
      end;
      // 正常转义
      if L.P >= L.PEnd then Exit(False);
      esc := L.P^; Inc(L.P); Inc(L.CurCol);
      case esc of
        '"':  buf := buf + '"';
'\':  buf := buf + '\';
        'n':   buf := buf + #10;
        'r':   buf := buf + #13;
        't':   buf := buf + #9;
        'b':   buf := buf + #8;
        'f':   buf := buf + #12;
        'u':   if not ReadEscapedUnicode4(L, buf) then Exit(False);
        'U':   if not ReadEscapedUnicode8(L, buf) then Exit(False);
      else
        Exit(False);
      end;
    end
    else
      buf := buf + AnsiChar(ch);
  end;
  S := buf;
end;

function ReadSQStringML(var L: TTomlLexer; out S: RawByteString): Boolean;
var buf: RawByteString; ch: Char;
begin
  Result := False; S := ''; buf := '';
  while (L.P < L.PEnd) do
  begin
    if (L.PEnd - L.P >= 3) and (L.P^=#39) and ((L.P+1)^=#39) and ((L.P+2)^=#39) then
    begin Inc(L.P,3); Inc(L.CurCol,3); Result := True; Break; end;
    ch := L.P^; Inc(L.P); Inc(L.CurCol);
    if (ch = #13) then
    begin
      if (L.P < L.PEnd) and (L.P^ = #10) then Inc(L.P) else ;
      BumpNewline(L);
      buf := buf + #10;
      Continue;
    end
    else if (ch = #10) then
    begin
      BumpNewline(L);
      buf := buf + #10;
      Continue;
    end;
    // 字面量：无转义
    buf := buf + AnsiChar(ch);
  end;
  S := buf;
end;


procedure TTomlLexer.Init(const AText: RawByteString);
begin
  Input := AText;
  if Length(Input) > 0 then
  begin
    Base := PChar(Input);
    PEnd := Base + Length(Input);
  end
  else
  begin
    Base := nil;
    PEnd := nil;
  end;
  P := Base;
  LineStart := P;
  CurLine := 1; CurCol := 1;
  LastErr := '';
end;

function TTomlLexer.Next(out Tok: TTomlToken): Boolean;
var ch: Char; startP: PChar; text: RawByteString; ok: Boolean;
begin
  Tok := Default(TTomlToken);
  // 跳空白/注释
  while True do
  begin
    SkipSpaces(Self);
    if (P >= PEnd) then begin SetTok(Self, Tok, ttEOF, P, P, ''); Exit(True); end;
    if P^ = '#' then begin SkipCommentToEOL(Self); Continue; end;
    Break;
  end;

  ch := P^;
  // 行结束
  if ch in [#10,#13] then
  begin
    if ch = #13 then
    begin
      Inc(P); if (P < PEnd) and (P^ = #10) then Inc(P) else ;
      BumpNewline(Self);
    end
    else
    begin
      Inc(P); BumpNewline(Self);
    end;
    SetTok(Self, Tok, ttNewline, P, P, ''); Exit(True);
  end;

  // 符号类
  case ch of
    '[': begin startP := P; Inc(P); Inc(CurCol); SetTok(Self, Tok, ttLBracket, startP, P, ''); Exit(True); end;
    ']': begin startP := P; Inc(P); Inc(CurCol); SetTok(Self, Tok, ttRBracket, startP, P, ''); Exit(True); end;
    '{': begin startP := P; Inc(P); Inc(CurCol); SetTok(Self, Tok, ttLBrace,   startP, P, ''); Exit(True); end;
    '}': begin startP := P; Inc(P); Inc(CurCol); SetTok(Self, Tok, ttRBrace,   startP, P, ''); Exit(True); end;
    ',': begin startP := P; Inc(P); Inc(CurCol); SetTok(Self, Tok, ttComma,    startP, P, ''); Exit(True); end;
    '.': begin startP := P; Inc(P); Inc(CurCol); SetTok(Self, Tok, ttDot,      startP, P, ''); Exit(True); end;
    '=': begin startP := P; Inc(P); Inc(CurCol); SetTok(Self, Tok, ttEqual,    startP, P, ''); Exit(True); end;
    '"': begin
      startP := P;
      // 三引号多行基本字符串
      if (PEnd - P >= 3) and (P^='"') and ((P+1)^='"') and ((P+2)^='"') then
      begin
        Inc(P,3); Inc(CurCol,3);
        // 首行紧随换行修剪
        if (P < PEnd) then
        begin
          if P^ = #13 then begin Inc(P); if (P < PEnd) and (P^ = #10) then Inc(P); BumpNewline(Self); end
          else if P^ = #10 then begin Inc(P); BumpNewline(Self); end;
        end;
        ok := ReadDQStringML(Self, text);
        if not ok then begin
          if Self.LastErr <> '' then SetTok(Self, Tok, ttError, startP, P, Self.LastErr)
          else SetTok(Self, Tok, ttError, startP, P, 'stringml_unterminated');
          Exit(True);
        end;
        SetTok(Self, Tok, ttString, startP, P, text);
        Exit(True);
      end
      else
      begin
        // 普通字符串
        Inc(P); Inc(CurCol);
        ok := ReadDQString(Self, text);
        if not ok then begin
          if Self.LastErr <> '' then SetTok(Self, Tok, ttError, startP, P, Self.LastErr)
          else SetTok(Self, Tok, ttError, startP, P, 'string_unterminated');
          Exit(True);
        end;
        SetTok(Self, Tok, ttString, startP, P, text);
        Exit(True);
      end;
    end;
    #39: begin
      startP := P;
      // 三引号多行字面量字符串
      if (PEnd - P >= 3) and (P^=#39) and ((P+1)^=#39) and ((P+2)^=#39) then
      begin
        Inc(P,3); Inc(CurCol,3);
        if (P < PEnd) then
        begin
          if P^ = #13 then begin Inc(P); if (P < PEnd) and (P^ = #10) then Inc(P); BumpNewline(Self); end
          else if P^ = #10 then begin Inc(P); BumpNewline(Self); end;
        end;
        ok := ReadSQStringML(Self, text);
        if not ok then begin
          if Self.LastErr <> '' then SetTok(Self, Tok, ttError, startP, P, Self.LastErr)
          else SetTok(Self, Tok, ttError, startP, P, 'literalml_unterminated');
          Exit(True);
        end;
        SetTok(Self, Tok, ttLiteralString, startP, P, text);
        Exit(True);
      end
      else
      begin
        // 单行字面量字符串（无转义）
        Inc(P); Inc(CurCol);
        ok := ReadSQString(Self, text);
        if not ok then begin
          if Self.LastErr <> '' then SetTok(Self, Tok, ttError, startP, P, Self.LastErr)
          else SetTok(Self, Tok, ttError, startP, P, 'literal_unterminated');
          Exit(True);
        end;
        SetTok(Self, Tok, ttLiteralString, startP, P, text);
        Exit(True);

  // 非法 Unicode 转义错误码设置：在 ReadDQString/ReadDQStringML 中已有 Exit(False) 分支，
  // 这里统一使用 'unicode_escape_invalid' 作为错误标识

      end;
    end;

  // 其余：逗号、花括号、日期时间、错误恢复等继续向后处理...

  end;

  // 标识符 / bare key （不含 '-' 作为首字符）
  if IsIdentStart(ch) then
  begin
    startP := P; Inc(P); Inc(CurCol);
    while (P < PEnd) and IsIdentCont(P^) do begin Inc(P); Inc(CurCol); end;
    SetString(text, startP, P - startP);
    // bool 识别（严格小写 true/false）
    if (text = 'true') or (text = 'false') then
    begin
      SetTok(Self, Tok, ttBool, startP, P, text); Exit(True);
    end;
    SetTok(Self, Tok, ttIdent, startP, P, text); Exit(True);
  end;

  // 数字（最小版：具体规则留待 Parser 层进一步细分）
  if (ch in ['+','-','0'..'9']) then
  begin
    startP := P;
    // 简化：全部收集到非分隔符（空格/换行/符号）为止，分类留 Parser
    while (P < PEnd) and not (P^ in [#9,' ',#10,#13,'[',']','{','}','=',',']) do begin Inc(P); end;
    // 列位置粗略推进（换行不可能在其中）
    Inc(CurCol, SizeUInt(P - startP));
    SetString(text, startP, P - startP);
    SetTok(Self, Tok, ttInt, startP, P, text); // 先标记为整数，Parser 再精分 float/datetime
    Exit(True);
  end;

  // 其他：未知字符 → 错误 token
  startP := P; Inc(P); Inc(CurCol);
  SetTok(Self, Tok, ttError, startP, P, 'unknown');
  Result := True;
end;

procedure InitLexer(var L: TTomlLexer; const S: RawByteString);
begin
  L.Init(S);
end;

function NextToken(var L: TTomlLexer; out Tok: TTomlToken): Boolean;
begin
  Result := L.Next(Tok);
end;

end.


