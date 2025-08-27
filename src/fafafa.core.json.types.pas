unit fafafa.core.json.types;

{$MODE OBJFPC}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

// Central type aliases for JSON flags and error codes to avoid duplication
// Current implementation delegates to fafafa.core.json.core. This allows
// facade and other units to depend on a stable type location even if the
// underlying implementation refactors.

uses
  SysUtils,
  fafafa.core.json.core;

type
  // Reader/Writer flags
  TJsonReadFlags       = fafafa.core.json.core.TJsonReadFlags;
  TJsonWriteFlags      = fafafa.core.json.core.TJsonWriteFlags;

  // Read/Write error codes and records
  TJsonErrorCode       = fafafa.core.json.core.TJsonErrorCode;
  TJsonError           = fafafa.core.json.core.TJsonError;

  TJsonWriteErrorCode  = fafafa.core.json.core.TJsonWriteErrorCode;
  TJsonWriteError      = fafafa.core.json.core.TJsonWriteError;

  // Pointer errors
  TJsonPointerErrorCode = fafafa.core.json.core.TJsonPointerErrorCode;
  TJsonPointerError     = fafafa.core.json.core.TJsonPointerError;

implementation

end.

