extends Control
# ═══════════════════════════════════════════════════════════════
#  ImageSelection — "Color Fun!" theme
#  Fond ciel dégradé, cartes blanches avec accent coloré,
#  header blanc arrondi, police joyeuse
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

# Accents par image (couleur de la bande en haut de la carte)
const CARD_ACCENTS: Array = [
	Color(1.00, 0.61, 0.24, 1),   # orange
	Color(0.66, 0.45, 1.00, 1),   # violet
	Color(0.36, 0.78, 0.96, 1),   # ciel
	Color(1.00, 0.42, 0.68, 1),   # candy
	Color(1.00, 0.88, 0.40, 1),   # soleil
	Color(0.43, 0.91, 0.48, 1),   # herbe
]

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

# ── Thème "Color Fun!" ────────────────────────────────────────
func _apply_theme() -> void:
	var tm = ThemeManager

	# Fond dégradé ciel (simulé avec ColorRect + second rect)
	bg_rect.color = tm.C_SKY

	# TopBar : fond blanc arrondi façon "app-logo" du HTML
	var tb = StyleBoxFlat.new()
	tb.bg_color = tm.C_INK
	tb.shadow_color  = tm.C_SHADOW
	tb.shadow_size   = 8
	tb.shadow_offset = Vector2(0, 3)
	tb.border_width_bottom = 4
	tb.border_color        = Color(1.00, 0.61, 0.24, 1)
	topbar.add_theme_stylebox_override("panel", tb)
	topbar.custom_minimum_size.y = tm.topbar_height

	title_label.add_theme_color_override("font_color",    tm.C_WHITE)
	title_label.add_theme_font_size_override("font_size", tm.font_size_title)

	# Boutons header : blancs avec ombre (style .header-btn du HTML)
	_style_header_btn(settings_btn, tm.C_WHITE, tm.C_INK)
	_style_header_btn(rewards_btn,  tm.C_SUN,   tm.C_INK)
	_style_header_btn(import_btn,   tm.C_CANDY, tm.C_WHITE)
	for btn in [settings_btn, rewards_btn, import_btn]:
		btn.custom_minimum_size = Vector2(tm.btn_height, tm.btn_height)
		btn.add_theme_font_size_override("font_size", int(tm.font_size_label * 1.1))

	stars_label.add_theme_color_override("font_color",    tm.C_SUN)
	stars_label.add_theme_font_size_override("font_size", tm.font_size_label)

	grid_container.columns = tm.grid_columns
	_restyle_cards()
	_style_overlay_panels()

func _style_header_btn(btn: Button, bg: Color, fg: Color) -> void:
	var tm = ThemeManager
	var n  = tm.make_rounded(bg, 20, Color.TRANSPARENT, 0)
	n.shadow_color  = tm.C_SHADOW
	n.shadow_size   = 6
	n.shadow_offset = Vector2(0, 4)
	var h  = tm.make_rounded(bg.lightened(0.10), 20)
	var p  = tm.make_rounded(bg.darkened(0.08),  20)
	btn.add_theme_stylebox_override("normal",  n)
	btn.add_theme_stylebox_override("hover",   h)
	btn.add_theme_stylebox_override("pressed", p)
	btn.add_theme_color_override("font_color",       fg)
	btn.add_theme_color_override("font_hover_color", fg)
	btn.add_theme_font_size_override("font_size",    tm.font_size_label)
	btn.custom_minimum_size.y = tm.btn_height

func _style_overlay_panels() -> void:
	var tm = ThemeManager
	for pname in ["SettingsPanel", "RewardsPanel"]:
		var ov  = get_node(pname)
		ov.get_node("Bg").color = Color(0.18, 0.09, 0.33, 0.80)
		var pc  = ov.get_node("PanelContainer")
		var st  = tm.make_card(tm.C_CARD, 32)
		st.shadow_size = 24
		pc.add_theme_stylebox_override("panel", st)

	var sv = $SettingsPanel/PanelContainer/VBox
	_style_panel_title(sv.get_node("Title"))
	tm.style_btn(sv.get_node("SoundBtn"),       tm.C_SKY,    tm.C_WHITE)
	tm.style_btn(sv.get_node("LangBox/LangFR"), tm.C_GRASS,  tm.C_WHITE)
	tm.style_btn(sv.get_node("LangBox/LangEN"), tm.C_BLUE,   tm.C_WHITE)
	tm.style_btn(sv.get_node("LangBox/LangAR"), tm.C_CANDY,  tm.C_WHITE)
	tm.style_btn(sv.get_node("CloseBtn"),       Color(0.88, 0.86, 0.92, 1), tm.C_INK)

	var rv = $RewardsPanel/PanelContainer/VBox
	_style_panel_title(rv.get_node("Title"))
	tm.style_btn(rv.get_node("CloseBtn"), Color(0.88, 0.86, 0.92, 1), tm.C_INK)

func _style_panel_title(lbl: Label) -> void:
	lbl.add_theme_color_override("font_color",    ThemeManager.C_INK)
	lbl.add_theme_font_size_override("font_size", ThemeManager.font_size_title)

func _restyle_cards() -> void:
	var sz = ThemeManager.card_size
	for btn in grid_container.get_children():
		if btn.has_meta("img_path"):
			btn.custom_minimum_size = Vector2(sz, sz + 56)

# ── i18n ──────────────────────────────────────────────────────
func _refresh_ui(_lang: String) -> void:
	title_label.text  = "🎨 Color Fun!"
	settings_btn.text = "⚙️"
	rewards_btn.text  = "⭐"
	import_btn.text   = "+"
	_refresh_stars()
	_refresh_sound_btn(GameManager.sound_enabled)
	_rebuild_grid()
	_apply_theme()

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

# ── Chargement images ─────────────────────────────────────────
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
	if found.is_empty():
		found = ["dog.png"]
	var _idx = 0
	for file_name in found:
		_create_thumbnail_button(PAGES_PATH + file_name, _idx)
		_idx += 1

func _rebuild_grid() -> void:
	var sz = ThemeManager.card_size
	for btn in grid_container.get_children():
		if btn.has_meta("img_path"):
			btn.custom_minimum_size = Vector2(sz, sz + 56)
			var path: String = btn.get_meta("img_path")
			if GameManager.is_completed(path):
				btn.text = "⭐⭐⭐"

func _create_thumbnail_button(path: String, idx: int) -> void:
	var tm     = ThemeManager
	var sz     = tm.card_size
	var accent = CARD_ACCENTS[idx % CARD_ACCENTS.size()]

	var btn = Button.new()
	btn.custom_minimum_size   = Vector2(sz, sz + 56)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.expand_icon           = true
	btn.icon_alignment        = HORIZONTAL_ALIGNMENT_CENTER
	btn.clip_contents         = true

	# Carte blanche avec ombre (style .img-card HTML)
	var normal = tm.make_card(tm.C_CARD, 28)
	var hover  = tm.make_card(tm.C_CARD, 28)
	hover.shadow_size   = 18
	hover.border_color  = accent
	hover.border_width_left   = 3
	hover.border_width_right  = 3
	hover.border_width_top    = 3
	hover.border_width_bottom = 3
	var pressed = tm.make_card(Color(0.96, 0.96, 0.94, 1), 28)
	pressed.shadow_size = 4

	btn.add_theme_stylebox_override("normal",  normal)
	btn.add_theme_stylebox_override("hover",   hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_color_override("font_color",       tm.C_INK)
	btn.add_theme_font_size_override("font_size",    tm.font_size_label)

	# Bande accent colorée en haut (simulée via modulate du icon)
	btn.set_meta("accent_color", accent)

	var img = _load_res_image(path)
	if img:
		btn.icon = ImageTexture.create_from_image(img)

	if GameManager.is_completed(path):
		btn.text = "⭐⭐⭐"

	btn.set_meta("img_path", path)
	btn.pressed.connect(func(): image_selected.emit(path))
	grid_container.add_child(btn)

func _load_res_image(res_path: String) -> Image:
	if not res_path.begins_with("res://"):
		return Image.load_from_file(res_path)
	if ResourceLoader.exists(res_path):
		var tex = ResourceLoader.load(res_path, "Texture2D", ResourceLoader.CACHE_MODE_REUSE)
		if tex is Texture2D:
			return tex.get_image()
	var file = FileAccess.open(res_path, FileAccess.READ)
	if file:
		var bytes = file.get_buffer(file.get_length())
		file.close()
		var img = Image.new()
		if img.load_png_from_buffer(bytes) == OK:
			return img
	return null

func _populate_rewards() -> void:
	var box = $RewardsPanel/PanelContainer/VBox
	for c in box.get_children():
		if c.name != "Title" and c.name != "CloseBtn":
			c.queue_free()
	var total_lbl = Label.new()
	total_lbl.text = "⭐ %d étoiles" % GameManager.get_total_stars()
	total_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	total_lbl.add_theme_color_override("font_color",    ThemeManager.C_SUN)
	total_lbl.add_theme_font_size_override("font_size", ThemeManager.font_size_label + 2)
	box.add_child(total_lbl)
	for img_path in GameManager.completed_images:
		var lbl = Label.new()
		lbl.text = "⭐⭐⭐ " + (img_path as String).get_file().get_basename()
		lbl.add_theme_color_override("font_color", ThemeManager.C_INK)
		box.add_child(lbl)
