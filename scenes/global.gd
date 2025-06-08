extends Node

var view_rotation : Transform2D = Transform2D()
signal view_rotated( new_rotation : Transform2D )
signal position_changed( new_position : Vector2)

func set_view_transform( new_transform : Transform2D ) -> void:
	view_rotation = new_transform
	view_rotated.emit( new_transform )

func update_overlays( new_pos : Vector2 ) -> void:
	position_changed.emit( new_pos )
	pass
