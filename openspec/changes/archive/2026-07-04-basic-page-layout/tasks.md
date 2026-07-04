## 1. 场景结构搭建

**比例要求（参考 gameplay_scene.png）**：
- A 区（顶部 HUD+ 订单）：约 **26.9%** 屏幕高度（2.5/9.3）
- B 区（棋盘）：约 **53.8%** 屏幕高度（5/9.3，最大区域）
- C 区（底部控制栏）：约 **19.4%** 屏幕高度（1.8/9.3）
- **布局方式**：使用 VBoxContainer 垂直排列，三个区域均设置 `size_flags_vertical = SIZE_EXPAND`

- [x] 1.1 创建 `scenes/GameScene.tscn` 主场景根节点（Control 类型，目标分辨率 1080×1920 竖屏）
- [x] 1.2 在根节点下添加 MainVBox（VBoxContainer），包含 A 区容器（custom_minimum_size y=516）
- [x] 1.3 在 MainVBox 下添加 B 区容器（custom_minimum_size y=1032）
- [x] 1.4 在 MainVBox 下添加 C 区容器（custom_minimum_size y=372）

## 2. A 区 - 顶部 HUD 和订单栏

**A 区内部比例**：
- TopHUDBar：约 **40%** A 区高度（~216px）
- OrderBar：约 **60%** A 区高度（~324px）

- [x] 2.1 在 A 区添加 TopHUDBar（Control，锚定右上角，高度约 216px）
- [x] 2.2 在 TopHUDBar 内添加 HBoxContainer（右对齐，separation: 16）
- [x] 2.3 添加 SettingsButton 占位（ColorRect 蓝色，48×48）
- [x] 2.4 添加 GoldDisplay 占位（ColorRect 黄色，120×48）
- [x] 2.5 添加 StaminaBar 占位（ColorRect 青色，160×48）
- [x] 2.6 在 A 区添加 OrderBar（Control，高度约 324px，位于 TopHUDBar 下方）
- [x] 2.7 在 OrderBar 内添加 3 个 OrderSlot 占位（ColorRect 橙色，120×100，左对齐间距 16px）

## 3. B 区 - 棋盘网格

**B 区要求**：占据屏幕约 52% 高度，是页面最大区域。棋盘应居中显示，四周留有适当边距。

- [x] 3.1 在 B 区添加 GridBoard 容器（PanelContainer 或 Control，四周 margin: 32px）
- [x] 3.2 在 GridBoard 内添加 GridContainer（6 列，separation: 8，居中）
- [x] 3.3 创建 36 个 ItemCellButton 占位（Button + ColorRect 绿色，80×80）
- [x] 3.4 验证棋盘网格在编辑器中显示为 6×6 均匀布局，且整体居中

## 4. C 区 - 底部控制栏

**C 区要求**：约占屏幕 20% 高度，容器居中放置，内部元素水平排列。

- [x] 4.1 在 C 区添加 BottomPanel 容器（Control，锚定底部居中，宽度约 900px）
- [x] 4.2 在 BottomPanel 内添加 HBoxContainer（居中对齐，separation: 16）
- [x] 4.3 添加 GeneratorButton 占位（ColorRect 紫色，80×80）
- [x] 4.4 添加 ItemInfoPanel 占位（ColorRect 灰色，200×80）
- [x] 4.5 添加 AutoMergeToggle 占位（ColorRect 红色，60×60）

## 5. 验证和预览

- [ ] 5.1 在 Godot 编辑器中打开 GameScene.tscn，确认所有元件可见
- [ ] 5.2 确认各区域颜色区分明显，可识别元件边界
- [ ] 5.3 确认棋盘 36 个按钮均匀分布
- [ ] 5.4 **验证 ABC 三区比例**：A 区~28%、B 区~20%、C 区~20% 屏幕高度
- [ ] 5.5 截图或记录预览效果，与参考图 `cankao/gameplay_scene.png` 对比确认布局一致
