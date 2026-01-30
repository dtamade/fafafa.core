{$CODEPAGE UTF8}
program example_xml_reader;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils, Classes, fafafa.core.xml;

procedure ReadFromStringDemo;
const
  Sample = '<?xml version="1.0"?><root xmlns="urn:demo" xmlns:ns1="urn:ns1">' +
           '<item id="1">hello &amp; world</item>' +
           '<ns1:item id="2" ns1:attr="v">text<![CDATA[ cdata ]]><!-- com --></ns1:item>' +
           '<empty/>' +
           '</root>';
var
  R: IXmlReader;
  Depth: SizeUInt;
  P: PChar; L: SizeUInt;
  CountItems: SizeInt = 0;
begin
  R := CreateXmlReader.ReadFromString(Sample, [xrfIgnoreWhitespace, xrfIgnoreComments]);
  while R.Read do
  begin
    case R.Token of
      xtStartElement:
        begin
          Inc(CountItems, Ord(R.LocalName = 'item'));
          if R.GetNameN(P, L) then
            WriteLn('Start<', Copy(R.Name, 1, Length(R.Name)), '> attrCount=', R.AttributeCount);
        end;
      xtEndElement:
        WriteLn('End</', R.Name, '>');
      xtText:
        if R.GetValueN(P, L) and (L > 0) then
          WriteLn('Text="', R.Value, '"');
      xtCData:
        WriteLn('CDATA="', R.Value, '"');
      xtPI:
        WriteLn('PI target/data: ', R.Name, ' / ', R.Value);
    end;
    Depth := R.Depth;
  end;
  WriteLn('Total <item> count = ', CountItems);
end;

begin
  try
    ReadFromStringDemo;
  except
    on E: Exception do
    begin
      WriteLn('Error: ', E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.

