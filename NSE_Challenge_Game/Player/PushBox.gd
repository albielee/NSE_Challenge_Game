extends Area

var knockback_vector = Vector3.ZERO
var rock = null

onready var shape = $CollisionShape

func _on_PushBox_area_entered(area):
	area.add_force(knockback_vector)
