extends SubViewport
class_name base_subviewport

## Extends SubViewport with funcions that all SubViewports need

func _ready() -> void:
	SettingsManager.graphics_settings_changed.connect( set_graphics )
	set_graphics()

func set_graphics()->void:
	msaa_2d = SettingsManager.get_msaa()
	canvas_item_default_texture_filter = SettingsManager.get_texture_filtering()
