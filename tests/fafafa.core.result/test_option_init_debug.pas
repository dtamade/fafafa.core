program test_option_init_debug;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.option.base;

type
  TIntOption = specialize TOption<Integer>;

var
  O: TIntOption;
begin
  WriteLn('FHas = ', O.IsNone);
  WriteLn('IsSome = ', O.IsSome);
  WriteLn('IsNone = ', O.IsNone);
  
  // Try to unwrap with default
  WriteLn('UnwrapOr(999) = ', O.UnwrapOr(999));
end.
