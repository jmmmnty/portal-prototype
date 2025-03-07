extends SubViewportContainer


func _ready() -> void:
	stretch = true
	ResolutionManager.resolution_changed.connect(_on_window_resized)
	_on_window_resized()
	$SubViewport.canvas_cull_mask -= 32


func _on_window_resized() -> void:
	stretch_shrink = int( ResolutionManager.multiplier )
	pass
