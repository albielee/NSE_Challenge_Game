extends Camera

var raycast_position = Vector3.ZERO

func _physics_process(_delta):
	cursor_raycast()

func cursor_raycast():
	if (InputEventMouseMotion):
		var mouse_position = get_tree().root.get_mouse_position()
		var raycast_from = project_ray_origin(mouse_position)
		var raycast_to = project_ray_normal(mouse_position)*1000
		
		# You might need a collision mask to avoid objects like the player...
		var space_state = get_world().direct_space_state
		var raycast_result = space_state.intersect_ray(raycast_from, raycast_to,[self],8, true, true)
		if(raycast_result):
			raycast_position = raycast_result.position
