{
  fafafa.core.id.xid — XID: 全局唯一、可排序的 ID

  XID 是 MongoDB ObjectId 的现代替代方案:
  - 12 字节 (96 位)
  - 布局: 4 字节时间戳 + 3 字节机器 ID + 2 字节进程 ID + 3 字节计数器
  - Base32 编码 (Crockford 变种): 20 字符
  - 可排序: 时间戳在高位

  对标 Rust: https://docs.rs/xid/latest/xid/
  对标 Go: https://github.com/rs/xid

  使用示例:
    var Id := Xid;                    // "9m4e2mr0ui3e8a215n4g"
    var Id := XidFromTime(ATime);     // 指定时间
    var T := XidTimestamp(Id);        // 提取时间戳
}

unit fafafa.core.id.xid;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, DateUtils, SyncObjs,
  fafafa.core.id.base;  // ✅ P1: 统一类型定义

{ 注意: TXid96, TXid96Array 现在在 fafafa.core.id.base 中定义 }

type
  { XID 生成器接口 }
  // ✅ T1.2: 统一接口方法名 - 添加 NextRaw 规范命名
  IXidGenerator = interface
    ['{D4E5F6A7-B8C9-0123-DEF0-456789012CDE}']
    function NextRaw: TXid96;             // ✅ 推荐: 返回原始类型
    function Next: string;                 // ✅ 推荐: 返回字符串 (最常用)
    function NextN(Count: Integer): TStringArray;
  end;

  { 无效 XID 异常 }
  EInvalidXid = class(Exception);

const
  { XID 字符串长度 (Base32 编码) }
  XID_STRING_LENGTH = 20;

  { XID 字节长度 }
  XID_BYTE_LENGTH = 12;

{ 基本生成函数 }

{**
 * Xid - 生成 XID
 *
 * @return XID 原始字节数组
 *}
function Xid: TXid96;

{**
 * XidString - 生成 XID 字符串
 *
 * @return 20 字符 Base32 编码的 XID
 *}
function XidString: string;

{**
 * XidFromTime - 使用指定时间生成 XID
 *
 * @param ATime 时间戳
 * @return XID 原始字节数组
 *}
function XidFromTime(ATime: TDateTime): TXid96;

{**
 * XidFromUnix - 使用 Unix 时间戳生成 XID
 *
 * @param UnixSec Unix 秒级时间戳
 * @return XID 原始字节数组
 *}
function XidFromUnix(UnixSec: Int64): TXid96;

{ 批量生成 }

{**
 * XidN - 批量生成 XID
 *
 * @param Count 生成数量
 * @return XID 字符串数组
 *}
function XidN(Count: Integer): TStringArray;

{**
 * XidBatchN - 批量生成 XID 原始数组
 *
 * @param Count 生成数量
 * @return XID 原始数组
 *}
function XidBatchN(Count: Integer): TXid96Array;

{ 编码/解码 }

{**
 * XidToString - 将 XID 编码为字符串
 *
 * @param X XID 原始字节
 * @return 20 字符 Base32 字符串
 *}
function XidToString(const X: TXid96): string;

{**
 * XidFromString - 从字符串解码 XID
 *
 * @param S 20 字符 Base32 字符串
 * @return XID 原始字节
 *
 * @raises EInvalidXid 如果格式无效
 *}
function XidFromString(const S: string): TXid96;

{**
 * TryXidFromString - 尝试从字符串解码 XID
 *
 * @param S 20 字符 Base32 字符串
 * @param X 输出 XID
 * @return True 如果解析成功
 *}
function TryXidFromString(const S: string; out X: TXid96): Boolean;

// ✅ P1: 统一解析函数命名 - TryParseXid 作为推荐名称
function TryParseXid(const S: string; out X: TXid96): Boolean; inline;

{ Zero-copy API }
// ✅ P2: 零拷贝格式化
procedure XidToChars(const X: TXid96; Dest: PChar); inline;

{ 组件提取 }

{**
 * XidTimestamp - 提取 XID 的时间戳
 *
 * @param X XID
 * @return TDateTime
 *}
function XidTimestamp(const X: TXid96): TDateTime;

{**
 * XidUnixTime - 提取 XID 的 Unix 时间戳
 *
 * @param X XID
 * @return Unix 秒级时间戳
 *}
function XidUnixTime(const X: TXid96): Int64;

{**
 * XidMachineId - 提取 XID 的机器 ID
 *
 * @param X XID
 * @return 3 字节机器 ID (作为整数)
 *}
function XidMachineId(const X: TXid96): UInt32;

{**
 * XidProcessId - 提取 XID 的进程 ID
 *
 * @param X XID
 * @return 2 字节进程 ID
 *}
function XidProcessId(const X: TXid96): Word;

{**
 * XidCounter - 提取 XID 的计数器
 *
 * @param X XID
 * @return 3 字节计数器
 *}
function XidCounter(const X: TXid96): UInt32;

{ 验证 }

{**
 * IsValidXidString - 检查字符串是否为有效 XID
 *
 * @param S 待验证字符串
 * @return True 如果有效
 *}
function IsValidXidString(const S: string): Boolean;

{**
 * XidIsNil - 检查 XID 是否为空
 *
 * @param X XID
 * @return True 如果全为零
 *}
function XidIsNil(const X: TXid96): Boolean;

{**
 * XidNil - 返回空 XID
 *
 * @return 全零 XID
 *}
function XidNil: TXid96;

{ 比较 }

{**
 * XidCompare - 比较两个 XID
 *
 * @param A, B XID
 * @return -1, 0, 1
 *}
function XidCompare(const A, B: TXid96): Integer;

{**
 * XidEquals - 检查两个 XID 是否相等
 *
 * @param A, B XID
 * @return True 如果相等
 *}
function XidEquals(const A, B: TXid96): Boolean;

{ 生成器工厂 }

{**
 * CreateXidGenerator - 创建 XID 生成器
 *
 * @return IXidGenerator 接口
 *}
function CreateXidGenerator: IXidGenerator;

implementation

uses
  {$IFDEF UNIX}
  BaseUnix,
  {$ENDIF}
  {$IFDEF WINDOWS}
  Windows,
  {$ENDIF}
  fafafa.core.crypto.random,
  fafafa.core.id.rng;  // ✅ 缓冲 RNG 优化

const
  { XID Base32 字母表 (小写，无 I L O U) }
  XID_ALPHABET = '0123456789abcdefghjkmnpqrstvwxyz';

var
  { 全局机器 ID (3 字节) }
  GMachineId: array[0..2] of Byte;
  GMachineIdInitialized: Boolean = False;

  { 全局进程 ID (2 字节) }
  GProcessId: Word;
  GProcessIdInitialized: Boolean = False;

  { 全局计数器 (原子递增) }
  GCounter: UInt32;
  GCounterInitialized: Boolean = False;

  { ✅ P0: 全局初始化锁 }
  GXidInitLock: TCriticalSection = nil;

{ 初始化函数 }

procedure InitMachineId;
var
  Bytes: array[0..2] of Byte;
begin
  // ✅ P0: 快速路径检查
  if GMachineIdInitialized then Exit;

  GXidInitLock.Acquire;
  try
    // 双重检查
    if GMachineIdInitialized then Exit;

    // 生成随机机器 ID
    // ✅ 使用缓冲 RNG 优化
    IdRngFillBytes(Bytes[0], 3);
    Move(Bytes[0], GMachineId[0], 3);
    ReadWriteBarrier;
    GMachineIdInitialized := True;
  finally
    GXidInitLock.Release;
  end;
end;

procedure InitProcessId;
begin
  // ✅ P0: 快速路径检查
  if GProcessIdInitialized then Exit;

  GXidInitLock.Acquire;
  try
    // 双重检查
    if GProcessIdInitialized then Exit;

    {$IFDEF UNIX}
    GProcessId := Word(FpGetPid mod 65536);
    {$ELSE}
    GProcessId := Word(GetCurrentProcessId mod 65536);
    {$ENDIF}
    ReadWriteBarrier;
    GProcessIdInitialized := True;
  finally
    GXidInitLock.Release;
  end;
end;

procedure InitCounter;
var
  RandBytes: array[0..3] of Byte;
begin
  // ✅ P0: 快速路径检查
  if GCounterInitialized then Exit;

  GXidInitLock.Acquire;
  try
    // 双重检查
    if GCounterInitialized then Exit;

    // 随机初始计数器
    // ✅ 使用缓冲 RNG 优化
    IdRngFillBytes(RandBytes[0], 4);
    GCounter := (UInt32(RandBytes[0]) shl 16) or
                (UInt32(RandBytes[1]) shl 8) or
                UInt32(RandBytes[2]);
    GCounter := GCounter and $FFFFFF;  // 只用 24 位
    ReadWriteBarrier;
    GCounterInitialized := True;
  finally
    GXidInitLock.Release;
  end;
end;

function GetNextCounter: UInt32;
begin
  InitCounter;
  Result := InterlockedIncrement(GCounter) and $FFFFFF;
end;

{ Core generation }

function GenerateXid(UnixSec: Int64): TXid96;
var
  Counter: UInt32;
begin
  InitMachineId;
  InitProcessId;

  // 时间戳 (4 字节, 大端)
  Result[0] := Byte((UnixSec shr 24) and $FF);
  Result[1] := Byte((UnixSec shr 16) and $FF);
  Result[2] := Byte((UnixSec shr 8) and $FF);
  Result[3] := Byte(UnixSec and $FF);

  // 机器 ID (3 字节)
  Result[4] := GMachineId[0];
  Result[5] := GMachineId[1];
  Result[6] := GMachineId[2];

  // 进程 ID (2 字节, 大端)
  Result[7] := Byte((GProcessId shr 8) and $FF);
  Result[8] := Byte(GProcessId and $FF);

  // 计数器 (3 字节, 大端)
  Counter := GetNextCounter;
  Result[9] := Byte((Counter shr 16) and $FF);
  Result[10] := Byte((Counter shr 8) and $FF);
  Result[11] := Byte(Counter and $FF);
end;

function Xid: TXid96;
var
  NowUnix: Int64;
begin
  NowUnix := DateTimeToUnix(LocalTimeToUniversal(Now), False);
  Result := GenerateXid(NowUnix);
end;

function XidString: string;
begin
  Result := XidToString(Xid);
end;

function XidFromTime(ATime: TDateTime): TXid96;
var
  UnixSec: Int64;
begin
  UnixSec := DateTimeToUnix(ATime, False);
  Result := GenerateXid(UnixSec);
end;

function XidFromUnix(UnixSec: Int64): TXid96;
begin
  Result := GenerateXid(UnixSec);
end;

{ Batch generation }

function XidN(Count: Integer): TStringArray;
var
  I: Integer;
begin
  if Count < 0 then
    Count := 0;
  SetLength(Result, Count);
  for I := 0 to Count - 1 do
    Result[I] := XidString;
end;

function XidBatchN(Count: Integer): TXid96Array;
var
  I: Integer;
begin
  if Count < 0 then
    Count := 0;
  SetLength(Result, Count);
  for I := 0 to Count - 1 do
    Result[I] := Xid;
end;

{ Encoding/Decoding }

function XidToString(const X: TXid96): string;
begin
  // 12 字节 = 96 位 -> 20 个 Base32 字符 (每个 5 位, 100 位容量)
  // 编码方式: 每 5 字节 -> 8 字符 (40 位 = 8*5)
  // 12 字节分成: 5 + 5 + 2
  // 或者简单地按位处理

  SetLength(Result, 20);

  // 字节 0-4 -> 字符 1-8
  Result[1] := XID_ALPHABET[((X[0] shr 3) and $1F) + 1];
  Result[2] := XID_ALPHABET[(((X[0] shl 2) or (X[1] shr 6)) and $1F) + 1];
  Result[3] := XID_ALPHABET[((X[1] shr 1) and $1F) + 1];
  Result[4] := XID_ALPHABET[(((X[1] shl 4) or (X[2] shr 4)) and $1F) + 1];
  Result[5] := XID_ALPHABET[(((X[2] shl 1) or (X[3] shr 7)) and $1F) + 1];
  Result[6] := XID_ALPHABET[((X[3] shr 2) and $1F) + 1];
  Result[7] := XID_ALPHABET[(((X[3] shl 3) or (X[4] shr 5)) and $1F) + 1];
  Result[8] := XID_ALPHABET[(X[4] and $1F) + 1];

  // 字节 5-9 -> 字符 9-16
  Result[9] := XID_ALPHABET[((X[5] shr 3) and $1F) + 1];
  Result[10] := XID_ALPHABET[(((X[5] shl 2) or (X[6] shr 6)) and $1F) + 1];
  Result[11] := XID_ALPHABET[((X[6] shr 1) and $1F) + 1];
  Result[12] := XID_ALPHABET[(((X[6] shl 4) or (X[7] shr 4)) and $1F) + 1];
  Result[13] := XID_ALPHABET[(((X[7] shl 1) or (X[8] shr 7)) and $1F) + 1];
  Result[14] := XID_ALPHABET[((X[8] shr 2) and $1F) + 1];
  Result[15] := XID_ALPHABET[(((X[8] shl 3) or (X[9] shr 5)) and $1F) + 1];
  Result[16] := XID_ALPHABET[(X[9] and $1F) + 1];

  // 字节 10-11 -> 字符 17-20
  Result[17] := XID_ALPHABET[((X[10] shr 3) and $1F) + 1];
  Result[18] := XID_ALPHABET[(((X[10] shl 2) or (X[11] shr 6)) and $1F) + 1];
  Result[19] := XID_ALPHABET[((X[11] shr 1) and $1F) + 1];
  Result[20] := XID_ALPHABET[((X[11] shl 4) and $1F) + 1];
end;

function Base32Value(C: Char): Integer;
begin
  case C of
    '0': Result := 0;
    '1': Result := 1;
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
    Result := -1;
  end;
end;

function TryXidFromString(const S: string; out X: TXid96): Boolean;
var
  V: array[1..20] of Byte;
  I: Integer;
  Val: Integer;
begin
  Result := False;
  FillChar(X[0], SizeOf(X), 0);

  if Length(S) <> XID_STRING_LENGTH then
    Exit;

  // 解析每个字符
  for I := 1 to 20 do
  begin
    Val := Base32Value(S[I]);
    if Val < 0 then
      Exit;
    V[I] := Byte(Val);
  end;

  // 反向编码: 8 字符 -> 5 字节
  // 字符 1-8 -> 字节 0-4
  X[0] := (V[1] shl 3) or (V[2] shr 2);
  X[1] := (V[2] shl 6) or (V[3] shl 1) or (V[4] shr 4);
  X[2] := (V[4] shl 4) or (V[5] shr 1);
  X[3] := (V[5] shl 7) or (V[6] shl 2) or (V[7] shr 3);
  X[4] := (V[7] shl 5) or V[8];

  // 字符 9-16 -> 字节 5-9
  X[5] := (V[9] shl 3) or (V[10] shr 2);
  X[6] := (V[10] shl 6) or (V[11] shl 1) or (V[12] shr 4);
  X[7] := (V[12] shl 4) or (V[13] shr 1);
  X[8] := (V[13] shl 7) or (V[14] shl 2) or (V[15] shr 3);
  X[9] := (V[15] shl 5) or V[16];

  // 字符 17-20 -> 字节 10-11
  X[10] := (V[17] shl 3) or (V[18] shr 2);
  X[11] := (V[18] shl 6) or (V[19] shl 1) or (V[20] shr 4);

  Result := True;
end;

// ✅ P1: TryParseXid 作为 TryXidFromString 的别名
function TryParseXid(const S: string; out X: TXid96): Boolean;
begin
  Result := TryXidFromString(S, X);
end;

// ✅ P2: 零拷贝格式化
procedure XidToChars(const X: TXid96; Dest: PChar);
begin
  // 12 字节 = 96 位 -> 20 个 Base32 字符
  Dest[0] := XID_ALPHABET[((X[0] shr 3) and $1F) + 1];
  Dest[1] := XID_ALPHABET[(((X[0] shl 2) or (X[1] shr 6)) and $1F) + 1];
  Dest[2] := XID_ALPHABET[((X[1] shr 1) and $1F) + 1];
  Dest[3] := XID_ALPHABET[(((X[1] shl 4) or (X[2] shr 4)) and $1F) + 1];
  Dest[4] := XID_ALPHABET[(((X[2] shl 1) or (X[3] shr 7)) and $1F) + 1];
  Dest[5] := XID_ALPHABET[((X[3] shr 2) and $1F) + 1];
  Dest[6] := XID_ALPHABET[(((X[3] shl 3) or (X[4] shr 5)) and $1F) + 1];
  Dest[7] := XID_ALPHABET[(X[4] and $1F) + 1];

  Dest[8] := XID_ALPHABET[((X[5] shr 3) and $1F) + 1];
  Dest[9] := XID_ALPHABET[(((X[5] shl 2) or (X[6] shr 6)) and $1F) + 1];
  Dest[10] := XID_ALPHABET[((X[6] shr 1) and $1F) + 1];
  Dest[11] := XID_ALPHABET[(((X[6] shl 4) or (X[7] shr 4)) and $1F) + 1];
  Dest[12] := XID_ALPHABET[(((X[7] shl 1) or (X[8] shr 7)) and $1F) + 1];
  Dest[13] := XID_ALPHABET[((X[8] shr 2) and $1F) + 1];
  Dest[14] := XID_ALPHABET[(((X[8] shl 3) or (X[9] shr 5)) and $1F) + 1];
  Dest[15] := XID_ALPHABET[(X[9] and $1F) + 1];

  Dest[16] := XID_ALPHABET[((X[10] shr 3) and $1F) + 1];
  Dest[17] := XID_ALPHABET[(((X[10] shl 2) or (X[11] shr 6)) and $1F) + 1];
  Dest[18] := XID_ALPHABET[((X[11] shr 1) and $1F) + 1];
  Dest[19] := XID_ALPHABET[((X[11] shl 4) and $1F) + 1];
end;

function XidFromString(const S: string): TXid96;
begin
  if not TryXidFromString(S, Result) then
    raise EInvalidXid.CreateFmt('Invalid XID string: "%s"', [S]);
end;

{ Component extraction }

function XidTimestamp(const X: TXid96): TDateTime;
begin
  Result := UnixToDateTime(XidUnixTime(X), False);
end;

function XidUnixTime(const X: TXid96): Int64;
begin
  Result := (Int64(X[0]) shl 24) or
            (Int64(X[1]) shl 16) or
            (Int64(X[2]) shl 8) or
            Int64(X[3]);
end;

function XidMachineId(const X: TXid96): UInt32;
begin
  Result := (UInt32(X[4]) shl 16) or
            (UInt32(X[5]) shl 8) or
            UInt32(X[6]);
end;

function XidProcessId(const X: TXid96): Word;
begin
  Result := (Word(X[7]) shl 8) or Word(X[8]);
end;

function XidCounter(const X: TXid96): UInt32;
begin
  Result := (UInt32(X[9]) shl 16) or
            (UInt32(X[10]) shl 8) or
            UInt32(X[11]);
end;

{ Validation }

function IsValidXidString(const S: string): Boolean;
var
  X: TXid96;
begin
  Result := TryXidFromString(S, X);
end;

function XidIsNil(const X: TXid96): Boolean;
var
  I: Integer;
begin
  Result := True;
  for I := 0 to 11 do
  begin
    if X[I] <> 0 then
    begin
      Result := False;
      Exit;
    end;
  end;
end;

function XidNil: TXid96;
begin
  FillChar(Result[0], SizeOf(Result), 0);
end;

{ Comparison }

function XidCompare(const A, B: TXid96): Integer;
var
  I: Integer;
begin
  for I := 0 to 11 do
  begin
    if A[I] < B[I] then
    begin
      Result := -1;
      Exit;
    end;
    if A[I] > B[I] then
    begin
      Result := 1;
      Exit;
    end;
  end;
  Result := 0;
end;

function XidEquals(const A, B: TXid96): Boolean;
begin
  Result := XidCompare(A, B) = 0;
end;

{ Generator }

type
  TXidGenerator = class(TInterfacedObject, IXidGenerator)
  public
    // ✅ T1.2: 统一接口命名
    function NextRaw: TXid96;
    function Next: string;
    function NextN(Count: Integer): TStringArray;
  end;

// ✅ T1.2: NextRaw 返回原始类型
function TXidGenerator.NextRaw: TXid96;
begin
  Result := Xid;
end;

// ✅ T1.2: Next 返回字符串 (最常用)
function TXidGenerator.Next: string;
begin
  Result := XidString;
end;

function TXidGenerator.NextN(Count: Integer): TStringArray;
begin
  Result := XidN(Count);
end;

function CreateXidGenerator: IXidGenerator;
begin
  Result := TXidGenerator.Create;
end;

initialization
  GXidInitLock := TCriticalSection.Create;

finalization
  // ✅ P0: 清理敏感数据
  FillChar(GMachineId[0], SizeOf(GMachineId), 0);
  GProcessId := 0;
  GCounter := 0;
  GXidInitLock.Free;

end.
