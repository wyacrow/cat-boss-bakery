## Context

《猫老板的面包店》V1 版本需要从零构建 Godot 4.7 手游项目。当前项目仅有设计文档（`cat_bakery_merge_design.md`、`cat_bakery_engineering_v1.md`、`placeholder_asset_plan.md`），无任何可运行代码。开发环境：Godot 4.7 + D3D12 渲染器 + Jolt Physics + Godot MCP 工具链。

核心约束：
- 严格分离的 8 个系统，每个系统一个脚本文件
- 单向数据流：Generator → Grid → Merge → Collect → Inventory → Order
- 所有通信通过 EventBus 信号，禁止跨系统直接方法调用
- 棋盘用 `Array[6][6]` 数据驱动，不创建 36 个独立节点
- 全代码绘制占位素材（StyleBoxFlat + emoji），后续切换 AI 素材时仅改纹理引用

## Goals / Non-Goals

**Goals:**
- 实现完整的 V1 游戏循环：体力→生成→棋盘合成→收取→库存→订单→金币→猫咪强化
- 建立可运行、可点击交互的手游原型，基准分辨率 390×844（iPhone 14）
- 所有系统通过 EventBus 信号通信，保持架构清晰可测试
- 使用占位素材方案，零外部图片依赖
- 场景层级结构支持手机触摸交互

**Non-Goals:**
- V1 不实现持久化存档（重启游戏恢复默认状态）
- V1 不实现猫咪升级、订单过期、音效系统
- V1 不实现 AI 素材替换（预留接口但不加载外部图片）
- V1 不实现多语言、无障碍、性能优化
- 不修改现有设计文档中的任何规则

## Decisions

### 1. EventBus Autoload 模式
- **选择**：使用 Godot Autoload 单例 `EventBus.gd` 承载所有 11 个信号
- **替代方案**：每个系统持有自己的信号 → 拒绝，因为会导致跨系统引用耦合
- **理由**：Autoload 是 Godot 原生的全局单例模式，所有系统通过 `EventBus.signal_name.connect()` 订阅，无需持有其他系统的引用

### 2. Item 使用 RefCounted 而非 Resource
- **选择**：`extends RefCounted` 纯数据类
- **替代方案**：`extends Resource` → 拒绝，因为不需要序列化/持久化，且 Resource 需要 `.tres` 文件
- **理由**：RefCounted 更轻量，自动内存管理，适合频繁创建/销毁的棋盘物品

### 3. 棋盘数据驱动渲染
- **选择**：单个 `Control` 节点 + `_draw()` 方法遍历 `Array[6][6]` 绘制所有格子
- **替代方案**：每个格子一个 `Panel` 节点 → 拒绝，36 个节点存在性能开销和复杂度
- **理由**：数据驱动 = 一次 `queue_redraw()` 完成所有渲染，性能最优，代码简洁

### 4. 全代码占位素材
- **选择**：`StyleBoxFlat` 绘制格子背景，`_draw()` 绘制物品图标，Unicode emoji 作为物品符号
- **替代方案**：placeholder PNG 图片 → 拒绝，增加外部依赖
- **理由**：零外部依赖，后续切换 AI 素材时仅需修改 View 脚本加载 PNG，逻辑代码零改动

### 5. 移动端 UI 布局
- **选择**：`canvas_items` 拉伸模式 + `expand` 宽高比，Control 节点层级布局
- **替代方案**：`viewport` 拉伸 → 拒绝，可能导致不同屏幕比例失真
- **理由**：`canvas_items + expand` 确保 UI 在不同手机屏幕上保持比例缩放，不裁剪边缘

### 6. 三击收取与单击合成的时序处理
- **选择**：CollectSystem 在 `_gui_input` 中以 0.8s 窗口检测三击，三击优先于合成选中
- **替代方案**：长按收取 → 拒绝，三击更快且更符合"治愈系"操作感
- **理由**：三击是明确的意图表达，0.8s 窗口简短不会影响正常合成操作

### 7. 自动合成链式触发
- **选择**：`grid_changed` 信号触发扫描 → 找到第一对 → 执行合成 → `merge_done` → `grid_changed` → 递归，每次间隔 0.1s Timer
- **替代方案**：一次性扫描并合并所有对 → 拒绝，视觉上瞬间消失不友好
- **理由**：0.1s 间隔创造视觉上的连锁反应感，符合治愈系游戏节奏

## Risks / Trade-offs

- **[三击/单击冲突] → 缓解**：CollectSystem 在 GridView 的 `_gui_input` 中优先拦截，0.8s 超时自动回退到合成状态机
- **[自动合成并发] → 缓解**：MergeSystem 在执行合成前重新验证格子内容（防手动合成已改变状态），使用 Timer 而非多线程
- **[手机性能] → 缓解**：36 格子的 `_draw()` 调用在 60fps 下无性能压力，无需额外优化
- **[触摸精度] → 缓解**：三击检测使用 50% 格子半径容差，防手指偏移
- **[库存满时用户体验] → 缓解**：Toast 提示 + 不阻塞操作，用户可自行决定是否腾出空间