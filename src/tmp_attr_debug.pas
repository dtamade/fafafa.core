program tmp_attr_debug;
{$mode objfpc}{$H+}
uses SysUtils, Classes, fafafa.core.xml;
var
  S: AnsiString;
  MS: TMemoryStream;
  R: IXmlReader;
  V: String;
begin
  S := '<?xml version="1.0"?><root><e a="' + StringOfChar('X', 1024) + '&amp;' + StringOfChar('Y', 1024) + '"/></root>';
  MS := TMemoryStream.Create;
  try
    if Length(S) > 0 then MS.WriteBuffer(S[1], Length(S));
    MS.Position := 0;
    R := CreateXmlReader.ReadFromStream(MS, [xrfIgnoreWhitespace], 64);
    while R.Read do
    begin
      if (R.Token = xtStartElement) then
      begin
        WriteLn('StartElement: name=', R.LocalName, ' empty=', R.EmptyElement, ' attrs=', R.AttributeCount);
        if (R.LocalName='e') then
        begin
          if R.TryGetAttribute('a', V) then
            WriteLn('Attr a found, len=', Length(V), ' hasAmp=', Pos('&', V)>0)
          else
            WriteLn('Attr a NOT found');
        end;
      end
      else if R.Token = xtText then
      begin
        WriteLn('Text len=', Length(R.Value));
      end;
    end;
  finally
    MS.Free;
  end;
end.

