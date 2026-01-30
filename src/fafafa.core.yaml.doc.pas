unit fafafa.core.yaml.doc;
{
  本单元为内部文档模型（fy-doc.c 占位骨架）。
  - 请通过门面单元 `fafafa.core.yaml` 访问对外 API（yaml_* / TYaml* / YAML_*）。
  - 直接依赖 TFy*/PFy* 仅用于内部实现层；对外不承诺兼容。
}


{$MODE OBJFPC}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fafafa.core.yaml.types;

// 说明：
// - 本单元为 fy-doc.c 的占位骨架

implementation

end.

