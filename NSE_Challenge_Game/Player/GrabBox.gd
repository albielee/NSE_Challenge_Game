extends Area

var cf_vector = Vector3.ZERO
var knockback_vector = Vector3.ZERO
var pullin_vector = Vector3.ZERO
var player_position = Vector3.ZERO

var rock = null

signal encounter_rock
signal lost_rock

func cf_update(playerloc, grab_force, dropoff):
	if (rock==null):
		cf_vector = Vector3.ZERO
	else:
		var rockloc = rock.global_transform.origin
		var meloc = global_transform.origin
		var dist = meloc.distance_squared_to(rockloc)
		
		var distplayer = playerloc-rockloc
		
		transform.origin.z = min(-2,-distplayer.length())
		transform.origin.z = max(-10,-distplayer.length())
		
		var grab = grab_force
		
		cf_vector=(meloc-rockloc)*dist
		if(is_center(rockloc, meloc)):
			emit_signal("encounter_rock")
		pull_center(grab)

func push(playerloc, dropoff):
	if (!rock==null):
		var distance = playerloc.distance_to(rock.global_transform.origin)
		rock.add_force(knockback_vector/(dropoff*distance))
		
	
func pull(playerloc, dropoff):
	if (!rock==null):
		var distance = playerloc.distance_to(rock.global_transform.origin)
		rock.add_force(pullin_vector/(dropoff*distance))

func drop_rock():
	if (!rock==null):
		rock.out_zone()
		rock=null

func pull_center(grab_force):
	if (!rock==null):
		rock.add_force(cf_vector*grab_force)

func _on_GrabBox_area_entered(area):
	if (rock==null):
		rock=area
		rock.in_zone()

func is_center(rockloc, meloc):
	if meloc.distance_to(rockloc) < 1:
		return true
	return false

func _on_GrabBox_area_exited(area):
	if (area==rock):
		rock.out_zone()
		emit_signal("lost_rock")
		rock=null
