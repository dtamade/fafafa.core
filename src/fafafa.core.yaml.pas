unit fafafa.core.yaml;

{$MODE OBJFPC}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes, Variants,
  fafafa.core.base,
  fafafa.core.mem.allocator,
  // 引入类型与实现（现代门面导出）
  fafafa.core.yaml.types,
  fafafa.core.yaml.impl,
  fafafa.core.yaml.diag;

type
  // 对外公开使用 TYaml*/PYaml* 命名；内部核心类型仍为 TFy*/PFy*
  TYamlVersion = fafafa.core.yaml.types.TFyVersion;
  TYamlTag = fafafa.core.yaml.types.TFyTag;
  TYamlMark = fafafa.core.yaml.types.TFyMark;
  TYamlErrorType = fafafa.core.yaml.types.TFyErrorType;
  TYamlErrorModule = fafafa.core.yaml.types.TFyErrorModule;
  TYamlEventType = fafafa.core.yaml.types.TFyEventType;
  TYamlScalarStyle = fafafa.core.yaml.types.TFyScalarStyle;
  TYamlNodeType = fafafa.core.yaml.types.TFyNodeType;
  TYamlParseCfgFlags = fafafa.core.yaml.types.TFyParseCfgFlags;
  TYamlParseCfg = fafafa.core.yaml.types.TFyParseCfg;
  TYamlEmitCfgFlags = fafafa.core.yaml.types.TFyEmitCfgFlags;
  TYamlEmitCfg = fafafa.core.yaml.types.TFyEmitCfg;
  // 事件记录类型
  TYamlEvent = fafafa.core.yaml.types.TFyEvent;

  // 不透明指针类型 (对应 libfyaml 的 opaque types)
  PYamlToken = fafafa.core.yaml.types.PFyToken;
  PYamlDocumentState = fafafa.core.yaml.types.PFyDocumentState;
  PYamlParser = fafafa.core.yaml.types.PFyParser;
  PYamlEmitter = fafafa.core.yaml.types.PFyEmitter;
  PYamlDocument = fafafa.core.yaml.types.PFyDocument;
  PYamlNode = fafafa.core.yaml.types.PFyNode;
  PYamlNodePair = fafafa.core.yaml.types.PFyNodePair;
  PYamlAnchor = fafafa.core.yaml.types.PFyAnchor;
  PYamlParseCfg = fafafa.core.yaml.types.PFyParseCfg;
  PYamlEmitCfg = fafafa.core.yaml.types.PFyEmitCfg;

  PYamlDiag = fafafa.core.yaml.types.PFyDiag;
  PYamlEvent = fafafa.core.yaml.types.PFyEvent;
  PYamlVersion = fafafa.core.yaml.types.PFyVersion;
  // 新增：安全阈值与解析选项（向后兼容扩展）
  TYamlSafetyLimits = fafafa.core.yaml.types.TFySafetyLimits;
  PYamlSafetyLimits = fafafa.core.yaml.types.PFySafetyLimits;
  TYamlParserOptions = fafafa.core.yaml.types.TFyParserOptions;
  PYamlParserOptions = fafafa.core.yaml.types.PFyParserOptions;


// 常量门面导出（统一 yaml_* 前缀，对外不再暴露 fy_*）
const
  // 事件类型（TYamlEventType）
  YAML_ET_NONE           = fafafa.core.yaml.types.FYET_NONE;
  YAML_ET_STREAM_START   = fafafa.core.yaml.types.FYET_STREAM_START;
  YAML_ET_STREAM_END     = fafafa.core.yaml.types.FYET_STREAM_END;
  YAML_ET_DOCUMENT_START = fafafa.core.yaml.types.FYET_DOCUMENT_START;
  YAML_ET_DOCUMENT_END   = fafafa.core.yaml.types.FYET_DOCUMENT_END;
  YAML_ET_MAPPING_START  = fafafa.core.yaml.types.FYET_MAPPING_START;
  YAML_ET_MAPPING_END    = fafafa.core.yaml.types.FYET_MAPPING_END;
  YAML_ET_SEQUENCE_START = fafafa.core.yaml.types.FYET_SEQUENCE_START;
  YAML_ET_SEQUENCE_END   = fafafa.core.yaml.types.FYET_SEQUENCE_END;
  YAML_ET_SCALAR         = fafafa.core.yaml.types.FYET_SCALAR;
  YAML_ET_ALIAS          = fafafa.core.yaml.types.FYET_ALIAS;
  // 新增解析 flags 常量导出
  YAML_PCF_STRICT_LIMITS            = fafafa.core.yaml.types.FYPCF_STRICT_LIMITS;
  YAML_PCF_COMPAT_SEMICOLON_IN_SEQ  = fafafa.core.yaml.types.FYPCF_COMPAT_SEMICOLON_IN_SEQ;

  // 解析配置 flags（TYamlParseCfgFlags）
  YAML_PCF_QUIET             = fafafa.core.yaml.types.FYPCF_QUIET;
  YAML_PCF_COLLECT_DIAG      = fafafa.core.yaml.types.FYPCF_COLLECT_DIAG;
  YAML_PCF_RESOLVE_DOCUMENT  = fafafa.core.yaml.types.FYPCF_RESOLVE_DOCUMENT;
  YAML_PCF_COPY_EVENT_TEXT   = fafafa.core.yaml.types.FYPCF_COPY_EVENT_TEXT;


// 首选 API 前缀：yaml_
// 为兼容过渡期，仍保留 fy_ 前缀函数；推荐使用 yaml_*

// 版本函数（yaml_ 前缀）
function yaml_version_compare(const va, vb: PYamlVersion): Integer; inline;
function yaml_version_default: PYamlVersion; inline;
function yaml_version_is_supported(const vers: PYamlVersion): Boolean; inline;

// 解析器函数（yaml_ 前缀）
function yaml_parser_create(const cfg: PYamlParseCfg): PYamlParser; inline;
procedure yaml_parser_destroy(fyp: PYamlParser); inline;
function yaml_parser_set_string(fyp: PYamlParser; const str: PChar; len: SizeUInt): Integer; inline;
function yaml_parser_parse(fyp: PYamlParser): PYamlEvent; inline;
procedure yaml_parser_event_free(fyp: PYamlParser; fye: PYamlEvent); inline;

// 文档函数（yaml_ 前缀）
function yaml_document_create(const cfg: PYamlParseCfg): PYamlDocument; inline;
procedure yaml_document_destroy(fyd: PYamlDocument); inline;
function yaml_document_build_from_string(const cfg: PYamlParseCfg; const str: PChar; len: SizeUInt): PYamlDocument; inline;
function yaml_document_build_from_file(const cfg: PYamlParseCfg; const filename: PChar): PYamlDocument; inline;
function yaml_document_get_root(fyd: PYamlDocument): PYamlNode; inline;

// 节点函数（yaml_ 前缀）
function yaml_node_get_type(fyn: PYamlNode): TYamlNodeType; inline;
function yaml_node_get_scalar(fyn: PYamlNode; len: PSizeUInt): PChar; inline;
function yaml_node_get_scalar0(fyn: PYamlNode): PChar; inline;
function yaml_node_sequence_item_count(fyn: PYamlNode): Integer; inline;
function yaml_node_sequence_get_by_index(fyn: PYamlNode; index: Integer): PYamlNode; inline;
function yaml_node_mapping_item_count(fyn: PYamlNode): Integer; inline;
function yaml_node_mapping_get_by_index(fyn: PYamlNode; index: Integer): PYamlNodePair; inline;
function yaml_node_mapping_lookup_by_string(fyn: PYamlNode; const key: PChar; keylen: SizeUInt): PYamlNode; inline;
function yaml_node_pair_key(fynp: PYamlNodePair): PYamlNode; inline;

	// 解析器创建（扩展版，向后兼容）
	function yaml_parser_create_ex(const opts: PYamlParserOptions): PYamlParser; inline;

	// 安全阈值默认值/初始化（便于调用方快速采用 Safe 模式）
	procedure yaml_safety_limits_default(out s: TYamlSafetyLimits); inline;
	procedure yaml_parser_options_init_defaults(out o: TYamlParserOptions); inline;

function yaml_node_pair_value(fynp: PYamlNodePair): PYamlNode; inline;

// 发射器函数（yaml_ 前缀）
function yaml_emitter_create(const cfg: PYamlEmitCfg): PYamlEmitter; inline;
procedure yaml_emitter_destroy(fye: PYamlEmitter); inline;
function yaml_emit_document(fyd: PYamlDocument; const cfg: PYamlEmitCfg; len: PSizeUInt): PChar; inline;

// 工具函数（yaml_ 前缀）
function yaml_event_type_get_text(event_type: TYamlEventType): PChar; inline;
function yaml_event_data(fye: PYamlEvent): Pointer; inline;
function yaml_event_scalar_get_text(fye: PYamlEvent; len: PSizeUInt): PChar; inline;

	// 事件安全访问器（门面转发）
	function yaml_event_scalar_get_anchor(fye: PYamlEvent; len: PSizeUInt): PChar; inline;
	function yaml_event_scalar_get_tag(fye: PYamlEvent; len: PSizeUInt): PChar; inline;
	function yaml_event_scalar_tag_implicit(fye: PYamlEvent): Boolean; inline;
	function yaml_event_alias_get_anchor(fye: PYamlEvent; len: PSizeUInt): PChar; inline;
	function yaml_event_sequence_start_get_anchor(fye: PYamlEvent; len: PSizeUInt): PChar; inline;
	function yaml_event_sequence_start_get_tag(fye: PYamlEvent; len: PSizeUInt): PChar; inline;
	function yaml_event_mapping_start_get_anchor(fye: PYamlEvent; len: PSizeUInt): PChar; inline;
	function yaml_event_mapping_start_get_tag(fye: PYamlEvent; len: PSizeUInt): PChar; inline;



	// 诊断门面（最小集）
	// 回调类型（与 tests/helpers/yaml_diag_helper.pas 的 DiagCallback2 匹配）
	type TYamlDiagCallback = procedure(userdata: Pointer; code: TFyDiagCode; level: TYamlErrorType; module: TYamlErrorModule; line, col: SizeUInt; const msg: PChar); cdecl;
	function yaml_diag_create(userdata: Pointer = nil): PYamlDiag; inline; overload;
	function yaml_diag_create(cb: TYamlDiagCallback; userdata: Pointer = nil): PYamlDiag; inline; overload;

	procedure yaml_diag_destroy(p: PYamlDiag); inline;
	procedure yaml_diag_clear(p: PYamlDiag); inline;
	procedure yaml_diag_push(p: PYamlDiag; etype: TYamlErrorType; module: TYamlErrorModule;
	  code: Integer; const msg: PChar; const start_mark, end_mark: TYamlMark); inline;
	// 简单回调类型（不含 code）
	type TYamlDiagSimpleCallback = procedure(userdata: Pointer; level: TYamlErrorType; module: TYamlErrorModule; line, col: SizeUInt; const msg: PChar); cdecl;
	function yaml_diag_create(cb: TYamlDiagSimpleCallback; userdata: Pointer = nil): PYamlDiag; inline; overload;

	function yaml_diag_count(p: PYamlDiag): SizeInt; inline;

	// 扩展：带 code 的回调（测试辅助）
	function yaml_diag_create2(cb: TYamlDiagCallback; userdata: Pointer = nil): PYamlDiag; inline;

    // 扩展：带 end 位置信息的回调（测试辅助）
    type TYamlDiagCallbackEx = procedure(userdata: Pointer; code: TFyDiagCode; level: TYamlErrorType; module: TYamlErrorModule; line, col, line2, col2: SizeUInt; const msg: PChar); cdecl;
    function yaml_diag_create_ex(cb: TYamlDiagCallbackEx; userdata: Pointer = nil): PYamlDiag; inline;



// 对外导出诊断代码（门面别名）
const
  YAML_DC_UNKNOWN = Integer(fafafa.core.yaml.types.FYDC_UNKNOWN);
  YAML_DC_EMPTY_FLOW_SEQUENCE = Integer(fafafa.core.yaml.types.FYDC_EMPTY_FLOW_SEQUENCE);
  YAML_DC_EMPTY_FLOW_MAPPING  = Integer(fafafa.core.yaml.types.FYDC_EMPTY_FLOW_MAPPING);
  YAML_DC_UNEXPECTED_EOF      = Integer(fafafa.core.yaml.types.FYDC_UNEXPECTED_EOF);
  YAML_DC_UNTERMINATED_DQUOTE = Integer(fafafa.core.yaml.types.FYDC_UNTERMINATED_DQUOTE);
  YAML_DC_UNTERMINATED_SQUOTE = Integer(fafafa.core.yaml.types.FYDC_UNTERMINATED_SQUOTE);
  YAML_DC_UNTERMINATED_TAG    = Integer(fafafa.core.yaml.types.FYDC_UNTERMINATED_TAG);
  YAML_DC_TAG_PAYLOAD_COLON_RULE = Integer(fafafa.core.yaml.types.FYDC_TAG_PAYLOAD_COLON_RULE);
  YAML_DC_ILLEGAL_CONTROL_CHAR   = Integer(fafafa.core.yaml.types.FYDC_ILLEGAL_CONTROL_CHAR);



implementation

function yaml_event_scalar_get_anchor(fye: PYamlEvent; len: PSizeUInt): PChar; inline;
begin
  Result := fafafa.core.yaml.impl.yaml_impl_event_scalar_get_anchor(PFyEvent(fye), len);
end;

function yaml_event_scalar_get_tag(fye: PYamlEvent; len: PSizeUInt): PChar; inline;
begin
  Result := fafafa.core.yaml.impl.yaml_impl_event_scalar_get_tag(PFyEvent(fye), len);
end;

function yaml_event_scalar_tag_implicit(fye: PYamlEvent): Boolean; inline;
begin
  Result := fafafa.core.yaml.impl.yaml_impl_event_scalar_tag_implicit(PFyEvent(fye));
end;

function yaml_event_alias_get_anchor(fye: PYamlEvent; len: PSizeUInt): PChar; inline;
begin
  Result := fafafa.core.yaml.impl.yaml_impl_event_alias_get_anchor(PFyEvent(fye), len);
end;

function yaml_event_sequence_start_get_anchor(fye: PYamlEvent; len: PSizeUInt): PChar; inline;
begin
  Result := fafafa.core.yaml.impl.yaml_impl_event_sequence_start_get_anchor(PFyEvent(fye), len);
end;

function yaml_event_sequence_start_get_tag(fye: PYamlEvent; len: PSizeUInt): PChar; inline;
begin
  Result := fafafa.core.yaml.impl.yaml_impl_event_sequence_start_get_tag(PFyEvent(fye), len);
end;

// 诊断门面实现
function yaml_diag_create(userdata: Pointer): PYamlDiag; inline; overload;
begin
  Result := fafafa.core.yaml.diag.yaml_impl_diag_create(userdata);
end;

function yaml_diag_create(cb: TYamlDiagSimpleCallback; userdata: Pointer): PYamlDiag; inline; overload;
begin
  Result := fafafa.core.yaml.diag.yaml_impl_diag_create_with_simple(cb, userdata);
end;

function yaml_diag_create(cb: TYamlDiagCallback; userdata: Pointer): PYamlDiag; inline; overload;
begin
  Result := yaml_diag_create2(cb, userdata);
end;

procedure yaml_diag_destroy(p: PYamlDiag); inline;
begin
  fafafa.core.yaml.diag.yaml_impl_diag_destroy(p);
end;

procedure yaml_diag_clear(p: PYamlDiag); inline;
begin
  fafafa.core.yaml.diag.yaml_impl_diag_clear(p);
end;

procedure yaml_diag_push(p: PYamlDiag; etype: TYamlErrorType; module: TYamlErrorModule;
  code: Integer; const msg: PChar; const start_mark, end_mark: TYamlMark); inline;
begin
  fafafa.core.yaml.diag.yaml_impl_diag_push(PFyDiag(p), TFyErrorType(etype), TFyErrorModule(module), code, msg,
    TFyMark(start_mark), TFyMark(end_mark));
end;


function yaml_diag_create_ex(cb: TYamlDiagCallbackEx; userdata: Pointer): PYamlDiag; inline;
begin
  Result := fafafa.core.yaml.diag.yaml_impl_diag_create_with_code_ex(cb, userdata);
end;

function yaml_diag_create2(cb: TYamlDiagCallback; userdata: Pointer): PYamlDiag; inline;
begin
  Result := fafafa.core.yaml.diag.yaml_impl_diag_create_with_code(cb, userdata);
end;

function yaml_diag_count(p: PYamlDiag): SizeInt; inline;
begin
  Result := fafafa.core.yaml.diag.yaml_impl_diag_count(p);
end;


function yaml_event_mapping_start_get_anchor(fye: PYamlEvent; len: PSizeUInt): PChar; inline;
begin
  Result := fafafa.core.yaml.impl.yaml_impl_event_mapping_start_get_anchor(PFyEvent(fye), len);
end;

function yaml_event_mapping_start_get_tag(fye: PYamlEvent; len: PSizeUInt): PChar; inline;
begin
  Result := fafafa.core.yaml.impl.yaml_impl_event_mapping_start_get_tag(PFyEvent(fye), len);
end;


// 内联函数实现，直接转发到核心模块
// 直接转发到 yaml_impl_*（内部实现前缀）
function yaml_version_compare(const va, vb: PFyVersion): Integer; inline;
begin
  Result := fafafa.core.yaml.impl.yaml_impl_version_compare(va, vb);
end;

function yaml_version_default: PFyVersion; inline;
begin
  Result := fafafa.core.yaml.impl.yaml_impl_version_default;
end;

function yaml_version_is_supported(const vers: PFyVersion): Boolean; inline;
begin
  Result := fafafa.core.yaml.impl.yaml_impl_version_is_supported(vers);
end;

function yaml_parser_create(const cfg: PFyParseCfg): PFyParser; inline;
begin
  Result := fafafa.core.yaml.impl.yaml_impl_parser_create(cfg);
end;

procedure yaml_parser_destroy(fyp: PFyParser); inline;
begin
  fafafa.core.yaml.impl.yaml_impl_parser_destroy(fyp);
end;

function yaml_parser_set_string(fyp: PFyParser; const str: PChar; len: SizeUInt): Integer; inline;
begin
  Result := fafafa.core.yaml.impl.yaml_impl_parser_set_string(fyp, str, len);
end;

function yaml_parser_parse(fyp: PFyParser): PFyEvent; inline;
begin
  Result := fafafa.core.yaml.impl.yaml_impl_parser_parse(fyp);
end;

procedure yaml_parser_event_free(fyp: PFyParser; fye: PFyEvent); inline;
begin
  fafafa.core.yaml.impl.yaml_impl_parser_event_free(fyp, fye);
end;

function yaml_document_create(const cfg: PFyParseCfg): PFyDocument; inline;
begin
  Result := fafafa.core.yaml.impl.yaml_impl_document_create(cfg);
end;

procedure yaml_document_destroy(fyd: PFyDocument); inline;
begin
  fafafa.core.yaml.impl.yaml_impl_document_destroy(fyd);
end;

function yaml_document_build_from_string(const cfg: PFyParseCfg; const str: PChar; len: SizeUInt): PFyDocument; inline;
begin
  Result := fafafa.core.yaml.impl.yaml_impl_document_build_from_string(cfg, str, len);
end;

function yaml_document_build_from_file(const cfg: PFyParseCfg; const filename: PChar): PFyDocument; inline;
begin
  Result := fafafa.core.yaml.impl.yaml_impl_document_build_from_file(cfg, filename);
end;

function yaml_document_get_root(fyd: PFyDocument): PFyNode; inline;
begin
  Result := fafafa.core.yaml.impl.yaml_impl_document_get_root(fyd);
end;

function yaml_node_get_type(fyn: PFyNode): TFyNodeType; inline;
begin
  Result := fafafa.core.yaml.impl.yaml_impl_node_get_type(fyn);
end;

function yaml_node_get_scalar(fyn: PFyNode; len: PSizeUInt): PChar; inline;
begin
  Result := fafafa.core.yaml.impl.yaml_impl_node_get_scalar(fyn, len);
end;

function yaml_node_get_scalar0(fyn: PFyNode): PChar; inline;
begin
  Result := fafafa.core.yaml.impl.yaml_impl_node_get_scalar0(fyn);
end;

function yaml_node_sequence_item_count(fyn: PFyNode): Integer; inline;
begin
  Result := fafafa.core.yaml.impl.yaml_impl_node_sequence_item_count(fyn);
end;

function yaml_node_sequence_get_by_index(fyn: PFyNode; index: Integer): PFyNode; inline;
begin
  Result := fafafa.core.yaml.impl.yaml_impl_node_sequence_get_by_index(fyn, index);
end;






function yaml_node_mapping_item_count(fyn: PFyNode): Integer;
begin
  Result := fafafa.core.yaml.impl.yaml_impl_node_mapping_item_count(fyn);
end;
function yaml_node_mapping_get_by_index(fyn: PFyNode; index: Integer): PFyNodePair;
begin
  Result := fafafa.core.yaml.impl.yaml_impl_node_mapping_get_by_index(fyn, index);
end;
function yaml_node_mapping_lookup_by_string(fyn: PFyNode; const key: PChar; keylen: SizeUInt): PFyNode;
begin
  Result := fafafa.core.yaml.impl.yaml_impl_node_mapping_lookup_by_string(fyn, key, keylen);
end;
function yaml_node_pair_key(fynp: PFyNodePair): PFyNode;
begin
  Result := fafafa.core.yaml.impl.yaml_impl_node_pair_key(fynp);
end;
function yaml_node_pair_value(fynp: PFyNodePair): PFyNode;
begin
  Result := fafafa.core.yaml.impl.yaml_impl_node_pair_value(fynp);
end;

function yaml_emitter_create(const cfg: PFyEmitCfg): PFyEmitter;
begin
  Result := fafafa.core.yaml.impl.yaml_impl_emitter_create(cfg);
end;
procedure yaml_emitter_destroy(fye: PFyEmitter);
begin
  fafafa.core.yaml.impl.yaml_impl_emitter_destroy(fye);
end;
function yaml_emit_document(fyd: PFyDocument; const cfg: PFyEmitCfg; len: PSizeUInt): PChar;
begin
  Result := fafafa.core.yaml.impl.yaml_impl_emit_document(fyd, cfg, len);
end;




function yaml_event_scalar_get_text(fye: PYamlEvent; len: PSizeUInt): PChar; inline;
begin
  Result := fafafa.core.yaml.impl.yaml_impl_event_scalar_get_text(PFyEvent(fye), len);
end;

function yaml_event_type_get_text(event_type: TFyEventType): PChar; inline;
var s: PChar;
begin

  // 显式赋初值，避免编译器对不可达路径的误判
  s := nil;
  s := fafafa.core.yaml.impl.yaml_impl_event_type_get_text(event_type);
  Result := s;
end;

function yaml_parser_create_ex(const opts: PYamlParserOptions): PYamlParser; inline;
begin
  Result := fafafa.core.yaml.impl.yaml_impl_parser_create_ex(PFyParserOptions(opts));
end;

procedure yaml_safety_limits_default(out s: TYamlSafetyLimits); inline;
begin
  s.max_depth := 100;
  s.max_nodes := 200000;
  s.max_alias_expansion := 1000000;
  s.max_scalar_length := 1024*1024;
  s.max_tag_length := 256;
  s.max_anchors := 10000;
  s.max_document_size_bytes := 100*1024*1024;
end;

procedure yaml_parser_options_init_defaults(out o: TYamlParserOptions); inline;
begin
  FillChar(o, SizeOf(o), 0);
  o.cfg.search_path := nil;
  o.cfg.flags := [];
  o.cfg.userdata := nil;
  o.cfg.diag := nil;
  yaml_safety_limits_default(o.safety);
end;


function yaml_event_data(fye: PFyEvent): Pointer; inline;
var p: Pointer;
begin
  // 显式赋初值，避免编译器对不可达路径的误判
  p := nil;
  p := fafafa.core.yaml.impl.yaml_impl_event_data(fye);
  Result := p;
end;

end.
