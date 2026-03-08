function GetCPUInformation: TCPUInfo; inline;
function GetCurrentBackend: TSimdBackend; inline;
function GetCurrentBackendInfo: TSimdBackendInfo; inline;
function GetBackendName(aBackend: TSimdBackend): string; inline;
procedure ForceBackend(aBackend: TSimdBackend); inline;
procedure ResetBackendSelection; inline;
