unit fafafa.core.json.patch.helpers;
{*
  JSON Patch/Merge Patch helper facade (draft)
  -------------------------------------------------
  Goal:
    - Provide Try* + ErrMsg convenience APIs for applying JSON Merge Patch (RFC 7386)
      and JSON Patch (RFC 6902) to an immutable document while keeping the main
      facade thin and stable.

  Design (Best Practice):
    - Do NOT mutate the input ADoc; on success, return a brand new Updated document
      (ideally using the same allocator as ADoc if applicable).
    - On failure, return False and set ErrMsg (lowercase, concise, aligned with
      fixed-layer wording like 'invalid arguments', 'patch must be array', etc.).
    - Implementation path (to be added):
        immutable root -> clone to mutable -> apply patch/merge -> write back to
        new immutable document -> return via Updated.

  Note:
    - This unit is an interface + placeholder implementation draft. It compiles,
      but functions currently return False with 'not implemented'.
    - When implementing, delegate to src/fafafa.core.json.patch.pas & .ptr, and use
      JsonWrapDocument / facade writer as appropriate.
*}

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.json; // facade is json now

{*
  Try to apply a JSON Merge Patch (RFC 7386) provided as a JSON string.
  - ADoc:     source immutable document (will not be modified)
  - PatchJson: UTF-8 JSON text of the merge patch object
  - Updated:  on success, returns a NEW immutable document
  - ErrMsg:   on failure, short reason aligned with fixed-layer wording
  Returns True on success, False on failure.
*}
function TryApplyJsonMergePatch(ADoc: IJsonDocument; const PatchJson: String;
  out Updated: IJsonDocument; out ErrMsg: String): Boolean;

{*
  Same as above but takes a pointer and length to the patch JSON text.
*}
function TryApplyJsonMergePatchN(ADoc: IJsonDocument; Patch: PChar; PatchLen: SizeUInt;
  out Updated: IJsonDocument; out ErrMsg: String): Boolean;

{*
  Try to apply a JSON Patch (RFC 6902) provided as a JSON string.
  - PatchJson should be a JSON array of operations.
*}
function TryApplyJsonPatch(ADoc: IJsonDocument; const PatchJson: String;
  out Updated: IJsonDocument; out ErrMsg: String): Boolean;

{*
  Same as above but takes a pointer and length to the patch JSON text.
*}
function TryApplyJsonPatchN(ADoc: IJsonDocument; Patch: PChar; PatchLen: SizeUInt;
  out Updated: IJsonDocument; out ErrMsg: String): Boolean;


const
  // keep lower-case, concise messages aligned with fixed-layer wording
  JSON_ERR_INVALID_ARGUMENTS   = 'invalid arguments';
  JSON_ERR_PARSE_SOURCE_FAILED = 'parse source failed';
  JSON_ERR_INVALID_PATCH       = 'invalid patch';
  JSON_ERR_CLONE_FAILED        = 'clone failed';
  JSON_ERR_MERGE_FAILED        = 'merge failed';


implementation


uses
  fafafa.core.mem.allocator,
  fafafa.core.json.core,
  fafafa.core.json.mut.util,
  fafafa.core.json.patch;

// moved to shared unit fafafa.core.json.mut.util


function TryApplyJsonMergePatch(ADoc: IJsonDocument; const PatchJson: String;
  out Updated: IJsonDocument; out ErrMsg: String): Boolean;
var
  Al: IAllocator;
  SrcText, OutText: String;
  SrcDoc, PatchDoc: TJsonDocument;
  MutDoc: TJsonMutDocument;
  MutRoot: PJsonMutValue;
  PatRoot: PJsonValue;
begin
  Updated := nil; ErrMsg := '';
  if (ADoc = nil) then begin ErrMsg := JSON_ERR_INVALID_ARGUMENTS; Exit(False); end;

  Al := ADoc.Allocator;
  // Serialize current doc to text, then parse to fixed immutable doc
  SrcText := NewJsonWriter.WriteToString(ADoc, []);
  SrcDoc := JsonRead(PChar(SrcText), Length(SrcText), []);
  if not Assigned(SrcDoc) then begin ErrMsg := JSON_ERR_PARSE_SOURCE_FAILED; Exit(False); end;

  // parse patch object
  PatchDoc := JsonRead(PChar(PatchJson), Length(PatchJson), []);
  if not Assigned(PatchDoc) then begin SrcDoc.Free; ErrMsg := JSON_ERR_INVALID_PATCH; Exit(False); end;
  try
    PatRoot := JsonDocGetRoot(PatchDoc);
    // clone immutable root to mutable
    MutDoc := JsonMutDocNew(Al);
    MutRoot := CloneImmToMut(MutDoc, JsonDocGetRoot(SrcDoc));
    if not Assigned(MutRoot) then begin ErrMsg := JSON_ERR_CLONE_FAILED; Exit(False); end;
    // apply merge patch
    MutRoot := JsonMergePatch(MutDoc, MutRoot, PatRoot);
    if not Assigned(MutRoot) then begin ErrMsg := JSON_ERR_MERGE_FAILED; Exit(False); end;
    // ensure document root reflects latest tree before serialization
    JsonMutDocSetRoot(MutDoc, MutRoot);
    // write back to immutable text and parse via facade reader
    OutText := WriteJsonMutValue(MutRoot, [], 0);
    // Use a fresh allocator for the resulting immutable document to avoid lifetime/ownership conflicts
    Updated := NewJsonReader(GetRtlAllocator).ReadFromString(OutText, []);
    Result := Assigned(Updated);
  finally
    PatchDoc.Free;
    SrcDoc.Free;
    MutDoc.Free;
  end;
end;

function TryApplyJsonMergePatchN(ADoc: IJsonDocument; Patch: PChar; PatchLen: SizeUInt;
  out Updated: IJsonDocument; out ErrMsg: String): Boolean;
var S: String;
begin
  SetString(S, Patch, PatchLen);
  Result := TryApplyJsonMergePatch(ADoc, S, Updated, ErrMsg);
end;

function TryApplyJsonPatch(ADoc: IJsonDocument; const PatchJson: String;
  out Updated: IJsonDocument; out ErrMsg: String): Boolean;
var
  Al: IAllocator;
  SrcText, OutText: String;
  SrcDoc, PatchDoc: TJsonDocument;
  MutDoc: TJsonMutDocument;
  MutRoot: PJsonMutValue;
  PatArr: PJsonValue;

begin
  Updated := nil; ErrMsg := '';
  if (ADoc = nil) then begin ErrMsg := JSON_ERR_INVALID_ARGUMENTS; Exit(False); end;

  Al := ADoc.Allocator;
  // Serialize current doc to text, then parse to fixed immutable doc
  SrcText := NewJsonWriter.WriteToString(ADoc, []);
  SrcDoc := JsonRead(PChar(SrcText), Length(SrcText), []);
  if not Assigned(SrcDoc) then begin ErrMsg := JSON_ERR_PARSE_SOURCE_FAILED; Exit(False); end;

  // parse patch array
  PatchDoc := JsonRead(PChar(PatchJson), Length(PatchJson), []);
  if not Assigned(PatchDoc) then begin SrcDoc.Free; ErrMsg := JSON_ERR_INVALID_PATCH; Exit(False); end;
  try
    PatArr := JsonDocGetRoot(PatchDoc);
    // clone immutable root to mutable
    MutDoc := JsonMutDocNew(Al);
    MutRoot := CloneImmToMut(MutDoc, JsonDocGetRoot(SrcDoc));
    if not Assigned(MutRoot) then begin ErrMsg := JSON_ERR_CLONE_FAILED; Exit(False); end;
    // apply patch
    if not JsonPatchApply(MutDoc, MutRoot, PatArr, ErrMsg) then Exit(False);
    // ensure document root reflects latest tree before serialization
    JsonMutDocSetRoot(MutDoc, MutRoot);
    // write back to immutable text and parse via facade reader
    OutText := WriteJsonMutValue(MutRoot, [], 0);
    // Use a fresh allocator for the resulting immutable document to avoid lifetime/ownership conflicts
    Updated := NewJsonReader(GetRtlAllocator).ReadFromString(OutText, []);
    Result := Assigned(Updated);
  finally
    PatchDoc.Free;
    SrcDoc.Free;
    MutDoc.Free;
  end;
end;

function TryApplyJsonPatchN(ADoc: IJsonDocument; Patch: PChar; PatchLen: SizeUInt;
  out Updated: IJsonDocument; out ErrMsg: String): Boolean;
var S: String;
begin
  SetString(S, Patch, PatchLen);
  Result := TryApplyJsonPatch(ADoc, S, Updated, ErrMsg);
end;

end.

