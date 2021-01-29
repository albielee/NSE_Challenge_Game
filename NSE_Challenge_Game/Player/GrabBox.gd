extends Area

var knockback_vector = Vector3.ZERO

func _on_PushBox_area_entered(area):
	area.add_force(knockback_vector)
