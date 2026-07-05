## 1. GridBoard 订单查询接口

- [x] 1.1 新增 `has_items(requirements: Dictionary) -> bool`
- [x] 1.2 新增 `remove_items(requirements: Dictionary) -> bool`
- [x] 1.3 新增 `_count_on_grid(key: String) -> int`
- [x] 1.4 新增 `_remove_from_grid(key: String, needed: int)`

## 2. OrderSystem 改为 GridBoard 直连

- [x] 2.1 `inventory_system` → `grid_board`
- [x] 2.2 `set_inventory()` → `set_grid_board()`
- [x] 2.3 `_validate_inventory()` → `_validate_grid()`
- [x] 2.4 `_consume_inventory()` → `_consume_grid()`
- [x] 2.5 更新注释

## 3. ItemCellButton 移除三击收取

- [x] 3.1 移除 `collect_request` 信号
- [x] 3.2 移除 `_tap_count` / `_last_tap_time` / `_TAP_INTERVAL`
- [x] 3.3 移除 `_handle_click()` / `_update_tap_counter()` / `_reset_tap_counter()`
- [x] 3.4 简化 `_on_button_up()`
- [x] 3.5 移除 `_play_collect_sfx()`

## 4. EventBus 精简信号

- [x] 4.1 移除 `inventory_changed`
- [x] 4.2 移除 `collect_request`
- [x] 4.3 移除 `collect_done`
- [x] 4.4 移除 `collect_failed`

## 5. 文档同步

- [x] 5.1 CLAUDE.md — 更新架构表/数据流/信号列表/规则
- [x] 5.2 cat_bakery_merge_design.md — 移除 Collection/Inventory 章节
- [x] 5.3 cat_bakery_engineering_v1.md — 更新系统列表/信号/数据流
