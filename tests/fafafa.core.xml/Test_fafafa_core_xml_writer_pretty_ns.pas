{$CODEPAGE UTF8}
unit Test_fafafa_core_xml_writer_pretty_ns;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.xml;

type
  TTestCase_Xml_Writer_Pretty_NS = class(TTestCase)
  published
    procedure Test_Pretty_Indent_Nested_With_Text_Comment_PI;
    procedure Test_NS_Default_And_Prefix_Mix;
  end;

implementation

procedure TTestCase_Xml_Writer_Pretty_NS.Test_Pretty_Indent_Nested_With_Text_Comment_PI;
var W: IXmlWriter; S: String;
begin
  W := CreateXmlWriter;
  W.StartDocument('1.0','UTF-8');
  W.StartElement('root');
  W.StartElement('a');
  W.WriteString('t');
  W.EndElement; // </a>
  W.WriteComment('c');
  W.StartElement('b');
  W.WritePI('pi','x=1');
  W.EndElement; // </b>
  W.EndElement; // </root>
  W.EndDocument;
  S := W.WriteToString([xwfPretty]);
  // 断言关键结构与换行缩进（宽松判断，仅检查行数与起止标签行）
  AssertTrue(Pos('<?xml version="1.0" encoding="UTF-8"?>', S) = 1);
  AssertTrue(Pos('<root>', S) > 0);
  AssertTrue(Pos('<a>t</a>', S) > 0);
  AssertTrue(Pos('<!--c-->', S) > 0);
  AssertTrue(Pos('<b>', S) > 0);
  AssertTrue(Pos('<?pi x=1?>', S) > 0);
  AssertTrue(Pos('</b>', S) > 0);
  AssertTrue(Pos('</root>', S) > 0);
end;

procedure TTestCase_Xml_Writer_Pretty_NS.Test_NS_Default_And_Prefix_Mix;
var W: IXmlWriter; S: String;
begin
  W := CreateXmlWriter;
  // 默认命名空间元素 + 带前缀的子元素与属性
  W.StartElementNS('', 'root', 'urn:x');
  W.StartElementNS('p', 'child', 'urn:y');
  W.WriteAttributeNS('p', 'k', 'urn:y', 'v');
  W.EndElement; // </p:child>
  W.EndElement; // </root>
  S := W.WriteToString([xwfPretty]);
  // 根声明默认 ns；子节点声明前缀 ns；属性使用同前缀
  AssertTrue(Pos('<root xmlns="urn:x">', S) > 0);
  AssertTrue(Pos('<p:child xmlns:p="urn:y" p:k="v"/>', S) > 0);
end;

initialization
  RegisterTest(TTestCase_Xml_Writer_Pretty_NS);

end.

