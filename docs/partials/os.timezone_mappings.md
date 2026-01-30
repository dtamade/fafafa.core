# Windows StandardName → IANA 时区映射（最佳努力）

说明：
- 本表用于辅助 `os_timezone_iana` 在 Windows 上将 `GetTimeZoneInformation.StandardName` 映射为 IANA 时区。
- 此映射表非完整覆盖；优先覆盖常见区域。未命中时返回空串以提示上层选择回退策略。
- 不处理夏令时切换的动态偏移，仅提供 IANA 标识供上层库处理时区规则。

当前内置映射（节选）：
- China Standard Time → Asia/Shanghai
- Tokyo Standard Time → Asia/Tokyo
- Korea Standard Time → Asia/Seoul
- Taipei Standard Time → Asia/Taipei
- Hong Kong Standard Time → Asia/Hong_Kong
- Singapore Standard Time → Asia/Singapore
- SE Asia Standard Time → Asia/Bangkok
- India Standard Time → Asia/Kolkata
- UTC → Etc/UTC
- Iran Standard Time → Asia/Tehran
- Azerbaijan Standard Time → Asia/Baku
- Georgian Standard Time → Asia/Tbilisi
- Caucasus Standard Time → Asia/Yerevan
- West Asia Standard Time → Asia/Tashkent

- GMT Standard Time → Europe/London
- Greenwich Standard Time → Atlantic/Reykjavik
- W. Europe Standard Time → Europe/Berlin
- Romance Standard Time → Europe/Paris
- Central European Standard Time → Europe/Warsaw
- Central Europe Standard Time → Europe/Budapest
- GTB Standard Time → Europe/Bucharest
- E. Europe Standard Time → Europe/Athens
- Turkey Standard Time → Europe/Istanbul
- Israel Standard Time → Asia/Jerusalem
- Russian Standard Time → Europe/Moscow
- FLE Standard Time → Europe/Kiev
- Central European Time → Europe/Prague
- Pacific Standard Time → America/Los_Angeles
- Mountain Standard Time → America/Denver
- US Mountain Standard Time → America/Phoenix
- Central Standard Time → America/Chicago
- Eastern Standard Time → America/New_York
- SA Pacific Standard Time → America/Bogota
- SA Western Standard Time → America/La_Paz
- Venezuela Standard Time → America/Caracas
- Peru Standard Time → America/Lima
- E. South America Standard Time → America/Sao_Paulo

- Atlantic Standard Time → America/Halifax
- Newfoundland Standard Time → America/St_Johns
- Greenland Standard Time → America/Nuuk
- Argentina Standard Time → America/Buenos_Aires
- SA Eastern Standard Time → America/Sao_Paulo
- Pacific SA Standard Time → America/Santiago
- W. Australia Standard Time → Australia/Perth
- AUS Eastern Standard Time → Australia/Sydney
- New Zealand Standard Time → Pacific/Auckland
- Alaskan Standard Time → America/Anchorage
- Hawaiian Standard Time → Pacific/Honolulu
- Morocco Standard Time → Africa/Casablanca
- Egypt Standard Time → Africa/Cairo
- South Africa Standard Time → Africa/Johannesburg
- Arab Standard Time → Asia/Riyadh
- Arabian Standard Time → Asia/Dubai
- Mexico Pacific Standard Time → America/Mazatlan
- Mexico Standard Time 2 → America/Chihuahua
- Central Standard Time (Mexico) → America/Mexico_City
- Eastern Standard Time (Mexico) → America/Cancun
- AUS Central Standard Time → Australia/Darwin
- Cen. Australia Standard Time → Australia/Adelaide
- E. Australia Standard Time → Australia/Brisbane
- Tasmania Standard Time → Australia/Hobart


注意：
- Windows 不同版本/区域语言的 StandardName 可能存在差异；建议在上层允许覆盖。
- IANA 名称区分大小写并采用“Region/City”格式；部分地区存在别名与历史变更，上层使用时应优先依赖时区数据库的规则解析。

