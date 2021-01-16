extends KinematicBody2D

export var ACCELERATION = 400
export var MAX_SPEED = 70
export var ROLL_SPEED = 125
export var FRICTION = 400

enum {
	MOVE,
	ROLL,
	SUMMON,
	PUSH,
	PULL,
	FALL
}

#Variables
var state = MOVE
var velocity = Vector2.ZERO
var roll_vector = Vector2.DOWN 

# Called when the node enters the scene tree for the first time.
func _ready():
	print("Player Spawned")

func set_control_profile(profile):
	""" This function sets the control profile this player is using, allowing multiple
	players to play on the same device. Control profiles consist of customized options,
	controls and which controller is being, allowing individual controlling of characters.
	This should be called by the game controller when a player is summoned.
	"""
	pass
	

func _physics_process(delta):
	"""Depending on the value of state, continue running that particular state every
	physics frame.
	"""
	match state:
		MOVE:
			move_state(delta)
			
		ROLL:
			roll_state(delta)
			
		SUMMON:
			attack_state(delta)
			
		PULL:
			pass
		
		PUSH:
			pass
			
		FALL:
			pass
			
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
	
	if(Input.is_action_just_pressed("Roll")):
		state = ROLL;
	
	if(Input.is_action_just_pressed("attack")):
		state = SUMMON;

func roll_state(delta):
	velocity = roll_vector * ROLL_SPEED;
	move();

func attack_state(delta):
	velocity = Vector2.ZERO

func move():
	velocity = move_and_slide(velocity)	


#archive
func roll_animation_finished():
	velocity = velocity / 1.2;
	state = MOVE;
	
func attack_animation_finished():
	state = MOVE
