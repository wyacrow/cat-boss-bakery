# Audio Manager

全局音频管理器，作为 Autoload 提供统一的 BGM 和 SFX 播放能力。

## ADDED Requirements

### Requirement: Autoload 注册
AudioManager SHALL 在 `project.godot` 中注册为 Autoload，在 `_ready()` 时解析 `sound_manifest.csv` 并初始化 SFX 播放器池。

#### Scenario: 项目启动时 AudioManager 初始化
- **WHEN** Godot 项目启动
- **THEN** AudioManager 作为 Autoload 自动加载，打印初始化日志
- **AND** 所有 SFX 播放器节点已创建
- **AND** sound_manifest.csv 已解析为内部映射表

### Requirement: SFX 播放
AudioManager SHALL 提供 `play_sfx(id: String)` 方法，接受 manifest 中的音效 ID（文件名去扩展名），从池中分配空闲 AudioStreamPlayer 播放该音效，首次播放时按需加载音频资源并缓存。

#### Scenario: 播放一个已加载的音效
- **WHEN** 调用 `AudioManager.play_sfx("ui_button_tap_soft")`
- **THEN** 该音效立即播放，使用 manifest 中定义的音量
- **AND** 同一音效再次调用时不重新加载资源

#### Scenario: 首次播放音效时加载
- **WHEN** 首次调用 `AudioManager.play_sfx("coin_gain")`
- **THEN** AudioManager 从 `res://assets/sounds/resource/coin_gain.wav` 加载音频
- **AND** 加载完成后播放，后续调用直接使用缓存

#### Scenario: 无效音效 ID
- **WHEN** 调用 `AudioManager.play_sfx("nonexistent_id")`
- **THEN** 静默忽略，不崩溃，打印 warning

### Requirement: SFX 池管理
AudioManager SHALL 维护 8 个 AudioStreamPlayer 节点组成 SFX 播放池。请求播放时分配空闲播放器；全部占用时，停止并复用最早播放的。

#### Scenario: 池内有余量
- **WHEN** 同时播放 4 个音效
- **THEN** 所有 4 个音效正常播放，各占用独立 AudioStreamPlayer

#### Scenario: 池满时复用
- **WHEN** 已有 8 个音效正在播放，再请求第 9 个
- **THEN** 第 1 个（最早开始的）音效被停止
- **AND** 其 AudioStreamPlayer 被第 9 个音效复用

### Requirement: BGM 播放
AudioManager SHALL 提供 `play_bgm(id: String)` 方法，用独立 AudioStreamPlayer 循环播放背景音乐。

#### Scenario: 开始播放 BGM
- **WHEN** 调用 `AudioManager.play_bgm("bakery_cat_room_loop")`
- **THEN** BGM 以 manifest 定义的音量（0.22）开始循环播放

#### Scenario: 切换 BGM
- **WHEN** 当前正在播放 BGM A，调用 `AudioManager.play_bgm("bgm_b")`
- **THEN** BGM A 停止，BGM B 开始循环播放

### Requirement: 停止 BGM
AudioManager SHALL 提供 `stop_bgm()` 方法。

#### Scenario: 停止背景音乐
- **WHEN** 调用 `AudioManager.stop_bgm()`
- **THEN** 当前 BGM 停止，不产生爆音

### Requirement: 事件驱动音效
AudioManager SHALL 在 `_ready()` 中连接 EventBus 信号，自动为领域事件触发对应音效。

#### Scenario: 合成完成触发音效
- **WHEN** EventBus 发出 `merge_done` 信号
- **THEN** AudioManager 根据 `result_item.level` 自动播放对应等级合成音效（Lv2-3: `merge_success_lv2_3`，Lv4-5: `merge_success_lv4_5`）

#### Scenario: 订单完成触发音效
- **WHEN** EventBus 发出 `order_completed` 信号
- **THEN** AudioManager 根据 reward_gold 自动播放对应订单完成音效

#### Scenario: 金币变化触发音效
- **WHEN** EventBus 发出 `gold_changed` 信号且新值大于旧值
- **THEN** AudioManager 自动播放 `coin_gain` 音效

### Requirement: 音频资源迁移
所有音效文件 SHALL 从 `cat_bakery_sfx_v3/assets/sounds/` 迁移到 `res://assets/sounds/`，保持原有目录结构。

#### Scenario: 音效文件可访问
- **WHEN** 播放任意 manifest 中的音效 ID
- **THEN** 对应的 `.wav` 文件在 `res://assets/sounds/<category>/<name>.wav` 路径下存在
- **AND** Godot 已生成对应的 `.import` 文件
