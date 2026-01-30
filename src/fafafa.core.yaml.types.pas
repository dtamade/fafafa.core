unit fafafa.core.yaml.types;
{
  本单元为内部类型定义（与 libfyaml 源码结构对齐）。
  - 请通过门面单元 `fafafa.core.yaml` 访问对外 API（yaml_* / TYaml* / YAML_*）。
  - 直接依赖 TFy*/PFy* 仅用于内部实现层；对外不承诺兼容。
}


{$MODE OBJFPC}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils;

type
  // 基础/不透明类型（与 libfyaml 对齐的 Pascal 映射）
  TFyVersion = record
    major: Integer;
    minor: Integer;
  end;
  PFyVersion = ^TFyVersion;

  TFyTag = record
    handle: PChar;
    prefix: PChar;
  end;

  TFyMark = record
    input_pos: SizeUInt;
    line: Integer;   // 0-based
    column: Integer; // 0-based
  end;

  TFyErrorType = (
    FYET_DEBUG,
    FYET_INFO,
    FYET_NOTICE,
    FYET_WARNING,
    FYET_ERROR,
    FYET_MAX
  );

  TFyErrorModule = (
    FYEM_UNKNOWN,
    FYEM_ATOM,
    FYEM_SCAN,
    FYEM_PARSE,
    FYEM_DOC,
    FYEM_BUILD,
    FYEM_INTERNAL,
    FYEM_SYSTEM,
    FYEM_MAX
  );

  // 事件类型
  TFyEventType = (
    FYET_NONE,
    FYET_STREAM_START,
    FYET_STREAM_END,
    FYET_DOCUMENT_START,
    FYET_DOCUMENT_END,
    FYET_MAPPING_START,
    FYET_MAPPING_END,
    FYET_SEQUENCE_START,
    FYET_SEQUENCE_END,
    FYET_SCALAR,
    FYET_ALIAS
  );

  // 标量样式
  TFyScalarStyle = (
    FYSS_ANY = -1,
    FYSS_PLAIN,
    FYSS_SINGLE_QUOTED,
    FYSS_DOUBLE_QUOTED,
    FYSS_LITERAL,
    FYSS_FOLDED,
    FYSS_MAX
  );

  // 节点类型（占位）
  TFyNodeType = (
    FYNT_SCALAR,
    FYNT_SEQUENCE,
    FYNT_MAPPING
  );

  // 诊断代码（最小集，按需扩展）
  TFyDiagCode = (
    FYDC_UNKNOWN,
    FYDC_EMPTY_FLOW_SEQUENCE,
    FYDC_EMPTY_FLOW_MAPPING,
    FYDC_UNEXPECTED_EOF,
    FYDC_UNTERMINATED_DQUOTE,
    FYDC_UNTERMINATED_SQUOTE,
    FYDC_UNTERMINATED_TAG,
    FYDC_TAG_PAYLOAD_COLON_RULE,
    FYDC_ILLEGAL_CONTROL_CHAR
  );

  // 解析配置 flags（最小子集，按需扩展）
  TFyParseCfgFlag = (
    FYPCF_QUIET,
    FYPCF_COLLECT_DIAG,
    FYPCF_RESOLVE_DOCUMENT,
    FYPCF_COPY_EVENT_TEXT,
    // 严格限制：超限立即报错终止
    FYPCF_STRICT_LIMITS,
    // 兼容选项：允许 ';' 作为序列分隔（默认关闭）
    FYPCF_COMPAT_SEMICOLON_IN_SEQ
  );
  TFyParseCfgFlags = set of TFyParseCfgFlag;

  // 发射配置 flags（最小子集，按需扩展）
  TFyEmitCfgFlag = (
    FYECF_SORT_KEYS,
    FYECF_OUTPUT_COMMENTS
  );
  TFyEmitCfgFlags = set of TFyEmitCfgFlag;

  // Token（最小实现）
  TFyTokenKind = (
    FYTK_UNKNOWN,
    FYTK_SCALAR,
    // flow symbols
    FYTK_LBRACKET,   // [
    FYTK_RBRACKET,   // ]
    FYTK_LBRACE,     // {
    FYTK_RBRACE,     // }
    FYTK_COLON,      // :
    FYTK_COMMA,      // ,
    FYTK_SEMICOLON,  // ;
    // anchors/tags (占位)
    FYTK_ANCHOR,      // &name
    FYTK_ALIAS,       // *name
    FYTK_TAG          // !tag or !!tag
  );
  TFyToken = record
    kind: TFyTokenKind;
    ptr: PChar;
    len: SizeUInt;
    refs: Integer; // 简单引用计数（用于 fy_token_ref/unref）
    owned: Boolean; // 是否由当前事件拥有，释放事件时需要释放 ptr
  end;
  PFyToken = ^TFyToken;

  // 不透明类型声明
  TFyDocumentState = record end; PFyDocumentState = ^TFyDocumentState;
  TFyParser = record end; PFyParser = ^TFyParser;
  TFyEmitter = record end; PFyEmitter = ^TFyEmitter;
  TFyDocument = record end; PFyDocument = ^TFyDocument;
  TFyNode = record end; PFyNode = ^TFyNode;
  TFyNodePair = record end; PFyNodePair = ^TFyNodePair;
  TFyAnchor = record end; PFyAnchor = ^TFyAnchor;
  TFyDiag = record end; PFyDiag = ^TFyDiag;

  // 解析/发射配置
  PFyParseCfg = ^TFyParseCfg;
  TFyParseCfg = record
    search_path: PChar;     // ':' 分隔的搜索路径
    flags: TFyParseCfgFlags;
    userdata: Pointer;
    diag: PFyDiag;
  end;

  PFyEmitCfg = ^TFyEmitCfg;
  TFyEmitCfg = record
    flags: TFyEmitCfgFlags;
    indent: Integer; // 默认2
    width: Integer;  // 默认80
    userdata: Pointer;
    diag: PFyDiag;
  end;

  // 安全阈值与解析选项（用于门面新增的安全模式与便捷创建）
  PFySafetyLimits = ^TFySafetyLimits;
  TFySafetyLimits = record
    // 解析深度（映射/序列嵌套）
    max_depth: Integer;                 // 默认 100
    // 节点/事件等总体数量上限（防止退化/恶意输入）
    max_nodes: Integer;                 // 默认 200000
    // 别名展开上限（YAML anchor/alias）
    max_alias_expansion: Int64;         // 默认 1000000
    // 单个标量/标签/锚点长度上限
    max_scalar_length: Integer;         // 默认 1*1024*1024
    max_tag_length: Integer;            // 默认 256
    max_anchors: Integer;               // 默认 10000
    // 单文档最大字节数（针对从流/文件读取的场景；字符串输入可忽略）
    max_document_size_bytes: Int64;     // 默认 100*1024*1024
  end;

  PFyParserOptions = ^TFyParserOptions;
  TFyParserOptions = record
    // 复用现有底层配置（诊断/flags/搜索路径等）
    cfg: TFyParseCfg;
    // 安全阈值（可选，若全部为 0 视为采用库默认）
    safety: TFySafetyLimits;
  end;


  // 事件负载数据结构
  TFyEventStreamStartData = record
    stream_start: PFyToken;
  end;
  TFyEventStreamEndData = record
    stream_end: PFyToken;
  end;
  TFyEventDocumentStartData = record
    document_start: PFyToken;        // 可为 nil 表示隐式
    document_state: PFyDocumentState; // 可为 nil
    implicit: Boolean;
  end;
  TFyEventDocumentEndData = record
    document_end: PFyToken; // 可为 nil 表示隐式
    implicit: Boolean;
  end;
  TFyEventAliasData = record
    anchor: PFyToken;
  end;
  TFyEventScalarData = record
    anchor: PFyToken;  // 可为 nil
    tag: PFyToken;     // 可为 nil
    value: PFyToken;   // 不能为 nil（在真实实现中）
    tag_implicit: Boolean;
  end;
  TFyEventSequenceStartData = record
    anchor: PFyToken;       // 可为 nil
    tag: PFyToken;          // 可为 nil
    sequence_start: PFyToken; // 可为 nil 表示隐式
  end;
  TFyEventSequenceEndData = record
    sequence_end: PFyToken; // 可为 nil 表示隐式
  end;
  TFyEventMappingStartData = record
    anchor: PFyToken;       // 可为 nil
    tag: PFyToken;          // 可为 nil
    mapping_start: PFyToken; // 可为 nil 表示隐式
  end;
  TFyEventMappingEndData = record
    mapping_end: PFyToken;  // 可为 nil 表示隐式
  end;

  // 事件结构（变体记录）
  PFyEvent = ^TFyEvent;
  TFyEvent = record
    event_type: TFyEventType;
    case Integer of
      0: (stream_start: TFyEventStreamStartData);
      1: (stream_end: TFyEventStreamEndData);
      2: (document_start: TFyEventDocumentStartData);
      3: (document_end: TFyEventDocumentEndData);
      4: (alias: TFyEventAliasData);
      5: (scalar: TFyEventScalarData);
      6: (sequence_start: TFyEventSequenceStartData);
      7: (sequence_end: TFyEventSequenceEndData);
      8: (mapping_start: TFyEventMappingStartData);
      9: (mapping_end: TFyEventMappingEndData);
  end;

implementation

end.

