unit fafafa.core.yaml.impl;

{$MODE OBJFPC}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes,
  fafafa.core.yaml.types, fafafa.core.yaml.tokenizer;

// 版本 API（内部实现前缀 yaml_impl_，不对外暴露 fy_*）
function yaml_impl_version_compare(const va, vb: PFyVersion): Integer; inline;
function yaml_impl_version_default: PFyVersion; inline;
function yaml_impl_version_is_supported(const vers: PFyVersion): Boolean; inline;

// 事件/工具 API
function yaml_impl_event_type_get_text(event_type: TFyEventType): PChar; inline;
function yaml_impl_event_data(fye: PFyEvent): Pointer; inline;
function yaml_impl_event_scalar_get_text(fye: PFyEvent; len: PSizeUInt): PChar; inline;


    // 新增：事件安全访问器（仅读取，不改变所有权）
    function yaml_impl_event_scalar_get_anchor(fye: PFyEvent; len: PSizeUInt): PChar; inline;
    function yaml_impl_event_scalar_get_tag(fye: PFyEvent; len: PSizeUInt): PChar; inline;
    function yaml_impl_event_scalar_tag_implicit(fye: PFyEvent): Boolean; inline;
    function yaml_impl_event_alias_get_anchor(fye: PFyEvent; len: PSizeUInt): PChar; inline;
    function yaml_impl_event_sequence_start_get_anchor(fye: PFyEvent; len: PSizeUInt): PChar; inline;
    function yaml_impl_event_sequence_start_get_tag(fye: PFyEvent; len: PSizeUInt): PChar; inline;
    function yaml_impl_event_mapping_start_get_anchor(fye: PFyEvent; len: PSizeUInt): PChar; inline;
    function yaml_impl_event_mapping_start_get_tag(fye: PFyEvent; len: PSizeUInt): PChar; inline;

// 解析器 API
function yaml_impl_parser_create(const cfg: PFyParseCfg): PFyParser;
procedure yaml_impl_parser_destroy(fyp: PFyParser);
function yaml_impl_parser_set_string(fyp: PFyParser; const str: PChar; len: SizeUInt): Integer;
function yaml_impl_parser_parse(fyp: PFyParser): PFyEvent;
procedure yaml_impl_parser_event_free(fyp: PFyParser; fye: PFyEvent);


  // 扩展：基于 Options 的创建（安全阈值可选）
  function yaml_impl_parser_create_ex(const opts: PFyParserOptions): PFyParser;

// 文档/节点/发射器（Phase-1 占位）
function yaml_impl_document_create(const cfg: PFyParseCfg): PFyDocument;
procedure yaml_impl_document_destroy(fyd: PFyDocument);
function yaml_impl_document_build_from_string(const cfg: PFyParseCfg; const str: PChar; len: SizeUInt): PFyDocument;
function yaml_impl_document_build_from_file(const cfg: PFyParseCfg; const filename: PChar): PFyDocument;
function yaml_impl_document_get_root(fyd: PFyDocument): PFyNode;

function yaml_impl_node_get_type(fyn: PFyNode): TFyNodeType; inline;
function yaml_impl_node_get_scalar(fyn: PFyNode; len: PSizeUInt): PChar; inline;
function yaml_impl_node_get_scalar0(fyn: PFyNode): PChar; inline;
function yaml_impl_node_sequence_item_count(fyn: PFyNode): Integer; inline;
function yaml_impl_node_sequence_get_by_index(fyn: PFyNode; index: Integer): PFyNode; inline;
function yaml_impl_node_mapping_item_count(fyn: PFyNode): Integer; inline;
function yaml_impl_node_mapping_get_by_index(fyn: PFyNode; index: Integer): PFyNodePair; inline;
function yaml_impl_node_mapping_lookup_by_string(fyn: PFyNode; const key: PChar; keylen: SizeUInt): PFyNode; inline;
function yaml_impl_node_pair_key(fynp: PFyNodePair): PFyNode; inline;
function yaml_impl_node_pair_value(fynp: PFyNodePair): PFyNode; inline;

function yaml_impl_emitter_create(const cfg: PFyEmitCfg): PFyEmitter; inline;
procedure yaml_impl_emitter_destroy(fye: PFyEmitter); inline;
function yaml_impl_emit_document(fyd: PFyDocument; const cfg: PFyEmitCfg; len: PSizeUInt): PChar; inline;

implementation

uses fafafa.core.yaml; // 仅用于调用门面中的 yaml_diag_push（避免环依赖）

var GDefaultVersion: TFyVersion = (major:1; minor:2);

// 版本 API
function yaml_impl_version_compare(const va, vb: PFyVersion): Integer; inline;
var A,B: TFyVersion; begin if va<>nil then A:=va^ else A:=GDefaultVersion; if vb<>nil then B:=vb^ else B:=GDefaultVersion; if A.major<>B.major then Exit(A.major-B.major); Result:=A.minor-B.minor; end;
function yaml_impl_version_default: PFyVersion; inline; begin Result:=@GDefaultVersion; end;


function yaml_impl_version_is_supported(const vers: PFyVersion): Boolean; inline;



var V: TFyVersion; begin if vers<>nil then V:=vers^ else V:=GDefaultVersion; Result:=(V.major=1) and ((V.minor=1) or (V.minor=2)); end;

// 事件/工具
function yaml_impl_event_type_get_text(event_type: TFyEventType): PChar; inline;
var s: PChar;
begin
  s := 'NONE';
  case event_type of
    FYET_NONE: s := 'NONE';
    FYET_STREAM_START: s := '+STR';
    FYET_STREAM_END: s := '-STR';
    FYET_DOCUMENT_START: s := '+DOC';
    FYET_DOCUMENT_END: s := '-DOC';
    FYET_MAPPING_START: s := '+MAP';
    FYET_MAPPING_END: s := '-MAP';
    FYET_SEQUENCE_START: s := '+SEQ';
    FYET_SEQUENCE_END: s := '-SEQ';
    FYET_SCALAR: s := '=VAL';
    FYET_ALIAS: s := '=ALI';
  end;
  Result := s;
end;

function yaml_impl_event_data(fye: PFyEvent): Pointer; inline;
begin
  if fye=nil then begin Result := nil; Exit; end;
  case fye^.event_type of
    FYET_STREAM_START: Result := @fye^.stream_start;
    FYET_STREAM_END: Result := @fye^.stream_end;
    FYET_DOCUMENT_START: Result := @fye^.document_start;
    FYET_DOCUMENT_END: Result := @fye^.document_end;
    FYET_ALIAS: Result := @fye^.alias;
    FYET_SCALAR: Result := @fye^.scalar;
    FYET_SEQUENCE_START: Result := @fye^.sequence_start;


    FYET_SEQUENCE_END: Result := @fye^.sequence_end;
    FYET_MAPPING_START: Result := @fye^.mapping_start;
    FYET_MAPPING_END: Result := @fye^.mapping_end;
  else
    Result := nil;
  end;
end;

function yaml_impl_event_scalar_get_text(fye: PFyEvent; len: PSizeUInt): PChar; inline;
begin if (fye=nil) or (fye^.event_type<>FYET_SCALAR) or (fye^.scalar.value=nil) then begin if len<>nil then len^:=0; Exit(nil); end; if len<>nil then len^:=fye^.scalar.value^.len; Result:=fye^.scalar.value^.ptr; end;


function yaml_impl_event_scalar_get_anchor(fye: PFyEvent; len: PSizeUInt): PChar; inline;
begin
  if (fye=nil) or (fye^.event_type<>FYET_SCALAR) or (fye^.scalar.anchor=nil) then begin if len<>nil then len^:=0; Exit(nil); end;
  if len<>nil then len^:=fye^.scalar.anchor^.len; Result:=fye^.scalar.anchor^.ptr;
end;

function yaml_impl_event_scalar_get_tag(fye: PFyEvent; len: PSizeUInt): PChar; inline;
begin
  if (fye=nil) or (fye^.event_type<>FYET_SCALAR) or (fye^.scalar.tag=nil) then begin if len<>nil then len^:=0; Exit(nil); end;
  if len<>nil then len^:=fye^.scalar.tag^.len; Result:=fye^.scalar.tag^.ptr;
end;

function yaml_impl_event_scalar_tag_implicit(fye: PFyEvent): Boolean; inline;
begin
  if (fye=nil) or (fye^.event_type<>FYET_SCALAR) then Exit(False);
  Result := fye^.scalar.tag_implicit;
end;

function yaml_impl_event_alias_get_anchor(fye: PFyEvent; len: PSizeUInt): PChar; inline;
begin
  if (fye=nil) or (fye^.event_type<>FYET_ALIAS) or (fye^.alias.anchor=nil) then begin if len<>nil then len^:=0; Exit(nil); end;
  if len<>nil then len^:=fye^.alias.anchor^.len; Result:=fye^.alias.anchor^.ptr;
end;

function yaml_impl_event_sequence_start_get_anchor(fye: PFyEvent; len: PSizeUInt): PChar; inline;
begin
  if (fye=nil) or (fye^.event_type<>FYET_SEQUENCE_START) or (fye^.sequence_start.anchor=nil) then begin if len<>nil then len^:=0; Exit(nil); end;
  if len<>nil then len^:=fye^.sequence_start.anchor^.len; Result:=fye^.sequence_start.anchor^.ptr;
end;

function yaml_impl_event_sequence_start_get_tag(fye: PFyEvent; len: PSizeUInt): PChar; inline;
begin
  if (fye=nil) or (fye^.event_type<>FYET_SEQUENCE_START) or (fye^.sequence_start.tag=nil) then begin if len<>nil then len^:=0; Exit(nil); end;
  if len<>nil then len^:=fye^.sequence_start.tag^.len; Result:=fye^.sequence_start.tag^.ptr;
end;

function yaml_impl_event_mapping_start_get_anchor(fye: PFyEvent; len: PSizeUInt): PChar; inline;
begin
  if (fye=nil) or (fye^.event_type<>FYET_MAPPING_START) or (fye^.mapping_start.anchor=nil) then begin if len<>nil then len^:=0; Exit(nil); end;
  if len<>nil then len^:=fye^.mapping_start.anchor^.len; Result:=fye^.mapping_start.anchor^.ptr;
end;

function yaml_impl_event_mapping_start_get_tag(fye: PFyEvent; len: PSizeUInt): PChar; inline;
begin
  if (fye=nil) or (fye^.event_type<>FYET_MAPPING_START) or (fye^.mapping_start.tag=nil) then begin if len<>nil then len^:=0; Exit(nil); end;
  if len<>nil then len^:=fye^.mapping_start.tag^.len; Result:=fye^.mapping_start.tag^.ptr;
end;

// 解析器最小实现（与旧 core 等价，后续将替换为扫描器驱动）

Type
  PParserImpl = ^TParserImpl;
  TParserImpl = record
    input: PChar; len: SizeUInt; stage: Integer; mapping: Boolean; flags: TFyParseCfgFlags;
    key_ptr: PChar; key_len: SizeUInt; val_ptr: PChar; val_len: SizeUInt; scan_i: SizeUInt; has_pair: Boolean;
    key_bol: Boolean; // 当前 pair 的 key 是否位于行首（紧随换行）
    has_eol: Boolean; // 文本中是否出现过换行
    // Flow 序列状态（顶层或作为映射值的序列）
    sequence: Boolean;      // 当前是否在处理 [] 序列（顶层或值）
    item_ptr: PChar;        // 当前项的指针
    item_len: SizeUInt;     // 当前项的长度
    has_item: Boolean;      // 是否还有项待输出
    // 作为映射值的嵌套序列子状态
    nested_seq: Boolean;
    nested_seq_started: Boolean;
    nested_seq_item_ptr: PChar;
    nested_seq_item_len: SizeUInt;
    nested_seq_has_item: Boolean;
    nested_seq_next_is_map: Boolean; // 序列下一项是否是内嵌映射
    // 作为映射值的嵌套 flow 映射子状态
    nested_map: Boolean;
    nested_map_started: Boolean;
    nested_map_expect_value: Boolean;
    nested_map_has_pair: Boolean;
    nested_map_key_ptr: PChar;
    nested_map_key_len: SizeUInt;
    nested_map_val_ptr: PChar;
    nested_map_val_len: SizeUInt;
    // Tokenizer 驱动（flow 模式）
    tz: PYamlTokenizer;     // 解析时的 tokenizer；仅在 flow 模式中使用
    // 非 flow 路径的行首索引（0-based 字节偏移）
    line_index: PSizeUInt;
    line_index_len: SizeUInt;
    flow_map: Boolean;      // 当前是否正在处理 flow 映射
    // 轻量上下文占位：是否期望下一个 token 为 Key（用于未来状态机化）
    expect_key: Boolean;
    // 诊断收集器
    diag: PFyDiag;
    // 最近返回但尚未释放的事件（用于自动清理，保证不泄漏）
    last_event: PFyEvent;
    // 安全阈值（可选；0 表示未设置，使用库默认）
    limits: TFySafetyLimits;
    // 运行时计数器（用于阈值检查）
    event_count: Int64;
    node_count: Int64;
    depth: Integer;
  end;
// 生成当前位置的 Mark（0-based 行列）
function Parser_CurrentMark(p: PParserImpl): TYamlMark;
var m: TYamlMark; var_idx: SizeUInt; var_l, var_c: Integer; lo, hi, mid: SizeInt; line_start: SizeUInt;
begin
  m.input_pos := 0; m.line := 0; m.column := 0;
  if p=nil then Exit(m);
  if (p^.tz<>nil) then begin
    m.line := Integer(p^.tz^.line - 1);
    m.column := Integer(p^.tz^.col - 1);
    m.input_pos := p^.tz^.i;
  end else begin
    m.input_pos := p^.scan_i;
    if (p^.input<>nil) then begin
      // 使用行首索引表进行二分查找，推导 0-based 行/列
      lo := 0; hi := p^.line_index_len - 1; line_start := 0;
      while lo<=hi do begin
        mid := (lo+hi) shr 1;
        if p^.line_index[mid] <= m.input_pos then begin line_start := p^.line_index[mid]; lo := mid + 1; end
        else hi := mid - 1;
      end;
      m.line := hi; // hi 为行号
      m.column := m.input_pos - line_start;
    end;
  end;
  Exit(m);
end;


// 诊断推送（带显式起止位置）
procedure Parser_DiagPushWithMark(p: PParserImpl; level: TFyErrorType; module: TFyErrorModule; code: Integer; const msg: PChar; const start_m, end_m: TYamlMark);
begin
  if (p=nil) or not (FYPCF_COLLECT_DIAG in p^.flags) then Exit;
  yaml_diag_push(p^.diag, TYamlErrorType(level), TYamlErrorModule(module), code, msg, start_m, end_m);
end;

// 诊断快捷推送（若设置了 COLLECT_DIAG 则触发回调/收集）
procedure Parser_DiagPush(p: PParserImpl; level: TFyErrorType; module: TFyErrorModule; code: Integer; const msg: PChar);
var m: TYamlMark;
begin
  if (p=nil) or not (FYPCF_COLLECT_DIAG in p^.flags) then Exit;
  m := Parser_CurrentMark(p);
  yaml_diag_push(p^.diag, TYamlErrorType(level), TYamlErrorModule(module), code, msg, m, m);
end;

// 针对标量 Token 的诊断检查（未闭合引号/标签、多冒号规则、非法控制字符）
procedure Parser_CheckScalarToken(p: PParserImpl; const tok: TYamlTok);
var ptr: PChar; len: SizeUInt; i, startIdx, j, gtPos: SizeUInt; c: Char; colonCount: SizeUInt; m1, m2: TYamlMark;
begin
  if (p=nil) or (tok.value_ptr=nil) or (tok.value_len=0) then Exit;
  ptr := tok.value_ptr; len := tok.value_len;
  // 未闭合双引号
  if (ptr[0] = '"') and (len>0) and (ptr[len-1] <> '"') then begin
    // 将 tokenizer 的 pos_line/pos_col 覆盖回 mark 起点
    if (p^.tz<>nil) then begin p^.tz^.line := tok.pos_line; p^.tz^.col := tok.pos_col; end;
    // 范围：从起始引号到当前可见末位置（用当前 Mark）
    m1 := Parser_CurrentMark(p); m2 := m1;
    m1.line := tok.pos_line-1; m1.column := tok.pos_col-1; m1.input_pos := SizeUInt(ptr - p^.input);
    Parser_DiagPushWithMark(p, FYET_ERROR, FYEM_PARSE, Integer(FYDC_UNTERMINATED_DQUOTE), 'unterminated double-quoted scalar', m1, m2);
  end;
  // 未闭合单引号
  if (ptr[0] = #39) and (len>0) and (ptr[len-1] <> #39) then begin
    if (p^.tz<>nil) then begin p^.tz^.line := tok.pos_line; p^.tz^.col := tok.pos_col; end;
    m1 := Parser_CurrentMark(p); m2 := m1;
    m1.line := tok.pos_line-1; m1.column := tok.pos_col-1; m1.input_pos := SizeUInt(ptr - p^.input);
    Parser_DiagPushWithMark(p, FYET_ERROR, FYEM_PARSE, Integer(FYDC_UNTERMINATED_SQUOTE), 'unterminated single-quoted scalar', m1, m2);
  end;
  // TAG 规则检查：!<...>
  if (len>=2) and (ptr[0]='!') and (ptr[1]='<') then
  begin
    // 在整个输入中查找后续的 '>'，若缺失则报未闭合标签
    startIdx := SizeUInt(ptr - p^.input);
    gtPos := p^.len; // 默认未找到
    j := startIdx + 2;
    while j < p^.len do
    begin
      c := p^.input[j];
      if c='>' then begin gtPos := j; Break; end;
      if c in [']',',',#10,#13] then Break; // 视为未闭合
      Inc(j);
    end;
    if gtPos = p^.len then begin
      if (p^.tz<>nil) then begin p^.tz^.line := tok.pos_line; p^.tz^.col := tok.pos_col; end;
      m1 := Parser_CurrentMark(p); m2 := m1;
      m1.line := tok.pos_line-1; m1.column := tok.pos_col-1; m1.input_pos := SizeUInt(ptr - p^.input);
      Parser_DiagPushWithMark(p, FYET_ERROR, FYEM_PARSE, Integer(FYDC_UNTERMINATED_TAG), 'unterminated tag', m1, m2)
    end else begin
      // 统计 < 和 > 之间的冒号个数
      colonCount := 0;
      for j := (startIdx+2) to gtPos-1 do if p^.input[j]=':' then Inc(colonCount);
      if colonCount<>1 then begin
        if (p^.tz<>nil) then begin p^.tz^.line := tok.pos_line; p^.tz^.col := tok.pos_col; end;
        m1 := Parser_CurrentMark(p); m2 := m1;
      m1.line := tok.pos_line-1; m1.column := tok.pos_col-1; m1.input_pos := SizeUInt(ptr - p^.input);
      Parser_DiagPushWithMark(p, FYET_ERROR, FYEM_PARSE, Integer(FYDC_TAG_PAYLOAD_COLON_RULE), 'tag payload has 0 or multiple colons', m1, m2);
      end;
    end;
  end;
  // 非法控制字符（允许 CR/LF/TAB）
  for i := 0 to len-1 do
  begin
    c := ptr[i];
    if (Ord(c) < 32) and not (c in [#9,#10,#13]) then
    begin
      if (p^.tz<>nil) then begin p^.tz^.line := tok.pos_line; p^.tz^.col := tok.pos_col; end;
      m1 := Parser_CurrentMark(p); m2 := m1;
      m1.line := tok.pos_line-1; m1.column := tok.pos_col-1; m1.input_pos := SizeUInt(ptr - p^.input + i);
      m2 := m1; Inc(m2.column); Inc(m2.input_pos);
      Parser_DiagPushWithMark(p, FYET_ERROR, FYEM_PARSE, Integer(FYDC_ILLEGAL_CONTROL_CHAR), 'illegal control character in scalar', m1, m2);
      Break;
    end;
  end;
end;


  {-
    Parser_ScanNextPair 设计说明（简版）：
    - 输入：
      fromPos 指向当前扫描起点（上一次 value 的末尾、或文首）。
    - 规约：
      1) 跳过：行结束(CR/LF/CRLF)、分隔符(, ;)及其后的空格、整行注释(#直至行尾)。
      2) Key：从当前位置到同一行的 ':' 之前，去掉尾随空白/换行；允许 Key 为空。
      3) Value：从 ':' 后首个非空格开始，直到 注释/分隔符/换行/EOF，去掉尾随空白/换行；允许空值(len=0)。

function yaml_impl_event_scalar_get_anchor(fye: PFyEvent; len: PSizeUInt): PChar; inline;
begin
  if (fye=nil) or (fye^.event_type<>FYET_SCALAR) or (fye^.scalar.anchor=nil) then begin if len<>nil then len^:=0; Exit(nil); end;
  if len<>nil then len^:=fye^.scalar.anchor^.len; Result:=fye^.scalar.anchor^.ptr;
end;

function yaml_impl_event_scalar_get_tag(fye: PFyEvent; len: PSizeUInt): PChar; inline;
begin
  if (fye=nil) or (fye^.event_type<>FYET_SCALAR) or (fye^.scalar.tag=nil) then begin if len<>nil then len^:=0; Exit(nil); end;
  if len<>nil then len^:=fye^.scalar.tag^.len; Result:=fye^.scalar.tag^.ptr;
end;

function yaml_impl_event_scalar_tag_implicit(fye: PFyEvent): Boolean; inline;
begin
  if (fye=nil) or (fye^.event_type<>FYET_SCALAR) then Exit(False);
  Result := fye^.scalar.tag_implicit;
end;

function yaml_impl_event_alias_get_anchor(fye: PFyEvent; len: PSizeUInt): PChar; inline;
begin
  if (fye=nil) or (fye^.event_type<>FYET_ALIAS) or (fye^.alias.anchor=nil) then begin if len<>nil then len^:=0; Exit(nil); end;
  if len<>nil then len^:=fye^.alias.anchor^.len; Result:=fye^.alias.anchor^.ptr;

end;

function yaml_impl_event_sequence_start_get_anchor(fye: PFyEvent; len: PSizeUInt): PChar; inline;
begin
  if (fye=nil) or (fye^.event_type<>FYET_SEQUENCE_START) or (fye^.sequence_start.anchor=nil) then begin if len<>nil then len^:=0; Exit(nil); end;
  if len<>nil then len^:=fye^.sequence_start.anchor^.len; Result:=fye^.sequence_start.anchor^.ptr;
end;

function yaml_impl_event_sequence_start_get_tag(fye: PFyEvent; len: PSizeUInt): PChar; inline;
begin
  if (fye=nil) or (fye^.event_type<>FYET_SEQUENCE_START) or (fye^.sequence_start.tag=nil) then begin if len<>nil then len^:=0; Exit(nil); end;
  if len<>nil then len^:=fye^.sequence_start.tag^.len; Result:=fye^.sequence_start.tag^.ptr;
end;

function yaml_impl_event_mapping_start_get_anchor(fye: PFyEvent; len: PSizeUInt): PChar; inline;
begin
  if (fye=nil) or (fye^.event_type<>FYET_MAPPING_START) or (fye^.mapping_start.anchor=nil) then begin if len<>nil then len^:=0; Exit(nil); end;
  if len<>nil then len^:=fye^.mapping_start.anchor^.len; Result:=fye^.mapping_start.anchor^.ptr;
end;

function yaml_impl_event_mapping_start_get_tag(fye: PFyEvent; len: PSizeUInt): PChar; inline;
begin
  if (fye=nil) or (fye^.event_type<>FYET_MAPPING_START) or (fye^.mapping_start.tag=nil) then begin if len<>nil then len^:=0; Exit(nil); end;
  if len<>nil then len^:=fye^.mapping_start.tag^.len; Result:=fye^.mapping_start.tag^.ptr;
end;

      4) nextPos：位于本 value 的末尾处，继续跳过空白/单个分隔符/整行注释/换行，指向下一轮起点。
      5) keyAtBOL：若本对 Key 出现在行首（上一字符为换行），置 True，用于多行末尾空值的收尾判定。
    - 返回：
      True=发现一对 key/value，并给出 kptr/klen/vptr/vlen/nextPos/keyAtBOL；False=未发现。
    - 目标：单一函数承担“切分 + 预取 + 起点推进”，避免在状态机内到处散落扫描细节。
  -}
  // 跳过双引号内容（支持 \\" 转义；不解码，仅前移 j）
  procedure SkipDoubleQuoted(const buf: PChar; L: SizeUInt; var j: SizeUInt); inline;
  begin
    // 入口处应为 '"'
    Inc(j);
    while j<L do begin
      case buf[j] of


        #92: begin Inc(j); if j<L then Inc(j); end; // backslash
        #34: begin Inc(j); Exit; end;            // double quote
      else Inc(j); end;
    end;
  end;

  // 跳过单引号内容（'' 视为转义单引号）
  procedure SkipSingleQuoted(const buf: PChar; L: SizeUInt; var j: SizeUInt); inline;
  begin
    // 入口处应为 '\''
    Inc(j);
    while j<L do begin
      if buf[j]=#39 then begin
        if (j+1<L) and (buf[j+1]=#39) then begin Inc(j,2); Continue; end
        else begin Inc(j); Exit; end;
      end;
      Inc(j);
    end;
  end;

  // 扫描 [] 中的下一个 item；返回是否找到；nextPos 为下一轮起点
  function Parser_ScanNextSeqItem(p: PParserImpl; fromPos: SizeUInt;
    out iptr: PChar; out ilen: SizeUInt; out nextPos: SizeUInt): Boolean; inline;
  var L,i,j,endPos: SizeUInt;
  begin
    Result := False; if (p=nil) or (p^.input=nil) then Exit(False);
    L := p^.len; i := fromPos;
    // 跳过前导空白/换行/分隔符/注释
    while (i<L) do begin
      case p^.input[i] of
        #10,#13: Inc(i);
        ' ',#9: Inc(i);
        ',': begin Inc(i); while (i<L) and (p^.input[i] in [' ',#9]) do Inc(i); end;

        '#': begin while (i<L) and not (p^.input[i] in [#10,#13]) do Inc(i); end;





      else Break; end;
    end;
    if i>=L then Exit(False);
    if p^.input[i]=']' then begin nextPos := i+1; Exit(False); end;
    // 起始
    iptr := @p^.input[i]; j := i; endPos := L;
    // 引号开头：借用引号跳过逻辑直到遇到终止或分隔或 ']'
    if p^.input[j] in ['"',''''] then begin
      if p^.input[j]='"' then SkipDoubleQuoted(p^.input, L, j) else SkipSingleQuoted(p^.input, L, j);
      endPos := j;
    end else begin
      while j<L do begin
        case p^.input[j] of
          '"': begin SkipDoubleQuoted(p^.input, L, j); Continue; end;
          '''': begin SkipSingleQuoted(p^.input, L, j); Continue; end;
          '#',',': begin endPos:=j; Break; end;
          ']': begin endPos:=j; Break; end;
          #10,#13: begin endPos:=j; Break; end;
        else Inc(j); end;
      end;
    end;
    // 收尾裁剪空白
    while (endPos>SizeUInt(iptr - p^.input)) and (p^.input[endPos-1] in [' ',#9]) do Dec(endPos);
    ilen := endPos - SizeUInt(iptr - p^.input);
    // nextPos：消耗空白后若是分隔符或 ']'，消耗并前进
    nextPos := endPos; while (nextPos<L) and (p^.input[nextPos] in [' ',#9]) do Inc(nextPos);
    if (nextPos<L) and (p^.input[nextPos]=',') then begin Inc(nextPos); while (nextPos<L) and (p^.input[nextPos] in [' ',#9]) do Inc(nextPos); end;
    if (nextPos<L) and (p^.input[nextPos]=']') then Inc(nextPos);
    Result := True;
    end;

  // 使用 tokenizer 扫描 flow 序列下一项
  function Parser_Token_ScanNextSeqItem(p: PParserImpl; out iptr: PChar; out ilen: SizeUInt): Boolean; inline;
  var tok: TYamlTok; kind: TYamlTokenKind; start_ptr: PChar; start_len: SizeUInt; lastSepLine, lastSepCol: SizeUInt; hasSep: Boolean; m, ms, me: TYamlMark;
  begin
    Result:=False; if (p=nil) or (p^.tz=nil) then Exit(False);
    // 跳过逗号，并记录最后一个逗号的位置，用于 EOF 时的范围起点
    lastSepLine := 0; lastSepCol := 0; hasSep := False;
    while True do begin kind := yaml_tokenizer_next(p^.tz, tok); if kind in [YTK_COMMA] then begin hasSep:=True; lastSepLine:=tok.pos_line; lastSepCol:=tok.pos_col; Continue; end else Break; end;
    if kind=YTK_FLOW_SEQ_END then begin Exit(False); end;
    {removed: let EOF be handled with diag below}
    if kind=YTK_EOF then begin
      m := Parser_CurrentMark(p); ms := m; me := m;
      if hasSep then begin ms.line := lastSepLine-1; ms.column := lastSepCol-1; end;
      Parser_DiagPushWithMark(p, FYET_ERROR, FYEM_PARSE, Integer(FYDC_UNEXPECTED_EOF), 'unexpected EOF', ms, me);
      Exit(False);
    end;

    // 支持序列项为内嵌容器：'{' 或 '['
    if kind=YTK_FLOW_MAP_START then begin p^.nested_seq_next_is_map := True; Exit(True); end;
    if kind=YTK_FLOW_SEQ_START then begin p^.nested_seq_next_is_map := False; Exit(True); end;
    // 标量（含引号）
    if kind=YTK_SCALAR then begin start_ptr:=tok.value_ptr; start_len:=tok.value_len; Parser_CheckScalarToken(p, tok); end else Exit(False);
    iptr := start_ptr; ilen := start_len; p^.nested_seq_next_is_map := False; Result:=True;
  end;

  // expect_key 占位对接：在 flow_map 下，逗号后期待 key，冒号后期待 value
  procedure Parser_UpdateExpectKey_AfterToken(p: PParserImpl; kind: TYamlTokenKind); inline;
  begin
    if p=nil then Exit;
    if not p^.flow_map then Exit;
    case kind of
      YTK_COMMA: p^.expect_key := True;
      YTK_COLON: p^.expect_key := False;
      YTK_FLOW_MAP_START: p^.expect_key := True;
      YTK_FLOW_MAP_END: p^.expect_key := False;
    else
      // 其他 token 不影响 expect_key，保持当前状态
    end;
  end;

  // 使用 tokenizer 扫描 flow 映射的下一对 key:value（支持 value 为内嵌 flow 序列/映射）
  function Parser_Token_ScanNextPair(p: PParserImpl; out kptr: PChar; out klen: SizeUInt; out vptr: PChar; out vlen: SizeUInt): Boolean; inline;
  var tok: TYamlTok; kind: TYamlTokenKind; kind2: TYamlTokenKind; tok2: TYamlTok; m: TYamlMark; ms, me: TYamlMark;
  begin
    Result:=False; if (p=nil) or (p^.tz=nil) then Exit(False);
    // 跳过分隔符（仅逗号）
    repeat kind := yaml_tokenizer_next(p^.tz, tok) until not (kind in [YTK_COMMA]);
    if kind in [YTK_FLOW_MAP_END] then begin Exit(False); end;
    if kind=YTK_EOF then begin Parser_DiagPush(p, FYET_ERROR, FYEM_PARSE, Integer(FYDC_UNEXPECTED_EOF), 'unexpected EOF'); Exit(False); end;
    Parser_UpdateExpectKey_AfterToken(p, kind);
    // 期望 key（简化：需要 SCALAR）
    if kind=YTK_EOF then begin
      // 将 EOF 的位置回退到上一个 token 起点；若不可用，则用当前 Mark
      if (p^.tz<>nil) then begin
        m := Parser_CurrentMark(p); // 当前 EOF 的位置
        // 无上一个 token 起点信息，这里直接使用当前 Mark 作为起点
        Parser_DiagPushWithMark(p, FYET_ERROR, FYEM_PARSE, Integer(FYDC_UNEXPECTED_EOF), 'unexpected EOF', m, m);
      end else Parser_DiagPush(p, FYET_ERROR, FYEM_PARSE, Integer(FYDC_UNEXPECTED_EOF), 'unexpected EOF');
      Exit(False);
    end;
    if kind<>YTK_SCALAR then Exit(False);
    kptr := tok.value_ptr; klen := tok.value_len;
    // 期望冒号
    kind := yaml_tokenizer_next(p^.tz, tok); Parser_UpdateExpectKey_AfterToken(p, kind);
    if kind=YTK_EOF then begin
      // 在冒号之前遇到 EOF：起点可落在 key 的末尾，退一列；此处退回到当前 mark 的前一列
      m := Parser_CurrentMark(p); ms := m; me := m; if ms.column>0 then Dec(ms.column);
      Parser_DiagPushWithMark(p, FYET_ERROR, FYEM_PARSE, Integer(FYDC_UNEXPECTED_EOF), 'unexpected EOF', ms, me);
      Exit(False);
    end;
    if kind<>YTK_COLON then Exit(False);
    // 期望 value：支持三种情况：
    //   a) 标量：直接返回
    //   b) 内嵌 flow 序列：[...]
    //   c) 内嵌 flow 映射：{...}
    kind2 := yaml_tokenizer_next(p^.tz, tok2); Parser_UpdateExpectKey_AfterToken(p, kind2);
    if kind2=YTK_EOF then begin
      // EOF 报告位置：范围从冒号起点到 EOF
      m := Parser_CurrentMark(p); ms := m; me := m;
      // tok 当前保存的是冒号 token
      if (tok.pos_line>0) and (tok.pos_col>0) then begin ms.line := tok.pos_line-1; ms.column := tok.pos_col-1; end;
      Parser_DiagPushWithMark(p, FYET_ERROR, FYEM_PARSE, Integer(FYDC_UNEXPECTED_EOF), 'unexpected EOF', ms, me);
      Exit(False);
    end;
    if kind2=YTK_SCALAR then begin vptr:=tok2.value_ptr; vlen:=tok2.value_len; Parser_CheckScalarToken(p, tok2); end
    else if kind2=YTK_FLOW_SEQ_START then begin
      // 初始化嵌套序列状态，并预取第一项
      p^.nested_seq := True; p^.nested_seq_started := False;
      if Parser_Token_ScanNextSeqItem(p, p^.nested_seq_item_ptr, p^.nested_seq_item_len) then p^.nested_seq_has_item := True else begin p^.nested_seq_has_item := False; ms := Parser_CurrentMark(p); me := ms; if (p^.tz<>nil) then begin ms.line := p^.tz^.line-1; ms.column := p^.tz^.col-1; if ms.column>0 then Dec(ms.column); end; Parser_DiagPushWithMark(p, FYET_INFO, FYEM_PARSE, Integer(FYDC_EMPTY_FLOW_SEQUENCE), 'empty/closed flow sequence', ms, me); end;
      vptr := nil; vlen := 0;
    end else if kind2=YTK_FLOW_MAP_START then begin
      // 初始化嵌套映射状态，并预取第一对
      p^.nested_map := True; p^.nested_map_started := False; p^.nested_map_expect_value := False;
      if Parser_Token_ScanNextPair(p, p^.nested_map_key_ptr, p^.nested_map_key_len, p^.nested_map_val_ptr, p^.nested_map_val_len) then p^.nested_map_has_pair := True else begin p^.nested_map_has_pair := False; ms := Parser_CurrentMark(p); me := ms; if (p^.tz<>nil) then begin ms.line := p^.tz^.line-1; ms.column := p^.tz^.col-1; if ms.column>0 then Dec(ms.column); end; Parser_DiagPushWithMark(p, FYET_INFO, FYEM_PARSE, Integer(FYDC_EMPTY_FLOW_MAPPING), 'empty/closed flow mapping', ms, me); end;
      vptr := nil; vlen := 0;
    end else begin
      // 空值或其他符号（逗号/分号/结束）
      vptr := nil; vlen := 0;
    end;
    Result:=True;
  end;

  // 非 flow 映射：基于字符扫描（保留 key 的前导空格），支持引号 value 与分隔/注释/换行
  function Parser_ScanNextPair_NonFlow(p: PParserImpl; fromPos: SizeUInt;
    out kptr: PChar; out klen: SizeUInt; out vptr: PChar; out vlen: SizeUInt; out nextPos: SizeUInt; out keyAtBOL: Boolean): Boolean; inline;
  var L,i,j,colonPos,startKey,endKey,startVal,endVal: SizeUInt; ch: Char; bol: Boolean;
  begin
    Result := False; if (p=nil) or (p^.input=nil) then Exit(False);
    L := p^.len; i := fromPos; if i>L then i:=L;
    // 1) 跳过：整行注释/空行；允许保留前导空格给 key
    bol := (i=0) or ((i>0) and (p^.input[i-1] in [#10,#13]));
    // 若起点在 CR 后并紧跟 LF，统一归并
    if (i<L) and (p^.input[i]=#13) then begin Inc(i); if (i<L) and (p^.input[i]=#10) then Inc(i); bol:=True; end;
    if (i<L) and (p^.input[i]=#10) then begin Inc(i); bol:=True; end;
    // 跳过分隔符及其后的空格/制表
    while (i<L) do begin
      case p^.input[i] of
        ',': begin Inc(i); while (i<L) and (p^.input[i] in [' ',#9]) do Inc(i); bol := bol or ((i>0) and (p^.input[i-1] in [#10,#13])); end;
        '#': begin while (i<L) and not (p^.input[i] in [#10,#13]) do Inc(i); Continue; end;
        #10: begin Inc(i); bol:=True; Continue; end;
        #13: begin Inc(i); if (i<L) and (p^.input[i]=#10) then Inc(i); bol:=True; Continue; end;
      else Break; end;
    end;
    if i>=L then Exit(False);
    // 2) Key: 从 i 起，直到同一行 ':' 前；保留起始空格，但裁剪尾随空格
    startKey := i; endKey := i; colonPos := L; j := i;
    while j<L do begin
      ch := p^.input[j];
      case ch of
        #10,#13: begin Break; end; // 本行无 ':'，放弃为 pair
        ':': begin colonPos := j; Break; end;
      else Inc(j); end;
    end;
    if colonPos>=L then Exit(False);
    // 计算 key 尾部裁剪（不跨越起点）
    endKey := colonPos;
    while (endKey>startKey) and (p^.input[endKey-1] in [' ',#9]) do Dec(endKey);
    kptr := @p^.input[startKey]; klen := endKey - startKey; keyAtBOL := bol;
    // 3) Value: 从 ':' 后跳过空格开始，直到 注释/分隔/换行/EOF；支持引号整体跳过
    i := colonPos + 1; while (i<L) and (p^.input[i] in [' ',#9]) do Inc(i);
    startVal := i; j := i; endVal := L;
    if (j<L) and (p^.input[j] in ['"','''']) then begin
      if p^.input[j]='"' then SkipDoubleQuoted(p^.input, L, j) else SkipSingleQuoted(p^.input, L, j);
      endVal := j;
    end else begin
      while j<L do begin
        case p^.input[j] of
          '"': begin SkipDoubleQuoted(p^.input, L, j); Continue; end;
          '''': begin SkipSingleQuoted(p^.input, L, j); Continue; end;
          '#',',': begin endVal:=j; Break; end;
          #10,#13: begin endVal:=j; Break; end;
        else Inc(j); end;
      end;
    end;
    // 裁剪 value 尾部空白
    while (endVal>startVal) and (p^.input[endVal-1] in [' ',#9]) do Dec(endVal);
    vptr := @p^.input[startVal]; vlen := endVal - startVal;
    // 4) 计算 nextPos：从 endVal 起跳过尾随空白与单个分隔符与注释/换行
    nextPos := endVal; while (nextPos<L) and (p^.input[nextPos] in [' ',#9]) do Inc(nextPos);
    if (nextPos<L) and (p^.input[nextPos]=',') then begin Inc(nextPos); while (nextPos<L) and (p^.input[nextPos] in [' ',#9]) do Inc(nextPos); end;
    if (nextPos<L) and (p^.input[nextPos]='#') then begin while (nextPos<L) and not (p^.input[nextPos] in [#10,#13]) do Inc(nextPos); end;
    if (nextPos<L) and (p^.input[nextPos] in [#10,#13]) then begin Inc(nextPos); if (nextPos<L) and (p^.input[nextPos]=#10) then Inc(nextPos); end;
    Result := True;
  end;

  // 使用 tokenizer 扫描 非 flow 映射 的下一对 key:value（保留键前导空格）：对接状态机
  function Parser_Token_ScanNextPair_NonFlow(p: PParserImpl;
    out kptr: PChar; out klen: SizeUInt; out vptr: PChar; out vlen: SizeUInt; out nextPos: SizeUInt): Boolean; inline;
  var bol: Boolean;
  begin
    Result := Parser_ScanNextPair_NonFlow(p, p^.scan_i, kptr, klen, vptr, vlen, nextPos, bol);
    if Result then p^.key_bol := bol;
  end;


function yaml_impl_parser_create(const cfg: PFyParseCfg): PFyParser;
var p: PParserImpl;
begin
  GetMem(p, SizeOf(TParserImpl)); FillChar(p^, SizeOf(TParserImpl), 0);
  if cfg<>nil then begin p^.flags:=cfg^.flags; p^.diag := cfg^.diag; end else begin p^.flags:=[]; p^.diag:=nil; end;
  p^.stage:=-1; p^.has_eol:=False; p^.tz := yaml_tokenizer_create; p^.line_index:=nil; p^.line_index_len:=0; p^.event_count:=0; p^.node_count:=0; p^.depth:=0;
  // 根据 flags 设置 tokenizer 兼容选项
  if (p^.tz<>nil) then p^.tz^.allow_semicolon := (FYPCF_COMPAT_SEMICOLON_IN_SEQ in p^.flags);
  Result:=PFyParser(p);
end;

function yaml_impl_parser_create_ex(const opts: PFyParserOptions): PFyParser;
var p: PParserImpl; defaultLimits: TFySafetyLimits;
begin
  GetMem(p, SizeOf(TParserImpl)); FillChar(p^, SizeOf(TParserImpl), 0);
  // 采用 opts.cfg 覆盖基础配置
  if (opts<>nil) then begin
    p^.flags := opts^.cfg.flags;
    p^.diag  := opts^.cfg.diag;
    // 设置安全阈值（0 则用默认）
    defaultLimits.max_depth := 100;
    defaultLimits.max_nodes := 200000;
    defaultLimits.max_alias_expansion := 1000000;
    defaultLimits.max_scalar_length := 1024*1024;
    defaultLimits.max_tag_length := 256;
    defaultLimits.max_anchors := 10000;
    defaultLimits.max_document_size_bytes := 100*1024*1024;
    if (opts^.safety.max_depth>0) then p^.limits.max_depth := opts^.safety.max_depth else p^.limits.max_depth := defaultLimits.max_depth;
    if (opts^.safety.max_nodes>0) then p^.limits.max_nodes := opts^.safety.max_nodes else p^.limits.max_nodes := defaultLimits.max_nodes;
    if (opts^.safety.max_alias_expansion>0) then p^.limits.max_alias_expansion := opts^.safety.max_alias_expansion else p^.limits.max_alias_expansion := defaultLimits.max_alias_expansion;
    if (opts^.safety.max_scalar_length>0) then p^.limits.max_scalar_length := opts^.safety.max_scalar_length else p^.limits.max_scalar_length := defaultLimits.max_scalar_length;
    if (opts^.safety.max_tag_length>0) then p^.limits.max_tag_length := opts^.safety.max_tag_length else p^.limits.max_tag_length := defaultLimits.max_tag_length;
    if (opts^.safety.max_anchors>0) then p^.limits.max_anchors := opts^.safety.max_anchors else p^.limits.max_anchors := defaultLimits.max_anchors;
    if (opts^.safety.max_document_size_bytes>0) then p^.limits.max_document_size_bytes := opts^.safety.max_document_size_bytes else p^.limits.max_document_size_bytes := defaultLimits.max_document_size_bytes;
  end else begin
    p^.flags := [];
    p^.diag  := nil;
    // 默认安全阈值
    p^.limits.max_depth := 100;
    p^.limits.max_nodes := 200000;
    p^.limits.max_alias_expansion := 1000000;
    p^.limits.max_scalar_length := 1024*1024;
    p^.limits.max_tag_length := 256;
    p^.limits.max_anchors := 10000;
    p^.limits.max_document_size_bytes := 100*1024*1024;
  end;
  p^.stage:=-1; p^.has_eol:=False; p^.tz := yaml_tokenizer_create; p^.line_index:=nil; p^.line_index_len:=0; p^.event_count:=0; p^.node_count:=0; p^.depth:=0;
  // 根据 flags 设置 tokenizer 兼容选项
  if (p^.tz<>nil) then p^.tz^.allow_semicolon := (FYPCF_COMPAT_SEMICOLON_IN_SEQ in p^.flags);
  Result:=PFyParser(p);
end;



procedure yaml_impl_parser_destroy(fyp: PFyParser);
var p: PParserImpl; begin if fyp=nil then Exit; p:=PParserImpl(fyp);
  if p^.last_event<>nil then begin yaml_impl_parser_event_free(fyp, p^.last_event); p^.last_event:=nil; end;
  yaml_tokenizer_destroy(p^.tz);
  if p^.line_index<>nil then FreeMem(p^.line_index);
  FreeMem(p); end;

function yaml_impl_parser_set_string(fyp: PFyParser; const str: PChar; len: SizeUInt): Integer;
var p: PParserImpl; i: SizeUInt; begin if fyp=nil then Exit(-1); p:=PParserImpl(fyp);
  // 若存在上一次未释放事件，先释放，避免输入切换后悬挂
  if p^.last_event<>nil then begin yaml_impl_parser_event_free(fyp, p^.last_event); p^.last_event:=nil; end;

  p^.input:=str; p^.len:=len; p^.stage:=0; p^.mapping:=False; p^.key_ptr:=nil; p^.key_len:=0; p^.val_ptr:=nil; p^.val_len:=0; p^.scan_i:=0; p^.key_bol:=False; p^.has_eol:=False; p^.sequence:=False; p^.item_ptr:=nil; p^.item_len:=0; p^.has_item:=False; p^.flow_map:=False; p^.expect_key:=True; p^.event_count:=0; p^.node_count:=0; p^.depth:=0; yaml_tokenizer_set_string(p^.tz, str, len);
  // 重建非 flow 路径行首索引
  if p^.line_index<>nil then begin FreeMem(p^.line_index); p^.line_index:=nil; p^.line_index_len:=0; end;
  if (str<>nil) and (len>0) then begin
    // 最大行数不会超过 len+1
    GetMem(p^.line_index, (len+1)*SizeOf(SizeUInt));
    p^.line_index_len := 0;
    i := 0;
    // 第一行起点
    p^.line_index[p^.line_index_len] := 0; Inc(p^.line_index_len);
    while (i<len) do begin
      if str[i]=#13 then begin
        Inc(i); if (i<len) and (str[i]=#10) then Inc(i);
        p^.line_index[p^.line_index_len] := i; Inc(p^.line_index_len); Continue;
      end else if str[i]=#10 then begin
        Inc(i);
        p^.line_index[p^.line_index_len] := i; Inc(p^.line_index_len); Continue;
      end;
      Inc(i);
    end;
  end;
  Result:=0; end;

function yaml_impl_parser_parse(fyp: PFyParser): PFyEvent;
var p:PParserImpl; e:PFyEvent; L,i,j,k,endPos: SizeUInt; np: SizeUInt; tok, tok2: TYamlTok; kind, kind2: TYamlTokenKind; handled: Boolean; emitted_nested_end: Boolean; buf: PChar; e_len: SizeUInt; ms, me: TYamlMark;
  begin Result:=nil; if fyp=nil then Exit(nil); p:=PParserImpl(fyp);
  if (p^.stage<0) or (p^.stage>8) then Exit(nil);
  // 若上一次返回的事件未被调用方释放，则在本次解析前自动释放
  if p^.last_event<>nil then begin yaml_impl_parser_event_free(fyp, p^.last_event); p^.last_event := nil; end;

  // 事件计数与阈值：每次解析前先检查总体事件上限
  if (p^.limits.max_nodes>0) and (p^.event_count>=p^.limits.max_nodes) then
  begin
    if (FYPCF_COLLECT_DIAG in p^.flags) then Parser_DiagPush(p, FYET_ERROR, FYEM_PARSE, Integer(FYDC_UNKNOWN), 'event/node limit reached');
    if (FYPCF_STRICT_LIMITS in p^.flags) then Exit(nil);
  end;

  GetMem(e, SizeOf(TFyEvent)); FillChar(e^, SizeOf(TFyEvent), 0);
  emitted_nested_end := False;
  case p^.stage of
  {-
    解析状态机（简版）：
    stage 0  -> STREAM_START
    stage 1  -> DOCUMENT_START
    stage 2  -> 若允许解析文档(FYPCF_RESOLVE_DOCUMENT)，调用 Parser_ScanNextPair 预取：
                - 命中：设置 mapping/has_pair，发 MAPPING_START
                - 未命中：按单行 SCALAR 读取（裁剪注释与尾随空白）
    stage 3  -> 若 mapping：发出 Key 的 SCALAR；否则 DOCUMENT_END
    stage 4  -> 若 mapping：
                - 若 has_pair=False：发 MAPPING_END
                - 否则：
                  a) 若遇“key 位于行首且是最后一对且空值”，发 MAPPING_END（不发空标量）
                  b) 其它情况：发出 Value 的 SCALAR，并预取下一对设置 has_pair
               否则：STREAM_END
    收尾序列：MAPPING_END -> DOCUMENT_END -> STREAM_END。
    设计目标：
      1) 预取驱动，避免“输出 value 后临时探测”带来的误判；
      2) 统一分支，确保事件序列与资源释放路径唯一稳定；
      3) 兼顾多行/注释/分隔符/空值等边界情况。
  -}

    0: e^.event_type:=FYET_STREAM_START;
    1: e^.event_type:=FYET_DOCUMENT_START;
    2: begin
         // Flow 模式优先：若检测到 { 或 [，切换 tokenizer 驱动
         i := p^.scan_i; L := p^.len; handled := False;
         // 若起始字符为 flow 起点，先推进 tokenizer 的 i
         if (i<L) and (p^.input[i]='{') then begin
           // 同步 tokenizer 状态：假定 set_string 已重置 tz^.i=0，与 scan_i 对齐
           yaml_tokenizer_set_string(p^.tz, p^.input, p^.len);
           // 消耗 '{'
           if yaml_tokenizer_next(p^.tz, tok)<>YTK_FLOW_MAP_START then begin end; // 容错
           // 检查是否立即 '}' -> 空映射
           kind := yaml_tokenizer_next(p^.tz, tok);
           // 若立即结束 '}'，诊断空映射

           if kind=YTK_FLOW_MAP_END then begin p^.flow_map:=True; p^.mapping:=True; p^.has_pair:=False; e^.event_type:=FYET_MAPPING_START; handled:=True; ms := Parser_CurrentMark(p); me := ms; if (p^.tz<>nil) then begin // 当前在 '}' 之后一列，回退到 '{'
             ms.line := p^.tz^.line-1; ms.column := p^.tz^.col-1; if ms.column>0 then Dec(ms.column);
           end; Parser_DiagPushWithMark(p, FYET_INFO, FYEM_PARSE, Integer(FYDC_EMPTY_FLOW_MAPPING), 'empty/closed flow mapping', ms, me); end
           else begin
             // 回退一步给下一步消费 key（简单处理：重置字符串并跳过 '{'）
             yaml_tokenizer_set_string(p^.tz, p^.input, p^.len); yaml_tokenizer_next(p^.tz, tok); // consume '{'
             p^.flow_map:=True; p^.mapping:=True;
             if Parser_Token_ScanNextPair(p, p^.key_ptr, p^.key_len, p^.val_ptr, p^.val_len) then p^.has_pair:=True else p^.has_pair:=False;
             e^.event_type := FYET_MAPPING_START; handled:=True;
           end;
         end;
         if (not handled) and (i<L) and (p^.input[i]='[') then begin
           yaml_tokenizer_set_string(p^.tz, p^.input, p^.len);
           if yaml_tokenizer_next(p^.tz, tok2)<>YTK_FLOW_SEQ_START then begin end;
           kind2 := yaml_tokenizer_next(p^.tz, tok2);
           if kind2=YTK_FLOW_SEQ_END then begin p^.sequence:=True; p^.has_item:=False; e^.event_type:=FYET_SEQUENCE_START; handled:=True; ms := Parser_CurrentMark(p); me := ms; if (p^.tz<>nil) then begin ms.line := p^.tz^.line-1; ms.column := p^.tz^.col-1; if ms.column>0 then Dec(ms.column); end; Parser_DiagPushWithMark(p, FYET_INFO, FYEM_PARSE, Integer(FYDC_EMPTY_FLOW_SEQUENCE), 'empty/closed flow sequence', ms, me); end
           else begin yaml_tokenizer_set_string(p^.tz, p^.input, p^.len); yaml_tokenizer_next(p^.tz, tok2); p^.sequence:=True; if Parser_Token_ScanNextSeqItem(p, p^.item_ptr, p^.item_len) then p^.has_item:=True else p^.has_item:=False; e^.event_type:=FYET_SEQUENCE_START; handled:=True; end;
         end;
         // 若已由 flow 分支处理，则直接返回；否则按原逻辑（行内 map 或标量）
         if handled then begin end else if (FYPCF_RESOLVE_DOCUMENT in p^.flags) then begin
           // 非 flow：切换到 tokenizer 驱动的 pair 扫描（保持行为一致）
           if Parser_Token_ScanNextPair_NonFlow(p, p^.key_ptr, p^.key_len, p^.val_ptr, p^.val_len, np) then begin
             p^.mapping := True; p^.has_pair := True; p^.scan_i := np;
             // 计算 key 是否位于行首（BOL）
             if p^.key_ptr<>nil then begin
               k := SizeUInt(p^.key_ptr - p^.input);
               if (k>0) and (p^.input[k-1] in [#10,#13]) then p^.key_bol := True else p^.key_bol := False;
             end else p^.key_bol := False;
             e^.event_type := FYET_MAPPING_START;
           end else begin
             // 标量模式（非解析映射）按行截取，去注释和尾随空白
             // 预先计算 endPos 与 e_len，避免在复制模式下使用未初始化的 endPos
             L:=p^.len; endPos:=L; i:=p^.scan_i; while i<L do begin case p^.input[i] of '#': begin endPos:=i; Break; end; #10,#13: begin endPos:=i; Break; end; end; Inc(i); end;
             while (endPos>p^.scan_i) and (p^.input[endPos-1] in [#9,' ',#10,#13]) do Dec(endPos);
             e_len := endPos - p^.scan_i;

             e^.event_type:=FYET_SCALAR; GetMem(e^.scalar.value, SizeOf(TFyToken)); e^.scalar.value^.kind:=FYTK_SCALAR; if (FYPCF_COPY_EVENT_TEXT in p^.flags) then begin GetMem(buf, endPos - p^.scan_i + 1); Move(p^.input[p^.scan_i], buf^, endPos - p^.scan_i); buf[endPos - p^.scan_i] := #0; e^.scalar.value^.ptr := buf; e^.scalar.value^.owned := True; end else begin e^.scalar.value^.ptr:=@p^.input[p^.scan_i]; e^.scalar.value^.owned := False; end;
             L:=p^.len; endPos:=L; i:=p^.scan_i; while i<L do begin case p^.input[i] of '#': begin endPos:=i; Break; end; #10,#13: begin endPos:=i; Break; end; end; Inc(i); end;
             while (endPos>p^.scan_i) and (p^.input[endPos-1] in [#9,' ',#10,#13]) do Dec(endPos); e^.scalar.value^.len:=endPos-p^.scan_i; e^.scalar.anchor:=nil; e^.scalar.tag:=nil; e^.scalar.tag_implicit:=True;

	// 标量长度阈值检查（若设置）
	if (e^.event_type=FYET_SCALAR) and (e^.scalar.value<>nil) and (p^.limits.max_scalar_length>0) then
	begin
	  if (e^.scalar.value^.len > SizeUInt(p^.limits.max_scalar_length)) then
	  begin
	    if (FYPCF_COLLECT_DIAG in p^.flags) then Parser_DiagPush(p, FYET_ERROR, FYEM_PARSE, Integer(FYDC_UNKNOWN), 'scalar length exceeds limit');
	    if (FYPCF_STRICT_LIMITS in p^.flags) then begin FreeMem(e^.scalar.value); FreeMem(e); Exit(nil); end;
	  end;
	end;
	Inc(p^.event_count);

           end;
         end else begin
           // 标量模式（非解析映射）按行截取，去注释和尾随空白
           e^.event_type:=FYET_SCALAR; GetMem(e^.scalar.value, SizeOf(TFyToken)); e^.scalar.value^.kind:=FYTK_SCALAR; if (FYPCF_COPY_EVENT_TEXT in p^.flags) then begin GetMem(buf, endPos - p^.scan_i + 1); Move(p^.input[p^.scan_i], buf^, endPos - p^.scan_i); buf[endPos - p^.scan_i] := #0; e^.scalar.value^.ptr := buf; e^.scalar.value^.owned := True; end else begin e^.scalar.value^.ptr:=@p^.input[p^.scan_i]; e^.scalar.value^.owned := False; end;
           L:=p^.len; endPos:=L; i:=p^.scan_i; while i<L do begin case p^.input[i] of '#': begin endPos:=i; Break; end; #10,#13: begin endPos:=i; Break; end; end; Inc(i); end;
           while (endPos>p^.scan_i) and (p^.input[endPos-1] in [#9,' ',#10,#13]) do Dec(endPos); e^.scalar.value^.len:=endPos-p^.scan_i; e^.scalar.anchor:=nil; e^.scalar.tag:=nil; e^.scalar.tag_implicit:=True;

	           // 标量长度阈值检查（非解析映射，非 RESOLVE_DOCUMENT 路径）
	           if (p^.limits.max_scalar_length>0) and (e^.scalar.value<>nil) and (e^.scalar.value^.len > SizeUInt(p^.limits.max_scalar_length)) then
	           begin
	             if (FYPCF_COLLECT_DIAG in p^.flags) then Parser_DiagPush(p, FYET_ERROR, FYEM_PARSE, Integer(FYDC_UNKNOWN), 'scalar length exceeds limit');
	             if (FYPCF_STRICT_LIMITS in p^.flags) then begin yaml_impl_parser_event_free(fyp, e); Exit(nil); end;
	           end;

         end; end;
    3: begin

	           // 标量长度阈值检查（非解析映射标量路径）
	           if (p^.limits.max_scalar_length>0) and (e^.scalar.value<>nil) and (e^.scalar.value^.len > SizeUInt(p^.limits.max_scalar_length)) then
	           begin
	             if (FYPCF_COLLECT_DIAG in p^.flags) then Parser_DiagPush(p, FYET_ERROR, FYEM_PARSE, Integer(FYDC_UNKNOWN), 'scalar length exceeds limit');
	             if (FYPCF_STRICT_LIMITS in p^.flags) then begin yaml_impl_parser_event_free(fyp, e); Exit(nil); end;
	           end;

         if p^.mapping then begin
           if not p^.has_pair then e^.event_type:=FYET_MAPPING_END
           else begin
             e^.event_type:=FYET_SCALAR; GetMem(e^.scalar.value, SizeOf(TFyToken)); e^.scalar.value^.kind:=FYTK_SCALAR; e_len:=p^.key_len; if (FYPCF_COPY_EVENT_TEXT in p^.flags) and (e_len>0) then begin GetMem(buf, e_len+1); Move(p^.key_ptr^, buf^, e_len); buf[e_len]:=#0; e^.scalar.value^.ptr:=buf; e^.scalar.value^.owned:=True; end else begin e^.scalar.value^.ptr:=p^.key_ptr; e^.scalar.value^.owned:=False; end; e^.scalar.value^.len:=e_len; e^.scalar.anchor:=nil; e^.scalar.tag:=nil; e^.scalar.tag_implicit:=True;
           end;
         end else if p^.sequence then begin
           if not p^.has_item then e^.event_type:=FYET_SEQUENCE_END
           else begin
             // 序列项：可能为标量或内嵌映射
             if p^.nested_map then begin
               // 在序列上下文中处理内嵌映射的键/值/结束
               if not p^.nested_map_started then begin
                 e^.event_type := FYET_MAPPING_START;
                 p^.nested_map_started := True;
                 p^.nested_map_expect_value := False;
               end else if p^.nested_map_expect_value then begin
                 e^.event_type:=FYET_SCALAR; GetMem(e^.scalar.value, SizeOf(TFyToken)); e^.scalar.value^.kind:=FYTK_SCALAR; e_len:=p^.nested_map_val_len; if (FYPCF_COPY_EVENT_TEXT in p^.flags) and (e_len>0) then begin GetMem(buf, e_len+1); Move(p^.nested_map_val_ptr^, buf^, e_len); buf[e_len]:=#0; e^.scalar.value^.ptr:=buf; e^.scalar.value^.owned:=True; end else begin e^.scalar.value^.ptr:=p^.nested_map_val_ptr; e^.scalar.value^.owned:=False; end; e^.scalar.value^.len:=e_len; e^.scalar.anchor:=nil; e^.scalar.tag:=nil; e^.scalar.tag_implicit:=True;
                 if Parser_Token_ScanNextPair(p, p^.nested_map_key_ptr, p^.nested_map_key_len, p^.nested_map_val_ptr, p^.nested_map_val_len) then p^.nested_map_has_pair := True else p^.nested_map_has_pair := False;
                 p^.nested_map_expect_value := False;
               end else begin
                 if not p^.nested_map_has_pair then begin
                   e^.event_type := FYET_MAPPING_END;
                   p^.nested_map := False;
                   // 映射作为一个序列项整体结束后，再预取序列的下一项
                   if Parser_Token_ScanNextSeqItem(p, p^.item_ptr, p^.item_len) then p^.has_item := True else p^.has_item := False;
                 end else begin
                   e^.event_type:=FYET_SCALAR; GetMem(e^.scalar.value, SizeOf(TFyToken)); e^.scalar.value^.kind:=FYTK_SCALAR; e_len:=p^.nested_map_key_len; if (FYPCF_COPY_EVENT_TEXT in p^.flags) and (e_len>0) then begin GetMem(buf, e_len+1); Move(p^.nested_map_key_ptr^, buf^, e_len); buf[e_len]:=#0; e^.scalar.value^.ptr:=buf; e^.scalar.value^.owned:=True; end else begin e^.scalar.value^.ptr:=p^.nested_map_key_ptr; e^.scalar.value^.owned:=False; end; e^.scalar.value^.len:=e_len; e^.scalar.anchor:=nil; e^.scalar.tag:=nil; e^.scalar.tag_implicit:=True;
                   p^.nested_map_expect_value := True;
                 end;
               end;
             end else if p^.nested_seq_next_is_map then begin
               // 该序列项为内嵌映射：立即发 START，并准备第一对
               e^.event_type := FYET_MAPPING_START;
               p^.nested_map := True; p^.nested_map_started := True; p^.nested_map_expect_value := False;
               if Parser_Token_ScanNextPair(p, p^.nested_map_key_ptr, p^.nested_map_key_len, p^.nested_map_val_ptr, p^.nested_map_val_len) then p^.nested_map_has_pair := True else begin p^.nested_map_has_pair := False; ms := Parser_CurrentMark(p); me := ms; if (p^.tz<>nil) then begin ms.line := p^.tz^.line-1; ms.column := p^.tz^.col-1; if ms.column>0 then Dec(ms.column); end; Parser_DiagPushWithMark(p, FYET_INFO, FYEM_PARSE, Integer(FYDC_EMPTY_FLOW_MAPPING), 'empty/closed flow mapping', ms, me); end;
               p^.nested_seq_next_is_map := False;
             end else begin
               // 标量项：发出并预取下一项
               e^.event_type:=FYET_SCALAR; GetMem(e^.scalar.value, SizeOf(TFyToken)); e^.scalar.value^.kind:=FYTK_SCALAR; e_len:=p^.item_len; if (FYPCF_COPY_EVENT_TEXT in p^.flags) and (e_len>0) then begin GetMem(buf, e_len+1); Move(p^.item_ptr^, buf^, e_len); buf[e_len]:=#0; e^.scalar.value^.ptr:=buf; e^.scalar.value^.owned:=True; end else begin e^.scalar.value^.ptr:=p^.item_ptr; e^.scalar.value^.owned:=False; end; e^.scalar.value^.len:=e_len; e^.scalar.anchor:=nil; e^.scalar.tag:=nil; e^.scalar.tag_implicit:=True;
               if Parser_Token_ScanNextSeqItem(p, p^.item_ptr, p^.item_len) then p^.has_item := True else p^.has_item := False;
             end;
           end;
           end

           else if p^.nested_map then begin
             // 值是内嵌 flow 映射：按顺序发出其键/值/结束
             if not p^.nested_map_started then begin
               // 第一个事件是键（SCALAR）
               if not p^.nested_map_has_pair then begin e^.event_type := FYET_MAPPING_END; p^.nested_map := False; emitted_nested_end := True; end
               else begin
                 e^.event_type := FYET_SCALAR; GetMem(e^.scalar.value, SizeOf(TFyToken)); e^.scalar.value^.kind:=FYTK_SCALAR; e_len:=p^.nested_map_key_len; if (FYPCF_COPY_EVENT_TEXT in p^.flags) and (e_len>0) then begin GetMem(buf, e_len+1); Move(p^.nested_map_key_ptr^, buf^, e_len); buf[e_len]:=#0; e^.scalar.value^.ptr:=buf; e^.scalar.value^.owned:=True; end else begin e^.scalar.value^.ptr:=p^.nested_map_key_ptr; e^.scalar.value^.owned:=False; end; e^.scalar.value^.len:=e_len; e^.scalar.anchor:=nil; e^.scalar.tag:=nil; e^.scalar.tag_implicit:=True;
                 p^.nested_map_started := True; p^.nested_map_expect_value := True;
               end;
             end else if p^.nested_map_expect_value then begin
               // 发出值（SCALAR），并预取下一对
               e^.event_type := FYET_SCALAR; GetMem(e^.scalar.value, SizeOf(TFyToken)); e^.scalar.value^.kind:=FYTK_SCALAR; e_len:=p^.nested_map_val_len; if (FYPCF_COPY_EVENT_TEXT in p^.flags) and (e_len>0) then begin GetMem(buf, e_len+1); Move(p^.nested_map_val_ptr^, buf^, e_len); buf[e_len]:=#0; e^.scalar.value^.ptr:=buf; e^.scalar.value^.owned:=True; end else begin e^.scalar.value^.ptr:=p^.nested_map_val_ptr; e^.scalar.value^.owned:=False; end; e^.scalar.value^.len:=e_len; e^.scalar.anchor:=nil; e^.scalar.tag:=nil; e^.scalar.tag_implicit:=True;
               if Parser_Token_ScanNextPair(p, p^.nested_map_key_ptr, p^.nested_map_key_len, p^.nested_map_val_ptr, p^.nested_map_val_len) then p^.nested_map_has_pair := True else p^.nested_map_has_pair := False;
               p^.nested_map_expect_value := False;
             end else begin
               // 准备下一轮：若还有 pair 则发键，否则结束嵌套映射并切回主映射
               if not p^.nested_map_has_pair then begin e^.event_type := FYET_MAPPING_END; p^.nested_map := False; emitted_nested_end := True; end
               else begin
                 e^.event_type := FYET_SCALAR; GetMem(e^.scalar.value, SizeOf(TFyToken)); e^.scalar.value^.kind:=FYTK_SCALAR; e^.scalar.value^.ptr:=p^.nested_map_key_ptr; e^.scalar.value^.len:=p^.nested_map_key_len; e^.scalar.anchor:=nil; e^.scalar.tag:=nil; e^.scalar.tag_implicit:=True;
                 p^.nested_map_expect_value := True;
               end;
             end;
           end
           else if p^.nested_seq then begin
             // 值是内嵌 flow 序列：按顺序发出其项与结束（项可为标量或内嵌容器）
             if not p^.nested_seq_started then begin
               if not p^.nested_seq_has_item then begin e^.event_type := FYET_SEQUENCE_END; p^.nested_seq := False; emitted_nested_end := True; end
               else begin
                 if p^.nested_seq_next_is_map then begin
                   // 序列项为内嵌映射：立即发 MAPPING_START，并初始化嵌套映射状态（置 started 避免二次发 START）
                   e^.event_type := FYET_MAPPING_START;
                   p^.nested_map := True; p^.nested_map_started := True; p^.nested_map_expect_value := False;
                   // 预取第一对 key:value，供下一轮 nested_map 分支发出键
                   if Parser_Token_ScanNextPair(p, p^.nested_map_key_ptr, p^.nested_map_key_len, p^.nested_map_val_ptr, p^.nested_map_val_len) then p^.nested_map_has_pair := True else p^.nested_map_has_pair := False;
                   // 转入映射处理后，清除标记
                   p^.nested_seq_next_is_map := False;
                   p^.nested_seq_started := True;
                 end else begin
                   e^.event_type := FYET_SCALAR; GetMem(e^.scalar.value, SizeOf(TFyToken)); e^.scalar.value^.kind:=FYTK_SCALAR; e_len:=p^.nested_seq_item_len; if (FYPCF_COPY_EVENT_TEXT in p^.flags) and (e_len>0) then begin GetMem(buf, e_len+1); Move(p^.nested_seq_item_ptr^, buf^, e_len); buf[e_len]:=#0; e^.scalar.value^.ptr:=buf; e^.scalar.value^.owned:=True; end else begin e^.scalar.value^.ptr:=p^.nested_seq_item_ptr; e^.scalar.value^.owned:=False; end; e^.scalar.value^.len:=e_len; e^.scalar.anchor:=nil; e^.scalar.tag:=nil; e^.scalar.tag_implicit:=True;
                   p^.nested_seq_started := True;
                   // 仅在标量项时预取下一项
                   if Parser_Token_ScanNextSeqItem(p, p^.nested_seq_item_ptr, p^.nested_seq_item_len) then p^.nested_seq_has_item:=True else p^.nested_seq_has_item:=False;
                 end;
               end;
             end else begin
               if not p^.nested_seq_has_item then begin e^.event_type := FYET_SEQUENCE_END; p^.nested_seq := False; emitted_nested_end := True; end
               else begin
                 if p^.nested_seq_next_is_map then begin
                   // 再次遇到内嵌映射作为项
                   e^.event_type := FYET_MAPPING_START;
                   p^.nested_map := True; p^.nested_map_started := False; p^.nested_map_expect_value := False;
                   if Parser_Token_ScanNextPair(p, p^.nested_map_key_ptr, p^.nested_map_key_len, p^.nested_map_val_ptr, p^.nested_map_val_len) then p^.nested_map_has_pair := True else p^.nested_map_has_pair := False;
                   p^.nested_seq_next_is_map := False; // 转入映射处理后，清除标记，待映射结束再拉取下一项
                 end else begin
                   e^.event_type := FYET_SCALAR; GetMem(e^.scalar.value, SizeOf(TFyToken)); e^.scalar.value^.kind:=FYTK_SCALAR; e_len:=p^.nested_seq_item_len; if (FYPCF_COPY_EVENT_TEXT in p^.flags) and (e_len>0) then begin GetMem(buf, e_len+1); Move(p^.nested_seq_item_ptr^, buf^, e_len); buf[e_len]:=#0; e^.scalar.value^.ptr:=buf; e^.scalar.value^.owned:=True; end else begin e^.scalar.value^.ptr:=p^.nested_seq_item_ptr; e^.scalar.value^.owned:=False; end; e^.scalar.value^.len:=e_len; e^.scalar.anchor:=nil; e^.scalar.tag:=nil; e^.scalar.tag_implicit:=True;
                   // 仅在标量项时预取下一项
                   if Parser_Token_ScanNextSeqItem(p, p^.nested_seq_item_ptr, p^.nested_seq_item_len) then p^.nested_seq_has_item:=True else p^.nested_seq_has_item:=False;
                 end;
               end;
             end;
           end
           else e^.event_type:=FYET_DOCUMENT_END;
         end;
    4: begin
         if p^.mapping then begin
           if not p^.has_pair then
             e^.event_type := FYET_MAPPING_END
           else begin
             // 嵌套值优先处理（flow 模式）：先发容器起止事件与内部项/对
             // 注意：若同时存在 nested_map 与 nested_seq，优先处理 nested_map，避免误发 SEQUENCE_END
             if p^.nested_map then begin
               if not p^.nested_map_started then begin
                 e^.event_type := FYET_MAPPING_START;
                 p^.nested_map_started := True;
                 p^.nested_map_expect_value := False; // 先发键
               end else if p^.nested_map_expect_value then begin
                 // 发值并预取嵌套下一对
                 e^.event_type:=FYET_SCALAR; GetMem(e^.scalar.value, SizeOf(TFyToken)); e^.scalar.value^.kind:=FYTK_SCALAR; e_len:=p^.nested_map_val_len; if (FYPCF_COPY_EVENT_TEXT in p^.flags) and (e_len>0) then begin GetMem(buf, e_len+1); Move(p^.nested_map_val_ptr^, buf^, e_len); buf[e_len]:=#0; e^.scalar.value^.ptr:=buf; e^.scalar.value^.owned:=True; end else begin e^.scalar.value^.ptr:=p^.nested_map_val_ptr; e^.scalar.value^.owned:=False; end; e^.scalar.value^.len:=e_len; e^.scalar.anchor:=nil; e^.scalar.tag:=nil; e^.scalar.tag_implicit:=True;
                 if Parser_Token_ScanNextPair(p, p^.nested_map_key_ptr, p^.nested_map_key_len, p^.nested_map_val_ptr, p^.nested_map_val_len) then p^.nested_map_has_pair := True else p^.nested_map_has_pair := False;
                 p^.nested_map_expect_value := False;
               end else begin
                 // 发键或结束嵌套映射
                 if not p^.nested_map_has_pair then begin
                   e^.event_type := FYET_MAPPING_END;
                   p^.nested_map := False;
                   emitted_nested_end := True;
                   // 若当前处于序列项上下文，则结束映射后预取序列下一项；否则预取父映射下一对
                   if p^.nested_seq then begin
                     if Parser_Token_ScanNextSeqItem(p, p^.nested_seq_item_ptr, p^.nested_seq_item_len) then p^.nested_seq_has_item:=True else p^.nested_seq_has_item:=False;
                   end else begin
                     if Parser_Token_ScanNextPair(p, p^.key_ptr, p^.key_len, p^.val_ptr, p^.val_len) then p^.has_pair := True else p^.has_pair := False;
                   end;
                 end else begin
                   e^.event_type:=FYET_SCALAR; GetMem(e^.scalar.value, SizeOf(TFyToken)); e^.scalar.value^.kind:=FYTK_SCALAR; e_len:=p^.nested_map_key_len; if (FYPCF_COPY_EVENT_TEXT in p^.flags) and (e_len>0) then begin GetMem(buf, e_len+1); Move(p^.nested_map_key_ptr^, buf^, e_len); buf[e_len]:=#0; e^.scalar.value^.ptr:=buf; e^.scalar.value^.owned:=True; end else begin e^.scalar.value^.ptr:=p^.nested_map_key_ptr; e^.scalar.value^.owned:=False; end; e^.scalar.value^.len:=e_len; e^.scalar.anchor:=nil; e^.scalar.tag:=nil; e^.scalar.tag_implicit:=True;
                   p^.nested_map_expect_value := True;
                 end;
               end;
             end else if p^.nested_seq then begin
               if not p^.nested_seq_started then begin
                 e^.event_type := FYET_SEQUENCE_START;
                 p^.nested_seq_started := True;
               end else if p^.nested_seq_has_item then begin
                 if p^.nested_seq_next_is_map then begin
                   e^.event_type := FYET_MAPPING_START;
                   // 初始化嵌套映射状态（置 started 避免二次发 START），并预取第一对
                   p^.nested_map := True; p^.nested_map_started := True; p^.nested_map_expect_value := False;
                   if Parser_Token_ScanNextPair(p, p^.nested_map_key_ptr, p^.nested_map_key_len, p^.nested_map_val_ptr, p^.nested_map_val_len) then p^.nested_map_has_pair := True else begin p^.nested_map_has_pair := False; ms := Parser_CurrentMark(p); me := ms; if (p^.tz<>nil) then begin ms.line := p^.tz^.line-1; ms.column := p^.tz^.col-1; if ms.column>0 then Dec(ms.column); end; Parser_DiagPushWithMark(p, FYET_INFO, FYEM_PARSE, Integer(FYDC_EMPTY_FLOW_MAPPING), 'empty/closed flow mapping', ms, me); end;
                   p^.nested_seq_next_is_map := False;
                 end else begin
                   e^.event_type:=FYET_SCALAR; GetMem(e^.scalar.value, SizeOf(TFyToken)); e^.scalar.value^.kind:=FYTK_SCALAR; e_len:=p^.nested_seq_item_len; if (FYPCF_COPY_EVENT_TEXT in p^.flags) and (e_len>0) then begin GetMem(buf, e_len+1); Move(p^.nested_seq_item_ptr^, buf^, e_len); buf[e_len]:=#0; e^.scalar.value^.ptr:=buf; e^.scalar.value^.owned:=True; end else begin e^.scalar.value^.ptr:=p^.nested_seq_item_ptr; e^.scalar.value^.owned:=False; end; e^.scalar.value^.len:=e_len; e^.scalar.anchor:=nil; e^.scalar.tag:=nil; e^.scalar.tag_implicit:=True;
                   // 仅标量项时拉取下一项
                   if Parser_Token_ScanNextSeqItem(p, p^.nested_seq_item_ptr, p^.nested_seq_item_len) then p^.nested_seq_has_item:=True else p^.nested_seq_has_item:=False;
                 end;
               end else begin
                 // 结束嵌套序列；若该序列作为映射值，则结束后预取父映射下一对
                 e^.event_type := FYET_SEQUENCE_END;
                 p^.nested_seq := False;
                 emitted_nested_end := True;
                 if p^.mapping then begin
                   if Parser_Token_ScanNextPair(p, p^.key_ptr, p^.key_len, p^.val_ptr, p^.val_len) then p^.has_pair := True else p^.has_pair := False;
                 end;
               end;
             end else begin
               // 常规：发 value 标量（非嵌套）
               if (p^.val_len=0) and (p^.scan_i>=p^.len) and p^.key_bol then begin
                 e^.event_type := FYET_MAPPING_END; p^.has_pair := False;
               end else begin
                 e^.event_type:=FYET_SCALAR; GetMem(e^.scalar.value, SizeOf(TFyToken)); e^.scalar.value^.kind:=FYTK_SCALAR; e_len:=p^.val_len; if (FYPCF_COPY_EVENT_TEXT in p^.flags) and (e_len>0) then begin GetMem(buf, e_len+1); Move(p^.val_ptr^, buf^, e_len); buf[e_len]:=#0; e^.scalar.value^.ptr:=buf; e^.scalar.value^.owned:=True; end else begin e^.scalar.value^.ptr:=p^.val_ptr; e^.scalar.value^.owned:=False; end; e^.scalar.value^.len:=e_len; e^.scalar.anchor:=nil; e^.scalar.tag:=nil; e^.scalar.tag_implicit:=True;
                 if p^.flow_map then begin
                   if Parser_Token_ScanNextPair(p, p^.key_ptr, p^.key_len, p^.val_ptr, p^.val_len) then p^.has_pair := True else p^.has_pair := False;
                 end else if Parser_Token_ScanNextPair_NonFlow(p, p^.key_ptr, p^.key_len, p^.val_ptr, p^.val_len, np) then begin
                   p^.has_pair := True; p^.scan_i := np;
                   if p^.key_ptr<>nil then begin
                     k := SizeUInt(p^.key_ptr - p^.input);
                     if (k>0) and (p^.input[k-1] in [#10,#13]) then p^.key_bol := True else p^.key_bol := False;
                   end else p^.key_bol := False;
                 end else p^.has_pair := False;
               end;
             end;
           end;
         end else if p^.sequence then begin
           if not p^.has_item then e^.event_type:=FYET_SEQUENCE_END
           else begin
             // 序列上下文下的项：支持内嵌映射或标量
             if p^.nested_map then begin
               if not p^.nested_map_started then begin
                 e^.event_type := FYET_MAPPING_START;
                 p^.nested_map_started := True;
                 p^.nested_map_expect_value := False;
               end else if p^.nested_map_expect_value then begin
                 e^.event_type:=FYET_SCALAR; GetMem(e^.scalar.value, SizeOf(TFyToken)); e^.scalar.value^.kind:=FYTK_SCALAR; e_len:=p^.nested_map_val_len; if (FYPCF_COPY_EVENT_TEXT in p^.flags) and (e_len>0) then begin GetMem(buf, e_len+1); Move(p^.nested_map_val_ptr^, buf^, e_len); buf[e_len]:=#0; e^.scalar.value^.ptr:=buf; e^.scalar.value^.owned:=True; end else begin e^.scalar.value^.ptr:=p^.nested_map_val_ptr; e^.scalar.value^.owned:=False; end; e^.scalar.value^.len:=e_len; e^.scalar.anchor:=nil; e^.scalar.tag:=nil; e^.scalar.tag_implicit:=True;
                 if Parser_Token_ScanNextPair(p, p^.nested_map_key_ptr, p^.nested_map_key_len, p^.nested_map_val_ptr, p^.nested_map_val_len) then p^.nested_map_has_pair := True else p^.nested_map_has_pair := False;
                 p^.nested_map_expect_value := False;
               end else begin
                 if not p^.nested_map_has_pair then begin
                   e^.event_type := FYET_MAPPING_END;
                   p^.nested_map := False;
                   // 结束映射项后，预取序列下一项
                   if Parser_Token_ScanNextSeqItem(p, p^.item_ptr, p^.item_len) then p^.has_item := True else p^.has_item := False;
                 end else begin
                   e^.event_type:=FYET_SCALAR; GetMem(e^.scalar.value, SizeOf(TFyToken)); e^.scalar.value^.kind:=FYTK_SCALAR; e_len:=p^.nested_map_key_len; if (FYPCF_COPY_EVENT_TEXT in p^.flags) and (e_len>0) then begin GetMem(buf, e_len+1); Move(p^.nested_map_key_ptr^, buf^, e_len); buf[e_len]:=#0; e^.scalar.value^.ptr:=buf; e^.scalar.value^.owned:=True; end else begin e^.scalar.value^.ptr:=p^.nested_map_key_ptr; e^.scalar.value^.owned:=False; end; e^.scalar.value^.len:=e_len; e^.scalar.anchor:=nil; e^.scalar.tag:=nil; e^.scalar.tag_implicit:=True;
                   p^.nested_map_expect_value := True;
                 end;
               end;
             end else if p^.nested_seq_next_is_map then begin
               e^.event_type := FYET_MAPPING_START;
               p^.nested_map := True; p^.nested_map_started := True; p^.nested_map_expect_value := False;
               if Parser_Token_ScanNextPair(p, p^.nested_map_key_ptr, p^.nested_map_key_len, p^.nested_map_val_ptr, p^.nested_map_val_len) then p^.nested_map_has_pair := True else p^.nested_map_has_pair := False;
               p^.nested_seq_next_is_map := False;
             end else begin
               // 标量项：发出并预取下一项
               e^.event_type:=FYET_SCALAR; GetMem(e^.scalar.value, SizeOf(TFyToken)); e^.scalar.value^.kind:=FYTK_SCALAR; e_len:=p^.item_len; if (FYPCF_COPY_EVENT_TEXT in p^.flags) and (e_len>0) then begin GetMem(buf, e_len+1); Move(p^.item_ptr^, buf^, e_len); buf[e_len]:=#0; e^.scalar.value^.ptr:=buf; e^.scalar.value^.owned:=True; end else begin e^.scalar.value^.ptr:=p^.item_ptr; e^.scalar.value^.owned:=False; end; e^.scalar.value^.len:=e_len; e^.scalar.anchor:=nil; e^.scalar.tag:=nil; e^.scalar.tag_implicit:=True;
               if Parser_Token_ScanNextSeqItem(p, p^.item_ptr, p^.item_len) then p^.has_item := True else p^.has_item := False;
             end;
           end;
         end else
           e^.event_type := FYET_STREAM_END;
       end;
    5: if p^.mapping then e^.event_type:=FYET_MAPPING_END
       else if p^.sequence then e^.event_type:=FYET_SEQUENCE_END
       else begin FreeMem(e); Exit(nil); end;
    6: e^.event_type:=FYET_DOCUMENT_END;
    7: e^.event_type:=FYET_STREAM_END;
  else FreeMem(e); Exit(nil); end;
  if p^.mapping then begin case p^.stage of
    2: p^.stage:=3; 3: if e^.event_type=FYET_MAPPING_END then begin p^.mapping:=False; p^.stage:=6; end else p^.stage:=4;
    4: begin
         if e^.event_type=FYET_MAPPING_END then begin
           if emitted_nested_end then begin
             // 嵌套容器结束
             if p^.nested_seq then begin
               // 若仍在处理嵌套序列的上下文，继续留在 stage=4 让序列分支发出后续（含 SEQUENCE_END）
               p^.stage := 4;
             end else begin
               // 非序列上下文：根据是否还有下一个 pair 决定回到键或收尾
               if p^.has_pair then p^.stage:=3 else p^.stage:=5;
             end;
           end else if (not p^.nested_map) and (not p^.nested_seq) then begin
             // 父映射结束
             p^.mapping:=False; p^.stage:=6;
           end else begin
             // 仍在嵌套容器中
             p^.stage := 4;
           end;
         end else if emitted_nested_end then begin
           if p^.has_pair then p^.stage:=3 else p^.stage:=5;
         end else if (p^.nested_map or p^.nested_seq) then p^.stage:=4
         else if p^.has_pair then p^.stage:=3 else p^.stage:=5;
       end;
    5: p^.stage:=6; 6: p^.stage:=7; 7: p^.stage:=8; else Inc(p^.stage); end;
  // 深度计数与上限检查（在发出事件前执行）
  if e<>nil then begin
    if (e^.event_type=FYET_MAPPING_START) or (e^.event_type=FYET_SEQUENCE_START) then begin
      Inc(p^.depth);
      if (p^.limits.max_depth>0) and (p^.depth>p^.limits.max_depth) then begin
        if (FYPCF_COLLECT_DIAG in p^.flags) then Parser_DiagPush(p, FYET_ERROR, FYEM_PARSE, Integer(FYDC_UNKNOWN), 'depth exceeds limit');
        if (FYPCF_STRICT_LIMITS in p^.flags) then begin yaml_impl_parser_event_free(fyp, e); Exit(nil); end;
      end;
    end;
    if (e^.event_type=FYET_MAPPING_END) or (e^.event_type=FYET_SEQUENCE_END) then begin
      if p^.depth>0 then Dec(p^.depth) else begin
        if (FYPCF_COLLECT_DIAG in p^.flags) then Parser_DiagPush(p, FYET_ERROR, FYEM_PARSE, Integer(FYDC_UNKNOWN), 'negative depth');
      end;
    end;
  end;

  // 统一标量长度阈值检查（在返回前执行，早于事件计数）
  if e<>nil then begin
    if (e^.event_type=FYET_SCALAR) and (e^.scalar.value<>nil) and (p^.limits.max_scalar_length>0) then
    begin
      if (e^.scalar.value^.len > SizeUInt(p^.limits.max_scalar_length)) then
      begin
        if (FYPCF_COLLECT_DIAG in p^.flags) then Parser_DiagPush(p, FYET_ERROR, FYEM_PARSE, Integer(FYDC_UNKNOWN), 'scalar length exceeds limit');
        if (FYPCF_STRICT_LIMITS in p^.flags) then begin yaml_impl_parser_event_free(fyp, e); Exit(nil); end;
      end;
    end;
  end;

  end else if p^.sequence then begin case p^.stage of
    2: p^.stage:=3; 3: if e^.event_type=FYET_SEQUENCE_END then begin p^.sequence:=False; p^.stage:=6; end else p^.stage:=4;
    4: if e^.event_type=FYET_SEQUENCE_END then begin p^.sequence:=False; p^.stage:=6; end else p^.stage:=3;
    5: p^.stage:=6; 6: p^.stage:=7; 7: p^.stage:=8; else Inc(p^.stage); end
  end else Inc(p^.stage);
  // 统一事件计数归口（成功生成事件时计数）
  if e<>nil then Inc(p^.event_count);
  // 统一记录/清理 last_event
  if e=nil then p^.last_event := nil else p^.last_event := e;
  Result:=e; end;

procedure yaml_impl_parser_event_free(fyp: PFyParser; fye: PFyEvent);
var p: PParserImpl;
begin
  if fyp<>nil then p := PParserImpl(fyp) else p := nil;
  if (p<>nil) and (p^.last_event=fye) then p^.last_event := nil;
  if fye=nil then Exit;
  if (fye^.event_type=FYET_SCALAR) and (fye^.scalar.value<>nil) then begin
    if fye^.scalar.value^.owned and (fye^.scalar.value^.ptr<>nil) then FreeMem(fye^.scalar.value^.ptr);
    FreeMem(fye^.scalar.value);
  end;
  FreeMem(fye);
end;

// 文档/节点/发射器（占位）
function yaml_impl_document_create(const cfg: PFyParseCfg): PFyDocument; begin Result:=nil; end;
procedure yaml_impl_document_destroy(fyd: PFyDocument); begin end;
function yaml_impl_document_build_from_string(const cfg: PFyParseCfg; const str: PChar; len: SizeUInt): PFyDocument; begin Result:=nil; end;
function yaml_impl_document_build_from_file(const cfg: PFyParseCfg; const filename: PChar): PFyDocument; var S:String; begin if filename=nil then Exit(nil); S:=String(filename); if not FileExists(S) then Exit(nil); Result:=nil; end;
function yaml_impl_document_get_root(fyd: PFyDocument): PFyNode; begin Result:=nil; end;

function yaml_impl_node_get_type(fyn: PFyNode): TFyNodeType; inline; begin Result:=FYNT_SCALAR; end;
function yaml_impl_node_get_scalar(fyn: PFyNode; len: PSizeUInt): PChar; inline; begin if len<>nil then len^:=0; Result:=nil; end;
function yaml_impl_node_get_scalar0(fyn: PFyNode): PChar; inline; begin Result:=nil; end;
function yaml_impl_node_sequence_item_count(fyn: PFyNode): Integer; inline; begin Result:=0; end;
function yaml_impl_node_sequence_get_by_index(fyn: PFyNode; index: Integer): PFyNode; inline; begin Result:=nil; end;
function yaml_impl_node_mapping_item_count(fyn: PFyNode): Integer; inline; begin Result:=0; end;
function yaml_impl_node_mapping_get_by_index(fyn: PFyNode; index: Integer): PFyNodePair; inline; begin Result:=nil; end;
function yaml_impl_node_mapping_lookup_by_string(fyn: PFyNode; const key: PChar; keylen: SizeUInt): PFyNode; inline; begin Result:=nil; end;
function yaml_impl_node_pair_key(fynp: PFyNodePair): PFyNode; inline; begin Result:=nil; end;
function yaml_impl_node_pair_value(fynp: PFyNodePair): PFyNode; inline; begin Result:=nil; end;

function yaml_impl_emitter_create(const cfg: PFyEmitCfg): PFyEmitter; inline; begin Result:=nil; end;
procedure yaml_impl_emitter_destroy(fye: PFyEmitter); inline; begin end;
function yaml_impl_emit_document(fyd: PFyDocument; const cfg: PFyEmitCfg; len: PSizeUInt): PChar; inline; begin if len<>nil then len^:=0; Result:=nil; end;

end.

