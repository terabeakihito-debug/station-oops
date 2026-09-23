extends Node2D
## Echo
## プレイヤーに追従するドローン相棒。
## STATION OPS でのECHOコメンタリー演出（tutorial → progress → OOPS伏線）を
## アクションゲーム内の会話イベントとして引き継ぐ。

@export var target_path: NodePath
@export var follow_offset: Vector2 = Vector2(-24, -32)
@export var follow_speed: float = 6.0
@export var scan_glow_duration: float = 0.8

@onready var _scan_area: Area2D = $ScanArea
@onready var _glow_light: PointLight2D = $GlowLight
@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

var _target: Node2D

func _ready() -> void:
	if target_path != NodePath():
		_target = get_node(target_path)
	EventBus.echo_command_issued.connect(_on_command_issued)
	EventBus.boss_defeated.connect(_on_boss_defeated)
	_sprite.play("float")
	_sprite.animation_finished.connect(_on_animation_finished)

func _process(delta: float) -> void:
	if _target == null:
		return
	var goal := _target.global_position + follow_offset
	global_position = global_position.lerp(goal, follow_speed * delta)

func _on_animation_finished() -> void:
	# point/wave/victory などの単発モーションが終わったらfloatに戻す
	if _sprite.animation != "float":
		_sprite.play("float")

func _on_boss_defeated() -> void:
	_sprite.play("victory")

func play_gesture(gesture_name: String) -> void:
	## wave など、スキャン以外の単発モーションを外部（インタラクトイベント等）から再生する用。
	if _sprite.sprite_frames.has_animation(gesture_name):
		_sprite.play(gesture_name)

func _on_command_issued(command_name: String) -> void:
	match command_name:
		"scan":
			_do_scan()
		_:
			push_warning("Echo: 未対応コマンド %s" % command_name)

func _do_scan() -> void:
	## get_overlapping_bodies()/get_overlapping_areas()は「継続的に置いてある
	## トリガー範囲」の追跡には向いているが、スキャンのようにQキーを押した
	## 瞬間だけ判定したいケースでは監視キャッシュの更新が追いつかず、
	## 直前まで重なっていなかった対象を取りこぼすことがある。
	## 攻撃判定（Player._try_attack）と同じく、物理エンジンへの直接クエリ
	## （intersect_shape）で判定する。
	_sprite.play("point")
	_glow_light.enabled = true

	var scan_shape: CollisionShape2D = $ScanArea/ScanShape
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = scan_shape.shape
	query.transform = scan_shape.global_transform
	query.collide_with_bodies = true
	query.collide_with_areas = true
	query.exclude = [_scan_area.get_rid()]
	var results := space_state.intersect_shape(query, 32)

	var scanned_targets: Array = []
	for result in results:
		var collider: Node = result.get("collider")
		if collider == null or collider == self:
			continue
		if collider.has_method("on_scanned") and not scanned_targets.has(collider):
			scanned_targets.append(collider)

	EventBus.echo_scan_completed.emit(scanned_targets.size())
	for target in scanned_targets:
		target.on_scanned()

	await get_tree().create_timer(scan_glow_duration).timeout
	_glow_light.enabled = false
