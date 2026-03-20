param(
  [string]$LibraryPath = "",
  [switch]$ValidateOnly
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($LibraryPath)) {
  $LibraryPath = Get-ChildItem -Path (Join-Path $PSScriptRoot 'bin') -Filter *.dll -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1 -ExpandProperty FullName
}

if ([string]::IsNullOrWhiteSpace($LibraryPath) -or -not (Test-Path $LibraryPath)) {
  Write-Error "[PUBLICABI] Missing library path"
  exit 2
}

$ResolvedPath = (Resolve-Path $LibraryPath).Path
$LibraryLiteral = $ResolvedPath.Replace('"', '""')

$TypeSource = @"
using System;
using System.Runtime.InteropServices;

[StructLayout(LayoutKind.Sequential, Pack=1)]
public struct FafafaSimdBackendPodInfo {
  public UInt32 StructSize;
  public UInt32 BackendId;
  public UInt64 CapabilityBits;
  public UInt32 Flags;
  public Int32 Priority;
}

[StructLayout(LayoutKind.Sequential, Pack=1)]
public struct FafafaSimdPublicApi {
  public UInt32 StructSize;
  public UInt16 AbiVersionMajor;
  public UInt16 AbiVersionMinor;
  public UInt64 AbiSignatureHi;
  public UInt64 AbiSignatureLo;
  public UInt32 ActiveBackendId;
  public UInt32 ActiveFlags;
  public IntPtr MemEqual;
  public IntPtr MemFindByte;
  public IntPtr MemDiffRange;
  public IntPtr SumBytes;
  public IntPtr CountByte;
  public IntPtr BitsetPopCount;
  public IntPtr Utf8Validate;
  public IntPtr AsciiIEqual;
  public IntPtr BytesIndexOf;
  public IntPtr MemCopy;
  public IntPtr MemSet;
  public IntPtr ToLowerAscii;
  public IntPtr ToUpperAscii;
  public IntPtr MemReverse;
  public IntPtr MinMaxBytes;
}

public static class FafafaSimdNative {
  [DllImport(@"$LibraryLiteral", CallingConvention = CallingConvention.Cdecl, EntryPoint = "fafafa_simd_abi_version_major")]
  public static extern UInt16 AbiVersionMajor();

  [DllImport(@"$LibraryLiteral", CallingConvention = CallingConvention.Cdecl, EntryPoint = "fafafa_simd_abi_version_minor")]
  public static extern UInt16 AbiVersionMinor();

  [DllImport(@"$LibraryLiteral", CallingConvention = CallingConvention.Cdecl, EntryPoint = "fafafa_simd_abi_signature")]
  public static extern void AbiSignature(out UInt64 hi, out UInt64 lo);

  [DllImport(@"$LibraryLiteral", CallingConvention = CallingConvention.Cdecl, EntryPoint = "fafafa_simd_get_backend_pod_info")]
  [return: MarshalAs(UnmanagedType.I4)]
  public static extern Int32 GetBackendPodInfo(UInt32 backendId, out FafafaSimdBackendPodInfo info);

  [DllImport(@"$LibraryLiteral", CallingConvention = CallingConvention.Cdecl, EntryPoint = "fafafa_simd_backend_name")]
  public static extern IntPtr BackendName(UInt32 backendId);

  [DllImport(@"$LibraryLiteral", CallingConvention = CallingConvention.Cdecl, EntryPoint = "fafafa_simd_backend_description")]
  public static extern IntPtr BackendDescription(UInt32 backendId);

  [DllImport(@"$LibraryLiteral", CallingConvention = CallingConvention.Cdecl, EntryPoint = "fafafa_simd_get_public_api")]
  public static extern IntPtr GetPublicApi();
}

[UnmanagedFunctionPointer(CallingConvention.Cdecl)]
public delegate Int32 FafafaSimdMemEqualFn(IntPtr a, IntPtr b, UIntPtr len);

[UnmanagedFunctionPointer(CallingConvention.Cdecl)]
public delegate IntPtr FafafaSimdMemFindByteFn(IntPtr p, UIntPtr len, Byte value);

[UnmanagedFunctionPointer(CallingConvention.Cdecl)]
public delegate Int32 FafafaSimdMemDiffRangeFn(IntPtr a, IntPtr b, UIntPtr len, out UIntPtr firstDiff, out UIntPtr lastDiff);

[UnmanagedFunctionPointer(CallingConvention.Cdecl)]
public delegate UInt64 FafafaSimdSumBytesFn(IntPtr p, UIntPtr len);

[UnmanagedFunctionPointer(CallingConvention.Cdecl)]
public delegate UIntPtr FafafaSimdCountByteFn(IntPtr p, UIntPtr len, Byte value);

[UnmanagedFunctionPointer(CallingConvention.Cdecl)]
public delegate UIntPtr FafafaSimdBitsetPopCountFn(IntPtr p, UIntPtr len);

[UnmanagedFunctionPointer(CallingConvention.Cdecl)]
public delegate Int32 FafafaSimdUtf8ValidateFn(IntPtr p, UIntPtr len);

[UnmanagedFunctionPointer(CallingConvention.Cdecl)]
public delegate Int32 FafafaSimdAsciiIEqualFn(IntPtr a, IntPtr b, UIntPtr len);

[UnmanagedFunctionPointer(CallingConvention.Cdecl)]
public delegate IntPtr FafafaSimdBytesIndexOfFn(IntPtr haystack, UIntPtr haystackLen, IntPtr needle, UIntPtr needleLen);

[UnmanagedFunctionPointer(CallingConvention.Cdecl)]
public delegate void FafafaSimdMemCopyFn(IntPtr src, IntPtr dst, UIntPtr len);

[UnmanagedFunctionPointer(CallingConvention.Cdecl)]
public delegate void FafafaSimdMemSetFn(IntPtr dst, UIntPtr len, Byte value);

[UnmanagedFunctionPointer(CallingConvention.Cdecl)]
public delegate void FafafaSimdToLowerAsciiFn(IntPtr p, UIntPtr len);

[UnmanagedFunctionPointer(CallingConvention.Cdecl)]
public delegate void FafafaSimdToUpperAsciiFn(IntPtr p, UIntPtr len);

[UnmanagedFunctionPointer(CallingConvention.Cdecl)]
public delegate void FafafaSimdMemReverseFn(IntPtr p, UIntPtr len);

[UnmanagedFunctionPointer(CallingConvention.Cdecl)]
public delegate void FafafaSimdMinMaxBytesFn(IntPtr p, UIntPtr len, out Byte minVal, out Byte maxVal);
"@

Add-Type -TypeDefinition $TypeSource

[UInt32]$FAF_SIMD_ABI_FLAG_SUPPORTED_ON_CPU = 1
[UInt32]$FAF_SIMD_ABI_FLAG_REGISTERED = 2
[UInt32]$FAF_SIMD_ABI_FLAG_DISPATCHABLE = 4
[UInt32]$FAF_SIMD_ABI_FLAG_ACTIVE = 8
[UInt32]$FAF_SIMD_ABI_FLAG_EXPERIMENTAL = 16

$abiMajor = [FafafaSimdNative]::AbiVersionMajor()
$abiMinor = [FafafaSimdNative]::AbiVersionMinor()
if ($abiMajor -le 0) {
  throw "[PUBLICABI] ABI major should be > 0"
}

[UInt64]$sigHi = 0
[UInt64]$sigLo = 0
[FafafaSimdNative]::AbiSignature([ref]$sigHi, [ref]$sigLo)
if ($sigHi -eq 0 -or $sigLo -eq 0) {
  throw "[PUBLICABI] ABI signature should not be zero"
}

$backendInfo = New-Object FafafaSimdBackendPodInfo
$ok = [FafafaSimdNative]::GetBackendPodInfo(0, [ref]$backendInfo)
if ($ok -eq 0) {
  throw "[PUBLICABI] scalar backend pod info query failed"
}
if ($backendInfo.StructSize -ne [System.Runtime.InteropServices.Marshal]::SizeOf([type][FafafaSimdBackendPodInfo])) {
  throw "[PUBLICABI] backend pod struct size mismatch"
}
if ($backendInfo.BackendId -ne 0) {
  throw "[PUBLICABI] scalar backend id mismatch"
}
if (($backendInfo.Flags -band $FAF_SIMD_ABI_FLAG_SUPPORTED_ON_CPU) -eq 0) {
  throw "[PUBLICABI] scalar backend should be supported_on_cpu"
}
if (($backendInfo.Flags -band $FAF_SIMD_ABI_FLAG_REGISTERED) -eq 0) {
  throw "[PUBLICABI] scalar backend should be registered"
}
if (($backendInfo.Flags -band $FAF_SIMD_ABI_FLAG_DISPATCHABLE) -eq 0) {
  throw "[PUBLICABI] scalar backend should be dispatchable"
}

$backendNamePtr = [FafafaSimdNative]::BackendName(0)
$backendDescPtr = [FafafaSimdNative]::BackendDescription(0)
if ($backendNamePtr -eq [IntPtr]::Zero -or [System.Runtime.InteropServices.Marshal]::PtrToStringAnsi($backendNamePtr) -eq "") {
  throw "[PUBLICABI] backend name missing"
}
if ($backendDescPtr -eq [IntPtr]::Zero -or [System.Runtime.InteropServices.Marshal]::PtrToStringAnsi($backendDescPtr) -eq "") {
  throw "[PUBLICABI] backend description missing"
}

$apiPtr = [FafafaSimdNative]::GetPublicApi()
if ($apiPtr -eq [IntPtr]::Zero) {
  throw "[PUBLICABI] public api pointer is null"
}

$api = [System.Runtime.InteropServices.Marshal]::PtrToStructure($apiPtr, [type][FafafaSimdPublicApi])
if ($api.StructSize -ne [System.Runtime.InteropServices.Marshal]::SizeOf([type][FafafaSimdPublicApi])) {
  throw "[PUBLICABI] public api struct size mismatch"
}
if ($api.AbiVersionMajor -ne $abiMajor -or $api.AbiVersionMinor -ne $abiMinor) {
  throw "[PUBLICABI] public api version mismatch"
}
if ($api.AbiSignatureHi -ne $sigHi -or $api.AbiSignatureLo -ne $sigLo) {
  throw "[PUBLICABI] public api signature mismatch"
}
if ($api.ActiveFlags -eq 0) {
  throw "[PUBLICABI] public api active flags should not be zero"
}
if (($api.ActiveFlags -band $FAF_SIMD_ABI_FLAG_SUPPORTED_ON_CPU) -eq 0) {
  throw "[PUBLICABI] public api active flags should include supported_on_cpu"
}
if (($api.ActiveFlags -band $FAF_SIMD_ABI_FLAG_REGISTERED) -eq 0) {
  throw "[PUBLICABI] public api active flags should include registered"
}
if (($api.ActiveFlags -band $FAF_SIMD_ABI_FLAG_DISPATCHABLE) -eq 0) {
  throw "[PUBLICABI] public api active flags should include dispatchable"
}
if (($api.ActiveFlags -band $FAF_SIMD_ABI_FLAG_ACTIVE) -eq 0) {
  throw "[PUBLICABI] public api active flags should include active"
}

$activeBackendInfo = New-Object FafafaSimdBackendPodInfo
$ok = [FafafaSimdNative]::GetBackendPodInfo($api.ActiveBackendId, [ref]$activeBackendInfo)
if ($ok -eq 0) {
  throw "[PUBLICABI] active backend pod info query failed"
}
if ($activeBackendInfo.StructSize -ne [System.Runtime.InteropServices.Marshal]::SizeOf([type][FafafaSimdBackendPodInfo])) {
  throw "[PUBLICABI] active backend pod struct size mismatch"
}
if ($activeBackendInfo.BackendId -ne $api.ActiveBackendId) {
  throw "[PUBLICABI] active backend id mismatch"
}
if ($activeBackendInfo.Flags -ne $api.ActiveFlags) {
  throw "[PUBLICABI] active backend flags should match public api active flags"
}

$activeBackendNamePtr = [FafafaSimdNative]::BackendName($api.ActiveBackendId)
$activeBackendDescPtr = [FafafaSimdNative]::BackendDescription($api.ActiveBackendId)
if ($activeBackendNamePtr -eq [IntPtr]::Zero -or [System.Runtime.InteropServices.Marshal]::PtrToStringAnsi($activeBackendNamePtr) -eq "") {
  throw "[PUBLICABI] active backend name missing"
}
if ($activeBackendDescPtr -eq [IntPtr]::Zero -or [System.Runtime.InteropServices.Marshal]::PtrToStringAnsi($activeBackendDescPtr) -eq "") {
  throw "[PUBLICABI] active backend description missing"
}
if ($api.ActiveBackendId -ne 0 -and (($backendInfo.Flags -band $FAF_SIMD_ABI_FLAG_ACTIVE) -ne 0)) {
  throw "[PUBLICABI] scalar backend should not be active when active backend differs"
}

if ($ValidateOnly) {
  Write-Host "[PUBLICABI] EXPORT OK"
  exit 0
}

$memEqual = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($api.MemEqual, [type][FafafaSimdMemEqualFn])
$memFindByte = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($api.MemFindByte, [type][FafafaSimdMemFindByteFn])
$memDiffRange = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($api.MemDiffRange, [type][FafafaSimdMemDiffRangeFn])
$sumBytes = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($api.SumBytes, [type][FafafaSimdSumBytesFn])
$countByte = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($api.CountByte, [type][FafafaSimdCountByteFn])
$bitsetPopCount = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($api.BitsetPopCount, [type][FafafaSimdBitsetPopCountFn])
$utf8Validate = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($api.Utf8Validate, [type][FafafaSimdUtf8ValidateFn])
$asciiIEqual = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($api.AsciiIEqual, [type][FafafaSimdAsciiIEqualFn])
$bytesIndexOf = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($api.BytesIndexOf, [type][FafafaSimdBytesIndexOfFn])
$memCopy = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($api.MemCopy, [type][FafafaSimdMemCopyFn])
$memSet = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($api.MemSet, [type][FafafaSimdMemSetFn])
$toLowerAscii = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($api.ToLowerAscii, [type][FafafaSimdToLowerAsciiFn])
$toUpperAscii = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($api.ToUpperAscii, [type][FafafaSimdToUpperAsciiFn])
$memReverse = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($api.MemReverse, [type][FafafaSimdMemReverseFn])
$minMaxBytes = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($api.MinMaxBytes, [type][FafafaSimdMinMaxBytesFn])

$a = New-Object byte[] 32
$b = New-Object byte[] 32
$c = New-Object byte[] 32
for ($i = 0; $i -lt $a.Length; $i++) {
  $a[$i] = [byte](($i * 7) -band 0xFF)
  $b[$i] = $a[$i]
}
$b[17] = 0xAA

$ga = [System.Runtime.InteropServices.GCHandle]::Alloc($a, [System.Runtime.InteropServices.GCHandleType]::Pinned)
$gb = [System.Runtime.InteropServices.GCHandle]::Alloc($b, [System.Runtime.InteropServices.GCHandleType]::Pinned)
$gc = [System.Runtime.InteropServices.GCHandle]::Alloc($c, [System.Runtime.InteropServices.GCHandleType]::Pinned)

$utf8Bytes = [System.Text.Encoding]::UTF8.GetBytes("simd-publicabi")
$asciiA = [System.Text.Encoding]::ASCII.GetBytes("AbCd")
$asciiB = [System.Text.Encoding]::ASCII.GetBytes("aBcD")
$lowerBuf = [System.Text.Encoding]::ASCII.GetBytes("AbCdEf012")
$upperBuf = [System.Text.Encoding]::ASCII.GetBytes("AbCdEf012")
$revBuf = [byte[]](1, 2, 3, 4, 5, 6, 7, 8)
$mmBuf = [byte[]](3, 7, 2, 9, 5)
$needleHit = [byte[]]($a[7], $a[8], $a[9])
$needleMiss = [byte[]](0xFE, 0xED, 0xDC)
$gu = [System.Runtime.InteropServices.GCHandle]::Alloc($utf8Bytes, [System.Runtime.InteropServices.GCHandleType]::Pinned)
$gaa = [System.Runtime.InteropServices.GCHandle]::Alloc($asciiA, [System.Runtime.InteropServices.GCHandleType]::Pinned)
$gab = [System.Runtime.InteropServices.GCHandle]::Alloc($asciiB, [System.Runtime.InteropServices.GCHandleType]::Pinned)
$glower = [System.Runtime.InteropServices.GCHandle]::Alloc($lowerBuf, [System.Runtime.InteropServices.GCHandleType]::Pinned)
$gupper = [System.Runtime.InteropServices.GCHandle]::Alloc($upperBuf, [System.Runtime.InteropServices.GCHandleType]::Pinned)
$grev = [System.Runtime.InteropServices.GCHandle]::Alloc($revBuf, [System.Runtime.InteropServices.GCHandleType]::Pinned)
$gmm = [System.Runtime.InteropServices.GCHandle]::Alloc($mmBuf, [System.Runtime.InteropServices.GCHandleType]::Pinned)
$gnh = [System.Runtime.InteropServices.GCHandle]::Alloc($needleHit, [System.Runtime.InteropServices.GCHandleType]::Pinned)
$gnm = [System.Runtime.InteropServices.GCHandle]::Alloc($needleMiss, [System.Runtime.InteropServices.GCHandleType]::Pinned)

try {
  if ($memEqual.Invoke($ga.AddrOfPinnedObject(), $ga.AddrOfPinnedObject(), [UIntPtr]$a.Length) -eq 0) {
    throw "[PUBLICABI] mem_equal parity failed"
  }
  if ([Int64]$memFindByte.Invoke($gb.AddrOfPinnedObject(), [UIntPtr]$b.Length, [byte]0xAA) -ne 17) {
    throw "[PUBLICABI] mem_find_byte parity failed"
  }
  [UIntPtr]$firstDiff = [UIntPtr]::Zero
  [UIntPtr]$lastDiff = [UIntPtr]::Zero
  if ($memDiffRange.Invoke($ga.AddrOfPinnedObject(), $gb.AddrOfPinnedObject(), [UIntPtr]$a.Length, [ref]$firstDiff, [ref]$lastDiff) -eq 0) {
    throw "[PUBLICABI] mem_diff_range should detect mismatch"
  }
  if ($firstDiff.ToUInt64() -ne 17 -or $lastDiff.ToUInt64() -ne 17) {
    throw "[PUBLICABI] mem_diff_range parity failed"
  }
  if ($sumBytes.Invoke($ga.AddrOfPinnedObject(), [UIntPtr]$a.Length) -eq 0) {
    throw "[PUBLICABI] sum_bytes returned zero unexpectedly"
  }
  if ([UInt64]$countByte.Invoke($gb.AddrOfPinnedObject(), [UIntPtr]$b.Length, [byte]0xAA).ToUInt64() -ne 1) {
    throw "[PUBLICABI] count_byte parity failed"
  }
  if ([UInt64]$bitsetPopCount.Invoke($ga.AddrOfPinnedObject(), [UIntPtr]$a.Length).ToUInt64() -eq 0) {
    throw "[PUBLICABI] bitset_popcount returned zero unexpectedly"
  }
  if ($utf8Validate.Invoke($gu.AddrOfPinnedObject(), [UIntPtr]$utf8Bytes.Length) -eq 0) {
    throw "[PUBLICABI] utf8_validate parity failed"
  }
  if ($asciiIEqual.Invoke($gaa.AddrOfPinnedObject(), $gab.AddrOfPinnedObject(), [UIntPtr]$asciiA.Length) -eq 0) {
    throw "[PUBLICABI] ascii_iequal parity failed"
  }
  if ([Int64]$bytesIndexOf.Invoke($ga.AddrOfPinnedObject(), [UIntPtr]$a.Length, $gnh.AddrOfPinnedObject(), [UIntPtr]$needleHit.Length) -ne 7) {
    throw "[PUBLICABI] bytes_index_of hit parity failed"
  }
  if ([Int64]$bytesIndexOf.Invoke($ga.AddrOfPinnedObject(), [UIntPtr]$a.Length, $gnm.AddrOfPinnedObject(), [UIntPtr]$needleMiss.Length) -ne -1) {
    throw "[PUBLICABI] bytes_index_of miss parity failed"
  }

  $memCopy.Invoke($ga.AddrOfPinnedObject(), $gc.AddrOfPinnedObject(), [UIntPtr]$a.Length)
  for ($i = 0; $i -lt $a.Length; $i++) {
    if ($c[$i] -ne $a[$i]) {
      throw "[PUBLICABI] mem_copy parity failed"
    }
  }

  $memSet.Invoke($gc.AddrOfPinnedObject(), [UIntPtr]$c.Length, [byte]0x5A)
  for ($i = 0; $i -lt $c.Length; $i++) {
    if ($c[$i] -ne [byte]0x5A) {
      throw "[PUBLICABI] mem_set parity failed"
    }
  }

  $toLowerAscii.Invoke($glower.AddrOfPinnedObject(), [UIntPtr]$lowerBuf.Length)
  if ([System.Text.Encoding]::ASCII.GetString($lowerBuf) -cne "abcdef012") {
    throw "[PUBLICABI] to_lower_ascii parity failed"
  }

  $toUpperAscii.Invoke($gupper.AddrOfPinnedObject(), [UIntPtr]$upperBuf.Length)
  if ([System.Text.Encoding]::ASCII.GetString($upperBuf) -cne "ABCDEF012") {
    throw "[PUBLICABI] to_upper_ascii parity failed"
  }

  $memReverse.Invoke($grev.AddrOfPinnedObject(), [UIntPtr]$revBuf.Length)
  for ($i = 0; $i -lt $revBuf.Length; $i++) {
    if ($revBuf[$i] -ne [byte]($revBuf.Length - $i)) {
      throw "[PUBLICABI] mem_reverse parity failed"
    }
  }

  [byte]$mmMin = 0
  [byte]$mmMax = 0
  $minMaxBytes.Invoke($gmm.AddrOfPinnedObject(), [UIntPtr]$mmBuf.Length, [ref]$mmMin, [ref]$mmMax)
  if ($mmMin -ne [byte]2 -or $mmMax -ne [byte]9) {
    throw "[PUBLICABI] min_max_bytes parity failed"
  }
}
finally {
  $ga.Free()
  $gb.Free()
  $gc.Free()
  $gu.Free()
  $gaa.Free()
  $gab.Free()
  $glower.Free()
  $gupper.Free()
  $grev.Free()
  $gmm.Free()
  $gnh.Free()
  $gnm.Free()
}

Write-Host "[PUBLICABI] OK"
exit 0
