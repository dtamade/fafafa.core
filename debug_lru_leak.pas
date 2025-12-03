program debug_lru_leak;
{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.collections.lrucache,
  fafafa.core.mem.allocator;

type
  TCountingInterface = class(TInterfacedObject)
  public
    class var Alive: Integer;
    constructor Create;
    destructor Destroy; override;
  end;

constructor TCountingInterface.Create;
begin
  inherited Create;
  Inc(Alive);
  WriteLn('Created, total: ', Alive);
end;

destructor TCountingInterface.Destroy;
begin
  Dec(Alive);
  WriteLn('Destroyed, total: ', Alive);
  inherited Destroy;
end;

var
  Cache: specialize ILruCache<Integer, IInterface>;
  Obj: TCountingInterface;
  Intf: IInterface;
begin
  TCountingInterface.Alive := 0;
  
  WriteLn('=== 创建对象 ===');
  Obj := TCountingInterface.Create;
  
  WriteLn('=== 创建Cache ===');
  Cache := specialize TLruCache<Integer, IInterface>.Create(8);
  
  WriteLn('=== 插入到Cache ===');
  Intf := Obj as IInterface;
  Cache.Put(1, Intf);
  Intf := nil; // 释放本地接口引用
  
  WriteLn('=== 释放本地对象引用 ===');
  Obj := nil;
  
  WriteLn('=== Cache.Clear ===');
  Cache.Clear;
  
  WriteLn('=== 释放Cache ===');
  Cache := nil;
  
  WriteLn('=== 最终状态 ===');
  WriteLn('Alive: ', TCountingInterface.Alive);
  
  if TCountingInterface.Alive = 0 then
    WriteLn('✅ 成功：没有内存泄漏')
  else
    WriteLn('❌ 失败：还有 ', TCountingInterface.Alive, ' 个泄漏');
end.
