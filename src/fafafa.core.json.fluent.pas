{$CODEPAGE UTF8}
unit fafafa.core.json.fluent;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

{ Modern fluent-style, type-safe(ish) wrappers atop fafafa.core.json.*
  - Non-breaking: does not change existing APIs; only adds a thin wrapper.
  - Ownership: TJsonDocF owns immutable TJsonDocument; TJsonBuilderF owns TJsonMutDocument
    unless Detach() is called.
  - Chainable builder for common object/array construction.
  - Read side: convenient Parse + Ptr + AsJson. }

interface

uses
  SysUtils, Classes,
  fafafa.core.mem.allocator,
  fafafa.core.json.core,
  fafafa.core.json.ptr;

Type
  // Lightweight typed view over immutable node
  TJsonNodeF = record
    Val: PJsonValue;
    // type checks
    function IsNull: Boolean; inline;
    function IsBool: Boolean; inline;
    function IsNum: Boolean; inline;
    function IsStr: Boolean; inline;
    function IsArr: Boolean; inline;
    function IsObj: Boolean; inline;
    // getters (Try*/OrDefault)
    function TryAsBool(out AVal: Boolean): Boolean; inline;
    function TryAsInt(out AVal: Int64): Boolean; inline;
    function TryAsReal(out AVal: Double): Boolean; inline;
    function TryAsStr(out AVal: String): Boolean;
    function AsBoolOrDefault(ADef: Boolean): Boolean; inline;
    function AsIntOrDefault(ADef: Int64): Int64; inline;
    function AsRealOrDefault(ADef: Double): Double; inline;
    function AsStrOrDefault(const ADef: String): String;
  end;

  // Fluent immutable document wrapper (reference-counted)
  IJsonDocF = interface
    ['{C7E8C1B9-7E5A-49D5-9B5A-6A49D7E7A2F2}']
    function Root: PJsonValue;
    function Ptr(const APath: String): PJsonValue;
    function AsJson(AFlags: TJsonWriteFlags = []; AIndent: Integer = 0): String;
    function View(const APath: String): TJsonNodeF;
    function NodeRoot: TJsonNodeF;
    function SaveToFile(const APath: String; AFlags: TJsonWriteFlags = []): Boolean;
  end;

  TJsonDocF = class(TInterfacedObject, IJsonDocF)
  private
    FDoc: TJsonDocument;
  public
    constructor Create(ADoc: TJsonDocument);
    destructor Destroy; override;
    function Root: PJsonValue;
    function Ptr(const APath: String): PJsonValue;
    function AsJson(AFlags: TJsonWriteFlags = []; AIndent: Integer = 0): String;
    function View(const APath: String): TJsonNodeF;
    function NodeRoot: TJsonNodeF;
    function SaveToFile(const APath: String; AFlags: TJsonWriteFlags = []): Boolean;
  end;

  // Fluent mutable document builder
  // Builder fluent nesting helpers (Begin*/End*)
  TJsonBuilderScope = (jbsNone, jbsObj, jbsArr);

  TJsonBuilderF = class
  private
    FDoc: TJsonMutDocument;
    FRoot: PJsonMutValue;
    FCursor: PJsonMutValue;
    FStack: array of PJsonMutValue;
    FScope: array of TJsonBuilderScope;
    procedure PushCursor(AScope: TJsonBuilderScope); inline;
    function PopCursor(out AScope: TJsonBuilderScope): Boolean; inline;
    function WriteJsonMutValue(AVal: PJsonMutValue; AFlags: TJsonWriteFlags; AIndent: Integer): String;
    function IsCursorObj: Boolean; inline;
    function IsCursorArr: Boolean; inline;
  public
    constructor Create(AAllocator: TAllocator);
    destructor Destroy; override;

    // Root constructors
    function Obj: TJsonBuilderF; overload;             // make {} as root and set cursor
    function Arr: TJsonBuilderF; overload;             // make [] as root and set cursor

    // Object member put (requires object cursor)
    function PutStr(const AKey, AVal: String): TJsonBuilderF;
    function PutInt(const AKey: String; const AVal: Int64): TJsonBuilderF;
    function PutBool(const AKey: String; const AVal: Boolean): TJsonBuilderF;

    // Array item add (requires array cursor)
    function AddStr(const AVal: String): TJsonBuilderF;
    function AddInt(const AVal: Int64): TJsonBuilderF;
    function AddBool(const AVal: Boolean): TJsonBuilderF;

    // Fluent nesting
    function BeginObj(const AKey: String): TJsonBuilderF; overload;   // parent must be obj
    function BeginArr(const AKey: String): TJsonBuilderF; overload;   // parent must be obj
    function ArrAddObj: TJsonBuilderF;                                // parent must be arr
    function ArrAddArr: TJsonBuilderF;                                // parent must be arr
    function EndObj: TJsonBuilderF;
    function EndArr: TJsonBuilderF;

    // Output convenience
    function ToJson(AFlags: TJsonWriteFlags = []; AIndent: Integer = 0): String;
    function SaveToFile(const APath: String; AFlags: TJsonWriteFlags = []; AIndent: Integer = 0): Boolean;

    // Finalization / ownership
    function SetRoot: TJsonBuilderF; // ensure FRoot assigned to document root
    function Detach: TJsonMutDocument; // transfer ownership to caller (FDoc := nil)

    // Accessors
    function Doc: TJsonMutDocument; inline;
    function Cursor: PJsonMutValue; inline;
  end;

  // Facade entry points
  JsonF = record
  public
    class function Parse(const AText: String): IJsonDocF; static; overload;
    class function Parse(const AText: String; AFlags: TJsonReadFlags; AAllocator: TAllocator;
      out AError: TJsonError): IJsonDocF; static; overload;
    class function ParseFile(const APath: String): IJsonDocF; static; overload;
    class function ParseFile(const APath: String; AFlags: TJsonReadFlags; AAllocator: TAllocator;
      out AError: TJsonError): IJsonDocF; static; overload;
    class function ParseStream(AStream: TStream): IJsonDocF; static; overload;
    class function ParseStream(AStream: TStream; AFlags: TJsonReadFlags; AAllocator: TAllocator;
      out AError: TJsonError): IJsonDocF; static; overload;
    class function NewBuilder(AAllocator: TAllocator = nil): TJsonBuilderF; static;
  end;

implementation

{ TJsonDocF }
constructor TJsonDocF.Create(ADoc: TJsonDocument);
begin
  inherited Create;
  FDoc := ADoc;
end;

destructor TJsonDocF.Destroy;
begin
  if Assigned(FDoc) then
    FDoc.Free;
  inherited Destroy;
end;

function TJsonDocF.Root: PJsonValue;
begin
  if Assigned(FDoc) then
    Result := JsonDocGetRoot(FDoc)
  else
    Result := nil;
end;

function TJsonDocF.Ptr(const APath: String): PJsonValue;
var R: PJsonValue;
begin
  R := nil;
  if (APath = '') then Exit(Root);
  if Assigned(FDoc) then
    R := JsonPtrGet(JsonDocGetRoot(FDoc), PChar(APath));
  Result := R;
end;

function TJsonDocF.AsJson(AFlags: TJsonWriteFlags; AIndent: Integer): String;
var R: PJsonValue;
begin
  R := Root;
  if not Assigned(R) then Exit('null');
  Result := WriteJsonValue(R, AFlags, AIndent);
end;

function TJsonDocF.View(const APath: String): TJsonNodeF;
begin
  Result.Val := Ptr(APath);
end;

function TJsonDocF.NodeRoot: TJsonNodeF;
begin
  Result.Val := Root;
end;

function TJsonDocF.SaveToFile(const APath: String; AFlags: TJsonWriteFlags): Boolean;
var Err: TJsonWriteError; Alc: TAllocator;
begin
  Alc := GetRtlAllocator();
  Err := Default(TJsonWriteError);
  Result := JsonWriteFile(APath, FDoc, AFlags, Alc, Err);
end;



{ TJsonBuilderF }
constructor TJsonBuilderF.Create(AAllocator: TAllocator);
begin
  inherited Create;
  if not Assigned(AAllocator) then
    AAllocator := GetRtlAllocator();
  FDoc := JsonMutDocNew(AAllocator);
  FRoot := nil;
  FCursor := nil;
  SetLength(FStack, 0);
  SetLength(FScope, 0);
end;

destructor TJsonBuilderF.Destroy;
begin
  if Assigned(FDoc) then
    FDoc.Free;
  inherited Destroy;
end;

procedure TJsonBuilderF.PushCursor(AScope: TJsonBuilderScope);
begin
  SetLength(FStack, Length(FStack)+1);
  SetLength(FScope, Length(FScope)+1);
  FStack[High(FStack)] := FCursor;
  FScope[High(FScope)] := AScope;
end;

function TJsonBuilderF.PopCursor(out AScope: TJsonBuilderScope): Boolean;
begin
  Result := Length(FStack) > 0;
  if Result then
  begin
    AScope := FScope[High(FScope)];
    SetLength(FScope, Length(FScope)-1);
    FCursor := FStack[High(FStack)];
    SetLength(FStack, Length(FStack)-1);
  end
  else
    AScope := jbsNone;
end;

function TJsonBuilderF.IsCursorObj: Boolean; inline;
begin
  Result := Assigned(FCursor) and (UnsafeGetType(PJsonValue(FCursor)) = YYJSON_TYPE_OBJ);
end;

function TJsonBuilderF.IsCursorArr: Boolean; inline;
begin
  Result := Assigned(FCursor) and (UnsafeGetType(PJsonValue(FCursor)) = YYJSON_TYPE_ARR);
end;

function TJsonBuilderF.Obj: TJsonBuilderF;
begin
  FRoot := JsonMutObj(FDoc);
  JsonMutDocSetRoot(FDoc, FRoot);
  FCursor := FRoot;
  Result := Self;
end;

function TJsonBuilderF.Arr: TJsonBuilderF;
begin
  FRoot := JsonMutArr(FDoc);
  JsonMutDocSetRoot(FDoc, FRoot);
  FCursor := FRoot;
  Result := Self;
end;

function TJsonBuilderF.PutStr(const AKey, AVal: String): TJsonBuilderF;
begin
  if not Assigned(FCursor) then Obj;
  JsonMutObjAddStr(FDoc, FCursor, AKey, AVal);
  Result := Self;
end;

function TJsonBuilderF.PutInt(const AKey: String; const AVal: Int64): TJsonBuilderF;
begin
  if not Assigned(FCursor) then Obj;
  JsonMutObjAddInt(FDoc, FCursor, AKey, AVal);
  Result := Self;
end;

function TJsonBuilderF.PutBool(const AKey: String; const AVal: Boolean): TJsonBuilderF;
begin
  if not Assigned(FCursor) then Obj;
  JsonMutObjAddBool(FDoc, FCursor, AKey, AVal);
  Result := Self;
end;

function TJsonBuilderF.AddStr(const AVal: String): TJsonBuilderF;
begin
  if not Assigned(FCursor) then Arr;
  JsonMutArrAddStr(FDoc, FCursor, AVal);
  Result := Self;
end;

function TJsonBuilderF.AddInt(const AVal: Int64): TJsonBuilderF;
begin
  if not Assigned(FCursor) then Arr;
  JsonMutArrAddInt(FDoc, FCursor, AVal);
  Result := Self;
end;

function TJsonBuilderF.AddBool(const AVal: Boolean): TJsonBuilderF;
begin
  if not Assigned(FCursor) then Arr;
  JsonMutArrAddBool(FDoc, FCursor, AVal);
  Result := Self;
end;

function TJsonBuilderF.BeginObj(const AKey: String): TJsonBuilderF;
var Child: PJsonMutValue;
begin
  if not Assigned(FCursor) then Obj;
  if not IsCursorObj then
  begin
    {$IFDEF DEBUG} Assert(False, 'BeginObj: parent must be object'); {$ENDIF}
    Exit(Self);
  end;
  Child := JsonMutObjAddObj(FDoc, FCursor, AKey);
  PushCursor(jbsObj);
  FCursor := Child;
  Result := Self;
end;

function TJsonBuilderF.BeginArr(const AKey: String): TJsonBuilderF;
var Child: PJsonMutValue;
begin
  if not Assigned(FCursor) then Obj;
  if not IsCursorObj then
  begin
    {$IFDEF DEBUG} Assert(False, 'BeginArr: parent must be object'); {$ENDIF}
    Exit(Self);
  end;
  Child := JsonMutObjAddArr(FDoc, FCursor, AKey);
  PushCursor(jbsArr);
  FCursor := Child;
  Result := Self;
end;

function TJsonBuilderF.ArrAddObj: TJsonBuilderF;
var Child: PJsonMutValue;
begin
  if not Assigned(FCursor) then Arr;
  if not IsCursorArr then
  begin
    {$IFDEF DEBUG} Assert(False, 'ArrAddObj: parent must be array'); {$ENDIF}
    Exit(Self);
  end;
  Child := JsonMutArrAddObj(FDoc, FCursor);
  PushCursor(jbsObj);
  FCursor := Child;
  Result := Self;
end;

function TJsonBuilderF.ArrAddArr: TJsonBuilderF;
var Child: PJsonMutValue;
begin
  if not Assigned(FCursor) then Arr;
  if not IsCursorArr then
  begin
    {$IFDEF DEBUG} Assert(False, 'ArrAddArr: parent must be array'); {$ENDIF}
    Exit(Self);
  end;
  Child := JsonMutArrAddArr(FDoc, FCursor);
  PushCursor(jbsArr);
  FCursor := Child;
  Result := Self;
end;

function TJsonBuilderF.EndObj: TJsonBuilderF;
var Scope: TJsonBuilderScope;
begin
  if PopCursor(Scope) and (Scope = jbsObj) then
    Result := Self
  else
    Result := Self; // no-op on mismatch (也可考虑断言)
end;

function TJsonBuilderF.EndArr: TJsonBuilderF;
var Scope: TJsonBuilderScope;
begin
  if PopCursor(Scope) and (Scope = jbsArr) then
    Result := Self
  else
    Result := Self;
end;

function TJsonBuilderF.SetRoot: TJsonBuilderF;
begin
  if Assigned(FDoc) and Assigned(FRoot) then
    JsonMutDocSetRoot(FDoc, FRoot);
  Result := Self;
end;

function TJsonBuilderF.Detach: TJsonMutDocument;
begin
  Result := FDoc;
  FDoc := nil;
end;

function TJsonBuilderF.Doc: TJsonMutDocument;
begin
  Result := FDoc;
end;

function TJsonBuilderF.Cursor: PJsonMutValue;
begin
  Result := FCursor;
end;

function TJsonBuilderF.WriteJsonMutValue(AVal: PJsonMutValue; AFlags: TJsonWriteFlags; AIndent: Integer): String;
var
  t: UInt8; itA: TJsonMutArrayIterator; itO: TJsonMutObjectIterator; k, v: PJsonMutValue;
  LIndentStr, LNewIndentStr: String; LFirst: Boolean;
begin
  LIndentStr := '';
  LNewIndentStr := '';
  if not Assigned(AVal) then Exit('null');
  t := UnsafeGetType(PJsonValue(AVal));
  case t of
    YYJSON_TYPE_NULL:   Exit('null');
    YYJSON_TYPE_BOOL:   if UnsafeIsTrue(PJsonValue(AVal)) then Exit('true') else Exit('false');
    YYJSON_TYPE_NUM:    Exit(WriteJsonNumber(PJsonValue(AVal), AFlags));
    YYJSON_TYPE_STR:    Exit(WriteJsonString(AVal^.Data.Str, UnsafeGetLen(PJsonValue(AVal)), AFlags));
    YYJSON_TYPE_ARR:    begin
      Result := '[';
      if JsonMutArrIterInit(AVal, @itA) then
      begin
        LFirst := True;
        while JsonMutArrIterHasNext(@itA) do
        begin
          v := JsonMutArrIterNext(@itA);
          if not LFirst then Result := Result + ',' else LFirst := False;
          if jwfPretty in AFlags then
          begin
            if LIndentStr = '' then LIndentStr := StringOfChar(' ', AIndent*2);
            LNewIndentStr := LIndentStr + '  ';
            Result := Result + sLineBreak + LNewIndentStr;
          end;
          Result := Result + WriteJsonMutValue(v, AFlags, AIndent + 1);
        end;
      end;
      if jwfPretty in AFlags then
        Result := Result + sLineBreak + LIndentStr + ']'
      else
        Result := Result + ']';
      Exit;
    end;
    YYJSON_TYPE_OBJ:    begin
      Result := '{';
      if JsonMutObjIterInit(AVal, @itO) then
      begin
        LFirst := True;
        while JsonMutObjIterHasNext(@itO) do
        begin
          k := JsonMutObjIterNext(@itO);
          v := k^.Next;
          if not LFirst then Result := Result + ',' else LFirst := False;
          if jwfPretty in AFlags then
          begin
            if LIndentStr = '' then LIndentStr := StringOfChar(' ', AIndent*2);
            LNewIndentStr := LIndentStr + '  ';
            Result := Result + sLineBreak + LNewIndentStr;
          end;
          Result := Result + WriteJsonString(k^.Data.Str, UnsafeGetLen(PJsonValue(k)), AFlags);
          if jwfPretty in AFlags then Result := Result + ': ' else Result := Result + ':';
          Result := Result + WriteJsonMutValue(v, AFlags, AIndent + 1);
        end;
      end;
      if jwfPretty in AFlags then
        Result := Result + sLineBreak + LIndentStr + '}'
      else
        Result := Result + '}';
      Exit;
    end;
  else
    Exit('null');
  end;
end;

function TJsonBuilderF.ToJson(AFlags: TJsonWriteFlags; AIndent: Integer): String;
begin
  if not Assigned(FRoot) then Exit('null');
  Result := WriteJsonMutValue(FRoot, AFlags, AIndent);
end;

function TJsonBuilderF.SaveToFile(const APath: String; AFlags: TJsonWriteFlags; AIndent: Integer): Boolean;
var S: String; FS: TFileStream;
begin
  S := ToJson(AFlags, AIndent);
  FS := TFileStream.Create(APath, fmCreate or fmOpenWrite);
  try
    if Length(S) > 0 then FS.WriteBuffer(S[1], Length(S));
    Result := True;
  finally
    FS.Free;
  end;
end;

{ TJsonNodeF }
function TJsonNodeF.IsNull: Boolean; inline;
begin
  Result := (not Assigned(Val)) or (UnsafeGetType(Val) = YYJSON_TYPE_NULL);
end;

function TJsonNodeF.IsBool: Boolean; inline;
begin
  Result := Assigned(Val) and (UnsafeGetType(Val) = YYJSON_TYPE_BOOL);
end;

function TJsonNodeF.IsNum: Boolean; inline;
begin
  Result := Assigned(Val) and (UnsafeGetType(Val) = YYJSON_TYPE_NUM);
end;

function TJsonNodeF.IsStr: Boolean; inline;
begin
  Result := Assigned(Val) and (UnsafeGetType(Val) = YYJSON_TYPE_STR);
end;

function TJsonNodeF.IsArr: Boolean; inline;
begin
  Result := Assigned(Val) and (UnsafeGetType(Val) = YYJSON_TYPE_ARR);
end;

function TJsonNodeF.IsObj: Boolean; inline;
begin
  Result := Assigned(Val) and (UnsafeGetType(Val) = YYJSON_TYPE_OBJ);
end;

function TJsonNodeF.TryAsBool(out AVal: Boolean): Boolean; inline;
begin
  Result := IsBool;
  if Result then AVal := UnsafeIsTrue(Val);
end;

function TJsonNodeF.TryAsInt(out AVal: Int64): Boolean; inline;
begin
  Result := IsNum;
  if Result then AVal := JsonGetInt(Val);
end;

function TJsonNodeF.TryAsReal(out AVal: Double): Boolean; inline;
begin
  Result := IsNum;
  if Result then AVal := JsonGetReal(Val);
end;

function TJsonNodeF.TryAsStr(out AVal: String): Boolean;
begin
  Result := IsStr;
  if Result then SetString(AVal, Val^.Data.Str, UnsafeGetLen(Val));
end;

function TJsonNodeF.AsBoolOrDefault(ADef: Boolean): Boolean; inline;
var V: Boolean;
begin
  if TryAsBool(V) then Exit(V) else Exit(ADef);
end;

function TJsonNodeF.AsIntOrDefault(ADef: Int64): Int64; inline;
var V: Int64;
begin
  if TryAsInt(V) then Exit(V) else Exit(ADef);
end;

function TJsonNodeF.AsRealOrDefault(ADef: Double): Double; inline;
var V: Double;
begin
  if TryAsReal(V) then Exit(V) else Exit(ADef);
end;

function TJsonNodeF.AsStrOrDefault(const ADef: String): String;
var V: String;
begin
  if TryAsStr(V) then Exit(V) else Exit(ADef);
end;

{ JsonF }
class function JsonF.Parse(const AText: String): IJsonDocF;
var E: TJsonError; Alc: TAllocator;
begin
  Alc := GetRtlAllocator();
  Result := JsonF.Parse(AText, [], Alc, E);
end;

class function JsonF.Parse(const AText: String; AFlags: TJsonReadFlags; AAllocator: TAllocator;
  out AError: TJsonError): IJsonDocF;
var Doc: TJsonDocument;
begin
  if not Assigned(AAllocator) then
    AAllocator := GetRtlAllocator();
  AError := Default(TJsonError);
  Doc := JsonReadOpts(PChar(AText), Length(AText), AFlags, AAllocator, AError);
  if Assigned(Doc) then
    Result := TJsonDocF.Create(Doc)
  else
    Result := nil;
end;

class function JsonF.NewBuilder(AAllocator: TAllocator): TJsonBuilderF;
begin
  Result := TJsonBuilderF.Create(AAllocator);
end;

class function JsonF.ParseFile(const APath: String): IJsonDocF;
var E: TJsonError; Alc: TAllocator;
begin
  Alc := GetRtlAllocator();
  Result := JsonF.ParseFile(APath, [], Alc, E);
end;

class function JsonF.ParseFile(const APath: String; AFlags: TJsonReadFlags; AAllocator: TAllocator;
  out AError: TJsonError): IJsonDocF;
var Doc: TJsonDocument;
begin
  if not Assigned(AAllocator) then
    AAllocator := GetRtlAllocator();
  AError := Default(TJsonError);
  Doc := JsonReadFile(APath, AFlags, AAllocator, AError);
  if Assigned(Doc) then
    Result := TJsonDocF.Create(Doc)
  else
    Result := nil;
end;

class function JsonF.ParseStream(AStream: TStream): IJsonDocF;
var S: String; E: TJsonError; Alc: TAllocator;
begin
  S := '';
  SetLength(S, AStream.Size);
  if AStream.Size > 0 then AStream.ReadBuffer(S[1], AStream.Size);
  Alc := GetRtlAllocator();
  Result := JsonF.Parse(S, [], Alc, E);
end;

class function JsonF.ParseStream(AStream: TStream; AFlags: TJsonReadFlags; AAllocator: TAllocator;
  out AError: TJsonError): IJsonDocF;
var S: String;
begin
  S := '';
  SetLength(S, AStream.Size);
  if AStream.Size > 0 then AStream.ReadBuffer(S[1], AStream.Size);
  AError := Default(TJsonError);
  Result := JsonF.Parse(S, AFlags, AAllocator, AError);
end;

end.

