extends UnitComponent
class_name InputComponent


func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("mouse_left"):
		print( "MOUSE")
	var direction : Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var look_point : Vector2 = get_global_mouse_position()
	main_node.move( direction, look_point, _delta )
	
