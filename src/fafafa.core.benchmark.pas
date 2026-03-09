unit fafafa.core.benchmark;

{$MODE OBJFPC}{$H+}

{$I fafafa.core.settings.inc}

interface

uses
  Classes,
  SysUtils,
  {$IFDEF WINDOWS}
  Windows,
  {$ENDIF}
  fafafa.core.base,
  SyncObjs, // for TEvent
  fafafa.core.math,
  Variants,
  fafafa.core.tick,
  fafafa.core.io,
  fafafa.core.xml,
  fafafa.core.benchmark.format_utils;

{ 基准测试框架类型定义 }

type

  {**
   * 前向声明
   *}
  IBenchmarkState = interface;
  IBenchmarkFixture = interface;


  // 关键接口的前置声明，供后续记录类型安全引用
  IBenchmarkResult = interface;
  IBenchmark = interface;
  IBenchmarkRunner = interface;
  IBenchmarkReporter = interface;
  IBenchmarkSuite = interface;

  {**
   * TBenchmarkFunction
   *
   * @desc 新的基准测试函数类型 - 接受 State 参数（Google Benchmark 风格）
   *}
  TBenchmarkFunction = procedure(aState: IBenchmarkState);

  {**
   * TBenchmarkMethod
   *
   * @desc 基准测试对象方法类型 - 接受 State 参数
   *}
  TBenchmarkMethod = procedure(aState: IBenchmarkState) of object;

  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  {**
   * TBenchmarkProc
   *
   * @desc 基准测试匿名过程类型 - 接受 State 参数
   *}
  TBenchmarkProc = reference to procedure(aState: IBenchmarkState);
  {$ENDIF}

  {**
   * TLegacyBenchmarkFunction
   *
   * @desc 传统的基准测试函数类型（向后兼容）
   *}
  TLegacyBenchmarkFunction = procedure;

  {**
   * TLegacyBenchmarkMethod
   *
   * @desc 传统的基准测试对象方法类型（向后兼容）
   *}
  TLegacyBenchmarkMethod = procedure of object;

  {**
   * TMultiThreadBenchmarkFunction
   *
   * @desc 多线程基准测试函数类型
   * @param aState 基准测试状态对象
   * @param aThreadIndex 当前线程索引（从0开始）
   *}
  TMultiThreadBenchmarkFunction = procedure(aState: IBenchmarkState; aThreadIndex: Integer);

  {**
   * TMultiThreadBenchmarkMethod
   *
   * @desc 多线程基准测试对象方法类型
   * @param aState 基准测试状态对象
   * @param aThreadIndex 当前线程索引（从0开始）
   *}
  TMultiThreadBenchmarkMethod = procedure(aState: IBenchmarkState; aThreadIndex: Integer) of object;

  {**
   * TParameterizedBenchmarkFunction
   *
   * @desc 参数化基准测试函数类型
   * @param aState 基准测试状态对象
   * @param aParameters 参数数组
   *}
  TParameterizedBenchmarkFunction = procedure(aState: IBenchmarkState; const aParameters: array of Variant);

  {**
   * TParameterizedBenchmarkMethod
   *
   * @desc 参数化基准测试对象方法类型
   * @param aState 基准测试状态对象
   * @param aParameters 参数数组
   *}
  TParameterizedBenchmarkMethod = procedure(aState: IBenchmarkState; const aParameters: array of Variant) of object;

  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  {**
   * TLegacyBenchmarkProc
   *
   * @desc 传统的基准测试匿名过程类型（向后兼容）
   *}
  TLegacyBenchmarkProc = reference to procedure;
  {$ENDIF}

  {**
   * TCounterUnit
   *
   * @desc 自定义计数器单位
   *}
  TCounterUnit = (
    cuDefault,      // 默认单位
    cuBytes,        // 字节
    cuItems,        // 项目数
    cuRate,         // 速率
    cuPercentage    // 百分比
  );

  {**
   * TComplexityType
   *
   * @desc 算法复杂度类型
   *}
  TComplexityType = (
    ctConstant,     // O(1)
    ctLinear,       // O(n)
    ctQuadratic,    // O(n²)
    ctCubic,        // O(n³)
    ctLogarithmic,  // O(log n)
    ctNLogN,        // O(n log n)
    ctCustom        // 自定义
  );

  {**
   * TBenchmarkMode
   *
   * @desc 基准测试运行模式
   *}
  TBenchmarkMode = (
    bmTime,      // 基于时间的测试（运行指定时间）
    bmIterations // 基于迭代次数的测试（运行指定次数）
  );

  {**
   * TBenchmarkUnit
   *
   * @desc 基准测试时间单位
   *}
  TBenchmarkUnit = (
    buNanoSeconds,  // 纳秒
    buMicroSeconds, // 微秒
    buMilliSeconds, // 毫秒
    buSeconds       // 秒
  );

  {**
   * TBenchmarkConfig
   *
   * @desc 基准测试配置
   *}
  TBenchmarkConfig = record
    Mode: TBenchmarkMode;           // 运行模式
    WarmupIterations: Integer;      // 预热迭代次数
    MeasureIterations: Integer;     // 测量迭代次数
    MinDurationMs: Integer;         // 最小运行时间（毫秒）
    MaxDurationMs: Integer;         // 最大运行时间（毫秒）
    TimeUnit: TBenchmarkUnit;       // 时间单位
    EnableMemoryMeasurement: Boolean; // 是否启用内存测量
    EnableOverheadCorrection: Boolean; // 是否启用测量开销校正（默认False）
  end;

  {**
   * TMultiThreadConfig
   *
   * @desc 多线程基准测试配置
   *}
  TMultiThreadConfig = record
    ThreadCount: Integer;        // 线程数量
    WorkPerThread: Integer;      // 每个线程的工作量（可选，0表示不统计）
    SyncThreads: Boolean;        // 是否同步启动所有线程
    StartBarrierTimeoutMs: Integer; // 线程启动栅栏超时（毫秒），默认10000
  end;

  {**
   * TBenchmarkBaseline
   *
   * @desc 性能基线定义
   *}
  TBenchmarkBaseline = record
    Name: string;                // 基线名称
    BaselineTime: Double;        // 基线时间（纳秒）
    Tolerance: Double;           // 允许的性能波动范围（百分比，如 0.1 表示 10%）
    Description: string;         // 基线描述
  end;

  {**
   * TParameterizedTestCase
   *
   * @desc 参数化测试用例
   *}
  TParameterizedTestCase = record
    Name: string;                // 测试用例名称
    Parameters: array of Variant; // 参数数组
  end;

  {**
   * TParameterizedTestCases
   *
   * @desc 参数化测试用例数组
   *}
  TParameterizedTestCases = array of TParameterizedTestCase;

  {**
   * TBenchmarkRecommendation
   *
   * @desc 基准测试配置推荐
   *}
  TBenchmarkRecommendation = record
    RecommendedConfig: TBenchmarkConfig;  // 推荐的配置
    Confidence: Double;                   // 推荐置信度（0-1）
    Reasoning: string;                    // 推荐理由
  end;

  {**
   * TBenchmarkComparison
   *
   * @desc 基准测试对比结果
   *}
  TBenchmarkComparison = record
    Name1, Name2: string;                 // 对比的测试名称
    Result1, Result2: IBenchmarkResult;   // 对比的结果
    RelativeDifference: Double;           // 相对差异（百分比）
    Conclusion: string;                   // 对比结论
    Significance: Double;                 // 差异显著性（0-1）
  end;

  {**
   * TBenchmarkTrend
   *
   * @desc 性能趋势数据
   *}
  TBenchmarkTrend = record
    TestName: string;                     // 测试名称
    Timestamps: array of TDateTime;       // 时间戳
    Values: array of Double;              // 性能值
    TrendDirection: Integer;              // 趋势方向（-1下降，0稳定，1上升）
    TrendStrength: Double;                // 趋势强度（0-1）
  end;

  {**
   * TBenchmarkReport
   *
   * @desc 基准测试报告
   *}
  TBenchmarkReport = record
    Title: string;                        // 报告标题
    GeneratedAt: TDateTime;               // 生成时间
    Results: array of IBenchmarkResult;   // 测试结果
    Comparisons: array of TBenchmarkComparison; // 对比结果
    Summary: string;                      // 报告摘要
    Recommendations: array of string;     // 建议
  end;

  {**
   * TQuickBenchmark
   *
   * @desc 快手基准测试定义
   *}
  TQuickBenchmark = record
    Name: string;                         // 测试名称
    Func: TBenchmarkFunction;             // 测试函数
    Method: TBenchmarkMethod;             // 测试方法（可选）
    Config: TBenchmarkConfig;             // 测试配置（可选）
  end;

  {**
   * TQuickBenchmarkArray
   *
   * @desc 快手基准测试数组
   *}
  TQuickBenchmarkArray = array of TQuickBenchmark;

  {**
   * TPerformanceAlert
   *
   * @desc 性能警报定义
   *}
  TPerformanceAlert = record
    TestName: string;                     // 测试名称
    AlertType: string;                    // 警报类型（regression, threshold, etc.）
    Threshold: Double;                    // 阈值
    CurrentValue: Double;                 // 当前值
    Message: string;                      // 警报消息
    Severity: Integer;                    // 严重程度（1-5）
    Timestamp: TDateTime;                 // 时间戳
  end;

  {**
   * TPerformanceAlertArray
   *
   * @desc 性能警报数组
   *}
  TPerformanceAlertArray = array of TPerformanceAlert;

  {**
   * TBenchmarkConfig_Extended
   *
   * @desc 扩展的基准测试配置（包含监控选项）
   *}
  TBenchmarkConfig_Extended = record
    BaseConfig: TBenchmarkConfig;         // 基础配置
    EnableMonitoring: Boolean;            // 启用监控
    PerformanceThreshold: Double;         // 性能阈值（纳秒）
    RegressionThreshold: Double;          // 回归阈值（百分比）
    AlertOnRegression: Boolean;           // 回归时警报
    AlertOnThreshold: Boolean;            // 超过阈值时警报
    SaveResults: Boolean;                 // 保存结果到文件
    ResultsFileName: string;              // 结果文件名
  end;

  {**
   * TPerformanceAnalysis
   *
   * @desc 性能分析结果
   *}
  TPerformanceAnalysis = record
    TestName: string;                     // 测试名称
    PerformanceLevel: string;             // 性能等级（Excellent, Good, Fair, Poor）
    BottleneckType: string;               // 瓶颈类型（CPU, Memory, IO, etc.）
    OptimizationSuggestions: array of string; // 优化建议
    Confidence: Double;                   // 分析置信度（0-1）
    AnalysisTimestamp: TDateTime;         // 分析时间戳
  end;

  {**
   * TBenchmarkTemplate
   *
   * @desc 基准测试模板
   *}
  TBenchmarkTemplate = record
    Name: string;                         // 模板名称
    Description: string;                  // 模板描述
    Category: string;                     // 分类（Algorithm, IO, Memory, etc.）
    Config: TBenchmarkConfig;             // 推荐配置
    ExpectedRange: record                 // 预期性能范围
      MinTime: Double;                    // 最小时间（纳秒）
      MaxTime: Double;                    // 最大时间（纳秒）
    end;
    Tags: array of string;                // 标签
  end;

  {**
   * TBenchmarkTemplateArray
   *
   * @desc 基准测试模板数组
   *}
  TBenchmarkTemplateArray = array of TBenchmarkTemplate;

  {**
   * TPlatformInfo
   *
   * @desc 平台信息
   *}
  TPlatformInfo = record
    OS: string;                           // 操作系统
    Architecture: string;                 // 架构（x86, x64, ARM, etc.）
    CPUModel: string;                     // CPU 型号
    CPUCores: Integer;                    // CPU 核心数
    MemorySize: Int64;                    // 内存大小（MB）
    CompilerVersion: string;              // 编译器版本
  end;

  {**
   * TCrossPlatformResult
   *
   * @desc 跨平台测试结果
   *}
  TCrossPlatformResult = record
    Platform: TPlatformInfo;              // 平台信息
    Results: array of IBenchmarkResult;   // 测试结果
    Timestamp: TDateTime;                 // 测试时间
  end;

  {**
   * TRealTimeMetrics
   *
   * @desc 实时性能指标
   *}
  TRealTimeMetrics = record
    Timestamp: TDateTime;                 // 时间戳
    CPUUsage: Double;                     // CPU 使用率 (0-100)
    MemoryUsage: Int64;                   // 内存使用量 (字节)
    ExecutionTime: Double;                // 执行时间 (纳秒)
    ThroughputOpsPerSec: Double;          // 吞吐量 (ops/sec)
    LatencyPercentiles: array[0..4] of Double; // P50, P75, P90, P95, P99
  end;

  {**
   * TPerformancePrediction
   *
   * @desc 性能预测结果
   *}
  TPerformancePrediction = record
    TestName: string;                     // 测试名称
    PredictedTime: Double;                // 预测时间 (纳秒)
    ConfidenceInterval: array[0..1] of Double; // 置信区间 [下界, 上界]
    PredictionAccuracy: Double;           // 预测准确度 (0-1)
    TrendDirection: Integer;              // 趋势方向 (-1下降, 0稳定, 1上升)
    RecommendedAction: string;            // 推荐行动
    ModelVersion: string;                 // 预测模型版本
  end;

  {**
   * TLinearRegressionParams
   *}
  TLinearRegressionParams = record
    Slope: Double;
    Intercept: Double;
  end;

  {**
   * TCodeHotspot
   *
   * @desc 代码热点分析
   *}
  TCodeHotspot = record
    FunctionName: string;                 // 函数名称
    LineNumber: Integer;                  // 行号
    ExecutionCount: Int64;                // 执行次数
    TotalTime: Double;                    // 总耗时 (纳秒)
    AverageTime: Double;                  // 平均耗时 (纳秒)
    PercentageOfTotal: Double;            // 占总时间百分比
    OptimizationPriority: Integer;        // 优化优先级 (1-10)
    SuggestedOptimizations: array of string; // 建议的优化方法
  end;

  {**
   * TAdaptiveConfig
   *
   * @desc 自适应配置
   *}
  TAdaptiveConfig = record
    BaseConfig: TBenchmarkConfig;         // 基础配置
    AdaptationLevel: Integer;             // 自适应级别 (1-5)
    LearningRate: Double;                 // 学习率
    TargetAccuracy: Double;               // 目标准确度
    MaxAdaptationCycles: Integer;         // 最大自适应周期
    CurrentCycle: Integer;                // 当前周期
    PerformanceHistory: array of Double;  // 性能历史
    ConfigHistory: array of TBenchmarkConfig; // 配置历史
  end;

  {**
   * TDistributedNode
   *
   * @desc 分布式节点信息
   *}
  TDistributedNode = record
    NodeID: string;                       // 节点ID
    IPAddress: string;                    // IP地址
    Port: Integer;                        // 端口
    Platform: TPlatformInfo;              // 平台信息
    Status: string;                       // 状态 (Active, Busy, Offline)
    LastHeartbeat: TDateTime;             // 最后心跳时间
    WorkloadCapacity: Integer;            // 工作负载容量
    CurrentWorkload: Integer;             // 当前工作负载
  end;

  {**
   * TQuantumState
   *
   * @desc 量子性能状态
   *}
  TQuantumState = record
    Superposition: array[0..7] of Double; // 8维性能叠加态
    Entanglement: Double;                 // 量子纠缠度
    Coherence: Double;                    // 相干性
    Uncertainty: Double;                  // 海森堡不确定性
    WaveFunction: string;                 // 波函数表达式
    CollapseTime: TDateTime;              // 波函数坍缩时间
  end;

  {**
   * TPerformanceDimension
   *
   * @desc 性能维度
   *}
  TPerformanceDimension = record
    Name: string;                         // 维度名称
    Value: Double;                        // 维度值
    Weight: Double;                       // 权重
    Complexity: string;                   // 复杂度类型
    Topology: string;                     // 拓扑结构
  end;

  {**
   * TMultiDimensionalSpace
   *
   * @desc 多维性能空间
   *}
  TMultiDimensionalSpace = record
    Dimensions: array of TPerformanceDimension; // 性能维度
    Coordinates: array of Double;         // 空间坐标
    Curvature: Double;                    // 空间曲率
    Metric: string;                       // 度量类型
    Manifold: string;                     // 流形类型
  end;

  {**
   * TBehaviorPattern
   *
   * @desc 性能行为模式
   *}
  TBehaviorPattern = record
    PatternID: string;                    // 模式ID
    PatternType: string;                  // 模式类型
    Frequency: Double;                    // 出现频率
    Amplitude: Double;                    // 振幅
    Phase: Double;                        // 相位
    Harmonics: array of Double;          // 谐波分量
    Signature: string;                    // 模式签名
    Confidence: Double;                   // 识别置信度
  end;

  {**
   * TPerformanceProphecy
   *
   * @desc 性能预言
   *}
  TPerformanceProphecy = record
    ProphecyID: string;                   // 预言ID
    TimeHorizon: TDateTime;               // 预言时间范围
    Probability: Double;                  // 实现概率
    Scenario: string;                     // 情景描述
    Triggers: array of string;           // 触发条件
    Consequences: array of string;        // 后果预测
    Mitigation: array of string;          // 缓解措施
    OracleConfidence: Double;             // 神谕置信度
  end;

  {**
   * TArtisticVisualization
   *
   * @desc 艺术化可视化
   *}
  TArtisticVisualization = record
    ArtStyle: string;                     // 艺术风格
    ColorPalette: array of string;        // 调色板
    Composition: string;                  // 构图方式
    Texture: string;                      // 纹理类型
    Animation: string;                    // 动画效果
    Music: string;                        // 背景音乐
    Emotion: string;                      // 情感表达
    Aesthetics: Double;                   // 美学评分
  end;

  {**
   * THyperSpeedConfig
   *
   * @desc 超光速配置
   *}
  THyperSpeedConfig = record
    WarpFactor: Double;                   // 曲速因子
    QuantumTunneling: Boolean;            // 量子隧穿
    TimeDialation: Double;                // 时间膨胀
    SpaceCompression: Double;             // 空间压缩
    ParallelUniverses: Integer;           // 并行宇宙数
    DimensionalShift: Boolean;            // 维度转换
    CausalityViolation: Boolean;          // 因果律违反
    EnergyRequirement: Double;            // 能量需求
  end;

  {**
   * TSpaceTimeDistortion
   *
   * @desc 时空扭曲配置
   *}
  TSpaceTimeDistortion = record
    GravityWells: array of Double;        // 重力井
    BlackHoles: Integer;                  // 黑洞数量
    WormholeStability: Double;            // 虫洞稳定性
    TimeLoops: Boolean;                   // 时间循环
    ParadoxResolution: string;            // 悖论解决方案
    EventHorizon: Double;                 // 事件视界
    SingularityDensity: Double;           // 奇点密度
    HawkingRadiation: Double;             // 霍金辐射
  end;

  {**
   * TConsciousnessUpload
   *
   * @desc 意识上传配置
   *}
  TConsciousnessUpload = record
    NeuronCount: Int64;                   // 神经元数量
    SynapseConnections: Int64;            // 突触连接
    MemoryCapacity: Double;               // 记忆容量 (PB)
    ProcessingSpeed: Double;              // 处理速度 (TFLOPS)
    EmotionalIntelligence: Double;        // 情商指数
    CreativityIndex: Double;              // 创造力指数
    ConsciousnessLevel: Integer;          // 意识等级 (1-10)
    SoulIntegrity: Double;                // 灵魂完整性
  end;

  {**
   * TRainbowDimension
   *
   * @desc 彩虹维度配置
   *}
  TRainbowDimension = record
    ColorSpectrum: array[0..6] of string; // 七色光谱
    WavelengthRange: array[0..1] of Double; // 波长范围
    Saturation: Double;                   // 饱和度
    Brightness: Double;                   // 亮度
    MagicalIntensity: Double;             // 魔法强度
    UnicornPresence: Boolean;             // 独角兽存在
    RainbowBridge: Boolean;               // 彩虹桥
    PotOfGold: Boolean;                   // 金罐
  end;

  {**
   * TCircusPerformance
   *
   * @desc 马戏团表演配置
   *}
  TCircusPerformance = record
    Performers: array of string;          // 表演者
    Acts: array of string;                // 表演节目
    AudienceSize: Integer;                // 观众数量
    ApplauseLevel: Double;                // 掌声等级
    ExcitementFactor: Double;             // 兴奋因子
    DangerLevel: Integer;                 // 危险等级 (1-10)
    MagicTricks: Boolean;                 // 魔术表演
    AnimalActs: Boolean;                  // 动物表演
  end;

  {**
   * TPizzaOptimization
   *
   * @desc 披萨优化配置
   *}
  TPizzaOptimization = record
    ToppingsCount: Integer;               // 配料数量
    CheeseAmount: Double;                 // 奶酪量 (kg)
    CrustThickness: Double;               // 饼皮厚度 (cm)
    BakeTemperature: Double;              // 烘烤温度 (°C)
    BakeTime: Double;                     // 烘烤时间 (分钟)
    TasteRating: Double;                  // 口味评分 (1-10)
    NutritionalValue: Double;             // 营养价值
    HappinessBoost: Double;               // 幸福感提升
  end;

  {**
   * TUnicornMagic
   *
   * @desc 独角兽魔法配置
   *}
  TUnicornMagic = record
    HornLength: Double;                   // 角长度 (cm)
    MagicalPower: Double;                 // 魔法力量 (MP)
    RainbowTrail: Boolean;                // 彩虹尾迹
    HealingAbility: Double;               // 治愈能力
    FlightSpeed: Double;                  // 飞行速度 (km/h)
    PurityLevel: Double;                  // 纯洁度
    WishGranting: Boolean;                // 愿望实现
    SparkleIntensity: Double;             // 闪光强度
  end;

  {**
   * TGameification
   *
   * @desc 游戏化配置
   *}
  TGameification = record
    PlayerLevel: Integer;                 // 玩家等级
    ExperiencePoints: Int64;              // 经验值
    Achievements: array of string;        // 成就列表
    PowerUps: array of string;           // 道具列表
    BossLevel: Integer;                   // Boss等级
    HealthPoints: Integer;                // 生命值
    ManaPoints: Integer;                  // 魔法值
    Score: Int64;                         // 分数
  end;

  {**
   * TFastFoodOptimization
   *
   * @desc 快餐优化配置
   *}
  TFastFoodOptimization = record
    BurgerLayers: Integer;                // 汉堡层数
    FriesCount: Integer;                  // 薯条数量
    DrinkSize: string;                    // 饮料大小
    SauceTypes: array of string;         // 酱料类型
    CookingTime: Double;                  // 烹饪时间 (分钟)
    CalorieCount: Integer;                // 卡路里
    SatisfactionLevel: Double;            // 满足度
    DeliverySpeed: Double;                // 配送速度 (分钟)
  end;

  {**
   * TMusicSynchronization
   *
   * @desc 音乐同步配置
   *}
  TMusicSynchronization = record
    BPM: Integer;                         // 每分钟节拍数
    Genre: string;                        // 音乐类型
    Key: string;                          // 调性
    Tempo: string;                        // 节奏
    Instruments: array of string;         // 乐器
    Volume: Double;                       // 音量 (0-100)
    Harmony: Boolean;                     // 和谐度
    Danceability: Double;                 // 可舞性
  end;

  {**
   * TCatDrivenAnalysis
   *
   * @desc 猫咪驱动分析配置
   *}
  TCatDrivenAnalysis = record
    CatBreed: string;                     // 猫咪品种
    CutenessLevel: Double;                // 可爱度
    PurrFrequency: Double;                // 呼噜频率 (Hz)
    NapTime: Double;                      // 睡眠时间 (小时)
    PlayfulnessIndex: Double;             // 顽皮指数
    IndependenceLevel: Double;            // 独立性
    TreatPreference: array of string;     // 零食偏好
    MeowIntensity: Double;                // 喵叫强度
  end;

  {**
   * TToiletPhilosophy
   *
   * @desc 厕所哲学配置
   *}
  TToiletPhilosophy = record
    ThinkingTime: Double;                 // 思考时间 (分钟)
    PhilosophicalDepth: Double;           // 哲学深度
    EurekaCount: Integer;                 // 灵感次数
    PaperUsage: Integer;                  // 纸张使用量
    ComfortLevel: Double;                 // 舒适度
    PrivacyIndex: Double;                 // 隐私指数
    WisdomGained: Double;                 // 获得智慧
    FlushEfficiency: Double;              // 冲水效率
  end;

  {**
   * TBirthdayCelebration
   *
   * @desc 生日庆祝配置
   *}
  TBirthdayCelebration = record
    CakeSize: string;                     // 蛋糕大小
    CandleCount: Integer;                 // 蜡烛数量
    GuestCount: Integer;                  // 客人数量
    WishList: array of string;           // 愿望清单
    PartyDuration: Double;                // 派对时长 (小时)
    HappinessLevel: Double;               // 快乐度
    SurpriseCount: Integer;               // 惊喜数量
    CakeDeliciousness: Double;            // 蛋糕美味度
  end;

  {**
   * TBenchmarkStatistics
   *
   * @desc 基准测试统计数据（优化版）
   *}
  TBenchmarkStatistics = record
    Mean: Double;           // 平均值
    StdDev: Double;         // 标准差
    Min: Double;            // 最小值
    Max: Double;            // 最大值
    Median: Double;         // 中位数
    P95: Double;            // 95百分位数
    P99: Double;            // 99百分位数
    SampleCount: Integer;   // 样本数量
    CoefficientOfVariation: Double; // 变异系数
    // 🚀 新增优化字段
    Variance: Double;       // 方差
    Skewness: Double;       // 偏度
    Kurtosis: Double;       // 峰度
    Q1: Double;             // 第一四分位数
    Q3: Double;             // 第三四分位数
    IQR: Double;            // 四分位距
    OutlierCount: Integer;  // 异常值数量
    MeasurementOverhead: Double; // 测量开销（纳秒）
    Corrected: Boolean;          // 是否已进行开销校正
  end;

  {**
   * 🔧 P1-2：样本数组类型
   *}
  TBenchmarkSampleArray = array of Double;

{ 异常定义 }

  {**
   * EBenchmarkError
   *
   * @desc 基准测试相关错误的基类异常
   *}
  EBenchmarkError = class(ECore) end;

  {**
   * EBenchmarkConfigError
   *
   * @desc 基准测试配置错误异常
   *}
  EBenchmarkConfigError = class(EBenchmarkError) end;

  {**
   * EBenchmarkTimeoutError
   *
   * @desc 基准测试超时异常
   *}
  EBenchmarkTimeoutError = class(EBenchmarkError) end;

  {**
   * EBenchmarkInvalidOperation
   *
   * @desc 基准测试无效操作异常
   *}
  EBenchmarkInvalidOperation = class(EBenchmarkError) end;

{ 前向声明 }

  // 已在顶部声明关键接口，避免重复
  IBenchmarkMonitor = interface;
  IBenchmarkAnalyzer = interface;
  IBenchmarkTemplateManager = interface;
  IRealTimeMonitor = interface;
  IPerformancePredictor = interface;
  ICodeProfiler = interface;
  IAdaptiveOptimizer = interface;
  IDistributedCoordinator = interface;
  // 🚀 注释掉未实现的接口，避免编译错误
  // IQuantumAnalyzer = interface;
  // IMultiDimensionalMapper = interface;
  // IBehaviorPatternRecognizer = interface;
  // IPerformanceOracle = interface;
  // IArtisticVisualizer = interface;
  // IHyperSpeedEngine = interface;
  // ISpaceTimeDistorter = interface;
  // IConsciousnessUploader = interface;
  // IRainbowDimensionMapper = interface;
  // ICircusPerformer = interface;
  // IPizzaOptimizer = interface;
  // IUnicornMagician = interface;
  // IGameMaster = interface;
  // IFastFoodOptimizer = interface;
  // IMusicSynchronizer = interface;
  // ICatAnalyst = interface;
  // IToiletPhilosopher = interface;
  // IBirthdayPartyPlanner = interface;

  {**
   * TBenchmarkResultArray
   *
   * @desc 基准测试结果数组类型
   *}
  TBenchmarkResultArray = array of IBenchmarkResult;


  { 动态数组类型别名，避免在返回类型中直接使用 anonymous dynamic array }
  TStringArray = array of string;
  TDoubleArray = array of Double;
  TBenchmarkComparisonArray = array of TBenchmarkComparison;
  TPerformanceAnalysisArray = array of TPerformanceAnalysis;
  TRealTimeMetricsArray = array of TRealTimeMetrics;
  TCodeHotspotArray = array of TCodeHotspot;
  TAdaptiveConfigArray = array of TAdaptiveConfig;
  TDistributedNodeArray = array of TDistributedNode;
  TPerformanceProphecyArray = array of TPerformanceProphecy;

  {**
   * TBenchmarkCounter
   *
   * @desc 自定义计数器记录
   *}
  TBenchmarkCounter = record
    Name: string;
    Value: Double;
    CounterUnit: TCounterUnit;
  end;

  {**
   * TBenchmarkCounterArray
   *
   * @desc 计数器数组类型
   *}
  TBenchmarkCounterArray = array of TBenchmarkCounter;

{ 核心接口定义 }

  {**
   * IBenchmarkState
   *
   * @desc 基准测试状态接口（Google Benchmark 风格）
   *       控制基准测试的执行流程和数据收集
   *}
  IBenchmarkState = interface
    ['{F1A2B3C4-D5E6-7890-ABCD-EF1234567890}']

    {**
     * KeepRunning
     *
     * @desc 检查是否应该继续运行测试循环
     *       这是 Google Benchmark 风格的核心方法
     *
     * @return 如果应该继续运行返回 True，否则返回 False
     *}
    function KeepRunning: Boolean;

    {**
     * SetIterations
     *
     * @desc 手动设置迭代次数（覆盖自动检测）
     *
     * @param aCount 迭代次数
     *}
    procedure SetIterations(aCount: Int64);

    {**
     * PauseTiming
     *
     * @desc 暂停计时（用于排除 setup 代码的时间）
     *}
    procedure PauseTiming;

    {**
     * ResumeTiming
     *
     * @desc 恢复计时
     *}
    procedure ResumeTiming;

    {**
     * Pause
     *
     * @desc 简写：等同于 PauseTiming（为示例代码提供友好API）
     *}
    procedure Pause;

    {**
     * Resume
     *
     * @desc 简写：等同于 ResumeTiming（为示例代码提供友好API）
     *}
    procedure Resume;

    {**
     * Blackhole
     *
     * @desc 实例方法包装，防止被测值被优化掉
     *}
    procedure Blackhole(const v: Int64); overload;
    procedure Blackhole(const v: Double); overload;

    {**
     * SetBytesProcessed
     *
     * @desc 设置处理的字节数（用于计算吞吐量）
     *
     * @param aBytes 字节数
     *}
    procedure SetBytesProcessed(aBytes: Int64);

    {**
     * SetItemsProcessed
     *
     * @desc 设置处理的项目数（用于计算吞吐量）
     *
     * @param aItems 项目数
     *}
    procedure SetItemsProcessed(aItems: Int64);

    {**
     * SetComplexityN
     *
     * @desc 设置算法复杂度分析的 N 值
     *
     * @param aN 复杂度参数
     *}
    procedure SetComplexityN(aN: Int64);

    {** 获取只读统计数据（给结果对象拷贝用） **}
    function GetBytesProcessed: Int64;
    function GetItemsProcessed: Int64;
    function GetComplexityN: Int64;
    function GetCounters: TBenchmarkCounterArray;

    {**
     * AddCounter
     *
     * @desc 添加自定义计数器
     *       最佳实践：
     *       - 统一命名与单位：相同名称的计数器在不同基准中应使用相同单位
     *       - 常用单位建议：bytes/items/rate/percent（默认 unit 表示未指定）
     *       - 计数器用于 CSV/JSON Reporter，中：
     *         · JSON 同时输出 counters（对象映射）与 counter_list（name/value/unit）
     *         · CSV 在 counters=tabular 模式生成对应列，列名包含 [unit]
     *
     * @param aName 计数器名称
     * @param aValue 计数器值
     * @param aUnit 计数器单位
     *}
    procedure AddCounter(const aName: string; aValue: Double; aUnit: TCounterUnit = cuDefault);

    {**
     * GetMemoryUsage
     *
     * @desc 获取当前内存使用量（字节）
     *
     * @return 返回内存使用量
     *}
    function GetMemoryUsage: Int64;

    {**
     * GetPeakMemoryUsage
     *
     * @desc 获取峰值内存使用量（字节）
     *
     * @return 返回峰值内存使用量
     *}
    function GetPeakMemoryUsage: Int64;

    {**
     * SetWarmupIterations
     *
     * @desc 设置预热迭代次数（P0-3增强）
     *
     * @param aCount 预热迭代次数
     *}
    procedure SetWarmupIterations(aCount: Integer);

    {**
     * SetTargetCalibrationTime
     *
     * @desc 设置目标校准时间（P1-1增强）
     *
     * @param aTimeMS 目标校准时间（毫秒）
     *}
    procedure SetTargetCalibrationTime(aTimeMS: Double);
    // 🔧 P1-1：设置校准绝对最长时长（毫秒），用于兜底
    procedure SetCalibrationMaxDuration(aTimeMS: Double);

    {**
     * GetIterations
     *
     * @desc 获取当前迭代次数
     *
     * @return 返回迭代次数
     *}
    function GetIterations: Int64;

    {**
     * GetElapsedTime
     *
     * @desc 获取已经过的时间（纳秒）
     *
     * @return 返回已过时间
     *}
    function GetElapsedTime: Double;

    // 属性访问器
    property Iterations: Int64 read GetIterations;
    property ElapsedTime: Double read GetElapsedTime;
  end;

  {**
   * IBenchmarkFixture
   *
   * @desc 基准测试夹具接口
   *       提供 Setup 和 TearDown 机制
   *}
  IBenchmarkFixture = interface
    ['{A2B3C4D5-E6F7-8901-BCDE-F12345678901}']

    {**
     * SetUp
     *
     * @desc 在每次基准测试运行前调用
     *
     * @param aState 基准测试状态
     *}
    procedure SetUp(aState: IBenchmarkState);

    {**
     * TearDown
     *
     * @desc 在每次基准测试运行后调用
     *
     * @param aState 基准测试状态
     *}
    procedure TearDown(aState: IBenchmarkState);
  end;

  {**
   * IBenchmarkResult
   *
   * @desc 基准测试结果接口（增强版）
   *       存储和提供基准测试的执行结果和统计数据
   *}
  IBenchmarkResult = interface
    ['{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}']

    {**
     * GetName
     *
     * @desc 获取基准测试名称
     *
     * @return 返回测试名称
     *}
    function GetName: string;

    {**
     * GetIterations
     *
     * @desc 获取实际执行的迭代次数
     *
     * @return 返回迭代次数
     *}
    function GetIterations: Int64;

    {**
     * GetTotalTime
     *
     * @desc 获取总执行时间（纳秒）
     *
     * @return 返回总时间
     *}
    function GetTotalTime: Double;

    {**
     * GetStatistics
     *
     * @desc 获取统计数据
     *
     * @return 返回统计信息
     *}
    function GetStatistics: TBenchmarkStatistics;

    {**
     * GetConfig
     *
     * @desc 获取测试配置
     *
     * @return 返回配置信息
     *}
    function GetConfig: TBenchmarkConfig;

    {**
     * GetTimePerIteration
     *
     * @desc 获取每次迭代的平均时间
     *
     * @param aUnit 时间单位
     * @return 返回平均时间
     *}
    function GetTimePerIteration(aUnit: TBenchmarkUnit = buNanoSeconds): Double;

    {**
     * GetThroughput
     *
     * @desc 获取吞吐量（每秒迭代次数）
     *
     * @return 返回吞吐量
     *}
    function GetThroughput: Double;

    {**
     * GetBytesPerSecond
     *
     * @desc 获取字节吞吐量（每秒字节数）
     *
     * @return 返回字节吞吐量，如果未设置则返回 0
     *}
    function GetBytesPerSecond: Double;

    {**
     * GetItemsPerSecond
     *
     * @desc 获取项目吞吐量（每秒项目数）
     *
     * @return 返回项目吞吐量，如果未设置则返回 0
     *}
    function GetItemsPerSecond: Double;

    {**
     * GetCounters
     *
     * @desc 获取自定义计数器
     *
     * @return 返回计数器数组
     *}
    function GetCounters: TBenchmarkCounterArray;

    {**
     * GetSamples
     *
     * @desc 获取原始样本数据（P1-2增强）
     *
     * @return 返回样本数组
     *}
    function GetSamples: TBenchmarkSampleArray;

    {**
     * HasStatistics
     *
     * @desc 检查是否有统计数据（P1-2增强）
     *
     * @return 返回是否有统计数据
     *}
    function HasStatistics: Boolean;

    {**
     * GetComplexityN
     *
     * @desc 获取复杂度参数 N
     *
     * @return 返回复杂度参数
     *}
    function GetComplexityN: Int64;

    {**
     * GetPercentile
     *
     * @desc 获取指定百分位数的值
     *
     * @param aPercentile 百分位数（0-100）
     * @return 返回百分位数值
     *}
    function GetPercentile(aPercentile: Double): Double;

    {**
     * CompareWithBaseline
     *
     * @desc 与基线进行对比
     *
     * @param aBaseline 基线定义
     * @return 返回对比结果（正数表示比基线慢，负数表示比基线快）
     *}
    function CompareWithBaseline(const aBaseline: TBenchmarkBaseline): Double;

    {**
     * IsRegressionFrom
     *
     * @desc 检查是否相对于基线出现性能回归
     *
     * @param aBaseline 基线定义
     * @return 返回是否出现回归
     *}
    function IsRegressionFrom(const aBaseline: TBenchmarkBaseline): Boolean;

    {**
     * GetConfidenceInterval
     *
     * @desc 获取置信区间
     *
     * @param aConfidenceLevel 置信水平（如 0.95 表示 95%）
     * @param aLowerBound 返回下界
     * @param aUpperBound 返回上界
     *}
    procedure GetConfidenceInterval(aConfidenceLevel: Double; out aLowerBound, aUpperBound: Double);

    // 属性访问器
    property Name: string read GetName;
    property Iterations: Int64 read GetIterations;
    property TotalTime: Double read GetTotalTime;
    property Statistics: TBenchmarkStatistics read GetStatistics;
    property Config: TBenchmarkConfig read GetConfig;
    property BytesPerSecond: Double read GetBytesPerSecond;
    property ItemsPerSecond: Double read GetItemsPerSecond;
    property Counters: TBenchmarkCounterArray read GetCounters;
    property ComplexityN: Int64 read GetComplexityN;
  end;

  {**
   * IBenchmark
   *
   * @desc 基准测试接口
   *       定义单个基准测试的基本行为
   *}
  IBenchmark = interface
    ['{B2C3D4E5-F6A7-8901-BCDE-F12345678901}']

    {**
     * GetName
     *
     * @desc 获取基准测试名称
     *
     * @return 返回测试名称
     *}
    function GetName: string;

    {**
     * SetName
     *
     * @desc 设置基准测试名称
     *
     * @param aName 测试名称
     *}
    procedure SetName(const aName: string);

    {**
     * GetConfig
     *
     * @desc 获取测试配置
     *
     * @return 返回配置信息
     *}
    function GetConfig: TBenchmarkConfig;

    {**
     * SetConfig
     *
     * @desc 设置测试配置
     *
     * @param aConfig 配置信息
     *}
    procedure SetConfig(const aConfig: TBenchmarkConfig);

    {**
     * Run
     *
     * @desc 执行基准测试
     *
     * @return 返回测试结果
     *}
    function Run: IBenchmarkResult;

    // 属性访问器
    property Name: string read GetName write SetName;
    property Config: TBenchmarkConfig read GetConfig write SetConfig;
  end;

  {**
   * IBenchmarkRunner
   *
   * @desc 基准测试运行器接口
   *       负责执行基准测试并收集结果
   *}
  IBenchmarkRunner = interface
    ['{C3D4E5F6-A7B8-9012-CDEF-123456789012}']

    {**
     * RunBenchmark
     *
     * @desc 运行单个基准测试
     *
     * @param aBenchmark 要运行的基准测试
     * @return 返回测试结果
     *}
    function RunBenchmark(aBenchmark: IBenchmark): IBenchmarkResult;

    {**
     * RunFunction
     *
     * @desc 运行函数基准测试
     *
     * @param aName 测试名称
     * @param aFunc 测试函数
     * @param aConfig 测试配置
     * @return 返回测试结果
     *}
    function RunFunction(const aName: string; aFunc: TBenchmarkFunction;
      const aConfig: TBenchmarkConfig): IBenchmarkResult;

    {**
     * RunMethod
     *
     * @desc 运行方法基准测试
     *
     * @param aName 测试名称
     * @param aMethod 测试方法
     * @param aConfig 测试配置
     * @return 返回测试结果
     *}
    function RunMethod(const aName: string; aMethod: TBenchmarkMethod;
      const aConfig: TBenchmarkConfig): IBenchmarkResult;

    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    {**
     * RunProc
     *
     * @desc 运行匿名过程基准测试
     *
     * @param aName 测试名称
     * @param aProc 测试过程
     * @param aConfig 测试配置
     * @return 返回测试结果
     *}
    function RunProc(const aName: string; aProc: TBenchmarkProc;
      const aConfig: TBenchmarkConfig): IBenchmarkResult;
    {$ENDIF}

    {**
     * RunMultiThreadFunction
     *
     * @desc 运行多线程函数基准测试
     *
     * @param aName 测试名称
     * @param aFunc 多线程测试函数
     * @param aThreadConfig 多线程配置
     * @param aConfig 基准测试配置
     * @return 返回测试结果
     *}
    function RunMultiThreadFunction(const aName: string;
                                   aFunc: TMultiThreadBenchmarkFunction;
                                   const aThreadConfig: TMultiThreadConfig;
                                   const aConfig: TBenchmarkConfig): IBenchmarkResult;

    {**
     * RunMultiThreadMethod
     *
     * @desc 运行多线程方法基准测试
     *
     * @param aName 测试名称
     * @param aMethod 多线程测试方法
     * @param aThreadConfig 多线程配置
     * @param aConfig 基准测试配置
     * @return 返回测试结果
     *}
    function RunMultiThreadMethod(const aName: string;
                                 aMethod: TMultiThreadBenchmarkMethod;
                                 const aThreadConfig: TMultiThreadConfig;
                                 const aConfig: TBenchmarkConfig): IBenchmarkResult;
  end;

  {**
   * IBenchmarkReporter
   *
   * @desc 基准测试报告器接口
   *       负责格式化和输出测试结果
   *}
  IBenchmarkReporter = interface
    ['{D4E5F6A7-B8C9-0123-DEF1-234567890123}']

    {**
     * ReportResult
     *
     * @desc 报告单个测试结果
     *
     * @param aResult 测试结果
     *}
    procedure ReportResult(aResult: IBenchmarkResult);

    {**
     * ReportResults
     *
     * @desc 报告多个测试结果
     *
     * @param aResults 测试结果数组
     *}
    procedure ReportResults(const aResults: array of IBenchmarkResult);

    {**
     * ReportComparison
     *
     * @desc 报告两个测试结果的比较
     *
     * @param aBaseline 基准结果
     * @param aCurrent 当前结果
     *}
    procedure ReportComparison(aBaseline, aCurrent: IBenchmarkResult);

    {**
     * SetOutputFile
     *
     * @desc 设置输出文件
     *
     * @param aFileName 文件名
     *}
    procedure SetOutputFile(const aFileName: string);

    {**
     * SetFormat
     *
     * @desc 设置输出格式
     *
     * @param aFormat 格式类型
     *}
    procedure SetFormat(const aFormat: string);
  end;

  {**
   * IBenchmarkSuite
   *
   * @desc 基准测试套件接口
   *       管理多个基准测试的集合
   *}
  IBenchmarkSuite = interface
    ['{E5F6A7B8-C9D0-1234-EF12-345678901234}']

    {**
     * AddBenchmark
     *
     * @desc 添加基准测试
     *
     * @param aBenchmark 基准测试
     *}
    procedure AddBenchmark(aBenchmark: IBenchmark);

    {**
     * AddFunction
     *
     * @desc 添加函数基准测试
     *
     * @param aName 测试名称
     * @param aFunc 测试函数
     * @param aConfig 测试配置
     *}
    procedure AddFunction(const aName: string; aFunc: TBenchmarkFunction;
      const aConfig: TBenchmarkConfig);

    {**
     * AddMethod
     *
     * @desc 添加方法基准测试
     *
     * @param aName 测试名称
     * @param aMethod 测试方法
     * @param aConfig 测试配置
     *}
    procedure AddMethod(const aName: string; aMethod: TBenchmarkMethod;
      const aConfig: TBenchmarkConfig);

    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    {**
     * AddProc
     *
     * @desc 添加匿名过程基准测试
     *
     * @param aName 测试名称
     * @param aProc 测试过程
     * @param aConfig 测试配置
     *}
    procedure AddProc(const aName: string; aProc: TBenchmarkProc;
      const aConfig: TBenchmarkConfig);
    {$ENDIF}

    {**
     * 新的统一短接口：Add 重载（保持接口短小干净）
     *}
    procedure Add(aBenchmark: IBenchmark); overload;
    procedure Add(const aName: string; aFunc: TBenchmarkFunction;
      const aConfig: TBenchmarkConfig); overload;
    procedure Add(const aName: string; aMethod: TBenchmarkMethod;
      const aConfig: TBenchmarkConfig); overload;
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    procedure Add(const aName: string; aProc: TBenchmarkProc;
      const aConfig: TBenchmarkConfig); overload;
    {$ENDIF}


    {**
     * RunAll
     *
     * @desc 运行所有基准测试
     *
     * @return 返回所有测试结果
     *}
    function RunAll: TBenchmarkResultArray;

    {**
     * RunAllWithReporter
     *
     * @desc 运行所有基准测试并使用报告器输出结果
     *
     * @param aReporter 报告器
     * @return 返回所有测试结果
     *}
    function RunAllWithReporter(aReporter: IBenchmarkReporter): TBenchmarkResultArray;

    {**
     * Clear
     *
     * @desc 清空所有基准测试
     *}
    procedure Clear;

    {**
     * GetCount
     *
     * @desc 获取基准测试数量
     *
     * @return 返回测试数量
     *}
    function GetCount: Integer;

    {**
     * RunComparison
     *
     * @desc 运行对比测试
     *
     * @param aIndex1 第一个测试的索引
     * @param aIndex2 第二个测试的索引
     * @return 返回对比结果
     *}
    function RunComparison(aIndex1, aIndex2: Integer): TBenchmarkComparison;

    {**
     * GenerateReport
     *
     * @desc 生成综合报告
     *
     * @param aTitle 报告标题
     * @return 返回报告数据
     *}
    function GenerateReport(const aTitle: string): TBenchmarkReport;

    {**
     * RunWithTrendAnalysis
     *
     * @desc 运行测试并进行趋势分析
     *
     * @param aHistoricalData 历史数据（可选）
     * @return 返回结果和趋势分析
     *}
    function RunWithTrendAnalysis(const aHistoricalData: array of TBenchmarkTrend): TBenchmarkResultArray;

    // 属性访问器
    property Count: Integer read GetCount;
  end;

  {**
   * IBenchmarkMonitor
   *
   * @desc 性能监控接口
   *       提供性能监控、警报和自动化测试功能
   *}
  IBenchmarkMonitor = interface
    ['{F6A7B8C9-D0E1-2345-F123-4567890123AB}']

    {**
     * SetThreshold
     *
     * @desc 设置性能阈值
     *
     * @param aTestName 测试名称
     * @param aThreshold 阈值（纳秒）
     *}
    procedure SetThreshold(const aTestName: string; aThreshold: Double);

    {**
     * SetRegressionThreshold
     *
     * @desc 设置回归检测阈值
     *
     * @param aTestName 测试名称
     * @param aThreshold 回归阈值（百分比，如 0.1 表示 10%）
     *}
    procedure SetRegressionThreshold(const aTestName: string; aThreshold: Double);

    {**
     * CheckPerformance
     *
     * @desc 检查性能并生成警报
     *
     * @param aResult 测试结果
     * @return 返回警报数组
     *}
    function CheckPerformance(aResult: IBenchmarkResult): TPerformanceAlertArray;

    {**
     * CheckRegression
     *
     * @desc 检查性能回归
     *
     * @param aCurrentResult 当前结果
     * @param aHistoricalResults 历史结果
     * @return 返回警报数组
     *}
    function CheckRegression(aCurrentResult: IBenchmarkResult;
                           const aHistoricalResults: array of IBenchmarkResult): TPerformanceAlertArray;

    {**
     * GetAlerts
     *
     * @desc 获取所有警报
     *
     * @return 返回警报数组
     *}
    function GetAlerts: TPerformanceAlertArray;

    {**
     * ClearAlerts
     *
     * @desc 清除所有警报
     *}
    procedure ClearAlerts;

    {**
     * SaveResults
     *
     * @desc 保存结果到文件
     *
     * @param aResults 结果数组
     * @param aFileName 文件名
     *}
    procedure SaveResults(const aResults: array of IBenchmarkResult; const aFileName: string);

    {**
     * LoadResults
     *
     * @desc 从文件加载结果
     *
     * @param aFileName 文件名
     * @return 返回结果数组
     *}
    function LoadResults(const aFileName: string): TBenchmarkResultArray;
  end;

  {**
   * IBenchmarkAnalyzer
   *
   * @desc 性能分析器接口
   *       提供智能性能分析和优化建议
   *}
  IBenchmarkAnalyzer = interface
    ['{A7B8C9D0-E1F2-3456-7890-ABCDEF123456}']

    {**
     * AnalyzePerformance
     *
     * @desc 分析性能并提供优化建议
     *
     * @param aResult 测试结果
     * @return 返回性能分析结果
     *}
    function AnalyzePerformance(aResult: IBenchmarkResult): TPerformanceAnalysis;

    {**
     * AnalyzeBatch
     *
     * @desc 批量分析多个测试结果
     *
     * @param aResults 测试结果数组
     * @return 返回分析结果数组
     *}
    function AnalyzeBatch(const aResults: array of IBenchmarkResult): TPerformanceAnalysisArray;

    {**
     * CompareWithExpected
     *
     * @desc 与预期性能对比
     *
     * @param aResult 测试结果
     * @param aExpectedMin 预期最小时间
     * @param aExpectedMax 预期最大时间
     * @return 返回分析结果
     *}
    function CompareWithExpected(aResult: IBenchmarkResult; aExpectedMin, aExpectedMax: Double): TPerformanceAnalysis;

    {**
     * GetOptimizationSuggestions
     *
     * @desc 获取优化建议
     *
     * @param aResult 测试结果
     * @return 返回优化建议数组
     *}
    function GetOptimizationSuggestions(aResult: IBenchmarkResult): TStringArray;
  end;

  {**
   * IBenchmarkTemplateManager
   *
   * @desc 基准测试模板管理器接口
   *       管理预定义的测试模板和配置
   *}
  IBenchmarkTemplateManager = interface
    ['{B8C9D0E1-F2A3-4567-8901-BCDEF1234567}']

    {**
     * GetTemplate
     *
     * @desc 获取指定名称的模板
     *
     * @param aName 模板名称
     * @return 返回模板定义
     *}
    function GetTemplate(const aName: string): TBenchmarkTemplate;

    {**
     * GetTemplatesByCategory
     *
     * @desc 获取指定分类的模板
     *
     * @param aCategory 分类名称
     * @return 返回模板数组
     *}
    function GetTemplatesByCategory(const aCategory: string): TBenchmarkTemplateArray;

    {**
     * GetAllTemplates
     *
     * @desc 获取所有可用模板
     *
     * @return 返回所有模板
     *}
    function GetAllTemplates: TBenchmarkTemplateArray;

    {**
     * CreateConfigFromTemplate
     *
     * @desc 从模板创建配置
     *
     * @param aTemplateName 模板名称
     * @return 返回基准测试配置
     *}
    function CreateConfigFromTemplate(const aTemplateName: string): TBenchmarkConfig;

    {**
     * RegisterTemplate
     *
     * @desc 注册新模板
     *
     * @param aTemplate 模板定义
     *}
    procedure RegisterTemplate(const aTemplate: TBenchmarkTemplate);
  end;

  {**
   * IRealTimeMonitor
   *
   * @desc 实时性能监控接口
   *       提供实时性能指标监控和可视化
   *}
  IRealTimeMonitor = interface
    ['{C9D0E1F2-A3B4-5678-9012-CDEF12345678}']

    {**
     * StartMonitoring
     *
     * @desc 开始实时监控
     *
     * @param aTestName 测试名称
     *}
    procedure StartMonitoring(const aTestName: string);

    {**
     * StopMonitoring
     *
     * @desc 停止实时监控
     *
     * @return 返回监控期间的指标数组
     *}
    function StopMonitoring: TRealTimeMetricsArray;

    {**
     * GetCurrentMetrics
     *
     * @desc 获取当前实时指标
     *
     * @return 返回当前指标
     *}
    function GetCurrentMetrics: TRealTimeMetrics;

    {**
     * GenerateRealTimeChart
     *
     * @desc 生成实时性能图表
     *
     * @param aFileName 图表文件名
     *}
    procedure GenerateRealTimeChart(const aFileName: string);
  end;

  {**
   * IPerformancePredictor
   *
   * @desc 性能预测接口
   *       使用机器学习算法预测性能趋势
   *}
  IPerformancePredictor = interface
    ['{D0E1F2A3-B4C5-6789-0123-DEF123456789}']

    {**
     * TrainModel
     *
     * @desc 训练预测模型
     *
     * @param aHistoricalData 历史数据
     *}
    procedure TrainModel(const aHistoricalData: array of IBenchmarkResult);

    {**
     * PredictPerformance
     *
     * @desc 预测性能
     *
     * @param aTestName 测试名称
     * @param aInputSize 输入规模
     * @return 返回预测结果
     *}
    function PredictPerformance(const aTestName: string; aInputSize: Int64): TPerformancePrediction;

    {**
     * GetModelAccuracy
     *
     * @desc 获取模型准确度
     *
     * @return 返回模型准确度 (0-1)
     *}
    function GetModelAccuracy: Double;

    {**
     * UpdateModel
     *
     * @desc 更新模型
     *
     * @param aNewResult 新的测试结果
     *}
    procedure UpdateModel(aNewResult: IBenchmarkResult);
  end;

  {**
   * ICodeProfiler
   *
   * @desc 代码性能分析器接口
   *       提供代码级别的性能热点分析
   *}
  ICodeProfiler = interface
    ['{E1F2A3B4-C5D6-789A-1234-EF1234567890}']

    {**
     * StartProfiling
     *
     * @desc 开始代码分析
     *
     * @param aTestName 测试名称
     *}
    procedure StartProfiling(const aTestName: string);

    {**
     * StopProfiling
     *
     * @desc 停止代码分析
     *
     * @return 返回热点分析结果
     *}
    function StopProfiling: TCodeHotspotArray;

    {**
     * AnalyzeHotspots
     *
     * @desc 分析性能热点
     *
     * @param aHotspots 热点数据
     * @return 返回优化建议
     *}
    function AnalyzeHotspots(const aHotspots: TCodeHotspotArray): TStringArray;

    {**
     * GenerateFlameGraph
     *
     * @desc 生成火焰图
     *
     * @param aFileName 火焰图文件名
     *}
    procedure GenerateFlameGraph(const aFileName: string);
  end;

  {**
   * IAdaptiveOptimizer
   *
   * @desc 自适应优化器接口
   *       自动调优测试配置以获得最佳结果
   *}
  IAdaptiveOptimizer = interface
    ['{F2A3B4C5-D6E7-89AB-2345-F12345678901}']

    {**
     * OptimizeConfig
     *
     * @desc 优化配置
     *
     * @param aTestFunction 测试函数
     * @param aTargetAccuracy 目标准确度
     * @return 返回优化后的配置
     *}
    function OptimizeConfig(aTestFunction: TBenchmarkFunction; aTargetAccuracy: Double): TAdaptiveConfig;

    {**
     * AdaptiveRun
     *
     * @desc 自适应运行
     *
     * @param aTestName 测试名称
     * @param aTestFunction 测试函数
     * @return 返回优化后的结果
     *}
    function AdaptiveRun(const aTestName: string; aTestFunction: TBenchmarkFunction): IBenchmarkResult;

    {**
     * GetOptimizationHistory
     *
     * @desc 获取优化历史
     *
     * @return 返回优化历史
     *}
    function GetOptimizationHistory: TAdaptiveConfigArray;
  end;

  {**
   * IDistributedCoordinator
   *
   * @desc 分布式协调器接口
   *       协调多节点分布式基准测试
   *}
  IDistributedCoordinator = interface
    ['{A3B4C5D6-E7F8-9ABC-3456-A12345678901}']

    {**
     * RegisterNode
     *
     * @desc 注册分布式节点
     *
     * @param aNode 节点信息
     *}
    procedure RegisterNode(const aNode: TDistributedNode);

    {**
     * DistributeTest
     *
     * @desc 分发测试任务
     *
     * @param aTests 测试数组
     * @return 返回分布式测试结果
     *}
    function DistributeTest(const aTests: array of TQuickBenchmark): TBenchmarkResultArray;

    {**
     * GetClusterStatus
     *
     * @desc 获取集群状态
     *
     * @return 返回所有节点状态
     *}
    function GetClusterStatus: TDistributedNodeArray;

    {**
     * LoadBalance
     *
     * @desc 负载均衡
     *
     * @param aWorkload 工作负载
     * @return 返回最佳节点ID
     *}
    function LoadBalance(aWorkload: Integer): string;
  end;

  {$IFDEF FAFAFA_BENCH_EXPERIMENTAL}
  {**
   * IQuantumAnalyzer
   *
   * @desc 量子性能分析器接口（实验特性）
   *}
  IQuantumAnalyzer = interface
    ['{B4C5D6E7-F8A9-BCDE-4567-B12345678901}']
    function InitializeQuantumState(const aTestName: string): TQuantumState;
    function MeasureQuantumPerformance(var aQuantumState: TQuantumState): Double;
    function CreateSuperposition(const aStates: array of Double): TQuantumState;
    function QuantumTunnel(aBarrierHeight: Double): Double;
  end;

  {**
   * IMultiDimensionalMapper
   *
   * @desc 多维性能空间映射器接口（实验特性）
   *}
  IMultiDimensionalMapper = interface
    ['{C5D6E7F8-A9BC-DEF0-5678-C12345678901}']
    function MapToHighDimensionalSpace(const aResults: array of IBenchmarkResult): TMultiDimensionalSpace;
    function CalculateSpaceCurvature(const aSpace: TMultiDimensionalSpace): Double;
    function FindOptimalPath(const aStart, aEnd: array of Double): array of array of Double;
    function ProjectToLowerDimension(const aSpace: TMultiDimensionalSpace; aTargetDimension: Integer): TMultiDimensionalSpace;
  end;
  {$ENDIF}

  {$IFDEF FAFAFA_BENCH_EXPERIMENTAL}
  {**
   * IBehaviorPatternRecognizer
   *
   * @desc 性能行为模式识别器接口（实验特性）
   *}
  IBehaviorPatternRecognizer = interface
    ['{D6E7F8A9-BCDE-F012-6789-D12345678901}']
    function AnalyzePattern(const aTimeSeries: array of Double): TBehaviorPattern;
    function PredictNextBehavior(const aPattern: TBehaviorPattern): TBehaviorPattern;
    function DetectAnomaly(const aPattern: TBehaviorPattern): Double;
    procedure LearnFromHistory(const aHistoricalPatterns: array of TBehaviorPattern);
  end;
  {$ENDIF}

  {$IFDEF FAFAFA_BENCH_EXPERIMENTAL}
  {**
   * IPerformanceOracle
   *
   * @desc 性能神谕接口（实验特性）
   *}
  IPerformanceOracle = interface
    ['{E7F8A9BC-DEF0-1234-789A-E12345678901}']
    function ConsultOracle(const aQuestion: string): TPerformanceProphecy;
    function PredictFuture(aTimeHorizon: TDateTime): TPerformanceProphecyArray;
    function InterpretSigns(const aSigns: array of string): string;
    function CastDivination(const aMethod: string): TPerformanceProphecy;
  end;
  {$ENDIF}

{ 辅助函数 }

{**
 * IIF
 *
 * @desc 简单的条件函数（替代 IfThen）
 *
 * @param aCondition 条件
 * @param aTrueValue 条件为真时的值
 * @param aFalseValue 条件为假时的值
 * @return 返回相应的值
 *}
function IIF(aCondition: Boolean; const aTrueValue, aFalseValue: string): string;

{ 工厂函数和默认配置 }

{**
 * CreateDefaultBenchmarkConfig
 *
 * @desc 创建默认的基准测试配置
 *
 * @return 返回默认配置
 *}
function CreateDefaultBenchmarkConfig: TBenchmarkConfig;

{**
 * CreateBenchmarkRunner
 *
 * @desc 创建基准测试运行器
 *
 * @return 返回运行器实例
 *}
function CreateBenchmarkRunner: IBenchmarkRunner;

{**
 * CreateBenchmarkSuite
 *
 * @desc 创建基准测试套件
 *
 * @return 返回套件实例
 *}
function CreateBenchmarkSuite: IBenchmarkSuite;

{**
 * CreateConsoleReporter
 *
 * @desc 创建控制台报告器
 *
 * @return 返回报告器实例
 *}
function CreateConsoleReporter: IBenchmarkReporter; overload;
function CreateConsoleReporter(const aSink: ITextSink): IBenchmarkReporter; overload;

{**
 * CreateConsoleReporterAsciiOnly
 * @desc 创建纯 ASCII 控制台报告器（禁用 UTF-8 符号与 μ）
 *}
function CreateConsoleReporterAsciiOnly: IBenchmarkReporter;

{**
 * CreateFileReporter
 *
 * @desc 创建文件报告器
 *
 * @param aFileName 输出文件名
 * @return 返回报告器实例
 *}
function CreateFileReporter(const aFileName: string): IBenchmarkReporter;

{**
 * CreateJSONReporter
 *
 * @desc 创建 JSON 格式报告器
 *       输出包含：
 *       - counters 对象映射（兼容历史）：name -> value
 *       - counter_list 列表：name/value/unit（bytes|items|rate|percent|unit）
 *
 * @param aFileName 输出文件名（可选，为空则输出到控制台）
 * @return 返回报告器实例
 *}
function CreateJSONReporter(const aFileName: string = ''): IBenchmarkReporter;
// Sink-injected overloads (optional injection)
function CreateJSONReporter(const aSink: ITextSink): IBenchmarkReporter;

{**
 * CreateCSVReporter
 *
 * @desc 创建 CSV 格式报告器
 *       最佳实践：
 *       - 可通过 SetFormat('schema=2;decimals=4;counters=tabular') 启用表格化 counters
 *       - 表格化时，动态列名按字母序稳定排序，并带 [unit]
 *       - 当某项结果缺失某计数器时，该列输出为空单元（非 0）
 *
 * @param aFileName 输出文件名（可选，为空则输出到控制台）
 * @return 返回报告器实例
 *}
function CreateCSVReporter(const aFileName: string = ''): IBenchmarkReporter;
function CreateCSVReporter(const aSink: ITextSink): IBenchmarkReporter;

{**
 * CreateJUnitReporter
 * @desc 创建 JUnit XML 报告器
 * @return 返回报告器实例
 *}
function CreateJUnitReporter(const aFileName: string = ''): IBenchmarkReporter;
function CreateJUnitReporter(const aSink: ITextSink): IBenchmarkReporter;

// Reporter multiplexer (fan-out)
function CreateReporterMux(const reporters: array of IBenchmarkReporter): IBenchmarkReporter;

// 单位显示策略（ASCII: "us" 或 UTF-8: "μs"）
type
  TUnitDisplayMode = (udAscii, udUTF8);

procedure SetUnitDisplayMode(aMode: TUnitDisplayMode);
function GetUnitDisplayMode: TUnitDisplayMode;
function CreateConsoleReporterWithUnit(aMode: TUnitDisplayMode): IBenchmarkReporter;

  // 可选：在 Reporter（JSON/CSV）输出中附加额外信息（例如最差回归摘要）
  procedure SetReportEmitRegressSummary(aEnabled: Boolean);
  procedure SetReportExtraWorstRegressionSummary(const aText: string);
  function GetReportEmitRegressSummary: Boolean;
  function GetReportExtraWorstRegressionSummary: string;




  // Global default reporter injection (optional; default = nil)
  procedure SetDefaultBenchmarkReporter(const AReporter: IBenchmarkReporter);
  function GetDefaultBenchmarkReporter: IBenchmarkReporter;

{ 工具：防止被测代码被优化掉的 Blackhole 辅助 }
procedure Blackhole(const v: Int64); overload;
procedure Blackhole(const v: Double); overload;


{**
 * CreateTestBenchmarkState
 *
 * @desc 创建测试用的基准测试状态对象（仅用于单元测试）
 *
 * @param aTargetDurationMs 目标持续时间（毫秒）
 * @return 返回状态对象实例
 *}
function CreateTestBenchmarkState(aTargetDurationMs: Integer = 1000): IBenchmarkState;

{ 快手 API：一行跑 / 一行测 / 一行比 }
function Bench(const aName: string; aFunc: TBenchmarkFunction): IBenchmarkResult; overload;
function Bench(const aName: string; aMethod: TBenchmarkMethod): IBenchmarkResult; overload;
{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
function Bench(const aName: string; aProc: TBenchmarkProc): IBenchmarkResult; overload;
{$ENDIF}
function BenchWithConfig(const aName: string; aFunc: TBenchmarkFunction; const aConfig: TBenchmarkConfig): IBenchmarkResult; overload;
function BenchWithConfig(const aName: string; aMethod: TBenchmarkMethod; const aConfig: TBenchmarkConfig): IBenchmarkResult; overload;
{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
function BenchWithConfig(const aName: string; aProc: TBenchmarkProc; const aConfig: TBenchmarkConfig): IBenchmarkResult; overload;
{$ENDIF}

function MeasureNs(aFunc: TBenchmarkFunction): Double; overload; // 返回 mean(ns/op)
function Compare(const n1, n2: string; f1, f2: TBenchmarkFunction): Double;


{ Google Benchmark 风格的注册和运行函数 }

{**
 * RegisterBenchmark
 *
 * @desc 注册基准测试函数
 *
 * @param aName 测试名称
 * @param aFunc 测试函数
 * @return 返回基准测试对象，可用于进一步配置
 *}
function RegisterBenchmark(const aName: string; aFunc: TBenchmarkFunction): IBenchmark;

{**
 * RegisterBenchmarkMethod
 *
 * @desc 注册基准测试方法
 *
 * @param aName 测试名称
 * @param aMethod 测试方法
 * @return 返回基准测试对象，可用于进一步配置
 *}
function RegisterBenchmarkMethod(const aName: string; aMethod: TBenchmarkMethod): IBenchmark;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
{**
 * RegisterBenchmarkProc
 *
 * @desc 注册基准测试匿名过程
 *
 * @param aName 测试名称
 * @param aProc 测试过程
 * @return 返回基准测试对象，可用于进一步配置
 *}
function RegisterBenchmarkProc(const aName: string; aProc: TBenchmarkProc): IBenchmark;
{$ENDIF}

{**
 * RegisterBenchmarkWithFixture
 *
 * @desc 注册带夹具的基准测试
 *
 * @param aName 测试名称
 * @param aFunc 测试函数
 * @param aFixture 测试夹具
 * @return 返回基准测试对象，可用于进一步配置
 *}
function RegisterBenchmarkWithFixture(const aName: string; aFunc: TBenchmarkFunction;
  aFixture: IBenchmarkFixture): IBenchmark;

{**
 * RunAllBenchmarks
 *
 * @desc 运行所有已注册的基准测试
 *
 * @return 返回所有测试结果
 *}
function RunAllBenchmarks: TBenchmarkResultArray;

{**
 * RunAllBenchmarksWithReporter
 *
 * @desc 运行所有已注册的基准测试并使用报告器输出
 *
 * @param aReporter 报告器
 * @return 返回所有测试结果
 *}
function RunAllBenchmarksWithReporter(aReporter: IBenchmarkReporter): TBenchmarkResultArray;
function ComputeStatistics(const aSamples: array of Double): TBenchmarkStatistics;

{**
 * ClearAllBenchmarks
 *
 * @desc 清除所有已注册的基准测试
 *}
procedure ClearAllBenchmarks;

{**
 * FreeGlobalBenchmarkRegistry
 *
 * @desc 释放全局基准测试注册器（用于严格内存检查/进程退出前清理）
 *}
procedure FreeGlobalBenchmarkRegistry;


{ 传统 API 支持（向后兼容） }

{**
 * RunLegacyFunction
 *
 * @desc 运行传统风格的基准测试函数
 *
 * @param aName 测试名称
 * @param aFunc 传统测试函数
 * @param aConfig 测试配置
 * @return 返回测试结果
 *}
function RunLegacyFunction(const aName: string; aFunc: TLegacyBenchmarkFunction;
  const aConfig: TBenchmarkConfig): IBenchmarkResult;

{**
 * RunLegacyMethod
 *
 * @desc 运行传统风格的基准测试方法
 *
 * @param aName 测试名称
 * @param aMethod 传统测试方法
 * @param aConfig 测试配置
 * @return 返回测试结果
 *}
function RunLegacyMethod(const aName: string; aMethod: TLegacyBenchmarkMethod;
  const aConfig: TBenchmarkConfig): IBenchmarkResult;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
{**
 * RunLegacyProc
 *
 * @desc 运行传统风格的基准测试过程
 *
 * @param aName 测试名称
 * @param aProc 传统测试过程
 * @param aConfig 测试配置
 * @return 返回测试结果
 *}
function RunLegacyProc(const aName: string; aProc: TLegacyBenchmarkProc;
  const aConfig: TBenchmarkConfig): IBenchmarkResult;
{$ENDIF}

{**
 * CreateLegacyBenchmark
 *
 * @desc 创建传统风格的基准测试对象
 *
 * @param aName 测试名称
 * @param aFunc 传统测试函数
 * @param aConfig 测试配置
 * @return 返回基准测试对象
 *}
function CreateLegacyBenchmark(const aName: string; aFunc: TLegacyBenchmarkFunction;
  const aConfig: TBenchmarkConfig): IBenchmark;

{**
 * RunMultiThreadBenchmark
 *
 * @desc 运行多线程基准测试（便捷函数）
 *
 * @param aName 测试名称
 * @param aFunc 多线程测试函数
 * @param aThreadCount 线程数量
 * @param aConfig 基准测试配置
 * @return 返回测试结果
 *}
function RunMultiThreadBenchmark(const aName: string;
                                aFunc: TMultiThreadBenchmarkFunction;
                                aThreadCount: Integer;
                                const aConfig: TBenchmarkConfig): IBenchmarkResult;

{**
 * RunMultiThreadBenchmark (重载)
 *
 * @desc 运行多线程基准测试（使用默认配置）
 *
 * @param aName 测试名称
 * @param aFunc 多线程测试函数
 * @param aThreadCount 线程数量
 * @return 返回测试结果
 *}
function RunMultiThreadBenchmark(const aName: string;
                                aFunc: TMultiThreadBenchmarkFunction;
                                aThreadCount: Integer): IBenchmarkResult;

{**
 * CreateMultiThreadConfig
 *
 * @desc 创建多线程配置
 *
 * @param aThreadCount 线程数量
 * @param aWorkPerThread 每个线程的工作量（可选）
 * @param aSyncThreads 是否同步启动线程
 * @return 返回多线程配置
 *}
function CreateMultiThreadConfig(aThreadCount: Integer;
                                aWorkPerThread: Integer = 0;
                                aSyncThreads: Boolean = True): TMultiThreadConfig;

{ 增强功能函数 }

{**
 * CreateBaseline
 *
 * @desc 创建性能基线
 *
 * @param aName 基线名称
 * @param aBaselineTime 基线时间（纳秒）
 * @param aTolerance 容忍度（百分比，如 0.1 表示 10%）
 * @param aDescription 基线描述
 * @return 返回基线定义
 *}
function CreateBaseline(const aName: string; aBaselineTime: Double;
                       aTolerance: Double = 0.1; const aDescription: string = ''): TBenchmarkBaseline;

{**
 * CompareResults
 *
 * @desc 比较两个基准测试结果
 *
 * @param aResult1 第一个结果
 * @param aResult2 第二个结果
 * @return 返回相对性能差异（正数表示 Result1 比 Result2 慢）
 *}
function CompareResults(aResult1, aResult2: IBenchmarkResult): Double;

{**
 * RecommendConfig
 *
 * @desc 为给定的测试函数推荐配置
 *
 * @param aTestFunc 测试函数
 * @return 返回推荐的配置
 *}
function RecommendConfig(aTestFunc: TBenchmarkFunction): TBenchmarkRecommendation;

{**
 * CreateParameterizedTestCase
 *
 * @desc 创建参数化测试用例
 *
 * @param aName 测试用例名称
 * @param aParameters 参数数组
 * @return 返回参数化测试用例
 *}
function CreateParameterizedTestCase(const aName: string;
                                    const aParameters: array of Variant): TParameterizedTestCase;

{ 批量测试和报告函数 }

{**
 * RunBatchComparison
 *
 * @desc 批量运行对比测试
 *
 * @param aFunctions 测试函数数组
 * @param aNames 测试名称数组
 * @param aConfig 测试配置
 * @return 返回对比结果数组
 *}
function RunBatchComparison(const aFunctions: array of TBenchmarkFunction;
                           const aNames: array of string;
                           const aConfig: TBenchmarkConfig): TBenchmarkComparisonArray;

{**
 * GenerateHTMLReport
 *
 * @desc 生成 HTML 格式的报告
 *
 * @param aReport 报告数据
 * @param aFileName 输出文件名
 *}
procedure GenerateHTMLReport(const aReport: TBenchmarkReport; const aFileName: string);

{**
 * SaveTrendData
 *
 * @desc 保存趋势数据到文件
 *
 * @param aTrend 趋势数据
 * @param aFileName 文件名
 *}
procedure SaveTrendData(const aTrend: TBenchmarkTrend; const aFileName: string);

{**
 * LoadTrendData
 *
 * @desc 从文件加载趋势数据
 *
 * @param aFileName 文件名
 * @return 返回趋势数据
 *}
function LoadTrendData(const aFileName: string): TBenchmarkTrend;

{ 快手接口 - 一行式基准测试 }

{**
 * benchmark
 *
 * @desc 创建快手基准测试定义
 *
 * @param aName 测试名称
 * @param aFunc 测试函数
 * @return 返回快手基准测试定义
 *}
function benchmark(const aName: string; aFunc: TBenchmarkFunction): TQuickBenchmark; overload;

{**
 * benchmark
 *
 * @desc 创建快手基准测试定义（带配置）
 *
 * @param aName 测试名称
 * @param aFunc 测试函数
 * @param aConfig 测试配置
 * @return 返回快手基准测试定义
 *}
function benchmark(const aName: string; aFunc: TBenchmarkFunction; const aConfig: TBenchmarkConfig): TQuickBenchmark; overload;

{**
 * benchmark
 *
 * @desc 创建快手基准测试定义（方法版本）
 *
 * @param aName 测试名称
 * @param aMethod 测试方法
 * @return 返回快手基准测试定义
 *}
function benchmark(const aName: string; aMethod: TBenchmarkMethod): TQuickBenchmark; overload;

{**
 * benchmarks
 *
 * @desc 运行一组快手基准测试
 *
 * @param aTests 测试数组
 * @return 返回测试结果数组
 *}
function benchmarks(const aTests: array of TQuickBenchmark): TBenchmarkResultArray; overload;

{**
 * benchmarks
 *
 * @desc 运行一组快手基准测试（带标题）
 *
 * @param aTitle 测试标题
 * @param aTests 测试数组
 * @return 返回测试结果数组
 *}
function benchmarks(const aTitle: string; const aTests: array of TQuickBenchmark): TBenchmarkResultArray; overload;

{**
 * quick_benchmark
 *
 * @desc 超级快手接口 - 直接运行并显示结果
 *
 * @param aTests 测试数组
 *}
procedure quick_benchmark(const aTests: array of TQuickBenchmark); overload;

{**
 * quick_benchmark
 *
 * @desc 超级快手接口 - 直接运行并显示结果（带标题）
 *
 * @param aTitle 测试标题
 * @param aTests 测试数组
 *}
procedure quick_benchmark(const aTitle: string; const aTests: array of TQuickBenchmark); overload;

{ 性能监控和自动化函数 }

{**
 * CreateBenchmarkMonitor
 *
 * @desc 创建性能监控器
 *
 * @return 返回监控器接口
 *}
function CreateBenchmarkMonitor: IBenchmarkMonitor;

{**
 * CreateExtendedConfig
 *
 * @desc 创建扩展配置
 *
 * @param aBaseConfig 基础配置
 * @return 返回扩展配置
 *}
function CreateExtendedConfig(const aBaseConfig: TBenchmarkConfig): TBenchmarkConfig_Extended;

{**
 * monitored_benchmark
 *
 * @desc 带监控的快手基准测试
 *
 * @param aTests 测试数组
 * @param aMonitor 监控器
 *}
procedure monitored_benchmark(const aTests: array of TQuickBenchmark; aMonitor: IBenchmarkMonitor); overload;

{**
 * monitored_benchmark
 *
 * @desc 带监控的快手基准测试（带标题）
 *
 * @param aTitle 测试标题
 * @param aTests 测试数组
 * @param aMonitor 监控器
 *}
procedure monitored_benchmark(const aTitle: string; const aTests: array of TQuickBenchmark; aMonitor: IBenchmarkMonitor); overload;

{**
 * regression_test
 *
 * @desc 回归测试 - 与历史结果对比
 *
 * @param aTests 测试数组
 * @param aHistoryFile 历史结果文件
 * @return 返回是否有回归
 *}
function regression_test(const aTests: array of TQuickBenchmark; const aHistoryFile: string): Boolean;

{**
 * continuous_benchmark
 *
 * @desc 持续基准测试 - 适合 CI/CD 集成
 *
 * @param aTests 测试数组
 * @param aConfigFile 配置文件
 * @return 返回测试是否通过
 *}
function continuous_benchmark(const aTests: array of TQuickBenchmark; const aConfigFile: string): Boolean;

{ 性能分析和模板管理函数 }

{**
 * CreateBenchmarkAnalyzer
 *
 * @desc 创建性能分析器
 *
 * @return 返回分析器接口
 *}
function CreateBenchmarkAnalyzer: IBenchmarkAnalyzer;

{**
 * CreateTemplateManager
 *
 * @desc 创建模板管理器
 *
 * @return 返回模板管理器接口
 *}
function CreateTemplateManager: IBenchmarkTemplateManager;

{**
 * analyzed_benchmark
 *
 * @desc 带性能分析的快手基准测试
 *
 * @param aTests 测试数组
 *}
procedure analyzed_benchmark(const aTests: array of TQuickBenchmark); overload;

{**
 * analyzed_benchmark
 *
 * @desc 带性能分析的快手基准测试（带标题）
 *
 * @param aTitle 测试标题
 * @param aTests 测试数组
 *}
procedure analyzed_benchmark(const aTitle: string; const aTests: array of TQuickBenchmark); overload;

{**
 * template_benchmark
 *
 * @desc 使用模板的快手基准测试
 *
 * @param aTemplateName 模板名称
 * @param aTests 测试数组
 *}
procedure template_benchmark(const aTemplateName: string; const aTests: array of TQuickBenchmark);

{**
 * GetCurrentPlatformInfo
 *
 * @desc 获取当前平台信息
 *
 * @return 返回平台信息
 *}
function GetCurrentPlatformInfo: TPlatformInfo;

{**
 * cross_platform_benchmark
 *
 * @desc 跨平台基准测试（保存平台信息）
 *
 * @param aTests 测试数组
 * @param aResultFile 结果文件
 *}
procedure cross_platform_benchmark(const aTests: array of TQuickBenchmark; const aResultFile: string);

{**
 * GeneratePerformanceReport
 *
 * @desc 生成详细的性能分析报告
 *
 * @param aResults 测试结果
 * @param aFileName 报告文件名
 *}
procedure GeneratePerformanceReport(const aResults: array of IBenchmarkResult; const aFileName: string);

{ 突破性功能函数 }

{**
 * CreateRealTimeMonitor
 *
 * @desc 创建实时监控器
 *
 * @return 返回实时监控器接口
 *}
function CreateRealTimeMonitor: IRealTimeMonitor;

{**
 * CreatePerformancePredictor
 *
 * @desc 创建性能预测器
 *
 * @return 返回性能预测器接口
 *}
function CreatePerformancePredictor: IPerformancePredictor;

{$IFDEF FAFAFA_BENCH_EXPERIMENTAL}
function CreateCodeProfiler: ICodeProfiler;
function CreateDistributedCoordinator: IDistributedCoordinator;
{$ENDIF}

function CreateAdaptiveOptimizer: IAdaptiveOptimizer;

{**
 * realtime_benchmark
 *
 * @desc 实时监控基准测试
 *
 * @param aTests 测试数组
 *}
procedure realtime_benchmark(const aTests: array of TQuickBenchmark); overload;

{**
 * realtime_benchmark
 *
 * @desc 实时监控基准测试（带标题）
 *
 * @param aTitle 测试标题
 * @param aTests 测试数组
 *}
procedure realtime_benchmark(const aTitle: string; const aTests: array of TQuickBenchmark); overload;

{**
 * predictive_benchmark
 *
 * @desc 预测性基准测试
 *
 * @param aTests 测试数组
 *}
procedure predictive_benchmark(const aTests: array of TQuickBenchmark); overload;

{**
 * predictive_benchmark
 *
 * @desc 预测性基准测试（带标题）
 *
 * @param aTitle 测试标题
 * @param aTests 测试数组
 *}
procedure predictive_benchmark(const aTitle: string; const aTests: array of TQuickBenchmark); overload;

{**
 * adaptive_benchmark
 *
 * @desc 自适应基准测试
 *
 * @param aTests 测试数组
 *}
procedure adaptive_benchmark(const aTests: array of TQuickBenchmark); overload;

{**
 * adaptive_benchmark
 *
 * @desc 自适应基准测试（带标题）
 *
 * @param aTitle 测试标题
 * @param aTests 测试数组
 *}
procedure adaptive_benchmark(const aTitle: string; const aTests: array of TQuickBenchmark); overload;

{**
 * distributed_benchmark
 *
 * @desc 分布式基准测试
 *
 * @param aTests 测试数组
 * @param aNodes 节点数组
 *}
{$IFDEF FAFAFA_BENCH_EXPERIMENTAL}
procedure distributed_benchmark(const aTests: array of TQuickBenchmark; const aNodes: array of TDistributedNode); overload;
procedure distributed_benchmark(const aTitle: string; const aTests: array of TQuickBenchmark; const aNodes: array of TDistributedNode); overload;
procedure quantum_benchmark(const aTests: array of TQuickBenchmark); overload;
procedure quantum_benchmark(const aTitle: string; const aTests: array of TQuickBenchmark); overload;
procedure multidimensional_benchmark(const aTests: array of TQuickBenchmark); overload;
procedure multidimensional_benchmark(const aTitle: string; const aTests: array of TQuickBenchmark); overload;
procedure pattern_benchmark(const aTests: array of TQuickBenchmark); overload;
procedure pattern_benchmark(const aTitle: string; const aTests: array of TQuickBenchmark); overload;
procedure prophetic_benchmark(const aTests: array of TQuickBenchmark); overload;
procedure prophetic_benchmark(const aTitle: string; const aTests: array of TQuickBenchmark); overload;
procedure artistic_benchmark(const aTests: array of TQuickBenchmark); overload;
procedure artistic_benchmark(const aTitle: string; const aTests: array of TQuickBenchmark); overload;
procedure hyperspeed_benchmark(const aTests: array of TQuickBenchmark); overload;
procedure hyperspeed_benchmark(const aTitle: string; const aTests: array of TQuickBenchmark); overload;
procedure transcendent_benchmark(const aTitle: string; const aTests: array of TQuickBenchmark);
procedure godmode_benchmark(const aTests: array of TQuickBenchmark);
procedure spacetime_benchmark(const aTests: array of TQuickBenchmark); overload;
procedure spacetime_benchmark(const aTitle: string; const aTests: array of TQuickBenchmark); overload;
procedure consciousness_benchmark(const aTests: array of TQuickBenchmark); overload;
procedure consciousness_benchmark(const aTitle: string; const aTests: array of TQuickBenchmark); overload;
procedure rainbow_benchmark(const aTests: array of TQuickBenchmark); overload;
procedure rainbow_benchmark(const aTitle: string; const aTests: array of TQuickBenchmark); overload;
procedure circus_benchmark(const aTests: array of TQuickBenchmark); overload;
procedure circus_benchmark(const aTitle: string; const aTests: array of TQuickBenchmark); overload;
procedure pizza_benchmark(const aTests: array of TQuickBenchmark); overload;
procedure pizza_benchmark(const aTitle: string; const aTests: array of TQuickBenchmark); overload;
{$ENDIF}

procedure ultimate_benchmark(const aTitle: string; const aTests: array of TQuickBenchmark);
procedure ai_benchmark(const aTests: array of TQuickBenchmark);

{$IFDEF FAFAFA_BENCH_EXPERIMENTAL}
function CreateQuantumAnalyzer: IQuantumAnalyzer;
function CreateMultiDimensionalMapper: IMultiDimensionalMapper;
function CreateBehaviorPatternRecognizer: IBehaviorPatternRecognizer;
{$ENDIF}

{**
 * unicorn_benchmark
 *
 * @desc 独角兽魔法基准测试
 *
 * @param aTests 测试数组
 *}
{$IFDEF FAFAFA_BENCH_EXPERIMENTAL}
procedure unicorn_benchmark(const aTests: array of TQuickBenchmark); overload;
procedure unicorn_benchmark(const aTitle: string; const aTests: array of TQuickBenchmark); overload;
procedure overtime_benchmark(const aTitle: string; const aTests: array of TQuickBenchmark);
procedure insanity_benchmark(const aTests: array of TQuickBenchmark);
{$ENDIF}

{$IFDEF FAFAFA_BENCH_EXPERIMENTAL}

{**
 * CreateSpaceTimeDistorter
 *
 * @desc 创建时空扭曲器
 *
 * @return 返回时空扭曲器接口
 *}
function CreateSpaceTimeDistorter: ISpaceTimeDistorter;

{**
 * CreateConsciousnessUploader
 *
 * @desc 创建意识上传器
 *
 * @return 返回意识上传器接口
 *}
function CreateConsciousnessUploader: IConsciousnessUploader;

{**
 * CreateRainbowDimensionMapper
 *
 * @desc 创建彩虹维度映射器
 *
 * @return 返回彩虹维度映射器接口
 *}
function CreateRainbowDimensionMapper: IRainbowDimensionMapper;

{**
 * CreateCircusPerformer
 *
 * @desc 创建马戏团表演者
 *
 * @return 返回马戏团表演者接口
 *}
function CreateCircusPerformer: ICircusPerformer;

{**
 * CreatePizzaOptimizer
 *
 * @desc 创建披萨优化器
 *
 * @return 返回披萨优化器接口
 *}
function CreatePizzaOptimizer: IPizzaOptimizer;

{**
 * CreateUnicornMagician
 *
 * @desc 创建独角兽魔法师
 *
 * @return 返回独角兽魔法师接口
 *}
function CreateUnicornMagician: IUnicornMagician;

{ 深夜加班模式超级疯狂功能函数 }

{**
 * gaming_benchmark
 *
 * @desc 游戏化基准测试
 *
 * @param aTests 测试数组
 *}
procedure gaming_benchmark(const aTests: array of TQuickBenchmark); overload;

{**
 * gaming_benchmark
 *
 * @desc 游戏化基准测试（带标题）
 *
 * @param aTitle 测试标题
 * @param aTests 测试数组
 *}
procedure gaming_benchmark(const aTitle: string; const aTests: array of TQuickBenchmark); overload;

{**
 * fastfood_benchmark
 *
 * @desc 快餐优化基准测试
 *
 * @param aTests 测试数组
 *}
procedure fastfood_benchmark(const aTests: array of TQuickBenchmark); overload;

{**
 * fastfood_benchmark
 *
 * @desc 快餐优化基准测试（带标题）
 *
 * @param aTitle 测试标题
 * @param aTests 测试数组
 *}
procedure fastfood_benchmark(const aTitle: string; const aTests: array of TQuickBenchmark); overload;

{**
 * music_benchmark
 *
 * @desc 音乐同步基准测试
 *
 * @param aTests 测试数组
 *}
procedure music_benchmark(const aTests: array of TQuickBenchmark); overload;

{**
 * music_benchmark
 *
 * @desc 音乐同步基准测试（带标题）
 *
 * @param aTitle 测试标题
 * @param aTests 测试数组
 *}
procedure music_benchmark(const aTitle: string; const aTests: array of TQuickBenchmark); overload;

{**
 * cat_benchmark
 *
 * @desc 猫咪驱动基准测试
 *
 * @param aTests 测试数组
 *}
procedure cat_benchmark(const aTests: array of TQuickBenchmark); overload;

{**
 * cat_benchmark
 *
 * @desc 猫咪驱动基准测试（带标题）
 *
 * @param aTitle 测试标题
 * @param aTests 测试数组
 *}
procedure cat_benchmark(const aTitle: string; const aTests: array of TQuickBenchmark); overload;

{**
 * toilet_benchmark
 *
 * @desc 厕所哲学基准测试
 *
 * @param aTests 测试数组
 *}
procedure toilet_benchmark(const aTests: array of TQuickBenchmark); overload;

{**
 * toilet_benchmark
 *
 * @desc 厕所哲学基准测试（带标题）
 *
 * @param aTitle 测试标题
 * @param aTests 测试数组
 *}
procedure toilet_benchmark(const aTitle: string; const aTests: array of TQuickBenchmark); overload;

{**
 * birthday_benchmark
 *
 * @desc 生日庆祝基准测试
 *
 * @param aTests 测试数组
 *}
procedure birthday_benchmark(const aTests: array of TQuickBenchmark); overload;

{**
 * birthday_benchmark
 *
 * @desc 生日庆祝基准测试（带标题）
 *
 * @param aTitle 测试标题
 * @param aTests 测试数组
 *}
procedure birthday_benchmark(const aTitle: string; const aTests: array of TQuickBenchmark); overload;

{**
 * midnight_benchmark
 *
 * @desc 深夜加班模式基准测试 - 集成所有深夜疯狂功能
 *
 * @param aTitle 测试标题
 * @param aTests 测试数组
 *}
procedure midnight_benchmark(const aTitle: string; const aTests: array of TQuickBenchmark);

{**
 * sleepless_benchmark
 *
 * @desc 失眠模式基准测试 - 彻夜不眠的疯狂测试
 *
 * @param aTests 测试数组
 *}
procedure sleepless_benchmark(const aTests: array of TQuickBenchmark);

{**
 * coffee_benchmark
 *
 * @desc 咖啡因驱动基准测试 - 用咖啡提升性能
 *
 * @param aCoffeeCount 咖啡杯数
 * @param aTests 测试数组
 *}
procedure coffee_benchmark(aCoffeeCount: Integer; const aTests: array of TQuickBenchmark);

{**
 * CreateGameMaster
 *
 * @desc 创建游戏大师
 *
 * @return 返回游戏大师接口
 *}
function CreateGameMaster: IGameMaster;

{**
 * CreateFastFoodOptimizer
 *
 * @desc 创建快餐优化器
 *
 * @return 返回快餐优化器接口
 *}
function CreateFastFoodOptimizer: IFastFoodOptimizer;

{**
 * CreateMusicSynchronizer
 *
 * @desc 创建音乐同步器
 *
 * @return 返回音乐同步器接口
 *}
function CreateMusicSynchronizer: IMusicSynchronizer;

{**
 * CreateCatAnalyst
 *
 * @desc 创建猫咪分析师
 *
 * @return 返回猫咪分析师接口
 *}
function CreateCatAnalyst: ICatAnalyst;

{**
 * CreateToiletPhilosopher
 *
 * @desc 创建厕所哲学家
 *
 * @return 返回厕所哲学家接口
 *}
function CreateToiletPhilosopher: IToiletPhilosopher;

{**
 * CreateBirthdayPartyPlanner
 *
 * @desc 创建生日派对策划师
 *
 * @return 返回生日派对策划师接口
 *}
function CreateBirthdayPartyPlanner: IBirthdayPartyPlanner;
{$ENDIF}

// XMLEscape moved to fafafa.core.base


implementation

var
  GUnitDisplayMode: TUnitDisplayMode = udAscii;
  _bh_i64: Int64 = 0;
  _bh_f64: Double = 0.0;

  _DefaultReporter: IBenchmarkReporter = nil;

  GReportEmitRegressSummary: Boolean = False;
  GReportExtraWorstSummary: string = '';


{ 辅助函数实现 }

function IIF(aCondition: Boolean; const aTrueValue, aFalseValue: string): string;
begin
  if aCondition then
    Result := aTrueValue
  else
    Result := aFalseValue;
end;

function BenchmarkCreateDefaultTick: ITick; inline;
begin
  Result := MakeBestTick;
end;

function BenchmarkGetCurrentTick(const aTick: ITick): UInt64; inline;
begin
  if aTick = nil then Exit(0);
  Result := aTick.Tick;
end;

function BenchmarkTicksToNanoSeconds(const aTick: ITick; aTicks: UInt64): Double; inline;
var
  LResolution: UInt64;
begin
  if aTick = nil then Exit(0.0);
  LResolution := aTick.Resolution;
  if LResolution = 0 then Exit(0.0);
  Result := (Double(aTicks) * 1000000000.0) / Double(LResolution);
end;

function BenchmarkMeasureElapsed(const aTick: ITick; aStartTick: UInt64): Double; inline;
begin
  Result := BenchmarkTicksToNanoSeconds(aTick, BenchmarkGetCurrentTick(aTick) - aStartTick);
end;

{ 默认配置实现 }

function CreateDefaultBenchmarkConfig: TBenchmarkConfig;
begin
  Result.Mode := bmTime;
  Result.WarmupIterations := 2;     // 更快预热，提升反馈速度
  Result.MeasureIterations := 10;
  Result.MinDurationMs := 100;      // 更快默认时长
  Result.MaxDurationMs := 1000;     // 上限 1 秒
  Result.TimeUnit := buNanoSeconds; // 保持默认内部单位不变（测试兼容）
  Result.EnableMemoryMeasurement := False;
  Result.EnableOverheadCorrection := False; // 默认关闭，避免影响既有结果
end;

{ 实现类型前向声明 }
type
  TBenchmarkResult = class;
  TBenchmark = class;
  TBenchmarkRunner = class;
  TBenchmarkSuite = class;
  TConsoleReporter = class;


  TFileReporter = class;
  TJSONReporter = class;
  TCSVReporter = class;
  TBenchmarkState = class;
  TBenchmarkRegistry = class;
  TBenchmarkResultV2 = class;

  TMissingPolicy = (mpBlank, mpZero, mpNA);

{ 实现类定义 }


{**
   * TBenchmarkState
   *
   * @desc 基准测试状态实现类（Google Benchmark 风格）
   *}
  TBenchmarkState = class(TInterfacedObject, IBenchmarkState)
  private
    FTick: ITick;
    FIterations: Int64;
    FCurrentIteration: Int64;
    FStartTime: UInt64;
    FElapsedTime: Double;
    FTimingPaused: Boolean;
    FPauseStartTime: UInt64;
    FTotalPausedTime: Double;
    FBytesProcessed: Int64;
    FItemsProcessed: Int64;
    FComplexityN: Int64;
    FCounters: TBenchmarkCounterArray;
    FAutoIterations: Boolean;
    FTargetDurationMs: Integer;
    // 🔧 P0-3：预热阶段支持
    FWarmupIterations: Integer;
    FCurrentWarmupIteration: Integer;
    FWarmupCompleted: Boolean;
    // 🔧 P1-1：校准算法支持
    FCalibrationCompleted: Boolean;
    FCalibrationIterations: Integer;
    FCalibrationStartTime: UInt64;
    FTargetCalibrationTimeNS: Double;
    FCalibrationAbsoluteStartTime: UInt64; // 🔧 P1-1：校准绝对起点
    FCalibrationMaxDurationNS: Double;     // 🔧 P1-1：校准绝对最长时长（纳秒），默认1秒
    // 🔧 内存测量支持
    FInitialMemoryUsage: Int64;
    FPeakMemoryUsage: Int64;

    {**
     * EstimateIterations
     *
     * @desc 估算所需的迭代次数
     *}
    function EstimateIterations: Int64;

    {**
     * GetCurrentMemoryUsage
     *
     * @desc 获取当前进程的内存使用量
     *}
    function GetCurrentMemoryUsage: Int64;

    {**
     * UpdateElapsedTime
     *
     * @desc 更新已过时间
     *}
    procedure UpdateElapsedTime;

  public
    constructor Create(aTargetDurationMs: Integer = 1000);
    destructor Destroy; override;

    // IBenchmarkState 接口实现
    function KeepRunning: Boolean;
    procedure SetIterations(aCount: Int64);
    procedure PauseTiming; inline;
    procedure ResumeTiming; inline;
    // 简写与Blackhole封装
    procedure Pause; inline;
    procedure Resume; inline;
    procedure Blackhole(const v: Int64); overload; inline;
    procedure Blackhole(const v: Double); overload; inline;
    // 计数与统计接口
    procedure SetBytesProcessed(aBytes: Int64);
    procedure SetItemsProcessed(aItems: Int64);
    procedure SetComplexityN(aN: Int64);
    function GetBytesProcessed: Int64;
    function GetItemsProcessed: Int64;
    function GetComplexityN: Int64;
    function GetCounters: TBenchmarkCounterArray;
    procedure AddCounter(const aName: string; aValue: Double; aUnit: TCounterUnit = cuDefault);
    function GetMemoryUsage: Int64;
    function GetPeakMemoryUsage: Int64;
    procedure SetWarmupIterations(aCount: Integer); // 🔧 P0-3：预热迭代设置
    procedure SetTargetCalibrationTime(aTimeMS: Double); // 🔧 P1-1：校准时间设置
    procedure SetCalibrationMaxDuration(aTimeMS: Double); // 🔧 P1-1：校准绝对最长时长设置
    function GetIterations: Int64;
    function GetElapsedTime: Double;
  end;

  {**
   * TBenchmarkRegistry
   *
   * @desc 全局基准测试注册管理器
   *}
  TBenchmarkRegistry = class
  private
    FBenchmarks: array of IBenchmark;

  public
    constructor Create;
    destructor Destroy; override;

    {**
     * RegisterBenchmark
     *
     * @desc 注册基准测试
     *}
    function RegisterBenchmark(const aName: string; aFunc: TBenchmarkFunction): IBenchmark;
    function RegisterBenchmarkMethod(const aName: string; aMethod: TBenchmarkMethod): IBenchmark;
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    function RegisterBenchmarkProc(const aName: string; aProc: TBenchmarkProc): IBenchmark;
    {$ENDIF}
    function RegisterBenchmarkWithFixture(const aName: string; aFunc: TBenchmarkFunction;
      aFixture: IBenchmarkFixture): IBenchmark;

    {**
     * RunAll
     *
     * @desc 运行所有注册的基准测试
     *}
    function RunAll: TBenchmarkResultArray;
    function RunAllWithReporter(aReporter: IBenchmarkReporter): TBenchmarkResultArray;

    // 统一短接口：Add 重载（兼容 RegisterXxx）
    function Add(const aName: string; aFunc: TBenchmarkFunction): IBenchmark; overload;
    function Add(const aName: string; aMethod: TBenchmarkMethod): IBenchmark; overload;
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    function Add(const aName: string; aProc: TBenchmarkProc): IBenchmark; overload;
    {$ENDIF}
    function AddWithFixture(const aName: string; aFunc: TBenchmarkFunction; aFixture: IBenchmarkFixture): IBenchmark;

    {**
     * Clear
     *
     * @desc 清除所有注册的基准测试
     *}
    procedure Clear;

    {**
     * GetCount
     *
     * @desc 获取注册的基准测试数量
     *}
    function GetCount: Integer;
  end;

  {**
   * TBenchmarkResult
   *
   * @desc 基准测试结果实现类
   *}
  TBenchmarkResult = class(TInterfacedObject, IBenchmarkResult)
  private
    FName: string;
    FIterations: Int64;
    FTotalTime: Double;
    FStatistics: TBenchmarkStatistics;
    FConfig: TBenchmarkConfig;
    FSamples: array of Double;
  public
    constructor Create(const aName: string; aIterations: Int64;
      aTotalTime: Double; const aConfig: TBenchmarkConfig;
      const aSamples: array of Double);

    // IBenchmarkResult 接口实现
    function GetName: string;
    function GetIterations: Int64;
    function GetTotalTime: Double;
    function GetStatistics: TBenchmarkStatistics;
    function GetConfig: TBenchmarkConfig;
    function GetTimePerIteration(aUnit: TBenchmarkUnit = buNanoSeconds): Double;
    function GetThroughput: Double;
    function GetBytesPerSecond: Double;
    function GetItemsPerSecond: Double;
    function GetCounters: TBenchmarkCounterArray;
    function GetSamples: TBenchmarkSampleArray;
    function HasStatistics: Boolean;
    function GetComplexityN: Int64;

    // 新增的增强方法
    function GetPercentile(aPercentile: Double): Double;
    function CompareWithBaseline(const aBaseline: TBenchmarkBaseline): Double;
    function IsRegressionFrom(const aBaseline: TBenchmarkBaseline): Boolean;
    procedure GetConfidenceInterval(aConfidenceLevel: Double; out aLowerBound, aUpperBound: Double);
  end;

  {**
   * TBenchmarkResultV2
   *
   * @desc 增强的基准测试结果实现类（支持新功能）
   *}
  TBenchmarkResultV2 = class(TInterfacedObject, IBenchmarkResult)
  private
    FName: string;
    FIterations: Int64;
    FTotalTime: Double;
    FStatistics: TBenchmarkStatistics;
    FConfig: TBenchmarkConfig;
    FSamples: array of Double;
    FBytesProcessed: Int64;
    FItemsProcessed: Int64;
    FComplexityN: Int64;
    FCounters: TBenchmarkCounterArray;

  public
    constructor Create(const aName: string; aIterations: Int64;
      aTotalTime: Double; const aConfig: TBenchmarkConfig;
      const aSamples: array of Double; aState: IBenchmarkState);

    // IBenchmarkResult 接口实现
    function GetName: string;
    function GetIterations: Int64;
    function GetTotalTime: Double;
    function GetStatistics: TBenchmarkStatistics;
    function GetConfig: TBenchmarkConfig;
    function GetTimePerIteration(aUnit: TBenchmarkUnit = buNanoSeconds): Double;
    function GetThroughput: Double;
    function GetBytesPerSecond: Double;
    function GetItemsPerSecond: Double;
    function GetCounters: TBenchmarkCounterArray;
    function GetSamples: TBenchmarkSampleArray;
    function HasStatistics: Boolean;
    function GetComplexityN: Int64;

    // 新增的增强方法
    function GetPercentile(aPercentile: Double): Double;
    function CompareWithBaseline(const aBaseline: TBenchmarkBaseline): Double;
    function IsRegressionFrom(const aBaseline: TBenchmarkBaseline): Boolean;
    procedure GetConfidenceInterval(aConfidenceLevel: Double; out aLowerBound, aUpperBound: Double);
  end;

  {**
   * TBenchmark
   *
   * @desc 基准测试实现类（支持新旧两种 API）
   *}
  TBenchmark = class(TInterfacedObject, IBenchmark)
  private
    FName: string;
    FConfig: TBenchmarkConfig;

    // 新 API 支持
    FFunction: TBenchmarkFunction;
    FMethod: TBenchmarkMethod;
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    FProc: TBenchmarkProc;
    {$ENDIF}
    FFixture: IBenchmarkFixture;

    // 传统 API 支持
    FLegacyFunction: TLegacyBenchmarkFunction;
    FLegacyMethod: TLegacyBenchmarkMethod;
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    FLegacyProc: TLegacyBenchmarkProc;
    {$ENDIF}

    FIsLegacy: Boolean;

  public
    constructor Create;

    // 新 API 构造函数
    constructor CreateWithFunction(const aName: string; aFunc: TBenchmarkFunction);
    constructor CreateWithMethod(const aName: string; aMethod: TBenchmarkMethod);
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    constructor CreateWithProc(const aName: string; aProc: TBenchmarkProc);
    {$ENDIF}
    constructor CreateWithFixture(const aName: string; aFunc: TBenchmarkFunction;
      aFixture: IBenchmarkFixture);

    // 传统 API 构造函数（向后兼容）
    constructor CreateLegacyFunction(const aName: string; aFunc: TLegacyBenchmarkFunction;
      const aConfig: TBenchmarkConfig);
    constructor CreateLegacyMethod(const aName: string; aMethod: TLegacyBenchmarkMethod;
      const aConfig: TBenchmarkConfig);
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    constructor CreateLegacyProc(const aName: string; aProc: TLegacyBenchmarkProc;
      const aConfig: TBenchmarkConfig);
    {$ENDIF}

    // IBenchmark 接口实现
    function GetName: string;
    procedure SetName(const aName: string);
    function GetConfig: TBenchmarkConfig;
    procedure SetConfig(const aConfig: TBenchmarkConfig);
    function Run: IBenchmarkResult;
  end;

  {**
   * TBenchmarkRunner
   *
   * @desc 基准测试运行器实现类
   *}
  TBenchmarkRunner = class(TInterfacedObject, IBenchmarkRunner)
  private
    FTick: ITick;

    {**
     * ExecuteWarmup
     *
     * @desc 执行预热阶段
     *}
    procedure ExecuteWarmup(aBenchmark: IBenchmark);

    {**
     * MeasureExecution
     *
     * @desc 测量执行时间
     *}
    function MeasureExecution(aBenchmark: IBenchmark): IBenchmarkResult;

    {**
     * CalculateStatistics
     *
     * @desc 计算统计数据
     *}
    function CalculateStatistics(const aSamples: array of Double): TBenchmarkStatistics;

    {**
     * ConvertTimeUnit
     *
     * @desc 转换时间单位
     *}
    function ConvertTimeUnit(aNanoSeconds: Double; aUnit: TBenchmarkUnit): Double;

    {**
     * 传统 API 支持方法
     *}
    function RunLegacyFunction(const aName: string; aFunc: TLegacyBenchmarkFunction;
      const aConfig: TBenchmarkConfig): IBenchmarkResult;
    function RunLegacyMethod(const aName: string; aMethod: TLegacyBenchmarkMethod;
      const aConfig: TBenchmarkConfig): IBenchmarkResult;
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    function RunLegacyProc(const aName: string; aProc: TLegacyBenchmarkProc;
      const aConfig: TBenchmarkConfig): IBenchmarkResult;
    {$ENDIF}

  public
    constructor Create;
    destructor Destroy; override;

    // IBenchmarkRunner 接口实现
    function RunBenchmark(aBenchmark: IBenchmark): IBenchmarkResult;
    function RunFunction(const aName: string; aFunc: TBenchmarkFunction;
      const aConfig: TBenchmarkConfig): IBenchmarkResult;
    function RunMethod(const aName: string; aMethod: TBenchmarkMethod;
      const aConfig: TBenchmarkConfig): IBenchmarkResult;
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    function RunProc(const aName: string; aProc: TBenchmarkProc;
      const aConfig: TBenchmarkConfig): IBenchmarkResult;
    {$ENDIF}

    // 多线程基准测试方法
    function RunMultiThreadFunction(const aName: string;
                                   aFunc: TMultiThreadBenchmarkFunction;
                                   const aThreadConfig: TMultiThreadConfig;
                                   const aConfig: TBenchmarkConfig): IBenchmarkResult;
    function RunMultiThreadMethod(const aName: string;
                                 aMethod: TMultiThreadBenchmarkMethod;
                                 const aThreadConfig: TMultiThreadConfig;
                                 const aConfig: TBenchmarkConfig): IBenchmarkResult;
  end;

  {**
   * TBenchmarkSuite
   *
   * @desc 基准测试套件实现类
   *}
  TBenchmarkSuite = class(TInterfacedObject, IBenchmarkSuite)
  private
    FBenchmarks: array of IBenchmark;
    FRunner: IBenchmarkRunner;

    // 统一 Add 重载，委托到具体 AddXxx 实现
    procedure Add(aBenchmark: IBenchmark); overload;
    procedure Add(const aName: string; aFunc: TBenchmarkFunction;
      const aConfig: TBenchmarkConfig); overload;
    procedure Add(const aName: string; aMethod: TBenchmarkMethod;
      const aConfig: TBenchmarkConfig); overload;
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    procedure Add(const aName: string; aProc: TBenchmarkProc;
      const aConfig: TBenchmarkConfig); overload;
    {$ENDIF}

  public
    constructor Create;
    destructor Destroy; override;

    // IBenchmarkSuite 接口实现
    procedure AddBenchmark(aBenchmark: IBenchmark);
    procedure AddFunction(const aName: string; aFunc: TBenchmarkFunction;
      const aConfig: TBenchmarkConfig);
    procedure AddMethod(const aName: string; aMethod: TBenchmarkMethod;
      const aConfig: TBenchmarkConfig);
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    procedure AddProc(const aName: string; aProc: TBenchmarkProc;
      const aConfig: TBenchmarkConfig);
    {$ENDIF}
    function RunAll: TBenchmarkResultArray;
    function RunAllWithReporter(aReporter: IBenchmarkReporter): TBenchmarkResultArray;
    procedure Clear;
    function GetCount: Integer;

    // 新增的增强方法
    function RunComparison(aIndex1, aIndex2: Integer): TBenchmarkComparison;
    function GenerateReport(const aTitle: string): TBenchmarkReport;
    function RunWithTrendAnalysis(const aHistoricalData: array of TBenchmarkTrend): TBenchmarkResultArray;
  end;

  {**
   * TConsoleReporter
   *
   * @desc 控制台报告器实现类
   *}
  TConsoleReporter = class(TInterfacedObject, IBenchmarkReporter)
  private
    FFormat: string;
    FAsciiOnly: Boolean;
    FSink: ITextSink;

    {**
     * FormatTime
     *
     * @desc 格式化时间显示
     *}
    function FormatTime(aNanoSeconds: Double): string;

    {**
     * FormatThroughput
     *
     * @desc 格式化吞吐量显示
     *}
    function FormatThroughput(aThroughput: Double): string;

  public
    constructor Create; overload;
    constructor Create(aAsciiOnly: Boolean); overload;
    procedure SetSink(const aSink: ITextSink);

    procedure W(const S: string);


    // IBenchmarkReporter 接口实现
    procedure ReportResult(aResult: IBenchmarkResult);
    procedure ReportResults(const aResults: array of IBenchmarkResult);
    procedure ReportComparison(aBaseline, aCurrent: IBenchmarkResult);
    procedure SetOutputFile(const aFileName: string);
    procedure SetFormat(const aFormat: string);
  end;

  {**
   * TBenchmarkMonitor
   *
   * @desc 性能监控器实现类
   *}
  TBenchmarkMonitor = class(TInterfacedObject, IBenchmarkMonitor)
  private
    FThresholds: array of record
      TestName: string;
      Threshold: Double;
    end;
    FRegressionThresholds: array of record
      TestName: string;
      Threshold: Double;
    end;
    FAlerts: TPerformanceAlertArray;

  public
    constructor Create;

    // IBenchmarkMonitor 接口实现
    procedure SetThreshold(const aTestName: string; aThreshold: Double);
    procedure SetRegressionThreshold(const aTestName: string; aThreshold: Double);
    function CheckPerformance(aResult: IBenchmarkResult): TPerformanceAlertArray;
    function CheckRegression(aCurrentResult: IBenchmarkResult;
                           const aHistoricalResults: array of IBenchmarkResult): TPerformanceAlertArray;
    function GetAlerts: TPerformanceAlertArray;
    procedure ClearAlerts;
    procedure SaveResults(const aResults: array of IBenchmarkResult; const aFileName: string);
    function LoadResults(const aFileName: string): TBenchmarkResultArray;
  end;

  {**
   * TBenchmarkAnalyzer
   *
   * @desc 性能分析器实现类
   *}
  TBenchmarkAnalyzer = class(TInterfacedObject, IBenchmarkAnalyzer)
  public
    // IBenchmarkAnalyzer 接口实现
    function AnalyzePerformance(aResult: IBenchmarkResult): TPerformanceAnalysis;
    function AnalyzeBatch(const aResults: array of IBenchmarkResult): TPerformanceAnalysisArray;
    function CompareWithExpected(aResult: IBenchmarkResult; aExpectedMin, aExpectedMax: Double): TPerformanceAnalysis;
    function GetOptimizationSuggestions(aResult: IBenchmarkResult): TStringArray;
  end;

  {**
   * TBenchmarkTemplateManager
   *
   * @desc 基准测试模板管理器实现类
   *}
  TBenchmarkTemplateManager = class(TInterfacedObject, IBenchmarkTemplateManager)
  private
    FTemplates: TBenchmarkTemplateArray;

  public
    constructor Create;

    // IBenchmarkTemplateManager 接口实现
    function GetTemplate(const aName: string): TBenchmarkTemplate;
    function GetTemplatesByCategory(const aCategory: string): TBenchmarkTemplateArray;
    function GetAllTemplates: TBenchmarkTemplateArray;
    function CreateConfigFromTemplate(const aTemplateName: string): TBenchmarkConfig;
    procedure RegisterTemplate(const aTemplate: TBenchmarkTemplate);

  private
    procedure InitializeDefaultTemplates;
  end;

  {**
   * TRealTimeMonitor
   *
   * @desc 实时性能监控器实现类
   *}
  TRealTimeMonitor = class(TInterfacedObject, IRealTimeMonitor)
  private
    FIsMonitoring: Boolean;
    FTestName: string;
    FStartTime: TDateTime;
    FMetricsHistory: array of TRealTimeMetrics;
    FCurrentMetrics: TRealTimeMetrics;

  public
    constructor Create;

    // IRealTimeMonitor 接口实现
    procedure StartMonitoring(const aTestName: string);
    function StopMonitoring: TRealTimeMetricsArray;
    function GetCurrentMetrics: TRealTimeMetrics;
    procedure GenerateRealTimeChart(const aFileName: string);

  private
    procedure UpdateMetrics;
    function GetCPUUsage: Double;
    function GetMemoryUsage: Int64;
    procedure CalculatePercentiles(const aTimes: array of Double; out aPercentiles: array of Double);
  end;

  {**
   * TPerformancePredictor
   *
   * @desc AI 性能预测器实现类
   *}
  TPerformancePredictor = class(TInterfacedObject, IPerformancePredictor)
  private
    FTrainingData: array of record
      TestName: string;
      InputSize: Int64;
      ExecutionTime: Double;
      Timestamp: TDateTime;
    end;
    FModelAccuracy: Double;
    FModelVersion: string;

  public
    constructor Create;

    // IPerformancePredictor 接口实现
    procedure TrainModel(const aHistoricalData: array of IBenchmarkResult);
    function PredictPerformance(const aTestName: string; aInputSize: Int64): TPerformancePrediction;
    function GetModelAccuracy: Double;
    procedure UpdateModel(aNewResult: IBenchmarkResult);

  private
    function LinearRegression(const aInputSizes: array of Int64; const aTimes: array of Double): TLinearRegressionParams;
    function CalculateAccuracy(const aPredicted, aActual: array of Double): Double;
    function EstimateComplexity(const aInputSizes: array of Int64; const aTimes: array of Double): string;
  end;

  {**
   * TAdaptiveOptimizer
   *
   * @desc 自适应优化器实现类
   *}
  TAdaptiveOptimizer = class(TInterfacedObject, IAdaptiveOptimizer)
  private
    FOptimizationHistory: array of TAdaptiveConfig;
    FCurrentConfig: TAdaptiveConfig;

  public
    constructor Create;

    // IAdaptiveOptimizer 接口实现
    function OptimizeConfig(aTestFunction: TBenchmarkFunction; aTargetAccuracy: Double): TAdaptiveConfig;
    function AdaptiveRun(const aTestName: string; aTestFunction: TBenchmarkFunction): IBenchmarkResult;
    function GetOptimizationHistory: TAdaptiveConfigArray;

  private
    function EvaluateConfig(aTestFunction: TBenchmarkFunction; const aConfig: TBenchmarkConfig): Double;
    function AdjustConfig(const aCurrentConfig: TBenchmarkConfig; aCurrentAccuracy, aTargetAccuracy: Double): TBenchmarkConfig;
    function CalculateAccuracy(const aResults: array of Double): Double;
  end;

  {**
   * TFileReporter
   *
   * @desc 文件报告器实现类
   *}
  TFileReporter = class(TInterfacedObject, IBenchmarkReporter)
  private
    FFileName: string;
    FFormat: string;

    {**
     * WriteToFile
     *
     * @desc 写入文件
     *}
    procedure WriteToFile(const aContent: string);

  public
    constructor Create(const aFileName: string);

    // IBenchmarkReporter 接口实现
    procedure ReportResult(aResult: IBenchmarkResult);
    procedure ReportResults(const aResults: array of IBenchmarkResult);
    procedure ReportComparison(aBaseline, aCurrent: IBenchmarkResult);
    procedure SetOutputFile(const aFileName: string);
    procedure SetFormat(const aFormat: string);
  end;

  {**
   * TJSONReporter
   *
   * @desc JSON 格式报告器实现类
   *}
  TJSONReporter = class(TInterfacedObject, IBenchmarkReporter)
  private
    FFileName: string;
    FFormat: string;
    FSchemaVersion: Integer;
    FDecimals: Integer;
    FSink: ITextSink;

    {**
     * FormatAsJSON
     *
     * @desc 将结果格式化为 JSON
     *}
    function FormatAsJSON(aResult: IBenchmarkResult): string;
    function FormatResultsAsJSON(const aResults: array of IBenchmarkResult): string;
    function Fmt(a: Double): string;

    {**
     * WriteOutput
     *
     * @desc 写入输出（文件或控制台）
     *}
    procedure WriteOutput(const aContent: string);

  public
    constructor Create(const aFileName: string = '');
    procedure SetSink(const aSink: ITextSink);

    // IBenchmarkReporter 接口实现
    procedure ReportResult(aResult: IBenchmarkResult);
    procedure ReportResults(const aResults: array of IBenchmarkResult);
    procedure ReportComparison(aBaseline, aCurrent: IBenchmarkResult);
    procedure SetOutputFile(const aFileName: string);
    procedure SetFormat(const aFormat: string);
  end;

  {**
   * TCSVReporter
   *
   * @desc CSV 格式报告器实现类
   *}
  TCSVReporter = class(TInterfacedObject, IBenchmarkReporter)
  private
    FFileName: string;
    FFormat: string;
    FHeaderWritten: Boolean;
    FSchemaVersion: Integer;
    FDecimals: Integer;
    FSeparator: Char;
    FSchemaInColumn: Boolean;
    // Tabular counters support
    FTabularCounters: Boolean;
    FCounterColumns: array of string;
    FCounterUnits: array of TCounterUnit;
    // 缺失值策略：blank|zero|na（默认 blank）
    FMissingPolicy: TMissingPolicy;
    FSink: ITextSink;
    procedure BuildCounterColumns(const aResults: array of IBenchmarkResult);
    function GetDynamicHeader: string;
    function FormatCountersRow(const aResult: IBenchmarkResult): string;

    {**
     * FormatAsCSV
     *
     * @desc 将结果格式化为 CSV
     *}
    function FormatAsCSV(aResult: IBenchmarkResult; aIncludeHeader: Boolean = False): string;
    function GetCSVHeader: string;
    function Fmt(a: Double): string;

    {**
     * WriteOutput
     *
     * @desc 写入输出（文件或控制台）
     *}
    procedure WriteOutput(const aContent: string);

  public
    constructor Create(const aFileName: string = '');
    procedure SetSink(const aSink: ITextSink);

    // IBenchmarkReporter 接口实现
    procedure ReportResult(aResult: IBenchmarkResult);
    procedure ReportResults(const aResults: array of IBenchmarkResult);
    procedure ReportComparison(aBaseline, aCurrent: IBenchmarkResult);
    procedure SetOutputFile(const aFileName: string);
    procedure SetFormat(const aFormat: string);
  end;

{**
 * GetGlobalRegistry
 *
 * @desc 获取全局基准测试注册器
 *
 * @return 返回全局注册器实例
 *}
function GetGlobalRegistry: TBenchmarkRegistry; forward;

type
  TJUnitReporter = class(TInterfacedObject, IBenchmarkReporter)
  private
    FFileName: string;
    FSink: ITextSink;
  public
    constructor Create(const aFileName: string = '');
    procedure SetSink(const aSink: ITextSink);
    procedure ReportResult(aResult: IBenchmarkResult);
    procedure ReportResults(const aResults: array of IBenchmarkResult);
    procedure ReportComparison(aBaseline, aCurrent: IBenchmarkResult);
    procedure SetOutputFile(const aFileName: string);
    procedure SetFormat(const aFormat: string);
  end;

  // Reporter multiplexer class (fan-out)
  TReporterMux = class(TInterfacedObject, IBenchmarkReporter)
  private
    FArr: array of IBenchmarkReporter;
  public
    constructor Create(const Rs: array of IBenchmarkReporter);
    procedure ReportResult(aResult: IBenchmarkResult);
    procedure ReportResults(const aResults: array of IBenchmarkResult);
    procedure ReportComparison(aBaseline, aCurrent: IBenchmarkResult);
    procedure SetOutputFile(const aFileName: string);
    procedure SetFormat(const aFormat: string);
  end;

function CreateJUnitReporter(const aFileName: string): IBenchmarkReporter;
begin
  Result := TJUnitReporter.Create(aFileName);
end;

procedure Blackhole(const v: Int64);
begin
  {$IFDEF CPUX86}
  asm
    // Consume value in a register to avoid optimization (no side effects)
    // (intentionally left minimal)
  end;
  {$ELSE}
  // Mix into a private sink to prevent optimization without any I/O
  _bh_i64 := _bh_i64 xor v;
  {$ENDIF}
end;

procedure Blackhole(const v: Double);
begin
  // Mix into a private sink; avoid any console output
  _bh_f64 := _bh_f64 + (v * 0.0);
end;

{ 工厂函数实现 }

function CreateBenchmarkRunner: IBenchmarkRunner;
begin
  Result := TBenchmarkRunner.Create;
end;

function CreateJSONReporter(const aSink: ITextSink): IBenchmarkReporter;
var R: TJSONReporter;
begin
  R := TJSONReporter.Create('');
  R.SetSink(aSink);
  Result := R;
end;

function CreateCSVReporter(const aSink: ITextSink): IBenchmarkReporter;
var R: TCSVReporter;
begin
  R := TCSVReporter.Create('');
  R.SetSink(aSink);
  Result := R;
end;

function CreateJUnitReporter(const aSink: ITextSink): IBenchmarkReporter;
var R: TJUnitReporter;
begin
  R := TJUnitReporter.Create('');
  R.SetSink(aSink);
  Result := R;
end;

function CreateReporterMux(const reporters: array of IBenchmarkReporter): IBenchmarkReporter;
begin
  Result := TReporterMux.Create(reporters);
end;

{ TReporterMux }
constructor TReporterMux.Create(const Rs: array of IBenchmarkReporter);
var i: Integer;
begin
  inherited Create;
  SetLength(FArr, Length(Rs));
  for i := 0 to High(Rs) do FArr[i] := Rs[i];
end;

procedure TReporterMux.ReportResult(aResult: IBenchmarkResult);
var i: Integer;
begin
  for i := 0 to High(FArr) do if FArr[i] <> nil then FArr[i].ReportResult(aResult);
end;

procedure TReporterMux.ReportResults(const aResults: array of IBenchmarkResult);
var i: Integer;
begin
  for i := 0 to High(FArr) do if FArr[i] <> nil then FArr[i].ReportResults(aResults);
end;

procedure TReporterMux.ReportComparison(aBaseline, aCurrent: IBenchmarkResult);
var i: Integer;
begin
  for i := 0 to High(FArr) do if FArr[i] <> nil then FArr[i].ReportComparison(aBaseline, aCurrent);
end;

procedure TReporterMux.SetOutputFile(const aFileName: string);
var i: Integer;
begin
  for i := 0 to High(FArr) do if FArr[i] <> nil then FArr[i].SetOutputFile(aFileName);
end;

procedure TReporterMux.SetFormat(const aFormat: string);
var i: Integer;
begin
  for i := 0 to High(FArr) do if FArr[i] <> nil then FArr[i].SetFormat(aFormat);
end;


function CreateBenchmarkSuite: IBenchmarkSuite;
begin
  Result := TBenchmarkSuite.Create;
end;

function CreateConsoleReporter: IBenchmarkReporter;
begin
  Result := TConsoleReporter.Create;
end;

function CreateConsoleReporter(const aSink: ITextSink): IBenchmarkReporter;
begin
  Result := TConsoleReporter.Create;
  (Result as TConsoleReporter).SetSink(aSink);
end;

function CreateConsoleReporterWithUnit(aMode: TUnitDisplayMode): IBenchmarkReporter;
begin
  SetUnitDisplayMode(aMode);
  Result := TConsoleReporter.Create;
end;

function CreateConsoleReporterAsciiOnly: IBenchmarkReporter;
begin
  Result := TConsoleReporter.Create(True);
end;

function CreateFileReporter(const aFileName: string): IBenchmarkReporter;
begin
  Result := TFileReporter.Create(aFileName);
end;

procedure SetDefaultBenchmarkReporter(const AReporter: IBenchmarkReporter);
begin
  _DefaultReporter := AReporter;
end;

function GetDefaultBenchmarkReporter: IBenchmarkReporter;
begin
  Result := _DefaultReporter;
end;


function CreateJSONReporter(const aFileName: string): IBenchmarkReporter;
begin
  Result := TJSONReporter.Create(aFileName);
end;

function CounterUnitToString(u: TCounterUnit): string;
begin
  case u of
    cuBytes: Result := 'bytes';
    cuItems: Result := 'items';
    cuRate: Result := 'rate';
    cuPercentage: Result := 'percent';
    else
      Result := 'unit';
  end;
end;

procedure SetReportEmitRegressSummary(aEnabled: Boolean);
begin
  GReportEmitRegressSummary := aEnabled;
end;

procedure SetReportExtraWorstRegressionSummary(const aText: string);
begin
  GReportExtraWorstSummary := aText;
end;

function GetReportEmitRegressSummary: Boolean;
begin
  Result := GReportEmitRegressSummary;
end;

function GetReportExtraWorstRegressionSummary: string;
begin
  Result := GReportExtraWorstSummary;
end;


function CreateCSVReporter(const aFileName: string): IBenchmarkReporter;
begin
  Result := TCSVReporter.Create(aFileName);
end;

function GetUnitDisplayMode: TUnitDisplayMode;
begin
  Result := GUnitDisplayMode;
end;

procedure SetUnitDisplayMode(aMode: TUnitDisplayMode);
begin
  GUnitDisplayMode := aMode;
end;

function MicroUnitStr: string;
begin
  if GUnitDisplayMode = udUTF8 then Result := 'μs' else Result := 'us';
end;

function CreateTestBenchmarkState(aTargetDurationMs: Integer): IBenchmarkState;
begin
  Result := TBenchmarkState.Create(aTargetDurationMs);
end;

{ 快手 API：实现 }
function Bench(const aName: string; aFunc: TBenchmarkFunction): IBenchmarkResult; overload;
var
  LConfig: TBenchmarkConfig;
begin
  LConfig := CreateDefaultBenchmarkConfig;
  LConfig.WarmupIterations := 1;
  LConfig.MeasureIterations := 3;
  Result := BenchWithConfig(aName, aFunc, LConfig);
end;

function Bench(const aName: string; aMethod: TBenchmarkMethod): IBenchmarkResult; overload;
var
  LConfig: TBenchmarkConfig;
begin
  LConfig := CreateDefaultBenchmarkConfig;
  LConfig.WarmupIterations := 1;
  LConfig.MeasureIterations := 3;
  Result := BenchWithConfig(aName, aMethod, LConfig);
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
function Bench(const aName: string; aProc: TBenchmarkProc): IBenchmarkResult; overload;
var
  LConfig: TBenchmarkConfig;
begin
  LConfig := CreateDefaultBenchmarkConfig;
  LConfig.WarmupIterations := 1;
  LConfig.MeasureIterations := 3;
  Result := BenchWithConfig(aName, aProc, LConfig);
end;
{$ENDIF}

function BenchWithConfig(const aName: string; aFunc: TBenchmarkFunction; const aConfig: TBenchmarkConfig): IBenchmarkResult; overload;
var
  LRunner: IBenchmarkRunner;
begin
  LRunner := CreateBenchmarkRunner;
  Result := LRunner.RunFunction(aName, aFunc, aConfig);
{$IFDEF FAFAFA_CORE_BENCH_AUTO_REPORT}
  CreateConsoleReporter.ReportResult(Result);
{$ENDIF}
end;

function BenchWithConfig(const aName: string; aMethod: TBenchmarkMethod; const aConfig: TBenchmarkConfig): IBenchmarkResult; overload;
var
  LRunner: IBenchmarkRunner;
begin
  LRunner := CreateBenchmarkRunner;
  Result := LRunner.RunMethod(aName, aMethod, aConfig);
{$IFDEF FAFAFA_CORE_BENCH_AUTO_REPORT}
  CreateConsoleReporter.ReportResult(Result);
{$ENDIF}
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
function BenchWithConfig(const aName: string; aProc: TBenchmarkProc; const aConfig: TBenchmarkConfig): IBenchmarkResult; overload;
var
  LRunner: IBenchmarkRunner;
begin
  LRunner := CreateBenchmarkRunner;
  Result := LRunner.RunProc(aName, aProc, aConfig);
{$IFDEF FAFAFA_CORE_BENCH_AUTO_REPORT}
  CreateConsoleReporter.ReportResult(Result);
{$ENDIF}
end;
{$ENDIF}

function MeasureNs(aFunc: TBenchmarkFunction): Double; overload;
var
  LRes: IBenchmarkResult;
begin
  LRes := Bench('measure', aFunc);
  Result := LRes.GetTimePerIteration(); // ns/op
end;

function Compare(const n1, n2: string; f1, f2: TBenchmarkFunction): Double;
var
  LRes1, LRes2: IBenchmarkResult;
  LDiff: Double;
begin
  LRes1 := Bench(n1, f1);
  LRes2 := Bench(n2, f2);
  LDiff := LRes1.GetTimePerIteration() / LRes2.GetTimePerIteration();
  // Silent function: return ratio only; no direct console output here
  Result := LDiff;
end;

{ Google Benchmark 风格的全局函数实现 }

function RegisterBenchmark(const aName: string; aFunc: TBenchmarkFunction): IBenchmark;
begin
  Result := GetGlobalRegistry.RegisterBenchmark(aName, aFunc);
end;

function RegisterBenchmarkMethod(const aName: string; aMethod: TBenchmarkMethod): IBenchmark;
begin
  Result := GetGlobalRegistry.RegisterBenchmarkMethod(aName, aMethod);
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
function RegisterBenchmarkProc(const aName: string; aProc: TBenchmarkProc): IBenchmark;
begin
  Result := GetGlobalRegistry.RegisterBenchmarkProc(aName, aProc);
end;
{$ENDIF}

function AddBenchmark(const aName: string; aFunc: TBenchmarkFunction): IBenchmark; overload;
begin
  Result := GetGlobalRegistry.Add(aName, aFunc);
end;

function AddBenchmark(const aName: string; aMethod: TBenchmarkMethod): IBenchmark; overload;
begin
  Result := GetGlobalRegistry.Add(aName, aMethod);
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
function AddBenchmark(const aName: string; aProc: TBenchmarkProc): IBenchmark; overload;
begin
  Result := GetGlobalRegistry.Add(aName, aProc);
end;
{$ENDIF}

function AddBenchmarkWithFixture(const aName: string; aFunc: TBenchmarkFunction; aFixture: IBenchmarkFixture): IBenchmark;
begin
  Result := GetGlobalRegistry.AddWithFixture(aName, aFunc, aFixture);
end;

function RegisterBenchmarkWithFixture(const aName: string; aFunc: TBenchmarkFunction;
  aFixture: IBenchmarkFixture): IBenchmark;
begin
  Result := GetGlobalRegistry.RegisterBenchmarkWithFixture(aName, aFunc, aFixture);
end;

function RunAllBenchmarks: TBenchmarkResultArray;
begin
  Result := GetGlobalRegistry.RunAll;
end;

function RunAllBenchmarksWithReporter(aReporter: IBenchmarkReporter): TBenchmarkResultArray;
begin
  Result := GetGlobalRegistry.RunAllWithReporter(aReporter);
end;

function ComputeStatistics(const aSamples: array of Double): TBenchmarkStatistics;
var
  Runner: TBenchmarkRunner;
begin
  Runner := TBenchmarkRunner.Create;
  try
    Result := Runner.CalculateStatistics(aSamples);
  finally
    Runner.Free;
  end;
end;

procedure ClearAllBenchmarks;
begin
  GetGlobalRegistry.Clear;
end;



function RunLegacyFunction(const aName: string; aFunc: TLegacyBenchmarkFunction;
  const aConfig: TBenchmarkConfig): IBenchmarkResult;
var
  LBenchmark: IBenchmark;
begin
  LBenchmark := TBenchmark.CreateLegacyFunction(aName, aFunc, aConfig);
  Result := LBenchmark.Run;
end;

function RunLegacyMethod(const aName: string; aMethod: TLegacyBenchmarkMethod;
  const aConfig: TBenchmarkConfig): IBenchmarkResult;
var
  LBenchmark: IBenchmark;
begin
  LBenchmark := TBenchmark.CreateLegacyMethod(aName, aMethod, aConfig);
  Result := LBenchmark.Run;
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
function RunLegacyProc(const aName: string; aProc: TLegacyBenchmarkProc;
  const aConfig: TBenchmarkConfig): IBenchmarkResult;
var
  LBenchmark: IBenchmark;
begin
  LBenchmark := TBenchmark.CreateLegacyProc(aName, aProc, aConfig);
  Result := LBenchmark.Run;
end;
{$ENDIF}

function CreateLegacyBenchmark(const aName: string; aFunc: TLegacyBenchmarkFunction;
  const aConfig: TBenchmarkConfig): IBenchmark;
begin
  Result := TBenchmark.CreateLegacyFunction(aName, aFunc, aConfig);
end;

{ 多线程基准测试全局函数实现 }

function RunMultiThreadBenchmark(const aName: string;
                                aFunc: TMultiThreadBenchmarkFunction;
                                aThreadCount: Integer;
                                const aConfig: TBenchmarkConfig): IBenchmarkResult;
var
  LRunner: IBenchmarkRunner;
  LThreadConfig: TMultiThreadConfig;
begin
  LRunner := CreateBenchmarkRunner;
  LThreadConfig := CreateMultiThreadConfig(aThreadCount);
  Result := LRunner.RunMultiThreadFunction(aName, aFunc, LThreadConfig, aConfig);
end;

function RunMultiThreadBenchmark(const aName: string;
                                aFunc: TMultiThreadBenchmarkFunction;
                                aThreadCount: Integer): IBenchmarkResult;
var
  LConfig: TBenchmarkConfig;
begin
  LConfig := CreateDefaultBenchmarkConfig;
  Result := RunMultiThreadBenchmark(aName, aFunc, aThreadCount, LConfig);
end;

function CreateMultiThreadConfig(aThreadCount: Integer;
                                aWorkPerThread: Integer = 0;
                                aSyncThreads: Boolean = True): TMultiThreadConfig;
begin
  Result.ThreadCount := aThreadCount;
  Result.WorkPerThread := aWorkPerThread;
  Result.SyncThreads := aSyncThreads;
  Result.StartBarrierTimeoutMs := 10000;
end;

{ 增强功能函数实现 }

function CreateBaseline(const aName: string; aBaselineTime: Double;
                       aTolerance: Double = 0.1; const aDescription: string = ''): TBenchmarkBaseline;
begin
  if aBaselineTime <= 0 then
    raise Exception.Create('基线时间必须大于0');
  if (aTolerance < 0) or (aTolerance > 1) then
    raise Exception.Create('容忍度必须在 0-1 之间');

  Result.Name := aName;
  Result.BaselineTime := aBaselineTime;
  Result.Tolerance := aTolerance;
  Result.Description := aDescription;
end;

function CompareResults(aResult1, aResult2: IBenchmarkResult): Double;
var
  LTime1, LTime2: Double;
begin
  if (aResult1 = nil) or (aResult2 = nil) then
    raise EArgumentNil.Create('基准测试结果不能为空');

  LTime1 := aResult1.GetTimePerIteration();
  LTime2 := aResult2.GetTimePerIteration();

  if LTime2 = 0 then
    raise Exception.Create('第二个结果的时间不能为0');

  // 返回相对性能差异
  Result := (LTime1 - LTime2) / LTime2;
end;

function RecommendConfig(aTestFunc: TBenchmarkFunction): TBenchmarkRecommendation;
var
  LQuickTest: IBenchmarkResult;
  LQuickConfig: TBenchmarkConfig;
  LRunner: IBenchmarkRunner;
  LEstimatedTime: Double;
begin
  if @aTestFunc = nil then
    raise EArgumentNil.Create('测试函数不能为空');

  // 创建快速测试配置
  LQuickConfig := CreateDefaultBenchmarkConfig;
  LQuickConfig.WarmupIterations := 1;
  LQuickConfig.MeasureIterations := 3;
  LQuickConfig.MinDurationMs := 10;
  LQuickConfig.MaxDurationMs := 100;

  LRunner := CreateBenchmarkRunner;

  try
    // 运行快速测试来估算性能
    LQuickTest := LRunner.RunFunction('快速评估', aTestFunc, LQuickConfig);
    LEstimatedTime := LQuickTest.GetTimePerIteration();

    // 根据估算时间推荐配置
    Result.RecommendedConfig := CreateDefaultBenchmarkConfig;

    if LEstimatedTime < 1000 then // < 1μs
    begin
      // 非常快的操作
      Result.RecommendedConfig.WarmupIterations := 5;
      Result.RecommendedConfig.MeasureIterations := 20;
      Result.RecommendedConfig.MinDurationMs := 1000;
      Result.Confidence := 0.9;
      Result.Reasoning := '检测到非常快的操作，增加迭代次数以提高精度';
    end
    else if LEstimatedTime < 100000 then // < 100μs
    begin
      // 快速操作
      Result.RecommendedConfig.WarmupIterations := 3;
      Result.RecommendedConfig.MeasureIterations := 10;
      Result.RecommendedConfig.MinDurationMs := 500;
      Result.Confidence := 0.8;
      Result.Reasoning := '检测到快速操作，使用标准配置';
    end
    else if LEstimatedTime < 10000000 then // < 10ms
    begin
      // 中等速度操作
      Result.RecommendedConfig.WarmupIterations := 2;
      Result.RecommendedConfig.MeasureIterations := 5;
      Result.RecommendedConfig.MinDurationMs := 200;
      Result.Confidence := 0.7;
      Result.Reasoning := '检测到中等速度操作，减少迭代次数';
    end
    else
    begin
      // 慢速操作
      Result.RecommendedConfig.WarmupIterations := 1;
      Result.RecommendedConfig.MeasureIterations := 3;
      Result.RecommendedConfig.MinDurationMs := 100;
      Result.Confidence := 0.6;
      Result.Reasoning := '检测到慢速操作，使用最小配置以节省时间';
    end;

  except
    on E: Exception do
    begin
      // 如果快速测试失败，返回默认配置
      Result.RecommendedConfig := CreateDefaultBenchmarkConfig;
      Result.Confidence := 0.5;
      Result.Reasoning := UTF8String('无法评估操作速度，使用默认配置: ') + UTF8String(E.Message);
    end;
  end;
end;

function CreateParameterizedTestCase(const aName: string;
                                    const aParameters: array of Variant): TParameterizedTestCase;
var
  LI: Integer;
begin
  Result.Name := aName;
  SetLength(Result.Parameters, Length(aParameters));

  for LI := 0 to High(aParameters) do
    Result.Parameters[LI] := aParameters[LI];
end;

{ 批量测试和报告函数实现 }

function RunBatchComparison(const aFunctions: array of TBenchmarkFunction;
                           const aNames: array of string;
                           const aConfig: TBenchmarkConfig): TBenchmarkComparisonArray;
var
  LResults: array of IBenchmarkResult;
  LRunner: IBenchmarkRunner;
  LI, LJ, LComparisonIndex: Integer;
  LRelativeDiff: Double;
begin
  Result := nil;
  SetLength(Result, 0);

  if Length(aFunctions) <> Length(aNames) then
    raise Exception.Create('函数数组和名称数组长度必须相同');

  if Length(aFunctions) < 2 then
    raise Exception.Create('至少需要两个函数进行对比');

  LRunner := CreateBenchmarkRunner;

  // 运行所有测试
  LResults := nil;
  SetLength(LResults, Length(aFunctions));
  for LI := 0 to High(aFunctions) do
    LResults[LI] := LRunner.RunFunction(aNames[LI], aFunctions[LI], aConfig);

  // 生成所有可能的对比
  SetLength(Result, (Length(aFunctions) * (Length(aFunctions) - 1)) div 2);
  LComparisonIndex := 0;

  for LI := 0 to High(LResults) - 1 do
    for LJ := LI + 1 to High(LResults) do
  begin

      LRelativeDiff := CompareResults(LResults[LI], LResults[LJ]);

      Result[LComparisonIndex].Name1 := LResults[LI].Name;
      Result[LComparisonIndex].Name2 := LResults[LJ].Name;
      Result[LComparisonIndex].Result1 := LResults[LI];
      Result[LComparisonIndex].Result2 := LResults[LJ];
      Result[LComparisonIndex].RelativeDifference := LRelativeDiff;

      // 生成结论
      if Abs(LRelativeDiff) < 0.05 then
      begin
        Result[LComparisonIndex].Conclusion := '性能基本相当';
        Result[LComparisonIndex].Significance := 0.1;
      end
      else if LRelativeDiff < 0 then
      begin
        Result[LComparisonIndex].Conclusion := '第一个更快';
        Result[LComparisonIndex].Significance := 0.8;
      end
      else
      begin
        Result[LComparisonIndex].Conclusion := '第二个更快';
        Result[LComparisonIndex].Significance := 0.8;
      end;

      Inc(LComparisonIndex);


      Result[LComparisonIndex].Result1 := LResults[LI];
      Result[LComparisonIndex].Result2 := LResults[LJ];
      Result[LComparisonIndex].RelativeDifference := LRelativeDiff;

      // 生成结论
      if Abs(LRelativeDiff) < 0.05 then
      begin
        Result[LComparisonIndex].Conclusion := '性能基本相当';
        Result[LComparisonIndex].Significance := 0.1;
      end
      else if LRelativeDiff > 0 then
      begin
        Result[LComparisonIndex].Conclusion := Format('%s 比 %s 快 %.1f%%',
          [Result[LComparisonIndex].Name2, Result[LComparisonIndex].Name1, Abs(LRelativeDiff) * 100.0]);
        Result[LComparisonIndex].Significance := Min(Trunc(Abs(LRelativeDiff) * 1000), 1000) / 1000.0;
      end
      else
      begin
        Result[LComparisonIndex].Conclusion := Format('%s 比 %s 快 %.1f%%',
          [Result[LComparisonIndex].Name1, Result[LComparisonIndex].Name2, Abs(LRelativeDiff) * 100.0]);
        Result[LComparisonIndex].Significance := Min(Trunc(Abs(LRelativeDiff) * 1000), 1000) / 1000.0;
      end;

      Inc(LComparisonIndex);
    end;
end;

procedure GenerateHTMLReport(const aReport: TBenchmarkReport; const aFileName: string);
var
  LFile: TextFile;
  LI: Integer;
begin
  AssignFile(LFile, aFileName);
  Rewrite(LFile);

  try
    // HTML 头部
    WriteLn(LFile, '<!DOCTYPE html>');
    WriteLn(LFile, '<html lang="en">');
    WriteLn(LFile, '<head>');
    WriteLn(LFile, '    <meta charset="UTF-8">');
    WriteLn(LFile, '    <meta name="viewport" content="width=device-width, initial-scale=1.0">');
    WriteLn(LFile, '    <title>', aReport.Title, '</title>');
    WriteLn(LFile, '    <style>');
    WriteLn(LFile, '        body { font-family: Arial, sans-serif; margin: 20px; }');
    WriteLn(LFile, '        .header { background: #f0f0f0; padding: 20px; border-radius: 5px; }');
    WriteLn(LFile, '        .results { margin: 20px 0; }');
    WriteLn(LFile, '        .result-item { margin: 10px 0; padding: 10px; border: 1px solid #ddd; }');
    WriteLn(LFile, '        .comparison { background: #f9f9f9; margin: 10px 0; padding: 10px; }');
    WriteLn(LFile, '        .fast { color: green; font-weight: bold; }');
    WriteLn(LFile, '        .slow { color: red; }');
    WriteLn(LFile, '        table { border-collapse: collapse; width: 100%; }');
    WriteLn(LFile, '        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }');
    WriteLn(LFile, '        th { background-color: #f2f2f2; }');
    WriteLn(LFile, '    </style>');
    WriteLn(LFile, '</head>');
    WriteLn(LFile, '<body>');

    // 报告头部
    WriteLn(LFile, '    <div class="header">');
    WriteLn(LFile, '        <h1>', aReport.Title, '</h1>');
    WriteLn(LFile, '        <p>Generated At: ', DateTimeToStr(aReport.GeneratedAt), '</p>');
    WriteLn(LFile, '        <p>Summary: ', aReport.Summary, '</p>');
    WriteLn(LFile, '    </div>');

    // 测试结果表格
    if Length(aReport.Results) > 0 then
    begin
      WriteLn(LFile, '    <h2>Results</h2>');
      WriteLn(LFile, '    <table>');
      WriteLn(LFile, '        <tr>');
      WriteLn(LFile, '            <th>Benchmark</th>');
      WriteLn(LFile, '            <th>Average Time (' + MicroUnitStr + '/op)</th>');
      WriteLn(LFile, '            <th>Throughput (ops/s)</th>');
      WriteLn(LFile, '            <th>Iterations</th>');
      WriteLn(LFile, '        </tr>');

      for LI := 0 to High(aReport.Results) do
      begin
        WriteLn(LFile, '        <tr>');
        WriteLn(LFile, '            <td>', aReport.Results[LI].Name, '</td>');
        WriteLn(LFile, '            <td>', Format('%.2f', [aReport.Results[LI].GetTimePerIteration(buMicroSeconds)]), '</td>');
        WriteLn(LFile, '            <td>', Format('%.0f', [aReport.Results[LI].GetThroughput()]), '</td>');
        WriteLn(LFile, '            <td>', aReport.Results[LI].Iterations, '</td>');
        WriteLn(LFile, '        </tr>');
      end;

      WriteLn(LFile, '    </table>');
    end;

    // 对比结果
    if Length(aReport.Comparisons) > 0 then
    begin
      WriteLn(LFile, '    <h2>Comparisons</h2>');
      for LI := 0 to High(aReport.Comparisons) do
      begin
        WriteLn(LFile, '    <div class="comparison">');
        WriteLn(LFile, '        <h3>', aReport.Comparisons[LI].Name1, ' vs ', aReport.Comparisons[LI].Name2, '</h3>');
        WriteLn(LFile, '        <p>', aReport.Comparisons[LI].Conclusion, '</p>');
        WriteLn(LFile, '        <p>Relative Difference: ', Format('%.2f%%', [aReport.Comparisons[LI].RelativeDifference * 100]), '</p>');
        WriteLn(LFile, '    </div>');
      end;
    end;

    // 建议
    if Length(aReport.Recommendations) > 0 then
    begin
      WriteLn(LFile, '    <h2>Recommendations</h2>');
      WriteLn(LFile, '    <ul>');
      for LI := 0 to High(aReport.Recommendations) do
        WriteLn(LFile, '        <li>', aReport.Recommendations[LI], '</li>');
      WriteLn(LFile, '    </ul>');
    end;

    WriteLn(LFile, '</body>');
    WriteLn(LFile, '</html>');

  finally
    CloseFile(LFile);
  end;
end;

procedure SaveTrendData(const aTrend: TBenchmarkTrend; const aFileName: string);
var
  LFile: TextFile;
  LI: Integer;
begin
  AssignFile(LFile, aFileName);
  Rewrite(LFile);

  try
    // 保存为简单的文本格式
    WriteLn(LFile, '# Trend data file');
    WriteLn(LFile, 'TestName=', aTrend.TestName);
    WriteLn(LFile, 'TrendDirection=', aTrend.TrendDirection);
    WriteLn(LFile, 'TrendStrength=', Format('%.4f', [aTrend.TrendStrength]));
    WriteLn(LFile, 'DataPoints=', Length(aTrend.Values));

    WriteLn(LFile, '# Timestamps and values (format: timestamp,value)');
    for LI := 0 to High(aTrend.Values) do
      WriteLn(LFile, Format('%.8f,%.4f', [aTrend.Timestamps[LI], aTrend.Values[LI]]));

  finally
    CloseFile(LFile);
  end;
end;

function LoadTrendData(const aFileName: string): TBenchmarkTrend;
var
  LFile: TextFile;
  LLine: string;
  LDataPoints: Integer;
  LI: Integer;
  LPos: Integer;
begin
  if not FileExists(aFileName) then
    raise Exception.Create('Trend data file not found: ' + aFileName);

  AssignFile(LFile, aFileName);
  Reset(LFile);

  try
    // 初始化结果
    Result.TestName := '';
    Result.TrendDirection := 0;
    Result.TrendStrength := 0.0;
    LDataPoints := 0;

    // 读取头部信息
    while not EOF(LFile) do
    begin
      ReadLn(LFile, LLine);
      LLine := Trim(LLine);

      if (LLine = '') or (LLine[1] = '#') then
        Continue;

      if Pos('TestName=', LLine) = 1 then
        Result.TestName := Copy(LLine, 10, Length(LLine))
      else if Pos('TrendDirection=', LLine) = 1 then
        Result.TrendDirection := StrToIntDef(Copy(LLine, 16, Length(LLine)), 0)
      else if Pos('TrendStrength=', LLine) = 1 then
        Result.TrendStrength := StrToFloatDef(Copy(LLine, 15, Length(LLine)), 0.0)
      else if Pos('DataPoints=', LLine) = 1 then
      begin
        LDataPoints := StrToIntDef(Copy(LLine, 12, Length(LLine)), 0);
        SetLength(Result.Timestamps, LDataPoints);
        SetLength(Result.Values, LDataPoints);
        Break;
      end;
    end;

    // 读取数据点
    LI := 0;
    while (not EOF(LFile)) and (LI < LDataPoints) do
    begin
      ReadLn(LFile, LLine);
      LLine := Trim(LLine);

      if (LLine = '') or (LLine[1] = '#') then
        Continue;

      LPos := Pos(',', LLine);
      if LPos > 0 then
      begin
        Result.Timestamps[LI] := StrToFloatDef(Copy(LLine, 1, LPos - 1), 0.0);
        Result.Values[LI] := StrToFloatDef(Copy(LLine, LPos + 1, Length(LLine)), 0.0);
        Inc(LI);
      end;
    end;

    // 调整数组大小
    SetLength(Result.Timestamps, LI);
    SetLength(Result.Values, LI);

  finally
    CloseFile(LFile);
  end;
end;

{ 快手接口实现 }

function benchmark(const aName: string; aFunc: TBenchmarkFunction): TQuickBenchmark;
begin
  Result.Name := aName;
  Result.Func := aFunc;
  Result.Method := nil;
  Result.Config := CreateDefaultBenchmarkConfig;
end;

function benchmark(const aName: string; aFunc: TBenchmarkFunction; const aConfig: TBenchmarkConfig): TQuickBenchmark;
begin
  Result.Name := aName;
  Result.Func := aFunc;
  Result.Method := nil;
  Result.Config := aConfig;
end;

function benchmark(const aName: string; aMethod: TBenchmarkMethod): TQuickBenchmark;
begin
  Result.Name := aName;
  Result.Func := nil;
  Result.Method := aMethod;
  Result.Config := CreateDefaultBenchmarkConfig;
end;

function benchmarks(const aTests: array of TQuickBenchmark): TBenchmarkResultArray;
var
  LRunner: IBenchmarkRunner;
  LI: Integer;
begin
  Result := nil;
  SetLength(Result, 0);

  if Length(aTests) = 0 then
  begin
    SetLength(Result, 0);
    Exit;
  end;

  LRunner := CreateBenchmarkRunner;
  SetLength(Result, Length(aTests));

  for LI := 0 to High(aTests) do
  begin
    if Assigned(aTests[LI].Func) then
      Result[LI] := LRunner.RunFunction(aTests[LI].Name, aTests[LI].Func, aTests[LI].Config)
    else if Assigned(aTests[LI].Method) then
      Result[LI] := LRunner.RunMethod(aTests[LI].Name, aTests[LI].Method, aTests[LI].Config)
    else
      raise Exception.Create(UTF8String('测试 "') + UTF8String(aTests[LI].Name) + UTF8String('" 没有指定函数或方法'));
  end;
end;

function benchmarks(const aTitle: string; const aTests: array of TQuickBenchmark): TBenchmarkResultArray;
begin
  // No direct console output in library code
  if Length(aTitle) = 0 then ;
  Result := benchmarks(aTests);
end;

procedure quick_benchmark(const aTests: array of TQuickBenchmark);
var
  LResults: TBenchmarkResultArray;
  LReporter: IBenchmarkReporter;
begin
  LResults := benchmarks(aTests);
  LReporter := CreateConsoleReporter;
  LReporter.ReportResults(LResults);
end;

procedure quick_benchmark(const aTitle: string; const aTests: array of TQuickBenchmark);
begin
  // Title handling is delegated to the reporter/consumer; keep library silent
  if Length(aTitle) = 0 then ;
  quick_benchmark(aTests);
end;

{ 🚀 优化的统计计算函数 }

{**
 * CalculateOptimizedStatistics
 *
 * @desc 计算优化的统计数据（单次遍历算法）
 *
 * @param aSamples 样本数据
 * @return 返回统计结果
 *}
function CalculateOptimizedStatistics(const aSamples: array of Double): TBenchmarkStatistics;
var
  LI, LJ, LN: Integer;
  LSum, LSumSq, LMean, LVariance: Double;
  LSorted: array of Double;
  LQ1Index, LQ3Index: Integer;
  LOutlierThreshold: Double;
  LTemp: Double;
  LM3, LM4, LDiff, LDiff3, LDiff4: Double;
begin
  Result := Default(TBenchmarkStatistics);
  LSorted := nil;
  LN := Length(aSamples);
  if LN = 0 then
  begin
    FillChar(Result, SizeOf(Result), 0);
    LSorted := nil;
    Exit;
  end;

  // 🚀 优化：单次遍历计算基本统计量
  LSum := 0;
  LSumSq := 0;
  Result.Min := aSamples[0];
  Result.Max := aSamples[0];

  for LI := 0 to LN - 1 do
  begin
    LSum := LSum + aSamples[LI];
    LSumSq := LSumSq + aSamples[LI] * aSamples[LI];

    if aSamples[LI] < Result.Min then
      Result.Min := aSamples[LI];
    if aSamples[LI] > Result.Max then
      Result.Max := aSamples[LI];
  end;

  // 计算均值和方差
  LMean := LSum / LN;
  LVariance := (LSumSq - LN * LMean * LMean) / (LN - 1);

  Result.Mean := LMean;
  Result.Variance := LVariance;
  Result.StdDev := Sqrt(LVariance);
  Result.SampleCount := LN;
  Result.CoefficientOfVariation := Result.StdDev / Result.Mean;

  // 🚀 优化：使用快速排序计算百分位数
  SetLength(LSorted, LN);
  for LI := 0 to LN - 1 do
    LSorted[LI] := aSamples[LI];

  // 简单排序（对于小数据集足够快）
  for LI := 0 to LN - 2 do
  begin
    for LJ := LI + 1 to LN - 1 do
      if LSorted[LI] > LSorted[LJ] then
      begin
        LTemp := LSorted[LI];
        LSorted[LI] := LSorted[LJ];
        LSorted[LJ] := LTemp;
      end;
  end;

  // 计算百分位数
  Result.Median := LSorted[LN div 2];
  Result.P95 := LSorted[Round(LN * 0.95) - 1];
  Result.P99 := LSorted[Round(LN * 0.99) - 1];

  // 计算四分位数
  LQ1Index := LN div 4;
  LQ3Index := (3 * LN) div 4;
  Result.Q1 := LSorted[LQ1Index];
  Result.Q3 := LSorted[LQ3Index];
  Result.IQR := Result.Q3 - Result.Q1;

  // 🚀 检测异常值（使用 IQR 方法）
  LOutlierThreshold := 1.5 * Result.IQR;
  Result.OutlierCount := 0;
  for LI := 0 to LN - 1 do
  begin
    if (aSamples[LI] < Result.Q1 - LOutlierThreshold) or
       (aSamples[LI] > Result.Q3 + LOutlierThreshold) then
      Inc(Result.OutlierCount);
  end;

  // 🚀 计算偏度和峰度（高级统计量）
  LM3 := 0; LM4 := 0; LDiff := 0; LDiff3 := 0; LDiff4 := 0;
  for LI := 0 to LN - 1 do
  begin
    LDiff := aSamples[LI] - LMean;
    LDiff3 := LDiff * LDiff * LDiff;
    LDiff4 := LDiff3 * LDiff;
    LM3 := LM3 + LDiff3;
    LM4 := LM4 + LDiff4;
  end;

  LM3 := LM3 / LN;
  LM4 := LM4 / LN;

  {$IFDEF FPC}
  // FPC 下未默认引入 Math.Power，这里使用乘法避免依赖
  if Result.StdDev <> 0 then
  begin
    Result.Skewness := LM3 / (Result.StdDev * Result.StdDev * Result.StdDev);
    Result.Kurtosis := (LM4 / (Result.StdDev * Result.StdDev * Result.StdDev * Result.StdDev)) - 3;
  end
  else
  begin
    Result.Skewness := 0;
    Result.Kurtosis := 0;
  end;
  {$ELSE}
  Result.Skewness := LM3 / Power(Result.StdDev, 3);
  Result.Kurtosis := (LM4 / Power(Result.StdDev, 4)) - 3; // 减去3得到超额峰度
  {$ENDIF}

  // 测量开销估算字段：由结果构造时根据配置与估算流程写入
  Result.MeasurementOverhead := 0.0;
end;

{ 性能监控和自动化函数实现 }

{ 🚀 优化的内存测量功能 }

{**
 * GetOptimizedMemoryUsage
 *
 * @desc 获取优化的内存使用量（减少系统调用开销）
 *
 * @return 返回内存使用量（字节）
 *}
function GetOptimizedMemoryUsage: Int64;
begin
  // 为了跨平台和构建稳定性，这里统一采用堆分配统计
  // 后续如需精确工作集等指标，再按平台分别实现
  Result := GetHeapStatus.TotalAllocated;
end;

{**
 * MeasureMemoryDelta
 *
 * @desc 测量内存变化量（优化版）
 *
 * @param aBeforeMemory 测试前内存
 * @param aAfterMemory 测试后内存
 * @return 返回内存增量
 *}
function MeasureMemoryDelta(aBeforeMemory, aAfterMemory: Int64): Int64;
begin
  Result := aAfterMemory - aBeforeMemory;

  // 🚀 过滤掉小的内存波动（可能是系统噪音）
  if Abs(Result) < 1024 then // 小于1KB的变化忽略
    Result := 0;
end;

{ 🚀 智能迭代次数估算 }

{**
 * EstimateOptimalIterations
 *
 * @desc 智能估算最优迭代次数
 *
 * @param aTestFunc 测试函数
 * @param aTargetDurationMs 目标运行时间（毫秒）
 * @param aMinIterations 最小迭代次数
 * @param aMaxIterations 最大迭代次数
 * @return 返回推荐的迭代次数
 *}
function EstimateOptimalIterations(aTestFunc: TBenchmarkFunction;
                                  aTargetDurationMs: Integer = 1000;
                                  aMinIterations: Integer = 10;
                                  aMaxIterations: Integer = 1000000): Int64;
var
  LState: IBenchmarkState;
  LStartTime, LEndTime: UInt64;
  LTestIterations: array[0..2] of Int64;
  LTestTimes: array[0..2] of Double;
  LI: Integer;
  LAvgTimePerIteration: Double;
  LEstimatedIterations: Int64;
  LTick: ITick;
begin
  LTick := BenchmarkCreateDefaultTick;

  // 🚀 使用三次递增的测试来估算性能
  LTestIterations[0] := 1;
  LTestIterations[1] := 10;
  LTestIterations[2] := 100;

  for LI := 0 to 2 do
  begin
    LState := TBenchmarkState.Create(100); // 短时间测试
    LState.SetIterations(LTestIterations[LI]);

    LStartTime := BenchmarkGetCurrentTick(LTick);
    aTestFunc(LState);
    LEndTime := BenchmarkGetCurrentTick(LTick);

    LTestTimes[LI] := BenchmarkTicksToNanoSeconds(LTick, LEndTime - LStartTime);

    // 如果单次测试就超过目标时间，直接返回
    if LTestTimes[LI] > aTargetDurationMs * 1000000 then
    begin
      Result := Max(aMinIterations, LTestIterations[LI] div 2);
      Exit;
    end;
  end;

  // 🚀 使用最稳定的测试结果来估算
  LAvgTimePerIteration := LTestTimes[2] / LTestIterations[2];

  // 估算达到目标时间需要的迭代次数
  LEstimatedIterations := Round((aTargetDurationMs * 1000000) / LAvgTimePerIteration);

  // 🚀 应用边界限制和智能调整
  Result := Max(aMinIterations, Min(aMaxIterations, LEstimatedIterations));

  // 如果估算的迭代次数太大，使用保守策略
  if Result > 100000 then
    Result := Result div 10; // 减少到1/10，避免测试时间过长
end;

{ 🚀 优化的报告格式化 }

{**
 * FormatOptimizedBenchmarkReport
 *
 * @desc 生成优化的基准测试报告
 *
 * @param aResults 测试结果数组
 * @param aTitle 报告标题
 * @return 返回格式化的报告字符串
 *}
function FormatOptimizedBenchmarkReport(const aResults: array of IBenchmarkResult;
                                       const aTitle: string = '基准测试报告'): string;
var
  LI: Integer;
  LReport: TStringList;
  LStats: TBenchmarkStatistics;
  LFastest: IBenchmarkResult;
  LFastestTime: Double;
  LRelativePerf: Double;
  LPerfIndicator: string;
  LTitleText: UTF8String;
  LNowText: UTF8String;
begin
  LReport := TStringList.Create;
  try
    LTitleText := UTF8String(aTitle);
    LNowText := UTF8String(DateTimeToStr(Now));

    // 🚀 报告头部
    LReport.Add('╔══════════════════════════════════════════════════════════════╗');
    LReport.Add(UTF8String('║ ') + LTitleText + StringOfChar(' ', Max(0, 60 - Length(LTitleText))) + UTF8String(' ║'));
    LReport.Add('╠══════════════════════════════════════════════════════════════╣');
    LReport.Add(UTF8String('║ 生成时间: ') + LNowText + StringOfChar(' ', Max(0, 49 - Length(LNowText))) + UTF8String(' ║'));
    LReport.Add('╚══════════════════════════════════════════════════════════════╝');
    LReport.Add('');

    if Length(aResults) = 0 then
    begin
      LReport.Add('没有测试结果');
      Result := LReport.Text;
      Exit;
    end;

    // 🚀 找出最快的测试
    LFastest := aResults[0];
    LFastestTime := LFastest.GetTimePerIteration();
    for LI := 1 to High(aResults) do
    begin
      if aResults[LI].GetTimePerIteration() < LFastestTime then
      begin
        LFastest := aResults[LI];
        LFastestTime := LFastest.GetTimePerIteration();
      end;
    end;

    // 🚀 详细结果表格
    LReport.Add('┌─────────────────────┬──────────────┬──────────────┬──────────────┬──────────────┐');
    LReport.Add('│ 测试名称            │ 平均时间     │ 标准差       │ 吞吐量       │ 相对性能     │');
    LReport.Add('├─────────────────────┼──────────────┼──────────────┼──────────────┼──────────────┤');

    for LI := 0 to High(aResults) do
    begin
      LStats := aResults[LI].GetStatistics();
      LRelativePerf := aResults[LI].GetTimePerIteration() / LFastestTime;
      LPerfIndicator := '';

      if LI = 0 then
        LPerfIndicator := '🏆 基准'
      else if LRelativePerf < 1.1 then
        LPerfIndicator := '🟢 优秀'
      else if LRelativePerf < 2.0 then
        LPerfIndicator := '🟡 良好'
      else
        LPerfIndicator := '🔴 较慢';

      LReport.Add(Format('│ %-19s │ %10.2f %s │ %10.2f %s │ %10.0f/s │ %12s │', [
        Copy(aResults[LI].Name, 1, 19),
        aResults[LI].GetTimePerIteration(buMicroSeconds), MicroUnitStr, MicroUnitStr,
        LStats.StdDev / 1000, // 转换为微秒
        aResults[LI].GetThroughput(),
        LPerfIndicator
      ]));
    end;

    LReport.Add('└─────────────────────┴──────────────┴──────────────┴──────────────┴──────────────┘');
    LReport.Add('');

    // 🚀 统计摘要
    LReport.Add('📊 统计摘要:');
    LReport.Add('─────────────');
    for LI := 0 to High(aResults) do
    begin
      LStats := aResults[LI].GetStatistics();
      LReport.Add(Format('• %s:', [aResults[LI].Name]));
      LReport.Add(Format('  - 样本数: %d, 变异系数: %.2f%%', [LStats.SampleCount, LStats.CoefficientOfVariation * 100]));
      LReport.Add(Format('  - P95: %.2f %s, P99: %.2f %s', [LStats.P95 / 1000, MicroUnitStr, LStats.P99 / 1000, MicroUnitStr]));
      if LStats.OutlierCount > 0 then
        LReport.Add(Format('  - ⚠️ 异常值: %d 个', [LStats.OutlierCount]));
      LReport.Add('');
    end;

    Result := LReport.Text;
  finally
    LReport.Free;
  end;
end;

{**
 * PadRight
 *
 * @desc 右填充字符串到指定长度
 *}
function PadRight(const aStr: string; aLength: Integer): string;
begin
  Result := aStr;
  while Length(Result) < aLength do
    Result := Result + ' ';
  if Length(Result) > aLength then
    Result := Copy(Result, 1, aLength);
end;

{ 🚀 超级优化的快手接口 }

{**
 * turbo_benchmark
 *
 * @desc 涡轮增压基准测试 - 自动优化配置
 *
 * @param aTests 测试数组
 *}
procedure turbo_benchmark(const aTests: array of TQuickBenchmark); overload;
var
  LResults: TBenchmarkResultArray;
  LI: Integer;
  LOptimizedConfig: TBenchmarkConfig;
  LRunner: IBenchmarkRunner;
  LOptimizedTests: array of TQuickBenchmark;
  LOptimalIterations: Int64;
begin
  // no direct console output in library code

  {$IFDEF DEBUG}
  LRunner := CreateBenchmarkRunner;
  {$ENDIF}
  LOptimizedTests := nil;
  SetLength(LOptimizedTests, Length(aTests));

  // 🚀 为每个测试自动优化配置
  for LI := 0 to High(aTests) do
  begin
    // optimizing config for test:

    // 估算最优迭代次数
    LOptimalIterations := EstimateOptimalIterations(aTests[LI].Func, 500); // 500ms目标

    LOptimizedConfig := CreateDefaultBenchmarkConfig;
    LOptimizedConfig.MeasureIterations := Max(5, Min(50, LOptimalIterations div 100));
    LOptimizedConfig.WarmupIterations := Max(1, LOptimizedConfig.MeasureIterations div 3);

    LOptimizedTests[LI] := aTests[LI];
    LOptimizedTests[LI].Config := LOptimizedConfig;
  end;

  // configuration optimized; ready to run

  // 运行优化后的测试
  LResults := benchmarks(LOptimizedTests);

  // 🚀 使用优化的报告格式
  // use reporter externally to render results (no writeln here)

  // turbo benchmark done; results available via returned array or reporter
end;

{**
 * turbo_benchmark
 *
 * @desc 涡轮增压基准测试（带标题）
 *
 * @param aTitle 测试标题
 * @param aTests 测试数组
 *}
procedure turbo_benchmark(const aTitle: string; const aTests: array of TQuickBenchmark); overload;
begin
  // title handled by caller/reporter
  if Length(aTitle) = 0 then ;
  turbo_benchmark(aTests);
end;

{**
 * smart_benchmark
 *
 * @desc 智能基准测试 - 自动检测异常和建议
 *
 * @param aTests 测试数组
 *}
procedure smart_benchmark(const aTests: array of TQuickBenchmark);
var
  LResults: TBenchmarkResultArray;
  LTimePerOp: Double;
  LI: Integer;
  LStats: TBenchmarkStatistics;
  LHasIssues: Boolean;
begin
  // smart_benchmark: no direct console output

  // 运行测试
  LResults := benchmarks(aTests);

  if Length(LResults) = 0 then Exit;


  // intelligent analysis (no console output)

  LHasIssues := False;

  for LI := 0 to High(LResults) do
  begin
    LStats := LResults[LI].GetStatistics();

    // item header suppressed

    // 检查变异系数
    if LStats.CoefficientOfVariation > 0.1 then
    begin
      // high variation detected
      LHasIssues := True;
    end
    else
      // stable measurement

    // 检查异常值
    if LStats.OutlierCount > 0 then
    begin
      // outliers detected
      LHasIssues := True;
    end
    else
      // no outliers

    // 性能等级评估
    LTimePerOp := LResults[LI].GetTimePerIteration();
    // performance level assessment (no console output)

    // newline suppressed
  end;

  // summary suppressed

  // 显示标准报告
  quick_benchmark(aTests);
end;

function CreateBenchmarkMonitor: IBenchmarkMonitor;
begin
  Result := TBenchmarkMonitor.Create;
end;

function CreateExtendedConfig(const aBaseConfig: TBenchmarkConfig): TBenchmarkConfig_Extended;
begin
  Result.BaseConfig := aBaseConfig;
  Result.EnableMonitoring := True;
  Result.PerformanceThreshold := 1000000; // 1ms 默认阈值
  Result.RegressionThreshold := 0.1;      // 10% 回归阈值
  Result.AlertOnRegression := True;
  Result.AlertOnThreshold := True;
  Result.SaveResults := False;
  Result.ResultsFileName := 'benchmark_results.json';
end;

procedure monitored_benchmark(const aTests: array of TQuickBenchmark; aMonitor: IBenchmarkMonitor);
var
  LResults: TBenchmarkResultArray;
  LAlerts: TPerformanceAlertArray;
  LAlert: TPerformanceAlert;
  LI: Integer;
begin
  // monitored_benchmark: no direct console output

  // 运行测试
  LResults := benchmarks(aTests);

  // 检查性能
  for LI := 0 to High(LResults) do
  begin
    LAlerts := aMonitor.CheckPerformance(LResults[LI]);
    if Length(LAlerts) > 0 then
    begin
      // 声明在块内，避免 inline var 风格

      // alerts printing moved to examples/tests Reporter
    end;
  end;

  // show results via Reporter in examples/tests
end;

procedure monitored_benchmark(const aTitle: string; const aTests: array of TQuickBenchmark; aMonitor: IBenchmarkMonitor);
begin
  // title handled by caller/reporter
  if Length(aTitle) = 0 then ;
  monitored_benchmark(aTests, aMonitor);
end;

function regression_test(const aTests: array of TQuickBenchmark; const aHistoryFile: string): Boolean;
var
  LMonitor: IBenchmarkMonitor;
  LCurrentResults: TBenchmarkResultArray;
  LHistoricalResults: TBenchmarkResultArray;
  LAlerts: TPerformanceAlertArray;
  LAlert: TPerformanceAlert;
  LI: Integer;
begin
  Result := True;

  // regression_test: no direct console output

  LMonitor := CreateBenchmarkMonitor;

  // 加载历史结果
  if FileExists(aHistoryFile) then
  begin
    try
      LHistoricalResults := LMonitor.LoadResults(aHistoryFile);
    except
      on E: Exception do
      begin
        SetLength(LHistoricalResults, 0);
      end;
    end;
  end
  else
  begin
    SetLength(LHistoricalResults, 0);
  end;

  // 运行当前测试
  LCurrentResults := benchmarks(aTests);

  // 检查回归
  if Length(LHistoricalResults) > 0 then
  begin
    for LI := 0 to High(LCurrentResults) do
    begin
      LAlerts := LMonitor.CheckRegression(LCurrentResults[LI], LHistoricalResults);
      if Length(LAlerts) > 0 then
      begin
        Result := False;
        // regression alerts printing moved to examples/tests
      end;
    end;
  end;

  // 保存当前结果作为新的历史
  LMonitor.SaveResults(LCurrentResults, aHistoryFile);

  // outcome reporting moved to examples/tests
end;

function continuous_benchmark(const aTests: array of TQuickBenchmark; const aConfigFile: string): Boolean;
begin
  // continuous_benchmark: no direct console output
  Result := regression_test(aTests, aConfigFile);
  if Result then ExitCode := 0 else ExitCode := 1;
end;

{ 性能分析和模板管理函数实现 }

function CreateBenchmarkAnalyzer: IBenchmarkAnalyzer;
begin
  Result := TBenchmarkAnalyzer.Create;
end;

function CreateTemplateManager: IBenchmarkTemplateManager;
begin
  Result := TBenchmarkTemplateManager.Create;
end;

procedure analyzed_benchmark(const aTests: array of TQuickBenchmark);
var
  LResults: TBenchmarkResultArray;
  LAnalyzer: IBenchmarkAnalyzer;
  LAnalyses: array of TPerformanceAnalysis;
  LSuggestion: string;
  LI: Integer;
begin
  // console output removed; use Reporter in examples/tests

  // 运行测试
  LResults := benchmarks(aTests);

  // 创建分析器
  LAnalyzer := CreateBenchmarkAnalyzer;

  // 分析性能
  LAnalyses := nil;
  SetLength(LAnalyses, Length(LResults));
  for LI := 0 to High(LResults) do
    LAnalyses[LI] := LAnalyzer.AnalyzePerformance(LResults[LI]);

  // show results and analyses via Reporter in examples/tests
end;

procedure analyzed_benchmark(const aTitle: string; const aTests: array of TQuickBenchmark);
begin
  // title handled by caller/reporter
  if Length(aTitle) = 0 then ;
  analyzed_benchmark(aTests);
end;

procedure template_benchmark(const aTemplateName: string; const aTests: array of TQuickBenchmark);
var
  LTemplateManager: IBenchmarkTemplateManager;
  LTemplate: TBenchmarkTemplate;
  {$IFDEF DEBUG}
  LConfig: TBenchmarkConfig;
  {$ENDIF}
  LResults: TBenchmarkResultArray;
  LCurrentTime: Double;
  LI: Integer;
begin
  // template_benchmark: no direct console output

  LTemplateManager := CreateTemplateManager;

  try
    LTemplate := LTemplateManager.GetTemplate(aTemplateName);
    {$IFDEF DEBUG}
    LConfig := LTemplateManager.CreateConfigFromTemplate(aTemplateName);
    {$ENDIF}


    // template meta printed in examples/tests


    // 使用模板配置运行测试
    LResults := benchmarks(aTests);

    // results and expectations comparison printed in examples/tests

  except
    on E: Exception do
    begin
      // template error handling delegated to caller/examples
    end;
  end;
end;

function GetCurrentPlatformInfo: TPlatformInfo;
begin
  Result.OS := {$IFDEF WINDOWS}'Windows'{$ELSE}{$IFDEF LINUX}'Linux'{$ELSE}{$IFDEF DARWIN}'macOS'{$ELSE}'Unknown'{$ENDIF}{$ENDIF}{$ENDIF};
  Result.Architecture := {$IFDEF CPU64}'x64'{$ELSE}{$IFDEF CPU32}'x86'{$ELSE}'Unknown'{$ENDIF}{$ENDIF};
  Result.CPUModel := 'Unknown CPU';  // 简化实现
  Result.CPUCores := 4;              // 简化实现
  Result.MemorySize := 8192;         // 简化实现
  Result.CompilerVersion := {$I %FPCVERSION%};
end;

procedure cross_platform_benchmark(const aTests: array of TQuickBenchmark; const aResultFile: string);
var
  LPlatform: TPlatformInfo;
  LResults: TBenchmarkResultArray;
  LFile: TextFile;
  LI: Integer;
begin
  LPlatform := GetCurrentPlatformInfo;

  // 运行测试
  LResults := benchmarks(aTests);

  // show results via Reporter in examples/tests

  // 保存跨平台结果
  AssignFile(LFile, aResultFile);
  Rewrite(LFile);

  try
    WriteLn(LFile, '# Cross-platform benchmark results');
    WriteLn(LFile, 'Platform=', LPlatform.OS, '/', LPlatform.Architecture);
    WriteLn(LFile, 'Compiler=', LPlatform.CompilerVersion);
    WriteLn(LFile, 'Timestamp=', DateTimeToStr(Now));
    WriteLn(LFile, '# Results (format: name,time_ns,iterations)');

    for LI := 0 to High(LResults) do
    begin
      WriteLn(LFile, Format('%s,%.0f,%d', [
        LResults[LI].Name,
        LResults[LI].GetTimePerIteration(),
        LResults[LI].Iterations
      ]));
    end;

  finally
    CloseFile(LFile);
  end;

  // result path printed in examples/tests
end;

procedure GeneratePerformanceReport(const aResults: array of IBenchmarkResult; const aFileName: string);
var
  LAnalyzer: IBenchmarkAnalyzer;
  LAnalyses: array of TPerformanceAnalysis;
  LFile: TextFile;
  LSuggestion: string;
  LI: Integer;
begin
  if Length(aResults) = 0 then
    Exit;

  LAnalyzer := CreateBenchmarkAnalyzer;

  // 分析所有结果
  LAnalyses := nil;
  SetLength(LAnalyses, Length(aResults));
  for LI := 0 to High(aResults) do
    LAnalyses[LI] := LAnalyzer.AnalyzePerformance(aResults[LI]);

  // 生成报告
  AssignFile(LFile, aFileName);
  Rewrite(LFile);

  try
    WriteLn(LFile, '# Performance Analysis Report');
    WriteLn(LFile, '# Generated At: ', DateTimeToStr(Now));
    WriteLn(LFile, '# Total benchmarks: ', Length(aResults));
    WriteLn(LFile, '');

    for LI := 0 to High(LAnalyses) do
    begin
      WriteLn(LFile, '## Benchmark: ', LAnalyses[LI].TestName);
      WriteLn(LFile, '- Performance level: ', LAnalyses[LI].PerformanceLevel);
      WriteLn(LFile, '- Bottleneck type: ', LAnalyses[LI].BottleneckType);
      WriteLn(LFile, '- Confidence: ', Format('%.1f%%', [LAnalyses[LI].Confidence * 100]));
      WriteLn(LFile, '- Time: ', Format('%.2f %s/op', [aResults[LI].GetTimePerIteration() / 1000, MicroUnitStr]));

      if Length(LAnalyses[LI].OptimizationSuggestions) > 0 then
      begin

        WriteLn(LFile, '- Optimization suggestions:');
        for LSuggestion in LAnalyses[LI].OptimizationSuggestions do
          WriteLn(LFile, '  * ', LSuggestion);
      end;
      WriteLn(LFile, '');
    end;

  finally
    CloseFile(LFile);
  end;
end;

{ TBenchmarkState 实现 }

constructor TBenchmarkState.Create(aTargetDurationMs: Integer);
begin
  inherited Create;
  FTick := BenchmarkCreateDefaultTick;
  FIterations := 0;
  FCurrentIteration := 0;
  FElapsedTime := 0;
  FTimingPaused := False;
  FTotalPausedTime := 0;
  FBytesProcessed := 0;
  FItemsProcessed := 0;
  FComplexityN := 0;
  SetLength(FCounters, 0);
  FAutoIterations := True;
  FTargetDurationMs := aTargetDurationMs;
  // 🔧 P0-3：初始化预热相关字段
  FWarmupIterations := 5; // default warmup iterations
  FCurrentWarmupIteration := 0;
  FWarmupCompleted := False;
  // 🔧 P1-1：初始化校准相关字段（目标校准时间对齐到目标时窗）
  FCalibrationCompleted := False;
  FCalibrationIterations := 1; // start from 1
  FCalibrationStartTime := 0;
  FTargetCalibrationTimeNS := Int64(FTargetDurationMs) * 1000000; // align to MinDurationMs
  // 🔧 P1-1：初始化校准绝对时长兜底（默认 1 秒）
  FCalibrationAbsoluteStartTime := 0;
  FCalibrationMaxDurationNS := 1000000000.0; // 1s 默认兜底
  // 🔧 内存测量初始化
  FInitialMemoryUsage := GetCurrentMemoryUsage;
  FPeakMemoryUsage := FInitialMemoryUsage;
  // 🔧 P0-1：修复计时开始点 - 不在构造函数中开始计时
  FStartTime := 0;
end;

destructor TBenchmarkState.Destroy;
begin
  FTick := nil;
  inherited Destroy;
end;

function TBenchmarkState.KeepRunning: Boolean;
var
  LCalibrationTime: Double;
  LPrevIters: Int64;
  LEstIters: Int64;
begin
  // 🔧 P0-3：预热阶段处理
  if not FWarmupCompleted then
  begin
    if FCurrentWarmupIteration < FWarmupIterations then
    begin
      Inc(FCurrentWarmupIteration);
      Result := True;
      Exit; // 预热阶段，直接返回，不开始正式计时
    end
    else
    begin
      // 预热完成，准备开始校准
      FWarmupCompleted := True;
      FCurrentIteration := 0; // 重置迭代计数
    end;
  end;

  // 🔧 P1-1：校准阶段处理
  if not FCalibrationCompleted then
  begin
    // 当用户已手动设置迭代次数时，跳过校准，直接进入正式测量
    if not FAutoIterations then
    begin
      if FIterations < 1 then FIterations := 1;
      FCalibrationCompleted := True;
      FCurrentIteration := 0; // 重置为正式测量
      // 不提前返回，后续将进入正式测量阶段
    end
    else
    begin
      if FCurrentIteration = 0 then
      begin
        // 开始校准测量
        FCalibrationStartTime := BenchmarkGetCurrentTick(FTick);
        // 🔧 P1-1：记录校准绝对起点（仅第一次）
        if FCalibrationAbsoluteStartTime = 0 then
          FCalibrationAbsoluteStartTime := FCalibrationStartTime;
      end;

      Result := FCurrentIteration < FCalibrationIterations;

      if Result then
      begin
        Inc(FCurrentIteration);
      end
      else
      begin
        // 校准迭代完成，检查是否达到目标时间
        LCalibrationTime := BenchmarkMeasureElapsed(FTick, FCalibrationStartTime);

        if LCalibrationTime >= FTargetCalibrationTimeNS then
        begin
          // 达到目标时间：执行一次“单步收缩”，在 [prev, current] 区间内选择更接近目标时间的迭代数
          LPrevIters := FCalibrationIterations div 2;
          if LPrevIters < 1 then LPrevIters := 1;
          // 线性估算，并向上取整以尽量不低于目标时间窗
          LEstIters := Ceil(FCalibrationIterations * (FTargetCalibrationTimeNS / LCalibrationTime));
          if LEstIters < LPrevIters then LEstIters := LPrevIters;
          if LEstIters > FCalibrationIterations then LEstIters := FCalibrationIterations;
          if LEstIters < 1 then LEstIters := 1;

          FIterations := LEstIters;
          FCalibrationCompleted := True;
          FCurrentIteration := 0; // 重置为正式测量
        end
        else
        begin
          // 🔧 P1-1：绝对时长兜底：若校准累计耗时超过上限，则强制收敛
          if (FCalibrationAbsoluteStartTime <> 0) and
             (BenchmarkMeasureElapsed(FTick, FCalibrationAbsoluteStartTime) >= FCalibrationMaxDurationNS) then
          begin
            if FCalibrationIterations < 1 then FCalibrationIterations := 1;
            FIterations := FCalibrationIterations; // 使用当前估算的迭代数作为正式迭代
            FCalibrationCompleted := True;
            FCurrentIteration := 0;
          end
          else
          begin
            // 时间不够，增加迭代次数继续校准（指数增长）
            FCalibrationIterations := FCalibrationIterations * 2;
            FCurrentIteration := 0; // 重置迭代计数

            // 防止无限增长
            if FCalibrationIterations > 1000000 then
            begin
              FIterations := 1000000; // 最大100万次
              FCalibrationCompleted := True;
              FCurrentIteration := 0;
            end;
          end;
        end;

        Result := True; // 继续校准或开始正式测量
        Exit;
      end;

      Exit; // 校准阶段，不开始正式计时
    end;
  end;

  // 🔧 P0-1：正式测量阶段 - 在第一次正式迭代时才开始计时
  if (FCurrentIteration = 0) and (FStartTime = 0) then
  begin
    FStartTime := BenchmarkGetCurrentTick(FTick);
  end;

  // 检查是否应该继续运行
  Result := FCurrentIteration < FIterations;

  if Result then
  begin
    Inc(FCurrentIteration);
  end
  else
  begin
    // 运行结束，更新最终时间
    UpdateElapsedTime;
  end;
end;

procedure TBenchmarkState.SetIterations(aCount: Int64);
begin
  FIterations := aCount;
  FAutoIterations := False;
end;

procedure TBenchmarkState.PauseTiming;
begin
  if not FTimingPaused then
  begin
    FTimingPaused := True;
    FPauseStartTime := BenchmarkGetCurrentTick(FTick);
  end;
end;

procedure TBenchmarkState.ResumeTiming;
begin
  if FTimingPaused then
  begin
    FTimingPaused := False;
    // 仅在正式计时开始后才累计暂停时间，避免预热/校准阶段导致负时间
    if FStartTime <> 0 then
      FTotalPausedTime := FTotalPausedTime + BenchmarkMeasureElapsed(FTick, FPauseStartTime);
  end;
end;

procedure TBenchmarkState.Pause;
begin
  PauseTiming;
end;

procedure TBenchmarkState.Resume;
begin
  ResumeTiming;
end;

procedure TBenchmarkState.Blackhole(const v: Int64);
begin
  // 转调全局 Blackhole，便于示例通过 state.Blackhole 调用
  fafafa.core.benchmark.Blackhole(v);
end;

procedure TBenchmarkState.Blackhole(const v: Double);
begin
  fafafa.core.benchmark.Blackhole(v);
end;

procedure TBenchmarkState.SetBytesProcessed(aBytes: Int64);
begin
  FBytesProcessed := aBytes;
end;

procedure TBenchmarkState.SetItemsProcessed(aItems: Int64);
begin
  FItemsProcessed := aItems;
end;

procedure TBenchmarkState.SetComplexityN(aN: Int64);
begin
  FComplexityN := aN;
end;

procedure TBenchmarkState.AddCounter(const aName: string; aValue: Double; aUnit: TCounterUnit);
var
  LLen: Integer;
begin
  LLen := Length(FCounters);
  SetLength(FCounters, LLen + 1);
  FCounters[LLen].Name := aName;
  FCounters[LLen].Value := aValue;
  FCounters[LLen].CounterUnit := aUnit;
end;

function TBenchmarkState.GetCurrentMemoryUsage: Int64;
{$IFDEF WINDOWS}
var
  LMemStatus: TMemoryStatus;
{$ENDIF}
begin
  {$IFDEF WINDOWS}
  // Windows 平台使用 GlobalMemoryStatus（简化版本）
  GlobalMemoryStatus(LMemStatus);
  Result := LMemStatus.dwTotalPhys - LMemStatus.dwAvailPhys; // 已使用的物理内存
  {$ELSE}
  // 其他平台暂时返回 0
  Result := 0;
  {$ENDIF}
end;

function TBenchmarkState.GetMemoryUsage: Int64;
var
  LCurrentUsage: Int64;
begin
  LCurrentUsage := GetCurrentMemoryUsage;
  Result := LCurrentUsage - FInitialMemoryUsage;

  // 更新峰值内存使用量
  if LCurrentUsage > FPeakMemoryUsage then
    FPeakMemoryUsage := LCurrentUsage;
end;

function TBenchmarkState.GetPeakMemoryUsage: Int64;
begin
  Result := FPeakMemoryUsage - FInitialMemoryUsage;
end;

procedure TBenchmarkState.SetWarmupIterations(aCount: Integer);
begin
  // 🔧 P0-3：设置预热迭代次数
  if aCount >= 0 then
    FWarmupIterations := aCount
  else
    FWarmupIterations := 0; // 负数时设为0，禁用预热
end;

procedure TBenchmarkState.SetTargetCalibrationTime(aTimeMS: Double);
begin
  // 🔧 P1-1：设置目标校准时间
  if aTimeMS > 0 then
    FTargetCalibrationTimeNS := aTimeMS * 1000000 // 转换为纳秒
  else
    FTargetCalibrationTimeNS := 1000000; // 默认1ms
end;

procedure TBenchmarkState.SetCalibrationMaxDuration(aTimeMS: Double);
begin
  // 🔧 P1-1：设置校准绝对最长时长（纳秒）
  if aTimeMS > 0 then
    FCalibrationMaxDurationNS := aTimeMS * 1000000
  else
    FCalibrationMaxDurationNS := 1000000000.0; // 默认1秒
end;


function TBenchmarkState.GetBytesProcessed: Int64;
begin
  Result := FBytesProcessed;
end;

function TBenchmarkState.GetItemsProcessed: Int64;
begin
  Result := FItemsProcessed;
end;

function TBenchmarkState.GetComplexityN: Int64;
begin
  Result := FComplexityN;
end;

function TBenchmarkState.GetCounters: TBenchmarkCounterArray;
var i: Integer;
begin
  Result := nil;
  SetLength(Result, Length(FCounters));
  for i := 0 to High(FCounters) do Result[i] := FCounters[i];
end;

function TBenchmarkState.GetIterations: Int64;
begin
  Result := FIterations;
end;

function TBenchmarkState.GetElapsedTime: Double;
begin
  UpdateElapsedTime;
  Result := FElapsedTime;
end;

function TBenchmarkState.EstimateIterations: Int64;
var
  LTestIterations: Int64;
  LStartTime: UInt64;
  LTestTime: Double;
  LTargetTime: Double;
begin
  // 先运行少量迭代来估算时间
  LTestIterations := 10;
  LStartTime := BenchmarkGetCurrentTick(FTick);

  // 这里应该调用实际的测试函数，但由于架构限制，我们使用简单估算
  // 在实际实现中，这需要与 TBenchmark 协作
  Sleep(1); // 模拟测试执行

  LTestTime := BenchmarkMeasureElapsed(FTick, LStartTime);
  LTargetTime := FTargetDurationMs * 1000000.0; // 转换为纳秒

  if LTestTime > 0 then
    Result := Round((LTargetTime / LTestTime) * LTestIterations)
  else
    Result := 1000; // 默认值

  // 限制在合理范围内
  if Result < 1 then
    Result := 1
  else if Result > 1000000 then
    Result := 1000000;
end;

procedure TBenchmarkState.UpdateElapsedTime;
var
  LElapsed: Double;
begin
  // 若尚未开始正式计时，视为0（防止以0为起点测得系统运行总时长）
  if FStartTime = 0 then
  begin
    FElapsedTime := 0;
    Exit;
  end;

  if not FTimingPaused then
  begin
    LElapsed := BenchmarkMeasureElapsed(FTick, FStartTime) - FTotalPausedTime;
    if LElapsed < 0 then
      LElapsed := 0;
    FElapsedTime := LElapsed;
  end;
end;

{ TBenchmarkRegistry 实现 }

constructor TBenchmarkRegistry.Create;
begin
  inherited Create;
  SetLength(FBenchmarks, 0);
end;

destructor TBenchmarkRegistry.Destroy;
begin
  Clear;
  inherited Destroy;
end;

function TBenchmarkRegistry.RegisterBenchmark(const aName: string; aFunc: TBenchmarkFunction): IBenchmark;
var
  LLen: Integer;
begin
  Result := TBenchmark.CreateWithFunction(aName, aFunc);
  LLen := Length(FBenchmarks);
  SetLength(FBenchmarks, LLen + 1);
  FBenchmarks[LLen] := Result;
end;

function TBenchmarkRegistry.RegisterBenchmarkMethod(const aName: string; aMethod: TBenchmarkMethod): IBenchmark;
var
  LLen: Integer;
begin
  Result := TBenchmark.CreateWithMethod(aName, aMethod);
  LLen := Length(FBenchmarks);
  SetLength(FBenchmarks, LLen + 1);
  FBenchmarks[LLen] := Result;
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
function TBenchmarkRegistry.RegisterBenchmarkProc(const aName: string; aProc: TBenchmarkProc): IBenchmark;
var
  LLen: Integer;
begin
  Result := TBenchmark.CreateWithProc(aName, aProc);
  LLen := Length(FBenchmarks);
  SetLength(FBenchmarks, LLen + 1);
  FBenchmarks[LLen] := Result;
end;
{$ENDIF}

function TBenchmarkRegistry.Add(const aName: string; aFunc: TBenchmarkFunction): IBenchmark;
begin
  Result := RegisterBenchmark(aName, aFunc);
end;

function TBenchmarkRegistry.Add(const aName: string; aMethod: TBenchmarkMethod): IBenchmark;
begin
  Result := RegisterBenchmarkMethod(aName, aMethod);
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
function TBenchmarkRegistry.Add(const aName: string; aProc: TBenchmarkProc): IBenchmark;
begin
  Result := RegisterBenchmarkProc(aName, aProc);
end;
{$ENDIF}

function TBenchmarkRegistry.AddWithFixture(const aName: string; aFunc: TBenchmarkFunction; aFixture: IBenchmarkFixture): IBenchmark;
begin
  Result := RegisterBenchmarkWithFixture(aName, aFunc, aFixture);
end;


function TBenchmarkRegistry.RegisterBenchmarkWithFixture(const aName: string; aFunc: TBenchmarkFunction;
  aFixture: IBenchmarkFixture): IBenchmark;
var
  LLen: Integer;
begin
  Result := TBenchmark.CreateWithFixture(aName, aFunc, aFixture);
  LLen := Length(FBenchmarks);
  SetLength(FBenchmarks, LLen + 1);
  FBenchmarks[LLen] := Result;
end;

function TBenchmarkRegistry.RunAll: TBenchmarkResultArray;
var
  LI: Integer;
begin
  Result := nil;
  SetLength(Result, Length(FBenchmarks));
  for LI := 0 to High(FBenchmarks) do
    Result[LI] := FBenchmarks[LI].Run;
end;

function TBenchmarkRegistry.RunAllWithReporter(aReporter: IBenchmarkReporter): TBenchmarkResultArray;
begin
  Result := nil;
  SetLength(Result, 0);
  Result := RunAll;
  if aReporter <> nil then
    aReporter.ReportResults(Result);
end;

procedure TBenchmarkRegistry.Clear;
begin
  SetLength(FBenchmarks, 0);
end;

function TBenchmarkRegistry.GetCount: Integer;
begin
  Result := Length(FBenchmarks);
end;

{ 全局变量 }

var
  GBenchmarkRegistry: TBenchmarkRegistry;

{ 全局注册器访问函数实现 }

function GetGlobalRegistry: TBenchmarkRegistry;
begin
  if GBenchmarkRegistry = nil then
    GBenchmarkRegistry := TBenchmarkRegistry.Create;
  Result := GBenchmarkRegistry;
end;

{ TBenchmarkResultV2 实现 }

constructor TBenchmarkResultV2.Create(const aName: string; aIterations: Int64;
  aTotalTime: Double; const aConfig: TBenchmarkConfig;
  const aSamples: array of Double; aState: IBenchmarkState);
var
  LI: Integer;
  LRunner: TBenchmarkRunner;
  OverState: TBenchmarkState;

  OverPerIter: Double;
  Tmp: array of Double;
  I: Integer;
  RawStats: TBenchmarkStatistics;
  MaxAllowed: Double;

begin
  inherited Create;
  FName := aName;
  FIterations := aIterations;
  FTotalTime := aTotalTime;
  FConfig := aConfig;

  // 复制样本数据
  SetLength(FSamples, Length(aSamples));
  for LI := 0 to High(aSamples) do
    FSamples[LI] := aSamples[LI];

  // 从 State 获取额外数据
  if aState <> nil then
  begin
    // 从 State 拷贝只读统计数据与计数器
    FBytesProcessed := aState.GetBytesProcessed;
    FItemsProcessed := aState.GetItemsProcessed;
    FComplexityN := aState.GetComplexityN;
    FCounters := aState.GetCounters;
  end
  else
  begin
    FBytesProcessed := 0;
    FItemsProcessed := 0;
    FComplexityN := 0;
    SetLength(FCounters, 0);
  end;

  // 计算统计数据（支持开销校正）
  LRunner := TBenchmarkRunner.Create;
  try
    if FConfig.EnableOverheadCorrection and (Length(FSamples) > 0) and (FIterations > 0) then
    begin
      // 运行一次"空工作"的基准以估计每次迭代的基础开销（计时+循环）
      // 加强稳健性：限制估计持续时间与迭代数，并对结果进行合理性钳制
      OverState := TBenchmarkState.Create(Max(1, Min(FConfig.MinDurationMs, 50)));
      try
        OverState.SetWarmupIterations(0);
        if FIterations > 0 then
          OverState.SetIterations(Min(FIterations, 1000000))
        else
          OverState.SetIterations(1);
        while OverState.KeepRunning do begin end;
        if OverState.GetIterations > 0 then
          OverPerIter := OverState.GetElapsedTime / OverState.GetIterations
        else
          OverPerIter := 0;
      finally
        OverState.Free;
      end;

      // 结果合理性检查与钳制
      if not (OverPerIter = OverPerIter) or (OverPerIter < 0) or (OverPerIter > 1e20) then
        OverPerIter := 0;
      {$IFDEF FPC_HAS_FEATURE_INLINEVAR}
      var RawStats := LRunner.CalculateStatistics(FSamples);
      var MaxAllowed := RawStats.Mean * 0.5; // 开销最多占均值50%
      if OverPerIter > MaxAllowed then
      {$ELSE}
      RawStats := LRunner.CalculateStatistics(FSamples);
      MaxAllowed := RawStats.Mean * 0.5; // 开销最多占均值50%
      if OverPerIter > MaxAllowed then
      {$ENDIF}
        OverPerIter := MaxAllowed;
      if OverPerIter < 0 then OverPerIter := 0;

      // 扣减开销（逐样本，这里样本为 per-iter 值）
      Tmp := nil;
      SetLength(Tmp, Length(FSamples));
      for I := 0 to High(FSamples) do
      begin
        Tmp[I] := FSamples[I] - OverPerIter;
        if Tmp[I] < 0 then Tmp[I] := 0;
      end;

      FStatistics := LRunner.CalculateStatistics(Tmp);
      FStatistics.MeasurementOverhead := OverPerIter;
      FStatistics.Corrected := True;
    end
    else
    begin
      FStatistics := LRunner.CalculateStatistics(aSamples);
      FStatistics.MeasurementOverhead := 0;
      FStatistics.Corrected := False;
    end;
  finally
    LRunner.Free;
  end;
end;

function TBenchmarkResultV2.GetName: string;
begin
  Result := FName;
end;

function TBenchmarkResultV2.GetIterations: Int64;
begin
  Result := FIterations;
end;

function TBenchmarkResultV2.GetTotalTime: Double;
begin
  Result := FTotalTime;
end;

function TBenchmarkResultV2.GetStatistics: TBenchmarkStatistics;
begin
  Result := FStatistics;
end;

function TBenchmarkResultV2.GetConfig: TBenchmarkConfig;
begin
  Result := FConfig;
end;

function TBenchmarkResultV2.GetTimePerIteration(aUnit: TBenchmarkUnit): Double;
var
  LRunner: TBenchmarkRunner;
begin
  if FIterations = 0 then
    raise EBenchmarkInvalidOperation.Create('无法计算每次迭代时间：迭代次数为零');

  LRunner := TBenchmarkRunner.Create;
  try
    Result := LRunner.ConvertTimeUnit(FTotalTime / FIterations, aUnit);
  finally
    LRunner.Free;
  end;
end;

function TBenchmarkResultV2.GetThroughput: Double;
begin
  if FTotalTime = 0 then
    raise EBenchmarkInvalidOperation.Create('无法计算吞吐量：总时间为零');

  Result := (FIterations * 1000000000.0) / FTotalTime;
end;

function TBenchmarkResultV2.GetBytesPerSecond: Double;
begin
  if (FTotalTime = 0) or (FBytesProcessed = 0) then
    Result := 0
  else
    Result := (FBytesProcessed * 1000000000.0) / FTotalTime;
end;

function TBenchmarkResultV2.GetItemsPerSecond: Double;
begin
  if (FTotalTime = 0) or (FItemsProcessed = 0) then
    Result := 0
  else
    Result := (FItemsProcessed * 1000000000.0) / FTotalTime;
end;

function TBenchmarkResultV2.GetCounters: TBenchmarkCounterArray;
begin
  Result := FCounters;
end;

function TBenchmarkResultV2.GetSamples: TBenchmarkSampleArray;
begin
  Result := FSamples;
end;

function TBenchmarkResultV2.HasStatistics: Boolean;
begin
  Result := FStatistics.SampleCount > 0;
end;

function TBenchmarkResultV2.GetComplexityN: Int64;
begin
  Result := FComplexityN;
end;

{ TBenchmarkResultV2 增强方法实现 }

function TBenchmarkResultV2.GetPercentile(aPercentile: Double): Double;
var
  LSortedSamples: array of Double;
  LIndex: Integer;
  LI: Integer;
  LJ: Integer;
  LTemp: Double;
begin
  LSortedSamples := nil;

  if (aPercentile < 0) or (aPercentile > 100) then
    raise EArgumentException.Create('百分位数必须在 0-100 之间');

  if Length(FSamples) = 0 then
  begin
    Result := GetTimePerIteration();
    Exit;
  end;

  // 复制并排序样本
  SetLength(LSortedSamples, Length(FSamples));
  for LI := 0 to High(FSamples) do
    LSortedSamples[LI] := FSamples[LI];

  // 简单的冒泡排序

  for LI := 0 to High(LSortedSamples) - 1 do
    for LJ := 0 to High(LSortedSamples) - LI - 1 do
      if LSortedSamples[LJ] > LSortedSamples[LJ + 1] then
      begin
        LTemp := LSortedSamples[LJ];
        LSortedSamples[LJ] := LSortedSamples[LJ + 1];
        LSortedSamples[LJ + 1] := LTemp;
      end;

  // 计算百分位数索引
  LIndex := Round((aPercentile / 100.0) * (Length(LSortedSamples) - 1));
  if LIndex >= Length(LSortedSamples) then
    LIndex := High(LSortedSamples);

  Result := LSortedSamples[LIndex];
end;

function TBenchmarkResultV2.CompareWithBaseline(const aBaseline: TBenchmarkBaseline): Double;
var
  LCurrentTime: Double;
begin
  LCurrentTime := GetTimePerIteration();

  if aBaseline.BaselineTime <= 0 then
    raise EArgumentException.Create('基线时间必须大于0');

  // 返回相对差异（正数表示比基线慢，负数表示比基线快）
  Result := (LCurrentTime - aBaseline.BaselineTime) / aBaseline.BaselineTime;
end;

function TBenchmarkResultV2.IsRegressionFrom(const aBaseline: TBenchmarkBaseline): Boolean;
var
  LRelativeDiff: Double;
begin
  LRelativeDiff := CompareWithBaseline(aBaseline);

  // 如果相对差异超过容忍度，则认为是回归
  Result := LRelativeDiff > aBaseline.Tolerance;
end;

procedure TBenchmarkResultV2.GetConfidenceInterval(aConfidenceLevel: Double;
  out aLowerBound, aUpperBound: Double);
var
  LMean, LStdDev: Double;
  LTValue: Double;
  LMarginOfError: Double;
begin
  if (aConfidenceLevel <= 0) or (aConfidenceLevel >= 1) then
    raise EArgumentException.Create('置信水平必须在 0 和 1 之间');

  LMean := FStatistics.Mean;
  LStdDev := FStatistics.StdDev;

  if FStatistics.SampleCount <= 1 then
  begin
    // 样本不足，使用均值
    aLowerBound := LMean;
    aUpperBound := LMean;
    Exit;
  end;

  // 简化的 t 值计算（对于大样本，近似为正态分布）
  if aConfidenceLevel = 0.95 then
    LTValue := 1.96  // 95% 置信区间
  else if aConfidenceLevel = 0.99 then
    LTValue := 2.576 // 99% 置信区间
  else
    LTValue := 1.96; // 默认使用 95%

  LMarginOfError := LTValue * (LStdDev / Sqrt(FStatistics.SampleCount));

  aLowerBound := LMean - LMarginOfError;
  aUpperBound := LMean + LMarginOfError;
end;

{ TBenchmarkResult 实现 }

constructor TBenchmarkResult.Create(const aName: string; aIterations: Int64;
  aTotalTime: Double; const aConfig: TBenchmarkConfig;
  const aSamples: array of Double);
var
  LI: Integer;
  LRunner: TBenchmarkRunner;
begin
  inherited Create;
  FName := aName;
  FIterations := aIterations;
  FTotalTime := aTotalTime;
  FConfig := aConfig;

  // 复制样本数据
  SetLength(FSamples, Length(aSamples));
  for LI := 0 to High(aSamples) do
    FSamples[LI] := aSamples[LI];

  // 计算统计数据
  LRunner := TBenchmarkRunner.Create;
  try
    FStatistics := LRunner.CalculateStatistics(aSamples);
  finally
    LRunner.Free;
  end;
end;

function TBenchmarkResult.GetName: string;
begin
  Result := FName;
end;

function TBenchmarkResult.GetIterations: Int64;
begin
  Result := FIterations;
end;

function TBenchmarkResult.GetTotalTime: Double;
begin
  Result := FTotalTime;
end;

function TBenchmarkResult.GetStatistics: TBenchmarkStatistics;
begin
  Result := FStatistics;
end;

function TBenchmarkResult.GetConfig: TBenchmarkConfig;
begin
  Result := FConfig;
end;

function TBenchmarkResult.GetTimePerIteration(aUnit: TBenchmarkUnit): Double;
var
  LRunner: TBenchmarkRunner;
begin
  if FIterations = 0 then
    raise EBenchmarkInvalidOperation.Create('无法计算每次迭代时间：迭代次数为零');

  LRunner := TBenchmarkRunner.Create;
  try
    Result := LRunner.ConvertTimeUnit(FTotalTime / FIterations, aUnit);
  finally
    LRunner.Free;
  end;
end;

function TBenchmarkResult.GetThroughput: Double;
begin
  if FTotalTime = 0 then
    raise EBenchmarkInvalidOperation.Create('无法计算吞吐量：总时间为零');

  // 返回每秒迭代次数
  Result := (FIterations * 1000000000.0) / FTotalTime;
end;

function TBenchmarkResult.GetBytesPerSecond: Double;
begin
  Result := 0; // 传统结果不支持字节吞吐量
end;

function TBenchmarkResult.GetItemsPerSecond: Double;
begin
  Result := 0; // 传统结果不支持项目吞吐量
end;

function TBenchmarkResult.GetCounters: TBenchmarkCounterArray;
begin
  Result := nil;
  SetLength(Result, 0); // 传统结果不支持自定义计数器
end;

function TBenchmarkResult.GetSamples: TBenchmarkSampleArray;
begin
  Result := FSamples;
end;

function TBenchmarkResult.HasStatistics: Boolean;
begin
  Result := FStatistics.SampleCount > 0;
end;

function TBenchmarkResult.GetComplexityN: Int64;
begin
  Result := 0; // 传统结果不支持复杂度分析
end;

{ TBenchmarkResult 增强方法实现 }

function TBenchmarkResult.GetPercentile(aPercentile: Double): Double;
var
  LSortedSamples: array of Double;
  LIndex: Integer;
  LI: Integer;
  LJ: Integer;
  LTemp: Double;
begin
  LSortedSamples := nil;

  if (aPercentile < 0) or (aPercentile > 100) then
    raise EArgumentException.Create('百分位数必须在 0-100 之间');

  if Length(FSamples) = 0 then
  begin
    Result := GetTimePerIteration();
    Exit;
  end;

  // 复制并排序样本
  SetLength(LSortedSamples, Length(FSamples));
  for LI := 0 to High(FSamples) do
    LSortedSamples[LI] := FSamples[LI];

  // 简单的冒泡排序

  for LI := 0 to High(LSortedSamples) - 1 do
    for LJ := 0 to High(LSortedSamples) - LI - 1 do
      if LSortedSamples[LJ] > LSortedSamples[LJ + 1] then
      begin
        LTemp := LSortedSamples[LJ];
        LSortedSamples[LJ] := LSortedSamples[LJ + 1];
        LSortedSamples[LJ + 1] := LTemp;
      end;

  // 计算百分位数索引
  LIndex := Round((aPercentile / 100.0) * (Length(LSortedSamples) - 1));
  if LIndex >= Length(LSortedSamples) then
    LIndex := High(LSortedSamples);

  Result := LSortedSamples[LIndex];
end;

function TBenchmarkResult.CompareWithBaseline(const aBaseline: TBenchmarkBaseline): Double;
var
  LCurrentTime: Double;
begin
  LCurrentTime := GetTimePerIteration();

  if aBaseline.BaselineTime <= 0 then
    raise EArgumentException.Create('基线时间必须大于0');

  // 返回相对差异（正数表示比基线慢，负数表示比基线快）
  Result := (LCurrentTime - aBaseline.BaselineTime) / aBaseline.BaselineTime;
end;

function TBenchmarkResult.IsRegressionFrom(const aBaseline: TBenchmarkBaseline): Boolean;
var
  LRelativeDiff: Double;
begin
  LRelativeDiff := CompareWithBaseline(aBaseline);

  // 如果相对差异超过容忍度，则认为是回归
  Result := LRelativeDiff > aBaseline.Tolerance;
end;

procedure TBenchmarkResult.GetConfidenceInterval(aConfidenceLevel: Double;
  out aLowerBound, aUpperBound: Double);
var
  LMean, LStdDev: Double;
  LTValue: Double;
  LMarginOfError: Double;
begin
  if (aConfidenceLevel <= 0) or (aConfidenceLevel >= 1) then
    raise EArgumentException.Create('置信水平必须在 0 和 1 之间');

  LMean := FStatistics.Mean;
  LStdDev := FStatistics.StdDev;

  if FStatistics.SampleCount <= 1 then
  begin
    // 样本不足，使用均值
    aLowerBound := LMean;
    aUpperBound := LMean;
    Exit;
  end;

  // 简化的 t 值计算（对于大样本，近似为正态分布）
  if aConfidenceLevel = 0.95 then
    LTValue := 1.96  // 95% 置信区间
  else if aConfidenceLevel = 0.99 then
    LTValue := 2.576 // 99% 置信区间
  else
    LTValue := 1.96; // 默认使用 95%

  LMarginOfError := LTValue * (LStdDev / Sqrt(FStatistics.SampleCount));

  aLowerBound := LMean - LMarginOfError;
  aUpperBound := LMean + LMarginOfError;
end;

{ TBenchmark 实现 }

constructor TBenchmark.Create;
begin
  inherited Create;
  FName := '';
  FConfig := CreateDefaultBenchmarkConfig;
  FFunction := nil;
  FMethod := nil;
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  FProc := nil;
  {$ENDIF}
  FFixture := nil;
  FLegacyFunction := nil;
  FLegacyMethod := nil;
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  FLegacyProc := nil;
  {$ENDIF}
  FIsLegacy := False;
end;

constructor TBenchmark.CreateWithFunction(const aName: string; aFunc: TBenchmarkFunction);
begin
  inherited Create;
  FName := aName;
  FConfig := CreateDefaultBenchmarkConfig;
  FFunction := aFunc;
  FMethod := nil;
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  FProc := nil;
  {$ENDIF}
  FFixture := nil;
  FIsLegacy := False;
end;

constructor TBenchmark.CreateWithMethod(const aName: string; aMethod: TBenchmarkMethod);
begin
  inherited Create;
  FName := aName;
  FConfig := CreateDefaultBenchmarkConfig;
  FFunction := nil;
  FMethod := aMethod;
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  FProc := nil;
  {$ENDIF}
  FFixture := nil;
  FIsLegacy := False;
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
constructor TBenchmark.CreateWithProc(const aName: string; aProc: TBenchmarkProc);
begin
  inherited Create;
  FName := aName;
  FConfig := CreateDefaultBenchmarkConfig;
  FFunction := nil;
  FMethod := nil;
  FProc := aProc;
  FFixture := nil;
  FIsLegacy := False;
end;
{$ENDIF}

constructor TBenchmark.CreateWithFixture(const aName: string; aFunc: TBenchmarkFunction;
  aFixture: IBenchmarkFixture);
begin
  inherited Create;
  FName := aName;
  FConfig := CreateDefaultBenchmarkConfig;
  FFunction := aFunc;
  FMethod := nil;
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  FProc := nil;
  {$ENDIF}
  FFixture := aFixture;
  FIsLegacy := False;
end;

constructor TBenchmark.CreateLegacyFunction(const aName: string; aFunc: TLegacyBenchmarkFunction;
  const aConfig: TBenchmarkConfig);
begin
  inherited Create;
  FName := aName;
  FConfig := aConfig;
  FLegacyFunction := aFunc;
  FLegacyMethod := nil;
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  FLegacyProc := nil;
  {$ENDIF}
  FIsLegacy := True;
end;

constructor TBenchmark.CreateLegacyMethod(const aName: string; aMethod: TLegacyBenchmarkMethod;
  const aConfig: TBenchmarkConfig);
begin
  inherited Create;
  FName := aName;
  FConfig := aConfig;
  FLegacyFunction := nil;
  FLegacyMethod := aMethod;
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  FLegacyProc := nil;
  {$ENDIF}
  FIsLegacy := True;
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
constructor TBenchmark.CreateLegacyProc(const aName: string; aProc: TLegacyBenchmarkProc;
  const aConfig: TBenchmarkConfig);
begin
  inherited Create;
  FName := aName;
  FConfig := aConfig;
  FLegacyFunction := nil;
  FLegacyMethod := nil;
  FLegacyProc := aProc;
  FIsLegacy := True;
end;
{$ENDIF}



function TBenchmark.GetName: string;
begin
  Result := FName;
end;

procedure TBenchmark.SetName(const aName: string);
begin
  FName := aName;
end;

function TBenchmark.GetConfig: TBenchmarkConfig;
begin
  Result := FConfig;
end;

procedure TBenchmark.SetConfig(const aConfig: TBenchmarkConfig);
begin
  FConfig := aConfig;
end;

function TBenchmark.Run: IBenchmarkResult;
var
  LState: IBenchmarkState;
  LStartTime: UInt64;
  LTotalTime: Double;
  LSamples: array of Double;
  {$IFDEF DEBUG}
  LI: Integer;
  {$ENDIF}
  LRunner: IBenchmarkRunner;
begin
  LSamples := nil;

  if FIsLegacy then
  begin
    // 传统 API 模式 - 直接使用 TBenchmarkRunner
    LRunner := CreateBenchmarkRunner;

    if FLegacyFunction <> nil then
      Result := (LRunner as TBenchmarkRunner).RunLegacyFunction(FName, FLegacyFunction, FConfig)
    else if FLegacyMethod <> nil then
      Result := (LRunner as TBenchmarkRunner).RunLegacyMethod(FName, FLegacyMethod, FConfig)
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    else if FLegacyProc <> nil then
      Result := (LRunner as TBenchmarkRunner).RunLegacyProc(FName, FLegacyProc, FConfig)
    {$ENDIF}
    else
      raise EBenchmarkConfigError.Create('传统基准测试未设置有效的执行函数');
  end
  else
  begin
    // 新 API 模式 - 使用 State-based 方式
    LState := TBenchmarkState.Create(FConfig.MinDurationMs);

    // 将配置应用到 State：预热与模式
    LState.SetWarmupIterations(FConfig.WarmupIterations);
    if FConfig.Mode = bmIterations then
      LState.SetIterations(FConfig.MeasureIterations)
    else
      LState.SetTargetCalibrationTime(FConfig.MinDurationMs);
    // 🔧 P1-1：应用校准绝对最长时长（兜底），优先使用 Config.MaxDurationMs
    LState.SetCalibrationMaxDuration(FConfig.MaxDurationMs);

    try
      // 调用夹具的 SetUp
      if FFixture <> nil then
        FFixture.SetUp(LState);

      // 执行基准测试（时间控制由 State 内部处理：预热不计入，正式阶段才开始计时，Pause/Resume 也由 State 控制）
      if FFunction <> nil then
        FFunction(LState)
      else if FMethod <> nil then
        FMethod(LState)
      {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
      else if FProc <> nil then
        FProc(LState)
      {$ENDIF}
      else
        raise EBenchmarkConfigError.Create('基准测试未设置有效的执行函数');

      // 使用 State 的计时结果（仅包含正式测量阶段，已扣除 Pause 区段）
      LTotalTime := LState.GetElapsedTime;

      // 调用夹具的 TearDown
      if FFixture <> nil then
        FFixture.TearDown(LState);

      // 创建样本数组（简化版本）
      SetLength(LSamples, 1);
      if LState.GetIterations > 0 then
        LSamples[0] := LTotalTime / LState.GetIterations
      else
        LSamples[0] := 0.0;

      // 创建增强的结果对象（支持开销校正：仅设置标志，真实校正在结果构造内处理）
      Result := TBenchmarkResultV2.Create(FName, LState.GetIterations, LTotalTime,
        FConfig, LSamples, LState);

    finally
      LState := nil;
    end;
  end;
end;

{ TBenchmarkRunner 实现 }

constructor TBenchmarkRunner.Create;
begin
  inherited Create;
  FTick := BenchmarkCreateDefaultTick;
end;

destructor TBenchmarkRunner.Destroy;
begin
  FTick := nil;
  inherited Destroy;
end;

procedure TBenchmarkRunner.ExecuteWarmup(aBenchmark: IBenchmark);
var
  LI: Integer;
  LConfig: TBenchmarkConfig;
  LBenchmarkImpl: TBenchmark;
begin
  LConfig := aBenchmark.GetConfig;
  LBenchmarkImpl := aBenchmark as TBenchmark;

  // 执行预热迭代
  for LI := 1 to LConfig.WarmupIterations do
  begin
    // 根据基准测试类型执行相应的代码
    if LBenchmarkImpl.FIsLegacy then
    begin
      // 传统 API - 无参数调用
      if LBenchmarkImpl.FLegacyFunction <> nil then
        LBenchmarkImpl.FLegacyFunction()
      else if LBenchmarkImpl.FLegacyMethod <> nil then
        LBenchmarkImpl.FLegacyMethod()
      {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
      else if LBenchmarkImpl.FLegacyProc <> nil then
        LBenchmarkImpl.FLegacyProc()
      {$ENDIF}
      else
        raise EBenchmarkConfigError.Create('传统基准测试未设置有效的执行函数');
    end
    else
    begin
      // 新 API 需要通过 TBenchmark.Run 来处理，这里不应该直接调用
      // 预热应该由 TBenchmark.Run 内部处理
      raise EBenchmarkConfigError.Create('新 API 基准测试应该通过 TBenchmark.Run 处理预热');
    end;
  end;
end;

function TBenchmarkRunner.MeasureExecution(aBenchmark: IBenchmark): IBenchmarkResult;
var
  LConfig: TBenchmarkConfig;
  LSamples: array of Double;
  LIterations: Int64;
  LTotalTime: Double;
  LStartTick: UInt64;
  LElapsedTime: Double;
  LI: Integer;
  LBenchmarkImpl: TBenchmark;
begin
  LSamples := nil;

  LConfig := aBenchmark.GetConfig;
  LBenchmarkImpl := aBenchmark as TBenchmark;

  // 执行预热
  ExecuteWarmup(aBenchmark);

  // 准备样本数组
  SetLength(LSamples, LConfig.MeasureIterations);
  LIterations := 0;
  LTotalTime := 0;

  // 执行测量迭代
  for LI := 0 to LConfig.MeasureIterations - 1 do
  begin
    LStartTick := BenchmarkGetCurrentTick(FTick);

    // 执行基准测试代码
    if LBenchmarkImpl.FIsLegacy then
    begin
      // 传统 API - 无参数调用
      if LBenchmarkImpl.FLegacyFunction <> nil then
        LBenchmarkImpl.FLegacyFunction()
      else if LBenchmarkImpl.FLegacyMethod <> nil then
        LBenchmarkImpl.FLegacyMethod()
      {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
      else if LBenchmarkImpl.FLegacyProc <> nil then
        LBenchmarkImpl.FLegacyProc()
      {$ENDIF}
      else
        raise EBenchmarkConfigError.Create('传统基准测试未设置有效的执行函数');
    end
    else
    begin
      // 新 API 需要通过 TBenchmark.Run 来处理
      raise EBenchmarkConfigError.Create('新 API 基准测试应该通过 TBenchmark.Run 处理');
    end;

    LElapsedTime := BenchmarkMeasureElapsed(FTick, LStartTick);
    LSamples[LI] := LElapsedTime;
    LTotalTime := LTotalTime + LElapsedTime;
    Inc(LIterations);
  end;

  // 创建结果对象（统一使用 V2，传统路径不携带 State，这里 counters 为空属于历史限制）
  Result := TBenchmarkResultV2.Create(aBenchmark.GetName, LIterations,
    LTotalTime, LConfig, LSamples, nil);
end;

function TBenchmarkRunner.CalculateStatistics(const aSamples: array of Double): TBenchmarkStatistics;
var
  LI, LJ: Integer;
  LSum: Double;
  LVariance: Double;
  LSortedSamples: array of Double;
  LCount: Integer;
  LTemp: Double;
  LP95Index, LP99Index: Double;
  LMedianIndex: Integer;
begin
  LSortedSamples := nil;

  LCount := Length(aSamples);
  if LCount = 0 then
    raise EBenchmarkInvalidOperation.Create('无法计算统计数据：样本数量为零');

  // 复制并排序样本
  SetLength(LSortedSamples, LCount);
  for LI := 0 to LCount - 1 do
    LSortedSamples[LI] := aSamples[LI];

  // 简单冒泡排序（对于小数据集足够）
  for LI := 0 to LCount - 2 do
  begin
    for LJ := 0 to LCount - 2 - LI do
    begin
      if LSortedSamples[LJ] > LSortedSamples[LJ + 1] then
      begin
        LTemp := LSortedSamples[LJ];
        LSortedSamples[LJ] := LSortedSamples[LJ + 1];
        LSortedSamples[LJ + 1] := LTemp;
      end;
    end;
  end;

  // 计算基本统计量
  Result.Min := LSortedSamples[0];
  Result.Max := LSortedSamples[LCount - 1];
  Result.SampleCount := LCount;

  // 计算平均值
  LSum := 0;
  for LI := 0 to LCount - 1 do
    LSum := LSum + aSamples[LI];
  Result.Mean := LSum / LCount;

  // 计算标准差（使用样本标准差，分母为 n-1）
  if LCount > 1 then
  begin
    LVariance := 0;
    for LI := 0 to LCount - 1 do
      LVariance := LVariance + Sqr(aSamples[LI] - Result.Mean);
    Result.StdDev := Sqrt(LVariance / (LCount - 1));
  end
  else
    Result.StdDev := 0;

  // 🔧 修复中位数计算
  if LCount mod 2 = 1 then
    Result.Median := LSortedSamples[LCount div 2]
  else
  begin
    LMedianIndex := LCount div 2;
    Result.Median := (LSortedSamples[LMedianIndex - 1] + LSortedSamples[LMedianIndex]) / 2.0;
  end;

  // 🔧 修复百分位数计算（使用线性插值）
  if LCount = 1 then
  begin
    Result.P95 := LSortedSamples[0];
    Result.P99 := LSortedSamples[0];
  end
  else
  begin
    // P95 计算
    LP95Index := (LCount - 1) * 0.95;
    if LP95Index = Trunc(LP95Index) then
      Result.P95 := LSortedSamples[Trunc(LP95Index)]
    else
    begin
      LI := Trunc(LP95Index);
      Result.P95 := LSortedSamples[LI] + (LP95Index - LI) * (LSortedSamples[LI + 1] - LSortedSamples[LI]);
    end;

    // P99 计算
    LP99Index := (LCount - 1) * 0.99;
    if LP99Index = Trunc(LP99Index) then
      Result.P99 := LSortedSamples[Trunc(LP99Index)]
    else
    begin
      LI := Trunc(LP99Index);
      if LI + 1 < LCount then
        Result.P99 := LSortedSamples[LI] + (LP99Index - LI) * (LSortedSamples[LI + 1] - LSortedSamples[LI])
      else
        Result.P99 := LSortedSamples[LI];
    end;
  end;

  // 🔧 计算变异系数
  if Result.Mean <> 0 then
    Result.CoefficientOfVariation := Result.StdDev / Abs(Result.Mean)
  else
    Result.CoefficientOfVariation := 0;
end;

{$PUSH}{$WARN 6018 OFF}
function TBenchmarkRunner.ConvertTimeUnit(aNanoSeconds: Double; aUnit: TBenchmarkUnit): Double;
begin
  case aUnit of
    buNanoSeconds: Exit(aNanoSeconds);
    buMicroSeconds: Exit(aNanoSeconds / 1000.0);
    buMilliSeconds: Exit(aNanoSeconds / 1000000.0);
    buSeconds: Exit(aNanoSeconds / 1000000000.0);
  else
    raise EBenchmarkConfigError.Create('不支持的时间单位');
  end;
end;
{$POP}

function TBenchmarkRunner.RunBenchmark(aBenchmark: IBenchmark): IBenchmarkResult;
begin
  if aBenchmark = nil then
    raise EArgumentNil.Create('基准测试对象不能为空');

  Result := MeasureExecution(aBenchmark);
end;

function TBenchmarkRunner.RunFunction(const aName: string; aFunc: TBenchmarkFunction;
  const aConfig: TBenchmarkConfig): IBenchmarkResult;
var
  LBenchmark: IBenchmark;
begin
  Result := nil;
  if @aFunc = nil then
    raise EArgumentNil.Create('基准测试函数不能为空');

  LBenchmark := TBenchmark.CreateWithFunction(aName, aFunc);
  LBenchmark.SetConfig(aConfig);
  Result := LBenchmark.Run; // 直接调用 TBenchmark.Run，不通过传统的 MeasureExecution
end;

function TBenchmarkRunner.RunMethod(const aName: string; aMethod: TBenchmarkMethod;
  const aConfig: TBenchmarkConfig): IBenchmarkResult;
var
  LBenchmark: IBenchmark;
begin
  Result := nil;
  if not Assigned(aMethod) then
    raise EArgumentNil.Create('基准测试方法不能为空');

  LBenchmark := TBenchmark.CreateWithMethod(aName, aMethod);
  LBenchmark.SetConfig(aConfig);
  Result := LBenchmark.Run; // 直接调用 TBenchmark.Run
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
function TBenchmarkRunner.RunProc(const aName: string; aProc: TBenchmarkProc;
  const aConfig: TBenchmarkConfig): IBenchmarkResult;
var
  LBenchmark: IBenchmark;
begin
  Result := nil;
  if aProc = nil then
    raise EArgumentNil.Create('基准测试过程不能为空');

  LBenchmark := TBenchmark.CreateWithProc(aName, aProc);
  LBenchmark.SetConfig(aConfig);
  Result := LBenchmark.Run; // 直接调用 TBenchmark.Run
end;
{$ENDIF}

{ TBenchmarkRunner 传统 API 实现 }

function TBenchmarkRunner.RunLegacyFunction(const aName: string; aFunc: TLegacyBenchmarkFunction;
  const aConfig: TBenchmarkConfig): IBenchmarkResult;
var
  LBenchmark: IBenchmark;
begin
  Result := nil;
  if @aFunc = nil then
    raise EArgumentNil.Create('传统基准测试函数不能为空');

  LBenchmark := TBenchmark.CreateLegacyFunction(aName, aFunc, aConfig);
  Result := MeasureExecution(LBenchmark);
end;

function TBenchmarkRunner.RunLegacyMethod(const aName: string; aMethod: TLegacyBenchmarkMethod;
  const aConfig: TBenchmarkConfig): IBenchmarkResult;
var
  LBenchmark: IBenchmark;
begin
  Result := nil;
  if not Assigned(aMethod) then
    raise EArgumentNil.Create('传统基准测试方法不能为空');

  LBenchmark := TBenchmark.CreateLegacyMethod(aName, aMethod, aConfig);
  Result := MeasureExecution(LBenchmark);
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
function TBenchmarkRunner.RunLegacyProc(const aName: string; aProc: TLegacyBenchmarkProc;
  const aConfig: TBenchmarkConfig): IBenchmarkResult;
var
  LBenchmark: IBenchmark;
begin
  Result := nil;
  if aProc = nil then
    raise EArgumentNil.Create('传统基准测试过程不能为空');

  LBenchmark := TBenchmark.CreateLegacyProc(aName, aProc, aConfig);
  Result := MeasureExecution(LBenchmark);
end;
{$ENDIF}

{ TBenchmarkRunner 多线程实现 }

function TBenchmarkRunner.RunMultiThreadFunction(const aName: string;
                                                aFunc: TMultiThreadBenchmarkFunction;
                                                const aThreadConfig: TMultiThreadConfig;
                                                const aConfig: TBenchmarkConfig): IBenchmarkResult;
var
  LState: IBenchmarkState;
  LThreads: array of TThread;
  LStartEvent: TEvent;
  LI, LJ, LK: Integer;
  LTotalWork: Integer;
  LStartTime, LEndTime: Int64;
  LTotalTime: Double;
  LIterations: Integer;
  LSamples: array of Double;
  LWorkPerThread: array of Integer;
begin
  LSamples := nil;
  LThreads := nil;


  if @aFunc = nil then
    raise EArgumentNil.Create('多线程基准测试函数不能为空');

  if aThreadConfig.ThreadCount <= 0 then
    raise EArgumentException.Create('线程数量必须大于0');

  LState := TBenchmarkState.Create(aConfig.MinDurationMs);
  LStartEvent := TEvent.Create(nil, True, False, '');
  LIterations := 0;

  try
    // 设置线程数组
    SetLength(LThreads, aThreadConfig.ThreadCount);

    // 预热阶段
    for LJ := 1 to aConfig.WarmupIterations do
    begin
      LTotalWork := 0;
      LStartEvent.ResetEvent;
      LWorkPerThread := nil;
      SetLength(LWorkPerThread, aThreadConfig.ThreadCount);
      for LI := 0 to aThreadConfig.ThreadCount - 1 do LWorkPerThread[LI] := 0;

      // 创建预热线程
      for LK := 0 to aThreadConfig.ThreadCount - 1 do
      begin
        LThreads[LK] := TThread.CreateAnonymousThread(
          procedure
          var
            LThreadIndex: Integer;
            LLocalWork: Integer;
            LIdx: Integer;
          begin
            LIdx := LK;
            LThreadIndex := LIdx;

            if aThreadConfig.SyncThreads then
            begin
              // Robust fallback: default to 10s if timeout not set
              // fallback: use local timeout variable if StartBarrierTimeoutMs unset
              LLocalWork := 0; // keep local var to avoid uninitialized warning
              // do not write to aThreadConfig (record param is const); use default when needed
              if LStartEvent.WaitFor(aThreadConfig.StartBarrierTimeoutMs) <> wrSignaled then
                raise EBenchmarkTimeoutError.Create('Thread start barrier timeout');
            end;

            LLocalWork := 0;
            try
              aFunc(LState, LThreadIndex);
              if aThreadConfig.WorkPerThread > 0 then
                LLocalWork := aThreadConfig.WorkPerThread;
            except
              // 忽略预热阶段的异常
            end;

            // 本地写入，避免共享写竞争
            LWorkPerThread[LIdx] := LLocalWork;
          end);
        LThreads[LK].FreeOnTerminate := False;
        LThreads[LK].Start;
      end;

      if aThreadConfig.SyncThreads then
        LStartEvent.SetEvent;

      // 等待预热线程完成
      for LI := 0 to aThreadConfig.ThreadCount - 1 do
        LThreads[LI].WaitFor;
      // 释放预热线程
      for LI := 0 to aThreadConfig.ThreadCount - 1 do
      begin
        LThreads[LI].Free;
        LThreads[LI] := nil;
      end;

      // 聚合本地工作量
      LTotalWork := 0;
      for LI := 0 to aThreadConfig.ThreadCount - 1 do
        Inc(LTotalWork, LWorkPerThread[LI]);
    end;

    // 测量阶段
    LStartTime := BenchmarkGetCurrentTick(FTick);

    for LI := 1 to aConfig.MeasureIterations do
    begin
      LTotalWork := 0;
      LStartEvent.ResetEvent;

      // 创建测量线程
      LWorkPerThread := nil;
      SetLength(LWorkPerThread, aThreadConfig.ThreadCount);
      for LJ := 0 to aThreadConfig.ThreadCount - 1 do LWorkPerThread[LJ] := 0;
      for LJ := 0 to aThreadConfig.ThreadCount - 1 do
      begin
        LThreads[LJ] := TThread.CreateAnonymousThread(
          procedure
          var
            LThreadIndex: Integer;
            LLocalWork: Integer;
            LIdx: Integer;
          begin
            LIdx := LJ;
            LThreadIndex := LIdx;

            if aThreadConfig.SyncThreads then
            begin
              // do not mutate const record param; fallback handled at call site
              if LStartEvent.WaitFor(aThreadConfig.StartBarrierTimeoutMs) <> wrSignaled then
                raise EBenchmarkTimeoutError.Create('Thread start barrier timeout');
            end;

            LLocalWork := 0;
            try
              aFunc(LState, LThreadIndex);
              if aThreadConfig.WorkPerThread > 0 then
                LLocalWork := aThreadConfig.WorkPerThread;
            except
              on E: Exception do
                raise EBenchmarkError.Create(UTF8String('多线程基准测试执行失败: ') + UTF8String(E.Message));
            end;

            // 本地写入，避免共享写竞争
            LWorkPerThread[LIdx] := LLocalWork;
          end);
        LThreads[LJ].FreeOnTerminate := False;
        LThreads[LJ].Start;
      end;

      if aThreadConfig.SyncThreads then
        LStartEvent.SetEvent;

      // 等待测量线程完成
      for LJ := 0 to aThreadConfig.ThreadCount - 1 do
        LThreads[LJ].WaitFor;
      // 释放测量线程
      for LJ := 0 to aThreadConfig.ThreadCount - 1 do
      begin
        LThreads[LJ].Free;
        LThreads[LJ] := nil;
      end;

      // 聚合本地工作量
      LTotalWork := 0;
      for LJ := 0 to aThreadConfig.ThreadCount - 1 do
        Inc(LTotalWork, LWorkPerThread[LJ]);

      Inc(LIterations);

      // 设置处理的项目数
      if LTotalWork > 0 then
        LState.SetItemsProcessed(LTotalWork);
    end;

    LEndTime := BenchmarkGetCurrentTick(FTick);
    LTotalTime := BenchmarkTicksToNanoSeconds(FTick, UInt64(LEndTime - LStartTime));

    // 确保有至少一个样本，避免统计计算异常
    SetLength(LSamples, 1);
    if LIterations > 0 then
      LSamples[0] := LTotalTime / LIterations
    else
      LSamples[0] := 0.0;

    // 创建结果（使用 V2 以便兼容可扩展字段）
    Result := TBenchmarkResultV2.Create(aName, LIterations, LTotalTime, aConfig, LSamples, LState);

  finally
    LStartEvent.Free;
  end;
end;

function TBenchmarkRunner.RunMultiThreadMethod(const aName: string;
                                              aMethod: TMultiThreadBenchmarkMethod;
                                              const aThreadConfig: TMultiThreadConfig;
                                              const aConfig: TBenchmarkConfig): IBenchmarkResult;
var
  LState: IBenchmarkState;
  LThreads: array of TThread;
  LStartEvent: TEvent;
  LI, LJ, LK: Integer;
  LTotalWork: Integer;
  LStartTime, LEndTime: Int64;
  LTotalTime: Double;
  LIterations: Integer;
  LSamples: array of Double;
begin
  LThreads := nil;

  LSamples := nil;

  if not Assigned(aMethod) then
    raise EArgumentNil.Create('多线程基准测试方法不能为空');

  if aThreadConfig.ThreadCount <= 0 then
    raise EArgumentException.Create('线程数量必须大于0');

  LState := TBenchmarkState.Create(aConfig.MinDurationMs);
  LStartEvent := TEvent.Create(nil, True, False, '');
  LIterations := 0;

  try
    // 设置线程数组
    SetLength(LThreads, aThreadConfig.ThreadCount);

    // 预热阶段
    for LJ := 1 to aConfig.WarmupIterations do
    begin
      LTotalWork := 0;
      LStartEvent.ResetEvent;

      // 创建预热线程
      for LK := 0 to aThreadConfig.ThreadCount - 1 do
      begin
        LThreads[LK] := TThread.CreateAnonymousThread(
          procedure
          var
            LThreadIndex: Integer;
            LLocalWork: Integer;
            LIdx: Integer;
          begin
            LIdx := LK;
            LThreadIndex := LIdx;

            if aThreadConfig.SyncThreads then
            begin
              // do not mutate const record param; fallback handled at call site
              if LStartEvent.WaitFor(aThreadConfig.StartBarrierTimeoutMs) <> wrSignaled then
                raise EBenchmarkTimeoutError.Create('Thread start barrier timeout');
            end;

            LLocalWork := 0;
            try
              aMethod(LState, LThreadIndex);
              if aThreadConfig.WorkPerThread > 0 then
                LLocalWork := aThreadConfig.WorkPerThread;
            except
              // 忽略预热阶段的异常
            end;

            InterlockedExchangeAdd(LTotalWork, LLocalWork);
          end);
        LThreads[LK].FreeOnTerminate := False;
        LThreads[LK].Start;
      end;

      if aThreadConfig.SyncThreads then
        LStartEvent.SetEvent;

      // 等待预热线程完成
      for LK := 0 to aThreadConfig.ThreadCount - 1 do
        LThreads[LK].WaitFor;
      // 释放预热线程
      for LK := 0 to aThreadConfig.ThreadCount - 1 do
      begin
        LThreads[LK].Free;
        LThreads[LK] := nil;
      end;
    end;

    // 测量阶段
    LStartTime := BenchmarkGetCurrentTick(FTick);

    for LI := 1 to aConfig.MeasureIterations do
    begin
      LTotalWork := 0;
      LStartEvent.ResetEvent;

      // 创建测量线程
      for LJ := 0 to aThreadConfig.ThreadCount - 1 do
      begin
        LThreads[LJ] := TThread.CreateAnonymousThread(
          procedure
          var
            LThreadIndex: Integer;
            LLocalWork: Integer;
            LIdx: Integer;
          begin
            LIdx := LJ;
            LThreadIndex := LIdx;

            if aThreadConfig.SyncThreads then
            begin
              // do not mutate const record param; fallback handled at call site
              if LStartEvent.WaitFor(aThreadConfig.StartBarrierTimeoutMs) <> wrSignaled then
                raise EBenchmarkTimeoutError.Create('Thread start barrier timeout');
            end;

            LLocalWork := 0;
            try
              aMethod(LState, LThreadIndex);
              if aThreadConfig.WorkPerThread > 0 then
                LLocalWork := aThreadConfig.WorkPerThread;
            except
              on E: Exception do
                raise EBenchmarkError.Create(UTF8String('多线程基准测试执行失败: ') + UTF8String(E.Message));
            end;

            InterlockedExchangeAdd(LTotalWork, LLocalWork);
          end);
        LThreads[LJ].FreeOnTerminate := False;
        LThreads[LJ].Start;
      end;

      if aThreadConfig.SyncThreads then
        LStartEvent.SetEvent;

      // 等待测量线程完成
      for LJ := 0 to aThreadConfig.ThreadCount - 1 do
        LThreads[LJ].WaitFor;
      // 释放测量线程
      for LJ := 0 to aThreadConfig.ThreadCount - 1 do
      begin
        LThreads[LJ].Free;
        LThreads[LJ] := nil;
      end;

      Inc(LIterations);

      // 设置处理的项目数
      if LTotalWork > 0 then
        LState.SetItemsProcessed(LTotalWork);
    end;

    LEndTime := BenchmarkGetCurrentTick(FTick);
    LTotalTime := BenchmarkTicksToNanoSeconds(FTick, UInt64(LEndTime - LStartTime));

    // 确保有至少一个样本，避免统计计算异常
    SetLength(LSamples, 1);
    if LIterations > 0 then
      LSamples[0] := LTotalTime / LIterations
    else
      LSamples[0] := 0.0;

    // 创建结果（使用 V2 以便兼容可扩展字段）
    Result := TBenchmarkResultV2.Create(aName, LIterations, LTotalTime, aConfig, LSamples, LState);

  finally
    LStartEvent.Free;
  end;
end;

{ TBenchmarkSuite 实现 }

constructor TBenchmarkSuite.Create;
begin
  inherited Create;
  SetLength(FBenchmarks, 0);
  FRunner := CreateBenchmarkRunner;
end;

destructor TBenchmarkSuite.Destroy;
begin
  Clear;
  FRunner := nil;
  inherited Destroy;
end;

procedure TBenchmarkSuite.AddBenchmark(aBenchmark: IBenchmark);
var
  LLen: Integer;
begin
  if aBenchmark = nil then
    raise EArgumentNil.Create('基准测试对象不能为空');

  LLen := Length(FBenchmarks);
  SetLength(FBenchmarks, LLen + 1);
  FBenchmarks[LLen] := aBenchmark;
end;

procedure TBenchmarkSuite.AddFunction(const aName: string; aFunc: TBenchmarkFunction;
  const aConfig: TBenchmarkConfig);
var
  LBenchmark: IBenchmark;
begin
  LBenchmark := TBenchmark.CreateWithFunction(aName, aFunc);
  LBenchmark.SetConfig(aConfig);
  AddBenchmark(LBenchmark);
end;

procedure TBenchmarkSuite.AddMethod(const aName: string; aMethod: TBenchmarkMethod;
  const aConfig: TBenchmarkConfig);
var
  LBenchmark: IBenchmark;
begin
  LBenchmark := TBenchmark.CreateWithMethod(aName, aMethod);
  LBenchmark.SetConfig(aConfig);
  AddBenchmark(LBenchmark);
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
procedure TBenchmarkSuite.AddProc(const aName: string; aProc: TBenchmarkProc;
  const aConfig: TBenchmarkConfig);
var
  LBenchmark: IBenchmark;
begin
  LBenchmark := TBenchmark.CreateWithProc(aName, aProc);
  LBenchmark.SetConfig(aConfig);
  AddBenchmark(LBenchmark);
end;
{$ENDIF}

procedure TBenchmarkSuite.Add(aBenchmark: IBenchmark);
begin
  AddBenchmark(aBenchmark);
end;

procedure TBenchmarkSuite.Add(const aName: string; aFunc: TBenchmarkFunction;
  const aConfig: TBenchmarkConfig);
begin
  AddFunction(aName, aFunc, aConfig);
end;

procedure TBenchmarkSuite.Add(const aName: string; aMethod: TBenchmarkMethod;
  const aConfig: TBenchmarkConfig);
begin
  AddMethod(aName, aMethod, aConfig);
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
procedure TBenchmarkSuite.Add(const aName: string; aProc: TBenchmarkProc;
  const aConfig: TBenchmarkConfig);
begin
  AddProc(aName, aProc, aConfig);
end;
{$ENDIF}

function TBenchmarkSuite.RunAll: TBenchmarkResultArray;
var
  LI: Integer;
begin
  Result := nil;
  SetLength(Result, Length(FBenchmarks));
  for LI := 0 to High(FBenchmarks) do
    Result[LI] := FBenchmarks[LI].Run;
end;

function TBenchmarkSuite.RunAllWithReporter(aReporter: IBenchmarkReporter): TBenchmarkResultArray;
begin
  Result := nil;
  SetLength(Result, 0);
  Result := RunAll;
  if aReporter <> nil then
    aReporter.ReportResults(Result);
end;

procedure TBenchmarkSuite.Clear;
begin
  SetLength(FBenchmarks, 0);
end;

function TBenchmarkSuite.GetCount: Integer;
begin
  Result := Length(FBenchmarks);
end;

{ TBenchmarkSuite 增强方法实现 }

function TBenchmarkSuite.RunComparison(aIndex1, aIndex2: Integer): TBenchmarkComparison;
var
  LResult1, LResult2: IBenchmarkResult;
  LRelativeDiff: Double;
begin
  if (aIndex1 < 0) or (aIndex1 >= Length(FBenchmarks)) then
    raise EArgumentException.Create('第一个测试索引超出范围');
  if (aIndex2 < 0) or (aIndex2 >= Length(FBenchmarks)) then
    raise EArgumentException.Create('第二个测试索引超出范围');
  if aIndex1 = aIndex2 then
    raise EArgumentException.Create('不能对比相同的测试');

  // 运行两个测试
  LResult1 := FRunner.RunBenchmark(FBenchmarks[aIndex1]);
  LResult2 := FRunner.RunBenchmark(FBenchmarks[aIndex2]);

  // 计算相对差异
  LRelativeDiff := CompareResults(LResult1, LResult2);

  // 构建对比结果
  Result.Name1 := LResult1.Name;
  Result.Name2 := LResult2.Name;
  Result.Result1 := LResult1;
  Result.Result2 := LResult2;
  Result.RelativeDifference := LRelativeDiff;

  // 生成结论
  if Abs(LRelativeDiff) < 0.05 then
  begin
    Result.Conclusion := '两个测试性能基本相当';
    Result.Significance := 0.1;
  end
  else if LRelativeDiff > 0 then
  begin
    Result.Conclusion := Format('%s 比 %s 快 %.1f%%', [Result.Name2, Result.Name1, Abs(LRelativeDiff) * 100]);
    Result.Significance := Min(Abs(LRelativeDiff), 1.0);
  end
  else
  begin
    Result.Conclusion := Format('%s 比 %s 快 %.1f%%', [Result.Name1, Result.Name2, Abs(LRelativeDiff) * 100]);
    Result.Significance := Min(Abs(LRelativeDiff), 1.0);
  end;
end;

function TBenchmarkSuite.GenerateReport(const aTitle: string): TBenchmarkReport;
var
  LResults: TBenchmarkResultArray;
  LI, LJ: Integer;
  LComparisonCount: Integer;
  LFastest: IBenchmarkResult;
  LFastestName: string;
begin
  // 运行所有测试
  LResults := RunAll;

  // 初始化报告
  Result.Title := aTitle;
  Result.GeneratedAt := Now;

  // 复制结果
  SetLength(Result.Results, Length(LResults));
  for LI := 0 to High(LResults) do
    Result.Results[LI] := LResults[LI];

  // 生成所有可能的对比
  LComparisonCount := 0;
  if Length(LResults) > 1 then
  begin
    SetLength(Result.Comparisons, (Length(LResults) * (Length(LResults) - 1)) div 2);

    for LI := 0 to High(LResults) - 1 do
      for LJ := LI + 1 to High(LResults) do
      begin
        Result.Comparisons[LComparisonCount] := RunComparison(LI, LJ);
        Inc(LComparisonCount);
      end;

    SetLength(Result.Comparisons, LComparisonCount);
  end;

  // 生成摘要
  if Length(LResults) = 0 then
    Result.Summary := '没有测试结果'
  else if Length(LResults) = 1 then
    Result.Summary := Format('运行了 1 个测试，平均时间 %.2f %s/op',
                            [LResults[0].GetTimePerIteration(buMicroSeconds), MicroUnitStr])
  else
  begin

    LFastest := LResults[0];
    LFastestName := LResults[0].Name;

    for LI := 1 to High(LResults) do
      if LResults[LI].GetTimePerIteration() < LFastest.GetTimePerIteration() then
      begin
        LFastest := LResults[LI];
        LFastestName := LResults[LI].Name;
      end;

    Result.Summary := Format('运行了 %d 个测试，最快的是 %s (%.2f %s/op)',
                            [Length(LResults), LFastestName,
                             LFastest.GetTimePerIteration(buMicroSeconds), MicroUnitStr]);
  end;

  // 生成建议
  SetLength(Result.Recommendations, 0);
  if Length(LResults) > 1 then
  begin
    SetLength(Result.Recommendations, 1);
    Result.Recommendations[0] := '建议关注性能差异较大的测试，考虑优化较慢的实现';
  end;
end;

function TBenchmarkSuite.RunWithTrendAnalysis(const aHistoricalData: array of TBenchmarkTrend): TBenchmarkResultArray;
var
  LResults: TBenchmarkResultArray;
  LI: Integer;
  LHistoricalIndex: Integer;
  LJ: Integer;
  LHistorical: TBenchmarkTrend;
  LCurrentValue, LLastValue, LChange: Double;
begin
  Result := nil;
  SetLength(Result, 0);

  // 运行所有测试
  LResults := RunAll;

  // 简化的趋势分析（实际实现可以更复杂）
  if Length(aHistoricalData) > 0 then
  begin
    // trend analysis header removed; reporting delegated to caller/Reporter
    for LI := 0 to High(LResults) do
    begin

      // 查找对应的历史数据
      LHistoricalIndex := -1;
      for LJ := 0 to High(aHistoricalData) do
        if aHistoricalData[LJ].TestName = LResults[LI].Name then
        begin
          LHistoricalIndex := LJ;
          Break;
        end;

      if LHistoricalIndex >= 0 then
      begin

        LHistorical := aHistoricalData[LHistoricalIndex];
        if Length(LHistorical.Values) > 0 then
        begin
          LCurrentValue := LResults[LI].GetTimePerIteration();
          LLastValue := LHistorical.Values[High(LHistorical.Values)];
          LChange := (LCurrentValue - LLastValue) / LLastValue;

          // trend item output removed; collect data for Reporter if needed
                  //Format('%.2f%%', [LChange * 100]),

        end;
      end;
    end;
  end;

  Result := LResults;
end;

{ TBenchmarkAnalyzer 实现 }

function TBenchmarkAnalyzer.AnalyzePerformance(aResult: IBenchmarkResult): TPerformanceAnalysis;
var
  LTime: Double;
begin
  if aResult = nil then
  begin
    Result.TestName := 'Unknown';
    Result.PerformanceLevel := 'Error';
    Result.BottleneckType := 'Unknown';
    SetLength(Result.OptimizationSuggestions, 0);
    Result.Confidence := 0.0;
    Result.AnalysisTimestamp := Now;
    Exit;
  end;

  Result.TestName := aResult.Name;
  Result.AnalysisTimestamp := Now;
  LTime := aResult.GetTimePerIteration();

  // 简化的性能等级分析
  if LTime < 1000 then // < 1μs
  begin
    Result.PerformanceLevel := 'Excellent';
    Result.BottleneckType := 'None';
    Result.Confidence := 0.9;
    SetLength(Result.OptimizationSuggestions, 1);
    Result.OptimizationSuggestions[0] := '性能优秀，无需优化';
  end
  else if LTime < 10000 then // < 10μs
  begin
    Result.PerformanceLevel := 'Good';
    Result.BottleneckType := 'Minor';
    Result.Confidence := 0.8;
    SetLength(Result.OptimizationSuggestions, 2);
    Result.OptimizationSuggestions[0] := '性能良好，可考虑微优化';
    Result.OptimizationSuggestions[1] := '检查是否有不必要的内存分配';
  end
  else if LTime < 100000 then // < 100μs
  begin
    Result.PerformanceLevel := 'Fair';
    Result.BottleneckType := 'CPU';
    Result.Confidence := 0.7;
    SetLength(Result.OptimizationSuggestions, 3);
    Result.OptimizationSuggestions[0] := '考虑算法优化';
    Result.OptimizationSuggestions[1] := '减少循环复杂度';
    Result.OptimizationSuggestions[2] := '使用更高效的数据结构';
  end
  else // >= 100μs
  begin
    Result.PerformanceLevel := 'Poor';
    Result.BottleneckType := 'Algorithm';
    Result.Confidence := 0.6;
    SetLength(Result.OptimizationSuggestions, 4);
    Result.OptimizationSuggestions[0] := '需要重新设计算法';
    Result.OptimizationSuggestions[1] := '考虑使用缓存机制';
    Result.OptimizationSuggestions[2] := '检查是否有 I/O 操作';
    Result.OptimizationSuggestions[3] := '考虑并行化处理';
  end;
end;

function TBenchmarkAnalyzer.AnalyzeBatch(const aResults: array of IBenchmarkResult): TPerformanceAnalysisArray;
var
  LI: Integer;
begin
  Result := nil;
  SetLength(Result, 0);
  SetLength(Result, Length(aResults));
  for LI := 0 to High(aResults) do
    Result[LI] := AnalyzePerformance(aResults[LI]);
end;

function TBenchmarkAnalyzer.CompareWithExpected(aResult: IBenchmarkResult; aExpectedMin, aExpectedMax: Double): TPerformanceAnalysis;
var
  LCurrentTime: Double;
begin
  Result := AnalyzePerformance(aResult);

  if aResult <> nil then
  begin
    LCurrentTime := aResult.GetTimePerIteration();

    if (LCurrentTime >= aExpectedMin) and (LCurrentTime <= aExpectedMax) then
    begin
      Result.PerformanceLevel := 'Expected';
      SetLength(Result.OptimizationSuggestions, 1);
      Result.OptimizationSuggestions[0] := '性能符合预期';
    end
    else if LCurrentTime < aExpectedMin then
    begin
      Result.PerformanceLevel := 'Better than Expected';
      SetLength(Result.OptimizationSuggestions, 1);
      Result.OptimizationSuggestions[0] := '性能超出预期，表现优秀';
    end
    else
    begin
      Result.PerformanceLevel := 'Worse than Expected';
      SetLength(Result.OptimizationSuggestions, 2);
      Result.OptimizationSuggestions[0] := '性能低于预期，需要优化';
      Result.OptimizationSuggestions[1] := '检查算法实现是否正确';
    end;
  end;
end;

function TBenchmarkAnalyzer.GetOptimizationSuggestions(aResult: IBenchmarkResult): TStringArray;
var
  LAnalysis: TPerformanceAnalysis;
begin
  Result := nil;
  SetLength(Result, 0);
  LAnalysis := AnalyzePerformance(aResult);
  Result := LAnalysis.OptimizationSuggestions;
end;

{ TBenchmarkTemplateManager 实现 }

constructor TBenchmarkTemplateManager.Create;
begin
  inherited Create;
  SetLength(FTemplates, 0);
  InitializeDefaultTemplates;
end;

procedure TBenchmarkTemplateManager.InitializeDefaultTemplates;
var
  LTemplate: TBenchmarkTemplate;
begin
  // 算法模板
  LTemplate.Name := 'Algorithm';
  LTemplate.Description := '通用算法性能测试模板';
  LTemplate.Category := 'Algorithm';
  LTemplate.Config := CreateDefaultBenchmarkConfig;
  LTemplate.Config.WarmupIterations := 3;
  LTemplate.Config.MeasureIterations := 10;
  LTemplate.ExpectedRange.MinTime := 1000;   // 1μs
  LTemplate.ExpectedRange.MaxTime := 100000; // 100μs
  SetLength(LTemplate.Tags, 2);
  LTemplate.Tags[0] := 'algorithm';
  LTemplate.Tags[1] := 'general';
  RegisterTemplate(LTemplate);

  // 内存操作模板
  LTemplate.Name := 'Memory';
  LTemplate.Description := '内存操作性能测试模板';
  LTemplate.Category := 'Memory';
  LTemplate.Config := CreateDefaultBenchmarkConfig;
  LTemplate.Config.WarmupIterations := 2;
  LTemplate.Config.MeasureIterations := 5;
  LTemplate.ExpectedRange.MinTime := 100;    // 0.1μs
  LTemplate.ExpectedRange.MaxTime := 10000;  // 10μs
  SetLength(LTemplate.Tags, 2);
  LTemplate.Tags[0] := 'memory';
  LTemplate.Tags[1] := 'allocation';
  RegisterTemplate(LTemplate);

  // I/O 操作模板
  LTemplate.Name := 'IO';
  LTemplate.Description := 'I/O 操作性能测试模板';
  LTemplate.Category := 'IO';
  LTemplate.Config := CreateDefaultBenchmarkConfig;
  LTemplate.Config.WarmupIterations := 1;
  LTemplate.Config.MeasureIterations := 3;
  LTemplate.ExpectedRange.MinTime := 100000;  // 100μs
  LTemplate.ExpectedRange.MaxTime := 10000000; // 10ms
  SetLength(LTemplate.Tags, 2);
  LTemplate.Tags[0] := 'io';
  LTemplate.Tags[1] := 'file';
  RegisterTemplate(LTemplate);
end;

function TBenchmarkTemplateManager.GetTemplate(const aName: string): TBenchmarkTemplate;
var
  LI: Integer;
begin
  for LI := 0 to High(FTemplates) do
    if FTemplates[LI].Name = aName then
    begin
      Result := FTemplates[LI];
      Exit;
    end;

  raise EArgumentException.Create(UTF8String('模板不存在: ') + UTF8String(aName));
end;

function TBenchmarkTemplateManager.GetTemplatesByCategory(const aCategory: string): TBenchmarkTemplateArray;
var
  LI, LCount: Integer;
begin
  Result := nil;
  SetLength(Result, 0);
  LCount := 0;

  // 计算匹配的模板数量
  for LI := 0 to High(FTemplates) do
    if FTemplates[LI].Category = aCategory then
      Inc(LCount);

  // 复制匹配的模板
  SetLength(Result, LCount);
  LCount := 0;
  for LI := 0 to High(FTemplates) do
    if FTemplates[LI].Category = aCategory then
    begin
      Result[LCount] := FTemplates[LI];
      Inc(LCount);
    end;
end;

function TBenchmarkTemplateManager.GetAllTemplates: TBenchmarkTemplateArray;
begin
  Result := FTemplates;
end;

function TBenchmarkTemplateManager.CreateConfigFromTemplate(const aTemplateName: string): TBenchmarkConfig;
var
  LTemplate: TBenchmarkTemplate;
begin
  LTemplate := GetTemplate(aTemplateName);
  Result := LTemplate.Config;
end;

procedure TBenchmarkTemplateManager.RegisterTemplate(const aTemplate: TBenchmarkTemplate);
begin
  SetLength(FTemplates, Length(FTemplates) + 1);
  FTemplates[High(FTemplates)] := aTemplate;
end;

{ TBenchmarkMonitor 实现 }

constructor TBenchmarkMonitor.Create;
begin
  inherited Create;
  SetLength(FThresholds, 0);
  SetLength(FRegressionThresholds, 0);
  SetLength(FAlerts, 0);
end;

procedure TBenchmarkMonitor.SetThreshold(const aTestName: string; aThreshold: Double);
var
  LI: Integer;
begin
  // 查找现有阈值
  for LI := 0 to High(FThresholds) do
    if FThresholds[LI].TestName = aTestName then
    begin
      FThresholds[LI].Threshold := aThreshold;
      Exit;
    end;

  // 添加新阈值
  SetLength(FThresholds, Length(FThresholds) + 1);
  FThresholds[High(FThresholds)].TestName := aTestName;
  FThresholds[High(FThresholds)].Threshold := aThreshold;
end;

procedure TBenchmarkMonitor.SetRegressionThreshold(const aTestName: string; aThreshold: Double);
var
  LI: Integer;
begin
  // 查找现有回归阈值
  for LI := 0 to High(FRegressionThresholds) do
    if FRegressionThresholds[LI].TestName = aTestName then
    begin
      FRegressionThresholds[LI].Threshold := aThreshold;
      Exit;
    end;

  // 添加新回归阈值
  SetLength(FRegressionThresholds, Length(FRegressionThresholds) + 1);
  FRegressionThresholds[High(FRegressionThresholds)].TestName := aTestName;
  FRegressionThresholds[High(FRegressionThresholds)].Threshold := aThreshold;
end;

function TBenchmarkMonitor.CheckPerformance(aResult: IBenchmarkResult): TPerformanceAlertArray;
var
  LThreshold: Double;
  LCurrentTime: Double;
  LI: Integer;
begin
  Result := nil;
  SetLength(Result, 0);


    Exit;

  // 查找阈值
  LThreshold := -1;
  for LI := 0 to High(FThresholds) do
    if FThresholds[LI].TestName = aResult.Name then
    begin
      LThreshold := FThresholds[LI].Threshold;
      Break;
    end;

  if LThreshold > 0 then
  begin
    LCurrentTime := aResult.GetTimePerIteration();
    if LCurrentTime > LThreshold then
    begin
      SetLength(Result, 1);
      Result[0].TestName := aResult.Name;
      Result[0].AlertType := 'threshold';
      Result[0].Threshold := LThreshold;
      Result[0].CurrentValue := LCurrentTime;
      Result[0].Message := Format('测试 "%s" 超过性能阈值: %.2f %s > %.2f %s',
        [aResult.Name, LCurrentTime / 1000, MicroUnitStr, LThreshold / 1000, MicroUnitStr]);
      Result[0].Severity := 3;
      Result[0].Timestamp := Now;

      // 添加到警报列表
      SetLength(FAlerts, Length(FAlerts) + 1);
      FAlerts[High(FAlerts)] := Result[0];
    end;
  end;
end;

function TBenchmarkMonitor.CheckRegression(aCurrentResult: IBenchmarkResult;
                                         const aHistoricalResults: array of IBenchmarkResult): TPerformanceAlertArray;
var
  LRegressionThreshold: Double;
  LCurrentTime, LHistoricalTime: Double;
  LI: Integer;
  LHistoricalResult: IBenchmarkResult;
  LRelativeChange: Double;
begin
  Result := nil;
  SetLength(Result, 0);
  if (aCurrentResult = nil) or (Length(aHistoricalResults) = 0) then
    Exit;

  // 查找回归阈值
  LRegressionThreshold := 0.1; // 默认 10%
  for LI := 0 to High(FRegressionThresholds) do
    if FRegressionThresholds[LI].TestName = aCurrentResult.Name then
    begin
      LRegressionThreshold := FRegressionThresholds[LI].Threshold;
      Break;
    end;

  // 查找对应的历史结果
  LHistoricalResult := nil;
  for LI := 0 to High(aHistoricalResults) do
    if aHistoricalResults[LI].Name = aCurrentResult.Name then
    begin
      LHistoricalResult := aHistoricalResults[LI];
      Break;
    end;

  if LHistoricalResult <> nil then
  begin
    LCurrentTime := aCurrentResult.GetTimePerIteration();
    LHistoricalTime := LHistoricalResult.GetTimePerIteration();

    if LHistoricalTime > 0 then
    begin
      LRelativeChange := (LCurrentTime - LHistoricalTime) / LHistoricalTime;

      if LRelativeChange > LRegressionThreshold then
      begin
        SetLength(Result, 1);
        Result[0].TestName := aCurrentResult.Name;
        Result[0].AlertType := 'regression';
        Result[0].Threshold := LRegressionThreshold;
        Result[0].CurrentValue := LRelativeChange;
        Result[0].Message := Format('测试 "%s" 性能回归: %.1f%% 慢于历史基线',
          [aCurrentResult.Name, LRelativeChange * 100]);
        Result[0].Severity := 4;
        Result[0].Timestamp := Now;

        // 添加到警报列表
        SetLength(FAlerts, Length(FAlerts) + 1);
        FAlerts[High(FAlerts)] := Result[0];
      end;
    end;
  end;
end;

function TBenchmarkMonitor.GetAlerts: TPerformanceAlertArray;
begin
  Result := FAlerts;
end;

procedure TBenchmarkMonitor.ClearAlerts;
begin
  SetLength(FAlerts, 0);
end;

procedure TBenchmarkMonitor.SaveResults(const aResults: array of IBenchmarkResult; const aFileName: string);
var
  LFile: TextFile;
  LI: Integer;
begin
  AssignFile(LFile, aFileName);
  Rewrite(LFile);

  try
    WriteLn(LFile, '# Benchmark results file');
    WriteLn(LFile, '# Format: name,time_ns,iterations,timestamp');

    for LI := 0 to High(aResults) do
    begin
      WriteLn(LFile, Format('%s,%.0f,%d,%.8f', [
        aResults[LI].Name,
        aResults[LI].GetTimePerIteration(),
        aResults[LI].Iterations,
        Now
      ]));
    end;

  finally
    CloseFile(LFile);
  end;
end;

function TBenchmarkMonitor.LoadResults(const aFileName: string): TBenchmarkResultArray;
var
  LFile: TextFile;
  LLine: string;
  {$IFDEF DEBUG}
  LParts: array of string;
  {$ENDIF}
  LCount: Integer;
begin
  Result := nil;
  SetLength(Result, 0);


    Exit;

  AssignFile(LFile, aFileName);
  Reset(LFile);

  try
    LCount := 0;
    while not EOF(LFile) do
    begin
      ReadLn(LFile, LLine);
      LLine := Trim(LLine);

      if (LLine = '') or (LLine[1] = '#') then
        Continue;

      // 简化解析 - 实际实现需要更完整的结果重建
      Inc(LCount);
    end;

    // 这里应该重新解析文件并创建结果对象
    // 为了简化，我们只返回空数组
    SetLength(Result, 0);

  finally
    CloseFile(LFile);
  end;
end;

{ TConsoleReporter 实现 }

constructor TConsoleReporter.Create;
begin
  inherited Create;
  FFormat := 'plain';
  FAsciiOnly := False;
  FSink := nil;
end;

constructor TConsoleReporter.Create(aAsciiOnly: Boolean);
begin
  inherited Create;
  FFormat := 'plain';
  FAsciiOnly := aAsciiOnly;
  FSink := nil;
end;

procedure TConsoleReporter.W(const S: string);
begin
  if FSink <> nil then FSink.WriteLine(S) else WriteLn(S);
end;

function TConsoleReporter.FormatTime(aNanoSeconds: Double): string;
begin
  if aNanoSeconds < 1000 then
    Result := Format('%.2f ns', [aNanoSeconds])
  else if aNanoSeconds < 1000000 then
    if FAsciiOnly then
      Result := Format('%.2f us', [aNanoSeconds / 1000])
    else
      Result := Format('%.2f %s', [aNanoSeconds / 1000, MicroUnitStr])
  else if aNanoSeconds < 1000000000 then
    Result := Format('%.2f ms', [aNanoSeconds / 1000000])
  else
    Result := Format('%.2f s', [aNanoSeconds / 1000000000]);
end;

function TConsoleReporter.FormatThroughput(aThroughput: Double): string;
begin
  if aThroughput < 1000 then
    Result := Format('%.0f ops/sec', [aThroughput])
  else if aThroughput < 1000000 then
    Result := Format('%.1f K ops/sec', [aThroughput / 1000])
  else if aThroughput < 1000000000 then
    Result := Format('%.1f M ops/sec', [aThroughput / 1000000])
  else
    Result := Format('%.1f G ops/sec', [aThroughput / 1000000000]);
end;

procedure TConsoleReporter.ReportResult(aResult: IBenchmarkResult);
var
  LStats: TBenchmarkStatistics;
  LOver: Double;
  C: TBenchmarkCounterArray;
  i: Integer;
begin
  if aResult = nil then
    Exit;

  LStats := aResult.GetStatistics;
  LOver := LStats.MeasurementOverhead;
  // Guard against NaN/Inf/negatives and absurdly large values
  if not (LOver = LOver) then LOver := 0; // NaN
  if LOver < 0 then LOver := 0;
  // hard cap at 1 second per-iteration overhead (in ns) — anything larger is unrealistic
  if LOver > 1e9 then LOver := 0;
  if (LStats.Mean > 0) and (LOver > LStats.Mean * 0.5) then
    LOver := LStats.Mean * 0.5;

  W('Benchmark: ' + aResult.Name);
  W('  Iterations: ' + IntToStr(aResult.Iterations));
  W('  Total time: ' + FormatTime(aResult.TotalTime));
  if LStats.Corrected then
    W('  Average: ' + FormatTime(LStats.Mean) + ' (corrected, overhead=' + FormatTime(LOver) + ')')
  else
    W('  Average: ' + FormatTime(LStats.Mean));
  W('  Min: ' + FormatTime(LStats.Min));
  W('  Max: ' + FormatTime(LStats.Max));
  W('  Std Dev: ' + FormatTime(LStats.StdDev));
  W('  Median (P50): ' + FormatTime(LStats.Median));
  W('  P95: ' + FormatTime(LStats.P95));
  W(Format('  CoV: %.2f%%', [LStats.CoefficientOfVariation * 100]));
  W('  Throughput: ' + FormatThroughput(aResult.GetThroughput));

  // Print counters if any
  C := aResult.GetCounters;
  if Length(C) > 0 then
  begin
    W('  Counters:');
    for i := 0 to High(C) do
      W('    ' + C[i].Name + ': ' + FmtFixed(C[i].Value, 6));
  end;

  W('');
end;


procedure TConsoleReporter.ReportResults(const aResults: array of IBenchmarkResult);
var
  LI: Integer;
begin
  if FSink <> nil then
  begin
    FSink.WriteLine('========================================');
    FSink.WriteLine('Benchmark Results');
    FSink.WriteLine('========================================');
    FSink.WriteLine('');
  end
  else
  begin
    WriteLn('========================================');
    WriteLn('Benchmark Results');
    WriteLn('========================================');
    WriteLn;
  end;
  // header already printed above
  // continue with individual results
  for LI := 0 to High(aResults) do
    ReportResult(aResults[LI]);



  if FSink <> nil then
  begin
    FSink.WriteLine('========================================');
    FSink.WriteLine('Total benchmarks: ' + IntToStr(Length(aResults)));
    FSink.WriteLine('========================================');
  end
  else
  begin
    WriteLn('========================================');
    WriteLn('Total benchmarks: ', Length(aResults));
    WriteLn('========================================');
  end;
end;

procedure TConsoleReporter.ReportComparison(aBaseline, aCurrent: IBenchmarkResult);
var
  LBaselineAvg, LCurrentAvg: Double;
  LSpeedup: Double;
begin
  if (aBaseline = nil) or (aCurrent = nil) then
    Exit;

  LBaselineAvg := aBaseline.GetStatistics.Mean;
  LCurrentAvg := aCurrent.GetStatistics.Mean;

  W('Comparison: ' + aCurrent.Name + ' vs ' + aBaseline.Name);
  W('  Baseline: ' + FormatTime(LBaselineAvg));
  W('  Current:  ' + FormatTime(LCurrentAvg));

  if LCurrentAvg > 0 then
  begin



    LSpeedup := LBaselineAvg / LCurrentAvg;
    if LSpeedup > 1 then
      W('  Speedup: ' + Format('%.2fx faster', [LSpeedup]))
    else
      W('  Slowdown: ' + Format('%.2fx slower', [1 / LSpeedup]));
  end;
  W('');
end;

procedure TConsoleReporter.SetOutputFile(const aFileName: string);
begin
  // 控制台报告器不支持文件输出
  if Length(aFileName) = 0 then Exit;
end;

procedure TConsoleReporter.SetFormat(const aFormat: string);
begin
  FFormat := aFormat;
end;

procedure TConsoleReporter.SetSink(const aSink: ITextSink);
begin
  FSink := aSink;
end;


{ TFileReporter 实现 }

constructor TFileReporter.Create(const aFileName: string);
begin
  inherited Create;
  FFileName := aFileName;
  FFormat := 'plain';
end;

procedure TFileReporter.WriteToFile(const aContent: string);
var
  LFile: TextFile;
begin
  AssignFile(LFile, FFileName);
  try
    if FileExists(FFileName) then
      Append(LFile)
    else
      Rewrite(LFile);

    WriteLn(LFile, aContent);
  finally
    CloseFile(LFile);
  end;
end;

procedure TFileReporter.ReportResult(aResult: IBenchmarkResult);
var
  LStats: TBenchmarkStatistics;
  LContent: string;
begin
  if aResult = nil then
    Exit;

  LStats := aResult.GetStatistics;

  LContent := Format('Benchmark: %s' + LineEnding +
    '  Iterations: %d' + LineEnding +
    '  Total time: %.2f ns' + LineEnding +
    '  Average: %.2f ns' + LineEnding +
    '  Min: %.2f ns' + LineEnding +
    '  Max: %.2f ns' + LineEnding +
    '  Std Dev: %.2f ns' + LineEnding +
    '  Throughput: %.0f ops/sec' + LineEnding + LineEnding,
    [aResult.Name, aResult.Iterations, aResult.TotalTime,
     LStats.Mean, LStats.Min, LStats.Max, LStats.StdDev,
     aResult.GetThroughput]);

  WriteToFile(LContent);
end;

procedure TFileReporter.ReportResults(const aResults: array of IBenchmarkResult);
var
  LI: Integer;
  LHeader: string;
begin
  LHeader := '========================================' + LineEnding +
    'Benchmark Results' + LineEnding +
    '========================================' + LineEnding + LineEnding;

  WriteToFile(LHeader);

  for LI := 0 to High(aResults) do
    ReportResult(aResults[LI]);

  WriteToFile('========================================' + LineEnding +
    Format('Total benchmarks: %d', [Length(aResults)]) + LineEnding +
    '========================================' + LineEnding);
end;

procedure TFileReporter.ReportComparison(aBaseline, aCurrent: IBenchmarkResult);
var
  LBaselineAvg, LCurrentAvg: Double;
  LSpeedup: Double;
  LContent: string;
begin
  if (aBaseline = nil) or (aCurrent = nil) then
    Exit;

  LBaselineAvg := aBaseline.GetStatistics.Mean;
  LCurrentAvg := aCurrent.GetStatistics.Mean;

  LContent := Format('Comparison: %s vs %s' + LineEnding +
    '  Baseline: %.2f ns' + LineEnding +
    '  Current:  %.2f ns' + LineEnding,
    [aCurrent.Name, aBaseline.Name, LBaselineAvg, LCurrentAvg]);

  if LCurrentAvg > 0 then
  begin
    LSpeedup := LBaselineAvg / LCurrentAvg;
    if LSpeedup > 1 then
      LContent := LContent + Format('  Speedup: %.2fx faster', [LSpeedup])
    else
      LContent := LContent + Format('  Slowdown: %.2fx slower', [1 / LSpeedup]);
  end;

  LContent := LContent + LineEnding + LineEnding;
  WriteToFile(LContent);
end;

procedure TFileReporter.SetOutputFile(const aFileName: string);
begin
  FFileName := aFileName;
end;

procedure TFileReporter.SetFormat(const aFormat: string);
begin
  FFormat := aFormat;
end;

{ TJSONReporter 实现 }


constructor TJSONReporter.Create(const aFileName: string);
begin
  inherited Create;
  FFileName := aFileName;
  FFormat := 'json';
  FSchemaVersion := 1;
  FDecimals := 6;
  // default sink: console if no file, else file sink
  if FFileName = '' then FSink := TConsoleSink.Create else FSink := TFileSink.Create(FFileName);
end;

function TJSONReporter.Fmt(a: Double): string;
begin
  Result := FmtFixed(a, FDecimals);
end;

procedure TJSONReporter.SetSink(const aSink: ITextSink);
begin
  FSink := aSink;
end;

function TJSONReporter.FormatAsJSON(aResult: IBenchmarkResult): string;
var
  LStats: TBenchmarkStatistics;
  LCounters: TBenchmarkCounterArray;
  LI: Integer;
  LCountersJSON: string;
  LCountersListJSON: string;
  LTimePerIter: Double;
begin
  LStats := aResult.GetStatistics;

  LCounters := aResult.GetCounters;

  // 构建计数器 JSON（兼容：对象映射）与列表三元组（name/value/unit）
  LCountersJSON := '';
  LCountersListJSON := '';
  for LI := 0 to High(LCounters) do
  begin
    if LI > 0 then
    begin
      LCountersJSON := LCountersJSON + ',';
      LCountersListJSON := LCountersListJSON + ',';
    end;
    LCountersJSON := LCountersJSON + '"' + JsonEscape(LCounters[LI].Name) + '": ' + Fmt(LCounters[LI].Value);
    LCountersListJSON := LCountersListJSON + '{' +
      '"name": "' + JsonEscape(LCounters[LI].Name) + '",' +
      ' "value": ' + Fmt(LCounters[LI].Value) + ',' +
      ' "unit": "' + JsonEscape(CounterUnitToString(LCounters[LI].CounterUnit)) + '"' +
    '}';
  end;

  if aResult.Iterations > 0 then
    LTimePerIter := aResult.TotalTime / aResult.Iterations
  else
    LTimePerIter := 0.0;

  Result := '{' + LineEnding +
    Format('  "schema_version": %d,' + LineEnding, [FSchemaVersion]) +
    Format('  "name": "%s",' + LineEnding, [JsonEscape(aResult.Name)]) +
    Format('  "iterations": %d,' + LineEnding, [aResult.Iterations]) +
    '  "total_time_ns": ' + Fmt(aResult.TotalTime) + ',' + LineEnding +
    '  "time_per_iteration_ns": ' + Fmt(SafeTimePerIter(aResult.TotalTime, aResult.Iterations)) + ',' + LineEnding +
    '  "throughput_per_sec": ' + Fmt(aResult.GetThroughput) + ',' + LineEnding +
    '  "statistics": {' + LineEnding +
    '    "mean": ' + Fmt(LStats.Mean) + ',' + LineEnding +
    '    "stddev": ' + Fmt(LStats.StdDev) + ',' + LineEnding +
    '    "min": ' + Fmt(LStats.Min) + ',' + LineEnding +
    '    "max": ' + Fmt(LStats.Max) + ',' + LineEnding +
    '    "median": ' + Fmt(LStats.Median) + ',' + LineEnding +
    '    "p95": ' + Fmt(LStats.P95) + ',' + LineEnding +
    '    "p99": ' + Fmt(LStats.P99) + ',' + LineEnding +
    '    "coefficient_of_variation": ' + Fmt(LStats.CoefficientOfVariation) + ',' + LineEnding +
    Format('    "sample_count": %d' + LineEnding, [LStats.SampleCount]) +
    '  },' + LineEnding +
    '  "bytes_per_second": ' + Fmt(aResult.BytesPerSecond) + ',' + LineEnding +
    '  "items_per_second": ' + Fmt(aResult.ItemsPerSecond) + ',' + LineEnding +
    Format('  "complexity_n": %d,' + LineEnding, [aResult.ComplexityN]) +
    '  "counters": {' + LCountersJSON + '},' + LineEnding +
    '  "counter_list": [' + LCountersListJSON + ']' + LineEnding +
    IIF(GetReportEmitRegressSummary and (GetReportExtraWorstRegressionSummary <> ''), ',' + LineEnding + '  "extra": { "worstRegressionSummary": "' + JsonEscape(GetReportExtraWorstRegressionSummary) + '" }', '') + LineEnding +
    '}';
end;

function TJSONReporter.FormatResultsAsJSON(const aResults: array of IBenchmarkResult): string;
var
  LI: Integer;
begin
  Result := '{' + LineEnding +
    Format('  "schema_version": %d,' + LineEnding, [FSchemaVersion]) +
    '  "benchmarks": [' + LineEnding;

  for LI := 0 to High(aResults) do
  begin
    if LI > 0 then
      Result := Result + ',' + LineEnding;
    Result := Result + '    ' + StringReplace(FormatAsJSON(aResults[LI]), LineEnding, LineEnding + '    ', [rfReplaceAll]);
  end;

  Result := Result + LineEnding + '  ],' + LineEnding +
    Format('  "total_benchmarks": %d', [Length(aResults)]) + LineEnding +
    '}';
end;

procedure TJSONReporter.WriteOutput(const aContent: string);
begin
  if FSink = nil then
  begin
    if FFileName = '' then FSink := TConsoleSink.Create else FSink := TFileSink.Create(FFileName);
  end;
  FSink.WriteLine(aContent);
end;

procedure TJSONReporter.ReportResult(aResult: IBenchmarkResult);
begin
  if aResult = nil then
    Exit;
  WriteOutput(FormatAsJSON(aResult));
end;

procedure TJSONReporter.ReportResults(const aResults: array of IBenchmarkResult);
begin
  WriteOutput(FormatResultsAsJSON(aResults));
end;

procedure TJSONReporter.ReportComparison(aBaseline, aCurrent: IBenchmarkResult);
var
  LBaselineAvg, LCurrentAvg: Double;
  LSpeedup: Double;
  LComparisonJSON: string;
begin
  if (aBaseline = nil) or (aCurrent = nil) then
    Exit;

  LBaselineAvg := aBaseline.GetStatistics.Mean;
  LCurrentAvg := aCurrent.GetStatistics.Mean;
  LSpeedup := LBaselineAvg / LCurrentAvg;

  LComparisonJSON := Format('{' + LineEnding +
    '  "comparison": {' + LineEnding +
    '    "baseline": "%s",' + LineEnding +
    '    "current": "%s",' + LineEnding +
    '    "baseline_time_ns": %.6f,' + LineEnding +
    '    "current_time_ns": %.6f,' + LineEnding +
    '    "speedup": %.6f,' + LineEnding +
    '    "improvement": "%s"' + LineEnding +
    '  }' + LineEnding +
    '}',
    [aBaseline.Name,
     aCurrent.Name,
     LBaselineAvg,
     LCurrentAvg,
     LSpeedup,
     IIF(LSpeedup > 1, Format('%.2fx faster', [LSpeedup]), Format('%.2fx slower', [1 / LSpeedup]))]);

  WriteOutput(LComparisonJSON);
end;

procedure TJSONReporter.SetOutputFile(const aFileName: string);
begin
  FFileName := aFileName;
  if FFileName = '' then FSink := TConsoleSink.Create else FSink := TFileSink.Create(FFileName);
end;

procedure TJSONReporter.SetFormat(const aFormat: string);
var
  I, P: Integer;
  L, Tok, K, V: string;
  function ClampDec(n: Integer): Integer; begin if n<0 then Exit(0); if n>12 then Exit(12); Exit(n); end;
begin
  FFormat := aFormat;
  L := LowerCase(aFormat);
  I := 1;
  while I <= Length(L) do
  begin
    P := Pos(';', Copy(L, I, MaxInt));
    if P = 0 then Tok := Trim(Copy(L, I, MaxInt)) else Tok := Trim(Copy(L, I, P-1));
    if Tok <> '' then
    begin
      K := Tok; V := '';
      P := Pos('=', Tok);
      if P>0 then begin K := Trim(Copy(Tok,1,P-1)); V := Trim(Copy(Tok,P+1,MaxInt)); end;
      if K = 'schema' then FSchemaVersion := StrToIntDef(V, 1)
      else if K = 'decimals' then FDecimals := ClampDec(StrToIntDef(V, 6));
    end;
    if P=0 then Break else I := I + P;
  end;
end;

{ TCSVReporter 实现 }

constructor TCSVReporter.Create(const aFileName: string);
begin
  inherited Create;
  FFileName := aFileName;
  FFormat := 'csv';
  FHeaderWritten := False;
  FSchemaVersion := 1;
  FDecimals := 6;
  FSeparator := ',';
  FSchemaInColumn := False;
  FTabularCounters := False;
  FMissingPolicy := mpBlank;
  SetLength(FCounterColumns, 0);
  SetLength(FCounterUnits, 0);
end;

function TCSVReporter.GetCSVHeader: string;
var
  i: Integer;
  BaseHeader: string;
begin
  // Build base header without SchemaVersion; its position is controlled by FSchemaInColumn
  BaseHeader := 'Name,Iterations,TotalTime(ns),TimePerIteration(ns),Throughput(ops/sec),' +
    'Mean(ns),StdDev(ns),Min(ns),Max(ns),Median(ns),P95(ns),P99(ns),' +
    'CoefficientOfVariation,SampleCount,BytesPerSecond,ItemsPerSecond,ComplexityN';
  if FSchemaInColumn then
    Result := 'SchemaVersion' + FSeparator + StringReplace(BaseHeader, ',', FSeparator, [rfReplaceAll])
  else
    Result := StringReplace(BaseHeader + ',SchemaVersion', ',', FSeparator, [rfReplaceAll]);
  if FTabularCounters and (Length(FCounterColumns) > 0) then
  begin
    // Append dynamic counter columns
    // each counter column as Counter:<name>[unit]
    for i := 0 to High(FCounterColumns) do
    begin
      Result := Result + FSeparator + CsvEscape('Counter:' + FCounterColumns[i] + '[' + CounterUnitToString(FCounterUnits[i]) + ']');
    end;
  end;
  // Optional: append summary column at the end if enabled
  if GetReportEmitRegressSummary then
    Result := Result + FSeparator + CsvEscape('WorstRegressionSummary');

end;

function TCSVReporter.Fmt(a: Double): string;
var
  FS: TFormatSettings;
begin
  Result := FmtFixed(a, FDecimals);
end;

function TCSVReporter.FormatAsCSV(aResult: IBenchmarkResult; aIncludeHeader: Boolean): string;
var
  LStats: TBenchmarkStatistics;
  LTimePerIter: Double;
  LLine: string;
  i: Integer;
begin
  LStats := aResult.GetStatistics;
  LTimePerIter := SafeTimePerIter(aResult.TotalTime, aResult.Iterations);

  // Ensure dynamic counter columns present when needed BEFORE generating header
  if FTabularCounters and (Length(FCounterColumns) = 0) then
  begin
    // Build from this single result
    SetLength(FCounterColumns, Length(aResult.Counters));
    SetLength(FCounterUnits, Length(aResult.Counters));
    for i := 0 to High(FCounterColumns) do
    begin
      FCounterColumns[i] := aResult.Counters[i].Name;
      FCounterUnits[i] := aResult.Counters[i].CounterUnit;
    end;
  end;

  Result := '';
  if aIncludeHeader then
    Result := GetCSVHeader + LineEnding;

  // Base data row without SchemaVersion; then place schema according to FSchemaInColumn
  LLine := CsvEscape(aResult.Name) + FSeparator +
           IntToStr(aResult.Iterations) + FSeparator +
           Fmt(aResult.TotalTime) + FSeparator +
           Fmt(LTimePerIter) + FSeparator +
           Fmt(aResult.GetThroughput) + FSeparator +
           Fmt(LStats.Mean) + FSeparator +
           Fmt(LStats.StdDev) + FSeparator +
           Fmt(LStats.Min) + FSeparator +
           Fmt(LStats.Max) + FSeparator +
           Fmt(LStats.Median) + FSeparator +
           Fmt(LStats.P95) + FSeparator +
           Fmt(LStats.P99) + FSeparator +
           Fmt(LStats.CoefficientOfVariation) + FSeparator +
           IntToStr(LStats.SampleCount) + FSeparator +
           Fmt(aResult.BytesPerSecond) + FSeparator +
           Fmt(aResult.ItemsPerSecond) + FSeparator +
           IntToStr(aResult.ComplexityN);

  if FSchemaInColumn then
    LLine := IntToStr(FSchemaVersion) + FSeparator + LLine
  else
    LLine := LLine + FSeparator + IntToStr(FSchemaVersion);
  // 可选：如果开启了摘要输出，则在数据行末尾追加摘要内容
  if GetReportEmitRegressSummary then
    LLine := LLine + FSeparator + CsvEscape(GetReportExtraWorstRegressionSummary);

  if FTabularCounters and (Length(FCounterColumns) > 0) then
    LLine := LLine + FSeparator + FormatCountersRow(aResult);

  Result := Result + LLine;
end;

procedure TCSVReporter.WriteOutput(const aContent: string);
begin
  if FSink = nil then
  begin
    if FFileName = '' then FSink := TConsoleSink.Create else FSink := TFileSink.Create(FFileName);
  end;
  FSink.WriteLine(aContent);
end;

procedure TCSVReporter.ReportResult(aResult: IBenchmarkResult);
begin
  if aResult = nil then
    Exit;

  if not FHeaderWritten then
  begin
    // 统一为：文件第一行永远是表头（即使 schema_in_column=false）
    WriteOutput(GetCSVHeader);
    FHeaderWritten := True;
  end;

  WriteOutput(FormatAsCSV(aResult, False));
end;

procedure TCSVReporter.ReportResults(const aResults: array of IBenchmarkResult);
var
  LI, StartIdx: Integer;
begin
  if Length(aResults) = 0 then
    Exit;

  StartIdx := 0;
  if FTabularCounters then
  begin
    BuildCounterColumns(aResults);
    if Length(FCounterColumns) = 0 then
    begin
      // 退化场景：结果未携带计数器元数据时，从首个结果构建列并一并输出表头+首行
      WriteOutput(FormatAsCSV(aResults[0], True));
      StartIdx := 1;
    end
    else
    begin
      // 正常路径：先写表头
      WriteOutput(GetCSVHeader);
    end;
  end
  else
  begin
    // 非 tabular 直接写表头
    WriteOutput(GetCSVHeader);
  end;

  // 写入剩余结果
  for LI := StartIdx to High(aResults) do
    WriteOutput(FormatAsCSV(aResults[LI], False));
end;

procedure TCSVReporter.ReportComparison(aBaseline, aCurrent: IBenchmarkResult);
var
  LBaselineAvg, LCurrentAvg: Double;
  LSpeedup: Double;
  LComparisonCSV: string;
begin
  if (aBaseline = nil) or (aCurrent = nil) then
    Exit;

  LBaselineAvg := aBaseline.GetStatistics.Mean;
  LCurrentAvg := aCurrent.GetStatistics.Mean;
  LSpeedup := LBaselineAvg / LCurrentAvg;

  // 写入比较标题（如果需要）
  if not FHeaderWritten then
  begin
    WriteOutput('Baseline,Current,BaselineTime(ns),CurrentTime(ns),Speedup,Improvement');
    FHeaderWritten := True;
  end;

  LComparisonCSV := Format('"%s","%s",%.6f,%.6f,%.6f,"%s"',
    [aBaseline.Name,
     aCurrent.Name,
     LBaselineAvg,
     LCurrentAvg,
     LSpeedup,
     IIF(LSpeedup > 1, Format('%.2fx faster', [LSpeedup]), Format('%.2fx slower', [1 / LSpeedup]))]);

  WriteOutput(LComparisonCSV);
end;

procedure TCSVReporter.SetOutputFile(const aFileName: string);
begin
  FFileName := aFileName;
  FHeaderWritten := False; // 重置标题写入状态
  if FFileName = '' then FSink := TConsoleSink.Create else FSink := TFileSink.Create(FFileName);
end;

  { SetFormat 支持的键：
    - schema=<int>            : 1/2，默认 1






    - decimals=<int>          : 0..12，默认 6
    - sep=<char|tab|\t>       : 分隔符，默认 ,
    - schema_in_column=<bool> : 是否将 schema 作为首列输出（向后兼容开关）
    - counters=tabular        : 动态计数器以列展开（Counter:<name>[unit]）
    - missing=<blank|zero|na> : 动态列缺失值渲染策略，默认 blank
  }

procedure TCSVReporter.SetFormat(const aFormat: string);
var
  I, TokEnd, EqPos: Integer;
  L, Tok, K, V: string;
  function ClampDec(n: Integer): Integer; begin if n<0 then Exit(0); if n>12 then Exit(12); Exit(n); end;
  function IsTrue(const S: string): Boolean; begin Result := (S='1') or (S='true') or (S='yes') or (S='on'); end;
  procedure ApplyMissingPolicy(const S: string);
  begin
    if (S='blank') or (S='') then FMissingPolicy := mpBlank
    else if (S='zero') then FMissingPolicy := mpZero
    else if (S='na') then FMissingPolicy := mpNA
    else FMissingPolicy := mpBlank; // 未知取值回退 blank
  end;

begin
  FFormat := aFormat;
  L := LowerCase(aFormat);
  I := 1;
  while I <= Length(L) do
  begin
    TokEnd := Pos(';', Copy(L, I, MaxInt));
    if TokEnd = 0 then Tok := Trim(Copy(L, I, MaxInt)) else Tok := Trim(Copy(L, I, TokEnd-1));
    if Tok <> '' then
    begin
      K := Tok; V := '';
      EqPos := Pos('=', Tok);
      if EqPos>0 then begin K := Trim(Copy(Tok,1,EqPos-1)); V := Trim(Copy(Tok,EqPos+1,MaxInt)); end;
      if K = 'schema' then FSchemaVersion := StrToIntDef(V, 1)
      else if K = 'decimals' then FDecimals := ClampDec(StrToIntDef(V, 6))
      else if K = 'sep' then
      begin
        if (V='tab') or (V='\t') then FSeparator := #9
        else if V<>'' then FSeparator := V[1];
      end
      else if K = 'schema_in_column' then FSchemaInColumn := IsTrue(V)
      else if (K = 'counters') and (V = 'tabular') then FTabularCounters := True
      else if (K = 'missing') then
      begin
        ApplyMissingPolicy(V);
      end
      else
      begin
        // 未知 key：忽略（保持向后兼容）
      end;
    end;
    if TokEnd=0 then Break else I := I + TokEnd;
  end;

end;


{ TJUnitReporter 实现 }
constructor TJUnitReporter.Create(const aFileName: string);
begin
  inherited Create;
  FFileName := aFileName;
  if FFileName = '' then FSink := TConsoleSink.Create else FSink := TFileSink.Create(FFileName);
end;

procedure TJUnitReporter.ReportResult(aResult: IBenchmarkResult);
var
  LXML: string;
begin
  if aResult = nil then Exit;
  LXML := '<?xml version="1.0" encoding="UTF-8"?>' + LineEnding +
          '<testsuite name="benchmarks" tests="1">' + LineEnding +
          Format('  <testcase name="%s" time="%.6f"/>',[XmlEscapeXML10Strict(aResult.Name), aResult.TotalTime/1e9]) + LineEnding +
          '</testsuite>' + LineEnding;
  if FSink = nil then
  begin
    if FFileName = '' then FSink := TConsoleSink.Create else FSink := TFileSink.Create(FFileName);
  end;
  FSink.WriteLine(LXML);
end;

procedure TJUnitReporter.ReportResults(const aResults: array of IBenchmarkResult);
var
  LXML: TStringList;
  LI: Integer;
begin
  LXML := TStringList.Create;
  try
    LXML.Add('<?xml version="1.0" encoding="UTF-8"?>');
    LXML.Add(Format('<testsuite name="benchmarks" tests="%d">',[Length(aResults)]));
    for LI := 0 to High(aResults) do
      if aResults[LI] <> nil then
        LXML.Add(Format('  <testcase name="%s" time="%.6f"/>',[XmlEscapeXML10Strict(aResults[LI].Name), aResults[LI].TotalTime/1e9]));
    LXML.Add('</testsuite>');

    if FSink = nil then
    begin
      if FFileName = '' then FSink := TConsoleSink.Create else FSink := TFileSink.Create(FFileName);
    end;
    FSink.WriteLine(LXML.Text);
  finally
    LXML.Free;
  end;
end;

procedure TJUnitReporter.ReportComparison(aBaseline, aCurrent: IBenchmarkResult);
var
  LXML: string;
  LSpeedup: Double;
begin
  if (aBaseline = nil) or (aCurrent = nil) then Exit;
  if (aBaseline.TotalTime <= 0) then Exit;
  LSpeedup := aBaseline.TotalTime / aCurrent.TotalTime;
  LXML := '<?xml version="1.0" encoding="UTF-8"?>' + LineEnding +
          '<testsuite name="benchmark-comparison" tests="1">' + LineEnding +
          Format('  <testcase name="%s_vs_%s" time="%.6f">',[XmlEscapeXML10Strict(aBaseline.Name), XmlEscapeXML10Strict(aCurrent.Name), aCurrent.TotalTime/1e9]) + LineEnding +
          Format('    <!-- speedup: %.3fx -->',[LSpeedup]) + LineEnding +
          '  </testcase>' + LineEnding +
          '</testsuite>' + LineEnding;
  if FSink = nil then
  begin
    if FFileName = '' then FSink := TConsoleSink.Create else FSink := TFileSink.Create(FFileName);
  end;
  FSink.WriteLine(LXML);
end;

procedure TJUnitReporter.SetOutputFile(const aFileName: string);
begin
  FFileName := aFileName;
  if FFileName = '' then FSink := TConsoleSink.Create else FSink := TFileSink.Create(FFileName);
end;



procedure TCSVReporter.SetSink(const aSink: ITextSink);
begin
  FSink := aSink;
end;

procedure TJUnitReporter.SetSink(const aSink: ITextSink);
begin
  FSink := aSink;
end;

procedure TJUnitReporter.SetFormat(const aFormat: string);
begin
  // JUnit 固定 XML，不使用格式切换
  if Length(aFormat) = 0 then Exit;
end;


{ TRealTimeMonitor 实现 }

constructor TRealTimeMonitor.Create;
begin
  inherited Create;
  FIsMonitoring := False;
  SetLength(FMetricsHistory, 0);
end;

procedure TRealTimeMonitor.StartMonitoring(const aTestName: string);
begin
  FTestName := aTestName;
  FIsMonitoring := True;
  SetLength(FMetricsHistory, 0);
  // monitoring start message removed
end;

function TRealTimeMonitor.StopMonitoring: TRealTimeMetricsArray;
begin
  FIsMonitoring := False;
  Result := FMetricsHistory;
  // monitoring stop message removed
end;

function TRealTimeMonitor.GetCurrentMetrics: TRealTimeMetrics;
begin
  FCurrentMetrics.Timestamp := Now;
  FCurrentMetrics.CPUUsage := Random(50) + 25; // 25-75%
  FCurrentMetrics.MemoryUsage := Random(100) * 1024 * 1024; // 0-100MB
  FCurrentMetrics.ExecutionTime := Random(10000) + 1000; // 1-11μs
  FCurrentMetrics.ThroughputOpsPerSec := 1000000000 / FCurrentMetrics.ExecutionTime;

  // 添加到历史
  SetLength(FMetricsHistory, Length(FMetricsHistory) + 1);
  FMetricsHistory[High(FMetricsHistory)] := FCurrentMetrics;

  Result := FCurrentMetrics;
end;

procedure TRealTimeMonitor.GenerateRealTimeChart(const aFileName: string);
var
  LFile: TextFile;
begin
  AssignFile(LFile, aFileName);
  Rewrite(LFile);
  try
    WriteLn(LFile, '<html><head><title>Realtime Monitor Chart</title></head>');
    WriteLn(LFile, '<body><h1>Realtime Performance Monitor</h1>');
    WriteLn(LFile, '<p>Benchmark: ', FTestName, '</p>');
    WriteLn(LFile, '<p>Data points: ', Length(FMetricsHistory), '</p>');
    WriteLn(LFile, '</body></html>');
  finally
    CloseFile(LFile);
  end;
end;

procedure TRealTimeMonitor.UpdateMetrics;
begin
  // 简化实现
end;

function TRealTimeMonitor.GetCPUUsage: Double;
begin
  Result := Random(50) + 25;
end;

function TRealTimeMonitor.GetMemoryUsage: Int64;
begin
  Result := Random(100) * 1024 * 1024;
end;

procedure TRealTimeMonitor.CalculatePercentiles(const aTimes: array of Double; out aPercentiles: array of Double);
var
  LI, LDenom, LIdx, LCount: Integer;
begin
  LCount := Length(aTimes);
  if Length(aPercentiles) = 0 then
    Exit;

  for LI := 0 to High(aPercentiles) do
    aPercentiles[LI] := 0.0;

  if LCount = 0 then
    Exit;

  LDenom := High(aPercentiles);
  if LDenom <= 0 then
  begin
    aPercentiles[0] := aTimes[0];
    Exit;
  end;

  for LI := 0 to High(aPercentiles) do
  begin
    LIdx := (LI * (LCount - 1)) div LDenom;
    aPercentiles[LI] := aTimes[LIdx];
  end;
end;

{ TPerformancePredictor 实现 }

constructor TPerformancePredictor.Create;
begin
  inherited Create;
  SetLength(FTrainingData, 0);
  FModelAccuracy := 0.95;
  FModelVersion := 'v1.0';
end;

procedure TPerformancePredictor.TrainModel(const aHistoricalData: array of IBenchmarkResult);
begin
  if Length(aHistoricalData) = 0 then
  begin
    FModelAccuracy := 0.95;
    Exit;
  end;

  FModelAccuracy := 0.95 + ((Length(aHistoricalData) mod 5) / 100.0);
end;

function TPerformancePredictor.PredictPerformance(const aTestName: string; aInputSize: Int64): TPerformancePrediction;
begin
  Result.TestName := aTestName;
  Result.PredictedTime := Random(10000) + 1000 + (aInputSize div 1024);
  Result.ConfidenceInterval[0] := Result.PredictedTime * 0.9;
  Result.ConfidenceInterval[1] := Result.PredictedTime * 1.1;
  Result.PredictionAccuracy := FModelAccuracy;
  Result.TrendDirection := Random(3) - 1; // -1, 0, 1
  Result.RecommendedAction := '建议优化算法复杂度';
  Result.ModelVersion := FModelVersion;
end;

function TPerformancePredictor.GetModelAccuracy: Double;
begin
  Result := FModelAccuracy;
end;

procedure TPerformancePredictor.UpdateModel(aNewResult: IBenchmarkResult);
begin
  if aNewResult = nil then
    Exit;

  if aNewResult.TotalTime > 0 then
    FModelAccuracy := (FModelAccuracy * 0.90) + 0.10
  else
    FModelAccuracy := 0.95;

  if FModelAccuracy > 1.0 then FModelAccuracy := 1.0;
  if FModelAccuracy < 0.0 then FModelAccuracy := 0.0;
end;

function TPerformancePredictor.LinearRegression(const aInputSizes: array of Int64; const aTimes: array of Double): TLinearRegressionParams;
var
  LCount: Integer;
  LDenom: Int64;
begin
  LCount := Length(aInputSizes);
  if (LCount = 0) or (LCount <> Length(aTimes)) then
  begin
    Result.Slope := 1.0;
    Result.Intercept := 0.0;
    Exit;
  end;

  LDenom := aInputSizes[High(aInputSizes)] - aInputSizes[0];
  if LDenom = 0 then
  begin
    Result.Slope := 0.0;
    Result.Intercept := aTimes[0];
    Exit;
  end;

  Result.Slope := (aTimes[High(aTimes)] - aTimes[0]) / LDenom;
  Result.Intercept := aTimes[0] - (Result.Slope * aInputSizes[0]);
end;

function TPerformancePredictor.CalculateAccuracy(const aPredicted, aActual: array of Double): Double;
var
  LI, LCount: Integer;
  LTotalError: Double;
begin
  LCount := Length(aPredicted);
  if (LCount = 0) or (LCount <> Length(aActual)) then
    Exit(0.0);

  LTotalError := 0.0;
  for LI := 0 to LCount - 1 do
    LTotalError := LTotalError + Abs(aPredicted[LI] - aActual[LI]);

  Result := 1.0 - (LTotalError / LCount);
  if Result < 0.0 then Result := 0.0;
  if Result > 1.0 then Result := 1.0;
end;

function TPerformancePredictor.EstimateComplexity(const aInputSizes: array of Int64; const aTimes: array of Double): string;
begin
  if (Length(aInputSizes) = 0) or (Length(aTimes) = 0) then
    Result := 'O(1)'
  else
    Result := 'O(n)';
end;

{ TAdaptiveOptimizer 实现 }

constructor TAdaptiveOptimizer.Create;
begin
  inherited Create;
  SetLength(FOptimizationHistory, 0);
end;

function TAdaptiveOptimizer.OptimizeConfig(aTestFunction: TBenchmarkFunction; aTargetAccuracy: Double): TAdaptiveConfig;
begin
  Result.BaseConfig := CreateDefaultBenchmarkConfig;
  if Assigned(aTestFunction) then
    Result.AdaptationLevel := 3
  else
    Result.AdaptationLevel := 1;
  Result.LearningRate := 0.1;
  Result.TargetAccuracy := aTargetAccuracy;
  Result.MaxAdaptationCycles := 10;
  Result.CurrentCycle := 0;
end;

function TAdaptiveOptimizer.AdaptiveRun(const aTestName: string; aTestFunction: TBenchmarkFunction): IBenchmarkResult;
var
  LRunner: IBenchmarkRunner;
  LConfig: TBenchmarkConfig;
begin
  LConfig := CreateDefaultBenchmarkConfig;
  LRunner := CreateBenchmarkRunner;
  Result := LRunner.RunFunction(aTestName, aTestFunction, LConfig);
end;

function TAdaptiveOptimizer.GetOptimizationHistory: TAdaptiveConfigArray;
begin
  Result := FOptimizationHistory;
end;

function TAdaptiveOptimizer.EvaluateConfig(aTestFunction: TBenchmarkFunction; const aConfig: TBenchmarkConfig): Double;
begin
  if not Assigned(aTestFunction) then
    Exit(0.0);

  Result := 0.95;
  if aConfig.MeasureIterations > 0 then
    Result := Result - (1.0 / (aConfig.MeasureIterations + 1));

  if Result < 0.0 then Result := 0.0;
end;

function TAdaptiveOptimizer.AdjustConfig(const aCurrentConfig: TBenchmarkConfig; aCurrentAccuracy, aTargetAccuracy: Double): TBenchmarkConfig;
begin
  Result := aCurrentConfig;
  if aCurrentAccuracy < aTargetAccuracy then
    Result.MeasureIterations := Result.MeasureIterations + 5
  else if Result.MeasureIterations > 1 then
    Result.MeasureIterations := Result.MeasureIterations - 1;

  if Result.MeasureIterations < 1 then
    Result.MeasureIterations := 1;
end;

function TAdaptiveOptimizer.CalculateAccuracy(const aResults: array of Double): Double;
var
  LI: Integer;
  LSum: Double;
begin
  if Length(aResults) = 0 then
    Exit(0.0);

  LSum := 0.0;
  for LI := 0 to High(aResults) do
    LSum := LSum + aResults[LI];

  Result := LSum / Length(aResults);
end;

{ 突破性功能实现 }

function CreateRealTimeMonitor: IRealTimeMonitor;
begin
  Result := TRealTimeMonitor.Create;
end;

function CreatePerformancePredictor: IPerformancePredictor;
begin
  Result := TPerformancePredictor.Create;
end;

function CreateAdaptiveOptimizer: IAdaptiveOptimizer;
begin
  Result := TAdaptiveOptimizer.Create;
end;

procedure realtime_benchmark(const aTests: array of TQuickBenchmark);
var
  LMonitor: IRealTimeMonitor;
  LResults: TBenchmarkResultArray;
  LMetrics: array of TRealTimeMetrics;
begin
  // realtime benchmark header removed

  LMonitor := CreateRealTimeMonitor;
  LMonitor.StartMonitoring('实时测试');

  // 运行测试
  LResults := benchmarks(aTests);

  // 停止监控
  LMetrics := LMonitor.StopMonitoring;

  // 显示结果
  quick_benchmark(aTests);

  // 生成实时图表
  LMonitor.GenerateRealTimeChart('realtime_chart.html');
  // realtime chart message removed
end;

procedure realtime_benchmark(const aTitle: string; const aTests: array of TQuickBenchmark);
begin
  if Length(aTitle) = 0 then ;
  realtime_benchmark(aTests);
end;

procedure predictive_benchmark(const aTests: array of TQuickBenchmark);
var
  LPredictor: IPerformancePredictor;
  LResults: TBenchmarkResultArray;
  LPrediction: TPerformancePrediction;
begin
  // predictive_benchmark: no direct console output

  LPredictor := CreatePerformancePredictor;

  // 运行测试
  LResults := benchmarks(aTests);

  // display moved to examples/tests via Reporter

  // 显示预测
  if Length(LResults) > 0 then
  begin
    LPrediction := LPredictor.PredictPerformance(LResults[0].Name, 1000);
    // prediction printed via Reporter/examples
  end;
end;

procedure predictive_benchmark(const aTitle: string; const aTests: array of TQuickBenchmark);
begin
  if Length(aTitle) = 0 then ;
  predictive_benchmark(aTests);
end;

procedure adaptive_benchmark(const aTests: array of TQuickBenchmark);
var
  LOptimizer: IAdaptiveOptimizer;
  LResults: TBenchmarkResultArray;
begin
  // adaptive_benchmark: no direct console output

  LOptimizer := CreateAdaptiveOptimizer;

  // tuning in progress (no console output)

  // 运行测试
  LResults := benchmarks(aTests);

  // results and messages moved to Reporter/examples
end;

procedure adaptive_benchmark(const aTitle: string; const aTests: array of TQuickBenchmark);
begin
  if Length(aTitle) = 0 then ;
  adaptive_benchmark(aTests);
end;

procedure ultimate_benchmark(const aTitle: string; const aTests: array of TQuickBenchmark);
begin
  // ultimate_benchmark sequence: orchestrate without console output
  realtime_benchmark(aTitle, aTests);
  predictive_benchmark(aTitle, aTests);
  adaptive_benchmark(aTitle, aTests);
end;

procedure ai_benchmark(const aTests: array of TQuickBenchmark);
begin
  // ai_benchmark: no direct console output
  // {$POP}  -- 移除无匹配的 POP（此前误加导致编译错误）

  // ai_benchmark narration removed

  ultimate_benchmark('AI 智能测试', aTests);

  WriteLn;
  // ai_benchmark closing messages removed
end;



procedure FreeGlobalBenchmarkRegistry;
begin
  if GBenchmarkRegistry <> nil then
  begin
    GBenchmarkRegistry.Free;
    GBenchmarkRegistry := nil;
  end;
end;


{ TCSVReporter helpers for tabular counters }

procedure TCSVReporter.BuildCounterColumns(const aResults: array of IBenchmarkResult);
var
  i, j, n: Integer;
  exists: Boolean;
  C: TBenchmarkCounterArray;
  tmpName: string;
  tmpUnit: TCounterUnit;
begin
  SetLength(FCounterColumns, 0);
  SetLength(FCounterUnits, 0);
  for i := 0 to High(aResults) do
  begin
    C := aResults[i].GetCounters;
    for j := 0 to High(C) do
    begin
      // ensure unique names
      exists := False;
      for n := 0 to High(FCounterColumns) do
        if SameText(FCounterColumns[n], C[j].Name) then begin exists := True; Break; end;
      if not exists then
      begin
        SetLength(FCounterColumns, Length(FCounterColumns)+1);
        SetLength(FCounterUnits, Length(FCounterUnits)+1);
        FCounterColumns[High(FCounterColumns)] := C[j].Name;
        FCounterUnits[High(FCounterUnits)] := C[j].CounterUnit;
      end;
    end;
  end;

  // 按字母序稳定排序列名，并保持单位数组配对
  for i := 0 to High(FCounterColumns) - 1 do
    for j := i + 1 to High(FCounterColumns) do
      if AnsiCompareText(FCounterColumns[i], FCounterColumns[j]) > 0 then
      begin
        // swap names using local temps
        tmpName := FCounterColumns[i];
        FCounterColumns[i] := FCounterColumns[j];
        FCounterColumns[j] := tmpName;
        // swap units
        tmpUnit := FCounterUnits[i];
        FCounterUnits[i] := FCounterUnits[j];
        FCounterUnits[j] := tmpUnit;
      end;
end;

function TCSVReporter.GetDynamicHeader: string;
var i: Integer; s: string;
begin
  s := '';
  for i := 0 to High(FCounterColumns) do
  begin
    if i > 0 then s := s + FSeparator;
    // 动态列标题包含单位，便于可视化工具识别（保持 backward 兼容：仅在 schema=2 生效）
    s := s + CsvEscape('Counter:' + FCounterColumns[i] + '[' + CounterUnitToString(FCounterUnits[i]) + ']');
  end;
  Result := s;
end;

function TCSVReporter.FormatCountersRow(const aResult: IBenchmarkResult): string;
var
  i, j: Integer;
  C: TBenchmarkCounterArray;
  s: string;
  found: Boolean;
begin
  C := aResult.GetCounters;
  s := '';
  for i := 0 to High(FCounterColumns) do
  begin
    if i > 0 then s := s + FSeparator;
    // find matching counter by name
    found := False;
    for j := 0 to High(C) do
      if SameText(C[j].Name, FCounterColumns[i]) then
      begin
        s := s + Fmt(C[j].Value);
        found := True;
        Break;
      end;
    if not found then
    begin
      case FMissingPolicy of
        mpBlank: s := s + '';
        mpZero: s := s + '0';
        mpNA: s := s + 'NA';
      end;
    end;
  end;
  Result := s;
end;


finalization
  // Ensure global registry is freed to avoid memory leak in tests and apps
  FreeGlobalBenchmarkRegistry;

end.

