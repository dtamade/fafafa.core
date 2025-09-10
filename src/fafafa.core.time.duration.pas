unit fafafa.core.time.duration;

{$I fafafa.core.settings.inc}

interface

type
  // 以纳秒为内部单位的持续时间类型（唯一真源）
  TDuration = record
  private
    FNs: Int64; // 纳秒
  public
    // 构造
    class function Zero: TDuration; static;
    class function FromNs(const ANs: Int64): TDuration; static;
    class function FromUs(const AUs: Int64): TDuration; static;
    class function FromMs(const AMs: Int64): TDuration; static;
    class function FromSec(const ASec: Int64): TDuration; static;

    // 访问
    function AsNs: Int64; inline;        // 纳秒（整数）
    function AsUs: Int64; inline;        // 微秒
    function AsMs: Int64; inline;        // 毫秒
    function AsSec: Int64; inline;       // 秒

    // 算术（可按需扩展）
    class operator +(const A, B: TDuration): TDuration; inline;
    class operator -(const A, B: TDuration): TDuration; inline;
  end;

implementation

{ TDuration }

class function TDuration.Zero: TDuration;
begin
  Result.FNs := 0;
end;

class function TDuration.FromNs(const ANs: Int64): TDuration;
begin
  Result.FNs := ANs;
end;

class function TDuration.FromUs(const AUs: Int64): TDuration;
begin
  Result.FNs := AUs * 1000;
end;

class function TDuration.FromMs(const AMs: Int64): TDuration;
begin
  Result.FNs := AMs * 1000 * 1000;
end;

class function TDuration.FromSec(const ASec: Int64): TDuration;
begin
  Result.FNs := ASec * 1000 * 1000 * 1000;
end;

function TDuration.AsNs: Int64;
begin
  Result := FNs;
end;

function TDuration.AsUs: Int64;
begin
  Result := FNs div 1000;
end;

function TDuration.AsMs: Int64;
begin
  Result := FNs div (1000 * 1000);
end;

function TDuration.AsSec: Int64;
begin
  Result := FNs div (1000 * 1000 * 1000);
end;

class operator TDuration.+(const A, B: TDuration): TDuration;
begin
  Result.FNs := A.FNs + B.FNs;
end;

class operator TDuration.-(const A, B: TDuration): TDuration;
begin
  Result.FNs := A.FNs - B.FNs;
end;

end.

