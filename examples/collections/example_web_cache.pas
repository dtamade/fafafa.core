program example_web_cache;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}
{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}

uses
  SysUtils,
  fafafa.core.collections.base,
  fafafa.core.collections.linkedhashmap;

type
  { LRU Web 缓存实现 }
  TWebCache = class
  private
    FCache: specialize ILinkedHashMap<string, string>;
    FMaxSize: SizeUInt;
    procedure EvictOldest;
  public
    constructor Create(aMaxSize: SizeUInt);
    procedure Put(const aURL: string; const aContent: string);
    function TryGet(const aURL: string; out aContent: string): Boolean;
    procedure PrintStats;
  end;

constructor TWebCache.Create(aMaxSize: SizeUInt);
begin
  FMaxSize := aMaxSize;
  FCache := specialize MakeLinkedHashMap<string, string>(aMaxSize);
end;

procedure TWebCache.EvictOldest;
var
  LFirst: specialize TPair<string, string>;
begin
  if FCache.GetCount >= FMaxSize then
  begin
    LFirst := FCache.First;
    WriteLn('[淘汰] ', LFirst.Key);
    FCache.Remove(LFirst.Key);
  end;
end;

procedure TWebCache.Put(const aURL: string; const aContent: string);
begin
  if FCache.ContainsKey(aURL) then
    FCache.Remove(aURL); // 更新时先删除（移到尾部）
  
  EvictOldest;
  FCache.Add(aURL, aContent);
  WriteLn('[缓存] ', aURL, ' (大小: ', Length(aContent), ' 字节)');
end;

function TWebCache.TryGet(const aURL: string; out aContent: string): Boolean;
begin
  Result := FCache.TryGetValue(aURL, aContent);
  if Result then
  begin
    WriteLn('[命中] ', aURL);
    // LRU 策略：访问时移到尾部
    FCache.Remove(aURL);
    FCache.Add(aURL, aContent);
  end
  else
    WriteLn('[未命中] ', aURL);
end;

procedure TWebCache.PrintStats;
begin
  WriteLn('--- 缓存状态 ---');
  WriteLn('当前条目: ', FCache.GetCount, '/', FMaxSize);
end;

var
  LCache: TWebCache;
  LContent: string;
begin
  WriteLn('=== Web 缓存示例（LRU 策略）===');
  WriteLn;
  
  LCache := TWebCache.Create(3); // 最多缓存3个页面
  try
    // 场景1：缓存页面
    WriteLn('--- 场景1：缓存3个页面 ---');
    LCache.Put('/index.html', '<html>Home Page</html>');
    LCache.Put('/about.html', '<html>About Us</html>');
    LCache.Put('/contact.html', '<html>Contact</html>');
    WriteLn;
    
    LCache.PrintStats;
    WriteLn;
    
    // 场景2：访问已缓存页面（命中）
    WriteLn('--- 场景2：访问已缓存页面 ---');
    if LCache.TryGet('/about.html', LContent) then
      WriteLn('内容: ', LContent);
    WriteLn;
    
    // 场景3：缓存第4个页面（淘汰最久未使用的 /index.html）
    WriteLn('--- 场景3：缓存新页面（触发淘汰）---');
    LCache.Put('/products.html', '<html>Products</html>');
    WriteLn;
    
    LCache.PrintStats;
    WriteLn;
    
    // 场景4：访问已淘汰页面（未命中）
    WriteLn('--- 场景4：访问已淘汰页面 ---');
    if not LCache.TryGet('/index.html', LContent) then
      WriteLn('页面已被淘汰，需要重新加载');
    WriteLn;
    
    WriteLn('=== 示例完成 ===');
  finally
    LCache.Free;
  end;
end.

