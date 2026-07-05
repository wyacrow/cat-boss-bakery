## ADDED Requirements

### Requirement: TopHUDBar 锚定右上角且宽高百分比

TopHUDBar 节点 SHALL 使用 anchor 锚定在父容器 AreaA_Top 的右上角，宽度 SHALL 为父容器宽度的 0.7 倍（减去右边距 20px），高度 SHALL 为父容器高度的 0.15 倍（减去上下边距各 20px）。

#### Scenario: TopHUDBar 在 1440×3120 分辨率下的位置
- **WHEN** 父容器 AreaA_Top 的尺寸为 1440×891
- **THEN** TopHUDBar 的宽度为 988px（1440×0.7−20），高度为 94px（891×0.15−20−20），左边缘距父容器左边 432px（1440×0.3），右边缘距父容器右边 20px，上/下边缘距父容器各 20px

### Requirement: OrderBar 锚定底部占 60% 高度

OrderBar 节点 SHALL 使用 anchor 锚定在父容器 AreaA_Top 的底部，高度 SHALL 为父容器高度的 0.6 倍，宽度 SHALL 为父容器全宽，无 padding。

#### Scenario: OrderBar 在 1440×3120 分辨率下的位置
- **WHEN** 父容器 AreaA_Top 的尺寸为 1440×891
- **THEN** OrderBar 的尺寸为 1440×535（891×0.6），上边缘距父容器顶部 356px（891×0.4），左/右/下边缘与父容器边缘齐平

### Requirement: GridBoard 在背景内四边等距

GridBoard 节点 SHALL 在其父容器 AreaB_Grid 的 Background 内保持四边各 10px 的 padding。GridBoard 内部的 GridContainer SHALL 保持居中对齐。

#### Scenario: GridBoard padding 验证
- **WHEN** AreaB_Grid 尺寸为 1440×1783
- **THEN** GridBoard 的可用区域为 1420×1763（各边减去 10px）

### Requirement: BottomPanel 内部 padding 和间距

AreaC_Bottom 内的 BottomPanel SHALL 在父容器内保持四边各 20px 的 padding。ButtonContainer 内的子元素间距 SHALL 为 20px。

#### Scenario: BottomPanel 布局验证
- **WHEN** AreaC_Bottom 尺寸为 1440×446
- **THEN** BottomPanel 的可用区域为 1400×406（各边减去 20px），ButtonContainer 内相邻子元素水平间距为 20px
