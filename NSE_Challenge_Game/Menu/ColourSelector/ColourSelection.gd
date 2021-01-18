extends Control


onready var colours = [Color(255,0,0),Color(0,255,0),Color(0,0,255),Color(255,0,255)]
onready var colourDisplay = $DisplayColour

var colourIndex = 0

func _ready():
	colourDisplay.modulate = colours[0]

func _on_SelectRight_pressed():
	colourIndex += 1
	if(colourIndex > 3):
		colourIndex = 0
	colourDisplay.modulate = colours[colourIndex]


func _on_SelectLeft_pressed():
	colourIndex -= 1
	if(colourIndex < 0):
		colourIndex = 3
	colourDisplay.modulate = colours[colourIndex]
