extends Camera

var raycast_position = Vector3.ZERO

var speed = 1
var travelling = true
var sound_played = false #idk why i have to do this but it calls ready twice???
onready var tp = get_parent().get_node("target_pos")

func _physics_process(_delta):
	cursor_raycast()
	travel_to_locrot(speed*_delta)

func cursor_raycast():
	if (InputEventMouseMotion):
		var mouse_position = get_tree().root.get_mouse_position()
		var raycast_from = project_ray_origin(mouse_position)
		var raycast_to = project_ray_normal(mouse_position)*10000
		
		# You might need a collision mask to avoid objects like the player...
		var space_state = get_world().direct_space_state
		var raycast_result = space_state.intersect_ray(raycast_from, raycast_to,[self],8, true, true)
		if(raycast_result):
			raycast_position = raycast_result.position

func travel_to_locrot(spd):
	if(travelling):
		if((transform.origin-tp.transform.origin).length() < 1):
			travelling = false
		transform = transform.interpolate_with(tp.transform, spd)
	
func start_travelling():
	travelling = true
