extends HBoxContainer

@export var action : StringName = "move_down"


func _ready() -> void:
	verify()
	set_text()


func verify()->void:
	if !InputMap.has_action( action ):
		push_error( "INVALID ACTION: ", str( action ) )


func set_text()->void:
	# Assumes only one button per action
	$Label.text = str(action)
	$bound.text = InputMap.action_get_events(action)[0].as_text()


func _on_rebind_pressed() -> void:
	# get_window().add_child.call_deferred(si)
	var scene := load("res://scenes/ui/settings/rebind_window.tscn")
	var dialog : rebind_window = scene.instantiate()
	dialog.initialize( action )
	get_window().add_child.call_deferred(dialog)
	dialog.connect( "button_set", key_rebind)


func key_rebind( new_key : InputEvent )->void:
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, new_key)
	SettingsManager.set_key( action, new_key )
	# TODO resolve conflicting keys
	set_text()
