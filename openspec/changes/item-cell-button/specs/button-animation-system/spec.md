## ADDED Requirements

### Requirement: 动画基类支持曲线控制
ButtonAnimation 基类 SHALL 提供 target、duration、transition、ease 四个属性，供子类实现动画效果。

#### Scenario: 创建按下缩放动画
- **WHEN** 创建 PressShrinkAnimation 实例并设置 target 为某按钮
- **THEN** 调用 play() 时按钮缩放到 0.9 倍，使用 Quad 过渡 + EaseIn 曲线

#### Scenario: 创建弹起放大动画
- **WHEN** 创建 ReleaseExpandAnimation 实例并设置 target 为某按钮
- **THEN** 调用 play() 时按钮从 0.9 倍恢复到 1.0，使用 Quad 过渡 + EaseOut 曲线

### Requirement: 三击检测
ItemCellButton SHALL 检测 0.8 秒内连续点击 3 次，触发收取信号。

#### Scenario: 有效三击
- **WHEN** 用户在 0.8 秒内连续点击同一按钮 3 次
- **THEN** 发送 collect_request 信号，包含物品数据和位置

#### Scenario: 超时重置
- **WHEN** 用户第 2 次点击后超过 0.8 秒才第 3 次点击
- **THEN** 计数器重置为 1，不触发收取

### Requirement: 长按拖动检测
ItemCellButton SHALL 检测长按 0.3 秒后进入拖动状态，显示半透明遮罩。

#### Scenario: 长按进入拖动
- **WHEN** 用户按下按钮超过 0.3 秒未释放
- **THEN** 按钮显示半透明遮罩，进入拖动模式

#### Scenario: 短按不触发拖动
- **WHEN** 用户按下按钮后在 0.3 秒内释放
- **THEN** 不进入拖动模式，正常处理单击/三击逻辑

### Requirement: 选中状态管理
ItemCellButton SHALL 支持选中/取消选中状态，显示/隐藏选中框。

#### Scenario: 选中按钮
- **WHEN** 调用 select() 方法
- **THEN** 显示选中框，is_selected 变为 true

#### Scenario: 取消选中
- **WHEN** 调用 deselect() 方法
- **THEN** 隐藏选中框，is_selected 变为 false

### Requirement: 拖动优先级高于其他交互
当处于拖动状态时，button_up SHALL 跳过三击和合成逻辑。

#### Scenario: 拖动后释放
- **WHEN** 用户拖动按钮后释放
- **THEN** _is_dragging 重置为 false，不触发收取或合成
