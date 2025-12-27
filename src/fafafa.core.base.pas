unit fafafa.core.base;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

uses
  classes,
  SysUtils;


type

  TProc    = procedure;
  TObjProc = procedure of object;
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  TRefProc = reference to procedure;
  {$ENDIF}


function XmlEscape(const S: string): string;


function XmlEscapeXML10Strict(const S: string): string; // strips invalid XML 1.0 chars then escapes

{ exception system 异常系统 }

type

  {**
   * ECore
   *
   * @desc
   *   The base exception class for all errors raised by the fafafa.core framework.
   *   fafafa.core 框架抛出的所有错误的基类异常.
   *}
  ECore = class(Exception) end;

  {**
   * EWow
   *
   * @desc
   *   A special exception that should not normally be triggered, indicating a surprising or unexpected internal state.
   *   一个通常不应被触发的特殊异常, 表明一个令人惊讶或意料之外的内部状态.
   *}
  EWow = class(ECore) end;

  {**
   * EArgumentNil
   *
   * @desc
   *   Raised when a required pointer, interface, or object argument is `nil`.
   *   当一个必需的指针、接口或对象参数为 `nil` 时抛出.
   *}
  EArgumentNil = class(ECore) end;

  {**
   * EEmptyCollection
   *
   * @desc
   *   Raised when an operation is performed on an empty collection that requires it to be non-empty.
   *   当在一个空集合上执行需要其非空的操作时抛出.
   *}
  EEmptyCollection = class(ECore) end;

  {**
   * EInvalidArgument
   *
   * @desc
   *   Raised when the value of an argument is unacceptable, but not covered by a more specific exception type.
   *   当一个参数的值不可接受, 但又没有更具体的异常类型可以描述时抛出.
   *}
  EInvalidArgument = class(ECore) end;

  {**
   * EInvalidResult
   *
   * @desc
   *   Raised when the result of an operation is unacceptable, but not covered by a more specific exception type.
   *   当一个操作的结果不可接受, 但又没有更具体的异常类型可以描述时抛出.
   *}
  EInvalidResult = class(ECore) end;

  {**
   * ETimeoutError
   *
   * @desc
   *   Raised when an operation times out.
   *   当操作超时时抛出.
   *}
  ETimeoutError = class(ECore) end;

  {**
   * EInvalidState
   *
   * @desc
   *   Raised when an object is in an invalid state for the requested operation.
   *   当对象处于无效状态无法执行请求的操作时抛出.
   *}
  EInvalidState = class(ECore) end;





  {**
   * EOutOfRange
   *
   * @desc
   *   Raised when an argument (e.g., an index or count) is outside its valid range of values.
   *   当一个参数 (例如: 索引或数量) 超出其有效范围时抛出.
   *}

  EOutOfRange = class(ECore) end;

  {**
   * ENotSupported
   *
   * @desc
   *   Raised when a called method or operation is not supported by the object.
   *   当调用的方法或操作不被此对象支持时抛出.
   *}
  ENotSupported = class(ECore) end;

  {**
   * ENotCompatible
   *
   * @desc
   *   Raised when two objects are not compatible.
   *   当两个对象不兼容时抛出.
   *}
  ENotCompatible = class(ECore) end;

  {**
   * EInvalidOperation
   *
   * @desc
   *   Raised when an operation is not valid for the current state of the object.
   *   当操作对于对象的当前状态无效时抛出.
   *}
  EInvalidOperation = class(ECore) end;

  {**
   * EOutOfMemory
   *
   * @desc
   *   Raised when a memory allocation fails.
   *   当内存分配失败时抛出.
   *}
  EOutOfMemory = class(ECore) end;

  {**
   * EOverflow
   *
   * @desc
   *   Raised when an operation overflows.
   *   当操作溢出时抛出.
   *}
  EOverflow = class(ECore) end;

const

  MAX_SIZE_INT  = High(SizeInt);
  MAX_SIZE_UINT = High(SizeUInt);
  MAX_UINT8     = High(UInt8);
  MAX_INT8      = High(Int8);
  MAX_UINT16    = High(UInt16);
  MAX_INT16     = High(Int16);
  MAX_UINT32    = High(UInt32);
  MAX_INT32     = High(Int32);
  MAX_UINT64    = High(UInt64);
  MAX_INT64     = High(Int64);

  MIN_SIZE_INT  = Low(SizeInt);
  MIN_INT8      = Low(Int8);
  MIN_INT16     = Low(Int16);
  MIN_INT32     = Low(Int32);
  MIN_INT64     = Low(Int64);

  SIZE_PTR = SizeOf(Pointer);
  SIZE_8   = SizeOf(UInt8);
  SIZE_16  = SizeOf(UInt16);
  SIZE_32  = SizeOf(UInt32);
  SIZE_64  = SizeOf(UInt64);

type

  TStringArray = array of string;
  // Canonical bytes alias across the framework
  TBytes = array of Byte;

type

  {**
   * TRandomGeneratorFunc
   *
   * @desc
   *   A function that generates a random number.
   *   一个生成随机数的函数回调.
   *
   * @param
   *   aRange - The range of the random number.
   *   随机数的范围.
   *}
  TRandomGeneratorFunc = function(aRange: Int64; aData: Pointer): Int64;

  {**
   * TRandomGeneratorMethod
   *
   * @desc
   *   A method that generates a random number.
   *   一个生成随机数的类方法回调.
   *}
  TRandomGeneratorMethod = function(aRange: Int64; aData: Pointer): Int64 of object;

  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  {**
   * TRandomGeneratorRefFunc
   *
   * @desc
   *   A function that generates a random number.
   *   一个生成随机数的函数回调.
   *}
  TRandomGeneratorRefFunc = reference to function(aRange: Int64): Int64;
  {$ENDIF}

implementation



function XmlEscape(const S: string): string;
begin
  Result := StringReplace(S, '&', '&amp;', [rfReplaceAll]);
  Result := StringReplace(Result, '<', '&lt;', [rfReplaceAll]);
  Result := StringReplace(Result, '>', '&gt;', [rfReplaceAll]);
  Result := StringReplace(Result, '"', '&quot;', [rfReplaceAll]);
  Result := StringReplace(Result, '''', '&apos;', [rfReplaceAll]);
end;





function XmlEscapeXML10Strict(const S: string): string;
var
  I, W: SizeInt;
  C: WideChar;
  Src: UnicodeString;
  OutBuf: UnicodeString;
begin
  // Normalize to UTF-16 (UnicodeString)
  OutBuf := '';
  Src := UTF8Decode(UTF8Encode(S));
  SetLength(OutBuf, Length(Src));
  W := 0;
  for I := 1 to Length(Src) do
  begin
    C := Src[I];
    // XML 1.0 valid chars: Tab(9), LF(10), CR(13), #x20-#xD7FF, #xE000-#xFFFD, #x10000-#x10FFFF
    if (C = #9) or (C = #10) or (C = #13) or
       ((Ord(C) >= $20) and (Ord(C) <= $D7FF)) or
       ((Ord(C) >= $E000) and (Ord(C) <= $FFFD)) then
    begin
      Inc(W);
      OutBuf[W] := C;
    end;
    // else: strip invalid char
  end;
  SetLength(OutBuf, W);
  // Escape after stripping
  Result := XmlEscape(UTF8Encode(OutBuf));
end;

end.
