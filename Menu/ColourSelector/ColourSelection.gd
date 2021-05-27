extends Control


onready var colours = [Color("0099db"),Color("68386c"),Color("feae34"),Color("3e8948")]
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
	if(get_tree().is_network_server()):
		gamestate.available_colours[gamestate.player_colour_index] = 1
		gamestate.player_colour_index = wrapi(gamestate.player_colour_index+1, 0, 4)
		var found = false
		while(!found):
			if(gamestate.available_colours[gamestate.player_colour_index]):
				found = true
				gamestate.available_colours[gamestate.player_colour_index] = 0
#				print("From Server: Found hosts next colour: " + str(gamestate.player_colour_index))
			else:
				gamestate.player_colour_index = wrapi(gamestate.player_colour_index+1, 0, 4)
		gamestate.players_colour[1] = gamestate.player_colour_index
#		print("Available colours = " + str(gamestate.available_colours))
#		print("Players colour dictionary = " + str(gamestate.players_colour))
	else:
		gamestate.call_server_next_colour()


func _on_SelectLeft_pressed():
	pass
