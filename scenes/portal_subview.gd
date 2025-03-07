extends SubViewport
class_name portal_viewport2


func _ready() -> void:
	world_2d = get_parent().get_viewport().world_2d
	$Camera2D.position = get_parent().position


func set_cam_pos( new_size : Vector2,  cam_offset : Vector2 ) -> void:
	$Camera2D.position = get_parent().position + floor(cam_offset)
	size = ceil(new_size)
