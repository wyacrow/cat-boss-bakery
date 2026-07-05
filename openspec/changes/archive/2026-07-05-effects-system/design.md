# EffectsSystem 设计文档

## 架构位置

```
GameScene (Control)
├── MainVBox
│   └── AreaB_Grid/GridBoard
├── OrderSystem
└── EffectsSystem (Node)          ← 独立特效系统
```

## 控制流

```
┌─ EventBus 驱动（游戏事件） ─────────────────────┐
│  EventBus.order_completed → 金币飘字浮标         │
│  EventBus.gold_changed    → 数字跳动动画         │
└─────────────────────────────────────────────────┘

┌─ 直接调用（交互反馈） ──────────────────────────┐
│  ItemCellButton._can_drop_data                  │
│    → EffectsSystem.show_merge_hint(pos, item)   │
│    → EffectsSystem.hide_any_hint()              │
└─────────────────────────────────────────────────┘
```

## 合并提示状态机

```
         show_merge_hint()
              │
    ┌─────────▼──────────┐
    │    appearing        │  scale 0→2.0, alpha 0→0.3 (0.18s ease_out)
    └─────────┬──────────┘
              │ tween 完成
    ┌─────────▼──────────┐
    │    breathing        │  scale 2.0↔2.1 (0.7s sine 循环)
    └─────────┬──────────┘
              │ hide_any_hint()
    ┌─────────▼──────────┐
    │    disappearing     │  scale →0, alpha →0 (0.12s ease_in)
    └─────────┬──────────┘
              │ tween 完成
              ▼
         _kill_hint()  →  queue_free
```

### 快速切换处理

- 不同格子：`_kill_hint()` 立即 kill tween + free 节点 → 创建新提示
- 消失中拖回：`_kill_all_tweens()` → 重新 `_play_appear()`
- 拖回原位：`_can_drop_data` 检测 `from_pos == cell_position` → skip
- 拖拽结束：`NOTIFICATION_DRAG_END` → `hide_any_hint()`

## 光环视觉

- **渲染方式**：TextureRect + ShaderMaterial（`ring_glow.gdshader`）
- **动画方式**：节点 `scale` + `pivot_offset` 居中（不用 shader `scale_size`）
- **透明度控制**：`base_color.a = 0.3`（shader 层面控制中心和光环透明度）
- **配色映射**：bread=橙, dessert=粉, drink=蓝

## 注入路径

```
GameScene._ready()
  → _wire_effects_system()
    → EffectsSystem.setup(grid_board)       // 棋盘引用 + EventBus 连接
    → GridBoard.set_effects_system(effects) // 分发给 63 个 ItemCellButton
```
