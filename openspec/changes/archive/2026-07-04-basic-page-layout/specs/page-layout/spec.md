## ADDED Requirements

### Requirement: 主场景三区布局
主场景 SHALL 包含三个垂直排列的区域：A 区（顶部 HUD+ 订单）、B 区（棋盘）、C 区（底部控制栏）。

#### Scenario: 场景结构正确
- **WHEN** 在 Godot 编辑器中打开 `GameScene.tscn`
- **THEN** 场景树包含 A 区、B 区、C 区三个主要容器节点

### Requirement: A 区 - 顶部 HUD
TopHUDBar SHALL 锚定右上角，内部元素从右向左排列（设置按钮、金币、体力）。

#### Scenario: HUD 位置正确
- **WHEN** 场景加载完成
- **THEN** TopHUDBar 显示在屏幕右上角，元素右对齐

### Requirement: A 区 - 订单栏
OrderBar SHALL 包含 3 个 OrderSlot，左对齐排列，每个 OrderSlot 为独立 Control 节点。

#### Scenario: 订单槽位排列
- **WHEN** 场景加载完成
- **THEN** 3 个 OrderSlot 从左到右水平排列，间距一致

### Requirement: B 区 - 棋盘网格
GridBoard SHALL 使用 GridContainer 布局 36 个 ItemCellButton 节点（6×6）。

#### Scenario: 棋盘网格正确
- **WHEN** 场景加载完成
- **THEN** 棋盘区域显示 6 行 6 列共 36 个按钮，间距均匀

### Requirement: C 区 - 底部控制栏
BottomPanel SHALL 居中放置，内部使用 HBoxContainer 水平排列生成器按钮、物品信息面板、自动合成开关。

#### Scenario: 底部栏布局正确
- **WHEN** 场景加载完成
- **THEN** 底部控制栏水平居中，三个元素等间距排列

### Requirement: 占位图片填充
每个容器和元件 SHALL 使用 ColorRect 或 TextureRect 填充占位颜色，用于预览大小。

#### Scenario: 占位颜色可见
- **WHEN** 在 Godot 编辑器中预览场景
- **THEN** 每个元件都有明显的颜色填充，可区分不同元件的边界和大小
