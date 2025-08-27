{$CODEPAGE UTF8}
unit Test_fafafa_core_xml_reader_attr_entities_smallbuf;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.xml;

implementation

type
  TTestCase_Reader_Attr_Entities_SmallBuf = class(TTestCase)
  published
    procedure Test_Attr_Entity_CrossChunk_SmallBuf;
  end;

procedure TTestCase_Reader_Attr_Entities_SmallBuf.Test_Attr_Entity_CrossChunk_SmallBuf;
var
  S: AnsiString; MS: TMemoryStream; R: IXmlReader;
  V: String; Seen: Boolean = False;
begin
  // 在属性值中放置实体，并通过极小缓冲区强制跨块
  S := '<?xml version="1.0"?><root><e a="' + StringOfChar('X', 1024) + '&amp;' + StringOfChar('Y', 1024) + '"/></root>';
  MS := TMemoryStream.Create;
  try
    if Length(S) > 0 then MS.WriteBuffer(S[1], Length(S));
    MS.Position := 0;
    R := CreateXmlReader.ReadFromStream(MS, [xrfIgnoreWhitespace], 64);
    while R.Read do
      if (R.Token = xtStartElement) and (R.LocalName='e') then
      begin
        if R.TryGetAttribute('a', V) then
        begin
          Seen := True;
          AssertTrue('Attr should contain decoded &', Pos('&', V) > 0);
        end;
      end;
    AssertTrue('Should see element with attribute', Seen);
  finally
    MS.Free;
  end;
end;

initialization
  RegisterTest(TTestCase_Reader_Attr_Entities_SmallBuf);

end.

