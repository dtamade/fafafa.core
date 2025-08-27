program tests_fs_no_fpcunit;

{$mode objfpc}{$H+}
{$modeswitch nestedprocvars}

{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.test.core,
  fafafa.core.test.runner,
  fafafa.core.fs;

procedure DefineTests;
begin
  // Smoke test for fs pilot
  Test('fs.smoke',
    procedure(const ctx: ITestContext)
    begin
      ctx.AssertTrue(True);
    end);

  Test('fs.tempdir',
    procedure(const ctx: ITestContext)
    var p: string;
    begin
      p := ctx.TempDir;
      ctx.AssertTrue(DirectoryExists(p), 'Temp dir exists');
    end);

  Test('fs.path.join',
    procedure(const ctx: ITestContext)
    var base, sub, full: string;
    begin
      base := ctx.TempDir;
      sub := 'a';
      full := IncludeTrailingPathDelimiter(base) + sub;
      ctx.AssertEquals(full, IncludeTrailingPathDelimiter(base)+sub);
    end);

  Test('fs.path.subtests',
    procedure(const ctx: ITestContext)
    begin
      ctx.Run('join.tmp', procedure(const c: ITestContext)
      var base, sub: string;
      begin
        base := c.TempDir; sub := 'b';
        c.AssertEquals(IncludeTrailingPathDelimiter(base)+sub, IncludeTrailingPathDelimiter(base)+sub);
      end);
      ctx.Run('join.table', procedure(const c: ITestContext)
      const arr: array[0..2] of string = ('x','yy','zzz');
      begin
        c.ForEachStr('seg', arr,
          procedure(const cc: ITestContext; const seg: string)
          var base: string;
          begin
            base := cc.TempDir;
            cc.AssertTrue(Length(IncludeTrailingPathDelimiter(base)+seg) > Length(base));
          end);
      end);
    end);

  // fs.walk-like smoke via mkdir/rmdir
  Test('fs.walk.smoke',
    procedure(const ctx: ITestContext)
    var dir, sub: string;
    begin
      dir := IncludeTrailingPathDelimiter(ctx.TempDir);
      sub := dir + 'sub';
      if fs_mkdir(sub, 0) = 0 then
        ctx.AssertTrue(DirectoryExists(sub))
      else
        ctx.Fail('mkdir failed');
      ctx.AssertTrue(fs_rmdir(sub) = 0, 'rmdir failed');
    end);

  // fs.ifile-like smoke using open/write/read/unlink
  Test('fs.ifile.smoke',
    procedure(const ctx: ITestContext)
    var dir, f: string; h: TfsFile; buf: array[0..2] of Char; w, r: Integer;
    begin
      dir := IncludeTrailingPathDelimiter(ctx.TempDir);
      f := dir + 't.txt';
      h := fs_open(f, O_CREAT or O_TRUNC or O_RDWR, 0);
      ctx.AssertTrue(IsValidHandle(h), 'open failed');
      buf[0]:='a'; buf[1]:='b'; buf[2]:='c';
      w := fs_write(h, @buf[0], 3, 0);
      ctx.AssertTrue(w = 3, 'write failed');
      r := fs_read(h, @buf[0], 3, 0);
      ctx.AssertTrue(r = 3, 'read failed');
      fs_close(h);
      ctx.AssertTrue(fs_unlink(f) = 0, 'unlink failed');
    end);

end;

begin
  DefineTests;
  TestMain;
end.



