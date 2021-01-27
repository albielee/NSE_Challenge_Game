extends RigidBody

#Input
puppet var puppet_control_movement = Vector2.ZERO
puppet var puppet_control_pushpull = 0.0
puppet var puppet_control_summon = 0.0
puppet var puppet_mouse_angle = 0.0

#Positional data
remote var remote_position = Vector3.ZERO
remote var remote_rotation = 0.0
#dead data
remote var remote_dead = false

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
var velocity = Vector3.ZERO
var rock_summoned = false
var dead = false

var spawn_position = Vector3.ZERO
var old_position = Vector3.ZERO

export var MASS = 10
export var FRICTION = 10
export var MAX_SPEED = 500
export var SPEED = 2000
export var TURN_SPEED = 400

func _ready():
	set_linear_damp(FRICTION)
	set_mass(MASS)
	spawn_position = get_transform().origin
	

func _physics_process(delta):
	if(state != FALL and state != DEATH and remote_dead):
		state = FALL
	
	if(is_network_master() and !remote_dead):
		#Let host input their controls
		var input_vector = Vector2.ZERO
		input_vector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
		input_vector.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
		input_vector = input_vector.normalized()

		#push/pull is either 1 or -1 respectively, or 0
		puppet_control_pushpull = Input.get_action_strength("push")-Input.get_action_strength("pull")
		puppet_control_movement = input_vector
		puppet_control_summon = Input.get_action_strength("summon_rock")
		
		
		var offset = deg2rad(90)
		var cam = get_tree().get_nodes_in_group("Camera")[0]
		if(cam != null):
			var up_dir = Vector3.UP;
			var target_position = cam.raycast_position
			var current_angle_y = get_transform().basis.get_euler().y;
			var target_angle_y = get_transform().looking_at(target_position, up_dir).basis.get_euler().y;
			var rotation_angle = wrapf(target_angle_y - current_angle_y, -PI, PI);
			
			puppet_mouse_angle = up_dir * (rotation_angle);
	
		
	#Take control input and run player code
	#send off positional values
	
	#If it is the host then do physics calculations
	if(get_tree().is_network_server()):
		if(mode != MODE_RIGID):
			set_mode(RigidBody.MODE_RIGID)
		#I want to handle the players movement here
		#I want to send the positional data from here
		var push_pull = puppet_control_pushpull
		var summon = puppet_control_summon
		var mouse_angle = puppet_mouse_angle

		match state:
			MOVE:
				move_state(delta)
			DASH:
				dash_state(delta)
			SUMMON:
				summon_state(delta)
			PUSH:
				push_state(delta)
			PULL:
				pull_state(delta)

		#Rotate the player to face the mouse

		#add_torque(mouse_angle*TURN_SPEED*delta)
		#print(Vector3(0,mouse_angle*TURN_SPEED,0))
		set_angular_velocity(mouse_angle*TURN_SPEED*delta)
		#rotation += mouse_angle	# multiply by value if we want slow rot (e.g. 0.1)	
		
		#Summoning a rock
		if(summon and rock_summoned == false):
			state = SUMMON;
			rock_summoned = true
		if(!summon):
			rock_summoned = false
		
	else:
		#This will allow the setting of positional arguments
		if(mode != MODE_KINEMATIC):
			set_mode(RigidBody.MODE_KINEMATIC)

		var p = get_transform().origin
		#Disable the collision box
		#$collider.disabled = true
		#set the mode to kinematic, remove collisions and
		#update recieved position
		var interpolate_speed = 0.1
		var x = move_toward(p.x, remote_position.x, interpolate_speed)
		var y = move_toward(p.y, remote_position.y, interpolate_speed)
		var z = move_toward(p.z, remote_position.z, interpolate_speed)
		transform.origin = Vector3(x,y,z)
		rotation = remote_rotation
		
	update_animations()


func update_animations():
	pass

func move_state(delta):
	var input_vector = puppet_control_movement

	if(input_vector != Vector2.ZERO):
		velocity = velocity.move_toward(Vector3(input_vector.x*MAX_SPEED,0,input_vector.y*MAX_SPEED), SPEED*delta)
	else:
		#No need to apply friction here because it is set through linear dampening
		velocity = Vector3.ZERO
	
	move()

func move():
	add_force(velocity, Vector3.ZERO)
	#apply_central_impulse(velocity)

func dash_state(delta):
	pass
	
func summon_state(delta):
	#Apply friction
	velocity = velocity.move_toward(Vector3.ZERO, FRICTION * delta)
	
	var rock_name = get_name()
	var offset = 1
	var y_rot = -get_transform().basis.get_euler().y
	var rock_pos = Vector3(translation.x + offset*sin(y_rot), 0, translation.z - offset*cos(y_rot))
	rpc("summon_rock", rock_name, rock_pos , get_tree().get_network_unique_id())
	state = MOVE
	
func push_state(delta):
	pass
	
func pull_state(delta):
	pass
	
func set_player_name(new_name):
	pass


func _on_SendData_timeout():
	if(get_tree().is_network_server()):
		#Send rotational and positional data
		rset_unreliable("remote_rotation", get_rotation())
		rset_unreliable("remote_position", get_transform().origin)
		rset("remote_dead", remote_dead)
	else:
		if(is_network_master()):
			#Send off players movement
			rset("puppet_control_movement", puppet_control_movement)
			#send pushpull
			rset("puppet_control_pushpull", puppet_control_pushpull)
			rset("puppet_control_summon", puppet_control_summon)
			rset("puppet_mouse_angle", puppet_mouse_angle)
	$SendData.start(1.0/Settings.tickrate)
	
#sync functions
#Summoning a rock and syncing it to players in server
# Use sync because it will be called everywhere
sync func summon_rock(rock_name, pos, by_who):
	var rock = preload("res://Objects/Rock/Rock.tscn").instance()
	rock.set_name(rock_name) # Ensure unique name for the bomb
	set_mode(RigidBody.MODE_KINEMATIC)
	rock.translation = pos
	set_mode(RigidBody.MODE_RIGID)
	#rock.from_who #we can set this when we need to know who killed who for stats
	
	# No need to set network master, will be owned by server by default
	get_node("../..").add_child(rock)
	

#Called when the player enters the void area
func fall_state():
	state = FALL;
	#anim, falling motion, destroy player
	
	#on animation finished, destroy player
	state = DEATH;
	death_state()
	

func death_state():
	#move the players away - this is easier than destroying the client and respawning them
	#if we do multiple rounds
	set_mode(RigidBody.MODE_KINEMATIC)
	translation = Vector3.ZERO

master func reset():
	set_mode(RigidBody.MODE_KINEMATIC)
	
	#bring player back to life
	remote_dead = false
	print("RESET")
	#bring player back to spawn position
	translation = spawn_position
	state = MOVE
	
	set_mode(RigidBody.MODE_RIGID)
