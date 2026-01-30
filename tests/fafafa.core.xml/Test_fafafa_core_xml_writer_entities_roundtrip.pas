{$CODEPAGE UTF8}
unit Test_fafafa_core_xml_writer_entities_roundtrip;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.xml;

implementation

type
  TTestCase_Writer_Entities_Roundtrip = class(TTestCase)
  published
    procedure Test_Writer_Text_Roundtrip_MixedEntities_SmallBuf;
  end;

procedure TTestCase_Writer_Entities_Roundtrip.Test_Writer_Text_Roundtrip_MixedEntities_SmallBuf;
var
  W: IXmlWriter;
  Xml: String;
  Orig, Combined: AnsiString;
  MS: TMemoryStream;
  R: IXmlReader; Tok: TXmlToken;
begin
  // 原始文本包含特殊字符与非 ASCII（确保 writer 正确转义，reader 解回原文）
  Orig := 'x & < > " '' ' + UTF8Encode('🙂你');

  W := CreateXmlWriter;
  W.Reset;
  W.StartElement('root');
  W.WriteString(String(Orig));
  W.EndElement;
  Xml := W.WriteToString;

  // 读回并比较值
  MS := TMemoryStream.Create;
  try
    if Length(Xml)>0 then MS.WriteBuffer(Xml[1], Length(Xml));
    MS.Position := 0;
    R := CreateXmlReader.ReadFromStream(MS, [xrfIgnoreWhitespace], 64);
    Combined := '';
    while R.Read do if R.Token = xtText then Combined += AnsiString(R.Value);
    AssertEquals('Roundtrip text should match', Orig, Combined);
  finally
    MS.Free;
  end;
end;

initialization
  RegisterTest(TTestCase_Writer_Entities_Roundtrip);

end.

