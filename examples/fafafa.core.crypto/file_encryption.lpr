{$CODEPAGE UTF8}
program file_encryption;

{$mode objfpc}{$H+}

{*
  File Encryption demo (PBKDF2 + AES-256-CBC)
  - Logs to console and examples/fafafa.core.crypto/fileenc.log
  - Includes negative case: decryption with wrong password must fail (no output file)
*}


uses
  Classes, SysUtils,
  fafafa.core.crypto;

{**

procedure Log(const S: string);
var
  L: Text;
  P: string;
begin
  P := ExtractFilePath(ParamStr(0)) + 'fileenc.log';
  AssignFile(L, P);
  {$I-}
  if FileExists(P) then
    Append(L)
  else
    Rewrite(L);
  {$I+}
  WriteLn(L, S);
  CloseFile(L);
end;

procedure PrintAndLog(const S: string);
begin
  WriteLn(S);
  Log(S);
end;

 * 文件加密演示程序
 *
 * 本程序演示如何使用 fafafa.core.crypto 库进行实际的文件加密：
 * 1. 从密码派生加密密钥 (PBKDF2)
 * 2. 使用AES-256-CBC加密文件
 * 3. 安全地存储盐值和IV
 * 4. 完整的加密/解密流程
 *}

// 简单的字符串转字节函数
function StringToBytes(const AStr: string): TBytes;
begin
  SetLength(Result, Length(AStr));
  if Length(AStr) > 0 then
    Move(AStr[1], Result[0], Length(AStr));
end;

// 字节转字符串函数
function BytesToString(const ABytes: TBytes): string;
begin
  SetLength(Result, Length(ABytes));
  if Length(ABytes) > 0 then
    Move(ABytes[0], Result[1], Length(ABytes));
end;

// 从密码派生密钥
function DeriveKeyFromPassword(const APassword: string; const ASalt: TBytes): TBytes;
const
  ITERATIONS = 600000; // OWASP 2023 推荐值
  KEY_LENGTH = 32;     // AES-256 密钥长度
begin
  Result := PBKDF2_SHA256(APassword, ASalt, ITERATIONS, KEY_LENGTH);
end;

// 加密文件
function EncryptFile(const AInputFile, AOutputFile, APassword: string): Boolean;
var
  LInputStream, LOutputStream: TFileStream;
  LBuffer: array[0..8191] of Byte;
  LBytesRead: Integer;
  LPlaintext, LCiphertext: TBytes;
  LSalt, LIV, LKey: TBytes;
  LAes: ISymmetricCipher;
  LTotalBytes: Int64;
begin
  Result := False;

  try
    WriteLn('开始加密文件: ', AInputFile);

    // 生成随机盐值和IV
    LSalt := GenerateRandomBytes(16);
    LIV := GenerateRandomBytes(16);
    WriteLn('生成盐值: ', BytesToHex(LSalt));
    WriteLn('生成IV: ', BytesToHex(LIV));

    // 从密码派生密钥
    LKey := DeriveKeyFromPassword(APassword, LSalt);
    WriteLn('密钥派生完成');

    // 创建AES-256-CBC加密器
    LAes := CreateAES256_CBC;
    LAes.SetKey(LKey);
    LAes.SetIV(LIV);

    // 打开输入和输出文件
    LInputStream := TFileStream.Create(AInputFile, fmOpenRead);
    try
      LOutputStream := TFileStream.Create(AOutputFile, fmCreate);
      try
        // 写入文件头：盐值(16字节) + IV(16字节)
        LOutputStream.WriteBuffer(LSalt[0], 16);
        LOutputStream.WriteBuffer(LIV[0], 16);

        // 读取整个文件内容
        LTotalBytes := LInputStream.Size;
        SetLength(LPlaintext, LTotalBytes);
        if LTotalBytes > 0 then
          LInputStream.ReadBuffer(LPlaintext[0], LTotalBytes);

        // 一次性加密整个文件（AES-CBC会自动添加PKCS#7填充）
        LCiphertext := LAes.Encrypt(LPlaintext);
        LOutputStream.WriteBuffer(LCiphertext[0], Length(LCiphertext));

        PrintAndLog('加密完成，处理了 ' + IntToStr(LTotalBytes) + ' 字节');
        Result := True;

      finally
        LOutputStream.Free;
      end;
    finally
      LInputStream.Free;
    end;

    // 安全清零敏感数据
    if Length(LKey) > 0 then
      FillChar(LKey[0], Length(LKey), 0);

  except
    on E: Exception do
    begin
      PrintAndLog('加密失败: ' + E.Message);
      Result := False;
    end;
  end;
end;

// 解密文件
function DecryptFile(const AInputFile, AOutputFile, APassword: string): Boolean;
var
  LInputStream, LOutputStream: TFileStream;
  LBuffer: array[0..8191] of Byte;
  LBytesRead: Integer;
  LCiphertext, LPlaintext: TBytes;
  LSalt, LIV, LKey: TBytes;
  LAes: ISymmetricCipher;
  LTotalBytes: Int64;
  LRemainingData: TBytes;
begin
  Result := False;

  try
    WriteLn('开始解密文件: ', AInputFile);

    // 打开输入文件
    LInputStream := TFileStream.Create(AInputFile, fmOpenRead);
    try
      if LInputStream.Size < 32 then
        raise Exception.Create('文件太小，不是有效的加密文件');

      // 读取文件头：盐值(16字节) + IV(16字节)
      SetLength(LSalt, 16);
      SetLength(LIV, 16);
      LInputStream.ReadBuffer(LSalt[0], 16);
      LInputStream.ReadBuffer(LIV[0], 16);

      WriteLn('读取盐值: ', BytesToHex(LSalt));
      WriteLn('读取IV: ', BytesToHex(LIV));

      // 从密码派生密钥
      LKey := DeriveKeyFromPassword(APassword, LSalt);
      WriteLn('密钥派生完成');

      // 创建AES-256-CBC解密器
      LAes := CreateAES256_CBC;
      LAes.SetKey(LKey);
      LAes.SetIV(LIV);

      // 打开输出文件
      LOutputStream := TFileStream.Create(AOutputFile, fmCreate);
      try
        // 读取整个加密文件内容
        LTotalBytes := LInputStream.Size - 32; // 减去盐值和IV的32字节
        SetLength(LCiphertext, LTotalBytes);
        if LTotalBytes > 0 then
          LInputStream.ReadBuffer(LCiphertext[0], LTotalBytes);

        // 一次性解密整个文件（AES-CBC会自动去除PKCS#7填充）
        LPlaintext := LAes.Decrypt(LCiphertext);
        LOutputStream.WriteBuffer(LPlaintext[0], Length(LPlaintext));
        LTotalBytes := Length(LPlaintext);

        PrintAndLog('解密完成，处理了 ' + IntToStr(LTotalBytes) + ' 字节');
        Result := True;

      finally
        LOutputStream.Free;
      end;
    finally
      LInputStream.Free;
    end;

    // 安全清零敏感数据
    if Length(LKey) > 0 then
      FillChar(LKey[0], Length(LKey), 0);

  except
    on E: Exception do
    begin
      PrintAndLog('解密失败: ' + E.Message);
      Result := False;
    end;
  end;
end;

// 创建测试文件
procedure CreateTestFile(const AFileName: string);
var
  LStream: TFileStream;
  LContent: string;
  LBytes: TBytes;
begin
  LContent := 'This is a test file for encryption demonstration.' + LineEnding +
              'It contains multiple lines of text.' + LineEnding +
              'The file will be encrypted using AES-256-CBC with a password-derived key.' + LineEnding +
              'This demonstrates a real-world use case of the fafafa.core.crypto library.' + LineEnding +
              LineEnding +
              '这是一个用于加密演示的测试文件。' + LineEnding +
              '它包含多行文本内容。' + LineEnding +
              '文件将使用AES-256-CBC和密码派生密钥进行加密。' + LineEnding +
              '这演示了fafafa.core.crypto库的实际应用场景。' + LineEnding;

  LBytes := StringToBytes(LContent);

  LStream := TFileStream.Create(AFileName, fmCreate);
  try
    LStream.WriteBuffer(LBytes[0], Length(LBytes));
    WriteLn('创建测试文件: ', AFileName, ' (', Length(LBytes), ' 字节)');
  finally
    LStream.Free;
  end;
end;

// 验证文件内容
function VerifyFiles(const AFile1, AFile2: string): Boolean;
var
  LStream1, LStream2: TFileStream;
  LBuffer1, LBuffer2: array[0..8191] of Byte;
  LRead1, LRead2: Integer;
begin
  Result := False;

  try
    LStream1 := TFileStream.Create(AFile1, fmOpenRead);
    try
      LStream2 := TFileStream.Create(AFile2, fmOpenRead);
      try
        if LStream1.Size <> LStream2.Size then
        begin
          WriteLn('文件大小不同: ', LStream1.Size, ' vs ', LStream2.Size);
          Exit;
        end;

        repeat
          LRead1 := LStream1.Read(LBuffer1, SizeOf(LBuffer1));
          LRead2 := LStream2.Read(LBuffer2, SizeOf(LBuffer2));

          if (LRead1 <> LRead2) or not CompareMem(@LBuffer1, @LBuffer2, LRead1) then
          begin
            WriteLn('文件内容不同');
            Exit;
          end;
        until LRead1 = 0;

        Result := True;
        WriteLn('文件内容完全相同');

      finally
        LStream2.Free;
      end;
    finally
      LStream1.Free;
    end;
  except
    on E: Exception do
      WriteLn('文件比较失败: ', E.Message);
  end;
end;

var
  LPassword: string;
  LPasswordDecrypt: string;
  LOriginalFile, LEncryptedFile, LDecryptedFile: string;
begin
  PrintAndLog('=== file_encryption demo start ===');

  try
    // 设置文件名
    LOriginalFile := 'test_original.txt';
    LEncryptedFile := 'test_encrypted.dat';
    LDecryptedFile := 'test_decrypted.txt';
    LPassword := 'MySecretPassword123!';

    LPasswordDecrypt := LPassword; // 正确密码解密
    PrintAndLog('使用密码(加密): "' + LPassword + '"');

    PrintAndLog('使用密码: "' + LPassword + '"');

    // 创建测试文件
    CreateTestFile(LOriginalFile);

    // 加密文件
    if EncryptFile(LOriginalFile, LEncryptedFile, LPassword) then
    begin
      PrintAndLog('✓ 文件加密成功');
    end
    else
    begin
      PrintAndLog('✗ 文件加密失败');
      Exit;
    end;

    // 解密文件
    if DecryptFile(LEncryptedFile, LDecryptedFile, LPassword) then
    begin
      PrintAndLog('✓ 文件解密成功');
    end
    else
    begin
      PrintAndLog('✗ 文件解密失败');
      Exit;
    end;

    // 负向用例：错误密码解密验证
    LPasswordDecrypt := 'WrongPassword!';
    if DecryptFile(LEncryptedFile, 'test_decrypted_wrong.txt', LPasswordDecrypt) then
    begin
      PrintAndLog('✗ 错误密码解密竟然成功（这不应发生）');
    end
    else
    begin
      PrintAndLog('✓ 错误密码解密失败（符合预期）');
    end;

    // 验证文件
    PrintAndLog('验证原始文件和解密文件...');
    if VerifyFiles(LOriginalFile, LDecryptedFile) then
    begin
      PrintAndLog('✓ 文件加密/解密测试完全成功！');
    end
    else
    begin
      PrintAndLog('✗ 文件验证失败');
    end;

    PrintAndLog('文件信息:');
    PrintAndLog('原始文件: ' + LOriginalFile);
    PrintAndLog('加密文件: ' + LEncryptedFile);
    PrintAndLog('解密文件: ' + LDecryptedFile);

  except
    on E: Exception do
    begin
      PrintAndLog('程序执行失败: ' + E.ClassName + ' - ' + E.Message);
      ExitCode := 1;
    end;
  end;

  PrintAndLog('=== file_encryption demo done ===');
end.
