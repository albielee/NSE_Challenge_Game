extends RigidBody

var movement = Vector2.ZERO
var pushpull = 0.0
var summon = 0.0
var grab = 0.0
var mouse_position = Vector3.ZERO
var controls = [movement, pushpull, summon, grab, mouse_position]

var mouse_angle = Vector3.ZERO
var current_angle = Vector3.ZERO
var velocity = Vector3.ZERO

enum {
	MOVE,
	DASH,
	SUMMON,
	PUSH,
	PULL,
	GRAB,
	GRABBED,
	FALL,
	DEATH
}
var state = MOVE

var anim = "idle"
var prevanim = "idle"

var rock_summoned = false

export var MASS = 10
export var FRICTION = 10
export var MAX_SPEED = 500
export var SPEED = 2000
export var TURN_SPEED = 400
export var PUSH_POWER = 500

onready var pushbox = $PushBox
onready var grabbox = $GrabBox

onready var network_handler = $NetworkHandler
onready var animationtree = $AnimationTree	
onready var animationstate = animationtree.get("parameters/playback")
onready var spawn_position = network_handler.spawn_position

func _ready():
	set_linear_damp(FRICTION)
	set_mass(MASS)

func _physics_process(delta):
	#check if dead using networkhandler death
	if(state != FALL and state != DEATH and network_handler.remote_dead):
		state = FALL
	
	if(network_handler.is_current_player()):
		controls = get_controls(network_handler.get_cam())
		network_handler.current_player(controls)
	else:
		host_get_controls()
	
	if(network_handler.is_host()):
		update(delta)
	else:
		puppet_update(delta)
	
	handle_animations(anim)

func host_get_controls():
	controls = network_handler.update_controls()
	movement = controls[0]
	pushpull = controls[1]
	summon = controls[2]
	grab = controls[3]
	mouse_position = controls[4]

#Required inputs: Camera location and current body location
func get_controls(cam):
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_vector.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	input_vector = input_vector.normalized()
	
	var pushpull = Input.get_action_strength("push")-Input.get_action_strength("pull")
	
	var summon = Input.get_action_strength("summon_rock")
	
	var grab = Input.get_action_strength("temp_float")
	
	var offset = deg2rad(90)
	
	if(cam != null):
		mouse_position = cam.raycast_position
	
	return [input_vector, pushpull, summon, grab, mouse_position]

func puppet_update(delta):
	if(mode != MODE_KINEMATIC):
		set_mode(RigidBody.MODE_KINEMATIC)

	var p = get_transform().origin

	var interpolate_speed = 0.1
	var x = move_toward(p.x, network_handler.remote_position.x, interpolate_speed)
	var y = move_toward(p.y, network_handler.remote_position.y, interpolate_speed)
	var z = move_toward(p.z, network_handler.remote_position.z, interpolate_speed)
	transform.origin = Vector3(x,y,z)
	set_rotation(network_handler.remote_rotation)
	anim = network_handler.remote_animation

func handle_animations(animation):
	if (animation!=prevanim):
		animationstate.travel(animation)
	prevanim = animationstate.get_current_node()

#Takes given control input and updates actions of the player
func update(delta):
	if(mode != MODE_RIGID):
		set_mode(RigidBody.MODE_RIGID)
	
	movement = controls[0] 
	pushpull = controls[1] 
	summon = controls[2]
	grab = controls[3]
	mouse_position = controls[4]
	
	angle_update()
	pushbox.knockback_vector=PUSH_POWER*current_angle
	
	match state:
		MOVE:
			move_state(delta, mouse_angle)
		DASH:
			dash_state(delta)
		SUMMON:
			summon_state()
		PUSH:
			push_state(delta)
		PULL:
			pull_state(delta)
		GRAB:
			grab_state(delta)
		GRABBED:
			grabbed_state(delta)

func move_state(delta, mouse_angle):
	#Handle movement, set to directional or set to 0
	if (movement != Vector2.ZERO):
		velocity = velocity.move_toward(Vector3(movement.x*MAX_SPEED,0,movement.y*MAX_SPEED), SPEED*delta)
	else:
		velocity = Vector3.ZERO
	
	#Handle summoning rocks, for which a player cannot have been doing other shit
	if(summon and rock_summoned == false):
		state = SUMMON;
		rock_summoned = true
	if(!summon):
		rock_summoned = false
		if(grab==1):
			state = GRAB
		else:
			if(pushpull==1):
				state = PUSH
	
	#Handle rotation of the character towards correct direction
	set_angular_velocity(mouse_angle*TURN_SPEED*delta)
	
	move()

func move():
	add_force(velocity, Vector3.ZERO)

func dash_state(delta):
	pass

func grab_state(delta):
	#check if grabbing got cancelled
	if (check_cancel_grab()):
		return
	
	anim="grabbing"
	grabbox.transform.origin.z-=0.1
	
	
	if (movement != Vector2.ZERO):
		velocity = velocity.move_toward(Vector3(movement.x*MAX_SPEED/3,0,movement.y*MAX_SPEED/3), SPEED*delta)
	else:
		velocity = Vector3.ZERO
	
	set_angular_velocity(mouse_angle*TURN_SPEED/5*delta)
	move()

func grabbed_state(delta):
	if (check_cancel_grab()):
		return
	
	if (movement != Vector2.ZERO):
		velocity = velocity.move_toward(Vector3(movement.x*MAX_SPEED/2.5,0,movement.y*MAX_SPEED/2.5), SPEED*delta)
	else:
		velocity = Vector3.ZERO
	
	set_angular_velocity(mouse_angle*TURN_SPEED/4*delta)
	move()	
	
func check_cancel_grab():
	if (grab==0):
		anim="idle"
		state=MOVE
		grabbox.transform.origin.z=-1
		return true
	return false

func max_grab():
	state = GRABBED
	anim = "grabmax"

func summon_state():
	velocity = Vector3.ZERO
	
	var rock_name = get_name()
	var offset = 1
	var y_rot = -get_transform().basis.get_euler().y
	var rock_pos = Vector3(translation.x + offset*sin(y_rot), 0, translation.z - offset*cos(y_rot))
	network_handler.all_summon_rock(rock_name, rock_pos)
	state = MOVE

func push_state(delta):
	velocity = Vector3.ZERO
	anim = "push_generic"

func push_complete():
	state = MOVE
	anim = "idle"

func pull_state(delta):
	pass

func set_player_name(name):
	pass
#	network_handler.set_player_name(name)

func angle_update():
	var current_angle_y = get_transform().basis.get_euler().y;
	var curang = wrapf(current_angle_y,-PI,PI)
	current_angle = Vector3(-sin(curang),0,-cos(curang))
	
	if(mouse_position != Vector3.ZERO):
		var up_dir = Vector3.UP
		var target_angle_y = get_transform().looking_at(mouse_position, up_dir).basis.get_euler().y;
		var rotation_angle = wrapf(target_angle_y - current_angle_y, -PI, PI);
		
		mouse_angle = up_dir * (rotation_angle);

#On timeout, update data back to server: Position, rotation, animation
func _on_SendData_timeout():
	network_handler.timeout(get_rotation(),get_transform().origin,anim)
