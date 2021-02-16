extends Spatial

export var frame_rate = 0.05
export var start_frame = 0
export var delete_atend = false

onready var frames = get_children()
onready var frame_count = get_child_count()

var current_frame = 0

func _ready():
	#IF RETURING AN ERROR THEN THE ANIMATION OBJECT DOES NOT HAVE THE MINIMUM OF TWO FRAMES (.objs)
	#Set all frames to not be visible apart from the first one
	for f in frames:
		f.visible = false
	frames[start_frame].visible = true

func _process(delta):
	current_frame += frame_rate
	if(current_frame > frame_count):
		if(delete_atend):
			queue_free()
		else:
			frames[current_frame-1].visible = false
			current_frame = 0

	frames[current_frame-1].visible = false
	frames[current_frame].visible = true
