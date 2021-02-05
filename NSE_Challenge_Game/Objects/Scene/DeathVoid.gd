extends Area

signal player_fell

func _on_Void_body_entered(body):
	if(body.is_in_group("player")):
		body.get_node("NetworkHandler").remote_dead = true
		print("A player fell")
		emit_signal("player_fell",body.player_name,body.last_attacker)
