extends Panel


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var music_bus = AudioServer.get_bus_index("Music")
var sounds_bus = AudioServer.get_bus_index("Sounds")

var button_map = ["move_up","move_down","move_left","move_right","push","pull","move_dash","summon_rock"]

var default_controls = {
	"move_up":KEY_W,
	"move_down":KEY_S,
	"move_left":KEY_A,
	"move_right":KEY_D,
	"push":"m"+str(BUTTON_LEFT),
	"pull":"m"+str(BUTTON_RIGHT),
	"move_dash":KEY_SPACE,
	"summon_rock":KEY_E,
	"music_volume":100,
	"effects_volume":100}
	
var data = default_controls
var input_mode = false

var current_button = ""

func controls_file_exists():
	var file = File.new()
	return file.file_exists("user://controls.json")


# Called when the node enters the scene tree for the first time.
func _ready():
	if controls_file_exists():
		var file = File.new()
		file.open("user://controls.json",File.READ)
		data = parse_json(file.get_line())
	set_all_controls(data)

func _input(event):
	if input_mode:
		if event is InputEventKey:
			data[current_button] = event.scancode
			update_button(current_button,event.as_text())
			input_mode=false
		elif event is InputEventMouseButton:
			data[current_button] = "m"+str(event.button_index)
			update_button(current_button,"m"+str(event.button_index))
			input_mode=false
		else:
			pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func set_all_controls(dict):
	for key in dict.keys():
		if key == "music_volume":
			_on_MusicSlider_value_changed(dict[key])
			continue
		elif key == "effects_volume":
			_on_EffectsSlider_value_changed(dict[key])
			continue
		InputMap.action_erase_events(key)
		var event
		if str(dict[key])=="m"+str(BUTTON_LEFT) or str(dict[key])=="m"+str(BUTTON_RIGHT):
			event = InputEventMouseButton.new()
			event.button_index = int(dict[key].substr(1,1))
			update_button(key,str(event.button_index))
		else:
			event = InputEventKey.new()
			event.scancode = dict[key]
			print(str(button_map.find(key)+1))
			update_button(key,event.as_text())
		InputMap.action_add_event(key,event)

func _on_Button_pressed(button_idx):
	input_mode = true
	current_button = button_map[button_idx]

func update_button(pos,text):
	get_node("Buttons/Button"+str(button_map.find(pos)+1)+"/Label").text = str(text)


func _on_BackButton_pressed():
	var file = File.new()
	file.open("user://controls.json",File.WRITE)
	file.store_line(to_json(data))
	file.close()
	set_all_controls(data)







func _on_MusicSlider_value_changed(value):
	var db = value
	if value == 0:
		AudioServer.set_bus_mute(music_bus,true)
	else:
		AudioServer.set_bus_mute(music_bus,false)
	AudioServer.set_bus_volume_db(music_bus,(86*value/100)-80)
	data["music_volume"] = value
		


func _on_EffectsSlider_value_changed(value):
	var db = value
	if value == 0:
		AudioServer.set_bus_mute(sounds_bus,true)
	else:
		AudioServer.set_bus_mute(sounds_bus,false)
	AudioServer.set_bus_volume_db(sounds_bus,(86*value/100)-80)
	data["effects_volume"] = value
