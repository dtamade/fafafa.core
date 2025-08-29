program debug_search;
{$mode objfpc}
uses fafafa.core.simd;

var
  hay, ned: array of Byte;
  i, idx: Integer;
begin
  // 简单测试：在小数组中搜索
  SetLength(hay, 100);
  SetLength(ned, 4);
  
  // 填充干草堆
  for i := 0 to 99 do
    hay[i] := Byte(i mod 10);
    
  // 创建针：[5,6,7,8]
  ned[0] := 5; ned[1] := 6; ned[2] := 7; ned[3] := 8;
  
  // 在位置20放置针
  hay[20] := 5; hay[21] := 6; hay[22] := 7; hay[23] := 8;
  
  writeln('Haystack around position 20: ', hay[18], ' ', hay[19], ' ', hay[20], ' ', hay[21], ' ', hay[22], ' ', hay[23], ' ', hay[24], ' ', hay[25]);
  writeln('Needle: ', ned[0], ' ', ned[1], ' ', ned[2], ' ', ned[3]);
  
  idx := BytesIndexOf(@hay[0], Length(hay), @ned[0], Length(ned));
  writeln('Found at: ', idx);
  
  if idx = 20 then
    writeln('SUCCESS')
  else
    writeln('FAILED - expected 20, got ', idx);
end.
