{$CODEPAGE UTF8}
unit Test_fafafa_core_xml;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.xml;

type
  TTestCase_Global = class(TTestCase)
  published
    procedure Test_CreateReader;
    procedure Test_CreateWriter;
  end;

implementation

procedure TTestCase_Global.Test_CreateReader;
var R: IXmlReader;
begin
  R := CreateXmlReader;
  AssertTrue('Reader created', R <> nil);
end;

procedure TTestCase_Global.Test_CreateWriter;
var W: IXmlWriter; S: String;
begin
  W := CreateXmlWriter;
  AssertTrue('Writer created', W <> nil);
  W.StartDocument;
  W.StartElement('root');
  W.WriteAttribute('k','v');
  W.WriteString('x');
  W.EndElement;
  S := W.WriteToString([xwfPretty]);
  AssertTrue('WriteToString not empty', Length(S) > 0);
  AssertTrue('Contains root element', Pos('<root', S) > 0);
  AssertTrue('Contains attribute', Pos('k="v"', S) > 0);
  AssertTrue('Contains text', Pos('>x</root>', S) > 0);
end;

initialization
  RegisterTest(TTestCase_Global);

end.

