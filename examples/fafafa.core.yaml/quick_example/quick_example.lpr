{$CODEPAGE UTF8}
program quick_example;

{$MODE OBJFPC}{$H+}
{$modeswitch advancedrecords}

uses
  SysUtils,
  fafafa.core.yaml;

var
  parser: PYamlParser;
  cfg: TYamlParseCfg;
  ev: PYamlEvent;
  p: PChar;
  L: SizeUInt;
  input: PChar;
  et: TYamlEventType;
begin
  // 最小配置（按需设置 flags）
  cfg.search_path := nil;
  cfg.flags := [YAML_PCF_RESOLVE_DOCUMENT];
  cfg.userdata := nil;
  cfg.diag := nil;

  parser := yaml_parser_create(@cfg);
  if parser = nil then Halt(1);

  input := '{a:[1,{b:2}]}'#0;
  if yaml_parser_set_string(parser, input, StrLen(input)) <> 0 then Halt(2);

  // 打印事件序列
  repeat
    ev := yaml_parser_parse(parser);
    if ev = nil then Break;

    et := ev^.event_type;
    WriteLn('Event: ', StrPas(yaml_event_type_get_text(et)));

    if et = YAML_ET_SCALAR then begin
      p := yaml_event_scalar_get_text(ev, @L);
      if (p<>nil) and (L>0) then
        WriteLn('  scalar: ', Copy(StrPas(p), 1, L))
      else
        WriteLn('  scalar: <empty>');
    end;

    yaml_parser_event_free(parser, ev);
  until et = YAML_ET_STREAM_END;

  yaml_parser_destroy(parser);
end.

