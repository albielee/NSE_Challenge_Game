extends Spatial

export var frame_rate = 0.05
export var start_frame = 0
export var run_once = false
export var playing = true

onready var frames = get_children()
onready var frame_count = get_child_count()

var current_frame = 0
var finished = false

func _ready():
	visible = false
	#IF RETURING AN ERROR THEN THE ANIMATION OBJECT DOES NOT HAVE THE MINIMUM OF TWO FRAMES (.objs)
	#Set all frames to not be visible apart from the first one
	for f in frames:
		f.visible = false
	frames[start_frame].visible = true

func play():
	playing = true

func stop():
	visible = false
	playing = false

func _process(delta):
	if(playing):
		visible = true
		current_frame += frame_rate
		if(current_frame > frame_count):
			if(run_once):
				stop()
				return
			else:
				frames[floor(current_frame)-1].visible = false
				current_frame = 0

		frames[floor(current_frame)-1].visible = false
		frames[floor(current_frame)].visible = true
