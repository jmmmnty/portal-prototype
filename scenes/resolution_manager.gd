extends Node
class_name resolution_manager

signal resolution_changed

# Internal resolution determines view distance
var internal_resolution : Vector2i
# Viewport resolution includes integer scaling
var viewport_resolution : Vector2i

# Integer multiplier for viewport container
var multiplier : int  = 1

# Scale for fractional scaling
var scale : float = 1

#Offset to keep view centered with black bars
var vieweport_offset : Vector2i = Vector2i(0,0) 

# Polygon that covers the viewport
var viewport_polygon : PackedVector2Array

# Allow fractional scaling
var fractional_scaling : bool = true

var target_resolution : Vector2i = Vector2(800, 480)
# Pixel Vector2(800, 480)
# 720p  Vector2(1280, 720)
# 1080p Vector2(1920, 1080)
# 1440p Vector2(2560, 1440)

# Allow drawing this multiplier bigger area to avoid black bars
var extend_limit : Vector2 = Vector2(1,1)

# Avoid resizing constantly when dragging
var timer : Timer

func _ready() -> void:
	get_tree().get_root().size_changed.connect(_on_window_resized)
	SettingsManager.graphics_settings_changed.connect( _on_settings_changed )
	_on_settings_changed()
	set_to_display()
	timer = Timer.new()
	add_child(timer)
	timer.one_shot = true
	timer.timeout.connect( set_to_display )


func _on_settings_changed()->void:
	target_resolution = SettingsManager.get_internal_resolution()
	extend_limit = SettingsManager.get_resolution_flex()
	fractional_scaling = SettingsManager.get_fractional_scaling()
	set_to_display()

func _on_window_resized() -> void:
	delayed_set_size()

func delayed_set_size()->void:
	timer.start( 0.02 )

func set_to_display()->void:
	var window_size : Vector2i = get_viewport().size
	
	if fractional_scaling:
		multiplier = int( min( window_size.x / float(target_resolution.x ), window_size.y / float(target_resolution.y ) ) )
		multiplier = max( multiplier, 1 )
		scale = min( window_size.x / float(target_resolution.x * multiplier ), window_size.y / float(target_resolution.y * multiplier ) )
	else:
		scale = 1
		multiplier = round( min( window_size.x / float(target_resolution.x ), window_size.y / float(target_resolution.y ) ) )
		multiplier = max( multiplier, 1 )
	
	internal_resolution.x = min( target_resolution.x * extend_limit.x, window_size.x / multiplier / scale )
	internal_resolution.y = min( target_resolution.y * extend_limit.y, window_size.y / multiplier / scale )
	
	# Internal resolution must be even number to avoid rounding errors
	internal_resolution.x += internal_resolution.x % 2
	internal_resolution.y += internal_resolution.y % 2
	
	viewport_resolution = internal_resolution * multiplier
	
	vieweport_offset = ( Vector2( window_size ) - viewport_resolution * scale ) / 2
	
	const RESIZED_MSG : String = "Display %s, viewport %s, internal %s, offset %s, int scale %s, frac scale %s, frac %s"
	print( RESIZED_MSG % [ window_size, viewport_resolution, internal_resolution, vieweport_offset, multiplier, scale, fractional_scaling ] )
	viewport_polygon = utils.centered_polygon( internal_resolution )
	resolution_changed.emit()
