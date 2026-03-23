extends Control
# ═══════════════════════════════════════════════════════════════
#  MainUI — Improved to match the image while preserving features
# ═══════════════════════════════════════════════════════════════

@onready var viewport        = $VBoxContainer/ColoringArea/ColoringSceneContainer/SubViewport
@onready var coloring_ui     = $VBoxContainer
@onready var topbar          = $VBoxContainer/TopBar
@onready var level_label     = $VBoxContainer/TopBar/LevelLabel
@onready var settings_btn    = $VBoxContainer/TopBar/SettingsBtn
@onready var reset_btn       = $VBoxContainer/TopBar/ResetBtn

@onready var bubble          = $VBoxContainer/SubHeader/Bubble
@onready var title_label     = $VBoxContainer/SubHeader/Bubble/HBox/TitleLabel
@onready var title_icon      = $VBoxContainer/SubHeader/Bubble/HBox/Icon

@onready var grid_btn        = $VBoxContainer/ColoringArea/SideLeft/GridBtn
@onready var pencil_btn      = $VBoxContainer/ColoringArea/SideLeft/PencilBtn
@onready var save_btn        = $VBoxContainer/ColoringArea/SideLeft/SaveBtn
@onready var skip_btn        = $VBoxContainer/ColoringArea/SideRight/SkipBtn
@onready var shop_btn        = $VBoxContainer/ColoringArea/SideRight/ShopBtn

@onready var palette_hbox    = $VBoxContainer/UIPalette/PaletteScroll/HBox
@onready var back_btn        = $VBoxContainer/UIPalette/BackBtn

@onready var bg_rect         = $BgRect
@onready var reward_popup    = $RewardPopup
@onready var save_popup      = $SavePopup
@onready var save_path_label = $SavePopup/Panel/VBox/PathLabel
@onready var file_dialog     = $FileDialog
@onready var import_popup    = $ImportPopup
@onready var image_selection      = $ImageSelection
@onready var banner_placeholder   = $VBoxContainer/BannerPlaceholder

var png_scene_template = preload("res://scenes/png_coloring_scene.tscn")
var current_coloring_scene = null
var current_image_path: String = ""
var _selected_btn: Button = null

func _ready() -> void:
	image_selection.image_selected.connect(_on_png_selected)
	image_selection.import_requested.connect(_on_import_pressed)
	back_btn.pressed.connect(_show_menu)
	settings_btn.pressed.connect(func(): image_selection._toggle_settings())
	reset_btn.pressed.connect(_on_reset_pressed)
	save_btn.pressed.connect(_on_save_pressed)
	grid_btn.pressed.connect(_show_menu)

	file_dialog.file_selected.connect(_on_png_selected)
	$ImportPopup/Panel/VBox/BrowseBtn.pressed.connect(_on_browse_pressed)
	$ImportPopup/Panel/VBox/CancelBtn.pressed.connect(func(): import_popup.hide())

	GameManager.language_changed.connect(_refresh_labels)
	ThemeManager.layout_updated.connect(_apply_theme)

	_build_palette()
	_apply_theme()
	if AdManager.has_signal("banner_loaded"):
		AdManager.banner_loaded.connect(_on_banner_loaded)
	_setup_import_popup()
	_refresh_labels(GameManager.current_language)
	_show_menu()

func _apply_theme() -> void:
	var tm = ThemeManager
	bg_rect.color = tm.APP_BG

	# Top bar styling
	_style_app_btn(settings_btn, tm.APP_YELLOW, Color(0.9, 0.6, 0.2))
	_style_app_btn(reset_btn,    tm.C_CANDY,    Color(0.8, 0.2, 0.2))
	level_label.add_theme_color_override("font_color", tm.APP_TITLE)
	level_label.add_theme_font_size_override("font_size", tm.font_size_title)

	# SubHeader Bubble
	var sb = StyleBoxFlat.new()
	sb.bg_color = tm.APP_BUBBLE
	sb.corner_radius_top_left = 40
	sb.corner_radius_top_right = 40
	sb.corner_radius_bottom_left = 40
	sb.corner_radius_bottom_right = 40
	sb.border_width_left = 2
	sb.border_width_right = 2
	sb.border_width_top = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(0.9, 0.9, 0.9)
	sb.shadow_color = Color(0, 0, 0, 0.05)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(0, 4)
	bubble.add_theme_stylebox_override("panel", sb)
	title_label.add_theme_color_override("font_color", tm.APP_TITLE)
	title_label.add_theme_font_size_override("font_size", tm.font_size_label)

	# Side buttons
	_style_app_btn(grid_btn,   tm.C_SKY2, tm.APP_BLUE)
	_style_app_btn(pencil_btn, tm.APP_YELLOW, tm.APP_ORANGE)
	_style_app_btn(save_btn,   tm.C_GRASS, tm.C_GRASS.darkened(0.2))
	_style_app_btn(skip_btn,   tm.C_CANDY, tm.C_CANDY.darkened(0.2))
	_style_app_btn(shop_btn,   tm.APP_YELLOW, tm.APP_ORANGE)

	# Back button (X)
	var xb = StyleBoxFlat.new()
	xb.bg_color = Color(0.9, 0.4, 0.4)
	xb.corner_radius_top_left = 12
	xb.corner_radius_top_right = 12
	xb.corner_radius_bottom_left = 12
	xb.corner_radius_bottom_right = 12
	xb.shadow_color = Color(0, 0, 0, 0.2)
	xb.shadow_size = 4
	xb.shadow_offset = Vector2(0, 2)
	back_btn.add_theme_stylebox_override("normal", xb)

	_restyle_palette()

func _style_app_btn(btn: Button, bg: Color, icon_col: Color) -> void:
	var tm = ThemeManager
	var s = tm.make_square_rounded(bg, 20)
	btn.add_theme_stylebox_override("normal", s)
	btn.add_theme_stylebox_override("hover",  tm.make_square_rounded(bg.lightened(0.1), 20))
	btn.add_theme_stylebox_override("pressed", tm.make_square_rounded(bg.darkened(0.1), 20))
	btn.add_theme_color_override("font_color", icon_col)
	btn.add_theme_font_size_override("font_size", 40)

# ══════════════════════════════════════════════════════════════
#  PALETTE
# ══════════════════════════════════════════════════════════════
func _build_palette() -> void:
	for c in palette_hbox.get_children():
		c.queue_free()
	for entry in ThemeManager.PALETTE_COLORS:
		var btn = Button.new()
		btn.name = entry["name"]
		btn.text = entry["label"]
		btn.set_meta("paint_color", entry["color"])
		btn.pressed.connect(_on_color_selected.bind(btn))
		palette_hbox.add_child(btn)

func _restyle_palette() -> void:
	var tm = ThemeManager
	var sz = tm.palette_btn_size
	for btn in palette_hbox.get_children():
		btn.custom_minimum_size = Vector2(sz, sz)
		var col: Color = btn.get_meta("paint_color")
		btn.add_theme_stylebox_override("normal",  tm.make_square_rounded(col, 32))
		btn.add_theme_stylebox_override("hover",   tm.make_square_rounded(col.lightened(0.1), 32))
		btn.add_theme_stylebox_override("pressed", tm.make_square_rounded(col.darkened(0.1), 32))

func _on_color_selected(btn: Button) -> void:
	if current_coloring_scene:
		current_coloring_scene.set_color(btn.get_meta("paint_color"))
	if _selected_btn and _selected_btn != btn:
		_deselect_btn(_selected_btn)
	_selected_btn = btn
	_highlight_btn(btn)

func _highlight_btn(btn: Button) -> void:
	var col: Color = btn.get_meta("paint_color")
	var s = ThemeManager.make_square_rounded(col, 32)
	s.border_width_left = 6
	s.border_width_right = 6
	s.border_width_top = 6
	s.border_width_bottom = 6
	s.border_color = Color(1, 1, 1, 0.8)
	btn.add_theme_stylebox_override("normal", s)

func _deselect_btn(btn: Button) -> void:
	if not btn.has_meta("paint_color"):
		return
	var col: Color = btn.get_meta("paint_color")
	btn.add_theme_stylebox_override("normal", ThemeManager.make_square_rounded(col, 32))

# ══════════════════════════════════════════════════════════════
#  NAVIGATION
# ══════════════════════════════════════════════════════════════
func _on_banner_loaded() -> void:
	banner_placeholder.custom_minimum_size.y = 80

func _show_menu() -> void:
	image_selection.visible = true
	coloring_ui.visible     = false
	reward_popup.hide()
	save_popup.visible      = false
	_selected_btn           = null
	if current_coloring_scene:
		current_coloring_scene.queue_free()
		current_coloring_scene = null
	current_image_path = ""
	AdManager.show_banner()

func _on_png_selected(path: String) -> void:
	_load_png_scene(path)

func _load_png_scene(path: String) -> void:
	image_selection.visible = false
	coloring_ui.visible     = true
	current_image_path      = path

	title_label.text = path.get_file().get_basename().capitalize()
	title_icon.texture = null

	# Using completion info to "fake" level or just show image index
	var total = GameManager.completed_images.size()
	level_label.text = GameManager.tr_key("level") + " " + str(total + 1)

	if current_coloring_scene:
		current_coloring_scene.queue_free()
	current_coloring_scene = png_scene_template.instantiate()
	viewport.add_child(current_coloring_scene)
	await get_tree().process_frame
	current_coloring_scene.setup_png(path)
	current_coloring_scene.coloring_complete.connect(_on_coloring_complete)
	AdManager.on_image_opened()

	var first = palette_hbox.get_child(0)
	if first and first.has_meta("paint_color"):
		_on_color_selected(first)

func _on_reset_pressed() -> void:
	if current_coloring_scene and not current_image_path.is_empty():
		current_coloring_scene.setup_png(current_image_path)
	_selected_btn = null

func _on_coloring_complete() -> void:
	var stars = GameManager.award_completion(current_image_path)
	if stars > 0:
		reward_popup.get_node("Label").text = (
			GameManager.tr_key("well_done") + "\n" +
			GameManager.tr_key("stars_earned") % stars
		)
		reward_popup.popup_centered()

# ══════════════════════════════════════════════════════════════
#  SAUVEGARDE
# ══════════════════════════════════════════════════════════════
func _on_save_pressed() -> void:
	if current_coloring_scene == null:
		return
	var saved_path = current_coloring_scene.save_to_gallery()
	if saved_path != "":
		save_path_label.text = saved_path.get_file()
		_style_save_popup()
		save_popup.visible = true

func _style_save_popup() -> void:
	var tm = ThemeManager
	$SavePopup/Panel.add_theme_stylebox_override("panel", tm.make_card(tm.C_CARD, 36))
	$SavePopup/Bg.color = Color(0.18, 0.09, 0.33, 0.82)
	$SavePopup/Panel/VBox/Icon.add_theme_color_override("font_color",    tm.C_GRASS)
	$SavePopup/Panel/VBox/Icon.add_theme_font_size_override("font_size", int(tm.font_size_title * 1.8))
	$SavePopup/Panel/VBox/Title.add_theme_color_override("font_color",    tm.C_INK)
	$SavePopup/Panel/VBox/Title.add_theme_font_size_override("font_size", tm.font_size_title)
	save_path_label.add_theme_color_override("font_color",    tm.C_TEXT_MUTED)
	save_path_label.add_theme_font_size_override("font_size", tm.font_size_small)
	var ok_btn = $SavePopup/Panel/VBox/OkBtn
	tm.style_btn(ok_btn, tm.C_GRASS, tm.C_WHITE)
	ok_btn.pressed.connect(func(): save_popup.visible = false, CONNECT_ONE_SHOT)

# ══════════════════════════════════════════════════════════════
#  IMPORT
# ══════════════════════════════════════════════════════════════
func _on_import_pressed() -> void:
	import_popup.visible = true

func _on_browse_pressed() -> void:
	import_popup.hide()
	_open_file_picker()

func _open_file_picker() -> void:
	var os_name = OS.get_name()
	if os_name == "Android" or os_name == "iOS":
		var status = DisplayServer.file_dialog_show(
			"Choisir une image PNG", "", "", false,
			DisplayServer.FILE_DIALOG_MODE_OPEN_FILE,
			["*.png"],
			_on_native_file_selected
		)
		if status != OK:
			file_dialog.popup_centered()
	else:
		file_dialog.popup_centered()

func _on_native_file_selected(status: bool, selected_paths: PackedStringArray, _filter_idx: int) -> void:
	if status and selected_paths.size() > 0:
		_on_png_selected(selected_paths[0])

# ══════════════════════════════════════════════════════════════
#  I18N
# ══════════════════════════════════════════════════════════════
func _refresh_labels(_lang: String) -> void:
	# Update localized texts if needed
	pass

func _setup_import_popup() -> void:
	var tm = ThemeManager
	$ImportPopup/Bg.color = Color(0.18, 0.09, 0.33, 0.82)
	$ImportPopup/Panel.add_theme_stylebox_override("panel", tm.make_card(tm.C_CARD, 32))
	tm.style_btn($ImportPopup/Panel/VBox/BrowseBtn, tm.C_INK, tm.C_WHITE)
	var cb = $ImportPopup/Panel/VBox/CancelBtn
	cb.add_theme_stylebox_override("normal", tm.make_rounded(Color(0.88, 0.86, 0.92, 1), -1, tm.C_INK, 1))
	cb.add_theme_font_size_override("font_size",    tm.font_size_label)
