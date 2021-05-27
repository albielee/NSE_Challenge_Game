extends RigidBody

#CONTROLS
var movement = Vector2.ZERO
var pushpull = 0.0
var summon = 0.0
var grab = 0.0
var dash = 0.0
var mouse_position = Vector3.ZERO
var controls = [movement, pushpull, summon, grab, dash, mouse_position]

#NETWORK SETUP STUFF
var playerid = 0
var player_name = ""
var player_col = Color("")
var colours = [Color("0099db"),Color("68386c"),Color("feae34"),Color("3e8948")]
var spawn_position = Vector3.ZERO

#DASH STUFF
var go = false
var d = 0
var dash_angle = current_angle
var can_dash = 0.0
var dashes = []

#POINT STUFF
var touched = false
var last_attacker=""

#ANGLE STUFF
var mouse_angle = Vector3.ZERO
var current_angle = Vector3.ZERO
var current_face = 0.0

#ACTUAL MOVE VELOCITY
var move_velocity = Vector3.ZERO

#REMOTE POSITIONAL STUFF
var puppet_last_position = transform.origin
var puppet_next_position = transform.origin
var puppet_speed = 0.0
var r_rotation = 0.0
var r_position = transform.origin
var r_animation = "idle"
var r_velocity = Vector3.ZERO
var r_stats = [r_rotation,r_position,r_animation,r_velocity]
var current_time = 0.0
var last_packet_time = 0.0
var packet_time = 0.0
var elapsed_time = 0.0
var ideal_updates_per_packet = 0.0
var updates_per_packet = 0.0
var _updates = 0.0
var _packets = 0.0
var avg = 1.0
var time = 0.0
var packets = []
var buffer = []
var prev_speed = 0.0
var next_speed = 0.0

#SUMMONING STUFF
var summon_length = 15
var post_summon_length = 35
var has_summoned = false
var decided = false
var growing = false
var growing_rock = null
var length_det = false
var has_growed = false
var grow_length = 10
var post_grow_length = 0
var rock_summoned = false

#STATE ENUM
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

#ANIMATION STUFF
var anim = "idle"
var prevanim = "idle"
var blend_x = 0
var blend_y = 0

#PUSHING STUFF
var push_cooldown = 0
var push_mouse_position = mouse_position
var started_pushing = false

#PULLING STUFF
var pull_cooldown = 0
var pull_mouse_position = mouse_position
var started_pulling = false

#SHOVING STUFF
var shovable = false
var s_rock = null
var contact = false

#(HOST) ROTATION STUFF
var current_turn_speed = 0
var current_rotation = 0
var current_position = Vector3.ZERO
