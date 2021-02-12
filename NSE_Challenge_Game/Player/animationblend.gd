extends Control

var point_pos = Vector2.ZERO

func _process(delta):
	update() 
	$RichTextLabel.text = String(Engine.get_frames_per_second())

func _draw():
	var mul = 5
	var pos = Vector2(30,30)
	var line_s = 30
	draw_line(Vector2(pos.x,pos.y+line_s)*mul,Vector2(pos.x,pos.y-line_s)*mul,Color(1,1,1,1))
	draw_line(Vector2(pos.x+line_s,pos.y)*mul,Vector2(pos.x-line_s,pos.y)*mul,Color(1,1,1,1))
	draw_circle(Vector2((point_pos.x*line_s*2)+line_s*mul, (point_pos.y*line_s*2)+line_s*mul), 5, Color(1,1,1,1))
