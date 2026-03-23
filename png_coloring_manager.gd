extends Node2D

signal coloring_complete()

@onready var sprite: Sprite2D = $Sprite2D

var selected_color: Color = Color.RED
var image: Image
var texture: ImageTexture
var current_path: String = ""
var _fill_count: int = 0
var _pending_path: String = ""

@export var sfx_fill: AudioStream = null
@export var sfx_complete: AudioStream = null

func _ready() -> void:
	# Fond de la scène = couleur de l'app
	RenderingServer.set_default_clear_color(Color(0.36, 0.78, 0.96, 1))
	if _pending_path != "":
		setup_png(_pending_path)

func setup_png(png_path: String) -> void:
	current_path = png_path
	_fill_count  = 0

	if not is_inside_tree():
		_pending_path = png_path
		return

	_pending_path = ""
	image = _load_image(png_path)
	if image:
		image.convert(Image.FORMAT_RGBA8)
		_update_texture()
		# Laisser 2 frames au viewport pour se dimensionner
		await get_tree().process_frame
		await get_tree().process_frame
		_fit_sprite_to_viewport()

func _fit_sprite_to_viewport() -> void:
	if image == null or sprite == null:
		return
	var vp = get_viewport()
	if vp == null:
		return

	var vp_size = Vector2(vp.size)
	# Attendre un vrai dimensionnement
	var tries = 0
	while (vp_size.x <= 1 or vp_size.y <= 1) and tries < 10:
		await get_tree().process_frame
		vp_size = Vector2(vp.size)
		tries += 1

	if vp_size.x <= 1 or vp_size.y <= 1:
		return

	var img_w = float(image.get_width())
	var img_h = float(image.get_height())

	# Remplir toute la zone disponible (fill, pas fit)
	# en gardant le ratio
	var scale_x = vp_size.x / img_w
	var scale_y = vp_size.y / img_h
	var scale_factor = min(scale_x, scale_y)

	sprite.scale    = Vector2(scale_factor, scale_factor)
	sprite.position = vp_size / 2.0

func _load_image(path: String) -> Image:
	if not path.begins_with("res://"):
		return Image.load_from_file(path)
	if ResourceLoader.exists(path):
		var tex = ResourceLoader.load(path, "Texture2D", ResourceLoader.CACHE_MODE_REUSE)
		if tex is Texture2D:
			return tex.get_image()
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var bytes = file.get_buffer(file.get_length())
		file.close()
		var img = Image.new()
		if img.load_png_from_buffer(bytes) == OK:
			return img
	push_error("[PngColoringManager] Impossible de charger : " + path)
	return null

func _update_texture() -> void:
	texture = ImageTexture.create_from_image(image)
	sprite.texture = texture

func set_color(color: Color) -> void:
	selected_color = color

func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed):
		return
	if event.button_index != MOUSE_BUTTON_LEFT:
		return
	if image == null:
		return

	var img_w     = float(image.get_width())
	var img_h     = float(image.get_height())
	var local_pos = sprite.get_local_mouse_position()
	var pixel_pos = Vector2i(local_pos + Vector2(img_w / 2.0, img_h / 2.0))

	if pixel_pos.x < 0 or pixel_pos.x >= int(img_w):
		return
	if pixel_pos.y < 0 or pixel_pos.y >= int(img_h):
		return

	var target_color = image.get_pixelv(pixel_pos)
	if target_color.v > 0.1:
		FloodFill.fill(image, pixel_pos, target_color, selected_color)
		_update_texture()
		_fill_count += 1
		GameManager.play_sound(sfx_fill)
		get_viewport().set_input_as_handled()
		if _fill_count >= 5:
			coloring_complete.emit()

func save_to_gallery() -> String:
	if image == null:
		return ""
	var ts   = Time.get_unix_time_from_system()
	var path = "user://coloring_%d.png" % int(ts)
	image.save_png(path)
	return path
