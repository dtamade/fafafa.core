program test_lrucache_leak_debug;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils, Classes,
  fafafa.core.collections.lrucache;

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
  Writeln('TCountingInterface.Create, Alive: ', Alive);
end;

destructor TCountingInterface.Destroy;
begin
  Dec(Alive);
  Writeln('TCountingInterface.Destroy, Alive: ', Alive);
  inherited Destroy;
end;

var
  Cache: specialize ILruCache<Integer, IInterface>;
  I: IInterface;
begin
  TCountingInterface.Alive := 0;
  
  // 创建缓存
  Cache := specialize TLruCache<Integer, IInterface>.Create(4);
  Writeln('Cache created, Alive: ', TCountingInterface.Alive);
  
  // 添加一个接口
  I := TCountingInterface.Create as IInterface;
  Writeln('Interface created, Alive: ', TCountingInterface.Alive);
  
  Cache.Put(1, I);
  Writeln('Interface added to cache, Alive: ', TCountingInterface.Alive);
  
  // 清除缓存
  Cache.Clear;
  Writeln('Cache cleared, Alive: ', TCountingInterface.Alive);
  
  // 释放缓存
  Cache := nil;
  Writeln('Cache released, Alive: ', TCountingInterface.Alive);
  
  // 释放接口引用
  I := nil;
  Writeln('Interface reference released, Alive: ', TCountingInterface.Alive);
  
  Writeln('Final Alive: ', TCountingInterface.Alive);
  if TCountingInterface.Alive <> 0 then
    Writeln('MEMORY LEAK DETECTED!')
  else
    Writeln('No memory leak');
end.
