program test_lru_leak;
{$MODE OBJFPC}{$H+}

uses
  Classes, SysUtils,
  fafafa.core.collections.lrucache;

type
  TTestCache = specialize TLruCache<UnicodeString, Integer>;

class function CaseInsensitiveHash(const aValue: UnicodeString; aData: Pointer): UInt64;
var
  LUpper: UnicodeString;
  LCh: WideChar;
begin
  LUpper := UpperCase(aValue);
  Result := 1469598103934665603; // FNV-1a offset basis (64-bit)
  for LCh in LUpper do
  begin
    Result := Result xor UInt64(Ord(LCh));
    Result := Result * 1099511628211; // FNV-1a prime
  end;
end;

class function CaseInsensitiveEquals(const aLeft, aRight: UnicodeString; aData: Pointer): Boolean;
begin
  Result := SameText(aLeft, aRight);
end;

var
  Cache: TTestCache;
  LValue: Integer;
begin
  WriteLn('开始测试LRU泄漏...');
  
  Cache := TTestCache.Create(4, nil, @CaseInsensitiveHash, @CaseInsensitiveEquals);
  
  WriteLn('Put One');
  Cache.Put('One', 1);
  
  WriteLn('Put Two');
  Cache.Put('Two', 2);
  
  WriteLn('Get ONE: ', Cache.Get('ONE', LValue));
  
  WriteLn('Contains two: ', Cache.Contains('two'));
  
  WriteLn('Remove TWO: ', Cache.Remove('TWO'));
  
  WriteLn('Clear');
  Cache.Clear;
  
  WriteLn('Free');
  Cache.Free;
  
  WriteLn('测试完成');
end.
