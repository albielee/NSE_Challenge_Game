extends Area

signal player_fell

sync func player_fell(player_name, last_attacker):
	print("A player fell")
	emit_signal("player_fell",player_name,last_attacker)

func _on_Void_body_entered(body):
	if get_tree().is_network_server():
		if(body.is_in_group("player")):
			body.get_node("NetworkHandler").remote_dead = true
			body.get_node("NetworkHandler").rset("remote_dead", true)
			rpc("player_fell", body.player_name, body.last_attacker)
		if(body.is_in_group("rock")):
			print("A rock fell")
			body.destroy()
