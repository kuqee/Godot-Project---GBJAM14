extends AnimatedSprite2D

func set_segments_remaining(segments: int) -> void:
	# segments: 3 = full, 2, 1, or 0 = empty
	match segments:
		3: frame = 0
		2: frame = 1
		1: frame = 2
		_: frame = 3
