## Why

《猫老板的面包店》是一个治愈系二合+模拟经营+猫咪养成手游，设计文档已冻结 V1 版本。当前项目仅有 Godot 4.7 空壳工程和 4 份设计文档，没有任何可运行的游戏代码。需要将设计文档转化为完整的 Godot 游戏实现，建立可运行、可交互的 V1 原型。

## What Changes

- 新增 **EventBus 全局事件总线**（Autoload），承载 11 个游戏信号
- 新增 **PlayerData 玩家数值管理**（Autoload），持有 gold 等玩家数值，为存档预留入口
- 新增 **Item 数据模型**（RefCounted），定义 3 链 × 4 级 = 12 种物品
- 新增 **8 个核心游戏系统**脚本：体力、生成器、棋盘、合成、收取、库存、订单、猫咪
- 新增 **6 个 UI 视图**脚本：棋盘渲染、物品渲染、猫咪展示、库存面板、订单面板、主 HUD
- 新增 **主场景**（`main.tscn`），组装所有系统和 UI
- 所有素材使用代码绘制（StyleBoxFlat + emoji），零外部图片依赖，后续切换 AI 素材时仅改纹理引用

## Capabilities

### New Capabilities

- `event-bus`: 全局信号总线，承载 stamina_changed、grid_changed、merge_done、inventory_changed、order_completed、order_generated、collect_request、collect_done、collect_failed、auto_merge_toggled、gold_changed 共 11 个信号
- `item-data`: 物品数据模型（RefCounted），type（bread/dessert/drink）+ level（1-4），12 种物品 + 3 条合成链
- `stamina-system`: 体力系统，最大 20，30 秒恢复 1 点，消耗用于生成器，工程猫 +25% 恢复速度
- `generator-system`: 生成器系统，消耗 1 体力生成 1 个 Lv1 物品，33%/33%/33% 随机出面粉/奶油/咖啡豆，自动投放至棋盘空位
- `grid-system`: 6×6 棋盘系统，Array[6][6] 数据驱动，每格存放 1 个物品或空，是唯一合成加工区
- `merge-system`: 合成系统，2 个同 type 同 level 物品合成 1 个 level+1，Lv4 为终点。默认手动合成，可选自动连锁合成（0.1s 间隔），两者可共存
- `collect-system`: 三击收取系统，0.8 秒内连续点击同一物品 3 次触发收取，棋盘→库存单向流动，库存满时 Toast 提示
- `inventory-system`: 库存系统，Dictionary 存储（key="type_level"），容量 25，纯存储不参与合成，不允许回流棋盘
- `order-system`: 订单系统，3 个订单槽，60 秒自动刷新，仅需求 Lv2+ 物品，V1 不过期，消耗库存发放金币
- `cat-system`: 猫咪系统，3 只猫（面包猫/咖啡猫/工程猫），同时激活 1 只，仅提供全局数值 buff，不修改核心规则，V1 无等级无升级
- `player-data`: 玩家数值管理系统（Autoload），持有 gold 等玩家数值，监听 order_completed 发放金币，为后续存档预留扩展入口

### Modified Capabilities

<!-- 无现有 capability，这是首个 change -->

## Impact

- 影响目录：`scripts/core/`、`scripts/data/`、`scripts/systems/`、`scenes/`（全部新建）
- 项目配置：需在 `project.godot` 中注册 EventBus 和 PlayerData 两个 Autoload
- 无外部依赖，无 API 变更，无破坏性变更
- 后续变更路径：V2 可能增加猫咪升级、订单过期、持久化存档、AI 素材替换