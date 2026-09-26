#Weak Enemy Script

extends AnimatedSprite2D

@onready var telegraph_timer: Timer = $TelegraphTimer

@export var player_path: NodePath
var player: Node

@export_group("Parry Window")
@export var parry_window_start_frame: int = 6
@export var parry_window_end_frame: int = 10

@export_group("Timing")
@export var min_idle_wait: float = 0.0
@export var max_idle_wait: float = 1.0
@export var staggered_idle_wait: float = 3.0

@export_group("Animation Names")
@export var idle_anim: String = "idle"
@export var attack_anim: String = "attack"
@export var stagger_anim: String = "stagger"
@export var damaged_anim: String = "damaged"

var is_parry_window: bool = false
var parried: bool = false
var miss_registered: bool = false

var is_open: bool:
	get:
		return animation in [idle_anim, stagger_anim, damaged_anim]

func _ready() -> void:
	play(idle_anim)
	player = get_node(player_path)

	telegraph_timer.timeout.connect(_on_telegraph_timer_timeout)
	frame_changed.connect(_on_frame_changed)
	animation_finished.connect(_on_animation_finished)

	start_attack_cycle(randf_range(min_idle_wait, max_idle_wait), false)


func start_attack_cycle(wait_time: float, staggered: bool) -> void:
	parried = false
	is_parry_window = false
	miss_registered = false

	if staggered:
		play(stagger_anim)
	else:
		play(idle_anim)

	telegraph_timer.wait_time = wait_time
	telegraph_timer.start()


func _on_telegraph_timer_timeout() -> void:
	play(attack_anim)


func _on_frame_changed() -> void:
	if animation == attack_anim:
		is_parry_window = frame >= parry_window_start_frame and frame <= parry_window_end_frame

		if frame > parry_window_end_frame and not parried and not miss_registered:
			miss_registered = true
			print("Missed parry window - player takes damage.")
			if player != null and player.has_method("take_damage"):
				player.take_damage()
	else:
		is_parry_window = false


func _process(_delta: float) -> void:
	pass # no longer needed here - see notify_parry_attempt()


func notify_parry_attempt() -> bool:
	if is_parry_window and not parried:
		parried = true
		print("Parried!")
		return true
	return false


func _on_animation_finished() -> void:
	if animation == attack_anim:
		if parried:
			print("Successful parry - enemy staggered.")
			start_attack_cycle(staggered_idle_wait, true)
		else:
			start_attack_cycle(randf_range(min_idle_wait, max_idle_wait), false)


func take_hit() -> void:
	print("take_hit called - is_open: %s, animation: %s" % [is_open, animation])
	if is_open:
		var was_staggered: bool = (animation == stagger_anim)
		var resume_frame: int = frame

		play(damaged_anim)
		await get_tree().create_timer(0.1).timeout

		if was_staggered:
			play(stagger_anim)
			frame = resume_frame
