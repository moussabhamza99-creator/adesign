extends Control
# ═══════════════════════════════════════════════════════════════
#  MainUI — Corrected navigation and feature access
# ═══════════════════════════════════════════════════════════════

@onready var viewport        = $VBoxContainer/ColoringArea/Margin/WhiteCard/ColoringSceneContainer/SubViewport
@onready var coloring_ui     = $VBoxContainer
@onready var topbar          = $VBoxContainer/TopBar
@onready var level_label     = $VBoxContainer/TopBar/LevelLabel
@onready var settings_btn    = $VBoxContainer/TopBar/SettingsBtn
@onready var undo_btn        = $VBoxContainer/TopBar/UndoBtn

@onready var white_card      = $VBoxContainer/ColoringArea/Margin/WhiteCard
@onready var tap_to_color    = $VBoxContainer/ColoringArea/Margin/WhiteCard/TapToColor
@onready var star_btn        = $VBoxContainer/ColoringArea/StarBtn

@onready var palette_panel   = $VBoxContainer/UIPalettePanel
@onready var palette_hbox    = $VBoxContainer/UIPalettePanel/HBox/PaletteScroll/PaletteHBox
@onready var save_tool       = $VBoxContainer/UIPalettePanel/HBox/ToolsHBox/SaveTool
@onready var pencil_tool      = $VBoxContainer/UIPalettePanel/HBox/ToolsHBox/PencilTool
@onready var back_tool        = $VBoxContainer/UIPalettePanel/HBox/ToolsHBox/BackTool

@onready var settings_panel   = $SettingsPanel
@onready var rewards_panel    = $RewardsPanel

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
	undo_btn.pressed.connect(_on_reset_pressed)
	settings_btn.pressed.connect(toggle_settings)
	save_tool.pressed.connect(_on_save_pressed)
	back_tool.pressed.connect(_show_menu)
	star_btn.pressed.connect(toggle_rewards)

	$SettingsPanel/PanelContainer/VBox/CloseBtn.pressed.connect(func(): settings_panel.hide())
	$RewardsPanel/PanelContainer/VBox/CloseBtn.pressed.connect(func():  rewards_panel.hide())
	$SettingsPanel/PanelContainer/VBox/SoundBtn.pressed.connect(GameManager.toggle_sound)
	$SettingsPanel/PanelContainer/VBox/LangBox/LangFR.pressed.connect(func(): GameManager.set_language("fr"))
	$SettingsPanel/PanelContainer/VBox/LangBox/LangEN.pressed.connect(func(): GameManager.set_language("en"))
	$SettingsPanel/PanelContainer/VBox/LangBox/LangAR.pressed.connect(func(): GameManager.set_language("ar"))

	file_dialog.file_selected.connect(_on_png_selected)
	$ImportPopup/Panel/VBox/BrowseBtn.pressed.connect(_on_browse_pressed)
	$ImportPopup/Panel/VBox/CancelBtn.pressed.connect(func(): import_popup.hide())

	GameManager.language_changed.connect(_refresh_labels)
	GameManager.sound_toggled.connect(_refresh_sound_btn)
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

	_style_app_btn(settings_btn, tm.APP_GRAY, Color(0.3, 0.3, 0.3))
	_style_app_btn(undo_btn,     tm.APP_BLUE, Color(1, 1, 1))

	var tb_st = StyleBoxFlat.new()
	tb_st.bg_color = tm.APP_BG
	tb_st.shadow_color = Color(0,0,0,0.05)
	tb_st.shadow_size = 4
	topbar.add_theme_stylebox_override("panel", tb_st)

	level_label.add_theme_color_override("font_color", tm.APP_TITLE)
	level_label.add_theme_font_size_override("font_size", tm.font_size_title)

	var wc = StyleBoxFlat.new()
	wc.bg_color = Color(1, 1, 1)
	wc.corner_radius_top_left = 80
	wc.corner_radius_top_right = 80
	wc.corner_radius_bottom_left = 80
	wc.corner_radius_bottom_right = 80
	wc.shadow_color = Color(0, 0, 0, 0.05)
	wc.shadow_size = 20
	wc.shadow_offset = Vector2(0, 10)
	white_card.add_theme_stylebox_override("panel", wc)

	var tc = StyleBoxFlat.new()
	tc.bg_color = tm.APP_YELLOW
	tc.corner_radius_top_left = 30
	tc.corner_radius_top_right = 30
	tc.corner_radius_bottom_left = 30
	tc.corner_radius_bottom_right = 30
	tap_to_color.add_theme_stylebox_override("panel", tc)
	var tcl = tap_to_color.get_node("Label")
	tcl.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2))
	tcl.add_theme_font_size_override("font_size", 22)

	var sb = StyleBoxFlat.new()
	sb.bg_color = tm.APP_YELLOW
	sb.corner_radius_top_left = 80
	sb.corner_radius_top_right = 80
	sb.corner_radius_bottom_left = 80
	sb.corner_radius_bottom_right = 80
	sb.shadow_color = Color(0, 0, 0, 0.1)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(0, 5)
	star_btn.add_theme_stylebox_override("normal", sb)
	star_btn.add_theme_stylebox_override("hover",  sb.duplicate())
	star_btn.add_theme_color_override("font_color", Color(0.4, 0.3, 0.0))
	star_btn.add_theme_font_size_override("font_size", 80)

	var pp = StyleBoxFlat.new()
	pp.bg_color = Color(1, 1, 1)
	pp.corner_radius_top_left = 60
	pp.corner_radius_top_right = 60
	pp.content_margin_left = 40
	pp.content_margin_right = 40
	palette_panel.add_theme_stylebox_override("panel", pp)

	_style_palette_tool(save_tool)
	_style_palette_tool(pencil_tool)
	_style_palette_tool(back_tool)

	_style_overlay_panels()

	_restyle_palette()

func _style_app_btn(btn: Button, bg: Color, icon_col: Color) -> void:
	var tm = ThemeManager
	var s = tm.make_square_rounded(bg, 20)
	btn.add_theme_stylebox_override("normal", s)
	btn.add_theme_stylebox_override("hover",  tm.make_square_rounded(bg.lightened(0.1), 20))
	btn.add_theme_stylebox_override("pressed", tm.make_square_rounded(bg.darkened(0.1), 20))
	btn.add_theme_color_override("font_color", icon_col)
	btn.add_theme_font_size_override("font_size", 40)

func _style_palette_tool(btn: Button) -> void:
	var tm = ThemeManager
	var s = tm.make_square_rounded(tm.APP_GRAY, 20)
	btn.add_theme_stylebox_override("normal", s)
	btn.add_theme_stylebox_override("hover",  tm.make_square_rounded(tm.APP_GRAY.lightened(0.05), 20))
	btn.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))
	btn.add_theme_font_size_override("font_size", 40)

func _style_overlay_panels() -> void:
	var tm = ThemeManager
	for panel in [settings_panel, rewards_panel]:
		panel.get_node("Bg").color = Color(0, 0, 0, 0.4)
		var pc = panel.get_node("PanelContainer")
		pc.add_theme_stylebox_override("panel", tm.make_card(tm.C_CARD, 32))

	var sv = settings_panel.get_node("PanelContainer/VBox")
	tm.style_btn(sv.get_node("SoundBtn"),       tm.C_SKY,    tm.C_WHITE)
	tm.style_btn(sv.get_node("LangBox/LangFR"), tm.C_GRASS,  tm.C_WHITE)
	tm.style_btn(sv.get_node("LangBox/LangEN"), tm.C_BLUE,   tm.C_WHITE)
	tm.style_btn(sv.get_node("LangBox/LangAR"), tm.C_CANDY,  tm.C_WHITE)
	tm.style_btn(sv.get_node("CloseBtn"),       Color(0.9, 0.9, 0.9), tm.C_INK)

func toggle_settings() -> void:
	settings_panel.visible = !settings_panel.visible
	rewards_panel.hide()

func toggle_rewards() -> void:
	rewards_panel.visible = !rewards_panel.visible
	settings_panel.hide()
	if rewards_panel.visible:
		_populate_rewards()

func _populate_rewards() -> void:
	var box = rewards_panel.get_node("PanelContainer/VBox")
	for c in box.get_children():
		if c.name != "Title" and c.name != "CloseBtn": c.queue_free()
	for img_path in GameManager.completed_images:
		var lbl = Label.new()
		lbl.text = "⭐⭐⭐ " + (img_path as String).get_file().get_basename()
		lbl.add_theme_color_override("font_color", ThemeManager.C_INK)
		box.add_child(lbl)

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
	var sz = 120
	for btn in palette_hbox.get_children():
		btn.custom_minimum_size = Vector2(sz, sz)
		var col: Color = btn.get_meta("paint_color")
		btn.add_theme_stylebox_override("normal",  tm.make_square_rounded(col, 32))

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
	s.border_width_left = 8
	s.border_width_right = 8
	s.border_width_top = 8
	s.border_width_bottom = 8
	s.border_color = Color(1, 1, 1, 0.6)
	btn.add_theme_stylebox_override("normal", s)

func _deselect_btn(btn: Button) -> void:
	if not btn.has_meta("paint_color"):
		return
	var col: Color = btn.get_meta("paint_color")
	btn.add_theme_stylebox_override("normal", ThemeManager.make_square_rounded(col, 32))

func _on_banner_loaded() -> void:
	banner_placeholder.custom_minimum_size.y = 80

func _show_menu() -> void:
	image_selection.visible = true
	coloring_ui.visible     = false
	reward_popup.hide()
	save_popup.visible      = false
	settings_panel.hide()
	rewards_panel.hide()
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
	_refresh_labels("")
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

func _refresh_labels(_lang: String) -> void:
	var l = GameManager.tr_key("level")
	var total = GameManager.completed_images.size()
	level_label.text = l + " " + str(total + 1)
	_refresh_sound_btn(GameManager.sound_enabled)

func _refresh_sound_btn(enabled: bool) -> void:
	settings_panel.get_node("PanelContainer/VBox/SoundBtn").text = GameManager.tr_key("sound_on" if enabled else "sound_off")

func _setup_import_popup() -> void:
	var tm = ThemeManager
	$ImportPopup/Bg.color = Color(0.18, 0.09, 0.33, 0.82)
	$ImportPopup/Panel.add_theme_stylebox_override("panel", tm.make_card(tm.C_CARD, 32))
	tm.style_btn($ImportPopup/Panel/VBox/BrowseBtn, tm.C_INK, tm.C_WHITE)
	var cb = $ImportPopup/Panel/VBox/CancelBtn
	cb.add_theme_stylebox_override("normal", tm.make_rounded(Color(0.88, 0.86, 0.92, 1), -1, tm.C_INK, 1))
	cb.add_theme_font_size_override("font_size",    tm.font_size_label)
