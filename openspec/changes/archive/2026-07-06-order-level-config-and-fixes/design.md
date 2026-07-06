## Design

### 订单队列机制

关卡订单不再全部同时展示，而是通过队列控制：

```
LevelConfig 关卡定义 N 个订单
       ↓
OrderSystem 持有 _order_queue（未展示的订单）
       ↓
2 个槽位填满（优先显示队列头部）
       ↓
提交订单 → 槽位清空 → 等消失动画 → order_slot_freed 信号 → 从队列补入
       ↓
队列空 + 槽位全空 → 关卡完成 → load_level(next)
```

### 信号流

```
submit_order()
  → order_completed.emit()          # GameStat 加金币、EffectsSystem 播特效
  → 清空槽位，不立即 fill
  → OrderBarManager 播消失动画
  → _on_slot_removed()
    → order_slot_freed.emit()       # 动画完成通知
    → OrderSystem._fill_slots()     # 补入下一个订单
```

### LevelConfig 数据结构

```gdscript
const LEVELS = {
    "level_01": {
        "name": "初来乍到",
        "orders": [
            {"requirements": {"drink_2": 1}, "base_reward": 20, "customer_cat": "tabby"},
            ...
        ],
    },
}
```

### 生成器图标缩放

在 `_setup_generator_visual()` 中设置 `scale = Vector2(1.2, 1.2)`，并通过 `call_deferred` 将 `pivot_offset` 设为中心点，避免偏移。
