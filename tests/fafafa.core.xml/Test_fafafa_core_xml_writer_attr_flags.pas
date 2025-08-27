{$CODEPAGE UTF8}
unit Test_fafafa_core_xml_writer_attr_flags;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.xml;

type
  TTestCase_Xml_Writer_Attr_Flags = class(TTestCase)
  published
    procedure Test_Attr_Sort;
    procedure Test_Attr_Dedup_KeepLast;
    procedure Test_Attr_Sort_Dedup_Combined;
  end;

implementation

procedure TTestCase_Xml_Writer_Attr_Flags.Test_Attr_Sort;
var W: IXmlWriter; S, E: String;
begin
  W := CreateXmlWriter;
  W.StartElement('root');
  W.WriteAttribute('b','2');
  W.WriteAttribute('a','1');
  W.EndElement;
  S := W.WriteToString([xwfPretty, xwfSortAttrs]);
  E := '<root'+LineEnding+ // pretty 会把开头的 <root 放在第一行，不加 XML 声明
       '  a="1" b="2"/>'+LineEnding+
       '</root>';
  // 由于现有 Pretty 行为不会把属性换行，直接断言排序后输出片段
  S := W.WriteToString([xwfSortAttrs]);
  AssertTrue(Pos('<root a="1" b="2"/>', S) > 0);
end;

procedure TTestCase_Xml_Writer_Attr_Flags.Test_Attr_Dedup_KeepLast;
var W: IXmlWriter; S: String;
begin
  W := CreateXmlWriter;
  W.StartElement('root');
  W.WriteAttribute('a','1');
  W.WriteAttribute('a','2');
  W.EndElement;
  S := W.WriteToString([xwfDedupAttrs]);
  AssertTrue(Pos('<root a="2"/>', S) > 0);
end;

procedure TTestCase_Xml_Writer_Attr_Flags.Test_Attr_Sort_Dedup_Combined;
var W: IXmlWriter; S: String;
begin
  W := CreateXmlWriter;
  W.StartElement('root');
  W.WriteAttribute('b','2');
  W.WriteAttribute('a','1');
  W.WriteAttribute('a','3');
  W.EndElement;
  S := W.WriteToString([xwfSortAttrs, xwfDedupAttrs]);
  // 去重保留最后的 a=3，再排序 => a,b
  AssertTrue(Pos('<root a="3" b="2"/>', S) > 0);
end;

initialization
  RegisterTest(TTestCase_Xml_Writer_Attr_Flags);

end.

