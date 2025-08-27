{$ifndef TESTUTILS_COLOR_TOLERANCES_INC}
{$define TESTUTILS_COLOR_TOLERANCES_INC}

const
  // L 阈值分层
  TOL_L_VERY_LOW = 0.06;
  TOL_L_LOW      = 0.08;
  // 近灰输出阈值（跳过 Hue 断言）
  TOL_C_NEAR_GRAY = 0.02;
  // Hue 容差（单位：度）
  TOL_HUE_VERY_LOW = 8.0;
  TOL_HUE_LOW      = 4.0;
  TOL_HUE_NORMAL   = 2.0;

{$endif}

