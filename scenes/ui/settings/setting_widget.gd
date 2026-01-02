extends Control
class_name setting_widget


@export var setting_name : String = ""
@export_multiline var description : String = ""

@export var require_restart : bool = false

# Variable to which this setting is stored.
# Also used for saving settings on file
# Must be unique
@export var variable_name : String = ""
@export var variable_group : String = ""
