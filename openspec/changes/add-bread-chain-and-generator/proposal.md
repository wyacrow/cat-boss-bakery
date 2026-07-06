## Why

当前项目处于调试期，仅开放了饮品链（drink）用于原型验证。面包（bread）素材已准备就绪（6 张 resized-bread*.png），但合成链、订单、生成器均未接入。需要正式激活面包链，并放置独立的烘焙生成器，让两条合成链并行运转，为 V1 完整三链开通做铺垫。

## What Changes

- **ResourceDB 面包纹理映射**：将 bread_1~4 的纹理从占位 food.png 替换为实际 resized-bread*.png 素材
- **GeneratorSystem 支持类型化生成器**：新增 `generator_type` 属性，让每个生成器指定产出物品类型（drink/bread），替代当前硬编码的 `["drink"]`
- **棋盘新增面包生成器**：在现有饮品生成器（Cell_8_3）旁边新增一个面包生成器（烘焙机），产出 bread 链物品
- **ItemCellButton 支持生成器图标区分**：饮品生成器显示咖啡机图标，面包生成器显示烘焙机图标
- **OrderSystem 扩展物品池**：`ITEM_TYPES` 从 `["drink"]` 扩展为 `["drink", "bread"]`，订单需求覆盖两条合成链
- **GridBoard 初始物品扩展**：棋盘初始放置中新增 bread 链物品

## Capabilities

### New Capabilities
- `typed-generator`: 生成器支持类型标识，不同生成器产出不同物品链的 Lv1 物品

### Modified Capabilities
- `resource-db`: 面包链纹理映射从占位图替换为实际素材
- `order-system`: 物品类型池从单链扩展为多链（bread + drink）
- `board-skill-system`: 棋盘新增 bread 生成器格位，初始物品布局包含 bread 链

## Impact

| 文件 | 变更类型 |
|---|---|
| `scripts/data/ResourceDB.gd` | 修改 — bread 纹理路径映射 |
| `scripts/systems/GeneratorSystem.gd` | 修改 — 新增 generator_type 属性 |
| `scripts/systems/OrderSystem.gd` | 修改 — 扩展 ITEM_TYPES 池 |
| `scripts/systems/GridBoard.gd` | 修改 — 支持多个类型化生成器 |
| `scripts/ui/components/item_cell_button.gd` | 修改 — 按 generator_type 切换图标 |
| `scenes/GameScene.tscn` | 修改 — 新增面包生成器格位 |
| `scenes/ui/cell_button.tscn` | 修改 — 可能无需改动（图标由代码控制） |
