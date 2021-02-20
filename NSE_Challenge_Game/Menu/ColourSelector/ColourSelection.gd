extends Control


onready var colours = [Color(255,0,0),Color(0,255,0),Color(0,0,255),Color(255,0,255)]
onready var colourDisplay = $DisplayColour

var colourIndex = 0
var run = false

func _ready():
	colourDisplay.modulate = colours[0]

func _process(delta):
	if(gamestate.colours_recieved and !run):
		run = true
		var available_colours = gamestate.get_available_colours()
		print(available_colours)
		var settled = false
		while(!settled):	
			if(colourIndex > 3):
				colourIndex = 0
			if(available_colours[colourIndex]):
				settled = true
			colourIndex += 1
		gamestate.set_colour(colourIndex)
		colourDisplay.modulate = colours[colourIndex]

func _on_SelectRight_pressed():
	var available_colours = gamestate.get_available_colours()
	var settled = false
	while(!settled):	
		colourIndex += 1
		if(colourIndex > 3):
			colourIndex = 0
		if(available_colours[colourIndex]):
			settled = true
	gamestate.set_colour(colourIndex)
	colourDisplay.modulate = colours[colourIndex]


func _on_SelectLeft_pressed():
	var available_colours = gamestate.get_available_colours()
	var settled = false
	while(!settled):	
		colourIndex -= 1
		if(colourIndex < 0):
			colourIndex = 3
		if(available_colours[colourIndex]):
			settled = true
	gamestate.set_colour(colourIndex)
	colourDisplay.modulate = colours[colourIndex]
