extends Node
# AudioManager — 全局音频管理器 (Autoload)

# ============================================================
#  AudioManager — 全局音频管理器 (Autoload)
#
#  外部调用：
#    AudioManager.play_sfx("ui_button_tap_soft")
#    AudioManager.play_bgm("bakery_cat_room_loop")
#    AudioManager.stop_bgm()
#
#  音效 ID 使用文件名（不含扩展名），manifest 定义在
#  assets/sounds/sound_manifest.csv 中。
# ============================================================

# ── 常量 ──────────────────────────────────────────────────

const MANIFEST_PATH := "res://assets/sounds/sound_manifest.csv"
const SFX_POOL_SIZE: int = 8

# ── 状态 ──────────────────────────────────────────────────

var _manifest: Dictionary = {}        # id → {path, volume, priority}
var _cache: Dictionary = {}           # id → AudioStream (lazy loaded)
var _sfx_pool: Array[AudioStreamPlayer] = []
var _bgm_player: AudioStreamPlayer = null
var _pool_cursor: int = 0            # 池轮转指针

# ── 上一帧金币值（用于检测金币增量） ──────────────────────
var _last_gold: int = 0


# ============================================================
#  初始化
# ============================================================

func _ready() -> void:
	_parse_manifest()
	_create_sfx_pool()
	_create_bgm_player()
	_connect_events()
	print("AudioManager: initialized, %d sfx, %d pool players" % [_manifest.size(), SFX_POOL_SIZE])


func _parse_manifest() -> void:
	var file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if file == null:
		push_error("AudioManager: cannot open manifest: %s" % MANIFEST_PATH)
		return

	# 跳过 header 行
	file.get_line()

	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line == "":
			continue

		var cols := line.split(",")
		if cols.size() < 3:
			continue

		var raw_path: String = cols[0].strip_edges()         # e.g. "assets/sounds/ui/ui_button_tap_soft.wav"
		var volume_str: String = cols[2].strip_edges()

		# 从路径提取 id（文件名去扩展名）
		var id := raw_path.get_file().get_basename()

		# 路径补前缀 Godot 资源路径
		var full_path := "res://" + raw_path

		var volume := volume_str.to_float()
		if volume == 0.0 and volume_str != "0":
			volume = 0.75  # fallback

		_manifest[id] = {
			"path": full_path,
			"volume": volume,
		}


func _create_sfx_pool() -> void:
	for i in range(SFX_POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.name = "SFX_%d" % (i + 1)
		add_child(player)
		_sfx_pool.append(player)


func _create_bgm_player() -> void:
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.name = "BGMMusic"
	_bgm_player.finished.connect(func(): _bgm_player.play())
	add_child(_bgm_player)


func _connect_events() -> void:
	EventBus.merge_done.connect(_on_merge_done)
	EventBus.order_completed.connect(_on_order_completed)
	EventBus.gold_changed.connect(_on_gold_changed)
	EventBus.order_generated.connect(_on_order_generated)


# ============================================================
#  公开 API
# ============================================================

func play_sfx(id: String) -> void:
	var stream := _get_or_load(id)
	if stream == null:
		return

	var info: Dictionary = _manifest.get(id, {})
	var vol: float = info.get("volume", 0.75)

	# 池轮转：分配下一个空闲/最早播放器
	var player: AudioStreamPlayer = _sfx_pool[_pool_cursor]
	_pool_cursor = (_pool_cursor + 1) % SFX_POOL_SIZE

	player.stop()
	player.stream = stream
	player.volume_db = linear_to_db(vol)
	player.play()


func play_bgm(id: String) -> void:
	if _bgm_player == null:
		return

	var stream := _get_or_load(id)
	if stream == null:
		return

	var info: Dictionary = _manifest.get(id, {})
	var vol: float = info.get("volume", 0.75)

	_bgm_player.stop()
	_bgm_player.stream = stream
	_bgm_player.volume_db = linear_to_db(vol)
	_bgm_player.play()


func stop_bgm() -> void:
	if _bgm_player:
		_bgm_player.stop()


func set_bgm_volume_db(db: float) -> void:
	if _bgm_player:
		_bgm_player.volume_db = db


func set_sfx_volume_db(db: float) -> void:
	for p in _sfx_pool:
		p.volume_db = db


# ============================================================
#  内部
# ============================================================

func _get_or_load(id: String) -> AudioStream:
	# 命中缓存
	if _cache.has(id):
		return _cache[id]

	var info: Dictionary = _manifest.get(id, {})
	var path: String = info.get("path", "")
	if path == "":
		push_warning("AudioManager: unknown sfx id '%s'" % id)
		return null

	if not ResourceLoader.exists(path):
		push_warning("AudioManager: file not found: %s" % path)
		return null

	var stream := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REUSE)
	if stream is AudioStream:
		_cache[id] = stream
		return stream

	push_warning("AudioManager: failed to load audio stream: %s" % path)
	return null


# ============================================================
#  EventBus 响应
# ============================================================

func _on_merge_done(_from_pos: Vector2i, _to_pos: Vector2i, result_item) -> void:
	if result_item == null:
		return
	var level: int = result_item.level
	if level <= 2:
		play_sfx("merge_success_lv2_3")
	elif level <= 3:
		play_sfx("merge_success_lv2_3")
	elif level <= 5:
		play_sfx("merge_success_lv4_5")
	else:
		play_sfx("merge_success_lv6_meow")


func _on_order_completed(_order_id: String, reward_gold: int) -> void:
	if reward_gold >= 150:
		play_sfx("order_complete_big_meow")
	elif reward_gold >= 50:
		play_sfx("order_complete_normal_meow")
	else:
		play_sfx("order_complete_quick_meow")


func _on_gold_changed(current: int) -> void:
	if current > _last_gold:
		play_sfx("coin_gain")
	_last_gold = current


func _on_order_generated(_order) -> void:
	play_sfx("order_refresh_soft")
