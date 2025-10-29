program example_word_counter;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}
{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}

uses
  SysUtils,
  fafafa.core.collections.base,
  fafafa.core.collections.hashmap,
  fafafa.core.collections.vec;

type
  TWordCount = record
    Word: string;
    Count: Integer;
  end;

{ 单词统计器 }
procedure CountWords(const aText: string);
var
  LWords: TStringArray;
  LWord: string;
  LCounts: specialize IHashMap<string, Integer>;
  LCount: Integer;
  LPair: specialize TPair<string, Integer>;
  LTopWords: specialize IVec<TWordCount>;
  LWordCount: TWordCount;
  i, j: SizeUInt;
begin
  WriteLn('--- 统计单词频率 ---');
  
  // 分词（简单按空格分割）
  LWords := aText.Split([' ', ',', '.', '!', '?', ';', ':']);
  LCounts := specialize MakeHashMap<string, Integer>();
  
  // 计数
  for LWord in LWords do
  begin
    LWord := LowerCase(Trim(LWord));
    if LWord = '' then Continue;
    
    if LCounts.TryGetValue(LWord, LCount) then
      LCounts.AddOrAssign(LWord, LCount + 1)
    else
      LCounts.Add(LWord, 1);
  end;
  
  WriteLn(Format('总单词数: %d', [Length(LWords)]));
  WriteLn(Format('不同单词: %d', [LCounts.GetCount]));
  WriteLn;
  
  // 转换为数组并排序
  WriteLn('--- 词频统计（前5名）---');
  LTopWords := specialize MakeVec<TWordCount>();
  for LPair in LCounts do
  begin
    LWordCount.Word := LPair.Key;
    LWordCount.Count := LPair.Value;
    LTopWords.Append(LWordCount);
  end;
  
  // 冒泡排序（按出现次数降序）
  for i := 0 to LTopWords.GetCount - 1 do
    for j := i + 1 to LTopWords.GetCount - 1 do
      if LTopWords[j].Count > LTopWords[i].Count then
      begin
        LWordCount := LTopWords[i];
        LTopWords[i] := LTopWords[j];
        LTopWords[j] := LWordCount;
      end;
  
  // 打印前5名
  for i := 0 to Min(4, LTopWords.GetCount - 1) do
    WriteLn(Format('  %d. "%s" 出现 %d 次', [
      i + 1,
      LTopWords[i].Word,
      LTopWords[i].Count
    ]));
end;

const
  SAMPLE_TEXT = 
    'The quick brown fox jumps over the lazy dog. ' +
    'The dog was really lazy, and the fox was extremely quick. ' +
    'Quick brown animals are fascinating. ' +
    'The lazy dog slept while the quick fox ran.';

begin
  WriteLn('=== 单词统计器示例 ===');
  WriteLn;
  
  WriteLn('--- 输入文本 ---');
  WriteLn(SAMPLE_TEXT);
  WriteLn;
  
  CountWords(SAMPLE_TEXT);
  WriteLn;
  
  WriteLn('=== 示例完成 ===');
  WriteLn('提示：HashMap 非常适合计数和频率统计场景');
end.

