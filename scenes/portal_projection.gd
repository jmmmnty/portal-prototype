extends Polygon2D
class_name portal_projection



func set_shape( new_polygon : PackedVector2Array ) -> void:
	polygon = new_polygon


func new_offset( new_offste : Vector2 ) -> void:
	texture_offset = -floor(new_offste)
	
