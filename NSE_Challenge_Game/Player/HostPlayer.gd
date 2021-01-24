extends RigidBody2D


#Input
puppet var puppet_control_movement = Vector2.ZERO
puppet var puppet_control_pushpull = 0.0
puppet var puppet_control_summon = 0.0
puppet var puppet_mouse_angle = 0.0

#Positional data
remote var remote_position = Vector2.ZERO
remote var remote_rotation = 0.0

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
var velocity = Vector2.ZERO
var rock_summoned = false
var dead = false

var old_position = Vector2.ZERO

export var MASS = 200
export var FRICTION = 100
export var MAX_SPEED = 100
export var SPEED = 100
export var TURN_SPEED = 400

func _ready():
	set_linear_damp(FRICTION/5)
	
	#Load animations
	$StackedSprite.load_animation("still","res://Assets/Player/stationary.png",2,40)
	$StackedSprite.load_animation("up","res://Assets/Player/walk_up.png",6,40)
	$StackedSprite.load_animation("down","res://Assets/Player/walk_down.png",6,40)
	$StackedSprite.load_animation("left","res://Assets/Player/walk_left.png",6,40)
	$StackedSprite.load_animation("right","res://Assets/Player/walk_right.png",6,40)
	

func _physics_process(delta):
	if(is_network_master()):
		#Let host input their controls
		var input_vector = Vector2.ZERO
		input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
		input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
		input_vector = input_vector.normalized()

		#push/pull is either 1 or -1 respectively, or 0
		puppet_control_pushpull = Input.get_action_strength("push")-Input.get_action_strength("pull")
		puppet_control_movement = input_vector
		puppet_control_summon = Input.get_action_strength("summon_rock")
		
		
		var offset = deg2rad(90)
		puppet_mouse_angle = get_local_mouse_position().angle() + offset	
		
	#Take control input and run player code
	#send off positional values
	
	#If it is the host then do physics calculations
	if(get_tree().is_network_server()):
		set_mode(RigidBody2D.MODE_RIGID)
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
		#set_applied_torque(mouse_angle*TURN_SPEED)
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
		set_mode(RigidBody2D.MODE_KINEMATIC)
		
		old_position = position
		#Disable the collision box
		#$collider.disabled = true
		#set the mode to kinematic, remove collisions and
		#update recieved position
		position = lerp(remote_position, old_position, 0.01)
		rotation = remote_rotation
		
	update_animations()


func update_animations():
	if velocity.y < 0:
		if($StackedSprite.playing_animation == ""):
			$StackedSprite.play_animation("up",30)
	elif velocity.y > 0:
		if($StackedSprite.playing_animation == ""):
			$StackedSprite.play_animation("down",30)
	elif velocity.x < 0:
		if($StackedSprite.playing_animation == ""):
			$StackedSprite.play_animation("left",30)
	elif velocity.x > 0:
		if($StackedSprite.playing_animation == ""):
			$StackedSprite.play_animation("right",30)
	else:
		$StackedSprite.play_animation("still",30)

func move_state(delta):
	var input_vector = puppet_control_movement
	
	if(input_vector != Vector2.ZERO):
		velocity += input_vector*SPEED*delta
		velocity = velocity.clamped(MAX_SPEED)
	else:
		#Apply friction
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	
	move()

func move():
	apply_central_impulse(velocity)

func dash_state(delta):
	pass
	
func summon_state(delta):
	#Apply friction
	velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	
	var rock_name = get_name()
	var offset = 40
	var rock_pos = Vector2(position.x + offset*sin(rotation), position.y - offset*cos(rotation))
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
		rset_unreliable("remote_rotation", rotation)
		rset_unreliable("remote_position", position)
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
	set_mode(RigidBody2D.MODE_KINEMATIC)
	rock.position = pos
	set_mode(RigidBody2D.MODE_RIGID)
	#rock.from_who #we can set this when we need to know who killed who for stats
	
	# No need to set network master to bomb, will be owned by server by default
	get_node("../..").add_child(rock)
	
