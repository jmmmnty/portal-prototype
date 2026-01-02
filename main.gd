extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("settings"):
		settings_window()
		pass
	pass

func settings_window()->void:
	if $settings_menu.visible:
		$settings_menu.hide()
		$game.process_mode = Node.PROCESS_MODE_INHERIT
	else:
		$settings_menu.show()
		$game.process_mode = Node.PROCESS_MODE_DISABLED
	pass
