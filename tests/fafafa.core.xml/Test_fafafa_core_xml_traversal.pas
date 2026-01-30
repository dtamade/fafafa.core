unit Test_fafafa_core_xml_traversal;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.xml;

Type
  TTestCase_Traversal = class(TTestCase)
  published
    procedure Test_Node_Traversal_Basics;
    procedure Test_Node_Traversal_Mixed_SelfClosing_Deep;
    procedure Test_Node_Traversal_Text_Ignored;
  end;


implementation

procedure TTestCase_Traversal.Test_Node_Traversal_Basics;
var
  R: IXmlReader;
  N, A, B, C, D: IXmlNode;
  Xml: string;
  openCount: SizeInt;
  guard: SizeInt;
begin
  Xml := '<root><a/><b/><c><d/></c></root>';
  R := CreateXmlReader.ReadFromString(Xml);
  // 构建：遇到第一个 StartElement 冻结为 root，然后只冻结其子树，直到配对的根结束标签
  AssertTrue('expect first StartElement', R.Read);
  AssertEquals('token is start', Ord(xtStartElement), Ord(R.Token));
  N := R.FreezeCurrentNode; // root
  // 计入已遇到的未闭合元素数量（root 已经 +1）
  openCount := 1;
  guard := 0;
  while (openCount > 0) and R.Read do
  begin
    if R.Token = xtStartElement then
    begin
      R.FreezeCurrentNode;
      Inc(openCount);
    end
    else if R.Token = xtEndElement then
      Dec(openCount)
    else if R.Token = xtEndDocument then
      Break; // 防御：异常输入时避免死循环
    Inc(guard);
    if guard > 10000 then Fail('Traversal guard triggered');
  end;
  AssertTrue('root not nil', N<>nil);
  AssertEquals('root name', 'root', N.Name);

  // 子节点计数
  AssertEquals('root child count', 3, N.GetChildCount);
  AssertTrue('root has children', N.HasChildNodes);

  // FirstChild/LastChild
  A := N.FirstChild; AssertTrue('A not nil', A<>nil); AssertEquals('A name', 'a', A.Name);
  C := N.LastChild;  AssertTrue('C not nil', C<>nil); AssertEquals('C name', 'c', C.Name);
  // NextSibling/PreviousSibling 链
  B := A.NextSibling; AssertTrue('B not nil', B<>nil); AssertEquals('B name', 'b', B.Name);
  AssertTrue('A.PreviousSibling=nil', A.PreviousSibling=nil);
  AssertEquals('B.PreviousSibling=a', 'a', B.PreviousSibling.Name);
  AssertEquals('B.NextSibling=c', 'c', B.NextSibling.Name);
  AssertEquals('C.PreviousSibling=b', 'b', C.PreviousSibling.Name);
  AssertTrue('C.NextSibling=nil', C.NextSibling=nil);

  // Parent
  AssertEquals('A.Parent=root', 'root', A.Parent.Name);
  AssertEquals('B.Parent=root', 'root', B.Parent.Name);
  AssertEquals('C.Parent=root', 'root', C.Parent.Name);

  // C 的子节点 d
  AssertTrue('C has child', C.HasChildNodes);
  AssertEquals('C child count', 1, C.GetChildCount);
  D := C.FirstChild; AssertTrue('D not nil', D<>nil); AssertEquals('D name', 'd', D.Name);
  AssertEquals('D.Parent=c', 'c', D.Parent.Name);
  AssertTrue('D has no children', not D.HasChildNodes);
  AssertEquals('D child count=0', 0, D.GetChildCount);
  AssertTrue('D.NextSibling=nil', D.NextSibling=nil);
  AssertTrue('D.PreviousSibling=nil', D.PreviousSibling=nil);


end;

procedure TTestCase_Traversal.Test_Node_Traversal_Mixed_SelfClosing_Deep;
var R: IXmlReader; Root, N1, N2, N3, X, Y, Z: IXmlNode; Xml: string; openCount, guard: SizeInt;
begin
  Xml := '<root><n1><x/><y><z/></y></n1><n2/><n3><x/></n3></root>';
  R := CreateXmlReader.ReadFromString(Xml);
  AssertTrue(R.Read);
  Root := R.FreezeCurrentNode;
  openCount := 1; guard := 0;
  while (openCount>0) and R.Read do
  begin
    if R.Token=xtStartElement then begin R.FreezeCurrentNode; Inc(openCount); end
    else if R.Token=xtEndElement then Dec(openCount);
    Inc(guard); if guard>10000 then Fail('guard');
  end;
  AssertEquals('root', 'root', Root.Name);
  // 三个孩子：n1, n2, n3
  AssertEquals('root child count', 3, Root.GetChildCount);
  N1 := Root.FirstChild; AssertEquals('n1', 'n1', N1.Name);
  N2 := N1.NextSibling; AssertEquals('n2', 'n2', N2.Name);
  N3 := N2.NextSibling; AssertEquals('n3', 'n3', N3.Name);
  AssertTrue(N3.NextSibling=nil);
  // n2 自闭合，无子
  AssertFalse(N2.HasChildNodes);
  AssertEquals(0, N2.GetChildCount);
  // n1: x(自闭合), y(含 z)
  AssertEquals(2, N1.GetChildCount);
  X := N1.FirstChild; AssertEquals('x', 'x', X.Name);
  Y := X.NextSibling; AssertEquals('y', 'y', Y.Name);
  AssertTrue(X.NextSibling<>nil);
  AssertTrue(X.PreviousSibling=nil);
  AssertEquals('n1', X.Parent.Name);
  AssertTrue(Y.HasChildNodes);
  Z := Y.FirstChild; AssertEquals('z', 'z', Z.Name);
  AssertTrue(Z.NextSibling=nil);
  AssertEquals('y', Z.Parent.Name);
  // n3: x
  AssertEquals(1, N3.GetChildCount);

  AssertEquals('x', N3.FirstChild.Name);
  AssertEquals('n3', N3.FirstChild.Parent.Name);
end;

procedure TTestCase_Traversal.Test_Node_Traversal_Text_Ignored;
var R: IXmlReader; Root, A: IXmlNode; Xml: string; openCount, guard: SizeInt;
begin
  // 文本节点不构成结构子节点
  Xml := '<root>t<a/>b</root>';
  R := CreateXmlReader.ReadFromString(Xml);
  AssertTrue(R.Read);
  Root := R.FreezeCurrentNode;
  openCount := 1; guard := 0;
  while (openCount>0) and R.Read do
  begin
    case R.Token of
      xtStartElement: begin R.FreezeCurrentNode; Inc(openCount); end;
      xtEndElement: Dec(openCount);
    end;
    Inc(guard); if guard>10000 then Fail('guard');
  end;
  AssertEquals('root', 'root', Root.Name);
  AssertEquals('only element children counted', 1, Root.GetChildCount);
  A := Root.FirstChild; AssertEquals('a', 'a', A.Name);
  AssertTrue(A.PreviousSibling=nil);
  AssertTrue(A.NextSibling=nil);
end;



initialization
  RegisterTest(TTestCase_Traversal);

end.

