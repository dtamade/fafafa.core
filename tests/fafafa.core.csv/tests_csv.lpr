program tests_csv;

{$mode objfpc}{$H+}
{$APPTYPE CONSOLE}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}cthreads,{$ENDIF}{$ENDIF}
  consoletestrunner,
  fafafa.core.csv,
  Test_fafafa_core_csv,
  Test_fafafa_core_csv_strict,
  Test_fafafa_core_csv_writer,
  Test_fafafa_core_csv_writer_headers,
  Test_fafafa_core_csv_reader_quoted,
  Test_fafafa_core_csv_reader_trim_lazy,
  Test_fafafa_core_csv_reader_escape_bom,
  Test_fafafa_core_csv_reader_headers_strict,
  Test_fafafa_core_csv_reader_cr_only_and_errors,
  Test_fafafa_core_csv_reader_positions_more,
  Test_fafafa_core_csv_reader_positions_asserts,
  Test_fafafa_core_csv_reader_mixed_newlines,
  Test_fafafa_core_csv_reader_trygetname_and_delims,
  Test_fafafa_core_csv_reader_field_index_error,
  Test_fafafa_core_csv_reader_multiline_and_noescape,
  Test_fafafa_core_csv_reader_multiline_edgecases,
  Test_fafafa_core_csv_reader_edgecases_more,
  Test_fafafa_core_csv_writer_behaviors,
  Test_fafafa_core_csv_writer_extremes,
  Test_fafafa_core_csv_reader_only_spaces_and_empty_lines,
  Test_fafafa_core_csv_reader_many_columns,
  Test_fafafa_core_csv_reader_invalid_utf8,
  Test_fafafa_core_csv_reader_error_codes,
  Test_fafafa_core_csv_reader_builder_options,
  Test_fafafa_core_csv_reader_builder_precedence,
  Test_fafafa_core_csv_reader_zero_copy_bytes,
  Test_fafafa_core_csv_reader_slice_lifetime,
  Test_fafafa_core_csv_reader_reuse_record,
  Test_fafafa_core_csv_writer_terminator_and_reset,
  Test_fafafa_core_csv_writer_escape_options,
  Test_fafafa_core_csv_facade,
  Test_fafafa_core_csv_trimmode,
  Test_fafafa_core_csv_quote_nonnumeric,
  Test_fafafa_core_csv_typed_accessors,
  Test_fafafa_core_csv_quoting_disabled;

begin
  with TTestRunner.Create(nil) do
  try
    Initialize;
    Run;
  finally
    Free;
  end;
end.
