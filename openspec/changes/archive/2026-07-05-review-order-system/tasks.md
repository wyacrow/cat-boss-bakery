## 1. order_slot.tscn 场景修复（实际执行方案变更）

- [x] 1.1 ~~将 `ItemContainer` 重命名为 `RequirementsContainer`~~ **实际情况：保持原始布局不变**，ItemContainer 等节点名未修改
- [x] 1.2 新增 `AnimationPlayer` 子节点到 order_slot.tscn
- [x] 1.3 order_slot.gd 的 `_cache_children()` 适配原始节点名：`ItemContainer`、`RewardBtn→RewardContainer→CurrencyIcon/AmountLabel`

## 2. OrderSystem.gd 逻辑修复

- [x] 2.1 改用 `call_deferred("_generate_initial_orders")` 延迟一帧，等 GameScene 连线完成后再生成
- [x] 2.2 `generation_interval` 默认值设为 `6.0`（调试值，规格为 60s）

## 3. 新建 OrderBarManager

- [x] 3.1 创建 `scripts/ui/components/order_bar_manager.gd` — 管理 slot 创建/销毁/定位/动画
- [x] 3.2 `setup()` 方法连接 EventBus.order_generated / order_completed
- [x] 3.3 `_create_slot()` 动态实例化 OrderSlot、注入 order_system、设置 GoldIcon 纹理
- [x] 3.4 `_process_pending()` 使用 `await` 实现错开 0.08s 的批量创建
- [x] 3.5 `_shift_all_slots()` 在 order_completed 后左移剩余 slot

## 4. OrderSlot 动画

- [x] 4.1 新增 `disappear_finished` 信号
- [x] 4.2 新增 `animate_appear(0.2s)` — modulate+scale 淡入
- [x] 4.3 新增 `animate_disappear(0.25s)` — modulate+scale 淡出，完成 emit 信号
- [x] 4.4 新增 `animate_to_position(0.3s)` — position 平滑位移
- [x] 4.5 `_update_requirements` 重写：图标大小自适应（单件 120px / 双件 80px），从 ResourceDB 加载纹理

## 5. GameScene 连线

- [x] 5.1 GameScene.tscn 新增 OrderSystem 节点，移除静态 OrderSlot_2/3
- [x] 5.2 GameScene.gd 新增 `_wire_order_system()` 连线 OrderSystem → GridBoard → OrderBarManager
- [x] 5.3 OrderBarManager 脚本通过 `load()` + `set_script()` 动态挂载到 OrderBar

## 6. 验证

- [x] 6.1 项目启动零错误，所有系统正确初始化
- [x] 6.2 3 个订单卡依次出现在 3 个锚定位置，错开动画正常
- [x] 6.3 布局与预制体设计一致（500×400，原始节点结构）
- [x] 6.4 实际操作：点击卡片提交订单 → 确认消失+左移动画（已验证）
