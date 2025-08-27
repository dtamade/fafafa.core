{$CODEPAGE UTF8}
unit Test_fafafa_core_xml_reader_entities;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.xml;

type
  TTestCase_Reader_Entities = class(TTestCase)
  published
    procedure Test_Decode_Text_And_Attr;
    procedure Test_Line_Column;
  end;

implementation

procedure TTestCase_Reader_Entities.Test_Decode_Text_And_Attr;
var R: IXmlReader; V: String;
begin
  R := CreateXmlReader.ReadFromString('<a k="&quot;v&apos;&quot;">x&lt;y&amp;z&gt;</a>');
  while R.Read do
    if R.Token = xtStartElement then
    begin
      AssertTrue(R.TryGetAttribute('k', V));
      AssertEquals('"v''"', V);
    end
    else if R.Token = xtText then
    begin
      AssertEquals('x<y&z>', R.Value);
    end;
end;

procedure TTestCase_Reader_Entities.Test_Line_Column;
var R: IXmlReader; L, C: SizeUInt;
begin
  R := CreateXmlReader.ReadFromString(#10#10'<a>'#10'  x'#10'</a>');
  while R.Read do
    if R.Token = xtText then
    begin
      L := R.Line; C := R.Column;
      AssertEquals(4, L);
      AssertTrue(C >= 3);
    end;
end;

initialization
  RegisterTest(TTestCase_Reader_Entities);

end.

