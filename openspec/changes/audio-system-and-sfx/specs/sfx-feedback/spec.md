# SFX Feedback

游戏操作音效反馈规则——定义哪些操作触发哪些音效。

## ADDED Requirements

### Requirement: UI 按钮音效
所有 UI 按钮点击 SHALL 播放 `ui_button_tap_soft` 音效。

#### Scenario: 棋盘格子点击
- **WHEN** 玩家点击棋盘中的任意格子（ItemCellButton）
- **THEN** 播放 `ui_button_tap_soft` 音效

#### Scenario: 订单栏按钮点击
- **WHEN** 玩家点击订单栏中的提交按钮
- **THEN** 播放 `ui_button_tap_soft` 音效

### Requirement: 棋盘拾起/放下音效
拖拽物品时 SHALL 播放拾起和放下音效。

#### Scenario: 开始拖动物品
- **WHEN** 玩家开始从棋盘拖动物品
- **THEN** 播放 `item_pickup_paw` 音效

#### Scenario: 物品放入空格
- **WHEN** 拖动的物品被释放到空格子中
- **THEN** 播放 `item_drop_paw` 音效

### Requirement: 无效操作提示音效
不可合成、拖放取消、棋盘满、订单材料不足等无效操作 SHALL 播放对应音效。

#### Scenario: 尝试合成不匹配的物品
- **WHEN** 拖放物品到不匹配的物品上（type 或 level 不同）
- **THEN** 播放 `invalid_merge_meow` 音效

#### Scenario: 拖放取消
- **WHEN** 物品被拖起后放回原位或取消
- **THEN** 播放 `invalid_merge_meow` 音效

#### Scenario: 棋盘满时点击生成器
- **WHEN** 棋盘没有空位时点击生成器格子
- **THEN** 播放 `board_full_meow` 音效

### Requirement: 合成成功音效
合成成功时 SHALL 根据产物等级播放对应层级音效。

#### Scenario: 低级合成（Lv2-Lv3）
- **WHEN** 两个 Lv1 物品合成得到 Lv2 物品
- **THEN** 播放 `merge_success_lv2_3` 音效

#### Scenario: 高级合成（Lv4-Lv5）
- **WHEN** 两个 Lv3 物品合成得到 Lv4 物品
- **THEN** 播放 `merge_success_lv4_5` 音效

### Requirement: 订单音效
订单系统操作 SHALL 根据事件类型播放对应音效。

#### Scenario: 订单变为可提交
- **WHEN** 订单需求被满足，订单状态变为"就绪"
- **THEN** 播放 `order_ready_meow` 音效

#### Scenario: 完成小额订单（reward < 50）
- **WHEN** 提交订单且金币奖励小于 50
- **THEN** 播放 `order_complete_quick_meow` 音效

#### Scenario: 完成普通订单（50 <= reward < 150）
- **WHEN** 提交订单且金币奖励在 50-149 之间
- **THEN** 播放 `order_complete_normal_meow` 音效

#### Scenario: 完成大额订单（reward >= 150）
- **WHEN** 提交订单且金币奖励 >= 150
- **THEN** 播放 `order_complete_big_meow` 音效

#### Scenario: 新订单生成
- **WHEN** EventBus 发出 `order_generated` 信号
- **THEN** 播放 `order_refresh_soft` 音效

### Requirement: 资源变化音效
金币增加时 SHALL 播放对应音效。

#### Scenario: 金币增加
- **WHEN** 金币数量增加（无论来源）
- **THEN** 播放 `coin_gain` 音效

### Requirement: 生成器音效
生成器操作 SHALL 播放对应音效（V1 原型阶段至少接入生成器点击）。

#### Scenario: 点击生成器
- **WHEN** 玩家点击棋盘中的生成器格子
- **THEN** 播放 `bakery_basket_tap_rustle` 音效

#### Scenario: 物品从生成器产出
- **WHEN** 生成器成功在空位生成物品
- **THEN** 播放 `bakery_item_spawn_plop` 音效

### Requirement: 环境 BGM
主场景 SHALL 循环播放低音量背景环境音。

#### Scenario: 进入主场景
- **WHEN** GameScene 加载完成
- **THEN** 自动播放 `bakery_cat_room_loop` BGM（音量 0.22，循环）
