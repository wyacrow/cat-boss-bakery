## 1. EventBus 信号清理

- [x] 1.1 从 `scripts/core/EventBus.gd` 删除 `signal auto_merge_toggled(enabled: bool)` 信号声明（第23行）
- [x] 1.2 更新 `_ready()` 中的信号计数打印（如有） — 无需修改，使用动态 `get_signal_list().size()`

## 2. 设计文档更新

- [x] 2.1 更新 `cat_bakery_merge_design.md` §四 合成系统 — 删除"自动合成""冲突处理""开关"三个子节，保留手动合成描述
- [x] 2.2 更新 `cat_bakery_merge_design.md` §四 EventBus 信号签名 — 删除 `auto_merge_toggled` 条目；§五 删除"自动合成必须手动开启"约束；§七 更新决策 #5（合成方式）和 #6（信号数量）
- [x] 2.3 更新 `cat_bakery_engineering_v1.md` §四.4 合成系统 — 删除"自动可选（连锁0.1s间隔）"和"自动合成由grid_changed信号触发扫描"描述
- [x] 2.4 更新 `cat_bakery_engineering_v1.md` §五 通信系统 — 删除 `auto_merge_toggled(enabled: bool)` 条目，更新信号数从 7→6

## 3. CLAUDE.md 更新

- [x] 3.1 从 `CLAUDE.md` 的 Required EventBus signals 列表中删除 `auto_merge_toggled(enabled: bool)` 条目

## 4. 验证

- [x] 4.1 全局搜索 `auto_merge` 确认无残留引用（仅归档变更 `generate-core-gameplay` 和当前变更 `remove-auto-merge` 中有引用，符合预期）
- [x] 4.2 确认 MergeSystem.gd 中无自动合成相关代码（当前为纯 `try_merge` 函数，保持不变）
