extends Area

var i = 0

func _on_Hitbox2_area_entered(area):
	area.start_pushing(get_parent())

func _on_Hitbox2_area_exited(area):
	area.stop_pushing(get_parent())
