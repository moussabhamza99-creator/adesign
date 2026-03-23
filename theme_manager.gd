extends Node
# ═══════════════════════════════════════════════════════════════
#  ThemeManager — "Color Fun!" 
#  Inspiré du design HTML : ciel bleu, cartes blanches,
#  accents candy/orange/violet, police ronde et joyeuse
# ═══════════════════════════════════════════════════════════════

# ── Palette "Color Fun!" ──────────────────────────────────────
const C_SKY          = Color(0.36, 0.78, 0.96, 1)   # #5BC8F5 ciel
const C_SKY2         = Color(0.53, 0.87, 1.00, 1)   # #87DEFF ciel clair
const C_GRASS        = Color(0.43, 0.91, 0.48, 1)   # #6EE77A vert herbe
const C_SUN          = Color(1.00, 0.88, 0.40, 1)   # #FFE066 soleil
const C_CANDY        = Color(1.00, 0.42, 0.68, 1)   # #FF6BAE rose candy
const C_ORANGE       = Color(1.00, 0.61, 0.24, 1)   # #FF9B3E orange
const C_PURPLE       = Color(0.66, 0.45, 1.00, 1)   # #A872FF violet
const C_INK          = Color(0.18, 0.09, 0.33, 1)   # #2D1654 encre foncée
const C_CARD         = Color(1.00, 1.00, 0.96, 1)   # #FFFEF5 carte
const C_WHITE        = Color(1.00, 1.00, 1.00, 1)   # blanc pur
const C_TEXT_LIGHT   = Color(1.00, 1.00, 1.00, 1)   # texte sur fond coloré
const C_TEXT_MUTED   = Color(0.53, 0.46, 0.63, 1)   # #8875a0 gris-violet
const C_SHADOW       = Color(0.18, 0.09, 0.33, 0.18)# shadow card

# App image colors
const APP_BG         = Color(0.96, 0.96, 0.96, 1.0) # Light gray background
const APP_TITLE      = Color(0.66, 0.18, 0.20, 1.0) # Dark red for level text
const APP_ORANGE     = Color(0.96, 0.53, 0.38, 1.0)
const APP_YELLOW     = Color(0.97, 0.88, 0.36, 1.0)
const APP_BLUE       = Color(0.00, 0.36, 0.56, 1.0) # Dark blue for Undo
const APP_GRAY       = Color(0.88, 0.88, 0.88, 1.0) # Gray for Settings
const APP_BUBBLE     = Color(1.0, 1.0, 1.0, 1.0)

# Alias pour compatibilité avec les scripts existants
const C_BG           = C_SKY
const C_BG2          = C_SKY2
const C_SURFACE      = C_CARD
const C_TOPBAR       = C_INK
const C_TOPBAR2      = Color(0.23, 0.12, 0.43, 1)
const C_ACCENT       = C_CANDY
const C_ACCENT2      = C_ORANGE
const C_SAGE         = C_GRASS
const C_SAGE2        = Color(0.60, 0.95, 0.65, 1)
const C_GOLD         = C_SUN
const C_BLUE         = C_SKY
const C_TEXT         = C_INK
const C_TEXT2        = C_TEXT_MUTED
const C_BORDER       = Color(1.00, 1.00, 1.00, 0.90)
const C_CARD_SHADOW  = C_SHADOW

# ── Tailles responsive ────────────────────────────────────────
var is_tablet: bool = false
var screen_w: int   = 0
var screen_h: int   = 0

var font_size_title: int  = 36
var font_size_label: int  = 26
var font_size_small: int  = 20
var btn_height: int       = 82
var btn_radius: int       = 999   # capsule parfaite (--r-btn: 999px)
var card_size: int        = 260
var grid_columns: int     = 2
var palette_btn_size: int = 140   # Bigger for swatches
var topbar_height: int    = 116
var palette_height: int   = 200
var margin: int           = 20

signal layout_updated()

func _ready() -> void:
	get_tree().root.size_changed.connect(_on_screen_resized)
	_on_screen_resized()

func _on_screen_resized() -> void:
	screen_w = DisplayServer.window_get_size().x
	screen_h = DisplayServer.window_get_size().y
	var dpi  = DisplayServer.screen_get_dpi()
	var dp_w = float(screen_w) / (float(dpi) / 160.0)
	is_tablet = dp_w >= 600.0
	_compute_sizes()
	layout_updated.emit()

func _compute_sizes() -> void:
	var scale = clampf(float(screen_w) / 1080.0, 0.62, 1.0)
	if is_tablet:
		font_size_title  = 44
		font_size_label  = 32
		font_size_small  = 24
		btn_height       = 96
		btn_radius       = 999
		card_size        = 300
		grid_columns     = 3
		palette_btn_size = 104
		topbar_height    = 136
		palette_height   = 164
		margin           = 28
	else:
		font_size_title  = int(36 * scale)
		font_size_label  = int(26 * scale)
		font_size_small  = int(20 * scale)
		btn_height       = int(82 * scale)
		btn_radius       = 999
		card_size        = int(260 * scale)
		grid_columns     = 2
		palette_btn_size = int(88 * scale)
		topbar_height    = int(116 * scale)
		palette_height   = int(144 * scale)
		margin           = int(20 * scale)

# ── StyleBox helpers ─────────────────────────────────────────
func make_rounded(color: Color, radius: int = -1,
		border_color: Color = Color.TRANSPARENT, border_w: int = 0) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	var r = btn_radius if radius < 0 else radius
	s.bg_color = color
	s.corner_radius_top_left     = r
	s.corner_radius_top_right    = r
	s.corner_radius_bottom_left  = r
	s.corner_radius_bottom_right = r
	if border_w > 0:
		s.border_width_left   = border_w
		s.border_width_right  = border_w
		s.border_width_top    = border_w
		s.border_width_bottom = border_w
		s.border_color        = border_color
	return s

func make_square_rounded(color: Color, radius: int = 24) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = color
	s.corner_radius_top_left     = radius
	s.corner_radius_top_right    = radius
	s.corner_radius_bottom_left  = radius
	s.corner_radius_bottom_right = radius
	s.shadow_color  = Color(0, 0, 0, 0.2)
	s.shadow_size   = 4
	s.shadow_offset = Vector2(0, 6)
	return s

func make_card(color: Color, radius: int = 28) -> StyleBoxFlat:
	var s = make_rounded(color, radius, C_WHITE, 3)
	s.shadow_color  = C_SHADOW
	s.shadow_size   = 10
	s.shadow_offset = Vector2(0, 6)
	s.content_margin_left   = 10
	s.content_margin_right  = 10
	s.content_margin_top    = 10
	s.content_margin_bottom = 12
	return s

func make_btn(bg: Color, radius: int = -1) -> StyleBoxFlat:
	var s = make_rounded(bg, radius)
	s.shadow_color  = Color(bg.r * 0.55, bg.g * 0.55, bg.b * 0.55, 0.40)
	s.shadow_size   = 8
	s.shadow_offset = Vector2(0, 4)
	s.content_margin_left   = 14
	s.content_margin_right  = 14
	s.content_margin_top    = 6
	s.content_margin_bottom = 6
	return s

func style_btn(btn: Button, bg: Color,
		fg: Color = C_TEXT_LIGHT, radius: int = -1) -> void:
	btn.add_theme_stylebox_override("normal",   make_btn(bg, radius))
	btn.add_theme_stylebox_override("hover",    make_btn(bg.lightened(0.12), radius))
	btn.add_theme_stylebox_override("pressed",  make_btn(bg.darkened(0.12), radius))
	btn.add_theme_stylebox_override("disabled", make_rounded(Color(0.75, 0.73, 0.70, 1), radius))
	btn.add_theme_color_override("font_color",         fg)
	btn.add_theme_color_override("font_hover_color",   fg)
	btn.add_theme_color_override("font_pressed_color", fg)
	btn.add_theme_font_size_override("font_size",      font_size_label)
	btn.custom_minimum_size.y = btn_height

# ── 31 couleurs de peinture ──────────────────────────────────
const PALETTE_COLORS: Array = [
	{name="Orange",     color=Color(0.96, 0.53, 0.38, 1), label=""},
	{name="Yellow",     color=Color(0.97, 0.88, 0.36, 1), label=""},
	{name="Blue",       color=Color(0.36, 0.36, 0.96, 1), label=""},
	{name="Red",        color=Color(0.92, 0.18, 0.18, 1), label="🔴"},
	{name="DarkRed",    color=Color(0.60, 0.05, 0.05, 1), label="🟥"},
	{name="Orange",     color=Color(0.95, 0.50, 0.08, 1), label="🟠"},
	{name="DarkOrange", color=Color(0.75, 0.30, 0.02, 1), label="🫙"},
	{name="Yellow",     color=Color(0.97, 0.84, 0.08, 1), label="🟡"},
	{name="LightYellow",color=Color(0.99, 0.95, 0.55, 1), label="🌟"},
	{name="LimeGreen",  color=Color(0.55, 0.88, 0.20, 1), label="🍏"},
	{name="Green",      color=Color(0.18, 0.70, 0.32, 1), label="🟢"},
	{name="DarkGreen",  color=Color(0.05, 0.42, 0.15, 1), label="🌲"},
	{name="Teal",       color=Color(0.08, 0.62, 0.58, 1), label="🩵"},
	{name="SkyBlue",    color=Color(0.40, 0.75, 0.95, 1), label="🩵"},
	{name="Blue",       color=Color(0.20, 0.50, 0.90, 1), label="🔵"},
	{name="DarkBlue",   color=Color(0.08, 0.18, 0.65, 1), label="🫐"},
	{name="Navy",       color=Color(0.05, 0.08, 0.40, 1), label="🌊"},
	{name="Purple",     color=Color(0.55, 0.18, 0.82, 1), label="🟣"},
	{name="DarkPurple", color=Color(0.32, 0.05, 0.50, 1), label="🍇"},
	{name="Violet",     color=Color(0.72, 0.38, 0.95, 1), label="💜"},
	{name="Pink",       color=Color(0.95, 0.42, 0.72, 1), label="🩷"},
	{name="HotPink",    color=Color(0.98, 0.12, 0.55, 1), label="💗"},
	{name="Magenta",    color=Color(0.82, 0.08, 0.62, 1), label="🌸"},
	{name="Coral",      color=Color(0.98, 0.42, 0.32, 1), label="🪸"},
	{name="Salmon",     color=Color(0.98, 0.65, 0.55, 1), label="🐠"},
	{name="Peach",      color=Color(0.99, 0.80, 0.62, 1), label="🍑"},
	{name="Gold",       color=Color(0.95, 0.75, 0.10, 1), label="🥇"},
	{name="Brown",      color=Color(0.52, 0.27, 0.08, 1), label="🟤"},
	{name="DarkBrown",  color=Color(0.30, 0.14, 0.03, 1), label="🍫"},
	{name="Tan",        color=Color(0.78, 0.62, 0.42, 1), label="🌾"},
	{name="Gray",       color=Color(0.55, 0.55, 0.55, 1), label="🩶"},
	{name="LightGray",  color=Color(0.82, 0.82, 0.82, 1), label="☁️"},
	{name="White",      color=Color(0.97, 0.97, 0.95, 1), label="⬜"},
	{name="Black",      color=Color(0.06, 0.06, 0.08, 1), label="⬛"},
]
