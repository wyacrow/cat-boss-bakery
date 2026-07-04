## Why

需要快速验证主游戏场景的 UI 布局结构和各元件的视觉比例关系。通过预创建场景 + 占位图片填充，可以在编写任何游戏逻辑之前，先确认页面布局是否符合设计预期，便于早期发现布局问题。

## What Changes

- 创建主场景 `GameScene.tscn`，包含 A/B/C 三个区域的容器结构
- A 区（顶部）：TopHUDBar（右上角锚点）+ OrderBar（左对齐 OrderSlot ×3）
- B 区（棋盘）：GridContainer 预创建 36 个 ItemCellButton 节点
- C 区（底部）：居中容器 + HBoxContainer 水平排列生成器/物品信息/自动合成开关
- 每个容器和元件都挂载占位图片（Placeholder Image），用于预览大小和位置
- 不编写任何游戏逻辑代码，仅搭建场景结构和视觉预览

## Capabilities

### New Capabilities

- `page-layout`: 主游戏场景的 UI 布局结构，包含所有容器和占位元件

### Modified Capabilities

（无）

## Impact

- 新增场景文件：`scenes/GameScene.tscn`
- 新增 UI 元件场景：`scenes/ui/TopHUDBar.tscn`, `scenes/ui/OrderBar.tscn`, `scenes/ui/OrderSlot.tscn`, `scenes/ui/GridBoard.tscn`, `scenes/ui/ItemCellButton.tscn`, `scenes/ui/BottomPanel.tscn`
- 需要占位图片资源（可使用 Godot 内置 ColorRect 或简单纹理）
- 不影响现有系统代码
