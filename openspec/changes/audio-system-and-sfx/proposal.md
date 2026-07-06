## Why

游戏目前完全没有音效反馈——棋盘操作、合成、订单完成等行为都是静默的，缺乏手感。现已有完整的音效素材库（28个音频文件，按类别组织），需要一个全局音频管理器将这些音效接入游戏系统。

## What Changes

- 新增 `AudioManager` Autoload：全局音频管理器，统一管理 BGM 和 SFX 播放
- 整理音效素材：将 `cat_bakery_sfx_v3/` 下的 wav 文件迁移到 `assets/sounds/` 目录
- 为以下操作接入音效反馈：
  - **UI 交互**：按钮点击、轻提示
  - **棋盘操作**：拾起物品、放下物品、无效合成/满棋盘提示
  - **合成**：按等级分层（Lv2-3 / Lv4-5 / Lv6）
  - **订单**：就绪提示、完成（快速/普通/大额）
  - **资源变化**：金币增加
  - **生成器**：点击生成器、产物出现
- 环境 BGM 低音量循环播放
- 现有 `_play_press_sfx()` / `_play_release_sfx()` 占位方法接入实际播放

## Capabilities

### New Capabilities
- `audio-manager`: 全局音频管理器，BGM/SFX 统一调度，音量控制，静音切换
- `sfx-feedback`: 游戏操作音效反馈规则——哪些操作触发哪些音效

### Modified Capabilities
<!-- 无现有 spec 需要修改；音效是纯新增能力，不改变现有系统规则 -->

## Impact

- 新增文件：`scripts/core/AudioManager.gd`（Autoload）
- 修改文件：`project.godot`（注册 AudioManager）、含音效占位符的系统脚本（`ItemCellButton.gd` 等）
- 迁移目录：`cat_bakery_sfx_v3/assets/sounds/` → `assets/sounds/`
- 受影响系统：GridBoard、MergeSystem、OrderSystem、GeneratorSystem、UI 按钮组件
