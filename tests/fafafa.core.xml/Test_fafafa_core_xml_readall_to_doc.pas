{$CODEPAGE UTF8}
unit Test_fafafa_core_xml_readall_to_doc;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.xml;

type
  TTestCase_ReadAllToDoc = class(TTestCase)
  published
    procedure Test_ReadAllToDocument_SimpleTree;
    procedure Test_ReadAllToDocument_Nested_Siblings;
  end;

implementation

procedure TTestCase_ReadAllToDoc.Test_ReadAllToDocument_SimpleTree;
var R: IXmlReader; D: IXmlDocument; Root, C1: IXmlNode;
begin
  R := CreateXmlReader.ReadFromString('<r><a/><b/></r>', [xrfIgnoreWhitespace]);
  D := XmlReadAllToDocument(R);
  AssertNotNull('document should not be nil', TObject(D));
  Root := D.Root;
  AssertEquals('r', Root.LocalName);
  AssertEquals(2, Root.ChildCount);
  C1 := Root.GetChild(0);
  AssertEquals('a', C1.LocalName);
  AssertEquals('b', Root.GetChild(1).LocalName);
end;

procedure TTestCase_ReadAllToDoc.Test_ReadAllToDocument_Nested_Siblings;
var R: IXmlReader; D: IXmlDocument; Root, A, B, C: IXmlNode;
begin
  R := CreateXmlReader.ReadFromString('<r><a><b/><c/></a></r>', [xrfIgnoreWhitespace]);
  D := XmlReadAllToDocument(R);
  Root := D.Root;
  A := Root.GetFirstChild;
  AssertEquals('a', A.LocalName);
  B := A.GetFirstChild;
  C := A.GetLastChild;
  AssertEquals('b', B.LocalName);
  AssertEquals('c', C.LocalName);
  AssertTrue('siblings linked', B.GetNextSibling <> nil);
  AssertTrue('siblings linked reverse', C.GetPreviousSibling <> nil);
end;

initialization
  if GetEnvironmentVariable('FAFAFA_TEST_SILENT_REG') <> '1' then
    Writeln('Registering TTestCase_ReadAllToDoc');
  RegisterTest(TTestCase_ReadAllToDoc);

end.

