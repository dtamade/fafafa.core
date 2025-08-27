unit fafafa.core.id.uuid.batch.examples;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fafafa.core.id, fafafa.core.id.codec;

procedure Example_Fill_Batch_Text(const N: Integer);

implementation

procedure Example_Fill_Batch_Text(const N: Integer);
var
  i: Integer;
  bufs: array of string;
  raw: TUuid128;
begin
  SetLength(bufs, N);
  // string[] 版本
  UuidV4_FillTextStringsN(bufs);
  for i := 0 to N-1 do
    if Length(bufs[i]) <> 36 then raise Exception.Create('bad len');
  // NoDash 版本
  UuidV4_FillTextNoDashStringsN(bufs);
  for i := 0 to N-1 do
    if Length(bufs[i]) <> 32 then raise Exception.Create('bad len');
  // Base64URL 示例：零分配写入
  raw := UuidV4_Raw;
  SetLength(bufs, 1);
  SetLength(bufs[0], 22);
  UuidToBase64UrlChars(raw, PChar(bufs[0]));
end;

end.

