unit fafafa.core.json.incr;

{$MODE OBJFPC}{$H+}

interface

uses
  SysUtils,
  fafafa.core.mem.allocator,
  fafafa.core.json.core;

type
  PJsonIncrState = ^TJsonIncrState;
  TJsonIncrState = record
    Buf: PByte;            // 缓冲区起始指针（外部提供，不归本库释放）
    BufCap: SizeUInt;      // 缓冲区总长度
    Avail: SizeUInt;       // 当前可用长度（已喂入）
    Consumed: SizeUInt;    // 已消费长度（上一份文档已读取的前缀）
    Flags: TJsonReadFlags; // 读取标志
    Allocator: IAllocator; // 分配器（接口优先）
    // 跨块 UTF-8 续字节需求（0 表示无）
    PendingUtf8: Byte;
  end;

function JsonIncrNew(ABuf: PChar; ABufLen: SizeUInt; AFlags: TJsonReadFlags; AAllocator: IAllocator): PJsonIncrState;
function JsonIncrRead(AState: PJsonIncrState; AFeedLen: SizeUInt; var AError: TJsonError): TJsonDocument;
procedure JsonIncrFree(AState: PJsonIncrState);

implementation

function JsonIncrNew(ABuf: PChar; ABufLen: SizeUInt; AFlags: TJsonReadFlags; AAllocator: IAllocator): PJsonIncrState;
begin
  Result := nil;
  if (ABuf = nil) or (ABufLen = 0) then Exit;
  New(Result);
  Result^.Buf := PByte(ABuf);
  Result^.BufCap := ABufLen;
  Result^.Avail := 0;
  Result^.Consumed := 0;
  Result^.Flags := AFlags;
  Result^.Allocator := AAllocator;
  Result^.PendingUtf8 := 0;
end;

function JsonIncrRead(AState: PJsonIncrState; AFeedLen: SizeUInt; var AError: TJsonError): TJsonDocument;
var
  LHdr, LCur, LEnd: PByte;
  ReadSize: SizeUInt;
  UseFlags: TJsonReadFlags;
  SliceLen: SizeUInt;
  // 近尾端启发式检测用变量
  TailStart, I, Rem: SizeUInt;
  NeedMore: Boolean;
  B: Byte;
  // 额外扫描用
  BackCnt: SizeUInt;
  J: SizeInt;
  InStr: Boolean;
  TmpBuf, TmpHdr, TmpCur, TmpEnd: PByte;
  TryDoc: TJsonDocument;
  TryErr: TJsonError;
begin
  Result := nil;
  if (AState = nil) or (AFeedLen = 0) then begin
    AError.Code := jecInvalidParameter; AError.Message := 'invalid incr params'; AError.Position := 0; Exit;
  end;
  if (AState^.Avail + AFeedLen > AState^.BufCap) then begin
    AError.Code := jecInvalidParameter; AError.Message := 'feed length exceeds buffer capacity'; AError.Position := AState^.Avail; Exit;
  end;
  Inc(AState^.Avail, AFeedLen);
  // 如存在挂起的 UTF-8 续字节需求，优先判断是否满足
  if (AState^.PendingUtf8 > 0) then
  begin
    if AFeedLen < AState^.PendingUtf8 then
    begin
      AError.Code := jecMore; AError.Message := 'need more data'; AError.Position := AState^.Avail - AState^.Consumed; Exit(nil);
    end
    else
      AState^.PendingUtf8 := 0; // 足够，清空并继续
  end;

  // 从已消费偏移处开始解析，容许尾随内容以便连续解析多文档
  LHdr := AState^.Buf + AState^.Consumed; LCur := LHdr; LEnd := AState^.Buf + AState^.Avail;
  UseFlags := AState^.Flags + [jrfStopWhenDone];
  // 统一通过 JsonReadOpts 在内部拷贝上解析，避免修改外部缓冲；失败时做 MORE 判定
  SliceLen := AState^.Avail - AState^.Consumed;
  if SliceLen = 0 then begin AError.Code := jecInvalidParameter; AError.Message := 'no data fed'; AError.Position := 0; Exit(nil); end;
  // 在临时拷贝上试解析，避免对原缓冲造成破坏；附加 NUL 终止，兼容潜在越界读取
  GetMem(TmpBuf, SliceLen + 1);
  try
    TmpHdr := TmpBuf; Move(LHdr^, TmpHdr^, SliceLen); (TmpHdr + SliceLen)^ := 0;
    TryDoc := JsonReadOpts(PChar(TmpHdr), SliceLen, UseFlags, AState^.Allocator, TryErr);
  finally
    // 不在此处释放 TmpBuf，下面还需要根据 TryDoc/TryErr 分支处理
  end;

  if Assigned(TryDoc) then
  begin
    // 试解析成功：直接返回试文档（其内部有独立输入缓冲），并释放临时输入拷贝

    FreeMem(TmpBuf); TmpBuf := nil;
    AError := Default(TJsonError);
    Result := TryDoc;
  end
  else
  begin
    // 试解析失败：释放临时缓冲并基于 TryErr 做 MORE 判定
    FreeMem(TmpBuf); TmpBuf := nil;
    AError := TryErr;



    // 解析失败：判断是否为“数据不足”的情形，尽量返回 jecMore 以便上层继续喂数据
    NeedMore := False;
    // 1) 明确的意外结束
    if (AError.Code = jecUnexpectedEnd) then
      NeedMore := True
    else if (AError.Code = jecInvalidString) or (AError.Code = jecInvalidNumber) then
    begin
      // 先基于错误消息关键字判断典型的“未闭合字符串/不完整 UTF-8” → MORE
      if (AError.Code = jecInvalidString) then
      begin
        if (Pos('Unterminated string', AError.Message) > 0) or
           (Pos('Invalid UTF-8 encoding in string', AError.Message) > 0) then
          NeedMore := True;
      end;
      if not NeedMore then
      begin
        // 2) 错误位置接近尾部（保守阈值 8 字节内）
        if (AError.Position + 8 >= SliceLen) then
          NeedMore := True
        else
        begin
          // 3) 尾部启发式：检查最后 8 字节是否存在未完成的转义或 UTF-8 起始字节
          if SliceLen >= 1 then
          begin
            if SliceLen > 8 then TailStart := SliceLen - 8 else TailStart := 0;
            I := TailStart;
            while I < SliceLen do
            begin
              B := (LHdr + I)^;
              // 反斜杠可能开启转义序列，落在尾部很近，保守认为需要更多数据
              if B = CHAR_BACKSLASH then begin NeedMore := True; Break; end;
              // 高位字节可能是 UTF-8 多字节起始，且后续不足
              if (B >= $C2) and (B <= $F4) then
              begin
                // 2字节起始且余量不足1/ 3字节起始且余量不足2/ 4字节起始且余量不足3
                Rem := SliceLen - I - 1; // 已读当前B后剩余可用字节数
                if ((B <= $DF) and (Rem < 1)) or
                   ((B >= $E0) and (B <= $EF) and (Rem < 2)) or
                   ((B >= $F0) and (B <= $F4) and (Rem < 3)) then begin NeedMore := True; Break; end;
              end;
              Inc(I);
            end;

          // 4) 引号奇偶启发：若当前切片处于字符串内（未闭合），判为 MORE
          if not NeedMore then
          begin
            InStr := False; J := 0; I := 0;
            // 从头扫描到尾，维护“是否在字符串内”的状态
            while I < SliceLen do
            begin
              B := (LHdr + I)^;
              if B = CHAR_QUOTE then
              begin
                // 统计前导反斜杠数量，判断是否为转义引号
                BackCnt := 0; J := I - 1;
                while (J >= 0) and ((LHdr + J)^ = CHAR_BACKSLASH) do begin Inc(BackCnt); Dec(J); end;
                if (BackCnt and 1) = 0 then InStr := not InStr; // 未转义引号翻转状态
                Inc(I);
                Continue;
              end;
              Inc(I);
            end;
            if InStr then NeedMore := True;
          end;
          end;
        end;
      end;
    end;

    if NeedMore then
    begin
      // 若检测到不完整 UTF-8 前导字节，计算所需续字节数并记录到状态中
      if (AState <> nil) then
      begin
        AState^.PendingUtf8 := 0;
        if SliceLen >= 1 then
        begin
          // 从尾部反向扫描寻找起始字节（更保守）：
          // 1) 先回退跨过所有 continuation 字节至候选起始字节 I；
          // 2) 若 I>0，且 I-1 不是 ASCII/反斜杠/引号，则放弃设置 PendingUtf8（避免跨 codepoint 误判）。
          I := SliceLen - 1;
          while (I > 0) and (((LHdr + I)^ and $C0) = $80) do Dec(I);
          if I < SliceLen then
          begin
            if (I > 0) then
            begin
              B := (LHdr + (I - 1))^;
              if not ((B < 128) or (B = CHAR_BACKSLASH) or (B = CHAR_QUOTE)) then
              begin
                // 上一个字节不是 ASCII/反斜杠/引号，保守不设置 PendingUtf8；但仍返回 MORE（不提前退出）
                AState^.PendingUtf8 := 0;
              end;
            end;
            B := (LHdr + I)^;
            Rem := SliceLen - I - 1; // 已有续字节数
            if (B >= $C2) and (B <= $DF) and (Rem < 1) then AState^.PendingUtf8 := 1
            else if (B >= $E0) and (B <= $EF) and (Rem < 2) then AState^.PendingUtf8 := 2 - Rem
            else if (B >= $F0) and (B <= $F4) and (Rem < 3) then AState^.PendingUtf8 := 3 - Rem;
          end;
        end;
      end;
      AError.Code := jecMore; AError.Message := 'need more data'; AError.Position := SliceLen; Exit(nil);
    end;
    Exit(nil);
  end;
  // 成功解析：推进已消费偏移；如恰好消费完，复位 Avail/Consumed
  if Assigned(Result) then begin
    ReadSize := JsonDocGetReadSize(Result);
    Inc(AState^.Consumed, ReadSize);
    if AState^.Consumed >= AState^.Avail then begin
      AState^.Consumed := 0; AState^.Avail := 0;
    end;
  end;
end;

procedure JsonIncrFree(AState: PJsonIncrState);
begin
  if Assigned(AState) then Dispose(AState);
end;

end.

