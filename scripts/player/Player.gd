extends CharacterBody2D
## Player
## 主人公（名を持たない技術者）の移動・ジャンプ制御と、
## InteractAreaを介した周辺オブジェクトへのインタラクト処理。

@export var speed: float = 300.0
@export var movement_acceleration: float = 2500.0
@export var stop_deceleration: float = 1900.0
@export var dash_speed: float = 760.0
@export var dash_duration: float = 0.16
@export var dash_cooldown: float = 0.55
@export var jump_velocity: float = -770.0
@export var jump_anticipation_time: float = 0.15 ## Spaceを押してから実際に飛び上がるまでの「タメ」の時間（秒）
@export var landing_duration: float = 0.20 ## 着地時の衝撃吸収しゃがみを表示する時間（秒）
@export var max_health: int = 100
@export var attack_damage: int = 15
@export var attack_offset: float = 40.0
@export var small_scale: float = 0.55
@export var big_scale: float = 1.6

const SPRITE_OFFSET_Y: float = -20.0 ## 通常重力時のスプライトYオフセット（反転時は符号反転して使う）
const MOVEMENT_ANIMATION_THRESHOLD: float = 14.0
const CLIMB_EXIT_DURATION: float = 0.32
const CLIMB_EXIT_SPEED: float = 160.0

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var health: int = max_health
var facing_dir: int = 1
var _is_attacking: bool = false
var gravity_dir: int = 1 ## 1=通常, -1=反転（FLIP LABギミック用）
var _gravity_toggle_cooldown: float = 0.0
var _external_lock_time: float = 0.0
var _dash_time: float = 0.0
var _dash_cooldown: float = 0.0
var _dash_dir: int = 1
var size_mode: String = "normal" ## "normal" or "small"（SIZE DOCKギミック用）
var _size_toggle_cooldown: float = 0.0
var is_climbing: bool = false ## true中ははしごを登り降り中（Ladderギミック用、各ステージ共通）
@export var climb_speed: float = 160.0
@export var respawn_delay: float = 2.0 ## 落下判定からリスポーンまでの待ち時間（秒）
@export var bob_amplitude: float = 2.0 ## 歩行時の頭の上下バウンスの振れ幅(px)
@export var squash_amount: float = 0.06 ## 歩行時のスクワッシュ&ストレッチの強さ(0〜1)
@export var run_bob_amplitude: float = 10.0 ## "run"アニメーション追加時用（未使用なら無視される）
@export var run_squash_amount: float = 0.1 ## "run"アニメーション追加時用（未使用なら無視される）

var _start_position: Vector2
var _is_respawning: bool = false
var _was_on_floor: bool = true
var _jump_anticipating: bool = false
var _climb_exit_time: float = 0.0

@onready var _interact_area: Area2D = $InteractArea
@onready var _attack_area: Area2D = $AttackArea
@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	add_to_group("player")
	_start_position = global_position
	EventBus.player_health_changed.emit(health, max_health)
	_update_attack_area_position()
	_sprite.animation_finished.connect(_on_animation_finished)
	_interact_area.area_entered.connect(_on_interact_area_entered)
	_interact_area.area_exited.connect(_on_interact_area_exited)
	_interact_area.body_entered.connect(_on_interact_body_entered)
	_interact_area.body_exited.connect(_on_interact_body_exited)

func _on_interact_area_entered(area: Area2D) -> void:
	## インタラクト範囲に入ったオブジェクトへ、近接プロンプト（Eアイコン等）の
	## 表示を依頼する。show_prompt()を持たないオブジェクトには何もしない。
	if area.has_method("on_interact") and area.has_method("show_prompt"):
		area.show_prompt()

func _on_interact_area_exited(area: Area2D) -> void:
	if area.has_method("hide_prompt"):
		area.hide_prompt()

func _on_interact_body_entered(body: Node) -> void:
	## NOAのようにArea2DではなくCharacterBody2D等の「ボディ」である
	## インタラクト対象用（上のarea_enteredと同じ役割）。
	if body.has_method("on_interact") and body.has_method("show_prompt"):
		body.show_prompt()

func _on_interact_body_exited(body: Node) -> void:
	if body.has_method("hide_prompt"):
		body.hide_prompt()

func _physics_process(delta: float) -> void:
	if _is_respawning:
		return

	if _gravity_toggle_cooldown > 0.0:
		_gravity_toggle_cooldown -= delta
	if _external_lock_time > 0.0:
		_external_lock_time -= delta
	if _size_toggle_cooldown > 0.0:
		_size_toggle_cooldown -= delta
	if _dash_cooldown > 0.0:
		_dash_cooldown -= delta
	if _climb_exit_time > 0.0:
		_climb_exit_time = maxf(0.0, _climb_exit_time - delta)

	if Input.is_action_just_pressed("dash"):
		_try_dash()
	var is_dashing: bool = _dash_time > 0.0
	if is_dashing:
		_dash_time = maxf(0.0, _dash_time - delta)
		velocity = Vector2(_dash_dir * dash_speed, 0.0)
		if _dash_time == 0.0:
			velocity.x = _dash_dir * speed

	if not is_dashing and _climb_exit_time > 0.0:
		# 梯子の上端から体を持ち上げて、足場へ移る。
		velocity.y = -CLIMB_EXIT_SPEED * gravity_dir
	elif not is_dashing and not is_on_floor() and not is_climbing:
		velocity.y += gravity * gravity_dir * delta

	if is_climbing:
		velocity.y = Input.get_axis("move_up", "move_down") * climb_speed

	if not is_dashing and Input.is_action_just_pressed("jump"):
		if is_climbing:
			# はしごから軽く飛び降りる（通常ジャンプよりやや弱め）
			set_climbing(false, false)
			_climb_exit_time = 0.0
			velocity.y = jump_velocity * gravity_dir * 0.6
		elif is_on_floor() and not _jump_anticipating:
			_start_jump_anticipation()

	if not is_dashing and Input.is_action_just_pressed("interact"):
		_try_interact()

	if not is_dashing and Input.is_action_just_pressed("echo_command"):
		EventBus.echo_command_issued.emit("scan")

	if not is_dashing and Input.is_action_just_pressed("attack"):
		_try_attack()
		_is_attacking = true
		_sprite.play("attack")

	var direction: float = Input.get_axis("move_left", "move_right")
	if is_dashing:
		direction = _dash_dir
	elif direction != 0:
		velocity.x = move_toward(velocity.x, direction * speed, movement_acceleration * delta)
		if direction > 0.0:
			facing_dir = 1
		else:
			facing_dir = -1
		_update_attack_area_position()
	else:
		velocity.x = move_toward(velocity.x, 0.0, stop_deceleration * delta)

	move_and_slide()

	if is_on_floor() and not _was_on_floor and not is_climbing and _climb_exit_time <= 0.0 and not _is_attacking and _external_lock_time <= 0.0:
		# 着地の瞬間、専用の"landing"アニメーション（衝撃を吸収するしゃがみ、
		# フレーム18〜24）を表示する。
		lock_animation("landing", landing_duration)
	_was_on_floor = is_on_floor()

	_update_animation()
	_apply_walk_bob(delta)

func _on_animation_finished() -> void:
	if _sprite.animation == "attack":
		_is_attacking = false
	if not _sprite.sprite_frames.get_animation_loop(_sprite.animation):
		_external_lock_time = 0.0

func _update_animation() -> void:
	# climb素材は背面寄りの固定向きなので、梯子上で左右反転すると
	# 手の位置が不自然に入れ替わる。横移動時だけ通常の反転を使う。
	if is_climbing:
		_sprite.flip_h = false
	else:
		_sprite.flip_h = facing_dir < 0
	_sprite.flip_v = gravity_dir < 0
	if _is_attacking or _external_lock_time > 0.0:
		return
	if _climb_exit_time > 0.0:
		if _sprite.animation != &"climb_exit":
			_sprite.play("climb_exit")
		return
	if is_climbing:
		# 専用の登りアニメーション（"climb"）が登録されればそちらを優先使用。
		# 未登録の間はkneelを暫定流用する。
		var climb_anim: StringName = &"climb" if _sprite.sprite_frames.has_animation(&"climb") else &"kneel"
		_sprite.speed_scale = clampf(absf(velocity.y) / climb_speed, 0.7, 1.0)
		if _sprite.animation != climb_anim:
			_sprite.play(climb_anim)
		if Input.get_axis("move_up", "move_down") == 0.0:
			_sprite.pause()
		elif not _sprite.is_playing():
			_sprite.play()
		return
	var target_anim: StringName
	if not is_on_floor():
		target_anim = &"jump" if velocity.y * gravity_dir < 0 else &"fall"
		_sprite.speed_scale = 1.0
	elif absf(velocity.x) > MOVEMENT_ANIMATION_THRESHOLD:
		target_anim = &"walk"
		_sprite.speed_scale = clampf(absf(velocity.x) / speed, 0.7, 1.1)
	else:
		target_anim = &"idle"
		_sprite.speed_scale = 1.0
	if _sprite.animation != target_anim:
		_sprite.play(target_anim)

func _apply_walk_bob(delta: float) -> void:
	## 絵は変えず、歩行中だけ疑似的な上下バウンス＋スクワッシュ&ストレッチを
	## 上乗せする。時間経過ではなく「現在再生中のアニメーションの何コマ目か
	## （frame / frame_count）」から位相を計算しているため、再生速度が変わっても
	## 絶対にズレない。停止時はmove_towardで滑らかに元の姿勢へ戻す。
	var base_offset := SPRITE_OFFSET_Y * gravity_dir
	var is_walking: bool = is_on_floor() and not is_climbing and absf(velocity.x) > MOVEMENT_ANIMATION_THRESHOLD and not _is_attacking and _external_lock_time <= 0.0
	var is_airborne: bool = not is_on_floor() and not is_climbing and not _is_attacking and _external_lock_time <= 0.0
	var pose_rotation: float = 0.0
	var pose_scale: Vector2 = Vector2.ONE
	if is_airborne:
		var vertical_ratio: float = clampf((velocity.y * gravity_dir) / absf(jump_velocity), -1.0, 1.0)
		# 上昇は前へ伸び、下降は着地に備えて少し沈む。
		pose_scale = Vector2.ONE
		pose_rotation = facing_dir * vertical_ratio * 0.04
		_sprite.rotation = lerp_angle(_sprite.rotation, pose_rotation, minf(delta * 14.0, 1.0))
	else:
		_sprite.rotation = lerp_angle(_sprite.rotation, 0.0, minf(delta * 14.0, 1.0))
	if _dash_time > 0.0:
		_sprite.position.y = base_offset
		_sprite.scale = Vector2(1.12, 0.88)
		return

	if is_walking:
		var current_anim: StringName = _sprite.animation
		var amplitude: float = bob_amplitude
		var squash: float = squash_amount
		if current_anim == "run": # 将来"run"アニメーションを追加した場合用
			amplitude = run_bob_amplitude
			squash = run_squash_amount

		var frame_count: int = _sprite.sprite_frames.get_frame_count(current_anim)
		var progress: float = float(_sprite.frame) / float(max(frame_count, 1))
		# 1歩行サイクル=バウンス2回（右足接地・左足接地でそれぞれ1回沈む）。
		var phase: float = progress * TAU * 2.0
		var raw_sin: float = sin(phase)
		# 綺麗な正弦波のままだと「フワフワ無重力」に見えてしまうため、
		# 沈み込み側は鋭く（2乗気味に）、持ち上がり側はなだらかにして
		# 「ドスンと踏み込む」重量感のある非対称カーブにする。
		var bob: float
		if raw_sin < 0.0:
			bob = -pow(abs(raw_sin), 1.5)
		else:
			bob = raw_sin * 0.7

		var bob_offset: float = bob * amplitude
		_sprite.position.y = base_offset - bob_offset * gravity_dir

		# 沈み込む瞬間(bob=-1)は縦に潰れ、最高点(bob=1)は縦に伸びる。
		var stretch: float = 1.0 + bob * squash
		_sprite.scale = Vector2(2.0 - stretch, stretch)
	else:
		# 立ち止まった瞬間にパッと戻さず、滑らかに元の姿勢へ戻す。
		_sprite.position.y = move_toward(_sprite.position.y, base_offset, 300.0 * delta)
		_sprite.scale = _sprite.scale.move_toward(pose_scale, 8.0 * delta)

func play_action(action_name: StringName) -> void:
	## kneel/pickup/pull/push/victory など、移動と無関係な単発モーションを
	## インタラクトイベント等から再生するための汎用エントリーポイント。
	if not _sprite.sprite_frames.has_animation(action_name):
		return
	_sprite.play(action_name)
	if not _sprite.sprite_frames.get_animation_loop(action_name):
		var frame_count: int = _sprite.sprite_frames.get_frame_count(action_name)
		var frame_rate: float = maxf(_sprite.sprite_frames.get_animation_speed(action_name), 1.0)
		_external_lock_time = float(frame_count) / frame_rate

func lock_animation(anim_name: StringName, duration: float) -> void:
	## WIRE BAYのワイヤー引っ張り等、外部のギミックが一時的に
	## プレイヤーのアニメーションを固定したい場合に使う汎用メソッド。
	## duration秒の間、_update_animation()による自動切替を止める。
	if _sprite.sprite_frames.has_animation(anim_name):
		_sprite.play(anim_name)
		_external_lock_time = maxf(duration, 0.0)

func _start_jump_anticipation() -> void:
	## Spaceを押した瞬間に即座に飛び上がらず、しゃがみ姿勢を一瞬見せてから
	## 実際に空中へ飛び出す「タメ」を作る。地面から離れる直前まで
	## velocity.yは変更しない（＝見た目上もまだ地面に立っている）。
	_jump_anticipating = true
	lock_animation("jump_anticipation", jump_anticipation_time)
	await get_tree().create_timer(jump_anticipation_time).timeout
	_jump_anticipating = false
	if is_on_floor():
		velocity.y = jump_velocity * gravity_dir

func _try_dash() -> void:
	if _dash_cooldown > 0.0 or _dash_time > 0.0 or not is_on_floor():
		return
	if is_climbing or _is_attacking or _external_lock_time > 0.0:
		return
	var direction: float = Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		if direction > 0.0:
			_dash_dir = 1
		else:
			_dash_dir = -1
	else:
		_dash_dir = facing_dir
	facing_dir = _dash_dir
	_update_attack_area_position()
	_dash_time = dash_duration
	_dash_cooldown = dash_cooldown

func toggle_gravity() -> void:
	## FLIP LABの重力反転ギミック用。GravityFlipPad等から呼ばれる。
	## up_directionを反転させることで、Godot標準のis_on_floor()判定を
	## 反転後の「床（＝元の天井）」に正しく追従させている。
	if _gravity_toggle_cooldown > 0.0:
		return
	gravity_dir *= -1
	up_direction = Vector2(0, -gravity_dir)
	velocity.y = 0.0
	_gravity_toggle_cooldown = 0.5

func set_size_mode(target: String) -> void:
	## SIZE DOCKのサイズ切替ギミック用。SizeTogglePad等から、目的の大きさを
	## 指定して呼ばれる（"small" / "normal" / "big"の3段階）。
	## Player自体をscaleすることで、子ノード（コリジョン・スプライト・
	## 各種Area2D）をまとめて縮小/拡大している。
	if _size_toggle_cooldown > 0.0 or size_mode == target:
		return
	size_mode = target
	match target:
		"small":
			scale = Vector2(small_scale, small_scale)
		"big":
			scale = Vector2(big_scale, big_scale)
		_:
			scale = Vector2(1.0, 1.0)
	_size_toggle_cooldown = 0.5

func set_climbing(value: bool, play_exit: bool = true) -> void:
	## Ladder（各ステージ共通の縦移動ギミック）から呼ばれる。
	## 登り中は重力を無効化し、move_up/move_downで昇降する。
	var was_climbing := is_climbing
	is_climbing = value
	if value:
		_climb_exit_time = 0.0
		velocity.y = 0.0
	elif was_climbing and play_exit:
		# 梯子の最後の数フレームを使って、上端へよじ登る動作にする。
		_climb_exit_time = CLIMB_EXIT_DURATION
		_sprite.play("climb_exit")
		_sprite.speed_scale = 1.0

func on_fall_death() -> void:
	## FallZone（各ステージの床の隙間の下に配置）に触れた瞬間に呼ばれる。
	## 時間や距離による推測は行わず、実際にその高さまで落ちたかどうかだけで判定する。
	if _is_respawning:
		return
	_start_fall_respawn()

func _start_fall_respawn() -> void:
	## 非表示＋操作停止にしてrespawn_delay秒後にステージ開始位置へ戻す。
	## 重力反転・縮小状態も混乱を避けるため通常状態にリセットする。
	_is_respawning = true
	visible = false
	velocity = Vector2.ZERO
	_dash_time = 0.0
	_dash_cooldown = 0.0
	is_climbing = false
	await get_tree().create_timer(respawn_delay).timeout
	gravity_dir = 1
	up_direction = Vector2.UP
	size_mode = "normal"
	scale = Vector2(1.0, 1.0)
	global_position = _start_position
	velocity = Vector2.ZERO
	visible = true
	_is_respawning = false

func _update_attack_area_position() -> void:
	_attack_area.position.x = facing_dir * attack_offset

func _try_interact() -> void:
	## get_overlapping_bodies()/get_overlapping_areas()は、直前まで重なって
	## いなかった相手に対してEキーを押した瞬間には反応しないことがある
	## （監視キャッシュの更新が追いつかないため）。攻撃判定と同じく、
	## 物理エンジンへの直接クエリ（intersect_shape）で判定する。
	var interact_shape: CollisionShape2D = $InteractArea/InteractShape
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = interact_shape.shape
	query.transform = interact_shape.global_transform
	query.collide_with_bodies = true
	query.collide_with_areas = true
	query.exclude = [get_rid()]
	var results := space_state.intersect_shape(query, 32)

	for result in results:
		var collider: Node = result.get("collider")
		if collider == null or collider == self:
			continue
		if collider.has_method("on_interact"):
			collider.on_interact()
			return

func _try_attack() -> void:
	## Area2Dのget_overlapping_bodies()は「継続的に置いておくトリガー範囲」
	## （InteractArea/ScanArea等）には向いているが、攻撃のように一瞬だけ
	## 判定したいケースでは監視キャッシュの更新が追いつかず反応しないことが
	## あるため、物理エンジンへの直接クエリ（intersect_shape）で判定する。
	var attack_shape: CollisionShape2D = $AttackArea/AttackShape
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = attack_shape.shape
	query.transform = attack_shape.global_transform
	query.collide_with_bodies = true
	query.collide_with_areas = true
	query.exclude = [get_rid()]
	var results := space_state.intersect_shape(query, 32)

	var hit_targets: Array = []
	for result in results:
		var collider: Node = result.get("collider")
		if collider == null or collider == self:
			continue
		if collider.has_method("take_damage") and not hit_targets.has(collider):
			hit_targets.append(collider)
		else:
			# NOAのHitboxAreaのように、当たり判定を別Area2Dとして持つ相手用
			var parent := collider.get_parent()
			if parent and parent != self and parent.has_method("take_damage") and not hit_targets.has(parent):
				hit_targets.append(parent)
	for target in hit_targets:
		target.take_damage(attack_damage)

func take_damage(amount: int) -> void:
	health = max(0, health - amount)
	EventBus.player_health_changed.emit(health, max_health)
	_flash_damage()
	_react_to_hit()
	if health <= 0:
		EventBus.player_died.emit()

func _flash_damage() -> void:
	## 被弾したことが分かるよう、一瞬赤く点滅させる。
	var tween := create_tween()
	tween.tween_property(_sprite, "modulate", Color(1.6, 0.3, 0.3), 0.06)
	tween.tween_property(_sprite, "modulate", Color(1, 1, 1), 0.1)
	tween.tween_property(_sprite, "modulate", Color(1.6, 0.3, 0.3), 0.06)
	tween.tween_property(_sprite, "modulate", Color(1, 1, 1), 0.1)

func _react_to_hit() -> void:
	## 点滅だけでなく、軽いノックバック（重力の逆方向へ弾かれる）と
	## 一瞬のひるみポーズ（kneelを流用）で、痛そうな反応にする。
	if _is_respawning:
		return
	velocity.y = jump_velocity * gravity_dir * 0.35
	velocity.x = -facing_dir * speed * 0.6
	lock_animation("kneel", 0.25)

func heal(amount: int) -> void:
	health = min(max_health, health + amount)
	EventBus.player_health_changed.emit(health, max_health)
