## 1. ResourceDB — 面包纹理映射

- [x] 1.1 更新 `ITEM_TEXTURES` 中 bread_1~4 的纹理路径：bread_1→resized-bread1.png, bread_2→resized-bread2.png, bread_3→resized-bread3.png, bread_4→resized-bread4.png
- [x] 1.2 确认 `sprites/art/烘焙机.png` 存在且可用作面包生成器图标

## 2. GeneratorSystem — 类型化生成器

- [x] 2.1 新增 `generator_type: String` 属性（默认 `"drink"`）
- [x] 2.2 将 `try_generate()` 中的随机类型选择改为固定使用 `generator_type`，移除 `ITEM_TYPES` 常量数组
- [x] 2.3 打印日志中包含 `generator_type` 便于调试

## 3. ItemCellButton — 生成器图标区分

- [x] 3.1 新增 `@export var generator_type: String = ""`
- [x] 3.2 修改 `_setup_generator_visual()`：根据 `generator_type` 选择图标（drink→咖啡机.png, bread→烘焙机.png）
- [x] 3.3 `_on_button_down()` 中 `cell_pressed` 信号保持不变（GridBoard 负责路由）

## 4. GridBoard — 多生成器支持

- [x] 4.1 将 `_generator` 单实例改为 Dictionary：`_generators: Dictionary = {}`，key 为 `generator_type`，value 为 GeneratorSystem 实例
- [x] 4.2 `_ready()` 中创建两个 GeneratorSystem 实例：drink 和 bread
- [x] 4.3 修改 `_on_generator_pressed(pos)` → 根据 cell 的 `generator_type` 查找对应 GeneratorSystem 实例
- [x] 4.4 修改 `_init_cells()`：读取 cell 的 `generator_type` 属性进行路由
- [x] 4.5 新增面包链初始物品放置（row 2~3 区域放置 bread Lv1/Lv2）
- [x] 4.6 `find_nearest_empty()` 排除所有生成器格（已实现，确认无回归）

## 5. OrderSystem — 扩展物品池

- [x] 5.1 将 `ITEM_TYPES` 常量从 `["drink"]` 改为 `["drink", "bread"]`
- [x] 5.2 确认 `_generate_order()` 中 `type_count = min(type_count, ITEM_TYPES.size())` 在双链时正确支持 2 种类型订单

## 6. GameScene.tscn — 场景配置

- [x] 6.1 将 Cell_6_3 设置为面包生成器：`is_generator = true`，`generator_type = "bread"`
- [x] 6.2 （可选）将现有 Cell_8_3 显式设置 `generator_type = "drink"`

## 7. 验证

- [x] 7.1 运行项目，确认饮品生成器（咖啡机图标）和面包生成器（烘焙机图标）均正确显示
- [x] 7.2 点击饮品生成器 → 生成 drink Lv1 物品，点击面包生成器 → 生成 bread Lv1 物品
- [x] 7.3 确认订单包含 drink 和 bread 两类需求
- [x] 7.4 确认面包合成链（bread Lv1+Lv1→Lv2...）正常工作
- [x] 7.5 确认面包物品图标显示为实际素材而非占位图
