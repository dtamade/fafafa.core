{
  fafafa.core.id.nanoid — NanoID: URL 友好的唯一 ID 生成器

  NanoID 是一个小巧、安全、URL 友好的唯一字符串 ID 生成器:
  - 默认 21 个字符 (vs UUID 36 字符)
  - URL 安全字母表: A-Za-z0-9_-
  - 密码学安全随机
  - 可自定义字母表和长度

  对标 Rust: https://docs.rs/nanoid/latest/nanoid/

  使用示例:
    var Id := NanoId;                    // "V1StGXR8_Z5jdHi6B-myT"
    var Id := NanoId(10);                // "IRFa-VaY2b"
    var Id := NanoIdCustom('abc123', 8); // "1a2b3c1a"
}

unit fafafa.core.id.nanoid;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fafafa.core.math;

type
  { NanoID 字母表预设 }
  TNanoIdAlphabet = (
    naUrlSafe,       // A-Za-z0-9_- (默认, 64 字符)
    naAlphanumeric,  // A-Za-z0-9 (62 字符)
    naAlphaLower,    // a-z0-9 (36 字符)
    naAlphaUpper,    // A-Z0-9 (36 字符)
    naHexLower,      // 0-9a-f (16 字符)
    naHexUpper,      // 0-9A-F (16 字符)
    naNoDoppelganger,// 无歧义字符: 去除 l1I0O (57 字符)
    naNumbers        // 0-9 (10 字符)
  );

  { NanoID 生成器接口 }
  INanoIdGenerator = interface
    ['{B2C3D4E5-F6A7-8901-BCDE-F23456789ABC}']
    function Next: string;
    function NextN(Count: Integer): TStringArray;
    function GetAlphabet: string;
    function GetSize: Integer;
    procedure SetSize(ASize: Integer);
    property Alphabet: string read GetAlphabet;
    property Size: Integer read GetSize write SetSize;
  end;

const
  { 默认 NanoID 长度 }
  NANOID_DEFAULT_SIZE = 21;

  { 预定义字母表 }
  NANOID_ALPHABET_URL_SAFE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-';
  NANOID_ALPHABET_ALPHANUMERIC = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  NANOID_ALPHABET_ALPHA_LOWER = 'abcdefghijklmnopqrstuvwxyz0123456789';
  NANOID_ALPHABET_ALPHA_UPPER = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  NANOID_ALPHABET_HEX_LOWER = '0123456789abcdef';
  NANOID_ALPHABET_HEX_UPPER = '0123456789ABCDEF';
  NANOID_ALPHABET_NO_DOPPELGANGER = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789';
  NANOID_ALPHABET_NUMBERS = '0123456789';

{ 基本生成函数 }

{**
 * NanoId - 生成默认 NanoID (21 字符, URL 安全)
 *
 * @return 21 字符的 NanoID 字符串
 *
 * @example
 *   var Id := NanoId;  // "V1StGXR8_Z5jdHi6B-myT"
 *}
function NanoId: string;

{**
 * NanoId - 生成指定长度的 NanoID
 *
 * @param Size ID 长度 (最小 1, 推荐 >= 10)
 * @return NanoID 字符串
 *
 * @note 长度越短, 碰撞概率越高
 *   - 21 字符: 10^9 ID/秒需要约 149 年才可能碰撞
 *   - 10 字符: 碰撞概率显著增加
 *}
function NanoId(Size: Integer): string;

{**
 * NanoIdCustom - 使用自定义字母表生成 NanoID
 *
 * @param Alphabet 自定义字母表 (长度 2-256)
 * @param Size ID 长度
 * @return NanoID 字符串
 *
 * @raises ERangeError 如果字母表长度不在 2-256 范围内
 *
 * @example
 *   var Id := NanoIdCustom('abc123', 8);  // "1a2b3c1a"
 *}
function NanoIdCustom(const Alphabet: string; Size: Integer): string;

{**
 * NanoIdWithAlphabet - 使用预设字母表生成 NanoID
 *
 * @param Alphabet 预设字母表类型
 * @param Size ID 长度 (默认 21)
 * @return NanoID 字符串
 *}
function NanoIdWithAlphabet(Alphabet: TNanoIdAlphabet; Size: Integer = NANOID_DEFAULT_SIZE): string;

{ 批量生成 }

{**
 * NanoIdN - 批量生成 NanoID
 *
 * @param Count 生成数量
 * @param Size 每个 ID 的长度 (默认 21)
 * @return NanoID 字符串数组
 *}
function NanoIdN(Count: Integer; Size: Integer = NANOID_DEFAULT_SIZE): TStringArray;

{ 生成器工厂 }

{**
 * CreateNanoIdGenerator - 创建 NanoID 生成器
 *
 * @param Alphabet 字母表类型 (默认 URL 安全)
 * @param Size ID 长度 (默认 21)
 * @return INanoIdGenerator 接口
 *}
function CreateNanoIdGenerator(Alphabet: TNanoIdAlphabet = naUrlSafe;
  Size: Integer = NANOID_DEFAULT_SIZE): INanoIdGenerator;

{**
 * CreateNanoIdGeneratorCustom - 创建自定义字母表的生成器
 *
 * @param Alphabet 自定义字母表
 * @param Size ID 长度 (默认 21)
 * @return INanoIdGenerator 接口
 *}
function CreateNanoIdGeneratorCustom(const Alphabet: string;
  Size: Integer = NANOID_DEFAULT_SIZE): INanoIdGenerator;

{ 验证 }

{**
 * IsValidNanoId - 验证字符串是否为有效的 NanoID
 *
 * @param S 待验证字符串
 * @param Alphabet 期望的字母表 (默认 URL 安全)
 * @param ExpectedSize 期望的长度 (0 表示任意长度)
 * @return True 如果是有效的 NanoID
 *}
function IsValidNanoId(const S: string;
  Alphabet: TNanoIdAlphabet = naUrlSafe;
  ExpectedSize: Integer = 0): Boolean;

{**
 * GetAlphabetString - 获取预设字母表的字符串
 *
 * @param Alphabet 预设字母表类型
 * @return 字母表字符串
 *}
function GetAlphabetString(Alphabet: TNanoIdAlphabet): string;

implementation

uses
  fafafa.core.crypto.random,
  fafafa.core.id.rng;  // ✅ 缓冲 RNG 优化

type
  { NanoID 生成器实现 }
  TNanoIdGenerator = class(TInterfacedObject, INanoIdGenerator)
  private
    FAlphabet: string;
    FSize: Integer;

  public
    constructor Create(const AAlphabet: string; ASize: Integer);

    function Next: string;
    function NextN(Count: Integer): TStringArray;
    function GetAlphabet: string;
    function GetSize: Integer;
    procedure SetSize(ASize: Integer);
  end;

{ Helper functions }

function GetAlphabetString(Alphabet: TNanoIdAlphabet): string;
begin
  case Alphabet of
    naUrlSafe:       Result := NANOID_ALPHABET_URL_SAFE;
    naAlphanumeric:  Result := NANOID_ALPHABET_ALPHANUMERIC;
    naAlphaLower:    Result := NANOID_ALPHABET_ALPHA_LOWER;
    naAlphaUpper:    Result := NANOID_ALPHABET_ALPHA_UPPER;
    naHexLower:      Result := NANOID_ALPHABET_HEX_LOWER;
    naHexUpper:      Result := NANOID_ALPHABET_HEX_UPPER;
    naNoDoppelganger: Result := NANOID_ALPHABET_NO_DOPPELGANGER;
    naNumbers:       Result := NANOID_ALPHABET_NUMBERS;
  end;
  // 注：所有枚举值已覆盖，无需 else 分支
end;

{ Core generation using unbiased algorithm }

function GenerateNanoId(const Alphabet: string; Size: Integer): string;
const
  MAX_STEP = 512;  // ✅ P0: 栈分配最大步长
var
  AlphabetLen: Integer;
  Mask: Integer;
  Step: Integer;
  RandomBytes: array[0..MAX_STEP - 1] of Byte;  // ✅ P0: 栈分配替代堆分配
  I, ByteIdx: Integer;
  ResultIdx: Integer;
begin
  if Size < 1 then
    Size := NANOID_DEFAULT_SIZE;

  AlphabetLen := Length(Alphabet);
  if (AlphabetLen < 2) or (AlphabetLen > 256) then
    raise ERangeError.CreateFmt('NanoID alphabet length must be 2-256, got %d', [AlphabetLen]);

  // 计算掩码: 找到 >= alphabetLen 的最小 2^n - 1
  // 这确保了均匀分布
  Mask := 1;
  while Mask < AlphabetLen do
    Mask := Mask shl 1;
  Dec(Mask);  // 2^n - 1

  // 计算步长: 每次获取多少随机字节
  // step = ceil(1.6 * mask * size / alphabetLen)
  // 1.6 是经验值，确保大多数情况下一次获取足够的字节
  Step := Trunc(1.6 * Mask * Size / AlphabetLen) + 1;
  // ✅ P0: 限制步长不超过栈缓冲区大小
  if Step > MAX_STEP then
    Step := MAX_STEP;

  SetLength(Result, Size);
  ResultIdx := 1;

  while ResultIdx <= Size do
  begin
    // 获取密码学安全的随机字节
    // ✅ 使用缓冲 RNG 优化性能
    IdRngFillBytes(RandomBytes[0], Step);

    for ByteIdx := 0 to Step - 1 do
    begin
      // 应用掩码获取在 [0, mask] 范围内的值
      I := RandomBytes[ByteIdx] and Mask;

      // 只使用在字母表范围内的值 (拒绝采样)
      if I < AlphabetLen then
      begin
        Result[ResultIdx] := Alphabet[I + 1];  // Pascal 1-based
        Inc(ResultIdx);
        if ResultIdx > Size then
          Break;
      end;
    end;
  end;
end;

{ Public functions }

function NanoId: string;
begin
  Result := GenerateNanoId(NANOID_ALPHABET_URL_SAFE, NANOID_DEFAULT_SIZE);
end;

function NanoId(Size: Integer): string;
begin
  Result := GenerateNanoId(NANOID_ALPHABET_URL_SAFE, Size);
end;

function NanoIdCustom(const Alphabet: string; Size: Integer): string;
begin
  Result := GenerateNanoId(Alphabet, Size);
end;

function NanoIdWithAlphabet(Alphabet: TNanoIdAlphabet; Size: Integer): string;
begin
  Result := GenerateNanoId(GetAlphabetString(Alphabet), Size);
end;

function NanoIdN(Count: Integer; Size: Integer): TStringArray;
var
  I: Integer;
begin
  if Count < 0 then
    Count := 0;
  SetLength(Result, Count);
  for I := 0 to Count - 1 do
    Result[I] := NanoId(Size);
end;

{ Generator implementation }

constructor TNanoIdGenerator.Create(const AAlphabet: string; ASize: Integer);
begin
  inherited Create;
  FAlphabet := AAlphabet;
  FSize := ASize;
  if FSize < 1 then
    FSize := NANOID_DEFAULT_SIZE;
end;

function TNanoIdGenerator.Next: string;
begin
  Result := GenerateNanoId(FAlphabet, FSize);
end;

function TNanoIdGenerator.NextN(Count: Integer): TStringArray;
var
  I: Integer;
begin
  if Count < 0 then
    Count := 0;
  SetLength(Result, Count);
  for I := 0 to Count - 1 do
    Result[I] := Next;
end;

function TNanoIdGenerator.GetAlphabet: string;
begin
  Result := FAlphabet;
end;

function TNanoIdGenerator.GetSize: Integer;
begin
  Result := FSize;
end;

procedure TNanoIdGenerator.SetSize(ASize: Integer);
begin
  if ASize < 1 then
    ASize := NANOID_DEFAULT_SIZE;
  FSize := ASize;
end;

{ Factory functions }

function CreateNanoIdGenerator(Alphabet: TNanoIdAlphabet; Size: Integer): INanoIdGenerator;
begin
  Result := TNanoIdGenerator.Create(GetAlphabetString(Alphabet), Size);
end;

function CreateNanoIdGeneratorCustom(const Alphabet: string; Size: Integer): INanoIdGenerator;
begin
  Result := TNanoIdGenerator.Create(Alphabet, Size);
end;

{ Validation }

// ✅ P0: 预计算字母表查表（256 字节，O(1) 查找）
type
  TCharLookupTable = array[0..255] of Boolean;

procedure BuildCharLookupTable(const Alphabet: string; out Table: TCharLookupTable);
var
  I: Integer;
begin
  FillChar(Table, SizeOf(Table), 0);
  for I := 1 to Length(Alphabet) do
    Table[Ord(Alphabet[I])] := True;
end;

// ✅ P0: 预计算的默认字母表查表（URL 安全）
var
  GUrlSafeCharTable: TCharLookupTable;
  GUrlSafeCharTableInitialized: Boolean = False;

procedure EnsureUrlSafeCharTable;
var
  I: Integer;
begin
  if not GUrlSafeCharTableInitialized then
  begin
    FillChar(GUrlSafeCharTable, SizeOf(GUrlSafeCharTable), 0);
    for I := 1 to Length(NANOID_ALPHABET_URL_SAFE) do
      GUrlSafeCharTable[Ord(NANOID_ALPHABET_URL_SAFE[I])] := True;
    GUrlSafeCharTableInitialized := True;
  end;
end;

function IsValidNanoId(const S: string; Alphabet: TNanoIdAlphabet; ExpectedSize: Integer): Boolean;
var
  AlphabetStr: string;
  CharTable: TCharLookupTable;
  I: Integer;
begin
  Result := False;

  if S = '' then
    Exit;

  if (ExpectedSize > 0) and (Length(S) <> ExpectedSize) then
    Exit;

  // ✅ P0: 对默认 URL 安全字母表使用预计算查表
  if Alphabet = naUrlSafe then
  begin
    EnsureUrlSafeCharTable;
    for I := 1 to Length(S) do
    begin
      if not GUrlSafeCharTable[Ord(S[I])] then
        Exit;
    end;
  end
  else
  begin
    // 其他字母表：动态构建查表
    AlphabetStr := GetAlphabetString(Alphabet);
    BuildCharLookupTable(AlphabetStr, CharTable);
    for I := 1 to Length(S) do
    begin
      if not CharTable[Ord(S[I])] then
        Exit;
    end;
  end;

  Result := True;
end;

end.
