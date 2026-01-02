extends SubViewportContainer


func _ready() -> void:
	stretch = true
	ResolutionManager.resolution_changed.connect(_on_window_resized)
	_on_window_resized()
	$SubViewport.canvas_cull_mask -= 32


func _on_window_resized() -> void:
	stretch_shrink = int( ResolutionManager.multiplier )
	scale = Vector2( ResolutionManager.scale, ResolutionManager.scale )
	position = ResolutionManager.vieweport_offset
	size = ResolutionManager.viewport_resolution

func add_projection( projection : Polygon2D ) -> void:
	$SubViewport.add_projection( projection )
	pass

func add_wall( wall : solid_wall ) -> void:
	$vision.add_wall( wall )

func sort_projections( camera_pos : Vector2 ) -> void:
	$SubViewport.sort_projections( camera_pos )
