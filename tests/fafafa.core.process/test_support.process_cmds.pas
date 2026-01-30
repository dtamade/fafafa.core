{$CODEPAGE UTF8}
unit test_support.process_cmds;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes, fafafa.core.process;

function NewLargeOutputCommand(const Bytes: Integer): IProcessBuilder;

implementation

function NewLargeOutputCommand(const Bytes: Integer): IProcessBuilder;
{$IFDEF WINDOWS}
var
  lines: Integer;
begin
  // 每行约 12 字节: '0123456789' + CRLF
  lines := (Bytes + 11) div 12;
  Result := NewProcessBuilder
              .Exe('cmd.exe')
              .Args(['/c', 'for', '/L', '%i', 'in', '(1,1,' + IntToStr(lines) + ')', 'do', '@echo', '0123456789']);
end;
{$ENDIF}
{$IFDEF UNIX}
begin
  // 使用 head -c 生成指定字节到 stdout
  Result := NewProcessBuilder
              .Exe('/bin/sh')
              .Args(['-c', 'head -c ' + IntToStr(Bytes) + ' /dev/zero']);
end;
{$ENDIF}

end.

