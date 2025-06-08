extends Polygon2D

func _process(delta: float) -> void:
	var direction : Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	position += direction * 10
