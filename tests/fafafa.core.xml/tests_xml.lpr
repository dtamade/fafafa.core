{$CODEPAGE UTF8}
program tests_xml;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  {$IFDEF MSWINDOWS}Windows,{$ENDIF}
  SysUtils, consoletestrunner,
  // 显式 uses 所有测试单元，保证 initialization 执行
  Test_fafafa_core_xml,
  Test_fafafa_core_xml_reader,
  Test_fafafa_core_xml_reader_entities,
  Test_fafafa_core_xml_errors,
  Test_fafafa_core_xml_errors_more,
  Test_fafafa_core_xml_errors_tags,
  Test_fafafa_core_xml_errors_tags2,
  Test_fafafa_core_xml_errors_attrs_more,
  Test_fafafa_core_xml_errors_names,
  Test_fafafa_core_xml_ns_reader,
  Test_fafafa_core_xml_traversal,
  Test_fafafa_core_xml_ns_writer,

  Test_fafafa_core_xml_ns_reserved,
  Test_fafafa_core_xml_errors_attrs,
  Test_fafafa_core_xml_reader_stream_chunks,
  Test_fafafa_core_xml_reader_stream_smallbuf,
  Test_fafafa_core_xml_reader_attr_entities_smallbuf,
  Test_fafafa_core_xml_reader_charrefs_smallbuf,
  Test_fafafa_core_xml_reader_charrefs_nonascii_smallbuf,
  Test_fafafa_core_xml_reader_charrefs_unicode4_smallbuf,
  Test_fafafa_core_xml_reader_charrefs_malformed_smallbuf,
  Test_fafafa_core_xml_reader_charrefs_named_mix_smallbuf,
  Test_fafafa_core_xml_reader_charrefs_hex_illegal_smallbuf,
  Test_fafafa_core_xml_writer_entities_roundtrip,
  Test_fafafa_core_xml_writer_pretty_ns,
  Test_fafafa_core_xml_writer_pretty_strict,
  Test_fafafa_core_xml_writer_attr_flags,
  Test_fafafa_core_xml_reader_attr_crosschunk_smallbuf_linc,
  Test_fafafa_core_xml_reader_coalesce,
  Test_fafafa_core_xml_reader_coalesce_edges,
  Test_fafafa_core_xml_reader_bom,
  Test_fafafa_core_xml_decl_encoding,
  Test_fafafa_core_xml_decl_encoding_more,
  Test_fafafa_core_xml_decl_encoding_variants,
  Test_fafafa_core_xml_writer_omit_decl,
  Test_fafafa_core_xml_attr_ns_freeze_more,
  Test_fafafa_core_xml_perf_baseline,
  Test_fafafa_core_xml_decl_bom_conflict,
  Test_fafafa_core_xml_stream_transcode_smallbuf,
  Test_fafafa_core_xml_invalid_surrogates_strict_lenient;

{$IFDEF UNIX}
function setenv(name: PAnsiChar; value: PAnsiChar; overwrite: Integer): Integer; cdecl; external 'c';
{$ENDIF}

var
  Application: TTestRunner;
begin
  Application := TTestRunner.Create(nil);
  Application.Title := 'FPCUnit Console test runner for fafafa.core.xml';
  {$IFDEF UNIX}
  setenv('FAFAFA_TEST_SILENT_REG', '1', 1);
  {$ELSE}
  SetEnvironmentVariable('FAFAFA_TEST_SILENT_REG', '1');
  {$ENDIF}
  Application.Initialize;
  Application.Run;
  Application.Free;
end.

