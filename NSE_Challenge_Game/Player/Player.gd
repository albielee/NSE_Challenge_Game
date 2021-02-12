extends RigidBody

export var SCALE = 1.0
export var MASS = 10
export var FRICTION = 10
export var MAX_SPEED = 8
export var ACCELERATION = 10
export var SPEED = 2000
export var TURN_SPEED = 400
export var PUSH_POWER = 300
export var DASH_INC = 2.0
export var DASH_COOLDOWN = 40.0
export var GRAB_POWER = 10
export var GRAB_DROPOFF_VAL = 1.0

var movement = Vector2.ZERO
var pushpull = 0.0
var summon = 0.0
var grab = 0.0
var dash = 0.0
var mouse_position = Vector3.ZERO

var controls = [movement, pushpull, summon, grab, dash, mouse_position]

var player_name = ""

var touched = false

var mouse_angle = Vector3.ZERO
var current_angle = Vector3.ZERO
var current_dir = Vector3.ZERO
var move_velocity = Vector3.ZERO

var puppet_last_position = transform.origin
var puppet_next_position = transform.origin
var puppet_speed = 0.0
var r_rotation = 0.0
var r_position = transform.origin
var r_animation = "idle"
var r_velocity = Vector3.ZERO
var r_stats = [r_rotation,r_position,r_animation,r_velocity]

var lp = Vector3.ZERO
var lptime = 1.0

enum {
	MOVE,
	DASH,
	SUMMON,
	SUMMONING,
	PUSH,
	PULL,
	GRAB,
	GRABBED,
	FALL,
	DEATH
}
var state = MOVE

var current_time = 0.0
var last_packet_time = 0.0
var packet_time = 0.0
var elapsed_time = 0.0
var proj_packet_time = 0.0
var ideal_updates_per_packet = 0.0
var updates_per_packet = 0.0

var anim = "idle"
var prevanim = "idle"

var push_cooldown = 0
var push_mouse_position = mouse_position

var summon_size = 0.5
var rock_summoned = false

var dash_angle = current_angle
var can_dash = 0.0

var last_attacker=""

var last_time = 0

onready var UPDATE_INTERVAL = 1.0 / $"/root/Settings".tickrate

onready var pushbox = $PushBox
onready var pullbox = $PullBox
onready var grabbox = $GrabBox

onready var network_handler = $NetworkHandler
onready var animationtree = $AnimationTree	
onready var animationstate = animationtree.get("parameters/playback")
onready var spawn_position = Vector3.ZERO

var _updates = 0.0
var _packets = 0.0
var avg = 0.0
var _delta = 0.0

func _ready():
	set_linear_damp(10)
	set_mass(MASS)
	$CollisionShape.scale=Vector3(SCALE*0.5,SCALE*0.5,SCALE*0.5)
	$MeshInstance.scale=Vector3(SCALE*0.5,SCALE*0.5,SCALE*0.5)
	
	pushbox.scale=Vector3(2*SCALE,SCALE,SCALE)
	pushbox.transform.origin.z=(-1.0*SCALE)
	
	pullbox.scale=Vector3(2*SCALE,SCALE,SCALE)
	pullbox.transform.origin.z=(-1.0*SCALE)
	
	grabbox.scale=Vector3(SCALE,SCALE,SCALE)
	grabbox.transform.origin.z=(-1.8*SCALE)
	grabbox.shape.shape.set_height(0.5*SCALE)
	
	proj_packet_time = UPDATE_INTERVAL

func _physics_process(delta):
	current_time += delta
	
	#check if dead using networkhandler death
	if(state != FALL and state != DEATH and network_handler.remote_dead):
		state = FALL
	
	#If current player: Give controls to host
	#If other player: Receive the controls for that player
	if(network_handler.is_current_player()):
		controls = get_controls(network_handler.get_cam())
		update(delta)
	else:
		puppet_update(delta)
	
	handle_animations(anim)

func get_network_handler():
	return network_handler

#Required inputs: Camera location and current body location
func get_controls(cam):
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_vector.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	input_vector = input_vector.normalized()
	
	var _pushpull = Input.get_action_strength("push")-Input.get_action_strength("pull")
	
	var _summon = Input.get_action_strength("summon_rock")
	
	var _grab = Input.get_action_strength("temp_float")
	
	var _dash = Input.get_action_strength("move_dash")
	
	if(cam != null):
		mouse_position = cam.raycast_position
	
	return [input_vector, _pushpull, _summon, _grab, _dash, mouse_position]

func puppet_update(delta):
	_delta = delta
#	print(updates_per_packet)
	if(mode != MODE_RIGID):
		set_mode(RigidBody.MODE_RIGID)
	
	var time = 0
	
	if len(buffer) > 0 and time <= 0:
		var statstime = buffer.pop_front()
		time = statstime[1]
		r_stats = statstime[0]
		r_rotation = r_stats[0]
		r_position = r_stats[1]
		r_animation = r_stats[2]
		r_velocity = r_stats[3]
	
	var p = get_transform().origin
	var dir = (puppet_next_position-p).normalized()
	var dist = p.distance_to(puppet_next_position)
	var speed = r_velocity.length()
	
	if time > 0: 
		puppet_speed = dist / time
		
		#inter fucking polate this shit
		var cur_speed = get_linear_velocity()
		var goal_speed = puppet_speed*dir
		set_linear_velocity(cur_speed.linear_interpolate(goal_speed,delta/0.5))
	
	#actually also interpolate this shit
	puppet_rotation(r_rotation,delta)
	
	anim = r_animation
	
	time -= delta

func puppet_rotation(target,delta):
	var angular_veloc =  Vector3.UP * wrapf(target-get_transform().basis.get_euler().y, -PI, PI);
	
	set_angular_velocity(angular_veloc*TURN_SPEED*delta)

func _on_NetworkHandler_packet_received():
	#how long since the last packet?
	elapsed_time = current_time - last_packet_time
	
	avg = average_packet_time(elapsed_time)
	
	#the next packet will probably arrive earlier/later depending on how early/late this one was
	proj_packet_time = UPDATE_INTERVAL - (elapsed_time-UPDATE_INTERVAL)
	
	#set this time to be the time the last packet arrived
	last_packet_time = current_time
	
	lptime = proj_packet_time
	
	build_buffer(network_handler.update_stats(), avg)
	
	puppet_next_position = r_position + (r_velocity * elapsed_time)
	
#	lp = (puppet_next_position-r_position) / (UPDATE_INTERVAL + jitter)

var packets = []
var buffer = []

func build_buffer(newstats, average):
	buffer.push_back([newstats,average])

func average_packet_time(newpacket_elapsed):
	packets.append(newpacket_elapsed)
	if len(packets) > 50:
		packets.remove(0)
	var total = 0.0
	for time in packets:
		total += time
	return total/len(packets)

func handle_animations(animation):
	if (animation!=prevanim):
		animationstate.travel(animation)
	prevanim = animationstate.get_current_node()

#Takes given control input and updates actions of the player
func update(delta):
	if(mode != MODE_RIGID):
		set_mode(RigidBody.MODE_RIGID)
	
	if touched: set_last_attacker()
	
	movement = controls[0] 
	pushpull = controls[1] 
	summon = controls[2]
	grab = controls[3]
	dash = controls[4]
	mouse_position = controls[5]
	
	angle_update()
	grabbox.knockback_vector=300*current_angle
	grabbox.pullin_vector=-300*current_angle
	grabbox.cf_update(global_transform.origin, GRAB_POWER, GRAB_DROPOFF_VAL)
	pushbox.knockback_vector=current_angle
	pushbox.update_angle(get_transform().basis.get_euler().y, mouse_angle,  global_transform.origin)
	if (pushbox.rock != null): 
#		pushbox.update_angle(get_transform().looking_at(mouse_position, Vector3.UP).basis.get_euler().y, mouse_angle)
		pushbox.update(mouse_position, get_transform().looking_at(pushbox.rock_position, Vector3.UP).basis.get_euler().y)
	
	match state:
		MOVE:
			move_state(delta, mouse_angle)
		DASH:
			dash_state(delta)
		SUMMON:
			summon_state()
		SUMMONING:
			summoning_state()
		PUSH:
			push_state(delta)
		PULL:
			pull_state(delta)
		GRAB:
			grab_state(delta)
		GRABBED:
			grabbed_state(delta)

func set_last_attacker():
	var bodies = get_colliding_bodies()
	touched = false
	for b in bodies:
		if b.is_in_group("rock"):
			if b.last_mover!="":
				last_attacker = b.last_mover
				break

func move_state(delta, mouse_angle):
	#Handle movement, set to directional or set to 0
	if (movement != Vector2.ZERO):
		move_velocity = move_velocity.move_toward(Vector3(movement.x*MAX_SPEED,0,movement.y*MAX_SPEED), ACCELERATION*delta)
		dash_angle = Vector3(movement.x,0,movement.y)
	else:
		move_velocity = move_velocity.move_toward(Vector3.ZERO, FRICTION*delta)
	
	set_angular_velocity(mouse_angle*TURN_SPEED*delta)
	
	#Handle summoning rocks, for which a player cannot have been doing other shit
	# Priority order: dash,summon, Grab, Push/pull
	if(dash and can_dash <= 0.0):
		set_angular_velocity(Vector3.ZERO)
		state = DASH
		rock_summoned = false
	else:
		can_dash -= 1.0
		if(summon and rock_summoned == false):
			set_angular_velocity(Vector3.ZERO)
			state = SUMMON;
			rock_summoned = true
		else:
			rock_summoned = false
			if(grab==1):
				state = GRAB
			else:
				if(pushpull==1 and push_cooldown==0):
					push_mouse_position=mouse_position
					state = PUSH
				elif(pushpull==0):
					push_cooldown=0
	move()

func move():
	if (move_velocity!=Vector3.ZERO):
		set_linear_velocity(move_velocity)

func dash_state(delta):
	anim="dash"
	move_velocity = move_velocity.move_toward(dash_angle*MAX_SPEED*DASH_INC,ACCELERATION*DASH_INC*delta)
	move()

func dash_finished():
	anim="idle"
	state=MOVE
	can_dash=DASH_COOLDOWN

func grab_state(delta):
	set_angular_velocity(mouse_angle*TURN_SPEED*delta)
	#check if grabbing got cancelled
	if (check_cancel_grab()):
		return
	
	anim="grabbing"
	
	#update the shape of the grabbing box
	grabbox.transform.origin.z -= 0.05*SCALE
	grabbox.shape.shape.set_height(grabbox.shape.shape.get_height()+0.1)
	
	if (movement != Vector2.ZERO):
		move_velocity = move_velocity.move_toward(Vector3(movement.x*MAX_SPEED/3,0,movement.y*MAX_SPEED/3), SPEED*delta)
	else:
		move_velocity = Vector3.ZERO
	
	set_angular_velocity(mouse_angle*TURN_SPEED/5*delta)
	move()

func grabbed_state(delta):
	if (check_cancel_grab()):
		return
	
	var distance = transform.origin.distance_squared_to(grabbox.transform.origin)
	if (pushpull < 0):
		grabbox.pull(transform.origin, GRAB_DROPOFF_VAL)
	if (pushpull > 0):
		grabbox.push(transform.origin, GRAB_DROPOFF_VAL)
	
	if (movement != Vector2.ZERO):
		move_velocity = move_velocity.move_toward(Vector3(movement.x*MAX_SPEED/2.5,0,movement.y*MAX_SPEED/2.5), SPEED*delta)
	else:
		move_velocity = Vector3.ZERO
	
	set_angular_velocity(mouse_angle*TURN_SPEED/4*delta)
	move()

func check_cancel_grab():
	if (grab==0):
		anim="idle"
		state=MOVE
		grabbox.drop_rock()
		grabbox.transform.origin.z=(-1.8*SCALE)
		grabbox.shape.shape.set_height(0.5*SCALE)
		return true
	return false

func max_grab():
	state=GRABBED
	anim = "grabmax"

func _on_GrabBox_encounter_rock():
	state = GRABBED
	anim = "grabmax"

func _on_GrabBox_lost_rock():
	anim="idle"
	state=MOVE
	grabbox.drop_rock()
	grabbox.transform.origin.z=-1.8
	grabbox.shape.shape.set_height(0.5)

func summon_state():
	move_velocity = Vector3.ZERO
	anim = "summon_charge"

func summoning_state():
	anim = "summon_generic"

func summon_complete():
	move_velocity = Vector3.ZERO
	
	var rock_name = get_name()
	var offset = summon_size
	var y_rot = -get_transform().basis.get_euler().y
	var rock_pos = Vector3(translation.x + offset*sin(y_rot), 0, translation.z - offset*cos(y_rot))
	network_handler.all_summon_rock(rock_name, rock_pos, summon_size)
	
	summon_size=0.5
	anim = "idle"
	state = MOVE

func summon_power_up():
	summon_size+=0.5
	if (summon == 0.0) or (summon_size == 3.0):
		state=SUMMONING

func push_state(delta):
	set_angular_velocity(get_mouse_angle(get_transform().basis.get_euler().y, push_mouse_position)*TURN_SPEED*delta)
	move_velocity = Vector3.ZERO
	if pushpull == 1 and anim != "push_over":
		#update pushbox shape
		if(pushbox.shape.shape.get_height()<40*SCALE):
			pushbox.shape.shape.set_height(pushbox.shape.shape.get_height()+5)
			pushbox.transform.origin.z-=2.5*SCALE
		else:
			pushbox.do_push()
		anim = "push_charge"
	else: 
		pushbox.do_push()
		anim = "push_over"

func push_complete():
	pushbox.shape.shape.set_height(1)
	pushbox.transform.origin.z=-1.0*SCALE
	state = MOVE
	anim = "idle"
	push_cooldown=1
	pushbox.release()

func pull_state(delta):
	pass

func set_player_name(name):
	player_name = name
	pass

func angle_update():
	var current_angle_y = get_transform().basis.get_euler().y;
	var curang = wrapf(current_angle_y,-PI,PI)
	current_angle = Vector3(-sin(curang),0,-cos(curang))
	
	if(mouse_position != Vector3.ZERO):
		mouse_angle = get_mouse_angle(current_angle_y, mouse_position)

func get_mouse_angle(current_angle, position):
	var up_dir = Vector3.UP
	var target_angle_y = get_transform().looking_at(position, up_dir).basis.get_euler().y;
	var rotation_angle = wrapf(target_angle_y - current_angle, -PI, PI);
	return up_dir * rotation_angle;

#On timeout, update data back to server: Position, rotation, animation
func _on_SendData_timeout():
	if(network_handler.is_host()):
		last_time = current_time
	network_handler.timeout(get_transform().basis.get_euler().y, get_transform().origin, anim, linear_velocity)

sync func reset():
	last_attacker=""
	network_handler.reset()

func _on_Player_body_entered(body):
	touched = true
