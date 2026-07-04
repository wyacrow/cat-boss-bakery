# 《猫老板的面包店》工程开发文档（Godot V1）

## 一、项目定位
- 类型：二合合成 + 模拟经营 + 猫咪养成
- 核心：体力驱动 + 合成链 + 库存缓冲 + 订单消耗 + 猫咪修正

---

## 二、核心循环
体力恢复 → 生成器 → 棋盘 → 合成 → 收取 → 库存 → 订单 → 奖励 → 猫咪强化 → 循环

---

## 三、工程架构

res://
├── scenes/
├── scripts/
│   ├── systems/
│   ├── data/
│   └── core/
└── assets/

---

## 四、核心系统

### 1. 体力系统
- max=20
- 30秒+1
- 消耗用于生成

### 2. 生成器
- 1体力=1Lv1物品
- 投放棋盘

### 3. 棋盘系统
- 6×6数组
- 数据驱动
- 唯一合成场

### 4. 合成系统
- 2合1升级
- 手动默认
- 自动可选（连锁0.1s间隔）
- 自动合成由grid_changed信号触发扫描

### 5. 收取系统
- 三击收取（0.8s内同一物品点3次）
- 50%格子半径容差
- 棋盘→库存（单向）
- 三击优先于合成选中

### 6. 库存系统
- key=type_level
- 容量上限：25
- 不参与合成
- 不允许回流棋盘

### 7. 订单系统
- 3个订单槽
- 60秒定时刷新
- 仅需求Lv2+物品
- V1不过期
- 消耗库存，发放金币（由PlayerData管理）

### 8. 猫咪系统
- 全局buff
- 不参与规则
- 影响效率与收益
- 倍率：面包猫1.1x(V1预留) / 咖啡猫1.2x / 工程猫1.25x

---

## 五、通信系统
EventBus事件驱动（共11个信号）：
- stamina_changed(current: int, max_stamina: int)
- grid_changed(positions: Array[Vector2i])
- merge_done(from_pos: Vector2i, to_pos: Vector2i, result_item: Item)
- inventory_changed(added_items: Array[Item], removed_items: Array[Item])
- order_completed(order_id: String, reward_gold: int)
- order_generated(order_id: String, requirements: Dictionary)
- collect_request(item: Item, from_pos: Vector2i)
- collect_done(item: Item)
- collect_failed(reason: String)
- auto_merge_toggled(enabled: bool)
- gold_changed(current: int)

---

## 六、设计原则
- 棋盘=加工区
- 库存=缓冲区
- 订单=终点
- 单向流动

### 9. 玩家数值（PlayerData Autoload）
- 持有gold等玩家数值
- 监听order_completed发放金币
- V2预留存档入口

---

## 七、总结
> 体力驱动的二合经营循环 + 猫咪情绪修正系统
