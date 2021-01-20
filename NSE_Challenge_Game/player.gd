extends KinematicBody2D

##
const velocity_SPEED = 90.0

puppet var puppet_pos = Vector2()
puppet var puppet_velocity = Vector2()
puppet var puppet_transform = Transform2D()

export var stunned = false
##

export var ACCELERATION = 400
export var MAX_SPEED = 70
export var ROLL_SPEED = 125
export var FRICTION = 400

export var MASS = 100


enum {
	MOVE,
	ROLL,
	ATTACK
}

#Variables
var state = MOVE
var velocity = Vector2.ZERO

var roll_vector = Vector2.DOWN


var current_anim = ""
var prev_bombing = false
var bomb_index = 0

func _ready():
	#Add player collisions if server host as they will be handling all physics calc
	if(get_tree().is_network_server()):
		set_collision_layer_bit(1, true);
		set_collision_mask_bit(1, true);
		set_collision_mask_bit(2, true);
		set_collision_mask_bit(3, true);
	stunned = false
	puppet_transform = transform

		

#Summoning a rock and syncing it to players in server
# Use sync because it will be called everywhere
sync func summon_rock(rock_name, pos, by_who):
	var rock = preload("res://Rock.tscn").instance()
	rock.set_name(rock_name) # Ensure unique name for the bomb
	rock.position = pos
	#rock.from_who #we can set this when we need to know who killed who for stats
	
	
	# No need to set network master to bomb, will be owned by server by default
	get_node("../..").add_child(rock)

func _physics_process(delta):

	if is_network_master():
		match state:
			MOVE:
				move_state(delta)
			ROLL:
				roll_state(delta)
				
			ATTACK:
				attack_state(delta)

		var summoning = Input.is_action_just_pressed("set_bomb")
		if summoning:
			var rock_name = get_name() + str(bomb_index)
			var rock_pos = position
			rpc("summon_rock", rock_name, rock_pos , get_tree().get_network_unique_id())

		rset("puppet_transform", transform)
	else:
		transform = puppet_transform

	var new_anim = "standing"
	if velocity.y < 0:
		new_anim = "walk_up"
	elif velocity.y > 0:
		new_anim = "walk_down"
	elif velocity.x < 0:
		new_anim = "walk_left"
	elif velocity.x > 0:
		new_anim = "walk_right"

	if stunned:
		new_anim = "stunned"

	if new_anim != current_anim:
		current_anim = new_anim
		get_node("anim").play(current_anim)

	if not is_network_master():
		puppet_transform = transform # To avoid jitter

func move_state(delta):
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	input_vector = input_vector.normalized()
	
	if(input_vector != Vector2.ZERO):
		roll_vector = input_vector;

		velocity += input_vector * ACCELERATION * MASS * delta
		velocity = velocity.clamped(MAX_SPEED)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	
	move();
	
	if(Input.is_action_just_pressed("Roll")):
		state = ROLL;
	
	if(Input.is_action_just_pressed("attack")):
		state = ATTACK

func roll_state(delta):
	velocity = roll_vector * ROLL_SPEED;
	move();

func attack_state(delta):
	velocity = Vector2.ZERO


func move():
	var bodies = $Area2D.get_overlapping_bodies()
	var velocity_sum = Vector2()
	for bod in bodies:
		if(bod != self):
			velocity_sum += bod.velocity
	
	move_and_slide(velocity+velocity_sum)

puppet func stun():
	stunned = true

master func exploded(_by_who):
	if stunned:
		return
	rpc("stun") # Stun puppets
	stun() # Stun master - could use sync to do both at once

func set_player_name(new_name):
	get_node("label").set_text(new_name)

