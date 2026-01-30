unit Test_Xml_Strict;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.base;

type
  TTestXmlStrict = class(TTestCase)
  published
    procedure Test_Strip_Invalid_XML10;
    procedure Test_Preserve_Valid_Control_Whitespace;
  end;

implementation

procedure TTestXmlStrict.Test_Strip_Invalid_XML10;
var
  S, R: string;
begin
  // includes invalid XML 1.0 chars: #0..#8, #11, #12, #14..#31
  S := #0#1#2#3#4#5#6#7#8 + 'A' + #11 + #12 + 'B' + #14#15#16#17#18#19#20#21#22#23#24#25#26#27#28#29#30#31 + 'C';
  R := XmlEscapeXML10Strict(S);
  AssertEquals('ABC', R);
end;

procedure TTestXmlStrict.Test_Preserve_Valid_Control_Whitespace;
var
  S, R: string;
begin
  // Tab, LF, CR should be preserved
  S := 'A' + #9 + 'B' + #10 + 'C' + #13 + 'D' + '&<>';
  R := XmlEscapeXML10Strict(S);
  AssertEquals('A'#9'B'#10'C'#13'D&amp;&lt;&gt;', R);
end;

initialization
  RegisterTest(TTestXmlStrict);
end.

