extends Area


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_FallArea_body_entered(body):
	if not body.is_in_group('ghost'):
		body.set_gravity_scale(2)
		body.set_linear_damp(0)
		if(body.is_in_group("player")):
			body.set_fall_state()
