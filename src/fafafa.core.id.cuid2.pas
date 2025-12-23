{
  fafafa.core.id.cuid2 — CUID2: 抗碰撞安全 ID

  CUID2 是 CUID 的改进版本，专为安全和抗碰撞设计:
  - 默认 24 字符
  - 只包含小写字母和数字
  - 首字符保证是字母 (a-z)
  - 基于哈希 (SHA256) 的安全设计
  - 不可预测、抗碰撞

  对标 Rust: https://docs.rs/cuid2/latest/cuid2/
  对标 JS: https://github.com/paralleldrive/cuid2

  使用示例:
    var Id := Cuid2;                  // "clh3am8q0000008mh3qwp3kqg"
    var Id := Cuid2(32);              // 32 字符版本
    var Gen := CreateCuid2Generator; // 生成器模式
}

unit fafafa.core.id.cuid2;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils;

type
  { CUID2 生成器接口 }
  ICuid2Generator = interface
    ['{E5F6A7B8-C9D0-1234-EF01-567890123DEF}']
    function Next: string;
    function NextN(Count: Integer): TStringArray;
    function GetLength: Integer;
    procedure SetLength_(ALength: Integer);
    property Length: Integer read GetLength write SetLength_;
  end;

const
  { CUID2 默认长度 }
  CUID2_DEFAULT_LENGTH = 24;

  { CUID2 最小长度 }
  CUID2_MIN_LENGTH = 2;

  { CUID2 最大长度 }
  CUID2_MAX_LENGTH = 32;

{ 基本生成函数 }

{**
 * Cuid2 - 生成 CUID2
 *
 * @param Length ID 长度 (默认 24, 范围 2-32)
 * @return CUID2 字符串
 *
 * @example
 *   var Id := Cuid2;     // "clh3am8q0000008mh3qwp3kqg"
 *   var Id := Cuid2(32); // 更长的版本
 *}
function Cuid2(ALength: Integer = CUID2_DEFAULT_LENGTH): string;

{ 批量生成 }

{**
 * Cuid2N - 批量生成 CUID2
 *
 * @param Count 生成数量
 * @param Length ID 长度 (默认 24)
 * @return CUID2 字符串数组
 *}
function Cuid2N(Count: Integer; ALength: Integer = CUID2_DEFAULT_LENGTH): TStringArray;

{ 验证 }

{**
 * IsCuid2 - 检查字符串是否为有效 CUID2
 *
 * @param S 待验证字符串
 * @return True 如果格式有效
 *}
function IsCuid2(const S: string): Boolean;

{ 生成器工厂 }

{**
 * CreateCuid2Generator - 创建 CUID2 生成器
 *
 * @param Length ID 长度 (默认 24)
 * @return ICuid2Generator 接口
 *}
function CreateCuid2Generator(ALength: Integer = CUID2_DEFAULT_LENGTH): ICuid2Generator;

implementation

uses
  DateUtils,
  {$IFDEF UNIX}
  BaseUnix,
  Unix,
  {$ENDIF}
  {$IFDEF WINDOWS}
  Windows,
  {$ENDIF}
  fafafa.core.crypto.random,
  fafafa.core.crypto.hash.sha256;

const
  { CUID2 字母表 (首字符) }
  ALPHABET_FIRST = 'abcdefghijklmnopqrstuvwxyz';

  { CUID2 字母表 (其他字符) }
  ALPHABET_ALL = 'abcdefghijklmnopqrstuvwxyz0123456789';

type
  { 指纹缓存 }
  TFingerprint = record
    Data: string;
    Initialized: Boolean;
  end;

var
  { 全局计数器 }
  GCounter: UInt64;
  GCounterInitialized: Boolean = False;

  { 全局指纹 }
  GFingerprint: TFingerprint;

{ Helper functions }

procedure InitCounter;
var
  RandBytes: array[0..7] of Byte;
begin
  if GCounterInitialized then Exit;

  GetSecureRandom.GetBytes(RandBytes[0], 8);
  GCounter := PUInt64(@RandBytes[0])^;
  GCounterInitialized := True;
end;

function GetNextCounter: UInt64;
begin
  InitCounter;
  Result := InterlockedIncrement64(GCounter);
end;

function CreateEntropy(ALength: Integer): string;
var
  Bytes: array of Byte;
  I: Integer;
begin
  SetLength(Bytes, ALength);
  GetSecureRandom.GetBytes(Bytes[0], ALength);

  Result := '';
  for I := 0 to ALength - 1 do
    Result := Result + IntToHex(Bytes[I], 2);
end;

function GetFingerprint: string;
var
  PID: Cardinal;
  RandPart: string;
begin
  if GFingerprint.Initialized then
  begin
    Result := GFingerprint.Data;
    Exit;
  end;

  // 获取进程 ID
  {$IFDEF UNIX}
  PID := FpGetPid;
  {$ELSE}
  PID := GetCurrentProcessId;
  {$ENDIF}

  // 使用随机部分作为机器标识 (简化实现，避免复杂的系统调用)
  RandPart := CreateEntropy(16);

  // 组合指纹
  Result := IntToStr(PID) + RandPart;

  GFingerprint.Data := Result;
  GFingerprint.Initialized := True;
end;

function HashToBase36(const Data: string; ALength: Integer): string;
var
  Hash: TBytes;
  I, Idx: Integer;
begin
  // 计算 SHA256 哈希
  Hash := SHA256Hash(Data);

  // 简化的 Base36 转换: 使用哈希的字节直接映射
  Result := '';

  // 首字符必须是字母
  Idx := Hash[0] mod 26;
  Result := Result + ALPHABET_FIRST[Idx + 1];

  // 其余字符
  for I := 1 to ALength - 1 do
  begin
    Idx := Hash[I mod 32] mod 36;
    Result := Result + ALPHABET_ALL[Idx + 1];
  end;
end;

{ Core generation }

function Cuid2(ALength: Integer): string;
var
  TimeMs: Int64;
  Counter: UInt64;
  Entropy: string;
  Fingerprint: string;
  Input: string;
begin
  // 验证长度
  if ALength < CUID2_MIN_LENGTH then
    ALength := CUID2_MIN_LENGTH;
  if ALength > CUID2_MAX_LENGTH then
    ALength := CUID2_MAX_LENGTH;

  // 获取组件
  TimeMs := DateTimeToUnix(LocalTimeToUniversal(Now), False) * 1000 +
            MilliSecondOf(Now);
  Counter := GetNextCounter;
  Entropy := CreateEntropy(ALength);
  Fingerprint := GetFingerprint;

  // 组合输入
  Input := IntToStr(TimeMs) +
           IntToStr(Counter) +
           Entropy +
           Fingerprint;

  // 哈希并转换
  Result := HashToBase36(Input, ALength);
end;

{ Batch generation }

function Cuid2N(Count: Integer; ALength: Integer): TStringArray;
var
  I: Integer;
begin
  if Count < 0 then
    Count := 0;
  SetLength(Result, Count);
  for I := 0 to Count - 1 do
    Result[I] := Cuid2(ALength);
end;

{ Validation }

function IsCuid2(const S: string): Boolean;
var
  I: Integer;
  C: Char;
begin
  Result := False;

  // 检查长度
  if (Length(S) < CUID2_MIN_LENGTH) or (Length(S) > CUID2_MAX_LENGTH) then
    Exit;

  // 首字符必须是小写字母
  C := S[1];
  if (C < 'a') or (C > 'z') then
    Exit;

  // 其余字符必须是小写字母或数字
  for I := 2 to Length(S) do
  begin
    C := S[I];
    if not ((C >= 'a') and (C <= 'z')) and not ((C >= '0') and (C <= '9')) then
      Exit;
  end;

  Result := True;
end;

{ Generator implementation }

type
  TCuid2Generator = class(TInterfacedObject, ICuid2Generator)
  private
    FLength: Integer;
  public
    constructor Create(ALength: Integer);
    function Next: string;
    function NextN(Count: Integer): TStringArray;
    function GetLength: Integer;
    procedure SetLength_(ALength: Integer);
  end;

constructor TCuid2Generator.Create(ALength: Integer);
begin
  inherited Create;
  FLength := ALength;
  if FLength < CUID2_MIN_LENGTH then
    FLength := CUID2_MIN_LENGTH;
  if FLength > CUID2_MAX_LENGTH then
    FLength := CUID2_MAX_LENGTH;
end;

function TCuid2Generator.Next: string;
begin
  Result := Cuid2(FLength);
end;

function TCuid2Generator.NextN(Count: Integer): TStringArray;
begin
  Result := Cuid2N(Count, FLength);
end;

function TCuid2Generator.GetLength: Integer;
begin
  Result := FLength;
end;

procedure TCuid2Generator.SetLength_(ALength: Integer);
begin
  FLength := ALength;
  if FLength < CUID2_MIN_LENGTH then
    FLength := CUID2_MIN_LENGTH;
  if FLength > CUID2_MAX_LENGTH then
    FLength := CUID2_MAX_LENGTH;
end;

function CreateCuid2Generator(ALength: Integer): ICuid2Generator;
begin
  Result := TCuid2Generator.Create(ALength);
end;

end.
