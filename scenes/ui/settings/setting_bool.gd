extends setting_widget
class_name setting_bool

@export var value : bool = false:
	set = value_changed

func _ready() -> void:
	$Label.text = setting_name

func value_changed( new_value : bool )->void:
	value = new_value
