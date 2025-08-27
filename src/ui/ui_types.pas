unit ui_types;

{$mode objfpc}{$H+}

interface

uses
  fafafa.core.term;

type
  TUiSize = record
    W: term_size_t;
    H: term_size_t;
  end;

  TUiPoint = record
    X: term_size_t;
    Y: term_size_t;
  end;

  TUiRect = record
    X: term_size_t;
    Y: term_size_t;
    W: term_size_t;
    H: term_size_t;
  end;

  TUiPadding = record
    Top, Right, Bottom, Left: term_size_t;
  end;


implementation

end.

