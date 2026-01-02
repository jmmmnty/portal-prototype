extends Node
class_name utils

static func get_polygon_size( polygon : PackedVector2Array ) -> Vector2:
	var min_point : Vector2 = polygon[0]
	var max_point : Vector2 = polygon[0]
	
	for point : Vector2 in polygon:
		min_point.x = min( min_point.x, point.x )
		min_point.y = min( min_point.y, point.y )
		max_point.x = max( max_point.x, point.x )
		max_point.y = max( max_point.y, point.y )
	return max_point-min_point

static func get_polygon_center( polygon : PackedVector2Array ) -> Vector2:
	var min_point : Vector2 = polygon[0]
	var max_point : Vector2 = polygon[0]
	
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

## Returns rectangle that covers the polygon
static func get_polygon_rect( polygon : PackedVector2Array ) -> Rect2:
	var min_corner : Vector2 = polygon[0]
	var max_corner : Vector2 = polygon[0]
	
	for point : Vector2 in polygon:
		min_corner.x = min( point.x, min_corner.x )
		min_corner.y = min( point.y, min_corner.y )
		max_corner.x = max( point.x, max_corner.x )
		max_corner.y = max( point.y, max_corner.y )
	
	var size : Vector2 = max_corner - min_corner
	var pos : Vector2 = min_corner
	return Rect2(pos, size)

## Rounds polygon points into integer coordinates
## Returns integer rounded polygon
static func integer_polygon( polygon : PackedVector2Array ) -> PackedVector2Array:
	var int_polygon : PackedVector2Array
	for point in polygon:
		int_polygon.append( round( point ) )
	return int_polygon

## Returns polygon of specified size
## The polygon is centered to its area
static func centered_polygon( size : Vector2 ) -> PackedVector2Array:
	var polygon : PackedVector2Array
	polygon.resize(4)
	polygon[0] = Vector2( 0, 0 )
	polygon[1] = Vector2( size.x, 0 )
	polygon[2] = Vector2( size.x + 1, size.y  )
	polygon[3] = Vector2( 0, size.y  )
	
	var offset : Vector2 = Vector2( -size.x / 2, -size.y / 2 )
	polygon = Transform2D( 0, offset ) * polygon
	
	return polygon

static func print_config( config : ConfigFile )->void:
	for section in config.get_sections():
		for key in config.get_section_keys( section ):
			print( "%s/%s = %s" % [ section, key, str( config.get_value(section, key) ) ] )
