extends Sprite

#for animation
var frame_number = 0

#
var file_name = ""
var file_location = ""

var asset_dictionary = {}

func preload_asset_animation(file_location, file_name, y_size, frame_count):
	for i in range(frame_count):
		preload_asset(file_location, file_name + "_" + str(i), y_size)

func preload_asset(file_location, file_name, y_size):
	var img = Image.new()
	var texture = ImageTexture.new()
	texture.create_from_image(img.load(file_location + "/" + file_name), 0)
	
	if(asset_dictionary.has(file_name)):
		asset_dictionary[file_name].append(texture)
	else:
		asset_dictionary[file_name] = [texture]

func draw_sprite_3d(name, pos, col):
	var images = asset_dictionary[name]
	for i in range(len(images)):
		draw_texture(images[i],pos + Vector2(0,-i),col)
		
	#var img = preload(file_location + "/" + file_name);
	
	
	


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
