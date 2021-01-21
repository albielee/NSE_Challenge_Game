extends Area2D


func _on_DeathVoid_body_entered(body):
	if(body.has_method("fall_state")):
		body.rpc("fall_state")
		
