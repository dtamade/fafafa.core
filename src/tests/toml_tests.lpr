program toml_tests;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}cthreads,{$ENDIF}{$ENDIF}
  consoletestrunner,
  test_toml_basic,
  test_toml_datetime_basic,
  test_toml_writer_multiline,
  test_toml_inline_array_tables,
  test_toml_multiline_strings,
  test_toml_lexer_t99_strings,
  test_toml_lexer_t99_strings_negative,
  test_toml_string_number_enhanced,
  test_toml_error_positions,
  test_toml_string_number_underscores_invalid,
  test_toml_writer_flags,
  test_toml_writer_snapshots,
  test_toml_writer_snapshots_advanced,
  test_toml_writer_snapshots_arrays,
  test_toml_writer_nested_arrays_tables,
  test_toml_writer_snapshots_deep,
  test_toml_writer_aot_nested_complex,
  test_toml_writer_edgecases,
  test_toml_parser_v2_minimal,
  test_toml_builder_aot_basic,
  test_toml_parser_v2_tables,
  test_toml_parser_v2_aot,
  test_toml_parser_v2_inline,
  test_toml_parser_v2_numbers,
  test_toml_parser_v2_arrays,
  test_toml_parser_v2_arrays_advanced;

begin
  // Register TOML tests
  test_toml_basic.RegisterTomlBasicTests;
  test_toml_datetime_basic.RegisterTomlDatetimeTests;
  test_toml_inline_array_tables.RegisterTomlInlineArrayTableTests;
  test_toml_multiline_strings.RegisterTomlMultilineStringTests;
  test_toml_string_number_enhanced.RegisterTomlStringNumberEnhancedTests;
  test_toml_error_positions.RegisterTomlErrorPositionTests;
  test_toml_string_number_underscores_invalid.RegisterTomlNumberUnderscoreInvalidTests;
  test_toml_writer_flags.RegisterTomlWriterFlagTests;
  test_toml_writer_snapshots.RegisterTomlWriterSnapshotTests;
  test_toml_writer_snapshots_advanced.RegisterTomlWriterSnapshotAdvancedTests;
  test_toml_writer_snapshots_arrays.RegisterTomlWriterSnapshotArrayTests;
  test_toml_writer_nested_arrays_tables.RegisterTomlWriterNestedArrayTableTests;
  test_toml_writer_multiline.RegisterTomlWriterMultilineTests;
  test_toml_lexer_t99_strings.RegisterTomlLexerT99StringTests;
  test_toml_lexer_t99_strings_negative.RegisterTomlLexerT99StringNegativeTests;
  test_toml_writer_snapshots_deep.RegisterTomlWriterSnapshotDeepTests;
  test_toml_writer_aot_nested_complex.RegisterTomlWriterAotNestedComplexTests;
  test_toml_writer_edgecases.RegisterTomlWriterEdgecaseTests;
  test_toml_parser_v2_minimal.RegisterTomlParserV2MinimalTests;
  test_toml_builder_aot_basic.RegisterTomlBuilderAotBasicTests;
  test_toml_parser_v2_tables.RegisterTomlParserV2TableTests;
  test_toml_parser_v2_aot.RegisterTomlParserV2AotTests;
  test_toml_parser_v2_inline.RegisterTomlParserV2InlineTests;
  test_toml_parser_v2_numbers.RegisterTomlParserV2NumberTests;
  test_toml_parser_v2_arrays.RegisterTomlParserV2ArrayTests;
  test_toml_parser_v2_arrays_advanced.RegisterTomlParserV2ArrayAdvancedTests;
  with TTestRunner.Create(nil) do
  begin
    Initialize;
    Run;
    Free;
  end;
end.

