tool
extends Node2D

export var slice_sheet : Texture = null setget set_slice_sheet  # LIMITATION: All layers must border with transparent pixels
export var columns : int = 1 setget set_columns
export var rows : int = 1 setget set_rows
export var static_z : bool = false setget set_static_z # Don't dynamically calculate Z value
export var center : int = 0 setget set_center;

var layer_count : int;

const SHADER = preload("res://Shaders/StackedSprite.shader")

var Mat;
var sheet_size = Vector2(64, 64);
var layer_size = Vector2(64, 64);

var playing_animation = ""
var anim_index = 0
var anim_dict= {}
var timer_waittime = 1

func sync_material():
	Mat.set_shader_param("slice_sheet", slice_sheet);
	Mat.set_shader_param("columns", columns);
	Mat.set_shader_param("rows", rows);
	Mat.set_shader_param("layer_count", layer_count);
	Mat.set_shader_param("stretch", SsGlobals.cam_pitch if not Engine.editor_hint else 1);
	Mat.set_shader_param("center", center);

func _ready():
	setup_shader();

func setup_shader():
	layer_count = rows * columns;
	
	if (slice_sheet):
		sheet_size = slice_sheet.get_size();
		layer_size = Vector2(sheet_size.x / columns, sheet_size.y / rows);
	
	Mat = ShaderMaterial.new()
	Mat.shader = SHADER
	self.set_material(Mat)
	call_deferred("sync_material");

func _process(_delta):
	if (not static_z):
		var cam_rot = get_viewport_transform().get_rotation()
		z_index = global_position.rotated(cam_rot).y;
	

func _draw():
	# TODO: draw a polygon that's only the visible parts and dynamic uv mapping
	draw_rect(Rect2(
		-layer_size / 2,
		layer_size
	), Color.black, true);
	
	# Draw a bigger bounding rect to prevent off-screen culling too early
	var largest_possible_size = layer_size + Vector2(layer_count, layer_count) * 2;
	draw_rect(Rect2(
		-largest_possible_size / 2,
		largest_possible_size
	), Color.transparent, false);

# Engine Hints

func on_value_change():
	setup_shader();

func set_slice_sheet(new_value):
	slice_sheet = new_value;
	on_value_change();

func set_columns(new_value):
	columns = new_value;
	on_value_change();

func set_rows(new_value):
	rows = new_value;
	on_value_change();

func set_static_z(new_value):
	static_z = new_value;
	on_value_change();

func set_center(new_value):
	center = new_value;
	on_value_change();

func set_sprite(load_path, r):
	set_rows(r)
	set_slice_sheet(load(load_path))

func load_animation(anim_name, load_path, frame_number, r):
	var frames = []
	load_path = load_path.split(".");
	var path = load_path[0]
	var png = load_path[1]

	frames.append(r)
	for i in range(frame_number):
		frames.append(load(path + str(i+1) + "." + png))
	anim_dict[anim_name] = frames

func play_animation(anim_name, speed):
	anim_index = 1
	playing_animation = anim_name
	timer_waittime = 1.0/speed
	
	set_rows(anim_dict[anim_name][0])
	set_slice_sheet(anim_dict[anim_name][anim_index])
	anim_index += 1
	$Timer.set_wait_time(timer_waittime)
	$Timer.start()
	

func _on_Timer_timeout():
	if(anim_index > len(anim_dict[playing_animation])-2):
		anim_index = 0
		playing_animation = ""
		timer_waittime = 1
		$Timer.stop()
	else:
		set_slice_sheet(anim_dict[playing_animation][anim_index])
		anim_index += 1
		$Timer.set_wait_time(timer_waittime)
		$Timer.start()
	
