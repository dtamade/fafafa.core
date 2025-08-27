program minitest_search_edges;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.simd;

procedure AssertTrue(cond: Boolean; const msg: string);
begin
  if not cond then begin Writeln('FAIL: ', msg); Halt(1); end;
end;

procedure TestEdgePositions;
var
  hay, ned: TBytes; idx: PtrInt;
begin
  // needle at head
  hay := TBytes('abcde'); ned := TBytes('ab');
  idx := BytesIndexOf(@hay[0], Length(hay), @ned[0], Length(ned));
  AssertTrue(idx=0, 'head match');
  // needle at tail
  hay := TBytes('abcde'); ned := TBytes('de');
  idx := BytesIndexOf(@hay[0], Length(hay), @ned[0], Length(ned));
  AssertTrue(idx=3, 'tail match');
end;

procedure TestRepeatedChars;
var
  hay, ned: TBytes; idx: PtrInt;
begin
  hay := TBytes('AAAAAAAABAAAA'); ned := TBytes('AAAAA');
  idx := BytesIndexOf(@hay[0], Length(hay), @ned[0], Length(ned));
  AssertTrue(idx=0, 'repeat chars first');
  hay := TBytes('BAAAAAAAABAAA');
  idx := BytesIndexOf(@hay[0], Length(hay), @ned[0], Length(ned));
  AssertTrue(idx=1, 'repeat chars second');
end;

begin
  TestEdgePositions;
  TestRepeatedChars;
  Writeln('OK: minitest_search_edges passed.');
end.

