program example_deduplicator;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}
{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}

uses
  SysUtils,
  fafafa.core.collections.base,
  fafafa.core.collections.hashset,
  fafafa.core.collections.vec;

type
  { 数据去重器 }
  TDataDeduplicator = class
  private
    FSeen: specialize IHashSet<string>;
    FUnique: specialize IVec<string>;
    FDuplicateCount: Integer;
  public
    constructor Create;
    procedure Process(const aItem: string);
    procedure PrintStats;
    procedure PrintUnique;
  end;

constructor TDataDeduplicator.Create;
begin
  FSeen := specialize MakeHashSet<string>();
  FUnique := specialize MakeVec<string>();
  FDuplicateCount := 0;
end;

procedure TDataDeduplicator.Process(const aItem: string);
begin
  if FSeen.Contains(aItem) then
  begin
    Inc(FDuplicateCount);
    WriteLn(Format('[重复] %s', [aItem]));
  end
  else
  begin
    FSeen.Add(aItem);
    FUnique.Append(aItem);
    WriteLn(Format('[新增] %s', [aItem]));
  end;
end;

procedure TDataDeduplicator.PrintStats;
begin
  WriteLn('--- 统计信息 ---');
  WriteLn(Format('  唯一项: %d', [FUnique.GetCount]));
  WriteLn(Format('  重复项: %d', [FDuplicateCount]));
  WriteLn(Format('  总处理: %d', [FUnique.GetCount + FDuplicateCount]));
end;

procedure TDataDeduplicator.PrintUnique;
var
  LItem: string;
  i: SizeUInt;
begin
  WriteLn('--- 去重后的数据 ---');
  i := 1;
  for LItem in FUnique do
  begin
    WriteLn(Format('  %d. %s', [i, LItem]));
    Inc(i);
  end;
end;

var
  LDedup: TDataDeduplicator;
  LInputData: array[0..11] of string = (
    'apple', 'banana', 'orange', 'apple',
    'grape', 'banana', 'kiwi', 'apple',
    'mango', 'orange', 'grape', 'peach'
  );
  LItem: string;
begin
  WriteLn('=== 数据去重器示例 ===');
  WriteLn;
  
  LDedup := TDataDeduplicator.Create;
  try
    WriteLn('--- 处理输入数据 ---');
    for LItem in LInputData do
      LDedup.Process(LItem);
    WriteLn;
    
    LDedup.PrintStats;
    WriteLn;
    
    LDedup.PrintUnique;
    WriteLn;
    
    WriteLn('=== 示例完成 ===');
    WriteLn('提示：HashSet 提供 O(1) 去重检测，适合大数据量去重场景');
  finally
    LDedup.Free;
  end;
end.

