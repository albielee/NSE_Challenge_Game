extends Area

var knockback = Vector3.ZERO
var size = 0
var pos = Vector3.ZERO

signal pushed

func add_force(knockback_vector):
	knockback = knockback_vector
	emit_signal("pushed")
