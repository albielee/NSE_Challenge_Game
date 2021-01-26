extends RigidBody


# Declare member variables here. Examples:
# var a = 2
# var b = "text"



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if(Input.get_action_strength("move_right")):
		add_central_force(Vector3(100,0,0))
