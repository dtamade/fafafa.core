unit fafafa.core.lockfree.util;

{$mode objfpc}{$H+}

{**
 * fafafa.core.lockfree.util - 无锁模块通用工具函数
 * 将 NextPowerOfTwo/IsPowerOfTwo/SimpleHash 等工具集中管理，
 * 供各子模块按需引用，降低门面单元耦合。
 *}

interface

// 计算下一个2的幂次方
function NextPowerOfTwo(AValue: Integer): Integer;
// 检查是否为2的幂次方
function IsPowerOfTwo(AValue: Integer): Boolean;
// 简单哈希函数（FNV-1a）
function SimpleHash(const AData; ASize: Integer): Cardinal;

implementation

function NextPowerOfTwo(AValue: Integer): Integer;
begin
  if AValue <= 1 then
    Exit(1);
  Result := 1;
  while Result < AValue do
    Result := Result shl 1;
end;

function IsPowerOfTwo(AValue: Integer): Boolean;
begin
  Result := (AValue > 0) and ((AValue and (AValue - 1)) = 0);
end;

function SimpleHash(const AData; ASize: Integer): Cardinal;
var
  LBytes: PByte;
  I: Integer;
begin
  Result := 2166136261; // FNV-1a 初始值
  LBytes := @AData;
  {$PUSH}
  {$Q-} // 关闭溢出检查，哈希允许算术溢出
  {$R-} // 局部关闭范围检查，避免指针索引触发
  for I := 0 to ASize - 1 do
  begin
    Result := Result xor LBytes[I];
    Result := Result * 16777619; // FNV-1a 质数
  end;
  {$POP}
end;

end.

