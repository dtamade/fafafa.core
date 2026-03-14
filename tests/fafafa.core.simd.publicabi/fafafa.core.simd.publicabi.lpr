library fafafa_core_simd_publicabi;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  fafafa.core.simd;

exports
  fafafa_simd_abi_version_major name 'fafafa_simd_abi_version_major',
  fafafa_simd_abi_version_minor name 'fafafa_simd_abi_version_minor',
  fafafa_simd_abi_signature name 'fafafa_simd_abi_signature',
  fafafa_simd_get_backend_pod_info name 'fafafa_simd_get_backend_pod_info',
  fafafa_simd_backend_name name 'fafafa_simd_backend_name',
  fafafa_simd_backend_description name 'fafafa_simd_backend_description',
  fafafa_simd_get_public_api name 'fafafa_simd_get_public_api';

begin
end.
