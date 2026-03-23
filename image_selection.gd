extends Control
# ═══════════════════════════════════════════════════════════════
#  ImageSelection — Redesigned with white theme & corrected imports
# ═══════════════════════════════════════════════════════════════

signal image_selected(path: String)
signal import_requested()

@onready var main_ui        = get_parent()
@onready var grid_container = $VBoxContainer/ScrollContainer/MarginContainer/GridContainer
@onready var title_label    = $VBoxContainer/TopBar/HBox/TitleLabel
@onready var import_btn     = $VBoxContainer/TopBar/HBox/ImportBtn
@onready var settings_btn   = $VBoxContainer/TopBar/HBox/SettingsBtn
@onready var topbar         = $VBoxContainer/TopBar
@onready var bg_rect        = $BgRect

const PAGES_PATH = "res://assets/coloring_pages/"

func _ready() -> void:
	import_btn.pressed.connect(func(): import_requested.emit())
	settings_btn.pressed.connect(func(): main_ui.toggle_settings())
	GameManager.language_changed.connect(_refresh_ui)
	ThemeManager.layout_updated.connect(_apply_theme)

	_apply_theme()
	_refresh_ui(GameManager.current_language)
	_load_images()

func _apply_theme() -> void:
	var tm = ThemeManager
	bg_rect.color = tm.APP_BG

	var tb = StyleBoxFlat.new()
	tb.bg_color = tm.APP_BG
	tb.shadow_color = Color(0,0,0,0.05)
	tb.shadow_size = 4
	topbar.add_theme_stylebox_override("panel", tb)

	title_label.add_theme_color_override("font_color", tm.APP_TITLE)
	title_label.add_theme_font_size_override("font_size", tm.font_size_title)

	_style_header_btn(settings_btn, tm.APP_GRAY, Color(0.3, 0.3, 0.3))
	_style_header_btn(import_btn,   tm.APP_BLUE, Color(1, 1, 1))

func _style_header_btn(btn: Button, bg: Color, fg: Color) -> void:
	var tm = ThemeManager
	btn.add_theme_stylebox_override("normal", tm.make_square_rounded(bg, 16))
	btn.add_theme_stylebox_override("hover",  tm.make_square_rounded(bg.lightened(0.1), 16))
	btn.add_theme_stylebox_override("pressed", tm.make_square_rounded(bg.darkened(0.1), 16))
	btn.add_theme_color_override("font_color", fg)

func _refresh_ui(_lang: String) -> void:
	title_label.text  = GameManager.tr_key("app_title")
	_rebuild_grid()
	_apply_theme()

func _load_images() -> void:
	for c in grid_container.get_children():
		c.queue_free()
	var found: Array[String] = []
	var dir = DirAccess.open(PAGES_PATH)
	if dir:
		dir.list_dir_begin()
		var f = dir.get_next()
		while f != "":
			if not dir.current_is_dir() and f.ends_with(".png") and not f.ends_with(".png.import"):
				found.append(f)
			f = dir.get_next()
		dir.list_dir_end()
	if found.is_empty(): found = ["dog.png"]
	for file_name in found:
		_create_thumbnail_button(PAGES_PATH + file_name)

func _rebuild_grid() -> void:
	for btn in grid_container.get_children():
		if btn.has_meta("img_path"):
			var path: String = btn.get_meta("img_path")
			if GameManager.is_completed(path): btn.text = "⭐⭐⭐"

func _create_thumbnail_button(path: String) -> void:
	var tm = ThemeManager
	var sz = tm.card_size
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(sz, sz)
	btn.expand_icon = true
	btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var normal = tm.make_card(tm.C_CARD, 24)
	var hover  = tm.make_card(tm.C_CARD, 24)
	hover.border_width_left = 4
	hover.border_width_right = 4
	hover.border_width_top = 4
	hover.border_width_bottom = 4
	hover.border_color = tm.APP_BLUE
	var pressed = tm.make_card(tm.C_CARD.darkened(0.05), 24)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover",  hover)
	btn.add_theme_stylebox_override("pressed", pressed)

	var img = _load_res_image(path)
	if img: btn.icon = ImageTexture.create_from_image(img)
	if GameManager.is_completed(path): btn.text = "⭐⭐⭐"
	btn.set_meta("img_path", path)
	btn.pressed.connect(func(): image_selected.emit(path))
	grid_container.add_child(btn)

func _load_res_image(res_path: String) -> Image:
	if not res_path.begins_with("res://"):
		return Image.load_from_file(res_path)
	if ResourceLoader.exists(res_path):
		var tex = ResourceLoader.load(res_path, "Texture2D", ResourceLoader.CACHE_MODE_REUSE)
		if tex is Texture2D: return tex.get_image()
	var file = FileAccess.open(res_path, FileAccess.READ)
	if file:
		var bytes = file.get_buffer(file.get_length())
		file.close()
		var img = Image.new()
		if img.load_png_from_buffer(bytes) == OK:
			return img
	return null
