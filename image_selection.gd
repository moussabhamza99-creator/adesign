extends Control
# ═══════════════════════════════════════════════════════════════
#  ImageSelection — Redesigned for the clean white theme
# ═══════════════════════════════════════════════════════════════

signal image_selected(path: String)
signal import_requested()

@onready var grid_container = $VBoxContainer/ScrollContainer/MarginContainer/GridContainer
@onready var title_label    = $VBoxContainer/TopBar/HBox/TitleLabel
@onready var stars_label    = $VBoxContainer/TopBar/HBox/StarsLabel
@onready var import_btn     = $VBoxContainer/TopBar/HBox/ImportBtn
@onready var settings_btn   = $VBoxContainer/TopBar/HBox/SettingsBtn
@onready var rewards_btn    = $VBoxContainer/TopBar/HBox/RewardsBtn
@onready var settings_panel = $SettingsPanel
@onready var rewards_panel  = $RewardsPanel
@onready var topbar         = $VBoxContainer/TopBar
@onready var bg_rect        = $BgRect

const PAGES_PATH = "res://assets/coloring_pages/"

func _ready() -> void:
	import_btn.pressed.connect(func(): import_requested.emit())
	settings_btn.pressed.connect(_toggle_settings)
	rewards_btn.pressed.connect(_toggle_rewards)
	$SettingsPanel/PanelContainer/VBox/CloseBtn.pressed.connect(func(): settings_panel.hide())
	$RewardsPanel/PanelContainer/VBox/CloseBtn.pressed.connect(func():  rewards_panel.hide())
	$SettingsPanel/PanelContainer/VBox/SoundBtn.pressed.connect(_on_sound_toggle)
	$SettingsPanel/PanelContainer/VBox/LangBox/LangFR.pressed.connect(func(): GameManager.set_language("fr"))
	$SettingsPanel/PanelContainer/VBox/LangBox/LangEN.pressed.connect(func(): GameManager.set_language("en"))
	$SettingsPanel/PanelContainer/VBox/LangBox/LangAR.pressed.connect(func(): GameManager.set_language("ar"))
	GameManager.language_changed.connect(_refresh_ui)
	GameManager.rewards_updated.connect(_refresh_stars)
	GameManager.sound_toggled.connect(_refresh_sound_btn)
	ThemeManager.layout_updated.connect(_apply_theme)
	AdManager.show_banner()
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

	stars_label.add_theme_color_override("font_color", tm.APP_ORANGE)
	stars_label.add_theme_font_size_override("font_size", tm.font_size_label)

	_style_header_btn(settings_btn, tm.APP_YELLOW)
	_style_header_btn(rewards_btn,  tm.APP_ORANGE)
	_style_header_btn(import_btn,   tm.C_SKY2)

	_style_overlay_panels()

func _style_header_btn(btn: Button, bg: Color) -> void:
	var tm = ThemeManager
	btn.add_theme_stylebox_override("normal", tm.make_square_rounded(bg, 16))
	btn.add_theme_color_override("font_color", Color(1,1,1))

func _style_overlay_panels() -> void:
	var tm = ThemeManager
	for pname in ["SettingsPanel", "RewardsPanel"]:
		var ov  = get_node(pname)
		ov.get_node("Bg").color = Color(0, 0, 0, 0.4)
		var pc  = ov.get_node("PanelContainer")
		pc.add_theme_stylebox_override("panel", tm.make_card(tm.C_CARD, 32))

	var sv = $SettingsPanel/PanelContainer/VBox
	tm.style_btn(sv.get_node("SoundBtn"),       tm.C_SKY,    tm.C_WHITE)
	tm.style_btn(sv.get_node("LangBox/LangFR"), tm.C_GRASS,  tm.C_WHITE)
	tm.style_btn(sv.get_node("LangBox/LangEN"), tm.C_BLUE,   tm.C_WHITE)
	tm.style_btn(sv.get_node("LangBox/LangAR"), tm.C_CANDY,  tm.C_WHITE)
	tm.style_btn(sv.get_node("CloseBtn"),       Color(0.9, 0.9, 0.9), tm.C_INK)

func _refresh_ui(_lang: String) -> void:
	title_label.text  = "Coloring"
	_rebuild_grid()

func _refresh_stars() -> void:
	stars_label.text = "⭐ %d" % GameManager.get_total_stars()

func _refresh_sound_btn(enabled: bool) -> void:
	$SettingsPanel/PanelContainer/VBox/SoundBtn.text = GameManager.tr_key("sound_on" if enabled else "sound_off")

func _on_sound_toggle() -> void:
	GameManager.toggle_sound()

func _toggle_settings() -> void:
	settings_panel.visible = !settings_panel.visible
	rewards_panel.hide()

func _toggle_rewards() -> void:
	rewards_panel.visible = !rewards_panel.visible
	settings_panel.hide()
	_populate_rewards()

func _load_images() -> void:
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
	btn.add_theme_stylebox_override("normal", tm.make_card(tm.C_CARD, 24))

	var img = _load_res_image(path)
	if img: btn.icon = ImageTexture.create_from_image(img)
	if GameManager.is_completed(path): btn.text = "⭐⭐⭐"
	btn.set_meta("img_path", path)
	btn.pressed.connect(func(): image_selected.emit(path))
	grid_container.add_child(btn)

func _load_res_image(res_path: String) -> Image:
	if ResourceLoader.exists(res_path):
		var tex = ResourceLoader.load(res_path, "Texture2D", ResourceLoader.CACHE_MODE_REUSE)
		if tex is Texture2D: return tex.get_image()
	return null

func _populate_rewards() -> void:
	var box = $RewardsPanel/PanelContainer/VBox
	for c in box.get_children():
		if c.name != "Title" and c.name != "CloseBtn": c.queue_free()
	for img_path in GameManager.completed_images:
		var lbl = Label.new()
		lbl.text = "⭐⭐⭐ " + (img_path as String).get_file().get_basename()
		box.add_child(lbl)
