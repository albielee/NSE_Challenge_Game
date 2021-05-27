extends AnimatedSprite

var falling = false
var fall_to = Vector2.ZERO
var accel = 4
var max_speed = 10
var speed = 0

func _process(delta):
	if(_is_playing()):
		$filledSquare.scale = Vector2((frame+1/10), 1)
	if(falling):
		fall(delta)
		
func fall(delta):
	if(speed < max_speed):
		speed += accel*delta 
	transform.origin.x -= speed
	#stop when arrived
	if(transform.origin.x < (fall_to.x+transform.origin.x*0.01)):
		transform.origin.x = fall_to.x
		transform.origin.y = fall_to.y
		falling = false
	
func init(x, y, fall_x, fall_y, colour):
	$filledSquare.modulate = colour
	$filledSquare.visible = false
	transform.origin.x = x
	transform.origin.y = y
	fall_to.x = fall_x
	fall_to.y = fall_y
	_set_playing(true)


func _on_scoreBox_animation_finished():
	_set_playing(false)
	frame = 9
	$filledSquare.scale = Vector2(1, 1)
	$filledSquare.visible = true
	falling = true
