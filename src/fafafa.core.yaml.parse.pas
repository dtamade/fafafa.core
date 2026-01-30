unit fafafa.core.yaml.parse;

{$MODE OBJFPC}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fafafa.core.yaml.types, fafafa.core.yaml.token;

// 说明：
// - 本单元为 fy-parse.c 的占位骨架，先定义接口与最小实现，保证编译

Type
  PFyParserCore = ^TFyParserCore;
  TFyParserCore = record
    // Note: legacy PFyScanner removed with scan/input stack.
    // Placeholder for future tokenizer-driven parser core state.
  end;

function fy_parser_core_create: PFyParserCore;
procedure fy_parser_core_destroy(pc: PFyParserCore);

implementation

function fy_parser_core_create: PFyParserCore;
var p: PFyParserCore;
begin
  GetMem(p, SizeOf(TFyParserCore)); FillChar(p^, SizeOf(TFyParserCore), 0);
  Result := p;
end;

procedure fy_parser_core_destroy(pc: PFyParserCore);
begin
  if pc=nil then Exit; FreeMem(pc);
end;

end.

