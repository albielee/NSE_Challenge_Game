extends Area


onready var objs = [$grass_tall1, $grass_tall2,$grass_tall3,$grass_tall4,$grass_tall5,$grass_tall6]
var frame = int(rand_range(0,4))
# Called when the node enters the scene tree for the first time.
func _ready():
	get_global_transform().rotated(Vector3(1.0,1.0,0.0).normalized(), rand_range(-PI,PI))
	get_global_transform().scaled(Vector3(1.0,rand_range(0.3,1.0),1.0))

func _on_Grass_body_entered(body):
	if(body != self and frame!=8):
		var t = body.get_linear_velocity().normalized()
		var ang = atan2(-t.z,t.x)+deg2rad(180)
		$flat.rotation = Vector3(0.0,ang,0.0)
		$Anim.paused = true
		objs[frame].hide()
		frame = 8
		$flat.show()


func _on_Anim_timeout():
	objs[frame].hide()
	frame+=1
	if(frame==6):
		frame = 0
	objs[frame].show()
	$Anim.start()

