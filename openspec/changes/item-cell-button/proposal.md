## Why

ItemCellButton 是棋盘的核心交互元件，需要支持三种交互模式（单击选中、三击收取、长按拖动合并）。当前没有可复用的动画系统和交互框架，每次创建 UI 按钮都需要重复编写动画和交互逻辑。

## What Changes

- 创建 `ButtonAnimation` 动画基类，支持曲线控制（TweenTransitionType + TweenEaseType）
- 创建 `PressShrinkAnimation` 和 `ReleaseExpandAnimation` 两个派生类
- 创建 `ItemCellButton` 预制体脚本，集成：
  - 动画组件系统（即插即用）
  - 三击检测（0.8s 内点击 3 次）
  - 长按拖动检测（0.3s 长按进入拖动）
  - 选中状态管理（选中框显示/隐藏）
  - 拖动视觉反馈（半透明遮罩）
- 创建动画组件目录结构 `scripts/ui/animations/`

## Capabilities

### New Capabilities

- `button-animation-system`: 可复用的按钮动画框架，支持曲线控制和即插即用
- `item-cell-interaction`: ItemCellButton 的完整交互系统（单击/三击/拖动）

### Modified Capabilities

（无）

## Impact

- 新增目录：`scripts/ui/animations/`
- 新增脚本：`button_animation.gd`, `press_shrink_animation.gd`, `release_expand_animation.gd`
- 新增脚本：`scripts/ui/components/item_cell_button.gd`
- 后续所有 UI 按钮都可以复用动画系统
- 不影响现有系统代码
