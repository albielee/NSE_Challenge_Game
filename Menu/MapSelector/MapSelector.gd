extends Control


var maps = ["res://Worlds/world.tscn"]
var mapIndex = 0

func _ready():
	$Label.text = maps[0]

func _on_ButtonLeft_pressed():
	mapIndex -= 1
	if(mapIndex < 0):
		mapIndex = len(maps)-1
	$Label.text = maps[mapIndex]


func _on_ButtonRight_pressed():
	mapIndex += 1
	if(mapIndex > len(maps)-1):
		mapIndex = 0
	$Label.text = maps[mapIndex]
