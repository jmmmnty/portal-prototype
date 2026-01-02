extends setting_widget
class_name setting_dropdown

var value : int = 0:
	set = value_changed,
	get = value_get

@export var choices : Array[String] = []:
	set = choices_changed

# Maps ID of the selected option into intended integer
# Use when the drop down menu indexes are not good for the job
# index of array is index in drop down. Value in array is value used
@export var mapping : Array[int] = []

func _ready() -> void:
	$Label.text = setting_name


func value_changed( new_value : int )->void:
	value = new_value
	$OptionButton.select(new_value)


func load_value( config : ConfigFile )->void:
	# TODO validate this to avoid loading garbage
	var new_value : int = config.get_value(variable_group, variable_name)
	if not mapping.is_empty():
		new_value = mapping.find( new_value )
		if new_value == -1:
			push_error("Invalid value %d for %s" % [config.get_value(variable_group, variable_name), variable_name])
	value = new_value


func value_get()->int:
	if mapping.is_empty():
		return $OptionButton.get_selected()
	else:
		return mapping[ $OptionButton.get_selected() ]


func choices_changed( new_choices : Array[String] )->void:
	choices = new_choices
	for choice in choices:
		$OptionButton.add_item( choice )
