extends Area

func _on_Void_body_entered(body):
	if(body.is_in_group("player")):
		body.get_node("NetworkHandler").remote_dead = true
	print("A player fell")
