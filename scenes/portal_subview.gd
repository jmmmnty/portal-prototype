extends SubViewport
class_name portal_viewport2

var camera : Camera2D

func _ready() -> void:
	world_2d = get_parent().get_viewport().world_2d


func set_cam_pos( new_size : Vector2,  cam_offset : Vector2 ) -> void:
	camera.position = get_parent().position + floor(cam_offset)
	size = ceil(new_size)
