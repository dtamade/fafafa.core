program example_stream_reader_min;

{$MODE OBJFPC}{$H+}

uses
  SysUtils, Classes,
  fafafa.core.mem.allocator,
  fafafa.core.json;

procedure Run;
var
  SR: IJsonStreamReader;
  F: TFileStream;
  Buf: array[0..65535] of AnsiChar;
  ReadBytes: Integer;
  Code: Integer;
  Doc: IJsonDocument;
begin
  Writeln('[CWD] ', GetCurrentDir);
  SR := NewJsonStreamReader(SizeOf(Buf), GetRtlAllocator, [jrfDefault]); // 默认限额已开启（门面注入）
  F := TFileStream.Create('example_json_input.json', fmOpenRead or fmShareDenyWrite);
  Writeln('[OPEN] example_json_input.json OK, size=', F.Size);
  try
    while True do
    begin
      ReadBytes := F.Read(Buf, SizeOf(Buf));
      if ReadBytes > 0 then
      begin
        Code := SR.Feed(@Buf[0], ReadBytes);
        if Code <> 0 then
        begin
          Writeln('Feed error: ', Code);
          Exit;
        end;
      end;
      Doc := nil;
      Code := SR.TryRead(Doc);
      if Code = 0 then
      begin
        // 成功解析
        if (Doc <> nil) and (Doc.Root <> nil) then
          Writeln('Parsed ok. ValuesRead=', Doc.ValuesRead, ' BytesRead=', Doc.BytesRead)
        else
          Writeln('Parsed ok, empty document');
        Break;
      end
      else if Code = Ord(jecMore) then
      begin
        if ReadBytes = 0 then
        begin
          Writeln('Need more data but reached EOF. Incomplete JSON.');
          Break;
        end;
        Continue;
      end
      else
      begin
        Writeln('Parse error: code=', Code);
        Break;
      end;
    end;
  finally
    F.Free;
  end;
end;

begin
  try
    Run;
  except
    on E: Exception do
      Writeln('[EXCEPTION] ', E.ClassName, ': ', E.Message);
  end;
end.

