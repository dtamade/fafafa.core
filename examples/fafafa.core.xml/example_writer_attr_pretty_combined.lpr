{$CODEPAGE UTF8}
program example_writer_attr_pretty_combined;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils, Classes, fafafa.core.xml;

procedure Demo;
var W: IXmlWriter; S: String;
begin
  W := CreateXmlWriter;
  W.StartDocument('1.0','UTF-8');

  W.StartElement('root');
  // 重名属性，后者应覆盖前者；混入不同属性以便观察排序
  W.WriteAttribute('b','2');
  W.WriteAttribute('a','1');
  W.WriteAttribute('b','3'); // keep-last for b

  // 子元素：自闭合 + 属性
  W.StartElement('child');
  W.WriteAttribute('z','9');
  W.WriteAttribute('y','8');
  W.EndElement; // <child .../>

  W.EndElement; // </root>
  W.EndDocument;

  S := W.WriteToString([xwfPretty, xwfSortAttrs, xwfDedupAttrs]);
  WriteLn(S);
end;

begin
  Demo;
end.

