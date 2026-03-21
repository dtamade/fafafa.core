#include "publicabi_smoke.h"

#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef uint16_t (*fn_ver_u16)(void);
typedef void (*fn_sig)(uint64_t*, uint64_t*);
typedef int32_t (*fn_get_backend_info)(uint32_t, fafafa_simd_backend_pod_info_t*);
typedef const char* (*fn_backend_text)(uint32_t);
typedef const fafafa_simd_public_api_t* (*fn_get_api)(void);

static void fail(const char* msg) {
  fprintf(stderr, "[PUBLICABI] FAIL: %s\n", msg);
  exit(1);
}

int main(int argc, char** argv) {
  void* lib;
  fn_ver_u16 abi_major;
  fn_ver_u16 abi_minor;
  fn_sig abi_sig;
  fn_get_backend_info get_backend_info;
  fn_backend_text backend_name;
  fn_backend_text backend_description;
  fn_get_api get_api;
  uint64_t sig_hi = 0;
  uint64_t sig_lo = 0;
  fafafa_simd_backend_pod_info_t scalar_info;
  fafafa_simd_backend_pod_info_t active_info;
  const fafafa_simd_public_api_t* api;
  const char* active_name;
  const char* active_description;
  unsigned char a[32];
  unsigned char b[32];
  unsigned char c[32];
  unsigned char needle[3];
  const char* utf8_text = "simd-publicabi";
  unsigned char lower_buf[9] = {'A', 'b', 'C', 'd', 'E', 'f', '0', '1', '2'};
  unsigned char upper_buf[9] = {'A', 'b', 'C', 'd', 'E', 'f', '0', '1', '2'};
  unsigned char rev_buf[8] = {1u, 2u, 3u, 4u, 5u, 6u, 7u, 8u};
  uint8_t mm_buf[5] = {3u, 7u, 2u, 9u, 5u};
  uint8_t mm_min = 0;
  uint8_t mm_max = 0;
  size_t first_diff = 0;
  size_t last_diff = 0;

  if (argc != 2) {
    fprintf(stderr, "Usage: %s <path-to-lib>\n", argv[0]);
    return 2;
  }

  lib = dlopen(argv[1], RTLD_NOW | RTLD_LOCAL);
  if (!lib) {
    fprintf(stderr, "dlopen failed: %s\n", dlerror());
    return 2;
  }

  abi_major = (fn_ver_u16)dlsym(lib, "fafafa_simd_abi_version_major");
  abi_minor = (fn_ver_u16)dlsym(lib, "fafafa_simd_abi_version_minor");
  abi_sig = (fn_sig)dlsym(lib, "fafafa_simd_abi_signature");
  get_backend_info = (fn_get_backend_info)dlsym(lib, "fafafa_simd_get_backend_pod_info");
  backend_name = (fn_backend_text)dlsym(lib, "fafafa_simd_backend_name");
  backend_description = (fn_backend_text)dlsym(lib, "fafafa_simd_backend_description");
  get_api = (fn_get_api)dlsym(lib, "fafafa_simd_get_public_api");

  if (!abi_major || !abi_minor || !abi_sig || !get_backend_info || !backend_name || !backend_description || !get_api)
    fail("required exported symbol missing");

  if (abi_major() == 0)
    fail("abi major should not be zero");

  abi_sig(&sig_hi, &sig_lo);
  if (sig_hi == 0 || sig_lo == 0)
    fail("abi signature should not be zero");

  memset(&scalar_info, 0, sizeof(scalar_info));
  if (!get_backend_info(0u, &scalar_info))
    fail("scalar backend info query failed");
  if (scalar_info.struct_size != sizeof(scalar_info))
    fail("backend pod struct size mismatch");
  if (scalar_info.backend_id != 0u)
    fail("scalar backend id mismatch");
  if (!(scalar_info.flags & FAF_SIMD_ABI_FLAG_SUPPORTED_ON_CPU))
    fail("scalar backend should be supported_on_cpu");
  if (!(scalar_info.flags & FAF_SIMD_ABI_FLAG_REGISTERED))
    fail("scalar backend should be registered");
  if (!(scalar_info.flags & FAF_SIMD_ABI_FLAG_DISPATCHABLE))
    fail("scalar backend should be dispatchable");
  if (!backend_name(0u) || backend_name(0u)[0] == '\0')
    fail("scalar backend name missing");
  if (!backend_description(0u) || backend_description(0u)[0] == '\0')
    fail("scalar backend description missing");

  api = get_api();
  if (!api)
    fail("public api pointer is null");
  if (api->struct_size != sizeof(*api))
    fail("public api struct size mismatch");
  if (api->abi_version_major != abi_major() || api->abi_version_minor != abi_minor())
    fail("public api version mismatch");
  if (api->abi_signature_hi != sig_hi || api->abi_signature_lo != sig_lo)
    fail("public api signature mismatch");
  if (api->active_flags == 0u)
    fail("public api active flags should not be zero");
  if (!(api->active_flags & FAF_SIMD_ABI_FLAG_SUPPORTED_ON_CPU))
    fail("public api active flags should include supported_on_cpu");
  if (!(api->active_flags & FAF_SIMD_ABI_FLAG_REGISTERED))
    fail("public api active flags should include registered");
  if (!(api->active_flags & FAF_SIMD_ABI_FLAG_DISPATCHABLE))
    fail("public api active flags should include dispatchable");
  if (!(api->active_flags & FAF_SIMD_ABI_FLAG_ACTIVE))
    fail("public api active flags should include active");
  memset(&active_info, 0, sizeof(active_info));
  if (!get_backend_info(api->active_backend_id, &active_info))
    fail("active backend info query failed");
  if (active_info.struct_size != sizeof(active_info))
    fail("active backend pod struct size mismatch");
  if (active_info.backend_id != api->active_backend_id)
    fail("active backend id mismatch");
  if (active_info.flags != api->active_flags)
    fail("active backend flags should match public api active flags");
  active_name = backend_name(api->active_backend_id);
  if (!active_name || active_name[0] == '\0')
    fail("active backend name missing");
  active_description = backend_description(api->active_backend_id);
  if (!active_description || active_description[0] == '\0')
    fail("active backend description missing");
  if (api->active_backend_id != 0u && (scalar_info.flags & FAF_SIMD_ABI_FLAG_ACTIVE))
    fail("scalar backend should not be active when active backend differs");
  if (!api->mem_equal || !api->mem_find_byte || !api->mem_diff_range || !api->sum_bytes || !api->count_byte ||
      !api->bitset_popcount || !api->utf8_validate || !api->ascii_iequal || !api->bytes_index_of || !api->mem_copy ||
      !api->mem_set || !api->to_lower_ascii || !api->to_upper_ascii || !api->mem_reverse || !api->min_max_bytes)
    fail("public api function pointer missing");

  for (size_t i = 0; i < sizeof(a); ++i) {
    a[i] = (unsigned char)((i * 7u) & 0xFFu);
    b[i] = a[i];
  }
  b[17] = 0xAAu;

  if (!api->mem_equal(a, a, sizeof(a)))
    fail("mem_equal parity failed");
  if (api->mem_find_byte(b, sizeof(b), 0xAAu) != 17)
    fail("mem_find_byte parity failed");
  if (!api->mem_diff_range(a, b, sizeof(a), &first_diff, &last_diff))
    fail("mem_diff_range should detect mismatch");
  if (first_diff != 17u || last_diff != 17u)
    fail("mem_diff_range parity failed");
  if (api->count_byte(b, sizeof(b), 0xAAu) != 1u)
    fail("count_byte parity failed");
  if (api->sum_bytes(a, sizeof(a)) == 0)
    fail("sum_bytes returned zero unexpectedly");
  if (api->bitset_popcount(a, sizeof(a)) == 0)
    fail("bitset_popcount returned zero unexpectedly");
  if (!api->utf8_validate(utf8_text, strlen(utf8_text)))
    fail("utf8_validate parity failed");
  if (!api->ascii_iequal("AbCd", "aBcD", 4u))
    fail("ascii_iequal parity failed");
  needle[0] = a[7];
  needle[1] = a[8];
  needle[2] = a[9];
  if (api->bytes_index_of(a, sizeof(a), needle, sizeof(needle)) != 7)
    fail("bytes_index_of hit parity failed");
  needle[0] = 0xFEu;
  needle[1] = 0xEDu;
  needle[2] = 0xDCu;
  if (api->bytes_index_of(a, sizeof(a), needle, sizeof(needle)) != -1)
    fail("bytes_index_of miss parity failed");

  memset(c, 0, sizeof(c));
  api->mem_copy(a, c, sizeof(a));
  if (memcmp(a, c, sizeof(a)) != 0)
    fail("mem_copy parity failed");

  api->mem_set(c, sizeof(c), 0x5Au);
  for (size_t i = 0; i < sizeof(c); ++i) {
    if (c[i] != 0x5Au)
      fail("mem_set parity failed");
  }

  api->to_lower_ascii(lower_buf, sizeof(lower_buf));
  if (memcmp(lower_buf, "abcdef012", sizeof(lower_buf)) != 0)
    fail("to_lower_ascii parity failed");

  api->to_upper_ascii(upper_buf, sizeof(upper_buf));
  if (memcmp(upper_buf, "ABCDEF012", sizeof(upper_buf)) != 0)
    fail("to_upper_ascii parity failed");

  api->mem_reverse(rev_buf, sizeof(rev_buf));
  if (rev_buf[0] != 8u || rev_buf[1] != 7u || rev_buf[2] != 6u || rev_buf[3] != 5u || rev_buf[4] != 4u ||
      rev_buf[5] != 3u || rev_buf[6] != 2u || rev_buf[7] != 1u)
    fail("mem_reverse parity failed");

  api->min_max_bytes(mm_buf, sizeof(mm_buf), &mm_min, &mm_max);
  if (mm_min != 2u || mm_max != 9u)
    fail("min_max_bytes parity failed");

  dlclose(lib);
  puts("[PUBLICABI] OK");
  return 0;
}
