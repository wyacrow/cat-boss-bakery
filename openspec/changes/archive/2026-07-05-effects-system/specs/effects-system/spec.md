## ADDED Requirements

### Requirement: 特效系统与动画系统隔离
EffectsSystem SHALL 独立于现有动画系统（GridBoard/ItemCellButton 内的操作反馈 tween），不共享状态，不互相调用。

#### Scenario: 特效不影响动画
- **WHEN** EffectsSystem 播放合并提示光环
- **THEN** ItemCellButton 的按下/弹起/消耗动画不受任何影响

#### Scenario: 动画不影响特效
- **WHEN** ItemCellButton 播放弹起动画
- **THEN** EffectsSystem 的合并提示状态不受任何影响

---

### Requirement: 拖拽悬停时显示可合成提示
当用户拖拽物品悬停在可合成目标格上方时，EffectsSystem SHALL 在目标格中心显示光环特效。

#### Scenario: 可合成悬停
- **WHEN** 用户拖拽饮品 Lv1 悬停在另一个饮品 Lv1 所在格
- **THEN** 目标格中心出现饮品链颜色（天蓝）的光环，从小到大扩张（0.18s，ease_out），完全显示后半透明可见，持续呼吸缩放

#### Scenario: 不可合成悬停
- **WHEN** 用户拖拽饮品 Lv1 悬停在面包 Lv2 所在格
- **THEN** 不显示光环提示（类型不匹配）

#### Scenario: 拖回原位
- **WHEN** 用户拖拽物品后又悬停回原来的格子
- **THEN** 不显示光环提示

#### Scenario: Lv4 不显示提示
- **WHEN** 用户拖拽饮品 Lv4 悬停在另一个饮品 Lv4 所在格
- **THEN** 不显示光环提示（已达最高等级，不可合成）

---

### Requirement: 光环出现动画
光环 SHALL 从中心向外扩张出现，使用先快后慢的缓动曲线。

#### Scenario: 出现动画参数
- **WHEN** 光环出现动画播放
- **THEN** 节点 scale 从 0 到 2.0，base_color.a 驱动透明度，duration = 0.18s，ease = EASE_OUT，transition = TRANS_QUAD

---

### Requirement: 光环呼吸动画
光环完全显示后 SHALL 维持微弱的缩放振荡，营造"活着"的视觉感受。

#### Scenario: 呼吸动画参数
- **WHEN** 呼吸动画循环播放
- **THEN** scale 在 2.0 ↔ 2.1 之间以正弦缓动振荡，半周期 = 0.7s

---

### Requirement: 光环消失动画
当拖拽离开可合成格时，光环 SHALL 缩小消失，使用先慢后快的缓动曲线。

#### Scenario: 消失动画参数
- **WHEN** 光环消失动画播放
- **THEN** scale 从当前值到 0，modulate.a 到 0，duration = 0.12s，ease = EASE_IN，transition = TRANS_QUAD

---

### Requirement: 快速切换稳定性
EffectsSystem SHALL 正确处理快速拖拽时的状态切换，不产生残留节点或崩溃。

#### Scenario: 快速跨格拖拽
- **WHEN** 用户在 0.1s 内从可合成格 A 拖到可合成格 B
- **THEN** A 的提示立即清除（kill tween + free 节点），B 的提示正常出现

#### Scenario: 消失中拖回
- **WHEN** 光环正在播放消失动画时，用户将物品拖回同一格
- **THEN** 取消消失动画，从当前 scale 重新开始出现动画

---

### Requirement: 光环颜色按物品链区分
光环颜色 SHALL 根据目标物品的类型显示不同颜色。

#### Scenario: 面包链颜色
- **WHEN** 可合成目标物品类型为 "bread"
- **THEN** 光环颜色为暖橙色 Color(1.0, 0.55, 0.15)

#### Scenario: 甜点链颜色
- **WHEN** 可合成目标物品类型为 "dessert"
- **THEN** 光环颜色为粉红色 Color(1.0, 0.25, 0.55)

#### Scenario: 饮品链颜色
- **WHEN** 可合成目标物品类型为 "drink"
- **THEN** 光环颜色为天蓝色 Color(0.25, 0.55, 1.0)
