extends Panel


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var button_map = ["move_up","move_down","move_left","move_right","push","pull","move_dash","summon_rock"]

var default_controls = {
	"move_up":KEY_W,
	"move_down":KEY_S,
	"move_left":KEY_A,
	"move_right":KEY_D,
	"push":"m"+str(BUTTON_LEFT),
	"pull":"m"+str(BUTTON_RIGHT),
	"move_dash":KEY_SPACE,
	"summon_rock":KEY_E}
	
var input_mode = false

var current_button = ""

func controls_file_exists():
	var file = File.new()
	return file.file_exists("user://controls.json")


# Called when the node enters the scene tree for the first time.
func _ready():
	var data = {}
	if controls_file_exists():
		var file = File.new()
		file.open("user://controls.json",File.READ)
		data.parse_json(file.get_line())
	else:
		data = default_controls
	for key in data.keys():
		InputMap.action_erase_events(key)
		var event
		if str(data[key])=="m"+str(BUTTON_LEFT) or str(data[key])=="m"+str(BUTTON_RIGHT):
			event = InputEventMouseButton.new()
			event.button_index = int(data[key].substr(1,1))
			get_node("Buttons/Button"+str(button_map.find(key)+1)+"/Label").text = str(event.button_index)
		else:
			event = InputEventKey.new()
			event.scancode = data[key]
			print(str(button_map.find(key)+1))
			get_node("Buttons/Button"+str(button_map.find(key)+1)+"/Label").text = event.as_text()
		InputMap.action_add_event(key,event)
	pass # Replace with function body.

func _input(event):
	if input_mode:
		if event is InputEventKey:
			pass
		elif event is InputEventMouseButton:
			
			update_control(1)
		else:
			pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func update_control(event):
	pass

func _on_Button_pressed(button_idx):
	input_mode = true
	current_button = button_map[button_idx]
