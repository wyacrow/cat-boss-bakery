# 《猫老板的面包店》工程开发文档（Godot V1）

## 一、项目定位
- 类型：二合合成 + 模拟经营 + 猫咪养成
- 核心：体力驱动 + 合成链 + 订单直接消费棋盘 + 猫咪修正

---

## 二、核心循环
体力恢复 → 生成器 → 棋盘 → 合成 → 订单（直接扣棋盘）→ 奖励 → 猫咪强化 → 循环

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
- 7×9数组（63 格，行列数由场景 GridContainer 动态读取）
- 数据驱动
- 唯一合成场

### 4. 合成系统
- 2合1升级（纯手动）
- Lv4为终点

### 7. 订单系统
- 3个订单槽
- 60秒定时刷新
- 仅需求Lv2+物品
- V1不过期
- 直接从棋盘校验+扣除物品，发放金币（由GameStat管理）

### 8. 猫咪系统
- 全局buff
- 不参与规则
- 影响效率与收益
- 倍率：面包猫1.1x(V1预留) / 咖啡猫1.2x / 工程猫1.25x

---

## 五、通信系统
EventBus事件驱动（共6个信号）：
- stamina_changed(current: int, max_stamina: int)
- grid_changed(positions: Array[Vector2i])
- merge_done(from_pos: Vector2i, to_pos: Vector2i, result_item)
- order_completed(order_id: String, reward_gold: int)
- order_generated(order)
- gold_changed(current: int)

---

## 六、设计原则
- 棋盘=加工区+缓冲区（无独立库存）
- 订单直接从棋盘消费
- 单向流动

### 9. 玩家数值（GameStat Autoload）
- 持有gold等玩家数值
- 监听order_completed发放金币
- V2预留存档入口

---

## 七、总结
> 体力驱动的二合经营循环 + 猫咪情绪修正系统
