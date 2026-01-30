{$CODEPAGE UTF8}
program example_writer_sort_pretty;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes,
  fafafa.core.toml;

procedure Run;
var
  B: ITomlBuilder;
  D: ITomlDocument;
  S: String;
begin
  // 构造包含标量、AoT 与子表的文档
  B := NewDoc
    .PutAtStr('title', 'TOML')
    .PutAtInt('y', 9)
    .PutAtInt('z', 0)
    .BeginTable('a.b')
      .PutInt('c', 1)
      .PutInt('d', 2)
    .EndTable
    .EnsureArray('a.t')
    .PushTable('a.t')
      .PutStr('name', 'n1')
    .EndTable
    .PushTable('a.t')
      .PutStr('name', 'n2')
    .EndTable;

  D := B.Build;
  S := String(ToToml(D, [twfSortKeys, twfPretty]));

  Writeln('===== TOML (SortKeys + Pretty) =====');
  Writeln(S);

  // 保存到文件
  with TFileStream.Create('example_writer_sort_pretty.toml', fmCreate) do
  try
    if Length(S) > 0 then
      WriteBuffer(S[1], Length(S));
  finally
    Free;
  end;
  Writeln('Saved to example_writer_sort_pretty.toml');
end;

begin
  Run;
end.

