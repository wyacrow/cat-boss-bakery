## Why

当前系统设计中合成系统包含"自动合成"功能（实时扫描、连锁触发、0.1s间隔），但根据7月5日状态报告，该功能已被列为"V1原型暂不实现"的刻意不做项。更重要的是，自动合成与游戏的核心设计理念——玩家手动操作、策略性选择合成时机——存在根本冲突。保留自动合成设计会增加 EventBus 信号数量、MergeSystem 复杂度、以及设计文档的认知负担，而这些成本换来的功能并不在 V1 规划中。应当从设计层面彻底删除自动合成，只保留手动二合机制。

## What Changes

- **BREAKING**: 删除 `EventBus.auto_merge_toggled` 信号
- **BREAKING**: 从 MergeSystem 设计规格中删除自动合成全部内容（扫描逻辑、连锁触发、开关按钮、`toggle_auto_merge()` 方法）
- 从 `cat_bakery_merge_design.md` §四 删除"自动合成"和"冲突处理"和"开关"三个子节
- 从 `cat_bakery_engineering_v1.md` §四.4 删除自动合成相关描述
- 从 `CLAUDE.md` 删除 `auto_merge_toggled` 信号条目
- 仅保留手动合成：玩家选中物品A → 选中物品B → type和level相同即合成 → 发出 `merge_done`

## Capabilities

### New Capabilities

- `merge-system`: 纯手动二合合成系统 — 玩家点击选中两个同type同level物品执行合成，Lv4为终点。无自动扫描、无连锁、无开关。

### Modified Capabilities

<!-- 无现有 live spec 需要修改。merge-system 和 event-bus 的 spec 仅存在于归档变更中，未被同步到 openspec/specs/。 -->

## Impact

- `scripts/core/EventBus.gd` — 删除 `auto_merge_toggled` 信号（第23行）
- `scripts/systems/MergeSystem.gd` — 保持现有核心逻辑，无需添加自动合成代码
- `cat_bakery_merge_design.md` — 删除 §四 自动合成/冲突处理/开关 三个子节
- `cat_bakery_engineering_v1.md` — 删除自动合成相关描述行
- `CLAUDE.md` — 删除 `auto_merge_toggled` 信号条目
