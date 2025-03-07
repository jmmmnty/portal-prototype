extends Node
class_name utils

static func get_polygon_size( polygon : PackedVector2Array ) -> Vector2:
	var min_point : Vector2 = Vector2.ZERO
	var max_point : Vector2 = Vector2.ZERO
	
	for point : Vector2 in polygon:
		min_point.x = min( min_point.x, point.x )
		min_point.y = min( min_point.y, point.y )
		max_point.x = max( max_point.x, point.x )
		max_point.y = max( max_point.y, point.y )
	return max_point-min_point

static func get_polygon_center( polygon : PackedVector2Array ) -> Vector2:
	var min_point : Vector2 = Vector2.ZERO
	var max_point : Vector2 = Vector2.ZERO
	
	for point : Vector2 in polygon:
		min_point.x = min( min_point.x, point.x )
		min_point.y = min( min_point.y, point.y )
		max_point.x = max( max_point.x, point.x )
		max_point.y = max( max_point.y, point.y )
	return (max_point+min_point)/2

## Returns top left orner of polygon
static func get_polygon_corner( polygon : PackedVector2Array ) -> Vector2:
	var corner : Vector2
	
	for point : Vector2 in polygon:
		corner.x = min( corner.x, point.x )
		corner.y = min( corner.y, point.y )
	
	return corner
	
