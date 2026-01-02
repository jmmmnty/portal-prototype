extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var lisence_text : String = ""
	
	lisence_text += "Source code available at [url]https://github.com/jmmmnty/portal-prototype[/url] \n"
	
	lisence_text += "This project is released under MIT lisence.\n\n"
	var file : FileAccess = FileAccess.open("res://LICENSE", FileAccess.READ)
	lisence_text += file.get_as_text()
	
	lisence_text += "\n\n--------------\n\n"
	lisence_text += "This game uses Godot Engine, available under the following license:\n"
	lisence_text += Engine.get_license_text()
	
	$lisence.append_text( lisence_text )


func _on_lisence_meta_clicked(meta: Variant) -> void:
	OS.shell_open(str(meta))
