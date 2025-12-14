{**
 * fafafa.core.json - 高性能 JSON 解析器
 * 严格按照 yyjson 源码移植到 FreePascal
 *
 * 基于 yyjson (https://github.com/ibireme/yyjson)
 * 版权所有 (c) 2020 YaoYuan <ibireme@gmail.com>
 * 移植到 FreePascal by fafafa.collections5
 *}
unit fafafa.core.json.core;

{$MODE OBJFPC}{$H+}
{$MODESWITCH ADVANCEDRECORDS}
{$MODESWITCH TYPEHELPERS}

{$I fafafa.core.settings.inc}
interface

uses
  SysUtils, Classes, fafafa.core.math,
  fafafa.core.mem.allocator;

// 字符常量 (严格对应 yyjson)
const
  CHAR_TAB = 9;
  CHAR_LF = 10;
  CHAR_CR = 13;
  CHAR_SPACE = 32;
  CHAR_QUOTE = 34;  // '"'
  CHAR_PLUS = 43;   // '+'
  CHAR_COMMA = 44;  // ','
  CHAR_MINUS = 45;  // '-'
  CHAR_DOT = 46;    // '.'
  CHAR_SLASH = 47;  // '/'
  CHAR_0 = 48;      // '0'
  CHAR_9 = 57;      // '9'
  CHAR_COLON = 58;  // ':'
  CHAR_E_UPPER = 69; // 'E'
  CHAR_LBRACKET = 91;  // '['
  CHAR_BACKSLASH = 92; // '\'
  CHAR_RBRACKET = 93;  // ']'
  CHAR_A_LOWER = 97;   // 'a'
  CHAR_E_LOWER = 101;  // 'e'
  CHAR_F_LOWER = 102;  // 'f'
  CHAR_N_LOWER = 110;  // 'n'
  CHAR_R_LOWER = 114;  // 'r'
  CHAR_T_LOWER = 116;  // 't'
  CHAR_U_LOWER = 117;  // 'u'
  CHAR_LBRACE = 123;   // '{'
  CHAR_RBRACE = 125;   // '}'

  // 字符类型常量 (严格对应 yyjson char_table)
  CHAR_TYPE_SPACE     = UInt8(1 shl 0);  // 空白字符
  CHAR_TYPE_NUMBER    = UInt8(1 shl 1);  // 数字字符
  CHAR_TYPE_ESC_ASCII = UInt8(1 shl 2);  // 转义字符
  CHAR_TYPE_NON_ASCII = UInt8(1 shl 3);  // 非ASCII字符
  CHAR_TYPE_CONTAINER = UInt8(1 shl 4);  // 容器字符
  CHAR_TYPE_COMMENT   = UInt8(1 shl 5);  // 注释字符
  CHAR_TYPE_LINE_END  = UInt8(1 shl 6);  // 行结束字符
  CHAR_TYPE_HEX       = UInt8(1 shl 7);  // 十六进制字符

  // JSON 类型常量 (严格对应 yyjson)
  YYJSON_TYPE_NONE = UInt8(0);
  YYJSON_TYPE_RAW  = UInt8(1);
  YYJSON_TYPE_NULL = UInt8(2);
  YYJSON_TYPE_BOOL = UInt8(3);
  YYJSON_TYPE_NUM  = UInt8(4);
  YYJSON_TYPE_STR  = UInt8(5);
  YYJSON_TYPE_ARR  = UInt8(6);
  YYJSON_TYPE_OBJ  = UInt8(7);

  // JSON 子类型常量 (严格对应 yyjson)
  YYJSON_SUBTYPE_NONE = UInt8(0 shl 3);
  YYJSON_SUBTYPE_FALSE = UInt8(0 shl 3);
  YYJSON_SUBTYPE_TRUE = UInt8(1 shl 3);
  YYJSON_SUBTYPE_UINT = UInt8(0 shl 3);
  YYJSON_SUBTYPE_SINT = UInt8(1 shl 3);
  YYJSON_SUBTYPE_REAL = UInt8(2 shl 3);

  // JSON 标签位掩码 (严格对应 yyjson)
  YYJSON_TYPE_MASK = UInt8($07);
  YYJSON_SUBTYPE_MASK = UInt8($18);
  // Strictly follow yyjson.h: NOESC is (1 << 3)
  YYJSON_SUBTYPE_NOESC = UInt8(1 shl 3);

  // 标签位常量
  YYJSON_TAG_BIT = UInt8(8);
  YYJSON_TAG_MASK = UInt8($FF);  // 低8位掩码

  // 浮点数常量
  F64_POW10_EXP_MAX_EXACT = 22;

  // 解析器常量 (严格对应 yyjson)
  YYJSON_READER_ESTIMATED_MINIFY_RATIO = 4;

type
  // JSON 值类型枚举
  TJsonValueType = (
    jvtNone,
    jvtRaw,
    jvtNull,
    jvtBoolean,
    jvtNumber,
    jvtString,
    jvtArray,
    jvtObject
  );

  // JSON 读取标志
  TJsonReadFlags = set of (
    jrfDefault,
    jrfAllowComments,
    jrfAllowTrailingCommas,
    jrfAllowInfAndNan,
    jrfNumberAsRaw,
    jrfBignumAsRaw,
    jrfAllowInvalidUnicode,
    jrfAllowBOM,
    jrfStopWhenDone
  );

  // JSON 写入标志 (严格对应 yyjson_write_flag)
  TJsonWriteFlags = set of (
    jwfDefault,
    jwfPretty,
    jwfEscapeUnicode,
    jwfEscapeSlashes,
    jwfAllowInfAndNan,
    jwfInfAndNanAsNull,
    jwfAllowInvalidUnicode
  );

  // JSON 写入错误代码 (严格对应 yyjson_write_code)
  TJsonWriteErrorCode = (
    jwecSuccess = 0,
    jwecInvalidParameter,
    jwecMemoryAllocation,
    jwecInvalidValueType,
    jwecNanOrInf,
    jwecFileOpenError,
    jwecFileWriteError
  );

  // JSON 值数据联合体
  TJsonValueData = record
    case Integer of
      0: (U64: UInt64);
      1: (I64: Int64);
      2: (F64: Double);
      3: (Str: PChar);
      4: (Ptr: Pointer);
  end;

  // JSON 值结构 (严格对应 yyjson_val)
  TJsonValue = record
    Tag: UInt64;           // 类型和长度信息
    Data: TJsonValueData;  // 值数据
  end;
  PJsonValue = ^TJsonValue;

  // JSON 文档
  TJsonDocument = class
  private
    FRoot: PJsonValue;
    FAllocator: IAllocator;
    FBytesRead: SizeUInt;
    FValuesRead: SizeUInt;
    FValueBuffer: PJsonValue;  // 指向分配的值缓冲区开始位置
    FInputBuffer: PByte;       // 解析时复制的可写输入缓冲区
  public
    constructor Create(AAllocator: IAllocator);
    destructor Destroy; override;

    property Root: PJsonValue read FRoot;
    property Allocator: IAllocator read FAllocator;
    property BytesRead: SizeUInt read FBytesRead;
    property ValuesRead: SizeUInt read FValuesRead;
  end;

// 字符类型检查函数 (严格对应 yyjson)
function CharIsSpace(C: Byte): Boolean; inline;
function CharIsDigit(C: Byte): Boolean; inline;
threadvar
  JsonGlobalReadFlags: TJsonReadFlags;
  JsonPendingInvalidComment: Boolean;

  // 资源限额（由门面注入；0 表示不限制）
  JsonMaxDepth: SizeUInt;
  JsonMaxValues: SizeUInt;
  JsonMaxStringBytes: SizeUInt;
  JsonMaxDocBytes: SizeUInt;

function CharIsHex(C: Byte): Boolean; inline;
function CharIsContainer(C: Byte): Boolean; inline;
function CharIsNum(C: Byte): Boolean; inline;

// Unsafe 函数 (严格对应 yyjson unsafe 函数)
function UnsafeGetType(AVal: PJsonValue): UInt8; inline;
function UnsafeGetTag(AVal: PJsonValue): UInt8; inline;
function UnsafeGetLen(AVal: PJsonValue): SizeUInt; inline;
function UnsafeSetLen(AVal: PJsonValue; ALen: SizeUInt): SizeUInt; inline;
function UnsafeGetFirst(ACtn: PJsonValue): PJsonValue; inline;
function UnsafeGetNext(AVal: PJsonValue): PJsonValue; inline;
function UnsafeIsCtn(AVal: PJsonValue): Boolean; inline;
function UnsafeIsNull(AVal: PJsonValue): Boolean; inline;
function UnsafeIsBool(AVal: PJsonValue): Boolean; inline;
function UnsafeIsTrue(AVal: PJsonValue): Boolean; inline;
function UnsafeIsFalse(AVal: PJsonValue): Boolean; inline;
function UnsafeIsNum(AVal: PJsonValue): Boolean; inline;
function UnsafeIsStr(AVal: PJsonValue): Boolean; inline;
function UnsafeIsArr(AVal: PJsonValue): Boolean; inline;
function UnsafeIsObj(AVal: PJsonValue): Boolean; inline;
function UnsafeArrIsFlat(AVal: PJsonValue): Boolean; inline;
function UnsafeEqualsStrN(AVal: PJsonValue; const AStr: PChar; ALen: SizeUInt): Boolean; inline;
function UnsafeIsUInt(AVal: PJsonValue): Boolean; inline;
function UnsafeIsSInt(AVal: PJsonValue): Boolean; inline;
function UnsafeIsReal(AVal: PJsonValue): Boolean; inline;
function UnsafeGetUInt(AVal: PJsonValue): UInt64; inline;
function UnsafeGetSInt(AVal: PJsonValue): Int64; inline;
function UnsafeGetReal(AVal: PJsonValue): Double; inline;
function UnsafeGetStr(AVal: PJsonValue): PChar; inline;


  // 空白与注释跳过（支持 jrfAllowComments）
  procedure SkipComments(var ACur: PByte; AEnd: PByte); inline;

  procedure SkipSpaces(var ACur: PByte; AEnd: PByte; Flags: TJsonReadFlags); inline;

// 字面量读取函数
function ReadTrue(var ACur: PByte; AVal: PJsonValue): Boolean;
function ReadFalse(var ACur: PByte; AVal: PJsonValue): Boolean;
function ReadNull(var ACur: PByte; AVal: PJsonValue): Boolean;
function ReadInfOrNan(var ACur: PByte; AEnd: PByte; AFlags: TJsonReadFlags; ANegative: Boolean; AVal: PJsonValue): Boolean;
function ReadNumberRaw(var ACur: PByte; AEnd: PByte; AVal: PJsonValue): Boolean;

// 完整解析函数
function ReadStr(var ACur: PByte; AEnd: PByte; AVal: PJsonValue; var AMsg: String): Boolean;
function ReadNum(var ACur: PByte; AEnd: PByte; AFlags: TJsonReadFlags; AVal: PJsonValue; var AMsg: String): Boolean;

// JSON 错误代码 (严格对应 yyjson_read_err)
type
  TJsonErrorCode = (
    jecSuccess,
    jecInvalidParameter,
    jecMemoryAllocation,
    jecEmptyContent,
    jecUnexpectedContent,
    jecUnexpectedEnd,
    jecUnexpectedCharacter,
    jecJsonStructure,
    jecInvalidComment,
    jecInvalidNumber,
    jecInvalidString,
    jecInvalidLiteral,
    jecFileOpenError,
    jecFileReadError,
    jecMore
  );

  TJsonError = record
    Code: TJsonErrorCode;
    Message: String;
    Position: SizeUInt;
  end;







  // JSON 写入错误信息 (严格对应 yyjson_write_err)
  TJsonWriteError = record
    Code: TJsonWriteErrorCode;
    Message: String;
  end;

  // JSON Pointer 错误代码 (严格对应 yyjson_ptr_code)
  TJsonPointerErrorCode = (
    jpecNone = 0,
    jpecParameter,
    jpecSyntax,
    jpecResolve,
    jpecNullRoot,
    jpecSetRoot,
    jpecMemoryAllocation
  );

  // JSON Pointer 错误信息 (严格对应 yyjson_ptr_err)
  TJsonPointerError = record
    Code: TJsonPointerErrorCode;
    Message: String;
    Position: SizeUInt;
  end;

  // 可变 JSON 值 (严格对应 yyjson_mut_val)
  PJsonMutValue = ^TJsonMutValue;
  TJsonMutValue = record
    Tag: UInt64;     // 类型和长度信息
    Data: TJsonValueData;  // 值数据
    Next: PJsonMutValue;   // 下一个值 (用于链表)
  end;

  // 可变 JSON 文档 (严格对应 yyjson_mut_doc)
  TJsonMutDocument = class
  private
    FRoot: PJsonMutValue;
    FAllocator: IAllocator;
    FValueCount: SizeUInt;
  public
    constructor Create(AAllocator: IAllocator);
    destructor Destroy; override;

    property Root: PJsonMutValue read FRoot write FRoot;
    property Allocator: IAllocator read FAllocator;
    property ValueCount: SizeUInt read FValueCount write FValueCount;
  end;

  // JSON Pointer 上下文 (严格对应 yyjson_ptr_ctx)
  TJsonPointerContext = record
    Container: PJsonMutValue;  // 目标值的容器 (父级)
    Previous: PJsonMutValue;   // 容器中的前一个值
    Old: PJsonMutValue;        // 被移除的旧值
  end;

// 文档解析函数 (严格对应 yyjson)
function ReadRootSingle(AHdr, ACur, AEnd: PByte; AAlc: IAllocator;
  AFlg: TJsonReadFlags; var AErr: TJsonError): TJsonDocument;
function ReadRootMinify(AHdr, ACur, AEnd: PByte; AAlc: IAllocator;
  AFlg: TJsonReadFlags; var AErr: TJsonError): TJsonDocument;

// JSON 序列化函数 (严格对应 yyjson 写入器)
function WriteJsonValue(AVal: PJsonValue; AFlags: TJsonWriteFlags; AIndent: Integer): String;
function WriteJsonString(const AStr: PChar; ALen: SizeUInt; AFlags: TJsonWriteFlags): String;
function WriteJsonNumber(AVal: PJsonValue; AFlags: TJsonWriteFlags): String;

// 数组迭代器 (严格对应 yyjson_arr_iter)
type
  TJsonArrayIterator = record
    Idx: SizeUInt;
    Max: SizeUInt;
    Cur: PJsonValue;
  end;
  PJsonArrayIterator = ^TJsonArrayIterator;

// 对象迭代器 (严格对应 yyjson_obj_iter)
  TJsonObjectIterator = record
    Idx: SizeUInt;
    Max: SizeUInt;
    Cur: PJsonValue;
    Obj: PJsonValue;
  end;
  PJsonObjectIterator = ^TJsonObjectIterator;

// 数组操作 API (严格对应 yyjson 数组 API)
function JsonArrSize(AArr: PJsonValue): SizeUInt; inline;
function JsonArrGet(AArr: PJsonValue; AIdx: SizeUInt): PJsonValue; inline;
function JsonArrGetFirst(AArr: PJsonValue): PJsonValue; inline;
function JsonArrGetLast(AArr: PJsonValue): PJsonValue; inline;

// 数组迭代器 API
function JsonArrIterInit(AArr: PJsonValue; AIter: PJsonArrayIterator): Boolean; inline;
function JsonArrIterHasNext(AIter: PJsonArrayIterator): Boolean; inline;
function JsonArrIterNext(AIter: PJsonArrayIterator): PJsonValue; inline;

// 对象操作 API (严格对应 yyjson 对象 API)
function JsonObjSize(AObj: PJsonValue): SizeUInt; inline;
function JsonObjGet(AObj: PJsonValue; const AKey: PChar): PJsonValue; inline;
function JsonObjGetN(AObj: PJsonValue; const AKey: PChar; AKeyLen: SizeUInt): PJsonValue; inline;

// 对象迭代器 API
function JsonObjIterInit(AObj: PJsonValue; AIter: PJsonObjectIterator): Boolean; inline;
function JsonObjIterHasNext(AIter: PJsonObjectIterator): Boolean; inline;
function JsonObjIterNext(AIter: PJsonObjectIterator): PJsonValue; inline;
function JsonObjIterGetVal(AKey: PJsonValue): PJsonValue; inline;

// 文档管理 API (严格对应 yyjson_doc_* 函数)
function JsonDocGetRoot(ADoc: TJsonDocument): PJsonValue; inline;
function JsonDocGetReadSize(ADoc: TJsonDocument): SizeUInt; inline;
function JsonDocGetValCount(ADoc: TJsonDocument): SizeUInt; inline;
procedure JsonDocFree(ADoc: TJsonDocument); inline;

// 值类型检查 API (严格对应 yyjson_is_* 函数)
function JsonIsRaw(AVal: PJsonValue): Boolean; inline;
function JsonIsNull(AVal: PJsonValue): Boolean; inline;
function JsonIsTrue(AVal: PJsonValue): Boolean; inline;
function JsonIsFalse(AVal: PJsonValue): Boolean; inline;
function JsonIsBool(AVal: PJsonValue): Boolean; inline;
function JsonIsUint(AVal: PJsonValue): Boolean; inline;
function JsonIsSint(AVal: PJsonValue): Boolean; inline;
function JsonIsInt(AVal: PJsonValue): Boolean; inline;
function JsonIsReal(AVal: PJsonValue): Boolean; inline;
function JsonIsNum(AVal: PJsonValue): Boolean; inline;
function JsonIsStr(AVal: PJsonValue): Boolean; inline;
function JsonIsArr(AVal: PJsonValue): Boolean; inline;
function JsonIsObj(AVal: PJsonValue): Boolean; inline;
function JsonIsCtn(AVal: PJsonValue): Boolean; inline;

// 值内容访问 API (严格对应 yyjson_get_* 函数)
function JsonGetType(AVal: PJsonValue): UInt8; inline;
function JsonGetSubtype(AVal: PJsonValue): UInt8; inline;
function JsonGetTag(AVal: PJsonValue): UInt8; inline;
function JsonGetTypeDesc(AVal: PJsonValue): String; inline;
function JsonGetRaw(AVal: PJsonValue): PChar; inline;
function JsonGetBool(AVal: PJsonValue): Boolean; inline;
function JsonGetUint(AVal: PJsonValue): UInt64; inline;
function JsonGetSint(AVal: PJsonValue): Int64; inline;
function JsonGetInt(AVal: PJsonValue): Integer; inline;
function JsonGetReal(AVal: PJsonValue): Double; inline;
function JsonGetNum(AVal: PJsonValue): Double; inline;
function JsonGetStr(AVal: PJsonValue): PChar; inline;
function JsonGetLen(AVal: PJsonValue): SizeUInt; inline;
function JsonEqualsStr(AVal: PJsonValue; const AStr: PChar): Boolean; inline;
function JsonEqualsStrN(AVal: PJsonValue; const AStr: PChar; ALen: SizeUInt): Boolean; inline;


  // UTF-8 friendly getters/comparers to avoid codepage ambiguity
  function JsonGetStrUtf8(AVal: PJsonValue): UTF8String; inline;
  function JsonEqualsStrUtf8(AVal: PJsonValue; const S: UTF8String): Boolean; inline;

// 高级读取器 API (严格对应 yyjson_read_* 函数)
function JsonRead(const AData: PChar; ALen: SizeUInt; AFlags: TJsonReadFlags): TJsonDocument; inline;
function JsonReadOpts(const AData: PChar; ALen: SizeUInt; AFlags: TJsonReadFlags;
  AAllocator: TAllocator; var AError: TJsonError): TJsonDocument; inline;
function JsonReadFile(const APath: String; AFlags: TJsonReadFlags;
  AAllocator: IAllocator; var AError: TJsonError): TJsonDocument; inline;
function JsonReadMaxMemoryUsage(ALen: SizeUInt; AFlags: TJsonReadFlags): SizeUInt; inline;
function JsonReadNumber(const AData: PChar; ALen: SizeUInt): Double; inline;



// 写入器 API (严格对应 yyjson_write_* 函数)
function JsonWrite(ADoc: TJsonDocument; AFlags: TJsonWriteFlags; var ALen: SizeUInt): PChar;
function JsonWrite(ADoc: TJsonDocument; out ALen: SizeUInt): PChar; inline; // 便捷重载，默认 flags=[]
function JsonWriteToString(ADoc: TJsonDocument; AFlags: TJsonWriteFlags = []): String; inline;
function JsonWriteOpts(ADoc: TJsonDocument; AFlags: TJsonWriteFlags; AAllocator: TAllocator;
  var ALen: SizeUInt; var AError: TJsonWriteError): PChar;
function JsonWriteFile(const APath: String; ADoc: TJsonDocument; AFlags: TJsonWriteFlags;
  AAllocator: IAllocator; var AError: TJsonWriteError): Boolean;


function JsonWriteNumber(AVal: PJsonValue; ABuf: PChar): PChar;
// 新增：直接写入到流的高效写入器，避免构造整块字符串
function JsonWriteToStream(ADoc: TJsonDocument; AStream: TStream; AFlags: TJsonWriteFlags = []): Boolean;

// 可变文档 API (严格对应 yyjson_mut_doc_* 函数)
function JsonMutDocNew(AAllocator: IAllocator): TJsonMutDocument;
procedure JsonMutDocFree(ADoc: TJsonMutDocument);
function JsonMutDocGetRoot(ADoc: TJsonMutDocument): PJsonMutValue;
procedure JsonMutDocSetRoot(ADoc: TJsonMutDocument; ARoot: PJsonMutValue);

// 可变值创建 API (严格对应 yyjson_mut_* 函数)
function JsonMutNull(ADoc: TJsonMutDocument): PJsonMutValue;
function JsonMutTrue(ADoc: TJsonMutDocument): PJsonMutValue;
function JsonMutFalse(ADoc: TJsonMutDocument): PJsonMutValue;
function JsonMutBool(ADoc: TJsonMutDocument; AVal: Boolean): PJsonMutValue;
function JsonMutUint(ADoc: TJsonMutDocument; AVal: UInt64): PJsonMutValue;
function JsonMutSint(ADoc: TJsonMutDocument; AVal: Int64): PJsonMutValue;
function JsonMutInt(ADoc: TJsonMutDocument; AVal: Integer): PJsonMutValue;
function JsonMutReal(ADoc: TJsonMutDocument; AVal: Double): PJsonMutValue;
function JsonMutStr(ADoc: TJsonMutDocument; const AVal: String): PJsonMutValue;
function JsonMutStrN(ADoc: TJsonMutDocument; const AVal: PChar; ALen: SizeUInt): PJsonMutValue;

// 可变容器创建 API (严格对应 yyjson_mut_arr/obj 函数)
function JsonMutArr(ADoc: TJsonMutDocument): PJsonMutValue;
function JsonMutObj(ADoc: TJsonMutDocument): PJsonMutValue;

// 可变数组迭代器 (严格对应 yyjson_mut_arr_iter)
type
  TJsonMutArrayIterator = record
    Idx: SizeUInt;
    Max: SizeUInt;
    Cur: PJsonMutValue;
    Pre: PJsonMutValue;
    Arr: PJsonMutValue;
  end;
  PJsonMutArrayIterator = ^TJsonMutArrayIterator;

// 可变数组操作 API (严格对应 yyjson_mut_arr_* 函数)
function JsonMutArrSize(AArr: PJsonMutValue): SizeUInt;
function JsonMutArrGet(AArr: PJsonMutValue; AIdx: SizeUInt): PJsonMutValue;
function JsonMutArrGetFirst(AArr: PJsonMutValue): PJsonMutValue;
function JsonMutArrGetLast(AArr: PJsonMutValue): PJsonMutValue;

// 可变数组迭代器 API
function JsonMutArrIterInit(AArr: PJsonMutValue; AIter: PJsonMutArrayIterator): Boolean;
function JsonMutArrIterHasNext(AIter: PJsonMutArrayIterator): Boolean;
function JsonMutArrIterNext(AIter: PJsonMutArrayIterator): PJsonMutValue;
function JsonMutArrIterRemove(AIter: PJsonMutArrayIterator): PJsonMutValue;

// 可变数组修改 API
function JsonMutArrInsert(AArr: PJsonMutValue; AVal: PJsonMutValue; AIdx: SizeUInt): Boolean;
function JsonMutArrAppend(AArr: PJsonMutValue; AVal: PJsonMutValue): Boolean;
function JsonMutArrPrepend(AArr: PJsonMutValue; AVal: PJsonMutValue): Boolean;
function JsonMutArrReplace(AArr: PJsonMutValue; AIdx: SizeUInt; AVal: PJsonMutValue): PJsonMutValue;
function JsonMutArrRemove(AArr: PJsonMutValue; AIdx: SizeUInt): PJsonMutValue;
function JsonMutArrRemoveFirst(AArr: PJsonMutValue): PJsonMutValue;
function JsonMutArrRemoveLast(AArr: PJsonMutValue): PJsonMutValue;
function JsonMutArrClear(AArr: PJsonMutValue): Boolean;

// 可变对象迭代器 (严格对应 yyjson_mut_obj_iter)
type
  TJsonMutObjectIterator = record
    Idx: SizeUInt;
    Max: SizeUInt;
    Cur: PJsonMutValue;
    Pre: PJsonMutValue;
    Obj: PJsonMutValue;
  end;
  PJsonMutObjectIterator = ^TJsonMutObjectIterator;

// 可变对象操作 API (严格对应 yyjson_mut_obj_* 函数)
function JsonMutObjSize(AObj: PJsonMutValue): SizeUInt;
function JsonMutObjGet(AObj: PJsonMutValue; const AKey: PChar): PJsonMutValue;
function JsonMutObjGetN(AObj: PJsonMutValue; const AKey: PChar; AKeyLen: SizeUInt): PJsonMutValue;

// 可变对象迭代器 API
function JsonMutObjIterInit(AObj: PJsonMutValue; AIter: PJsonMutObjectIterator): Boolean;
function JsonMutObjIterHasNext(AIter: PJsonMutObjectIterator): Boolean;
function JsonMutObjIterNext(AIter: PJsonMutObjectIterator): PJsonMutValue;
function JsonMutObjIterGetVal(AKey: PJsonMutValue): PJsonMutValue;
function JsonMutObjIterRemove(AIter: PJsonMutObjectIterator): PJsonMutValue;
function JsonMutObjIterGet(AIter: PJsonMutObjectIterator; const AKey: PChar): PJsonMutValue;
function JsonMutObjIterGetN(AIter: PJsonMutObjectIterator; const AKey: PChar; AKeyLen: SizeUInt): PJsonMutValue;

// 可变对象修改 API
function JsonMutObjAdd(AObj: PJsonMutValue; AKey: PJsonMutValue; AVal: PJsonMutValue): Boolean;
function JsonMutObjPut(AObj: PJsonMutValue; AKey: PJsonMutValue; AVal: PJsonMutValue): Boolean;
function JsonMutObjInsert(AObj: PJsonMutValue; AKey: PJsonMutValue; AVal: PJsonMutValue; AIdx: SizeUInt): Boolean;
function JsonMutObjRemove(AObj: PJsonMutValue; AKey: PJsonMutValue): PJsonMutValue;
function JsonMutObjRemoveKey(AObj: PJsonMutValue; const AKey: PChar): PJsonMutValue;
function JsonMutObjRemoveKeyN(AObj: PJsonMutValue; const AKey: PChar; AKeyLen: SizeUInt): PJsonMutValue;
function JsonMutObjClear(AObj: PJsonMutValue): Boolean;
function JsonMutObjReplace(AObj: PJsonMutValue; AKey: PJsonMutValue; AVal: PJsonMutValue): Boolean;

// 可变数组便利 API (严格对应 yyjson_mut_arr_add_* 函数)
function JsonMutArrAddVal(AArr: PJsonMutValue; AVal: PJsonMutValue): Boolean;
function JsonMutArrAddNull(ADoc: TJsonMutDocument; AArr: PJsonMutValue): Boolean;
function JsonMutArrAddTrue(ADoc: TJsonMutDocument; AArr: PJsonMutValue): Boolean;
function JsonMutArrAddFalse(ADoc: TJsonMutDocument; AArr: PJsonMutValue): Boolean;
function JsonMutArrAddBool(ADoc: TJsonMutDocument; AArr: PJsonMutValue; AVal: Boolean): Boolean;
function JsonMutArrAddUint(ADoc: TJsonMutDocument; AArr: PJsonMutValue; ANum: UInt64): Boolean;
function JsonMutArrAddSint(ADoc: TJsonMutDocument; AArr: PJsonMutValue; ANum: Int64): Boolean;
function JsonMutArrAddInt(ADoc: TJsonMutDocument; AArr: PJsonMutValue; ANum: Int64): Boolean;
function JsonMutArrAddReal(ADoc: TJsonMutDocument; AArr: PJsonMutValue; ANum: Double): Boolean;
function JsonMutArrAddStr(ADoc: TJsonMutDocument; AArr: PJsonMutValue; const AStr: String): Boolean;
function JsonMutArrAddStrN(ADoc: TJsonMutDocument; AArr: PJsonMutValue; const AStr: PChar; ALen: SizeUInt): Boolean;
function JsonMutArrAddArr(ADoc: TJsonMutDocument; AArr: PJsonMutValue): PJsonMutValue;
function JsonMutArrAddObj(ADoc: TJsonMutDocument; AArr: PJsonMutValue): PJsonMutValue;

// 可变对象便利 API (严格对应 yyjson_mut_obj_add_* 函数)
function JsonMutObjAddVal(ADoc: TJsonMutDocument; AObj: PJsonMutValue; const AKey: String; AVal: PJsonMutValue): Boolean;
function JsonMutObjAddNull(ADoc: TJsonMutDocument; AObj: PJsonMutValue; const AKey: String): Boolean;
function JsonMutObjAddTrue(ADoc: TJsonMutDocument; AObj: PJsonMutValue; const AKey: String): Boolean;
function JsonMutObjAddFalse(ADoc: TJsonMutDocument; AObj: PJsonMutValue; const AKey: String): Boolean;
function JsonMutObjAddBool(ADoc: TJsonMutDocument; AObj: PJsonMutValue; const AKey: String; AVal: Boolean): Boolean;
function JsonMutObjAddUint(ADoc: TJsonMutDocument; AObj: PJsonMutValue; const AKey: String; ANum: UInt64): Boolean;
function JsonMutObjAddSint(ADoc: TJsonMutDocument; AObj: PJsonMutValue; const AKey: String; ANum: Int64): Boolean;
function JsonMutObjAddInt(ADoc: TJsonMutDocument; AObj: PJsonMutValue; const AKey: String; ANum: Int64): Boolean;
function JsonMutObjAddReal(ADoc: TJsonMutDocument; AObj: PJsonMutValue; const AKey: String; ANum: Double): Boolean;
function JsonMutObjAddStr(ADoc: TJsonMutDocument; AObj: PJsonMutValue; const AKey: String; const AVal: String): Boolean;
function JsonMutObjAddStrN(ADoc: TJsonMutDocument; AObj: PJsonMutValue; const AKey: String; const AVal: PChar; ALen: SizeUInt): Boolean;
function JsonMutObjAddArr(ADoc: TJsonMutDocument; AObj: PJsonMutValue; const AKey: String): PJsonMutValue;
function JsonMutObjAddObj(ADoc: TJsonMutDocument; AObj: PJsonMutValue; const AKey: String): PJsonMutValue;

// 第八阶段：JSON Pointer API (将在后续版本中实现)
// 当前专注于已验证的核心功能



var
  // 字符类型表 (严格对应 yyjson char_table[256])
  CharTable: array[0..255] of UInt8;

  // 浮点数 pow10 表
  F64Pow10Table: array[0..F64_POW10_EXP_MAX_EXACT] of Double;



implementation

const
  ERR_DOC_TOO_LARGE    = 'Document too large';
  ERR_STRING_TOO_LONG  = 'String too long';
  ERR_MAX_DEPTH        = 'Max depth exceeded';
  ERR_MAX_VALUES       = 'Max values exceeded';

// 统一错误消息常量，避免散落硬编码导致不一致
const
  ERR_UNEXPECTED_END = 'Unexpected end of data';
  ERR_UNEXPECTED_VALUE = 'Unexpected character, expected a JSON value';
  ERR_UNEXPECTED_CONTENT = 'Unexpected content after document';
  // 次常用错误消息常量（仅整合重复文案，不更改措辞或语义）
  ERR_INVALID_NULL  = 'Invalid null literal';
  ERR_INVALID_TRUE  = 'Invalid true literal';
  ERR_INVALID_FALSE = 'Invalid false literal';
  ERR_INVALID_NUM   = 'Invalid number';
  ERR_INVALID_INFNAN = 'Invalid -inf/nan literal';
  ERR_EXPECT_KEY    = 'Unexpected character, expected a string key';
  ERR_EXPECT_COLON  = 'Unexpected character, expected '':'' after key';
  // ERR_TRAILING_COMMA = 'Trailing comma is not allowed'; // unused consolidated message
  ERR_UNCLOSED_ML_COMMENT = 'Unclosed multiline comment';
  ERR_INVALID_NUM_FMT = 'Invalid number format';
  ERR_INVALID_NUM_LEADING_ZERO = 'Invalid number with leading zero';

  ERR_INVALID_INFNAN_LITERAL = 'Invalid inf/nan literal';
  ERR_DECIMAL_NEEDS_DIGITS = 'Decimal point must be followed by digits';
  ERR_INCOMPLETE_EXPONENT = 'Incomplete exponent';
  ERR_EXPONENT_NEEDS_DIGITS = 'Exponent must have digits';
  ERR_BOM_NOT_SUPPORTED = 'UTF-8 byte order mark (BOM) is not supported';
  ERR_INPUT_EMPTY = 'input data is empty';
  ERR_INVALID_INPUT_DATA = 'Invalid input data';
  ERR_INVALID_ALLOCATOR = 'Invalid allocator';
  ERR_EMPTY_FILE_PATH = 'Empty file path';
  ERR_DOC_NULL = 'Document is null';
  // ERR_INVALID_INCR_PARAMS = 'invalid incr params'; // unused consolidated message



function ReadNumberRaw(var ACur: PByte; AEnd: PByte; AVal: PJsonValue): Boolean;
var

  p: PByte;
begin
  p := ACur;
  if (p < AEnd) and (p^ = CHAR_MINUS) then Inc(p);
  if (p < AEnd) and (p^ = CHAR_0) then Inc(p) else while (p < AEnd) and (p^ >= CHAR_0) and (p^ <= CHAR_9) do Inc(p);
  if (p < AEnd) and (p^ = CHAR_DOT) then begin Inc(p); while (p < AEnd) and (p^ >= CHAR_0) and (p^ <= CHAR_9) do Inc(p); end;
  if (p < AEnd) and ((p^ = CHAR_E_LOWER) or (p^ = CHAR_E_UPPER)) then begin Inc(p); if (p < AEnd) and ((p^ = CHAR_PLUS) or (p^ = CHAR_MINUS)) then Inc(p); while (p < AEnd) and (p^ >= CHAR_0) and (p^ <= CHAR_9) do Inc(p); end;
  AVal^.Tag := (UInt64(p - ACur) shl YYJSON_TAG_BIT) or YYJSON_TYPE_RAW;
  AVal^.Data.Str := PChar(ACur);
  ACur := p;
  Result := True;
end;

procedure SkipSpaces(var ACur: PByte; AEnd: PByte; Flags: TJsonReadFlags);
var
  AllowComments: Boolean;
begin
  AllowComments := (jrfAllowComments in Flags);
  while (ACur < AEnd) do begin
    while (ACur < AEnd) and CharIsSpace(ACur^) do Inc(ACur);
    if (ACur >= AEnd) then Exit;
    if AllowComments and (ACur^ = CHAR_SLASH) and (ACur + 1 < AEnd) then begin
      if ((ACur + 1)^ = CHAR_SLASH) or ((ACur + 1)^ = Ord('*')) then begin
        SkipComments(ACur, AEnd);
        if (ACur >= AEnd) and AllowComments then begin
          // 注释未闭合：采用与 yyjson 一致的消息
          ACur := AEnd; Exit;
        end;
        Continue;
      end;
    end;
    Break;
  end;
end;


procedure SkipComments(var ACur: PByte; AEnd: PByte);
begin
  while (ACur + 1 < AEnd) and (ACur^ = CHAR_SLASH) do begin
    if ((ACur + 1)^ = CHAR_SLASH) then begin
      Inc(ACur, 2);
      while (ACur < AEnd) do begin
        if (ACur^ in [CHAR_LF, CHAR_CR]) then begin Inc(ACur); Break; end;
        if (ACur + 1 < AEnd) and (ACur^ = Ord('\')) and ((ACur + 1)^ = Ord('n')) then begin Inc(ACur, 2); Break; end;
        Inc(ACur);
      end;
    end else if ((ACur + 1)^ = Ord('*')) then begin
      Inc(ACur, 2);
      while (ACur + 1 < AEnd) and not ((ACur^ = Ord('*')) and ((ACur + 1)^ = CHAR_SLASH)) do Inc(ACur);
      if (ACur + 1 < AEnd) then Inc(ACur, 2) else begin
        // 未关闭的多行注释
        JsonPendingInvalidComment := True;
        Exit; // 交由调用者在适当位置判错
      end;
    end else Break;
    while (ACur < AEnd) and CharIsSpace(ACur^) do Inc(ACur);
  end;
end;


// 字符类型检查函数实现
function CharIsSpace(C: Byte): Boolean; inline;
begin
  Result := (CharTable[C] and CHAR_TYPE_SPACE) <> 0;
end;

function CharIsDigit(C: Byte): Boolean; inline;
begin
  Result := (C >= CHAR_0) and (C <= CHAR_9);
end;

function CharIsHex(C: Byte): Boolean; inline;
begin
  Result := (CharTable[C] and CHAR_TYPE_HEX) <> 0;
end;

function CharIsContainer(C: Byte): Boolean; inline;
begin
  Result := (CharTable[C] and CHAR_TYPE_CONTAINER) <> 0;
end;

function CharIsNum(C: Byte): Boolean; inline;
begin
  Result := (CharTable[C] and CHAR_TYPE_NUMBER) <> 0;
end;

// Unsafe 函数实现
function UnsafeGetType(AVal: PJsonValue): UInt8; inline;
begin
  Result := UInt8(AVal^.Tag) and YYJSON_TYPE_MASK;
end;

function UnsafeGetTag(AVal: PJsonValue): UInt8; inline;
begin
  Result := UInt8(AVal^.Tag);
end;

function UnsafeIsNull(AVal: PJsonValue): Boolean; inline;
begin
  Result := UnsafeGetType(AVal) = YYJSON_TYPE_NULL;
end;

function UnsafeIsBool(AVal: PJsonValue): Boolean; inline;
begin
  Result := UnsafeGetType(AVal) = YYJSON_TYPE_BOOL;
end;

function UnsafeIsTrue(AVal: PJsonValue): Boolean; inline;
begin
  Result := UnsafeGetTag(AVal) = (YYJSON_TYPE_BOOL or YYJSON_SUBTYPE_TRUE);
end;

function UnsafeIsFalse(AVal: PJsonValue): Boolean; inline;
begin
  Result := UnsafeGetTag(AVal) = (YYJSON_TYPE_BOOL or YYJSON_SUBTYPE_FALSE);
end;

function UnsafeIsNum(AVal: PJsonValue): Boolean; inline;
begin
  Result := UnsafeGetType(AVal) = YYJSON_TYPE_NUM;
end;

function UnsafeIsStr(AVal: PJsonValue): Boolean; inline;
begin
  Result := UnsafeGetType(AVal) = YYJSON_TYPE_STR;
end;

function UnsafeIsArr(AVal: PJsonValue): Boolean; inline;
begin
  Result := UnsafeGetType(AVal) = YYJSON_TYPE_ARR;
end;

function UnsafeIsObj(AVal: PJsonValue): Boolean; inline;
begin
  Result := UnsafeGetType(AVal) = YYJSON_TYPE_OBJ;
end;

// 关键的 Unsafe 函数实现 (严格对应 yyjson)
function UnsafeGetLen(AVal: PJsonValue): SizeUInt; inline;
begin
  Result := SizeUInt(AVal^.Tag shr YYJSON_TAG_BIT);
end;

function UnsafeSetLen(AVal: PJsonValue; ALen: SizeUInt): SizeUInt; inline;
begin
  AVal^.Tag := (AVal^.Tag and YYJSON_TAG_MASK) or (UInt64(ALen) shl YYJSON_TAG_BIT);
  Result := ALen;
end;

function UnsafeGetFirst(ACtn: PJsonValue): PJsonValue; inline;
begin
  Result := ACtn + 1;
end;

function UnsafeGetNext(AVal: PJsonValue): PJsonValue; inline;
var
  LIsCtn: Boolean;
  LCtnOfs: SizeUInt;
  LOfs: SizeUInt;
begin
  LIsCtn := UnsafeIsCtn(AVal);
  if LIsCtn then
  begin
    LCtnOfs := AVal^.Data.U64; // 容器的偏移量存储在 Data 中
    LOfs := LCtnOfs;
  end
  else
    LOfs := SizeOf(TJsonValue);
  Result := PJsonValue(PByte(AVal) + LOfs);
end;

function UnsafeIsCtn(AVal: PJsonValue): Boolean; inline;
var
  LType: UInt8;
begin
  LType := UnsafeGetType(AVal);
  Result := (LType = YYJSON_TYPE_ARR) or (LType = YYJSON_TYPE_OBJ);
end;

function UnsafeArrIsFlat(AVal: PJsonValue): Boolean; inline;
var
  LOfs: SizeUInt;
  LLen: SizeUInt;
begin
  LOfs := AVal^.Data.U64;
  LLen := UnsafeGetLen(AVal);
  Result := LLen * SizeOf(TJsonValue) + SizeOf(TJsonValue) = LOfs;
end;

function UnsafeEqualsStrN(AVal: PJsonValue; const AStr: PChar; ALen: SizeUInt): Boolean; inline;


begin
  Result := (UnsafeGetLen(AVal) = ALen) and (CompareMem(AVal^.Data.Str, AStr, ALen));
end;

function UnsafeIsUInt(AVal: PJsonValue): Boolean; inline;
begin
  Result := (UnsafeGetTag(AVal) and YYJSON_TAG_MASK) = (YYJSON_TYPE_NUM or YYJSON_SUBTYPE_UINT);
end;

function UnsafeIsSInt(AVal: PJsonValue): Boolean; inline;
begin
  Result := (UnsafeGetTag(AVal) and YYJSON_TAG_MASK) = (YYJSON_TYPE_NUM or YYJSON_SUBTYPE_SINT);
end;

function UnsafeIsReal(AVal: PJsonValue): Boolean; inline;
begin
  Result := (UnsafeGetTag(AVal) and YYJSON_TAG_MASK) = (YYJSON_TYPE_NUM or YYJSON_SUBTYPE_REAL);
end;

function UnsafeGetUInt(AVal: PJsonValue): UInt64; inline;
begin
  Result := AVal^.Data.U64;
end;

function UnsafeGetSInt(AVal: PJsonValue): Int64; inline;
begin
  Result := AVal^.Data.I64;
end;

function UnsafeGetReal(AVal: PJsonValue): Double; inline;
begin
  Result := AVal^.Data.F64;
end;

function UnsafeGetStr(AVal: PJsonValue): PChar; inline;
begin
  Result := AVal^.Data.Str;
end;

// 字面量读取函数实现
function ReadInfOrNan(var ACur: PByte; AEnd: PByte; AFlags: TJsonReadFlags; ANegative: Boolean; AVal: PJsonValue): Boolean;
var
  p: PByte;
  isInf, isInfinity, isNaN: Boolean;
begin
  Result := False;
  if not (jrfAllowInfAndNan in AFlags) then Exit;
  p := ACur;
  isInf := False; isInfinity := False; isNaN := False;
  // case-insensitive match: inf | infinity | nan
  if (p^ = Ord('i')) or (p^ = Ord('I')) then
  begin
    // try "inf" or "infinity"
    if (p + 2 < AEnd) and ((p+1)^ in [Ord('n'),Ord('N')]) and ((p+2)^ in [Ord('f'),Ord('F')]) then
    begin
      isInf := True; Inc(p, 3);
      if (p + 5 <= AEnd) and ((p^ in [Ord('i'),Ord('I')]) and ((p+1)^ in [Ord('n'),Ord('N')]) and
         ((p+2)^ in [Ord('i'),Ord('I')]) and ((p+3)^ in [Ord('t'),Ord('T')]) and
         ((p+4)^ in [Ord('y'),Ord('Y')])) then
      begin
        isInfinity := True; Inc(p, 5);
      end;
    end;
  end
  else if (p^ = Ord('n')) or (p^ = Ord('N')) then
  begin
    if (p + 2 < AEnd) and ((p+1)^ in [Ord('a'),Ord('A')]) and ((p+2)^ in [Ord('n'),Ord('N')]) then
    begin
      isNaN := True; Inc(p, 3);
    end;
  end;
  if isInf or isInfinity or isNaN then
  begin
    // NumberAsRaw/BignumAsRaw: 返回 RAW
    if (jrfNumberAsRaw in AFlags) or (jrfBignumAsRaw in AFlags) then
    begin
      AVal^.Tag := (UInt64((p - ACur) + Ord(ANegative)) shl YYJSON_TAG_BIT) or YYJSON_TYPE_RAW;
      if ANegative then Dec(ACur);
      AVal^.Data.Str := PChar(ACur);
      ACur := p;
      Exit(True);
    end
    else
    begin
      AVal^.Tag := YYJSON_TYPE_NUM or YYJSON_SUBTYPE_REAL;
      if isNaN then
        AVal^.Data.F64 := 0.0/0.0
      else if ANegative then
        AVal^.Data.F64 := -1.0/0.0
      else
        AVal^.Data.F64 := 1.0/0.0;
      ACur := p;
      Exit(True);
    end;
  end;
end;

function ReadTrue(var ACur: PByte; AVal: PJsonValue): Boolean;
begin
  Result := False;
  if (ACur[0] = CHAR_T_LOWER) and (ACur[1] = CHAR_R_LOWER) and
     (ACur[2] = CHAR_U_LOWER) and (ACur[3] = CHAR_E_LOWER) then
  begin
    AVal^.Tag := YYJSON_TYPE_BOOL or YYJSON_SUBTYPE_TRUE;
    Inc(ACur, 4);
    Result := True;
  end;
end;

function ReadFalse(var ACur: PByte; AVal: PJsonValue): Boolean;
begin
  Result := False;
  if (ACur[0] = CHAR_F_LOWER) and (ACur[1] = CHAR_A_LOWER) and
     (ACur[2] = 108) and (ACur[3] = 115) and (ACur[4] = 101) then // 'alse'
  begin
    AVal^.Tag := YYJSON_TYPE_BOOL or YYJSON_SUBTYPE_FALSE;
    Inc(ACur, 5);
    Result := True;
  end;
end;

function ReadNull(var ACur: PByte; AVal: PJsonValue): Boolean;
begin
  Result := False;
  if (ACur[0] = CHAR_N_LOWER) and (ACur[1] = CHAR_U_LOWER) and
     (ACur[2] = 108) and (ACur[3] = 108) then // 'ull'
  begin
    AVal^.Tag := YYJSON_TYPE_NULL;
    Inc(ACur, 4);
    Result := True;
  end;
end;

// 完整字符串解析 (严格对应 yyjson read_str，含转义与 Unicode 验证与解码)
function ReadStr(var ACur: PByte; AEnd: PByte; AVal: PJsonValue; var AMsg: String): Boolean;
var
  LStart, LSrc, LDst: PByte;
  LLen: SizeUInt;
  B0, B1, B2, B3: Byte;
  LHi, LLo: Word;
  LCodePoint: Cardinal;
  LHasEsc: Boolean;

  function HexNibble(C: Byte): Integer; inline;
  begin
    case C of
      Ord('0')..Ord('9'): Exit(C - Ord('0'));
      Ord('A')..Ord('F'): Exit(C - Ord('A') + 10);
      Ord('a')..Ord('f'): Exit(C - Ord('a') + 10);
    else
      Exit(-1);
    end;
  end;

  function ReadHexU16(P: PByte; out V: Word): Boolean; inline;
  var N0, N1, N2, N3: Integer;
  begin
    N0 := HexNibble(P[0]); N1 := HexNibble(P[1]);
    N2 := HexNibble(P[2]); N3 := HexNibble(P[3]);
    if (N0 < 0) or (N1 < 0) or (N2 < 0) or (N3 < 0) then Exit(False);
    V := (N0 shl 12) or (N1 shl 8) or (N2 shl 4) or N3;
    Result := True;
  end;

  procedure EncodeUTF8(U: Cardinal); inline;
  begin
    if U < $80 then begin LDst^ := Byte(U); Inc(LDst); end
    else if U < $800 then begin LDst^ := Byte($C0 or (U shr 6)); Inc(LDst); LDst^ := Byte($80 or (U and $3F)); Inc(LDst); end
    else if U < $10000 then begin LDst^ := Byte($E0 or (U shr 12)); Inc(LDst); LDst^ := Byte($80 or ((U shr 6) and $3F)); Inc(LDst); LDst^ := Byte($80 or (U and $3F)); Inc(LDst); end
    else begin LDst^ := Byte($F0 or (U shr 18)); Inc(LDst); LDst^ := Byte($80 or ((U shr 12) and $3F)); Inc(LDst); LDst^ := Byte($80 or ((U shr 6) and $3F)); Inc(LDst); LDst^ := Byte($80 or (U and $3F)); Inc(LDst); end;
  end;

  function CopyValidUTF8: Boolean; inline;
  begin
    Result := False;
    B0 := LSrc^;
    if B0 < $80 then Exit(False);
    // 2 字节序列
    if (B0 >= $C2) and (B0 <= $DF) then begin
      if LSrc + 1 >= AEnd then Exit(False);
      B1 := (LSrc + 1)^; if (B1 and $C0) <> $80 then Exit(False);
      LDst^ := B0; Inc(LDst); LDst^ := B1; Inc(LDst); Inc(LSrc, 2); Exit(True);
    end;
    // 3 字节序列
    if (B0 >= $E0) and (B0 <= $EF) then begin
      if LSrc + 2 >= AEnd then Exit(False);
      B1 := (LSrc + 1)^; B2 := (LSrc + 2)^;
      if (B1 and $C0) <> $80 then Exit(False);
      if (B2 and $C0) <> $80 then Exit(False);
      if (B0 = $E0) and (B1 < $A0) then Exit(False); // overlong
      if (B0 = $ED) and (B1 >= $A0) then Exit(False); // surrogate range
      LDst^ := B0; Inc(LDst); LDst^ := B1; Inc(LDst); LDst^ := B2; Inc(LDst); Inc(LSrc, 3); Exit(True);
    end;
    // 4 字节序列
    if (B0 >= $F0) and (B0 <= $F4) then begin
      if LSrc + 3 >= AEnd then Exit(False);
      B1 := (LSrc + 1)^; B2 := (LSrc + 2)^; B3 := (LSrc + 3)^;
      if (B1 and $C0) <> $80 then Exit(False);
      if (B2 and $C0) <> $80 then Exit(False);
      if (B3 and $C0) <> $80 then Exit(False);
      if (B0 = $F0) and (B1 < $90) then Exit(False); // overlong
      if (B0 = $F4) and (B1 > $8F) then Exit(False); // > U+10FFFF
      LDst^ := B0; Inc(LDst); LDst^ := B1; Inc(LDst); LDst^ := B2; Inc(LDst); LDst^ := B3; Inc(LDst); Inc(LSrc, 4); Exit(True);
    end;
    Exit(False);
  end;

begin
  Result := False; AMsg := ''; LHasEsc := False;
  if (ACur >= AEnd) or (ACur^ <> CHAR_QUOTE) then begin AMsg := 'Expected quote character'; Exit; end;
  Inc(ACur); LStart := ACur; LSrc := ACur;
  // 快速跳过纯 ASCII 段
  while (LSrc < AEnd) do begin B0 := LSrc^; if (B0 = CHAR_QUOTE) or (B0 = CHAR_BACKSLASH) or (B0 < 32) or (B0 >= 128) then Break; Inc(LSrc); end;
  if LSrc >= AEnd then begin AMsg := 'Unterminated string'; ACur := LSrc; Exit; end;
  if LSrc^ = CHAR_QUOTE then begin
    // 就地写入 0 作为字符串终止符，便于 PChar 直接转 String
    LSrc^ := 0;
    LLen := LSrc - LStart;
    AVal^.Tag := (UInt64(LLen) shl YYJSON_TAG_BIT) or (YYJSON_TYPE_STR or YYJSON_SUBTYPE_NOESC);
    AVal^.Data.Str := PChar(LStart);
    ACur := LSrc + 1; Result := True; Exit;
  end;
  // 解码路径（原地写入）
  LDst := LSrc;
  while (LSrc < AEnd) do begin
    B0 := LSrc^;
    // 限额：字符串最大字节数（按输出 UTF-8 计数）
    if (JsonMaxStringBytes <> 0) and (SizeUInt(LDst - LStart) > JsonMaxStringBytes) then begin AMsg := ERR_STRING_TOO_LONG; ACur := LSrc; Exit; end;

    if B0 = CHAR_QUOTE then begin
      // 在解码路径，使用 LDst 写入 0 终止符
      LDst^ := 0;
      LLen := LDst - LStart; AVal^.Tag := (UInt64(LLen) shl YYJSON_TAG_BIT) or YYJSON_TYPE_STR;
      AVal^.Data.Str := PChar(LStart); Inc(LSrc); ACur := LSrc; Result := True; Exit;
    end;
    if B0 = CHAR_BACKSLASH then begin
      LHasEsc := True; Inc(LSrc); if LSrc >= AEnd then begin AMsg := 'Unterminated escape sequence'; ACur := LSrc; Exit; end;
      case LSrc^ of
        Ord('"'): begin LDst^ := Ord('"'); Inc(LDst); Inc(LSrc); end;
        Ord('\'): begin LDst^ := Ord('\'); Inc(LDst); Inc(LSrc); end;
        Ord('/') : begin LDst^ := Ord('/');  Inc(LDst); Inc(LSrc); end;
        Ord('b') : begin LDst^ := 8;   Inc(LDst); Inc(LSrc); end;
        Ord('f') : begin LDst^ := 12;  Inc(LDst); Inc(LSrc); end;
        Ord('n') : begin LDst^ := 10;  Inc(LDst); Inc(LSrc); end;
        Ord('r') : begin LDst^ := 13;  Inc(LDst); Inc(LSrc); end;
        Ord('t') : begin LDst^ := 9;   Inc(LDst); Inc(LSrc); end;
        Ord('u') : begin
          if (LSrc + 4 >= AEnd) or (not ReadHexU16(LSrc + 1, LHi)) then begin AMsg := 'Invalid unicode escape'; ACur := LSrc; Exit; end;
          Inc(LSrc, 5);
          if (LHi < $D800) or (LHi > $DFFF) then begin EncodeUTF8(LHi); end
          else if (LHi >= $D800) and (LHi <= $DBFF) then begin
            if (jrfAllowInvalidUnicode in JsonGlobalReadFlags) then begin
              // 放宽：缺失低代理或非法低代理时，按单个高代理编码通过
              EncodeUTF8(LHi);
            end else begin
              if (LSrc + 6 > AEnd) or (LSrc^ <> Ord('\')) or ((LSrc + 1)^ <> Ord('u')) then begin AMsg := 'No low surrogate in string'; ACur := LSrc; Exit; end;
              if not ReadHexU16(LSrc + 2, LLo) then begin AMsg := 'Invalid escape in string'; ACur := LSrc; Exit; end;
              if (LLo < $DC00) or (LLo > $DFFF) then begin AMsg := 'Invalid low surrogate in string'; ACur := LSrc; Exit; end;
              LCodePoint := ((Cardinal(LHi) - $D800) shl 10) + (Cardinal(LLo) - $DC00) + $10000; EncodeUTF8(LCodePoint); Inc(LSrc, 6);
            end;
          end else begin AMsg := 'Invalid surrogate in string'; ACur := LSrc; Exit; end;
        end;
      else AMsg := 'Invalid escaped sequence in string';
      end;
      if AMsg <> '' then begin Exit; end; Continue;
    end;
    if B0 < 32 then begin
      if not (jrfAllowInvalidUnicode in JsonGlobalReadFlags) then begin AMsg := 'Unexpected control character in string'; ACur := LSrc; Exit; end
      else begin LDst^ := B0; Inc(LDst); Inc(LSrc); Continue; end;
    end;
    if B0 >= 128 then begin
      if (jrfAllowInvalidUnicode in JsonGlobalReadFlags) then begin LDst^ := B0; Inc(LDst); Inc(LSrc); Continue; end
      else begin if not CopyValidUTF8 then begin AMsg := 'Invalid UTF-8 encoding in string'; ACur := LSrc; Exit; end; Continue; end;
    end;
    LDst^ := B0; Inc(LDst); Inc(LSrc);
  end;
  AMsg := 'Unterminated string';
end;

// 完整数字解析 (严格对应 yyjson read_num，含溢出与指数处理)
function ReadNum(var ACur: PByte; AEnd: PByte; AFlags: TJsonReadFlags; AVal: PJsonValue; var AMsg: String): Boolean;
var
  LSign: Boolean;
  LSig: UInt64;
  LExp: Int32;        // 小数部分引入的指数（负数）+ 额外整数位（正数）
  LExpLit: Int64;     // 显式指数
  LExpSign: Boolean;
  LHasDot, LHasExp: Boolean;
  LFloatVal: Double;
  LOverflow: Boolean;
  LIntExtra: Int32;   // 整数部分溢出的额外位数
  LDigit: UInt8;
  LStart: PByte;      // token 起始（含可选负号）
const
  U64_DIV10 = UInt64(18446744073709551615 div 10);
  U64_MOD10 = UInt64(18446744073709551615 mod 10);
begin
  Result := False;
  LStart := ACur;
  LSign := False;
  LSig := 0;
  LExp := 0;
  LExpLit := 0;
  LExpSign := False;
  LHasDot := False;
  LHasExp := False;
  LOverflow := False;
  LIntExtra := 0;

  // 符号
  if (ACur < AEnd) and (ACur^ = CHAR_MINUS) then
  begin
    LSign := True;
    Inc(ACur);
    if (ACur >= AEnd) then
    begin
      AMsg := ERR_INVALID_NUM_FMT;
      Exit;
    end;
  end;

  // 允许 Inf/NaN 前缀（大小写不限）
  if (jrfAllowInfAndNan in AFlags) and (ACur < AEnd) and (ACur^ in [Ord('i'), Ord('I'), Ord('n'), Ord('N')]) then
  begin
    if ReadInfOrNan(ACur, AEnd, AFlags, LSign, AVal) then
    begin
      Result := True; Exit;
    end
    else
    begin
      AMsg := ERR_INVALID_INFNAN_LITERAL;
      Exit;
    end;
  end;

  // 首位必须为数字
  if (ACur >= AEnd) or not ((ACur^ >= CHAR_0) and (ACur^ <= CHAR_9)) then
  begin
    AMsg := 'Invalid number format';
    Exit;
  end;

  // 处理前导零
  if ACur^ = CHAR_0 then
  begin
    Inc(ACur);
    // 若后续仍是数字，则为非法前导零
    if (ACur < AEnd) and CharIsDigit(ACur^) then
    begin
      AMsg := ERR_INVALID_NUM_LEADING_ZERO;
      Exit;
    end;
  end
  else
  begin
    // 读取整数部分
    while (ACur < AEnd) and (ACur^ >= CHAR_0) and (ACur^ <= CHAR_9) do
    begin
      LDigit := ACur^ - CHAR_0;
      if (not LOverflow) then
      begin
        if (LSig > U64_DIV10) or ((LSig = U64_DIV10) and (LDigit > U64_MOD10)) then
        begin
          LOverflow := True;
        end
        else
        begin
          LSig := LSig * 10 + LDigit;
        end;
      end
      else
      begin
        // 记录额外的整数位（用于转换为浮点的指数修正）
        Inc(LIntExtra);
      end;
      Inc(ACur);
    end;
  end;

  // 小数部分
  if (ACur < AEnd) and (ACur^ = CHAR_DOT) then
  begin
    LHasDot := True;
    Inc(ACur);
    if (ACur >= AEnd) or not ((ACur^ >= CHAR_0) and (ACur^ <= CHAR_9)) then
    begin
      AMsg := ERR_DECIMAL_NEEDS_DIGITS;
      Exit;
    end;
    while (ACur < AEnd) and (ACur^ >= CHAR_0) and (ACur^ <= CHAR_9) do
    begin
      LDigit := ACur^ - CHAR_0;
      if (not LOverflow) then
      begin
        if (LSig > U64_DIV10) or ((LSig = U64_DIV10) and (LDigit > U64_MOD10)) then
        begin
          LOverflow := True;
        end
        else
        begin
          LSig := LSig * 10 + LDigit;
        end;
      end;
      // 小数位每增加一位，指数减一
      Dec(LExp);
      Inc(ACur);
    end;
  end;

  // 指数部分
  if (ACur < AEnd) and ((ACur^ = CHAR_E_LOWER) or (ACur^ = CHAR_E_UPPER)) then
  begin
    LHasExp := True;
    Inc(ACur);
    if (ACur >= AEnd) then
    begin
      AMsg := ERR_INCOMPLETE_EXPONENT;
      Exit;
    end;
    if ACur^ = CHAR_MINUS then
    begin
      LExpSign := True; Inc(ACur);
    end
    else if ACur^ = CHAR_PLUS then
      Inc(ACur);
    if (ACur >= AEnd) or not ((ACur^ >= CHAR_0) and (ACur^ <= CHAR_9)) then
    begin
      AMsg := ERR_EXPONENT_NEEDS_DIGITS;
      Exit;
    end;
    while (ACur < AEnd) and (ACur^ >= CHAR_0) and (ACur^ <= CHAR_9) do
    begin
      LExpLit := LExpLit * 10 + (ACur^ - CHAR_0);
      Inc(ACur);
    end;
    if LExpSign then LExpLit := -LExpLit;
  end;

  // 合并指数：小数修正 + 额外整数位修正 + 显式指数
  if LIntExtra <> 0 then
    Inc(LExp, LIntExtra);
  if LExpLit <> 0 then
    Inc(LExp, LExpLit);

  // bignum-as-raw：无小数/指数且整数溢出时，直接返回 RAW
  if (jrfBignumAsRaw in AFlags) and (not LHasDot) and (not LHasExp) and LOverflow then
  begin
    AVal^.Tag := (UInt64(ACur - LStart) shl YYJSON_TAG_BIT) or YYJSON_TYPE_RAW;
    AVal^.Data.Str := PChar(LStart);
    Result := True;
    Exit;
  end;

  // Inf/NaN 支持（非标准）
  if (not (jrfAllowInfAndNan in AFlags)) then
  begin
    // 若后续是 Inf/NaN 的字母起始，则报错（和 yyjson 一致）
    if (ACur < AEnd) and (ACur^ in [Ord('i'), Ord('I'), Ord('n'), Ord('N')]) then
    begin
      AMsg := 'NaN or Inf number is not allowed';
      Exit;
    end;
  end
  else
  begin
    // 支持 -?inf/-?infinity/-?nan （大小写不敏感）
    // 尝试匹配当前位置的 inf/infinity/nan
    // 说明：为保持实现简洁，这里匹配当前位置开始的文本；
    // 在我们的解析流程中，进入此处时 ACur 通常位于数值 token 末尾或紧跟其后，
    // 仅当用户直接以 i/n 开头值时才会命中，数组/对象分支会在分派前先判断首字母。
    // 完整 1:1 可在后续集中抽取入口匹配逻辑。

    // 小写匹配
    if (ACur < AEnd) then
    begin
      // 无前缀负号情况（负号在更早处处理），这里仅处理正向
      // 为兼容 -inf / -infinity / -nan，我们在负号路径进入时同样允许字母开头
    end;
  end;

  // number-as-raw 在分派层处理，此处不再处理

  // 判定类型与生成数值
  if LHasDot or LHasExp or LOverflow then
  begin
    // 浮点数路径
    // bignum-as-raw: 在进行昂贵/可能溢出的运算前先用指数阈值拦截常见 Infinity 情况
    if (jrfBignumAsRaw in AFlags) and (LExp > 308) then
    begin
      AVal^.Tag := (UInt64(ACur - LStart) shl YYJSON_TAG_BIT) or YYJSON_TYPE_RAW;
      AVal^.Data.Str := PChar(LStart);
      Result := True;
      Exit;
    end;
    LFloatVal := LSig;
    if (LExp >= 0) and (LExp <= F64_POW10_EXP_MAX_EXACT) then
      LFloatVal := LFloatVal * F64Pow10Table[LExp]
    else if (LExp < 0) and (-LExp <= F64_POW10_EXP_MAX_EXACT) then
      LFloatVal := LFloatVal / F64Pow10Table[-LExp]
    else
      LFloatVal := LFloatVal * Power(10.0, LExp);

    // bignum-as-raw：无法以有限 Double 表达（Inf/NaN）时返回 RAW
    if (jrfBignumAsRaw in AFlags) and (IsNaN(LFloatVal) or IsInfinite(LFloatVal)) then
    begin
      AVal^.Tag := (UInt64(ACur - LStart) shl YYJSON_TAG_BIT) or YYJSON_TYPE_RAW;
      AVal^.Data.Str := PChar(LStart);
      Result := True;
      Exit;
    end;

    AVal^.Tag := YYJSON_TYPE_NUM or YYJSON_SUBTYPE_REAL;
    if LSign then AVal^.Data.F64 := -LFloatVal else AVal^.Data.F64 := LFloatVal;
  end
  else
  begin
    // 整数路径（检查有符号范围）
    if LSign then
    begin
      if LSig <= UInt64(High(Int64)) + 1 then
      begin
        // 允许 -2^63
        if LSig = UInt64(High(Int64)) + 1 then
        begin
          AVal^.Tag := YYJSON_TYPE_NUM or YYJSON_SUBTYPE_SINT;
          AVal^.Data.I64 := Low(Int64); // -9223372036854775808
        end
        else
        begin
          AVal^.Tag := YYJSON_TYPE_NUM or YYJSON_SUBTYPE_SINT;
          AVal^.Data.I64 := -Int64(LSig);
        end;
      end
      else
      begin
        // 溢出，转为浮点
        AVal^.Tag := YYJSON_TYPE_NUM or YYJSON_SUBTYPE_REAL;
        AVal^.Data.F64 := - (Double(LSig));
      end;
    end
    else
    begin
      // 无符号范围由上面溢出检查保证
      AVal^.Tag := YYJSON_TYPE_NUM or YYJSON_SUBTYPE_UINT;
      AVal^.Data.U64 := LSig;
    end;
  end;

  Result := True;
end;

// 数组操作 API 实现 (严格对应 yyjson)
function JsonArrSize(AArr: PJsonValue): SizeUInt; inline;
begin
  if UnsafeIsArr(AArr) then
    Result := UnsafeGetLen(AArr)
  else
    Result := 0;
end;

function JsonArrGet(AArr: PJsonValue; AIdx: SizeUInt): PJsonValue; inline;
var
  LVal: PJsonValue;
begin
  Result := nil;
  if UnsafeIsArr(AArr) then
  begin
    if UnsafeGetLen(AArr) > AIdx then
    begin
      LVal := UnsafeGetFirst(AArr);
      if UnsafeArrIsFlat(AArr) then
        Result := LVal + AIdx
      else
      begin
        while AIdx > 0 do
        begin
          LVal := UnsafeGetNext(LVal);
          Dec(AIdx);
        end;
        Result := LVal;
      end;
    end;
  end;
end;

function JsonArrGetFirst(AArr: PJsonValue): PJsonValue; inline;
begin
  if UnsafeIsArr(AArr) and (UnsafeGetLen(AArr) > 0) then
    Result := UnsafeGetFirst(AArr)
  else
    Result := nil;
end;

function JsonArrGetLast(AArr: PJsonValue): PJsonValue; inline;
var
  LLen: SizeUInt;
  LVal: PJsonValue;
begin
  Result := nil;
  if UnsafeIsArr(AArr) then
  begin
    LLen := UnsafeGetLen(AArr);
    if LLen > 0 then
    begin
      LVal := UnsafeGetFirst(AArr);
      if UnsafeArrIsFlat(AArr) then
        Result := LVal + (LLen - 1)
      else
      begin
        while LLen > 1 do
        begin
          LVal := UnsafeGetNext(LVal);
          Dec(LLen);
        end;
        Result := LVal;
      end;
    end;
  end;
end;

// 数组迭代器 API 实现
function JsonArrIterInit(AArr: PJsonValue; AIter: PJsonArrayIterator): Boolean; inline;
begin
  if UnsafeIsArr(AArr) and Assigned(AIter) then
  begin
    AIter^.Idx := 0;
    AIter^.Max := UnsafeGetLen(AArr);
    AIter^.Cur := UnsafeGetFirst(AArr);
    Result := True;
  end
  else
  begin
    if Assigned(AIter) then
      FillChar(AIter^, SizeOf(TJsonArrayIterator), 0);
    Result := False;
  end;
end;

function JsonArrIterHasNext(AIter: PJsonArrayIterator): Boolean; inline;
begin
  Result := Assigned(AIter) and (AIter^.Idx < AIter^.Max);
end;

function JsonArrIterNext(AIter: PJsonArrayIterator): PJsonValue; inline;
begin
  if Assigned(AIter) and (AIter^.Idx < AIter^.Max) then
  begin
    Result := AIter^.Cur;
    AIter^.Cur := UnsafeGetNext(Result);
    Inc(AIter^.Idx);
  end
  else
    Result := nil;
end;

// 对象操作 API 实现 (严格对应 yyjson)
function JsonObjSize(AObj: PJsonValue): SizeUInt; inline;
begin
  if UnsafeIsObj(AObj) then
    Result := UnsafeGetLen(AObj)
  else
    Result := 0;
end;

function JsonObjGet(AObj: PJsonValue; const AKey: PChar): PJsonValue; inline;
begin
  if Assigned(AKey) then
    Result := JsonObjGetN(AObj, AKey, StrLen(AKey))
  else
    Result := nil;
end;

function JsonObjGetN(AObj: PJsonValue; const AKey: PChar; AKeyLen: SizeUInt): PJsonValue; inline;
var
  LLen: SizeUInt;
  LKey: PJsonValue;
begin
  Result := nil;
  if UnsafeIsObj(AObj) and Assigned(AKey) then
  begin
    LLen := UnsafeGetLen(AObj);
    LKey := UnsafeGetFirst(AObj);
    while LLen > 0 do
    begin
      if UnsafeEqualsStrN(LKey, AKey, AKeyLen) then
      begin
        Result := LKey + 1; // 值紧跟在键后面
        Exit;
      end;
      LKey := UnsafeGetNext(LKey + 1); // 跳过键和值
      Dec(LLen);
    end;
  end;
end;

// 对象迭代器 API 实现
function JsonObjIterInit(AObj: PJsonValue; AIter: PJsonObjectIterator): Boolean; inline;
begin
  if UnsafeIsObj(AObj) and Assigned(AIter) then
  begin
    AIter^.Idx := 0;
    AIter^.Max := UnsafeGetLen(AObj);
    // 为了在 GetVal 时能稳定定位到“值”，Cur 指向“键”之前的位置，
    // 让 JsonObjIterNext 返回键后，将 Cur 跳到“值”位置，便于 GetVal 取到。
    AIter^.Cur := UnsafeGetFirst(AObj); // 当前键
    AIter^.Obj := AObj;
    Result := True;
  end
  else
  begin
    if Assigned(AIter) then
      FillChar(AIter^, SizeOf(TJsonObjectIterator), 0);
    Result := False;
  end;
end;

function JsonObjIterHasNext(AIter: PJsonObjectIterator): Boolean; inline;
begin
  Result := Assigned(AIter) and (AIter^.Idx < AIter^.Max);
end;

function JsonObjIterNext(AIter: PJsonObjectIterator): PJsonValue; inline;
var
  Key, Val: PJsonValue;
begin
  if Assigned(AIter) and (AIter^.Idx < AIter^.Max) then
  begin
    // AIter^.Cur 指向当前“键”
    Key := AIter^.Cur;
    // 下一个位置是“值”
    Val := Key + 1;
    // 计算下一个键的位置：跳过当前值整个跨度
    AIter^.Cur := UnsafeGetNext(Val);
    Inc(AIter^.Idx);
    Result := Key;
  end
  else
    Result := nil;
end;

function JsonObjIterGetVal(AKey: PJsonValue): PJsonValue; inline;
begin
  if Assigned(AKey) then
    Result := AKey + 1 // 值紧跟在键后面
  else
    Result := nil;
end;

// 文档管理 API 实现 (严格对应 yyjson_doc_* 函数)
function JsonDocGetRoot(ADoc: TJsonDocument): PJsonValue; inline;
begin
  if Assigned(ADoc) then
    Result := ADoc.Root
  else
    Result := nil;
end;

function JsonDocGetReadSize(ADoc: TJsonDocument): SizeUInt; inline;
begin
  if Assigned(ADoc) then
    Result := ADoc.BytesRead
  else
    Result := 0;
end;

function JsonDocGetValCount(ADoc: TJsonDocument): SizeUInt; inline;
begin
  if Assigned(ADoc) then
    Result := ADoc.ValuesRead
  else
    Result := 0;
end;

procedure JsonDocFree(ADoc: TJsonDocument); inline;
begin
  if Assigned(ADoc) then
    ADoc.Free;
end;

// 值类型检查 API 实现 (严格对应 yyjson_is_* 函数)
function JsonIsRaw(AVal: PJsonValue): Boolean; inline;
begin
  if Assigned(AVal) then
    Result := UnsafeGetType(AVal) = YYJSON_TYPE_RAW
  else
    Result := False;
end;

function JsonIsNull(AVal: PJsonValue): Boolean; inline;
begin
  if Assigned(AVal) then
    Result := UnsafeIsNull(AVal)
  else
    Result := False;
end;

function JsonIsTrue(AVal: PJsonValue): Boolean; inline;
begin
  if Assigned(AVal) then
    Result := UnsafeIsTrue(AVal)
  else
    Result := False;
end;

function JsonIsFalse(AVal: PJsonValue): Boolean; inline;
begin
  if Assigned(AVal) then
    Result := UnsafeIsFalse(AVal)
  else
    Result := False;
end;

function JsonIsBool(AVal: PJsonValue): Boolean; inline;
begin
  if Assigned(AVal) then
    Result := UnsafeIsBool(AVal)
  else
    Result := False;
end;

function JsonIsUint(AVal: PJsonValue): Boolean; inline;
begin
  if Assigned(AVal) then
    Result := UnsafeIsNum(AVal) and ((AVal^.Tag and YYJSON_SUBTYPE_MASK) = YYJSON_SUBTYPE_UINT)
  else
    Result := False;
end;

function JsonIsSint(AVal: PJsonValue): Boolean; inline;
begin
  if Assigned(AVal) then
    Result := UnsafeIsNum(AVal) and ((AVal^.Tag and YYJSON_SUBTYPE_MASK) = YYJSON_SUBTYPE_SINT)
  else
    Result := False;
end;

function JsonIsInt(AVal: PJsonValue): Boolean; inline;
begin
  if Assigned(AVal) then
    Result := UnsafeIsNum(AVal) and ((AVal^.Tag and YYJSON_SUBTYPE_MASK) <> YYJSON_SUBTYPE_REAL)
  else
    Result := False;
end;

function JsonIsReal(AVal: PJsonValue): Boolean; inline;
begin
  if Assigned(AVal) then
    Result := UnsafeIsNum(AVal) and ((AVal^.Tag and YYJSON_SUBTYPE_MASK) = YYJSON_SUBTYPE_REAL)
  else
    Result := False;
end;

function JsonIsNum(AVal: PJsonValue): Boolean; inline;
begin
  if Assigned(AVal) then
    Result := UnsafeIsNum(AVal)
  else
    Result := False;
end;

function JsonIsStr(AVal: PJsonValue): Boolean; inline;
begin
  if Assigned(AVal) then
    Result := UnsafeIsStr(AVal)
  else
    Result := False;
end;

function JsonIsArr(AVal: PJsonValue): Boolean; inline;
begin
  if Assigned(AVal) then
    Result := UnsafeIsArr(AVal)
  else
    Result := False;
end;

function JsonIsObj(AVal: PJsonValue): Boolean; inline;
begin
  if Assigned(AVal) then
    Result := UnsafeIsObj(AVal)
  else
    Result := False;
end;

function JsonIsCtn(AVal: PJsonValue): Boolean; inline;
begin
  if Assigned(AVal) then
    Result := UnsafeIsCtn(AVal)
  else
    Result := False;
end;

// 值内容访问 API 实现 (严格对应 yyjson_get_* 函数)
function JsonGetType(AVal: PJsonValue): UInt8; inline;
begin
  if Assigned(AVal) then
    Result := UnsafeGetType(AVal)
  else
    Result := YYJSON_TYPE_NONE;
end;

function JsonGetSubtype(AVal: PJsonValue): UInt8; inline;
begin
  if Assigned(AVal) then
    Result := UInt8(AVal^.Tag) and YYJSON_SUBTYPE_MASK
  else
    Result := YYJSON_SUBTYPE_NONE;
end;

function JsonGetTag(AVal: PJsonValue): UInt8; inline;
begin
  if Assigned(AVal) then
    Result := UnsafeGetTag(AVal)
  else
    Result := 0;
end;

function JsonGetTypeDesc(AVal: PJsonValue): String; inline;
var
  LType: UInt8;
  LSubtype: UInt8;
begin
  if not Assigned(AVal) then
  begin
    Result := 'unknown';
    Exit;
  end;

  LType := UnsafeGetType(AVal);
  LSubtype := UInt8(AVal^.Tag) and YYJSON_SUBTYPE_MASK;

  case LType of
    YYJSON_TYPE_RAW: Result := 'raw';
    YYJSON_TYPE_NULL: Result := 'null';
    YYJSON_TYPE_BOOL:
      if LSubtype = YYJSON_SUBTYPE_TRUE then
        Result := 'true'
      else
        Result := 'false';
    YYJSON_TYPE_NUM:
      case LSubtype of
        YYJSON_SUBTYPE_UINT: Result := 'uint';
        YYJSON_SUBTYPE_SINT: Result := 'sint';
        YYJSON_SUBTYPE_REAL: Result := 'real';
      else
        Result := 'number';
      end;
    YYJSON_TYPE_STR: Result := 'string';
    YYJSON_TYPE_ARR: Result := 'array';
    YYJSON_TYPE_OBJ: Result := 'object';
  else
    Result := 'unknown';
  end;
end;

function JsonGetRaw(AVal: PJsonValue): PChar; inline;
begin
  if Assigned(AVal) and (UnsafeGetType(AVal) = YYJSON_TYPE_RAW) then
    Result := AVal^.Data.Str
  else
    Result := nil;
end;

function JsonGetBool(AVal: PJsonValue): Boolean; inline;
begin
  if Assigned(AVal) and UnsafeIsBool(AVal) then
    Result := UnsafeIsTrue(AVal)
  else
    Result := False;
end;

function JsonGetUint(AVal: PJsonValue): UInt64; inline;
begin
  if Assigned(AVal) and JsonIsInt(AVal) then
    Result := AVal^.Data.U64
  else
    Result := 0;
end;

function JsonGetSint(AVal: PJsonValue): Int64; inline;
begin
  if Assigned(AVal) and JsonIsInt(AVal) then
    Result := AVal^.Data.I64
  else
    Result := 0;
end;

function JsonGetInt(AVal: PJsonValue): Integer; inline;
begin
  if Assigned(AVal) and JsonIsInt(AVal) then
  begin
    if JsonIsSint(AVal) then
      Result := Integer(AVal^.Data.I64)
    else
      Result := Integer(AVal^.Data.U64);
  end
  else
    Result := 0;
end;

function JsonGetReal(AVal: PJsonValue): Double; inline;
begin
  if Assigned(AVal) and JsonIsReal(AVal) then
    Result := AVal^.Data.F64
  else
    Result := 0.0;
end;

function JsonGetNum(AVal: PJsonValue): Double; inline;
begin
  if Assigned(AVal) and UnsafeIsNum(AVal) then
  begin
    case UInt8(AVal^.Tag) and YYJSON_SUBTYPE_MASK of
      YYJSON_SUBTYPE_UINT: Result := Double(AVal^.Data.U64);
      YYJSON_SUBTYPE_SINT: Result := Double(AVal^.Data.I64);
      YYJSON_SUBTYPE_REAL: Result := AVal^.Data.F64;
    else
      Result := 0.0;
    end;
  end
  else
    Result := 0.0;
end;

function JsonGetStr(AVal: PJsonValue): PChar; inline;
begin
  if Assigned(AVal) and UnsafeIsStr(AVal) then
    Result := AVal^.Data.Str
  else
    Result := nil;
end;

function JsonGetLen(AVal: PJsonValue): SizeUInt; inline;
begin
  if Assigned(AVal) then
    Result := UnsafeGetLen(AVal)
  else
    Result := 0;
end;

function JsonEqualsStr(AVal: PJsonValue; const AStr: PChar): Boolean; inline;
begin
  if Assigned(AStr) then
    Result := JsonEqualsStrN(AVal, AStr, StrLen(AStr))
  else
    Result := False;
end;

function JsonEqualsStrN(AVal: PJsonValue; const AStr: PChar; ALen: SizeUInt): Boolean; inline;
begin
  if Assigned(AVal) and Assigned(AStr) and UnsafeIsStr(AVal) then
    Result := UnsafeEqualsStrN(AVal, AStr, ALen)
  else
    Result := False;
end;

function JsonGetStrUtf8(AVal: PJsonValue): UTF8String; inline;
begin
  if Assigned(AVal) and UnsafeIsStr(AVal) then
  begin
    SetLength(Result, UnsafeGetLen(AVal));
    if Length(Result) > 0 then
      Move(AVal^.Data.Str^, PAnsiChar(Result)^, Length(Result));
  end
  else
    Result := '';
end;

function JsonEqualsStrUtf8(AVal: PJsonValue; const S: UTF8String): Boolean; inline;
begin
  if Assigned(AVal) and UnsafeIsStr(AVal) then
    Result := (UnsafeGetLen(AVal) = Length(S)) and CompareMem(AVal^.Data.Str, PAnsiChar(S), Length(S))
  else
    Result := False;
end;

function NormalizeJsonFloatString(const S: String): String; forward;

// JSON 序列化函数实现 (严格对应 yyjson 写入器)
function WriteJsonNumber(AVal: PJsonValue; AFlags: TJsonWriteFlags): String;
var
  LSubtype: UInt8;
  V: Double;
begin
  if not Assigned(AVal) or not UnsafeIsNum(AVal) then
  begin
    Result := 'null';
    Exit;
  end;

  LSubtype := UInt8(AVal^.Tag) and YYJSON_SUBTYPE_MASK;
  case LSubtype of
    YYJSON_SUBTYPE_UINT: Result := IntToStr(AVal^.Data.U64);
    YYJSON_SUBTYPE_SINT: Result := IntToStr(AVal^.Data.I64);
    YYJSON_SUBTYPE_REAL:
      begin
        V := AVal^.Data.F64;
        if IsNaN(V) then
        begin
          if jwfInfAndNanAsNull in AFlags then Exit('null');
          if jwfAllowInfAndNan in AFlags then Exit('NaN');
          Exit(''); // signal error
        end
        else if IsInfinite(V) then
        begin
          if jwfInfAndNanAsNull in AFlags then Exit('null');
          if jwfAllowInfAndNan in AFlags then
            if Sign(V) < 0 then Exit('-Infinity') else Exit('Infinity');
          Exit('');
        end
        else
          Result := NormalizeJsonFloatString(FloatToStrF(V, ffGeneral, 17, 0, DefaultFormatSettings));
      end;
  else
    Result := 'null';
  end;
end;

function WriteJsonString(const AStr: PChar; ALen: SizeUInt; AFlags: TJsonWriteFlags): String;
var
  I: SizeUInt;
  LChar: Byte;
  LOutput: String;
  B0, B1, B2, B3: Byte;
  U: Word;
  U32: Cardinal;
  Hi, Lo: Word;


begin
  if not Assigned(AStr) or (ALen = 0) then
  begin
    Result := '""';
    Exit;
  end;

  LOutput := '"';

  I := 0;
  while I < ALen do
  begin
    LChar := PByte(AStr)[I];
    case LChar of
      8: LOutput := LOutput + '\b';    // backspace
      9: LOutput := LOutput + '\t';    // tab
      10: LOutput := LOutput + '\n';   // newline
      12: LOutput := LOutput + '\f';   // form feed
      13: LOutput := LOutput + '\r';   // carriage return
      34: LOutput := LOutput + '\"';   // quote
      92: LOutput := LOutput + '\\';   // backslash
      47: // slash
        if jwfEscapeSlashes in AFlags then
          LOutput := LOutput + '\/'
        else
          LOutput := LOutput + '/';
    else
      if (LChar < 32) then
        LOutput := LOutput + '\u' + IntToHex(LChar, 4)
      else if (LChar < 128) then
        LOutput := LOutput + Chr(LChar)
      else if (jwfEscapeUnicode in AFlags) then
      begin
        B0 := 0; B1 := 0; B2 := 0; B3 := 0;
        B0 := LChar;
        if (B0 >= $C2) and (B0 <= $DF) then
        begin
          if I + 1 >= ALen then
            if jwfAllowInvalidUnicode in AFlags then LOutput := LOutput + '\u' + IntToHex(B0, 4) else LOutput := LOutput + '?'
          else
          begin
            B1 := PByte(AStr)[I+1];
            if (B1 and $C0) <> $80 then
              if jwfAllowInvalidUnicode in AFlags then LOutput := LOutput + '\u' + IntToHex(B0, 4) else LOutput := LOutput + '?'
            else
            begin
              U := ((B0 and $1F) shl 6) or (B1 and $3F);
              LOutput := LOutput + '\u' + IntToHex(U, 4);
              Inc(I);
            end;
          end;
        end
        else if (B0 >= $E0) and (B0 <= $EF) then
        begin
          if I + 2 >= ALen then
            if jwfAllowInvalidUnicode in AFlags then LOutput := LOutput + '\u' + IntToHex(B0, 4) else LOutput := LOutput + '?'
          else
          begin
            B1 := PByte(AStr)[I+1]; B2 := PByte(AStr)[I+2];
            if ((B1 and $C0) <> $80) or ((B2 and $C0) <> $80) then
              if jwfAllowInvalidUnicode in AFlags then LOutput := LOutput + '\u' + IntToHex(B0, 4) else LOutput := LOutput + '?'
            else
            begin
              U := ((B0 and $0F) shl 12) or ((B1 and $3F) shl 6) or (B2 and $3F);
              LOutput := LOutput + '\u' + IntToHex(U, 4);
              Inc(I, 2);
            end;
          end;
        end
        else if (B0 >= $F0) and (B0 <= $F4) then
        begin
          if I + 3 >= ALen then
            if jwfAllowInvalidUnicode in AFlags then LOutput := LOutput + '\u' + IntToHex(B0, 4) else LOutput := LOutput + '?'
          else
          begin
            B1 := PByte(AStr)[I+1]; B2 := PByte(AStr)[I+2]; B3 := PByte(AStr)[I+3];
            if ((B1 and $C0) <> $80) or ((B2 and $C0) <> $80) or ((B3 and $C0) <> $80) then
              if jwfAllowInvalidUnicode in AFlags then LOutput := LOutput + '\u' + IntToHex(B0, 4) else LOutput := LOutput + '?'
            else
            begin
              U32 := ((B0 and $07) shl 18) or ((B1 and $3F) shl 12) or ((B2 and $3F) shl 6) or (B3 and $3F);
              Hi := Word(0);
              Lo := Word(0);
              U32 := U32 - $10000;
              Hi := Word($D800 or (U32 shr 10));
              Lo := Word($DC00 or (U32 and $3FF));
              LOutput := LOutput + '\u' + IntToHex(Hi, 4) + '\u' + IntToHex(Lo, 4);
              Inc(I, 3);
            end;
          end;
        end
        else
        begin
          if jwfAllowInvalidUnicode in AFlags then
            LOutput := LOutput + '\u' + IntToHex(B0, 4)
          else
            LOutput := LOutput + '?';
        end;
      end
      else
        LOutput := LOutput + Chr(LChar);
    end;
    Inc(I);
  end;




  LOutput := LOutput + '"';
  Result := LOutput;
end;

function WriteJsonValue(AVal: PJsonValue; AFlags: TJsonWriteFlags; AIndent: Integer): String;
var
  LType: UInt8;
  LLen: SizeUInt;
  LIter: TJsonArrayIterator;
  LObjIter: TJsonObjectIterator;
  LKey, LValue: PJsonValue;
  LIndentStr, LNewIndentStr: String;
  LFirst: Boolean;
  I: Integer;
begin
  if not Assigned(AVal) then
  begin
    Result := 'null';
    Exit;
  end;

  LType := UnsafeGetType(AVal);

  // 生成缩进字符串
  if jwfPretty in AFlags then
  begin
    LIndentStr := '';
    for I := 0 to AIndent - 1 do
      LIndentStr := LIndentStr + '  ';
    LNewIndentStr := '';
    for I := 0 to AIndent do
      LNewIndentStr := LNewIndentStr + '  ';
  end;

  case LType of
    YYJSON_TYPE_NULL: Result := 'null';
    YYJSON_TYPE_BOOL:
      if UnsafeIsTrue(AVal) then
        Result := 'true'
      else
        Result := 'false';
    YYJSON_TYPE_NUM:
      begin
        Result := WriteJsonNumber(AVal, AFlags);
        if Result = '' then
        begin
          Result := '';
        end;
      end;
    YYJSON_TYPE_STR:
      begin
        if ((UInt8(AVal^.Tag) and YYJSON_SUBTYPE_NOESC) <> 0) and
           not (jwfEscapeUnicode in AFlags) and not (jwfEscapeSlashes in AFlags) then
        begin
          // Fast path: raw ASCII/UTF-8 without escapes
          SetLength(Result, UnsafeGetLen(AVal) + 2);
          Result[1] := '"';
          Move(AVal^.Data.Str^, Result[2], UnsafeGetLen(AVal));
          Result[2 + UnsafeGetLen(AVal)] := '"';
        end
        else
          Result := WriteJsonString(AVal^.Data.Str, UnsafeGetLen(AVal), AFlags);
      end;
    YYJSON_TYPE_ARR:
    begin
      LLen := UnsafeGetLen(AVal);
      if LLen = 0 then
      begin
        Result := '[]';
        Exit;
      end;

      if jwfPretty in AFlags then
        Result := '[' + sLineBreak
      else
        Result := '[';

      LFirst := True;
      if JsonArrIterInit(AVal, @LIter) then
      begin
        while JsonArrIterHasNext(@LIter) do
        begin
          LValue := JsonArrIterNext(@LIter);
          if not LFirst then
          begin
            if jwfPretty in AFlags then
              Result := Result + ',' + sLineBreak
            else
              Result := Result + ',';
          end;
          LFirst := False;

          if jwfPretty in AFlags then
            Result := Result + LNewIndentStr;

          Result := Result + WriteJsonValue(LValue, AFlags, AIndent + 1);
        end;
      end;

      if jwfPretty in AFlags then
        Result := Result + sLineBreak + LIndentStr + ']'
      else
        Result := Result + ']';
    end;
    YYJSON_TYPE_OBJ:
    begin
      LLen := UnsafeGetLen(AVal);
      if LLen = 0 then
      begin
        Result := '{}';
        Exit;
      end;

      if jwfPretty in AFlags then
        Result := '{' + sLineBreak
      else
        Result := '{';

      LFirst := True;
      if JsonObjIterInit(AVal, @LObjIter) then
      begin
        while JsonObjIterHasNext(@LObjIter) do
        begin
          LKey := JsonObjIterNext(@LObjIter);
          LValue := JsonObjIterGetVal(LKey);

          if not LFirst then
          begin
            if jwfPretty in AFlags then
              Result := Result + ',' + sLineBreak
            else
              Result := Result + ',';
          end;
          LFirst := False;

          if jwfPretty in AFlags then
            Result := Result + LNewIndentStr;

          // 写入键
          Result := Result + WriteJsonString(LKey^.Data.Str, UnsafeGetLen(LKey), AFlags);

          if jwfPretty in AFlags then
            Result := Result + ': '
          else
            Result := Result + ':';

          // 写入值
          Result := Result + WriteJsonValue(LValue, AFlags, AIndent + 1);
        end;
      end;

      if jwfPretty in AFlags then
        Result := Result + sLineBreak + LIndentStr + '}'
      else
        Result := Result + '}';
    end;
  else
    Result := 'null';
  end;
end;

// 高级读取器 API 实现 (严格对应 yyjson_read_* 函数)
function JsonRead(const AData: PChar; ALen: SizeUInt; AFlags: TJsonReadFlags): TJsonDocument; inline;
var
  LError: TJsonError;
  LAllocator: IAllocator;
begin
  LAllocator := GetRtlAllocator();
  LError := Default(TJsonError);
  Result := JsonReadOpts(AData, ALen, AFlags, LAllocator, LError);
end;

function JsonReadOpts(const AData: PChar; ALen: SizeUInt; AFlags: TJsonReadFlags;
  AAllocator: IAllocator; var AError: TJsonError): TJsonDocument; inline;
var
  LHdr, LCur, LEnd: PByte;
  LBuf: PByte;
begin
  Result := nil;

  // 参数验证
  if not Assigned(AData) or (ALen = 0) then
  begin
    AError.Position := 0;
    AError.Code := jecInvalidParameter;
    AError.Message := ERR_INVALID_INPUT_DATA;
    Exit;
  end;

  if not Assigned(AAllocator) then
  begin
    AError.Position := 0;
    AError.Code := jecInvalidParameter;
    AError.Message := ERR_INVALID_ALLOCATOR;
    Exit;
  end;

  // 文档大小限额（若设置）
  if (JsonMaxDocBytes <> 0) and (ALen > JsonMaxDocBytes) then
  begin
    AError.Position := 0;
    AError.Code := jecMemoryAllocation;
    AError.Message := ERR_DOC_TOO_LARGE;
    Exit;
  end;

  // 为解析创建可写拷贝缓冲区，避免就地修改只读字符串导致崩溃
  // 分配 ALen + 8 字节，尾部写入哨兵 0 以便安全读取
  {$PUSH}
  {$WARN 5057 off}
  LBuf := PByte(AAllocator.GetMem(ALen + 8));
  {$POP}
  if not Assigned(LBuf) then
  begin
    AError.Position := 0;
    AError.Code := jecMemoryAllocation;
    AError.Message := 'Failed to allocate input buffer';
    Exit;
  end;
  Move(AData^, LBuf^, ALen);
  FillChar((LBuf + ALen)^, 8, 0);

  // 设置解析指针到可写缓冲
  LHdr := LBuf;
  LCur := LHdr;
  LEnd := LHdr + ALen;

  // 处理 UTF-8 BOM
  if (LCur + 2 < LEnd) and (LCur^ = $EF) and ((LCur + 1)^ = $BB) and ((LCur + 2)^ = $BF) then
  begin
    if (jrfAllowBOM in AFlags) then
      Inc(LCur, 3)
    else
    begin
      AError.Position := 0;
      AError.Code := jecUnexpectedCharacter;
      AError.Message := ERR_BOM_NOT_SUPPORTED;
      Exit;
    end;
  end;

  // 初始化错误信息
  AError.Position := 0;
  AError.Code := jecSuccess;
  AError.Message := '';

  // 设置全局读取 flags（供 ReadStr 放宽用）
  JsonGlobalReadFlags := AFlags; JsonPendingInvalidComment := False;

  // 跳过前导空白与注释
  SkipSpaces(LCur, LEnd, AFlags);
  if (LCur >= LEnd) then begin
    if JsonPendingInvalidComment then begin
      AError.Position := ALen; AError.Code := jecInvalidComment; AError.Message := ERR_UNCLOSED_ML_COMMENT;
    end else begin
      AError.Position := 0; AError.Code := jecEmptyContent; AError.Message := ERR_INPUT_EMPTY;
    end;
    Exit;
  end;

  if LCur >= LEnd then
  begin
    AError.Position := 0;
    AError.Code := jecEmptyContent;
    AError.Message := ERR_INPUT_EMPTY;
    Exit;
  end;

  // 如果在根部报错，覆盖 UTF-16/UTF-32 提示（对齐 yyjson）
  if (LCur = LHdr) and (AError.Code <> jecMemoryAllocation) then
  begin
    if (ALen >= 4) and (LCur^ = $00) and ((LCur + 1)^ = $00) and ((LCur + 2)^ = $FE) and ((LCur + 3)^ = $FF) then
      AError.Message := 'UTF-32 encoding is not supported'
    else if (ALen >= 4) and (LCur^ = $FF) and ((LCur + 1)^ = $FE) and ((LCur + 2)^ = $00) and ((LCur + 3)^ = $00) then
      AError.Message := 'UTF-32 encoding is not supported'
    else if (ALen >= 2) and (LCur^ = $FE) and ((LCur + 1)^ = $FF) then
      AError.Message := 'UTF-16 encoding is not supported'
    else if (ALen >= 2) and (LCur^ = $FF) and ((LCur + 1)^ = $FE) then
      AError.Message := 'UTF-16 encoding is not supported';
  end;

  // 根据第一个字符决定解析策略
  if (LCur^ = CHAR_LBRACE) or (LCur^ = CHAR_LBRACKET) then
  begin
    Result := ReadRootMinify(LHdr, LCur, LEnd, AAllocator, AFlags, AError);
  end
  else
  begin
    Result := ReadRootSingle(LHdr, LCur, LEnd, AAllocator, AFlags, AError);
  end;

  // 如果解析失败，释放输入缓冲
  if not Assigned(Result) then
  begin
    AAllocator.FreeMem(LHdr);
    Exit;
  end;

  // 保存输入缓冲到文档，供销毁时释放
  Result.FInputBuffer := LHdr;
end;

function JsonReadFile(const APath: String; AFlags: TJsonReadFlags;
  AAllocator: IAllocator; var AError: TJsonError): TJsonDocument; inline;
var
  LFileStream: TFileStream;
  LData: RawByteString; // use raw bytes to avoid implicit codepage conversions
  LSize: Int64;
begin
  Result := nil;

  SetLength(LData, 0);
  // 参数验证
  if APath = '' then
  begin
    AError.Position := 0;
    AError.Code := jecInvalidParameter;
    AError.Message := ERR_EMPTY_FILE_PATH;
    Exit;
  end;

  if not FileExists(APath) then
  begin
    AError.Position := 0;
    AError.Code := jecFileOpenError;
    AError.Message := 'failed to open file';
    Exit;
  end;

  try
    // 读取文件内容（按字节读取，保持 UTF-8 原样，不触发 RTL 转码）
    LFileStream := TFileStream.Create(APath, fmOpenRead or fmShareDenyWrite);
    try
      LSize := LFileStream.Size;
      if LSize = 0 then
      begin
        AError.Position := 0;
        AError.Code := jecEmptyContent;
        AError.Message := ERR_INPUT_EMPTY;
        Exit;
      end;

      if LSize > High(Integer) then
      begin
        AError.Position := 0;
        AError.Code := jecMemoryAllocation;
        AError.Message := 'File too large';
        Exit;
      end;

      // 分配额外 1 字节以确保以 #0 结尾，便于后续 PChar 安全使用
      SetLength(LData, LSize + 1);
      if LSize > 0 then
        LFileStream.ReadBuffer(LData[1], LSize);
      LData[LSize + 1] := #0;

      // 解析 JSON 数据
      AError := Default(TJsonError);
      Result := JsonReadOpts(PChar(@LData[1]), LSize, AFlags, AAllocator, AError);

    finally
      LFileStream.Free;
    end;
  except
    on E: Exception do
    begin
      AError.Position := 0;
      AError.Code := jecFileReadError;
      // 保留底层异常信息以便诊断
      AError.Message := 'failed to read file: ' + E.Message;
    end;
  end;
end;

function JsonReadMaxMemoryUsage(ALen: SizeUInt; AFlags: TJsonReadFlags): SizeUInt; inline;
var
  LMul, LPad, LMax, LLen: SizeUInt;
begin
  // 严格对齐 yyjson_read_max_memory_usage 实现：
  // size_t mul = 12 + !(flg & YYJSON_READ_INSITU);
  // size_t pad = 256;
  // size_t max = ~((size_t)0);
  // if (flg & YYJSON_READ_STOP_WHEN_DONE) len = len < 256 ? 256 : len;
  // if (len >= (max - pad - mul) / mul) return 0;
  // return len * mul + pad;
  LMul := 12 + 1; // 我们不支持 INSITU，因此恒为 +1
  LPad := 256;
  LMax := High(SizeUInt);
  LLen := ALen;
  if (jrfStopWhenDone in AFlags) and (LLen < 256) then
    LLen := 256;
  if LLen >= (LMax - LPad - LMul) div LMul then
    Exit(0);
  Result := LLen * LMul + LPad;
end;

function JsonReadNumber(const AData: PChar; ALen: SizeUInt): Double; inline;
var
  LVal: TJsonValue;
  LCur: PByte;
  LEnd: PByte;
  LMsg: String;
begin
  Result := 0.0;

  LMsg := '';
  if not Assigned(AData) or (ALen = 0) then
    Exit;

  LCur := PByte(AData);
  LEnd := LCur + ALen;

  // 跳过前导空白字符
  while (LCur < LEnd) and CharIsSpace(LCur^) do
    Inc(LCur);

  if LCur >= LEnd then
    Exit;

  // 尝试解析数字
  if ReadNum(LCur, LEnd, [], @LVal, LMsg) then
  begin
    // 成功解析，返回数字值
    case UInt8(LVal.Tag) and YYJSON_SUBTYPE_MASK of
      YYJSON_SUBTYPE_UINT: Result := Double(LVal.Data.U64);
      YYJSON_SUBTYPE_SINT: Result := Double(LVal.Data.I64);
      YYJSON_SUBTYPE_REAL: Result := LVal.Data.F64;
    end; // case
  end; // if ReadNum
end; // function JsonReadNumber

// --- Stream-based JSON writer (incremental, avoids O(n^2) string concatenation) ---
procedure _WriteRaw(AStream: TStream; const P: PChar; L: SizeUInt); inline;
begin
  if (AStream <> nil) and (P <> nil) and (L > 0) then
    AStream.WriteBuffer(P^, L);
end;


function NormalizeJsonFloatString(const S: String): String; inline;
var
  T, Mant, Expo: String;
  pE, pDot, j: Integer;
begin
  T := StringReplace(S, ',', '.', [rfReplaceAll]);
  // split exponent if any
  pE := Pos('E', T);
  if pE = 0 then pE := Pos('e', T);
  if pE > 0 then
  begin
    Mant := Copy(T, 1, pE - 1);
    Expo := Copy(T, pE, Length(T) - pE + 1);
  end
  else
  begin
    Mant := T;
    Expo := '';
  end;
  // trim trailing zeros after decimal point
  pDot := Pos('.', Mant);
  if pDot > 0 then
  begin
    j := Length(Mant);
    while (j > pDot) and (Mant[j] = '0') do Dec(j);
    if j = pDot then Dec(j); // remove the dot if no fraction left
    Mant := Copy(Mant, 1, j);
  end;
  // normalize -0 to 0
  if Mant = '-0' then Mant := '0';
  Result := Mant + Expo;
end;

procedure _WriteStr(AStream: TStream; const S: String); inline;
begin
  if (AStream <> nil) and (Length(S) > 0) then
    AStream.WriteBuffer(S[1], Length(S));
end;

procedure _WriteChar(AStream: TStream; C: AnsiChar); inline;
begin
  if (AStream <> nil) then
    AStream.WriteBuffer(C, 1);
end;


procedure WriteJsonStringToStream(const AStr: PChar; ALen: SizeUInt; AFlags: TJsonWriteFlags; AStream: TStream);
var
  I, Last: SizeUInt;
  C: AnsiChar;
  EscSlashes: Boolean;
  N: Byte;
  Hi, Lo: AnsiChar;
begin
  if (AStream = nil) or (AStr = nil) then Exit;
  // 若需要 Unicode 全转义，直接复用现有实现，保证语义一致
  if (jwfEscapeUnicode in AFlags) then
  begin
    _WriteStr(AStream, WriteJsonString(AStr, ALen, AFlags));
    Exit;
  end;
  EscSlashes := (jwfEscapeSlashes in AFlags);
  // 开始引号
  _WriteChar(AStream, '"');
  I := 0; Last := 0;
  while I < ALen do
  begin
    C := AStr[I];
    if (Ord(C) >= 32) and (Ord(C) < 128) and (C <> '"') and (C <> '\') and (not (EscSlashes and (C = '/'))) then
    begin
      Inc(I);
      Continue;
    end;
    // flush ASCII safe run [Last, I)
    if I > Last then _WriteRaw(AStream, @AStr[Last], I - Last);
    // handle special/escape
    case C of
      '"': begin _WriteRaw(AStream, PChar('"'), 2); Inc(I); end;
      '\': begin _WriteRaw(AStream, PChar('\\'), 2); Inc(I); end;
      '/':  begin if EscSlashes then begin _WriteRaw(AStream, PChar('\/'), 2); end else _WriteChar(AStream, '/'); Inc(I); end;
      #8:   begin _WriteRaw(AStream, PChar('\b'), 2); Inc(I); end;
      #9:   begin _WriteRaw(AStream, PChar('\t'), 2); Inc(I); end;
      #10:  begin _WriteRaw(AStream, PChar('\n'), 2); Inc(I); end;
      #12:  begin _WriteRaw(AStream, PChar('\f'), 2); Inc(I); end;
      #13:  begin _WriteRaw(AStream, PChar('\r'), 2); Inc(I); end;
    else
      if Ord(C) < 32 then
      begin
        _WriteRaw(AStream, PChar('\u00'), 4);
        N := Byte(C);
        Hi := AnsiChar(Ord('0') + ((N shr 4) and $F));
        Lo := AnsiChar(Ord('0') + (N and $F));
        if ((N shr 4) and $F) > 9 then Hi := AnsiChar(Ord('A') + ((N shr 4) and $F) - 10);
        if (N and $F) > 9 then Lo := AnsiChar(Ord('A') + (N and $F) - 10);
        _WriteChar(AStream, Hi);
        _WriteChar(AStream, Lo);
        Inc(I);
      end
      else
      begin
        _WriteChar(AStream, C);
        Inc(I);
      end;
    end;
    Last := I;
  end;
  // flush remainder
  if I > Last then _WriteRaw(AStream, @AStr[Last], I - Last);
  // 结束引号
  _WriteChar(AStream, '"');
end;

procedure _WriteUInt64(AStream: TStream; U: QWord); inline;
var
  Buf: array[0..31] of AnsiChar;
  P: Integer;
begin
  P := High(Buf);
  repeat
    Buf[P] := AnsiChar(Ord('0') + (U mod 10));
    U := U div 10;
    Dec(P);
  until U = 0;
  Inc(P);
  _WriteRaw(AStream, @Buf[P], SizeUInt(High(Buf) - P + 1));
end;

procedure _WriteInt64(AStream: TStream; I: Int64); inline;
begin
  if I < 0 then
  begin
    _WriteChar(AStream, '-');
    if I = Low(Int64) then
    begin
      // avoid overflow on abs(Low(Int64))
      _WriteRaw(AStream, PChar('9223372036854775808'), 19);
      Exit;
    end;
    _WriteUInt64(AStream, QWord(-I));
  end
  else
    _WriteUInt64(AStream, QWord(I));
end;


procedure WriteJsonNumberToStream(AVal: PJsonValue; AFlags: TJsonWriteFlags; AStream: TStream);
var
  LSubtype: UInt8;
  V: Double;
  S: String;
begin
  if (AStream = nil) then Exit;
  if not Assigned(AVal) or not UnsafeIsNum(AVal) then begin _WriteStr(AStream, 'null'); Exit; end;
  LSubtype := UInt8(AVal^.Tag) and YYJSON_SUBTYPE_MASK;
  case LSubtype of
    YYJSON_SUBTYPE_UINT: begin _WriteUInt64(AStream, AVal^.Data.U64); Exit; end;
    YYJSON_SUBTYPE_SINT: begin _WriteInt64(AStream, AVal^.Data.I64); Exit; end;
    YYJSON_SUBTYPE_REAL:
      begin
        V := AVal^.Data.F64;
        if IsNaN(V) then
        begin
          if jwfInfAndNanAsNull in AFlags then _WriteStr(AStream, 'null')
          else if jwfAllowInfAndNan in AFlags then _WriteStr(AStream, 'NaN');
          Exit;
        end
        else if IsInfinite(V) then
        begin
          if jwfInfAndNanAsNull in AFlags then _WriteStr(AStream, 'null')
          else if jwfAllowInfAndNan in AFlags then
            if Sign(V) < 0 then _WriteStr(AStream, '-Infinity') else _WriteStr(AStream, 'Infinity');
          Exit;
        end
        else
        begin
          S := NormalizeJsonFloatString(FloatToStrF(V, ffGeneral, 17, 0, DefaultFormatSettings));
          _WriteStr(AStream, S);
        end;
      end;
  else
    _WriteStr(AStream, 'null');
  end;
end;

procedure _WriteIndent(AStream: TStream; AIndent: Integer); inline;
var I: Integer;
begin
  for I := 1 to AIndent do _WriteRaw(AStream, PChar('  '), 2);
end;

// removed duplicate helpers (defined once above)

procedure SerializeJsonValueToStream(AVal: PJsonValue; AFlags: TJsonWriteFlags; AIndent: Integer; AStream: TStream);
var
  LType: UInt8;
  LLen: SizeUInt;
  LIter: TJsonArrayIterator;
  LObjIter: TJsonObjectIterator;
  LKey, LValue: PJsonValue;
  LFirst: Boolean;
begin
  if not Assigned(AVal) then begin _WriteStr(AStream, 'null'); Exit; end;
  LType := UnsafeGetType(AVal);
  case LType of
    YYJSON_TYPE_NULL: _WriteStr(AStream, 'null');
    YYJSON_TYPE_BOOL: if UnsafeIsTrue(AVal) then _WriteStr(AStream, 'true') else _WriteStr(AStream, 'false');
    YYJSON_TYPE_NUM: begin
      // number: write via helper (future: avoid intermediate string)
      WriteJsonNumberToStream(AVal, AFlags, AStream);
    end;
    YYJSON_TYPE_STR: begin
      // prefer fast path when no escaping needed
      if ((UInt8(AVal^.Tag) and YYJSON_SUBTYPE_NOESC) <> 0) and not (jwfEscapeUnicode in AFlags) and not (jwfEscapeSlashes in AFlags) then
      begin
        _WriteChar(AStream, '"');
        _WriteRaw(AStream, AVal^.Data.Str, UnsafeGetLen(AVal));
        _WriteChar(AStream, '"');
      end
      else
        WriteJsonStringToStream(AVal^.Data.Str, UnsafeGetLen(AVal), AFlags, AStream);
    end;
    YYJSON_TYPE_ARR: begin
      LLen := UnsafeGetLen(AVal);
      if LLen = 0 then begin _WriteStr(AStream, '[]'); Exit; end;
      if jwfPretty in AFlags then _WriteStr(AStream, '[' + sLineBreak) else _WriteChar(AStream, '[');
      LFirst := True;
      if JsonArrIterInit(AVal, @LIter) then
      begin
        while JsonArrIterHasNext(@LIter) do
        begin
          LValue := JsonArrIterNext(@LIter);
          if not LFirst then begin if jwfPretty in AFlags then _WriteStr(AStream, ',' + sLineBreak) else _WriteChar(AStream, ','); end;
          LFirst := False;
          if jwfPretty in AFlags then _WriteIndent(AStream, AIndent + 1);
          SerializeJsonValueToStream(LValue, AFlags, AIndent + 1, AStream);
        end;
      end;
      if jwfPretty in AFlags then begin _WriteStr(AStream, sLineBreak); _WriteIndent(AStream, AIndent); _WriteChar(AStream, ']'); end
      else _WriteChar(AStream, ']');
    end;
    YYJSON_TYPE_OBJ: begin
      LLen := UnsafeGetLen(AVal);
      if LLen = 0 then begin _WriteStr(AStream, '{}'); Exit; end;
      if jwfPretty in AFlags then _WriteStr(AStream, '{' + sLineBreak) else _WriteChar(AStream, '{');
      LFirst := True;
      if JsonObjIterInit(AVal, @LObjIter) then
      begin
        while JsonObjIterHasNext(@LObjIter) do
        begin
          LKey := JsonObjIterNext(@LObjIter);
          LValue := JsonObjIterGetVal(LKey);
          if not LFirst then begin if jwfPretty in AFlags then _WriteStr(AStream, ',' + sLineBreak) else _WriteChar(AStream, ','); end;
          LFirst := False;
          if jwfPretty in AFlags then _WriteIndent(AStream, AIndent + 1);
          // key
          WriteJsonStringToStream(LKey^.Data.Str, UnsafeGetLen(LKey), AFlags, AStream);
          if jwfPretty in AFlags then _WriteStr(AStream, ': ') else _WriteChar(AStream, ':');
          // value
          SerializeJsonValueToStream(LValue, AFlags, AIndent + 1, AStream);
        end;
      end;
      if jwfPretty in AFlags then begin _WriteStr(AStream, sLineBreak); _WriteIndent(AStream, AIndent); _WriteChar(AStream, '}'); end
      else _WriteChar(AStream, '}');
    end
  else
    _WriteStr(AStream, 'null');
  end;
end;

// 写入器 API 实现 (严格对应 yyjson_write_* 函数)
function JsonWrite(ADoc: TJsonDocument; AFlags: TJsonWriteFlags; var ALen: SizeUInt): PChar;
var
  LError: TJsonWriteError;
  LAllocator: IAllocator;
begin
  LAllocator := GetRtlAllocator();
  LError := Default(TJsonWriteError);
  Result := JsonWriteOpts(ADoc, AFlags, LAllocator, ALen, LError);
end;

function JsonWrite(ADoc: TJsonDocument; out ALen: SizeUInt): PChar; inline;
begin
  ALen := 0;
  Result := JsonWrite(ADoc, [], ALen);
end;

function JsonWriteToStream(ADoc: TJsonDocument; AStream: TStream; AFlags: TJsonWriteFlags): Boolean;
var Root: PJsonValue;
begin
  Result := False;
  if (ADoc = nil) or (AStream = nil) then Exit;
  Root := JsonDocGetRoot(ADoc);
  if Root = nil then Exit;
  SerializeJsonValueToStream(Root, AFlags, 0, AStream);
  Result := True;
end;



function JsonWriteToString(ADoc: TJsonDocument; AFlags: TJsonWriteFlags): String; inline;
var L: SizeUInt; P: PChar; Alc: TAllocator;
begin
  Result := '';
  if (ADoc = nil) then Exit;
  L := 0;
  P := JsonWrite(ADoc, AFlags, L);
  if P <> nil then
  begin
    SetString(Result, P, L);
    Alc := GetRtlAllocator();
    if Assigned(Alc) then Alc.FreeMem(P);
  end;
end;

function JsonWriteOpts(ADoc: TJsonDocument; AFlags: TJsonWriteFlags; AAllocator: IAllocator;
  var ALen: SizeUInt; var AError: TJsonWriteError): PChar;
var
  LRoot: PJsonValue;
  LResult: PChar;
  LMem: TMemoryStream;
  function ContainsDisallowedNaNInf(AVal: PJsonValue): Boolean;
  var LType: UInt8; LIter: TJsonArrayIterator; LObjIter: TJsonObjectIterator; V: PJsonValue; K: PJsonValue;
  begin
    Result := False;
    if AVal = nil then Exit(False);
    LType := UnsafeGetType(AVal);
    case LType of
      YYJSON_TYPE_NUM:
        begin
          if UnsafeIsReal(AVal) then
            if (not (jwfAllowInfAndNan in AFlags)) and (not (jwfInfAndNanAsNull in AFlags)) then
              if IsNaN(AVal^.Data.F64) or IsInfinite(AVal^.Data.F64) then Exit(True);
        end;
      YYJSON_TYPE_ARR:
        begin
          if JsonArrIterInit(AVal, @LIter) then
            while JsonArrIterHasNext(@LIter) do
            begin
              V := JsonArrIterNext(@LIter);
              if ContainsDisallowedNaNInf(V) then Exit(True);
            end;
        end;
      YYJSON_TYPE_OBJ:
        begin
          if JsonObjIterInit(AVal, @LObjIter) then
            while JsonObjIterHasNext(@LObjIter) do
            begin
              K := JsonObjIterNext(@LObjIter);
              V := JsonObjIterGetVal(K);
              if ContainsDisallowedNaNInf(V) then Exit(True);
            end;
        end;
    end;
  end;
begin
  Result := nil;
  ALen := 0;

  // 参数验证
  if not Assigned(ADoc) then
  begin
    AError.Code := jwecInvalidParameter;
    AError.Message := ERR_DOC_NULL;
    Exit;
  end;

  if not Assigned(AAllocator) then
  begin
    AError.Code := jwecInvalidParameter;
    AError.Message := 'Allocator is null';
    Exit;
  end;

  LRoot := JsonDocGetRoot(ADoc);
  if not Assigned(LRoot) then
  begin
    AError.Code := jwecInvalidParameter;
    AError.Message := 'Document has no root value';
    Exit;
  end;

  // 初始化错误信息
  AError.Code := jwecSuccess;
  AError.Message := '';

  try
    // 检查是否存在被禁止的 NaN/Infinity
    if ContainsDisallowedNaNInf(LRoot) then
    begin
      AError.Code := jwecNanOrInf;
      AError.Message := 'NaN or Infinity not allowed by flags';
      Exit;
    end;

    // 流式序列化到内存流，避免 O(n^2) 字符串拼接
    LMem := TMemoryStream.Create;
    try
      SerializeJsonValueToStream(LRoot, AFlags, 0, LMem);
      ALen := LMem.Size;
      if ALen = 0 then
      begin
        Result := PChar(AAllocator.GetMem(1));
        if Assigned(Result) then Result[0] := #0;
        Exit;
      end;
      LResult := PChar(AAllocator.GetMem(ALen + 1));
      if not Assigned(LResult) then
      begin
        AError.Code := jwecMemoryAllocation;
        AError.Message := 'Failed to allocate output buffer';
        Exit;
      end;
      Move(LMem.Memory^, LResult^, ALen);
      LResult[ALen] := #0;
      Result := LResult;
    finally
      LMem.Free;
    end;

  except
    on E: Exception do
    begin
      AError.Code := jwecInvalidValueType;
      AError.Message := 'Serialization error: ' + E.Message;
      if Assigned(LResult) then
        AAllocator.FreeMem(LResult);
    end;
  end;
end;

function JsonWriteFile(const APath: String; ADoc: TJsonDocument; AFlags: TJsonWriteFlags;
  AAllocator: IAllocator; var AError: TJsonWriteError): Boolean;
var
  LFileStream: TFileStream;
  LData: PChar;
  LLen: SizeUInt;
begin
  Result := False;

  LLen := 0;
  // 参数验证
  if APath = '' then
  begin
    AError.Code := jwecInvalidParameter;
    AError.Message := 'Empty file path';
    Exit;
  end;

  if not Assigned(ADoc) then
  begin
    AError.Code := jwecInvalidParameter;
    AError.Message := ERR_DOC_NULL;
    Exit;
  end;

  // 序列化 JSON 数据
  AError := Default(TJsonWriteError);
  LData := JsonWriteOpts(ADoc, AFlags, AAllocator, LLen, AError);
  if not Assigned(LData) then
    Exit;

  try
    // 写入文件
    LFileStream := TFileStream.Create(APath, fmCreate);
    try
      LFileStream.WriteBuffer(LData^, LLen);
      Result := True;
      AError.Code := jwecSuccess;
      AError.Message := '';
    finally
      LFileStream.Free;
    end;
  except

    on E: Exception do
    begin
      AError.Code := jwecFileWriteError;
      AError.Message := 'File write error: ' + E.Message;
    end;
  end;

  // 释放序列化数据
  if Assigned(LData) then
    AAllocator.FreeMem(LData);
end;

function JsonWriteNumber(AVal: PJsonValue; ABuf: PChar): PChar;
var
  LNumStr: String;
begin
  if not Assigned(AVal) or not Assigned(ABuf) then
  begin
    Result := ABuf;
    Exit;
  end;

  LNumStr := WriteJsonNumber(AVal, []);
  Move(LNumStr[1], ABuf^, Length(LNumStr));
  Result := ABuf + Length(LNumStr);
end;

// ReadRootSingle 实现 (严格对应 yyjson read_root_single)
function ReadRootSingle(AHdr, ACur, AEnd: PByte; AAlc: IAllocator;
  AFlg: TJsonReadFlags; var AErr: TJsonError): TJsonDocument;
var
  LHdrLen: SizeUInt;
  LAlcNum: SizeUInt;
  LValHdr: PJsonValue;
  LVal: PJsonValue;
  LDoc: TJsonDocument;
  LMsg: String;
  LParsed: Boolean;

  // 内联错误处理宏 (对应 yyjson return_err)
  procedure ReturnErr(APos: PByte; ACode: TJsonErrorCode; const AMessage: String);
  begin
    AErr.Position := APos - AHdr;
    AErr.Code := ACode;
    AErr.Message := AMessage;
    if Assigned(LValHdr) then
      AAlc.FreeMem(LValHdr);
    Result := nil;
  end;

begin
  Result := nil;
  LValHdr := nil;

  // 计算头部长度 (对应 yyjson hdr_len 计算)
  LHdrLen := SizeOf(TJsonDocument) div SizeOf(TJsonValue);
  if (SizeOf(TJsonDocument) mod SizeOf(TJsonValue)) > 0 then
    Inc(LHdrLen);
  LAlcNum := LHdrLen + 1; // 单个值

  // 分配内存 (对应 yyjson val_hdr 分配)
  LValHdr := PJsonValue(AAlc.GetMem(LAlcNum * SizeOf(TJsonValue)));
  if not Assigned(LValHdr) then
  begin
    ReturnErr(ACur, jecMemoryAllocation, 'Failed to allocate memory for JSON value');
    Exit;
  end;

  // 初始化内存
  FillChar(LValHdr^, LAlcNum * SizeOf(TJsonValue), 0);
  LVal := LValHdr + LHdrLen;

  // 跳过前导空白/注释
  SkipSpaces(ACur, AEnd, AFlg);

  if ACur >= AEnd then
  begin
    ReturnErr(ACur, jecUnexpectedEnd, ERR_UNEXPECTED_END);
    Exit;
  end;

  // 先尝试 Inf/NaN 快速路径
  LParsed := False;
  if (jrfAllowInfAndNan in AFlg) then
  begin
    if (ACur^ = CHAR_MINUS) and (ACur + 1 < AEnd) and (((ACur + 1)^ in [Ord('i'), Ord('I'), Ord('n'), Ord('N')])) then
    begin
      Inc(ACur);
      if ReadInfOrNan(ACur, AEnd, AFlg, True, LVal) then
        LParsed := True
      else
        Dec(ACur);
    end
    else if (ACur^ in [Ord('i'), Ord('I'), Ord('n'), Ord('N')]) then
    begin
      if ReadInfOrNan(ACur, AEnd, AFlg, False, LVal) then
        LParsed := True;
    end;
  end;

  // number-as-raw: 单值直接走 RAW 路径
  if (jrfNumberAsRaw in AFlg) then
  begin
    ReadNumberRaw(ACur, AEnd, LVal);
  end
  else
  // 解析单个值 (对应 yyjson 单值解析)
  if not LParsed then
  case ACur^ of
    CHAR_N_LOWER: // null or NaN
      if (jrfAllowInfAndNan in AFlg) and ReadInfOrNan(ACur, AEnd, AFlg, False, LVal) then
      begin
        // parsed NaN
      end
      else if not ReadNull(ACur, LVal) then
      begin
        ReturnErr(ACur, jecInvalidLiteral, ERR_INVALID_NULL);
        Exit;
      end;
    CHAR_T_LOWER: // true
      if not ReadTrue(ACur, LVal) then
      begin
        ReturnErr(ACur, jecInvalidLiteral, ERR_INVALID_TRUE);
        Exit;
      end;
    CHAR_F_LOWER: // false
      if not ReadFalse(ACur, LVal) then
      begin
        ReturnErr(ACur, jecInvalidLiteral, ERR_INVALID_FALSE);
        Exit;
      end;
    CHAR_QUOTE: // string
      if not ReadStr(ACur, AEnd, LVal, LMsg) then
      begin
        ReturnErr(ACur, jecInvalidString, LMsg);
        Exit;
      end;
    CHAR_MINUS: // number or -inf/-nan
      if (jrfNumberAsRaw in AFlg) then
      begin
        if not ReadNumberRaw(ACur, AEnd, LVal) then begin ReturnErr(ACur, jecInvalidNumber, ERR_INVALID_NUM); Exit; end;
      end
      else if (jrfAllowInfAndNan in AFlg) and (ACur + 1 < AEnd) and (((ACur + 1)^ in [Ord('i'), Ord('I'), Ord('n'), Ord('N')])) then
      begin
        Inc(ACur); // skip '-'
        if not ReadInfOrNan(ACur, AEnd, AFlg, True, LVal) then
        begin
          ReturnErr(ACur, jecInvalidNumber, ERR_INVALID_INFNAN);
          Exit;
        end;
      end
      else if not ReadNum(ACur, AEnd, AFlg, LVal, LMsg) then
      begin
        ReturnErr(ACur, jecInvalidNumber, LMsg);
        Exit;
      end;
    CHAR_0..CHAR_9: // number
      if (jrfNumberAsRaw in AFlg) then
      begin
        ReadNumberRaw(ACur, AEnd, LVal);
      end
      else if not ReadNum(ACur, AEnd, AFlg, LVal, LMsg) then
      begin
        ReturnErr(ACur, jecInvalidNumber, LMsg);
        Exit;
      end;
  else if (ACur^ in [Ord('i'), Ord('I'), Ord('n'), Ord('N')]) then
  begin
    // 允许 Inf/NaN
    if not ReadInfOrNan(ACur, AEnd, AFlg, False, LVal) then
    begin
      ReturnErr(ACur, jecUnexpectedCharacter, ERR_UNEXPECTED_VALUE);
      Exit;
    end;
  end
  else
    ReturnErr(ACur, jecUnexpectedCharacter, ERR_UNEXPECTED_VALUE);
    Exit;
  end;

// 跳过尾随空白/注释
  SkipSpaces(ACur, AEnd, AFlg);

  // 检查是否还有多余字符 (严格模式除非 StopWhenDone)
  if (ACur < AEnd) and not (jrfStopWhenDone in AFlg) then
  begin
    ReturnErr(ACur, jecUnexpectedContent, ERR_UNEXPECTED_CONTENT);
    Exit;
  end;

  // 创建文档对象 (对应 yyjson 文档创建)
  LDoc := TJsonDocument.Create(AAlc);
  LDoc.FRoot := LVal;
  LDoc.FBytesRead := ACur - AHdr;
  LDoc.FValuesRead := 1;
  LDoc.FValueBuffer := LValHdr;  // 保存缓冲区指针以便正确释放

  Result := LDoc;
end;

// ReadRootMinify 实现 (严格对应 yyjson read_root_minify)
function ReadRootMinify(AHdr, ACur, AEnd: PByte; AAlc: IAllocator;
  AFlg: TJsonReadFlags; var AErr: TJsonError): TJsonDocument;
var
  LDatLen: SizeUInt;        // data length in bytes, hint for allocator
  LHdrLen: SizeUInt;        // value count used by yyjson_doc
  LAlcLen: SizeUInt;        // value count allocated
  LAlcMax: SizeUInt;        // maximum value count for allocator
  LCtnLen: SizeUInt;        // the number of elements in current container
  LParsedVal: Boolean;      // flag to skip case when Inf/NaN matched
  LValHdr: PJsonValue;      // the head of allocated values
  LValEnd: PJsonValue;      // the end of allocated values
  LValTmp: PJsonValue;      // temporary pointer for realloc
  LVal: PJsonValue;         // current JSON value
  LCtn: PJsonValue;         // current container
  // LCtnParent: PJsonValue;   // parent of current container (unused)
  LDoc: TJsonDocument;      // the JSON document
  LMsg: String;             // error message
  LScan: PByte;             // scanner for lookahead (e.g., trailing comma)


  // 前向声明，处理对象/数组的相互递归
  procedure ParseObjectValue; forward;
  procedure ParseArrayValue; forward;

  // 内联宏函数 (对应 yyjson 宏定义)
  procedure ReturnErr(APos: PByte; ACode: TJsonErrorCode; const AMessage: String);
  begin
    AErr.Position := APos - AHdr;
    AErr.Code := ACode;
    AErr.Message := AMessage;
    if Assigned(LValHdr) then
      AAlc.FreeMem(LValHdr);
    Result := nil;
  end;

  // val_incr 宏 (对应 yyjson val_incr)
  procedure ValIncr;
  var
    // LAlcOld: SizeUInt; // unused
    LValOfs: SizeUInt;
    LCtnOfs: SizeUInt;
  begin
    Inc(LVal);
    if LVal >= LValEnd then
    begin
      // keep capacity growth old value for potential debugging
      // LAlcOld := LAlcLen; // removed unused var
      { $IFDEF DEBUG }
      // noop to keep symbol referenced when needed
      // if False then WriteStr(LTmp, LAlcOld);
      { $ENDIF }

      LValOfs := LVal - LValHdr;
      LCtnOfs := LCtn - LValHdr;
      LAlcLen := LAlcLen + LAlcLen div 2;
      {$IFNDEF CPU64}
      if (LAlcLen >= LAlcMax) then
      begin
        ReturnErr(ACur, jecMemoryAllocation, 'Memory allocation limit exceeded');
        Exit;
      end;
      {$ENDIF}
      LValTmp := PJsonValue(AAlc.ReallocMem(LValHdr, LAlcLen * SizeOf(TJsonValue)));
      if not Assigned(LValTmp) then
      begin
        ReturnErr(ACur, jecMemoryAllocation, 'Failed to reallocate memory');
        Exit;
      end;
      LVal := LValTmp + LValOfs;
      LCtn := LValTmp + LCtnOfs;
      LValHdr := LValTmp;
      LValEnd := LValTmp + (LAlcLen - 2);
    end;
        if (JsonMaxValues <> 0) and (LCtnLen >= JsonMaxValues) then begin ReturnErr(ACur, jecJsonStructure, ERR_MAX_VALUES); Exit; end;

  end;
  // 解析嵌套对象，当前 ACur^ 应为 '{'，LVal 指向已分配的值槽位
  procedure ParseObjectValue;
  var SavedCtnOfs: SizeUInt; SavedLen: SizeUInt; LParsed: Boolean;
  begin
    if (ACur >= AEnd) or (ACur^ <> CHAR_LBRACE) then begin ReturnErr(ACur, jecUnexpectedCharacter, 'Expected "{" for object'); Exit; end;
    Inc(ACur);
    SavedCtnOfs := SizeUInt(LCtn - LValHdr); SavedLen := LCtnLen;
    LCtn := LVal; LCtn^.Tag := YYJSON_TYPE_OBJ; LCtn^.Data.U64 := 0; LCtnLen := 0;
    if (JsonMaxDepth <> 0) and (SavedLen >= JsonMaxDepth) then begin ReturnErr(ACur, jecJsonStructure, ERR_MAX_DEPTH); Exit; end;
    SkipSpaces(ACur, AEnd, AFlg);
    if ACur >= AEnd then begin ReturnErr(ACur, jecUnexpectedEnd, ERR_UNEXPECTED_END); Exit; end;
    if ACur^ = CHAR_RBRACE then begin Inc(ACur); end else
    begin
      repeat
        SkipSpaces(ACur, AEnd, AFlg);
        if ACur >= AEnd then begin ReturnErr(ACur, jecUnexpectedEnd, ERR_UNEXPECTED_END); Exit; end;
        if ACur^ <> CHAR_QUOTE then begin ReturnErr(ACur, jecUnexpectedCharacter, ERR_EXPECT_KEY); Exit; end;
        ValIncr; Inc(LCtnLen);
        if not ReadStr(ACur, AEnd, LVal, LMsg) then begin ReturnErr(ACur, jecInvalidString, LMsg); Exit; end;
        SkipSpaces(ACur, AEnd, AFlg);
        if ACur >= AEnd then begin ReturnErr(ACur, jecUnexpectedEnd, ERR_UNEXPECTED_END); Exit; end;
        if ACur^ <> CHAR_COLON then begin ReturnErr(ACur, jecUnexpectedCharacter, ERR_EXPECT_COLON); Exit; end;
        Inc(ACur);
        SkipSpaces(ACur, AEnd, AFlg);
        if ACur >= AEnd then begin ReturnErr(ACur, jecUnexpectedEnd, ERR_UNEXPECTED_END); Exit; end;
        ValIncr; LParsed := False;
        if (jrfAllowInfAndNan in AFlg) then begin
          if (ACur^ = CHAR_MINUS) and (ACur + 1 < AEnd) and (((ACur + 1)^ in [Ord('i'), Ord('I'), Ord('n'), Ord('N')])) then begin Inc(ACur); if ReadInfOrNan(ACur, AEnd, AFlg, True, LVal) then LParsed := True else Dec(ACur); end
          else if (ACur^ in [Ord('i'), Ord('I'), Ord('n'), Ord('N')]) then begin if ReadInfOrNan(ACur, AEnd, AFlg, False, LVal) then LParsed := True; end;
        end;
        if not LParsed then
          case ACur^ of
            CHAR_LBRACE: ParseObjectValue;
            CHAR_LBRACKET: ParseArrayValue;
            CHAR_N_LOWER: if not ReadNull(ACur, LVal) then begin ReturnErr(ACur, jecInvalidLiteral, 'invalid literal, expected ''null'''); Exit; end;
            CHAR_T_LOWER: if not ReadTrue(ACur, LVal) then begin ReturnErr(ACur, jecInvalidLiteral, 'invalid literal, expected ''true'''); Exit; end;
            CHAR_F_LOWER: if not ReadFalse(ACur, LVal) then begin ReturnErr(ACur, jecInvalidLiteral, 'invalid literal, expected ''false'''); Exit; end;
            CHAR_QUOTE: if not ReadStr(ACur, AEnd, LVal, LMsg) then begin ReturnErr(ACur, jecInvalidString, LMsg); Exit; end;
            CHAR_MINUS: if not ReadNum(ACur, AEnd, AFlg, LVal, LMsg) then begin ReturnErr(ACur, jecInvalidNumber, LMsg); Exit; end;
            CHAR_0..CHAR_9: if not ReadNum(ACur, AEnd, AFlg, LVal, LMsg) then begin ReturnErr(ACur, jecInvalidNumber, LMsg); Exit; end;
          else ReturnErr(ACur, jecUnexpectedCharacter, ERR_UNEXPECTED_VALUE); Exit;
          end;
        SkipSpaces(ACur, AEnd, AFlg);
        if ACur >= AEnd then begin ReturnErr(ACur, jecUnexpectedEnd, ERR_UNEXPECTED_END); Exit; end;
        if ACur^ = CHAR_RBRACE then begin Inc(ACur); Break; end
        else if ACur^ = CHAR_COMMA then begin
          LScan := ACur + 1; SkipSpaces(LScan, AEnd, AFlg);
          if (LScan < AEnd) and (LScan^ = CHAR_RBRACE) then begin
            if (jrfAllowTrailingCommas in AFlg) then begin ACur := LScan + 1; Break; end
            else begin ReturnErr(ACur, jecJsonStructure, 'trailing comma is not allowed'); Exit; end;
          end else begin
            Inc(ACur);
          end;
        end else begin ReturnErr(ACur, jecUnexpectedCharacter, 'Unexpected character, expected '','' or ''}'''); Exit; end;
      until False;
    end;
    // 设置长度并恢复父容器
    LCtn^.Tag := (UInt64(LCtnLen) shl YYJSON_TAG_BIT) or (LCtn^.Tag and YYJSON_TYPE_MASK);
    // 计算容器跨度（自身 + 所有子节点），用于 UnsafeGetNext 跳过整个容器
        if (JsonMaxValues <> 0) and (LCtnLen >= JsonMaxValues) then begin ReturnErr(ACur, jecJsonStructure, ERR_MAX_VALUES); Exit; end;

    LCtn^.Data.U64 := SizeUInt((LVal - LCtn) + 1) * SizeOf(TJsonValue);
    // 恢复父容器（使用偏移恢复，避免 ValIncr 触发的 Realloc 后悬挂指针）
    LCtn := LValHdr + SavedCtnOfs; LCtnLen := SavedLen;
  end;

  // 解析嵌套数组，当前 ACur^ 应为 '['，LVal 指向已分配的值槽位
  procedure ParseArrayValue;
  var SavedCtnOfs: SizeUInt; SavedLen: SizeUInt; LParsed: Boolean;
  begin
    if (ACur >= AEnd) or (ACur^ <> CHAR_LBRACKET) then begin ReturnErr(ACur, jecUnexpectedCharacter, ERR_UNEXPECTED_VALUE); Exit; end;
    Inc(ACur);
    SavedCtnOfs := SizeUInt(LCtn - LValHdr); SavedLen := LCtnLen;
    LCtn := LVal; LCtn^.Tag := YYJSON_TYPE_ARR; LCtn^.Data.U64 := 0; LCtnLen := 0;
    if (JsonMaxDepth <> 0) and (SavedLen >= JsonMaxDepth) then begin ReturnErr(ACur, jecJsonStructure, ERR_MAX_DEPTH); Exit; end;
    SkipSpaces(ACur, AEnd, AFlg);
    if ACur >= AEnd then begin ReturnErr(ACur, jecUnexpectedEnd, ERR_UNEXPECTED_END); Exit; end;
    if ACur^ = CHAR_RBRACKET then begin Inc(ACur); end else
    begin
      repeat
        SkipSpaces(ACur, AEnd, AFlg);
        if ACur >= AEnd then begin ReturnErr(ACur, jecUnexpectedEnd, ERR_UNEXPECTED_END); Exit; end;
        ValIncr; Inc(LCtnLen); LParsed := False;
        if (jrfAllowInfAndNan in AFlg) then begin
          if (ACur^ = CHAR_MINUS) and (ACur + 1 < AEnd) and (((ACur + 1)^ in [Ord('i'), Ord('I'), Ord('n'), Ord('N')])) then begin Inc(ACur); if ReadInfOrNan(ACur, AEnd, AFlg, True, LVal) then LParsed := True else Dec(ACur); end
          else if (ACur^ in [Ord('i'), Ord('I'), Ord('n'), Ord('N')]) then begin if ReadInfOrNan(ACur, AEnd, AFlg, False, LVal) then LParsed := True; end;
        end;
        if not LParsed then
          case ACur^ of
            CHAR_LBRACE: ParseObjectValue;
            CHAR_N_LOWER: if not ReadNull(ACur, LVal) then begin ReturnErr(ACur, jecInvalidLiteral, ERR_INVALID_NULL); Exit; end;
            CHAR_T_LOWER: if not ReadTrue(ACur, LVal) then begin ReturnErr(ACur, jecInvalidLiteral, ERR_INVALID_TRUE); Exit; end;
            CHAR_F_LOWER: if not ReadFalse(ACur, LVal) then begin ReturnErr(ACur, jecInvalidLiteral, ERR_INVALID_FALSE); Exit; end;
            CHAR_QUOTE: if not ReadStr(ACur, AEnd, LVal, LMsg) then begin ReturnErr(ACur, jecInvalidString, LMsg); Exit; end;
            CHAR_MINUS: if not ReadNum(ACur, AEnd, AFlg, LVal, LMsg) then begin ReturnErr(ACur, jecInvalidNumber, LMsg); Exit; end;
            CHAR_0..CHAR_9: if not ReadNum(ACur, AEnd, AFlg, LVal, LMsg) then begin ReturnErr(ACur, jecInvalidNumber, LMsg); Exit; end;
          else ReturnErr(ACur, jecUnexpectedCharacter, ERR_UNEXPECTED_VALUE); Exit;
          end;
        SkipSpaces(ACur, AEnd, AFlg);
        if ACur >= AEnd then begin ReturnErr(ACur, jecUnexpectedEnd, ERR_UNEXPECTED_END); Exit; end;
        if ACur^ = CHAR_RBRACKET then begin Inc(ACur); Break; end
        else if ACur^ = CHAR_COMMA then begin
          LScan := ACur + 1; SkipSpaces(LScan, AEnd, AFlg);
          if (LScan < AEnd) and (LScan^ = CHAR_RBRACKET) then begin
            if (jrfAllowTrailingCommas in AFlg) then begin ACur := LScan + 1; Break; end
            else begin ReturnErr(ACur, jecJsonStructure, 'trailing comma is not allowed'); Exit; end;
          end else begin
            Inc(ACur);
          end;
        end else begin ReturnErr(ACur, jecUnexpectedCharacter, 'Unexpected character, expected '','' or '']'''); Exit; end;
      until False;
    end;
    // 设置容器长度与跨度（数组）
    LCtn^.Tag := (UInt64(LCtnLen) shl YYJSON_TAG_BIT) or (LCtn^.Tag and YYJSON_TYPE_MASK);
    LCtn^.Data.U64 := SizeUInt((LVal - LCtn) + 1) * SizeOf(TJsonValue);
    // 恢复父容器（使用偏移恢复，避免 ValIncr 触发的 Realloc 后悬挂指针）
    LCtn := PJsonValue(LValHdr + SavedCtnOfs); LCtnLen := SavedLen;
  end;


begin
  Result := nil;
  LValHdr := nil;

  // 计算初始分配大小 (对应 yyjson 计算逻辑)
  LDatLen := AEnd - ACur;
  LHdrLen := SizeOf(TJsonDocument) div SizeOf(TJsonValue);
  if (SizeOf(TJsonDocument) mod SizeOf(TJsonValue)) > 0 then
    Inc(LHdrLen);
  LAlcMax := High(SizeUInt) div SizeOf(TJsonValue);
  LAlcLen := LHdrLen + (LDatLen div YYJSON_READER_ESTIMATED_MINIFY_RATIO) + 4;
  if LAlcLen > LAlcMax then
    LAlcLen := LAlcMax;

  // 分配初始内存
  LValHdr := PJsonValue(AAlc.GetMem(LAlcLen * SizeOf(TJsonValue)));
  if not Assigned(LValHdr) then
  begin
    ReturnErr(ACur, jecMemoryAllocation, 'Failed to allocate initial memory');
    Exit;
  end;

  // 初始化变量
  LValEnd := LValHdr + (LAlcLen - 2); // padding for key-value pair reading
  LVal := LValHdr + LHdrLen;
  LCtn := LVal;
  LCtnLen := 0;

  // 跳过前导空白/注释
  SkipSpaces(ACur, AEnd, AFlg);

  if ACur >= AEnd then
  begin
    ReturnErr(ACur, jecUnexpectedEnd, ERR_UNEXPECTED_END);
    Exit;
  end;

  // 确定根容器类型并开始解析 (对应 yyjson 逻辑)
  if ACur^ = CHAR_LBRACE then // '{'
  begin
    Inc(ACur);
    LCtn^.Tag := YYJSON_TYPE_OBJ;
    LCtn^.Data.U64 := 0;

    // 完整的对象解析 (对应 yyjson obj_key_begin)
    SkipSpaces(ACur, AEnd, AFlg);

    if ACur >= AEnd then
    begin
      ReturnErr(ACur, jecUnexpectedEnd, ERR_UNEXPECTED_END);
      Exit;
    end;

    // 检查空对象
    if ACur^ = CHAR_RBRACE then // '}'
    begin
      Inc(ACur);
      // 空对象解析成功
    end
    else
    begin
      // 解析对象键值对
      repeat
        // 跳过空白/注释
        SkipSpaces(ACur, AEnd, AFlg);

        if ACur >= AEnd then
        begin
          ReturnErr(ACur, jecUnexpectedEnd, ERR_UNEXPECTED_END);
          Exit;
        end;

        // 解析键 (必须是字符串)
        if ACur^ <> CHAR_QUOTE then
        begin
          ReturnErr(ACur, jecUnexpectedCharacter, ERR_EXPECT_KEY);
          Exit;
        end;

        // 分配键的值空间
        ValIncr;
        Inc(LCtnLen);

        // 解析键字符串
        if not ReadStr(ACur, AEnd, LVal, LMsg) then
        begin
          ReturnErr(ACur, jecInvalidString, LMsg);
          Exit;
        end;

        // 跳过空白/注释
        SkipSpaces(ACur, AEnd, AFlg);

        if ACur >= AEnd then
        begin
          ReturnErr(ACur, jecUnexpectedEnd, ERR_UNEXPECTED_END);
          Exit;
        end;

        // 检查冒号
        if ACur^ <> CHAR_COLON then
        begin
          ReturnErr(ACur, jecUnexpectedCharacter, ERR_EXPECT_COLON);
          Exit;
        end;
        Inc(ACur);

        // 跳过空白/注释
        SkipSpaces(ACur, AEnd, AFlg);

        if ACur >= AEnd then
        begin
          ReturnErr(ACur, jecUnexpectedEnd, ERR_UNEXPECTED_END);
          Exit;
        end;

        // 分配值的空间
        ValIncr;

        LParsedVal := False;
        // 允许值为 Inf/NaN 的快速路径
        if (jrfAllowInfAndNan in AFlg) then
        begin
          if (ACur^ = CHAR_MINUS) and (ACur + 1 < AEnd) and (((ACur + 1)^ in [Ord('i'), Ord('I'), Ord('n'), Ord('N')])) then
          begin
            Inc(ACur);
            if ReadInfOrNan(ACur, AEnd, AFlg, True, LVal) then LParsedVal := True;
            Dec(ACur);
          end
          else if (ACur^ in [Ord('i'), Ord('I'), Ord('n'), Ord('N')]) then
          begin
            if ReadInfOrNan(ACur, AEnd, AFlg, False, LVal) then LParsedVal := True;
          end;
        end;

        // 解析值
if not LParsedVal then
        case ACur^ of
          CHAR_LBRACE: ParseObjectValue; // nested object
          CHAR_LBRACKET: ParseArrayValue; // nested array
          CHAR_N_LOWER: // null
            if not ReadNull(ACur, LVal) then
            begin
              ReturnErr(ACur, jecInvalidLiteral, 'invalid literal, expected ''null''');
              Exit;
            end;
          CHAR_T_LOWER: // true
            if not ReadTrue(ACur, LVal) then
            begin
              ReturnErr(ACur, jecInvalidLiteral, 'invalid literal, expected ''true''');
              Exit;
            end;
          CHAR_F_LOWER: // false
            if not ReadFalse(ACur, LVal) then
            begin
              ReturnErr(ACur, jecInvalidLiteral, 'invalid literal, expected ''false''');
              Exit;
            end;
          CHAR_QUOTE: // string
            if not ReadStr(ACur, AEnd, LVal, LMsg) then
            begin
              ReturnErr(ACur, jecInvalidString, LMsg);
              Exit;
            end;
          CHAR_MINUS: // number or -inf/-nan
            if (jrfNumberAsRaw in AFlg) then
            begin
              if not ReadNumberRaw(ACur, AEnd, LVal) then begin ReturnErr(ACur, jecInvalidNumber, ERR_INVALID_NUM); Exit; end;
            end
            else if (jrfAllowInfAndNan in AFlg) and (ACur + 1 < AEnd) and (((ACur + 1)^ in [Ord('i'), Ord('I'), Ord('n'), Ord('N')])) then
            begin
              Inc(ACur);
              if not ReadInfOrNan(ACur, AEnd, AFlg, True, LVal) then
              begin
                ReturnErr(ACur, jecInvalidNumber, ERR_INVALID_INFNAN);
                Exit;
              end;
            end
            else if not ReadNum(ACur, AEnd, AFlg, LVal, LMsg) then
            begin
              ReturnErr(ACur, jecInvalidNumber, LMsg);
              Exit;
            end;
          CHAR_0..CHAR_9: // number
            if (jrfNumberAsRaw in AFlg) then
            begin
              ReadNumberRaw(ACur, AEnd, LVal);
            end
            else if not ReadNum(ACur, AEnd, AFlg, LVal, LMsg) then
            begin
              ReturnErr(ACur, jecInvalidNumber, LMsg);
              Exit;
            end;
        else if (ACur^ in [Ord('i'), Ord('I'), Ord('n'), Ord('N')]) then
        begin
          if not ReadInfOrNan(ACur, AEnd, AFlg, False, LVal) then
          begin
            ReturnErr(ACur, jecUnexpectedCharacter, 'Unexpected character in object value: ' + Chr(ACur^));
            Exit;
          end;
        end
        else
          ReturnErr(ACur, jecUnexpectedCharacter, 'Unexpected character in object value: ' + Chr(ACur^));
          Exit;
        end;

        // 跳过空白/注释
        SkipSpaces(ACur, AEnd, AFlg);

        if ACur >= AEnd then
        begin
          ReturnErr(ACur, jecUnexpectedEnd, ERR_UNEXPECTED_END);
          Exit;
        end;

        // 检查对象结束或继续
        if ACur^ = CHAR_RBRACE then // '}'
        begin
          Inc(ACur);
          Break; // 对象解析完成
        end
        else if ACur^ = CHAR_COMMA then // ','
        begin
          // 允许尾随逗号：逗号后直接遇到 '}' 时接受
          if (jrfAllowTrailingCommas in AFlg) then
          begin
            LScan := ACur + 1;
            SkipSpaces(LScan, AEnd, AFlg);
            if (LScan < AEnd) and (LScan^ = CHAR_RBRACE) then
            begin
              ACur := LScan + 1;
              Break; // 对象解析完成（尾随逗号）
            end;
          end;
          Inc(ACur);
          // 继续解析下一个键值对
        end
        else
        begin
          ReturnErr(ACur, jecUnexpectedCharacter, 'Unexpected character, expected '','' or ''}''');
          Exit;
        end;

      until False;
    end;
  end
  else if ACur^ = CHAR_LBRACKET then // '['
  begin
    Inc(ACur);
    LCtn^.Tag := YYJSON_TYPE_ARR;
    LCtn^.Data.U64 := 0;

    // 完整的数组解析 (对应 yyjson arr_val_begin)
    SkipSpaces(ACur, AEnd, AFlg);

    if ACur >= AEnd then
    begin
      ReturnErr(ACur, jecUnexpectedEnd, ERR_UNEXPECTED_END);
      Exit;
    end;

    // 检查空数组
    if ACur^ = CHAR_RBRACKET then // ']'
    begin
      Inc(ACur);
      // 空数组解析成功
    end
    else
    begin
      // 解析数组元素
      repeat
        // 跳过空白/注释
        SkipSpaces(ACur, AEnd, AFlg);

        if ACur >= AEnd then
        begin
          ReturnErr(ACur, jecUnexpectedEnd, ERR_UNEXPECTED_END);
          Exit;
        end;

        // 分配新的值空间
        ValIncr;
        Inc(LCtnLen);

        // 重置快速路径标志
        LParsedVal := False;
        // 允许数组元素为 Inf/NaN 的快速路径
        if (jrfAllowInfAndNan in AFlg) then
        begin
          if (ACur^ = CHAR_MINUS) and (ACur + 1 < AEnd) and (((ACur + 1)^ in [Ord('i'), Ord('I'), Ord('n'), Ord('N')])) then
          begin
            Inc(ACur);
            if ReadInfOrNan(ACur, AEnd, AFlg, True, LVal) then LParsedVal := True else Dec(ACur);
          end
          else if (ACur^ in [Ord('i'), Ord('I'), Ord('n'), Ord('N')]) then
          begin
            if ReadInfOrNan(ACur, AEnd, AFlg, False, LVal) then LParsedVal := True;
          end;
        end;

        // 解析数组元素值
if not LParsedVal then
        case ACur^ of
          CHAR_LBRACE: ParseObjectValue; // nested object
          CHAR_LBRACKET: ParseArrayValue; // nested array
          CHAR_N_LOWER: // null
            if not ReadNull(ACur, LVal) then
            begin
              ReturnErr(ACur, jecInvalidLiteral, 'invalid literal, expected ''null''');
              Exit;
            end;
          CHAR_T_LOWER: // true
            if not ReadTrue(ACur, LVal) then
            begin
              ReturnErr(ACur, jecInvalidLiteral, 'invalid literal, expected ''true''');
              Exit;
            end;
          CHAR_F_LOWER: // false
            if not ReadFalse(ACur, LVal) then
            begin
              ReturnErr(ACur, jecInvalidLiteral, 'invalid literal, expected ''false''');
              Exit;
            end;
          CHAR_QUOTE: // string
            if not ReadStr(ACur, AEnd, LVal, LMsg) then
            begin
              ReturnErr(ACur, jecInvalidString, LMsg);
              Exit;
            end;
          CHAR_MINUS: // number or -inf/-nan
            if (jrfNumberAsRaw in AFlg) then
            begin
              if not ReadNumberRaw(ACur, AEnd, LVal) then begin ReturnErr(ACur, jecInvalidNumber, ERR_INVALID_NUM); Exit; end;
            end
            else if (jrfAllowInfAndNan in AFlg) and (ACur + 1 < AEnd) and (((ACur + 1)^ in [Ord('i'), Ord('I'), Ord('n'), Ord('N')])) then
            begin
              Inc(ACur);
              if not ReadInfOrNan(ACur, AEnd, AFlg, True, LVal) then
              begin
                ReturnErr(ACur, jecInvalidNumber, ERR_INVALID_INFNAN);
                Exit;
              end;
            end
            else if not ReadNum(ACur, AEnd, AFlg, LVal, LMsg) then
            begin
              ReturnErr(ACur, jecInvalidNumber, LMsg);
              Exit;
            end;
          CHAR_0..CHAR_9: // number
            if (jrfNumberAsRaw in AFlg) then
            begin
              ReadNumberRaw(ACur, AEnd, LVal);
            end
            else if not ReadNum(ACur, AEnd, AFlg, LVal, LMsg) then
            begin
              ReturnErr(ACur, jecInvalidNumber, LMsg);
              Exit;
            end;
        else if (ACur^ in [Ord('i'), Ord('I'), Ord('n'), Ord('N')]) then
        begin
          if not ReadInfOrNan(ACur, AEnd, AFlg, False, LVal) then
          begin
            ReturnErr(ACur, jecUnexpectedCharacter, 'Unexpected character in array: ' + Chr(ACur^));
            Exit;
          end;
        end
        else
          ReturnErr(ACur, jecUnexpectedCharacter, 'Unexpected character in array: ' + Chr(ACur^));
          Exit;
        end;

        // 跳过空白/注释
        SkipSpaces(ACur, AEnd, AFlg);

        if ACur >= AEnd then
        begin
          ReturnErr(ACur, jecUnexpectedEnd, ERR_UNEXPECTED_END);
          Exit;
        end;

        // 检查数组结束或继续
        if ACur^ = CHAR_RBRACKET then // ']'
        begin
          Inc(ACur);
          Break; // 数组解析完成
        end
        else if ACur^ = CHAR_COMMA then // ','
        begin
          // 允许尾随逗号：逗号后直接遇到 ']' 时接受
          if (jrfAllowTrailingCommas in AFlg) then
          begin
            LScan := ACur + 1;
            SkipSpaces(LScan, AEnd, AFlg);
            if (LScan < AEnd) and (LScan^ = CHAR_RBRACKET) then
            begin
              ACur := LScan + 1;
              Break; // 数组解析完成（尾随逗号）
            end;
          end;
          Inc(ACur);
          // 继续解析下一个元素
        end
        else
        begin
          ReturnErr(ACur, jecUnexpectedCharacter, 'Unexpected character, expected '','' or '']''');
          Exit;
        end;

      until False;
    end;
  end
  else
  begin
    ReturnErr(ACur, jecUnexpectedCharacter, ERR_UNEXPECTED_VALUE);
    Exit;
  end;

  // 跳过尾随空白/注释
  SkipSpaces(ACur, AEnd, AFlg);

  // 检查是否还有多余字符（严格模式除非 StopWhenDone）
  if (ACur < AEnd) and not (jrfStopWhenDone in AFlg) then
  begin
    ReturnErr(ACur, jecUnexpectedContent, ERR_UNEXPECTED_CONTENT);
    Exit;
  end;

  // 设置容器长度
  LCtn^.Tag := (UInt64(LCtnLen) shl YYJSON_TAG_BIT) or (LCtn^.Tag and YYJSON_TYPE_MASK);
  // 设置容器跨度（自身 + 所有子节点），供 UnsafeGetNext 使用
  LCtn^.Data.U64 := SizeUInt((LVal - LCtn) + 1) * SizeOf(TJsonValue);

  // 创建文档对象
  LDoc := TJsonDocument.Create(AAlc);
  LDoc.FRoot := LCtn;
  LDoc.FBytesRead := ACur - AHdr;
  LDoc.FValuesRead := 1;
  LDoc.FValueBuffer := LValHdr;

  Result := LDoc;
end;

// TJsonDocument 实现
constructor TJsonDocument.Create(AAllocator: IAllocator);
begin
  inherited Create;
  FAllocator := AAllocator;
  FRoot := nil;
  FBytesRead := 0;
  FValuesRead := 0;
  FValueBuffer := nil;
end;

destructor TJsonDocument.Destroy;
begin
  if Assigned(FValueBuffer) and Assigned(FAllocator) then
    FAllocator.FreeMem(FValueBuffer);
  if Assigned(FInputBuffer) and Assigned(FAllocator) then
    FAllocator.FreeMem(FInputBuffer);
  inherited Destroy;
end;

// TJsonMutDocument 实现
constructor TJsonMutDocument.Create(AAllocator: IAllocator);
begin
  inherited Create;
  FAllocator := AAllocator;
  FRoot := nil;
  FValueCount := 0;
end;

destructor TJsonMutDocument.Destroy;
begin
  // 可变文档的内存由分配器管理，这里只需要释放文档对象本身
  inherited Destroy;
end;

// 可变 API 实现 (严格对应 yyjson_mut_* 函数)
function JsonMutDocNew(AAllocator: IAllocator): TJsonMutDocument;
begin
  if Assigned(AAllocator) then
    Result := TJsonMutDocument.Create(AAllocator)
  else
    Result := nil;
end;

procedure JsonMutDocFree(ADoc: TJsonMutDocument);
begin
  if Assigned(ADoc) then
    ADoc.Free;
end;

function JsonMutDocGetRoot(ADoc: TJsonMutDocument): PJsonMutValue;
begin
  if Assigned(ADoc) then
    Result := ADoc.Root
  else
    Result := nil;
end;

procedure JsonMutDocSetRoot(ADoc: TJsonMutDocument; ARoot: PJsonMutValue);
begin
  if Assigned(ADoc) then
    ADoc.Root := ARoot;
end;

// 可变值创建函数实现
function JsonMutNull(ADoc: TJsonMutDocument): PJsonMutValue;
begin
  if not Assigned(ADoc) or not Assigned(ADoc.Allocator) then
  begin
    Result := nil;
    Exit;
  end;

  Result := PJsonMutValue(ADoc.Allocator.GetMem(SizeOf(TJsonMutValue)));
  if Assigned(Result) then
  begin
    Result^.Tag := YYJSON_TYPE_NULL;
    Result^.Data.U64 := 0;
    Result^.Next := nil;
    Inc(ADoc.FValueCount);
  end;
end;

function JsonMutTrue(ADoc: TJsonMutDocument): PJsonMutValue;
begin
  if not Assigned(ADoc) or not Assigned(ADoc.Allocator) then
  begin
    Result := nil;
    Exit;
  end;

  Result := PJsonMutValue(ADoc.Allocator.GetMem(SizeOf(TJsonMutValue)));
  if Assigned(Result) then
  begin
    Result^.Tag := YYJSON_TYPE_BOOL or YYJSON_SUBTYPE_TRUE;
    Result^.Data.U64 := 0;
    Result^.Next := nil;
    Inc(ADoc.FValueCount);
  end;
end;

function JsonMutFalse(ADoc: TJsonMutDocument): PJsonMutValue;
begin
  if not Assigned(ADoc) or not Assigned(ADoc.Allocator) then
  begin
    Result := nil;
    Exit;
  end;

  Result := PJsonMutValue(ADoc.Allocator.GetMem(SizeOf(TJsonMutValue)));
  if Assigned(Result) then
  begin
    Result^.Tag := YYJSON_TYPE_BOOL or YYJSON_SUBTYPE_FALSE;
    Result^.Data.U64 := 0;
    Result^.Next := nil;
    Inc(ADoc.FValueCount);
  end;
end;

function JsonMutBool(ADoc: TJsonMutDocument; AVal: Boolean): PJsonMutValue;
begin
  if AVal then
    Result := JsonMutTrue(ADoc)
  else
    Result := JsonMutFalse(ADoc);
end;

function JsonMutUint(ADoc: TJsonMutDocument; AVal: UInt64): PJsonMutValue;
begin
  if not Assigned(ADoc) or not Assigned(ADoc.Allocator) then
  begin
    Result := nil;
    Exit;
  end;

  Result := PJsonMutValue(ADoc.Allocator.GetMem(SizeOf(TJsonMutValue)));
  if Assigned(Result) then
  begin
    Result^.Tag := YYJSON_TYPE_NUM or YYJSON_SUBTYPE_UINT;
    Result^.Data.U64 := AVal;
    Result^.Next := nil;
    Inc(ADoc.FValueCount);
  end;
end;

function JsonMutSint(ADoc: TJsonMutDocument; AVal: Int64): PJsonMutValue;
begin
  if not Assigned(ADoc) or not Assigned(ADoc.Allocator) then
  begin
    Result := nil;
    Exit;
  end;

  Result := PJsonMutValue(ADoc.Allocator.GetMem(SizeOf(TJsonMutValue)));
  if Assigned(Result) then
  begin
    Result^.Tag := YYJSON_TYPE_NUM or YYJSON_SUBTYPE_SINT;
    Result^.Data.I64 := AVal;
    Result^.Next := nil;
    Inc(ADoc.FValueCount);
  end;
end;

function JsonMutInt(ADoc: TJsonMutDocument; AVal: Integer): PJsonMutValue;
begin
  if AVal >= 0 then
    Result := JsonMutUint(ADoc, UInt64(AVal))
  else
    Result := JsonMutSint(ADoc, Int64(AVal));
end;

function JsonMutReal(ADoc: TJsonMutDocument; AVal: Double): PJsonMutValue;
begin
  if not Assigned(ADoc) or not Assigned(ADoc.Allocator) then
  begin
    Result := nil;
    Exit;
  end;

  Result := PJsonMutValue(ADoc.Allocator.GetMem(SizeOf(TJsonMutValue)));
  if Assigned(Result) then
  begin
    Result^.Tag := YYJSON_TYPE_NUM or YYJSON_SUBTYPE_REAL;
    Result^.Data.F64 := AVal;
    Result^.Next := nil;
    Inc(ADoc.FValueCount);
  end;
end;

function JsonMutStr(ADoc: TJsonMutDocument; const AVal: String): PJsonMutValue;
begin
  Result := JsonMutStrN(ADoc, PChar(AVal), Length(AVal));
end;

function JsonMutStrN(ADoc: TJsonMutDocument; const AVal: PChar; ALen: SizeUInt): PJsonMutValue;
var
  LStrBuf: PChar;
begin
  if not Assigned(ADoc) or not Assigned(ADoc.Allocator) or not Assigned(AVal) then
  begin
    Result := nil;
    Exit;
  end;

  Result := PJsonMutValue(ADoc.Allocator.GetMem(SizeOf(TJsonMutValue)));
  if not Assigned(Result) then
    Exit;

  // 分配字符串缓冲区
  LStrBuf := PChar(ADoc.Allocator.GetMem(ALen + 1));
  if not Assigned(LStrBuf) then
  begin
    ADoc.Allocator.FreeMem(Result);
    Result := nil;
    Exit;
  end;

  // 复制字符串数据
  Move(AVal^, LStrBuf^, ALen);
  LStrBuf[ALen] := #0;

  Result^.Tag := YYJSON_TYPE_STR or (UInt64(ALen) shl YYJSON_TAG_BIT);
  Result^.Data.Str := LStrBuf;
  Result^.Next := nil;
  Inc(ADoc.FValueCount);
end;

// 可变容器创建函数实现
function JsonMutArr(ADoc: TJsonMutDocument): PJsonMutValue;
begin
  if not Assigned(ADoc) or not Assigned(ADoc.Allocator) then
  begin
    Result := nil;
    Exit;
  end;

  Result := PJsonMutValue(ADoc.Allocator.GetMem(SizeOf(TJsonMutValue)));
  if Assigned(Result) then
  begin
    Result^.Tag := YYJSON_TYPE_ARR;  // 空数组，长度为 0
    Result^.Data.Ptr := nil;  // 空数组没有元素
    Result^.Next := nil;
    Inc(ADoc.FValueCount);
  end;
end;

function JsonMutObj(ADoc: TJsonMutDocument): PJsonMutValue;
begin
  if not Assigned(ADoc) or not Assigned(ADoc.Allocator) then
  begin
    Result := nil;
    Exit;
  end;

  Result := PJsonMutValue(ADoc.Allocator.GetMem(SizeOf(TJsonMutValue)));
  if Assigned(Result) then
  begin
    Result^.Tag := YYJSON_TYPE_OBJ;  // 空对象，长度为 0
    Result^.Data.Ptr := nil;  // 空对象没有元素
    Result^.Next := nil;
    Inc(ADoc.FValueCount);
  end;
end;

// 可变数组操作函数实现
function JsonMutArrSize(AArr: PJsonMutValue): SizeUInt;
begin
  if Assigned(AArr) and (UnsafeGetType(PJsonValue(AArr)) = YYJSON_TYPE_ARR) then
    Result := UnsafeGetLen(PJsonValue(AArr))
  else
    Result := 0;
end;

function JsonMutArrGet(AArr: PJsonMutValue; AIdx: SizeUInt): PJsonMutValue;
var
  LSize: SizeUInt;
  LVal: PJsonMutValue;
  I: SizeUInt;
begin
  LSize := JsonMutArrSize(AArr);
  if AIdx < LSize then
  begin
    LVal := PJsonMutValue(AArr^.Data.Ptr);
    for I := 0 to AIdx - 1 do
      LVal := LVal^.Next;
    Result := LVal^.Next;
  end
  else
    Result := nil;
end;

function JsonMutArrGetFirst(AArr: PJsonMutValue): PJsonMutValue;
begin
  if JsonMutArrSize(AArr) > 0 then
    Result := PJsonMutValue(AArr^.Data.Ptr)^.Next
  else
    Result := nil;
end;

function JsonMutArrGetLast(AArr: PJsonMutValue): PJsonMutValue;
begin
  if JsonMutArrSize(AArr) > 0 then
    Result := PJsonMutValue(AArr^.Data.Ptr)
  else
    Result := nil;
end;

// 可变数组迭代器实现
function JsonMutArrIterInit(AArr: PJsonMutValue; AIter: PJsonMutArrayIterator): Boolean;
begin
  if Assigned(AArr) and Assigned(AIter) and (UnsafeGetType(PJsonValue(AArr)) = YYJSON_TYPE_ARR) then
  begin
    AIter^.Idx := 0;
    AIter^.Max := UnsafeGetLen(PJsonValue(AArr));
    if AIter^.Max > 0 then
      AIter^.Cur := PJsonMutValue(AArr^.Data.Ptr)
    else
      AIter^.Cur := nil;
    AIter^.Pre := nil;
    AIter^.Arr := AArr;
    Result := True;
  end
  else
  begin
    if Assigned(AIter) then
      FillChar(AIter^, SizeOf(TJsonMutArrayIterator), 0);
    Result := False;
  end;
end;

function JsonMutArrIterHasNext(AIter: PJsonMutArrayIterator): Boolean;
begin
  Result := Assigned(AIter) and (AIter^.Idx < AIter^.Max);
end;

function JsonMutArrIterNext(AIter: PJsonMutArrayIterator): PJsonMutValue;
begin
  if Assigned(AIter) and (AIter^.Idx < AIter^.Max) then
  begin
    Result := AIter^.Cur;         // return current element
    AIter^.Pre := Result;         // remember previous
    AIter^.Cur := Result^.Next;   // advance to next
    Inc(AIter^.Idx);
  end
  else
    Result := nil;
end;

function JsonMutArrIterRemove(AIter: PJsonMutArrayIterator): PJsonMutValue;
var
  LPrev, LCur, LNext: PJsonMutValue;
begin
  if Assigned(AIter) and (0 < AIter^.Idx) and (AIter^.Idx <= AIter^.Max) then
  begin
    LPrev := AIter^.Pre;
    LCur := AIter^.Cur;
    LNext := LCur^.Next;

    if AIter^.Idx = AIter^.Max then
      AIter^.Arr^.Data.Ptr := LPrev;

    LPrev^.Next := LNext;
    AIter^.Cur := LNext;
    Dec(AIter^.Max);

    // 更新数组长度
    UnsafeSetLen(PJsonValue(AIter^.Arr), AIter^.Max);

    Result := LCur;
  end
  else
    Result := nil;
end;

// 可变数组修改函数实现
function JsonMutArrInsert(AArr: PJsonMutValue; AVal: PJsonMutValue; AIdx: SizeUInt): Boolean;
var
  LLen: SizeUInt;
  LPrev, LCur: PJsonMutValue;
  I: SizeUInt;
begin
  if Assigned(AArr) and Assigned(AVal) and (UnsafeGetType(PJsonValue(AArr)) = YYJSON_TYPE_ARR) then
  begin
    LLen := UnsafeGetLen(PJsonValue(AArr));
    if AIdx <= LLen then
    begin
      UnsafeSetLen(PJsonValue(AArr), LLen + 1);

      if LLen = 0 then
      begin
        // 空数组，直接设置
        AVal^.Next := AVal;
        AArr^.Data.Ptr := AVal;
      end
      else if AIdx = 0 then
      begin
        // 插入到开头
        LPrev := PJsonMutValue(AArr^.Data.Ptr);
        AVal^.Next := LPrev^.Next;
        LPrev^.Next := AVal;
      end
      else if AIdx = LLen then
      begin
        // 插入到末尾
        LPrev := PJsonMutValue(AArr^.Data.Ptr);
        AVal^.Next := LPrev^.Next;
        LPrev^.Next := AVal;
        AArr^.Data.Ptr := AVal;
      end
      else
      begin
        // 插入到中间
        LPrev := PJsonMutValue(AArr^.Data.Ptr);
        for I := 0 to AIdx - 1 do
          LPrev := LPrev^.Next;
        LCur := LPrev^.Next;
        AVal^.Next := LCur;
        LPrev^.Next := AVal;
      end;

      Result := True;
    end
    else
      Result := False;
  end
  else
    Result := False;
end;

function JsonMutArrAppend(AArr: PJsonMutValue; AVal: PJsonMutValue): Boolean;
var
  LLen: SizeUInt;
  LLast: PJsonMutValue;
begin
  if Assigned(AArr) and Assigned(AVal) and (UnsafeGetType(PJsonValue(AArr)) = YYJSON_TYPE_ARR) then
  begin
    LLen := UnsafeGetLen(PJsonValue(AArr));
    UnsafeSetLen(PJsonValue(AArr), LLen + 1);

    if LLen = 0 then
    begin
      AVal^.Next := AVal;
      AArr^.Data.Ptr := AVal;
    end
    else
    begin
      LLast := PJsonMutValue(AArr^.Data.Ptr);
      AVal^.Next := LLast^.Next;
      LLast^.Next := AVal;
      AArr^.Data.Ptr := AVal;
    end;

    Result := True;
  end
  else
    Result := False;
end;

function JsonMutArrPrepend(AArr: PJsonMutValue; AVal: PJsonMutValue): Boolean;
var
  LLen: SizeUInt;
  LLast: PJsonMutValue;
begin
  if Assigned(AArr) and Assigned(AVal) and (UnsafeGetType(PJsonValue(AArr)) = YYJSON_TYPE_ARR) then
  begin
    LLen := UnsafeGetLen(PJsonValue(AArr));
    UnsafeSetLen(PJsonValue(AArr), LLen + 1);

    if LLen = 0 then
    begin
      AVal^.Next := AVal;
      AArr^.Data.Ptr := AVal;
    end
    else
    begin
      LLast := PJsonMutValue(AArr^.Data.Ptr);
      AVal^.Next := LLast^.Next;
      LLast^.Next := AVal;
    end;

    Result := True;
  end
  else
    Result := False;
end;

function JsonMutArrReplace(AArr: PJsonMutValue; AIdx: SizeUInt; AVal: PJsonMutValue): PJsonMutValue;
var
  LLen: SizeUInt;
  LPrev, LCur, LNext: PJsonMutValue;
  I: SizeUInt;
begin
  if Assigned(AArr) and Assigned(AVal) and (UnsafeGetType(PJsonValue(AArr)) = YYJSON_TYPE_ARR) then
  begin
    LLen := UnsafeGetLen(PJsonValue(AArr));
    if AIdx < LLen then
    begin
      if AIdx = 0 then
      begin
        // 替换第一个元素
        LPrev := PJsonMutValue(AArr^.Data.Ptr);
        LCur := LPrev^.Next;
        LNext := LCur^.Next;
        AVal^.Next := LNext;
        LPrev^.Next := AVal;
        Result := LCur;
      end
      else
      begin
        // 替换其他元素
        LPrev := PJsonMutValue(AArr^.Data.Ptr);
        for I := 0 to AIdx - 1 do
          LPrev := LPrev^.Next;
        LCur := LPrev^.Next;
        LNext := LCur^.Next;
        AVal^.Next := LNext;
        LPrev^.Next := AVal;

        if AIdx = LLen - 1 then
          AArr^.Data.Ptr := AVal;  // 更新最后一个元素指针

        Result := LCur;
      end;
    end
    else
      Result := nil;
  end
  else
    Result := nil;
end;

function JsonMutArrRemove(AArr: PJsonMutValue; AIdx: SizeUInt): PJsonMutValue;
var
  LLen: SizeUInt;
  LPrev, LCur, LNext: PJsonMutValue;
  I: SizeUInt;
begin
  if Assigned(AArr) and (UnsafeGetType(PJsonValue(AArr)) = YYJSON_TYPE_ARR) then
  begin
    LLen := UnsafeGetLen(PJsonValue(AArr));
    if AIdx < LLen then
    begin
      UnsafeSetLen(PJsonValue(AArr), LLen - 1);

      if LLen = 1 then
      begin
        // 移除唯一元素
        Result := PJsonMutValue(AArr^.Data.Ptr);
        AArr^.Data.Ptr := nil;
      end
      else if AIdx = 0 then
      begin
        // 移除第一个元素
        LPrev := PJsonMutValue(AArr^.Data.Ptr);
        LCur := LPrev^.Next;
        LNext := LCur^.Next;
        LPrev^.Next := LNext;
        Result := LCur;
      end
      else
      begin
        // 移除其他元素
        LPrev := PJsonMutValue(AArr^.Data.Ptr);
        for I := 0 to AIdx - 1 do
          LPrev := LPrev^.Next;
        LCur := LPrev^.Next;
        LNext := LCur^.Next;
        LPrev^.Next := LNext;

        if AIdx = LLen - 1 then
          AArr^.Data.Ptr := LPrev;  // 更新最后一个元素指针

        Result := LCur;
      end;
    end
    else
      Result := nil;
  end
  else
    Result := nil;
end;

function JsonMutArrRemoveFirst(AArr: PJsonMutValue): PJsonMutValue;
begin
  Result := JsonMutArrRemove(AArr, 0);
end;

function JsonMutArrRemoveLast(AArr: PJsonMutValue): PJsonMutValue;
var
  LLen: SizeUInt;
begin
  LLen := JsonMutArrSize(AArr);
  if LLen > 0 then
    Result := JsonMutArrRemove(AArr, LLen - 1)
  else
    Result := nil;
end;

function JsonMutArrClear(AArr: PJsonMutValue): Boolean;
begin
  if Assigned(AArr) and (UnsafeGetType(PJsonValue(AArr)) = YYJSON_TYPE_ARR) then
  begin
    UnsafeSetLen(PJsonValue(AArr), 0);
    AArr^.Data.Ptr := nil;
    Result := True;
  end
  else
    Result := False;
end;

// 可变对象操作函数实现
function JsonMutObjSize(AObj: PJsonMutValue): SizeUInt;
begin
  if Assigned(AObj) and (UnsafeGetType(PJsonValue(AObj)) = YYJSON_TYPE_OBJ) then
    Result := UnsafeGetLen(PJsonValue(AObj))
  else
    Result := 0;
end;

function JsonMutObjGet(AObj: PJsonMutValue; const AKey: PChar): PJsonMutValue;
begin
  if Assigned(AKey) then
    Result := JsonMutObjGetN(AObj, AKey, StrLen(AKey))
  else
    Result := nil;
end;

function JsonMutObjGetN(AObj: PJsonMutValue; const AKey: PChar; AKeyLen: SizeUInt): PJsonMutValue;
var
  LLen: SizeUInt;
  LKey: PJsonMutValue;
  LCount: SizeUInt;
begin
  LLen := JsonMutObjSize(AObj);
  if (LLen > 0) and Assigned(AKey) then
  begin
    // 简化实现：从最后一个键开始遍历
    LKey := PJsonMutValue(AObj^.Data.Ptr);  // 最后一个键
    LCount := 0;

    while LCount < LLen do
    begin
      if UnsafeEqualsStrN(PJsonValue(LKey), AKey, AKeyLen) then
      begin
        Result := LKey^.Next;  // 返回对应的值
        Exit;
      end;

      // 移动到下一个键：当前键 -> 值 -> 下一个键
      LKey := LKey^.Next^.Next;
      Inc(LCount);
    end;
  end;
  Result := nil;
end;

// 可变对象迭代器实现
function JsonMutObjIterInit(AObj: PJsonMutValue; AIter: PJsonMutObjectIterator): Boolean;
begin
  if Assigned(AObj) and Assigned(AIter) and (UnsafeGetType(PJsonValue(AObj)) = YYJSON_TYPE_OBJ) then
  begin
    AIter^.Idx := 0;
    AIter^.Max := UnsafeGetLen(PJsonValue(AObj));
    if AIter^.Max > 0 then
      AIter^.Cur := PJsonMutValue(AObj^.Data.Ptr) // 指向最后一个键，Next 将返回第一个键
    else
      AIter^.Cur := nil;
    AIter^.Pre := nil;
    AIter^.Obj := AObj;
    Result := True;
  end
  else
  begin
    if Assigned(AIter) then
      FillChar(AIter^, SizeOf(TJsonMutObjectIterator), 0);
    Result := False;
  end;
end;

function JsonMutObjIterHasNext(AIter: PJsonMutObjectIterator): Boolean;
begin
  Result := Assigned(AIter) and (AIter^.Idx < AIter^.Max);
end;

function JsonMutObjIterNext(AIter: PJsonMutObjectIterator): PJsonMutValue;
begin
  if Assigned(AIter) and (AIter^.Idx < AIter^.Max) then
  begin
    AIter^.Pre := AIter^.Cur;
    Result := AIter^.Cur^.Next^.Next;  // 返回下一个键（相对当前 Cur）
    AIter^.Cur := Result;              // 将 Cur 移动到当前返回的键
    Inc(AIter^.Idx);
  end
  else
    Result := nil;
end;

function JsonMutObjIterGetVal(AKey: PJsonMutValue): PJsonMutValue;
begin
  if Assigned(AKey) then
    Result := AKey^.Next
  else
    Result := nil;
end;

function JsonMutObjIterRemove(AIter: PJsonMutObjectIterator): PJsonMutValue;
var
  LPrev, LCur, LNext: PJsonMutValue;
begin
  if Assigned(AIter) and (0 < AIter^.Idx) and (AIter^.Idx <= AIter^.Max) then
  begin
    LPrev := AIter^.Pre;
    LCur := AIter^.Cur;
    LNext := LCur^.Next^.Next;

    if AIter^.Idx = AIter^.Max then
      AIter^.Obj^.Data.Ptr := LPrev;

    LPrev^.Next^.Next := LNext;
    AIter^.Cur := LNext;
    Dec(AIter^.Max);

    // 更新对象长度
    UnsafeSetLen(PJsonValue(AIter^.Obj), AIter^.Max);

    Result := LCur^.Next;
  end
  else
    Result := nil;
end;

function JsonMutObjIterGet(AIter: PJsonMutObjectIterator; const AKey: PChar): PJsonMutValue;
begin
  if Assigned(AKey) then
    Result := JsonMutObjIterGetN(AIter, AKey, StrLen(AKey))
  else
    Result := nil;
end;

function JsonMutObjIterGetN(AIter: PJsonMutObjectIterator; const AKey: PChar; AKeyLen: SizeUInt): PJsonMutValue;
var
  LIdx: SizeUInt;
  LMax: SizeUInt;
  // LPre: PJsonMutValue; // unused
  LCur: PJsonMutValue;
begin
  if Assigned(AIter) and Assigned(AKey) then
  begin
    LIdx := 0;
    LMax := AIter^.Max;
    LCur := AIter^.Cur;

    while LIdx < LMax do
    begin
      if UnsafeEqualsStrN(PJsonValue(LCur), AKey, AKeyLen) then
      begin
        AIter^.Idx := LIdx + 1;
        AIter^.Pre := LCur;
        AIter^.Cur := LCur^.Next^.Next;
        Result := LCur^.Next;
        Exit;
      end;
      AIter^.Pre := LCur;
      LCur := LCur^.Next^.Next;
      Inc(LIdx);
    end;
  end;
  Result := nil;
end;

// 可变对象修改函数实现
function JsonMutObjAdd(AObj: PJsonMutValue; AKey: PJsonMutValue; AVal: PJsonMutValue): Boolean;
var
  LLen: SizeUInt;
  LLastKey, LLastVal, LFirstKey: PJsonMutValue;
begin
  if Assigned(AObj) and Assigned(AKey) and Assigned(AVal) and
     (UnsafeGetType(PJsonValue(AObj)) = YYJSON_TYPE_OBJ) and
     (UnsafeGetType(PJsonValue(AKey)) = YYJSON_TYPE_STR) then
  begin
    LLen := UnsafeGetLen(PJsonValue(AObj));

    if LLen > 0 then
    begin
      // 对象不为空，插入到循环链表末尾
      LLastKey := PJsonMutValue(AObj^.Data.Ptr);      // 当前最后一个键
      LLastVal := LLastKey^.Next;                     // 当前最后一个值
      LFirstKey := LLastVal^.Next;                    // 第一个键

      // 插入新键值对：LastVal -> NewKey -> NewVal -> FirstKey
      LLastVal^.Next := AKey;
      AKey^.Next := AVal;
      AVal^.Next := LFirstKey;

      // 更新最后一个键指针
      AObj^.Data.Ptr := AKey;
    end
    else
    begin
      // 空对象，设置第一个键值对：Key -> Val -> Key
      AKey^.Next := AVal;
      AVal^.Next := AKey;
      AObj^.Data.Ptr := AKey;
    end;

    UnsafeSetLen(PJsonValue(AObj), LLen + 1);
    Result := True;
  end
  else
    Result := False;
end;

function JsonMutObjPut(AObj: PJsonMutValue; AKey: PJsonMutValue; AVal: PJsonMutValue): Boolean;
var
  LReplaced: Boolean;
  LKeyLen: SizeUInt;
  LIter: TJsonMutObjectIterator;
  LCurKey: PJsonMutValue;
begin
  if not (Assigned(AObj) and Assigned(AKey) and
          (UnsafeGetType(PJsonValue(AObj)) = YYJSON_TYPE_OBJ) and
          (UnsafeGetType(PJsonValue(AKey)) = YYJSON_TYPE_STR)) then
  begin
    Result := False;
    Exit;
  end;

  LReplaced := False;
  LKeyLen := UnsafeGetLen(PJsonValue(AKey));

  if JsonMutObjIterInit(AObj, @LIter) then
  begin
    while JsonMutObjIterHasNext(@LIter) do
    begin
      LCurKey := JsonMutObjIterNext(@LIter);
      if UnsafeEqualsStrN(PJsonValue(LCurKey), AKey^.Data.Str, LKeyLen) then
      begin
        if not LReplaced and Assigned(AVal) then
        begin
          LReplaced := True;
          AVal^.Next := LCurKey^.Next^.Next;
          LCurKey^.Next := AVal;
        end
        else
        begin
          JsonMutObjIterRemove(@LIter);
        end;
      end;
    end;
  end;

  if not LReplaced and Assigned(AVal) then
    JsonMutObjAdd(AObj, AKey, AVal);

  Result := True;
end;

function JsonMutObjInsert(AObj: PJsonMutValue; AKey: PJsonMutValue; AVal: PJsonMutValue; AIdx: SizeUInt): Boolean;
var
  LLen: SizeUInt;
  LPtr: Pointer;
  I: SizeUInt;
  LCur: PJsonMutValue;
begin
  if Assigned(AObj) and Assigned(AKey) and Assigned(AVal) and
     (UnsafeGetType(PJsonValue(AObj)) = YYJSON_TYPE_OBJ) and
     (UnsafeGetType(PJsonValue(AKey)) = YYJSON_TYPE_STR) then
  begin
    LLen := UnsafeGetLen(PJsonValue(AObj));
    if AIdx <= LLen then
    begin
      if LLen > AIdx then
      begin
        // 保存当前指针
        LPtr := AObj^.Data.Ptr;

        // 旋转到插入位置
        LCur := PJsonMutValue(AObj^.Data.Ptr);
        for I := 0 to AIdx - 1 do
          LCur := LCur^.Next^.Next;
        AObj^.Data.Ptr := LCur;

        // 添加键值对
        JsonMutObjAdd(AObj, AKey, AVal);

        // 恢复指针
        AObj^.Data.Ptr := LPtr;
      end
      else
      begin
        JsonMutObjAdd(AObj, AKey, AVal);
      end;
      Result := True;
    end
    else
      Result := False;
  end
  else
    Result := False;
end;

function JsonMutObjRemove(AObj: PJsonMutValue; AKey: PJsonMutValue): PJsonMutValue;
begin
  if Assigned(AObj) and Assigned(AKey) and
     (UnsafeGetType(PJsonValue(AObj)) = YYJSON_TYPE_OBJ) and
     (UnsafeGetType(PJsonValue(AKey)) = YYJSON_TYPE_STR) then
  begin
    Result := JsonMutObjRemoveKeyN(AObj, AKey^.Data.Str, UnsafeGetLen(PJsonValue(AKey)));
  end
  else
    Result := nil;
end;

function JsonMutObjRemoveKey(AObj: PJsonMutValue; const AKey: PChar): PJsonMutValue;
begin
  if Assigned(AKey) then
    Result := JsonMutObjRemoveKeyN(AObj, AKey, StrLen(AKey))
  else
    Result := nil;
end;

function JsonMutObjRemoveKeyN(AObj: PJsonMutValue; const AKey: PChar; AKeyLen: SizeUInt): PJsonMutValue;
var
  LTotal: SizeUInt;
  LCountDown: SizeUInt;
  LPreKey, LCurKey, LNextKey: PJsonMutValue;
  LVal: PJsonMutValue;
  LPrevKey: PJsonMutValue; // 维护上一轮的“键”节点，便于删除最后键时回退
begin
  LTotal := JsonMutObjSize(AObj);
  if (LTotal > 0) and Assigned(AKey) then
  begin
    LCountDown := LTotal;
    LPrevKey := PJsonMutValue(AObj^.Data.Ptr);     // 上一“键”，初始为最后键
    LPreKey := LPrevKey^.Next;                     // 上一“值”，用于断链
    LCurKey := LPreKey^.Next;                      // 当前键 = 第一键

    while LCountDown > 0 do
    begin
      if UnsafeEqualsStrN(PJsonValue(LCurKey), AKey, AKeyLen) then
      begin
        LVal := LCurKey^.Next;
        LNextKey := LVal^.Next;

        if LTotal = 1 then
        begin
          // 移除唯一的键值对
          AObj^.Data.Ptr := nil;
        end
        else
        begin
          // LPreKey 是待删键的前一个值（value），其 Next 指向待删键
          // LNextKey 是待删键后面的键
          LPreKey^.Next := LNextKey; // 断开: pre.value -> del.key -> del.value -> next.key
          // 若待删的是最后一个键，则最后键应回退为前一个键（即 LNextKey 的前驱键）
          if LCurKey = PJsonMutValue(AObj^.Data.Ptr) then
            AObj^.Data.Ptr := LPrevKey; // 若删除的是最后一个键，则最后键回退为上一轮的键
          // 更新上一键为当前的上一键（本轮删除后，下一轮上一键仍应为 LPrevKey）
        end;

        UnsafeSetLen(PJsonValue(AObj), UnsafeGetLen(PJsonValue(AObj)) - 1);
        Result := LVal;
        Exit;
      end;

      // 进入下一轮前，更新上一键为当前键
      LPrevKey := LCurKey;
      LPreKey := LCurKey^.Next;   // 当前键的值
      LCurKey := LPreKey^.Next;   // 下一个键
      Dec(LCountDown);
    end;
  end;
  Result := nil;
end;

function JsonMutObjClear(AObj: PJsonMutValue): Boolean;
begin
  if Assigned(AObj) and (UnsafeGetType(PJsonValue(AObj)) = YYJSON_TYPE_OBJ) then
  begin
    UnsafeSetLen(PJsonValue(AObj), 0);
    AObj^.Data.Ptr := nil;
    Result := True;
  end
  else
    Result := False;
end;

function JsonMutObjReplace(AObj: PJsonMutValue; AKey: PJsonMutValue; AVal: PJsonMutValue): Boolean;
var
  LKeyLen: SizeUInt;
  LCountDown: SizeUInt;
  LCurKey: PJsonMutValue;
begin
  if Assigned(AObj) and Assigned(AKey) and Assigned(AVal) and
     (UnsafeGetType(PJsonValue(AObj)) = YYJSON_TYPE_OBJ) and
     (UnsafeGetType(PJsonValue(AKey)) = YYJSON_TYPE_STR) then
  begin
    LKeyLen := UnsafeGetLen(PJsonValue(AKey));
    LCountDown := UnsafeGetLen(PJsonValue(AObj));

    if UnsafeGetLen(PJsonValue(AObj)) > 0 then
    begin
      LCountDown := UnsafeGetLen(PJsonValue(AObj));
      LCurKey := PJsonMutValue(AObj^.Data.Ptr)^.Next^.Next;
      while LCountDown > 0 do
      begin
        if UnsafeEqualsStrN(PJsonValue(LCurKey), AKey^.Data.Str, LKeyLen) then
        begin
          AVal^.Next := LCurKey^.Next^.Next;
          LCurKey^.Next := AVal;
          Result := True;
          Exit;
        end;
        LCurKey := LCurKey^.Next^.Next;
        Dec(LCountDown);
      end;
    end;
  end;
  Result := False;
end;

// 可变数组便利 API 实现 (严格对应 yyjson_mut_arr_add_* 函数)
function JsonMutArrAddVal(AArr: PJsonMutValue; AVal: PJsonMutValue): Boolean;
begin
  Result := JsonMutArrAppend(AArr, AVal);
end;

function JsonMutArrAddNull(ADoc: TJsonMutDocument; AArr: PJsonMutValue): Boolean;
var
  LVal: PJsonMutValue;
begin
  if Assigned(ADoc) and Assigned(AArr) and (UnsafeGetType(PJsonValue(AArr)) = YYJSON_TYPE_ARR) then
  begin
    LVal := JsonMutNull(ADoc);
    Result := JsonMutArrAppend(AArr, LVal);
  end
  else
    Result := False;
end;

function JsonMutArrAddTrue(ADoc: TJsonMutDocument; AArr: PJsonMutValue): Boolean;
var
  LVal: PJsonMutValue;
begin
  if Assigned(ADoc) and Assigned(AArr) and (UnsafeGetType(PJsonValue(AArr)) = YYJSON_TYPE_ARR) then
  begin
    LVal := JsonMutTrue(ADoc);
    Result := JsonMutArrAppend(AArr, LVal);
  end
  else
    Result := False;
end;

function JsonMutArrAddFalse(ADoc: TJsonMutDocument; AArr: PJsonMutValue): Boolean;
var
  LVal: PJsonMutValue;
begin
  if Assigned(ADoc) and Assigned(AArr) and (UnsafeGetType(PJsonValue(AArr)) = YYJSON_TYPE_ARR) then
  begin
    LVal := JsonMutFalse(ADoc);
    Result := JsonMutArrAppend(AArr, LVal);
  end
  else
    Result := False;
end;

function JsonMutArrAddBool(ADoc: TJsonMutDocument; AArr: PJsonMutValue; AVal: Boolean): Boolean;
var
  LVal: PJsonMutValue;
begin
  if Assigned(ADoc) and Assigned(AArr) and (UnsafeGetType(PJsonValue(AArr)) = YYJSON_TYPE_ARR) then
  begin
    LVal := JsonMutBool(ADoc, AVal);
    Result := JsonMutArrAppend(AArr, LVal);
  end
  else
    Result := False;
end;

function JsonMutArrAddUint(ADoc: TJsonMutDocument; AArr: PJsonMutValue; ANum: UInt64): Boolean;
var
  LVal: PJsonMutValue;
begin
  if Assigned(ADoc) and Assigned(AArr) and (UnsafeGetType(PJsonValue(AArr)) = YYJSON_TYPE_ARR) then
  begin
    LVal := JsonMutUint(ADoc, ANum);
    Result := JsonMutArrAppend(AArr, LVal);
  end
  else
    Result := False;
end;

function JsonMutArrAddSint(ADoc: TJsonMutDocument; AArr: PJsonMutValue; ANum: Int64): Boolean;
var
  LVal: PJsonMutValue;
begin
  if Assigned(ADoc) and Assigned(AArr) and (UnsafeGetType(PJsonValue(AArr)) = YYJSON_TYPE_ARR) then
  begin
    LVal := JsonMutSint(ADoc, ANum);
    Result := JsonMutArrAppend(AArr, LVal);
  end
  else
    Result := False;
end;

function JsonMutArrAddInt(ADoc: TJsonMutDocument; AArr: PJsonMutValue; ANum: Int64): Boolean;
var
  LVal: PJsonMutValue;
begin
  if Assigned(ADoc) and Assigned(AArr) and (UnsafeGetType(PJsonValue(AArr)) = YYJSON_TYPE_ARR) then
  begin
    LVal := JsonMutSint(ADoc, ANum);  // yyjson_mut_arr_add_int 使用 sint
    Result := JsonMutArrAppend(AArr, LVal);
  end
  else
    Result := False;
end;

function JsonMutArrAddReal(ADoc: TJsonMutDocument; AArr: PJsonMutValue; ANum: Double): Boolean;
var
  LVal: PJsonMutValue;
begin
  if Assigned(ADoc) and Assigned(AArr) and (UnsafeGetType(PJsonValue(AArr)) = YYJSON_TYPE_ARR) then
  begin
    LVal := JsonMutReal(ADoc, ANum);
    Result := JsonMutArrAppend(AArr, LVal);
  end
  else
    Result := False;
end;

function JsonMutArrAddStr(ADoc: TJsonMutDocument; AArr: PJsonMutValue; const AStr: String): Boolean;
var
  LVal: PJsonMutValue;
begin
  if Assigned(ADoc) and Assigned(AArr) and (UnsafeGetType(PJsonValue(AArr)) = YYJSON_TYPE_ARR) then
  begin
    LVal := JsonMutStr(ADoc, AStr);
    Result := JsonMutArrAppend(AArr, LVal);
  end
  else
    Result := False;
end;

function JsonMutArrAddStrN(ADoc: TJsonMutDocument; AArr: PJsonMutValue; const AStr: PChar; ALen: SizeUInt): Boolean;
var
  LVal: PJsonMutValue;
begin
  if Assigned(ADoc) and Assigned(AArr) and (UnsafeGetType(PJsonValue(AArr)) = YYJSON_TYPE_ARR) then
  begin
    LVal := JsonMutStrN(ADoc, AStr, ALen);
    Result := JsonMutArrAppend(AArr, LVal);
  end
  else
    Result := False;
end;

function JsonMutArrAddArr(ADoc: TJsonMutDocument; AArr: PJsonMutValue): PJsonMutValue;
begin
  if Assigned(ADoc) and Assigned(AArr) and (UnsafeGetType(PJsonValue(AArr)) = YYJSON_TYPE_ARR) then
  begin
    Result := JsonMutArr(ADoc);
    if Assigned(Result) and JsonMutArrAppend(AArr, Result) then
      // 成功
    else
      Result := nil;
  end
  else
    Result := nil;
end;

function JsonMutArrAddObj(ADoc: TJsonMutDocument; AArr: PJsonMutValue): PJsonMutValue;
begin
  if Assigned(ADoc) and Assigned(AArr) and (UnsafeGetType(PJsonValue(AArr)) = YYJSON_TYPE_ARR) then
  begin
    Result := JsonMutObj(ADoc);
    if Assigned(Result) and JsonMutArrAppend(AArr, Result) then
      // 成功
    else
      Result := nil;
  end
  else
    Result := nil;
end;

// 可变对象便利 API 实现 (严格对应 yyjson_mut_obj_add_* 函数)
function JsonMutObjAddVal(ADoc: TJsonMutDocument; AObj: PJsonMutValue; const AKey: String; AVal: PJsonMutValue): Boolean;
var
  LKey: PJsonMutValue;
begin
  if Assigned(ADoc) and Assigned(AObj) and Assigned(AVal) and (AKey <> '') and
     (UnsafeGetType(PJsonValue(AObj)) = YYJSON_TYPE_OBJ) then
  begin
    LKey := JsonMutStr(ADoc, AKey);
    if Assigned(LKey) then
      Result := JsonMutObjAdd(AObj, LKey, AVal)
    else
      Result := False;
  end
  else
    Result := False;
end;

function JsonMutObjAddNull(ADoc: TJsonMutDocument; AObj: PJsonMutValue; const AKey: String): Boolean;
var
  LKey, LVal: PJsonMutValue;
begin
  if Assigned(ADoc) and Assigned(AObj) and (AKey <> '') and
     (UnsafeGetType(PJsonValue(AObj)) = YYJSON_TYPE_OBJ) then
  begin
    LKey := JsonMutStr(ADoc, AKey);
    LVal := JsonMutNull(ADoc);
    if Assigned(LKey) and Assigned(LVal) then
      Result := JsonMutObjAdd(AObj, LKey, LVal)
    else
      Result := False;
  end
  else
    Result := False;
end;

function JsonMutObjAddTrue(ADoc: TJsonMutDocument; AObj: PJsonMutValue; const AKey: String): Boolean;
var
  LKey, LVal: PJsonMutValue;
begin
  if Assigned(ADoc) and Assigned(AObj) and (AKey <> '') and
     (UnsafeGetType(PJsonValue(AObj)) = YYJSON_TYPE_OBJ) then
  begin
    LKey := JsonMutStr(ADoc, AKey);
    LVal := JsonMutTrue(ADoc);
    if Assigned(LKey) and Assigned(LVal) then
      Result := JsonMutObjAdd(AObj, LKey, LVal)
    else
      Result := False;
  end
  else
    Result := False;
end;

function JsonMutObjAddFalse(ADoc: TJsonMutDocument; AObj: PJsonMutValue; const AKey: String): Boolean;
var
  LKey, LVal: PJsonMutValue;
begin
  if Assigned(ADoc) and Assigned(AObj) and (AKey <> '') and
     (UnsafeGetType(PJsonValue(AObj)) = YYJSON_TYPE_OBJ) then
  begin
    LKey := JsonMutStr(ADoc, AKey);
    LVal := JsonMutFalse(ADoc);
    if Assigned(LKey) and Assigned(LVal) then
      Result := JsonMutObjAdd(AObj, LKey, LVal)
    else
      Result := False;
  end
  else
    Result := False;
end;

function JsonMutObjAddBool(ADoc: TJsonMutDocument; AObj: PJsonMutValue; const AKey: String; AVal: Boolean): Boolean;
var
  LKey, LVal: PJsonMutValue;
begin
  if Assigned(ADoc) and Assigned(AObj) and (AKey <> '') and
     (UnsafeGetType(PJsonValue(AObj)) = YYJSON_TYPE_OBJ) then
  begin
    LKey := JsonMutStr(ADoc, AKey);
    LVal := JsonMutBool(ADoc, AVal);
    if Assigned(LKey) and Assigned(LVal) then
      Result := JsonMutObjAdd(AObj, LKey, LVal)
    else
      Result := False;
  end
  else
    Result := False;
end;

function JsonMutObjAddUint(ADoc: TJsonMutDocument; AObj: PJsonMutValue; const AKey: String; ANum: UInt64): Boolean;
var
  LKey, LVal: PJsonMutValue;
begin
  if Assigned(ADoc) and Assigned(AObj) and (AKey <> '') and
     (UnsafeGetType(PJsonValue(AObj)) = YYJSON_TYPE_OBJ) then
  begin
    LKey := JsonMutStr(ADoc, AKey);
    LVal := JsonMutUint(ADoc, ANum);
    if Assigned(LKey) and Assigned(LVal) then
      Result := JsonMutObjAdd(AObj, LKey, LVal)
    else
      Result := False;
  end
  else
    Result := False;
end;

function JsonMutObjAddSint(ADoc: TJsonMutDocument; AObj: PJsonMutValue; const AKey: String; ANum: Int64): Boolean;
var
  LKey, LVal: PJsonMutValue;
begin
  if Assigned(ADoc) and Assigned(AObj) and (AKey <> '') and
     (UnsafeGetType(PJsonValue(AObj)) = YYJSON_TYPE_OBJ) then
  begin
    LKey := JsonMutStr(ADoc, AKey);
    LVal := JsonMutSint(ADoc, ANum);
    if Assigned(LKey) and Assigned(LVal) then
      Result := JsonMutObjAdd(AObj, LKey, LVal)
    else
      Result := False;
  end
  else
    Result := False;
end;

function JsonMutObjAddInt(ADoc: TJsonMutDocument; AObj: PJsonMutValue; const AKey: String; ANum: Int64): Boolean;
var
  LKey, LVal: PJsonMutValue;
begin
  if Assigned(ADoc) and Assigned(AObj) and (AKey <> '') and
     (UnsafeGetType(PJsonValue(AObj)) = YYJSON_TYPE_OBJ) then
  begin
    LKey := JsonMutStr(ADoc, AKey);
    LVal := JsonMutSint(ADoc, ANum);  // yyjson_mut_obj_add_int 使用 sint
    if Assigned(LKey) and Assigned(LVal) then
      Result := JsonMutObjAdd(AObj, LKey, LVal)
    else
      Result := False;
  end
  else
    Result := False;
end;

function JsonMutObjAddReal(ADoc: TJsonMutDocument; AObj: PJsonMutValue; const AKey: String; ANum: Double): Boolean;
var
  LKey, LVal: PJsonMutValue;
begin
  if Assigned(ADoc) and Assigned(AObj) and (AKey <> '') and
     (UnsafeGetType(PJsonValue(AObj)) = YYJSON_TYPE_OBJ) then
  begin
    LKey := JsonMutStr(ADoc, AKey);
    LVal := JsonMutReal(ADoc, ANum);
    if Assigned(LKey) and Assigned(LVal) then
      Result := JsonMutObjAdd(AObj, LKey, LVal)
    else
      Result := False;
  end
  else
    Result := False;
end;

function JsonMutObjAddStr(ADoc: TJsonMutDocument; AObj: PJsonMutValue; const AKey: String; const AVal: String): Boolean;
var
  LKey, LVal: PJsonMutValue;
begin
  if Assigned(ADoc) and Assigned(AObj) and (AKey <> '') and
     (UnsafeGetType(PJsonValue(AObj)) = YYJSON_TYPE_OBJ) then
  begin
    LKey := JsonMutStr(ADoc, AKey);
    LVal := JsonMutStr(ADoc, AVal);
    if Assigned(LKey) and Assigned(LVal) then
      Result := JsonMutObjAdd(AObj, LKey, LVal)
    else
      Result := False;
  end
  else
    Result := False;
end;

function JsonMutObjAddStrN(ADoc: TJsonMutDocument; AObj: PJsonMutValue; const AKey: String; const AVal: PChar; ALen: SizeUInt): Boolean;
var
  LKey, LVal: PJsonMutValue;
begin
  if Assigned(ADoc) and Assigned(AObj) and (AKey <> '') and
     (UnsafeGetType(PJsonValue(AObj)) = YYJSON_TYPE_OBJ) then
  begin
    LKey := JsonMutStr(ADoc, AKey);
    LVal := JsonMutStrN(ADoc, AVal, ALen);
    if Assigned(LKey) and Assigned(LVal) then
      Result := JsonMutObjAdd(AObj, LKey, LVal)
    else
      Result := False;
  end
  else
    Result := False;
end;

function JsonMutObjAddArr(ADoc: TJsonMutDocument; AObj: PJsonMutValue; const AKey: String): PJsonMutValue;
var
  LKey: PJsonMutValue;
begin
  if Assigned(ADoc) and Assigned(AObj) and (AKey <> '') and
     (UnsafeGetType(PJsonValue(AObj)) = YYJSON_TYPE_OBJ) then
  begin
    LKey := JsonMutStr(ADoc, AKey);
    Result := JsonMutArr(ADoc);
    if Assigned(LKey) and Assigned(Result) and JsonMutObjAdd(AObj, LKey, Result) then
      // 成功
    else
      Result := nil;
  end
  else
    Result := nil;
end;

function JsonMutObjAddObj(ADoc: TJsonMutDocument; AObj: PJsonMutValue; const AKey: String): PJsonMutValue;
var
  LKey: PJsonMutValue;
begin
  if Assigned(ADoc) and Assigned(AObj) and (AKey <> '') and
     (UnsafeGetType(PJsonValue(AObj)) = YYJSON_TYPE_OBJ) then
  begin
    LKey := JsonMutStr(ADoc, AKey);
    Result := JsonMutObj(ADoc);
    if Assigned(LKey) and Assigned(Result) and JsonMutObjAdd(AObj, LKey, Result) then
      // 成功
    else
      Result := nil;
  end
  else
    Result := nil;
end;

initialization
  // 初始化字符类型表 (严格对应 yyjson char_table[256])
  FillChar(CharTable, SizeOf(CharTable), 0);

  // 控制字符 (0-31)
  CharTable[0] := $44; CharTable[1] := $04; CharTable[2] := $04; CharTable[3] := $04;
  CharTable[4] := $04; CharTable[5] := $04; CharTable[6] := $04; CharTable[7] := $04;
  CharTable[8] := $04; CharTable[9] := $05; CharTable[10] := $45; CharTable[11] := $04;
  CharTable[12] := $04; CharTable[13] := $45; CharTable[14] := $04; CharTable[15] := $04;
  CharTable[16] := $04; CharTable[17] := $04; CharTable[18] := $04; CharTable[19] := $04;
  CharTable[20] := $04; CharTable[21] := $04; CharTable[22] := $04; CharTable[23] := $04;
  CharTable[24] := $04; CharTable[25] := $04; CharTable[26] := $04; CharTable[27] := $04;
  CharTable[28] := $04; CharTable[29] := $04; CharTable[30] := $04; CharTable[31] := $04;

  // 可打印字符 (32-127)
  CharTable[32] := $01; CharTable[33] := $00; CharTable[34] := $04; CharTable[35] := $00;
  CharTable[36] := $00; CharTable[37] := $00; CharTable[38] := $00; CharTable[39] := $00;
  CharTable[40] := $00; CharTable[41] := $00; CharTable[42] := $00; CharTable[43] := $00;
  CharTable[44] := $00; CharTable[45] := $02; CharTable[46] := $00; CharTable[47] := $20;
  CharTable[48] := $82; CharTable[49] := $82; CharTable[50] := $82; CharTable[51] := $82;
  CharTable[52] := $82; CharTable[53] := $82; CharTable[54] := $82; CharTable[55] := $82;
  CharTable[56] := $82; CharTable[57] := $82; CharTable[58] := $00; CharTable[59] := $00;
  CharTable[60] := $00; CharTable[61] := $00; CharTable[62] := $00; CharTable[63] := $00;
  CharTable[64] := $00; CharTable[65] := $80; CharTable[66] := $80; CharTable[67] := $80;
  CharTable[68] := $80; CharTable[69] := $80; CharTable[70] := $80; CharTable[71] := $00;
  CharTable[72] := $00; CharTable[73] := $00; CharTable[74] := $00; CharTable[75] := $00;
  CharTable[76] := $00; CharTable[77] := $00; CharTable[78] := $00; CharTable[79] := $00;
  CharTable[80] := $00; CharTable[81] := $00; CharTable[82] := $00; CharTable[83] := $00;
  CharTable[84] := $00; CharTable[85] := $00; CharTable[86] := $00; CharTable[87] := $00;
  CharTable[88] := $00; CharTable[89] := $00; CharTable[90] := $00; CharTable[91] := $10;
  CharTable[92] := $04; CharTable[93] := $00; CharTable[94] := $00; CharTable[95] := $00;
  CharTable[96] := $00; CharTable[97] := $80; CharTable[98] := $80; CharTable[99] := $80;
  CharTable[100] := $80; CharTable[101] := $80; CharTable[102] := $80; CharTable[103] := $00;
  CharTable[104] := $00; CharTable[105] := $00; CharTable[106] := $00; CharTable[107] := $00;
  CharTable[108] := $00; CharTable[109] := $00; CharTable[110] := $00; CharTable[111] := $00;
  CharTable[112] := $00; CharTable[113] := $00; CharTable[114] := $00; CharTable[115] := $00;
  CharTable[116] := $00; CharTable[117] := $00; CharTable[118] := $00; CharTable[119] := $00;
  CharTable[120] := $00; CharTable[121] := $00; CharTable[122] := $00; CharTable[123] := $10;
  CharTable[124] := $00; CharTable[125] := $00; CharTable[126] := $00; CharTable[127] := $00;

  // 非ASCII字符 (128-255)
  FillChar(CharTable[128], 128, $08);

  // 初始化浮点数 pow10 表
  F64Pow10Table[0] := 1e0; F64Pow10Table[1] := 1e1; F64Pow10Table[2] := 1e2;
  F64Pow10Table[3] := 1e3; F64Pow10Table[4] := 1e4; F64Pow10Table[5] := 1e5;
  F64Pow10Table[6] := 1e6; F64Pow10Table[7] := 1e7; F64Pow10Table[8] := 1e8;
  F64Pow10Table[9] := 1e9; F64Pow10Table[10] := 1e10; F64Pow10Table[11] := 1e11;
  F64Pow10Table[12] := 1e12; F64Pow10Table[13] := 1e13; F64Pow10Table[14] := 1e14;
  F64Pow10Table[15] := 1e15; F64Pow10Table[16] := 1e16; F64Pow10Table[17] := 1e17;
  F64Pow10Table[18] := 1e18; F64Pow10Table[19] := 1e19; F64Pow10Table[20] := 1e20;
  F64Pow10Table[21] := 1e21; F64Pow10Table[22] := 1e22;

end.


// 增量读取器 API 实现 (最小骨架，对齐 yyjson_incr_*)
function JsonIncrNew(ABuf: PChar; ABufLen: SizeUInt; AFlags: TJsonReadFlags; AAllocator: IAllocator): PJsonIncrState; inline;
begin
  Result := nil;
  if (ABuf = nil) or (ABufLen = 0) then Exit;
  New(Result);
  Result^.Buf := PByte(ABuf);
  Result^.BufCap := ABufLen;
  Result^.Avail := 0;
  Result^.Flags := AFlags;
  Result^.Allocator := AAllocator;
end;

function JsonIncrRead(AState: PJsonIncrState; AFeedLen: SizeUInt; var AError: TJsonError): TJsonDocument; inline;
var
  LHdr, LCur, LEnd: PByte;
begin
  Result := nil;
  if (AState = nil) or (AFeedLen = 0) then begin
    AError.Code := jecInvalidParameter; AError.Message := ERR_INVALID_INCR_PARAMS; AError.Position := 0; Exit;
  end;
  if (AState^.Avail + AFeedLen > AState^.BufCap) then begin
    AError.Code := jecInvalidParameter; AError.Message := 'feed length exceeds buffer capacity'; AError.Position := AState^.Avail; Exit;
  end;
  // 视作当前可用区间从 0..Avail+AFeedLen，直接尝试解析完整 JSON（最小实现）
  Inc(AState^.Avail, AFeedLen);
  LHdr := AState^.Buf; LCur := LHdr; LEnd := LHdr + AState^.Avail;
  // 直接调用现有的 ReadRootMinify（完整解析）
  Result := ReadRootMinify(LHdr, LCur, LEnd, AState^.Allocator, AState^.Flags, AError);
end;

procedure JsonIncrFree(AState: PJsonIncrState); inline;
begin
  if Assigned(AState) then Dispose(AState);
end;


  LVal: PJsonValue;
  LDoc: TJsonDocument;
  LMsg: String;

  // 内联错误处理宏 (对应 yyjson return_err)
  procedure ReturnErr(APos: PByte; ACode: TJsonErrorCode; const AMessage: String);
  begin
    AErr.Position := APos - AHdr;
    AErr.Code := ACode;
    AErr.Message := AMessage;
    if Assigned(LValHdr) then
      AAlc.FreeMem(LValHdr);
    Result := nil;
  end;

begin
  Result := nil;
  LMsg := '';
  LValHdr := nil;

  // 计算头部长度 (对应 yyjson hdr_len 计算)
  LHdrLen := SizeOf(TJsonDocument) div SizeOf(TJsonValue);
  if (SizeOf(TJsonDocument) mod SizeOf(TJsonValue)) > 0 then
    Inc(LHdrLen);
  LAlcNum := LHdrLen + 1; // 单个值

  // 分配内存 (对应 yyjson val_hdr 分配)
  LValHdr := PJsonValue(AAlc.GetMem(LAlcNum * SizeOf(TJsonValue)));
  if not Assigned(LValHdr) then
  begin
    ReturnErr(ACur, jecMemoryAllocation, 'Failed to allocate memory for JSON value');
    Exit;
  end;

  // 初始化内存
  FillChar(LValHdr^, LAlcNum * SizeOf(TJsonValue), 0);
  LVal := LValHdr + LHdrLen;

  // 跳过前导空白/注释
  SkipSpaces(ACur, AEnd, AFlg);

  if ACur >= AEnd then
  begin
    ReturnErr(ACur, jecUnexpectedEnd, ERR_UNEXPECTED_END);
    Exit;
  end;

  // 解析单个值 (对应 yyjson 单值解析)
  case ACur^ of
    CHAR_N_LOWER: // null or NaN
      if (jrfAllowInfAndNan in AFlg) and ReadInfOrNan(ACur, AEnd, AFlg, False, LVal) then
      begin
        // parsed NaN
      end
      else if not ReadNull(ACur, LVal) then
      begin
        ReturnErr(ACur, jecInvalidLiteral, ERR_INVALID_NULL);
        Exit;
      end;
    CHAR_T_LOWER: // true
      if not ReadTrue(ACur, LVal) then
      begin
        ReturnErr(ACur, jecInvalidLiteral, ERR_INVALID_TRUE);
        Exit;
      end;
    CHAR_F_LOWER: // false
      if not ReadFalse(ACur, LVal) then
      begin
        ReturnErr(ACur, jecInvalidLiteral, ERR_INVALID_FALSE);
        Exit;
      end;
    CHAR_QUOTE: // string
      if not ReadStr(ACur, AEnd, LVal, LMsg) then
      begin
        ReturnErr(ACur, jecInvalidString, LMsg);
        Exit;
      end;
    CHAR_MINUS: // number or -inf/-nan
      if (jrfAllowInfAndNan in AFlg) and (ACur + 1 < AEnd) and (((ACur + 1)^ in [Ord('i'), Ord('I'), Ord('n'), Ord('N')])) then
      begin
        Inc(ACur);
        if not ReadInfOrNan(ACur, AEnd, AFlg, True, LVal) then
        begin
          ReturnErr(ACur, jecInvalidNumber, ERR_INVALID_INFNAN);
          Exit;
        end;
      end
      else if not ReadNum(ACur, AEnd, AFlg, LVal, LMsg) then
      begin
        ReturnErr(ACur, jecInvalidNumber, LMsg);
        Exit;
      end;
    CHAR_0..CHAR_9: // number
      if (jrfNumberAsRaw in AFlg) then
      begin
        ReadNumberRaw(ACur, AEnd, LVal);
      end
      else if not ReadNum(ACur, AEnd, AFlg, LVal, LMsg) then
      begin
        ReturnErr(ACur, jecInvalidNumber, LMsg);
        Exit;
      end;
  else if (ACur^ in [Ord('i'), Ord('I'), Ord('n'), Ord('N')]) then
  begin
    if not ReadInfOrNan(ACur, AEnd, AFlg, False, LVal) then
    begin
      ReturnErr(ACur, jecUnexpectedCharacter, ERR_UNEXPECTED_VALUE);
      Exit;
    end;
  end
  else
    ReturnErr(ACur, jecUnexpectedCharacter, ERR_UNEXPECTED_VALUE);
    Exit;
  end;

  // 跳过尾随空白/注释
  SkipSpaces(ACur, AEnd, AFlg);

  // 检查是否还有多余字符 (严格模式除非 StopWhenDone)
  if (ACur < AEnd) and not (jrfStopWhenDone in AFlg) then
  begin
    if JsonPendingInvalidComment then begin ReturnErr(ACur, jecInvalidComment, ERR_UNCLOSED_ML_COMMENT); Exit; end;
    ReturnErr(ACur, jecUnexpectedContent, ERR_UNEXPECTED_CONTENT);
    Exit;
  end;

  // 创建文档对象 (对应 yyjson 文档创建)
  LDoc := TJsonDocument.Create(AAlc);
  LDoc.FRoot := LVal;
  LDoc.FBytesRead := ACur - AHdr;
  LDoc.FValuesRead := 1;

  Result := LDoc;
end;
begin
  if not Assigned(AStr) or (ALen = 0) then
  begin
    Result := '""';
    Exit;
  end;

  LOutput := '"';

  I := 0;
  while I < ALen do
  begin
    LChar := PByte(AStr)[I];
    case LChar of
      8: LOutput := LOutput + '\b';    // backspace
      9: LOutput := LOutput + '\t';    // tab
      10: LOutput := LOutput + '\n';   // newline
      12: LOutput := LOutput + '\f';   // form feed
      13: LOutput := LOutput + '\r';   // carriage return
      34: LOutput := LOutput + '\"';   // quote
      92: LOutput := LOutput + '\\';   // backslash
      47: // slash
        if jwfEscapeSlashes in AFlags then
          LOutput := LOutput + '\/'
        else
          LOutput := LOutput + '/';
    else
      if (LChar < 32) then
        LOutput := LOutput + '\u' + IntToHex(LChar, 4)
      else if (LChar < 128) then
        LOutput := LOutput + Chr(LChar)
      else if (jwfEscapeUnicode in AFlags) then
      begin
        // 读取 UTF-8 多字节并编码为 \uXXXX（必要时代理对）
        // 简化：只处理常见合法 UTF-8，非法或不完整按 jwfAllowInvalidUnicode -> 按字节 \u00XX
        B0 := 0; B1 := 0; B2 := 0; B3 := 0;
        B0 := LChar;
        if (B0 >= $C2) and (B0 <= $DF) then
        begin
          if I + 1 >= ALen then
          begin
            if jwfAllowInvalidUnicode in AFlags then LOutput := LOutput + '\u' + IntToHex(B0, 4) else LOutput := LOutput + '?';
          end
          else
          begin
            B1 := PByte(AStr)[I+1];
            if (B1 and $C0) <> $80 then
            begin
              if jwfAllowInvalidUnicode in AFlags then LOutput := LOutput + '\u' + IntToHex(B0, 4) else LOutput := LOutput + '?';
            end
            else
            begin
              U := ((B0 and $1F) shl 6) or (B1 and $3F);
              LOutput := LOutput + '\u' + IntToHex(U, 4);
              Inc(I); // consume extra
            end;
          end;
        end
        else if (B0 >= $E0) and (B0 <= $EF) then
        begin
          if I + 2 >= ALen then
          begin
            if jwfAllowInvalidUnicode in AFlags then LOutput := LOutput + '\u' + IntToHex(B0, 4) else LOutput := LOutput + '?';
          end
          else
          begin
            B1 := PByte(AStr)[I+1]; B2 := PByte(AStr)[I+2];
            if ((B1 and $C0) <> $80) or ((B2 and $C0) <> $80) then
            begin
              if jwfAllowInvalidUnicode in AFlags then LOutput := LOutput + '\u' + IntToHex(B0, 4) else LOutput := LOutput + '?';
            end
            else
            begin
              U := ((B0 and $0F) shl 12) or ((B1 and $3F) shl 6) or (B2 and $3F);
              LOutput := LOutput + '\u' + IntToHex(U, 4);
              Inc(I, 2);
            end;
          end;
        end
        else if (B0 >= $F0) and (B0 <= $F4) then
        begin
          if I + 3 >= ALen then
          begin
            if jwfAllowInvalidUnicode in AFlags then LOutput := LOutput + '\u' + IntToHex(B0, 4) else LOutput := LOutput + '?';
          end
          else
          begin
            B1 := PByte(AStr)[I+1]; B2 := PByte(AStr)[I+2]; B3 := PByte(AStr)[I+3];
            if ((B1 and $C0) <> $80) or ((B2 and $C0) <> $80) or ((B3 and $C0) <> $80) then
            begin
              if jwfAllowInvalidUnicode in AFlags then LOutput := LOutput + '\u' + IntToHex(B0, 4) else LOutput := LOutput + '?';
            end
            else
            begin
              U32 := ((B0 and $07) shl 18) or ((B1 and $3F) shl 12) or ((B2 and $3F) shl 6) or (B3 and $3F);
              Hi := Word(0);
              Lo := Word(0);
              U32 := U32 - $10000;
              Hi := Word($D800 or (U32 shr 10));
              Lo := Word($DC00 or (U32 and $3FF));
              LOutput := LOutput + '\u' + IntToHex(Hi, 4) + '\u' + IntToHex(Lo, 4);
              Inc(I, 3);
            end;
          end;
        end
        else
        begin
          // 单独高位字节：视为非法
          if jwfAllowInvalidUnicode in AFlags then
            LOutput := LOutput + '\u' + IntToHex(B0, 4)
          else
            LOutput := LOutput + '?';
        end;
      end
      else
        // 直出 UTF-8 字节
        LOutput := LOutput + Chr(LChar);
    end;
    Inc(I);
  end;

  LOutput := LOutput + '"';
  Result := LOutput;
end;

function WriteJsonValue(AVal: PJsonValue; AFlags: TJsonWriteFlags; AIndent: Integer): String;
var
  LType: UInt8;
  LLen: SizeUInt;
  LIter: TJsonArrayIterator;
  LObjIter: TJsonObjectIterator;
  LKey, LValue: PJsonValue;
  LIndentStr, LNewIndentStr: String;
  LFirst: Boolean;
  I: Integer;
begin
  if not Assigned(AVal) then
  begin
    Result := 'null';
    Exit;
  end;

  LType := UnsafeGetType(AVal);

  // 生成缩进字符串
  if jwfPretty in AFlags then
  begin
    LIndentStr := '';
    for I := 0 to AIndent - 1 do
      LIndentStr := LIndentStr + '  ';
    LNewIndentStr := '';
    for I := 0 to AIndent do
      LNewIndentStr := LNewIndentStr + '  ';
  end;

  case LType of
    YYJSON_TYPE_NULL: Result := 'null';
    YYJSON_TYPE_BOOL:
      if UnsafeIsTrue(AVal) then
        Result := 'true'
      else
        Result := 'false';
    YYJSON_TYPE_NUM:
      begin
        Result := WriteJsonNumber(AVal, AFlags);
        if Result = '' then Result := '';
      end;
    YYJSON_TYPE_STR:
      begin
        if ((UInt8(AVal^.Tag) and YYJSON_SUBTYPE_NOESC) <> 0) and
           not (jwfEscapeUnicode in AFlags) and not (jwfEscapeSlashes in AFlags) then
        begin
          SetLength(Result, UnsafeGetLen(AVal) + 2);
          Result[1] := '"';
          Move(AVal^.Data.Str^, Result[2], UnsafeGetLen(AVal));
          Result[2 + UnsafeGetLen(AVal)] := '"';
        end
        else
          Result := WriteJsonString(AVal^.Data.Str, UnsafeGetLen(AVal), AFlags);
      end;
    YYJSON_TYPE_ARR:
    begin
      LLen := UnsafeGetLen(AVal);
      if LLen = 0 then
      begin
        Result := '[]';
        Exit;
      end;

      if jwfPretty in AFlags then
        Result := '[' + sLineBreak
      else
        Result := '[';

      LFirst := True;
      if JsonArrIterInit(AVal, @LIter) then
      begin
        while JsonArrIterHasNext(@LIter) do
        begin
          LValue := JsonArrIterNext(@LIter);
          if not LFirst then
          begin
            if jwfPretty in AFlags then
              Result := Result + ',' + sLineBreak
            else
              Result := Result + ',';
          end;
          LFirst := False;

          if jwfPretty in AFlags then
            Result := Result + LNewIndentStr;

          Result := Result + WriteJsonValue(LValue, AFlags, AIndent + 1);
        end;
      end;

      if jwfPretty in AFlags then
        Result := Result + sLineBreak + LIndentStr + ']'
      else
        Result := Result + ']';
    end;
    YYJSON_TYPE_OBJ:
    begin
      LLen := UnsafeGetLen(AVal);
      if LLen = 0 then
      begin
        Result := '{}';
        Exit;
      end;

      if jwfPretty in AFlags then
        Result := '{' + sLineBreak
      else
        Result := '{';



      LFirst := True;
      if JsonObjIterInit(AVal, @LObjIter) then
      begin
        while JsonObjIterHasNext(@LObjIter) do
        begin
          LKey := JsonObjIterNext(@LObjIter);
          LValue := JsonObjIterGetVal(LKey);

          if not LFirst then
          begin
            if jwfPretty in AFlags then
              Result := Result + ',' + sLineBreak
            else
              Result := Result + ',';
          end;
          LFirst := False;

          if jwfPretty in AFlags then
            Result := Result + LNewIndentStr;

          // 写入键
          Result := Result + WriteJsonString(LKey^.Data.Str, UnsafeGetLen(LKey), AFlags);

          if jwfPretty in AFlags then
            Result := Result + ': '
          else
            Result := Result + ':';

          // 写入值
          Result := Result + WriteJsonValue(LValue, AFlags, AIndent + 1);
        end;
      end;

      if jwfPretty in AFlags then
        Result := Result + sLineBreak + LIndentStr + '}'
      else
        Result := Result + '}';
    end;
  else
    Result := 'null';
  end;
end;

// 剩余的写入器 API 函数实现
function JsonWriteFile(const APath: String; ADoc: TJsonDocument; AFlags: TJsonWriteFlags;
  AAllocator: IAllocator; var AError: TJsonWriteError): Boolean; inline;
var
  LFileStream: TFileStream;
  LData: PChar;
  LLen: SizeUInt;
begin
  Result := False;

  LLen := 0;
  // 参数验证
  if APath = '' then
  begin
    AError.Code := jwecInvalidParameter;
    AError.Message := ERR_EMPTY_FILE_PATH;
    Exit;
  end;

  if not Assigned(ADoc) then
  begin
    AError.Code := jwecInvalidParameter;
    AError.Message := ERR_DOC_NULL;
    Exit;
  end;

  // 序列化 JSON 数据
  AError := Default(TJsonWriteError);
  LData := JsonWriteOpts(ADoc, AFlags, AAllocator, LLen, AError);
  if not Assigned(LData) then
    Exit;

  try
    // 写入文件
    LFileStream := TFileStream.Create(APath, fmCreate);
    try
      LFileStream.WriteBuffer(LData^, LLen);
      Result := True;
      AError.Code := jwecSuccess;
      AError.Message := '';
    finally
      try
        LFileStream.Free;
      except
        on E: Exception do begin AError.Code := jwecFileWriteError; AError.Message := 'failed to close file'; end;
      end;
    end;
  except
    on E: Exception do
    begin
      AError.Code := jwecFileWriteError;
      AError.Message := 'failed to write file';
    end;
  end;

  // 释放序列化数据
  if Assigned(LData) then
    AAllocator.FreeMem(LData);
end;


procedure JsonMutDocFree(ADoc: TJsonMutDocument);
begin
  if Assigned(ADoc) then
    ADoc.Free;
end;

function JsonMutDocGetRoot(ADoc: TJsonMutDocument): PJsonMutValue;
begin
  if Assigned(ADoc) then
    Result := ADoc.Root
  else
    Result := nil;
end;

procedure JsonMutDocSetRoot(ADoc: TJsonMutDocument; ARoot: PJsonMutValue);
begin
  if Assigned(ADoc) then
    ADoc.Root := ARoot;
end;

// 可变值创建函数实现
function JsonMutNull(ADoc: TJsonMutDocument): PJsonMutValue;
begin
  if not Assigned(ADoc) or not Assigned(ADoc.Allocator) then
  begin
    Result := nil;
    Exit;
  end;

  Result := PJsonMutValue(ADoc.Allocator.GetMem(SizeOf(TJsonMutValue)));
  if Assigned(Result) then
  begin
    Result^.Tag := YYJSON_TYPE_NULL;
    Result^.Data.U64 := 0;


    Result^.Next := nil;
    Inc(ADoc.FValueCount);
  end;
end;

function JsonMutTrue(ADoc: TJsonMutDocument): PJsonMutValue;
begin
  if not Assigned(ADoc) or not Assigned(ADoc.Allocator) then
  begin
    Result := nil;
    Exit;
  end;

  Result := PJsonMutValue(ADoc.Allocator.GetMem(SizeOf(TJsonMutValue)));
  if Assigned(Result) then
  begin
    Result^.Tag := YYJSON_TYPE_BOOL or YYJSON_SUBTYPE_TRUE;
    Result^.Data.U64 := 0;
    Result^.Next := nil;
    Inc(ADoc.FValueCount);
  end;
end;

function JsonMutFalse(ADoc: TJsonMutDocument): PJsonMutValue;
begin
  if not Assigned(ADoc) or not Assigned(ADoc.Allocator) then
  begin
    Result := nil;
    Exit;
  end;

  Result := PJsonMutValue(ADoc.Allocator.GetMem(SizeOf(TJsonMutValue)));
  if Assigned(Result) then
  begin
    Result^.Tag := YYJSON_TYPE_BOOL or YYJSON_SUBTYPE_FALSE;
    Result^.Data.U64 := 0;
    Result^.Next := nil;
    Inc(ADoc.FValueCount);
  end;
end;

function JsonMutBool(ADoc: TJsonMutDocument; AVal: Boolean): PJsonMutValue;
begin
  if AVal then
    Result := JsonMutTrue(ADoc)
  else
    Result := JsonMutFalse(ADoc);
end;

function JsonMutUint(ADoc: TJsonMutDocument; AVal: UInt64): PJsonMutValue;
begin
  if not Assigned(ADoc) or not Assigned(ADoc.Allocator) then
  begin
    Result := nil;
    Exit;
  end;

  Result := PJsonMutValue(ADoc.Allocator.GetMem(SizeOf(TJsonMutValue)));
  if Assigned(Result) then
  begin
    Result^.Tag := YYJSON_TYPE_NUM or YYJSON_SUBTYPE_UINT;
    Result^.Data.U64 := AVal;
    Result^.Next := nil;
    Inc(ADoc.FValueCount);
  end;
end;

function JsonMutSint(ADoc: TJsonMutDocument; AVal: Int64): PJsonMutValue;
begin
  if not Assigned(ADoc) or not Assigned(ADoc.Allocator) then
  begin
    Result := nil;
    Exit;
  end;

  Result := PJsonMutValue(ADoc.Allocator.GetMem(SizeOf(TJsonMutValue)));
  if Assigned(Result) then
  begin
    Result^.Tag := YYJSON_TYPE_NUM or YYJSON_SUBTYPE_SINT;
    Result^.Data.I64 := AVal;
    Result^.Next := nil;
    Inc(ADoc.FValueCount);
  end;
end;

function JsonMutInt(ADoc: TJsonMutDocument; AVal: Integer): PJsonMutValue;
begin
  if AVal >= 0 then
    Result := JsonMutUint(ADoc, UInt64(AVal))
  else
    Result := JsonMutSint(ADoc, Int64(AVal));
end;

function JsonMutReal(ADoc: TJsonMutDocument; AVal: Double): PJsonMutValue;
begin
  if not Assigned(ADoc) or not Assigned(ADoc.Allocator) then
  begin
    Result := nil;
    Exit;
  end;

  Result := PJsonMutValue(ADoc.Allocator.GetMem(SizeOf(TJsonMutValue)));
  if Assigned(Result) then
  begin
    Result^.Tag := YYJSON_TYPE_NUM or YYJSON_SUBTYPE_REAL;
    Result^.Data.F64 := AVal;
    Result^.Next := nil;
    Inc(ADoc.FValueCount);
  end;
end;

function JsonMutStr(ADoc: TJsonMutDocument; const AVal: String): PJsonMutValue;
begin
  Result := JsonMutStrN(ADoc, PChar(AVal), Length(AVal));
end;

function JsonMutStrN(ADoc: TJsonMutDocument; const AVal: PChar; ALen: SizeUInt): PJsonMutValue;
var
  LStrBuf: PChar;
begin
  if not Assigned(ADoc) or not Assigned(ADoc.Allocator) or not Assigned(AVal) then
  begin
    Result := nil;
    Exit;
  end;

  Result := PJsonMutValue(ADoc.Allocator.GetMem(SizeOf(TJsonMutValue)));
  if not Assigned(Result) then
    Exit;

  // 分配字符串缓冲区
  LStrBuf := PChar(ADoc.Allocator.GetMem(ALen + 1));
  if not Assigned(LStrBuf) then
  begin
    ADoc.Allocator.FreeMem(Result);
    Result := nil;
    Exit;
  end;

  // 复制字符串数据
  Move(AVal^, LStrBuf^, ALen);
  LStrBuf[ALen] := #0;

  Result^.Tag := YYJSON_TYPE_STR or (UInt64(ALen) shl YYJSON_TAG_BIT);
  Result^.Data.Str := LStrBuf;
  Result^.Next := nil;
  Inc(ADoc.FValueCount);
end;

// 第八阶段 JSON Pointer API 将在后续版本中实现
// 当前专注于已验证的核心功能

end.
