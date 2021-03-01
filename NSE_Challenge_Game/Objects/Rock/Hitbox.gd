extends Area

var knockback = Vector3.ZERO
var angular = 0
var face = 0
var speed = 0.0
var flying = false
var pushed = false
var size = 0
var owned_by = 0
var linear_velocity = 0
var pos = Vector3.ZERO

signal pushed
signal zone
signal nozone
signal spun

func add_force(knockback_vector):
	knockback = knockback_vector
	emit_signal("pushed")

func angular_velocity(value):
	angular = value
	emit_signal("spun")

func in_zone(pusher):
	owned_by = pusher
	pushed = true
	emit_signal("zone")
	
func out_zone():
	pushed = false
	emit_signal("nozone")
