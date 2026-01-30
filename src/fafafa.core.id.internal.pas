{
  fafafa.core.id.internal — 内部共享辅助函数

  提供 ID 生成器共用的底层操作:
  - 48 位时间戳编码/解码 (big-endian)
  - 32 位时间戳编码/解码 (big-endian)
  - 80 位随机数递增
  - 安全随机填充

  此单元仅供 fafafa.core.id.* 内部使用，不保证 API 稳定性。
}

unit fafafa.core.id.internal;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

type
  { 通用字节数组类型 }
  TBytes10 = array[0..9] of Byte;   // 80-bit
  TBytes6 = array[0..5] of Byte;    // 48-bit
  TBytes4 = array[0..3] of Byte;    // 32-bit

{ 48 位时间戳编码/解码 (big-endian) }

{**
 * EncodeTimestamp48BE - 将 64 位毫秒时间戳编码为 6 字节 big-endian
 *
 * @param Ms 毫秒时间戳 (仅使用低 48 位)
 * @param Dest 目标缓冲区 (至少 6 字节)
 *}
procedure EncodeTimestamp48BE(Ms: Int64; Dest: PByte); inline;

{**
 * DecodeTimestamp48BE - 从 6 字节 big-endian 解码 48 位时间戳
 *
 * @param Src 源缓冲区 (至少 6 字节)
 * @return 毫秒时间戳
 *}
function DecodeTimestamp48BE(Src: PByte): Int64; inline;

{ 32 位时间戳编码/解码 (big-endian) }

{**
 * EncodeTimestamp32BE - 将 32 位秒时间戳编码为 4 字节 big-endian
 *
 * @param Seconds 秒时间戳
 * @param Dest 目标缓冲区 (至少 4 字节)
 *}
procedure EncodeTimestamp32BE(Seconds: UInt32; Dest: PByte); inline;

{**
 * DecodeTimestamp32BE - 从 4 字节 big-endian 解码 32 位时间戳
 *
 * @param Src 源缓冲区 (至少 4 字节)
 * @return 秒时间戳
 *}
function DecodeTimestamp32BE(Src: PByte): UInt32; inline;

{ 80 位随机数操作 }

{**
 * Inc80 - 递增 80 位 big-endian 整数
 *
 * @param Data 10 字节数组 (big-endian)
 * @return True 如果成功，False 如果溢出 (wrap to zero)
 *}
function Inc80(var Data: TBytes10): Boolean;

{**
 * ClearSensitive10 - 清除 10 字节敏感数据
 *
 * @param Data 要清除的数据
 *}
procedure ClearSensitive10(var Data: TBytes10); inline;

{**
 * ClearSensitive6 - 清除 6 字节敏感数据
 *
 * @param Data 要清除的数据
 *}
procedure ClearSensitive6(var Data: TBytes6); inline;

{ 十六进制转换 }

{**
 * HexCharToNibble - 单个十六进制字符转数值
 *
 * @param C 十六进制字符 (0-9, a-f, A-F)
 * @param V 输出数值 (0-15)
 * @return True 如果字符有效
 *}
function HexCharToNibble(C: Char; out V: Byte): Boolean; inline;

{**
 * HexCharValue - 单个十六进制字符转数值 (无验证)
 *
 * @param C 十六进制字符 (0-9, a-f, A-F)
 * @return 数值 (0-15)，无效字符返回 0
 *}
function HexCharValue(C: Char): Byte; inline;

{**
 * HexToByte - 两个十六进制字符转字节
 *
 * @param C1 高位字符
 * @param C2 低位字符
 * @return 字节值
 *}
function HexToByte(C1, C2: Char): Byte; inline;

{ 安全随机填充 }

{**
 * SecureFillRandom - 使用密码学安全随机数填充缓冲区
 *
 * @param Dest 目标缓冲区
 * @param Len 字节数
 *
 * @note 使用 IdRngFillBytes 优化版本
 *}
procedure SecureFillRandom(Dest: PByte; Len: Integer);

implementation

uses
  fafafa.core.id.rng;

{ 48 位时间戳编码/解码 }

procedure EncodeTimestamp48BE(Ms: Int64; Dest: PByte);
begin
  Dest[0] := Byte((Ms shr 40) and $FF);
  Dest[1] := Byte((Ms shr 32) and $FF);
  Dest[2] := Byte((Ms shr 24) and $FF);
  Dest[3] := Byte((Ms shr 16) and $FF);
  Dest[4] := Byte((Ms shr 8) and $FF);
  Dest[5] := Byte(Ms and $FF);
end;

function DecodeTimestamp48BE(Src: PByte): Int64;
begin
  Result := (Int64(Src[0]) shl 40) or
            (Int64(Src[1]) shl 32) or
            (Int64(Src[2]) shl 24) or
            (Int64(Src[3]) shl 16) or
            (Int64(Src[4]) shl 8) or
            Int64(Src[5]);
end;

{ 32 位时间戳编码/解码 }

procedure EncodeTimestamp32BE(Seconds: UInt32; Dest: PByte);
begin
  Dest[0] := Byte((Seconds shr 24) and $FF);
  Dest[1] := Byte((Seconds shr 16) and $FF);
  Dest[2] := Byte((Seconds shr 8) and $FF);
  Dest[3] := Byte(Seconds and $FF);
end;

function DecodeTimestamp32BE(Src: PByte): UInt32;
begin
  Result := (UInt32(Src[0]) shl 24) or
            (UInt32(Src[1]) shl 16) or
            (UInt32(Src[2]) shl 8) or
            UInt32(Src[3]);
end;

{ 80 位随机数操作 }

function Inc80(var Data: TBytes10): Boolean;
var
  I: Integer;
  Carry: Integer;
begin
  // 从低字节到高字节递增 (big-endian: Data[9] 是最低字节)
  Carry := 1;
  for I := 9 downto 0 do
  begin
    Carry := Carry + Data[I];
    Data[I] := Byte(Carry and $FF);
    Carry := Carry shr 8;
    if Carry = 0 then Break;
  end;
  // 如果 Carry 仍然 > 0，说明溢出 (wrap to zero)
  Result := (Carry = 0);
end;

procedure ClearSensitive10(var Data: TBytes10);
begin
  FillChar(Data[0], SizeOf(Data), 0);
end;

procedure ClearSensitive6(var Data: TBytes6);
begin
  FillChar(Data[0], SizeOf(Data), 0);
end;

{ 十六进制转换 }

function HexCharToNibble(C: Char; out V: Byte): Boolean;
begin
  case C of
    '0'..'9': begin V := Ord(C) - Ord('0'); Result := True; end;
    'a'..'f': begin V := 10 + (Ord(C) - Ord('a')); Result := True; end;
    'A'..'F': begin V := 10 + (Ord(C) - Ord('A')); Result := True; end;
  else
    V := 0;
    Result := False;
  end;
end;

function HexCharValue(C: Char): Byte;
begin
  case C of
    '0'..'9': Result := Ord(C) - Ord('0');
    'a'..'f': Result := 10 + (Ord(C) - Ord('a'));
    'A'..'F': Result := 10 + (Ord(C) - Ord('A'));
  else
    Result := 0;
  end;
end;

function HexToByte(C1, C2: Char): Byte;
begin
  Result := (HexCharValue(C1) shl 4) or HexCharValue(C2);
end;

{ 安全随机填充 }

procedure SecureFillRandom(Dest: PByte; Len: Integer);
begin
  if Len > 0 then
    IdRngFillBytes(Dest^, Len);
end;

end.
