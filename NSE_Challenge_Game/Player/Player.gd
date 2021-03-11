extends "res://Character.gd"

export var ACCELERATION = 100
export var SCALE = 1.0
export var MASS = 10
export var FRICTION = 10
export var MAX_SPEED = 500
export var SPEED = 2000
export var TURN_SPEED = 400
export var PUSH_POWER = 300
export var DASH_DIST = 5
export var DASH_COOLDOWN = 40.0
export var GRAB_POWER = 10
export var GRAB_DROPOFF_VAL = 1.0
export var DASHES = 3
export var RECHARGE_PER_CRYSTAL = 0.5
export var RECHARGE_ALL = 4

onready var UPDATE_INTERVAL = 1.0 / $"/root/Settings".tickrate

onready var pushbox = $PushBox
onready var pullbox = $PullBox
onready var grabbox = $GrabBox
onready var rockhitbox = $RockHitBox

onready var network_handler = $NetworkHandler
onready var animationtree = $AnimationTree
onready var animationplayer = $player_animations/AnimationPlayer
onready var animationstate = animationtree.get("parameters/playback")
onready var sounds = $Sounds
onready var grabbeam_handler = $GrabBeamHandler
onready var dashhitbox = $DashHitBox
onready var summonhitboxes = $SummonHitBoxes
onready var growhitbox = $GrowHitBox

var _delta = 0.1

sync var players = {}

func _ready():
	spawn_position = transform.origin
	set_linear_damp(10)
	set_mass(MASS)
	scale_setup()
	dash_setup(DASHES)
	animationplayer.set_speed_scale(3)
	
	current_turn_speed = TURN_SPEED
	current_position = spawn_position
	
	if network_handler.is_current_player(): 
		playerid = get_tree().get_network_unique_id()
	
	players[player_name] = [controls,r_stats]

func scale_setup():
	$player_animations.scale = Vector3(2*SCALE,2*SCALE,2*SCALE)
	$CollisionShape.scale=Vector3(SCALE*0.5,SCALE*0.5,SCALE*0.5)
	dashhitbox.scale=Vector3(SCALE*0.8,SCALE*0.8,SCALE*0.8)
	
	summonhitboxes.transform.origin.z=(-4.0*SCALE)
	summonhitboxes.setup(2.0)
	
	growhitbox.transform.origin = Vector3(0, SCALE*2, -4.0*SCALE)
	
	rockhitbox.scale=Vector3(SCALE*0.5,SCALE*0.5,SCALE*0.5)
	
	pushbox.scale=Vector3(2*SCALE,SCALE,SCALE)
	pushbox.transform.origin.z=(-2.0*SCALE)
	
	pullbox.scale=Vector3(2*SCALE,SCALE,SCALE)
	pullbox.transform.origin.z=(-2.0*SCALE)
	
	grabbox.scale=Vector3(SCALE,SCALE,SCALE)
	grabbox.transform.origin.z=(-1.8*SCALE)
	grabbox.shape.shape.set_height(0.5*SCALE)

func _physics_process(delta):
	#INTEGRATE PHYSICS STUFF
	_delta = delta
	current_position = transform.origin
	current_rotation = rotation
	current_face = get_transform().basis.get_euler().y
	
	#PACKET RECEIVING STUFF
	current_time += delta
	
	#IS THIS STILL NECESSARY? 
	if(state != FALL and state != DEATH and network_handler.remote_dead):
		state = FALL
	
	#IF WE ARE THE CURRENT PLAYER, PUT SHIT ONTO THE 'NET
	if (network_handler.is_current_player()):
		server_controls_update(player_name, get_controls(network_handler.get_cam()))
	
	#IF WE ARE THE HOST, UPDATE THE CURRENT PLAYER FOR REAL
	#IF WE ARE A CLIENT, TAKE REMOTE DATA & UPDATE
	if(network_handler.is_host()):
		update(delta)
	else:
		puppet_update(delta)
	
	#ANIMATION STUFF
	handle_animations(anim)
	
	#SOUND STUFF
	handle_sounds()

func server_controls_update(player_name, controllist):
	#reminder: [input_vector, _pushpull, _summon, _grab, _dash, mouse_position]
	if not network_handler.is_host():
		rpc_unreliable_id(1, "manage_clients", player_name, controllist)
	else:
		manage_clients(player_name, controllist)

sync func manage_clients(player_name, controls):
	players[player_name] = [controls, get_positionals()]
	rset_unreliable("players", players)

func _integrate_forces(s):
	if(network_handler.is_host()):
		rotation = current_rotation + (mouse_angle*(current_turn_speed*_delta/30))
	else:
		var target = Vector3.UP * wrapf(r_rotation-current_face, -PI, PI)
		rotation = current_rotation + (target*(current_turn_speed*_delta/30))
		
		var next
		if current_position.distance_to(puppet_next_position) > DASH_DIST-1:
			next = puppet_next_position
		else:
#			next = current_position.move_toward(puppet_next_position,_delta)
			next = puppet_next_position
#
#		if contacts_reported>0: 
#			for i in get_colliding_bodies():
#				if i.is_in_group('rock_hitbox'):
#					var size = i.get_parent().size
#					var pos = i.get_parent().location
#					if next.distance_to(pos) > size:
#						var dir = (next-pos).normalized()
#						next = pos + dir * size
		transform.origin = next

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
		if(!$Sounds/player_fall.playing):	
			$Sounds/player_fall.play()
	else:
		$Sounds/player_fall.stop()

func play_footsteps():
	if(!$Sounds/footstep.playing):
		$Sounds/footstep.play()

func get_network_handler():
	return network_handler

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
	if player_name in players.keys():
		r_stats = players[player_name][1]
	r_rotation = r_stats[0]
	r_position = r_stats[1]
	r_animation = r_stats[2]
	r_velocity = r_stats[3]
	puppet_next_position = r_position + (r_velocity * delta)
	
	if(r_animation == "movement"):
		var vel_norm = r_velocity.normalized()
		var	angle_to_movement = - abs(get_transform().basis.get_euler().y+(2*PI) - atan2(-vel_norm.z, vel_norm.x))
		var blend_to_x = cos(angle_to_movement)
		var blend_to_y = sin(angle_to_movement)
		
#		#Now interpolate the blend points so the transition is gradual
		var inter_spd = 0.1
		blend_x = lerp(blend_x, blend_to_x, inter_spd)
		blend_y = lerp(blend_y, blend_to_y, inter_spd)
		if(blend_y > 0):
			$player_animations.rotation_degrees.z = 10*blend_y
		else:
			$player_animations.rotation_degrees.z = 0
		animationtree.set("parameters/movement/Movement/blend_position", Vector2(blend_x, blend_y))
	
	anim = r_animation

func handle_animations(animation):
	if (animation!=prevanim):
		animationstate.travel(animation)
	prevanim = animationstate.get_current_node()
	
	#Blender is a bad program and I never want to use it again, anyway:
	if(animation == "idle" or
		animation == "push_charge" or
		animation == "push_hold" or animation == "summon_start"):
		$player_animations.rotation_degrees.z = 13
	else:
		$player_animations.rotation_degrees.z = 0

#Takes given control input and updates actions of the player
func update(delta):
	if touched: set_last_attacker()
	
	controls = players[player_name][0]
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
		pushbox.update(mouse_position, get_transform().looking_at(pushbox.rock_position, Vector3.UP).basis.get_euler().y)
	
	if (pullbox.rock != null):
		pullbox.update(mouse_position, get_transform().looking_at(pullbox.rock_position, Vector3.UP).basis.get_euler().y)
	
	match state:
		MOVE:
			move_state(delta, mouse_angle)
		DASH:
			dash_state(delta)
		SUMMONING:
			summon_state(delta)
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
		animationtree.set("parameters/movement/Movement/blend_position", Vector2(blend_x, blend_y))
		if(blend_y > 0.3):
			$player_animations.rotation_degrees.z = 10*blend_y
		else:
			$player_animations.rotation_degrees.z = 0
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
		if(summon and rock_summoned == false and summonhitboxes.can_summon):
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

func stop_movement():
	set_linear_velocity(Vector3.ZERO)

func dash_setup(numdashes):
	for i in range(numdashes):
		dashes.append(1.0)

func dash_state(delta):
	#come up with another way. Use fancy particles?
	anim="dash"
	visible = false
	stop_movement()
	dashhitbox.scale=Vector3(SCALE*0.6,SCALE*0.6,SCALE*0.6)
	if go != true and d < DASH_DIST*2:
		d += 1.5
		dashhitbox.global_transform.origin=global_transform.origin+(dash_angle*d)-(Vector3.UP*0.1)
		if len(dashhitbox.get_overlapping_areas()) == 0:
			go = true
		for i in dashhitbox.get_overlapping_areas():
			if i.is_in_group("rock"):
				go = true
	else:
		var dash_pos = transform.origin+(dash_angle*(d-DASH_DIST))
		transform.origin = dash_pos
		dash_finished()

func dash_finished():
	if(network_handler.is_host()):
		visible = true
		stop_movement()
		dashhitbox.scale=Vector3(SCALE*0.8,SCALE*0.8,SCALE*0.8)
		anim="idle"
		go = false
		d = 0
		dashhitbox.global_transform.origin =global_transform.origin
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
	if(network_handler.is_host()):
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

func summon_state(delta):
	#if no rock
	if not decided:
		if len(growhitbox.get_overlapping_areas()) > 0:
			growing_rock = growhitbox.get_overlapping_areas()[0]
			decided = true
			growing = true
		else:
			growing = false
			decided = true
	
	if not growing:
		summoning_state(delta)
	if growing:
		growing_state(delta)

func summoning_state(delta):
	move_velocity = move_velocity.move_toward(Vector3.ZERO, FRICTION*delta)
	current_turn_speed = 0
	
	summon_length -= 1
	anim = "summon_start"
	
	if(summon_length <= 0):
		if not has_summoned:
			summon_rock(delta)
			has_summoned = true
		post_summon_length -= 1
		if(post_summon_length <= 0):
			summon_length = 15
			post_summon_length = 25
			decided = false
			growing = false
			has_summoned = false
			state = MOVE

func summon_rock(delta):
	rock_summoned = true
	var offset = 1.5
	var y_rot = -get_transform().basis.get_euler().y
	var rock_pos = Vector3(translation.x + offset*sin(y_rot), -1, translation.z - offset*cos(y_rot))
	network_handler.all_summon_rock(get_name(), rock_pos, get_transform().basis.get_euler().y)

func growing_state(delta):
	move_velocity = move_velocity.move_toward(Vector3.ZERO, FRICTION*delta)
	current_turn_speed = 0
	if (not summon) or (growing_rock == null):
		stop_growing()
		return
	if not length_det:
		grow_length = 8 * growing_rock.size * growing_rock.size
		length_det = true
	anim = "summon_start"
	grow_length -= 1
	if grow_length <= 0:
		if not has_growed:
			growing_rock.grow(0.01)
			var new_size = growing_rock.size + 0.5
			var rockpos = growing_rock.global_transform.origin
			var dist = new_size/2 - rockpos.distance_to(global_transform.origin)
			if dist < 0: dist = 0
			var new_position= rockpos + Vector3(dist*sin(-get_transform().basis.get_euler().y), 0, dist*-cos(-get_transform().basis.get_euler().y))
			network_handler.all_summon_rock(growing_rock.name, new_position, new_size,growing_rock.face)
			has_growed = true
		post_grow_length -= 1
		if post_grow_length <= 0:
			if summon:
				growing_rock = growhitbox.get_overlapping_areas()[0]
				has_growed = false
				length_det = false
				post_grow_length = 15
			else:
				stop_growing()
				return

func stop_growing():
	decided = false
	growing = false
	has_growed = false
	length_det = false
	post_grow_length = 15
	state = MOVE

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
	if(network_handler.is_host()):
		pushbox.shape.shape.set_height(1)
		pushbox.transform.origin.z=-2.0*SCALE
		pushbox.shape.disabled = true
		state = MOVE
		anim = "idle"
		push_cooldown=1
		pushbox.release()

func pull_state(delta):
#	mouse_angle = get_mouse_angle(get_transform().basis.get_euler().y, pull_mouse_position)
	current_turn_speed = TURN_SPEED/2
	move_velocity = move_velocity.move_toward(Vector3.ZERO, FRICTION*delta)
	if pushpull == -1:
		pullbox.shape.disabled = false
		if(pullbox.shape.shape.get_height()<80*SCALE):
			pullbox.shape.shape.set_height(pullbox.shape.shape.get_height()+5)
			pullbox.transform.origin.z-=2.5*SCALE
		else:
			pullbox.do_pull()
		if(!started_pulling):
			anim = "pull_charge"
			started_pulling = true
		else:
			anim = "push_hold"
	else: 
		started_pulling = false
		pull_complete()

func pull_complete():
	if(network_handler.is_host()):
		pullbox.shape.shape.set_height(1)
		pullbox.transform.origin.z=-2.0*SCALE
		pullbox.shape.disabled = true
		state = MOVE
		anim = "idle"
		pull_cooldown=1
		pullbox.release()

func check_shove(rock):
	if rock == null or not rock.still:
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
	anim = "rock_push"
	
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

func set_player_name(name):
	player_name = name

func set_player_colour(col):
	player_col = col
	$player_animations/metarig003/Skeleton/ObjObject.get_surface_material(0).albedo_color = col

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

func get_positionals():
	return [get_transform().basis.get_euler().y, get_transform().origin, anim, linear_velocity]

#On timeout, update data back to server: Position, rotation, animation
func _on_SendData_timeout():
	network_handler.timeout(get_positionals())

sync func reset():
	last_attacker = ""
	state = MOVE
	set_linear_velocity(Vector3.ZERO)
	set_angular_velocity(Vector3.ZERO)
	set_linear_damp(10)
	set_gravity_scale(1)
	transform.origin = spawn_position
	anim = "idle"
	animationstate.travel(anim)
	if network_handler.is_host():
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
	if(network_handler.is_host()):
		s_rock = $RockHitBox.rock
		shovable = check_shove(s_rock)
		contact = true
		grabbeam_handler.start_beam(rockhitbox.rock)

func _on_RockHitBox_stop_pushing():
	contact = false
	grabbeam_handler.stop_beam()
