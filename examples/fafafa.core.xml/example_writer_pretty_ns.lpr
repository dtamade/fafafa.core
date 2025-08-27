{$CODEPAGE UTF8}
program example_writer_pretty_ns;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils, Classes, fafafa.core.xml;

procedure Demo_Pretty_NS;
var W: IXmlWriter; S: String;
begin
  W := CreateXmlWriter;
  W.StartDocument('1.0','UTF-8');

  // 默认命名空间根
  W.StartElementNS('', 'root', 'urn:x');
  W.WriteAttribute('version', '1.0');

  // 子元素：同默认命名空间
  W.StartElementNS('', 'child', 'urn:x');
  W.EndElement;

  // 子元素：带前缀命名空间 + 属性命名空间
  W.StartElementNS('p', 'node', 'urn:y');
  W.WriteAttributeNS('p', 'k', 'urn:y', 'v');
  W.EndElement;

  // 注释与 PI
  W.WriteComment('pretty + ns demo');
  W.WritePI('pi','a=1');

  W.EndElement; // </root>
  W.EndDocument;

  S := W.WriteToString([xwfPretty]);
  WriteLn(S);
end;

begin
  try
    Demo_Pretty_NS;
  except
    on E: Exception do
    begin
      WriteLn('Error: ', E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.

