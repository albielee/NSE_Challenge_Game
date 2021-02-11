extends Node

var current_time = 0
var last_time = 0

func _physics_process(delta):
	current_time += delta

func _on_Timer_timeout():
#	print(get_tree().is_network_server())
#	print(current_time-last_time)
	last_time=current_time
	$SendData.start(1.0/Settings.tickrate)
