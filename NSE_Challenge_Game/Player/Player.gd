extends RigidBody

var movement = Vector2.ZERO
var pushpull = 0.0
var summon = 0.0
var mouse_angle = Vector3.ZERO
var controls = [movement, pushpull, summon, mouse_angle]

var current_angle = Vector3.ZERO
var velocity = Vector3.ZERO

enum {
	MOVE,
	DASH,
	SUMMON,
	PUSH,
	PULL,
	FALL,
	DEATH
}
var state = MOVE
var rock_summoned = false

export var MASS = 10
export var FRICTION = 10
export var MAX_SPEED = 500
export var SPEED = 2000
export var TURN_SPEED = 400
export var PUSH_POWER = 500

onready var pushbox = $PushBox
onready var network_handler = $NetworkHandler
onready var animation_player = $AnimationPlayer
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

func host_get_controls():
	controls = network_handler.update_controls()
	movement = controls[0]
	pushpull = controls[1]
	summon = controls[2]
	mouse_angle = controls[3]

#Required inputs: Camera location and current body location
func get_controls(cam):
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_vector.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	input_vector = input_vector.normalized()
	
	var pushpull = Input.get_action_strength("push")-Input.get_action_strength("pull")
	
	var summon = Input.get_action_strength("summon_rock")
	
	var offset = deg2rad(90)
	
	var mouse_angle = Vector3.ZERO
	
	if(cam != null):
		var up_dir = Vector3.UP
		var target_position = cam.raycast_position
		var current_angle_y = get_transform().basis.get_euler().y;
		var target_angle_y = get_transform().looking_at(target_position, up_dir).basis.get_euler().y;
		var rotation_angle = wrapf(target_angle_y - current_angle_y, -PI, PI);
		
		mouse_angle = up_dir * (rotation_angle);
		
	return [input_vector, pushpull, summon, mouse_angle]

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

#Takes given control input and updates actions of the player, hands info back to handler
func update(delta):
	if(mode != MODE_RIGID):
		set_mode(RigidBody.MODE_RIGID)
	
	movement = controls[0] 
	pushpull = controls[1] 
	summon = controls[2]
	mouse_angle = controls[3]
	
	current_angle = angle_update()
	pushbox.knockback_vector=PUSH_POWER*current_angle
	
	match state:
		MOVE:
			move_state(delta, mouse_angle)
		DASH:
			dash_state(delta)
		SUMMON:
			summon_state(delta)
		PUSH:
			push_state(delta)
		PULL:
			pull_state(delta)
	
	if(summon and rock_summoned == false):
		state = SUMMON;
		rock_summoned = true
	if(!summon):
		rock_summoned = false

func move_state(delta, mouse_angle):
	#Handle movement, set to directional or set to 0
	if (movement != Vector2.ZERO):
		velocity = velocity.move_toward(Vector3(movement.x*MAX_SPEED,0,movement.y*MAX_SPEED), SPEED*delta)
	else:
		velocity = Vector3.ZERO
	
	#Handle entering pushing or pulling states, for which player must not have been
	#doing other shit
	if(pushpull==1):
		state = PUSH
	
	#Handle rotation of the character towards correct direction
	set_angular_velocity(mouse_angle*TURN_SPEED*delta)
	
	move()

func move():
	add_force(velocity, Vector3.ZERO)

func dash_state(delta):
	pass

func summon_state(delta):
	#Apply friction
	velocity = Vector3.ZERO
	
	var rock_name = get_name()
	var offset = 1
	var y_rot = -get_transform().basis.get_euler().y
	var rock_pos = Vector3(translation.x + offset*sin(y_rot), 0, translation.z - offset*cos(y_rot))
	rpc("summon_rock", rock_name, rock_pos , get_tree().get_network_unique_id())
	state = MOVE

sync func summon_rock(rock_name, pos, by_who):
	var rock = preload("res://Objects/Rock/Rock.tscn").instance()
	rock.set_name(rock_name)
	
	set_mode(RigidBody.MODE_KINEMATIC)
	rock.translation = pos
	set_mode(RigidBody.MODE_RIGID)

	get_node("../..").add_child(rock)


func push_state(delta):
	velocity = Vector3.ZERO
	animation_player.play("push_generic")
	
func push_complete():
	state=MOVE

func pull_state(delta):
	pass

func set_player_name(name):
	pass
#	network_handler.set_player_name(name)

func angle_update():
	var current_angle_y = get_transform().basis.get_euler().y;
	var curang = wrapf(current_angle_y,-PI,PI)
	return Vector3(-sin(curang),0,-cos(curang))
	
func _on_SendData_timeout():
	network_handler.timeout(get_rotation(),get_transform().origin)
