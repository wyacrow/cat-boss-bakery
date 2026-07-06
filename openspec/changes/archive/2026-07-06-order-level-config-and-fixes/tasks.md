## Tasks

- [x] 新建 `scripts/data/LevelConfig.gd` 关卡配表（level_01 + level_02）
- [x] 重写 `scripts/systems/OrderSystem.gd` 为关卡队列驱动（移除定时/随机生成，新增 load_level/_fill_slots/队列）
- [x] 微调 `scripts/data/OrderData.gd` 新增 level_id 字段
- [x] 微调 `scripts/core/EventBus.gd` 新增 level_completed/level_loaded/order_slot_freed 信号
- [x] 微调 `scripts/core/GameStat.gd` 移除重复 progress emit
- [x] 微调 `scripts/core/GameScene.gd` 新增 load_level 调用
- [x] 动画结束后补入订单：order_bar_manager.gd 动画完成 emit order_slot_freed
- [x] 生成器图标放大 1.2x：item_cell_button.gd _setup_generator_visual 中 scale + pivot_offset
- [x] 体力上限 50：StaminaSystem.gd max_stamina = 50
- [x] 运行验证无报错
