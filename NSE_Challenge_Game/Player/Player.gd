extends RigidBody

#this is set to the tree's unique ID
var playerid = 0

var movement = Vector2.ZERO
var pushpull = 0.0
var summon = 0.0
var grab = 0.0
var dash = 0.0
var mouse_position = Vector3.ZERO

var controls = [movement, pushpull, summon, grab, dash, mouse_position]

var player_name = ""
var player_col = Color("")

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

var colours = [Color("0099db"),Color("68386c"),Color("feae34"),Color("3e8948")]

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
	DEATH,
	PAUSE,
	SHOVE
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
#movement animation blend space
var blend_x = 0
var blend_y = 0

var push_cooldown = 0
var push_mouse_position = mouse_position
var started_pushing = false

var pull_cooldown = 0
var pull_mouse_position = mouse_position
var started_pulling = false

var summon_size = 0.5
var rock_summoned = false
var growing_rock = null

var dash_angle = current_angle
var can_dash = 0.0

var last_attacker=""

var shovable = false
var s_rock = null
var contact = false

export var ACCELERATION = 100
export var SCALE = 1.0
export var MASS = 10
export var FRICTION = 10
export var MAX_SPEED = 500
export var SPEED = 2000
export var TURN_SPEED = 400
export var PUSH_POWER = 300
export var DASH_INC = 2.0
export var DASH_COOLDOWN = 40.0
export var GRAB_POWER = 10
export var GRAB_DROPOFF_VAL = 1.0
var last_time = 0
var current_turn_speed = TURN_SPEED
var current_rotation = 0

onready var UPDATE_INTERVAL = 1.0 / $"/root/Settings".tickrate

onready var pushbox = $PushBox
onready var pullbox = $PullBox
onready var grabbox = $GrabBox
onready var rockhitbox = $RockHitBox

onready var network_handler = $NetworkHandler
onready var animationtree = $AnimationTree
onready var animationplayer = $player_animations/AnimationPlayer
onready var animationstate = animationtree.get("parameters/playback")
onready var spawn_position = Vector3.ZERO
onready var sounds = $Sounds
onready var grabbeam_handler = $GrabBeamHandler

var _updates = 0.0
var _packets = 0.0
var avg = 1.0
var time = 0.0
var packets = []
var buffer = []
var prev_speed = 0.0
var next_speed = 0.0
var puppet_current_face = 0.0

var _delta = 0.1

func _ready():
	set_linear_damp(10)
	set_mass(MASS)
	$CollisionShape.scale=Vector3(SCALE*0.5,SCALE*0.5,SCALE*0.5)
	
	rockhitbox.scale=Vector3(SCALE*0.5,SCALE*0.5,SCALE*0.5)
	
	pushbox.scale=Vector3(2*SCALE,SCALE,SCALE)
	pushbox.transform.origin.z=(-1.0*SCALE)
	
	pullbox.scale=Vector3(2*SCALE,SCALE,SCALE)
	pullbox.transform.origin.z=(-1.0*SCALE)
	
	grabbox.scale=Vector3(SCALE,SCALE,SCALE)
	grabbox.transform.origin.z=(-1.8*SCALE)
	grabbox.shape.shape.set_height(0.5*SCALE)
	
	animationplayer.set_speed_scale(3)
	proj_packet_time = UPDATE_INTERVAL
	
	if network_handler.is_current_player(): playerid = get_tree().get_network_unique_id()

func _physics_process(delta):
	$player_animations/metarig003/Skeleton/ObjObject.get_surface_material(0).albedo_color = player_col
	current_time += delta
	current_rotation = rotation
	_delta = delta
	puppet_current_face = get_transform().basis.get_euler().y
	
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
	handle_sounds()

func _integrate_forces(s):
	if(network_handler.is_current_player()):
		rotation = current_rotation + (mouse_angle*(current_turn_speed*_delta/30))
	else:
		var target = Vector3.UP * wrapf(r_rotation-puppet_current_face, -PI, PI)
		rotation = current_rotation + (target*(current_turn_speed*_delta/30))

func handle_sounds():
	if(anim == "movement"):
		play_footsteps()
	if(anim == "summon_start"):
		$Sounds/player_summon.play()
	if(anim == "push_hold"):
		if(!$Sounds/beam_push.playing):
			$Sounds/beam_push.play()
	else:
		$Sounds/beam_push.stop()
	
	if(anim == "fall"):
		#if(!$Sounds/player_fall.playing):
			#$Sounds/player_fall.play()
		if(!$Sounds/player_fall.playing):	
			$Sounds/player_fall.play()
	else:
		$Sounds/player_fall.stop()

func play_footsteps():
	if(!$Sounds/footstep.playing):
		$Sounds/footstep.play()

func get_network_handler():
	return network_handler

#Required inputs: Camera location and current body location
func get_controls(cam):
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_vector.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	input_vector = input_vector.normalized()
	
	var _pushpull = Input.get_action_strength("push") - Input.get_action_strength("pull")
	
	var _summon = Input.get_action_strength("summon_rock")
	
	var _grab = Input.get_action_strength("temp_float")
	
	var _dash = Input.get_action_strength("move_dash")
	
	if(cam != null):
		mouse_position = cam.raycast_position
	
	return [input_vector, _pushpull, _summon, _grab, _dash, mouse_position]

func puppet_update(delta):
#	time = 0
	var p = get_transform().origin
	var dir = (puppet_next_position-p).normalized()
	var dist = p.distance_to(puppet_next_position)
	
	if len(buffer) > 0 and time <= 0:
		prev_speed = r_velocity.length()
		var statstime = buffer.pop_front()
		time += statstime[1]
		
		r_stats = statstime[0]
		r_rotation = r_stats[0]
		r_position = r_stats[1]
		r_animation = r_stats[2]
		r_velocity = r_stats[3]
		
		puppet_next_position = r_position + (r_velocity * time)
		
		var interp = 1/1.5
		var speed = r_velocity.length()
		if speed == 10:
			next_speed = 10
		if speed < prev_speed:
			if dist > 0.05:
				next_speed = dist + next_speed + (((prev_speed - speed)-next_speed) * interp)
			else: next_speed += ((prev_speed - speed)-next_speed) * interp
		if speed > prev_speed:
			if speed+prev_speed<10:
				next_speed = prev_speed + speed
			else:
				next_speed = 10
	
	#If other player is running about, do same blend point code as player athough with velocity not movement now
	if(r_animation == "movement"):
		var vel_norm = r_velocity.normalized()
		var	angle_to_movement = - abs(get_transform().basis.get_euler().y+(2*PI) - atan2(-vel_norm.z, vel_norm.x))
		var blend_to_x = cos(angle_to_movement)
		var blend_to_y = sin(angle_to_movement)
		#Now interpolate the blend points so the transition is gradual
		var inter_spd = 0.1
		blend_x = lerp(blend_x, blend_to_x, inter_spd)
		blend_y = lerp(blend_y, blend_to_y, inter_spd)
		animationtree.set("parameters/movement/blend_position", Vector2(blend_x, blend_y))
	
#	transform.origin = puppet_next_position
#	print(dist)
	
	if dist >= 1:
		set_linear_velocity(next_speed*dir*dist)
	else: set_linear_velocity(next_speed*dir)
	
	anim = r_animation
	if time > 0:
		time -= delta

func _on_NetworkHandler_packet_received():
#	print(len(buffer))
	#how long since the last packet?
	elapsed_time = current_time - last_packet_time
	
	avg = average_packet_time(elapsed_time)
	
	#set this time to be the time the last packet arrived
	last_packet_time = current_time
	
	build_buffer(network_handler.update_stats(), avg)

func build_buffer(newstats, average):
	buffer.push_back([newstats,average])

func average_packet_time(newpacket_elapsed):
	packets.push_back(newpacket_elapsed)
	if len(packets) > 50:
		packets.pop_front()
	var total = 0.0
	for time in packets:
		total += time
	return total/(len(packets)+len(buffer))

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
	pullbox.knockback_vector=current_angle
	pullbox.update_angle(get_transform().basis.get_euler().y, mouse_angle,  global_transform.origin)
	
	if (pushbox.rock != null): 
#		pushbox.update_angle(get_transform().looking_at(mouse_position, Vector3.UP).basis.get_euler().y, mouse_angle)
		pushbox.update(mouse_position, get_transform().looking_at(pushbox.rock_position, Vector3.UP).basis.get_euler().y)
	
	if (pullbox.rock != null):
		pullbox.update(mouse_position, get_transform().looking_at(pullbox.rock_position, Vector3.UP).basis.get_euler().y)
	
	match state:
		MOVE:
			move_state(delta, mouse_angle)
		DASH:
			dash_state(delta)
		SUMMONING:
			summoning_state(delta)
		PUSH:
			push_state(delta)
		PULL:
			pull_state(delta)
		GRAB:
			grab_state(delta)
		GRABBED:
			grabbed_state(delta)
		FALL:
			fall_state(delta)
		PAUSE:
			pause_state(delta)
		SHOVE:
			shove_state(delta)
	if state != FALL and state != PAUSE: move()

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
		
		anim = "movement"
		
		var	angle_to_movement = - abs(get_transform().basis.get_euler().y+(2*PI) - atan2(-movement.y, movement.x))
		var blend_to_x = cos(angle_to_movement)
		var blend_to_y = sin(angle_to_movement)
		#Now interpolate the blend points so the transition is gradual
		var inter_spd = 0.1
		blend_x = lerp(blend_x, blend_to_x, inter_spd)
		blend_y = lerp(blend_y, blend_to_y, inter_spd)
		animationtree.set("parameters/movement/blend_position", Vector2(blend_x, blend_y))
		
		$animationblend.point_pos = Vector2(blend_x, blend_y)
	else:
		anim = "idle"
		move_velocity = move_velocity.move_toward(Vector3.ZERO, FRICTION*delta)
	
#	set_angular_velocity(mouse_angle*TURN_SPEED*delta)
	current_turn_speed = TURN_SPEED
	
	#Handle summoning rocks, for which a player cannot have been doing other shit
	# Priority order: dash,summon, Grab, Push/pull
	if(dash and can_dash <= 0.0):
		set_angular_velocity(Vector3.ZERO)
		state = DASH
		rock_summoned = false
	else:
		can_dash -= 1.0
		if(summon and rock_summoned == false):
			#set_angular_velocity(Vector3.ZERO)
			state = SUMMONING;
		elif(state != SUMMONING and !summon):
			rock_summoned = false
			if(grab==1):
				state = GRAB
			else:
				if(pushpull==1 and push_cooldown==0):
					push_mouse_position=mouse_position
					state = PUSH
				if(pushpull==-1 and push_cooldown==0):
					pull_mouse_position=mouse_position
					state = PULL
				elif(pushpull==0):
					push_cooldown=0
					if(contact == true):
						if check_shove(s_rock):
							state = SHOVE

func pause_state(delta):
	current_turn_speed = TURN_SPEED

func move():
	if (move_velocity!=Vector3.ZERO):
		set_linear_velocity(move_velocity)

func dash_state(delta):
	if(anim != "dash"):
		var dash_time = 0.1
		$ActionTimer.start(dash_time)
	anim="dash"
	current_turn_speed = TURN_SPEED
	move_velocity = move_velocity.move_toward(dash_angle*MAX_SPEED*DASH_INC,ACCELERATION*DASH_INC*delta)
	if($ActionTimer.time_left < 0.02):
		dash_finished()

func dash_finished():
	if(network_handler.is_current_player()):
		anim="idle"
		state=MOVE
		can_dash=DASH_COOLDOWN

func set_fall_state():
	move_velocity = Vector3.ZERO
	state = FALL

func fall_state(delta):
	anim = "fall"

func grab_state(delta):
	current_turn_speed = TURN_SPEED
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
		move_velocity = move_velocity.move_toward(Vector3.ZERO, FRICTION*delta)
	
	set_angular_velocity(mouse_angle*TURN_SPEED/5*delta)

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
	
	current_turn_speed = TURN_SPEED/4

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
	if(network_handler.is_current_player()):
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

func summoning_state(delta):
	move_velocity = move_velocity.move_toward(Vector3.ZERO, FRICTION*delta)
	
	var rock_name = get_name()
#	growing_rock = get_node("/root/World/RockNetworkHandler/"+String(rock_name))

	if(!rock_summoned):
		anim = "summon_start"
		rock_summoned = true
		var offset = 2.0
		var y_rot = -get_transform().basis.get_euler().y
		var rock_pos = Vector3(translation.x + offset*sin(y_rot), 0, translation.z - offset*cos(y_rot))
		var start_size = 2.0
		network_handler.all_summon_rock(rock_name, rock_pos, start_size)
		state = MOVE
	elif(growing_rock != null):
		#anim = "summon_hold"
		var summon_speed = 1
		summon_size+=summon_speed*delta
		#network_handler.all_grow_rock(growing_rock, summon_size)
		if (summon == 0.0) or (summon_size > 3.0):
			summon_size=0.5
			state = MOVE
#		print(summon)

func summon_power_up():
	if(network_handler.is_current_player()):
		summon_size+=0.5
		if (summon == 0.0) or (summon_size == 3.0):
			state=SUMMONING

func push_state(delta):
	current_turn_speed = TURN_SPEED/40
	move_velocity = move_velocity.move_toward(Vector3.ZERO, FRICTION*delta)
	if pushpull == 1:
		#update pushbox shape
		pushbox.shape.disabled = false
		if(pushbox.shape.shape.get_height()<80*SCALE):
			pushbox.shape.shape.set_height(pushbox.shape.shape.get_height()+5)
			pushbox.transform.origin.z-=2.5*SCALE
		else:
			pushbox.do_push()
		if(!started_pushing):
			anim = "push_charge"
			started_pushing = true
		else:
			anim = "push_hold"
	else: 
		started_pushing = false
		push_complete()

func push_complete():
	if(network_handler.is_current_player()):
		pushbox.shape.shape.set_height(1)
		pushbox.transform.origin.z=-1.0*SCALE
		pushbox.shape.disabled = true
		state = MOVE
		anim = "idle"
		push_cooldown=1
		pushbox.release()

func pull_state(delta):
#	mouse_angle = get_mouse_angle(get_transform().basis.get_euler().y, pull_mouse_position)
	current_turn_speed = TURN_SPEED/30
	move_velocity = move_velocity.move_toward(Vector3.ZERO, FRICTION*delta)
	if pushpull == -1:
		pullbox.shape.disabled = false
		if(pullbox.shape.shape.get_height()<80*SCALE):
			pullbox.shape.shape.set_height(pullbox.shape.shape.get_height()+5)
			pullbox.transform.origin.z-=2.5*SCALE
		else:
			pullbox.do_pull()
		if(!started_pulling):
			anim = "push_charge"
			started_pulling = true
		else:
			anim = "push_hold"
	else: 
		started_pulling = false
		pull_complete()

func pull_complete():
	if(network_handler.is_current_player()):
		pullbox.shape.shape.set_height(1)
		pullbox.transform.origin.z=-1.0*SCALE
		pullbox.shape.disabled = true
		state = MOVE
		anim = "idle"
		pull_cooldown=1
		pullbox.release()

func check_shove(rock):
	if rock == null:
		return false
	
	var up_dir = Vector3.UP
	var angle_to_rock = get_transform().looking_at(rock.transform.origin, up_dir).basis.get_euler().y
	
	var dics = {}
	var diffs = []
	var current_angle_y = get_transform().basis.get_euler().y
	
	for i in [-1,0,1,2]:
		var f = rock.face + (i * (PI/2))
		
		var line = (rock.transform.origin - transform.origin).normalized()
		var line2ang = wrapf(atan2(line.x,line.z)-PI, -PI, PI)
		
		var diff = wrapf(line2ang - f - 3*PI/4, -PI, PI);
		dics[diff] = f
		diffs.append(diff)
	
	var rot = wrapf(dics[diffs.min()] - current_angle_y, -PI, PI)
	
	if (rot < PI/8) and (rot > -PI/8):
		var rotation_angle = wrapf(dics[diffs.min()] - current_angle_y, -PI, PI);
		rock_face_angle = up_dir * rotation_angle
		return true
	return false

var rock_face_angle = Vector3.ZERO

func shove_state(delta):
	#here should be the code for the new animation.
	#how does that work? I'm gonna set up the controls without any animations
	anim = "idle"
	
	if not contact and not s_rock.p_hitbox in get_colliding_bodies():
		stop_shove()
		return
	elif not check_shove(s_rock):
		stop_shove()
		return
	
	if (movement != Vector2.ZERO):
		move_velocity = move_velocity.move_toward(Vector3(movement.x*MAX_SPEED,0,movement.y*MAX_SPEED), ACCELERATION*delta)
		dash_angle = Vector3(movement.x,0,movement.y)
	else:
		move_velocity = move_velocity.move_toward(Vector3.ZERO, FRICTION*delta)
	
	mouse_angle = rock_face_angle
	
	s_rock.add_force(40*current_angle, Vector3.ZERO)
	
	if(pushpull==1):
		push_mouse_position=mouse_position
		state = PUSH
	if(pushpull==-1):
		pass

func stop_shove():
	state = MOVE
	s_rock = null
#	set_axis_lock(PhysicsServer.BODY_AXIS_ANGULAR_Y,false)

func set_player_name(name):
	player_name = name

func set_player_colour(col):
	player_col = col
	#$player_animations/metarig003/Skeleton/ObjObject.get_surface_material(0).albedo_color = col

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
	network_handler.timeout(get_transform().basis.get_euler().y, get_transform().origin, anim, linear_velocity)

sync func reset():
	last_attacker = ""
	state = MOVE
	set_linear_velocity(Vector3.ZERO)
	set_angular_velocity(Vector3.ZERO)
	transform.origin = spawn_position
	anim = "idle"
	animationstate.travel(anim)
	if(not network_handler.is_current_player()):
		puppet_last_position = transform.origin
		puppet_next_position = transform.origin
		puppet_speed = 0.0
		r_rotation = 0.0
		r_position = transform.origin
		r_animation = "idle"
		r_velocity = Vector3.ZERO
		r_stats = [r_rotation,r_position,r_animation,r_velocity]
	network_handler.reset()

func set_paused(yes):
	if yes:
		state = PAUSE
	else:
		state = MOVE

func _on_Player_body_entered(body):
	touched = true

func _on_RockHitBox_start_pushing():
	s_rock = $RockHitBox.rock
	shovable = check_shove(s_rock)
	contact = true
	grabbeam_handler.start_beam(rockhitbox.rock)

func _on_RockHitBox_stop_pushing():
	contact = false
	grabbeam_handler.stop_beam()
