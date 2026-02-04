unit fafafa.core.xml;
{$IFDEF DEBUG}
{$R+}{$Q+}
{$ENDIF}


{$MODE OBJFPC}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes,
  fafafa.core.base,
  fafafa.core.mem.allocator;

type
  // 读取 Token 类型（流式）
  TXmlToken = (
    xtNone,
    xtStartDocument,
    xtEndDocument,
    xtStartElement,
    xtEndElement,
    xtText,
    xtCData,
    xtComment,
    xtPI,
    xtWhitespace
  );

  // 读取选项
  TXmlReadFlag = (
    xrfDefault,
    xrfIgnoreWhitespace,
    xrfCoalesceText,
    xrfIgnoreComments,
    xrfAllowInvalidUnicode,
    // 编码策略（Phase 1：仅定义标志；实际自动解码将在后续阶段实现）
    xrfAssumeUTF8,           // 假定输入为 UTF-8；仍会跳过 UTF-8 BOM；检测到非 UTF-8 BOM 将报错
    xrfAutoDecodeEncoding    // 自动探测并转码（占位，后续阶段实现）；本阶段仍按 UTF-8 处理
  );
  TXmlReadFlags = set of TXmlReadFlag;

  // 写入选项
  TXmlWriteFlag = (
    xwfDefault,
    xwfPretty,
    xwfOmitXmlDecl,
    xwfSortAttrs,
    xwfDedupAttrs
  );
  TXmlWriteFlags = set of TXmlWriteFlag;

  // 错误
  TXmlErrorCode = (
    xecSuccess,
    xecInvalidParameter,
    xecMalformedXml,
    xecUnexpectedEnd,
    xecInvalidName,
    xecInvalidEncoding,
    xecFileIO,
    xecMemory
  );

  TXmlError = record
    Code: TXmlErrorCode;
    Message: String;
    Position: SizeUInt;
    Line: SizeUInt;
    Column: SizeUInt;
  public
    procedure Clear; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
    function HasError: Boolean; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
    function ToString: String;
  end;

  // 前置接口
  IXmlReader = interface;
  IXmlWriter = interface;
  IXmlNode = interface;
  IXmlDocument = interface;

  // DOM 抽象（占位，后续细化）
  IXmlNode = interface
  ['{0D91F7A1-6B84-4D9F-823F-0B6F3B6E9D60}']
    function GetName: String;
    function GetLocalName: String;
    function GetPrefix: String;
    function GetNamespaceURI: String;
    function GetValue: String;
    function GetChildCount: SizeUInt;
    function GetChild(AIndex: SizeUInt): IXmlNode;
    function GetAttributeCount: SizeUInt;
    function GetAttributeName(AIndex: SizeUInt): String;
    function GetAttributeValue(AIndex: SizeUInt): String;
    function GetAttributeByName(const AName: String; out AValue: String): Boolean;
    // 属性名解析与命名空间
    function GetAttributeLocalName(AIndex: SizeUInt): String;
    function GetAttributePrefix(AIndex: SizeUInt): String;
    function GetAttributeNamespaceURI(AIndex: SizeUInt): String;
    // 结构导航
    function GetParent: IXmlNode;
    function GetFirstChild: IXmlNode;
    function GetLastChild: IXmlNode;
    function GetNextSibling: IXmlNode;
    function GetPreviousSibling: IXmlNode;
    function GetHasChildNodes: Boolean;

    property Name: String read GetName;
    property LocalName: String read GetLocalName;
    property Prefix: String read GetPrefix;
    property NamespaceURI: String read GetNamespaceURI;
    property Value: String read GetValue;
    property Parent: IXmlNode read GetParent;
    property FirstChild: IXmlNode read GetFirstChild;
    property LastChild: IXmlNode read GetLastChild;
    property NextSibling: IXmlNode read GetNextSibling;
    property PreviousSibling: IXmlNode read GetPreviousSibling;
    property HasChildNodes: Boolean read GetHasChildNodes;
  end;

  IXmlDocument = interface
  ['{2F0A6B2A-7E3E-4F2E-8B1E-8A8A9B4F7D1B}']
    function GetRoot: IXmlNode;
    function GetAllocator: TAllocator;

    property Root: IXmlNode read GetRoot;
    property Allocator: TAllocator read GetAllocator;
  end;
  // 解析异常（结构化，含定位）
  EXmlParseError = class(Exception)
  public
    Code: TXmlErrorCode;
    Position: SizeUInt;
    Line: SizeUInt;
    Column: SizeUInt;
    constructor Create(ACode: TXmlErrorCode; const AMsg: String; APos, ALine, ACol: SizeUInt);
  end;


  // Reader：StAX/Pull 风格
  IXmlReader = interface
  ['{A4B5C6D7-E8F9-4A0B-9123-4567890ABCDE}']
    // 源读取
    function ReadFromString(const AText: String): IXmlReader; overload;
    function ReadFromString(const AText: String; AFlags: TXmlReadFlags): IXmlReader; overload;
    function ReadFromStringN(ABuf: PChar; ALength: SizeUInt): IXmlReader; overload;
    function ReadFromStringN(ABuf: PChar; ALength: SizeUInt; AFlags: TXmlReadFlags): IXmlReader; overload;
    function ReadFromStream(AStream: TStream): IXmlReader; overload;
    function ReadFromStream(AStream: TStream; AFlags: TXmlReadFlags): IXmlReader; overload;
    function ReadFromStream(AStream: TStream; AFlags: TXmlReadFlags; InitialBufCap: SizeUInt): IXmlReader; overload;
    function ReadFromFile(const AFileName: String): IXmlReader; overload;
    function ReadFromFile(const AFileName: String; AFlags: TXmlReadFlags): IXmlReader; overload;
    function ReadFromFile(const AFileName: String; AFlags: TXmlReadFlags; InitialBufCap: SizeUInt): IXmlReader; overload;

    // 便捷：读完构建最小 DOM
    function ReadAllToDocument: IXmlDocument; inline;

    // 游标推进
    function Read: Boolean;

    // 当前节点信息
    function GetToken: TXmlToken;
    function GetDepth: SizeUInt;
    function GetName: String;        // QName or node name
    function GetLocalName: String;
    function GetPrefix: String;
    function GetNamespaceURI: String;
    function GetValue: String;       // 文本值/PI数据/注释内容/CDATA
    // N-系零拷贝视图（返回指针与长度，不分配）
    function GetNameN(out P: PChar; out Len: SizeUInt): Boolean;
    function GetLocalNameN(out P: PChar; out Len: SizeUInt): Boolean;
    function GetPrefixN(out P: PChar; out Len: SizeUInt): Boolean;
    function GetNamespaceURIN(out P: PChar; out Len: SizeUInt): Boolean;
    function GetValueN(out P: PChar; out Len: SizeUInt): Boolean;
    function IsEmptyElement: Boolean;

    // 属性访问（仅当 Token 为 StartElement）
    function GetAttributeCount: SizeUInt;
    function GetAttributeName(AIndex: SizeUInt): String;
    function GetAttributeLocalName(AIndex: SizeUInt): String;
    function GetAttributePrefix(AIndex: SizeUInt): String;
    function GetAttributeNamespaceURI(AIndex: SizeUInt): String;
    function GetAttributeValue(AIndex: SizeUInt): String;
    function TryGetAttribute(const AName: String; out AValue: String): Boolean;
    // N-系属性零拷贝视图
    function GetAttributeNameN(AIndex: SizeUInt; out P: PChar; out Len: SizeUInt): Boolean;
    function GetAttributeLocalNameN(AIndex: SizeUInt; out P: PChar; out Len: SizeUInt): Boolean;
    function GetAttributePrefixN(AIndex: SizeUInt; out P: PChar; out Len: SizeUInt): Boolean;
    function GetAttributeNamespaceURIN(AIndex: SizeUInt; out P: PChar; out Len: SizeUInt): Boolean;
    function GetAttributeValueN(AIndex: SizeUInt; out P: PChar; out Len: SizeUInt): Boolean;
    function TryGetAttributeN(const AName: PChar; ANameLen: SizeUInt; out P: PChar; out Len: SizeUInt): Boolean;

    // 冻结当前 StartElement 为只读节点并链接到文档树
    function FreezeCurrentNode: IXmlNode;

    // 位置
    function GetLine: SizeUInt;
    function GetColumn: SizeUInt;
    function GetPosition: SizeUInt; // byte offset

    // 属性
    property Token: TXmlToken read GetToken;
    property Depth: SizeUInt read GetDepth;
    property Name: String read GetName;
    property LocalName: String read GetLocalName;
    property Prefix: String read GetPrefix;
    property NamespaceURI: String read GetNamespaceURI;
    property Value: String read GetValue;
    property EmptyElement: Boolean read IsEmptyElement;
    property AttributeCount: SizeUInt read GetAttributeCount;
    property Line: SizeUInt read GetLine;
    property Column: SizeUInt read GetColumn;
    property Position: SizeUInt read GetPosition;
  end;

  // ===== 最小 DOM 节点与文档占位，供 FreezeCurrentNode 返回 =====
  type
    TXmlNodeRec = record
      Kind: TXmlToken;
      Parent: SizeUInt;
      FirstChild: SizeUInt;
      LastChild: SizeUInt;
      NextSibling: SizeUInt;
      // 名称与值（最小实现先用字符串保存；后续可切到 Arena）
      Name: String;
      Value: String;
      // 元素命名空间 URI
      ElemNS: String;
      // 属性（最小实现：仅名称与值；若已有结构可替换）
      AttrNames: array of String;
      AttrValues: array of String;
      AttrNS: array of String; // 属性命名空间 URI（默认 NS 不作用于属性）
    end;

    TXmlDocumentImpl = class;

    TXmlNodeIntf = class(TInterfacedObject, IXmlNode)
    private
      FDoc: TXmlDocumentImpl;
      FDocRef: IXmlDocument; // 持有接口引用，延长文档生命周期
      FIndex: SizeUInt;
    public
      constructor Create(ADoc: TXmlDocumentImpl; AIndex: SizeUInt);
      function GetName: String;
      function GetLocalName: String;
      function GetPrefix: String;
      function GetNamespaceURI: String;
      function GetAttributeLocalName(AIndex: SizeUInt): String;
      function GetAttributePrefix(AIndex: SizeUInt): String;
      function GetAttributeNamespaceURI(AIndex: SizeUInt): String;

      function GetValue: String;
      function GetChildCount: SizeUInt;
      function GetChild(AIndex: SizeUInt): IXmlNode;
      function GetAttributeCount: SizeUInt;
      function GetAttributeName(AIndex: SizeUInt): String;
      function GetAttributeValue(AIndex: SizeUInt): String;
      function GetAttributeByName(const AName: String; out AValue: String): Boolean;
      // 结构导航
      function GetParent: IXmlNode;
      function GetFirstChild: IXmlNode;
      function GetLastChild: IXmlNode;
      function GetNextSibling: IXmlNode;
      function GetPreviousSibling: IXmlNode;
      function GetHasChildNodes: Boolean;


    end;

    TXmlDocumentImpl = class(TInterfacedObject, IXmlDocument)
    public
      FNodes: array of TXmlNodeRec;
      FRoot: SizeUInt;
      constructor Create;
      function GetRoot: IXmlNode;
      function GetAllocator: TAllocator;
      function AddNode(const N: TXmlNodeRec): SizeUInt;
    end;


  // Writer：配合 Flags Pretty/Compact
  IXmlWriter = interface
  ['{B5C6D7E8-F9A0-4B1C-9234-567890ABCDE1}']
    procedure Reset;
    procedure StartDocument; overload;
    procedure StartDocument(const AVersion, AEncoding: String); overload;
    procedure EndDocument;

    procedure StartElement(const AName: String);
    procedure StartElementNS(const APrefix, ALocalName, ANamespaceURI: String);
    procedure EndElement; // 自动闭合与缩进
    procedure WriteAttribute(const AName, AValue: String);
    procedure WriteAttributeNS(const APrefix, ALocalName, ANamespaceURI, AValue: String);
    procedure WriteString(const AText: String);
    procedure WriteCData(const AText: String);
    procedure WriteComment(const AText: String);
    procedure WritePI(const ATarget, AData: String);
    procedure Flush;

    function WriteToString: String; overload;
    function WriteToString(AFlags: TXmlWriteFlags): String; overload;
    procedure WriteToStream(AStream: TStream); overload;
    procedure WriteToStream(AStream: TStream; AFlags: TXmlWriteFlags); overload;
    procedure WriteToFile(const AFileName: String); overload;
    procedure WriteToFile(const AFileName: String; AFlags: TXmlWriteFlags); overload;
  end;
// 便捷函数（接口区声明）
function XmlReadAllToDocument(const R: IXmlReader): IXmlDocument; overload;

// XML 转义函数
function XmlEscapeXML10Strict(const S: String): String;

// 工厂
function CreateXmlReader(AAllocator: IAllocator = nil): IXmlReader;
function CreateXmlWriter: IXmlWriter;

implementation

function XmlEscapeXML10Strict(const S: String): String;
var
  i: SizeInt;
  c: Char;
  NeedEscape: Boolean;
begin
  // ✅ XML 1.0 严格转义：转义 <, >, &, ", ' 和控制字符
  // 快速路径：检查是否需要转义
  NeedEscape := False;
  for i := 1 to Length(S) do
  begin
    c := S[i];
    if (c = '<') or (c = '>') or (c = '&') or (c = '"') or (c = '''') or
       (Ord(c) < 32) and (c <> #9) and (c <> #10) and (c <> #13) then
    begin
      NeedEscape := True;
      Break;
    end;
  end;

  if not NeedEscape then
    Exit(S);

  // 慢速路径：构建转义字符串
  Result := '';
  for i := 1 to Length(S) do
  begin
    c := S[i];
    case c of
      '<': Result := Result + '&lt;';
      '>': Result := Result + '&gt;';
      '&': Result := Result + '&amp;';
      '"': Result := Result + '&quot;';
      '''': Result := Result + '&apos;';
      #9, #10, #13: Result := Result + c; // 保留合法的空白字符
    else
      if Ord(c) < 32 then
        Result := Result + '&#' + IntToStr(Ord(c)) + ';' // 转义控制字符
      else
        Result := Result + c;
    end;
  end;
end;

function XmlReadAllToDocument(const R: IXmlReader): IXmlDocument; overload;
var DocImpl: TXmlDocumentImpl; Doc: IXmlDocument; Depth: SizeUInt;
begin
  DocImpl := nil; Doc := nil; Depth := 0;
  while R.Read do
  begin
    case R.Token of
      xtStartElement:
        begin
          if DocImpl = nil then DocImpl := TXmlDocumentImpl.Create;
          // Freeze 会把节点追加到 DocImpl；返回的接口可不使用
          R.FreezeCurrentNode;
          if Doc = nil then Doc := DocImpl;
          Inc(Depth);
        end;
      xtEndElement:
        begin
          if Depth > 0 then Dec(Depth);
        end;
      xtEndDocument:
        Break;
    end;
  end;
  Result := Doc;
end;


{$IFDEF DEBUG}
procedure __AssertNodeIdxBounds(const Doc: TXmlDocumentImpl; Idx: SizeUInt);
begin
  if (Doc=nil) then Exit;
  if Idx=High(SizeUInt) then Exit;
  if not (Idx<SizeUInt(Length(Doc.FNodes))) then
    raise Exception.CreateFmt('NodeIdx OOB: %d vs %d',[Idx, Length(Doc.FNodes)]);
end;
{$ENDIF}

const
  XML_NS_URI   = 'http://www.w3.org/XML/1998/namespace';
  XMLNS_URI    = 'http://www.w3.org/2000/xmlns/';


function ReadAllToAnsiString(AStream: TStream): AnsiString;
const
  BUF_SIZE = 256 * 1024; // 256KB
var
  Remain: Int64;
  Acc: AnsiString;
  Cap: SizeInt;
  OldLen: SizeInt;
  ReadBytes: SizeInt;
  Buf: array[0..BUF_SIZE-1] of AnsiChar;
begin
  // 尝试快速路径：已知剩余大小
  try
    Remain := AStream.Size - AStream.Position;
  except
    Remain := -1;
  end;
  if (Remain >= 0) and (Remain < High(SizeInt)) then
  begin
    SetLength(Acc, Remain);

    if Remain > 0 then
      AStream.ReadBuffer(Acc[1], Remain);
    Exit(Acc);
  end;

  // 回退：未知大小，指数扩容
  Cap := 0;
  SetLength(Acc, 0);
  repeat
    ReadBytes := AStream.Read(Buf, SizeOf(Buf));
    if ReadBytes > 0 then
    begin
      OldLen := Length(Acc);
      if OldLen + ReadBytes > Cap then
      begin
        if Cap = 0 then Cap := ReadBytes;
        while Cap < OldLen + ReadBytes do Cap := Cap * 2;
        SetLength(Acc, Cap);
        // 注意：这里临时扩容，稍后会收缩到实际长度
      end;
      Move(Buf[0], Acc[OldLen + 1], ReadBytes);
      SetLength(Acc, OldLen + ReadBytes);
    end;
  until ReadBytes = 0;
  Result := Acc;
end;


type
  TXmlNameSlice = record
    P: PChar;
    L: SizeUInt;
    Owned: AnsiString; // 流式模式下持有名称拷贝，跨窗口有效
  end;
  TXmlAttrSlice = record
    NameP: PChar;
    NameLen: SizeUInt;
    NameOwned: AnsiString; // 流式模式下持有名称拷贝，跨窗口有效
    ValueP: PChar;
    ValueLen: SizeUInt;
    ValueOwned: AnsiString; // 流式模式下，跨块拼接的属性值需要独立持有
  end;
  TNSBinding = record
    Prefix: String;
    URI: String;
  end;

{ TXmlError }

type
  TDetectedEnc = (deUnknown, deUTF8, deUTF16, deUTF32);

procedure TXmlError.Clear;
begin
  Code := xecSuccess;
  Message := '';
  Position := 0;
  Line := 0;
  Column := 0;
end;
type
  TXmlReaderImpl = class(TInterfacedObject, IXmlReader)
  private
    FText: String;       // 保持所有权，确保 PChar 有效
    FBuf: PChar;
    FCur: PChar;
    FEnd: PChar;
    FToken: TXmlToken;
    FDepth: SizeUInt;
    FFlags: TXmlReadFlags;
    FLine: SizeUInt;
    FColumn: SizeUInt;
    FTokLine: SizeUInt;
    FTokColumn: SizeUInt;
    // Detected input encoding via BOM (stream path)
    FDetectedEnc: TDetectedEnc;
    // 渐进式行列定位缓存（字符串路径）
    FLCScanP: PChar;
    FLCLine: SizeUInt;
    FLCColumn: SizeUInt;
    // 缓存解析得到的元素命名空间，用于 N-系 NamespaceURIN 返回持久指针
    FNSUriOwned: AnsiString;
    FPosP: PChar;
    FTokP: PChar;
    // 当前名称/值切片
    FNameP: PChar; FNameLen: SizeUInt;
    FNameOwned: AnsiString; // 流式：当前 token 名称的持久化副本，避免 FScratch 复用
    // 命名空间：作用域栈（简单实现，字符串保存）
    FNSStack: array of TNSBinding;
    FNSLen: SizeUInt;
    // 命名空间：前缀→URI 快速查找表（开放定址）
    FNSMapKeys: array of String;
    FNSMapVals: array of String;
    FNSMapUsed: array of Boolean;
    FNSMapCap: SizeUInt;

    FValueP: PChar; FValueLen: SizeUInt;
    FValueOwned: AnsiString; // 为流式文本 token 保持一份稳定副本，避免指针悬挂
    FEmpty: Boolean;
    // 自动补发 EndElement（针对 <x/>）
    FPendingAutoEnd: Boolean;
    FNeedCompact: Boolean; // 在下一次 Read 前压实环形窗口
    // 简单栈：保存元素名称切片
    FStack: array of TXmlNameSlice;
    FStackLen: SizeUInt;
    // 当前属性
    FAttrs: array of TXmlAttrSlice;
    FAttrCount: SizeUInt;
    // 冻结构建：共享文档与节点索引栈（用于 FreezeCurrentNode/遍历）
    FBuildDoc: TXmlDocumentImpl;
    FNodeIdxStack: array of SizeUInt;
    FNodeIdxLen: SizeUInt;

  private
    // 解析器内部（现有基于连续缓冲）；下阶段将切换为环形/双缓冲
    procedure StackPush(P: PChar; L: SizeUInt);
    procedure StackPop;
    function ParseQuoted(out VP: PChar; out VL: SizeUInt): Boolean;
    function ParseAttributes: Boolean;
    procedure SkipSpaces;
    procedure Step; inline;
    procedure SkipN(N: SizeInt); inline;
    function StartsWith(const S: PChar; L: SizeUInt): Boolean;
    function ParseName(out P: PChar; out L: SizeUInt): Boolean;
    function ParseUntil(const Terminator: PChar; TermLen: SizeUInt): Boolean;
    function DecodeEntities(P: PChar; L: SizeUInt): String;
    procedure ComputeLineColumn(out L, C: SizeUInt);
    procedure ComputeLineColumnAt(AP: PChar; out L, C: SizeUInt);
    // Scratch builder (reduce reallocations)
    procedure ScratchClear; inline;
    procedure ScratchAppend(P: PChar; L: SizeUInt); inline;
    // NS helpers
    procedure NSPushBinding(const APrefix, AURI: String);
    procedure NSPushMark;
    procedure NSPopToMark;
    function NSResolve(const APrefix: String): String;
    procedure NSMapClear; inline;
    procedure NSMapEnsureCap(Need: SizeUInt);
    function NSMapHash(const S: String): SizeUInt;
    function NSMapTryGet(const Key: String; out Val: String): Boolean;
    procedure NSMapPut(const Key, Val: String);

    // 预备：环形缓冲/真流式解析的成员与工具（暂未在解析循环中启用）
    type TSourceKind = (skNone, skString, skStream);
    var
      FSourceKind: TSourceKind;
      FSourceStream: TStream;
      FOwnsStream: Boolean; // 是否由 Reader 负责释放流（ReadFromFile 流式路径）
      FRingBuf: PAnsiChar;
      FRingCap: SizeUInt;
      FRingStart: SizeUInt; // 窗口起始索引
      FRingLen: SizeUInt;   // 窗口内有效长度
      FEOF: Boolean;        // 源是否读尽
      FScratch: AnsiString; // 跨块 token 的局部缓存
      FBaseOffset: SizeUInt; // 从源起点到当前窗口起点的累计字节偏移
      // 流式转码模式与暂存
      type TTranscodeMode = (tmNone, tmUTF16LE, tmUTF16BE, tmUTF32LE, tmUTF32BE);
      var
        FTransMode: TTranscodeMode;
        FCarry: array[0..3] of Byte; // 跨块未完整码元暂存
        FCarryLen: SizeUInt;
        FTransPendingRaw: AnsiString; // 预读(含BOM后余量)的原始字节，优先被消费

    procedure InitStreamSource(AStream: TStream; InitialCap: SizeUInt = 256*1024);
    function RingWritableSize: SizeUInt; inline;
    function RingReadableSize: SizeUInt; inline;
    function RefillAtLeast(AMin: SizeUInt): Boolean; // 确保至少 AMin 可读（必要时压实）
    function TranscodeRefill(AMin: SizeUInt): Boolean; // 当启用转码模式时，增量补给 UTF-8
    procedure CompactWindow; // 在 token 边界压实；保证切片在下一次 Read 前有效
    procedure ReleaseStreamSource; inline;
    procedure AdvanceWindowToCur; inline; // 丢弃 [窗口起点, FCur) 数据并压实

  public
    destructor Destroy; override;

    // IXmlReader
    function ReadFromString(const AText: String): IXmlReader; overload;
    function ReadFromString(const AText: String; AFlags: TXmlReadFlags): IXmlReader; overload;
    function ReadFromStringN(ABuf: PChar; ALength: SizeUInt): IXmlReader; overload;
    function ReadFromStringN(ABuf: PChar; ALength: SizeUInt; AFlags: TXmlReadFlags): IXmlReader; overload;
    function ReadFromStream(AStream: TStream): IXmlReader; overload;
    function ReadFromStream(AStream: TStream; AFlags: TXmlReadFlags): IXmlReader; overload;
    function ReadFromStream(AStream: TStream; AFlags: TXmlReadFlags; InitialBufCap: SizeUInt): IXmlReader; overload;
    function ReadFromFile(const AFileName: String): IXmlReader; overload;
    function ReadFromFile(const AFileName: String; AFlags: TXmlReadFlags): IXmlReader; overload;
    function ReadFromFile(const AFileName: String; AFlags: TXmlReadFlags; InitialBufCap: SizeUInt): IXmlReader; overload;

    function Read: Boolean;
    function ReadStreamImpl: Boolean; // 流式主循环（Step 1）
    function EnsureLookahead(N: SizeUInt): Boolean; inline; // 尝试保证前瞻

    function GetToken: TXmlToken; inline;
    function GetDepth: SizeUInt; inline;
    function GetName: String; inline;
    function GetLocalName: String; inline;    // MVP: 同 Name
    function GetPrefix: String; inline;       // MVP: 空
    function GetNamespaceURI: String; inline; // MVP: 空
    function GetValue: String; inline;
    function IsEmptyElement: Boolean; inline;

    function GetAttributeCount: SizeUInt; inline;
    function GetAttributeName(AIndex: SizeUInt): String; inline;
    function GetAttributeLocalName(AIndex: SizeUInt): String; inline;
    function GetAttributePrefix(AIndex: SizeUInt): String; inline;
    function GetAttributeNamespaceURI(AIndex: SizeUInt): String; inline;
    function GetAttributeValue(AIndex: SizeUInt): String; inline;
    function TryGetAttribute(const AName: String; out AValue: String): Boolean; inline;

    function GetNameN(out P: PChar; out Len: SizeUInt): Boolean; inline;
    function GetLocalNameN(out P: PChar; out Len: SizeUInt): Boolean; inline;
    function GetPrefixN(out P: PChar; out Len: SizeUInt): Boolean; inline;
    function GetNamespaceURIN(out P: PChar; out Len: SizeUInt): Boolean; inline;
    function GetValueN(out P: PChar; out Len: SizeUInt): Boolean; inline;
    function GetAttributeNameN(AIndex: SizeUInt; out P: PChar; out Len: SizeUInt): Boolean; inline;
    function GetAttributeLocalNameN(AIndex: SizeUInt; out P: PChar; out Len: SizeUInt): Boolean; inline;
    function GetAttributePrefixN(AIndex: SizeUInt; out P: PChar; out Len: SizeUInt): Boolean; inline;
    function GetAttributeNamespaceURIN(AIndex: SizeUInt; out P: PChar; out Len: SizeUInt): Boolean; inline;
    function GetAttributeValueN(AIndex: SizeUInt; out P: PChar; out Len: SizeUInt): Boolean; inline;
    function TryGetAttributeN(const AName: PChar; ANameLen: SizeUInt; out P: PChar; out Len: SizeUInt): Boolean; inline;

    function FreezeCurrentNode: IXmlNode;
    function GetLine: SizeUInt; inline;
    function GetColumn: SizeUInt; inline;
    function GetPosition: SizeUInt; inline;
    function ReadAllToDocument: IXmlDocument; inline;
  end;

{ EXmlParseError }
constructor EXmlParseError.Create(ACode: TXmlErrorCode; const AMsg: String; APos, ALine, ACol: SizeUInt);
begin
  inherited Create(AMsg);
  Code := ACode; Position := APos; Line := ALine; Column := ACol;
end;

function TXmlError.HasError: Boolean;
begin
  Result := Code <> xecSuccess;
end;

function TXmlError.ToString: String;
begin
  Result := Format('Code=%d, Line=%d, Col=%d, Pos=%d, Msg=%s',
    [Ord(Code), Line, Column, Position, Message]);
end;

// 简易占位实现：返回空实现，便于后续逐步替换

type
  TXmlReaderStub = class(TInterfacedObject, IXmlReader)
  private
    FToken: TXmlToken;
  public
    function ReadFromString(const AText: String): IXmlReader; overload;
    function ReadFromString(const AText: String; AFlags: TXmlReadFlags): IXmlReader; overload;
    function ReadFromStringN(ABuf: PChar; ALength: SizeUInt): IXmlReader; overload;
    function ReadFromStringN(ABuf: PChar; ALength: SizeUInt; AFlags: TXmlReadFlags): IXmlReader; overload;
    function ReadFromStream(AStream: TStream): IXmlReader; overload;
    function ReadFromStream(AStream: TStream; AFlags: TXmlReadFlags): IXmlReader; overload;
    function ReadFromStream(AStream: TStream; AFlags: TXmlReadFlags; InitialBufCap: SizeUInt): IXmlReader; overload;
    function ReadFromFile(const AFileName: String): IXmlReader; overload;
    function ReadFromFile(const AFileName: String; AFlags: TXmlReadFlags): IXmlReader; overload;
    function ReadFromFile(const AFileName: String; AFlags: TXmlReadFlags; InitialBufCap: SizeUInt): IXmlReader; overload;

    function Read: Boolean;

    function GetToken: TXmlToken;
    function GetDepth: SizeUInt; inline;
    function GetName: String; inline;
    function GetLocalName: String; inline;
    function GetPrefix: String; inline;
    function GetNamespaceURI: String; inline;
    function GetValue: String; inline;
    function IsEmptyElement: Boolean; inline;

    function GetAttributeCount: SizeUInt; inline;
    function GetAttributeName(AIndex: SizeUInt): String; inline;
    function GetAttributeLocalName(AIndex: SizeUInt): String; inline;
    function GetAttributePrefix(AIndex: SizeUInt): String; inline;
    function GetAttributeNamespaceURI(AIndex: SizeUInt): String; inline;
    function GetAttributeValue(AIndex: SizeUInt): String; inline;
    function TryGetAttribute(const AName: String; out AValue: String): Boolean; inline;
    function GetNameN(out P: PChar; out Len: SizeUInt): Boolean; inline;
    function GetLocalNameN(out P: PChar; out Len: SizeUInt): Boolean; inline;
    function GetPrefixN(out P: PChar; out Len: SizeUInt): Boolean; inline;
    function GetNamespaceURIN(out P: PChar; out Len: SizeUInt): Boolean; inline;
    function GetValueN(out P: PChar; out Len: SizeUInt): Boolean; inline;
    function GetAttributeNameN(AIndex: SizeUInt; out P: PChar; out Len: SizeUInt): Boolean; inline;
    function GetAttributeLocalNameN(AIndex: SizeUInt; out P: PChar; out Len: SizeUInt): Boolean; inline;
    function GetAttributePrefixN(AIndex: SizeUInt; out P: PChar; out Len: SizeUInt): Boolean; inline;
    function GetAttributeNamespaceURIN(AIndex: SizeUInt; out P: PChar; out Len: SizeUInt): Boolean; inline;
    function GetAttributeValueN(AIndex: SizeUInt; out P: PChar; out Len: SizeUInt): Boolean; inline;
    function TryGetAttributeN(const AName: PChar; ANameLen: SizeUInt; out P: PChar; out Len: SizeUInt): Boolean; inline;

    function FreezeCurrentNode: IXmlNode; inline;
    function GetLine: SizeUInt; inline;
    function GetColumn: SizeUInt; inline;
    function GetPosition: SizeUInt; inline;
    function ReadAllToDocument: IXmlDocument; inline;
  end;

function TXmlReaderStub.ReadFromString(const AText: String): IXmlReader;
begin
  Result := ReadFromString(AText, []);
end;

function TXmlReaderStub.ReadFromString(const AText: String; AFlags: TXmlReadFlags): IXmlReader;
begin
  FToken := xtStartDocument;
  Result := Self;
end;

function TXmlReaderStub.ReadFromStringN(ABuf: PChar; ALength: SizeUInt): IXmlReader;
begin
  Result := ReadFromStringN(ABuf, ALength, []);
end;

function TXmlReaderStub.ReadFromStringN(ABuf: PChar; ALength: SizeUInt; AFlags: TXmlReadFlags): IXmlReader;
begin
  FToken := xtStartDocument;
  Result := Self;
end;

function TXmlReaderStub.ReadFromStream(AStream: TStream): IXmlReader;
begin
  Result := ReadFromStream(AStream, []);
end;

function TXmlReaderStub.ReadFromStream(AStream: TStream; AFlags: TXmlReadFlags): IXmlReader;
begin
  Result := ReadFromStream(AStream, AFlags, 256*1024);
end;

function TXmlReaderStub.ReadFromStream(AStream: TStream; AFlags: TXmlReadFlags; InitialBufCap: SizeUInt): IXmlReader;
begin
  FToken := xtStartDocument;
  Result := Self;
end;

function TXmlReaderStub.ReadFromFile(const AFileName: String): IXmlReader;
begin
  Result := ReadFromFile(AFileName, []);
end;

function TXmlReaderStub.ReadFromFile(const AFileName: String; AFlags: TXmlReadFlags): IXmlReader;
begin
  FToken := xtStartDocument;
  Result := Self;
end;

function TXmlReaderStub.ReadFromFile(const AFileName: String; AFlags: TXmlReadFlags; InitialBufCap: SizeUInt): IXmlReader;
begin
  Result := ReadFromFile(AFileName, AFlags);
end;

function TXmlReaderStub.Read: Boolean;
begin
  case FToken of
    xtStartDocument:
      begin
        FToken := xtEndDocument;
        Exit(True);
      end;
    xtEndDocument:
      Exit(False);
  else
    FToken := xtEndDocument;
    Exit(True);
  end;
end;

function TXmlReaderStub.GetNameN(out P: PChar; out Len: SizeUInt): Boolean; begin P:=nil; Len:=0; Result:=False; end;
function TXmlReaderStub.GetLocalNameN(out P: PChar; out Len: SizeUInt): Boolean; begin P:=nil; Len:=0; Result:=False; end;
function TXmlReaderStub.GetPrefixN(out P: PChar; out Len: SizeUInt): Boolean; begin P:=nil; Len:=0; Result:=False; end;
function TXmlReaderStub.GetNamespaceURIN(out P: PChar; out Len: SizeUInt): Boolean; begin P:=nil; Len:=0; Result:=False; end;
function TXmlReaderStub.GetValueN(out P: PChar; out Len: SizeUInt): Boolean; begin P:=nil; Len:=0; Result:=False; end;
function TXmlReaderStub.GetAttributeNameN(AIndex: SizeUInt; out P: PChar; out Len: SizeUInt): Boolean; begin P:=nil; Len:=0; Result:=False; end;
function TXmlReaderStub.GetAttributeLocalNameN(AIndex: SizeUInt; out P: PChar; out Len: SizeUInt): Boolean; begin P:=nil; Len:=0; Result:=False; end;
function TXmlReaderStub.GetAttributePrefixN(AIndex: SizeUInt; out P: PChar; out Len: SizeUInt): Boolean; begin P:=nil; Len:=0; Result:=False; end;
function TXmlReaderStub.GetAttributeNamespaceURIN(AIndex: SizeUInt; out P: PChar; out Len: SizeUInt): Boolean; begin P:=nil; Len:=0; Result:=False; end;
function TXmlReaderStub.GetAttributeValueN(AIndex: SizeUInt; out P: PChar; out Len: SizeUInt): Boolean; begin P:=nil; Len:=0; Result:=False; end;
function TXmlReaderStub.TryGetAttributeN(const AName: PChar; ANameLen: SizeUInt; out P: PChar; out Len: SizeUInt): Boolean; begin P:=nil; Len:=0; Result:=False; end;

function TXmlReaderStub.FreezeCurrentNode: IXmlNode; begin Result := nil; end;
function TXmlReaderStub.GetToken: TXmlToken; begin Result := FToken; end;
function TXmlReaderStub.GetDepth: SizeUInt; begin Result := 0; end;
function TXmlReaderStub.GetName: String; begin Result := ''; end;
function TXmlReaderStub.GetLocalName: String; begin Result := ''; end;
function TXmlReaderStub.GetPrefix: String; begin Result := ''; end;
function TXmlReaderStub.GetNamespaceURI: String; begin Result := ''; end;
function TXmlReaderStub.GetValue: String; begin Result := ''; end;
function TXmlReaderStub.IsEmptyElement: Boolean; begin Result := False; end;
function TXmlReaderStub.GetAttributeCount: SizeUInt; begin Result := 0; end;
function TXmlReaderStub.GetAttributeName(AIndex: SizeUInt): String; begin Result := ''; end;
function TXmlReaderStub.GetAttributeLocalName(AIndex: SizeUInt): String; begin Result := ''; end;
function TXmlReaderStub.GetAttributePrefix(AIndex: SizeUInt): String; begin Result := ''; end;
function TXmlReaderStub.GetAttributeNamespaceURI(AIndex: SizeUInt): String; begin Result := ''; end;
function TXmlReaderStub.GetAttributeValue(AIndex: SizeUInt): String; begin Result := ''; end;
function TXmlReaderStub.TryGetAttribute(const AName: String; out AValue: String): Boolean; begin AValue := ''; Result := False; end;
function TXmlReaderStub.GetLine: SizeUInt; begin Result := 0; end;
function TXmlReaderStub.GetColumn: SizeUInt; begin Result := 0; end;
function TXmlReaderStub.GetPosition: SizeUInt; begin Result := 0; end;
function TXmlReaderStub.ReadAllToDocument: IXmlDocument; inline;
begin
  Result := XmlReadAllToDocument(Self);
end;


type
  TXmlWriterStub = class(TInterfacedObject, IXmlWriter)
  private
    FBuffer: TStringBuilder;
    FStack: array of String;
    FDepth: Integer;
    FOpenTagPending: Boolean;
    // NS scope
    FNSStack: array of TNSBinding;
    FNSLen: SizeUInt;
    FPendingDecl: record
      Pending: Boolean;
      Version, Encoding: String;
    end;
    FPretty: Boolean;
    // Attr queue captured per open tag; always enqueue, later flush via placeholder
    type
      TPendingAttr = record
        Name, Value: String;
      end;
      TAttrGroup = record
        Attrs: array of TPendingAttr;
        Count: SizeInt;
      end;
    private
    FPendingAttrs: array of TPendingAttr;
    FPendingAttrCount: SizeInt;
    FAttrGroups: array of TAttrGroup;
    FAttrGroupCount: SizeInt;
    FSortAttrs: Boolean;
    FDedupAttrs: Boolean;
    FLastWasText: Boolean;
    FLastEmittedNL: Boolean;
    FLastWasPI: Boolean;

    procedure EnsureOpenTagClosed;
    procedure WriteIndent;
    function EscapeText(const S: String): String;
    function EscapeAttr(const S: String): String;
    procedure EnqueueAttr(const AName, AValue: String);
    procedure AppendAttrPlaceholder(ASelfClose: Boolean);
    function BuildAttrString(const G: TAttrGroup): String;
    function PrettyFormat(const S: String): String;
    function ReplaceNewlinePlaceholders(const S: String; Pretty: Boolean): String;
    function StripAnyPlaceholders(const S: String): String;
    function EndsWithNLPlaceholder: Boolean;

  public
    constructor Create;
    destructor Destroy; override;

    procedure Reset;
    procedure StartDocument; overload;
    procedure StartDocument(const AVersion, AEncoding: String); overload;
    procedure EndDocument;

    procedure StartElement(const AName: String);
    procedure StartElementNS(const APrefix, ALocalName, ANamespaceURI: String);
    procedure EndElement;
    procedure WNSPushBinding(const APrefix, AURI: String);
    function WNSResolve(const APrefix: String): String;
    procedure WNSPushMark;
    procedure WNSPopToMark;
    function WNSFindPrefix(const AURI: String): String;

    function WNSHasURI(const AURI: String): Boolean;

    procedure WriteAttribute(const AName, AValue: String);
    procedure WriteAttributeNS(const APrefix, ALocalName, ANamespaceURI, AValue: String);
    procedure WriteString(const AText: String);
    procedure WriteCData(const AText: String);
    procedure WriteComment(const AText: String);
    procedure WritePI(const ATarget, AData: String);
    // 快速声明 URI 到当前作用域（默认 ns 用空前缀）
    procedure DeclareNamespace(const APrefix, AURI: String);

    procedure Flush;

    function WriteToString: String; overload;
    function WriteToString(AFlags: TXmlWriteFlags): String; overload;
    procedure WriteToStream(AStream: TStream); overload;
    procedure WriteToStream(AStream: TStream; AFlags: TXmlWriteFlags); overload;
    procedure WriteToFile(const AFileName: String); overload;
    procedure WriteToFile(const AFileName: String; AFlags: TXmlWriteFlags); overload;
  end;



// ===== Reader NS helpers =====
procedure TXmlReaderImpl.NSPushBinding(const APrefix, AURI: String);
begin
  if FNSLen >= SizeUInt(Length(FNSStack)) then
    SetLength(FNSStack, Length(FNSStack)*2 + 8);
  FNSStack[FNSLen].Prefix := APrefix;
  FNSStack[FNSLen].URI := AURI;
  Inc(FNSLen);
  // 同步到快速表（跳过作用域标记）
  if (APrefix<>#1) then NSMapPut(APrefix, AURI);
end;

procedure TXmlReaderImpl.NSPushMark;
begin
  NSPushBinding(#1, ''); // 用前缀=#1 作为作用域标记
end;

procedure TXmlReaderImpl.NSPopToMark;
begin
  while (FNSLen>0) and (FNSStack[FNSLen-1].Prefix<>#1) do
  begin
    // 同步快速表：移除绑定（简化起见，整表清空等待重建，可选优化为惰性 tombstone）
    Dec(FNSLen);
  end;
  if (FNSLen>0) and (FNSStack[FNSLen-1].Prefix=#1) then
  begin
    Dec(FNSLen);
  end;
  // 作用域关闭后清空快速表
  NSMapClear;
end;

function TXmlReaderImpl.NSResolve(const APrefix: String): String;
var i: SizeInt;
begin
  // 简单缓存：与上次解析相同的前缀，直接返回上次结果（字符串比较成本较低）
  if (Length(FNSUriOwned)>0) and (FNSStack[FNSLen-1].Prefix = APrefix) then
    Exit(String(FNSUriOwned));
  // 先查快速表
  if NSMapTryGet(APrefix, Result) then begin FNSUriOwned := AnsiString(Result); Exit; end;
  // 回退线性扫描（兼容极端退化场景）
  Result := '';
  for i := FNSLen-1 downto 0 do
    if FNSStack[i].Prefix = APrefix then begin Result := FNSStack[i].URI; Break; end;
  FNSUriOwned := AnsiString(Result);
end;

// ===== end Reader NS helpers =====

constructor TXmlWriterStub.Create;
begin
  inherited Create;
  FBuffer := TStringBuilder.Create;
  SetLength(FStack, 0);
  FDepth := 0;
  FOpenTagPending := False;
  FPendingDecl.Pending := False;
  FPretty := False;
  SetLength(FNSStack, 0);
  FNSLen := 0;
  SetLength(FPendingAttrs, 0);
  FPendingAttrCount := 0;
  SetLength(FAttrGroups, 0);
  FAttrGroupCount := 0;
  FSortAttrs := False;
  FDedupAttrs := False;
  FLastWasText := False;
end;

procedure TXmlReaderImpl.NSMapClear;
begin
  SetLength(FNSMapKeys, 0);
  SetLength(FNSMapVals, 0);
  SetLength(FNSMapUsed, 0);
  FNSMapCap := 0;
end;

procedure TXmlReaderImpl.NSMapEnsureCap(Need: SizeUInt);
var newCap, i: SizeUInt;
begin
  if FNSMapCap >= Need then Exit;
  if Need < 16 then newCap := 16 else newCap := Need;
  SetLength(FNSMapKeys, newCap);
  SetLength(FNSMapVals, newCap);
  SetLength(FNSMapUsed, newCap);
  for i := 0 to newCap-1 do FNSMapUsed[i] := False;
  FNSMapCap := newCap;
end;

function TXmlReaderImpl.NSMapHash(const S: String): SizeUInt;
var h: SizeUInt; i: SizeInt;
begin
  // 简易 FNV-1a（小范围，够用）
  h := 2166136261;
  for i := 1 to Length(S) do
  begin
    h := h xor Ord(S[i]);
    h := h * 16777619;
  end;
  Result := h;
end;

function TXmlReaderImpl.NSMapTryGet(const Key: String; out Val: String): Boolean;
var idx, probe, mask: SizeUInt;
begin
  Result := False;
  if FNSMapCap = 0 then Exit;
  mask := FNSMapCap - 1;
  idx := NSMapHash(Key) and mask;
  probe := 1;
  while FNSMapUsed[idx] do
  begin
    if FNSMapKeys[idx] = Key then begin Val := FNSMapVals[idx]; Exit(True); end;
    idx := (idx + probe) and mask;
    Inc(probe);
  end;
end;

procedure TXmlReaderImpl.NSMapPut(const Key, Val: String);
var idx, probe, mask: SizeUInt; load, i: SizeUInt; curUsed: SizeUInt;
begin
  if FNSMapCap = 0 then NSMapEnsureCap(16);
  // 简单扩容策略：装载因子 > 0.7 时翻倍并重建
  curUsed := 0;
  for i := 0 to FNSMapCap-1 do if FNSMapUsed[i] then Inc(curUsed);
  load := (curUsed * 10) div FNSMapCap;
  if load > 7 then
  begin
    NSMapEnsureCap(FNSMapCap * 2);
    // 重建：从现有栈重新插入（此处简化：清空后重建由调用方触发，避免 O(n^2)）
    // 这里直接清空，后续 NSPushMark/解析属性会再次填充
    for i := 0 to FNSMapCap-1 do FNSMapUsed[i] := False;
  end;
  mask := FNSMapCap - 1;
  idx := NSMapHash(Key) and mask;
  probe := 1;
  while FNSMapUsed[idx] and (FNSMapKeys[idx] <> Key) do
  begin
    idx := (idx + probe) and mask;
    Inc(probe);
  end;
  FNSMapUsed[idx] := True;
  FNSMapKeys[idx] := Key;
  FNSMapVals[idx] := Val;
end;

procedure TXmlWriterStub.WNSPushBinding(const APrefix, AURI: String);
begin
  if FNSLen >= SizeUInt(Length(FNSStack)) then
    SetLength(FNSStack, Length(FNSStack)*2 + 8);
  FNSStack[FNSLen].Prefix := APrefix;
  FNSStack[FNSLen].URI := AURI;
  Inc(FNSLen);
end;

function TXmlWriterStub.WNSResolve(const APrefix: String): String;
var i: SizeInt;
begin
  Result := '';
  for i := FNSLen-1 downto 0 do
    if FNSStack[i].Prefix = APrefix then exit(FNSStack[i].URI);
end;

procedure TXmlWriterStub.WNSPushMark;
begin
  WNSPushBinding(#1, '');
end;

procedure TXmlWriterStub.WNSPopToMark;
begin
  while (FNSLen>0) and (FNSStack[FNSLen-1].Prefix<>#1) do Dec(FNSLen);
  if (FNSLen>0) and (FNSStack[FNSLen-1].Prefix=#1) then Dec(FNSLen);
end;

function TXmlWriterStub.WNSFindPrefix(const AURI: String): String;
var i: SizeInt;
begin
  Result := '';
  for i := FNSLen-1 downto 0 do
    if (FNSStack[i].Prefix<>#1) and (FNSStack[i].URI = AURI) then
      exit(FNSStack[i].Prefix);
end;

function TXmlWriterStub.WNSHasURI(const AURI: String): Boolean;
var j: SizeInt;
begin
  Result := False;
  for j := FNSLen-1 downto 0 do
    if (FNSStack[j].Prefix<>#1) and (FNSStack[j].URI = AURI) then exit(True);
end;





{ TXmlReaderImpl helpers }
procedure TXmlReaderImpl.StackPush(P: PChar; L: SizeUInt);
begin
  if FStackLen >= SizeUInt(Length(FStack)) then
    SetLength(FStack, Length(FStack) * 2 + 4);
  FStack[FStackLen].P := P;
  FStack[FStackLen].L := L;
  // 流式模式下，名称切片会在下次 Read 前被压实失效，需要持有一份拷贝
  if FSourceKind = skStream then
  begin
    SetString(FStack[FStackLen].Owned, P, L);
    // 将 P 重定向到 Owned 的数据，保证后续 CompareMem 等基于指针的比较仍有效
    FStack[FStackLen].P := PChar(FStack[FStackLen].Owned);
  end
  else
    FStack[FStackLen].Owned := '';
  Inc(FStackLen);
end;

procedure TXmlReaderImpl.StackPop;
begin
  if FStackLen > 0 then Dec(FStackLen);
end;
function TXmlReaderImpl.ParseQuoted(out VP: PChar; out VL: SizeUInt): Boolean;
var Q: Char; S: PChar; SegBuf: AnsiString;
begin
  if (FCur >= FEnd) or not (FCur^ in ['"','''']) then Exit(False);
  Q := FCur^; Inc(FCur);
  S := FCur;
  if FSourceKind <> skStream then
  begin
    while (FCur < FEnd) and (FCur^ <> Q) do Inc(FCur);
    if FCur >= FEnd then Exit(False);
    VP := S; VL := FCur - S;
    Inc(FCur); // skip closing quote
    Exit(True);
  end;

  // 流式模式：支持跨块累积
  ScratchClear;
  while True do
  begin
    // 快速前进直到当前块的末尾或遇到引号
    while (FCur < FEnd) and (FCur^ <> Q) do Inc(FCur);
    if (FCur < FEnd) and (FCur^ = Q) then Break; // 找到终止引号
    // 走到块末尾：累积片段并拉流
    if FCur > S then
    begin
      if FScratch = '' then SetString(FScratch, S, FCur - S)
      else ScratchAppend(S, FCur - S);
    end;
    if not EnsureLookahead(1) then Exit(False); // EOF 前未闭合
    S := FCur;
  end;
  // 终止前的最后一段加入
  if FCur > S then
  begin
    if FScratch = '' then SetString(FScratch, S, FCur - S)
    else ScratchAppend(S, FCur - S);
  end;
  if FScratch <> '' then begin VP := PChar(FScratch); VL := Length(FScratch); end
  else begin VP := S; VL := FCur - S; end;
  Inc(FCur); // skip closing quote
  Result := True;
end;

function TXmlReaderImpl.ParseAttributes: Boolean;
var NP: PChar; NL: SizeUInt; VP: PChar; VL: SizeUInt; k: SizeUInt; Pref, URI: String;
    nm: String; NameCopy: String;
begin
  FAttrCount := 0;
  // 预留少量空间，避免频繁扩容
  if Length(FAttrs) < 8 then SetLength(FAttrs, 8);
  while True do
  begin
    NameCopy := '';
    if not EnsureLookahead(1) then begin if (FSourceKind = skStream) then begin if FEOF then Break else Continue; end else Break; end;
    SkipSpaces;
    if not EnsureLookahead(1) then begin if (FSourceKind = skStream) then begin if FEOF then Break else Continue; end else Break; end;

    // 若当前位置是合法的属性名起始，则优先解析属性名，避免在极小缓冲下误把边界当作结束符
    if (FCur^ in ['A'..'Z','a'..'z','_',':']) then
    begin
      if not ParseName(NP, NL) then begin Result := False; Exit; end;
      if FSourceKind = skStream then begin SetString(NameCopy, NP, NL); NP := PChar(NameCopy); NL := Length(NameCopy); end;
    end
    else
    begin
      // 非属性名起始：才判定是否为 '/>' 或 '>' 结束
      if (FCur^ = '>') then Break;
      if (FCur^ = '/') then
      begin
        if not EnsureLookahead(2) then
        begin
          if (FSourceKind = skStream) then
          begin
            // 拉流不足，尝试推进空白并继续
            SkipSpaces;
            if not EnsureLookahead(1) then begin if FEOF then Break else Continue; end;
            Continue;
          end
          else
            Break; // 字符串模式：无更多输入，交由调用方判定未闭合
        end;
        if ((FCur+1)^ = '>') then Break;
      end;
      // 若为空白或其他噪音字符，消耗后继续（避免在边界处空转）
      if (FCur^ <= ' ') then begin SkipSpaces; Continue; end
      else begin Inc(FCur); Continue; end;
    end;
    SkipSpaces;
    // 允许 name 与 '=' 之间存在空白
    if not EnsureLookahead(1) then
      raise EXmlParseError.Create(xecMalformedXml, 'Attribute missing =', GetPosition, GetLine, GetColumn);
    // 宽松处理：属性名后允许有空白；若当前位置不是 '='，尝试跳过空白后再检查
    if (FCur^ <> '=') then
    begin
      SkipSpaces;
      if not EnsureLookahead(1) or (FCur^ <> '=') then
        raise EXmlParseError.Create(xecMalformedXml, 'Attribute missing =', GetPosition, GetLine, GetColumn);
    end;
    Inc(FCur); // '='
    if not EnsureLookahead(1) then
      raise EXmlParseError.Create(xecMalformedXml, 'Attribute value not quoted or unterminated', GetPosition, GetLine, GetColumn);
    SkipSpaces;
    if not ParseQuoted(VP, VL) then
      raise EXmlParseError.Create(xecMalformedXml, 'Attribute value not quoted or unterminated', GetPosition, GetLine, GetColumn);

    // 命名空间声明过滤与绑定：xmlns 或 xmlns:prefix
    // 注意：根据 XML 规范，xmlns 声明的值中的字符实体不参与普通属性处理，仅用于 URI 解析
    if (NL = 5) and CompareMem(NP, PChar('xmlns'), 5) then
    begin
      // 默认命名空间声明（不影响属性）
      URI := DecodeEntities(VP, VL);
      if URI = XMLNS_URI then
        raise EXmlParseError.Create(xecMalformedXml, 'Cannot bind default namespace to xmlns URI', GetPosition, GetLine, GetColumn);
      NSPushBinding('', URI);
      Continue;
    end
    else if (NL > 6) and CompareMem(NP, PChar('xmlns:'), 6) then
    begin
      // 提取前缀名（兼容旧编译器：使用上方局部变量 Pref）
      SetString(Pref, NP+6, NL-6);
      URI := DecodeEntities(VP, VL);
      // 禁止重绑定保留前缀
      if (Pref='xml') and (URI<>XML_NS_URI) then
        raise EXmlParseError.Create(xecMalformedXml, 'Cannot rebind reserved prefix xml', GetPosition, GetLine, GetColumn);
      if (Pref='xmlns') then
        raise EXmlParseError.Create(xecMalformedXml, 'Cannot bind reserved prefix xmlns', GetPosition, GetLine, GetColumn);
      if (URI=XMLNS_URI) and (Pref<>'xmlns') then
        raise EXmlParseError.Create(xecMalformedXml, 'Cannot bind prefix to xmlns URI', GetPosition, GetLine, GetColumn);
      NSPushBinding(Pref, URI);
      Continue;
    end;

    // 保存切片（非 xmlns 声明）
    if FAttrCount >= SizeUInt(Length(FAttrs)) then
      SetLength(FAttrs, Length(FAttrs) * 2 + 4);
    FAttrs[FAttrCount].NameP := NP;

    // 重复属性名检查（简单按精确匹配）
    if FAttrCount > 0 then
      for k := 0 to FAttrCount-1 do
        if (FAttrs[k].NameP<>nil) and (NL>0) and (FAttrs[k].NameLen = NL) and CompareMem(FAttrs[k].NameP, NP, NL) then
          raise EXmlParseError.Create(xecMalformedXml, 'Duplicate attribute name', GetPosition, GetLine, GetColumn);

    FAttrs[FAttrCount].NameLen := NL;



    // 若为流式模式，名称切片在窗口压实时可能失效，拷贝持有
    if FSourceKind = skStream then
    begin
      SetString(FAttrs[FAttrCount].NameOwned, NP, NL);
      FAttrs[FAttrCount].NameP := PChar(FAttrs[FAttrCount].NameOwned);
    end;
    // 流式模式下统一持久化属性值，避免窗口压实或 FScratch 复用导致悬挂
    if (FSourceKind = skStream) then
    begin
      // 保证名称在流式窗口压实时不失效：使用 NameCopy 持久化
      FAttrs[FAttrCount].NameOwned := NameCopy;
      FAttrs[FAttrCount].NameP := PChar(FAttrs[FAttrCount].NameOwned);
      if (VL > 0) then SetString(FAttrs[FAttrCount].ValueOwned, VP, VL)
      else FAttrs[FAttrCount].ValueOwned := '';
      FAttrs[FAttrCount].ValueP := PChar(FAttrs[FAttrCount].ValueOwned);
      FAttrs[FAttrCount].ValueLen := Length(FAttrs[FAttrCount].ValueOwned);
    end
    else
    begin
      FAttrs[FAttrCount].ValueP := VP;
      FAttrs[FAttrCount].ValueLen := VL;
    end;
    Inc(FAttrCount);
  end;
  Result := True;
end;

procedure TXmlReaderImpl.SkipSpaces;
begin
  while (FCur < FEnd) and (FCur^ <= ' ') do Inc(FCur);
end;

function TXmlReaderImpl.StartsWith(const S: PChar; L: SizeUInt): Boolean;
begin
  if (FEnd - FCur) < PtrInt(L) then Exit(False);
  Result := CompareMem(FCur, S, L);
end;

procedure TXmlReaderImpl.ScratchClear;
begin
  SetLength(FScratch, 0);
end;

procedure TXmlReaderImpl.ScratchAppend(P: PChar; L: SizeUInt);
var oldLen: SizeUInt;
begin
  if L=0 then Exit;
  if FScratch='' then begin SetString(FScratch, P, L); Exit; end;
  oldLen := Length(FScratch);
  SetLength(FScratch, oldLen + L);
  Move(P^, FScratch[oldLen+1], L);
end;

function TXmlReaderImpl.DecodeEntities(P: PChar; L: SizeUInt): String;
var
  i, j, LenSrc: SizeUInt;
  Src: AnsiString;
  cp, base, digit: SizeUInt;
  ch: Char;
  function StartsWithAt(const Lit: AnsiString): Boolean;
  var k, LL: SizeUInt;
  begin
    LL := Length(Lit);
    if i + LL - 1 > LenSrc then Exit(False);
    for k := 1 to LL do if Src[i + k - 1] <> Lit[k] then Exit(False);
    Result := True;
  end;
  procedure AppendUtf8(C: SizeUInt);
  begin
    // 将 Unicode 码点 C 以 UTF-8 形式追加到 Result（AnsiString，字节容器）
    if C <= $7F then
    begin
      Result += AnsiChar(C);
    end
    else if C <= $7FF then
    begin
      Result += AnsiChar($C0 or (C shr 6));
      Result += AnsiChar($80 or (C and $3F));
    end
    else if C <= $FFFF then
    begin
      Result += AnsiChar($E0 or (C shr 12));
      Result += AnsiChar($80 or ((C shr 6) and $3F));
      Result += AnsiChar($80 or (C and $3F));
    end
    else if C <= $10FFFF then
    begin
      Result += AnsiChar($F0 or (C shr 18));
      Result += AnsiChar($80 or ((C shr 12) and $3F));
      Result += AnsiChar($80 or ((C shr 6) and $3F));
      Result += AnsiChar($80 or (C and $3F));
    end
    else
    begin
      // 超出 Unicode 范围，退化为 '?'
      Result += AnsiChar('?');
    end;
  end;
begin
  if (P = nil) or (L = 0) then Exit('');
  // 复制切片，避免跨块/悬空指针
  SetString(Src, P, L);
  LenSrc := Length(Src);
  Result := '';
  i := 1; // 1-based indexing
  while i <= LenSrc do
  begin
    ch := Src[i];
    if ch = '&' then
    begin
      // named entities
      if StartsWithAt('&quot;') then begin Result += '"'; Inc(i, 6); Continue; end;
      if StartsWithAt('&amp;')  then begin Result += '&';  Inc(i, 5); Continue; end;
      if StartsWithAt('&lt;')   then begin Result += '<';  Inc(i, 4); Continue; end;
      if StartsWithAt('&gt;')   then begin Result += '>';  Inc(i, 4); Continue; end;
      if StartsWithAt('&apos;') then begin Result += ''''; Inc(i, 6); Continue; end;
      // numeric entities: &#...; or &#x...;
      if (i + 1 <= LenSrc) and (Src[i+1] = '#') then
      begin
        j := i + 2;
        cp := 0;
        if (j <= LenSrc) and ((Src[j] = 'x') or (Src[j] = 'X')) then
        begin
          Inc(j);
          base := 16;
          while (j <= LenSrc) and (((Src[j] >= '0') and (Src[j] <= '9')) or ((Src[j] >= 'a') and (Src[j] <= 'f')) or ((Src[j] >= 'A') and (Src[j] <= 'F'))) do
          begin
            if (Src[j] >= '0') and (Src[j] <= '9') then digit := Ord(Src[j]) - Ord('0')
            else if (Src[j] >= 'a') and (Src[j] <= 'f') then digit := 10 + Ord(Src[j]) - Ord('a')
            else digit := 10 + Ord(Src[j]) - Ord('A');
            cp := cp * base + digit;
            Inc(j);
          end;
        end
        else
        begin
          base := 10;
          while (j <= LenSrc) and (Src[j] >= '0') and (Src[j] <= '9') do
          begin
            digit := Ord(Src[j]) - Ord('0');
            cp := cp * base + digit;
            Inc(j);
          end;
        end;
        if (j <= LenSrc) and (Src[j] = ';') and (cp <= $10FFFF) then
        begin
          AppendUtf8(cp);
          i := j + 1; // skip ';'
          Continue;
        end;
        // malformed numeric entity: fall through
      end;
      Result += '&'; Inc(i);
    end
    else
    begin
      Result += ch; Inc(i);
    end;
  end;
end;

procedure TXmlReaderImpl.Step;
begin
  if FCur^ = #10 then
  begin
    Inc(FLine);
    FColumn := 1;
  end
  else
    Inc(FColumn);
  Inc(FCur);
end;

procedure TXmlReaderImpl.SkipN(N: SizeInt);
var i: SizeInt;
begin
  for i := 1 to N do Step;
end;


function TXmlReaderImpl.ParseName(out P: PChar; out L: SizeUInt): Boolean;
var S: PChar;
begin
  if (FCur >= FEnd) and not EnsureLookahead(1) then Exit(False);
  S := FCur;
  // 名称首字符：字母、'_'、':'
  if (FCur >= FEnd) or not (FCur^ in ['A'..'Z','a'..'z','_',':']) then Exit(False);
  Step; // consume first char
  // 后续字符：字母数字、'-','_','.',':'
  while True do
  begin
    if (FCur < FEnd) and (FCur^ in ['A'..'Z','a'..'z','0'..'9','-','_','.',':']) then Step
    else if (FCur >= FEnd) and EnsureLookahead(1) then Continue
    else Break;
  end;
  P := S; L := FCur - S; Result := True;
end;

function TXmlReaderImpl.ParseUntil(const Terminator: PChar; TermLen: SizeUInt): Boolean;
begin
  while (FCur < FEnd) do
  begin
    if (FEnd - FCur) >= PtrInt(TermLen) then
      if CompareMem(FCur, Terminator, TermLen) then Exit(True);
    Step;
  end;
  Result := False;
end;

function TXmlReaderImpl.ReadFromStream(AStream: TStream): IXmlReader;
begin
  Result := ReadFromStream(AStream, []);
end;

{ TXmlReaderImpl IXmlReader }
function TXmlReaderImpl.ReadFromString(const AText: String): IXmlReader;
begin
  Result := ReadFromString(AText, []);
end;

function TXmlReaderImpl.ReadFromStream(AStream: TStream; AFlags: TXmlReadFlags): IXmlReader;
const INIT_CAP = 256*1024;
begin
  Result := ReadFromStream(AStream, AFlags, INIT_CAP);
end;

function TXmlReaderImpl.ReadFromStream(AStream: TStream; AFlags: TXmlReadFlags; InitialBufCap: SizeUInt): IXmlReader;
begin
  // 真流式入口（Step 1）：初始化流源与解析状态；实际解析在 Read 中的流式分支进行
  ReleaseStreamSource; // 清理旧的流式资源（如有）
  if InitialBufCap = 0 then InitialBufCap := 256*1024;
  InitStreamSource(AStream, InitialBufCap);

  // 初始化解析公共状态
  FText := '';
  FBuf := PChar(FRingBuf + FRingStart);
  FCur := FBuf;
  FEnd := FBuf + FRingLen;
  FToken := xtStartDocument;
  FDepth := 0;
  FFlags := AFlags;
  FLine := 1; FColumn := 1;
  FPosP := nil; FTokP := nil;
  FNameP := nil; FNameLen := 0;
  FValueP := nil; FValueLen := 0;
  FEmpty := False;
  FPendingAutoEnd := False;
  FStackLen := 0;
  SetLength(FStack, 0);
  SetLength(FNSStack, 0); FNSLen := 0;
  // 初始化编码检测状态
  FDetectedEnc := deUnknown;

  // 标记来源为流
  FSourceKind := skStream;
  // 初始化转码模式与暂存
  FTransMode := tmNone; FCarryLen := 0; SetLength(FTransPendingRaw, 0);

  Result := Self;
end;

function TXmlReaderImpl.ReadFromString(const AText: String; AFlags: TXmlReadFlags): IXmlReader;
begin
  FText := AText;
  FBuf := PChar(FText);
  FCur := FBuf;
  FEnd := FBuf + Length(FText);
  FToken := xtStartDocument;
  FDepth := 0;
  FFlags := AFlags;
  FLine := 1; FColumn := 1; FTokLine := 1; FTokColumn := 1;
  // 初始化渐进式行列缓存（字符串路径）
  FLCScanP := FBuf; FLCLine := 1; FLCColumn := 1;
  FNameP := nil; FNameLen := 0;
  FValueP := nil; FValueLen := 0; SetLength(FValueOwned, 0);
  FEmpty := False;
  FPendingAutoEnd := False;
  FStackLen := 0;
  SetLength(FStack, 0);
  SetLength(FNSStack, 0); FNSLen := 0;
  SetLength(FAttrs, 0); FAttrCount := 0;
  SetLength(FScratch, 0);
  // 初始化 Freeze 构建状态
  FBuildDoc := nil; SetLength(FNodeIdxStack, 0); FNodeIdxLen := 0;
  Result := Self;
end;

function TXmlReaderImpl.ReadFromStringN(ABuf: PChar; ALength: SizeUInt): IXmlReader;
begin
  Result := ReadFromStringN(ABuf, ALength, []);
end;

function TXmlReaderImpl.ReadFromStringN(ABuf: PChar; ALength: SizeUInt; AFlags: TXmlReadFlags): IXmlReader;
begin
  SetString(FText, ABuf, ALength); // 保持所有权
  Result := ReadFromString(FText, AFlags);
end;



function TXmlReaderImpl.ReadFromFile(const AFileName: String): IXmlReader;
begin
  Result := ReadFromFile(AFileName, []);
end;

function TXmlReaderImpl.ReadFromFile(const AFileName: String; AFlags: TXmlReadFlags): IXmlReader;
begin
  // 统一走流式路径，避免一次性读入内存；使用默认初始缓冲容量
  Result := ReadFromFile(AFileName, AFlags, 256*1024);
end;

function TXmlReaderImpl.ReadFromFile(const AFileName: String; AFlags: TXmlReadFlags; InitialBufCap: SizeUInt): IXmlReader;
var FS: TFileStream;
begin
  // 直接走流式路径，避免一次性读入内存，且由 Reader 负责释放文件流
  FS := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
  Result := ReadFromStream(FS, AFlags, InitialBufCap);
  // Reader 接管流所有权以确保生命周期
  FOwnsStream := True;
end;

function TXmlReaderImpl.Read: Boolean;
var S: PChar; idx, jj: SizeUInt; PfxLen: SizeUInt; Pfx: String; Coalesce: Boolean;
    StartDecl: PChar; DeclLen: SizeUInt; Seg: AnsiString; encPos, eqPos, endq: SizeInt; rest, encName: String; q: Char; SegBuf: AnsiString;
begin
  // 流式路径：如标记需要压实则压实后再进入流式循环
  if FSourceKind = skStream then
  begin
    if FNeedCompact then begin AdvanceWindowToCur; FNeedCompact := False; end;
    Exit(ReadStreamImpl);
  end;

  // 处理 <x/> 自动补发 EndElement
  if FPendingAutoEnd then
  begin
    FPendingAutoEnd := False;
    FToken := xtEndElement;
    if FStackLen > 0 then
    begin
      FNameP := FStack[FStackLen-1].P;
      FNameLen := FStack[FStackLen-1].L;
      FTokP := FNameP; FTokLine := FLine; FTokColumn := FColumn;
      StackPop;
    end;
    // 弹出当前元素作用域的 NS 绑定
    NSPopToMark;
    if FDepth > 0 then Dec(FDepth);
    Exit(True);
  end;

  // 文档开始后第一次读，可能跳过 XML 声明
  if FToken = xtStartDocument then
  begin
    // 跳空白
    SkipSpaces;
    // 跳过 "<?xml ...?>"
    if (FEnd - FCur >= 5) and (FCur^ = '<') and ((FCur+1)^='?') and ((FCur+2)^='x') and ((FCur+3)^='m') and ((FCur+4)^='l') then
    begin
      SkipN(5);
      // 捕获 XML 声明内容到 FScratch，解析 encoding（仅在 AutoDecode 开启时生效）
      StartDecl := FCur;
      while (FCur < FEnd-1) and not ((FCur^='?') and ((FCur+1)^='>')) do Step;
      DeclLen := FCur - StartDecl;
      if DeclLen > 0 then
      begin
        SetString(Seg, StartDecl, DeclLen);
        FScratch := Seg;
        if (FScratch <> '') then
        begin
          encPos := Pos('encoding', LowerCase(FScratch));
          if encPos > 0 then
          begin
            rest := Copy(FScratch, encPos+8, MaxInt);
            eqPos := Pos('=', rest);
            if eqPos > 0 then
            begin
              rest := Trim(Copy(rest, eqPos+1, MaxInt));
              if (Length(rest) >= 1) and ((rest[1] = '"') or (rest[1] = '''')) then
              begin
                q := rest[1];
                endq := Pos(q, Copy(rest, 2, MaxInt));
                if endq > 0 then
                begin
                  encName := Copy(rest, 2, endq-1);
                  if CompareText(encName, 'utf-8') <> 0 then
                    raise EXmlParseError.Create(xecInvalidEncoding, 'Unsupported declared encoding (only UTF-8 supported currently): '+encName, GetPosition, GetLine, GetColumn);
                end;
              end;
            end;
          end;
        end;
      end;
      if (FCur < FEnd-1) then SkipN(2);
    end;
  end;

  // 跳空白 -> 如果是纯空白，作为 Whitespace Token 返回（可用 Flag 后续抉择）
  if (FCur < FEnd) and (FCur^ <= ' ') then
  begin
    S := FCur;
    SkipSpaces;
    if FCur > S then
    begin
      if (xrfIgnoreWhitespace in FFlags) then
        // 忽略空白，继续解析
      else
      begin
        FToken := xtWhitespace;
        FValueP := S; FValueLen := FCur - S;
        FTokP := FValueP; FTokLine := FLine; FTokColumn := FColumn;
        Exit(True);
      end;
    end;
  end;

  if FCur >= FEnd then
  begin
    if FToken <> xtEndDocument then
    begin
      FToken := xtEndDocument; Exit(True);
    end
    else Exit(False);
  end;

  if FCur^ = '<' then
  begin
    Step; // Inc(FCur)
    // 注释 <!-- ... -->
    if (FCur < FEnd-2) and (FCur^='!') and ((FCur+1)^='-') and ((FCur+2)^='-') then
    begin
      SkipN(3);
      S := FCur;
      while (FCur < FEnd-2) and not ((FCur^='-') and ((FCur+1)^='-') and ((FCur+2)^='>')) do Step;
      if (FCur < FEnd-2) then
      begin
        FToken := xtComment;
        FValueP := S; FValueLen := FCur - S;
        FTokP := FValueP; FTokLine := FLine; FTokColumn := FColumn;
        SkipN(3);
        if (xrfIgnoreComments in FFlags) then
          Exit(Read) // 继续读取下一个事件
        else
          Exit(True);
      end
      else begin
        raise EXmlParseError.Create(xecMalformedXml, 'Unterminated comment', GetPosition, GetLine, GetColumn);
      end;

    end
    // CDATA <![CDATA[ ... ]]>
    else if (FCur < FEnd-7) and (FCur^='!') and ((FCur+1)^='[') and ((FCur+2)^='C') and ((FCur+3)^='D') and ((FCur+4)^='A') and ((FCur+5)^='T') and ((FCur+6)^='A') and ((FCur+7)^='[') then
    begin
      SkipN(8);
      S := FCur;
      while (FCur < FEnd-2) and not ((FCur^=']') and ((FCur+1)^=']') and ((FCur+2)^='>')) do Step;
      if (FCur < FEnd-2) then
      begin
        // 若需要合并文本：先捕获本段 CDATA，然后继续粘连后续 Text/CDATA
        if (xrfCoalesceText in FFlags) then
        begin
          // 当前 CDATA 内容
          FValueOwned := '';
          if FCur > S then SetString(FValueOwned, S, FCur - S);
          SkipN(3);
          // 粘连循环：后续若紧接文本或 CDATA，则都并入
          while True do
          begin
            // 文本：连续非 '<'
            if (FCur < FEnd) and (FCur^ <> '<') then
            begin
              S := FCur;
              while (FCur < FEnd) and (FCur^ <> '<') do Inc(FCur);
              if FCur > S then FValueOwned += AnsiString(Copy(S,1,FCur-S));
              Continue;
            end;
            // 紧跟另一个 CDATA
            if (FCur < FEnd-8) and (FCur^='<') and ((FCur+1)^='!') and ((FCur+2)^='[') and ((FCur+3)^='C') and ((FCur+4)^='D') and ((FCur+5)^='A') and ((FCur+6)^='T') and ((FCur+7)^='A') and ((FCur+8)^='[') then
            begin
              SkipN(9);
              S := FCur;
              while (FCur < FEnd-2) and not ((FCur^=']') and ((FCur+1)^=']') and ((FCur+2)^='>')) do Step;
              if (FCur < FEnd-2) and (FCur > S) then
              begin
                FValueOwned += AnsiString(Copy(S,1,FCur-S));
                SkipN(3);
                Continue;
              end
              else break;
            end
            else break;
          end;
          // 产出合并后的文本 token
          if Length(FValueOwned)>0 then begin FValueP := PChar(FValueOwned); FValueLen := Length(FValueOwned); end else begin FValueP := nil; FValueLen := 0; end;
          FToken := xtText; FTokP := FValueP; FTokLine := FLine; FTokColumn := FColumn;
          Exit(True);
        end
        else
        begin
          FToken := xtCData;
          FValueP := S; FValueLen := FCur - S;
          FTokP := FValueP; FTokLine := FLine; FTokColumn := FColumn;
          SkipN(3);
          Exit(True);
        end;
      end
      else begin
        raise EXmlParseError.Create(xecMalformedXml, 'Unterminated CDATA', GetPosition, GetLine, GetColumn);
      end;
    end
    // 处理指令 <?target data?>
    else if (FCur < FEnd) and (FCur^='?') then
    begin
      Step; // skip '?'
      if not ParseName(FNameP, FNameLen) then begin FToken := xtEndDocument; Exit(True); end;
      S := FCur;
      while (FCur < FEnd-1) and not ((FCur^='?') and ((FCur+1)^='>')) do Step;
      if (FCur < FEnd-1) then
      begin
        FToken := xtPI;
        FValueP := S; FValueLen := FCur - S;
        FTokP := FValueP; FTokLine := FLine; FTokColumn := FColumn;
        SkipN(2);
        Exit(True);
      end
      else begin
        raise EXmlParseError.Create(xecMalformedXml, 'Unterminated PI', GetPosition, GetLine, GetColumn);
      end;
    end
    else if (FCur < FEnd) and (FCur^ = '/') then
    begin
      // 结束标签 </name>
      Inc(FCur);
      if not ParseName(FNameP, FNameLen) then begin FToken := xtEndDocument; Exit(True); end;
      while (FCur < FEnd) and (FCur^ <> '>') do Inc(FCur);
      if FCur < FEnd then Inc(FCur);
      // 校验结束标签是否与栈顶匹配
      if (FStackLen = 0) or ( (FStack[FStackLen-1].L <> FNameLen) or (not CompareMem(FStack[FStackLen-1].P, FNameP, FNameLen)) ) then
        raise EXmlParseError.Create(xecMalformedXml, 'Mismatched end tag', GetPosition, GetLine, GetColumn);
      FToken := xtEndElement;
      FTokP := FNameP; FTokLine := FLine; FTokColumn := FColumn;
      if FDepth > 0 then Dec(FDepth);
      StackPop;
      NSPopToMark;
      // DOM 构建：遇到 EndElement 弹出当前父节点
      if FNodeIdxLen>0 then Dec(FNodeIdxLen);
      Exit(True);
    end
    else
    begin
      // 开始标签 <name ...>
      if not ParseName(FNameP, FNameLen) then
      begin
        // 在字符串模式下，缺失名称属于格式错误，应抛出异常而非静默结束
        raise EXmlParseError.Create(xecMalformedXml, 'Unterminated start tag', GetPosition, GetLine, GetColumn);
      end;
      // 注意：NodeIdx 栈的入栈在 FreezeCurrentNode 里进行
      // 流式：持久化开始标签名称到栈顶 Owned，保证返回后 LocalName 可用
      if FSourceKind = skStream then
      begin
        // Push 之前先把 name 拷贝到临时 Owned，在 StackPush 后立刻覆盖栈顶的 Owned
      end;
      FTokP := FNameP; FTokLine := FLine; FTokColumn := FColumn;

      // 新作用域标记
      NSPushMark;
      // 预热前缀→URI 快速表
      NSMapClear;
      NSMapEnsureCap(16);

      // 解析属性（同时处理 xmlns 绑定，xmlns 不计入属性表）
      if not ParseAttributes then begin FToken := xtEndDocument; Exit(True); end;

      if (FCur < FEnd) and (FCur^ = '/') and ((FCur+1)^ = '>') then
      begin
        Inc(FCur, 2);
        FEmpty := True;
        FToken := xtStartElement;
        Inc(FDepth);
        StackPush(FNameP, FNameLen);
        FPendingAutoEnd := True;
        // 校验前缀绑定（元素），在解析完 xmlns 后进行
        if GetPrefix <> '' then
        begin
          if NSResolve(GetPrefix) = '' then
            raise EXmlParseError.Create(xecMalformedXml, 'Unbound prefix', GetPosition, GetLine, GetColumn);
        end;
        // 校验属性前缀绑定（默认命名空间不作用于属性）
        if FAttrCount>0 then
        begin
          for idx := 0 to FAttrCount-1 do
          begin
            // 扫描属性名中的前缀
            PfxLen := 0;
            for jj := 0 to FAttrs[idx].NameLen-1 do
              if (FAttrs[idx].NameP+jj)^=':' then begin PfxLen := jj; Break; end;
            if PfxLen>0 then
            begin
              SetString(Pfx, FAttrs[idx].NameP, PfxLen);
              if NSResolve(Pfx) = '' then
                raise EXmlParseError.Create(xecMalformedXml, 'Unbound prefix', GetPosition, GetLine, GetColumn);
            end;
          end;
        end;
        Exit(True);
      end
      else if (FCur < FEnd) and (FCur^ = '>') then
      begin
        Inc(FCur);
        FEmpty := False;
        FToken := xtStartElement;
        Inc(FDepth);
        StackPush(FNameP, FNameLen);
        // 校验前缀绑定（元素），在解析完 xmlns 后进行
        if GetPrefix <> '' then
        begin
          if NSResolve(GetPrefix) = '' then
            raise EXmlParseError.Create(xecMalformedXml, 'Unbound prefix', GetPosition, GetLine, GetColumn);
        end;
        // 校验属性前缀绑定（默认命名空间不作用于属性）
        if FAttrCount>0 then
        begin
          for idx := 0 to FAttrCount-1 do
          begin
            PfxLen := 0;
            for jj := 0 to FAttrs[idx].NameLen-1 do
              if (FAttrs[idx].NameP+jj)^=':' then begin PfxLen := jj; Break; end;
            if PfxLen>0 then
            begin
              SetString(Pfx, FAttrs[idx].NameP, PfxLen);
              if NSResolve(Pfx) = '' then
                raise EXmlParseError.Create(xecMalformedXml, 'Unbound prefix', GetPosition, GetLine, GetColumn);
            end;
          end;
        end;
        Exit(True);

      end
      else
      begin
        raise EXmlParseError.Create(xecMalformedXml, 'Unterminated start tag', GetPosition, GetLine, GetColumn);
      end;
    end;
  end
  else
  begin
    // 文本节点
    S := FCur;
    while (FCur < FEnd) and (FCur^ <> '<') do Inc(FCur);
    // 若需要合并文本：继续采集相邻的 CDATA
    if (xrfCoalesceText in FFlags) then
    begin
      // 初始文本段
      FValueOwned := '';
      if FCur > S then SetString(FValueOwned, S, FCur - S);
      // 粘连：后续若紧跟 CDATA 则拼接
      while (FCur < FEnd-8) and (FCur^='<') and ((FCur+1)^='!') and ((FCur+2)^='[') and ((FCur+3)^='C') and ((FCur+4)^='D') and ((FCur+5)^='A') and ((FCur+6)^='T') and ((FCur+7)^='A') and ((FCur+8)^='[') do
      begin
        SkipN(9);
        S := FCur;
        while (FCur < FEnd-2) and not ((FCur^=']') and ((FCur+1)^=']') and ((FCur+2)^='>')) do Step;
        if (FCur < FEnd-2) and (FCur > S) then
        begin
          FValueOwned += AnsiString(Copy(S,1,FCur-S));
          SkipN(3);
          // 继续吸收后续文本
          S := FCur;
          while (FCur < FEnd) and (FCur^ <> '<') do Inc(FCur);
          if (FCur > S) then FValueOwned += AnsiString(Copy(S,1,FCur-S));
        end
        else Break;
      end;
      if Length(FValueOwned)>0 then begin FValueP := PChar(FValueOwned); FValueLen := Length(FValueOwned); end else begin FValueP := nil; FValueLen := 0; end;
      FTokP := FValueP; FTokLine := FLine; FTokColumn := FColumn;
      FToken := xtText;
      Exit(True);
    end
    else
    begin
      FValueP := S; FValueLen := FCur - S;
      FTokP := FValueP; FTokLine := FLine; FTokColumn := FColumn;
      FToken := xtText;
      Exit(True);
    end;
  end;
end;

function TXmlReaderImpl.GetToken: TXmlToken; begin Result := FToken; end;
function TXmlReaderImpl.GetDepth: SizeUInt; begin Result := FDepth; end;
function TXmlReaderImpl.GetName: String; begin if (FNameP=nil) or (FNameLen=0) then Exit(''); SetString(Result, FNameP, FNameLen); end;
function TXmlReaderImpl.GetLocalName: String;
var i: SizeUInt; P: PChar;
begin
  if (FNameP=nil) or (FNameLen=0) then Exit('');
  P := FNameP;
  for i := 0 to FNameLen-1 do
    if (P+i)^ = ':' then begin SetString(Result, P+i+1, FNameLen - i - 1); Exit; end;
  Result := GetName;
end;

function TXmlReaderImpl.GetPrefix: String;
var i: SizeUInt; P: PChar;
begin
  Result := '';
  if (FNameP=nil) or (FNameLen=0) then Exit;
  P := FNameP;
  for i := 0 to FNameLen-1 do
    if (P+i)^ = ':' then begin SetString(Result, P, i); Exit; end;
end;

function TXmlReaderImpl.GetNamespaceURI: String;
var Pref: String;
begin
  Pref := GetPrefix;
  if Pref = '' then
    Exit(NSResolve(''))
  else
    Exit(NSResolve(Pref));
end;

function TXmlReaderImpl.GetValue: String; begin if (FValueP=nil) or (FValueLen=0) then Exit(''); Result := DecodeEntities(FValueP, FValueLen); end;
function TXmlReaderImpl.IsEmptyElement: Boolean; begin Result := FEmpty; end;
function TXmlReaderImpl.GetAttributeCount: SizeUInt; begin Result := FAttrCount; end;
function TXmlReaderImpl.GetAttributeName(AIndex: SizeUInt): String; begin if AIndex>=FAttrCount then Exit(''); if (FAttrs[AIndex].NameP=nil) or (FAttrs[AIndex].NameLen=0) then Exit(''); SetString(Result, FAttrs[AIndex].NameP, FAttrs[AIndex].NameLen); end;
function TXmlReaderImpl.GetAttributeLocalName(AIndex: SizeUInt): String;
var i: SizeUInt; P: PChar; L: SizeUInt;
begin
  if AIndex>=FAttrCount then Exit('');
  P := FAttrs[AIndex].NameP; L := FAttrs[AIndex].NameLen;
  for i := 0 to L-1 do
    if (P+i)^ = ':' then begin SetString(Result, P+i+1, L - i - 1); Exit; end;
  SetString(Result, P, L);
end;

function TXmlReaderImpl.GetAttributePrefix(AIndex: SizeUInt): String;
var i: SizeUInt; P: PChar; L: SizeUInt;
begin
  Result := '';
  if AIndex>=FAttrCount then Exit;
  P := FAttrs[AIndex].NameP; L := FAttrs[AIndex].NameLen;
  for i := 0 to L-1 do
    if (P+i)^ = ':' then begin SetString(Result, P, i); Exit; end;
end;

function TXmlReaderImpl.GetAttributeNamespaceURI(AIndex: SizeUInt): String;
var Pref: String;
begin
  Pref := GetAttributePrefix(AIndex);
  if Pref = '' then
    Exit('') // 默认命名空间不作用于属性
  else
    Exit(NSResolve(Pref));
end;
function TXmlReaderImpl.GetAttributeValue(AIndex: SizeUInt): String; begin if AIndex>=FAttrCount then Exit(''); if (FAttrs[AIndex].ValueP=nil) or (FAttrs[AIndex].ValueLen=0) then Exit(''); Result := DecodeEntities(FAttrs[AIndex].ValueP, FAttrs[AIndex].ValueLen); end;
function TXmlReaderImpl.TryGetAttribute(const AName: String; out AValue: String): Boolean;
var i: SizeUInt; L: SizeUInt; P: PChar;
    nm: String;
begin
  L := Length(AName);
  P := PChar(AName);

  for i := 0 to FAttrCount-1 do
    if (FAttrs[i].NameP<>nil) and (FAttrs[i].NameLen = L) and CompareMem(FAttrs[i].NameP, P, L) then
    begin
      AValue := DecodeEntities(FAttrs[i].ValueP, FAttrs[i].ValueLen);
      Exit(True);
    end;
  AValue := '';
  Result := False;
end;
function TXmlReaderImpl.GetNameN(out P: PChar; out Len: SizeUInt): Boolean; begin P := FNameP; Len := FNameLen; Result := (P<>nil) and (Len>0); end;
function TXmlReaderImpl.GetLocalNameN(out P: PChar; out Len: SizeUInt): Boolean; begin Result := GetNameN(P, Len); end;
function TXmlReaderImpl.GetPrefixN(out P: PChar; out Len: SizeUInt): Boolean;
var i: SizeUInt; Q: PChar;
begin
  if (FNameP=nil) or (FNameLen=0) then begin P:=nil; Len:=0; Exit(False); end;
  Q := FNameP;
  for i := 0 to FNameLen-1 do
    if (Q+i)^ = ':' then begin P := Q; Len := i; Exit(True); end;
  P := nil; Len := 0; Result := False;
end;
function TXmlReaderImpl.GetNamespaceURIN(out P: PChar; out Len: SizeUInt): Boolean;
var preP: PChar; preL: SizeUInt; pref, uri: String;
begin
  // 通过前缀解析 URI；空前缀返回默认命名空间；将结果保存在 FNSUriOwned 以便返回持久指针
  if GetPrefixN(preP, preL) then begin SetString(pref, preP, preL); uri := NSResolve(pref); end
  else uri := NSResolve('');
  FNSUriOwned := AnsiString(uri);
  if FNSUriOwned<>'' then begin P := PChar(FNSUriOwned); Len := Length(FNSUriOwned); Result := True; end
  else begin P:=nil; Len:=0; Result := False; end;
end;
function TXmlReaderImpl.GetValueN(out P: PChar; out Len: SizeUInt): Boolean; begin P := FValueP; Len := FValueLen; Result := (P<>nil) and (Len>0); end;
function TXmlReaderImpl.GetAttributeNameN(AIndex: SizeUInt; out P: PChar; out Len: SizeUInt): Boolean;
begin
  if AIndex>=FAttrCount then begin P:=nil; Len:=0; Exit(False); end;
  P:=FAttrs[AIndex].NameP; Len:=FAttrs[AIndex].NameLen; Result:=Len>0;
end;
function TXmlReaderImpl.GetAttributeLocalNameN(AIndex: SizeUInt; out P: PChar; out Len: SizeUInt): Boolean; begin Result := GetAttributeNameN(AIndex, P, Len); end;
function TXmlReaderImpl.GetAttributePrefixN(AIndex: SizeUInt; out P: PChar; out Len: SizeUInt): Boolean;
var i: SizeUInt; Q: PChar; L: SizeUInt;
begin
  if AIndex>=FAttrCount then begin P:=nil; Len:=0; Exit(False); end;
  Q := FAttrs[AIndex].NameP; L := FAttrs[AIndex].NameLen;
  for i := 0 to L-1 do if (Q+i)^ = ':' then begin P := Q; Len := i; Exit(True); end;
  P := nil; Len := 0; Result := False;
end;

function TXmlReaderImpl.GetAttributeNamespaceURIN(AIndex: SizeUInt; out P: PChar; out Len: SizeUInt): Boolean;
var preP: PChar; preL: SizeUInt; pref, uri: String;
begin
  if AIndex>=FAttrCount then begin P:=nil; Len:=0; Exit(False); end;
  if GetAttributePrefixN(AIndex, preP, preL) then begin SetString(pref, preP, preL); uri := NSResolve(pref); end else uri := '';
  FNSUriOwned := AnsiString(uri);
  if FNSUriOwned<>'' then begin P := PChar(FNSUriOwned); Len := Length(FNSUriOwned); Result := True; end
  else begin P:=nil; Len:=0; Result := False; end;
end;
function TXmlReaderImpl.GetAttributeValueN(AIndex: SizeUInt; out P: PChar; out Len: SizeUInt): Boolean;
begin
  if AIndex>=FAttrCount then begin P:=nil; Len:=0; Exit(False); end;
  P := FAttrs[AIndex].ValueP;
  Len := FAttrs[AIndex].ValueLen;
  Result := Len>0;
end;

{ ===== 真流式解析：环形缓冲预备实现（暂未接入 Read 主循环） ===== }

procedure TXmlReaderImpl.InitStreamSource(AStream: TStream; InitialCap: SizeUInt);
begin
  FSourceKind := skStream;
  FSourceStream := AStream;
  FOwnsStream := False;
  GetMem(FRingBuf, InitialCap);
  FRingCap := InitialCap;
  FRingStart := 0;
  FRingLen := 0;
  FEOF := False;
  SetLength(FScratch, 0);
  FBaseOffset := 0;
end;

function TXmlReaderImpl.RingWritableSize: SizeUInt;
begin
  Result := FRingCap - (FRingStart + FRingLen);
end;

function TXmlReaderImpl.RingReadableSize: SizeUInt;
begin
  Result := FRingLen;
end;

procedure TXmlReaderImpl.CompactWindow;
var NewStart: SizeUInt;
begin
  // 在 token 边界调用：把窗口前段去掉，使数据前移到 0
  if FRingStart > 0 then
  begin
    if FRingLen > 0 then
      Move((FRingBuf + FRingStart)^, FRingBuf^, FRingLen);
    FRingStart := 0;
  end;
end;

procedure TXmlReaderImpl.AdvanceWindowToCur;
begin
  if FSourceKind <> skStream then Exit;
  // 计算从窗口起点到当前的已消费长度
  if (FCur <> nil) then
  begin
    // 将 [FRingStart, FCur) 丢弃，并将剩余有效数据前移到0起点

    FBaseOffset += SizeUInt(FCur - PChar(FRingBuf + FRingStart));
    FRingLen := FRingLen - SizeUInt(FCur - PChar(FRingBuf + FRingStart));
    Move(FCur^, FRingBuf^, FRingLen);
    FRingStart := 0;
    FBuf := PChar(FRingBuf);
    FCur := FBuf;
    FEnd := FBuf + FRingLen;
  end;
end;

function TXmlReaderImpl.RefillAtLeast(AMin: SizeUInt): Boolean;
var ToRead: SizeInt; ReadBytes: SizeInt; OldLen: SizeUInt;
begin
  // 如果已有足够数据
  if RingReadableSize >= AMin then Exit(True);
  if FEOF then Exit(RingReadableSize >= AMin);

  // 压实并扩容（如有需要）
  CompactWindow;
  if RingWritableSize < AMin then
  begin
    // 扩容至满足 AMin + FRingLen
    while (FRingCap - FRingLen) < AMin do FRingCap := FRingCap * 2;
    ReallocMem(FRingBuf, FRingCap);
  end;

  // 拉流补给
  ToRead := FRingCap - (FRingStart + FRingLen);
  OldLen := FRingLen;
  ReadBytes := 0;
  if ToRead > 0 then
    ReadBytes := FSourceStream.Read((FRingBuf + FRingStart + FRingLen)^, ToRead);
  if ReadBytes > 0 then
  begin
    Inc(FRingLen, ReadBytes);


    Result := FRingLen >= AMin;
  end
  else
  begin
    FEOF := True;
    Result := FRingLen >= AMin;
  end;
end;

function TXmlReaderImpl.TranscodeRefill(AMin: SizeUInt): Boolean;
begin
  // ✅ Stub implementation: transcoding functionality has been removed
  // UTF-16/UTF-32 BOMs now raise errors during detection phase
  raise EXmlParseError.Create(xecInvalidEncoding,
    'Internal error: TranscodeRefill called but transcoding is not implemented',
    GetPosition, GetLine, GetColumn);
end;

procedure TXmlReaderImpl.ReleaseStreamSource;
begin
  if FRingBuf <> nil then FreeMem(FRingBuf);
  FRingBuf := nil; FRingCap := 0; FRingStart := 0; FRingLen := 0;
  if FOwnsStream and (FSourceStream <> nil) then FSourceStream.Free;
  FSourceKind := skNone; FSourceStream := nil; FEOF := True; FOwnsStream := False;
  SetLength(FScratch, 0);
end;

function TXmlReaderImpl.EnsureLookahead(N: SizeUInt): Boolean;
var off: SizeUInt; ok: Boolean;
begin
  if FSourceKind <> skStream then Exit((FEnd - FCur) >= PtrInt(N));
  if (FEnd - FCur) >= PtrInt(N) then Exit(True);
  off := SizeUInt(FCur - PChar(FRingBuf + FRingStart));
  if FTransMode = tmNone then ok := RefillAtLeast(off + N)
  else ok := TranscodeRefill(off + N);
  if not ok then
  begin
    FBuf := PChar(FRingBuf + FRingStart);
    FEnd := FBuf + FRingLen;
    if off <= FRingLen then FCur := FBuf + off else FCur := FEnd;
    Exit(False);
  end;
  FBuf := PChar(FRingBuf + FRingStart);
  FEnd := FBuf + FRingLen;
  FCur := FBuf + off;
  Result := (FEnd - FCur) >= PtrInt(N);
end;


function TXmlReaderImpl.ReadStreamImpl: Boolean;
var
  S: PChar;
  SegBuf: AnsiString;
  i, MaxPrint: SizeUInt;
  DbgNm: String;
  // Encoding decode helpers (no inline var per project rule)
  isLE32: Boolean;
  Mem32: TMemoryStream;
  OutS32: AnsiString;
  PBytes: PByte;
  sz32: SizeUInt;
  i32: SizeUInt;
  cp32: LongWord;
  isLE16: Boolean;
  Mem16: TMemoryStream;
  OutS16: AnsiString;
  P16: PByte;
  sz16: SizeUInt;
  i16: SizeUInt;
  cu, cu2: Word;
  cp16: LongWord;
  BufRead: array[0..8191] of Byte;
  RRead: SizeInt;
  // XML decl parse locals (no inline vars)
  DeclStart: PChar;
  DeclLen: SizeUInt;
  Seg: AnsiString;
  encPos, eqPos, endq: SizeInt;
  rest, encName: String;
  q: Char;

begin
  // 在返回 token 之前，先设置 token 坐标快照
  // 处理 <x/> 自动补发 EndElement
  if FPendingAutoEnd then
  begin
    FPendingAutoEnd := False;
    FToken := xtEndElement;
    if FStackLen > 0 then
    begin
      FNameP := FStack[FStackLen-1].P;
      FNameLen := FStack[FStackLen-1].L;
      FTokP := FNameP; FTokLine := FLine; FTokColumn := FColumn;
      StackPop;
    end;
    NSPopToMark;
    if FDepth > 0 then Dec(FDepth);
    Exit(True);
  end;

  if FToken = xtStartDocument then
  begin
    // Phase 1 编码处理：BOM 检测与 UTF-8 BOM 去除；非 UTF-8 直接报错
    if EnsureLookahead(4) then
    begin
      // UTF-32 BE: 00 00 FE FF 或 UTF-32 LE: FF FE 00 00
      if ((FCur^ = #$00) and ((FCur+1)^ = #$00) and ((FCur+2)^ = #$FE) and ((FCur+3)^ = #$FF))
         or ((FCur^ = #$FF) and ((FCur+1)^ = #$FE) and ((FCur+2)^ = #$00) and ((FCur+3)^ = #$00)) then
      begin
        if (xrfAutoDecodeEncoding in FFlags) then
        begin
          // UTF-32 自动转 UTF-8（LE/BE）：切换到增量转码模式
          FDetectedEnc := deUTF32;
          isLE32 := (FCur^ = #$FF) and ((FCur+1)^ = #$FE) and ((FCur+2)^ = #$00) and ((FCur+3)^ = #$00);
          // 跳过 BOM
          SkipN(4);
          // 设置转码模式，并清空环形缓冲窗口以用于 UTF-8 输出
          if isLE32 then FTransMode := tmUTF32LE else FTransMode := tmUTF32BE;
          FRingStart := 0; FRingLen := 0; FBuf := PChar(FRingBuf); FCur := FBuf; FEnd := FBuf;
          // 尝试补给一些数据，保证后续解析可继续
          EnsureLookahead(1);
          // 继续按流式路径解析
        end
        else
          raise EXmlParseError.Create(xecInvalidEncoding, 'Unsupported encoding: UTF-32 BOM detected (only UTF-8 supported currently)', GetPosition, GetLine, GetColumn)
      end
      // UTF-8 BOM: EF BB BF
      else if (FCur^ = #$EF) and ((FCur+1)^ = #$BB) and ((FCur+2)^ = #$BF) then
      begin
        FDetectedEnc := deUTF8;
        SkipN(3);
      end
      // UTF-16 BE: FE FF 或 UTF-16 LE: FF FE
      else if ((FCur^ = #$FE) and ((FCur+1)^ = #$FF)) or ((FCur^ = #$FF) and ((FCur+1)^ = #$FE)) then
      begin
        if (xrfAutoDecodeEncoding in FFlags) then
        begin
          // UTF-16(LE/BE) 自动转 UTF-8：切换到增量转码模式
          FDetectedEnc := deUTF16;
          isLE16 := (FCur^ = #$FF) and ((FCur+1)^ = #$FE);
          SkipN(2); // 跳过 BOM
          if isLE16 then FTransMode := tmUTF16LE else FTransMode := tmUTF16BE;
          FRingStart := 0; FRingLen := 0; FBuf := PChar(FRingBuf); FCur := FBuf; FEnd := FBuf;
          EnsureLookahead(1);
        end
        else
        begin
          // 默认 AssumeUTF8：遇到 UTF-16 BOM 直接报不支持（除非 AutoDecode 开启）
          raise EXmlParseError.Create(xecInvalidEncoding, 'Unsupported encoding: UTF-16 BOM detected (enable xrfAutoDecodeEncoding to decode)', GetPosition, GetLine, GetColumn);
        end;
      end;
    end;

    EnsureLookahead(5);
    while True do
    begin
      if (FCur < FEnd) and (FCur^ <= ' ') then Step else Break;
      if (FCur >= FEnd) and not EnsureLookahead(1) then Break;
    end;
    if EnsureLookahead(5) and (FCur^ = '<') and ((FCur+1)^='?') and ((FCur+2)^='x') and ((FCur+3)^='m') and ((FCur+4)^='l') then
    begin
      // 捕获 XML 声明片段内容（在 'xml' 之后，直到 '?>' 之前）到 FScratch 以便解析 encoding
      SkipN(5);
      FScratch := '';
      DeclStart := FCur;
      while True do
      begin
        if EnsureLookahead(2) and (FCur < FEnd-1) and (FCur^='?') and ((FCur+1)^='>') then
        begin
          DeclLen := FCur - DeclStart;
          if DeclLen > 0 then
          begin
            SetString(Seg, DeclStart, DeclLen);
            FScratch := Seg;
          end;
          SkipN(2);
          Break;
        end;
        if (FCur < FEnd-1) then Step
        else if not EnsureLookahead(2) then Break;
      end;
      // 解析 encoding 属性（仅 ASCII 安全扫描）
      if (FScratch <> '') then
      begin
        encPos := Pos('encoding', LowerCase(FScratch));
        if encPos > 0 then
        begin
          // 简单查找 encoding="..." 或 encoding='...'
          rest := Copy(FScratch, encPos+8, MaxInt);
          eqPos := Pos('=', rest);
          if eqPos > 0 then
          begin
            rest := Trim(Copy(rest, eqPos+1, MaxInt));
            if (Length(rest) >= 1) and ((rest[1] = '"') or (rest[1] = '''')) then
            begin
              q := rest[1];
              endq := Pos(q, Copy(rest, 2, MaxInt));
              if endq > 0 then
              begin
                encName := Copy(rest, 2, endq-1);
                if CompareText(encName, 'utf-8') <> 0 then
                begin
                  // 若存在 BOM，且与声明冲突：以 BOM 为准（标准建议 BOM 优先）
                  if (FDetectedEnc <> deUnknown) then
                  begin
                    // 当前我们只支持 UTF-8/16/32 的自动解码；其他声明一律拒绝
                    raise EXmlParseError.Create(xecInvalidEncoding,
                      'Declared encoding conflicts with BOM or unsupported: '+encName,
                      GetPosition, GetLine, GetColumn);
                  end
                  else
                  begin
                    // 无 BOM 且声明非 UTF-8：不支持（本阶段仅支持 UTF-8/AutoDecode via BOM）
                    raise EXmlParseError.Create(xecInvalidEncoding,
                      'Unsupported declared encoding (only UTF-8 or BOM-based autodetect supported currently): '+encName,
                      GetPosition, GetLine, GetColumn);
                  end;
                end;
              end;
            end;
          end;
        end;
      end;
    end;
  end;

  if EnsureLookahead(1) and (FCur < FEnd) and (FCur^ <= ' ') then
  begin
    S := FCur;
    while True do
    begin
      if (FCur < FEnd) and (FCur^ <= ' ') then Step else Break;
      if (FCur >= FEnd) and not EnsureLookahead(1) then Break;
    end;
    if FCur > S then
    begin
      if (xrfIgnoreWhitespace in FFlags) then
      else
      begin
        FToken := xtWhitespace;
        FValueP := S; FValueLen := FCur - S;
        FTokP := FValueP; FTokLine := FLine; FTokColumn := FColumn;
        Exit(True);
      end;
    end;
  end;

  if not EnsureLookahead(1) or (FCur >= FEnd) then
  begin
    if FToken <> xtEndDocument then begin FToken := xtEndDocument; Exit(True); end else Exit(False);
  end;

  if FCur^ = '<' then
  begin
    Step;
    if EnsureLookahead(3) and (FCur^='!') and ((FCur+1)^='-') and ((FCur+2)^='-') then
    begin
      SkipN(3);
      S := FCur;
      while True do
      begin
        if EnsureLookahead(3) and (FCur^='-') and ((FCur+1)^='-') and ((FCur+2)^='>') then Break;
        if (FCur < FEnd) then Step else if not EnsureLookahead(1) then Break;
      end;
      if EnsureLookahead(3) then
      begin
        FToken := xtComment;
        FValueP := S; FValueLen := FCur - S;
        FTokP := FValueP; FTokLine := FLine; FTokColumn := FColumn;
        SkipN(3);
        if (xrfIgnoreComments in FFlags) then ; // 吃掉注释继续
        // 注释作为 token 返回：与字符串路径一致
        Exit(True);
      end
      else
        raise EXmlParseError.Create(xecMalformedXml, 'Unterminated comment', GetPosition, GetLine, GetColumn);
    end
    else if EnsureLookahead(8) and (FCur^='!') and ((FCur+1)^='[') and ((FCur+2)^='C') and ((FCur+3)^='D') and ((FCur+4)^='A') and ((FCur+5)^='T') and (((FCur+6)^='A')) and ((FCur+7)^='[') then
    begin
      SkipN(8);
      S := FCur;
      FScratch := '';
      while True do
      begin
        // 查找结尾 ]]>
        if EnsureLookahead(3) and (FCur^=']') and ((FCur+1)^=']') and ((FCur+2)^='>') then Break;
        if (FCur < FEnd) then
        begin
          Inc(FCur);
        end
        else
        begin
          // 追加片段并补给
          if FCur > S then
          begin
            if FScratch = '' then SetString(FScratch, S, FCur - S)
            else ScratchAppend(S, FCur - S);
          end;
          S := FCur;
          if not EnsureLookahead(1) then Break;
        end;
      end;
      if not EnsureLookahead(3) then
        raise EXmlParseError.Create(xecMalformedXml, 'Unterminated CDATA', GetPosition, GetLine, GetColumn);
      // 终止符前的最后一段加入
      if FCur > S then begin SetString(SegBuf, S, FCur - S); if FScratch='' then FScratch:=SegBuf else ScratchAppend(PChar(SegBuf), Length(SegBuf)); end;
      // 消耗结尾 ]]>
      SkipN(3);
      if (xrfCoalesceText in FFlags) then
      begin
        // 粘连后续文本与 CDATA
        while True do
        begin
          // 先吸收紧随的文本片段
          if EnsureLookahead(1) and (FCur < FEnd) and (FCur^ <> '<') then
          begin
            S := FCur;
            while True do
            begin
              if (FCur < FEnd) and (FCur^ <> '<') then Inc(FCur) else Break;
              if (FCur >= FEnd) and EnsureLookahead(1) then Continue else if (FCur >= FEnd) then Break;
            end;
            if FCur > S then begin SetString(SegBuf, S, FCur - S); if FScratch='' then FScratch:=SegBuf else ScratchAppend(PChar(SegBuf), Length(SegBuf)); end;
            Continue;
          end;
          // 再吸收紧随的另一个 CDATA
          if EnsureLookahead(9) and (FCur^='<') and ((FCur+1)^='!') and ((FCur+2)^='[') and ((FCur+3)^='C') and ((FCur+4)^='D') and ((FCur+5)^='A') and ((FCur+6)^='T') and ((FCur+7)^='A') and ((FCur+8)^='[') then
          begin
            SkipN(9);
            S := FCur;
            while True do
            begin
              if EnsureLookahead(3) and (FCur^=']') and ((FCur+1)^=']') and ((FCur+2)^='>') then Break;
              if (FCur < FEnd) then Inc(FCur) else if not EnsureLookahead(1) then Break;
            end;
            if not EnsureLookahead(3) then raise EXmlParseError.Create(xecMalformedXml, 'Unterminated CDATA', GetPosition, GetLine, GetColumn);
            if FCur > S then begin SetString(SegBuf, S, FCur - S); if FScratch='' then FScratch:=SegBuf else ScratchAppend(PChar(SegBuf), Length(SegBuf)); end;
            SkipN(3);
            Continue;
          end;
          Break;
        end;
        // 产出合并后的文本 token
        FValueOwned := FScratch;
        FValueP := PChar(FValueOwned); FValueLen := Length(FValueOwned);
        FTokP := FValueP; FTokLine := FLine; FTokColumn := FColumn;
        FToken := xtText;
        Exit(True);
      end;
    end;
  end;

  Result := False;
end;

function TXmlNodeIntf.GetAttributeLocalName(AIndex: SizeUInt): String;
var
  p: SizeInt;
begin
  if (FDoc=nil) or (FIndex>=SizeUInt(Length(FDoc.FNodes))) then Exit('');
  if AIndex<SizeUInt(Length(FDoc.FNodes[FIndex].AttrNames)) then
  begin
    Result := FDoc.FNodes[FIndex].AttrNames[AIndex];
    p := Pos(':', Result);
    if p>0 then Result := Copy(Result, p+1, MaxInt);
  end
  else Result := '';
end;

function TXmlNodeIntf.GetAttributePrefix(AIndex: SizeUInt): String;
var
  p: SizeInt;
begin
  Result := '';
  if (FDoc=nil) or (FIndex>=SizeUInt(Length(FDoc.FNodes))) then Exit('');
  if AIndex<SizeUInt(Length(FDoc.FNodes[FIndex].AttrNames)) then
  begin
    Result := FDoc.FNodes[FIndex].AttrNames[AIndex];
    p := Pos(':', Result);
    if p>0 then Result := Copy(Result, 1, p-1) else Result := '';
  end;
end;

function TXmlNodeIntf.GetAttributeNamespaceURI(AIndex: SizeUInt): String;
var pref: String;
begin
  pref := GetAttributePrefix(AIndex);
  if pref='' then Exit('');
  // 解析属性命名空间：默认 ns 不作用于属性
  if pref='xml' then Exit('http://www.w3.org/XML/1998/namespace');
  Result := '';
  if (FDoc=nil) or (FIndex>=SizeUInt(Length(FDoc.FNodes))) then Exit('');
  if AIndex<SizeUInt(Length(FDoc.FNodes[FIndex].AttrNS)) then
    Result := FDoc.FNodes[FIndex].AttrNS[AIndex];
end;

function TXmlReaderImpl.TryGetAttributeN(const AName: PChar; ANameLen: SizeUInt; out P: PChar; out Len: SizeUInt): Boolean;
var i: SizeUInt;
begin
  for i := 0 to FAttrCount-1 do
    if (FAttrs[i].NameLen = ANameLen) and CompareMem(FAttrs[i].NameP, AName, ANameLen) then
    begin
      P := FAttrs[i].ValueP; Len := FAttrs[i].ValueLen; Exit(True);
    end;
  P := nil; Len := 0; Result := False;
end;
// 渐进式行列定位：从上次扫描处增量推进到 AP
procedure TXmlReaderImpl.ComputeLineColumnAt(AP: PChar; out L, C: SizeUInt);
var P: PChar; LN, CN: SizeUInt;
begin
  if (FSourceKind = skString) and (FLCScanP <> nil) and (FLCScanP <= AP) then
  begin
    P := FLCScanP; LN := FLCLine; CN := FLCColumn;
  end
  else
  begin
    P := FBuf; LN := 1; CN := 1;
  end;
  while P < AP do
  begin
    if P^ = #10 then begin Inc(LN); CN := 1; end else Inc(CN);
    Inc(P);
  end;
  L := LN; C := CN;
  if FSourceKind = skString then begin FLCScanP := AP; FLCLine := LN; FLCColumn := CN; end;
end;

procedure TXmlReaderImpl.ComputeLineColumn(out L, C: SizeUInt);
var P: PChar; LN, CN: SizeUInt;
begin
  P := FBuf; LN := 1; CN := 1;
  while P < FCur do
  begin
    if P^ = #10 then begin Inc(LN); CN := 1; end else Inc(CN);
    Inc(P);
  end;
  L := LN; C := CN;
end;



{ TXmlDocumentImpl }
constructor TXmlDocumentImpl.Create;
begin
  inherited Create;
  SetLength(FNodes, 0);
  FRoot := High(SizeUInt);
end;

function TXmlDocumentImpl.GetRoot: IXmlNode;
begin
  if (FRoot <> High(SizeUInt)) and (FRoot < SizeUInt(Length(FNodes))) then
    Result := TXmlNodeIntf.Create(Self, FRoot)
  else
    Result := nil;
end;

function TXmlDocumentImpl.GetAllocator: TAllocator;
begin
  Result := nil;
end;

function TXmlDocumentImpl.AddNode(const N: TXmlNodeRec): SizeUInt;
begin
  Result := Length(FNodes);
  SetLength(FNodes, Result+1);
  FNodes[Result] := N;
  if (FRoot = High(SizeUInt)) and (N.Parent = High(SizeUInt)) then
    FRoot := Result;
end;

{ TXmlNodeIntf }
constructor TXmlNodeIntf.Create(ADoc: TXmlDocumentImpl; AIndex: SizeUInt);
begin
  inherited Create;
  FDoc := ADoc;
  FDocRef := ADoc; // 保存接口引用避免文档过早释放
  FIndex := AIndex;
end;

function TXmlNodeIntf.GetName: String;
begin
  if (FDoc=nil) or (FIndex>=SizeUInt(Length(FDoc.FNodes))) then Exit('');
  Result := FDoc.FNodes[FIndex].Name;
end;
function TXmlNodeIntf.GetLocalName: String;
var i: SizeInt;
begin
  if (FDoc=nil) or (FIndex>=SizeUInt(Length(FDoc.FNodes))) then Exit('');
  Result := FDoc.FNodes[FIndex].Name;
  i := Pos(':', Result);
  if i>0 then Result := Copy(Result, i+1, MaxInt);
end;
function TXmlNodeIntf.GetPrefix: String;
var i: SizeInt; s: String;
begin
  if (FDoc=nil) or (FIndex>=SizeUInt(Length(FDoc.FNodes))) then Exit('');
  s := FDoc.FNodes[FIndex].Name;
  i := Pos(':', s);
  if i>0 then Result := Copy(s,1,i-1) else Result := '';
end;
function TXmlNodeIntf.GetNamespaceURI: String;
begin
  if (FDoc=nil) or (FIndex>=SizeUInt(Length(FDoc.FNodes))) then Exit('');
  Result := FDoc.FNodes[FIndex].ElemNS;
end;
function TXmlNodeIntf.GetValue: String;
begin
  if (FDoc=nil) or (FIndex>=SizeUInt(Length(FDoc.FNodes))) then Exit('');
  Result := FDoc.FNodes[FIndex].Value;
end;
function TXmlNodeIntf.GetChildCount: SizeUInt;
var cnt: SizeUInt; idx: SizeUInt; len: SizeUInt;
{$IFDEF DEBUG}
    parentCnt: SizeUInt; j: SizeUInt;
{$ENDIF}
begin
  Result := 0;
  if (FDoc=nil) then Exit;
  len := SizeUInt(Length(FDoc.FNodes));
  if (FIndex>=len) then Exit;
  cnt := 0; idx := FDoc.FNodes[FIndex].FirstChild;
  while (idx<>High(SizeUInt)) and (idx<len) do begin Inc(cnt); idx := FDoc.FNodes[idx].NextSibling; end;
  {$IFDEF DEBUG}
  // 计算 parent 扫描计数，对比链表计数
  parentCnt := 0;
  for j := 0 to len-1 do
    if FDoc.FNodes[j].Parent = FIndex then Inc(parentCnt);
  if parentCnt<>cnt then
  begin
    if FDoc.FNodes[FIndex].FirstChild<>High(SizeUInt) then
      idx := FDoc.FNodes[FDoc.FNodes[FIndex].FirstChild].NextSibling
    else
      idx := High(SizeUInt);
    raise Exception.CreateFmt('ChildCount mismatch: chain=%d parentScan=%d first=%d last=%d next(first)=%d len=%d',
      [cnt, parentCnt, FDoc.FNodes[FIndex].FirstChild, FDoc.FNodes[FIndex].LastChild,
       idx, len]);
  end;
  {$ENDIF}
  Result := cnt;
end;
function TXmlNodeIntf.GetChild(AIndex: SizeUInt): IXmlNode;
var idx: SizeUInt; i: SizeUInt; len: SizeUInt;
begin
  Result := nil;
  if (FDoc=nil) then Exit;
  len := SizeUInt(Length(FDoc.FNodes));
  if (FIndex>=len) then Exit;
  idx := FDoc.FNodes[FIndex].FirstChild; i := 0;
  while (idx<>High(SizeUInt)) and (idx<len) do begin
    if i=AIndex then Exit(TXmlNodeIntf.Create(FDoc, idx));
    Inc(i); idx := FDoc.FNodes[idx].NextSibling;
  end;
end;
function TXmlNodeIntf.GetAttributeCount: SizeUInt;
begin
  if (FDoc=nil) or (FIndex>=SizeUInt(Length(FDoc.FNodes))) then Exit(0);
  Result := Length(FDoc.FNodes[FIndex].AttrNames);
end;
function TXmlNodeIntf.GetAttributeName(AIndex: SizeUInt): String;
begin
  if (FDoc=nil) or (FIndex>=SizeUInt(Length(FDoc.FNodes))) then Exit('');
  if AIndex<SizeUInt(Length(FDoc.FNodes[FIndex].AttrNames)) then Result := FDoc.FNodes[FIndex].AttrNames[AIndex] else Result := '';
end;
function TXmlNodeIntf.GetAttributeValue(AIndex: SizeUInt): String;
begin
  if (FDoc=nil) or (FIndex>=SizeUInt(Length(FDoc.FNodes))) then Exit('');
  if AIndex<SizeUInt(Length(FDoc.FNodes[FIndex].AttrValues)) then Result := FDoc.FNodes[FIndex].AttrValues[AIndex] else Result := '';
end;
function TXmlNodeIntf.GetAttributeByName(const AName: String; out AValue: String): Boolean;
var i: SizeInt;
begin
  if (FDoc=nil) or (FIndex>=SizeUInt(Length(FDoc.FNodes))) then begin AValue := ''; Exit(False); end;
  for i := 0 to High(FDoc.FNodes[FIndex].AttrNames) do
    if SameText(FDoc.FNodes[FIndex].AttrNames[i], AName) then begin AValue := FDoc.FNodes[FIndex].AttrValues[i]; Exit(True); end;
  AValue := ''; Result := False;
end;






function TXmlNodeIntf.GetParent: IXmlNode;
var p: SizeUInt;
begin
  if (FDoc=nil) or (FIndex>=SizeUInt(Length(FDoc.FNodes))) then Exit(nil);
  p := FDoc.FNodes[FIndex].Parent;
  if (p<>High(SizeUInt)) and (p<SizeUInt(Length(FDoc.FNodes))) then
    Result := TXmlNodeIntf.Create(FDoc, p)
  else
    Result := nil;
end;

function TXmlNodeIntf.GetFirstChild: IXmlNode;
var c: SizeUInt;
begin
  if (FDoc=nil) or (FIndex>=SizeUInt(Length(FDoc.FNodes))) then Exit(nil);
  c := FDoc.FNodes[FIndex].FirstChild;
  if (c<>High(SizeUInt)) and (c<SizeUInt(Length(FDoc.FNodes))) then
    Result := TXmlNodeIntf.Create(FDoc, c)
  else
    Result := nil;
end;

function TXmlNodeIntf.GetLastChild: IXmlNode;
var c: SizeUInt;
begin
  if (FDoc=nil) or (FIndex>=SizeUInt(Length(FDoc.FNodes))) then Exit(nil);
  c := FDoc.FNodes[FIndex].LastChild;
  if (c<>High(SizeUInt)) and (c<SizeUInt(Length(FDoc.FNodes))) then
    Result := TXmlNodeIntf.Create(FDoc, c)
  else
    Result := nil;
end;

function TXmlNodeIntf.GetNextSibling: IXmlNode;
var s: SizeUInt;
begin
  if (FDoc=nil) or (FIndex>=SizeUInt(Length(FDoc.FNodes))) then Exit(nil);
  s := FDoc.FNodes[FIndex].NextSibling;
  if (s<>High(SizeUInt)) and (s<SizeUInt(Length(FDoc.FNodes))) then
    Result := TXmlNodeIntf.Create(FDoc, s)
  else
    Result := nil;
end;

function TXmlNodeIntf.GetPreviousSibling: IXmlNode;
var idx: SizeUInt; parent: SizeUInt;
begin
  Result := nil;
  if (FDoc=nil) or (FIndex>=SizeUInt(Length(FDoc.FNodes))) then Exit;
  parent := FDoc.FNodes[FIndex].Parent;
  if (parent=High(SizeUInt)) or (parent>=SizeUInt(Length(FDoc.FNodes))) then Exit;
  idx := FDoc.FNodes[parent].FirstChild;
  if idx=FIndex then Exit;
  while (idx<>High(SizeUInt)) and (idx<SizeUInt(Length(FDoc.FNodes))) do
  begin
    if FDoc.FNodes[idx].NextSibling=FIndex then
      Exit(TXmlNodeIntf.Create(FDoc, idx));
    idx := FDoc.FNodes[idx].NextSibling;
  end;
end;

function TXmlNodeIntf.GetHasChildNodes: Boolean;
var c: SizeUInt;
begin
  if (FDoc=nil) or (FIndex>=SizeUInt(Length(FDoc.FNodes))) then Exit(False);
  c := FDoc.FNodes[FIndex].FirstChild;
  Result := (c<>High(SizeUInt)) and (c<SizeUInt(Length(FDoc.FNodes)));
end;

function TXmlReaderImpl.FreezeCurrentNode: IXmlNode;
var N: TXmlNodeRec; i: SizeUInt; nm, val, pref, uri: String;
    parentIdx, newIdx, last: SizeUInt;
{$IFDEF DEBUG}
    oldFirst, oldLast: SizeUInt; oldCnt, curDbg, cur, cnt: SizeUInt; found: Boolean;
{$ENDIF}
begin

  Result := nil;
  if FToken<>xtStartElement then Exit;
  // 懒创建文档容器（跨多次 Freeze 复用）
  if FBuildDoc=nil then FBuildDoc := TXmlDocumentImpl.Create;
  // 构造节点
  FillChar(N, SizeOf(N), 0);
  N.Kind := xtStartElement;
  N.Parent := High(SizeUInt);
  N.FirstChild := High(SizeUInt);
  N.LastChild := High(SizeUInt);
  N.NextSibling := High(SizeUInt);
  N.Name := GetName;
  N.Value := '';
  // 解析并保存元素命名空间 URI
  pref := GetPrefix;
  if pref='' then uri := NSResolve('') else uri := NSResolve(pref);
  N.ElemNS := uri;
  SetLength(N.AttrNames, FAttrCount);
  SetLength(N.AttrValues, FAttrCount);
  SetLength(N.AttrNS, FAttrCount);
  if FAttrCount>0 then
    for i := 0 to FAttrCount-1 do
    begin
      nm := GetAttributeName(i);
      val := GetAttributeValue(i);
      pref := GetAttributePrefix(i);
      if pref='' then uri := '' else uri := NSResolve(pref);
      N.AttrNames[i] := nm;
      N.AttrValues[i] := val;
      N.AttrNS[i] := uri;
    end;
  // 父链与兄弟链
  if FNodeIdxLen>0 then parentIdx := FNodeIdxStack[FNodeIdxLen-1] else parentIdx := High(SizeUInt);
  {$IFDEF DEBUG}
  // 根节点(FDepth=1)没有父节点是正常的；更深层级缺父时记录日志即可（不抛异常以继续验证）
  if (parentIdx=High(SizeUInt)) and (FDepth>1) then
    WriteLn(Format('Debug: Parent missing at Freeze (non-fatal). Depth=%d NodeIdxLen=%d Name=%s',[FDepth, FNodeIdxLen, PChar(GetName)]));
  {$ENDIF}
  // 容错：若深度>0但父索引缺失，回退到文档 Root（理论上不应发生）
  if (parentIdx=High(SizeUInt)) and (FDepth>0) and (FBuildDoc.FRoot<>High(SizeUInt)) then
    parentIdx := FBuildDoc.FRoot;
  {$IFDEF DEBUG}
  __AssertNodeIdxBounds(FBuildDoc, parentIdx);
  // 立即子节点（FDepth=2）应挂在文档根
  if (FDepth=2) and (FBuildDoc.FRoot<>High(SizeUInt)) and (parentIdx<>FBuildDoc.FRoot) then
    raise Exception.CreateFmt('Parent mismatch at depth2: parentIdx=%d root=%d name=%s',[parentIdx, FBuildDoc.FRoot, PChar(GetName)]);
  {$ENDIF}
  N.Parent := parentIdx;
  newIdx := FBuildDoc.AddNode(N);
  {$IFDEF DEBUG} __AssertNodeIdxBounds(FBuildDoc, newIdx); {$ENDIF}
  if (parentIdx<>High(SizeUInt)) and (parentIdx<SizeUInt(Length(FBuildDoc.FNodes))) then
  begin
    {$IFDEF DEBUG}
    // 追加前统计
    oldFirst := FBuildDoc.FNodes[parentIdx].FirstChild;
    oldLast := FBuildDoc.FNodes[parentIdx].LastChild;
    oldCnt := 0; curDbg := oldFirst;
    while (curDbg<>High(SizeUInt)) and (curDbg<SizeUInt(Length(FBuildDoc.FNodes))) do begin Inc(oldCnt); curDbg := FBuildDoc.FNodes[curDbg].NextSibling; end;
    {$ENDIF}
    // 追加到父的 children 链表末尾
    if FBuildDoc.FNodes[parentIdx].FirstChild=High(SizeUInt) then
      FBuildDoc.FNodes[parentIdx].FirstChild := newIdx
    else
    begin
      last := FBuildDoc.FNodes[parentIdx].FirstChild;
      while (last<>High(SizeUInt)) and (last<SizeUInt(Length(FBuildDoc.FNodes))) and (FBuildDoc.FNodes[last].NextSibling<>High(SizeUInt)) do
      begin
        {$IFDEF DEBUG}
        if FBuildDoc.FNodes[last].NextSibling=last then
          raise Exception.CreateFmt('Sibling self-loop at %d',[last]);
        {$ENDIF}
        last := FBuildDoc.FNodes[last].NextSibling;
      end;
      if (last<>High(SizeUInt)) and (last<SizeUInt(Length(FBuildDoc.FNodes))) then
        FBuildDoc.FNodes[last].NextSibling := newIdx;
      FBuildDoc.FNodes[parentIdx].LastChild := newIdx;
    end;
    FBuildDoc.FNodes[parentIdx].LastChild := newIdx;
    {$IFDEF DEBUG}
    // 验证 newIdx 可从 FirstChild 链表可达，并统计子数
    cnt := 0; found := False; cur := FBuildDoc.FNodes[parentIdx].FirstChild;
    while (cur<>High(SizeUInt)) and (cur<SizeUInt(Length(FBuildDoc.FNodes))) do
    begin
      Inc(cnt);
      if cur=newIdx then found := True;
      cur := FBuildDoc.FNodes[cur].NextSibling;
    end;
    if not found then raise Exception.CreateFmt('Child not linked: parent=%d new=%d cnt=%d',[parentIdx,newIdx,cnt]);
    // 检查 LastChild 指向 newIdx
    if FBuildDoc.FNodes[parentIdx].LastChild<>newIdx then
      raise Exception.CreateFmt('LastChild not updated: parent=%d last=%d expected=%d',[parentIdx, FBuildDoc.FNodes[parentIdx].LastChild, newIdx]);
    // 若之前已有孩子，检查旧尾巴的 next 指向 newIdx
    if (oldFirst<>High(SizeUInt)) and (oldLast<>High(SizeUInt)) then
      if FBuildDoc.FNodes[oldLast].NextSibling<>newIdx then
        raise Exception.CreateFmt('Old last not linked to new: parent=%d oldLast=%d next=%d expected=%d',[parentIdx, oldLast, FBuildDoc.FNodes[oldLast].NextSibling, newIdx]);
    // 验证子数+1
    if cnt<>(oldCnt+1) then
      raise Exception.CreateFmt('Child count mismatch after append: parent=%d oldCnt=%d newCnt=%d',[parentIdx,oldCnt,cnt]);
    {$ENDIF}
  end;
  // 将本节点作为新的当前父节点（等待 EndElement 时弹栈）
  if not FEmpty then
  begin
    if FNodeIdxLen >= SizeUInt(Length(FNodeIdxStack)) then
      SetLength(FNodeIdxStack, Length(FNodeIdxStack)*2 + 8);
    FNodeIdxStack[FNodeIdxLen] := newIdx; Inc(FNodeIdxLen);
    {$IFDEF DEBUG} __AssertNodeIdxBounds(FBuildDoc, FNodeIdxStack[FNodeIdxLen-1]); {$ENDIF}
  end;
  Result := TXmlNodeIntf.Create(FBuildDoc, newIdx);
end;

function TXmlReaderImpl.GetLine: SizeUInt;
begin
  if FSourceKind = skStream then Exit(FTokLine);
  if FTokP = nil then FTokP := FCur;
  ComputeLineColumnAt(FTokP, Result, FColumn);
end;

function TXmlReaderImpl.GetColumn: SizeUInt;
begin
  if FSourceKind = skStream then Exit(FTokColumn);
  if FTokP = nil then FTokP := FCur;
  ComputeLineColumnAt(FTokP, FLine, Result);
end;

function TXmlReaderImpl.GetPosition: SizeUInt;
begin
  if FSourceKind = skStream then
    Result := FBaseOffset + SizeUInt(FCur - PChar(FRingBuf + FRingStart))
  else
    Result := FCur - FBuf;
end;

function TXmlReaderImpl.ReadAllToDocument: IXmlDocument;
begin
  Result := XmlReadAllToDocument(Self);
end;


destructor TXmlReaderImpl.Destroy;
begin
  // 释放可能的流式资源与缓冲
  ReleaseStreamSource;
  inherited Destroy;
  end;



function TXmlWriterStub.BuildAttrString(const G: TAttrGroup): String;
var
  i, j: SizeInt;
  tmp: TPendingAttr;
  Arr, OutArr: array of TPendingAttr;
  C, OutC: SizeInt;
  Found: Boolean;
  EscVals: array of String;
  EstCap: SizeInt;
  SB: TStringBuilder;
begin
  // 拷贝到临时数组进行排序/去重，不影响后续组
  C := G.Count;
  SetLength(Arr, C);
  for i := 0 to C-1 do Arr[i] := G.Attrs[i];

  // 去重：保留最后一次，稳定覆盖
  if FDedupAttrs and (C>1) then
  begin
    SetLength(OutArr, C);
    OutC := 0;
    for i := 0 to C-1 do
    begin
      Found := False;
      // 线性查找已有同名，若有则覆盖其值（保留最后一次）
      for j := 0 to OutC-1 do
        if OutArr[j].Name = Arr[i].Name then
        begin
          OutArr[j].Value := Arr[i].Value;
          Found := True;
          Break;
        end;
      // 未找到则追加
      if not Found then
      begin
        OutArr[OutC] := Arr[i];
        Inc(OutC);
      end;
    end;
    // 用去重后的数组替换 Arr
    SetLength(Arr, OutC);
    for i := 0 to OutC-1 do Arr[i] := OutArr[i];
    C := OutC;
  end;

  // 排序（小 N 插入排序）
  if FSortAttrs and (C>1) then
  begin
    for i := 1 to C-1 do
    begin
      tmp := Arr[i];
      j := i - 1;
      while (j >= 0) and (Arr[j].Name > tmp.Name) do
      begin
        Arr[j+1] := Arr[j];
        Dec(j);
      end;
      Arr[j+1] := tmp;
    end;
  end;

  // 预先转义属性值并估算容量，减少拼接开销
  if C = 0 then Exit('');
  SetLength(EscVals, C);
  EstCap := 0;
  for i := 0 to C-1 do
  begin
    EscVals[i] := EscapeAttr(Arr[i].Value);
    // 估算：空格(1) + 名称 + ="(2) + 值 + "(1)
    EstCap += 4 + Length(Arr[i].Name) + Length(EscVals[i]);
  end;

  SB := TStringBuilder.Create;
  try
    SB.EnsureCapacity(EstCap);
    for i := 0 to C-1 do
    begin
      SB.Append(' ');
      SB.Append(Arr[i].Name);
      SB.Append('="');
      SB.Append(EscVals[i]);
      SB.Append('"');
    end;
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

procedure TXmlWriterStub.AppendAttrPlaceholder(ASelfClose: Boolean);
var G: TAttrGroup; i, base: SizeInt;
begin
  // 将当前待写属性捕获为一组，并在 Buffer 中放置一个占位符 #{k};
  // 最终输出时再统一替换。
  base := Length(FAttrGroups);
  SetLength(FAttrGroups, base+1);
  G.Count := FPendingAttrCount;
  SetLength(G.Attrs, FPendingAttrCount);
  for i := 0 to FPendingAttrCount-1 do G.Attrs[i] := FPendingAttrs[i];
  FAttrGroups[base] := G;
  Inc(FAttrGroupCount);
  // 在流中放置占位符，标记是否自闭合
  if ASelfClose then
    FBuffer.Append('#{ATTR').Append(base).Append('/}')
  else
    FBuffer.Append('#{ATTR').Append(base).Append('}');
  // 清空当前队列
  FPendingAttrCount := 0;
end;



destructor TXmlWriterStub.Destroy;
begin
  FBuffer.Free;
  inherited Destroy;
end;

procedure TXmlWriterStub.EnsureOpenTagClosed;
begin
  if FOpenTagPending then
  begin
    // 输出占位符，结束 '>' 稍后在 EndElement/内容写入时决定
    AppendAttrPlaceholder(False);
    FBuffer.Append('>');
    FOpenTagPending := False;
    FLastEmittedNL := False; // 刚刚输出了 '>'，允许下一个 WriteIndent 生效
  end;
end;

procedure TXmlWriterStub.WriteIndent;
begin
  // 仅在已开始输出内容后插入占位符，避免文档最前面出现 leading NL
  if FBuffer.Length = 0 then Exit;
  // 避免连续重复 NL 占位符
  if not EndsWithNLPlaceholder then
    FBuffer.Append('#{NL').Append(IntToStr(FDepth)).Append('}');
end;

function TXmlWriterStub.EndsWithNLPlaceholder: Boolean;
var L: SizeInt; S: String;
begin
  L := FBuffer.Length;
  if L<5 then Exit(False);
  // 末尾形如 ...#{NLd}
  S := FBuffer.ToString;
  Result := (S[L-4] = '#') and (S[L-3] = '{') and (S[L-2] = 'N') and (S[L-1] = 'L');
end;
function TXmlWriterStub.EscapeText(const S: String): String;
var i: SizeInt; ch: Char; cLt,cGt,cAmp, L, EstCap: SizeInt; SB: TStringBuilder;
begin
  L := Length(S); if L=0 then Exit('');
  cLt:=0; cGt:=0; cAmp:=0;
  for i := 1 to L do
  begin
    ch := S[i];
    if ch='<' then Inc(cLt)
    else if ch='>' then Inc(cGt)
    else if ch='&' then Inc(cAmp);
  end;
  if (cLt=0) and (cGt=0) and (cAmp=0) then Exit(S);
  EstCap := L + cLt*3 + cGt*3 + cAmp*4;
  SB := TStringBuilder.Create;
  try
    SB.EnsureCapacity(EstCap);
    for i := 1 to L do
    begin
      ch := S[i];
      case ch of
        '<': SB.Append('&lt;');
        '>': SB.Append('&gt;');
        '&': SB.Append('&amp;');
      else
        SB.Append(ch);
      end;
    end;
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

function TXmlWriterStub.EscapeAttr(const S: String): String;
var i: SizeInt; ch: Char; cLt,cGt,cAmp,cQu,cAp, L, EstCap: SizeInt; SB: TStringBuilder;
begin
  L := Length(S); if L=0 then Exit('');
  cLt:=0; cGt:=0; cAmp:=0; cQu:=0; cAp:=0;
  for i := 1 to L do
  begin
    ch := S[i];
    case ch of
      '<': Inc(cLt);
      '>': Inc(cGt);
      '&': Inc(cAmp);
      '"': Inc(cQu);
      '''': Inc(cAp);
    end;
  end;
  if (cLt=0) and (cGt=0) and (cAmp=0) and (cQu=0) and (cAp=0) then Exit(S);
  EstCap := L + cLt*3 + cGt*3 + cAmp*4 + cQu*5 + cAp*5;
  SB := TStringBuilder.Create;
  try
    SB.EnsureCapacity(EstCap);
    for i := 1 to L do
    begin
      ch := S[i];
      case ch of
        '<': SB.Append('&lt;');
        '>': SB.Append('&gt;');
        '&': SB.Append('&amp;');
        '"': SB.Append('&quot;');
        '''': SB.Append('&apos;');
      else
        SB.Append(ch);
      end;
    end;
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

procedure TXmlWriterStub.Reset;
begin
  FBuffer.Clear;
  SetLength(FStack, 0);
  FDepth := 0;
  FOpenTagPending := False;
  FPendingDecl.Pending := False;
  FPretty := False;
  FPendingAttrCount := 0; SetLength(FPendingAttrs, 0);
end;

procedure TXmlWriterStub.StartDocument;
begin
  StartDocument('1.0', 'UTF-8');
end;

procedure TXmlWriterStub.StartDocument(const AVersion, AEncoding: String);
begin
  FPendingDecl.Pending := True;
  FPendingDecl.Version := AVersion;
  FPendingDecl.Encoding := AEncoding;
end;

procedure TXmlWriterStub.EndDocument;
begin
  // 仅收尾未闭合开始标签；是否输出 XML 声明交由 WriteToString 决定
  EnsureOpenTagClosed;
end;

procedure TXmlWriterStub.StartElement(const AName: String);
begin
  // 不在此处输出 XML 声明，推迟到 WriteToString 决策（以支持 xwfOmitXmlDecl）
  EnsureOpenTagClosed;
  // 每个元素入栈一层命名空间作用域标记
  WNSPushMark;
  // 如果当前缓冲末尾已经是 NL 占位符（上一行刚结束），不要重复写缩进占位，避免空行
  if not EndsWithNLPlaceholder then
    WriteIndent;
  FLastWasText := False;
  FLastEmittedNL := False;
  FBuffer.Append('<').Append(AName);
  FOpenTagPending := True;
  Inc(FDepth);
  SetLength(FStack, Length(FStack)+1);
  FStack[High(FStack)] := AName;
  // 开始一个新的属性组（当前 FPendingAttrs 中的将属于这个 open tag）
  FPendingAttrCount := 0;
end;

procedure TXmlWriterStub.StartElementNS(const APrefix, ALocalName, ANamespaceURI: String);
var Q: String; NeedDecl: Boolean; Existing: String;
begin
  // 为元素命名空间查找/声明前缀
  if ANamespaceURI<>'' then
  begin
    if (APrefix='xml') and (ANamespaceURI<>XML_NS_URI) then
      raise Exception.Create('Cannot rebind reserved prefix xml');
    if (APrefix='xmlns') then
      raise Exception.Create('Cannot bind reserved prefix xmlns');
  FLastWasText := False;
    if (ANamespaceURI=XMLNS_URI) and (APrefix<>'xmlns') then
      raise Exception.Create('Cannot bind prefix to xmlns URI');

    Existing := WNSFindPrefix(ANamespaceURI);
    if (APrefix<>'') and (Existing<>'') and (Existing<>APrefix) then
      Existing := '';
    NeedDecl := (Existing='') or ((APrefix<>'') and (WNSResolve(APrefix)<>ANamespaceURI));
  end
  else
    NeedDecl := False;

  // 写开始标签名
  if (APrefix<>'') then Q := APrefix + ':' + ALocalName else Q := ALocalName;
  StartElement(Q);

  // 必要时声明 xmlns（默认 ns 用空前缀）
  if ANamespaceURI<>'' then
  begin
    if (APrefix='') then
    begin
      if not WNSHasURI(ANamespaceURI) then WriteAttribute('xmlns', ANamespaceURI);
    end
    else if NeedDecl then
      WriteAttribute('xmlns:'+APrefix, ANamespaceURI);
    // 更新 writer 作用域绑定
    WNSPushBinding(APrefix, ANamespaceURI);
  end;
end;

procedure TXmlWriterStub.EndElement;
var Name: String;
begin
  if (FDepth <= 0) and (Length(FStack)=0) then Exit;
  if FDepth > 0 then Dec(FDepth);
  Name := FStack[High(FStack)];
  SetLength(FStack, Length(FStack)-1);
  if FOpenTagPending then
  begin
    // 输出属性占位符并自闭合
    AppendAttrPlaceholder(True);
    FBuffer.Append('/>');
    FOpenTagPending := False;
    // 退出作用域
    WNSPopToMark;
  end
  else
  begin
    // 退出 writer 元素作用域
    WNSPopToMark;
    // 如果上一个内容是文本，则本行直接闭合
    if FLastWasText then
    begin
      FBuffer.Append('</').Append(Name).Append('>');
      FLastWasText := False;
      Exit;
    end;
    // 如果上一个内容是 PI，按测试约定：换行到深度0再闭合；但仅当当前深度>0，若深度已是根级（0），无需再插入 NL0
    if FLastWasPI then
    begin
      if FDepth>0 then FBuffer.Append('#{NL').Append('0').Append('}');
      FBuffer.Append('</').Append(Name).Append('>');
      FLastWasPI := False;
      Exit;
    end;
    WriteIndent;
    FBuffer.Append('</').Append(Name).Append('>');
  end;
end;

procedure TXmlWriterStub.WriteAttribute(const AName, AValue: String);
begin
  if not FOpenTagPending then Exit;
  // 始终入队，稍后通过占位符统一输出（根据 flags 决定排序/去重）
  EnqueueAttr(AName, AValue);
end;

procedure TXmlWriterStub.EnqueueAttr(const AName, AValue: String);
begin
  if FPendingAttrCount >= Length(FPendingAttrs) then
    SetLength(FPendingAttrs, Length(FPendingAttrs)*2 + 8);
  FPendingAttrs[FPendingAttrCount].Name := AName;
  FPendingAttrs[FPendingAttrCount].Value := AValue;
  Inc(FPendingAttrCount);
end;

procedure TXmlWriterStub.DeclareNamespace(const APrefix, AURI: String);
begin
  if not FOpenTagPending then Exit; // 仅在打开的开始标签中有效
  if APrefix='' then
    WriteAttribute('xmlns', AURI)
  else
    WriteAttribute('xmlns:'+APrefix, AURI);
  WNSPushBinding(APrefix, AURI);
end;

procedure TXmlWriterStub.WriteAttributeNS(const APrefix, ALocalName, ANamespaceURI, AValue: String);
var NeedDecl: Boolean; Existing, QAttr: String;
begin
  if not FOpenTagPending then Exit;
  // 属性命名空间：默认 ns 不作用于属性
  if (ANamespaceURI<>'') and (APrefix<>'') then
  begin
    if (APrefix='xml') and (ANamespaceURI<>XML_NS_URI) then
      raise Exception.Create('Cannot rebind reserved prefix xml');
    if (APrefix='xmlns') then
      raise Exception.Create('Cannot bind reserved prefix xmlns');
    if (ANamespaceURI=XMLNS_URI) and (APrefix<>'xmlns') then
      raise Exception.Create('Cannot bind prefix to xmlns URI');

    Existing := WNSFindPrefix(ANamespaceURI);
    NeedDecl := (Existing='') or (WNSResolve(APrefix)<>ANamespaceURI);
    if NeedDecl then WriteAttribute('xmlns:'+APrefix, ANamespaceURI);
    WNSPushBinding(APrefix, ANamespaceURI);
  end;
  if APrefix<>'' then QAttr := APrefix+':'+ALocalName else QAttr := ALocalName;
  // 始终入队，稍后统一输出
  EnqueueAttr(QAttr, AValue);
end;
function TXmlWriterStub.PrettyFormat(const S: String): String;
var i, posStart, k: SizeInt; outS: String; gidStr: String; gid, gidEnd: SizeInt; selfClose: Boolean; attrStr: String; d: SizeInt;
begin
  // 替换占位符为排序/去重后的属性串
  outS := S;
  i := 1;
  while i <= Length(outS) do
  begin
    if (outS[i] = '#') and (i+5<=Length(outS)) and (Copy(outS, i, 6)='#{ATTR') then
    begin
      posStart := i;
      // 读取组编号
      k := i+6; gidStr := '';
      while (k<=Length(outS)) and (outS[k] in ['0'..'9']) do begin gidStr += outS[k]; Inc(k); end;
      if (k<=Length(outS)) and (outS[k] in ['}','/']) then
      begin
        selfClose := False;
        if outS[k]='/' then begin selfClose := True; Inc(k); end;
        if (k<=Length(outS)) and (outS[k] = '}') then
        begin
          // 解析 gidStr 为整数
          gid := 0;
          for d := 1 to Length(gidStr) do gid := gid*10 + Ord(gidStr[d]) - Ord('0');
          if (gid>=0) and (gid<Length(FAttrGroups)) then
          begin
            attrStr := BuildAttrString(FAttrGroups[gid]);
            gidEnd := k;
            Delete(outS, posStart, gidEnd-posStart+1);
            Insert(attrStr, outS, posStart);
            i := posStart + Length(attrStr);
            Continue;
          end;
        end;
      end;
    end;
    Inc(i);
  end;
  Result := outS;
end;

function TXmlWriterStub.ReplaceNewlinePlaceholders(const S: String; Pretty: Boolean): String;
var i, j, depth: SizeInt; num: String;
begin
  Result := S;
  i := 1;
  while i <= Length(Result) do
  begin
    if (Result[i] = '#') and (i+3<=Length(Result)) and (Copy(Result, i, 4)='#{NL') then
    begin
      j := i+4; num := '';
      while (j<=Length(Result)) and (Result[j] in ['0'..'9']) do begin num += Result[j]; Inc(j); end;
      if (j<=Length(Result)) and (Result[j] = '}') then
      begin
        // 删除占位符
        Delete(Result, i, j - i + 1);
        // 若需要 pretty，则插入换行+缩进
        if Pretty then
        begin
          Val(num, depth);
          Insert(LineEnding + StringOfChar(' ', depth*2), Result, i);
          Inc(i); // 略过刚插入的换行
        end;
        Continue;
      end;
    end;
    Inc(i);
  end;
end;

function TXmlWriterStub.StripAnyPlaceholders(const S: String): String;
var i, j: SizeInt;
begin
  Result := S;
  i := 1;
  while i <= Length(Result) do
  begin
    if (Result[i] = '#') and (i+3<=Length(Result)) and (Copy(Result, i, 4)='#{NL') then
    begin

      j := i+4;
      while (j<=Length(Result)) and (Result[j] in ['0'..'9']) do Inc(j);
      if (j<=Length(Result)) and (Result[j] = '}') then
      begin
        Delete(Result, i, j - i + 1);
        Continue;
      end;
    end;
    Inc(i);
  end;
end;
procedure TXmlWriterStub.WriteString(const AText: String);
begin
  EnsureOpenTagClosed;
  FBuffer.Append(EscapeText(AText));
  FLastWasText := True;
  FLastEmittedNL := False;
end;

procedure TXmlWriterStub.WriteCData(const AText: String);
begin
  EnsureOpenTagClosed;
  FBuffer.Append('<![CDATA[').Append(AText).Append(']]>');
  FLastWasText := False;
end;

procedure TXmlWriterStub.WriteComment(const AText: String);
begin
  EnsureOpenTagClosed;
  WriteIndent;
  FBuffer.Append('<!--').Append(AText).Append('-->');
  FLastEmittedNL := False; // 紧接着允许 EndElement 再次插入 NL
end;

procedure TXmlWriterStub.WritePI(const ATarget, AData: String);
begin
  EnsureOpenTagClosed;
  FBuffer.Append('<?').Append(ATarget);
  if AData <> '' then FBuffer.Append(' ').Append(AData);
  FBuffer.Append('?>');
  FLastWasPI := True;
  FLastEmittedNL := False; // 允许随后 EndElement 写入 NL，使 </b> 顶格
end;

procedure TXmlWriterStub.Flush;
begin
  // Pretty: nothing special here yet
end;

function TXmlWriterStub.WriteToString: String;
begin
  Result := WriteToString([]);
end;

function TXmlWriterStub.WriteToString(AFlags: TXmlWriteFlags): String;
var S: String; OmitDecl: Boolean;
begin
  FPretty := (xwfPretty in AFlags);
  FSortAttrs := (xwfSortAttrs in AFlags);
  FDedupAttrs := (xwfDedupAttrs in AFlags);
  OmitDecl := (xwfOmitXmlDecl in AFlags);
  // 先收尾：关闭未完成的开始标签以及补齐所有未闭合元素
  // 注意：仅当需要排序/去重时才插入属性占位符；否则直接关闭 '>'
  if FOpenTagPending then
  begin
    if FSortAttrs or FDedupAttrs then AppendAttrPlaceholder(False);
    FBuffer.Append('>');
    FOpenTagPending := False;
  end;
  while (FDepth > 0) or (Length(FStack) > 0) do
    EndElement;
  // 若曾调用 StartDocument 且未要求省略声明，则补到最前
  if FPendingDecl.Pending and (not OmitDecl) and not FOpenTagPending then
  begin
    FBuffer.Insert(0, '<?xml version="'+FPendingDecl.Version+'" encoding="'+FPendingDecl.Encoding+'"?>');
    FPendingDecl.Pending := False;
  end
  else if OmitDecl then
  begin
    // 请求省略声明：无论 Pending 与否，都不输出
    FPendingDecl.Pending := False;
  end;
  S := FBuffer.ToString;
  // 替换属性占位符
  if (FAttrGroupCount>0) or FSortAttrs or FDedupAttrs then
    S := PrettyFormat(S);
  // 处理换行/缩进占位符
  S := ReplaceNewlinePlaceholders(S, FPretty);
  if not FPretty then
    S := StripAnyPlaceholders(S);
  Result := S;
end;

procedure TXmlWriterStub.WriteToStream(AStream: TStream);
begin
  WriteToStream(AStream, []);
end;

procedure TXmlWriterStub.WriteToStream(AStream: TStream; AFlags: TXmlWriteFlags);
var
  OmitDecl, Pretty: Boolean;
  R: String;
  i, start, k, depth: SizeInt;
  gid: SizeInt; gidStr: String; selfClose: Boolean;
  piece: String; num: String;
begin
  // 配置 flags
  FPretty := (xwfPretty in AFlags);
  FSortAttrs := (xwfSortAttrs in AFlags);
  FDedupAttrs := (xwfDedupAttrs in AFlags);
  OmitDecl := (xwfOmitXmlDecl in AFlags);
  Pretty := FPretty;

  // 收尾未闭合标签
  if FOpenTagPending then
  begin
    if FSortAttrs or FDedupAttrs then AppendAttrPlaceholder(False);
    FBuffer.Append('>');
    FOpenTagPending := False;
  end;
  while (FDepth > 0) or (Length(FStack) > 0) do
    EndElement;

  // XML 声明（如未省略），直接先输出到流
  if FPendingDecl.Pending and (not OmitDecl) then
  begin
    R := '<?xml version="' + FPendingDecl.Version + '" encoding="' + FPendingDecl.Encoding + '"?>';
    if Length(R) > 0 then AStream.WriteBuffer(Pointer(R)^, Length(R));
    FPendingDecl.Pending := False;
  end
  else if OmitDecl then
  begin
    FPendingDecl.Pending := False;
  end;

  // 获取当前缓冲内容，单次构造；占位符逐段展开并写入流
  R := FBuffer.ToString;
  i := 1; start := 1;
  while i <= Length(R) do
  begin
    if (R[i] = '#') and (i+1 <= Length(R)) and (R[i+1] = '{') then
    begin
      // 写入之前的普通片段
      if i > start then
      begin
        piece := Copy(R, start, i-start);
        if piece <> '' then AStream.WriteBuffer(Pointer(piece)^, Length(piece));
      end;
      // 占位符：属性
      if (i+5<=Length(R)) and (Copy(R, i, 6) = '#{ATTR') then
      begin
        k := i+6; gidStr := ''; selfClose := False;
        while (k<=Length(R)) and (R[k] in ['0'..'9']) do begin gidStr += R[k]; Inc(k); end;
        if (k<=Length(R)) and (R[k] = '/') then begin selfClose := True; Inc(k); end;
        if (k<=Length(R)) and (R[k] = '}') then
        begin
          gid := 0;
          for depth := 1 to Length(gidStr) do gid := gid*10 + Ord(gidStr[depth]) - Ord('0');
          if (gid>=0) and (gid<Length(FAttrGroups)) then
          begin
            piece := BuildAttrString(FAttrGroups[gid]);
            if piece <> '' then AStream.WriteBuffer(Pointer(piece)^, Length(piece));
          end;
          i := k + 1; start := i; Continue;
        end;
      end
      // 占位符：换行缩进
      else if (i+3<=Length(R)) and (Copy(R, i, 4) = '#{NL') then
      begin
        k := i+4; num := '';
        while (k<=Length(R)) and (R[k] in ['0'..'9']) do begin num += R[k]; Inc(k); end;
        if (k<=Length(R)) and (R[k] = '}') then
        begin
          if Pretty then
          begin
            Val(num, depth);
            piece := LineEnding + StringOfChar(' ', depth*2);
            if piece <> '' then AStream.WriteBuffer(Pointer(piece)^, Length(piece));
          end;
          i := k + 1; start := i; Continue;
        end;
      end;
      // 未识别：当成普通字符处理
      Inc(i);
      Continue;
    end;
    Inc(i);
  end;
  // 末尾剩余片段
  if start <= Length(R) then
  begin
    piece := Copy(R, start, Length(R)-start+1);
    if piece <> '' then AStream.WriteBuffer(Pointer(piece)^, Length(piece));
  end;
end;

procedure TXmlWriterStub.WriteToFile(const AFileName: String);
begin
  WriteToFile(AFileName, []);
end;

procedure TXmlWriterStub.WriteToFile(const AFileName: String; AFlags: TXmlWriteFlags);
var FS: TFileStream;
begin
  FS := TFileStream.Create(AFileName, fmCreate);
  try
    WriteToStream(FS, AFlags);
  finally
    FS.Free;
  end;
end;

function CreateXmlReader(AAllocator: IAllocator): IXmlReader;
begin
  Result := TXmlReaderImpl.Create;
end;

function CreateXmlWriter: IXmlWriter;
begin
  Result := TXmlWriterStub.Create;
end;

end.

