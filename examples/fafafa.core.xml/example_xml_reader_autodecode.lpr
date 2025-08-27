{$CODEPAGE UTF8}
program example_xml_reader_autodecode;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils, Classes, fafafa.core.xml;

procedure ReadUTF16FileDemo(const APath: String);
var
  FS: TFileStream;
  R: IXmlReader;
begin
  FS := TFileStream.Create(APath, fmOpenRead or fmShareDenyNone);
  try
    R := CreateXmlReader.ReadFromStream(FS, [xrfIgnoreWhitespace, xrfAutoDecodeEncoding]);
    while R.Read do
    begin
      case R.Token of
        xtStartElement: Writeln('Start<', R.Name, '> attrs=', R.AttributeCount);
        xtText:         Writeln('Text: ', Copy(R.Value, 1, 40));
        xtEndElement:   Writeln('End</', R.Name, '>');
      end;
    end;
  finally
    FS.Free;
  end;
end;

var
  FilePath: String;
begin
  if ParamCount < 1 then
  begin
    Writeln('Usage: example_xml_reader_autodecode <utf16-or-utf32-xml-file>');
    Halt(1);
  end;
  FilePath := ParamStr(1);
  ReadUTF16FileDemo(FilePath);
end.

