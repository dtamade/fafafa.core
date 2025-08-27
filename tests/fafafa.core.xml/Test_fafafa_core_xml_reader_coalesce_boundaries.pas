{$CODEPAGE UTF8}
unit Test_fafafa_core_xml_reader_coalesce_boundaries;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.xml;

type
  TTestCase_Reader_Coalesce_Boundaries = class(TTestCase)
  published
    procedure Test_Text_Comment_Text_Not_Merged_Even_IgnoreComments;
    procedure Test_Text_PI_CDATA_Not_Merged;
    procedure Test_Stream_SmallBuf_Text_CDATA_Merged_All;
  end;

implementation

procedure TTestCase_Reader_Coalesce_Boundaries.Test_Text_Comment_Text_Not_Merged_Even_IgnoreComments;
var R: IXmlReader; texts: array of String; cnt: Integer;
begin
  R := CreateXmlReader.ReadFromString('<r>a<!--c-->b</r>', [xrfCoalesceText, xrfIgnoreWhitespace, xrfIgnoreComments]);
  cnt := 0;
  while R.Read do
    if R.Token = xtText then
    begin
      SetLength(texts, cnt+1);
      texts[cnt] := R.Value;
      Inc(cnt);
    end;
  AssertEquals('should have two text tokens', 2, cnt);
  AssertEquals('a', texts[0]);
  AssertEquals('b', texts[1]);
end;

procedure TTestCase_Reader_Coalesce_Boundaries.Test_Text_PI_CDATA_Not_Merged;
var R: IXmlReader; vals: array of String; cnt: Integer;
begin
  R := CreateXmlReader.ReadFromString('<r>a<?p x?><![CDATA[b]]></r>', [xrfCoalesceText, xrfIgnoreWhitespace]);
  cnt := 0;
  while R.Read do
    if R.Token = xtText then
    begin
      SetLength(vals, cnt+1);
      vals[cnt] := R.Value;
      Inc(cnt);
    end;
  AssertEquals(2, cnt);
  AssertEquals('a', vals[0]);
  AssertEquals('b', vals[1]);
end;

procedure TTestCase_Reader_Coalesce_Boundaries.Test_Stream_SmallBuf_Text_CDATA_Merged_All;
var R: IXmlReader; seen: Boolean; v: String; S: TStringStream;
begin
  S := TStringStream.Create('<r>aa<![CDATA[bb]]>cc<![CDATA[dd]]>ee</r>');
  try
    // 极小缓冲触发跨块
    R := CreateXmlReader.ReadFromStream(S, [xrfCoalesceText, xrfIgnoreWhitespace], 32);
    seen := False;
    while R.Read do
      if (R.Token = xtText) and (not seen) then
      begin
        v := R.Value; seen := True;
      end;
    AssertTrue('should see one merged text', seen);
    AssertEquals('aabbccddee', v);
  finally
    S.Free;
  end;
end;

initialization
  if GetEnvironmentVariable('FAFAFA_TEST_SILENT_REG') <> '1' then
    Writeln('Registering TTestCase_Reader_Coalesce_Boundaries');
  RegisterTest(TTestCase_Reader_Coalesce_Boundaries);

end.

