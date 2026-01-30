unit fafafa.core.yaml.tokenizer;

{$MODE OBJFPC}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes, fafafa.core.base;

// 最小化 Tokenizer（M1）：支持 FLOW 模式符号([ ] { } , :)、注释(#)与空白；
// 标量仅支持简单的 plain（不含引号/转义），以空白/分隔/括号/注释/换行作为终止。

type
  TYamlTokenKind = (
    YTK_NONE,
    YTK_EOF,
    YTK_FLOW_SEQ_START,  // [
    YTK_FLOW_SEQ_END,    // ]
    YTK_FLOW_MAP_START,  // {
    YTK_FLOW_MAP_END,    // }
    YTK_COMMA,           // ,

    YTK_COLON,           // :
    YTK_SCALAR
  );

  TYamlTok = record
    kind: TYamlTokenKind;
    value_ptr: PChar;
    value_len: SizeUInt;
    pos_line: SizeUInt; // 起始行（1-based）
    pos_col: SizeUInt;  // 起始列（1-based，UTF-8 假定，按字节列计）
  end;

  PYamlTokenizer = ^TYamlTokenizer;
  TYamlTokenizer = record
    input: PChar;
    len: SizeUInt;
    i: SizeUInt;
    line: SizeUInt;
    col: SizeUInt;
    // 兼容选项：允许 ';' 作为分隔符（默认 False）
    allow_semicolon: Boolean;
  end;

// API（yaml_* 前缀）
function yaml_tokenizer_create: PYamlTokenizer;
procedure yaml_tokenizer_destroy(tz: PYamlTokenizer);
function yaml_tokenizer_set_string(tz: PYamlTokenizer; const str: PChar; len: SizeUInt): Integer;
function yaml_tokenizer_next(tz: PYamlTokenizer; out tok: TYamlTok): TYamlTokenKind;

implementation

function yaml_tokenizer_create: PYamlTokenizer;
var p: PYamlTokenizer;
begin
  GetMem(p, SizeOf(TYamlTokenizer));
  FillChar(p^, SizeOf(TYamlTokenizer), 0);
  Result := p;
end;

procedure yaml_tokenizer_destroy(tz: PYamlTokenizer);
begin
  if tz=nil then Exit;
  FreeMem(tz);
end;

function yaml_tokenizer_set_string(tz: PYamlTokenizer; const str: PChar; len: SizeUInt): Integer;
begin
  if tz=nil then Exit(-1);
  tz^.input := str;
  tz^.len := len;
  tz^.i := 0;
  tz^.line := 1;
  tz^.col := 1;
  tz^.allow_semicolon := False;
  Result := 0;
end;

function yaml_tokenizer_next(tz: PYamlTokenizer; out tok: TYamlTok): TYamlTokenKind;
var L,i,start,endPos: SizeUInt; ch: Char; j, colonCount, firstColonPos: SizeUInt;
begin
  tok.kind := YTK_NONE; tok.value_ptr := nil; tok.value_len := 0;
  if (tz=nil) or (tz^.input=nil) then Exit(YTK_EOF);
  L := tz^.len; i := tz^.i;

  // 跳过空白/换行与注释（维护行列号）
  while i<L do begin
    ch := tz^.input[i];
    if (ch=' ') or (ch=#9) then begin Inc(i); Inc(tz^.col); Continue; end;
    if (ch=#13) then begin // CRLF 归并为一行
      Inc(i);
      if (i<L) and (tz^.input[i]=#10) then Inc(i);
      Inc(tz^.line); tz^.col := 1; Continue;
    end;
    if (ch=#10) then begin Inc(i); Inc(tz^.line); tz^.col := 1; Continue; end;
    if ch='#' then begin
      // 跳到行尾（不消耗行结束，由上面逻辑处理）
      while (i<L) and not (tz^.input[i] in [#10,#13]) do begin Inc(i); Inc(tz^.col); end;
      Continue;
    end;
    Break;
  end;
  if i>=L then begin tz^.i := i; Exit(YTK_EOF); end;

  // 记录当前 token 起始位置
  tok.pos_line := tz^.line; tok.pos_col := tz^.col;

  ch := tz^.input[i];
  case ch of
    '[': begin Inc(i); Inc(tz^.col); tz^.i:=i; tok.kind:=YTK_FLOW_SEQ_START; Exit(tok.kind); end;
    ']': begin Inc(i); Inc(tz^.col); tz^.i:=i; tok.kind:=YTK_FLOW_SEQ_END; Exit(tok.kind); end;
    '{': begin Inc(i); Inc(tz^.col); tz^.i:=i; tok.kind:=YTK_FLOW_MAP_START; Exit(tok.kind); end;
    '}': begin Inc(i); Inc(tz^.col); tz^.i:=i; tok.kind:=YTK_FLOW_MAP_END; Exit(tok.kind); end;
    ',': begin Inc(i); Inc(tz^.col); tz^.i:=i; tok.kind:=YTK_COMMA; Exit(tok.kind); end;

    ':': begin Inc(i); Inc(tz^.col); tz^.i:=i; tok.kind:=YTK_COLON; Exit(tok.kind); end;
    '"': begin
      // 双引号标量，占位扫描（包含引号，不解码转义）
      start := i; Inc(i); Inc(tz^.col);
      while i<L do begin
        ch := tz^.input[i];
        if ch='\' then begin
          Inc(i); Inc(tz^.col);
          if i<L then begin Inc(i); Inc(tz^.col); end;
          Continue;
        end;
        if ch='"' then begin Inc(i); Inc(tz^.col); Break; end;
        if ch=#13 then begin Inc(i); if (i<L) and (tz^.input[i]=#10) then Inc(i); Inc(tz^.line); tz^.col := 1; Continue; end;
        if ch=#10 then begin Inc(i); Inc(tz^.line); tz^.col := 1; Continue; end;
        Inc(i); Inc(tz^.col);
      end;
      endPos := i; tz^.i := i; tok.kind := YTK_SCALAR; tok.value_ptr := @tz^.input[start]; tok.value_len := endPos - start; Exit(tok.kind);
    end;
    '''': begin
      // 单引号标量，占位扫描（包含引号，不解码；'' 视作转义单引号并跳过两个字符）
      start := i; Inc(i); Inc(tz^.col);
      while i<L do begin
        ch := tz^.input[i];
        if ch='''' then begin
          if (i+1<L) and (tz^.input[i+1]='''') then begin
            // 转义单引号，两字符一起跳过
            Inc(i,2); Inc(tz^.col,2); Continue;
          end else begin
            Inc(i); Inc(tz^.col); Break;
          end;
        end;
        if ch=#13 then begin Inc(i); if (i<L) and (tz^.input[i]=#10) then Inc(i); Inc(tz^.line); tz^.col := 1; Continue; end;
        if ch=#10 then begin Inc(i); Inc(tz^.line); tz^.col := 1; Continue; end;
        Inc(i); Inc(tz^.col);
      end;
      endPos := i; tz^.i := i; tok.kind := YTK_SCALAR; tok.value_ptr := @tz^.input[start]; tok.value_len := endPos - start; Exit(tok.kind);
    end;
  end;

  // 特例：以 !< 开头的 TAG
  // 行为规则：
  // - 若尖括号内包含恰好一个冒号，则拆分为：SCALAR("!<..."直到冒号前)、COLON、SCALAR(冒号后到'>')
  // - 否则（0个或>=2个冒号），整体作为一个 SCALAR 令牌
  if (tz^.input[i]='!') and (i+1<L) and (tz^.input[i+1]='<') then begin
    start := i;
    // 预扫描以统计尖括号内冒号个数，并记录首个冒号位置
    j := i + 2; // 跳过 !<
    colonCount := 0;
    firstColonPos := L;
    while j<L do begin
      if tz^.input[j]='>' then break;
      if tz^.input[j]=':' then begin
        Inc(colonCount);
        if firstColonPos=L then firstColonPos := j;
      end;
      Inc(j);
    end;
    if colonCount=1 then begin
      // 仅拆出冒号前部分为本次 SCALAR，不消耗冒号，留给下次返回 YTK_COLON
      endPos := firstColonPos;
      // 更新 i/col 到冒号处（不消耗冒号字符）
      tz^.i := endPos; tz^.col := tz^.col + (endPos - i);
      tok.kind := YTK_SCALAR; tok.value_ptr := @tz^.input[start]; tok.value_len := endPos - start;
      Exit(tok.kind);
    end else begin
      // 整体作为 SCALAR（直到包含右尖括号）
      Inc(i,2); Inc(tz^.col,2);
      while i<L do begin
        if tz^.input[i]='>' then begin Inc(i); Inc(tz^.col); Break; end;
        if tz^.input[i]=#13 then begin Inc(i); if (i<L) and (tz^.input[i]=#10) then Inc(i); Inc(tz^.line); tz^.col := 1; Continue; end;
        if tz^.input[i]=#10 then begin Inc(i); Inc(tz^.line); tz^.col := 1; Continue; end;
        Inc(i); Inc(tz^.col);
      end;
      endPos := i;
      tz^.i := i;
      tok.kind := YTK_SCALAR; tok.value_ptr := @tz^.input[start]; tok.value_len := endPos - start;
      Exit(tok.kind);
    end;
  end;

  // SCALAR（plain，直到分隔/括号/注释/空白/换行）
  start := i;
  while i<L do begin
    ch := tz^.input[i];
    if (ch in ['[',']','{','}',',',':','#',#9,' ',#10,#13]) then Break;
    // 可选兼容：允许 ';' 作为分隔
    if (ch=';') and (tz^.allow_semicolon) then Break;
    Inc(i); Inc(tz^.col);
  end;
  endPos := i;
  tok.kind := YTK_SCALAR;
  tok.value_ptr := @tz^.input[start];
  tok.value_len := endPos - start;
  tz^.i := i;
  Result := tok.kind;
end;

end.

