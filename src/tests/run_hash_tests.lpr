program run_hash_tests;

{$mode objfpc}{$H+}
{$I ../fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}cthreads,{$ENDIF}{$ENDIF}
  consoletestrunner,
  test_hash_xxh3_64_seed0_kat,
  test_hash_xxh3_64_seeded_kat,
  test_hash_xxh3_64_streaming_vs_oneshot,
  test_hash_xxh3_64_streaming_large,
  test_cipher_caesar_basic,
  test_hash_xxh3_128_seed0_kat;

begin
  // Register tests
  test_hash_xxh3_64_seed0_kat.RegisterTests_XXH3_64_Seed0_KAT;
  test_hash_xxh3_64_seeded_kat.RegisterTests_XXH3_64_Seeded_KAT;
  test_hash_xxh3_64_streaming_vs_oneshot.RegisterTests_XXH3_64_StreamVsOneShot;
  test_hash_xxh3_64_streaming_large.RegisterTests_XXH3_64_Streaming_Large;
  test_cipher_caesar_basic.RegisterTests_Caesar_Basic;
  test_hash_xxh3_128_seed0_kat.RegisterTests_XXH3_128_Seed0_KAT;
  with TTestRunner.Create(nil) do
  begin
    Initialize;
    Run;
    Free;
  end;
end.

