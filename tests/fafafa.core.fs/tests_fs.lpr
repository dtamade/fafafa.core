{$CODEPAGE UTF8}
program tests_fs;

{$mode objfpc}{$H+}

uses
  Classes, consoletestrunner,
  Test_fafafa_core_fs,
  Test_fafafa_core_fs_path,
  Test_fafafa_core_fs_errors,
  Test_fafafa_core_fs_walk,
  Test_fafafa_core_fs_unified_mode,
  Test_fafafa_core_fs_ifile,
  Test_fafafa_core_fs_ifile_noexcept,
  Test_fafafa_core_fs_longpath,
  Test_fafafa_core_fs_symlink,
  Test_fafafa_core_fs_symlink_deep_loop,
  Test_fafafa_core_fs_copytree_move,
  Test_fafafa_core_fs_copytree_symlink,
  Test_fafafa_core_fs_errno,
  Test_fafafa_core_fs_access_semantics,
  Test_fafafa_core_fs_walk_windows_fileindex,
  Test_fafafa_core_fs_mkstemp_mkdtemp_flock,
  // Newly added tests
  Test_fafafa_core_fs_copytree_stats,
  Test_fafafa_core_fs_copytree_rootbehavior,
  Test_fafafa_core_fs_copytree_errorpolicy,
  Test_fafafa_core_fs_copytree_errorpolicy_skipsubtree,
  Test_fafafa_core_fs_watch,
  Test_fafafa_core_fs_copytree_symlink_aslink,
  Test_fafafa_core_fs_copytree_movetree_fallback,
  Test_fafafa_core_fs_preserve_time_perm_loose,
  Test_fafafa_core_fs_walkdir_edges,
  Test_fafafa_core_fs_movetree_abort_safe,
  Test_fafafa_core_fs_remove_tree_atomic_write,
  Test_fafafa_core_fs_watch_e2e,
  // Issue #10: 树操作集成测试
  Test_fafafa_core_fs_tree_integration,
  // Issue #11: IFileSystemProvider 抽象
  Test_fafafa_core_fs_provider,
  // Rust 风格 API 测试
  Test_fafafa_core_fs_rustapi,
  // 缓冲读写器测试
  Test_fafafa_core_fs_bufio,
  // 边界测试
  Test_fafafa_core_fs_boundary,
  // 接口测试
  Test_fafafa_core_fs_traits;

type
  { TMyTestRunner }
  TMyTestRunner = class(TTestRunner)
  protected
    // 可以在这里自定义测试运行器行为
  end;

var
  LApplication: TMyTestRunner;

begin
  LApplication := TMyTestRunner.Create(nil);
  try
    LApplication.Initialize;
    LApplication.Title := 'fafafa.core.fs Test Suite';
    LApplication.Run;
  finally
    LApplication.Free;
  end;
end.
