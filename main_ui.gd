extends Control
# ═══════════════════════════════════════════════════════════════
#  MainUI — "Color Fun!" theme
#  Fond ciel, toolbar encre foncée, palette pleine largeur
# ═══════════════════════════════════════════════════════════════

@onready var viewport        = $VBoxContainer/ColoringArea/ColoringSceneContainer/SubViewport
@onready var coloring_ui     = $VBoxContainer
@onready var topbar          = $VBoxContainer/TopBar
@onready var back_btn        = $VBoxContainer/TopBar/HBox/BackBtn
@onready var save_btn        = $VBoxContainer/TopBar/HBox/SaveBtn
@onready var sound_btn       = $VBoxContainer/TopBar/HBox/SoundBtn
@onready var title_label     = $VBoxContainer/TopBar/HBox/TitleLabel
@onready var palette_panel   = $VBoxContainer/UIPalette
@onready var palette_hbox    = $VBoxContainer/UIPalette/HBoxLayout/Scroll/HBox
@onready var palette_scroll  = $VBoxContainer/UIPalette/HBoxLayout/Scroll
@onready var arrow_left      = $VBoxContainer/UIPalette/HBoxLayout/ArrowLeft
@onready var arrow_right     = $VBoxContainer/UIPalette/HBoxLayout/ArrowRight
@onready var bg_rect         = $BgRect
@onready var reward_popup    = $RewardPopup
@onready var save_popup      = $SavePopup
@onready var save_path_label = $SavePopup/Panel/VBox/PathLabel
@onready var file_dialog     = $FileDialog
@onready var import_popup    = $ImportPopup
@onready var import_drop     = $ImportPopup/Panel/VBox/DropZone
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
	save_btn.pressed.connect(_on_save_pressed)
	sound_btn.pressed.connect(GameManager.toggle_sound)
	file_dialog.file_selected.connect(_on_png_selected)
	$ImportPopup/Panel/VBox/BrowseBtn.pressed.connect(_on_browse_pressed)
	$ImportPopup/Panel/VBox/CancelBtn.pressed.connect(func(): import_popup.hide())
	$ImportPopup/Panel/VBox/DropZone.gui_input.connect(_on_drop_zone_input)
	GameManager.language_changed.connect(_refresh_labels)
	GameManager.sound_toggled.connect(_refresh_sound_btn)
	ThemeManager.layout_updated.connect(_apply_theme)
	arrow_left.pressed.connect(_scroll_palette.bind(-1))
	arrow_right.pressed.connect(_scroll_palette.bind(1))
	$VBoxContainer/TopBar/HBox/ResetBtn.pressed.connect(_on_reset_pressed)
	_build_palette()
	_apply_theme()
	if AdManager.has_signal("banner_loaded"):
		AdManager.banner_loaded.connect(_on_banner_loaded)
	_setup_import_popup()
	_refresh_labels(GameManager.current_language)
	_show_menu()

# ══════════════════════════════════════════════════════════════
#  THÈME "Color Fun!"
# ══════════════════════════════════════════════════════════════
func _apply_theme() -> void:
	var tm = ThemeManager

	# Fond ciel
	bg_rect.color = tm.C_SKY

	# TopBar encre foncée (style .color-toolbar HTML)
	var tb = StyleBoxFlat.new()
	tb.bg_color      = tm.C_INK
	tb.shadow_color  = Color(0, 0, 0, 0.22)
	tb.shadow_size   = 10
	tb.shadow_offset = Vector2(0, 4)
	tb.border_width_bottom = 4
	tb.border_color        = Color(1.00, 0.61, 0.24, 1)
	topbar.add_theme_stylebox_override("panel", tb)
	topbar.custom_minimum_size.y = tm.topbar_height

	title_label.add_theme_color_override("font_color",    tm.C_WHITE)
	title_label.add_theme_font_size_override("font_size", tm.font_size_label)

	# Boutons toolbar : style .tool-btn (blanc, arrondi 16px)
	_style_tool_btn(back_btn,  tm.C_CANDY,  tm.C_WHITE)
	_style_tool_btn(save_btn,  tm.C_GRASS,  tm.C_WHITE)
	_style_tool_btn(sound_btn, tm.C_SKY,    tm.C_WHITE)
	back_btn.custom_minimum_size  = Vector2(100, tm.btn_height)
	save_btn.custom_minimum_size  = Vector2(125, tm.btn_height)
	sound_btn.custom_minimum_size = Vector2(tm.btn_height, tm.btn_height)
	_style_tool_btn($VBoxContainer/TopBar/HBox/ResetBtn, Color(0.92, 0.30, 0.22, 1), tm.C_WHITE)
	$VBoxContainer/TopBar/HBox/ResetBtn.custom_minimum_size = Vector2(tm.btn_height, tm.btn_height)

	# Palette : fond blanc avec ombre, swatches circulaires
	var pal = StyleBoxFlat.new()
	pal.bg_color      = tm.C_WHITE
	pal.shadow_color  = Color(0, 0, 0, 0.12)
	pal.shadow_size   = 8
	pal.shadow_offset = Vector2(0, -3)
	palette_panel.add_theme_stylebox_override("panel", pal)
	palette_panel.custom_minimum_size.y = tm.palette_height

	_restyle_palette()

	# Flèches palette
	# Fleches semi-transparentes avec scroll visible au survol
	var arrow_n = StyleBoxFlat.new()
	arrow_n.bg_color = Color(tm.C_INK.r, tm.C_INK.g, tm.C_INK.b, 0.35)
	var arrow_h = StyleBoxFlat.new()
	arrow_h.bg_color = Color(tm.C_INK.r, tm.C_INK.g, tm.C_INK.b, 0.65)
	var arrow_p = StyleBoxFlat.new()
	arrow_p.bg_color = Color(tm.C_INK.r, tm.C_INK.g, tm.C_INK.b, 0.80)
	for arr in [arrow_left, arrow_right]:
		arr.add_theme_stylebox_override("normal",  arrow_n)
		arr.add_theme_stylebox_override("hover",   arrow_h)
		arr.add_theme_stylebox_override("pressed", arrow_p)
		arr.add_theme_color_override("font_color",         Color(1, 1, 1, 0.9))
		arr.add_theme_color_override("font_hover_color",   Color(1, 1, 1, 1.0))
		arr.add_theme_color_override("font_pressed_color", Color(1, 1, 1, 1.0))
		arr.add_theme_font_size_override("font_size", tm.font_size_title)
		arr.custom_minimum_size = Vector2(tm.palette_btn_size, 0)

func _style_tool_btn(btn: Button, bg: Color, fg: Color) -> void:
	var tm = ThemeManager
	btn.add_theme_stylebox_override("normal",  tm.make_btn(bg))
	btn.add_theme_stylebox_override("hover",   tm.make_btn(bg.lightened(0.12)))
	btn.add_theme_stylebox_override("pressed", tm.make_btn(bg.darkened(0.12)))
	btn.add_theme_color_override("font_color",       fg)
	btn.add_theme_color_override("font_hover_color", fg)
	btn.add_theme_font_size_override("font_size",    tm.font_size_label)
	btn.custom_minimum_size.y = tm.btn_height

# ══════════════════════════════════════════════════════════════
#  PALETTE
# ══════════════════════════════════════════════════════════════
func _scroll_palette(direction: int) -> void:
	var step = ThemeManager.palette_btn_size + 16
	palette_scroll.scroll_horizontal += direction * step * 6

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
	var r  = sz >> 1
	for btn in palette_hbox.get_children():
		btn.custom_minimum_size = Vector2(sz, sz)
		btn.add_theme_font_size_override("font_size", int(sz * 0.66))
		var col: Color = btn.get_meta("paint_color")
		var n = tm.make_rounded(col, r, tm.C_WHITE, 3)
		n.shadow_color  = Color(col.r * 0.5, col.g * 0.5, col.b * 0.5, 0.35)
		n.shadow_size   = 5
		n.shadow_offset = Vector2(0, 3)
		btn.add_theme_stylebox_override("normal",  n)
		btn.add_theme_stylebox_override("hover",   tm.make_rounded(col.lightened(0.10), r, tm.C_WHITE, 4))
		btn.add_theme_stylebox_override("pressed", tm.make_rounded(col.darkened(0.12), r, tm.C_WHITE, 2))
		btn.add_theme_color_override("font_color",       Color(1, 1, 1, 0.0))
		btn.add_theme_color_override("font_hover_color", Color(1, 1, 1, 0.0))

func _on_color_selected(btn: Button) -> void:
	if current_coloring_scene:
		current_coloring_scene.set_color(btn.get_meta("paint_color"))
	if _selected_btn and _selected_btn != btn:
		_deselect_btn(_selected_btn)
	_selected_btn = btn
	_highlight_btn(btn)

func _highlight_btn(btn: Button) -> void:
	var col: Color = btn.get_meta("paint_color")
	var sz = ThemeManager.palette_btn_size
	var r  = sz >> 1
	var s  = ThemeManager.make_rounded(col, r, ThemeManager.C_WHITE, 5)
	s.shadow_color  = Color(col.r * 0.4, col.g * 0.4, col.b * 0.4, 0.55)
	s.shadow_size   = 10
	s.shadow_offset = Vector2(0, 4)
	btn.add_theme_stylebox_override("normal", s)

func _deselect_btn(btn: Button) -> void:
	if not btn.has_meta("paint_color"):
		return
	var col: Color = btn.get_meta("paint_color")
	var sz = ThemeManager.palette_btn_size
	var r  = sz >> 1
	var n  = ThemeManager.make_rounded(col, r, ThemeManager.C_WHITE, 3)
	n.shadow_color  = Color(col.r * 0.5, col.g * 0.5, col.b * 0.5, 0.35)
	n.shadow_size   = 5
	n.shadow_offset = Vector2(0, 3)
	btn.add_theme_stylebox_override("normal", n)

# ══════════════════════════════════════════════════════════════
#  NAVIGATION
# ══════════════════════════════════════════════════════════════
func _on_banner_loaded() -> void:
	# Le banner AdMob est chargé — réserver 60px pour lui
	banner_placeholder.custom_minimum_size.y = 60

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
	if current_coloring_scene:
		current_coloring_scene.queue_free()
	current_coloring_scene = png_scene_template.instantiate()
	viewport.add_child(current_coloring_scene)
	# Attendre que le viewport soit dimensionné avant setup_png
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

func _on_drop_zone_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
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

func _setup_import_popup() -> void:
	var tm = ThemeManager
	$ImportPopup/Bg.color = Color(0.18, 0.09, 0.33, 0.82)
	$ImportPopup/Panel.add_theme_stylebox_override("panel", tm.make_card(tm.C_CARD, 32))
	$ImportPopup/Panel/VBox/Title.add_theme_color_override("font_color",    tm.C_INK)
	$ImportPopup/Panel/VBox/Title.add_theme_font_size_override("font_size", tm.font_size_title)
	$ImportPopup/Panel/VBox/Subtitle.add_theme_color_override("font_color",    tm.C_TEXT_MUTED)
	$ImportPopup/Panel/VBox/Subtitle.add_theme_font_size_override("font_size", tm.font_size_small)
	$ImportPopup/Panel/VBox/DropZone.add_theme_stylebox_override("panel",
		tm.make_rounded(Color(0.87, 0.95, 1.0, 1), 20, tm.C_SKY, 2))
	$ImportPopup/Panel/VBox/DropZone/VBox/DropLabel.add_theme_color_override("font_color",    tm.C_INK)
	$ImportPopup/Panel/VBox/DropZone/VBox/DropLabel.add_theme_font_size_override("font_size", tm.font_size_label)
	$ImportPopup/Panel/VBox/DropZone/VBox/DropHint.add_theme_color_override("font_color",    tm.C_SKY)
	$ImportPopup/Panel/VBox/DropZone/VBox/DropHint.add_theme_font_size_override("font_size", tm.font_size_small)
	tm.style_btn($ImportPopup/Panel/VBox/BrowseBtn, tm.C_INK, tm.C_WHITE)
	var cb = $ImportPopup/Panel/VBox/CancelBtn
	cb.add_theme_stylebox_override("normal", tm.make_rounded(Color(0.88, 0.86, 0.92, 1), -1, tm.C_INK, 1))
	cb.add_theme_stylebox_override("hover",  tm.make_rounded(Color(0.80, 0.78, 0.88, 1), -1, tm.C_CANDY, 2))
	cb.add_theme_color_override("font_color",       tm.C_INK)
	cb.add_theme_color_override("font_hover_color", tm.C_INK)
	cb.add_theme_font_size_override("font_size",    tm.font_size_label)
	cb.custom_minimum_size.y = tm.btn_height

# ══════════════════════════════════════════════════════════════
#  I18N
# ══════════════════════════════════════════════════════════════
func _refresh_labels(_lang: String) -> void:
	title_label.text = "🎨 " + GameManager.tr_key("app_title").split(" ")[0]
	back_btn.text    = "← " + GameManager.tr_key("back")
	save_btn.text    = "💾 " + GameManager.tr_key("save")
	_refresh_sound_btn(GameManager.sound_enabled)

func _refresh_sound_btn(enabled: bool) -> void:
	sound_btn.text = "♪" if enabled else "✕"
