extends Control
class_name  rebind_window


signal button_set( new_button : InputEvent )

var event_name : StringName
var old_button : InputEvent
var new_button : InputEvent

func _ready() -> void:
	#dummy_values()
	pass

func dummy_values()->void:
	initialize( "move_down" )

func initialize( event : StringName )->void:
	event_name = event
	old_button = InputMap.action_get_events(event)[0]
	new_button = old_button
	set_text()

func set_text()->void:
	
	var label : Label = $CenterContainer/VBoxContainer/Label
	var current_label : Label = $CenterContainer/VBoxContainer/current_label
	var new_label : Label = $CenterContainer/VBoxContainer/new_label
	var note_label : Label = $CenterContainer/VBoxContainer/notes

	label.text = "Rebinding: " + str(event_name)
	current_label.text = "Current key: " + old_button.as_text()
	new_label.text = "New key: " + new_button.as_text()
	var note : String = ""
	note_label.text = note

func _unhandled_input(event: InputEvent) -> void:
	if event.is_released():
		return
	if event.is_action_type():
		new_button = event
		set_text()

func _on_set_pressed() -> void:
	button_set.emit( new_button )
	queue_free()


func _on_cancel_pressed() -> void:
	queue_free()
