extends Node
class_name resolution_manager

var internal_resolution : Vector2i = Vector2i(800, 480)
var viewport_resolution : Vector2i = Vector2i(800, 480)
var multiplier : float  = 1
#Offset to keep view centered with black bars
var vieweport_offset : Vector2i = Vector2i(0,0) 

# Polygon that covers the viewport
var viewport_polygon : PackedVector2Array

signal resolution_changed

# Only allow integer scaling
var strict_integer : bool = true
# Only allow orignal area withou any deviations
# Adds padding to compensate
var strict_area : bool = false

const RESIZED_MSG : String = "Display %s, viewport %s, internal %s, offset %s, multiplier %s, %.2f%%"
var target_resolution : Vector2i = Vector2(800, 480)

func _ready() -> void:
	get_tree().get_root().size_changed.connect(_on_window_resized)
	set_to_display( get_viewport().size )

func _on_window_resized() -> void:
	set_to_display( get_viewport().size )

func set_to_display( window_size : Vector2i )->void:
	# Sets internal and viewport resolutions to match window size 
	if strict_integer and strict_area:
		multiplier = min( window_size.x / float(target_resolution.x ), window_size.y / float(target_resolution.y ) )
		multiplier = floor( multiplier )
	else:
		multiplier = sqrt( window_size.x * window_size.y / float( target_resolution.x * target_resolution.y ) )
	if strict_integer:
		multiplier = round( multiplier )
	multiplier = max( multiplier, 1 )
	
	if strict_area:
		internal_resolution = target_resolution
	else:
		internal_resolution.x = int( window_size.x / multiplier )
		internal_resolution.y = int( window_size.y / multiplier )
	
	# Bug with camera movement.
	# size must be even number
	if internal_resolution.x%2:
		internal_resolution.x += 1
	if internal_resolution.y%2:
		internal_resolution.y += 1
	
	viewport_resolution = internal_resolution * multiplier
	if strict_integer and strict_area:
		# There may be need for black bars
		vieweport_offset = ( window_size - viewport_resolution ) / 2
	else:
		vieweport_offset = Vector2i(0,0)
	var view_area_ratio : float = internal_resolution.x*internal_resolution.y / float(target_resolution.x * target_resolution.y)
	print( RESIZED_MSG % [ window_size, viewport_resolution, internal_resolution, vieweport_offset, multiplier, view_area_ratio*100 ] )
	viewport_polygon = create_viewport_polygon()
	resolution_changed.emit()

func set_multiplier( new_multiplier : float )->void:
	# Window size does not change but multiplier changes
	internal_resolution = viewport_resolution / new_multiplier
	multiplier = new_multiplier
	print( RESIZED_MSG % [ Vector2i(0,0), viewport_resolution, internal_resolution, multiplier ] )
	viewport_polygon = create_viewport_polygon()
	resolution_changed.emit()
	pass

func create_viewport_polygon() -> PackedVector2Array:
	# Creates polygon that covers the internal resolution area
	var polygon : PackedVector2Array
	polygon.resize(4)
	polygon[0] = Vector2(0,0)
	polygon[1] = Vector2( internal_resolution.x,0 )
	polygon[2] = Vector2( internal_resolution.x,internal_resolution.y )
	polygon[3] = Vector2( 0,internal_resolution.y )
	
	var offset : Vector2 = Vector2( -internal_resolution.x / 2, -internal_resolution.y / 2 )
	polygon = Transform2D(0, offset) * polygon
	
	return polygon
