## Context

项目已有 28 个音效素材文件（`cat_bakery_sfx_v3/assets/sounds/`），附带 `sound_manifest.csv` 定义了每个音效的触发场景、优先级和推荐音量。当前游戏系统中有 `_play_press_sfx()` / `_play_release_sfx()` 空占位方法，但没有任何实际音频播放能力。

按项目架构惯例（EventBus Autoload + 各系统独立脚本），需要新增一个 AudioManager Autoload 作为全局音频入口。

## Goals / Non-Goals

**Goals:**
- V1 实现 SFX 播放：按钮、棋盘、合成、订单、金币等核心操作的音效反馈
- V1 实现环境 BGM 低音量循环
- 提供简洁的 API：`AudioManager.play_sfx("sfx_id")` + `AudioManager.play_bgm("bgm_id")`
- 利用现有 `sound_manifest.csv` 作为音效注册表，避免硬编码路径
- 接入现有 EventBus 信号（如 `merge_done`、`order_completed`、`gold_changed`）自动触发音效

**Non-Goals:**
- V1 不做音量设置 UI（音量常量在代码中，后续可加设置面板）
- V1 不做静音切换 UI
- 不做音频淡入淡出效果
- 不做空间音频（3D/定位音效）
- 不做对话打字音效（已预留 `sfx` 字段但 V1 不处理）

## Decisions

### 1. AudioManager 架构

```
AudioManager (Autoload, extends Node)
├── AudioStreamPlayer "BGMMusic"     → 单曲 BGM 循环
├── AudioStreamPlayer "SFX_1"        → SFX 池 (8 个播放器)
├── AudioStreamPlayer "SFX_2"
├── ...
└── AudioStreamPlayer "SFX_8"
```

- **SFX 池化**：8 个 AudioStreamPlayer 应对短时间内的多个音效叠加（如合成连锁 + 金币 + 订单完成同时发生）。超过池容量时放弃最老的播放。
- **BGM 独立播放器**：单个 AudioStreamPlayer 专用于背景音乐循环。
- **不引入 AudioStreamPlayer2D/3D**：游戏为纯 2D UI，无需空间定位。

**替代方案**：使用 Godot 内置的 AudioServer 直接播 — 但缺乏池管理；用单个 AudioStreamPlayer — 无法同时播放多个 SFX。

### 2. 音效加载策略

- 使用 `ResourceLoader.load()` 按需加载音效，首次 `play_sfx(id)` 时加载并缓存到 `Dictionary[String, AudioStream]`
- 不预加载所有 28 个音频（节省启动内存）
- `sound_manifest.csv` 在 `_ready()` 中解析为内部字典，提供 `id → {path, volume, priority}` 映射

### 3. 音效 ID 命名

直接使用 `sound_manifest.csv` 中的文件名（不含扩展名）作为 ID：

```
ui_button_tap_soft, ui_toast_notice,
item_pickup_paw, item_drop_paw, invalid_merge_meow, board_full_meow, item_delete_puff,
bakery_basket_tap_rustle, bakery_item_spawn_plop, coffee_machine_tap_steam, coffee_item_spawn_pour, coffee_bean_clink, oven_ding_bright,
merge_success_lv2_3, merge_success_lv4_5, merge_success_lv6_meow,
order_ready_meow, order_complete_quick_meow, order_complete_normal_meow, order_complete_big_meow, order_refresh_soft,
coin_gain, exp_gain_twinkle, reward_pop,
cat_unlock_happy, cat_purr_short_loop,
bakery_cat_room_loop
```

**替代方案**：自定义短 ID（如 `click`、`merge_1`）— 增加映射层，不必要。

### 4. 音效触发方式

两层触发：

| 方式 | 场景 | 示例 |
|---|---|---|
| **EventBus 监听** | 领域事件发生，AudioManager 自行决定播哪个音效 | `merge_done` → `merge_success_lvX` |
| **直接调用** `AudioManager.play_sfx(id)` | 系统内 UI 行为，无对应 EventBus 信号 | 按钮点击 → `AudioManager.play_sfx("ui_button_tap_soft")` |

AudioManager 在 `_ready()` 中连接 EventBus 信号，内部维护事件→音效映射。

### 5. 音频文件迁移

从 `cat_bakery_sfx_v3/assets/sounds/` 复制到 `assets/sounds/`，按原目录结构保持分类：

```
assets/sounds/
├── ambient/   → bakery_cat_room_loop.wav
├── board/     → *.wav
├── cat/       → *.wav
├── generator/ → *.wav
├── merge/     → *.wav
├── order/     → *.wav
├── resource/  → *.wav
└── ui/        → *.wav
```

同时将 `sound_manifest.csv` 中的路径前缀从 `assets/sounds/` 更新为 `res://assets/sounds/`。

### 6. SFX 操作方法接入点

| 操作 | 音效 ID | 接入位置 |
|---|---|---|
| 点击按钮/格子 | `ui_button_tap_soft` | `ItemCellButton._play_press_sfx()` |
| 拾起物品 | `item_pickup_paw` | `ItemCellButton._start_dragging()` |
| 放入空格 | `item_drop_paw` | `ItemCellButton._do_move_to_empty()` |
| 无效操作 | `invalid_merge_meow` | `MergeSystem.try_merge()` 返回 null 时 / 拖放取消时 |
| 棋盘满 | `board_full_meow` | `GeneratorSystem` 生成失败时 |
| 合成 Lv2-3 | `merge_success_lv2_3` | EventBus `merge_done` 信号，按 result_item.level |
| 合成 Lv4-5 | `merge_success_lv4_5` | 同上 |
| 合成 Lv6 | `merge_success_lv6_meow` | 同上（V1 最大 Lv4，预留） |
| 订单就绪 | `order_ready_meow` | OrderSystem 检测满足需求时 |
| 订单完成 | `order_complete_*_meow` | EventBus `order_completed`，按 reward 档位 |
| 订单刷新 | `order_refresh_soft` | EventBus `order_generated` |
| 金币增加 | `coin_gain` | EventBus `gold_changed`（增量>0时） |
| 生成器点击 | `bakery_basket_tap_rustle` | GeneratorSystem 触发时 |
| 产物出现 | `bakery_item_spawn_plop` | GeneratorSystem 生成后 |
| BGM | `bakery_cat_room_loop` | 进入主场景自动播放 |

## Risks / Trade-offs

- **池满时丢弃音效** → SFX 池设为 8 已超过游戏实际并发需求（最多 3-4 个同时），基本不会触发
- **首播延迟** → 按需加载意味着第一次播放某音效时有 I/O 延迟。V1 可接受（wav 文件很小），后续可在场景切换时预加载热音效
- **音量硬编码** → 无用户调节入口。manifest 中已有推荐音量值，将其作为初始化默认值
- **manifest 的 import 文件** → 观察到已有 `.wav.import` 文件但音频文件本身在 `cat_bakery_sfx_v3/` 下。迁移时需要确保 Godot 正确重新导入
