extends Area

signal start_pushing
signal stop_pushing

var rock = null

func start_pushing(body):
	rock = body
	print("push")
	emit_signal("start_pushing")
	get_node("../GrabBeamHandler").start_beam(body,0)

func stop_pushing(body):
	rock = null
	emit_signal("stop_pushing")
	get_node("../GrabBeamHandler").stop_beam()

func _on_RockHitBox_area_entered(area):
	start_pushing(area.get_parent())

func _on_RockHitBox_area_exited(area):
	stop_pushing(area.get_parent())
