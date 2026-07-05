## Why

简化架构：移除 InventorySystem 和 CollectSystem，改为订单直接从棋盘扫描扣除物品（类似浪漫餐厅模式）。减少系统数量、消除单向数据流中的缓冲层、缩短核心循环路径。

## What Changes

- **REMOVED** InventorySystem — 不再需要独立库存
- **REMOVED** CollectSystem — 不再需要三击收取
- **REMOVED** 3 个 EventBus 信号：`collect_request`, `collect_done`, `collect_failed`, `inventory_changed`
- **MODIFIED** OrderSystem：`inventory_system` → `grid_board`，直接从棋盘校验+扣除
- **MODIFIED** GridBoard：新增 `has_items()` / `remove_items()` 查询接口
- **MODIFIED** ItemCellButton：移除三击收取逻辑
- **MODIFIED** CLAUDE.md / 设计文档：同步更新架构描述

## Capabilities

### New Capabilities
<!-- 无新增 capability -->

### Modified Capabilities
- `order-system`: 订单提交从 Inventory 改为 GridBoard 直接操作

## Impact

- `scripts/systems/GridBoard.gd` — 新增 has_items/remove_items
- `scripts/systems/OrderSystem.gd` — inventory_system → grid_board
- `scripts/ui/components/item_cell_button.gd` — 移除 collect_request 信号和 triple-tap
- `scripts/core/EventBus.gd` — 移除 4 个信号
- `scripts/core/GameScene.gd` — 新增 _get_grid_board helper
- `CLAUDE.md` — 更新规则/信号/数据流
- `cat_bakery_merge_design.md` — 移除 Collection/Inventory 章节
- `cat_bakery_engineering_v1.md` — 更新系统列表/信号/数据流
