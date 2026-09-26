extends AnimatedSprite2D

@export var enemy_path: NodePath
var enemy: Node

var is_holding: bool = false
var is_stunned: bool = false
var parry_succeeded: bool = false

var light_attack_parry_frames: Array = [0, 1, 6, 7]
var heavy_attack_parry_frames: Array = [0, 1, 2, 10, 11]

var light_attack_hit_frames: Array = [4, 5]
var heavy_attack_hit_frames: Array = [4, 5, 6]

var hit_registered: bool = false

func _ready() -> void:
	play("idle")
	enemy = get_node(enemy_path)
	animation_finished.connect(_on_animation_finished)
	frame_changed.connect(_on_frame_changed)


func set_enemy(new_enemy: Node) -> void:
	enemy = new_enemy


func _can_cancel_current_animation() -> bool:
	if animation == "light_attack":
		return frame in light_attack_parry_frames
	elif animation == "heavy_attack":
		return frame in heavy_attack_parry_frames
	return true


func _can_parry() -> bool:
	if animation == "idle":
		return true
	elif animation == "light_attack":
		return frame in light_attack_parry_frames
	elif animation == "heavy_attack":
		return frame in heavy_attack_parry_frames
	return false


func _process(_delta: float) -> void:
	if is_stunned:
		return

	if Input.is_action_pressed("block") or Input.is_action_pressed("duck"):
		print("Holding: block=%s duck=%s | is_holding=%s | animation=%s" % [Input.is_action_pressed("block"), Input.is_action_pressed("duck"), is_holding, animation])
	# Held actions: block and duck
	if Input.is_action_pressed("block"):
		if animation != "block":
			if _can_cancel_current_animation():
				play("block")
				is_holding = true
		else:
			is_holding = true
		return
	elif Input.is_action_pressed("duck"):
		if animation != "duck":
			if _can_cancel_current_animation():
				play("duck")
				is_holding = true
		else:
			is_holding = true
		return
	else:
		if is_holding:
			is_holding = false
			play("idle")

	if not is_holding and Input.is_action_just_pressed("parry"):
		if _can_parry():
			parry_succeeded = enemy != null and enemy.has_method("notify_parry_attempt") and enemy.notify_parry_attempt()
			is_stunned = true
			play("parry")

	elif Input.is_action_just_pressed("light_attack"):
		hit_registered = false
		play("light_attack")
	elif Input.is_action_just_pressed("heavy_attack"):
		hit_registered = false
		play("heavy_attack")


func _on_frame_changed() -> void:
	if hit_registered:
		return

	if animation == "light_attack" and frame in light_attack_hit_frames:
		try_attack("light")
	elif animation == "heavy_attack" and frame in heavy_attack_hit_frames:
		try_attack("heavy")


func try_attack(attack_type: String) -> void:
	hit_registered = true
	if enemy != null:
		print("Enemy animation at hit: %s | is_open: %s" % [enemy.animation, enemy.is_open])
	if enemy != null and "is_open" in enemy and enemy.is_open:
		print("Landed a %s attack on the enemy!" % attack_type)
		enemy.take_hit()
	else:
		print("%s attack whiffed - enemy wasn't open." % attack_type.capitalize())


func _on_animation_finished() -> void:
	if animation == "parry":
		if parry_succeeded:
			is_stunned = false
			play("idle")
		else:
			frame = 0
			await get_tree().create_timer(1.0).timeout
			is_stunned = false
			play("idle")
	elif animation in ["light_attack", "heavy_attack"]:
		play("idle")


func take_damage() -> void:
	if animation == "block":
		print("Blocked!")
		return

	is_stunned = true
	is_holding = false
	play("damaged")
	await get_tree().create_timer(0.5).timeout
	is_stunned = false
	play("idle")
