{$CODEPAGE UTF8}
program tests_crypto;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, CustApp, fpcunit, testregistry, consoletestrunner,
  Test_crypto,
  Test_aes_ecb_vectors,
  Test_aes_ctr_vectors,
  Test_aead_gcm_vectors,
  Test_ghash_kat_vectors,
  Test_aead_gcm_kat_minimal_vectors,
  Test_aead_gcm_kat12_invariants,
  Test_aead_gcm_extra_roundtrip,
  Test_aead_gcm_kat16_invariants,
  Test_aead_gcm_nist_kat16,
  Test_aead_gcm_api_contract_negatives,
  {$IFDEF MSWINDOWS}
  Test_rng_windows,
  {$ENDIF}
  {$IFDEF UNIX}
  Test_rng_unix,
  {$ENDIF}
  Test_pbkdf2_vectors,
  Test_hkdf_vectors,
  Test_chacha20poly1305_vectors,
  Test_nonce_manager_ts,
  Test_ghash_basic_properties,
  Test_ghash_mini_kat,
  Test_ghash_update_chunked_equivalence,
  Test_aead_gcm_taglen12_16_matrix,
  Test_aead_append_api_minimal,
  Test_aead_inplace_api_minimal,
  Test_aead_safe_api_minimal,
  Test_aead_tamper_extras,
  Test_aead_tamper_more,
  Test_aead_safe_taglen_matrix,

  Test_ghash_clmul_equivalence,
  Test_ghash_clmul_gfmult_vectors,
  Test_ghash_clmul_bench,
  Test_xxhash_consistency,
  Test_ghash_precomp_bench,

  Test_ghash_pure_mode_consistency,

  Test_ghash_pure_mode_sweep,

  Test_ghash_pure_mode_bench_sweep,

  Test_ghash_clmul_vs_pure_byte_bench,

  Test_ghash_bench_sizes_sweep,

  Test_ghash_kat_additional,

  Test_ghash_zeroize_tables_option,

  Test_ghash_set_pure_mode_api,

  Test_ghash_precompute_coldstart_bench,

  Test_ghash_cache_per_h_basic,

  Test_ghash_finalize_mismatch_debug,

  Test_include_integrity,

  Test_rng_contracts,
  Test_ghash_warmup_smoke;

type

  { TMyTestRunner }

  TMyTestRunner = class(TTestRunner)
  protected
    // override the protected methods of TTestRunner to customize its behavior
  end;

var
  Application: TMyTestRunner;

begin
  Application := TMyTestRunner.Create(nil);
  Application.Initialize;
  Application.Title := 'fafafa.core.crypto Tests';
  Application.Run;
  Application.Free;
end.
