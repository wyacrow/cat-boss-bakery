## 1. 音频素材迁移

- [ ] 1.1 将 `cat_bakery_sfx_v3/assets/sounds/` 下的所有 wav 文件复制到 `assets/sounds/`，保持目录结构（ambient/board/cat/generator/merge/order/resource/ui）
- [ ] 1.2 确认 Godot 为每个 wav 文件生成 `.import` 文件

## 2. AudioManager Autoload

- [ ] 2.1 创建 `scripts/core/AudioManager.gd`，extends Node，包含：SFX 池（8 个 AudioStreamPlayer）、BGM 独立 AudioStreamPlayer、sound_manifest 解析、`play_sfx(id)`、`play_bgm(id)`、`stop_bgm()` 方法
- [ ] 2.2 在 `project.godot` 中注册 `AudioManager` 为 Autoload
- [ ] 2.3 实现 manifest CSV 解析：`_ready()` 中读取 `res://assets/sounds/sound_manifest.csv`，构建 `{id: {path, volume, priority}}` 字典
- [ ] 2.4 实现按需加载与缓存：`ResourceLoader.load()` 首次加载音频，存入 `Dictionary[String, AudioStream]` 缓存
- [ ] 2.5 实现 SFX 池分配逻辑：空闲优先，全忙时复用最早播放器
- [ ] 2.6 实现 BGM 播放器：单曲循环，切换时停止上一曲

## 3. EventBus 事件监听

- [ ] 3.1 AudioManager `_ready()` 中连接 `merge_done` → 按 `result_item.level` 播放对应合成音效
- [ ] 3.2 连接 `order_completed` → 按 `reward_gold` 档位播放对应订单完成音效
- [ ] 3.3 连接 `gold_changed` → 增量 > 0 时播放 `coin_gain`
- [ ] 3.4 连接 `order_generated` → 播放 `order_refresh_soft`

## 4. 系统接入音效

- [ ] 4.1 ItemCellButton: `_play_press_sfx()` 和 `_play_release_sfx()` 接入 `ui_button_tap_soft`
- [ ] 4.2 ItemCellButton: 拖动开始 `_start_dragging()` 中调用 `item_pickup_paw`
- [ ] 4.3 ItemCellButton: 物品移动成功 `_do_move_to_empty()` 中调用 `item_drop_paw`
- [ ] 4.4 ItemCellButton: 拖放取消 `_finish_drag()` 中调用 `invalid_merge_meow`
- [ ] 4.5 MergeSystem: `try_merge()` 返回 null 时接入 `invalid_merge_meow`
- [ ] 4.6 GridBoard: 生成器点击接入 `bakery_basket_tap_rustle`，生成成功接入 `bakery_item_spawn_plop`，棋盘满时接入 `board_full_meow`
- [ ] 4.7 OrderSystem: 订单可提交时接入 `order_ready_meow`

## 5. BGM 环境音

- [ ] 5.1 GameScene `_ready()` 或适当位置调用 `AudioManager.play_bgm("bakery_cat_room_loop")`

## 6. 验证测试

- [ ] 6.1 运行项目，验证主场景 BGM 循环播放
- [ ] 6.2 操作棋盘：点击格子、拖拽合成、拖放取消 → 验证对应 SFX 播放
- [ ] 6.3 完成订单 → 验证订单层级音效 + 金币音效同时播放不冲突
- [ ] 6.4 无报错，控制台无异常日志
