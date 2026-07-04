## 1. 动画系统基础

- [x] 1.1 创建目录 `scripts/ui/animations/`
- [x] 1.2 创建 `button_animation.gd` 动画基类（RefCounted，含 target/duration/transition/ease 属性）
- [x] 1.3 创建 `press_shrink_animation.gd` 按下缩放动画（1.0 → 0.9，Quad+EaseIn）
- [x] 1.4 创建 `release_expand_animation.gd` 弹起放大动画（0.9 → 1.0，Quad+EaseOut）

## 2. ItemCellButton 核心脚本

- [x] 2.1 创建目录 `scripts/ui/components/`
- [x] 2.2 创建 `item_cell_button.gd` 脚本骨架（类定义、信号、属性声明）
- [x] 2.3 实现动画组件初始化（_setup_animations）
- [x] 2.4 实现按下处理（_on_button_down：播放动画 + 启动拖动定时器）
- [x] 2.5 实现弹起处理（_on_button_up：拖动判断 → 三击判断 → 单击逻辑）

## 3. 三击检测系统

- [x] 3.1 实现三击计数器（_update_tap_counter，0.8s 间隔）
- [x] 3.2 实现计数器重置（_reset_tap_counter）
- [x] 3.3 实现收取信号发送（collect_request）

## 4. 长按拖动系统

- [x] 4.1 实现拖动定时器（0.3s 长按检测）
- [x] 4.2 实现拖动状态管理（_is_dragging 标志位）
- [x] 4.3 实现半透明遮罩显示/隐藏（show_drag_overlay / hide_drag_overlay）
- [x] 4.4 实现拖动数据获取（_get_drag_data）
- [x] 4.5 实现拖动预览创建（_make_drag_preview）

## 5. 选中状态管理

- [x] 5.1 实现选中框显示/隐藏（select / deselect）
- [x] 5.2 实现选中状态切换（toggle_selection）

## 6. 视觉反馈

- [x] 6.1 实现物品设置/清空（set_item / clear_item）
- [x] 6.2 添加音效占位符（_play_press_sfx / _play_release_sfx / _play_collect_sfx）

## 7. 验证

- [ ] 7.1 在 Godot 编辑器中创建测试场景，绑定 ItemCellButton 脚本
- [ ] 7.2 验证按下/弹起动画效果
- [ ] 7.3 验证三击检测（0.8s 内 3 次点击）
- [ ] 7.4 验证长按拖动（0.3s 后半透明遮罩）
- [ ] 7.5 验证选中状态切换
