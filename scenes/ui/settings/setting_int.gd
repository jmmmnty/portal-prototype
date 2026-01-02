extends setting_widget
class_name setting_int

@export var value : int = 0:
	set = value_changed

@export var min_value : int = 0
@export var max_value : int = 1

var previous_input : String = ""

func _ready() -> void:
	$Label.text = setting_name
	$TextEdit.text = str( value )
	previous_input = str( value )

func value_changed( new_value : int )->void:
	value = new_value


func load_value( config : ConfigFile )->void:
	# TODO validate this to avoid loading garbage
	value = config.get_value(variable_group, variable_name)
	$TextEdit.text = str(value)

func _on_text_edit_text_changed() -> void:
	if $TextEdit.text.is_valid_int():
		previous_input = $TextEdit.text
	elif $TextEdit.text == "-":
		previous_input = $TextEdit.text
	else:
		# Invalid input. Silently reject
		var column : int = $TextEdit.get_caret_column() - 1
		$TextEdit.text = previous_input
		$TextEdit.set_caret_column(column)
	var new_value : int = int( $TextEdit.text )
	if new_value >= min_value and new_value <= max_value:
		value=new_value
	else:
		# Invalid value. Silently ignore
		pass


func _on_text_edit_focus_exited() -> void:
	$TextEdit.text = str(value)
