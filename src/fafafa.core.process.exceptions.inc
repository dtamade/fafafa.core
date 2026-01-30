// Exceptions implementation for fafafa.core.process

constructor EProcessExitError.Create(const Msg: string; const AExitCode: Integer);
begin
  inherited Create(Msg);
  FExitCode := AExitCode;
end;

