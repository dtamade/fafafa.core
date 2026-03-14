#ifndef FAFAFA_CORE_SIMD_PUBLICABI_SMOKE_H
#define FAFAFA_CORE_SIMD_PUBLICABI_SMOKE_H

#include <stddef.h>
#include <stdint.h>

typedef uint32_t fafafa_simd_abi_flags_t;

enum {
  FAF_SIMD_ABI_FLAG_SUPPORTED_ON_CPU = 1u << 0,
  FAF_SIMD_ABI_FLAG_REGISTERED       = 1u << 1,
  FAF_SIMD_ABI_FLAG_DISPATCHABLE     = 1u << 2,
  FAF_SIMD_ABI_FLAG_ACTIVE           = 1u << 3,
  FAF_SIMD_ABI_FLAG_EXPERIMENTAL     = 1u << 4
};

#pragma pack(push, 1)
typedef struct fafafa_simd_backend_pod_info_t {
  uint32_t struct_size;
  uint32_t backend_id;
  uint64_t capability_bits;
  fafafa_simd_abi_flags_t flags;
  int32_t priority;
} fafafa_simd_backend_pod_info_t;

typedef int32_t (*fafafa_simd_mem_equal_fn)(const void*, const void*, size_t);
typedef intptr_t (*fafafa_simd_mem_find_byte_fn)(const void*, size_t, uint8_t);
typedef int32_t (*fafafa_simd_mem_diff_range_fn)(const void*, const void*, size_t, size_t*, size_t*);
typedef uint64_t (*fafafa_simd_sum_bytes_fn)(const void*, size_t);
typedef size_t (*fafafa_simd_count_byte_fn)(const void*, size_t, uint8_t);
typedef size_t (*fafafa_simd_bitset_popcount_fn)(const void*, size_t);
typedef int32_t (*fafafa_simd_utf8_validate_fn)(const void*, size_t);
typedef int32_t (*fafafa_simd_ascii_iequal_fn)(const void*, const void*, size_t);
typedef intptr_t (*fafafa_simd_bytes_index_of_fn)(const void*, size_t, const void*, size_t);
typedef void (*fafafa_simd_mem_copy_fn)(const void*, void*, size_t);
typedef void (*fafafa_simd_mem_set_fn)(void*, size_t, uint8_t);
typedef void (*fafafa_simd_to_lower_ascii_fn)(void*, size_t);
typedef void (*fafafa_simd_to_upper_ascii_fn)(void*, size_t);
typedef void (*fafafa_simd_mem_reverse_fn)(void*, size_t);
typedef void (*fafafa_simd_min_max_bytes_fn)(const void*, size_t, uint8_t*, uint8_t*);

typedef struct fafafa_simd_public_api_t {
  uint32_t struct_size;
  uint16_t abi_version_major;
  uint16_t abi_version_minor;
  uint64_t abi_signature_hi;
  uint64_t abi_signature_lo;
  uint32_t active_backend_id;
  fafafa_simd_abi_flags_t active_flags;
  fafafa_simd_mem_equal_fn mem_equal;
  fafafa_simd_mem_find_byte_fn mem_find_byte;
  fafafa_simd_mem_diff_range_fn mem_diff_range;
  fafafa_simd_sum_bytes_fn sum_bytes;
  fafafa_simd_count_byte_fn count_byte;
  fafafa_simd_bitset_popcount_fn bitset_popcount;
  fafafa_simd_utf8_validate_fn utf8_validate;
  fafafa_simd_ascii_iequal_fn ascii_iequal;
  fafafa_simd_bytes_index_of_fn bytes_index_of;
  fafafa_simd_mem_copy_fn mem_copy;
  fafafa_simd_mem_set_fn mem_set;
  fafafa_simd_to_lower_ascii_fn to_lower_ascii;
  fafafa_simd_to_upper_ascii_fn to_upper_ascii;
  fafafa_simd_mem_reverse_fn mem_reverse;
  fafafa_simd_min_max_bytes_fn min_max_bytes;
} fafafa_simd_public_api_t;
#pragma pack(pop)

#endif
