extends Area

signal start_pushing
signal stop_pushing

var rock = null

func start_pushing(body):
	rock = body
	emit_signal("start_pushing")

func stop_pushing(body):
	rock = null
	emit_signal("stop_pushing")
