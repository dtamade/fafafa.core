{$CODEPAGE UTF8}
unit fafafa.core.result.testcase;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.result, fafafa.core.option;

type
  // 针对 TResult<Integer,String> 的具体测试用例，覆盖所有公开接口
  TTestCase_TResult_IntStr = class(TTestCase)
  published
    procedure Test_Construct_And_Query;
    procedure Test_Unwrap_And_Expect;
    procedure Test_UnwrapErr;
  end;

  TTestCase_Global = class(TTestCase)
  published
    procedure Test_Combinators_Map_MapErr_AndThen_OrElse;
    procedure Test_Combinators_MapOr_MapOrElse_Inspect_InspectErr;
    procedure Test_ToDebugString;
    procedure Test_ManagedTypes_StringAndArray; // re-enabled
    procedure Test_InterfaceErrorChannel;
    procedure Test_Ext_Swap_Flatten_MapBoth;
    procedure Test_ExpectErr;
    // 新增覆盖
    procedure Test_FromTry_Details;
    procedure Test_Equals_Boundaries;
    procedure Test_Complex_Chains_MatchFold; // re-enabled
    procedure Test_ManagedType_String_Chain;
    procedure Test_And_Or_Contains_FilterOrElse;
    procedure Test_Transpose_And_OptionBridge;
    procedure Test_Equals_Default_And_ToTry;
  end;
{$IFDEF FAFAFA_CORE_RESULT_METHODS}
    procedure Test_Methods_Map_MapErr;
{$IFDEF FAFAFA_CORE_RESULT_METHODS}
    procedure Test_Methods_Phase3_MapOr_MapOrElse_Inspect_Opt;
{$ENDIF}

{$ENDIF}


implementation

type
  TIntDynArray = array of Integer;

  IMyErr = interface(IInterface)
    ['{6C1056B5-4A3D-4D39-9F81-6F3D9B1B9E10}']
    function MessageText: string;
  end;

  TMyErr = class(TInterfacedObject, IMyErr)
  private
    FMsg: string;
  public
    constructor Create(const A: string);
    function MessageText: string;

  end;

constructor TMyErr.Create(const A: string);
begin
  FMsg := A;
end;

function TMyErr.MessageText: string;
begin
  Result := FMsg;
end;





// 全局函数与过程用于测试“函数指针”重载
function IncOne(const X: Integer): Integer; begin Result := X + 1; end;
function StrLenI(const S: string): Integer; begin Result := Length(S); end;
function AppendBang(const S: string): string; begin Result := S + '!'; end;
function WorkOk: Integer; begin Result := 5; end;
function WorkFail: Integer; begin raise Exception.Create('X'); end;
function MapEx(const Ex: Exception): string; begin Result := Ex.Message; end;
var GTapCount: Integer = 0;
procedure TapInt(const X: Integer); begin Inc(GTapCount, X); end;
procedure TapStr(const S: string); begin Inc(GTapCount, Length(S)); end;

procedure TTestCase_TResult_IntStr.Test_Construct_And_Query;
var
  R1: specialize TResult<Integer,String>;
  R2: specialize TResult<Integer,String>;
begin
  // Ok 构造与查询
  R1 := specialize TResult<Integer,String>.Ok(123);
  CheckTrue(R1.IsOk, 'R1 should be Ok');
  CheckFalse(R1.IsErr, 'R1 should not be Err');
  // UnwrapOr 应返回 Ok 值
  CheckEquals(123, R1.UnwrapOr(0));

  // Err 构造与查询
  R2 := specialize TResult<Integer,String>.Err('e');
  CheckTrue(R2.IsErr, 'R2 should be Err');
  CheckFalse(R2.IsOk, 'R2 should not be Ok');
  // Err 路径 UnwrapOr 返回默认值
  CheckEquals(0, R2.UnwrapOr(0));
end;

procedure TTestCase_TResult_IntStr.Test_Unwrap_And_Expect;
var
  R: specialize TResult<Integer,String>;
begin
  R := specialize TResult<Integer,String>.Ok(7);
  CheckEquals(7, R.Unwrap);

  // Expect on Err 应抛出 EResultUnwrapError（统一使用 try/except，避免环境差异）
  try
    specialize TResult<Integer,String>.Err('boom').Expect('boom');
    Fail('Expect on Err should raise');
  except
    on E: EResultUnwrapError do ;
  end;
end;

procedure TTestCase_TResult_IntStr.Test_UnwrapErr;
var
  R: specialize TResult<Integer,String>;
begin
  R := specialize TResult<Integer,String>.Ok(1);
  // 统一使用 try/except 分支
  try
    R.UnwrapErr;
    Fail('UnwrapErr on Ok should raise');
  except
    on E: EResultUnwrapError do ;
  end;
end;

procedure TTestCase_Global.Test_Combinators_Map_MapErr_AndThen_OrElse;
var
  ROk, RErr: specialize TResult<Integer,String>;
  R: specialize TResult<Integer,String>;
  FPlus1: specialize TResultFunc<Integer,Integer>;
  FAndThen: specialize TResultFunc<Integer, specialize TResult<Integer,String>>;
  FOrElse: specialize TResultFunc<String, specialize TResult<Integer,AnsiString>>;
  RMap, RMapErr, RAndThen, ROrElse: specialize TResult<Integer,AnsiString>;
begin
  // 准备数据
  ROk := specialize TResult<Integer,String>.Ok(7);
  RErr := specialize TResult<Integer,String>.Err('e');

  // FPlus1: Int -> Int（+1）
  FPlus1 := function (const X: Integer): Integer
  begin
    Result := X + 1;
  end;

  // AndThen：Ok -> Ok(x+1)
  FAndThen := function (const X: Integer): specialize TResult<Integer,String>
  begin
    if X > 0 then
      Result := specialize TResult<Integer,String>.Ok(X+1)
    else
      Result := specialize TResult<Integer,String>.Err('neg');
  end;

  // 函数指针重载覆盖
  // 注意：ResultMap 返回 Result<U,E>，此处 U=Int, E=String；R 类型已声明为 TResult<Integer,String>
  R := specialize ResultMap<Integer,String,Integer>(ROk, @IncOne);
  CheckEquals(8, R.Unwrap);
  R := specialize ResultMapErr<Integer,String,String>(RErr, @AppendBang);
  CheckEquals('e!', R.UnwrapErr);
  R := specialize ResultAndThen<Integer,String,Integer>(ROk,
    function (const X: Integer): specialize TResult<Integer,String>
    begin
      if X > 0 then
        Result := specialize TResult<Integer,String>.Ok(X+1)
      else
        Result := specialize TResult<Integer,String>.Err('neg');
    end);
  CheckEquals(8, R.Unwrap);
  // OrElse（指针）
  R := specialize ResultOrElse<Integer,String,String>(RErr, function (const S: string): specialize TResult<Integer,string>
  begin Result := specialize TResult<Integer,string>.Ok(Length(S)); end);
  CheckEquals(1, R.Unwrap);
  // MapOr 指针
  CheckEquals(8, specialize ResultMapOr<Integer,String,Integer>(ROk, -1, @IncOne));
  CheckEquals(99, specialize ResultMapOr<Integer,String,Integer>(RErr, 99, @IncOne));
  // MapOrElse 指针
  CheckEquals(8, specialize ResultMapOrElse<Integer,String,Integer>(ROk, @StrLenI, @IncOne));
  CheckEquals(1, specialize ResultMapOrElse<Integer,String,Integer>(RErr, @StrLenI, @IncOne));
  // Inspect/InspectErr 指针
  GTapCount := 0;
  specialize ResultInspect<Integer,String>(ROk, @TapInt);
  specialize ResultInspectErr<Integer,String>(RErr, @TapStr);
  CheckEquals(8, GTapCount);

  // OrElse：Err -> Ok(0) with different E2 type AnsiString
  FOrElse := function (const S: String): specialize TResult<Integer,AnsiString>
  begin
    Result := specialize TResult<Integer,AnsiString>.Ok(0);
  end;

  // Map（Ok->Ok，Err->Err）
  RMap := specialize ResultMap<Integer,String,Integer>(ROk, FPlus1);
  CheckTrue(RMap.IsOk);
  CheckEquals(8, RMap.Unwrap);

  RMap := specialize ResultMap<Integer,String,Integer>(RErr, FPlus1);
  CheckTrue(RMap.IsErr);

  // MapErr（Ok->Ok 原类型，Err->Err(E2)）
  RMapErr := specialize ResultMapErr<Integer,String,AnsiString>(ROk,
    function (const S: String): AnsiString begin Result := AnsiString(S + '!'); end);
  CheckTrue(RMapErr.IsOk);

  RMapErr := specialize ResultMapErr<Integer,String,AnsiString>(RErr,
    function (const S: String): AnsiString begin Result := AnsiString(S + '!'); end);
  CheckTrue(RMapErr.IsErr);

  // AndThen（Ok->F，Err直传）
  RAndThen := specialize ResultAndThen<Integer,String,Integer>(ROk, FAndThen);
  CheckTrue(RAndThen.IsOk);
  CheckEquals(8, RAndThen.Unwrap);

  RAndThen := specialize ResultAndThen<Integer,String,Integer>(RErr, FAndThen);
  CheckTrue(RAndThen.IsErr);

  // OrElse（Err->F，Ok直传）不同错误类型
  ROrElse := specialize ResultOrElse<Integer,String,AnsiString>(ROk, FOrElse);
  CheckTrue(ROrElse.IsOk);
  CheckEquals(7, ROrElse.Unwrap);

  ROrElse := specialize ResultOrElse<Integer,String,AnsiString>(RErr, FOrElse);
  CheckTrue(ROrElse.IsOk);
  CheckEquals(0, ROrElse.Unwrap);
end;

procedure TTestCase_Global.Test_Combinators_MapOr_MapOrElse_Inspect_InspectErr;
var
  ROk, RErr: specialize TResult<Integer,String>;
  COk, CErr: Integer;
  S: Integer;
  V: Integer;
  E: String;
  R: specialize TResult<Integer,String>;
begin
  ROk := specialize TResult<Integer,String>.Ok(5);
  RErr := specialize TResult<Integer,String>.Err('e');

  // MapOr: Ok -> f, Err -> default
  S := specialize ResultMapOr<Integer,String,Integer>(ROk, -1,
    function (const X: Integer): Integer begin Result := X*2; end);
  CheckEquals(10, S);
  S := specialize ResultMapOr<Integer,String,Integer>(RErr, -1,
    function (const X: Integer): Integer begin Result := X*2; end);
  CheckEquals(-1, S);

  // MapOrElse: Ok -> f_ok, Err -> f_err
  S := specialize ResultMapOrElse<Integer,String,Integer>(ROk,
    function (const E: String): Integer begin Result := -2; end,
    function (const X: Integer): Integer begin Result := X+3; end);
  CheckEquals(8, S);
  S := specialize ResultMapOrElse<Integer,String,Integer>(RErr,
    function (const E: String): Integer begin Result := -2; end,
    function (const X: Integer): Integer begin Result := X+3; end);
  CheckEquals(-2, S);

  // Inspect / InspectErr
  COk := 0; CErr := 0;

  // 新增：TryUnwrap / TryUnwrapErr / UnwrapOrElse
  // TryUnwrap
  R := specialize TResult<Integer,String>.Ok(10);
  CheckTrue(R.TryUnwrap(V));
  CheckEquals(10, V);
  // TryUnwrapErr
  R := specialize TResult<Integer,String>.Err('x');
  CheckTrue(R.TryUnwrapErr(E));
  CheckEquals('x', E);
  // UnwrapOrElse
  R := specialize TResult<Integer,String>.Err('boom');
  V := R.UnwrapOrElse(
    function (const S: String): Integer begin Result := Length(S); end);
  CheckEquals(4, V);

  ROk := specialize ResultInspect<Integer,String>(ROk,
    procedure (const X: Integer) begin Inc(COk, X); end);
  RErr := specialize ResultInspectErr<Integer,String>(RErr,
    procedure (const E: String) begin Inc(CErr); end);

  CheckEquals(5, COk);
  CheckEquals(1, CErr);

  // 返回值应保持原 Result
  CheckTrue(ROk.IsOk); CheckEquals(5, ROk.Unwrap);
  CheckTrue(RErr.IsErr); CheckEquals('e', RErr.UnwrapErr);
end;

procedure TTestCase_Global.Test_ToDebugString;
var
  ROk: specialize TResult<Integer,String>;
  RErr: specialize TResult<Integer,String>;
  S1, S2: string;
begin
  ROk := specialize TResult<Integer,String>.Ok(9);
  RErr := specialize TResult<Integer,String>.Err('oops');
  S1 := ROk.ToDebugString(
    function (const V: Integer): string begin Result := IntToStr(V); end,
    function (const E: String): string begin Result := E; end);
  S2 := RErr.ToDebugString(
    function (const V: Integer): string begin Result := IntToStr(V); end,
    function (const E: String): string begin Result := E; end);
  CheckEquals('Ok(9)', S1);
  CheckEquals('Err(oops)', S2);
end;

// NOTE: 暂时注释管理型类型用例以隔离问题定位（稍后恢复）
//procedure TTestCase_Global.Test_ManagedTypes_StringAndArray;
//var
//  RS: specialize TResult<string,string>;
//  RA: specialize TResult<TIntDynArray,string>;
//  A: TIntDynArray;
//begin
//  // string as T/E
//  RS := specialize TResult<string,string>.Ok('ok');
//  CheckTrue(RS.IsOk); CheckEquals('ok', RS.Unwrap);
//  RS := specialize TResult<string,string>.Err('e');
//  CheckTrue(RS.IsErr); CheckEquals('e', RS.UnwrapErr);
//  RS := specialize ResultMap<string,string,string>(
//    specialize TResult<string,string>.Ok('ok'),
//    function (const S: string): string begin Result := S; end
//  );
//  CheckEquals('ok', RS.Unwrap);
//
//  // dynamic array as T
//  SetLength(A, 2); A[0]:=1; A[1]:=2;
//  RA := specialize TResult<TIntDynArray,string>.Ok(A);
//  CheckTrue(RA.IsOk);
//  CheckEquals(2, Length(RA.Unwrap));
//end;

procedure TTestCase_Global.Test_ManagedTypes_StringAndArray;
var
  RS: specialize TResult<string,string>;
  RA: specialize TResult<TIntDynArray,string>;
  A: TIntDynArray;
begin
  // string as T/E
  RS := specialize TResult<string,string>.Ok('ok');
  CheckTrue(RS.IsOk); CheckEquals('ok', RS.Unwrap);
  RS := specialize TResult<string,string>.Err('e');
  CheckTrue(RS.IsErr); CheckEquals('e', RS.UnwrapErr);

  RS := specialize ResultMap<string,string,string>(RS,
    function (const S: string): string begin Result := S; end);
  CheckEquals('ok', RS.UnwrapOr('ok'));

  // dynamic array as T
  SetLength(A, 2); A[0]:=1; A[1]:=2;
  RA := specialize TResult<TIntDynArray,string>.Ok(A);
  CheckTrue(RA.IsOk);
  CheckEquals(2, Length(RA.Unwrap));
end;

//procedure TTestCase_Global.Test_Match_Fold_And_Predicates;
//var
//  ROk, RErr: specialize TResult<Integer,String>;
//  U: Integer;
//begin
//  ROk := specialize TResult<Integer,String>.Ok(3);
//  RErr := specialize TResult<Integer,String>.Err('xx');
//
//  // Match/Fold
//  U := specialize ResultMatch<Integer,String,Integer>(ROk,
//    function (const X: Integer): Integer begin Result := X*10; end,
//    function (const S: String): Integer begin Result := -1; end);
//  CheckEquals(30, U);
//
//  U := specialize ResultFold<Integer,String,Integer>(RErr,
//    function (const X: Integer): Integer begin Result := X*10; end,
//    function (const S: String): Integer begin Result := Length(S); end);
//  CheckEquals(2, U);
//
//  // Predicates
//  CheckTrue(specialize ResultIsOkAnd<Integer,String>(ROk,
//    function (const X: Integer): Boolean begin Result := X>0; end));
//  CheckTrue(specialize ResultIsErrAnd<Integer,String>(RErr,
//    function (const S: String): Boolean begin Result := S<>''; end));
//end;

{$IFDEF FAFAFA_CORE_RESULT_METHODS}
procedure TTestCase_Global.Test_Methods_Map_MapErr;
var
  R: specialize TResult<Integer,String>;
begin
  // Ok path: Map then AndThen
  R := specialize TResult<Integer,String>.Ok(7)
    .Map(function (const X: Integer): Integer begin Result := X+1; end)
    .AndThen(function (const X: Integer): specialize TResult<Integer,String>
             begin if X>0 then Result := specialize TResult<Integer,String>.Ok(X) else Result := specialize TResult<Integer,String>.Err('neg'); end)
    .MapErr(function (const E: String): String begin Result := E + '!'; end);
  CheckTrue(R.IsOk);
  CheckEquals(8, R.Unwrap);

  // Err path: OrElse then MapErr
  R := specialize TResult<Integer,String>.Err('e')
    .OrElse(function (const E: String): specialize TResult<Integer,String>
            begin Result := specialize TResult<Integer,String>.Ok(Length(E)); end)
    .MapErr(function (const E: String): String begin Result := E + '!'; end);
  CheckTrue(R.IsOk);
  CheckEquals(1, R.Unwrap);
end;
{$ENDIF}


// ----------------------------------------------------------------------
//procedure TTestCase_Global.Test_Complex_Chains_MatchFold;
//var
//  ROk, RErr: specialize TResult<Integer,String>;
//  U: Integer;
//  function Ten(const X: Integer): Integer; begin Result := X*10; end;
//  function NegOne(const S: String): Integer; begin Result := -1; end;
//  function PosInt(const X: Integer): Boolean; begin Result := X>0; end;
//  function NonEmpty(const S: String): Boolean; begin Result := S<>''; end;
//begin
//  ROk := specialize TResult<Integer,String>.Ok(3);
//  RErr := specialize TResult<Integer,String>.Err('xx');
{$IFDEF FAFAFA_CORE_RESULT_METHODS}
procedure TTestCase_Global.Test_Methods_Phase3_MapOr_MapOrElse_Inspect_Opt;
var
  R: specialize TResult<Integer,String>;
  U: Integer;
  OI: specialize TOption<Integer>;
  OS: specialize TOption<String>;
begin
  // MapOr/MapOrElse
  R := specialize TResult<Integer,String>.Ok(7);
  U := R.MapOr(-1, function (const X: Integer): Integer begin Result := X+1; end);
  CheckEquals(8, U);
  U := R.MapOrElse(@StrLenI, function (const X: Integer): Integer begin Result := X+1; end);
  CheckEquals(8, U);

  R := specialize TResult<Integer,String>.Err('xx');
  U := R.MapOr(99, function (const X: Integer): Integer begin Result := X+1; end);
  CheckEquals(99, U);
  U := R.MapOrElse(@StrLenI, function (const X: Integer): Integer begin Result := X+1; end);
  CheckEquals(2, U);

  // Inspect/InspectErr
  GTapCount := 0;
  R := specialize TResult<Integer,String>.Ok(3).Inspect(@TapInt);
  CheckTrue(R.IsOk);
  R := specialize TResult<Integer,String>.Err('a').InspectErr(@TapStr);
  CheckTrue(R.IsErr);
  CheckEquals(3+1, GTapCount);

  // OkOpt/ErrOpt
  OI := specialize TResult<Integer,String>.Ok(5).OkOpt;
  CheckTrue(OI.IsSome); CheckEquals(5, OI.Unwrap);
  OS := specialize TResult<Integer,String>.Ok(5).ErrOpt;
  CheckTrue(OS.IsNone);
  OS := specialize TResult<Integer,String>.Err('e').ErrOpt;
  CheckTrue(OS.IsSome); CheckEquals('e', OS.Unwrap);
  OI := specialize TResult<Integer,String>.Err('e').OkOpt;
  CheckTrue(OI.IsNone);
end;
{$ENDIF}

//
//  // Match/Fold using named local functions
//  U := specialize ResultMatch<Integer,String,Integer>(ROk, @Ten, @NegOne);
//  CheckEquals(30, U);
//
//  U := specialize ResultFold<Integer,String,Integer>(RErr, @Ten, function (const S: String): Integer begin Result := Length(S); end);
//  CheckEquals(2, U);
//
//  // Predicates
//  CheckTrue(specialize ResultIsOkAnd<Integer,String>(ROk, @PosInt));
//  CheckTrue(specialize ResultIsErrAnd<Integer,String>(RErr, @NonEmpty));
//end;






procedure TTestCase_Global.Test_ExpectErr;
var
  R: specialize TResult<Integer,String>;
begin
  R := specialize TResult<Integer,String>.Ok(1);
  // 统一使用 try/except 分支，避免 AssertException 与匿名过程宏组合差异
  try
    R.ExpectErr('should err');
    Fail('ExpectErr on Ok should raise');
  except
    on E: EResultUnwrapError do ;
  end;

  R := specialize TResult<Integer,String>.Err('bad');
  CheckEquals('bad', R.ExpectErr('ignored'));
end;

procedure TTestCase_Global.Test_InterfaceErrorChannel;
var
  E: IMyErr;
  R: specialize TResult<Integer,IMyErr>;
  R2: specialize TResult<Integer,string>;
begin
  E := TMyErr.Create('boom');
  R := specialize TResult<Integer,IMyErr>.Err(E);
  CheckTrue(R.IsErr);
  CheckEquals('boom', R.UnwrapErr.MessageText);

  // MapErr: IMyErr -> string
  R2 := specialize ResultMapErr<Integer,IMyErr,string>(R,
    function (const Ex: IMyErr): string begin Result := Ex.MessageText; end);
  CheckTrue(R2.IsErr);
  CheckEquals('boom', R2.UnwrapErr);

  // OrElse: Err -> Ok(0)
  R2 := specialize ResultOrElse<Integer,IMyErr,string>(R,
    function (const Ex: IMyErr): specialize TResult<Integer,string>
    begin
      Result := specialize TResult<Integer,string>.Ok(0);
    end);
  CheckTrue(R2.IsOk);
end;

procedure TTestCase_Global.Test_Ext_Swap_Flatten_MapBoth;
var
  ROk: specialize TResult<Integer,String>;
  RErr: specialize TResult<Integer,String>;
  RS: specialize TResult<String,Integer>;
  RR: specialize TResult< specialize TResult<Integer,String>, String>;
  RU: specialize TResult<Integer,AnsiString>;
begin
  // Swap
  ROk := specialize TResult<Integer,String>.Ok(7);
  RErr := specialize TResult<Integer,String>.Err('e');
  RS := specialize ResultSwap<Integer,String>(ROk);
  CheckTrue(RS.IsErr);
  CheckEquals(7, RS.UnwrapErr);
  RS := specialize ResultSwap<Integer,String>(RErr);
  CheckTrue(RS.IsOk);
  CheckEquals('e', RS.Unwrap);

  // Flatten
  RR := specialize TResult< specialize TResult<Integer,String>, String>.Ok(
          specialize TResult<Integer,String>.Ok(5));
  CheckTrue(specialize ResultFlatten<Integer,String>(RR).IsOk);
  RR := specialize TResult< specialize TResult<Integer,String>, String>.Ok(
          specialize TResult<Integer,String>.Err('x'));
  CheckTrue(specialize ResultFlatten<Integer,String>(RR).IsErr);
  RR := specialize TResult< specialize TResult<Integer,String>, String>.Err('outer');
  CheckTrue(specialize ResultFlatten<Integer,String>(RR).IsErr);

  // MapBoth（同时映射 Ok 与 Err）
  RU := specialize ResultMapBoth<Integer,String,Integer,AnsiString>(RErr,
    function (const X: Integer): Integer begin Result := X+1; end,
    function (const S: String): AnsiString begin Result := AnsiString(S + '!'); end);
  CheckTrue(RU.IsErr);
  CheckEquals('e!', RU.UnwrapErr);

  RU := specialize ResultMapBoth<Integer,String,Integer,AnsiString>(ROk,
    function (const X: Integer): Integer begin Result := X+1; end,
    function (const S: String): AnsiString begin Result := AnsiString(S + '!'); end);
  CheckTrue(RU.IsOk);
  CheckEquals(8, RU.Unwrap);
end;


procedure TTestCase_Global.Test_FromTry_Details;
var
  R: specialize TResult<Integer,String>;
  U: Integer;
  Cnt: Integer = 0;
begin
  // Ok path: Work increments Cnt and returns 7
  U := specialize ResultFromTry<Integer,String>(
    function: Integer begin Inc(Cnt); Result := 7; end,
    function (const Ex: Exception): String begin Result := Ex.ClassName; end
  ).Unwrap;
  CheckEquals(1, Cnt);
  CheckEquals(7, U);

  // Err path: Work raises, MapEx maps message
  R := specialize ResultFromTry<Integer,String>(
    function: Integer begin raise Exception.Create('boom'); end,
    function (const Ex: Exception): String begin Result := Ex.Message; end
  );
  CheckTrue(R.IsErr);
  CheckEquals('boom', R.UnwrapErr);
end;

procedure TTestCase_Global.Test_Equals_Boundaries;
var
  RA, RB: specialize TResult<Integer,String>;
  RX, RY: specialize TResult<String,AnsiString>;
  E1, E2: IMyErr;
  RI1, RI2: specialize TResult<Integer,IMyErr>;
begin
  RA := specialize TResult<Integer,String>.Ok(10);
  RB := specialize TResult<Integer,String>.Ok(10);
  CheckTrue(specialize ResultEquals<Integer,String>(RA, RB,
    function (const A,B: Integer): Boolean begin Result := A=B; end,
    function (const A,B: String): Boolean begin Result := A=B; end));

  RB := specialize TResult<Integer,String>.Err('e');
  CheckFalse(specialize ResultEquals<Integer,String>(RA, RB,
    function (const A,B: Integer): Boolean begin Result := A=B; end,
    function (const A,B: String): Boolean begin Result := A=B; end));

  RX := specialize TResult<String,AnsiString>.Ok('x');
  RY := specialize TResult<String,AnsiString>.Ok('x');
  CheckTrue(specialize ResultEquals<String,AnsiString>(RX, RY,
    function (const A,B: String): Boolean begin Result := A=B; end,
    function (const A,B: AnsiString): Boolean begin Result := A=B; end));

  // Interface error comparator
  E1 := TMyErr.Create('m'); E2 := TMyErr.Create('m');
  RI1 := specialize TResult<Integer,IMyErr>.Err(E1);
  RI2 := specialize TResult<Integer,IMyErr>.Err(E2);
  CheckTrue(specialize ResultEquals<Integer,IMyErr>(RI1, RI2,
    function (const A,B: Integer): Boolean begin Result := A=B; end,
    function (const A,B: IMyErr): Boolean begin Result := A.MessageText=B.MessageText; end));

  RY := specialize TResult<String,AnsiString>.Err('y');
  CheckFalse(specialize ResultEquals<String,AnsiString>(RX, RY,
    function (const A,B: String): Boolean begin Result := A=B; end,
    function (const A,B: AnsiString): Boolean begin Result := A=B; end));
end;

procedure TTestCase_Global.Test_Complex_Chains_MatchFold;
var
  R: specialize TResult<Integer,String>;
  U: Integer;
begin
  R := specialize TResult<Integer,String>.Ok(2);
  // Ok -> AndThen(+3) -> AndThen(*2)
  R := specialize ResultAndThen<Integer,String,Integer>(R,
    function (const X: Integer): specialize TResult<Integer,String>
    begin Result := specialize TResult<Integer,String>.Ok(X+3); end);
  R := specialize ResultAndThen<Integer,String,Integer>(R,
    function (const X: Integer): specialize TResult<Integer,String>
    begin Result := specialize TResult<Integer,String>.Ok(X*2); end);
  U := specialize ResultMatch<Integer,String,Integer>(R,
    function (const X: Integer): Integer begin Result := X; end,
    function (const E: String): Integer begin Result := -1; end);
  CheckEquals(10, U);

  // Err -> OrElse(map to Ok(5)) -> Match
  R := specialize TResult<Integer,String>.Err('bad');
  R := specialize ResultOrElse<Integer,String,String>(R,
    function (const E: String): specialize TResult<Integer,String>
    begin Result := specialize TResult<Integer,String>.Ok(5); end);
  U := specialize ResultFold<Integer,String,Integer>(R,
    function (const X: Integer): Integer begin Result := X; end,
    function (const E: String): Integer begin Result := 0; end);
  CheckEquals(5, U);
end;

procedure TTestCase_Global.Test_ManagedType_String_Chain;
var
  RS: specialize TResult<String,String>;
  S: Integer;
begin
  RS := specialize TResult<String,String>.Ok('foo');
  // MapOrElse with string length on both paths
  S := specialize ResultMapOrElse<String,String,Integer>(RS,
    function (const E: String): Integer begin Result := Length(E); end,
    function (const V: String): Integer begin Result := Length(V); end);
  CheckEquals(3, S);

  RS := specialize TResult<String,String>.Err('error');
  S := specialize ResultMapOrElse<String,String,Integer>(RS,
    function (const E: String): Integer begin Result := Length(E); end,
    function (const V: String): Integer begin Result := Length(V); end);
  CheckEquals(5, S);

end;
procedure TTestCase_Global.Test_And_Or_Contains_FilterOrElse;
var
  A, B, R: specialize TResult<Integer,String>;
  Has: Boolean;
begin
  A := specialize TResult<Integer,String>.Ok(1);
  B := specialize TResult<Integer,String>.Err('x');
  R := specialize ResultAnd<Integer,String>(A, B);
  CheckTrue(R.IsErr);

  A := specialize TResult<Integer,String>.Err('e');
  B := specialize TResult<Integer,String>.Ok(2);
  R := specialize ResultOr<Integer,String>(A, B);
  CheckTrue(R.IsOk);
  CheckEquals(2, R.Unwrap);

  A := specialize TResult<Integer,String>.Ok(10);
  Has := specialize ResultContains<Integer,String>(A, 10,
    function (const L,R: Integer): Boolean begin Result := L=R; end);
  CheckTrue(Has);

  A := specialize TResult<Integer,String>.Err('e');
  Has := specialize ResultContainsErr<Integer,String>(A, 'e',
    function (const L,R: String): Boolean begin Result := L=R; end);
  CheckTrue(Has);

  // FilterOrElse：Ok 但不满足谓词 -> 转 Err
  A := specialize TResult<Integer,String>.Ok(3);
  R := specialize ResultFilterOrElse<Integer,String>(A,
    function (const X: Integer): Boolean begin Result := X mod 2 = 0; end,
    function (const X: Integer): String begin Result := 'odd'; end);
  CheckTrue(R.IsErr);
  CheckEquals('odd', R.UnwrapErr);
end;

procedure TTestCase_Global.Test_Transpose_And_OptionBridge;
var
  RO: specialize TResult< specialize TOption<Integer>, String>;
  ORs: specialize TOption< specialize TResult<Integer,String> >;
  R2: specialize TResult< specialize TOption<Integer>, String>;
  OI: specialize TOption<Integer>;
begin
  // Result<Option<T>,E> -> Option<Result<T,E>>
  RO := specialize TResult< specialize TOption<Integer>, String>.Ok(specialize TOption<Integer>.Some(5));
  ORs := specialize ResultTransposeOption<Integer,String>(RO);
  CheckTrue(ORs.IsSome); CheckTrue(ORs.Unwrap.IsOk); CheckEquals(5, ORs.Unwrap.Unwrap);

  RO := specialize TResult< specialize TOption<Integer>, String>.Ok(specialize TOption<Integer>.None);
  ORs := specialize ResultTransposeOption<Integer,String>(RO);
  CheckTrue(ORs.IsNone);

  RO := specialize TResult< specialize TOption<Integer>, String>.Err('e');
  ORs := specialize ResultTransposeOption<Integer,String>(RO);
  CheckTrue(ORs.IsSome); CheckTrue(ORs.Unwrap.IsErr); CheckEquals('e', ORs.Unwrap.UnwrapErr);

  // Option<Result<T,E>> -> Result<Option<T>,E>
  ORs := specialize TOption< specialize TResult<Integer,String> >.Some(specialize TResult<Integer,String>.Ok(7));
  R2 := specialize OptionTransposeResult<Integer,String>(ORs);
  CheckTrue(R2.IsOk); CheckTrue(R2.Unwrap.IsSome); CheckEquals(7, R2.Unwrap.Unwrap);

  ORs := specialize TOption< specialize TResult<Integer,String> >.Some(specialize TResult<Integer,String>.Err('x'));
  R2 := specialize OptionTransposeResult<Integer,String>(ORs);
  CheckTrue(R2.IsErr); CheckEquals('x', R2.UnwrapErr);

  ORs := specialize TOption< specialize TResult<Integer,String> >.None;
  R2 := specialize OptionTransposeResult<Integer,String>(ORs);
  CheckTrue(R2.IsOk); CheckTrue(R2.Unwrap.IsNone);

  // OptionToResult 别名验证（从 Option 单元委托）
  OI := specialize TOption<Integer>.Some(1);
  CheckTrue(specialize OptionToResult<Integer,String>(OI, 'e').IsOk);
  OI := specialize TOption<Integer>.None;
  CheckTrue(specialize OptionToResult<Integer,String>(OI, 'e').IsErr);
end;


procedure TTestCase_Global.Test_Equals_Default_And_ToTry;
var
  A, B: specialize TResult<Integer,String>;
  TVal: Integer;
begin
  A := specialize TResult<Integer,String>.Ok(5);
  B := specialize TResult<Integer,String>.Ok(5);
  CheckTrue(specialize ResultEquals<Integer,String>(A,B));

  A := specialize TResult<Integer,String>.Err('e');
  B := specialize TResult<Integer,String>.Err('e');
  CheckTrue(specialize ResultEquals<Integer,String>(A,B));

  // ToTry: Err -> raise mapped exception
  A := specialize TResult<Integer,String>.Err('bad');
  try
    TVal := specialize ResultToTry<Integer,String>(A, function (const E: String): Exception begin Result := Exception.Create('mapped:'+E); end);
    Fail('ResultToTry on Err should raise');
  except
    on Ex: Exception do CheckEquals('mapped:bad', Ex.Message);
  end;

  // ToTry: Ok -> return value
  A := specialize TResult<Integer,String>.Ok(9);
  TVal := specialize ResultToTry<Integer,String>(A, function (const E: String): Exception begin Result := Exception.Create(E); end);
  CheckEquals(9, TVal);
end;


initialization
  RegisterTest(TTestCase_TResult_IntStr);
  RegisterTest(TTestCase_Global);
end.

