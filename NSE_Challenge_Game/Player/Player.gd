extends KinematicBody2D


puppet var puppet_pos = Vector2()
puppet var puppet_velocity = Vector2()
puppet var puppet_rotation = rotation

export var ACCELERATION = 400
export var MAX_SPEED = 70
export var ROLL_SPEED = 125
export var FRICTION = 400

enum {
	MOVE,
	DASH,
	SUMMON,
	PUSH,
	PULL,
	FALL,
	DEATH
}

#Variables
var state = MOVE
var dead = false

var velocity = Vector2.ZERO
var roll_vector = Vector2.DOWN

var mouse_position
var spawn_position
var current_anim = ""

func _ready():
	$StackedSprite.load_animation("still","res://Assets/Player/stationary.png",2,40)
	$StackedSprite.load_animation("up","res://Assets/Player/walk_up.png",6,40)
	$StackedSprite.load_animation("down","res://Assets/Player/walk_down.png",6,40)
	$StackedSprite.load_animation("left","res://Assets/Player/walk_left.png",6,40)
	$StackedSprite.load_animation("right","res://Assets/Player/walk_right.png",6,40)
	
	
	spawn_position = position
	#Add player collisions if server host as they will be handling all physics calc
	if(get_tree().is_network_server()):
		set_collision_layer_bit(1, true);
		set_collision_mask_bit(1, true);
		set_collision_mask_bit(2, true);
		set_collision_mask_bit(3, true);



func _physics_process(delta):

	if(is_network_master() and !dead):
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
		
		#get mouse position
		mouse_position = get_local_mouse_position()
		#Rotate the player to face the mouse
		rotation += mouse_position.angle()+deg2rad(90)	# multiply by value if we want slow rot (e.g. 0.1)	
		
		#send off your position to other peeps
		send_status()
	else:
		rotation = puppet_rotation;
		position = puppet_pos;
		velocity = puppet_velocity;

	update_animations()


	#syncing position for other clients but not self
	if not is_network_master():
		puppet_pos = position # To avoid jitter
		puppet_velocity = velocity
		puppet_rotation = rotation

func update_animations():
	var new_anim = "standing"
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

	if new_anim != current_anim:
		current_anim = new_anim
	
func send_status():
	#send off your position to other peeps
	rset("puppet_rotation", rotation)
	rset("puppet_pos", position)
	rset("puppet_velocity", velocity)

func move_state(delta):
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	input_vector = input_vector.normalized()
	
	if(input_vector != Vector2.ZERO):
		roll_vector = input_vector;

		velocity += input_vector * ACCELERATION * delta
		velocity = velocity.clamped(MAX_SPEED)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	
	move();
	
	#if actions causing other states:
	if(Input.is_action_just_pressed("dash")):
		state = DASH;
	
	#Summoning a rock
	if(Input.is_action_just_pressed("summon_rock")):
		state = SUMMON;

func dash_state(delta):
	velocity = roll_vector * ROLL_SPEED;
	move();

func summon_state(delta):
	
	velocity = Vector2.ZERO
	var rock_name = get_name()
	var offset = 40
	var rock_pos = Vector2(position.x + offset*sin(rotation), position.y - offset*cos(rotation))
	rpc("summon_rock", rock_name, rock_pos , get_tree().get_network_unique_id())
	state = MOVE
	
func push_state(delta):
	pass

func pull_state(delta):
	pass

#Called when the player enters the void area
master func fall_state():
	state = FALL;
	#anim, falling motion, destroy player
	
	#on animation finished, destroy player
	state = DEATH;
	death_state()
	

func death_state():
	#move the players away - this is easier than destroying the client and respawning them
	#if we do multiple rounds
	position = Vector2.ZERO
	
	#keep everyone updated on your predicament
	send_status()
	rpc("dead")
	dead()

puppet func dead():
	dead = true

puppet func alive():
	dead = false

func move():
	velocity = move_and_slide(velocity)

func set_player_name(new_name):
	pass
	#get_node("label").set_text(new_name)

master func reset():
	#bring player back to life
	rpc("alive")
	alive()
	send_status()
	print("RESET")
	#bring player back to spawn position
	position = spawn_position
	state = MOVE

#sync functions
#Summoning a rock and syncing it to players in server
# Use sync because it will be called everywhere
sync func summon_rock(rock_name, pos, by_who):
	var rock = preload("res://Objects/Rock/Rock.tscn").instance()
	rock.set_name(rock_name) # Ensure unique name for the bomb
	rock.position = pos
	#rock.from_who #we can set this when we need to know who killed who for stats
	
	# No need to set network master to bomb, will be owned by server by default
	get_node("../..").add_child(rock)
