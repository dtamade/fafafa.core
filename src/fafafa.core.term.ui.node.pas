unit fafafa.core.term.ui.node;

{$mode objfpc}{$H+}

interface

uses
  fafafa.core.term,
  ui_node; // 暂复用实现

type
  IUiNode = ui_node.IUiNode;
  TStackRootNode = ui_node.TStackRootNode;
  TBannerNode = ui_node.TBannerNode;
  TStatusBarNode = ui_node.TStatusBarNode;
  TPanelNode = ui_node.TPanelNode;
  TVBoxNode = ui_node.TVBoxNode;
  THBoxNode = ui_node.THBoxNode;

implementation
end.

