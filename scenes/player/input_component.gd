extends UnitComponent
class_name InputComponent


func _physics_process(_delta: float) -> void:
	var direction : Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	main_node.move( direction, _delta )
	
