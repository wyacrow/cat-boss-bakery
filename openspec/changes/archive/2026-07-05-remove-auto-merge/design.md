## Context

当前系统设计中，MergeSystem 包含手动合成和自动合成两种模式。自动合成模式（实时扫描 + 0.1s 连锁 + 开关按钮）自 V1 原型阶段起就未被实现，且已被明确列为"刻意不做"项。保留该设计增加了不必要的复杂度：EventBus 多一个 `auto_merge_toggled` 信号，设计文档多三个子节描述自动合成行为，MergeSystem 代码中需预留 `toggle_auto_merge()` 方法和扫描逻辑的接口。

本设计将 MergeSystem 简化为**纯手动二合**：玩家选中两个同 type 同 level 的物品 → 执行合成 → 发出 `merge_done` 和 `grid_changed`。这是典型的 merge-2 游戏的标准模式（如 Triple Town、2048 的手动变体）。

## Goals / Non-Goals

**Goals:**
- 从设计文档中彻底删除自动合成的所有描述
- 从 EventBus 中删除 `auto_merge_toggled` 信号
- 简化 MergeSystem 规格，只保留手动二合逻辑

**Non-Goals:**
- 不改变手动合成的核心逻辑（2×LvN → LvN+1, Lv4 终点）
- 不改变 GridBoard 的合并接口
- 不影响订单系统、生成器系统、猫咪系统
- 不在 V1 中重新引入自动合成

## Decisions

### D1: 彻底删除 vs 标记为"未实现"

**选择**: 彻底删除自动合成设计，不留 TODO 或注释。

**理由**: 自动合成与游戏核心设计理念（玩家手动操作、策略性选择合成时机）冲突。如果未来需要自动合成，可以从 git 历史恢复。保留死代码和未实现的信号只会增加维护负担。

**备选**: 保留 `auto_merge_enabled` 字段但永远为 false → 拒绝，因为增加无意义的代码路径。

### D2: EventBus 信号处理

**选择**: 直接删除 `auto_merge_toggled` 信号，信号数量从 7 减为 6。

**理由**: 该信号唯一的生产者和消费者（MergeSystem toggle + UI toggle button）都不存在。保留无用信号违反"信号精简"原则。

### D3: 设计文档更新范围

**选择**: 只修改涉及自动合成的文件，不重写整份设计文档。

**范围**:
1. `cat_bakery_merge_design.md` §四 — 删除"自动合成""冲突处理""开关"三个子节
2. `cat_bakery_engineering_v1.md` §四.4 — 删除自动合成描述
3. `CLAUDE.md` — 删除 `auto_merge_toggled` 信号条目

## Risks / Trade-offs

- **[低风险] 未来可能重新需要自动合成**: git 历史中保留了完整设计，可以随时恢复。且自动合成更适合"挂机"类 idle game，而本作是主动操作的 merge-2 游戏。
- **[无风险] 现有代码不受影响**: MergeSystem.gd 当前只含 `try_merge` 纯逻辑，没有自动合成代码。EventBus 中 `auto_merge_toggled` 信号无任何 emit 或 connect 调用。
