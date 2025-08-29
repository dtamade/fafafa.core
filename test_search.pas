program test_search;
uses fafafa.core.simd;
var
  hay, ned: array of Byte;
  i: Integer;
  idx: PtrInt;
begin
  SetLength(hay, 2048);
  SetLength(ned, 64);
  
  // Fill haystack with pattern
  for i := 0 to 2047 do
    hay[i] := Byte(i mod 256);
    
  // Create needle pattern  
  for i := 0 to 63 do
    ned[i] := Byte((i + 100) mod 256);
    
  // Place needle at position 500
  for i := 0 to 63 do
    hay[500 + i] := ned[i];
    
  idx := BytesIndexOf(@hay[0], Length(hay), @ned[0], Length(ned));
  writeln(Found at: , idx);
  if idx = 500 then
    writeln(SUCCESS)
  else
    writeln(FAILED);
end.
