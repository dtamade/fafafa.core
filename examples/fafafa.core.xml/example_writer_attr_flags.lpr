{$CODEPAGE UTF8}
program example_writer_attr_flags;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils, Classes, fafafa.core.xml;

procedure Demo_Attr_Flags;
var W: IXmlWriter; S: String;
begin
  W := CreateXmlWriter;
  W.StartElement('root');
  W.WriteAttribute('b','2');
  W.WriteAttribute('a','1');
  W.WriteAttribute('a','3');
  W.EndElement;
  // 同时开启排序与去重：先保留最后一个 a=3，再排序为 a,b
  S := W.WriteToString([xwfSortAttrs, xwfDedupAttrs]);
  WriteLn(S);
end;

begin
  try
    Demo_Attr_Flags;
  except
    on E: Exception do
    begin
      WriteLn('Error: ', E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.

