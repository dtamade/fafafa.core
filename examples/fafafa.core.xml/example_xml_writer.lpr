{$CODEPAGE UTF8}
program example_xml_writer;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils, Classes, fafafa.core.xml;

procedure WriteDemo;
var
  W: IXmlWriter;
  S: String;
begin
  W := CreateXmlWriter;
  W.StartDocument('1.0', 'UTF-8');
  W.StartElementNS('', 'root', 'urn:demo');               // 默认命名空间
  W.WriteAttribute('version', '1.0');

  W.StartElementNS('ns1', 'item', 'urn:ns1');             // 带前缀命名空间
  W.WriteAttribute('ns1:attr', 'value & "quoted"');      // 带转义
  W.WriteString('hello');
  W.EndElement;                                           // </ns1:item>

  W.StartElement('empty');                                // <empty/>
  W.EndElement;

  W.EndDocument;

  // 输出（预期：文本与闭合标签同一行，无行首孤立 '>'）
  S := W.WriteToString([xwfPretty]);
  WriteLn(S);
end;

begin
  try
    WriteDemo;
  except
    on E: Exception do
    begin
      WriteLn('Error: ', E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.

