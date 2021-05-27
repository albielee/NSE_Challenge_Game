extends Spatial

onready var box1 = $Box1
onready var box2 = $Box2
onready var box3 = $Box3
onready var box4 = $Box4

var can_summon = false

func setup(size):
	box1.transform.origin = Vector3(-size/sqrt(2)/2,0,-size/sqrt(2)/2)
	box2.transform.origin = Vector3(size/sqrt(2)/2,0,-size/sqrt(2)/2)
	box3.transform.origin = Vector3(-size/sqrt(2)/2,0,size/sqrt(2)/2)
	box4.transform.origin = Vector3(size/sqrt(2)/2,0,size/sqrt(2)/2)

func _process(delta):
	if can_summon == true:
		for b in [box1, box2, box3, box4]:
			if len(b.get_overlapping_bodies()) == 0:
				can_summon = false
	if can_summon == false:
		var c = 0
		for b in [box1, box2, box3, box4]:
			if len(b.get_overlapping_bodies()) >= 1:
				c+=1
		if c == 4: 
			can_summon = true
	
