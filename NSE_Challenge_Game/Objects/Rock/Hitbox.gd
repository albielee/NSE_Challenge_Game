extends Area

var knockback = Vector3.ZERO

signal pushed
signal zone
signal nozone

func add_force(knockback_vector):
	knockback = knockback_vector
	emit_signal("pushed")

func in_zone():
	emit_signal("zone")
	
func out_zone():
	emit_signal("nozone")
