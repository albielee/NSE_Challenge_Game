extends Area

func _on_FallArea_body_entered(body):
	if not body.is_in_group('ghost'):
		body.set_gravity_scale(2)
		body.set_linear_damp(0)
		if(body.is_in_group("player")):
			body.set_fall_state()
