unit fafafa.core.io.scanner;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

{
  fafafa.core.io.scanner - 惰性行迭代器与可配置扫描器

  提供：
  - ILineIterator: 惰性行迭代器接口
  - TLineIterator: 基于 TBufReader 的行迭代器实现
  - TScanner: 可配置的通用扫描器（自定义分隔符、最大长度等）

  用法示例：
    // 惰性行迭代
    var It: ILineIterator;
        Line: string;
    It := IO.LinesIter(SomeReader);
    while It.Next(Line) do
      ProcessLine(Line);

    // 扫描器（自定义分隔符）
    var Sc: TScanner;
        Token: string;
    Sc := IO.Scanner(SomeReader).Delimiter(',').MaxLength(1024);
    while Sc.Scan(Token) do
      ProcessToken(Token);

  参考: Go bufio.Scanner, Rust std::io::BufRead::lines()
}

interface

uses
  SysUtils,
  fafafa.core.io.base,
  fafafa.core.io.buffered;

type
  { ILineIterator - 惰性行迭代器接口

    惰性地逐行读取，避免一次性加载整个文件到内存。
  }
  ILineIterator = interface
    ['{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}']
    { 读取下一行，成功返回 True，EOF 返回 False }
    function Next(out Line: string): Boolean;
    { 获取当前行号（从 1 开始，EOF 后为最后一行号） }
    function LineNumber: Integer;
    { 获取最近一次错误（nil 表示无错误） }
    function Error: Exception;
  end;

  { TLineIterator - 行迭代器实现

    内部使用 TBufReader，支持 LF 和 CRLF 行终止符。
  }
  TLineIterator = class(TInterfacedObject, ILineIterator)
  private
    FBufReader: TBufReader;
    FLineNumber: Integer;
    FError: Exception;
    FOwnsReader: Boolean;
  public
    constructor Create(AReader: IReader; ABufSize: SizeInt = DefaultBufSize);
    destructor Destroy; override;

    { ILineIterator }
    function Next(out Line: string): Boolean;
    function LineNumber: Integer;
    function Error: Exception;
  end;

  { TScannerOptions - 扫描器选项 }
  TScannerOptions = record
    Delimiter: Byte;        // 分隔符（默认 LF）
    MaxLength: SizeInt;     // 最大令牌长度（0 表示无限制）
    KeepDelimiter: Boolean; // 是否保留分隔符
    TrimCR: Boolean;        // 是否去除 CR（用于 CRLF 兼容）
  end;

  { TLineEnumerator - for-in 行迭代枚举器

    用于支持 Pascal for-in 语法的惰性行迭代。
  }
  TLineEnumerator = class
  private
    FBufReader: TBufReader;
    FCurrent: string;
    FOwns: Boolean;
  public
    constructor Create(AReader: IReader);
    destructor Destroy; override;
    function MoveNext: Boolean;
    property Current: string read FCurrent;
  end;

  { TLineEnumerable - for-in 行迭代容器

    返回 TLineEnumerator 以支持 for Line in IO.ReadLines(R) 语法。
  }
  TLineEnumerable = record
  private
    FReader: IReader;
  public
    function GetEnumerator: TLineEnumerator;
  end;

  { TScanner - 可配置的通用扫描器

    支持自定义分隔符、最大长度限制、保留/去除分隔符等选项。
    超出最大长度时抛出 EIOError(ekInvalidData)。
  }
  TScanner = class(TInterfacedObject, ICloser)
  private
    FBufReader: TBufReader;
    FOptions: TScannerOptions;
    FTokenCount: Integer;
    FError: Exception;
    FErrorOwned: Boolean;  // True if we should free FError in destructor
    FOwnsReader: Boolean;
    FEOF: Boolean;
  public
    constructor Create(AReader: IReader; ABufSize: SizeInt = DefaultBufSize);
    destructor Destroy; override;

    { 配置方法（流畅接口） }
    function Delimiter(ADelim: Byte): TScanner; overload;
    function Delimiter(ADelim: Char): TScanner; overload;
    function MaxLength(AMax: SizeInt): TScanner;
    function KeepDelimiter(AKeep: Boolean): TScanner;
    function TrimCR(ATrim: Boolean): TScanner;

    { 扫描方法 }
    function Scan(out Token: string): Boolean;
    function ScanBytes(out Token: TBytes): Boolean;

    { 状态查询 }
    function TokenCount: Integer;
    function Error: Exception;
    function EOF: Boolean;

    { ICloser }
    procedure Close;
  end;

{ 工厂函数 }
function LineIterator(AReader: IReader; ABufSize: SizeInt = DefaultBufSize): ILineIterator;
function Scanner(AReader: IReader; ABufSize: SizeInt = DefaultBufSize): TScanner;
{ for-in 行迭代 }
function ReadLines(AReader: IReader): TLineEnumerable;

implementation

uses
  fafafa.core.io.error;

{ TLineIterator }

constructor TLineIterator.Create(AReader: IReader; ABufSize: SizeInt);
begin
  inherited Create;
  if AReader = nil then
    raise EIOError.Create('TLineIterator: reader is nil');
  FBufReader := TBufReader.Create(AReader, ABufSize);
  FOwnsReader := True;
  FLineNumber := 0;
  FError := nil;
end;

destructor TLineIterator.Destroy;
begin
  if FOwnsReader then
    FreeAndNil(FBufReader);
  FreeAndNil(FError);
  inherited Destroy;
end;

function TLineIterator.Next(out Line: string): Boolean;
begin
  Line := '';
  if FBufReader = nil then
    Exit(False);

  try
    Result := FBufReader.ReadLine(Line);
    if Result then
      Inc(FLineNumber);
  except
    on E: Exception do
    begin
      FreeAndNil(FError);
      FError := Exception(AcquireExceptionObject);
      Result := False;
    end;
  end;
end;

function TLineIterator.LineNumber: Integer;
begin
  Result := FLineNumber;
end;

function TLineIterator.Error: Exception;
begin
  Result := FError;
end;

{ TScanner }

constructor TScanner.Create(AReader: IReader; ABufSize: SizeInt);
begin
  inherited Create;
  if AReader = nil then
    raise EIOError.Create('TScanner: reader is nil');
  FBufReader := TBufReader.Create(AReader, ABufSize);
  FOwnsReader := True;
  FTokenCount := 0;
  FError := nil;
  FErrorOwned := False;
  FEOF := False;

  // 默认选项
  FOptions.Delimiter := 10;  // LF
  FOptions.MaxLength := 0;   // 无限制
  FOptions.KeepDelimiter := False;
  FOptions.TrimCR := True;   // 默认去除 CRLF 中的 CR
end;

destructor TScanner.Destroy;
begin
  if FOwnsReader then
    FreeAndNil(FBufReader);
  if FErrorOwned then
    FreeAndNil(FError);
  inherited Destroy;
end;

function TScanner.Delimiter(ADelim: Byte): TScanner;
begin
  FOptions.Delimiter := ADelim;
  Result := Self;
end;

function TScanner.Delimiter(ADelim: Char): TScanner;
begin
  FOptions.Delimiter := Byte(ADelim);
  Result := Self;
end;

function TScanner.MaxLength(AMax: SizeInt): TScanner;
begin
  FOptions.MaxLength := AMax;
  Result := Self;
end;

function TScanner.KeepDelimiter(AKeep: Boolean): TScanner;
begin
  FOptions.KeepDelimiter := AKeep;
  Result := Self;
end;

function TScanner.TrimCR(ATrim: Boolean): TScanner;
begin
  FOptions.TrimCR := ATrim;
  Result := Self;
end;

function TScanner.Scan(out Token: string): Boolean;
var
  TokenBytes: TBytes;
  Len: SizeInt;
begin
  Token := '';
  Result := ScanBytes(TokenBytes);
  if Result then
  begin
    Len := Length(TokenBytes);
    if Len > 0 then
      SetString(Token, PAnsiChar(@TokenBytes[0]), Len);
  end;
end;

function TScanner.ScanBytes(out Token: TBytes): Boolean;
var
  Buf: PByte;
  Len, I, TokenLen, TokenCap: SizeInt;
begin
  SetLength(Token, 0);
  if FEOF or (FBufReader = nil) then
    Exit(False);

  TokenLen := 0;
  TokenCap := 0;

  try
    while True do
    begin
      if not FBufReader.FillBuf(Buf, Len) then
      begin
        // EOF
        FEOF := True;
        if TokenLen > 0 then
        begin
          // 处理 TrimCR
          if FOptions.TrimCR and (TokenLen > 0) and (Token[TokenLen - 1] = 13) then
            Dec(TokenLen);
          SetLength(Token, TokenLen);
          Inc(FTokenCount);
          Exit(True);
        end;
        Exit(False);
      end;

      // 在缓冲区中查找分隔符
      for I := 0 to Len - 1 do
      begin
        if Buf[I] = FOptions.Delimiter then
        begin
          // 计算最终 token 长度并检查 MaxLength
          if FOptions.KeepDelimiter then
          begin
            if (FOptions.MaxLength > 0) and (TokenLen + I + 1 > FOptions.MaxLength) then
            begin
              FError := EIOError.Create(ekInvalidData, 'scan', '',
                0, Format('token exceeds max length %d', [FOptions.MaxLength]));
              FEOF := True;
              raise FError;
            end;
          end
          else
          begin
            if (FOptions.MaxLength > 0) and (TokenLen + I > FOptions.MaxLength) then
            begin
              FError := EIOError.Create(ekInvalidData, 'scan', '',
                0, Format('token exceeds max length %d', [FOptions.MaxLength]));
              FEOF := True;
              raise FError;
            end;
          end;

          // 追加到 Token
          if FOptions.KeepDelimiter then
          begin
            if TokenLen + I + 1 > TokenCap then
            begin
              TokenCap := TokenLen + I + 1;
              SetLength(Token, TokenCap);
            end;
            if I > 0 then
              Move(Buf[0], Token[TokenLen], I);
            Token[TokenLen + I] := Buf[I];
            Inc(TokenLen, I + 1);
          end
          else
          begin
            if I > 0 then
            begin
              if TokenLen + I > TokenCap then
              begin
                TokenCap := TokenLen + I;
                SetLength(Token, TokenCap);
              end;
              Move(Buf[0], Token[TokenLen], I);
              Inc(TokenLen, I);
            end;
          end;

          FBufReader.Consume(I + 1);

          // 处理 TrimCR（如果分隔符是 LF 且前一个字符是 CR）
          if FOptions.TrimCR and (FOptions.Delimiter = 10) and
             (TokenLen > 0) and (Token[TokenLen - 1] = 13) then
            Dec(TokenLen);

          SetLength(Token, TokenLen);
          Inc(FTokenCount);
          Exit(True);
        end;
      end;

      // 没找到分隔符，追加整个缓冲区
      // 检查最大长度
      if (FOptions.MaxLength > 0) and (TokenLen + Len > FOptions.MaxLength) then
      begin
        FError := EIOError.Create(ekInvalidData, 'scan', '',
          0, Format('token exceeds max length %d', [FOptions.MaxLength]));
        FEOF := True;
        raise FError;
      end;

      if TokenLen + Len > TokenCap then
      begin
        TokenCap := TokenLen + Len + 256;
        SetLength(Token, TokenCap);
      end;
      Move(Buf[0], Token[TokenLen], Len);
      Inc(TokenLen, Len);

      FBufReader.Consume(Len);
    end;
  except
    on E: EIOError do
    begin
      // FError is already set if we raised it ourselves
      // The raised exception is not owned by us (will be freed by caller)
      if FError = nil then
        FError := E;
      raise;
    end;
    on E: Exception do
    begin
      FError := EIOError.Create(ekUnknown, 'scan', '', 0, E.Message);
      // We're raising this new exception, so we don't own it
      raise FError;
    end;
  end;
end;

function TScanner.TokenCount: Integer;
begin
  Result := FTokenCount;
end;

function TScanner.Error: Exception;
begin
  Result := FError;
end;

function TScanner.EOF: Boolean;
begin
  Result := FEOF;
end;

procedure TScanner.Close;
begin
  if FOwnsReader then
    FreeAndNil(FBufReader);
  FEOF := True;
end;

{ TLineEnumerator }

constructor TLineEnumerator.Create(AReader: IReader);
begin
  inherited Create;
  FBufReader := TBufReader.Create(AReader);
  FOwns := True;
  FCurrent := '';
end;

destructor TLineEnumerator.Destroy;
begin
  if FOwns then
    FreeAndNil(FBufReader);
  inherited Destroy;
end;

function TLineEnumerator.MoveNext: Boolean;
begin
  Result := FBufReader.ReadLine(FCurrent);
end;

{ TLineEnumerable }

function TLineEnumerable.GetEnumerator: TLineEnumerator;
begin
  Result := TLineEnumerator.Create(FReader);
end;

{ Factory functions }

function LineIterator(AReader: IReader; ABufSize: SizeInt): ILineIterator;
begin
  Result := TLineIterator.Create(AReader, ABufSize);
end;

function Scanner(AReader: IReader; ABufSize: SizeInt): TScanner;
begin
  Result := TScanner.Create(AReader, ABufSize);
end;

function ReadLines(AReader: IReader): TLineEnumerable;
begin
  Result.FReader := AReader;
end;

end.
