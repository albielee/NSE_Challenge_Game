extends Sprite

var falling = false
var fall_to = Vector2.ZERO
var accel = 1
var max_speed = 5
var speed = 0

func _process(delta):
	if(falling):
		fall(delta)
		
func fall(delta):
	if(speed < max_speed):
		speed += accel*delta 
	transform.origin.x += speed
	#stop when arrived
	if(transform.origin.x < (transform.origin.x+transform.origin.x*0.01)):
		transform.origin.x = fall_to.x
		transform.origin.y = fall_to.y
		falling = false
	
func init(x, y, colour):
	$filledSquare.modulate = colour
	fall_to.x = x
	fall_to.y = y
	falling = true
