extends Control


onready var colours = [Color(255,0,0),Color(0,255,0),Color(0,0,255),Color(255,0,255)]
onready var colourDisplay = $DisplayColour

var colourIndex = 0
var run = false
var old_c = 0

func _ready():
	colourDisplay.modulate = colours[0]

func _process(delta):
	var pc = gamestate.player_colour_index
	if(old_c != pc):
		colourDisplay.modulate = colours[pc]
	old_c = pc
	
func _on_SelectRight_pressed():
	gamestate.call_server_next_colour()


func _on_SelectLeft_pressed():
	pass
