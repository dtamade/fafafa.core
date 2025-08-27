{
  fafafa.core.crypto.utils - 加密实用工具函数

  本单元提供各种加密相关的实用工具函数：
  - 常量时间操作
  - 密码强度检查
  - 安全密码生成
  - 内存安全操作

  实现特点：
  - 防止时间攻击的常量时间实现
  - 符合现代密码安全标准
  - 易于使用的高级接口
}

unit fafafa.core.crypto.utils;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.crypto.interfaces;

type
  TBytes = array of Byte;

  // 使用接口单元中的共享异常类型，避免重复定义
  ECrypto = fafafa.core.crypto.interfaces.ECrypto;
  EInvalidArgument = fafafa.core.crypto.interfaces.EInvalidArgument;
  EWeakPassword = class(ECrypto) end;

  // 使用完整接口定义
  ISecureRandom = fafafa.core.crypto.interfaces.ISecureRandom;

  {**
   * TPasswordStrength
   *
   * @desc
   *   Password strength levels.
   *   密码强度等级.
   *}
  TPasswordStrength = (
    psVeryWeak,    // 非常弱
    psWeak,        // 弱
    psFair,        // 一般
    psGood,        // 良好
    psStrong,      // 强
    psVeryStrong   // 非常强
  );

  {**
   * TPasswordPolicy
   *
   * @desc
   *   Password policy configuration.
   *   密码策略配置.
   *}
  TPasswordPolicy = record
    MinLength: Integer;           // 最小长度
    RequireUppercase: Boolean;    // 需要大写字母
    RequireLowercase: Boolean;    // 需要小写字母
    RequireDigits: Boolean;       // 需要数字
    RequireSymbols: Boolean;      // 需要符号
    MaxRepeatedChars: Integer;    // 最大重复字符数
    ForbidCommonPasswords: Boolean; // 禁止常见密码
  end;

{**
 * 常量时间操作函数
 * Constant-time Operations
 *}

{**
 * ConstantTimeCompare
 *
 * @desc
 *   Compares two byte arrays in constant time.
 *   常量时间比较两个字节数组.
 *
 * @params
 *   AData1 - First byte array.
 *           第一个字节数组.
 *   AData2 - Second byte array.
 *           第二个字节数组.
 *
 * @returns
 *   True if arrays are equal, False otherwise.
 *   如果数组相等返回True，否则返回False.
 *}
function ConstantTimeCompare(const AData1, AData2: TBytes): Boolean;

{**
 * ConstantTimeStringCompare
 *
 * @desc
 *   Compares two strings in constant time.
 *   常量时间比较两个字符串.
 *
 * @params
 *   AStr1 - First string.
 *          第一个字符串.
 *   AStr2 - Second string.
 *          第二个字符串.
 *
 * @returns
 *   True if strings are equal, False otherwise.
 *   如果字符串相等返回True，否则返回False.
 *}
function ConstantTimeStringCompare(const AStr1, AStr2: string): Boolean;

{**
 * 安全内存操作
 * Secure Memory Operations
 *}

{**
 * SecureZeroMemory
 *
 * @desc
 *   Securely zeros memory to prevent data recovery.
 *   安全地清零内存以防止数据恢复.
 *
 * @params
 *   ABuffer - Pointer to memory buffer.
 *            内存缓冲区指针.
 *   ASize - Size of buffer in bytes.
 *          缓冲区大小（字节）.
 *}
procedure SecureZeroMemory(ABuffer: Pointer; ASize: Integer);

{**
 * SecureZeroBytes
 *
 * @desc
 *   Securely zeros a byte array.
 *   安全地清零字节数组.
 *
 * @params
 *   AData - Byte array to zero.
 *          要清零的字节数组.
 *}
procedure SecureZeroBytes(var AData: TBytes);

{**
 * SecureZeroString
 *
 * @desc
 *   Securely zeros a string.
 *   安全地清零字符串.
 *
 * @params
 *   AStr - String to zero.
 *         要清零的字符串.
 *}
procedure SecureZeroString(var AStr: string);

{**
 * 密码强度检查
 * Password Strength Checking
 *}

{**
 * CheckPasswordStrength
 *
 * @desc
 *   Checks the strength of a password.
 *   检查密码强度.
 *
 * @params
 *   APassword - Password to check.
 *              要检查的密码.
 *
 * @returns
 *   Password strength level.
 *   密码强度等级.
 *}
function CheckPasswordStrength(const APassword: string): TPasswordStrength;

{**
 * ValidatePassword
 *
 * @desc
 *   Validates a password against a policy.
 *   根据策略验证密码.
 *
 * @params
 *   APassword - Password to validate.
 *              要验证的密码.
 *   APolicy - Password policy.
 *            密码策略.
 *
 * @returns
 *   True if password meets policy, False otherwise.
 *   如果密码符合策略返回True，否则返回False.
 *}
function ValidatePassword(const APassword: string; const APolicy: TPasswordPolicy): Boolean;

{**
 * GetPasswordStrengthDescription
 *
 * @desc
 *   Gets a human-readable description of password strength.
 *   获取密码强度的可读描述.
 *
 * @params
 *   AStrength - Password strength level.
 *              密码强度等级.
 *
 * @returns
 *   Description string.
 *   描述字符串.
 *}
function GetPasswordStrengthDescription(AStrength: TPasswordStrength): string;

{**
 * 安全密码生成
 * Secure Password Generation
 *}

{**
 * GenerateSecurePassword
 *
 * @desc
 *   Generates a cryptographically secure password.
 *   生成加密安全的密码.
 *
 * @params
 *   ALength - Desired password length.
 *            期望的密码长度.
 *   AIncludeUppercase - Include uppercase letters.
 *                      包含大写字母.
 *   AIncludeLowercase - Include lowercase letters.
 *                      包含小写字母.
 *   AIncludeDigits - Include digits.
 *                   包含数字.
 *   AIncludeSymbols - Include symbols.
 *                    包含符号.
 *
 * @returns
 *   Generated password.
 *   生成的密码.
 *}
function GenerateSecurePassword(ALength: Integer;
  AIncludeUppercase: Boolean = True;
  AIncludeLowercase: Boolean = True;
  AIncludeDigits: Boolean = True;
  AIncludeSymbols: Boolean = True): string;

{**
 * GeneratePassphrase
 *
 * @desc
 *   Generates a secure passphrase using word lists.
 *   使用词汇表生成安全的密码短语.
 *
 * @params
 *   AWordCount - Number of words in passphrase.
 *               密码短语中的单词数.
 *   ASeparator - Word separator character.
 *               单词分隔符.
 *
 * @returns
 *   Generated passphrase.
 *   生成的密码短语.
 *}
function GeneratePassphrase(AWordCount: Integer = 4; const ASeparator: string = '-'): string;

{**
 * 默认密码策略
 * Default Password Policies
 *}

{**
 * GetDefaultPasswordPolicy
 *
 * @desc
 *   Gets a default password policy for general use.
 *   获取通用的默认密码策略.
 *
 * @returns
 *   Default password policy.
 *   默认密码策略.
 *}
function GetDefaultPasswordPolicy: TPasswordPolicy;

{**
 * GetStrictPasswordPolicy
 *
 * @desc
 *   Gets a strict password policy for high-security applications.
 *   获取高安全应用的严格密码策略.
 *
 * @returns
 *   Strict password policy.
 *   严格密码策略.
 *}
function GetStrictPasswordPolicy: TPasswordPolicy;

  {**
   * AEAD/GCM Nonce Helpers
   * 非对称加密的随机数之外，一般推荐 96-bit (12字节) Nonce：
   * - GenerateNonce12: 使用 CSPRNG 直接生成 12 字节（需调用方确保同一密钥下不重复）
   * - ComposeGCMNonce12: 使用 32-bit 实例ID + 64-bit 计数器（大端拼接），便于跨进程有序唯一
   *}
  function GenerateNonce12: TBytes;
  function ComposeGCMNonce12(AInstanceID: UInt32; ACounter: UInt64): TBytes;


// 前向声明
function GetSecureRandom: ISecureRandom;

implementation

uses
  fafafa.core.crypto.random;

// 辅助函数
function LowerCase(const AStr: string): string;
var
  LI: Integer;
begin
  Result := '';
  SetLength(Result, Length(AStr));
  for LI := 1 to Length(AStr) do
  begin
    if AStr[LI] in ['A'..'Z'] then
      Result[LI] := Chr(Ord(AStr[LI]) + 32)
    else
      Result[LI] := AStr[LI];
  end;
end;

function Max(A, B: Integer): Integer;
begin
  if A > B then
    Result := A
  else
    Result := B;
end;

{**
 * 常量时间操作实现
 *}

function ConstantTimeCompare(const AData1, AData2: TBytes): Boolean;
var
  LI: Integer;
  LResult: Byte;
  LLen1, LLen2: Integer;
begin
  LLen1 := Length(AData1);
  LLen2 := Length(AData2);

  // 首先比较长度，但仍然要遍历完整个数组以保持常量时间
  LResult := 0;

  // 使用较长的长度来确保遍历所有数据
  for LI := 0 to Max(LLen1, LLen2) - 1 do
  begin
    if (LI < LLen1) and (LI < LLen2) then
      LResult := LResult or (AData1[LI] xor AData2[LI])
    else
      LResult := LResult or $FF; // 长度不同，标记为不相等
  end;

  // 长度不同也标记为不相等
  if LLen1 <> LLen2 then
    LResult := LResult or $FF;

  Result := LResult = 0;
end;

function ConstantTimeStringCompare(const AStr1, AStr2: string): Boolean;
var
  LI: Integer;
  LResult: Byte;
  LLen1, LLen2: Integer;
begin
  LLen1 := Length(AStr1);
  LLen2 := Length(AStr2);

  LResult := 0;

  // 使用较长的长度来确保遍历所有字符
  for LI := 1 to Max(LLen1, LLen2) do
  begin
    if (LI <= LLen1) and (LI <= LLen2) then
      LResult := LResult or (Ord(AStr1[LI]) xor Ord(AStr2[LI]))
    else
      LResult := LResult or $FF; // 长度不同，标记为不相等
  end;

  // 长度不同也标记为不相等
  if LLen1 <> LLen2 then
    LResult := LResult or $FF;

  Result := LResult = 0;
end;

{**
 * 安全内存操作实现
 *}

procedure SecureZeroMemory(ABuffer: Pointer; ASize: Integer);
var
  LBytePtr: PByte;
  LI: Integer;
begin
  if (ABuffer = nil) or (ASize <= 0) then
    Exit;

  LBytePtr := PByte(ABuffer);

  // 使用volatile写入来防止编译器优化
  for LI := 0 to ASize - 1 do
  begin
    LBytePtr^ := 0;
    Inc(LBytePtr);
  end;

  // 添加内存屏障以确保写入完成
  {$IFDEF CPUX86_64}
  asm
    mfence
  end;
  {$ENDIF}
end;

procedure SecureZeroBytes(var AData: TBytes);
begin
  if Length(AData) > 0 then
  begin
    SecureZeroMemory(@AData[0], Length(AData));
    // 不改变数组长度，只清零内容
  end;
end;

procedure SecureZeroString(var AStr: string);
var
  LLen: Integer;
  LPtr: PChar;
begin
  LLen := Length(AStr);
  if LLen > 0 then
  begin
    // 确保字符串是唯一的（不与其他引用共享）
    UniqueString(AStr);
    LPtr := PChar(AStr);
    SecureZeroMemory(LPtr, LLen * SizeOf(Char));
    AStr := '';
  end;
end;

{**
 * 密码强度检查实现
 *}

function CheckPasswordStrength(const APassword: string): TPasswordStrength;
var
  LScore: Integer;
  LLength: Integer;
  LHasUpper, LHasLower, LHasDigit, LHasSymbol: Boolean;
  LI: Integer;
  LChar: Char;
  LUniqueChars: Integer;
  LCharSet: set of Char;
  LRepeatedChars: Integer;
  LMaxRepeated: Integer;
  LCurrentRepeated: Integer;
  LPrevChar: Char;
begin
  LLength := Length(APassword);

  // 基础分数：长度
  LScore := 0;
  if LLength >= 8 then Inc(LScore, 1);
  if LLength >= 12 then Inc(LScore, 1);
  if LLength >= 16 then Inc(LScore, 1);
  if LLength >= 20 then Inc(LScore, 1);

  // 字符类型检查
  LHasUpper := False;
  LHasLower := False;
  LHasDigit := False;
  LHasSymbol := False;
  LCharSet := [];

  for LI := 1 to LLength do
  begin
    LChar := APassword[LI];
    Include(LCharSet, LChar);

    if LChar in ['A'..'Z'] then
      LHasUpper := True
    else if LChar in ['a'..'z'] then
      LHasLower := True
    else if LChar in ['0'..'9'] then
      LHasDigit := True
    else
      LHasSymbol := True;
  end;

  // 字符类型分数
  if LHasUpper then Inc(LScore, 1);
  if LHasLower then Inc(LScore, 1);
  if LHasDigit then Inc(LScore, 1);
  if LHasSymbol then Inc(LScore, 2); // 符号权重更高

  // 唯一字符数
  LUniqueChars := 0;
  for LChar := #0 to #255 do
    if LChar in LCharSet then
      Inc(LUniqueChars);

  if LUniqueChars >= LLength div 2 then Inc(LScore, 1);
  if LUniqueChars >= LLength * 3 div 4 then Inc(LScore, 1);

  // 检查重复字符
  LMaxRepeated := 0;
  LCurrentRepeated := 1;
  LPrevChar := #0;

  for LI := 1 to LLength do
  begin
    LChar := APassword[LI];
    if LChar = LPrevChar then
    begin
      Inc(LCurrentRepeated);
      if LCurrentRepeated > LMaxRepeated then
        LMaxRepeated := LCurrentRepeated;
    end
    else
    begin
      LCurrentRepeated := 1;
    end;
    LPrevChar := LChar;
  end;

  // 重复字符惩罚
  if LMaxRepeated >= 3 then Dec(LScore, 2);
  if LMaxRepeated >= 4 then Dec(LScore, 2);

  // 检查常见模式（简化版）
  if (Pos('123', APassword) > 0) or (Pos('abc', APassword) > 0) or
     (Pos('qwe', APassword) > 0) or (Pos('asd', APassword) > 0) then
    Dec(LScore, 1);

  // 检查常见密码（简化版）
  if (LowerCase(APassword) = 'password') or
     (LowerCase(APassword) = '123456') or
     (LowerCase(APassword) = 'qwerty') or
     (LowerCase(APassword) = 'admin') then
    LScore := 0;

  // 根据分数确定强度
  if LScore <= 2 then
    Result := psVeryWeak
  else if LScore <= 4 then
    Result := psWeak
  else if LScore <= 6 then
    Result := psFair
  else if LScore <= 8 then
    Result := psGood
  else if LScore <= 10 then
    Result := psStrong
  else
    Result := psVeryStrong;
end;

function ValidatePassword(const APassword: string; const APolicy: TPasswordPolicy): Boolean;
var
  LLength: Integer;
  LHasUpper, LHasLower, LHasDigit, LHasSymbol: Boolean;
  LI: Integer;
  LChar: Char;
  LMaxRepeated: Integer;
  LCurrentRepeated: Integer;
  LPrevChar: Char;
begin
  LLength := Length(APassword);

  // 检查最小长度
  if LLength < APolicy.MinLength then
  begin
    Result := False;
    Exit;
  end;

  // 字符类型检查
  LHasUpper := False;
  LHasLower := False;
  LHasDigit := False;
  LHasSymbol := False;

  for LI := 1 to LLength do
  begin
    LChar := APassword[LI];

    if LChar in ['A'..'Z'] then
      LHasUpper := True
    else if LChar in ['a'..'z'] then
      LHasLower := True
    else if LChar in ['0'..'9'] then
      LHasDigit := True
    else
      LHasSymbol := True;
  end;

  // 检查字符类型要求
  if APolicy.RequireUppercase and not LHasUpper then
  begin
    Result := False;
    Exit;
  end;

  if APolicy.RequireLowercase and not LHasLower then
  begin
    Result := False;
    Exit;
  end;

  if APolicy.RequireDigits and not LHasDigit then
  begin
    Result := False;
    Exit;
  end;

  if APolicy.RequireSymbols and not LHasSymbol then
  begin
    Result := False;
    Exit;
  end;

  // 检查重复字符
  if APolicy.MaxRepeatedChars > 0 then
  begin
    LMaxRepeated := 0;
    LCurrentRepeated := 1;
    LPrevChar := #0;

    for LI := 1 to LLength do
    begin
      LChar := APassword[LI];
      if LChar = LPrevChar then
      begin
        Inc(LCurrentRepeated);
        if LCurrentRepeated > LMaxRepeated then
          LMaxRepeated := LCurrentRepeated;
      end
      else
      begin
        LCurrentRepeated := 1;
      end;
      LPrevChar := LChar;
    end;

    if LMaxRepeated > APolicy.MaxRepeatedChars then
    begin
      Result := False;
      Exit;
    end;
  end;

  // 检查常见密码
  if APolicy.ForbidCommonPasswords then
  begin
    if (LowerCase(APassword) = 'password') or
       (LowerCase(APassword) = '123456') or
       (LowerCase(APassword) = 'qwerty') or
       (LowerCase(APassword) = 'admin') or
       (LowerCase(APassword) = 'letmein') or
       (LowerCase(APassword) = 'welcome') then
    begin
      Result := False;
      Exit;
    end;
  end;

  Result := True;
end;

{$PUSH}
{$WARN 6018 OFF} // silence unreachable code warning for default case by design
function GetPasswordStrengthDescription(AStrength: TPasswordStrength): string;
begin
  // init for analyzers; overwritten by case
  Result := '';
  case AStrength of
    psVeryWeak: Result := 'Very Weak (非常弱)';
    psWeak: Result := 'Weak (弱)';
    psFair: Result := 'Fair (一般)';
    psGood: Result := 'Good (良好)';
    psStrong: Result := 'Strong (强)';
    psVeryStrong: Result := 'Very Strong (非常强)';
  else
    Result := 'Unknown (未知)';
  end;
end;
{$POP}

{**
 * 安全密码生成实现
 *}

function GenerateSecurePassword(ALength: Integer;
  AIncludeUppercase: Boolean = True;
  AIncludeLowercase: Boolean = True;
  AIncludeDigits: Boolean = True;
  AIncludeSymbols: Boolean = True): string;
{$push}
{$hints off}

const
  UPPERCASE_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  LOWERCASE_CHARS = 'abcdefghijklmnopqrstuvwxyz';
  DIGIT_CHARS    = '0123456789';
  SYMBOL_CHARS   = '!@#$%^&*()_+-=[]{}|;:,.<>?';
var
  LCombinedSet: string;        // 合并后的字符集
  LClassSets: array[0..3] of string; // 各类别字符集
  LClassEnabled: array[0..3] of Boolean; // 各类别开关
  LEnabledCount: Integer;      // 启用的类别数量
  LPos, LI: Integer;           // 位置索引
  LIdx, LSwapIdx: Integer;     // 随机索引
  LRandom: ISecureRandom;      // 安全随机数
  LChars: array of Char;       // 中间结果（待洗牌）
  Tmp: Char;                   // 交换用临时变量
begin
  // 参数校验
  Result := '';
  SetLength(LChars, 0); // calm analyzers: init managed local
  if ALength <= 0 then
    raise EInvalidArgument.Create('Password length must be positive');

  // 组装类别与开关
  LClassSets[0] := UPPERCASE_CHARS; LClassEnabled[0] := AIncludeUppercase;
  LClassSets[1] := LOWERCASE_CHARS; LClassEnabled[1] := AIncludeLowercase;
  LClassSets[2] := DIGIT_CHARS;     LClassEnabled[2] := AIncludeDigits;
  LClassSets[3] := SYMBOL_CHARS;    LClassEnabled[3] := AIncludeSymbols;

  // 合并启用的字符集
  LCombinedSet := '';
  LEnabledCount := 0;
  for LI := 0 to 3 do
  begin
    if LClassEnabled[LI] then
    begin
      LCombinedSet := LCombinedSet + LClassSets[LI];
      Inc(LEnabledCount);
    end;
  end;

  if Length(LCombinedSet) = 0 then
    raise EInvalidArgument.Create('At least one character type must be included');

  // 如果长度不足以覆盖所有启用类别，直接报错
  if ALength < LEnabledCount then
    raise EInvalidArgument.Create('Password length too short for required character classes');

  // 初始化 RNG 与结果缓冲
  LRandom := GetSecureRandom;
  SetLength(LChars, ALength);

  // 先确保每种启用的字符类型至少出现一次
  LPos := 0;
  for LI := 0 to 3 do
  begin
    if LClassEnabled[LI] then
    begin
      // 从该类别中随机取 1 个字符
      LIdx := LRandom.GetInteger(1, Length(LClassSets[LI]));
      LChars[LPos] := LClassSets[LI][LIdx];
      Inc(LPos);
    end;
  end;

  // 其余位置从合并集合随机填充
  while LPos < ALength do
  begin
    LIdx := LRandom.GetInteger(1, Length(LCombinedSet));
    LChars[LPos] := LCombinedSet[LIdx];
    Inc(LPos);
  end;

  // Fisher-Yates 洗牌，打乱位置，避免固定顺序泄漏类别信息
  // 使用安全 RNG 生成索引
  for LI := ALength - 1 downto 1 do
  begin
    LSwapIdx := LRandom.GetInteger(0, LI);
    // 交换 LChars[LI] 与 LChars[LSwapIdx]
    if LSwapIdx <> LI then
    begin
      // 交换（使用临时变量，避免不可达代码/复杂表达式导致的警告）
      tmp := LChars[LI];
      LChars[LI] := LChars[LSwapIdx];
      LChars[LSwapIdx] := tmp;
    end;
  end;

  // 输出为字符串
  SetLength(Result, ALength);
  for LI := 0 to ALength - 1 do
    Result[LI + 1] := LChars[LI];

  // 清理中间缓冲（字符数组）
  if Length(LChars) > 0 then
  begin
    for LI := 0 to High(LChars) do
      LChars[LI] := #0;
    SetLength(LChars, 0);
  end;
{$pop}

end;

function GeneratePassphrase(AWordCount: Integer = 4; const ASeparator: string = '-'): string;
const
  // 简化的词汇表（实际应用中应该使用更大的词汇表）
  WORD_LIST: array[0..99] of string = (
    'apple', 'brave', 'chair', 'dance', 'eagle', 'flame', 'grace', 'house',
    'image', 'juice', 'knife', 'light', 'music', 'night', 'ocean', 'peace',
    'queen', 'river', 'stone', 'table', 'unity', 'voice', 'water', 'youth',
    'zebra', 'angel', 'beach', 'cloud', 'dream', 'earth', 'field', 'green',
    'happy', 'ivory', 'jewel', 'kite', 'lemon', 'magic', 'novel', 'olive',
    'piano', 'quiet', 'radio', 'smile', 'tiger', 'urban', 'value', 'world',
    'extra', 'young', 'azure', 'bread', 'cream', 'depth', 'event', 'fresh',
    'giant', 'heart', 'index', 'joint', 'known', 'lunar', 'metal', 'north',
    'orbit', 'power', 'quick', 'round', 'solar', 'trust', 'ultra', 'vital',
    'wheat', 'xenon', 'yield', 'zonal', 'amber', 'basic', 'coral', 'dense',
    'empty', 'final', 'grand', 'human', 'ideal', 'jolly', 'karma', 'local',
    'moral', 'noble', 'opera', 'prime', 'quest', 'royal', 'solid', 'total',
    'ultra', 'vivid', 'worth', 'xerus'
  );
var
  LI: Integer;
  LWordIndex: Integer;
  LRandom: ISecureRandom;
begin
  Result := '';
  if AWordCount <= 0 then
    raise EInvalidArgument.Create('Word count must be positive');

  LRandom := GetSecureRandom;

  Result := '';
  for LI := 0 to AWordCount - 1 do
  begin
    if LI > 0 then
      Result := Result + ASeparator;

    LWordIndex := LRandom.GetInteger(0, High(WORD_LIST));
    Result := Result + WORD_LIST[LWordIndex];
  end;
end;

{**
 * 默认密码策略实现
 *}

function GetDefaultPasswordPolicy: TPasswordPolicy;
begin
  Result.MinLength := 8;
  Result.RequireUppercase := True;
  Result.RequireLowercase := True;
  Result.RequireDigits := True;
  Result.RequireSymbols := False;
  Result.MaxRepeatedChars := 3;
  Result.ForbidCommonPasswords := True;
end;

function GetStrictPasswordPolicy: TPasswordPolicy;
begin
  Result.MinLength := 12;
  Result.RequireUppercase := True;
  Result.RequireLowercase := True;
  Result.RequireDigits := True;
  Result.RequireSymbols := True;
  Result.MaxRepeatedChars := 2;
  Result.ForbidCommonPasswords := True;
end;

function GenerateNonce12: TBytes;
var
  R: ISecureRandom;
begin
  Result := nil; SetLength(Result, 0);
  SetLength(Result, 12);
  R := GetSecureRandom;
  if R = nil then
    raise EInvalidArgument.Create('SecureRandom not available');
  R.GetBytes(Result[0], Length(Result));
end;

function ComposeGCMNonce12(AInstanceID: UInt32; ACounter: UInt64): TBytes;
begin
  // 96-bit Nonce = 32-bit InstanceID || 64-bit Counter (big-endian)
  Result := nil; SetLength(Result, 0);
  SetLength(Result, 12);
  // InstanceID (32-bit, big-endian)
  Result[0] := Byte((AInstanceID shr 24) and $FF);
  Result[1] := Byte((AInstanceID shr 16) and $FF);
  Result[2] := Byte((AInstanceID shr 8) and $FF);
  Result[3] := Byte(AInstanceID and $FF);
  // Counter (64-bit, big-endian)
  Result[4] := Byte((ACounter shr 56) and $FF);
  Result[5] := Byte((ACounter shr 48) and $FF);
  Result[6] := Byte((ACounter shr 40) and $FF);
  Result[7] := Byte((ACounter shr 32) and $FF);
  Result[8] := Byte((ACounter shr 24) and $FF);
  Result[9] := Byte((ACounter shr 16) and $FF);
  Result[10] := Byte((ACounter shr 8) and $FF);
  Result[11] := Byte(ACounter and $FF);
end;

// GetSecureRandom实现
function GetSecureRandom: ISecureRandom;
begin
  Result := fafafa.core.crypto.random.GetSecureRandom;
end;

end.
