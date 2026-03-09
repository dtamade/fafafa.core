{$CODEPAGE UTF8}
program tests_toml;

{$mode objfpc}{$H+}

uses
  SysUtils, consoletestrunner,
  Test_fafafa_core_toml_parse_router_fallback,
  Test_fafafa_core_toml,
  Test_fafafa_core_toml_contains,
  Test_fafafa_core_toml_dotted,
  Test_fafafa_core_toml_dotted2,
  Test_fafafa_core_toml_reader_dotted_extras,
  Test_fafafa_core_toml_writer_nested,
  Test_fafafa_core_toml_writer_flags,
  Test_fafafa_core_toml_writer_combination_flags,
  Test_fafafa_core_toml_writer_quoted_mixed,
  Test_fafafa_core_toml_writer_strings_order,
  Test_fafafa_core_toml_writer_sort,
  Test_fafafa_core_toml_writer_spaces_flag,
  Test_fafafa_core_toml_writer_mixed_nested,
  Test_fafafa_core_toml_writer_aot_interleaved,
  Test_fafafa_core_toml_writer_pretty_flag,
  Test_fafafa_core_toml_writer_datetime_snapshots,
  Test_fafafa_core_toml_writer_snapshots_deep,
  Test_fafafa_core_toml_writer_deep_mixed_2,
  Test_fafafa_core_toml_writer_snapshot_full,
  Test_fafafa_core_toml_writer_snapshot_no_pretty,
  Test_fafafa_core_toml_writer_snapshot_pretty_no_sort,
  Test_fafafa_core_toml_writer_snapshot_tight_todo,
  Test_fafafa_core_toml_writer_snapshot_tight_pretty,
  Test_fafafa_core_toml_writer_snapshot_tight_sort,
  Test_fafafa_core_toml_writer_snapshot_tight_sort_pretty,
  Test_fafafa_core_toml_reader_errors_consistency_3,
  Test_fafafa_core_toml_writer_snapshot_tight_unicode,
  Test_fafafa_core_toml_reader_errors_datetime_prefix,
  Test_fafafa_core_toml_writer_snapshot_tight_unicode_sort,
  Test_fafafa_core_toml_writer_snapshot_tight_unicode_pretty,
  Test_fafafa_core_toml_reader_errors_datetime_prefix_ext,
  Test_fafafa_core_toml_reader_errors_consistency_2,
  Test_fafafa_core_toml_strings_numbers_negatives,
  Test_fafafa_core_toml_numbers_negatives,
  Test_fafafa_core_toml_numbers_bases_negatives,
  Test_fafafa_core_toml_reader_errors_consistency,
  Test_fafafa_core_toml_builder,
  Test_fafafa_core_toml_builder_getters,
  Test_fafafa_core_toml_arrays,
  Test_fafafa_core_toml_arrays_writer,
  Test_fafafa_core_toml_arrays_nested_writer,
  Test_fafafa_core_toml_arrays_strings,
  Test_fafafa_core_toml_arrays_empty_bool,
  Test_fafafa_core_toml_tables_headers,
  Test_fafafa_core_toml_tables_headers_conflicts,
  Test_fafafa_core_toml_datetime,
  Test_fafafa_core_toml_datetime_negatives,
  Test_fafafa_core_toml_inline_tables,
  Test_fafafa_core_toml_array_of_tables,
  Test_fafafa_core_toml_unicode_escapes,
  Test_fafafa_core_toml_unicode_negatives,
  Test_fafafa_core_toml_unicode_negatives_ext,
  Test_fafafa_core_toml_unicode_keys_negatives,
  Test_fafafa_core_toml_unicode_keys_regression;

var
  Application: TTestRunner;
begin
  DefaultFormat := fPlain;
  Application := TTestRunner.Create(nil);
  Application.Title := 'FPCUnit Console test runner for fafafa.core.toml';
  Application.Initialize;
  Application.Run;
  Application.Free;
end.

