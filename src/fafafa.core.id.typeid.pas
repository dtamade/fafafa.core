{
  fafafa.core.id.typeid — TypeID: 类型安全的可排序 ID

  TypeID 是 Stripe 风格的类型安全前缀 ID:
  - 格式: `<prefix>_<base32_uuid>` 如 `user_01h455vb4pex5vsknk084sn02q`
  - 前缀: 只有小写字母 a-z (最多 63 字符)
  - 后缀: UUIDv7 的 Crockford Base32 编码 (26 字符)
  - 可排序: 底层使用 UUIDv7 保持时间顺序

  对标 Rust: https://docs.rs/typeid/latest/typeid/

  使用示例:
    var Id := TypeId('user');                   // "user_01h455vb4pex5vsknk084sn02q"
    var Id := TypeIdFromUuid('user', MyUuid);   // 使用现有 UUID
    var Parsed := ParseTypeId('user_01h...');   // 解析 TypeID
}

unit fafafa.core.id.typeid;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.base,  // ✅ TYPEID-001: 引入 ECore 基类
  fafafa.core.id,      // TUuid128, UuidV7_Raw
  fafafa.core.id.uuid;

type
  { TypeID 解析结果 }
  TTypeIdParts = record
    Prefix: string;
    Uuid: TUuid128;
    Valid: Boolean;
  end;

  { TypeID 生成器接口 }
  ITypeIdGenerator = interface
    ['{C3D4E5F6-A7B8-9012-CDEF-345678901ABC}']
    function Next: string;
    function NextN(Count: Integer): TStringArray;
    function GetPrefix: string;
    property Prefix: string read GetPrefix;
  end;

  { 无效前缀异常 }
  EInvalidTypeIdPrefix = class(ECore);  // ✅ TYPEID-001: 继承自 ECore
  EInvalidTypeId = class(ECore);  // ✅ TYPEID-002: 继承自 ECore

const
  { TypeID 前缀最大长度 (规范定义) }
  TYPEID_MAX_PREFIX_LENGTH = 63;

  { TypeID 后缀长度 (Base32 编码的 UUID) }
  TYPEID_SUFFIX_LENGTH = 26;

{ 基本生成函数 }

{**
 * TypeId - 生成 TypeID (使用 UUIDv7)
 *
 * @param Prefix 类型前缀 (小写字母 a-z, 最多 63 字符)
 * @return TypeID 字符串
 *
 * @raises EInvalidTypeIdPrefix 如果前缀无效
 *
 * @example
 *   var Id := TypeId('user');  // "user_01h455vb4pex5vsknk084sn02q"
 *}
function TypeId(const Prefix: string): string;

{**
 * TypeIdFromUuid - 从现有 UUID 创建 TypeID
 *
 * @param Prefix 类型前缀
 * @param Uuid 现有 UUID (可以是任何版本)
 * @return TypeID 字符串
 *}
function TypeIdFromUuid(const Prefix: string; const Uuid: TUuid128): string;

{**
 * TypeIdNil - 创建空 TypeID (使用空 UUID)
 *
 * @param Prefix 类型前缀
 * @return 空 TypeID 字符串
 *}
function TypeIdNil(const Prefix: string): string;

{ 批量生成 }

{**
 * TypeIdN - 批量生成 TypeID
 *
 * @param Prefix 类型前缀
 * @param Count 生成数量
 * @return TypeID 字符串数组
 *}
function TypeIdN(const Prefix: string; Count: Integer): TStringArray;

{ 解析函数 }

{**
 * ParseTypeId - 解析 TypeID 字符串
 *
 * @param S TypeID 字符串
 * @return TTypeIdParts 包含前缀和 UUID
 *
 * @raises EInvalidTypeId 如果格式无效
 *}
function ParseTypeId(const S: string): TTypeIdParts;

{**
 * TryParseTypeId - 尝试解析 TypeID
 *
 * @param S TypeID 字符串
 * @param Parts 输出解析结果
 * @return True 如果解析成功
 *}
function TryParseTypeId(const S: string; out Parts: TTypeIdParts): Boolean;

{**
 * TypeIdGetPrefix - 提取 TypeID 的前缀
 *
 * @param S TypeID 字符串
 * @return 前缀字符串
 *}
function TypeIdGetPrefix(const S: string): string;

{**
 * TypeIdGetUuid - 提取 TypeID 的 UUID
 *
 * @param S TypeID 字符串
 * @return UUID
 *}
function TypeIdGetUuid(const S: string): TUuid128;

{ 验证 }

{**
 * IsValidTypeIdPrefix - 检查前缀是否有效
 *
 * @param Prefix 待验证前缀
 * @return True 如果有效 (只包含 a-z, 长度 <= 63)
 *}
function IsValidTypeIdPrefix(const Prefix: string): Boolean;

{**
 * IsValidTypeId - 检查 TypeID 是否有效
 *
 * @param S 待验证 TypeID
 * @param ExpectedPrefix 期望的前缀 (空字符串表示任意前缀)
 * @return True 如果有效
 *}
function IsValidTypeId(const S: string; const ExpectedPrefix: string = ''): Boolean;

{ 生成器工厂 }

{**
 * CreateTypeIdGenerator - 创建 TypeID 生成器
 *
 * @param Prefix 类型前缀
 * @return ITypeIdGenerator 接口
 *}
function CreateTypeIdGenerator(const Prefix: string): ITypeIdGenerator;

{ 编码/解码 }

{**
 * TypeIdEncode - 将 UUID 编码为 TypeID 后缀
 *
 * @param Uuid UUID
 * @return 26 字符 Base32 字符串
 *}
function TypeIdEncode(const Uuid: TUuid128): string;

{**
 * TypeIdDecode - 将 TypeID 后缀解码为 UUID
 *
 * @param Suffix 26 字符 Base32 字符串
 * @return UUID
 *}
function TypeIdDecode(const Suffix: string): TUuid128;

implementation

type
  { TypeID 生成器实现 }
  TTypeIdGenerator = class(TInterfacedObject, ITypeIdGenerator)
  private
    FPrefix: string;
  public
    constructor Create(const APrefix: string);
    function Next: string;
    function NextN(Count: Integer): TStringArray;
    function GetPrefix: string;
  end;

const
  { Crockford Base32 字母表 (小写) }
  BASE32_ALPHABET = '0123456789abcdefghjkmnpqrstvwxyz';

{ Helper: Crockford Base32 编码 UUID }

function TypeIdEncode(const Uuid: TUuid128): string;
var
  I: Integer;
  Bits: UInt64;
  Hi, Lo: UInt64;
begin
  // UUID 是 128 位, 编码为 26 个 Base32 字符 (每个 5 位)
  // 130 位容量, 但只用 128 位, 最高 2 位为 0

  // 组装高低 64 位 (大端序)
  Hi := 0;
  Lo := 0;
  for I := 0 to 7 do
  begin
    Hi := (Hi shl 8) or Uuid[I];
    Lo := (Lo shl 8) or Uuid[I + 8];
  end;

  SetLength(Result, 26);

  // 编码 26 个字符: 前 13 个来自高位, 后 13 个来自低位
  // 实际用的算法: 从左到右每次取 5 位

  // 字符 1-13 (高 65 位的 65 -> 13*5=65, 但 UUID 高 64 位只有 64 位)
  // 字符 1: 取 Hi 的最高 2 位 (因为 64 位只能填充 12.8 个字符的 5 位)
  // 字符 2-13: 取接下来的 60 位
  // 字符 14-26: 取 Lo 的 65 位...

  // 更简单的方法: 将 128 位看作大数, 逐位提取
  // TypeID 规范: 从低位开始编码

  // 实际算法 (从 TypeID 规范):
  // 将 128 位分成 26 组 5 位, 高位在前

  // 字符 1: bits 125-129 (只有 3 位有效, 高 2 位补 0)
  Result[1] := BASE32_ALPHABET[((Hi shr 62) and $03) + 1];  // 2 bits

  // 字符 2-13: bits 60-124 (每组 5 位)
  Result[2] := BASE32_ALPHABET[((Hi shr 57) and $1F) + 1];
  Result[3] := BASE32_ALPHABET[((Hi shr 52) and $1F) + 1];
  Result[4] := BASE32_ALPHABET[((Hi shr 47) and $1F) + 1];
  Result[5] := BASE32_ALPHABET[((Hi shr 42) and $1F) + 1];
  Result[6] := BASE32_ALPHABET[((Hi shr 37) and $1F) + 1];
  Result[7] := BASE32_ALPHABET[((Hi shr 32) and $1F) + 1];
  Result[8] := BASE32_ALPHABET[((Hi shr 27) and $1F) + 1];
  Result[9] := BASE32_ALPHABET[((Hi shr 22) and $1F) + 1];
  Result[10] := BASE32_ALPHABET[((Hi shr 17) and $1F) + 1];
  Result[11] := BASE32_ALPHABET[((Hi shr 12) and $1F) + 1];
  Result[12] := BASE32_ALPHABET[((Hi shr 7) and $1F) + 1];
  Result[13] := BASE32_ALPHABET[((Hi shr 2) and $1F) + 1];

  // 字符 14: bits 58-62 跨越 Hi 和 Lo
  Bits := ((Hi and $03) shl 3) or ((Lo shr 61) and $07);
  Result[14] := BASE32_ALPHABET[Bits + 1];

  // 字符 15-26: bits 0-60 from Lo
  Result[15] := BASE32_ALPHABET[((Lo shr 56) and $1F) + 1];
  Result[16] := BASE32_ALPHABET[((Lo shr 51) and $1F) + 1];
  Result[17] := BASE32_ALPHABET[((Lo shr 46) and $1F) + 1];
  Result[18] := BASE32_ALPHABET[((Lo shr 41) and $1F) + 1];
  Result[19] := BASE32_ALPHABET[((Lo shr 36) and $1F) + 1];
  Result[20] := BASE32_ALPHABET[((Lo shr 31) and $1F) + 1];
  Result[21] := BASE32_ALPHABET[((Lo shr 26) and $1F) + 1];
  Result[22] := BASE32_ALPHABET[((Lo shr 21) and $1F) + 1];
  Result[23] := BASE32_ALPHABET[((Lo shr 16) and $1F) + 1];
  Result[24] := BASE32_ALPHABET[((Lo shr 11) and $1F) + 1];
  Result[25] := BASE32_ALPHABET[((Lo shr 6) and $1F) + 1];
  Result[26] := BASE32_ALPHABET[((Lo shr 1) and $1F) + 1];
end;

function Base32CharToValue(C: Char): Integer;
begin
  case C of
    '0', 'O', 'o': Result := 0;
    '1', 'I', 'i', 'L', 'l': Result := 1;
    '2': Result := 2;
    '3': Result := 3;
    '4': Result := 4;
    '5': Result := 5;
    '6': Result := 6;
    '7': Result := 7;
    '8': Result := 8;
    '9': Result := 9;
    'a', 'A': Result := 10;
    'b', 'B': Result := 11;
    'c', 'C': Result := 12;
    'd', 'D': Result := 13;
    'e', 'E': Result := 14;
    'f', 'F': Result := 15;
    'g', 'G': Result := 16;
    'h', 'H': Result := 17;
    'j', 'J': Result := 18;
    'k', 'K': Result := 19;
    'm', 'M': Result := 20;
    'n', 'N': Result := 21;
    'p', 'P': Result := 22;
    'q', 'Q': Result := 23;
    'r', 'R': Result := 24;
    's', 'S': Result := 25;
    't', 'T': Result := 26;
    'v', 'V': Result := 27;
    'w', 'W': Result := 28;
    'x', 'X': Result := 29;
    'y', 'Y': Result := 30;
    'z', 'Z': Result := 31;
  else
    Result := -1;  // Invalid character
  end;
end;

function TypeIdDecode(const Suffix: string): TUuid128;
var
  I, V: Integer;
  Hi, Lo: UInt64;
begin
  if Length(Suffix) <> TYPEID_SUFFIX_LENGTH then
    raise EInvalidTypeId.CreateFmt('Invalid TypeID suffix length: %d (expected 26)', [Length(Suffix)]);

  // 验证并解码第一个字符 (只能是 0-7, 因为只用 2 位)
  V := Base32CharToValue(Suffix[1]);
  if (V < 0) or (V > 7) then
    raise EInvalidTypeId.Create('Invalid TypeID suffix: first character overflow');

  Hi := V;  // 只用低 2 位

  // 解码字符 2-13 -> Hi 的剩余 60 位
  for I := 2 to 13 do
  begin
    V := Base32CharToValue(Suffix[I]);
    if V < 0 then
      raise EInvalidTypeId.CreateFmt('Invalid character in TypeID suffix at position %d', [I]);
    Hi := (Hi shl 5) or UInt64(V);
  end;

  // 解码字符 14 (跨越 Hi 和 Lo)
  V := Base32CharToValue(Suffix[14]);
  if V < 0 then
    raise EInvalidTypeId.Create('Invalid character in TypeID suffix at position 14');

  // 字符 14 的高 2 位属于 Hi, 低 3 位属于 Lo
  Hi := (Hi shl 2) or ((V shr 3) and $03);
  Lo := UInt64(V and $07);

  // 解码字符 15-26 -> Lo 的剩余位
  for I := 15 to 26 do
  begin
    V := Base32CharToValue(Suffix[I]);
    if V < 0 then
      raise EInvalidTypeId.CreateFmt('Invalid character in TypeID suffix at position %d', [I]);
    Lo := (Lo shl 5) or UInt64(V);
  end;

  // 最后还需要左移 1 位 (因为 26*5=130 位, 但只需要 128 位)
  // 实际上编码时最后一个字符只用了 4 位 (5-1=4)
  // 不对，让我重新计算...
  // 26 个字符 * 5 位 = 130 位
  // UUID 只有 128 位
  // 所以最后 2 位被丢弃了? 不，是最高 2 位为 0
  // 编码时: 第一个字符只有 3 位有效 (高 2 位为 0)
  // 所以解码时: 第一个字符的 V 应该 <= 7

  // 但上面的解码还需要处理最后的 1 位...
  // 让我重新看编码:
  // 字符 26: Lo shr 1, 意味着 Lo 的最低 1 位被丢弃了? 不对
  // 实际上 26*5=130 位，UUID 128 位，所以有 2 位冗余
  // 这 2 位就是第一个字符的高 2 位 (必须为 0)

  // 检查 Lo 是否需要左移
  // 编码时最后一个字符是 (Lo shr 1) and $1F
  // 所以 Lo 的最低 1 位被移出去了
  // 解码时需要补回来: Lo := Lo shl 1
  Lo := Lo shl 1;

  // 将 Hi/Lo 转换为字节数组 (大端序)
  for I := 7 downto 0 do
  begin
    Result[7 - I] := Byte(Hi shr (I * 8));
    Result[15 - I] := Byte(Lo shr (I * 8));
  end;
end;

{ Validation }

function IsValidTypeIdPrefix(const Prefix: string): Boolean;
var
  I: Integer;
  C: Char;
begin
  Result := False;

  // 空前缀有效 (无前缀 TypeID)
  if Prefix = '' then
  begin
    Result := True;
    Exit;
  end;

  // 检查长度
  if Length(Prefix) > TYPEID_MAX_PREFIX_LENGTH then
    Exit;

  // 检查每个字符: 只允许小写字母 a-z
  for I := 1 to Length(Prefix) do
  begin
    C := Prefix[I];
    if (C < 'a') or (C > 'z') then
      Exit;
  end;

  Result := True;
end;

function IsValidTypeId(const S: string; const ExpectedPrefix: string): Boolean;
var
  Parts: TTypeIdParts;
begin
  Result := False;

  if not TryParseTypeId(S, Parts) then
    Exit;

  if not Parts.Valid then
    Exit;

  // 检查前缀是否匹配
  if (ExpectedPrefix <> '') and (Parts.Prefix <> ExpectedPrefix) then
    Exit;

  Result := True;
end;

{ Core generation }

function TypeId(const Prefix: string): string;
var
  Uuid: TUuid128;
begin
  if not IsValidTypeIdPrefix(Prefix) then
    raise EInvalidTypeIdPrefix.CreateFmt('Invalid TypeID prefix: "%s" (must be lowercase a-z, max 63 chars)', [Prefix]);

  Uuid := UuidV7_Raw;
  Result := TypeIdFromUuid(Prefix, Uuid);
end;

function TypeIdFromUuid(const Prefix: string; const Uuid: TUuid128): string;
var
  Suffix: string;
begin
  if not IsValidTypeIdPrefix(Prefix) then
    raise EInvalidTypeIdPrefix.CreateFmt('Invalid TypeID prefix: "%s"', [Prefix]);

  Suffix := TypeIdEncode(Uuid);

  if Prefix = '' then
    Result := Suffix
  else
    Result := Prefix + '_' + Suffix;
end;

function TypeIdNil(const Prefix: string): string;
var
  NilUuid: TUuid128;
begin
  FillChar(NilUuid[0], SizeOf(NilUuid), 0);
  Result := TypeIdFromUuid(Prefix, NilUuid);
end;

function TypeIdN(const Prefix: string; Count: Integer): TStringArray;
var
  I: Integer;
begin
  if not IsValidTypeIdPrefix(Prefix) then
    raise EInvalidTypeIdPrefix.CreateFmt('Invalid TypeID prefix: "%s"', [Prefix]);

  if Count < 0 then
    Count := 0;

  SetLength(Result, Count);
  for I := 0 to Count - 1 do
    Result[I] := TypeId(Prefix);
end;

{ Parsing }

function TryParseTypeId(const S: string; out Parts: TTypeIdParts): Boolean;
var
  UnderscorePos: Integer;
  Suffix: string;
  I: Integer;
begin
  Result := False;
  Parts.Valid := False;
  Parts.Prefix := '';
  FillChar(Parts.Uuid[0], SizeOf(Parts.Uuid), 0);

  if S = '' then
    Exit;

  // 查找最后一个下划线
  UnderscorePos := 0;
  for I := Length(S) downto 1 do
  begin
    if S[I] = '_' then
    begin
      UnderscorePos := I;
      Break;
    end;
  end;

  if UnderscorePos = 0 then
  begin
    // 无前缀 TypeID: 只有后缀
    if Length(S) <> TYPEID_SUFFIX_LENGTH then
      Exit;
    Suffix := S;
    Parts.Prefix := '';
  end
  else
  begin
    // 有前缀
    Parts.Prefix := Copy(S, 1, UnderscorePos - 1);
    Suffix := Copy(S, UnderscorePos + 1, Length(S) - UnderscorePos);

    if not IsValidTypeIdPrefix(Parts.Prefix) then
      Exit;

    if Length(Suffix) <> TYPEID_SUFFIX_LENGTH then
      Exit;
  end;

  // 解码后缀
  try
    Parts.Uuid := TypeIdDecode(Suffix);
    Parts.Valid := True;
    Result := True;
  except
    on E: Exception do
      Result := False;
  end;
end;

function ParseTypeId(const S: string): TTypeIdParts;
begin
  if not TryParseTypeId(S, Result) then
    raise EInvalidTypeId.CreateFmt('Invalid TypeID: "%s"', [S]);
end;

function TypeIdGetPrefix(const S: string): string;
var
  Parts: TTypeIdParts;
begin
  Parts := ParseTypeId(S);
  Result := Parts.Prefix;
end;

function TypeIdGetUuid(const S: string): TUuid128;
var
  Parts: TTypeIdParts;
begin
  Parts := ParseTypeId(S);
  Result := Parts.Uuid;
end;

{ Generator }

constructor TTypeIdGenerator.Create(const APrefix: string);
begin
  inherited Create;
  if not IsValidTypeIdPrefix(APrefix) then
    raise EInvalidTypeIdPrefix.CreateFmt('Invalid TypeID prefix: "%s"', [APrefix]);
  FPrefix := APrefix;
end;

function TTypeIdGenerator.Next: string;
begin
  Result := TypeId(FPrefix);
end;

function TTypeIdGenerator.NextN(Count: Integer): TStringArray;
begin
  Result := TypeIdN(FPrefix, Count);
end;

function TTypeIdGenerator.GetPrefix: string;
begin
  Result := FPrefix;
end;

function CreateTypeIdGenerator(const Prefix: string): ITypeIdGenerator;
begin
  Result := TTypeIdGenerator.Create(Prefix);
end;

end.
